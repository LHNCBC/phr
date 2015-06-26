require 'test_helper'
class RuleCaseTest < ActiveSupport::TestCase
  def test_methods_for_reminder_rule_report
    # Defines labels A1 and B1
    # 1) Create a reminder rule
    a_rule = Rule.create(:name => "abc_#{Time.now.to_i}",
      :rule_type => Rule::REMINDER_RULE)
    assert_valid a_rule
    # 2) Defines type A label
    fetch_rule = Rule.create(:name => "some_fetch_rule",
                             :rule_type => Rule::FETCH_RULE)
    assert_valid fetch_rule
    db_field = DbFieldDescription.create(
      :predefined_field => PredefinedField.create(:form_builder => 1),
      :data_column => "DATA COLUMN", :display_name => "SOME PROPERTY")
    assert_valid db_field
    a_rule.rule_labels.create(
      :label => "A1",
      :rule_type => "fetch_rule",
      :property_C => db_field.id,
      :rule_name_C => fetch_rule.id
    )
    # 3) Defines type B label
    value_rule = Rule.create(:name => "some_value_rule",
                             :rule_type => Rule::VALUE_RULE)
    assert_valid value_rule
    a_rule.rule_labels.create(
      :label => "B1",
      :rule_type => "value_rule",
      :rule_name_C => value_rule.id
    )
    # 4) Defines label descriptions
    label_a_desc = "#{fetch_rule.name}[#{db_field.display_name}]"
    label_b_desc = "#{value_rule.name}"


    # Tests method: expression_in_readable_format
    case_expression = "!A1 and B1!=20"
    a_rule_case = a_rule.rule_cases.create(
      :case_expression => case_expression,
      :sequence_num => 1,
      :computed_value => "1")
    assert_valid a_rule_case
    actual = a_rule_case.expression_in_readable_format
    expected = "NOT #{label_a_desc} AND #{label_b_desc} <> 20"
    assert_equal  expected, actual 


    # Tests method: message_in_readable_format
    RuleActionDescription.create(:function_name => "add_message")
    message = "This is a testing message for label {A1} and label {B1}."
    an_action = a_rule_case.rule_actions.create(
      :action => "add_message", :parameters => message, :affected_field => "reminders")
    assert_valid an_action
    actual = a_rule_case.message_in_readable_format
    expected = message.gsub("\{A1\}", "{" + label_a_desc + "}").
      gsub("\{B1\}", "{" + label_b_desc + "}")
    assert_equal  expected, actual 


    # Test method: rule_expression_in_readable_format
    a_rule_case.rule.update_attributes(:expression => "A1=12 or !B1")
    assert_valid a_rule
    actual = a_rule_case.rule_expression_in_readable_format
    expected = "#{label_a_desc} == 12 OR NOT #{label_b_desc}"
    assert_equal  expected, actual 
  end

  def assert_valid(obj)
    assert obj.valid?, obj.errors.full_messages.to_s
  end
end
