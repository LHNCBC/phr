require 'test_helper'
require "helper_testcase"

module PhrFormHelper 
  include FormHelper
end

class TextFieldsHelperTest < HelperTestCase
  include ApplicationHelper
  
  # The default FormHelper here is Rails framework form helpers. In order to 
  # load our in-house form helper methods here, we need to give it an alias name
  include PhrFormHelper

  fixtures :text_list_items, :gopher_terms, :forms, :field_descriptions
  
  def setup
    super
  end
  
  def test_get_list_item_codes
    # If the code field is not specified, it should return the values for 
    # the field 'code' (assuming there is one).
    list_items = [text_list_items(:dose1), text_list_items(:route1)]
    codes = get_list_item_codes(list_items)
    assert_equal(['24611', '24935'], codes)
    
    # If the code field is specified, the code value should be taken from that
    # field instead of field "code".
    codes = get_list_item_codes(list_items, 'item_text')
    assert_equal(['3 Tbsp', 'By Mouth'], codes)
    
    # If the code field is not specified, and there is no 'code' field,
    # the 'id' field should be used.
    list_items = [gopher_terms(:one), gopher_terms(:two)]
    codes = get_list_item_codes(list_items)
    assert_equal([gopher_terms(:one).id.to_s, gopher_terms(:two).id.to_s],
      codes)
  end


  # Tests data_req_params
  def test_data_req_params
    fd = field_descriptions(:phr_drug_name)
    params = data_req_params(fd)
    assert_equal(4, params.size, 'drug name')
    assert_equal("/form/handle_data_req?fd_id=#{fd.id}", params[:dataUrl])
    assert_nil(params[:dataReqInput])

    # Test for case where output fields are in the same group
    fd = field_descriptions(:data_req_params_test_list_field)
    opts = data_req_params(fd)
    assert_not_nil(opts[:dataUrl])
    assert_equal(["other_list_field"], opts[:dataReqInput])
    assert_equal(["output1"], opts[:dataReqOutput])
    assert_equal(true, opts[:outputToSameGroup])

    # Test for case where one output field is not in a group
    fd = field_descriptions(:data_req_params_test_list_field2)
    opts = data_req_params(fd)
    assert_equal(["output1", "output2"], opts[:dataReqOutput])
    assert_equal(false, opts[:outputToSameGroup])

    # Test for case where one output field is in a different group
    fd = field_descriptions(:data_req_params_test_list_field3)
    opts = data_req_params(fd)
    assert_equal(["output1", "output3"], opts[:dataReqOutput])
    assert_equal(false, opts[:outputToSameGroup])
  end
end
