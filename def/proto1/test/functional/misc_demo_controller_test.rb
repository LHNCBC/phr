require 'test_helper'
require 'misc_demo_controller'

# Re-raise errors caught by the controller.
class MiscDemoController; def rescue_action(e) raise e end; end

class MiscDemoControllerTest < ActionController::TestCase
  def setup
    @controller = MiscDemoController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
