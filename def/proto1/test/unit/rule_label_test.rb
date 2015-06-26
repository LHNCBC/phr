require 'test_helper'

class RuleLabelTest < ActiveSupport::TestCase
  fixtures :predefined_fields

  def test_required_fields
    # db_table and db_field being fetched
    db_table = DbTableDescription.create(:description => "Test Table", :data_table =>"test_table")
    assert db_table.valid?, db_table.errors.full_messages.join("/")
    db_field = db_table.db_field_descriptions.create(
      :predefined_field_id => PredefinedField.create(:form_builder => 1).id,
      :display_name => "test_property")
    assert db_field.valid?, db_field.errors.full_messages.join("/")

    # create a test fetch rule
    a_fetch_rule = Rule.create(:rule_type => Rule::FETCH_RULE,
      :name => "test_fetch_rule")
    assert a_fetch_rule.valid?
    a_rule_fetch = a_fetch_rule.create_rule_fetch(:source_table_C => db_table.id, :source_table => db_table.description)
    assert a_rule_fetch.valid?

    # label and rule_type are required
    rule_label = RuleLabel.new()
    assert !rule_label.valid?
    expected = "Rule type is not included in the list | Label can't be blank"
    assert rule_label.errors.full_messages.size == 2
    assert_equal rule_label.errors.full_messages.join(" | "),  expected

    # rule_name and property fields are required depending on other required fields
    rule_label.update_attributes({:label => "A1", :rule_type => "fetch_rule"})
    expected = "The rule_name_C value is invalid."
    assert !rule_label.valid?
    assert rule_label.errors.full_messages.size == 1
    assert_equal rule_label.errors.full_messages[0], expected

#    rule_label.update_attributes(:rule_name => "test_rule_name")
#    expected = "The Fetch Rule Name is invalid."
#    assert !rule_label.valid?
#    assert_equal rule_label.errors.full_messages.size, 1
#    assert_equal rule_label.errors.full_messages.join(" | "), expected

    rule_label.update_attributes(:rule_name_C => 999000009 )
    expected = "The rule_name_C value is invalid."
    assert !rule_label.valid?
    assert_equal rule_label.errors.full_messages.size, 1
    assert_equal rule_label.errors.full_messages.join(" | "), expected

    rule_label.update_attributes(:rule_name_C => a_fetch_rule.id)
    expected = "Property c must not be blank."
    assert !rule_label.valid?
    assert_equal rule_label.errors.full_messages.size, 1
    assert_equal rule_label.errors.full_messages.join(" | "), expected

    rule_label.update_attributes(:property_C => 9999999999)
    expected = "Property c is invalid."
    assert !rule_label.errors.empty?
    assert_equal rule_label.errors.full_messages.size, 1
    assert_equal rule_label.errors.full_messages.join(" | "), expected

    rule_label.update_attributes(:property_C => db_field.id)
    assert rule_label.valid?
  end

  
  def test_readable_label
    f_rule = Rule.create(:name => "test_fetch_rule_#{Time.now.to_i}",
      :rule_type => Rule::FETCH_RULE)
    assert_obj = f_rule
    assert assert_obj.valid?, assert_obj.errors.full_messages.to_s

    db_field = DbFieldDescription.create(
      :predefined_field_id=>predefined_fields(:one).id,
      :data_column => "dafa_column",
      :display_name => "DATA COLUMN")
    assert_obj = db_field
    assert assert_obj.valid?, assert_obj.errors.full_messages.to_s

    a_label = RuleLabel.create(
      :label => "A1",
      :rule_type => "fetch_rule",
      :property_C => db_field.id,
      :rule_name_C => f_rule.id)
    assert_obj = a_label
    assert assert_obj.valid?, assert_obj.errors.full_messages.to_s

    expected = "#{f_rule.name}[#{db_field.display_name}]"
    actual = a_label.readable_label
    assert_equal  expected, actual 

    v_rule = Rule.create(:name => "test_value_rule_#{Time.now.to_i}",
      :rule_type => Rule::VALUE_RULE)
    assert_obj = v_rule
    assert assert_obj.valid?, assert_obj.errors.full_messages.to_s

    b_label = RuleLabel.create(
      :label => "B1",
      :rule_type => "value_rule",
      :property_C => db_field.id,
      :rule_name_C => v_rule.id)
    assert_obj = b_label
    assert assert_obj.valid?, assert_obj.errors.full_messages.to_s

    expected = "#{v_rule.name}"
    actual = b_label.readable_label
    assert_equal  expected, actual 
  end


end
