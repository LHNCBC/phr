require 'test_helper'

class RuleActionTest < ActiveSupport::TestCase
  
  fixtures :rules
  fixtures :rule_actions
  fixtures :rule_dependencies
  fixtures :rules_forms
  fixtures :field_descriptions
  fixtures :forms
  TABLES =   ["rule_action_descriptions" ]

  def setup
    DatabaseMethod.copy_development_tables_to_test(TABLES, false)
    RuleAction.populate_actions_cache
  end
  
  # Check the validation
  def test_valid
    f = forms(:shared_fields_one)
    # Check that a valid rule action can be created.
    test_rule = rules(:b)
    rule_action = RuleAction.create(:action=>'hide', :parameters=>'',
      :affected_field=>'first_name', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert rule_action.valid?, "validation errors: #{rule_action.errors.full_messages.inspect};"
    rule_action.destroy
    rule_action = RuleAction.create(:action=>'hide',
      :affected_field=>'first_name', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(rule_action.valid?)
    rule_action.destroy

    # Check that a rule action must have a non-empty name
    rule_action = RuleAction.create(:action=>'', :parameters=>'',
      :affected_field=>'first_name', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0)    
    
    # Check that a rule action must have a non-nil name
    rule_action = RuleAction.create(:action=>nil, :parameters=>'',
      :affected_field=>'first_name', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0) 
    
    # Check the a rule action must have a valid name
    rule_action = RuleAction.create(:action=>'howdy', :parameters=>'',
      :affected_field=>'first_name', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0) 
    
    # Check the a rule action must have a valid name
    rule_action = RuleAction.create(:action=>'howdy', :parameters=>'',
      :affected_field=>'first_name', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0)
    
    # Check that the "add_message" action must have a single parameter
    # for the message, and that the field must be of type message_button
    rule_action = RuleAction.create!(:action=>'add_message',
      :parameters=>'I\'m a message with escaped commas\\,',
      :affected_field=>'more_reminders', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(rule_action.valid?)
    assert_equal('message=>I\'m a message with escaped commas\\,',
      rule_action.parameters)
    rule_action.destroy
    # Test for a field of the wrong control type
    rule_action = RuleAction.create(:action=>'add_message',
      :parameters=>'Some message',
      :affected_field=>'first_name', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0)
    rule_action = RuleAction.create(:action=>'add_message',
      :parameters=>'message=>I\'m a message with escaped commas\\,',
      :affected_field=>'more_reminders', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(rule_action.valid?)
    rule_action.destroy
    rule_action = RuleAction.create(:action=>'add_message',
      :parameters=>'missive=>I\'m a message with escaped commas\\,',
      :affected_field=>'more_reminders', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0)
    rule_action = RuleAction.create(:action=>'add_message',
      :parameters=>'message=>I\'m a message with escaped commas\\,,param2=>5',
      :affected_field=>'more_reminders', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?) 
    assert(rule_action.errors.size>0) 
    rule_action = RuleAction.create(:action=>'add_message',
      :parameters=>
         'I\'m a message with an unescaped commas, (validation fixes it)',
      :affected_field=>'more_reminders', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(rule_action.valid?)
    assert_equal(
    'message=>I\'m a message with an unescaped commas\\, (validation fixes it)',
     rule_action.parameters)
    rule_action.destroy
    
    # Check that a hide action can't have a parameter value
    rule_action = RuleAction.create(:action=>'hide',
      :parameters=>'I\'m a message with escaped commas\\,',
      :affected_field=>'first_name', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0)
    
    # Check that the affected_field value can't be blank
    rule_action = RuleAction.create(:action=>'hide',
      :affected_field=>'', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0)    
    rule_action = RuleAction.create(:action=>'hide',
      :rule_part_id=>1002, :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0)    
    
    # Check that a rule action's affected field must be on all forms to which
    # the rule is applied.  (In this test, the referenced rule is applied to
    # two forms, only one of which has the affected field.)
    rule_action = RuleAction.create(:action=>'hide', :parameters=>'',
      :affected_field=>'first_name', :rule_part_id=>rules(:a).id,
      :rule_part_type=>'Rule')
    assert(!rule_action.valid?)
    assert(rule_action.errors.size>0)
    
    # Check that the affected field can be a group header (at least for a hide
    # action).
    rule_action = RuleAction.create(:action=>'hide', :parameters=>'',
      :affected_field=>'some_hdr', :rule_part_id=>test_rule.id,
      :rule_part_type=>'Rule')
    assert(rule_action.valid?)

    # Create a rule action of hide_loinc_panel
    #
    # checks action name should be validated
    # checks affected field can not be empty
    # checks affected field should be either in main form or in test panel
    # checks the parameters can not be empty
    # checks the parameters has the valid loinc number
    # checks the parameters will be converted into hash after saved
    
    # Create a valid loinc number
    LoincItem.create!(:loinc_num => "8480-6") if LoincItem.find_by_loinc_num("8480-6").nil?
    # Add a new action called "hide_loinc_panel" into auto_complete_list
    t = TextListItem.create!(:item_name  => "hide_loinc_panel",
      :code  => "22",
      :text_list_id => 30)
    t.update_attributes!(:code => t.id)
    RuleAction.populate_actions_cache

    options = {
      :action =>'hide_loinc_panel',
      :parameters =>'8480-6',
      :affected_field =>'active_drugs',
      :rule_part_id => rules(:change_target_not_case_rule).id,
      :rule_part_type =>'Rule'}
    rule_action = RuleAction.create(options)
    assert rule_action.valid?

    rule_action = RuleAction.create(options.merge(:affected_field => ""))
    assert !rule_action.valid?

    rule_action = RuleAction.create(options.merge(:affected_field => "tp_test_value"))
    assert rule_action.valid?

    rule_action = RuleAction.create(options.merge(:parameters => ""))
    assert !rule_action.valid?

    rule_action = RuleAction.create(options.merge(:parameters => "wrong number"))
    assert !rule_action.valid?

    rule_action = RuleAction.create(options.merge(:parameters => "8480-6"))
    actual = rule_action.parameters
    expected = "loinc_number=>8480-6"
    assert_equal  expected, actual 
  end
end
