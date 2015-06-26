require 'test_helper'

class FieldDescriptionTest < ActiveSupport::TestCase
  fixtures :field_descriptions
  fixtures :predefined_fields
  fixtures :rule_cases
  fixtures :rule_actions
  fixtures :rules
  fixtures :forms
  fixtures :rules_forms
  TABLES =   ["rule_action_descriptions" ]

  def setup
    @field_desc = FieldDescription.new
    @field_desc.control_type_detail = {
      'search_table'=>'text_list','list_id'=>'6','fields_searched'=>
      ['item_name','item_text'],'fields_returned'=>['red'],
      'fields_displayed'=>['green','blue'],'list_placement'=>'split'}
    @field_desc.list_code_column = 'id'
  end


  def test_default_value_eval
    template = 'timeout = #{SESSION_TIMEOUT}'
    fd = FieldDescription.new(:default_value=>template)
    assert_equal(template, fd.default_value)
    assert_equal("timeout = #{SESSION_TIMEOUT}", fd.default_value_eval)
  end


  def test_list_items
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
      'forms', 'text_lists', 'text_list_items'])
    fd = FieldDescription.find_by_target_field('experimental')
    assert_equal(2, fd.list_items.size)
  end


  # Tests the help_text method
  def test_help_text
    test_file = 'deleteme_test_only'
    test_pn = File.join(HelpText::HELP_DIR, test_file);
    basic_mode_help_file = 'basic_' + test_file
    basic_mode_help_pn = File.join(HelpText::HELP_DIR, basic_mode_help_file)
    # Make sure we don't overwrite something that actually exists
    assert(!File.exists?(test_file))
    assert(!File.exists?(basic_mode_help_pn))

    # Create a field description and test
    fd1 = FieldDescription.new(:help_text=>'asdf')
    assert_equal('asdf', fd1.help_text)
    assert_equal('asdf', fd1.help_text('basic'))
    help_url = File.join(HelpText::REL_HELP_DIR, test_file)
    fd2 = FieldDescription.new(:help_text=>help_url)
    assert_equal(help_url, fd2.help_text)
    assert_equal(help_url, fd2.help_text('basic'))
    # Now create the basic mode help file and see if that gets overridden
    require 'tempfile'
    f = File.new(basic_mode_help_pn, "w"); f.close
    begin
      assert_equal('asdf', fd1.help_text)
      assert_equal('asdf', fd1.help_text('basic'))
      basic_help_url = File.join(HelpText::REL_HELP_DIR, basic_mode_help_file)
      assert_equal(help_url, fd2.help_text)
      assert_equal(basic_help_url, fd2.help_text('basic'))
    ensure
      File.delete(f.path)
    end
  end


  def test_get_date_format_requirements
    @field_desc.control_type_detail['date_format'] = 'YYYY/MM/DD'
    @field_desc.control_type = 'calendar'
    reqs = @field_desc.get_date_format_requirements
    assert(reqs[0]) # month required
    assert(reqs[1]) # day required
    @field_desc.control_type_detail['date_format'] = 'YYYY/MM/[DD]'
    reqs = @field_desc.get_date_format_requirements
    assert(reqs[0]) # month required
    assert(!reqs[1]) # day not required
    @field_desc.control_type_detail['date_format'] = 'YYYY/[MM/[DD]]'
    reqs = @field_desc.get_date_format_requirements
    assert(!reqs[0]) # month not required
    assert(!reqs[1]) # day not required
  end


  # Tests the hidden_field method.
  def test_hidden_field
    assert(field_descriptions(:hidden_field).hidden_field?,
      field_descriptions(:hidden_field).target_field + ' should be hidden')
    assert(!field_descriptions(:non_hidden_field1).hidden_field?,
      field_descriptions(:non_hidden_field1).target_field +
      ' should not be hidden')
    assert(!field_descriptions(:non_hidden_field2).hidden_field?,
      field_descriptions(:non_hidden_field2).target_field +
      ' should not be hidden')
  end


  # Tests the has_id_column method.
  def test_has_id_column
    assert(field_descriptions(:has_id_col1).has_id_column?,
      field_descriptions(:has_id_col1).target_field + ' should have id col')
    assert(field_descriptions(:has_id_col2).has_id_column?,
      field_descriptions(:has_id_col2).target_field +
      ' should have id col')
    assert(!field_descriptions(:no_id_col1).has_id_column?,
      field_descriptions(:no_id_col1).target_field +
      ' should not have id col')
    assert(!field_descriptions(:no_id_col2).has_id_column?,
      field_descriptions(:no_id_col2).target_field +
      ' should not have id col')
  end


  # Test of the fields_searched method.
  def test_fields_searched
    fields = @field_desc.fields_searched
    assert_equal(2, fields.size)
    assert_equal(:item_name, fields[0])
    assert_equal(:item_text, fields[1])
  end
  
  # Test of the fields_returned method.
  def test_fields_returned
    fields = @field_desc.fields_returned
    assert_equal(1, fields.size)
    assert_equal(:red, fields[0])
  end
  
  # Test of the fields_displayed method.
  def test_fields_displayed
    fields = @field_desc.fields_displayed
    assert_equal(2, fields.size)
    assert_equal(:green, fields[0])
    assert_equal(:blue, fields[1])
  end

  def test_hl7_data_type_code
    assert_equal('ST', field_descriptions(:one).hl7_data_type_code)
    assert_nil(field_descriptions(:two).hl7_data_type_code, ':two')
    assert_equal('ST',
      field_descriptions(:phr_drug_strength).hl7_data_type_code,
     'phr_drug_strength')
    assert_equal('ST',
      field_descriptions(:data_hash_table_field).hl7_data_type_code)
  end
  
  def test_field_type
    # Test of a field that has an hl7_data_type_id value
    assert_equal('ST - string data',
      field_descriptions(:data_hash_table_field).field_type)
    # Test of a field that has a field_type value
    assert_equal('NM - numeric',
      field_descriptions(:birth_date).field_type)
    # Test of a field without either
    assert_nil(field_descriptions(:data_hash_table_field2).field_type)
  end

  def test_parse_hash_value
    val = FieldDescription.parse_hash_value(
      'one=>two,three=>(four, five, six),seven=>(eight)')
    assert_equal(3, val.size)
    assert_equal('two', val['one'])
    assert_equal(3, val['three'].size)
    assert_equal('four', val['three'][0])
    assert_equal('five', val['three'][1])
    assert_equal('six', val['three'][2])
    assert_equal(1, val['seven'].size)
    assert_equal('eight', val['seven'][0])
    
    val = FieldDescription.parse_hash_value(
      'one=>two,three=>four')
    assert_equal(2, val.size)
    assert_equal('two', val['one'])
    assert_equal('four', val['three'])
    
    # Test of escapes
    # Remember that inside a string, you have to double the \ characters if it
    # would normally be treated as an escape (so \\\\ is really two \
    # characters.)
    val = FieldDescription.parse_hash_value(
      'one=>two\,three,four=>(five\\\\,six,seven\),eight),nine=>ten\\\\\,eleven')
    assert_equal(3, val.size)
    assert_equal('two,three', val['one'])
    assert_equal(4, val['four'].size)
    assert_equal('five\\', val['four'][0])
    assert_equal('six', val['four'][1])
    assert_equal('seven)', val['four'][2])
    assert_equal('eight', val['four'][3])
    assert_equal('ten\,eleven', val['nine']) # two backslashes
    
    # Test of the new hash map parameter.
    val = FieldDescription.parse_hash_value(
      'one=>two,three=>{four=>five,six=>seven},eight=>nine')
    assert_equal(3, val.size, 'hash map parameter test')
    assert_equal('two', val['one'])
    assert_equal('nine', val['eight'])
    assert(val['three'])
    assert_equal(2, val['three'].size, 'size of hash map parameter')
    assert_equal('five', val['three']['four'])
    assert_equal('seven', val['three']['six'])
    
    # Test that the last character can be an escaped comma
    val = FieldDescription.parse_hash_value('one=>two\\,')
    assert_equal(1, val.size)
    assert_equal('two\\,', val['one'])
    
  end
  
  # Test the change_target_field method
  def test_change_target_field
    DatabaseMethod.copy_development_tables_to_test(TABLES, false)
    forms[0] = forms(:one)
    RuleAction.populate_actions_cache
    FieldDescription.change_target_field('to_be_changed', 'has_been_changed')
  
    assert_equal('has_been_changed', 
          field_descriptions(:target_field_to_change).target_field,
          'field_descriptions.target_field - target_field_to_change') 
    assert_equal({'not_changed'=>true}, 
          field_descriptions(:target_field_to_change).control_type_detail,
          'field_descriptions.control_type_detail - target_field_to_change')
          
    assert_equal('no_change', 
          field_descriptions(:control_detail_at_beginning).target_field,
          'field_descriptions.target_field - control_detail_at_beginning')
    exp = {'search_table'=>'drug_name_routes','has_been_changed'=>'at_start',
      'list_details_id'=>1000,'superfluous_parameter'=>'at_end'}
    assert_equal(exp,
          field_descriptions(:control_detail_at_beginning).control_type_detail,
          'field_descriptions.control_type_detail - ' + 'control_detail_at_beginning')         
                 
    assert_equal('no_change', 
          field_descriptions(:control_detail_at_end).target_field,
          'field_descriptions.target_field - control_detail_at_end')   
    assert_equal({'superfluous_parameter'=>'at_start','has_been_changed'=>'at_end'}, 
          field_descriptions(:control_detail_at_end).control_type_detail,
          'field_descriptions.control_type_detail - control_detail_at_end') 
          
    assert_equal('no_change', 
          field_descriptions(:control_detail_in_middle).target_field,
          'field_descriptions.target_field - control_detail_in_middle') 
    assert_equal(FieldDescription.parse_hash_value('superfluous_parameter=>at_start,has_been_changed=>in_middle' +
                 ',more_superfluidity=>at_end'), 
          field_descriptions(:control_detail_in_middle).control_type_detail,
          'field_descriptions.control_type_detail = control_detail_in_middle') 
                 
    assert_equal('has_been_changed', 
          field_descriptions(:target_and_control).target_field,
          'field_descriptions.target_field - target_and_control')
    assert_equal(FieldDescription.parse_hash_value('has_been_changed=>with_target_field'), 
          field_descriptions(:target_and_control).control_type_detail,
          'field_descriptions.control_type_detail - target_and_control') 
                  
    assert_equal("has_been_changed='true'", 
          rule_cases(:change_case_expression).case_expression,
          'rule_cases.case_expression - change_case_expression')
    assert_equal('no_change+30', 
          rule_cases(:change_case_expression).computed_value,
          'rule_cases.computed_value - change_case_expression')                  
                  
    assert_equal("no_change='true'", 
          rule_cases(:change_computed_value).case_expression,
          'rule_cases.case_expression - change_computed_value')
    assert_equal('has_been_changed+30', 
          rule_cases(:change_computed_value).computed_value,
          'rule_cases.computed_value - change_computed_value')                  
                                   
    assert_equal("has_been_changed='true'", 
          rule_cases(:change_both).case_expression,
          'rule_cases.case_expression - change_both')
    assert_equal('has_been_changed+30', 
          rule_cases(:change_both).computed_value,
          'rule_cases.computed_valuel - change_both')                  

    assert_equal('value=>has_been_changed', 
          rule_actions(:change_parameters).parameters,
          'rule_actions.parameters - change_parameters')
    assert_equal('no_change', 
          rule_actions(:change_parameters).affected_field,
          'rule_actions.affected_field - change_parameters')                  
                  
    assert_equal('value=>no_change', 
          rule_actions(:change_affected_field).parameters,
          'rule_actions.parameters - change_affected_field')
    assert_equal('has_been_changed', 
          rule_actions(:change_affected_field).affected_field,
          'rule_actions.affected_field - change_affected_field')                  
                                   
    assert_equal('value=>has_been_changed', 
          rule_actions(:change_both).parameters,
          'rule_actions.parameters - change_both')
    assert_equal('has_been_changed', 
          rule_actions(:change_both).affected_field,
          'rule_actions.affected_field - change_both')                  

    assert_equal("has_been_changed='true'", 
          rules(:change_target_case_rule).expression,
          'rules.expression - change_target_case_rule')
    assert_equal("has_been_changed='true'", 
          rules(:change_target_not_case_rule).expression,
          'rules.expression - change_target_not_case_rule')            
  end
  
  # Test the validity checking for predefined_field_id and field_type
  def test_validate
    new_id1 = FieldDescription.create(
                   :display_name => 'Missing target_field',
                   :control_type => 'text_field1',
                   :predefined_field_id =>predefined_fields(:one).id)
    assert(new_id1.errors[:target_field].length > 0)
    assert_equal('ST - string data', new_id1.field_type)
    
    new_id2 = FieldDescription.create(
                    :display_name => 'Missing control_type',
                    :target_field => 'targ_field_val2',
                    :predefined_field_id => predefined_fields(:two).id)
    assert(new_id2.errors[:control_type].length > 0)
    
    new_id3 = FieldDescription.create(
                    :display_name => 'Missing predefined_field_id',
                    :target_field => 'targ_field_val3',
                    :control_type => 'text_field2')
    assert(new_id3.errors[:predefined_field_id].length > 0)
    
    new_id4 = FieldDescription.create(
                    :display_name => 'Missing everything')
    assert(new_id4.errors[:target_field].length > 0)
    assert(new_id4.errors[:control_type].length > 0)
    assert(new_id4.errors[:predefined_field_id].length > 0)

    # new target_field should not conflict with existing rule names
    f = forms(:one)
    r = f.rules.first
    fd = FieldDescription.new(:form_id=>f.id, :control_type => "text_field",
      :predefined_field_id => predefined_fields(:one).id)
    fd.target_field = r.name
    assert !fd.valid?
    assert fd.errors.full_messages[0],
           "Target field must not conflict with rule name"
    fd.target_field = "abc_#{Time.now.to_i}"
    assert fd.valid?

    fetch_rule_name = "testing_fetchrule_#{Time.now.to_i}"
    fr = Rule.create(:rule_type => Rule::FETCH_RULE,
      :name => fetch_rule_name)
    fd.target_field = fetch_rule_name
    assert !fd.valid?
    assert fd.errors.full_messages[0],
           "Target field must not conflict with rule name"
    fd.target_field = "abc_#{Time.now.to_i}"
    assert fd.valid?

  end # test_validate
  
  
  # This method tests the remove_param method.  It tests removal of 
  # parameters with three types of values:  a string value, an array
  # value, and a hash value..
  #
  # This method uses the phr_drug_name field_description object defined
  # in field_descriptions.yml.
  #
  # This method also tests, indirectly, the rewrite_ctd method
  #
  def test_remove_param
    test_field = field_descriptions(:one)
    dri = {'one'=>'two','three'=>'four'}
           
    # test removal of a parameter with a string value 
    test_field.remove_param('no_button')
    assert_equal('drug_name_routes', test_field.getParam('search_table'))
    assert_equal(['text'], test_field.getParam('fields_searched'))
    assert_equal(['text'], test_field.getParam('fields_displayed'))
    assert_equal(dri, test_field.getParam('data_req_input'))
    assert_equal(1, test_field.getParam('auto'))
    assert_nil(test_field.getParam('no_button'))
    
    # test removal of a parameter with an array value
    test_field.remove_param('fields_displayed')
    assert_equal('drug_name_routes', test_field.getParam('search_table'))
    assert_equal(['text'], test_field.getParam('fields_searched'))
    assert_nil(test_field.getParam('fields_displayed'))
    assert_equal(dri, test_field.getParam('data_req_input'))
    assert_equal(1, test_field.getParam('auto'))
    assert_nil(test_field.getParam('no_button'))
      
    # test removal of a parameter with a hash value
    test_field.remove_param('data_req_input')
    assert_equal('drug_name_routes', test_field.getParam('search_table'))
    assert_equal(['text'], test_field.getParam('fields_searched'))
    assert_nil(test_field.getParam('fields_displayed'))
    assert_nil(test_field.getParam('data_req_input'))
    assert_equal(1, test_field.getParam('auto'))
    assert_nil(test_field.getParam('no_button'))
   
  end # test_remove_param
  
  
  # This method tests the add_param method.  It tests addition of 
  # parameters with three types of values:  a string value, an array
  # value, and a hash value.
  #
  # This method uses the two field_description object defined
  # in field_descriptions.yml.
  #
  # This method also tests, indirectly, the rewrite_ctd method
  #
  def test_add_param
  
    field_two = field_descriptions(:two)
    field_two.target_field = 'a target field value'
    field_two.predefined_field_id = 1
    field_two.control_type = 'text_field'
    
    # test addition of a parameter with a string value 
    field_two.add_param('search_table', 'drug_name_routes')
    assert_equal('drug_name_routes', field_two.getParam('search_table'))
    
    # test addition of a parameter with an array value
    field_two.add_param('fields_displayed', ['text','code'])
    assert_equal('drug_name_routes', field_two.getParam('search_table'))
    assert_equal(['text', 'code'], field_two.getParam('fields_displayed'))

    # test addition of a parameter with a hash value
    dro = {'strength_form_list' => 'strength_and_form',
           'code' => 'drug_code' , 
           'patient_route' => 'route',
           'id' => 'drug_name_route_id'}
    field_two.add_param('data_req_output', dro)
    assert_equal('drug_name_routes', field_two.getParam('search_table'))
    assert_equal(['text', 'code'], field_two.getParam('fields_displayed'))
    assert_equal(dro, field_two.getParam('data_req_output'))                              

  end # test_add_param

  def test_complete_label_name
    field_one = field_descriptions(:one)
    field_one.group_header_id = field_descriptions(:form_one_group_hdr).id
    assert_equal(field_one.display_name, "First Name")
    assert_equal(field_one.complete_label_name, "I'm a group header >> First Name")
  end

  # Tests the getting and setting of data req output
  def test_data_req_output
    # Test a field description that has a non-nil value
    fd = field_descriptions(:phr_drug_strength)
    dro = fd.data_req_output
    assert_equal({"amount_list"=>["dose"], "rxcui"=>["rxcui"]}, dro)

    # Try changing it.
    fd.data_req_output = {3=>4}
    assert_equal({3=>4}, fd.data_req_output)

    # Test a field description that does not have a data req output.
    dro = field_descriptions(:one).data_req_output
    assert_nil(dro)
  end
  
  
  # Tests the retrieving of validations definitions for the form field
  def test_get_validation
    f= Form.create(:form_name => Time.now.to_i)
    fld = f.field_descriptions.create( :target_field=>Time.now.to_i.to_s, 
      :control_type => "text_field")
    db_table = DbTableDescription.new(data_table: Time.now.to_i.to_s)
    db_table.save!
    pf = PredefinedField.new(:form_builder=>true, :rails_data_type =>"string")
    pf.save!
    db_field = db_table.db_field_descriptions.build(:predefined_field_id => pf.id)
    db_field.save!
    
    # xss validation
    fld.db_field_description_id = db_field.id # fld.db_field_description is not nil
    fld.predefined_field_id = pf.id # make sure fld.rails_data_type is a string
    fld.save!

    type = "xss"
    actual = fld.get_validation(type).inspect
    expected = [type].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly when the input is #{type}"    
    fld.db_field_description = nil # turn fld.db_field_description to nil   
    fld.save!
    actual = fld.get_validation(type) # xss validation is not needed
    assert_nil actual
    
    # regex validation
    type="regex"
    code = "abcde"
    rv= RegexValidator.create!(:code => code)
    fld.regex_validator_id = rv.id
    fld.save!
    actual = fld.get_validation(type).inspect  
    expected = [type, code].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly when the input is #{type}"    
    fld.regex_validator_id = nil
    fld.save!
    actual = fld.get_validation(type) 
    assert_nil actual
    
    # date field validation
    type = "date"
    date_format, epoch_point="yyyy/mm/dd", "xxx"
    fld.control_type_detail = {"date_format"=>date_format, "epoch_point"=>epoch_point}
    fld.control_type = "calendar"
    fld.save!
    actual = fld.get_validation(type).inspect     
    expected = [type, date_format, epoch_point].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly when the input is #{type}"    
    fld.control_type = "anything"
    fld.save!
    actual = fld.get_validation(type)
    assert_nil actual
    
    # time field validation
    type = "time"
    fld.control_type = "time_field"
    fld.save!
    actual = fld.get_validation(type).inspect     
    expected = [type].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly when the input is #{type}"    
    fld.control_type = "anything"
    fld.save!
    actual = fld.get_validation(type)
    assert_nil actual
    
    # abs_range field validation
    type = "abs_range"
    max, min = 222, 22
    fld.control_type_detail = {"abs_max" => max, "abs_min" => min}
    fld.save!
    actual = fld.get_validation(type).inspect     
    expected=[type, max, min].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly when the input is #{type}"    
    fld.control_type_detail = nil
    fld.save!
    actual = fld.get_validation(type)     
    assert_nil actual
    
    # date_range field validation
    type = "date_range"    
    max, min=222, 22
    min_msg="date range error (min)"
    max_msg="date range error (max)"
    display_name = "date range display_name"
    fld.control_type_detail = {"abs_max" => max, "abs_min" => min}
    fld.min_err_msg=min_msg
    fld.max_err_msg=max_msg
    fld.display_name=display_name
    fld.save!
    actual = fld.get_validation(type).inspect     
    expected = [type, display_name, min, max, min_msg, max_msg].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly when the input is #{type}"    
    fld.control_type_detail = nil
    fld.save!
    actual = fld.get_validation(type)
    assert_nil actual
    
    # field has unique value 
    type = "uniqueness"
    fld.update_controls("unique_field_value", true)
    fld.save!
    actual = fld.get_validation(type).inspect     
    expected = [type].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly when the input is #{type}"    
    fld.control_type_detail= nil
    fld.save!
    actual = fld.get_validation(type)
    assert_nil actual
    
    # required field validation
    type = "required"
    fld.required = true
    fld.group_header_id = nil
    fld.save!
    actual = fld.get_validation(type).inspect     
    expected = [type, "common"].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly on common required field"    
    # create normal line parent
    gpf = PredefinedField.create!(:form_builder=>true, :rails_data_type =>"label")
    gfld = f.field_descriptions.build( :target_field=>fld.target_field + "1",       
      :predefined_field_id => gpf.id)
    gfld.control_type = "group_hdr"
    gfld.control_type_detail={"orientation" => "horizontal"}
    gfld.save!
    # create a sibling field
    sfld = f.field_descriptions.create!( :target_field=>fld.target_field + "2", 
      :control_type => "text_field", :predefined_field_id => gpf.id)
    fld.group_header=gfld
    fld.save!
    actual = fld.get_validation(type).inspect     
    expected = [type, "normalLine"].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly on normaline required field"    
    
    # password validation
    type = "password"
    fld.control_type = "password_field"
    ctd = fld.control_type_detail || {}
    ctd["password"] = true
    fld.control_type_detail = ctd
    fld.save!
    actual = fld.get_validation(type).inspect     
    expected = [type].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly when the input is #{type}"    
    fld.control_type = "non_password_field"
    fld.save!
    actual = fld.get_validation(type)    
    assert_nil actual
    
    # confirmation field validation
    type = "confirmation"
    master_field = "master_field_123"
    fld.control_type_detail = { type => master_field}
    fld.save!
    actual = fld.get_validation(type).inspect     
    expected = [type, master_field].inspect
    assert_equal expected, actual,    
      "The get_validation function does not working correctly when the input is #{type}"    
    fld.control_type_detail = nil 
    fld.save!
    actual = fld.get_validation(type)    
    assert_nil actual    
    
  end
end
