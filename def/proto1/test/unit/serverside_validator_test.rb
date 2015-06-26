require 'test_helper'

class ServersideValidatorTest < ActiveSupport::TestCase
  fixtures :db_table_descriptions

  def setup
    # tring to test private methods
    def ServersideValidator.validate_date_range_t(range, v)
      self.validate_date_range(range, v)
    end
    def ServersideValidator.validate_date_format_t(format, v)
      self.validate_date_format(format, v)
    end
    def ServersideValidator.validate_t(data_hash, validate_def)
      self.validate(data_hash, validate_def)
    end
  end

#  def test_validate_date_range
#    range = ["t-100Y", "t"]
#
#    v = "1999"
#    expected = ServersideValidator.validate_date_range_t(range, v)
#    assert expected.nil?
#
##    v = "2010"
#    v = (Time.now.year.to_i + 10).to_s
#    expected = ServersideValidator.validate_date_range_t(range, v)
#    assert expected.include?("Please use correct date range")
#
#    v = "1908"
#    expected = ServersideValidator.validate_date_range_t(range, v)
#    assert expected.include?("Please use correct date range")
#  end
#
# def test_validate_date_format
#   format_list = ["YYYY", "YYYY/MM","YYYY/MM/DD","YYYY/MM/[DD]","YYYY/[MM/[DD]]"]
#
#   # test acceptable formats
#   v="1999"
#   rs_list = format_list.map do|format|
#     ServersideValidator.validate_date_format_t(format, v)
#   end
#   #valid formats
#   assert rs_list[0].nil?
#   assert rs_list[4].nil?
#   #invalid formats
#   assert rs_list.compact.size == 3 # three formats are not valid
#
#   v="1999/01"
#   rs_list = format_list.map {|fmt|ServersideValidator.validate_date_format_t(fmt, v)}
#   #valid formats
#   assert rs_list[1].nil?
#   assert rs_list[3].nil?
#   assert rs_list[4].nil?
#   #invalid formats
#   assert rs_list.compact.size == 2 # two formats are not valid
#
#   v="1999/01/01"
#   rs_list = format_list.map {|fmt|ServersideValidator.validate_date_format_t(fmt, v)}
#   #valid formats
#   assert rs_list[2].nil?
#   assert rs_list[3].nil?
#   assert rs_list[4].nil?
#   #invalid formats
#   assert rs_list.compact.size == 2 # two formats are not valid
#
#   # test invalid formats
#   v="1999/01/32"
#   rs_list =
#     format_list.map{|fmt|ServersideValidator.validate_date_format_t(fmt, v)}
#   assert rs_list.compact.size == 5 # no format is valid format
#
#   v="1999/13/01"
#   rs_list =
#     format_list.map{|fmt|ServersideValidator.validate_date_format_t(fmt, v)}
#   assert rs_list.compact.size == 5 # no format is valid format
#
#   v="0999/01/01"
#   rs_list =
#     format_list.map{|fmt|ServersideValidator.validate_date_format_t(fmt, v)}
#   assert rs_list.compact.size == 5 # no format is valid format
# end
#
#
# def test_validate
#   v_type = ServersideValidator::VALIDATE_TYPE
#
#   #test fields with auto-completer list
#   validate_def = {"gender" => [v_type[:auto_completer],
#       ["Female","Male"]] }
#   data_hash = { "gender_1" => "WrongData"}
#   error = ServersideValidator.validate_t(data_hash, validate_def)
#   assert !error.nil?
#
#   data_hash = { "gender_1" => "Female"}
#   error = ServersideValidator.validate_t(data_hash, validate_def)
#   assert error.nil?
#
#
#   #test calendar fields
#   validate_def = {"when_started" => [v_type[:calendar],
#       ["YYYY/MM/DD",["t-100Y","t"]]]}
#   data_hash = {"when_started_1" => "1999/01/01"}
#   error = ServersideValidator.validate_t(data_hash, validate_def)
#   assert error.nil?
#
#   data_hash = {"when_started_1" => "1999"}
#   error = ServersideValidator.validate_t(data_hash, validate_def)
#   assert !!error
#   assert error.include?("format") # invalid calendar format
#
#   data_hash = {"when_started_1" => "2020/01/01"}
#   error = ServersideValidator.validate_t(data_hash, validate_def)
#   assert !!error
#   assert error.include?("range") # invalid calendar range
# end

 def test_unique_values_by_field
   # Define the user data table model classes
   DbTableDescription.define_user_data_models
   
   form_name = 'phr_index'
   @form = Form.create(:form_name => form_name)
      pid = PredefinedField.create!(:form_builder  => false).id
      db_table = DbTableDescription.find_by_data_table("phrs")
      # insert records for test panels
      # db_table = DbTableDescription.create!(
      #  :data_table => "phrs",
      #  :description => "test table"
      #)
      # panel loinc num
      db_field = DbFieldDescription.create!(
        :db_table_description_id => db_table.id,
        :data_column => "pseudonym",
        :field_type => "ST - string data",
        :predefined_field_id => pid
      )
    #  field = FieldDescription.find_by_form_id_and_target_field(tp.id, "tp_invisible_field_panel_loinc_num")
    #  field.db_field_description_id = db_field.id
    #  field.save!

   # define a field which should have unique value
   fd = FieldDescription.new(
     :form_id => @form.id,
     :target_field => "pseudonym",
     :control_type_detail => "unique_field_value=>true",
     :control_type => "test ct",
     :db_field_description_id => db_field.id,
     :predefined_field_id => pid)
   fd.save!
   
   db_field = DbFieldDescription.create!(
     :db_table_description_id => db_table.id,
     :data_column => "birth_date",
     :field_type => "ST - string data",
     :predefined_field_id => pid,
     :required=>false
   )   
   fd = FieldDescription.create!(
     :form_id=>@form.id,
     :db_field_description_id => db_field.id,
     :target_field => 'birth_date',
     :control_type => 'calendar',
     :predefined_field_id => pid
   )   
   
   # Create the list for the gender field
   tl = TextList.create!(:list_name=>'gender')
   tl.text_list_items << TextListItem.new(:code=>'M', :item_text=>'Male')
   tl.text_list_items << TextListItem.new(:code=>'F', :item_text=>'Female')
   
   # create a user record which has value in the specified field
   @user = create_test_user
   p=Phr.create(
     :profile_id =>@user.profiles.create.id,
     :latest => 1,
     :pseudonym => "howdy",
     :gender_C => 'M',
     :birth_date=>'1950/1/2')
   puts "ServerSideValidatorTest:  profile errors=#{p.errors.full_messages}" if !p.valid?
   
   actual = ServersideValidator.unique_values_by_field(@form.id, @user.id)
   expected = {"pseudonym"=>["howdy"]}
   assert_equal expected, actual
 end
end


