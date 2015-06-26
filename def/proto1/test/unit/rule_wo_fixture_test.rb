require 'test_helper'

class RuleWoFixtureTest < ActiveSupport::TestCase
  # In order to load the joint table: forms_rule_sets, we need to create an
  # empty model FormsRuleSet(see DatabaseMethod.copy_development_tables_to_test)
  TABLES =   ["rules", "rule_cases","rule_actions","forms",
              "rule_fetches","rule_fetch_conditions", "rule_labels",
              "field_descriptions", "loinc_field_rules",
              "rule_dependencies","rule_field_dependencies","text_lists",
              "text_list_items","rules_forms",  "predefined_fields",
              "loinc_items","text_list_items", "rule_sets","forms_rule_sets",
              "rule_action_descriptions", "db_field_descriptions",
              "db_table_descriptions",
             ]

  def test_validate_rules_and_associations
    DatabaseMethod.copy_development_tables_to_test(TABLES, false)
    # Validates existing rules, rule_cases and rule_actions
    indent_spaces = "  "
    result = {}

    [Rule, RuleLabel, RuleCase, RuleAction].each do |model|

      RuleAction.populate_actions_cache if model == RuleAction

      key = "invalid_#{model.name.underscore.pluralize}"
      result[key] = model.all.map do |e|
        e.valid? ?  nil :
          ["#{e.class.name} ID:\"#{e.id}\"",
           "Error Messages:",
            e.errors.full_messages.map{|e| indent_spaces + e}
          ].join("\n* ")
      end.compact
    end

    # Test LoincFieldRule validation when its instance object is associated with
    # a score rule
    saving_result = []
    Rule.score_rules.each do |sr|
      # each sr.save will trigger saving of sr.loinc_field_rules twice due to
      # has_many relationship 
      # 
      # The first save saved all the new loinc_field_rules associated with this 
      # score rule without collecting error messages from loinc_field_rules
      # The second save did both saving and error collecting for 
      # loinc_field_rules
      saving_result << [sr.name, sr.save == sr.save]
    end

    DatabaseMethod.clear_tables(TABLES)

    # Assertion for rules, rule_labels, rule_cases and rule_actions validations
    %w(rules rule_labels rule_actions rule_cases).each do |asso_name|
      
      header_msg = "\n*** Following #{asso_name} are NOT valid:"
      footer_msg = "\n*** Please check with Paul or Frank for details.\n"
      body_msg =  "\n* " + result["invalid_#{asso_name}"].join("\n* ")
      msg = header_msg + body_msg + footer_msg
      
      assert result["invalid_#{asso_name}"].empty?, msg
    end

    # Test LoincFieldRule validation (continued)
    saving_result.each do |result|
      assert result[1], "Score rule [#{result[0]}] validation failed."
    end

  end

    # Test: when form was destroyed, all orphan rules will be destroyed
  def test_form_dependent_destroy
    f = Form.create(:form_name => "test#{Time.now.to_i}")
    r = Rule.create(:name => "rule_#{Time.now.to_i}", :expression => "1 ==1", :forms=>[f])
    f.rules = [r]

    assert f.valid?
    assert r.valid?
    assert r.forms.size == 1
    assert f.rules.size == 1

    f_id, r_id = f.id, r.id
    # when the form gets deleted
    f.destroy
    # the associated rule also gets deleted
    assert Form.find_by_id(f_id).nil?
    assert Rule.find_by_id(r_id).nil?
  end
  
  
  def test_prefetched_obx_observations
    # Makes sure obx_observations is in db_table_descriptions table
    tables = %w( db_table_descriptions rule_fetches rules db_field_descriptions)
    DatabaseMethod.copy_development_tables_to_test(tables, false)
   
    @db_table = DbTableDescription.find_by_data_table("obx_observations")
    rf = RuleFetch.new(
      :source_table => "ObxObservations", :source_table_C => @db_table.id)
    @test_ln = "test_ln_#{Time.now.to_i}"
    @order = "desc"
    cond = {:order => {'test_date_ET' => @order}, 
      :conditions=>{"loinc_num"=>{"=" => @test_ln}}}
    rf.executable_fetch_query_ar = [nil, [cond]]

    @rule_name ="test_rule_name_#{Time.now.to_i}"    
    test_rule = Rule.new(:name => @rule_name, :expression => "true")
    test_rule.forms << Form.new(:form_name => "#{Time.now.to_i}")
    test_rule.save!
    rf.rule_id = test_rule.id
    rf.save!
    
    @profile_a = Profile.new()
    @profile_a.save!
    @profile_b = Profile.new()
    @profile_b.save!

    order = ObrOrder.create(:latest=>1, :test_date=>'2010/9/3')
    @test_obx_rec_1 = ObxObservation.new(:loinc_num => @test_ln,
      :obr_order_id=>order.id, :obx5_value=>'test value here')
    @test_obx_rec_1.save!
    @test_obx_rec_2 = ObxObservation.new(:loinc_num => @test_ln,
      :obr_order_id=>order.id, :obx5_value=>'test value here')
    @test_obx_rec_2.save!
    lor = LatestObxRecord.create({:profile_id => @profile_a.id, 
        :loinc_num => @test_ln, 
        :first_obx_id => @test_obx_rec_1.id, 
        :last_obx_id => @test_obx_rec_2.id })
    
    attr_list = %w(test_normal_low record_id obx6_1_unit lastvalue_date 
    last_date_HL7 unit_code required_in_panel obx3_2_obs_ident)
    actual = Rule.prefetched_obx_observations(@profile_a.id, attr_list)
    expected= 
     {"#{@rule_name}"=>{"test_normal_low"=>"",
      "record_id"=>nil, "obx6_1_unit"=>nil, "lastvalue_date"=>nil,
      "last_date_HL7"=>nil, "unit_code"=>nil, "required_in_panel"=>nil,
      "obx3_2_obs_ident"=>nil}}
    assert_equal expected, actual
  end

end
