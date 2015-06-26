# A class for loading resources needed for pages with the captcha.  Right now
# this is just for Google's reCaptcha, and for the Basic HTML mode, but it
# could be modified to also support other modes/captchas.
require 'net/http'
class CaptchaPresenter
  attr_accessor :image_url, :challenge_key, :audio_url

  RECAPTCHA_API_BASE = 'http://www.google.com/recaptcha/api/'

  # Returns a new instance of CaptchaPresenter with fields loaded for an
  # image captcha.
  def self.image
    rtn = CaptchaPresenter.new
    image_url, challenge_key = get_new_challenge(false)
    rtn.image_url = image_url
    rtn.challenge_key = challenge_key
    return rtn
  end


  # Returns a new instance of CaptchaPresenter with fields loaded for an
  # audio captcha.
  def self.audio
    rtn = CaptchaPresenter.new
    audio_url, challenge_key = get_new_challenge(true)
    rtn.audio_url = audio_url
    rtn.challenge_key = challenge_key
    return rtn
  end


  # Returns true if the captcha answer is valid for the given key.
  #
  # Parameters:
  # * answer - the attempted answer to the captcha
  # * challenge_key - the challenge key for the captcha (which identifies the
  #   captcha).
  # * remote_ip - the ip address of the user supplying the answer
  def self.check_answer(answer, challenge_key, remote_ip)
    params={:privatekey=>RECAPTCHA_PRIVATE_KEY,
     :challenge=>challenge_key, :remoteip=>remote_ip,
     :response=>answer}
    url = URI('http://www.google.com/recaptcha/api/verify')
    response = get_http_client.post_form url, params
    return response.body.index("true\n") == 0
  end


  # Private class methods
  class <<self
    private
    # Returns something with the Net:HTTP API which either uses a proxy
    # or doesn't depending on ENV['proxy_host'].
    def get_http_client
      if ENV['proxy_host']
        host, port = ENV['proxy_host'].split(/:/)
        client = Net::HTTP.Proxy(host, port)
      else
        client = Net::HTTP
      end
      return client
    end


    # Returns a new image/audio URL and the challege key.
    #
    # Parameters:
    # * is_audio - true if the challenge should be audio
    def get_new_challenge(is_audio)
      google_page_url =
        "#{RECAPTCHA_API_BASE}noscript?is_audio=#{is_audio}&k=#{::RECAPTCHA_PUBLIC_KEY}"
      response = get_http_client.get_response(URI(google_page_url))
      if response.body =~ /"(image?[^"]+)"/
        image_url = RECAPTCHA_API_BASE + $1
      end
      if response.body =~ /<input\s[^>]*id="recaptcha_challenge_field"[^>]*>/
        input_tag = $&
        if input_tag =~/\svalue="([^"]*)"/
          challenge_key = $1
        end
      end
      return image_url, challenge_key
    end
  end



  private


end