require 'test_helper'
class RuleFetchTest < ActiveSupport::TestCase
  #fixtures :comparison_operators


  
  def mc_dr_data
    # Create a form_data hash for two source tables with varying
    # conditions.  Used for multiple tests.
    DatabaseMethod.copy_development_tables_to_test('comparison_operators')
    DatabaseMethod.copy_development_tables_to_test('db_table_descriptions')
    DatabaseMethod.copy_development_tables_to_test('db_field_descriptions')
    @eq_op = ComparisonOperator.find_by_display_value('equal (=)')
    @is_op = ComparisonOperator.find_by_display_value('is')

    @med = DbFieldDescription.find_by_display_name('Medical Condition')

    @mc_data = {"source_table"=>"Medical Conditions",
                "major_qualifier_group"=>[
                  {"major_qualifier_group_id"=>nil,
                   "major_qualifier_name"=> @med.display_name,
                   "major_qualifier_name_C"=> @med.id,
                   "major_qualifier_value"=>"arthritis",
                   "major_qualifier_value_C"=>"4443"}],
                "non_date_fetch_qualifiers_group"=>[
                  {"non_date_fetch_qualifiers_group_id"=>nil,
                   "non_date_qualifier_name"=>@med.display_name,
                   "non_date_qualifier_name_C"=>@med.id,
                   "qualifier_value"=>"arthritis",
                   "qualifier_value_C"=>"4443"}]
               } # end mc_data

    @dcl = DbFieldDescription.find_by_display_name('Drug Classes')
    @sta = DbFieldDescription.find_by_display_name('Status')

    @dr_data = {"source_table"=>"Drugs",
                "major_qualifier_group"=>[
                 {"major_qualifier_name"=>@dcl.display_name ,
                  "major_qualifier_name_C"=>@dcl.id ,
                  "major_qualifier_value"=>"Aspirin",
                  "major_qualifier_value_C"=>"4443"},
                 {"major_qualifier_name"=>@sta.display_name ,
                  "major_qualifier_name_C"=>@sta.id ,
                  "major_qualifier_value"=>"Active",
                  "major_qualifier_value_C"=>"3"}],
                "non_date_fetch_qualifiers_group"=>[
                 {"non_date_qualifier_name"=>@dcl.display_name ,
                  "non_date_qualifier_name_C"=>@dcl.id ,
                  "qualifier_value"=>"Aspirin",
                  "qualifier_value_C"=>"4443"},
                 {"non_date_qualifier_name"=>@sta.display_name ,
                  "non_date_qualifier_name_C"=>@sta.id ,
                  "qualifier_value"=>"Active",
                  "qualifier_value_C"=>"3"}]
               }
               
  end # setup


  #
  # Verify that has_conditions returns the correct response (true or
  # false) for a fetch rule with 0, 1 and 2 conditions.
  #
  def test_has_conditions
    rf = Form.create!(:form_name => 'rule_fetch_test_form')
    r1 = Rule.add_new_rule('rule_fetch_unit_test_rule_1', nil, rf.id,
      Rule::FETCH_RULE)
    r1f = RuleFetch.create!(:rule_id=>r1.id,
                            :source_table=>'Drugs',
                            :source_table_C=>'6')
    assert_equal(false, r1f.has_conditions)
    
    r1fq1 = RuleFetchCondition.new(:condition_type => 'M',
                                   :source_field => 'A source field',
                                   :source_field_C => '2' ,
                                   :operator_1 => 'EQ (=)' ,
                                   :operator_1_C => '2',
                                   :non_date_condition_value => 'value 1',
                                   :non_date_condition_value_C => 'v1')
    r1f.rule_fetch_conditions << r1fq1

    r1fq2 = RuleFetchCondition.new(:condition_type => 'O',
                                   :source_field => 'Another source field',
                                   :source_field_C => '2' ,
                                   :operator_1 => 'EQ (=)' ,
                                   :operator_1_C => '2',
                                   :non_date_condition_value => 'value 2',
                                   :non_date_condition_value_C => 'v2')
    r1f.rule_fetch_conditions << r1fq2
    assert_equal(true, r1f.has_conditions)

    q1id = r1fq1.id
    r1f.rule_fetch_conditions.delete(r1fq1)
    assert_equal(nil, RuleFetchCondition.find_by_id(q1id))
    assert_equal(true, r1f.has_conditions)

    q2id = r1fq2.id
    r1f.rule_fetch_conditions.delete(r1fq2)
    assert_equal(nil, RuleFetchCondition.find_by_id(q2id))
    assert_equal(false, r1f.has_conditions)
    rf.destroy
  end # test_has_conditions


  #
  # Verify that the major_qualifiers method produces the correct number of
  # major_qualifiers for a fetch rule with 0, 1 and 2 conditions.
  #
  def test_major_qualifiers
    DatabaseMethod.copy_development_tables_to_test('comparison_operators')
    rf = Form.create!(:form_name => 'rule_fetch_test_form')
    r1 = Rule.add_new_rule('rule_fetch_unit_test_rule_1', nil, rf.id,
      Rule::FETCH_RULE)
    r1f = RuleFetch.create!(:rule_id=>r1.id,
                            :source_table=>'Drugs',
                            :source_table_C=>'6')
    assert_equal(0, r1f.major_qualifiers.size)

    r1fc1 = RuleFetchCondition.new(:condition_type => 'M',
                                   :source_field => 'A source field',
                                   :source_field_C => '2' ,
                                   :operator_1 => 'equal (=)' ,
                                   :operator_1_C => '2',
                                   :non_date_condition_value => 'value 1',
                                   :non_date_condition_value_C => 'v1')
    r1f.rule_fetch_conditions << r1fc1
    assert_equal(1, r1f.major_qualifiers.length)

    r1fc2 = RuleFetchCondition.new(:condition_type => 'M',
                                   :source_field => 'Another source field',
                                   :source_field_C => '2' ,
                                   :operator_1 => 'equal (=)' ,
                                   :operator_1_C => '2',
                                   :non_date_condition_value => 'value 2',
                                   :non_date_condition_value_C => 'v2')
    r1f.rule_fetch_conditions << r1fc2
    assert_equal(2, r1f.major_qualifiers.size)

    r1f.rule_fetch_conditions.delete(r1fc1)
    assert_equal(1, r1f.major_qualifiers.size)

    r1f.rule_fetch_conditions.delete(r1fc2)
    assert_equal(0, r1f.major_qualifiers.size)
    rf.destroy
  end # test_major_qualifiers


  #
  # Verify that the other_qualifiers method produces the correct number of
  # other_qualifiers for a fetch rule with 0, 1 and 2 conditions.
  #
  def test_other_qualifiers
    DatabaseMethod.copy_development_tables_to_test('comparison_operators')
    rf = Form.create!(:form_name => 'rule_fetch_test_form')
    r1 = Rule.add_new_rule('rule_fetch_unit_test_rule_1', nil, rf.id,
      Rule::FETCH_RULE)
    r1f = RuleFetch.create!(:rule_id=>r1.id,
                            :source_table=>'Drugs',
                            :source_table_C=>'6')
    assert_equal(0, r1f.other_qualifiers.size)

    r1fc1 = RuleFetchCondition.new(:condition_type => 'O',
                                   :source_field => 'A source field',
                                   :source_field_C => '2' ,
                                   :operator_1 => 'equal (=)' ,
                                   :operator_1_C => '2',
                                   :non_date_condition_value => 'value 1',
                                   :non_date_condition_value_C => 'v1')
    r1f.rule_fetch_conditions << r1fc1
    assert_equal(1, r1f.other_qualifiers.size)

    r1fc2 = RuleFetchCondition.new(:condition_type => 'O',
                                   :source_field => 'Another source field',
                                   :source_field_C => '2' ,
                                   :operator_1 => 'equal (=)' ,
                                   :operator_1_C => '2',
                                   :non_date_condition_value => 'value 2',
                                   :non_date_condition_value_C => 'v2')
    r1f.rule_fetch_conditions << r1fc2
    assert_equal(2, r1f.other_qualifiers.size)

    r1f.rule_fetch_conditions.delete(r1fc1)
    assert_equal(1, r1f.other_qualifiers.size)

    r1f.rule_fetch_conditions.delete(r1fc2)
    assert_equal(0, r1f.other_qualifiers.size)
    rf.destroy
  end # test_other_qualifiers

  #
  # Verify that the search_hash method finds the correct hash key/value
  # pairs at various levels of a hash consisting of arrays and hashs.
  #
  def test_search_hash

    rf = Form.create!(:form_name => 'rule_fetch_test_form')
    r1 = Rule.add_new_rule('rule_fetch_unit_test_rule_1', nil, rf.id,
      Rule::FETCH_RULE)
    r1f = RuleFetch.create!(:rule_id=>r1.id,
                            :source_table=>'Drugs',
                            :source_table_C=>'6')
    sh = {"level_one"=>"first_level",
          "first_array"=>[
            {"first_array_hash1"=>"down one",
             "first_array_hash2"=>"down two",
             "first_array_hash3"=>[
               {"second_array_hash1"=>"sah_value1",
                "second_array_hash2"=>"sah_value2"}]}]}
    assert_equal('down one', r1f.search_hash("first_array_hash1", sh))
    assert_equal('sah_value2', r1f.search_hash("second_array_hash2", sh))
    assert_equal('first_level', r1f.search_hash("level_one", sh))
    assert_equal('down two', r1f.search_hash("first_array_hash2", sh))
    assert_equal([{"second_array_hash1"=>"sah_value1",
                   "second_array_hash2"=>"sah_value2"}],
                 r1f.search_hash("first_array_hash3", sh))
    rf.destroy
  end # test_search_hash


  #
  # Defer this test to functional testing for the rule controller
  #
  #def test_add_update_fetch_rule
  #end # test_add_update_fetch_rule


  #
  # Verify that the get_main_fetch_data method obtains the correct data, with
  # the correct hash keys, from a hash in the format returned for form data.
  #
  def test_get_main_fetch_data
    fetch = RuleFetch.new
    no_source_table_hash = {"rule_name"=>"test_fetch",
                            "non_date_fetch_qualifiers_group"=>[
                             {"non_date_qualifier_name"=>"Drug classes",
                              "qualifier_value"=>"Aspirin",
                              "qualifier_value_C"=>"4443"}]
                           }
    no_source = fetch.get_main_fetch_data(no_source_table_hash)
    assert_equal(nil, no_source[:source_table])
    assert_equal(nil, no_source[:source_table_C])

    no_comparison_hash = {"rule_name"=>"test_fetch",
                          "source_table"=>"Drugs",
                          "non_date_fetch_qualifiers_group"=>[
                           {"non_date_qualifier_name"=>"Drug classes",
                            "qualifier_operator"=>"Has",
                            "non_date_qualifier_name_C"=>"1576",
                            "qualifier_operator_C"=>"26228",
                            "qualifier_value"=>"Aspirin",
                            "qualifier_value_C"=>"4443"},
                           {"non_date_qualifier_name"=>"Status",
                            "qualifier_operator"=>"EQ (=)",
                            "non_date_qualifier_name_C"=>"762",
                            "qualifier_operator_C"=>"26220",
                            "qualifier_value"=>"Active",
                            "qualifier_value_C"=>"5"}],
                           "source_table_C"=>"459"}

    no_comp = fetch.get_main_fetch_data(no_comparison_hash)
    assert_equal('Drugs', no_comp[:source_table])
    assert_equal('459', no_comp[:source_table_C])

    all_there_hash = {"rule_name"=>"test_fetch",
                      "source_table"=>"Drugs",
                      "non_date_fetch_qualifiers_group"=>[
                       {"non_date_qualifier_name"=>"Drug classes",
                        "qualifier_value"=>"Aspirin",
                        "qualifier_value_C"=>"4443"},
                       {"non_date_qualifier_name"=>"Status",
                        "qualifier_value"=>"Active",
                        "qualifier_value_C"=>"5"}],
                       "source_table_C"=>"459"}
    has_all = fetch.get_main_fetch_data(all_there_hash)
    assert_equal('Drugs', has_all[:source_table])
    assert_equal('459', has_all[:source_table_C])
  end # test_get_main_fetch_data


  # Verify that the get_major_qualifiers_data method obtains the correct
  # data, with the correct hash keys, from a hash in the format returned for
  # form data.
  #
  def test_get_major_qualifiers_data

    mc_dr_data
    fetch = RuleFetch.new
    mc = fetch.get_major_qualifier_data(@mc_data)
    assert_equal(1, mc.size)
    assert_equal(nil, mc[0][:condition_id])
    assert_equal('M', mc[0][:condition_type])
    assert_equal('Medical Condition', mc[0][:source_field])
    assert_equal(@med.id, mc[0][:source_field_C])
    assert_equal(@eq_op.display_value, mc[0][:operator_1])
    assert_equal(@eq_op.id, mc[0][:operator_1_C])
    assert_equal('arthritis', mc[0][:non_date_condition_value])
    assert_equal('4443', mc[0][:non_date_condition_value_C])

    fetch = RuleFetch.new
    dr = fetch.get_major_qualifier_data(@dr_data)
    assert_equal(2, dr.size)
    dr.each do |ch|
      assert_equal(nil, ch[:condition_id])
      assert_equal('M', ch[:condition_type])
      case ch[:source_field]
      when 'Drug Classes'
        assert_equal(@dcl.id, ch[:source_field_C])
        assert_equal(@is_op.display_value, ch[:operator_1])
        assert_equal(@is_op.id, ch[:operator_1_C])
        assert_equal('Aspirin', ch[:non_date_condition_value])
        assert_equal('4443', ch[:non_date_condition_value_C])
      when 'Status'
        assert_equal(@sta.id, ch[:source_field_C])
        assert_equal(@eq_op.display_value, ch[:operator_1])
        assert_equal(@eq_op.id, ch[:operator_1_C])
        assert_equal('Active', ch[:non_date_condition_value])
        assert_equal('3', ch[:non_date_condition_value_C])
      else
        assert(false, 'invalid source_field value returned for ' +
                      'non-date qualifier.  Value = ' + ch[:source_field])
      end
    end 
  end # test_get_non_date_qualifiers_data


  # Verify that the get_non_date_qualifiers_data method obtains the correct
  # data, with the correct hash keys, from a hash in the format returned for
  # form data.
  #
  def test_get_non_date_qualifiers_data

    mc_dr_data
    fetch = RuleFetch.new
    mc = fetch.get_non_date_qualifiers_data(@mc_data)
    med = DbFieldDescription.find_by_display_name('Medical Condition')
    assert_equal(1, mc.size)
    assert_equal(nil, mc[0][:condition_id])
    assert_equal('O', mc[0][:condition_type])
    assert_equal('Medical Condition', mc[0][:source_field])
    assert_equal(@med.id, mc[0][:source_field_C])
    assert_equal(@eq_op.display_value, mc[0][:operator_1])
    assert_equal(@eq_op.id, mc[0][:operator_1_C])
    assert_equal('arthritis', mc[0][:non_date_condition_value])
    assert_equal('4443', mc[0][:non_date_condition_value_C])

    dr = fetch.get_non_date_qualifiers_data(@dr_data)
    dcl = DbFieldDescription.find_by_display_name('Drug Classes')
    sta = DbFieldDescription.find_by_display_name('Status')
    assert_equal(2, dr.size)
    dr.each do |ch|
      assert_equal(nil, ch[:condition_id])
      assert_equal('O', ch[:condition_type])
      case ch[:source_field]
      when 'Drug Classes'
        assert_equal(@dcl.id, ch[:source_field_C])
        assert_equal(@is_op.display_value, ch[:operator_1])
        assert_equal(@is_op.id, ch[:operator_1_C])
        assert_equal('Aspirin', ch[:non_date_condition_value])
        assert_equal('4443', ch[:non_date_condition_value_C])
      when 'Status'
        assert_equal(@sta.id, ch[:source_field_C])
        assert_equal(@eq_op.display_value, ch[:operator_1])
        assert_equal(@eq_op.id, ch[:operator_1_C])
        assert_equal('Active', ch[:non_date_condition_value])
        assert_equal('3', ch[:non_date_condition_value_C])
      else
        assert(false, 'invalid source_field value returned for ' +
                      'non-date qualifier.  Value = ' + ch[:source_field])
      end
    end
  end # test_get_non_date_qualifiers_data

  
  # Verify that the validate method validates correctly.
  #
  def test_validate
    fetch = RuleFetch.new() ;
    fetch.validate
    assert_equal("must not be nil", fetch.errors[:rule_id][0])
    assert_equal("must not be blank", fetch.errors[:source_table][0])
    assert_equal("must not be blank", fetch.errors[:source_table_C][0])

    fetch2 = RuleFetch.new(:rule_id => '2000000000',
                           :source_table => 'Medical Conditions',
                           :source_table_C => '469')
    fetch2.validate
    assert_equal("must be the id of an existing rule",
                 fetch2.errors[:rule_id][0])

    rf = Form.create!(:form_name => 'rule_fetch_test_form')
    r1 = Rule.add_new_rule('rule_fetch_unit_test_rule_1', nil, rf.id,
      Rule::FETCH_RULE)
    fetch3 = RuleFetch.new(:rule_id=>r1.id,
                           :source_table => 'Medical Conditions',
                           :source_table_C => '469')
    fetch3.validate
    assert_blank fetch3.errors[:rule_id]
    assert_blank fetch3.errors[:source_table]
    assert_blank fetch3.errors[:source_table_C]
  end # test_validate



  #
  # Verify that the check_required_column method recognizes the absence
  # or presence of data correctly.
  #
  def test_check_required_column
    fetch = RuleFetch.new(:source_table => 'Medical Conditions',
                          :source_table_C => '469')
    fetch.check_required_column('source_table')
    assert_blank fetch.errors[:source_table]
    
    fetch.source_table = nil
    fetch.check_required_column('source_table')
    assert_equal("must not be blank", fetch.errors[:source_table][0])

  end # test_check_required_column

end # rule_fetch_test
