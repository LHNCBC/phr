require 'test_helper'

class RuleAndFieldDataCacheTest < ActiveSupport::TestCase
  TABLES =  ["rule_action_descriptions" ]
  def setup
    DatabaseMethod.copy_development_tables_to_test(TABLES, false)
    RuleAction.populate_actions_cache
    @form= Form.create(:form_name => "f")
    @rule = Rule.create(:name => "r1", :expression => "'r1'", :forms => [@form])
    @form.rules << @rule
    @used_by_rule_1 = Rule.create(:name => "r1u", :expression => "'r1u'", :forms => [@form])
    @rule.used_by_rules << @used_by_rule_1
    @predefined_field = PredefinedField.create(
      :field_type => "ST - string data", :form_builder => false)
    @field_description_1 = @form.field_descriptions.create!(
      :display_name => "fld",
      :control_type => "text_field",
      :control_type_detail => '',
      :predefined_field => @predefined_field,
      :target_field => "abc"
    )
    @rule.field_descriptions << @field_description_1
    
    @rule_action_1 = @rule.rule_actions.create(
      :affected_field => "abc", :action => "hide")
    
    @rule_case_1 = @rule.rule_cases.create(:case_expression => "true",
      :computed_value => "1", :sequence_num => 1)

    @sub_field_description_2 = @form.field_descriptions.create!(
      :display_name => "sub fld 2",
      :group_header_id => @field_description_1.id,
      :control_type => "text_field",
      :control_type_detail => '',
      :predefined_field => @predefined_field,
      :target_field => "abc2",
      :display_order => 20
    )
    @sub_field_description_1 = @form.field_descriptions.create!(
      :display_name => "sub fld 1",
      :group_header_id => @field_description_1.id,
      :control_type => "text_field",
      :control_type_detail => '',
      :predefined_field => @predefined_field,
      :target_field => "abc1",
      :display_order => 10
    )
    @sub_field_description_3 = @form.field_descriptions.create!(
      :display_name => "sub fld 3",
      :group_header_id => @field_description_1.id,
      :control_type => "text_field",
      :control_type_detail => '',
      :predefined_field => @predefined_field,
      :target_field => "abc3",
      :display_order => 30
    )
  end

  def teardown
    RuleAndFieldDataCache.reset
  end


  def test_cache_rule_and_field_associations
    # When there is no cache, we need an update on the cache
    assert RuleAndFieldDataCache.need_an_update?(@form)

    # Setup the cache
    RuleAndFieldDataCache.cache_rule_and_field_associations(@form)

    # Should know whether caching was done against all the rules and fields
    # of the specified form
    actual = RuleAndFieldDataCache.need_an_update?(@form)
    expected = false
    assert_equal expected, actual

    # Should be able to get the correct cached objects
    actual = RuleAndFieldDataCache.get_used_by_rules_by_rule(@rule.id)
    expected = [@used_by_rule_1]
    assert_equal expected, actual

    actual = RuleAndFieldDataCache.get_field_descriptions_by_rule(@rule.id)
    expected = [@field_description_1]
    assert_equal expected, actual

    actual = RuleAndFieldDataCache.get_rule_actions_by_rule(@rule.id)
    expected = [@rule_action_1]
    assert_equal expected, actual

    actual = RuleAndFieldDataCache.get_rule_cases_by_rule(@rule.id)
    expected = [@rule_case_1]
    assert_equal expected, actual

    actual = RuleAndFieldDataCache.get_sub_fields_by_field(@field_description_1.id)
    expected = [@sub_field_description_1, @sub_field_description_2, @sub_field_description_3]
    assert_equal expected, actual
    
    @sub_field_description_1.display_order = 1000
    @sub_field_description_1.save!
    # Refresh the cache
    RuleAndFieldDataCache.reset
    RuleAndFieldDataCache.cache_rule_and_field_associations(@form)

    # Should cached sub_fields in a specified order
    actual = RuleAndFieldDataCache.get_sub_fields_by_field(@field_description_1.id)
    expected = [@sub_field_description_2, @sub_field_description_3, @sub_field_description_1]
    assert_equal expected, actual

    actual = RuleAndFieldDataCache.get_rules_by_field(@field_description_1.id)
    expected = [@rule]
    assert_equal expected, actual

    # If we did not change rule or form field of a form, we do not need to update
    # the existing cache for the form
    assert !RuleAndFieldDataCache.need_an_update?(@form)

    # After creating a rule, the cache needs to be updated
    @rule = Rule.create(:name => "r11", :expression => "'r11'", :forms => [@form])
    assert @rule.valid?, "Creation of a testing rule failed."
    assert RuleAndFieldDataCache.need_an_update?(@form)

    # After updating the cache version, "need_an_update" will back to false
    RuleAndFieldDataCache.update_cache_version(@form)
    assert !RuleAndFieldDataCache.need_an_update?(@form)

    # Saving a form field will true "need_an_update" back to true again
    assert @field_description_1.save, "Saving of a testing field failed"
    assert RuleAndFieldDataCache.need_an_update?(@form)
  end

end
