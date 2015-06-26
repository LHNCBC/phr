require 'test_helper'
class RuleFetchConditionTest < ActiveSupport::TestCase
  fixtures :comparison_operators
  #
  # Verify that condition_string returns the correct string for various
  # combinations of missing/present condition column data.
  #
  def test_condition_string
    nd_cond = RuleFetchCondition.new(:source_field => 'Source Field',
      :operator_1 => 'op1',
      :non_date_condition_value => 'nd_val')
    assert_equal('Source Field op1 nd_val', nd_cond.condition_string)

    vl_cond = RuleFetchCondition.new(:source_field => 'Source Field',
      :operator_1 => 'op1')
    assert_equal('Source Field op1', vl_cond.condition_string)

#    dt_cond1 = RuleFetchCondition.new(:source_field => 'Source Field' ,
#      :operator_1 => 'op1',
#      :condition_date => 'Sep 1 2009')
#    assert_equal('Source Field op1 2009-09-01', dt_cond1.condition_string)

#    dt_cond2 = RuleFetchCondition.new(:source_field => 'Source Field' ,
#      :operator_2 => 'op2',
#      :condition_date => 'Sep 1 2009')
#    assert_equal('Source Field op2 2009-09-01', dt_cond2.condition_string)

#    dt_cond3 = RuleFetchCondition.new(:source_field => 'Source Field' ,
#      :operator_1 => 'op1',
#      :operator_2 => 'op2',
#      :condition_date => 'Sep 1 2009')
#    assert_equal('Source Field op1 op2 2009-09-01', dt_cond3.condition_string)

  end # test_condition_string

  #
  # Defer this test to functional testing for the rule controller
  #
  #def test_update_add_conditions
  #end # test_update_add_conditions


  #
  # Verify that the validate method performs the correct validations 
  # correctly.  :)
  #
  def test_validate

    # test for missing columns that are required for all conditions
    cond1 = RuleFetchCondition.new()
    cond1.validate
    assert_equal(6, cond1.errors.size)
    #assert_equal(7, cond1.errors.size)
    assert_equal('must not be nil', cond1.errors[:rule_fetch_id][0])
    assert_equal('must not be blank', cond1.errors[:condition_type][0])
    assert_equal('must not be blank', cond1.errors[:source_field][0])
    assert_equal('must not be blank', cond1.errors[:source_field_C][0])
    assert_equal('must not be blank', cond1.errors[:operator_1][0])
    assert_equal('must not be blank', cond1.errors[:operator_1_C][0])

    # test invalid rule id, condition type and operator_1
    cond1.rule_fetch_id = '2000'
    cond1.condition_type = 'S'
    cond1.source_field = 'source_field'
    cond1.source_field_C = '5000'
    cond1.operator_1 = 'xx'
    cond1.operator_1_C = '3'
    cond1.errors.clear
    cond1.validate
    assert_equal("has an invalid operator 'xx' for field 'source_field'",
                 cond1.errors[:operator_1][0])
    assert_equal('must be the id of an existing fetch rule',
                 cond1.errors[:rule_fetch_id][0])
#    assert_equal('invalid condition type (S)',
#                 cond1.errors[:condition_type])
    assert cond1.errors[:source_field].empty?   
    assert cond1.errors[:source_field_C].empty?
    assert cond1.errors[:operator_1_C].empty?

    # create a form, rule, and fetch rule to use in testing rule_fetch_id
    # and checking for a comparison basis
    rf = Form.create!(:form_name => 'rule_fetch_condition_test_form')
    r1 = Rule.add_new_rule('rule_fetch_condition_unit_test_rule_1', nil,
      rf.id, Rule::FETCH_RULE)
    fetch = RuleFetch.create!(:rule_id=>r1.id,
                               :source_table => 'Medical Conditions',
                               :source_table_C => '469')
    cond1.rule_fetch_id = fetch.id
    cond1.condition_type = 'M'
    cond1.operator_1 = 'equal (=)'
    cond1.errors.clear
    cond1.validate
    assert cond1.errors[:operator_1].empty?
    assert cond1.errors[:rule_fetch_id].empty?
#    assert_equal('Comparison Basis must be specified with Comparison Criteria',
#      cond1.errors[:condition_type])

#    fetch.comparison_basis = 'Any Items'
#    fetch.comparison_basis_C = '1'
    fetch.save!
    cond1.errors.clear
    cond1.validate
    assert cond1.errors[:condition_type].empty?

    # now do testing for a non-date condition
    cond1.non_date_condition_value = 'a value'
    cond1.operator_2 = 'an operator'
    cond1.condition_date = '2009/09/02'
    cond1.condition_date_ET = '1234456'
    cond1.condition_date_HL7 = '2009/09/02'
    cond1.errors.clear
    cond1.validate
    assert_equal('used only for source fields that are date fields.',
      cond1.errors[:operator_2][0])
    assert_equal('must not be specified when a condition value is specified.' +
        '  One of these is wrong.', cond1.errors[:condition_date][0])
    assert_equal('must not be specified when a condition value is specified.',
      cond1.errors[:condition_date_ET][0])
    assert_equal('must not be specified when a condition value is specified.',
      cond1.errors[:condition_date_HL7][0])

    # now do date condition testing
#    cond1.non_date_condition_value = nil
#    cond1.condition_date = nil
#    cond1.errors.clear
#    cond1.validate
#    assert_equal("has an invalid operator 'an operator' for field 'source_field'",
#      cond1.errors[:operator_2])
#    assert_equal('Date must be specified if a recency qualifier is ' +
#        'specified.', cond1.errors[:condition_date])
#
#    cond1.condition_date = '2009/09/02'
#    cond1.operator_2 = nil
#    cond1.condition_date_ET = nil
#    cond1.condition_date_HL7 = nil
#    cond1.errors.clear
#    cond1.validate
#    assert_equal('Recency qualifier must be specified if a date is ' +
#        'specified.', cond1.errors[:operator_2])
#    assert_equal('missing epoch value for date',
#      cond1.errors[:condition_date_ET])
#    assert_equal('missing HL7 value for date',
#      cond1.errors[:condition_date_HL7])
  end # test_validate


  #
  # Verify that the check_required_column method recognizes the absence
  # or presence of data correctly.  Tested extensively by test_validate.
  # Not repeated here.
  #
  #def test_check_required_column
  #end # test_check_required_column


  #
  # Verify ?
  #
  def test_executable_query
  end # test_search_hash

end # rule_fetch_test
