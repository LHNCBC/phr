require 'test_helper'

class CaptchaPresenterTest < ActiveSupport::TestCase

  def setup
    # TBD - substitute your host name below; change port if necessary
    ENV['proxy_host'] = 'TBD.your.host.name:3500'
  end

  def test_image
    cp = CaptchaPresenter.image
    assert_not_nil cp.image_url
    assert_not_nil cp.challenge_key
  end

  def test_audio
    cp = CaptchaPresenter.audio
    assert_not_nil cp.audio_url
    assert_not_nil cp.challenge_key
  end

  def test_check_answer
    # We can't test a successful answer, but we can at least test a false one
    assert_equal(false, CaptchaPresenter.check_answer('Curious George', '1234',
      '127.0.0.1'))
  end
end
