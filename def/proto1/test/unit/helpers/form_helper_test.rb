require 'test_helper'
require 'helper_testcase'

class FormHelperTest < HelperTestCase
  include ApplicationHelper
  include FormHelper

  fixtures :vaccines
  fixtures :field_descriptions

  def setup
    super
  end
  
  def test_make_auto_completion_list_items
    list_objects = Vaccine.get_list_items(nil,nil, ['id desc'])
    display_strings =
      make_auto_completion_list_items(list_objects, ['id', 'name'])
    assert_equal(14, display_strings.size)
    assert_equal('-14 - Influenza vaccine, injected - TIV', display_strings[13])
  end
  
  
  def test_mergeTagAttributes
    first = {:green=>'blue', :onclick=>'green', :red=>'yellow'}
    second = {:green=>'red', :onclick=>'purple'}
    result = merge_tag_attributes(first, second)
    assert_equal('red', result[:green])
    assert_equal('green; purple', result[:onclick])
    assert_equal(second, merge_tag_attributes(nil, second))
    assert_equal({}, merge_tag_attributes(nil, nil))
    assert_equal({:class=>'one two'},
       merge_tag_attributes({:class=>'one'}, {:class=>'two'}))
  end
  
  
  def test_add_required_icon
    result = add_required_icon(field_descriptions(:required_field))
    assert_not_equal("", result, 
                     'add_required_icon did not return icon for required field')
    result = add_required_icon(field_descriptions(:optional_field))
    assert_equal("", result,
                 'add_required_icon returned icon for optional field')
  end
 

  def test_add_common_attributes
 
    tagsOut = add_common_attributes(field_descriptions(:attributes_1),
                                    {}, '_1')  
    assert_nil(tagsOut[:value],
               'add_common_attributes should no longer add a default value '+
               'attribute except on buttons')
    assert_nil(tagsOut[:class],
                'add_common_attributes generated unexpected class')
    assert_nil(tagsOut[:readonly],
                'add_common_attributes generated unexpected readonly attribute')             

    tagsOut = add_common_attributes(field_descriptions(:attributes_2),
                                    {}, '_1')   
    assert_nil(tagsOut[:value],
                'add_common_attributes generated unexpected size')                
    assert_equal('class1 class2 readonly_field', tagsOut[:class], 
                'add_common_attributes did not generate expected class')
    assert_equal(true, tagsOut[:readonly], 
                'add_common_attributes did not generate expected ' + 'readonlyattribute')       
  end    
    
end
