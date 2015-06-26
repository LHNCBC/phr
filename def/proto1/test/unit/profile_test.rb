require 'test_helper'

class ProfileTest < ActiveSupport::TestCase

  fixtures :users
  fixtures :profiles
  fixtures :forms
  fixtures :profiles_users
  fixtures :autosave_tmps

  def test_export
    # Tables for testing CVS
    tcvs = ["forms", "field_descriptions", "db_field_descriptions", "text_lists", "text_list_items"]
    # Tables for testing EXCEL
    DatabaseMethod.copy_development_tables_to_test(["db_table_descriptions"], false)
    txsl =  DbTableDescription.current_data_tables.map(&:data_table)
    tables = ["profiles", "users", "profiles_users"] + tcvs + txsl
   
    DatabaseMethod.copy_development_tables_to_test(tables, false)
    # For some reason all data table models are missing, reload them again
    DbTableDescription.define_user_data_models

    profile = Profile.first
    profile_name = profile.phr.pseudonym
    user = profile.users.first
    profile_data, file_name = profile.export("phr", "1", user.id)
    assert_not_nil profile_data
    assert_equal "#{profile_name}.csv", file_name

    profile_data, file_name = profile.export("phr", "2", user.id)
    assert_not_nil profile_data
    assert_equal "#{profile_name}.xls", file_name
  end


  # Requires that fields & tables in the user data tables are also defined
  # in config/excel_export.yml and vice-versa, with possibly a few exceptions.
  def test_export_definition
    DatabaseMethod.copy_development_tables_to_test(
      ['db_table_descriptions', 'db_field_descriptions'], false)

    db_table_to_fields = {} # database definition
    DbTableDescription.current_data_tables.each do |dbt|
      skip_tables = Set.new(%w{obr_orders date_reminders reminder_options users})
      if !skip_tables.member?(dbt.data_table)
        db_table_to_fields[dbt.data_table] =
          dbt.data_table.singularize.camelize.constantize.column_names.clone
      end
    end
    export_config = config = YAML::load(File.open('config/excel_export.yml'))
    exp_table_to_fields = {} # config definition
    export_config['sheets'].each do |sheet|
      tbl_config = sheet['rows'][0]['table']
      exp_table_to_fields[tbl_config['name']] =
        tbl_config['fields'].collect{|f| f.keys[0]}
    end

    # Report things in the configuration that are not in the database.
    # Also allow fields that are defined as methods on the model class.
    exp_table_to_fields.each do |table_name, config_fields|
      db_fields = db_table_to_fields[table_name]
      assert_not_nil(db_fields,
        "#{table_name} was defined in config/excel_export.yml but not in "+
        "db_table_descriptions")
      db_class = table_name.singularize.camelize.constantize
      config_fields.each do |config_field|
        assert(db_fields.index(config_field) ||
               db_class.instance_methods.include?(config_field.to_sym),
          "#{config_field} was defined in config/excel_export.yml but not in "+
          "#{table_name} or its model class #{db_class.name}")
      end
    end

    # Report things in the database that are not in the configuration
    skipped_cols = {
        'obx_observations'=>%w{obx3_1_obs_ident obx3_2_obs_ident
         obx3_3_obs_ident obx5_3_value_if_coded obx5_value_if_text_report
         obx6_2_unit obx6_3_unit obx11_result_status_code
         obx19_analysis_datetime obx23_performing_organization
         obx24_performing_address obx25_performing_director display_order
         code_system is_panel required_in_panel last_value lastvalue_date
         last_date last_date_ET last_date_HL7 is_panel_hdr disp_level}
    }
    db_table_to_fields.each do |table_name, db_fields|
      config_fields = exp_table_to_fields[table_name]
      assert_not_nil(config_fields,
        "#{table_name} was defined in db_table_descriptions but not in "+
        "config/excel_export.yml")
      db_fields.delete('id') # we don't export the id column
      db_fields.delete('latest') # we don't need this because we only export the current values
      db_fields.delete('profile_id') # we only export that once, with the phrs table
      db_fields.delete('deleted_at') # we only export current records
      cols = skipped_cols[table_name]
      cols.each {|c| db_fields.delete(c)} if cols
      db_fields.each do |field|
        assert(config_fields.index(field),
          "#{field} was defined in #{table_name} but not in "+
          "config/excel_export.yml")
      end
    end
  end


  def test_soft_delete
    DatabaseMethod.copy_development_tables_to_test(['users', 'profiles',
        'profiles_users', 'phrs'])
    profile = Profile.first
    user = profile.users.first
    phr = profile.phr
    # Check the join table, using straight SQL.  Unfortunately, we can't
    # use Rails' anti-sql injection parameters here, but we are just inserting
    # IDs.
    assert_equal(1, ActiveRecord::Base.connection.select_rows(
      "select * from profiles_users where profile_id=#{profile.id} and user_id=#{user.id}").count)
    profile.soft_delete
    assert_equal(0, ActiveRecord::Base.connection.select_rows(
      "select * from profiles_users where profile_id=#{profile.id} and user_id=#{user.id}").count)
    assert_not_nil(Phr.find_by_id(phr.id))
    assert_nil(Profile.find_by_id(profile.id))
    assert_not_nil(User.find_by_id(user.id))
  end


  def test_has_autosave
    has_one = profiles(:temp_profile_4)
    has_none = profiles(:other_user_phr1)
    assert_equal(true, has_one.has_autosave?)
    assert_equal(false, has_none.has_autosave?)
  end


  def test_delete_autosave
    has_one = profiles(:temp_profile_4)
    has_one_ct = AutosaveTmp.where(:profile_id => has_one.id).count
    assert_equal(3, has_one_ct)
    has_one.delete_autosave
    has_one_ct = AutosaveTmp.where(:profile_id => has_one.id).count
    assert_equal(0, has_one_ct)

    has_none = profiles(:other_user_phr1)
    has_none_ct = AutosaveTmp.where(:profile_id => has_none.id).count
    assert_equal(0, has_none_ct)
    has_none.delete_autosave
    has_none_ct = AutosaveTmp.where(:profile_id => has_none.id).count
    assert_equal(0, has_none_ct)
  end


  def test_latest_obr_orders
    # Create two profiles
    p1 = Profile.create!
    p2 = Profile.create!
    # Create 3 ObrOrders for p1 with the same loinc_num and with the latest
    # date in the middle, to test which one we will get.
    loinc_num = 'AAA'
    LoincItem.create!(:loinc_num=>loinc_num)
    p1.obr_orders << ObrOrder.new(:loinc_num=>loinc_num, :test_date=>'2000/2/3')
    p1.obr_orders << ObrOrder.new(:loinc_num=>loinc_num, :test_date=>'2012/2/3')
    p1.obr_orders << ObrOrder.new(:loinc_num=>loinc_num, :test_date=>'2009/2/3')
    # Create one ObrOrder for p2 whose date is even later (to test whether it
    # gets mixed in with the p1 ObrOrders).
    p2.obr_orders << ObrOrder.new(:loinc_num=>loinc_num, :test_date=>'2013/4/5')

    obrs = p1.latest_obr_orders
    assert_equal(1, obrs.length)
    assert_equal('2012 Feb 3', obrs[0].test_date)
    assert_equal('20120203', obrs[0].test_date_HL7)
  end


  def test_multi_column_sort
    data_to_sort = [['c', 'g'],
                    ['a', 'a'],
                    ['a', 'b'],
                    ['b', 'g']]
    # Sort first by the first column, and secondarily (with in the first
    # column's groupings) by the third column in reverse order.
    Profile.multi_column_sort(data_to_sort, [1, -2])
    assert_equal(['a', 'b'], data_to_sort[0])
    assert_equal(['a', 'a'], data_to_sort[1])
    assert_equal(['b', 'g'], data_to_sort[2])
    assert_equal(['c', 'g'], data_to_sort[3])


    # Make sure the negative column number is not resulting in a negative
    # array index.  Try a 3 element array, and sort in reverse on field 3
    # A index of -2 would pick up the second element and sort on that by
    # mistake.
    data_to_sort = [['a', 'z', 'a'],
                    ['a', 'y', 'b']]
    Profile.multi_column_sort(data_to_sort, [-3])
    assert_equal([['a', 'y', 'b'],
                  ['a', 'z', 'a']], data_to_sort)
    data_to_sort = [['a', 'y', 'a'],
                    ['a', 'z', 'b']]
    Profile.multi_column_sort(data_to_sort, [-3])
    assert_equal([['a', 'z', 'b'],
                  ['a', 'y', 'a']], data_to_sort)
  end
end
