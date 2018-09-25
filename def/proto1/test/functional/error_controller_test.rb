require 'test_helper'

# Tests for the ErrorController
class ErrorControllerTest < ActionController::TestCase

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
    SystemError.destroy_all
  end

  test "post to 'new'" do
    assert SystemError.count == 0
    post :new, params: {:message=>"Hello"}
    assert SystemError.count == 1
    report = SystemError.first
    assert_equal("Hello", report.exception)
    # Check that we can't make another one from the same IP (within the
    # one hour window).
    post :new, params: {:message=>"Howdy"}
    assert SystemError.count == 1
  end
end
