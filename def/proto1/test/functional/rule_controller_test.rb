require 'test_helper'
require 'rule_controller'

# Re-raise errors caught by the controller.
class RuleController; def rescue_action(e) raise e end; end

# Note:  There is a bug in Rails 2.0.2.  If you extend from
# ActionController::TestCase, the setup method cannot be overridden.  So, we
# extend from Test::Unit::TestCase instead (which is the older approach).
class RuleControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :two_factors

  def setup
    DatabaseMethod.copy_development_tables_to_test(
      ['forms', 'field_descriptions', 'rules', 'rules_forms',
      'rule_actions', 'rule_cases', 'rule_dependencies', 'rule_fetches',
      'rule_fetch_conditions', 'rule_field_dependencies', 'text_lists',
      'text_list_items',
      'rule_action_descriptions'
      ])

    RuleAction.populate_actions_cache

#    @controller = RuleController.new
#    @request    = ActionController::TestRequest.new
#    @response   = ActionController::TestResponse.new
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
    @user = users(:phr_admin)
#    @phr_form_params = {:form_name => "PHR", :rendering_form => "edit_general_rule"}
  end
  
  def test_show_rules
    # Confirm that you can get a rule summary page back successfully.
    get :show_rules, {:form_name=>'PHR'},
      {:user_id=>users(:phr_admin).id}
    assert_response(:success)
  end
    
  def test_edit_rule
    default_params = {:form_name => "PHR", :rendering_form => "edit_general_rule"}
    # Confirm that you can't edit a rule that isn't associated with the given
    # form
    params = default_params.merge({:form_name=>'data_rule_form', :id=>2})
    assert_raise(ActiveRecord::RecordNotFound) {
      get :edit_rule, params, {:user_id=>users(:phr_admin).id}
    }
    
#    copyDevelopmentTables
    
    # Confirm that you can edit a rule that is associated with the form.
    params = default_params.merge(:id=>8)
    get :edit_rule, params, {:user_id=>users(:phr_admin).id}
    assert_response(:success)
    
    # Check that the page is redirected following a successful save
    rule = Rule.find_by_name('hide_colon_header')
    action_id = rule.rule_actions[0].id.to_s
    params[:fe] = {:rule_expression=>'age < 50 +2', :rule_name=>'hide_colon_header',
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations', :rule_action_id_1=>action_id}
    put :edit_rule, params, {:user_id=>users(:phr_admin).id}
    assert_redirected_to('/forms/PHR/rules')
    
    # Test for a bug in which the action fields are not edited but duplicated
    # during a save.
    rule = Rule.find_by_name('hide_colon_header')
    assert_equal(1, rule.rule_actions.size)
    
    # Check that one can create an action by not specifying an id.
    params = default_params.merge(:id => 8)
    params[:fe]= {:rule_expression=>'age < 50 +2', :rule_name=>'hide_colon_header',
        :rule_action_name_1=>'show', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'}

    put :edit_rule, params,{:user_id=>users(:phr_admin).id}
    rule = Rule.find_by_name('hide_colon_header')
    assert_equal(2, rule.rule_actions.size)    
    assert_redirected_to('/forms/PHR/rules')
    
    # Check that one can delete an action by not passing in values for it.
    params = default_params.merge(:id => 8)
    params[:fe]={:rule_expression=>'age < 50 +2', :rule_name=>'hide_colon_header',
        :rule_action_id_1=>action_id}
    put :edit_rule, params, {:user_id=>users(:phr_admin).id}
    rule = Rule.find_by_name('hide_colon_header')
    assert_equal(1, rule.rule_actions.size)
    assert_redirected_to('/forms/PHR/rules')

    # Check that a record is not edited following an unsucessful save.
    # Unfortunately, it does not seem possible to test this.  Test methods
    # are wrapped inside a transaction, and it seems that one can't rollback
    # a nested transaction.  In fact, the nested transaction has no effect.
    #put :edit_rule, {:form_name=>'PHR', :id=>8,
    #  :fe=>{:rule_expression=>'age < 50 +3', :rule_name=>'hide_colon_header',
    #        :rule_action_1=>'hide', :rule_parameters_1=>'',
    #        :rule_affected_field_1=>'another_field'}},
    #  {:user_id=>users(:phr_admin).id}
    #assert_response(:success) # back to same page (with errors)
    #rule = Rule.find_by_name('hide_colon_header')      
    #assert_equal('age < 50 +2', rule.expression)
  end
  
  
  def test_new_rule
#    copyDevelopmentTables

    default_params = {:form_name=>'PHR', :rendering_form => "edit_general_rule",
      :type => Rule::GENERAL_RULE
    }
    # Check that a request for the blank new rule form returns successfully
    get :new_rule, default_params, {:user_id=>users(:phr_admin).id}
    assert_response(:success)
  
    # Check that the page is redirected following a successful save
    params = default_params.merge(
      :fe=>{:rule_expression=>'age < 50 +12', :rule_name=>'my_test_rule',
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'})
    post :new_rule, params, {:user_id=>users(:phr_admin).id}
    assert_redirected_to('/forms/PHR/rules')
    
    # Check that the rule was saved
    rule = Rule.find_by_name('my_test_rule')
    assert_equal('age < 50 +12', rule.expression)
    assert_not_nil(rule.js_function)
    assert_equal(1, rule.rule_actions.size)

    # Check that you can't create two rules with the same name
    params = default_params.merge(
      :fe=>{:rule_expression=>'age < 50 +3', :rule_name=>'my_test_rule',
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'})
    post :new_rule, params, {:user_id=>users(:phr_admin).id}
    assert_response(:success)  # not redirected
  end

#   this applies to the old Vital Sign group, which is gone now
#   Rewrite the test when the new test panel is ready
#  def test_latest_blood_pressure_rule_
#    copyDevelopmentTables
#
#    # Check that a request for the blank new rule form returns successfully
#    get :new_rule, {:form_name=>'PHR'}, {:user_id=>users(:phr_admin).id}
#    assert_response(:success)
#
#    @rule_expression = 'latest_from_form(blo_sybp, "blo_test_date")'
#    @rule_name      ='latest_blood_pressure'
#    @rule_name_diff ='latest_blood_pressure_diff'
#    @rule_name_1    ='latest_blood_pressure_1'
#    @wrong_func_name   = 'unknown_func_name(blo_sybp, "blo_test_date")'
#    @wrong_target_field= 'latest_from_form(wrong_target_field, "blo_test_date")'
#
#    # Check that the page is redirected following a successful save
#    post :new_rule, {:form_name=>'PHR',
#      :fe=>{:rule_expression=> @rule_expression,
#        :rule_name=> @rule_name,
#        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
#        :affected_field_1=>'colon_header'}},
#      {:user_id=>users(:phr_admin).id}
#    assert_redirected_to('/forms/PHR/rules')
#
#    # Check that the rule was saved
#    rule = Rule.find_by_name(@rule_name)
#    assert_equal(@rule_expression, rule.expression)
#    assert_not_nil(rule.js_function)
#    assert_equal(1, rule.rule_actions.size)
#
#    # Check that you can't create two rules with the same name
#    post :new_rule, {:form_name=>'PHR',
#      :fe=>{:rule_expression=>@rule_expression,
#        :rule_name=>@rule_name,
#        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
#        :affected_field_1=>'colon_header'}},
#      {:user_id=>users(:phr_admin).id}
#    assert_response(:success)  # not redirected
#
#    # Check that you can create a rule with the different name
#    post :new_rule, {:form_name=>'PHR',
#      :fe=>{:rule_expression=>@rule_expression,
#        :rule_name=>@rule_name_diff,
#        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
#        :affected_field_1=>'colon_header'}},
#      {:user_id=>users(:phr_admin).id}
#    assert_redirected_to('/forms/PHR/rules')
#
#    # Check that you can't create a rule with an unknow function name
#    post :new_rule, {:form_name=>'PHR',
#      :fe=>{:rule_expression=>@wrong_func_name,
#        :rule_name=>@rule_name_1,
#        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
#        :affected_field_1=>'colon_header'}},
#      {:user_id=>users(:phr_admin).id}
#    msg = "Rule expression  - unknown_func_name does not match a known field"
#    assert(@response.body.include?(msg))
#    assert_response(:success)  # not redirected
#
#    # Check that you can't create a rule with a wrong target field
#    post :new_rule, {:form_name=>'PHR',
#      :fe=>{:rule_expression=>@wrong_target_field,
#        :rule_name=>@rule_name_1,
#        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
#        :affected_field_1=>'colon_header'}},
#      {:user_id=>users(:phr_admin).id}
#    assert_response(:success)  # not redirected
#  end


  def test_panel_rules
#    copyDevelopmentTables
    DatabaseMethod.copy_development_tables_to_test(
      ['loinc_items','loinc_panels','loinc_units'])
    default_params = {:form_name => "PHR", :rendering_form => "edit_general_rule",
      :type => Rule::GENERAL_RULE
    }

    # Check that a request for the blank new rule form returns successfully
    get :new_rule, default_params, {:user_id=>users(:phr_admin).id}
    assert_response(:success)
    func_name = "getVal_loincFn"
    input_params  = '(8480-6, tp_test_value)'

    unknown_func_name   = 'wrong_func_name'
    input_params_with_wrong_target_field  = '(8480-6, tp_wrong_target_field)'
    input_params_with_wrong_loinc_number ='(wrong_loinc_number, tp_test_value)'

    # Check that the page is redirected following a successful save
    rule_expression = func_name + input_params
    rule_name      ='testing_get_sytolic_bp'
    params = default_params.merge(
      :fe=>{:rule_expression=> rule_expression,
        :rule_name=> rule_name,
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'})
    post :new_rule, params, {:user_id=>users(:phr_admin).id}

    assert_redirected_to('/forms/PHR/rules')

    # Check that the rule was saved
    rule = Rule.find_by_name(rule_name)
    assert_equal(rule_expression, rule.expression)
    assert_not_nil(rule.js_function)
    assert_equal(1, rule.rule_actions.size)

    # Check that you can't create two rules with the same name
    params = default_params.merge(
      :fe=>{:rule_expression=>rule_expression,
        :rule_name=>rule_name,
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'})
    post :new_rule, params, {:user_id=>users(:phr_admin).id}
    assert_response(:success)  # not redirected

    # Check that you can create a rule with the different name
    rule_name_diff ='testing_get_sytolic_bp_diff'
    params = default_params.merge(
      :fe=>{:rule_expression=>rule_expression,
        :rule_name=>rule_name_diff,
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'}
    )
    post :new_rule, params, {:user_id=>users(:phr_admin).id}
    assert_redirected_to('/forms/PHR/rules')

    # Check that you can't create a rule with an unknown function name
    rule_expression = unknown_func_name + input_params
    rule_name_1    ='get_blood_pressure_1'
    params = default_params.merge(
      :fe=>{:rule_expression=>rule_expression,
        :rule_name=>rule_name_1,
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'})
    post :new_rule, params, {:user_id=>users(:phr_admin).id}
    msg = "Rule expression  - "+
          "Target field #{unknown_func_name} does not exist on form 7"
    assert(@response.body.include?(msg))
    assert_response(:success)  # not redirected

    # Check that you can't create a rule with a wrong target field
    rule_expression = func_name + input_params_with_wrong_target_field
    params = default_params.merge(
      :fe=>{:rule_expression=>rule_expression,
        :rule_name=>rule_name_1,
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'})
    post :new_rule, params, {:user_id=>users(:phr_admin).id}
    assert_response(:success)  # not redirected

    # Check that you can't create a rule with a wrong loinc number
    rule_expression = func_name + input_params_with_wrong_loinc_number
    params = default_params.merge(
      :fe=>{:rule_expression=>input_params_with_wrong_loinc_number,
        :rule_name=>rule_name_1,
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'})
    post :new_rule, params, {:user_id=>users(:phr_admin).id}
    assert_response(:success)  # not redirected
  end
  

  def test_new_case_rule
#    copyDevelopmentTables

    default_params = {:form_name=>'PHR', :rendering_form => "edit_case_rule",
      :type=>Rule::CASE_RULE}
    # Check that a request for the blank new rule form returns successfully
    get :new_rule, default_params, {:user_id=>users(:phr_admin).id}
    assert_response(:success)

    # Check that the page is redirected following a successful save
    params = default_params.merge(
      :fe=>{:case_rule_name=>'my_test_rule',
        :exclusion_criteria=>'age < 50 +12',
        :case_order_1=>1, :case_expression_1=>'gender="Male"',
        :computed_value_1=>'log(birth_date)',
        :rule_action_name_1_1=>'hide', :rule_action_parameters_1_1=>'',
        :affected_field_1_1=>'immunizations',
        :case_order_2=>2, :case_expression_2=>'',
        :computed_value_2=>'log(birth_date)',
        :rule_action_name_2_1=>'hide', :rule_action_parameters_2_1=>'',
        :affected_field_2_1=>'problems_header'
      })
    post :new_rule, params, {:user_id=>users(:phr_admin).id}
    assert_redirected_to('/forms/PHR/rules')

    # Check that the rule was saved
    rule = Rule.find_by_name('my_test_rule')
    assert_equal('age < 50 +12', rule.expression)
    assert_not_nil(rule.js_function)
    assert_equal(0, rule.rule_actions.size)
    assert_equal(2, rule.rule_cases.size)
    assert_equal(1, rule.rule_cases[0].rule_actions.size)

    # Check that you can't create two rules with the same name
    params = default_params.merge(
      :fe=>{:case_rule_name=>'my_test_rule',
        :exclusion_criteria=>'age < 50 +13',
        :case_order_1=>1, :case_expression_1=>'gender="male"',
        :computed_value_1=>'log(birth_date)',
        :rule_action_name_1_1=>'hide', :rule_action_parameters_1_1=>'',
        :affected_field_1_1=>'immunizations',
        :case_order_2=>2, :case_expression_2=>'',
        :computed_value_2=>'log(birth_date)',
        :rule_action_name_2_1=>'hide', :rule_action_parameters_2_1=>'',
        :affected_field_2_1=>'problems_header'})
    post :new_rule, params, {:user_id=>users(:phr_admin).id}
    assert_response(:success)  # not redirected
  end # test_new_case_rule

=begin
    # test auditing of changes to general rule and it's associates with user_id
  def test_general_rule_auditing
    params = {:form_name=>'PHR', :rendering_form => "edit_general_rule",
      :type => Rule::GENERAL_RULE,
      :fe=>{:rule_expression=>'age < 50 +12', :rule_name=>'rule_audit_test',
        :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
        :affected_field_1=>'immunizations'}}

    # Check the creation of a new rule with a rule_action are being audited
    Audit.delete_all
    post :new_rule, params, {:user_id=>@user.id}

    # define newly created rule and rule_action
    rule = Rule.last
    rule_action = RuleAction.last

    action = "create"
    assert_equal(2, Audit.count)
    expected = [[action, @user.id, "Rule", rule.id],
                [action, @user.id, "RuleAction", rule_action.id]]
    actual = Audit.all.map{|e| [e.action, e.user_id, e.auditable_type, e.auditable_id]}
    assert_equal_of_arrays(expected, actual)

    # Update rule and rule action
    params[:id]= rule.id
    params[:fe][:rule_expression] = "age < 5"

    params[:fe][:rule_action_id_1] = rule_action.id
    params[:fe][:rule_action_name_1] = "show"

    # Check after updating an existing rule and it's associated rule_action(s),
    # the destroy action of both rule and rule_action(s) will be audited with an
    # user_id
    Audit.delete_all
    put :edit_rule, params, {:user_id=>@user.id}

    action = "update"
    assert_equal(2, Audit.count)
    expected = [[action, @user.id, "Rule", rule.id],
                [action, @user.id, "RuleAction", rule_action.id]]
    actual = Audit.all.map{|e| [e.action, e.user_id, e.auditable_type, e.auditable_id]}
    assert_equal_of_arrays(expected, actual)

    # Check after destroying an existing rule and it's associated rule_action(s),
    # the destroy action of both rule and rule_action will be audited with an
    # user_id
    Audit.delete_all
    post :show_rules,
      {:form_name=>'PHR', :fe=>{:delete_general_rule_1=>rule.id}},
      {:user_id=>@user.id}

    action = "destroy"
    assert_equal(2, Audit.count)
    expected = [[action, @user.id, "Rule", rule.id],
                [action, @user.id, "RuleAction", rule_action.id]]
    actual = Audit.all.map{|e| [e.action, e.user_id, e.auditable_type, e.auditable_id]}
    assert_equal_of_arrays(expected, actual)
  end

  # test auditing of changes to case rule and its associates with user_id
  def test_case_rule_auditing
    params = {:form_name=>'PHR', :rendering_form => "edit_case_rule",
      :type=>Rule::CASE_RULE,
      :fe=>{:case_rule_name=>'case_rule_audit_test',
        :exclusion_criteria=>'age < 50 ',
        :case_order_1=>1, :case_expression_1=>'gender="Male"',
        :computed_value_1=>'log(birth_date)',
        :rule_action_name_1_1=>'hide', :rule_action_parameters_1_1=>'',
        :affected_field_1_1=>'immunizations',
        :case_order_2=>2, :case_expression_2=>'',
        :computed_value_2=>'log(birth_date)',
        :rule_action_name_2_1=>'hide', :rule_action_parameters_2_1=>'',
        :affected_field_2_1=>'problems_header'
      }}

    # Check when a new case rule was created with two rule_cases and each
    # rule_case has an rule_action
    Audit.delete_all
    post :new_rule, params, {:user_id=>@user.id}

    # define newly created rule, rule_case, rule_action instances
    case_rule = Rule.last
    rule_cases = RuleCase.order("id desc, sequence_num desc").limit(2)
    rule_case_2, rule_case_1 = rule_cases
    rule_action_2, rule_action_1 = rule_cases.map{|e| e.rule_actions[0]}

    action = "create"
    assert_equal(6, Audit.count)
    expected = [[action, @user.id, "Rule", case_rule.id],
                [action, @user.id, "RuleCase", rule_case_1.id],
                [action, @user.id, "RuleCase", rule_case_2.id],
                [action, @user.id, "RuleAction", rule_action_1.id],
                [action, @user.id, "RuleAction", rule_action_2.id]]
    # To build js_function of a case rule, we have to save the case rule again
    # after we created/updated it's rule_cases
    expected << ["update", @user.id, "Rule", case_rule.id]
    actual = Audit.all.map{|e| [e.action, e.user_id, e.auditable_type, e.auditable_id]}
    assert_equal_of_arrays(expected, actual)

    #update rule, rule_cases and rule_actions
    params[:id] = case_rule.id
    params[:fe][:exclusion_criteria] = "age < 5"

    params[:fe][:rule_case_id_1] = rule_case_1.id
    params[:fe][:computed_value_1] += " + 100"
    params[:fe][:case_action_id_1_1] = rule_action_1.id
    params[:fe][:rule_action_name_1_1] = "show"

    params[:fe][:rule_case_id_2] = rule_case_2.id
    params[:fe][:computed_value_2] += " + 100"
    params[:fe][:case_action_id_2_1] = rule_action_2.id
    params[:fe][:rule_action_name_2_1] = "show"

    # Check when newly created case rule gets updated
    Audit.delete_all
    put :edit_rule, params, {:user_id=>@user.id}

    action = "update"
    assert_equal(6, Audit.count)
    expected = [[action, @user.id, "Rule", case_rule.id],
                [action, @user.id, "Rule", case_rule.id],
                [action, @user.id, "RuleCase", rule_case_1.id],
                [action, @user.id, "RuleCase", rule_case_2.id],
                [action, @user.id, "RuleAction", rule_action_1.id],
                [action, @user.id, "RuleAction", rule_action_2.id]]
    actual = Audit.all.map{|e| [e.action, e.user_id, e.auditable_type, e.auditable_id]}
    assert_equal_of_arrays(expected, actual)


    # Check when newly created case rule gets destroyed
    Audit.delete_all
    post :show_rules,
      {:form_name=>'PHR',:fe=>{:delete_case_rule_1=>case_rule.id}},
      {:user_id=>@user.id}

    action = "destroy"
    assert_equal(5, Audit.count)
    expected = [[action, @user.id, "Rule", case_rule.id],
                [action, @user.id, "RuleCase", rule_case_1.id],
                [action, @user.id, "RuleCase", rule_case_2.id],
                [action, @user.id, "RuleAction", rule_action_1.id],
                [action, @user.id, "RuleAction", rule_action_2.id]]
    actual = Audit.all.map{|e| [e.action, e.user_id, e.auditable_type, e.auditable_id]}
    assert_equal_of_arrays(expected, actual)
  end
=end

  private

  def assert_equal_of_arrays(expected, actual, msg = nil)
    assert_equal(expected.map{|e| e.join("/")}.sort, actual.map{|e| e.join("/")}.sort, msg)
  end

  
end
