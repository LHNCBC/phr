require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :two_factors
  fixtures :field_descriptions
  fixtures :forms
  fixtures :rules
  fixtures :rules_forms
  fixtures :rule_actions

  def test_data_hash_from_params
    # Make a params hashmap with data for a test form.
    form = forms(:data_hash_from_params_test)
    form_params = {
       :top_field=>'a',
       :group_field_1=>'b',
       :group_field2_1=>'c',
       :sub_group_field_1_1=>'d',
       :sub_table_id_1_1=>'10',      
       :table_field_1_1=>'e',
       :table_field2_1_1=>'f',
       :sub_table_id_1_2=>'11',
       :table_field_1_2=>'g',
       :sub_table_id_1_3=>'12',
       :table_field2_1_3=>'h',
       :sub_table_id_1_4=>'', # test that rows with nothing but blanks
       :table_field_1_5=>'',  # are not included in the returned data_hash.
       :sub_table_id_1_6=>'13', # test that a row following a blank row is
       :table_field_1_6=>'i'}   # included in the data_hash

    data_hash = @controller.send :data_hash_from_params, form_params, form
    assert_not_nil(data_hash)
    assert_equal(2, data_hash.size)
    assert_equal('a', data_hash['top_field'])
    v_group = data_hash['top_field_group']
    assert_not_nil('v_group')
    assert_equal(4, v_group.size)
    assert_equal('b', v_group['group_field'])
    assert_equal('c', v_group['group_field2'])
    v_group_sub_group = v_group['sub_group']
    assert_not_nil(v_group_sub_group)
    assert_equal(1, v_group_sub_group.size)
    assert_equal('d', v_group_sub_group['sub_group_field'])
    assert_equal('c', v_group['group_field2'])
    sub_table = v_group['sub_table']
    assert_not_nil(sub_table)
    assert_equal(4, sub_table.size)
    assert_equal({'sub_table_id'=>'10', 'table_field'=>'e',
                  'table_field2'=>'f'}, sub_table[0])
    assert_equal({'sub_table_id'=>'11', 'table_field'=>'g'}, sub_table[1])
    assert_equal({'sub_table_id'=>'12', 'table_field2'=>'h'}, sub_table[2])
    assert_equal({'sub_table_id'=>'13', 'table_field'=>'i'}, sub_table[3])
  end


end
