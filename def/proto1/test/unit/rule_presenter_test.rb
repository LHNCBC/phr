require 'test_helper'
class RulePresenterTest < ActiveSupport::TestCase
  TABLES = [ "field_descriptions","rule_action_descriptions"]

  def setup
    # Creates data table with two data fields for rule to do fetching
    @db_table = DbTableDescription.create(:description => "Test Table", :data_table =>"test_table")
    assert @db_table.valid?
    @db_field = @db_table.db_field_descriptions.create(
      :predefined_field_id => PredefinedField.create(:form_builder => 1).id,
      :data_column => "test_property", :display_name => "Test Property")
    @db_field_2 = @db_table.db_field_descriptions.create(
      :predefined_field_id => PredefinedField.create(:form_builder => 1).id,
      :data_column => "test_property_2", :display_name => "Test Property 2")

    # Creates a test fetch rule
    @a_fetch_rule = Rule.create(:rule_type => Rule::FETCH_RULE,
      :name => "test_fetch_rule")
    @a_fetch_rule.create_rule_fetch(:source_table_C => @db_table.id,
      :source_table => @db_table.description)
  end


  def test_create_reminder_rule
    DatabaseMethod.copy_development_tables_to_test(TABLES, false)
    # Tests invalid rule name
    new_rule_data={"rule_cases"=>[{"reminder"=>"34", "case_expression"=>"12"}],
      "rule_name"=>""}
    rulepst = create_reminder_rule(new_rule_data)
    errors = rulepst.rule_presenter_errors
    assert_equal errors.keys.size, 1
    assert_equal errors[:rule], ["Rule Name must not be blank."]

    # Tests valid rule name
    new_rule_data["rule_name"] = "abc"
    rulepst = create_reminder_rule(new_rule_data)
    assert !rulepst.has_rule_presenter_error
    
    # make the rule label invalid
    # 1) missing fetch rule property
    new_rule_data["rule_name"] = "abcd"
    new_rule_data["fetch_rules_used"] ||= []
    new_rule_data["fetch_rules_used"] << { "fetch_rule_label" => "A1" ,
      "fetch_rule_property" => "",
      "fetch_rule_name_C"=> @a_fetch_rule.id,
      "fetch_rule_name"=> @a_fetch_rule.name}
    rulepst = create_reminder_rule(new_rule_data)
    assert rulepst.has_rule_presenter_error
    errors = rulepst.rule_presenter_errors
    assert errors.keys.size == 1
    assert_equal errors[:rule_label],["Label A1: Property c must not be blank."]

    new_rule_data["rule_name"] = "abcde"
    new_rule_data["fetch_rules_used"][0]["fetch_rule_property"] = @db_field.display_name
    new_rule_data["fetch_rules_used"][0]["fetch_rule_property_C"] = @db_field.id
    rulepst = create_reminder_rule(new_rule_data)
    assert !rulepst.has_rule_presenter_error

    # make rule case invalid
    # 1) has case expression but no rule_value or reminder msg
    new_rule_data["rule_name"] = "abcdef"
    new_rule_data["rule_cases"][0]["reminder"] = ""
    rulepst = create_reminder_rule(new_rule_data)
    assert rulepst.has_rule_presenter_error
    errors = rulepst.rule_presenter_errors
    assert errors.keys.size == 1
    assert_equal errors[:rule_action], ["Parameters should specify a message"]

    new_rule_data["rule_name"] = "abcdefg"
    new_rule_data["rule_cases"][0]["reminder"] = "a reminder message"
    rulepst = create_reminder_rule(new_rule_data)
    assert !rulepst.has_rule_presenter_error

    new_rule_data["rule_name"] = "abcdefgh"
    new_rule_data["rule_cases"][0]["reminder"] = "a reminder \#{A11} message"
    rulepst = create_reminder_rule(new_rule_data)
    assert rulepst.has_rule_presenter_error
    errors = rulepst.rule_presenter_errors
    assert_equal errors.keys.size, 1
    assert_equal errors[:general], ["Label \"A11\" has not been defined."]
    new_rule_data["rule_name"] = "abcdefgh_1"
    new_rule_data["rule_cases"][0]["reminder"] = "a reminder \#{A1} message"
    rulepst = create_reminder_rule(new_rule_data)
    assert !rulepst.has_rule_presenter_error

    # 2) has rule_value/reminder_msg but no case_expression and it is not last line
    new_rule_data["rule_name"] = "abcdefgi"
    new_rule_data["rule_cases"] ||= []
    new_rule_data["rule_cases"] << {"reminder" => "11", "case_expression" => ""}
    new_rule_data["rule_cases"] << {"reminder" => "22", "case_expression" => ""}
    rulepst = create_reminder_rule(new_rule_data)
    assert rulepst.has_rule_presenter_error
    errors = rulepst.rule_presenter_errors
    assert errors.keys.size == 1
    assert_equal errors[:general], ["Case on row 2: Case Expression must not be blank."]

    new_rule_data["rule_name"] = "abcdefghj"
    new_rule_data["rule_cases"][1]["case_expression"] = "true"
    rulepst = create_reminder_rule(new_rule_data)
    assert !rulepst.has_rule_presenter_error

    # Tests editing reminder rule

    # user can edit property name
    # 1) load rule date from rule object
    rule_data = rulepst.get_combo_rule_data_hash
    # 2) select the testing label
    test_label_data = rule_data["fetch_rules_used"].first
    # 3) modify property name
    test_label_data["fetch_rule_property"] = @db_field_2.display_name
    test_label_data["fetch_rule_property_C"] = @db_field_2.id
    # 4) save it
    rulepst.save_data_rule(rule_data)
    assert rulepst.rule_presenter_errors.empty?
    first_label = rulepst.rule_labels.first
    assert_equal first_label.id, test_label_data["fetch_rules_used_id"]
    assert_equal first_label.property_display_name, test_label_data["fetch_rule_property"]
    # user can delete this label and add a new label at the same time
    # 1) delete this label by clear rule name and property fields
    test_label_data["fetch_rule_property"] = ""
    test_label_data["fetch_rule_name"] = ""

    # 2) adding new label by providing new record information with no record id value
    rule_data["fetch_rules_used"] << {
      "fetch_rule_label" => "A2",
      "fetch_rule_name" => @a_fetch_rule.name,
      "fetch_rule_name_C" => @a_fetch_rule.id,
      "fetch_rule_property_C" => @db_field.id,
      "fetch_rule_property" => @db_field.display_name
    }
    rulepst.save_data_rule(rule_data)
    # refresh associations of rules
    rulepst.reload
    assert !rulepst.rule_presenter_errors.empty? # Label A1 is not defined in reminder message
    assert_equal rulepst.rule_labels.size, 1
    assert_equal rulepst.rule_presenter_errors[:general], ["Label \"A1\" has not been defined."]

    # should raise error if wrong record id was submitted
    first_label = rulepst.rule_labels.first
    rule_data = rulepst.data_hash_for_data_rule_page([])
    first_label_data = rule_data["fetch_rules_used"].first
    first_label_data["fetch_rules_used_id"] = first_label.id + 1
    rulepst.save_data_rule(rule_data)
    assert !rulepst.rule_presenter_errors.empty?
  end


  def create_reminder_rule(new_rule_data)
    rulepst = Rule.new(:rule_type => Rule::REMINDER_RULE)
    rulepst.save_data_rule(new_rule_data)
    rulepst
  end
end
