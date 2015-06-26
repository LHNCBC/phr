require 'test_helper'

class ActionParamTest < ActiveSupport::TestCase
  fixtures :action_params
  
  def test_get_next_page_url
    ap = action_params(:get_next_page_url_test_one)
    assert_equal('/one/:id;edit', ap.get_next_page_url)
    assert_equal('/one/hello;edit', ap.get_next_page_url('hello'))
    
    ap = action_params(:get_next_page_url_test_two)
    assert_equal('/one/two', ap.get_next_page_url)
  end
end
