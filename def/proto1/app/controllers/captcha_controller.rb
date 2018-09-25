class CaptchaController < ApplicationController
  layout 'basic'

  # Show the image captcha
  def show
    @page_title = 'PHR Security Check'
  end

  # Handles the submission of the challenge.  Expects
  # session[:captcha_protected_uri] to contain the page the user should go to
  # next if they pass the captcha.
  def answer
    pass = verify_recaptcha

    # See whether this came from the audio captcha or the image captcha
    u_data = {"mode"=>"basic","source"=>"basic_mode","type"=>'visual/audio'}
    if !pass
      flash[:error] = 'The code you submitted is incorrect.  ' +
                      'Please try again.'
      report_params = [['captcha_failure', 
                        Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                        u_data]].to_json
      UsageStat.create_stats(nil,
                             nil,
                             report_params,
                             request.session.id,
                             request.env["REMOTE_ADDR"],
                             false)

      # Now redirect the user based on the captcha type
      redirect_to :action=> 'show'
    else
      session[:passed_basic_captcha] = true
      report_params = [['captcha_success', 
                        Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                        u_data]].to_json
      UsageStat.create_stats(nil,
                             nil,
                             report_params,
                             request.session.id,
                             request.env["REMOTE_ADDR"],
                             false)

      uri = session.delete(:captcha_protected_uri)
      # Send the user to the URI from which the were redirected to the captcha
      redirect_to uri || login_url # login page if we've lost the URL somehow
    end
  end
  # End of action methods

end
