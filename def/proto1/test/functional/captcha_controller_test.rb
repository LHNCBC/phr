require 'test_helper'

class CaptchaControllerTest < ActionController::TestCase

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  def test_actions

    get :show
    assert_response :success

    get :audio
    assert_response :success

    post :answer, {:answer=>'Curious George',	:challenge_key=>'asdf'}
    assert_redirected_to captcha_path
    assert_not_nil flash[:error]
    # check to make sure a captcha failure event was recorded in the usage stats
    ur = UsageStat.where(['session_id = ? AND user_id is NULL',
                                      @request.session_options[:id]]).load
    assert_not_nil(ur)
    assert_equal(1, ur.size)
    assert_equal(@request.env["REMOTE_ADDR"], ur[0].ip_address)
    det = ur[0]
    assert_equal('captcha_failure', det.event)
    assert_nil(det.profile_id)
    assert_equal('basic', det.data["mode"])
    assert_equal('basic_mode', det.data["source"])
    assert_equal('visual', det.data["type"])

    # can we test a successful captcha?

  end

end
