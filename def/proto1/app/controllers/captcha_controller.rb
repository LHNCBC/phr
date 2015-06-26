class CaptchaController < ApplicationController
  layout 'basic'

  # Show the image captcha
  def show
    @page_title = 'PHR Security Check'
    @captcha_info = CaptchaPresenter.image
  end

  # Show the audio captcha
  def audio
    @page_title = 'PHR Security Check (Audio)'
    @captcha_info = CaptchaPresenter.audio
  end

  # Handles the submission of the challenge.  Expects
  # session[:captcha_protected_uri] to contain the page the user should go to
  # next if they pass the captcha.
  def answer
    pass = CaptchaPresenter.check_answer(params[:answer],
                                         params[:challenge_key],
                                         request.remote_ip)

    # See whether this came from the audio captcha or the image captcha
    cap_type = request.referer =~ /audio\Z/ ? 'audio' : 'visual'
    u_data = {"mode"=>"basic","source"=>"basic_mode","type"=>cap_type}
    if !pass
      flash[:error] = 'The words you entered did not match the challenge.  ' +
                      'Please try again.'
      report_params = [['captcha_failure', 
                        Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                        u_data]].to_json
      UsageStat.create_stats(nil,
                             nil,
                             report_params,
                             request.session_options[:id],
                             request.env["REMOTE_ADDR"],
                             false)

      # Now redirect the user based on the captcha type
      redirect_action = cap_type == 'audio' ? 'audio' : 'show'
      redirect_to :action=>redirect_action
    else
      session[:passed_basic_captcha] = true
      report_params = [['captcha_success', 
                        Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                        u_data]].to_json
      UsageStat.create_stats(nil,
                             nil,
                             report_params,
                             request.session_options[:id],
                             request.env["REMOTE_ADDR"],
                             false)

      uri = session.delete(:captcha_protected_uri)
      # Send the user to the URI from which the were redirected to the captcha
      redirect_to uri || login_url # login page if we've lost the URL somehow
    end
  end

  # End of action methods

end
