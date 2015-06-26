require 'test_helper'

class RuleDataTest < ActiveSupport::TestCase

  TABLES =  ["rule_action_descriptions" ]
  def setup
    DatabaseMethod.copy_development_tables_to_test(TABLES, false)
    RuleAction.populate_actions_cache
    @form= Form.create(:form_name => "f")
    @pdfld= PredefinedField.create!(:form_builder => true)
    # embed an foreign form
    foreign_form_name = "test_foreign_form"
    @embedded_form= Form.create(:form_name => foreign_form_name)
    embedding_field_opts = {:control_type => "loinc_panel", 
      :control_type_detail => {'panel_name'=>@embedded_form.form_name},
      :target_field => "emb_tf",  :predefined_field_id => @pdfld.id}
    @embedding_field = @form.field_descriptions.create(embedding_field_opts)
    @embedded_txt_fld = @embedded_form.field_descriptions.create!(
      :display_name => "embedded text field",
      :control_type => "text_field",
      :predefined_field_id => @pdfld.id,
      :target_field => "embedded abc txt"
    )
    
  end

  # Test load_data_to_form
  def test_load_data_to_form
    @fld_hdr= @form.field_descriptions.create!(
      :display_name => "header field",
      :control_type => "group_hdr",
      :predefined_field_id => @pdfld.id,
      :target_field => "abc hdr"
    )
    @fld_sub= @form.field_descriptions.create!(
      :display_name => "text field",
      :control_type => "text_field",
      :predefined_field_id => @pdfld.id,
      :target_field => "abc sub",
      :group_header_id => @fld_hdr.id
    )
    @fld_txt= @form.field_descriptions.create!(
      :display_name => "text field",
      :control_type => "text_field",
      :predefined_field_id => @pdfld.id,
      :target_field => "abc txt"
    )

    # Add rules to txt field
    @rule_1 = Rule.create!(:name => "r_1", :expression => "'exp1'", :forms => [@form])
    @rule_2 = Rule.create!(:rule_type => Rule::CASE_RULE,
        :name => "r_2", :expression => "'exp2'", :forms => [@form])
    # introducing a loinc panel rule and a loinc field rule 
    @rule_3 = Rule.create!(
        :name => "r_3", :expression => "'exp3'", :forms => [@embedded_form])
    @rule_4 = Rule.create!(
        :name => "r_4", :expression => "'exp4'", :forms => [@embedded_form])

    # add rules to the main form and main form fields
    @form.rules = [@rule_1, @rule_2]
    @fld_txt.rules = [@rule_1, @rule_2]
    @rule_1.field_descriptions = [@fld_txt]
    @rule_2.field_descriptions = [@fld_txt]
    
    # add loinc panel rule to the embedded form
    @embedded_form.rules = [@rule_3, @rule_4]
    @embedded_txt_fld.rules = [@rule_3]
    @rule_3.field_descriptions = [@embedded_txt_fld]
    # add loinc field rule
    @loinc_item = LoincItem.create(:loinc_num=>"ssss")
    LoincFieldRule.create(:rule_id=>@rule_4.id, :loinc_item_id=>@loinc_item.id, 
      :field_description_id=>@embedded_txt_fld.id)    

    # @rule_1 has rule_actions
    @rule_action_1 =
      @rule_1.rule_actions.create!(:action => "hide",
                                   :affected_field => "abc sub")

    # @rule_2 is a case rule
    @rule_case_2 = @rule_2.rule_cases.create(:computed_value => '1',
      :case_expression => "true", :sequence_num => 10)

    @rule_action_2 =
      @rule_case_2.rule_actions.create!(:action => "show",
      :affected_field => "abc sub")

    options = RuleData.load_data_to_form(@form)
    expected =
      [ "Def.Rules.rule_r_4 = function(prefix, suffix, depFieldIndex) {\n" +
        "  return 'exp4';\n}\n",
        "Def.Rules.rule_r_3 = function(prefix, suffix, depFieldIndex) {\n" +
        "  return 'exp3';\n}\n",
       nil,
      "Def.Rules.rule_r_1 = function(prefix, suffix, depFieldIndex) {\n" +
        "  return 'exp1';\n}\n" ]
    actual = options[:rule_scripts]
    assert_equal expected, actual

    expected = ["r_4", "r_3", "r_2", "r_1"]
    actual = options[:form_rules]
    assert_equal expected, actual

    expected = {"abc txt"=> ["r_2", "r_1"], "embedded abc txt"=> ["r_3"]}
    actual = options[:field_rules]
    assert_equal expected, actual

    expected = { [@embedded_txt_fld.target_field,"ssss"].join(":")=> ["r_4"]}
    actual = options[:loinc_field_rules]
    assert_equal expected, actual

    expected = {"r_2"=> 1}
    actual = options[:case_rules]
    assert_equal expected, actual


    #expected = {"r_1"=> [["hide", "abc sub",{}]]}
    expected = {"r_1"=>[["hide", "abc sub", {}]], "r_2.10"=>[["show", "abc sub", {}]]}
    actual = options[:rule_actions]
    assert_equal expected, actual

    expected = [@embedding_field, @fld_hdr, @fld_txt]
    actual = options[:fields]
    assert_equal expected, actual

    expected = {@rule_1.name => @fld_txt.target_field,
      @rule_2.name => @fld_txt.target_field,
      @rule_3.name => @embedded_txt_fld.target_field,
      @rule_4.name => [@embedded_txt_fld.target_field,"ssss"].join(":")}
    actual = options[:rule_trigger]
    assert_equal expected, actual
  end

end
