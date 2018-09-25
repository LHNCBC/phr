require 'test_helper'

class CaptchaControllerTest < ActionController::TestCase

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  def test_actions
    get :show
    assert_response :success

    post :answer, params: {'g-recaptcha-response'=>'Curious George'}
    assert_redirected_to captcha_path
    assert_not_nil flash[:error]
    # check to make sure a captcha failure event was recorded in the usage stats
    ur = UsageStat.where(['session_id = ? AND user_id is NULL',
                                      @request.session.id]).load
    assert_not_nil(ur)
    assert_equal(1, ur.size)
    det = ur.last
    assert_equal(@request.env["REMOTE_ADDR"], det.ip_address)
    assert_equal('captcha_failure', det.event)
    assert_nil(det.profile_id)
    assert_equal('basic', det.data["mode"])
    assert_equal('basic_mode', det.data["source"])
    assert_equal('visual/audio', det.data["type"])

    post :answer, params: {'g-recaptcha-response'=>'correct_response'}
    assert_redirected_to login_path
    assert session[:passed_basic_captcha]
    # check to make sure a captcha success event was recorded in the usage stats
    ur = UsageStat.where(['session_id = ? AND user_id is NULL',
                          @request.session.id]).load
    assert_not_nil(ur)
    assert_equal(2, ur.size)
    det = ur.last
    assert_equal(@request.env["REMOTE_ADDR"], det.ip_address)
    assert_equal('captcha_success', det.event)
    assert_nil(det.profile_id)
    assert_equal('basic', det.data["mode"])
    assert_equal('basic_mode', det.data["source"])
    assert_equal('visual/audio', det.data["type"])
  end

end
