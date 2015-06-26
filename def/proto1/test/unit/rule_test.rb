require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  fixtures :rules
  fixtures :rule_actions
  fixtures :rule_dependencies
  fixtures :rules_forms
  fixtures :rule_cases
  fixtures :field_descriptions
  fixtures :forms
  fixtures :loinc_items
  fixtures :predefined_fields

  def test_complete_rule_list
    complete_list = Rule.complete_rule_list([rules(:d)])
    expected_list = [rules(:d), rules(:c), rules(:a), rules(:b)]
    assert_equal(expected_list, complete_list, "test 1")

    # Try adding another rule that depends on :d
    complete_list = Rule.complete_rule_list([rules(:d), rules(:c)])
    assert_equal(expected_list, complete_list, "test 2")

    # Try passing in the rules in a different order.
    complete_list = Rule.complete_rule_list([rules(:c), rules(:d)])
    assert_equal(expected_list, complete_list, "test 3")

    # Try passing in just :a
    complete_list = Rule.complete_rule_list([rules(:a)])
    assert_equal([rules(:a), rules(:b)], complete_list, 'test 4')

    # Try passing in just :b
    complete_list = Rule.complete_rule_list([rules(:b)])
    assert_equal([rules(:b)], complete_list, 'test 5')
  end

  def test_used_by_rules
    # Check that c is used by a and b.  Use sets to avoid checking the order
    # of these rules, which in this case we don't care about.
    assert_equal(Set.new.merge([rules(:a), rules(:b)]),
      Set.new.merge(rules(:c).used_by_rules))
  end

  def test_uses_rules
    # Check that a uses c and d.  Use sets to avoid checking the order
    # of these rules, which in this case we don't care about.
    assert_equal(Set.new.merge([rules(:c), rules(:d)]),
      Set.new.merge(rules(:a).uses_rules))
  end

  def test_depends_on_rule
    # Check that b depends on d
    assert(rules(:b).depends_on_rule?('d'))

    # Check that d doesn't depend on b
    assert(!rules(:d).depends_on_rule?('b'))
  end

  def test_delete
    # Check that a rule that is used by another can't be deleted.
    assert_raise(RuntimeError) {Rule.delete('a')}

    # Check that a rule that isn't used by another can be deleted.
    Rule.delete('b')
  end

  def test_update_rule
    b_rule = Rule.find_by_name('b')
    assert_not_nil(b_rule)
    assert_equal(2, b_rule.uses_rules.size, 'rule size')
    b_rule = Rule.update_rule('b', 'd+first_name')
    assert(b_rule.errors.empty?)
    assert_equal(1, b_rule.uses_rules.size, 'rule size')
    assert_equal('d', b_rule.uses_rules[0].name)
    assert_equal(1, b_rule.field_descriptions.size, 'field desc size')
    assert_equal('first_name', b_rule.field_descriptions[0].target_field)
  end


  # Tests validations that aren't checked elsewhere
  def test_validate
    # Check that a rule name cannot contain a '.'
    rule = Rule.new(:name=>'abc.d', :expression=>'1+2')
    rule.forms << forms(:one)
    rule.save
    assert(rule.errors[:name].length > 0)

    # Check that a rule cannot have two cases with the same sequence number,
    # and that the first case expression (if there are two) cannot be blank.
    rule = Rule.new(:name=>'mytest', :rule_type=>Rule::CASE_RULE)
    rule.forms << forms(:two)
    assert(rule.js_function.blank?) # we don't have any cases yet
    rule.save!
    rule_case1 = RuleCase.create(:rule_id=>rule.id, :sequence_num=>1,
      :case_expression=>'', :computed_value=>'20')
    rule.rule_cases << rule_case1
    rule_case2 = RuleCase.create(:rule_id=>rule.id, :sequence_num=>1,
      :case_expression=>'', :computed_value=>'20')
    rule.rule_cases << rule_case2
    rule.save
    assert(rule_case1.errors[:case_expression].length > 0)
    assert(rule_case2.errors[:order].length > 0)
    # Data rule name should not conflict with any target field
    r = Rule.new(:name => FieldDescription.first.target_field,
      :rule_type => Rule::FETCH_RULE)
    assert !r.valid?
    assert r.errors.full_messages[0],
           "Rule name must not conflict with any target field."
    
    # Check fetch rule can not have uses_rules
#    rule = Rule.add_new_rule("test_fetch_rule", nil, forms(:one), "fetch")
#    rule.uses_rules << rule(:a)
#    assert !rule.valid?
#    expected = ""
#    actual = rule.errors.messages.join
#    assert actual, expected
  end


  def test_build_case_rule_function
    case_rule = rules(:case_rule_one)
    # Add a RuleCase, to test that build_case_rule_function correctly
    # sorts newly added (or revised) cases when creating the JavaScript.
    new_case = RuleCase.create(:rule_id=>case_rule.id, :sequence_num=>2,
      :case_expression=>'birth_date>1950', :computed_value=>'hcl+20')
    # new_case should have id 3 (because according to the fixtures file, the
    # last id is 2)
    case_rule.rule_cases << new_case

    js_function, ref_fields, ref_rules = case_rule.build_case_rule_function
    expected =<<END_EXP_JS
Def.Rules.rule_case_rule_one = function(prefix, suffix) {
  var depFieldIndex = 0;
  var selectedOrderNum = null;
  var exclusion = 5>2;
  if (!exclusion) {
    var birth_date_field_val = parseFieldVal(selectField(prefix,'birth_date',suffix,depFieldIndex, true));
    if (birth_date_field_val>1920) {
      selectedOrderNum = 1;
    }
    else {
      if (birth_date_field_val>1950) {
        selectedOrderNum = 2;
      }
      else {
        selectedOrderNum = 3;
      }
    }
  }
  return this.processCaseActions('case_rule_one', [1,2,3], selectedOrderNum, prefix, suffix, null);
}

Def.Rules.ruleCaseVal_case_rule_one_1 = function(prefix, suffix, depFieldIndex) {
  var hcl_field_val = parseFieldVal(selectField(prefix,'hcl',suffix,depFieldIndex, true));
  return hcl_field_val+30;
}

Def.Rules.ruleCaseVal_case_rule_one_2 = function(prefix, suffix, depFieldIndex) {
  var hcl_field_val = parseFieldVal(selectField(prefix,'hcl',suffix,depFieldIndex, true));
  return hcl_field_val+20;
}

Def.Rules.ruleCaseVal_case_rule_one_3 = function(prefix, suffix, depFieldIndex) {
  var hcl_field_val = parseFieldVal(selectField(prefix,'hcl',suffix,depFieldIndex, true));
  return Math.log(hcl_field_val);
}
END_EXP_JS
    assert_equal(expected, js_function)
  end


  def test_build_expression_function
    # Test a case statement.
    rule_expression="case a=2: 5 case 1<=1 and 2!=3: strength_and_form+2"
    expected =<<END_EXP_CASE
Def.Rules.rule_case_test = function(prefix, suffix, depFieldIndex) {
  var a_rule_val = function(){ return Def.Rules.Cache.getRuleVal('a');};
  var strength_and_form_field_val = parseFieldVal(selectField(prefix,'strength_and_form',suffix,depFieldIndex, true));
  var case_val=null;
  switch(true) {
  case a_rule_val()==2: case_val = 5     break;
  case 1<=1 && 2!=3: case_val = strength_and_form_field_val+2
    break;
  default:
    throw new Def.Rules.Exceptions.NoVal();
  }
  return case_val;
}
END_EXP_CASE

    test_form_id = forms(:data_hash_from_params_test).id
    assert_equal(expected, Rule.build_expression_function('case_test',
        rule_expression, test_form_id)[0])

    # Test a math statement
     expected = "Def.Rules.rule_exp_test = function(prefix, suffix, depFieldIndex) {\n"+
      "  return Math.log(5);\n}\n"
    assert_equal(expected,
      Rule.build_expression_function('exp_test', 'log(5)', test_form_id)[0])

    # Test a column_contains statement.
    crule = Rule.build_expression_function('col_test',
      'column_contains(table_field, "hi")', test_form_id)
    expected = <<END_EXP_CASE2
Def.Rules.rule_col_test = function(prefix, suffix, depFieldIndex) {
  return Def.FieldOps.column_contains(selectField(prefix,'table_field',suffix,depFieldIndex, true).id,'', "hi");
}
END_EXP_CASE2

    assert_equal(expected, crule[0])

    crule = Rule.build_expression_function('latest_value_f',
      'latest_from_form(blo_sybp, "blo_test_date")', '')
    expected = <<END_EXP_CASE2
Def.Rules.rule_latest_value_f = function(prefix, suffix, depFieldIndex) {
  return Def.FieldOps.latest_from_form(selectField(prefix,'blo_sybp',suffix,depFieldIndex, true).id,'', "blo_test_date");
}
END_EXP_CASE2

    assert_equal(expected, crule[0])

    # Test a has_list statement.
    crule = Rule.build_expression_function('has_list_test',
      'has_list(table_field, "hi")', test_form_id)
    assert_not_nil(crule)

  end


  # Test that you can't add a rule name that already exists on the same form or
  # some different forms
  def test_add_dup_rule
    rule = Rule.add_new_rule('a', '1+2', forms(:one).id)
    assert(!rule.errors.empty?) # i.e., there were errors
    rule = Rule.add_new_rule('a', '1+2', forms(:rules).id)  # different form
    assert(!rule.errors.empty?) # i.e., there were errors too
  end


  # Tests the data_hash_for_rule_form method
  def test_data_hash_for_rule_form
    dh = Rule.data_hash_for_rule_form(forms(:one))
    assert_equal(3, dh.size)
    rule_table = dh['general_rules']
    assert_not_nil(rule_table)
    assert_equal(5, rule_table.size) # 4 rules and 2 actions for same rule
    form_rules = forms(:one).rules
    # Only consider general rules
    form_rules = form_rules.select{|r| r.rule_type== Rule::GENERAL_RULE}
    num_rows = rule_table.size
    row_index = 0;  # index in rule_table
    rule_index = 0;  # index in form_rules
    while(row_index < num_rows)
      row = rule_table[row_index]
      r = form_rules[rule_index]
      num_fields_in_row = r.rule_actions.size>0 ? 6 : 4
      assert_equal(num_fields_in_row, row.size)
      assert_equal("#{r.id};edit", row['edit_general_rule'])
      assert_equal("#{r.id}", row['delete_general_rule'])
      assert_equal(r.name, row['rule_name_ro'])
      assert_equal(r.expression, row['rule_expression_ro'])
      action_index = 0
      num_actions = r.rule_actions.size
      while (action_index < num_actions)
        if (action_index>0)
          # This is not the first iteration.  Get the next row.
          row_index += 1
          row = rule_table[row_index]
          assert_equal(2, row.size)
        end
        ra = r.rule_actions[action_index]
        assert_equal(ra.action, row['rule_action_ro'])
        assert_equal(ra.affected_field, row['rule_affected_field_ro'])
        action_index += 1
      end
      rule_index += 1
      row_index += 1
    end

    assert_not_nil(dh['case_rules'])
    case_table = dh['case_rules']
    assert_equal(1, case_table.size)
    row = case_table[0]
    assert_not_nil(row['case_rule_name'])
    assert_not_nil(row['case_rule_summary'])
  end


  def test_data_hash_for_general_edit_page
    # Confirm that we return the hash for the right rule.
    r = rules(:b)
    h = r.data_hash_for_general_edit_page([])

    assert_equal('b', h['rule_name'])

    # Confirm that we have actions
    action_table = h['rule_actions']
    assert_not_nil(action_table)
    assert_equal(2, action_table.size)

    # Confirm that the IDs for the actions are present.
    assert_not_nil(action_table[0]['rule_action_id'])

    # Now test for the case were we pass in some submitted rule data
    rule_data =  {"rule_name"=>"hide_colon_header",
      "rule_actions"=>[{"rule_action_id"=>"1", "rule_action_parameters"=>"",
          "affected_field"=>"colon_header",
          "rule_action_name"=>"hide"}],
      "rule_expression"=>"age < 50 +2"}
    h = r.data_hash_for_general_edit_page([], rule_data)

    # Confirm that we have actions
    action_table = h['rule_actions']
    assert_not_nil(action_table)
    assert_equal(1, action_table.size)

    # Confirm that the IDs for the actions are present.
    assert_not_nil(action_table[0]['rule_action_id'])

    # Confirm that we have expression help
    assert_not_nil(h['expression_help'])
  end


  def test_data_hash_for_new_general_rule_page
    h = Rule.data_hash_for_new_general_rule_page(forms(:one))

    assert_equal('Hash', h.class.name)
    assert_not_nil(h['expression_help'])
  end



  def test_common_expression_fields
    form_list = [forms(:shared_fields_one), forms(:shared_fields_two)]
    common_fields = Rule.common_expression_fields(form_list)
    assert_equal(2, common_fields.size)
    s = Set.new(common_fields)
    assert(s.member?('shared_a'))
    assert(s.member?('shared_c'))
  end


  def test_allowed_expression_rules
    r = rules(:c)
    allowed = Rule.allowed_expression_rules(r.forms, r.name)
    assert_equal(1, allowed.size)
    assert_equal('d', allowed[0]);
  end


  def test_update_rule
    r= rules(:a)
    expression_before_save = r.expression + " AND name in blah_set"
    r.expression = expression_before_save
    r.save

    assert_equal expression_before_save, r.expression
  end

  def test_equal_sign_conversion
    r= rules(:a)
    expression_before_save = "12 =< 23 AND 30 >= 29"
    r.expression = expression_before_save
    r.save
    assert r.js_function.include? expression_before_save.gsub("AND", "&&")

    expression_before_save = "8 = 8"
    r.expression = expression_before_save
    r.save
    assert r.js_function.include? expression_before_save.gsub("=","==")
  end


  def test_process_expression
    form_id = forms(:shared_fields_two).id

    test_input_list =[
      ["Quotes may not be escaped outside of strings", "\\\" ''"],
      ["Quoted strings must be terminated", "'"]]
    test_input_list.each do |test|
      raise_msg, test_expression = test
      assert_raise_message RuntimeError, /#{raise_msg}/ do
        Rule.process_expression(test_expression, form_id)
      end
    end
  end

  # List of rule functions which are available in rule creating/editing
  def test_rule_functions_availability
    rule_functions =
      ['today', 'time_in_years', 'index_of',
        'intersect_with_set', 'extract_values_from_fields',
        'get_drug_set',
        'find_month','find_year','is_blank', 'to_date','years_elapsed_since']
    rule_functions.each do |e|
      r = Rule.new(
        :name => "testing_rule_#{Time.now.to_i.to_s}",
        :expression => "#{e}()",
        :forms => [forms(:one)])
      assert r.valid?
    end
  end

  # List of fieldOps functions which are available in rule creating/editing
  def test_field_ops_functions_availability
    # non test panel part
    field_ops_functions = 'column_max|column_blank|column_contains|'+
      'latest_from_table|has_list|latest_from_form|field_blank|select_fields'+
      "|field_length|latest_with_conditions|column_conditions"
      
    field_ops_functions.split('|').each do |e|
      target_field = "first_name"
      r = Rule.new(
        :name => "testing_rule_#{Time.now.to_i.to_s}",
        :expression => "#{e}(#{target_field},'')",
        :forms => [forms(:one)])
      assert(r.valid?, "Failed for function #{e}")
      # column_conditions() function has different parameters then other
      # functions in fieldOps.js
      e != "column_conditions" ?
        assert(r.js_function.include?("#{e}(selectField(prefix")) :
        assert(r.js_function.include?("#{e}(prefix, suffix, '#{target_field}'"))

      target_field = "wrong_target_field_name"
      r = Rule.new(
        :name => "testing_rule_#{Time.now.to_i.to_s}",
        :expression => "#{e}(#{target_field},'')",
        :forms => [forms(:one)])
      assert(!r.valid?, "Failed for function #{e}")
    end
    # test panel part, please see "test_rule_parser_for_test_panel_rules"
  end

  def test_rule_parser
    #rule name can not be the same as any target_field in the same form
    tf_name = "foo090505"
    fm = forms(:shared_fields_two)
    tfield_1 = FieldDescription.create(
      :control_type => "",
      :predefined_field => PredefinedField.first,
      :target_field => tf_name
    )
    fm.field_descriptions << tfield_1

    r = Rule.new(
      :expression =>"2 > 1",
      :name => tfield_1.target_field,
      :forms => [fm])
    r.save
    assert !r.errors.empty?
    err_msg = "Rule name *#{tf_name}* can not be the same as any "+
      "target_field in the same form"
    assert_equal r.errors.full_messages.join, err_msg

    # rule expression can not have un-balanced parentheses
    balanced_parentheses = "(1<2 AND (1<2) AND (1<2 AND ( 1<2)))"
    r = Rule.new(
      :expression => balanced_parentheses + ")",
      :name => "test_unbalanced_parentheses_in_rule_expression",
      :forms => [fm])
    r.save
    assert !r.errors.empty?
    err_msg = "parentheses not balanced"
    assert r.errors.full_messages.join.include?(err_msg)
  end

  def test_rule_parser_for_test_panel_rules
    @rule_name_saved_1 = "rule_saved_001"
    @suffix = Rule::LOINC_FUNC_SUFFIX

    @loinc_num_1 ="8480-6"
    @loinc_field_1 ="tp_test_value"
    @loinc_panel_field_1 ="tp_panel_testdate"

    test_form = forms(:shared_fields_two)
    # Should be able to create rule as expected
    @expression = "getVal_#{@suffix}(#{@loinc_num_1}, #{@loinc_field_1})"
    @rule_forms = [test_form]
    expected = "Def.Rules.rule_#{@rule_name_saved_1} = "+
      "function(prefix, suffix, depFieldIndex) {\n"+
      "  return "+
      "Def.FieldOps.getVal_#{@suffix}(prefix, suffix, '#{@loinc_num_1}',"+
      "'#{@loinc_field_1}');\n}\n"

    r = Rule.new(
      :expression =>@expression,
      :name => @rule_name_saved_1,
      :forms => [test_form])
    r.save
    assert r.errors.empty?
    assert r.expression == @expression
    assert r.name == @rule_name_saved_1
    assert r.forms == @rule_forms
    assert_equal r.js_function, expected

    # Should has no uses_rules
    assert r.uses_rules == []

    # Should have all loinc_field_rules saved properly so that we will know the
    # list of rules which can be triggered by a loinc field
    # (association amony rules, field descriptions and loinc items)
    expected = []
    expected <<  ["rule:#{@rule_name_saved_1}","loinc:#{@loinc_num_1}",
      "field:#{@loinc_field_1}"].join(" | ")
 
    actual= r.loinc_field_rules.map(&:display_name)
    assert_equal  expected, actual 

    # Input validation on loinc function name, loinc number, target field
    # Check wrong loinc suffix
    @rule_name_unsaved = "rule_unsaved"
    @wrong_loinc_func_suffix = "wrong_loinc_function_suffix"
    r = Rule.new(
      :expression =>"getVal_#{@wrong_loinc_func_suffix}(#{@loinc_num_1}, "+
        "#{@loinc_field_1})",
      :name => @rule_name_unsaved)
    r.forms = [test_form]
    r.save
    expected = ["Rule expression  - Target field ",
     "getVal_#{@wrong_loinc_func_suffix} does not exist on "+
      "form #{test_form.id}"].join()
    actual = r.errors.full_messages.join()
    assert_equal  expected, actual 
    assert !r.errors.empty?

    # Check wrong loinc number
    @wrong_loinc_number ="wrong-loinc-number"
    r = Rule.new(
      :expression =>"getVal_#{@suffix}(#{@wrong_loinc_number}, #{@loinc_field_1})",
      :name => @rule_name_unsaved)
    r.forms = [test_form]
    r.save
    expected = ["Rule expression  ",
      "- The loinc number: #{@wrong_loinc_number} is not valid!!"].join
    actual = r.errors.full_messages[0]
    assert_equal  expected, actual 
    assert !r.errors.empty?

    #Check wrong target field
    @wrong_target_field ="wrong_target_field"
    r = Rule.new(
      :expression =>"getVal_#{@suffix}(#{@loinc_num_1}, "+
        "#{@wrong_target_field})",
      :name => @rule_name_unsaved)
    r.forms = [test_form]
    r.save
    expected = ["Rule expression  - Target field ",
     "#{@wrong_target_field} does not exist on form #{test_form.id}"].join
    actual = r.errors.full_messages.join
    assert_equal  expected, actual 
    assert !r.errors.empty?
  end

  def test_class_variable_boolean_ops
    fm = Form.last
    r = Rule.create(:name => "boolean_op_false",:expression => "FALSE",
      :forms => [fm])
    assert r.errors.empty?

    r = Rule.create(:name => "boolean_ops_true",:expression => "TRUE",
      :forms => [fm])
    assert r.errors.empty?
  end
  
  def test_column_conditions_function

  end

  # Calendar field will no longer be converted into epoch time in the rule parse
  # as used to be
  def test_calendar_field_parser
    fm = Form.last
    target_field = "abc"
    fld = FieldDescription.new
    
#    fld = FieldDescription.create!(
    fld[:control_type] = "calendar"
    fld[:predefined_field_id] = PredefinedField.first.id
    fld[:target_field] = target_field
    fld[:form_id] = fm.id
    #fm.field_descriptions << fld
    fld.save!

    r = Rule.new
    r[:name] = "calendar_field_parser"
    r[:expression] = "#{target_field}"
    r.forms = [fm]
    r.save!
    assert !r.js_function.include?("getEpochTime")
  end

  def test_used_by_forms
    # create a form
    @f = Form.create(:form_name => "formName#{rand(9999).to_s}")
    # create a form with a reminders button in it
    @f_reminder = Form.create(:form_name => "formName#{rand(9999).to_s}")
    @fld_reminder = @f_reminder.field_descriptions.create(
      :target_field => "reminders",
      :control_type => "button",
      :predefined_field_id => predefined_fields(:one).id)

    # create a saved general rule
    @gr = Rule.create(:name => "generalRule#{rand(9999).to_s}",
      :rule_type => Rule::GENERAL_RULE,
      :expression => "false", :forms => [@f])
    # create a saved value rule
    @vr = Rule.create(:name => "valueRule#{rand(9999).to_s}",
      :rule_type => Rule::VALUE_RULE )
    # creates a saved fetch rule
    @fr = Rule.create(:name => "fetchRule#{rand(9999).to_s}",
      :rule_type => Rule::FETCH_RULE )
    # create a saved reminder rule
    @rr = Rule.create(:name => "reminderRule#{rand(9999).to_s}",
      :rule_type => Rule::REMINDER_RULE )

    # test each rule for the forms which use this rule
    assert_equal @gr.used_by_forms, [@f]
    assert_equal @vr.used_by_forms, []
    assert_equal @fr.used_by_forms, []
    assert_equal @rr.used_by_forms, [@f_reminder]

    # If value rule is used by form rules or reminder rules, it will be
    # used by the forms which uses these form rules or reminder rules
    @gr.uses_rules << @vr
    @vr.reload  #TODO:: why reload????, test it by turning off the caching - Frank
    assert_equal @vr.used_by_forms, [@f]
    @gr.uses_rules = []
    @vr.reload
    assert_equal @vr.used_by_forms, []
    @rr.uses_rules << @vr
    @vr.reload
    assert_equal @vr.used_by_forms, [@f_reminder]
    @rr.uses_rules  = []
    @vr.reload
    assert_equal @vr.used_by_forms, []

    # If fetch rule is used by value rules or reminder rules, it will be
    # used by the forms which uses these form rules or reminder rules
    @rr.uses_rules << @fr
    @fr.reload
    assert_equal @fr.used_by_forms, [@f_reminder]
    @rr.uses_rules = []
    @fr.reload
    assert_equal @fr.used_by_forms, []
    @vr.uses_rules << @fr
    @fr.reload
    assert_equal @fr.used_by_forms, []
    @rr.uses_rules << @vr
    @fr.reload
    assert_equal @fr.used_by_forms, [@f_reminder]
  end


  def test_run_fetch_rule_at_serverside
    ComparisonOperator.destroy_all
    # Begin to build fetch rule to fetch last 'X0009-1'
    db_table_name = "Observations"
    data_table = "obx_observations"

    text_field_type = "ST - string data"
    text_field_hl7 = "ST"
    source_field = "Observation Name"
    data_column = "obx3_2_obs_ident"
    op_name = "equal (=)"
    op_ar_name = "="
    # op_taffydb_name and op_taffydb_name_o are used for updating
    # exec_fetch_query_js when running save_fetch_rule method.
    op_taffydb_name = "is"

    date_field_type = "DT - date"
    date_field_hl7 = "DT"
    source_field_o = "Observation Date"
    data_column_o = "test_date"
    op_name_o = "Last/most recent date"
    op_ar_name_o = "desc"
    op_taffydb_name_o = "desc"
    
    loinc_num = "X0009-1"
    loinc_display_name = "foo"

    @db_table = DbTableDescription.find_by_data_table(data_table)
    @db_table = DbTableDescription.create(:data_table =>data_table,
      :description => db_table_name) unless @db_table
    assert @db_table.valid?
    @predefined_text_field = PredefinedField.create(
      :field_type => text_field_type,
      :hl7_code => text_field_hl7, :form_builder => true)
    assert @predefined_text_field.valid?
    @db_field = @predefined_text_field.db_field_descriptions.create(
      :data_column => data_column,
      :display_name => source_field,
      :db_table_description_id => @db_table.id)
    assert @db_field.valid?
    @equal_op = @predefined_text_field.comparison_operators.create(
      :display_value => op_name,
      :active_record_operator => op_ar_name,
      :taffy_db_operator => op_taffydb_name)
    assert @equal_op.valid?

    @predefined_date_field = PredefinedField.create(
      :field_type => date_field_type,
      :hl7_code => date_field_hl7,
      :form_builder => true)
    assert @predefined_date_field.valid?
    @db_field_o = @predefined_date_field.db_field_descriptions.create(
      :data_column => data_column_o,
      :display_name => source_field_o,
      :db_table_description_id => @db_table.id)
    assert @db_field_o.valid?
    @last_op = @predefined_date_field.comparison_operators.create(
      :display_value => op_name_o,
      :active_record_operator => op_ar_name_o,
      :taffy_db_operator => op_taffydb_name_o)
    assert @last_op.valid?

    @loinc_item = LoincItem.create(
      :loinc_num => loinc_num, :component => loinc_display_name)
    assert @loinc_item.valid?

    # create a fetch rule to fetch last observation
    major_qua = [
      {"major_qualifier_name_C"=>@db_field.id,
        "major_qualifier_value"=>@loinc_item.display_name,
        "major_qualifier_name"=>@db_field.display_name,
        "major_qualifier_value_C"=>@loinc_item.loinc_num}]
    non_date = [
      {"non_date_qualifier_name"=>@db_field_o.display_name,
        "qualifier_value_C"=>@last_op.id,
        "non_date_qualifier_name_C"=>@db_field_o.id,
        "qualifier_value"=>@last_op.display_value}]
    rule_data = {
      "rule_name"=>"fetchrule#{Time.now.to_i.to_s}",
      "source_table"=> @db_table.description,
      "source_table_C"=>@db_table.id.to_s,
      "major_qualifier_group"=> major_qua,
      "non_date_fetch_qualifiers_group"=> non_date}
    @fr = Rule.new(:rule_type => Rule::FETCH_RULE)
    assert @fr.save_data_rule(rule_data)
    # End of building fetch rule

    # make sure in obx_observation table, there is a record for profile_a
    # but no record for profile_b
    @profile_a = Profile.create
    assert @profile_a.valid?
    @profile_b = Profile.create
    assert @profile_b.valid?

    order = ObrOrder.create!(:latest=>1, :test_date=>'2010/9/3')
    @obs = ObxObservation.create(:profile_id => @profile_a.id,
      :loinc_num => @loinc_item.loinc_num,
      :test_date_ET => 1231232131,
      :obx5_value => "not blank",
      :obr_order_id=>order.id
    )

    #assert @obs.valid?
    # test the prefetch_obx_observations_at_serverside method
    assert !@fr.rule_fetch.prefetch_obx_observations_at_serverside(@profile_a.id).nil?
    assert @fr.rule_fetch.prefetch_obx_observations_at_serverside(@profile_b.id).nil?
  end


  def test_rule_name_and_code_conversion
    rulekey_prefix = Rule::RULEKEY_PREFIX
    rule_a = rules(:a)

    # create a new rule which referencing another rule's name in expression
    rule_expression = "#{rule_a.name} = 1"
    rule_name = "rule_name_conversion_test"
    r = Rule.create!(:name => rule_name,
      :expression => rule_expression,
      :rule_type => Rule::GENERAL_RULE, :forms => [rule_a.forms.first])
    # rule name in expression should be converted into unique key when the expression
    # attribute gets written to databse
    actual = r.attributes["expression"]
    expected = "#{rulekey_prefix}_#{rule_a.id} = 1"
    assert_equal  expected, actual 
    # when read the expression attribute, it should show rule name instead of
    # the saved unique key
    actual = r.expression
    expected = rule_expression
    assert_equal  expected, actual 

    # same cases apply to js_function attribute
    actual = r.attributes["js_function"]
    expected =<<-EOF
Def.Rules.rule_#{rule_name} = function(prefix, suffix, depFieldIndex) {
  var #{rulekey_prefix}_#{rule_a.id}_rule_val = function(){ return Def.Rules.Cache.getRuleVal('#{rulekey_prefix}_#{rule_a.id}');};
  return #{rulekey_prefix}_#{rule_a.id}_rule_val() == 1;
}
EOF
    assert_equal  expected, actual 
    # rule key should be converted back into rule name when reads the attribute
    actual = r.js_function
    expected =<<-EOF
Def.Rules.rule_#{rule_name} = function(prefix, suffix, depFieldIndex) {
  var #{rule_a.name}_rule_val = function(){ return Def.Rules.Cache.getRuleVal('#{rule_a.name}');};
  return #{rule_a.name}_rule_val() == 1;
}
EOF
    assert_equal  expected, actual 

    # test same cases for attributes in rule_cases: case_expression, computed_value
    rule_b = rules(:b)
    rule_c = rules(:c)
    rule_d = rules(:d)
    case_exp = "#{rule_b.name} = 2"
    comp_val = "#{rule_c.name}"
    rc = r.rule_cases.create(:case_expression => case_exp,
      :computed_value => comp_val, :sequence_num => 1)
    assert rc.errors.empty?, rc.errors.full_messages.join("/")

    actual = rc.attributes["case_expression"]
    expected  = "#{rulekey_prefix}_#{rule_b.id} = 2"
    assert_equal  expected, actual 

    actual = rc.case_expression
    expected  = case_exp
    assert_equal  expected, actual 

    actual = rc.attributes["computed_value"]
    expected  = "#{rulekey_prefix}_#{rule_c.id}"
    assert_equal  expected, actual 

    actual = rc.computed_value
    expected  = comp_val
    assert_equal  expected, actual 

    # test updating rule case expressions
    case_exp_update = "#{rule_c.name} = 3"
    comp_val_update = "#{rule_b.name}"
    rc.update_attributes(:case_expression => case_exp_update,
      :computed_value => comp_val_update)

    actual = rc.attributes["case_expression"]
    expected  = "#{rulekey_prefix}_#{rule_c.id} = 3"
    assert_equal  expected, actual 

    actual = rc.case_expression
    expected  = case_exp_update
    assert_equal  expected, actual 

    actual = rc.attributes["computed_value"]
    expected  = "#{rulekey_prefix}_#{rule_b.id}"
    assert_equal  expected, actual 

    actual = rc.computed_value
    expected  = comp_val_update
    assert_equal  expected, actual 

    # Fix errors of message: Action add_messge is invalid
    rad = RuleActionDescription.create(:function_name => "add_message")
    assert rad.valid?, rad.errors.full_messages.join("/")
    RuleAction.clear_actions_cache
    RuleAction.populate_actions_cache

    ra = rc.rule_actions.create(:action => "add_message",
      :parameters => "${#{rule_d.name};*.0}",
      :affected_field => "more_reminders")
    assert ra.errors.empty?, ra.errors.full_messages.join("/")

    actual = ra.attributes["parameters"]
    expected = "message=>${#{rulekey_prefix}_#{rule_d.id};*.0}"
    assert_equal  expected, actual 

    actual = ra.parameters
    expected ="message=>${#{rule_d.name};*.0}"
    assert_equal  expected, actual 
  end

  def test_combo_process_labels
    f_rule = Rule.create(:name => "test_fetch_rule_#{Time.now.to_i}",
      :rule_type => Rule::FETCH_RULE)
    obj = f_rule
    assert obj.valid?, obj.errors.full_messages.join("/")

    db_field = DbFieldDescription.create(
      :predefined_field_id =>predefined_fields(:one).id,
      :data_column => "dafa_column",
      :display_name => "DATA COLUMN")
    obj = db_field
    assert obj.valid?, obj.errors.full_messages.join("/")

    a_label = RuleLabel.create(:label => "A1",:rule_type => "fetch_rule",
      :rule_name_C => f_rule.id,
      :property_C => db_field.id)
    obj = a_label
    assert obj.valid?, obj.errors.full_messages.join("/")

    asso_labels = [a_label]
    actual = Rule.combo_process_labels(asso_labels)[1]
    expected = {"#{a_label.label}"=>"#{f_rule.name}[#{db_field.display_name}]"}
    assert_equal  expected, actual 
  end

  def test_combo_process_expression_part
    readable_label_a1 = "fetch_rule_one[Property One]"
    readable_label_b1 = "value_rule_one"
    labels_found = {"A1"=> readable_label_a1, "B1"=> readable_label_b1 }

    # Test case 1
    exp = "not A1<5"
    actual = 
      Rule.combo_process_expression_part(exp,Set.new,labels_found,[],true)[0]
    # readable format
    expected = "NOT #{readable_label_a1} < 5"
    assert_equal  expected, actual 

    actual =
      Rule.combo_process_expression_part(exp,Set.new,labels_found,[])[0]
    # JavaScript format
    expected = "! A1()<5"
    assert_equal  expected, actual 

    # Test case 2
    exp = "!A1<5"
    actual =
      Rule.combo_process_expression_part(exp,Set.new,labels_found,[],true)[0]
    # readable format
    expected = "NOT #{readable_label_a1} < 5"
    assert_equal  expected, actual 

    actual =
      Rule.combo_process_expression_part(exp,Set.new,labels_found,[])[0]
    # JavaScript format (with no space between ! and A1)
    expected = "!A1()<5"
    assert_equal  expected, actual 

    # Test case 3
    exp = "B1!=12 and !A1"
    actual =
      Rule.combo_process_expression_part(exp,Set.new,labels_found,[],true)[0]
    # readable format
    expected = "#{readable_label_b1} <> 12 AND NOT #{readable_label_a1}"
    assert_equal  expected, actual 

    actual =
      Rule.combo_process_expression_part(exp,Set.new,labels_found,[])[0]
    # JavaScript format (with no space between ! and A1)
    expected = "B1_downcase()!=12 && !A1()"
    assert_equal  expected, actual 

  end

  def test_downcase_label_value
    exp = "A1() !=A2() and B1()==123"
    actual = Rule.downcase_label_value(exp, [])
    expected_exp =
      "A1_downcase() !=A2_downcase() and B1_downcase()==123"
    expected_js_lines = [
      " var A1_downcase = function(){return Def.Rules.toLowerCase(A1());}",
      " var A2_downcase = function(){return Def.Rules.toLowerCase(A2());}",
      " var B1_downcase = function(){return Def.Rules.toLowerCase(B1());}"]
    expected = [expected_exp, expected_js_lines]
    assert_equal  expected, actual 
  end
  
  # The Rule's trigger method will return a rule trigger based on where the trigger 
  # is located. The column fields will have lower priority than other fields as 
  # it can cause runFormRules to evaluate the exact same rule for n times (where 
  # n is the number of fields in the column, see show_when_done_field_only rule 
  # for details)
  def test_rule_trigger
    form = rules(:a).forms[0]
    fields = form.fields
    assert fields.size > 2, "This test requires two form fields" 
    # creates a new form rule
    r = Rule.new(:name => "test_#{Time.now.to_i}", 
                 :rule_type => Rule::GENERAL_RULE, :forms => [form])
    r.expression = "#{fields[1].target_field} = '' "+
                   "AND column_blank(#{fields[2].target_field})"
    r.save!
    actual = r.trigger
    # The non-column field has higher priority than the column field
    expected = fields[1].target_field 
    assert_equal expected, actual
  end
end
