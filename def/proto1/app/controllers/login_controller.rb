# $Log: login_controller.rb,v $
# Revision 1.128  2011/07/21 15:58:05  mujusu
# bug fixes
#
# Revision 1.127  2011/07/06 14:08:43  mujusu
# account signup page
#
# Revision 1.126  2011/06/22 16:22:58  mujusu
# fixed login error bug etc
#
# Revision 1.125  2011/06/21 18:02:08  mujusu
# check for unique userid
#
# Revision 1.124  2011/06/14 18:31:41  mujusu
# login error message & verify_password fix
#
# Revision 1.123  2011/06/10 18:07:44  mujusu
# icomment fixes and account cretion Q/A bug fix
#
# Revision 1.122  2011/06/06 19:57:45  plynch
# Added a redirect from the page timer to the page that shows the charts,
# and made chart page initially show the chart for the current system
#
# Revision 1.121  2011/06/02 17:01:58  plynch
# Changed the text of messages about the status of attempts to change
# account settings.
#
# Revision 1.120  2011/06/01 21:16:59  mujusu
# show notice to verify email
#
# Revision 1.119  2011/05/26 18:28:27  mujusu
# skip  captcha verification for  account management tests
#
# Revision 1.118  2011/05/18 14:15:26  mujusu
# fixes for validation and QA related issues at account creation time
#
# Revision 1.117  2011/05/16 20:26:22  plynch
# page_timer_controller- now measures rails and apache times
# others- changed logger.info to logger.debug
#
# Revision 1.116  2011/04/15 14:36:51  mujusu
# clear out trials
#
# Revision 1.115  2011/04/04 16:47:38  mujusu
# accounts management refactoring
#
# Revision 1.114  2011/03/02 22:13:16  mujusu
# no cache anymore. only .2 sec difference
#
# Revision 1.113  2011/02/25 19:22:06  mujusu
# added comments, login goes to profile if already logged in
#  ----------------------------------------------------------------------
#
# Revision 1.112  2011/02/19 00:11:16  mujusu
# new recaptcha keys etc
#
# Revision 1.111  2011/02/18 22:24:35  mujusu
# updates for updated recaptcha plugin
#
# Revision 1.110  2011/02/15 17:22:13  lmericle
# uncommented before file for account type flag
#
# Revision 1.109  2011/02/14 17:23:11  mujusu
# support email address in array format now supported
#
# Revision 1.108  2011/02/04 21:20:01  mujusu
# reset password fixes
#
# Revision 1.107  2011/02/01 21:31:01  mujusu
# mostly code review changes
#
# Revision 1.106  2011/01/13 17:03:59  mujusu
# review based changes
#
# Revision 1.105  2011/01/05 23:23:33  mujusu
# request.domain returns only nih.gov for some reason
#
# Revision 1.104  2010/12/28 20:43:52  mujusu
# send email when resetting profile/password
#
# Revision 1.103  2010/12/27 22:51:03  mujusu
# fix login bug plus few minor updates
#
# Revision 1.102  2010/12/22 20:40:42  mujusu
# authentication_token not cached in login page now
#
# Revision 1.101  2010/12/20 20:09:51  plynch
# Update to the gopher terms table (based on work by
# Julia Xu to map the terms to Snomed codes)
# plus updates the the tests.
#
# Revision 1.100  2010/12/17 17:20:01  mujusu
# fixed/refactored trial update
#
# Revision 1.99  2010/12/10 22:40:25  mujusu
# changed reset email sig
#
# Revision 1.98  2010/11/22 14:51:45  mujusu
# rearranged account locking for incorrect answer/password attempts
#
# Revision 1.97  2010/11/18 15:38:16  lmericle
# fixed new user creation bug where recaptcha was not being loaded for errors
# other than incorrect recaptcha text
#
# Revision 1.96  2010/11/16 23:41:26  mujusu
# SHA256 changes
#
# Revision 1.95  2010/11/10 17:55:34  mujusu
# new methods to support accountID and password recover features. as well as
# contact support feature
#
# Revision 1.94  2010/10/25 18:21:09  mujusu
# ADadded DOB and PIN fields
#
# Revision 1.93  2010/09/29 01:07:02  taof
# bugfix: turn on regular user trial limit
#
# Revision 1.92  2010/09/28 21:57:02  taof
# bugfix: cannot save new class type
#
# Revision 1.91  2010/09/20 23:03:33  mujusu
# changes based on code review
#
# Revision 1.90  2010/09/16 15:51:08  mujusu
# fix account settings page
#
# Revision 1.89  2010/09/14 20:36:33  mujusu
# review changes
# Revision 1.88  2010/09/09 16:11:44  mujusu
# bug fixes for security reset
#
# Revision 1.87  2010/09/07 19:28:00  mujusu
# functionality to reset security
#
# Revision 1.86  2010/08/13 16:19:30  lmericle
# minor code & wording cleanups
#
# Revision 1.85  2010/08/10 19:26:24  mujusu
# set cookie expiry on creation
#
# Revision 1.84  2010/08/05 18:43:07  mujusu
# bug ifx
#
# Revision 1.83  2010/08/03 19:14:48  mujusu
# ibug fix method signature etc
#
# Revision 1.82  2010/07/30 14:50:06  mujusu
# check user/pass before chellenge question ow
#
# Revision 1.81  2010/07/27 19:45:10  mujusu
# reformatting and refactoring etc
#
# Revision 1.80  2010/07/19
# 20:59:35  mujusu added two_factor as seperate model
#
# Revision 1.79  2010/07/15 18:34:35  mujusu added two_factor cookie support
#
# Revision 1.78  2010/07/02 19:58:29  lmericle changes to field suffixes cause
# by changes to signup form
#
# Revision 1.77  2010/06/29 19:42:28  lmericle removed redundant temporary
# account banner warning
#
# Revision 1.76  2010/06/25 13:59:38  lmericle added before_action for
# set_account_type_flag; added set_account_type_flag to application_controller
#
# Revision 1.75  2010/06/21 21:10:40  lmericle added code to update expiration
# date for experimental accounts when the user logs in
#
# Revision 1.74  2010/05/27 16:14:31  mujusu show header_template in account s
# pages req login. Also cleanup header_template
#
# Revision 1.73  2010/05/26 19:35:34  abangalore handles mutiple sessions
#
# Revision 1.72  2010/04/29 14:14:16  lmericle added exception handling in
# add_user
#
# Revision 1.71  2010/04/26 17:48:20  abangalore .
#
# Revision 1.70  2010/04/06 20:27:37  mujusu filetr answers etc in log
#
# Revision 1.69  2010/04/01 13:02:17  lmericle changes to add_user, cleanups -
# NEEDS MORE
#
# Revision 1.68  2010/03/29 22:15:28  mujusu redirect to admin_profile
#
# Revision 1.67  2010/03/18 14:20:28  mujusu check original uri against regex
#
# Revision 1.66  2010/03/03 18:51:59  mujusu admin profile for admin
#
# Revision 1.65  2010/02/19 21:29:11  mujusu no flash message for logoff`
#
# Revision 1.64  2010/02/17 23:02:37  mujusu logout should not need
# authorization
#
# Revision 1.63  2010/02/09 23:36:32  plynch Changes for task 1701 (mechanism
# for system notices)
#
# Revision 1.62  2010/02/08 22:41:47  mujusu commeted openid related code to
# prevent possible misuse/security hole
#
# Revision 1.61  2010/02/05 19:27:16  mujusu make ans case insenstive/space
# insensitive and also fix too much new salt issue
#
# Revision 1.60  2010/01/20 21:56:11  mujusu account change screen related
# fixes/
#
# Revision 1.59  2010/01/08 22:29:16  mujusu no authorization req for logoff
#
# Revision 1.58  2009/10/29 20:51:00  mujusu user ID is Account ID now
#
# Revision 1.57  2009/10/26 22:45:17  mujusu added cache for login form
#
# Revision 1.56  2009/09/23 17:25:01  abangalore .
#
# Revision 1.55  2009/08/21 18:43:20  mujusu
#  fixes bug 1443
#
# Revision 1.54  2009/08/03 18:41:37  mujusu fix to go to original URl after
# login
#
# Revision 1.53  2009/07/31 19:27:11  plynch Changed routes from /app/phr to
# /profiles
#
# Revision 1.52  2009/07/29 20:00:11  mujusu check captcha before adding user
#
# Revision 1.51  2009/07/29 19:31:09  mujusu updated the lockout message
#
# Revision 1.50  2009/07/29 17:55:03  mujusu fix for session fixation loophole
#
# Revision 1.49  2009/07/22 19:38:33  mujusu
#  added protect_from sorgery exceptions for unprotected pages
#
# Revision 1.48  2009/07/17 20:11:47  mujusu icommented openid related code
# since no account_type param sent in
#
# Revision 1.47  2009/05/20 22:05:02  mujusu bug fixes
#
# Revision 1.46  2009/04/17 21:15:41  mujusu email no longer used
#
# Revision 1.45  2009/04/02 18:07:56  mujusu refactored accounts management code
#
# Revision 1.44  2009/03/25 19:36:14  mujusu moved email code to model till
# refoactoring moves to helper
#
# Revision 1.43  2009/03/25 14:26:44  mujusu changes for verify_password page
#
# Revision 1.42  2009/02/27 23:03:14  smuju check for same email address twice
# and other changes
#
# Revision 1.41  2008/11/14 19:51:52  smuju changes to remove extra login plus
# account type sicne openid disabled for now
#
# Revision 1.40  2008/10/23 18:32:15  smuju added more relevent error messages
#
# Revision 1.39  2008/09/15 15:50:16  plynch Changes made for supporting the
# phr_index page.
#
# Revision 1.38  2008/08/15 16:50:27  smuju return datahash , not array of hash
#
# Revision 1.37  2008/08/07 22:47:24  yango add intructions to the Create
# security questions fix a bug in error handling when you only fill captcha and
# submit the form
#
# Revision 1.36  2008/08/05 18:23:56  yango move the old login.rb code into
# user.rb. This makes more sense.
#
# Revision 1.35  2008/07/31 22:18:02  yango create a feature that if a user
# forgot their email address, they can use email address to retrieve their user
# id.
#
# Revision 1.34  2008/07/31 20:49:58  yango Change the wording of  forgot
# password page, change profile page.
#
# Revision 1.33  2008/07/30 16:32:30  yango add check box control logic
#
# Revision 1.32  2008/07/24 21:48:51  yango Change the add_user. When captcha
# failed, the error message is something like "neighter openid nor regular
# account"
#
# Revision 1.31  2008/07/18 20:54:16  yango add new links
#
# Revision 1.30  2008/07/16 23:37:03  plynch The key in "session[:original_uri]"
# should not be changed to :original_uri_1, because this is not a form
# parameter.
#
# Revision 1.29  2008/07/16 22:13:13  yango Change the login layout
#
# Revision 1.28  2008/07/11 23:14:51  wangye change 2 open id table names
#
# Revision 1.27  2008/07/11 22:38:55  yango fix openid function not defined. add
# three times trial access control.
#
# Revision 1.26  2008/07/10 15:08:00  yango solve the "add_to_base" problem in
# validate_recap().
#
# Revision 1.25  2008/07/09 17:04:12  plynch Routing changes for the form
# builder, simplification of what happens after a login, and the addition of the
# beginning of a file for field events.
#
# Revision 1.24  2008/07/08 20:44:56  yango revise the login, signup, change
# profile, change password for openid.
#
# July 3, 2008, I added comments and restructure the code: move some database
#     code to the modeller.
# June 21,2008, before_action is revised by Gongjun Yan to add Change Profile
#     and Change Password functions
# #++ The program implements all the functions of account management. The
# account management includes sign up, sign in (login), sign out (logout),
# change profile, and change password. The most important issues of the personal
# health record (PHR) are privacy and security. Another important issue is to
# design the systm as generic as possible. Therefore the design is on these
# basis. There are some rules: 1) emails are accounted as privacy information;
# 2) openid [1,2] is allowed to use; 3) password has to follow the NIH's
# regulations (three combinations of uppercase letters, lower case, numbers, and
# other characters); 4) Security questions include two types (fixed and user
# defined); 5) all the security answers for questions have to be hashed
# (encrypted); 6) captcha [3,4,5,6] from Recaptcha.com, a third party and a free
# plug in, is installed.
#
#
# Reference:
#
# [1] Openid official home page: http://openid.net/
# [2] Openid for developers web page: http://openid.net/developers/
# [3] Captcha offical site: http://www.captcha.net/
# [4] Captcha wikipedia page: http://en.wikipedia.org/wiki/Captcha
# [5] Recaptcha offical site: http://recaptcha.net/
# [6] Recaptcha install and configure in ruby:
#   http://www.loonsoft.com/recaptcha/ NOTE: Some of this code is borrowed from
#   Chapter 11 of AWDR
#
# This class is the controller of all the account management. The route from a
# url to a function/action in this class is specified in the route file which
# is located at config/routes.rb
#
require 'digest/sha2'

class LoginController < ApplicationController
  helper FormHelper, PhrRecordsHelper

  # disable CSRF security check for public pages
  skip_before_action :verify_authenticity_token, :only =>
    [:login,:logoff, :browser_support, :handle_two_factor, :add_user, :email_verification]

  # before_action checks if the user is allowed to access these functions by
  # authorize control method which is defined in controllers/application.rb.
  # The except part lets public methods be accessible without
  # login/authorization filter screening.
  before_action :authorize, :except =>
    [:login,:add_user,:forgot_password,:change_password,:forgot_id,
    :forgot_id_step2,:timeout_logoff,:logout,:get_reset_link, :update_password,
    :reset_account_security, :expire_reset_key, :browser_support,
    :handle_two_factor, :demo_login, :email_verification]

  before_action :check_logged_in_user, :only=>[:login, :demo_login]

  # these pages not available on demo system
  before_action :check_demo_system, :only => [:login, :add_user, :forgot_id,
      :forgot_password
  ]
  # demo_login not available on production system except when it's a demo system
  before_action :check_demo_system2, :only => [:demo_login]

  #before_action :set_account_type_flag
  # Confirm user by checking password first
  before_action :show_header, :only =>  [:change_account_settings]
  before_action :verify_password, :only =>  [:change_account_settings]
  before_action :reset_preconditions, :only =>  [:update_password, :reset_account_security]
  before_action :verify_user, :only =>[:change_password, :get_reset_link]
  around_action :captcha, :only=>[:add_user, :forgot_id, :forgot_password]

  before_action :get_form_params, only: [:add_user, :change_account_settings, :change_password, :update_password,
                                         :reset_account_security, :forgot_id, :forgot_password, :handle_two_factor,
                                         :email_verification, :login, :demo_login]

  # the min_hold_time is a class variable too, meaning the minimum holding time
  # if a user failed to login up to USER::MAX_TRIAL.
  @@min_hold_time = 3600

  # Account registration error messages applicable just to the registration
  # process. Does not include messages related to user data that is actually
  # stored.
  @@invalid_captcha_msg = 'Your recaptcha verification failed. Please try it again.'
  @@need_captcha_input_msg = 'Please verify you are human by finishing any recaptcha challenge prompt.'
  @@no_email_error = 'No email address has been specified for this user.'+
    'Please answer challenge questions and reset password instead by '+
    'selecting "Answer challenge questions" option.'
  @@no_changes = 'There are no changes to save. Please update the question(s) '+
    'and/or the password or click Cancel button to return to the login page.'
  @@user_name = 'Please enter a valid Account ID.'
  @@password = 'Please enter a valid password.'

  # The error messsage the user sees if there is some problem with the way
  # their security questions are set up.  This should not normally happen.
  SECURITY_QUESTION_PROBLEM_MSG = 'This account does not seem to have security '+
    'questions set up correctly. Please use the '+ SUPPORT_PAGE_NAME +
    ' page for assistance.'

  # This is a sign up method When a request is get, we simply feed the sign up
  # form (dynamically generated from database "forms" and "field_descriptions")
  # to web browser. When a request is post, we validate captcha first by calling
  # the method "recaptcha_valid?" of recaptcha (Ambethia third party plugin).
  # Another note is that this method has to be placed in the "except" part of
  # "before_action" to enable public access. Third note: the route from a url to
  # this method is specified in file config/routes.rb
  # Parameters:
  # * param1 - NONE
  # Returns:  NONE
  def add_user
    default_mode = default_html_mode?
    if request.get?
      # if a link "/accounts/new" is typed in the browser address, a request
      # "get" is sent to here. We just send the signup page to the user.
      @action_url = request.path
      render_sign_up_form
    elsif request.post?
      js_to_run = ''
      @page_errors = []

      @p = SignUpPresenter.new(@form_params)
      user, @page_errors = @p.process_form_params # creates a new user object

      # If all the tests passed, store the signup data, set the flash message to
      # let the user know if worked, and return the status and URL of the next
      # page to be displayed (the login page) to the javascript method that
      # called this.
      begin
        User.transaction do
          if @recaptcha_page_errors.empty? && @page_errors.empty?
            # Check to see if we're actually saving this data.  If so, make sure
            # that we haven't found any errors before we proceed.
            user.save!
            pdata = @p.profile_data
            user.update_security_question(pdata[:question_answers], @page_errors)
          end
          unless @recaptcha_page_errors.empty?
            @page_errors << "Verification section:<ul><li>#{@recaptcha_page_errors.join}</li></ul>"
          end
          raise ActiveRecord::Rollback , "Error creating User!!" unless @page_errors.empty?
        end # transaction
      rescue Exception => e
        SystemError.record_server_error(e, request, session)
        @page_errors <<
          'We are sorry, but an error occurred while trying to create your ' +
          'account. We have been notified about the problem and will look ' +
          'into it as soon as possible.'
      end

      if @page_errors.empty?
        cookies[:phr_user] =  { :value => User.generate_cookie(user),
          :expires => 1.year.from_now, :secure=>true } if cookies[:phr_user].nil?
        if default_mode && !@form_params[:cookie_checkbox_1].empty? &&
            @form_params[:cookie_checkbox_1] == '1'
          user.two_factors.create(:cookie => cookies[:phr_user],
            :user_id => user.id )
          user.save!
        end

        # If there is an invite_key for a shared access invitation on the
        # page, this person created an account so they could share access
        # to a phr based on an invitation from that phr's owner.  Finish
        # off the acceptance now that they've created the account.
        if !@form_params["invite_key"].blank?
          ShareInvitationController.implement_access(user, nil,
                                                     @form_params["invite_key"])
        end

        # send activation email
        vtoken = user.email_verifications[0].token
        DefMailer.verify_reg_email(user.name, vtoken, user.email).deliver_now
        #flash[:notice] = "User account " + @form_params[:user_name_1] +
        #  " was created successfully."
        flash[:notice] = "Thanks for signing up the new user account " + @form_params[:user_name_1] +
          ". An account activation email has been sent to your email address: #{user.email}."+
          " Please follow the instruction in the email to activate your account."
        if !default_mode
          redirect_to login_path
        else
          render :status => :ok,
            :plain => ({'target' => '/accounts/login'}).to_json
        end

        # Otherwise send a message back to the javascript client with the error
        # messages indicating the problem(s).
      else
        if !default_mode
          render_sign_up_form
        else
          logger.debug 'post request failed, @page_errors = ' +
            @page_errors.join('  ')
          render :status => :failed,
            :plain => {'javascript' => js_to_run ,
            'errors' => @page_errors}.to_json
        end
      end
    end # end elsif request.post?
  end # add_user


  # Redirect page if it's a demo system
  def check_demo_system
    # redirect if it's a demo system
    if DEMO_SYSTEM
      redirect_to demo_login_path(:format=>params[:format])
    end
  end


  # Redirect demo_login to login if it's a non-demo production system
  def check_demo_system2
    if !DEMO_SYSTEM && Rails.env == 'production'
      redirect_to('/accounts/login')
    end
  end


  # This is a method by which a user can change the profile users can change
  # email, password, openid, security questions if theirs account is
  # validated. We validate captcha first by calling the method
  # "validate_recap" of recaptch (a third party plug in). The simple steps of
  # installing, configuring refers http://www.loonsoft.com/recaptcha/
  # Parameters:
  # * param1 - no explicit parameters, but a default parameter "params"
  # Returns:  NULL
  def change_account_settings
    no_ajax = non_default_html_mode?
    @form_submission_method = :put
    @page_errors = []
    user = @user # @user gets set in authorize
    if (request.put? or request.post?) && !@form_params["save_changes_1"].nil?
      old_email = user.email
      ret = nil
      User.transaction do
        @p = AccountSettingsPresenter.new(@form_params)
        ret = user.update_profile_to_db(@p.profile_data, @page_errors)
        # If there was any error in save action, rollback the whole thing.
        raise ActiveRecord::Rollback if ret < 0
      end

      if @page_errors.size > 0
        if no_ajax
          flash[:error] = @page_errors.join(" ")
          render_account_settings_form
        else
          render :status => :failed, :plain => {'errors'=> @page_errors }.to_json
        end
      else
        if ret > 0
          # send notification email if valid email address on file
          if !old_email.blank?
            DefMailer.profile_update(user.name, old_email).deliver_now
          end
          @message = 'Your account settings were updated successfully.'
        else
          @message = 'There was no change to your account settings.'
        end

        if no_ajax
          flash[:notice] = @message
          redirect_to phr_records_path
        elsif params['from'] == 'popup'
          js = Hash.new
          js["javascript"] = "Def.getWindowOpener().Def.showNotice('#{@message}');  window.close() ;"
          render json: js
        else
          js = Hash.new
          js["javascript"] = "Def.getWindowOpener().Def.showNotice('#{@message}'); "
          render json: js
        end
      end
    elsif @form_params["delete_account_1"]
      redirect_to delete_account_path
    else  #end if request.post
      # Show the account settings page
      @data_hash = user.data_hash_for_update_account_settings
      @action_url = request.path
      render_account_settings_form
    end
  end  #end def change_profile


  # This is a method which lets a user modify password. It's a 3 step process
  # and this function handles various scenarios for step 2. User is
  # provided option to either request a reset link to be emailed to their email
  # account to change password online or answer challenge questions.
  def change_password
    @page_errors = []
    if request.post?
      if @form_params[:email_option_radio_1_1] == 'email'
        # Generate the link based on the session[:user_name]
        redirect_to :action => :get_reset_link
      else# submitting challenge question answers from Step 2
        if check_challenge_questions(@form_params)
          # check errors related to the correctness of the answers
          @user.is_answer_correct(@form_params[:ch_answ1_1_1_1],
            @form_params[:ch_answ2_1_1_1], @page_errors)
        else
          # if No option selected in step 2
          @page_errors << "Please select appropriate option and enter value in
                  required fields."
        end

        if @page_errors.empty?
          @user.reset_qa_answered_flag # clear answer_trial after answering questions
          #@user.trial_update
          @user.setup_reset_key
          # following code is equivalent to a reset link
          session[:user] = @user.name
          session[:reset_key] = @user.reset_key
          redirect_to :action=>:update_password
        else
          render_recover_pw_step_two(@user)  # sent back to step 2 page
        end
      end
    elsif request.get?
      render_recover_pw_step_two(@user)
    end
  end


  # Last step in the change password process. This function updates the password
  # if user entered correct password along with correct reset key.
  # The user gets here after choosing to reset their password via
  # answering security questions (as opposed to the reset link
  # option).  After answering those successfully, the user goes to the
  # change_password action, which then leads here on a POST from that
  # form with the new password.
  #
  # Parameters:
  # params: a hash from :fe to a hash which includes the following information
  #   required for password updating:
  #   - cpnew_passwd_1 the new password
  #   - cpconfm_passwd_1 the confirmed/re-typed new password
  # session: two values (i.e. user and reset_key) needed in order to qualify for
  #   password updating. The reset_key will be used to match with the one stored
  #   in the user record. The reset_key will be cleared after being verified in the
  #   before filter to prevent user from make a second post without getting a
  #   new reset key (see reset_preconditions in application_controller.rb for details).
  #
  # Returns:  redirects to login after successful update
  #           render the update page otherwise.
  #           redirects to login page if incorrect reset key or hacking attempts
  #           were found (see the before filter for details)
  def update_password
    @page_errors=[]
    if request.post?
      # updating user record with new password
      @user.password = @form_params[:cpnew_passwd_1]
      @user.password_confirmation = @form_params[:cpconfm_passwd_1]
      if @user.save
        DefMailer.password_reset(@user.name,@user.email).deliver_now
        flash[:notice] = "Password changed successfully."
        redirect_to login_path
      else
        # We need to re-create the reset key to give user another chance for password updating
        flash.now[:error] = @user.errors[:password].join(" ")
        @user = User.find(@user.id)  # @user record has be to error free when setup_reset_key
        @user.setup_reset_key
        session[:reset_key] = @user.reset_key
        render_recover_pw_step_three(@user)
      end # end updating user record with new password
    elsif request.get?
      render_recover_pw_step_three(@user)
    end
  end


  # This method generates and emails an account security reset link.
  # It has a before filter to generate the @user object after verifying the user name
  def get_reset_link
    if @user.email.blank? # no email associated with account.
      @page_errors = @@no_email_error
      @data_hash = {'user_name_1'=>@user.name}
      render_recover_pw_step_one
    else
      @user.setup_reset_key
      DefMailer.reset_link(@user.name, @user.reset_key, @user.email).deliver_now
      flash[:notice] = "A reset link has been sent to your email box:
        #{@user.masked_email}. It will expire after 60 minutes."
      redirect_to login_url
    end
  end


  # If cancelling the account security reset, clear out the reset_key to
  # prevent misuse.
  def expire_reset_key
    if !session[:user].blank?
      user = User.where(name: session[:user]).first
      user.clear_reset_key if user
    end
    head :ok
  end


  # This function resets users QA as well as password. Essentially used when
  # user cannot remember password as well as answers to questions
  def reset_account_security
    if request.post?
      @page_errors = []
      @p = ResetSecurityPresenter.new(@form_params)
      ret = @user.update_profile_to_db(@p.profile_data, @page_errors)
      if ret > 0
        flash[:notice] = "Security question(s) and/or password have been "+
            "updated for user:  #{@user.name}."
        DefMailer.profile_update(@user.name,@user.email).deliver_now
        redirect_to login_url
      else
        # We need to re-create the reset key to give user another chance for password updating
        # as the reset_key carried by params or session was cleared by the before filter (see
        # reset_preconditions in application_controller.rb for details)
        @user.setup_reset_key
        session[:reset_key] = @user.reset_key
        flash.now[:error] = (ret == 0) ? @@no_changes : @page_errors.join(" ")
        render_security_form(@user)
      end
    elsif request.get?
      render_security_form(@user)
    end
  end


  # This is a method which handles a case that users forgot their Account ID. We
  # ask a user the email linked with the account, and then redirect to next
  # page with option to verify challenge question or password. We validate
  # captcha first by calling the method "recaptcha_valid?" of recaptcha
  #
  # Parameters:
  # * param1 - default parameter "params"
  #
  # Returns:  true - successfully displayed next step page
  #           false - cannot identify account liinked with email.
  def forgot_id
    if request.get?
      render_recover_id_step_one
    elsif request.post?
      session[:user_email] = nil
      @data_hash = nil
      @page_errors= @recaptcha_page_errors || []

      if !@form_params[:user_email_1].blank? && @page_errors.empty?
        session[:user_email] = @form_params[:user_email_1]
        user = User.where(email: @form_params[:user_email_1]).first
        if user # forward to step2
          render_recover_id_step_two(user)
        else
          error_msg = "User with email #{@form_params[:user_email_1]}
            does not exist in our system."
          if non_default_html_mode?
            # For this kind of error, make the user solve another CAPTCHA,
            # so they can't automatically check a list of email addresses.
            flash[:error] = error_msg
            redirect_to_captcha
          else
            @page_errors << error_msg
            render_recover_id_step_one
          end
        end # if found == true
      else
        @data_hash = {'user_email_1'=>@form_params[:user_email_1]}
        if @form_params[:user_email_1].blank?
          @page_errors << 'Please enter your e-mail address. Your input was empty.'
        end
        render_recover_id_step_one
      end # if !@form_params
    end # end request.post
  end


  # This is a method which handles step 2 of the case that users forgot their
  #   Account ID. Depending on whether user selected the password or challenge
  #   question, the function verifies the appropriate entry for the account
  #   linked with the email. Parameters:
  # * param1 - default paramter "params" with field elements from the form
  #   Returns:  redirects to login page if successful or forgot_id_step2 if
  #   unsuccessful
  def forgot_id_step2
    if request.post? && session[:user_email]
      user = User.where(email: session[:user_email]).first
      @p = RecoverIdStepTwoPresenter.for_user(params[FORM_OBJ_NAME], user)
      data_size_ok = true
      begin
        @page_errors = @p.process_form_params
      rescue SecurityError => err_msg
        SystemError.record_server_error(err_msg, request, session)
        data_size_ok = false
      end

      if !data_size_ok
        redirect_to login_path
      else
        if !@page_errors.blank?
          render_recover_id_step_two(user)
        else
          flash[:notice] = "Your account ID has been sent to your email box:
                    #{session[:user_email]}."
          redirect_to login_path
        end
      end
    else
      render_html_status_page(400)
    end
  end


  # This is a method which handles a case that users forgot their passwords. We
  # ask a user the account name, and then provide a change_password web page.
  # We validate captcha first by calling the method "recaptcha_valid?" of
  # rack-recaptcha plugin.
  #  Parameters:
  # * param1 - no explicit parameters, but a default parameter "params"
  # Returns:  true - successfully changed the password false - failed to
  #   change the password
  def forgot_password
    if request.get?
      render_recover_pw_step_one
    elsif request.post?
      session[:user_name] = nil
      @data_hash = nil
      @page_errors= @recaptcha_page_errors || []
      user_name_param = @form_params[:user_name_1]
      # condition of exit this method Check Captcha

      # captcha is valid
      if !user_name_param.blank? && @page_errors.empty?
        user = User.where(name: user_name_param).first
        if user
          # create a data_hash structure to ask user security questions. The
          # security questions will be randomly selected and shown in the
          # reset_password page
          @data_hash = user.data_hash_for_reset_password
          if (@data_hash == nil)
            @page_errors << SECURITY_QUESTION_PROBLEM_MSG
            render_recover_pw_step_one
          else
            session[:user_name] = user_name_param
            redirect_to :action => :change_password # password reset step 2
          end # end of if (@data_hash == nil) check the data hash is not nill
        else
          user_name_error = User.non_exist_user_error(user_name_param)
          # For this kind of error, we need to send the user back to the
          # CAPTCHA, so someone can't run through a list of user names.
          if non_default_html_mode?
            flash[:error] = user_name_error
            redirect_to_captcha
          else
            @page_errors << user_name_error
            render_recover_pw_step_one
          end
        end # end of if user
      else
        @data_hash = {'user_name_1'=>user_name_param}
        @page_errors << 'Please specify a user name.' if user_name_param.blank?
        render_recover_pw_step_one
      end# end of if @page_errors.empty?
    end # request.post?
  end


  # Sets up the two factor question page for rendering.
  def create_twofactor(username, password)
    session[:user_name] = username
    session[:password] =  password
    make_data_hash(@user)
    @user.trial_update
    @user.save!
    render_two_factor(@user)
  end


  # Handles the user request coming in from Identity confirmation page with
  # recaptcha values. Log in user if correct answer to question as well as
  # recaptcha presented. Otherwise, redisplay confirm identity page or sent
  # to login page if data size limit exceeded.
  # Return: none
  def handle_two_factor
    @login = false
    @page_errors = []
    @user = nil
    # ie. user/pass correct, so ask challenge question
    @action_url=request.path # submit the form back here
    if !session[:user_name].blank? && !session[:password].blank?
      data_size_ok, @user = authenticate_and_check_data_sz(request,
                session[:user_name],session[:password])
    end

    if @user && data_size_ok
      good_answer = @user.check_answer(@form_params[:user_answ_1_1],@page_errors)
      if good_answer
        if @form_params[:cookie_checkbox_1_1] && @form_params[:cookie_checkbox_1_1] == '1'
          @user.two_factors.create(:cookie => cookies[:phr_user],
            :user_id => @user.id )
        end
        @user.reset_qa_answered_flag
        @user.save!
        login_successful(@user)
      else
        make_data_hash(@user)
        @user.trial_update
        @user.save!
        render_two_factor(@user)
      end # if good_answer
    else
      cookies.delete :phr_user
      @action_url="/accounts/login"
      @login_notice = SystemNotice.login_page_notice
      render_form('login')
    end # if !recaptcha_valid?
  end


  # Activates new user account using the activation link sent to user's email address
  def email_verification
    @page_errors = []
    if request.get?
      # render the email_verification page with a hidden token field
      @action_url="/accounts/email_verification"
      @data_hash = {:verification_token_1 => params[:verification_token]}
      render_form "email_verification"
    elsif request.post?
      username = @form_params[:user_name_1]
      password = @form_params[:password_1]
      vtoken = @form_params[:verification_token_1]

      @user = User.authenticate(username, password, @page_errors)
      # In this method, we need to have user record in order to match the input token
      # even if the user is inactive. Therefore, we need to remove the related error and
      # reload the inactive user after authenticating
      if @page_errors.include?(User::INACTIVE_ACCOUNT)
        @page_errors.delete(User::INACTIVE_ACCOUNT)
        @user = User.where(:name=>username).take if @user.nil?
      end

      flash_msg = nil
      if @user && @page_errors.empty?
        error_msg, flash_msg = EmailVerification.match_token(@user, vtoken)
        @page_errors << error_msg if error_msg
      end

      if @user.nil? || !@page_errors.empty?
        # show the current page with error msg
        @action_url= request.path # /accounts/email_verification (no parameters)
        @data_hash = {:verification_token_1 => vtoken }
        render_form "email_verification"
      else
        # show the done page with flash notice
        flash[:notice]= flash_msg
        render_login_form
        #render html: "Email Verification Done! Click <a href='/accounts/login'>Here</a> to log in now.".html_safe
        #render_form "email_verification_done"
      end
    end
  end



  # This is a signin method. The trickiest part of the method is the openid but
  #   we are not using it currently. Openid has two steps: first step is to
  #   render user a validation web page which is from openid provider. The user
  #   enters the account and password. The second step is to return a user's
  #   openid authentication back to our login method. One of parameters is
  #   "open_id_complete", if the value of this parameter is "1", this indicates
  #   that the openid is authenticated. For regular account, a conventional
  #   method, we directly validate the user name and password. Second note:
  #   Login does not need to validate captcha and this method has to be placed
  #   in the "except" part of "before_action" to enable public access. Third
  #   note: the rout from a URL to this method is specified in file
  #   config/routes.rb
  #   Parameters:
  # * param1 - NONE
  # Returns:  NONE
  def login
    next_page = nil
    # If this is a request for the login page, clear out session identifying
    # info and give them the page
    if request.get? || request.head?
      next_page = "login"
    # Else the user has filled out the page and here it is.  Process the input.
    elsif request.post?
      @page_errors = []
      # If no input came back from the page, put up the errors page
      if @form_params.empty?
        next_page = "bad_request"
      else
        data_size_ok, @user = authenticate_and_check_data_sz(request,
            @form_params[:user_name_1_1],@form_params[:password_1_1])

        if !data_size_ok
          params[:end_type] = 'data_overflow'
          next_page = 'logout'
        else
          has_user_cookies = !cookies[:phr_user].blank? && session[:user_name].blank?
          if !@user || !@page_errors.empty?
            cookies.delete :phr_user  if !@user && has_user_cookies
            next_page = 'login'
          else
            # Use when cookies already set.
            logged_in = has_user_cookies &&
              @user.two_factors.where(cookie: cookies[:phr_user]).first
            next_page = logged_in ? 'login_done' : 'two_factor'
          end
        end
      end
    end # request.post?

    case next_page
    when 'two_factor'
      # Sets up two factor authentication form with challenge question.
      create_twofactor(@form_params[:user_name_1_1],@form_params[:password_1_1])
    when 'login_done'
      login_successful(@user)
    when 'login'
      # clear out previous login
      session[:user_name] = nil
      session[:password] =  nil
      @user = nil
      @login_notice = SystemNotice.login_page_notice
      render_login_form
    when 'logout'
      logout
    when 'bad_request'
      render :file=>'public/errors/400.txt', :status=>:bad_request
    else
      raise 'Something wrong in login action'
    end # case
  end # login


  # This is a method to handle demo user logins
  # First it picks a demo user account from a demo account pool.
  # Then it logs in the user with the selected demo user account and
  # redirect to the phr management page.
  #
  # Parameters: None
  # Returns: None
  def demo_login
    # If this is a request for the login page, clear out session identifying
    # info and give them the page
    if request.get?
      # clear out previous login
      session[:user_name] = nil
      session[:password] =  nil
      @user = nil
      @action_url="/accounts/demo_login"
      @login_notice = SystemNotice.login_page_notice
      render_demo_login_form

    # Else the user has filled out the page and here it is.  Process the input.
    elsif request.post?
      @page_errors = []

      if @form_params['agree_chbox_1'] != '1'
        flash.now[:error] = 'Please mark the checkbox to indicate that you have '+
          'read and understood the purpose of the demo account.'
        render_demo_login_form
      else
        # If no input came back from the page, put up the errors page
        if @form_params.empty?
          render :file=>'public/errors/400.txt', :status=>:bad_request
        else
          # pick a demo user account from a demo account pool, where the demo account
          # has a user_type as 'D' (for demo) and has not been used before.
          @user = User.get_an_available_demo_account
          updated_rows = 0
          while @user && updated_rows == 0 do
            new_name = "Demo_#{rand(10000000000).to_s}"
            # mark this demo account as use and change the user name
            # check the used_for_demo flag again when updating
            updated_rows = User.where(:used_for_demo=>false).where(:id=>@user.id).update_all("used_for_demo=1, name='#{new_name}'")
            # if the record is not found (the user account is taken by another session )
            if (updated_rows == 0)
              # take another available user account and try again.
              @user = User.get_an_available_demo_account
            end
          end
          # log in the demo user
          # If successful authentication redirect to appropriate page
          if (@user && updated_rows == 1)
            login_successful(@user)
          else # run out of accounts
            @action_url="/accounts/demo_login"
            @login_notice = "We are running out user accounts for demo. " +
                "Please come back after 3:00 A.M. EST."
            render_demo_login_form
          end # if @user
        end # if !@form_params
      end # else the checkbox was checked
    end # request.post?
  end # demo_login


  # Authenticates a user and checks if data size limit exceeded.
  # returns : Array with a boolean which is true if data size not exceeded, and
  # false otherwise as well as user object.
  def authenticate_and_check_data_sz(request,username,pass)
    data_size_ok = true
    precon_ok = true
    user = nil

    # Do a precheck for presence of a username or password.
    f = Form.where(form_name: 'login').first
    fd = f.field_descriptions.where(target_field: 'user_name').first
    tip = fd.getParam('tooltip')

    if (username.blank? || (!tip.blank? && username.eql?(tip)))
      @page_errors << @@user_name
      precon_ok = false
    end
    if pass.blank?
      @page_errors << @@password
      precon_ok = false
    end

    # authenticate by using username and password.
    if precon_ok
      begin
        user = User.authenticate(username,pass,@page_errors)
      rescue DataOverflowError => err_msg
        SystemError.record_server_error(err_msg, request, session)
        user = User.find(err_msg.user_id)
        data_size_ok = false
      end
    end
    return [data_size_ok,user]
  end


  # This is called after the login method determines that this is a valid login.
  # It sets up the variables and clears information, including clearing the
  # current session id so that a new one can be generated.  This does NOT
  # log the login event in the usage statistics.  That is done by the
  # get_new_session_id after-filter.
  #
  # Parameters:
  # * user the user object for the user logging in
  # Returns:
  # * none
  #
  def login_successful(user)

    uri = session[:original_uri]
    user.reset_qa_answered_flag
    user.trial_update
    user.save!

    reset_session_info(user)
    session[:cur_ip] = request.env["REMOTE_ADDR"]
    # set flash message reminder for user to update email address if last
    # reminder > 3 months ago.
    set_account_update_reminder(user)
    record_login
    if !uri.blank? && check_uri(uri)
      redirect_to(uri)
    elsif non_default_html_mode?
      redirect_to('/phr_records')
    elsif user.admin?
      redirect_to('/admin_home')
    else
      redirect_to('/phr_home?logging_in=true')
    end # action.nil
  end


  # This records a user's successful login in the usage statistics.
  #
  def record_login
    begin
      @user ||= current_user
      report_data = [['login',
                      Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                      {"old_session" => @old_session_id.to_s}]].to_json
      UsageStat.create_stats(@user,
                             nil,
                             report_data,
                             nil,
                             session[:cur_ip],
                             false)

    # If we get an exception from the call, we expect that it's a problem
    # with the user object.  Record the error so that it will get mailed
    # to folks, but don't stop processing.  (Seems like this couldn't
    # happen, but that's usually a silly thing to assume)
    rescue Exception => excep
      SystemError.record_server_error(excep, request, session)
    end
  end # record_login


  # This is a logout method. We simply kick the user out of our session
  # Parameters:
  # * if specified, we use params[:end_type] to determine what type of
  #   logout should be recorded (user requested, timeout, data overflow).
  #   Otherwise we assume 'user_requested'.
  # Returns:  NULL
  def logout

    if params.nil? || params[:end_type].nil?
      end_type = 'user_requested'
    else
      end_type = params[:end_type]
    end
    # This code has been moved to the end_user_session in the base
    # application controller so that a session can be ended in a manner
    # appropriate to the problem that ended it.  For example, see the
    # check_for_data_overflow method in the application controller.
#    session[:user_id] = nil
#    session[:_csrf_token] = nil
#    request.env.delete('rack.session.record')
#    request.env.delete('rack.request.cookie_hash')
#    request.env.delete('rack.request.cookie_string')
    if end_type == 'after_overflow'
#      if !flash[:error].nil? &&
#         !(flash[:error].include? User::DATA_LIMIT_EXCEEDED)
        flash[:error].nil? ? flash[:error] = User::DATA_LIMIT_EXCEEDED :
                             flash[:error] << '\n' + User::DATA_LIMIT_EXCEEDED ;
#      end
    else
      end_user_session(end_type)
    end
    # redirect if it's a demo system
    if DEMO_SYSTEM
      @action_url="/accounts/demo_login"
      render_demo_login_form
    else
      render_login_form
    end
  end


  # This method sets the state of a session It can be one of three values
  # active, inactive and logoff Parameters session_status - status of the
  # session
  # Returns: NONE
  def set_session_state
    status = params[:session_status]
    session[:status] = status
    head :ok
  end


  # This method returns the state of the session
  # Parameters:
  # Return:NONE
  def check_session_state
    status = session[:status]
    render(:plain=>status)
  end


  # This method sets a message notifying the user why they've been logged off,
  # clears the original uri in the session, sets the end type so that the
  # logout is recorded as a timeout, and calls logout to logs off the user.
  def timeout_logoff
    session[:original_uri] = nil
    flash[:notice] = "You have been logged out because your session timed out."
    params[:end_type] = 'timeout'
    logout
  end


  # This method deletes the account and associated profiles.
  # Return: text 'Valid' , status 200 when account deleted siuccessfully
  #         text 'Invalid ..', status 200 when incorrect password provided/locked account
  #         status 500 when there is an exception/error
  def delete_account
    non_default_mode = non_default_html_mode?
    if request.get? && non_default_mode
      # Show the confirmation page
      render_confirm_account_deletion
    elsif request.delete?
      begin
        user_id = session[:user_id]
        user = User.find(user_id)
        password = params[:password]
        page_errors = []
        user = User.authenticate(user.name,password, page_errors)
        if user
          profiles = user.profiles
          profiles.each do |profile|
            profile.soft_delete
          end

          # Now permanently delete the profiles and associated phrs data. It
          # includes records that were previously deleted individually by user.
          # This method can be commented out to keep the profile data after
          # account delete. pds = DeletedProfile.where(user_id: user_id)
          # pds.each do |pd|
          #  pd.delete_profile_records_perm
          # end
          qas = user.question_answers
          qas.each do |qa|
            qa.destroy
          end
          end_user_session('account_deleted')
          # Destroy user after the session is cleared since user object needed.
          user.destroy
          flash[:notice] = 'Account deleted.  You are logged out.'
          if non_default_mode
            redirect_to login_path
          else
            flash.keep
            render :plain => 'Valid', :status => 200
          end
        else
          if page_errors.empty?
            page_errors << 'Invalid Password. Please re-enter your password.'
          end
          if non_default_mode
            flash.now[:error] = page_errors.join
            render :template=>'basic/login/confirm_account_deletion', :layout=>'basic'
          else
            render :plain => page_errors.join, :status => 200
          end
        end
      rescue Exception => excep
        SystemError.record_server_error(excep, request, session)
        flash[:notice] = 'There was an error deleting your account.  Please '+
          'contact us for help.'
        end_user_session('account_deleted')
        if non_default_mode
          redirect_to phr_records_path
        else
          render :plain => flash[:notice], :status => 500
        end
      end
    end
  end


  # Shows a page with browser support information listed as follows:
  # 1) Name and version of the browser detected and its compatibility with our
  # current system;
  # 2) Some compatible browsers which works best with our current system;
  def browser_support; end


  # End of action methods

  # Class methods

=begin
  # Loads class variables for the login page (currently just those needed by the
  # basic mode).
  def self.load_class_vars
    # Store the "class" variables as instance variables on the class object
    # so that the variables are not shared amongst subclasses.
    if !defined? @login_fds
      class << self
        attr_accessor :login_fds, :login_labels
      end
      field_form = Form.where(form_name: 'login').first
      fds = field_form.field_descriptions
      fd_hash = {} # hash of field names to FieldDescription objects
      %w{splash user_name}.each {|f| fd_hash[f] = fds.where(target_field: f).first}

      label_hash = {} # hash of database field names to display labels
      fd_hash.each do |name, fd|
        label_hash[name] = fd.display_name
      end
      self.login_fds = fd_hash
      self.login_labels = label_hash
    end
  end


  # Loads the class variables needed by the basic HTML mode demo login page
  def self.load_demo_class_vars
    if !defined? @demo_login_fds
      class << self
        attr_accessor :demo_login_fds, :demo_login_labels
      end
      field_form = Form.where(form_name: 'demo_login').first
      fds = field_form.field_descriptions
      fd_hash = {} # hash of field names to FieldDescription objects
      label_hash = {} # hash of database field names to display labels
      fds.where(target_field: %w{instructions2 agree_chbox submit}).each do |fd|
        f = fd.target_field
        fd_hash[f] = fd
        label_hash[f] = fd.display_name
      end
      self.demo_login_fds = fd_hash
      self.demo_login_labels = label_hash
    end
  end
=end


  # Loads class variables for the specified form/page (currently just those needed by the
  # basic mode).
  def self.load_basic_form_class_vars(form_name=nil, field_list=nil)
    fd_var = "#{form_name}_fds"
    label_var = "#{form_name}_labels"

    # Store the "class" variables as instance variables on the class object
    # so that the variables are not shared amongst subclasses.
    if !self.instance_variable_names.include?  "@#{fd_var}"
      self.class_eval <<-EOF
        class << self
          attr_accessor :#{fd_var}, :#{label_var}
        end
      EOF
      logger.debug("\n\n\ $$$$$$$  the form name is : #{form_name}")
      field_form = Form.where(:form_name => form_name).first
      logger.debug("\n\n\ $$$$$$$  the form name is : #{form_name}")
      logger.debug("\n\n\ $$$$$$$  the field form is : #{field_form.inspect}")
      fds = field_form.field_descriptions
      fd_hash = {} # hash of field names to FieldDescription objects
      field_list.each {|f| fd_hash[f] = fds.where(target_field: f).first}

      label_hash = {} # hash of database field names to display labels
      fd_hash.each do |name, fd|
        label_hash[name] = fd.display_name
      end
      self.send("#{fd_var}=", fd_hash)
      self.send("#{label_var}=", label_hash)
    end
    [self.send(fd_var), self.send(label_var)]
  end


  private

  # Return the value of key :fe from the controller parameter. Default to ActionController::Parameters.new if the key
  # :fe is missing.
  def get_form_params
    if request.put? || request.post?
      @form_params = params.has_key?(:fe) ? params[:fe] : ActionController::Parameters.new
    end
  end

  # An around filter for validating captcha in both basic and standard mode
  def captcha
    @recaptcha_page_errors = []
    # An around filter for the basic HTML mode, to show a CAPTCHA
    # (if haven't already passed it).  On GET requests,
    # if the captcha hasn't been passed the user is taken to the captcha page.
    # When the user passes the captcha a flag is stored in the session which
    # allows the GET request through, and the user is redirected to the original
    # GET request.  On POST requests, after the request completes if flash[:error]
    # is nil (validation for the post successed) then the session flag is cleared
    # so that the next time the user will see the captcha again.
    if non_default_html_mode?
      #session[:passed_basic_captcha]=true if Rails.env == "development" # this line for debugging only
      if !session[:passed_basic_captcha]
        redirect_to_captcha
        return
      end
      yield # to the action
      if !request.get? && flash[:error].nil? && @page_errors.size == 0
        # POST or PUT or DELETE
        # Clear the flag so the next time the user goes back to the captcha
        session.delete(:passed_basic_captcha)
      end
    else
      # update @recaptcha_page_errors with any errors found
      if request.post?
        # Now validate the registration process related data. Validate the captcha
        # response by calling the method "recaptcha_valid?" of the rack-recaptcha
        # third party plugin.
        if params['g-recaptcha-response'].blank?
          @recaptcha_page_errors << @@need_captcha_input_msg.html_safe
        else
          if !verify_recaptcha
            @recaptcha_page_errors << @@invalid_captcha_msg.html_safe
            str = 'captcha_failure'
          else
            str = 'captcha_success'
          end
          action_name = request.parameters["action"]
          action_name = "registration" if action_name == "add_user"
          u_data = {"mode"=>"full","source"=>action_name,"type"=>"visual"}
          # record the captcha result in the usage stats
          report_params =
            [[str,Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),u_data]]
          UsageStat.create_stats(@user,
                                 nil,
                                 report_params.to_json,
                                 request.session.id,
                                 session[:cur_ip],
                                 false)
        end
      end
      yield
    end
  end


  # Stores the current request's URI and redirects to the Basic HTML captcha page.
  def redirect_to_captcha
    session.delete(:passed_basic_captcha)
    session[:captcha_protected_uri] = request.path
    redirect_to captcha_path
  end


  # Shows the "forgot_id" step 1 form.
  def render_recover_id_step_one
    if non_default_html_mode?
      @p = RecoverIdStepOnePresenter.new
      @page_title = @p.form.form_title
      render :template=>'basic/login/recover_id_step_one', :layout=>'basic'
    else
      @action_url=request.path # return the form back here
      render_form('forgot_id')
    end
  end


  # Shows the "forgot_id" step 2 form.
  #
  # Parameters:
  # * user - the user object corresponding to the submitted email address
  def render_recover_id_step_two(user)
    if non_default_html_mode?
      @p = RecoverIdStepTwoPresenter.for_user(nil, user)
      @page_title = @p.form.form_title
      render :template=>'basic/login/recover_id_step_two', :layout=>'basic'
    else
      @data_hash = user.data_hash_for_forgot_id if user
      @action_url = '/accounts/forgot_id_step2'
      render_form('forgot_id_step2')
    end
  end


  # Shows the "forgot_password" step 1 form.
  def render_recover_pw_step_one
    if non_default_html_mode?
      @p = ResetPwStepOnePresenter.new
      @page_title = @p.form.form_title
      render :template=>'basic/login/reset_pw_step_one', :layout=>'basic'
    else
      @action_url=request.path # submit the form back here
      render_form('forgot_password')
    end
  end


  # Shows the "forgot_password" step 2 form.
  #
  # Parameters:
  # * user - the user object corresponding to the submitted accountID
  def render_recover_pw_step_two(user)
    if non_default_html_mode?
      @p = ResetPwStepTwoPresenter.for_user(params[FORM_OBJ_NAME], user)
      @page_title = @p.form.form_title
      render :template=>'basic/login/reset_pw_step_two', :layout=>'basic'
    else
      @data_hash = user.data_hash_for_reset_password
      @action_url="/accounts/change_password"
      render_form('reset_password_step2')
    end
  end


  # This method renders step3 password reset page
  #
  # Parameters:
  # * user - the user object corresponding to the submitted accountID
  def render_recover_pw_step_three(user)
    # TODO:: May need code for basic_mode only. -Frank
    @data_hash = { 'cppasswd_subgrp' => { 'user_name'=>user.name } }
    @action_url="/accounts/update_password"
    render_form('reset_password_step3')
  end


  # Shows the login form
  def render_login_form
    @action_url= login_path
    if non_default_html_mode?
      load_basic_login_vars
      form = Form.where(form_name: 'login').first
      @page_title = form.form_title
      render :template=>'basic/login/login', :layout=>'basic'
    else
      render_form('login')
    end
  end

  # Shows the demo login form
  def render_demo_login_form
    if non_default_html_mode?
      load_basic_demo_login_vars
      form = Form.where(form_name: 'demo_login').first
      @page_title = form.form_title
      render :template=>'basic/login/demo_login', :layout=>'basic'
    else
      render_form('demo_login')
    end
  end


  # Shows the account sign up form
  def render_sign_up_form
    if non_default_html_mode?
      @p = SignUpPresenter.new(params[FORM_OBJ_NAME]) if !@p
      @page_title = @p.form.form_title
      render :template=>'basic/login/sign_up', :layout=>'basic'
    else
      @action_url = request.path
      @exp_account_name = EXP_ACCOUNT_NAME # needed to render a default_value
      @form = Form.where(:form_name=>'signup').take
      @form_subtitle = @form.sub_title.html_safe
      render_form('signup')
    end
  end


  # Shows the account settings form
  def render_account_settings_form
    if non_default_html_mode?
      form_data = params[FORM_OBJ_NAME]
      if !form_data["save_changes"].nil? # the user submitted the form
        @p = AccountSettingsPresenter.new(form_data)
      else
        @p = AccountSettingsPresenter.current_settings(@user)
      end
      @page_title = @p.form.form_title
      render :template=>'basic/login/account_settings', :layout=>'basic'
    else
      @action_url = request.path
      render_form('change_profile')
    end
  end


  # Shows the confirm account deletion page (used for basic mode only)
  def render_confirm_account_deletion
    @page_title = 'Confirm Account Deletion'
    @p = AccountSettingsPresenter.new
    render :template=>'basic/login/confirm_account_deletion', :layout=>'basic'
  end


  # Loads the instance variables needed for the basic mode of the login page.
  def load_basic_login_vars
    form_name = "login"
    field_list = %w{splash user_name}
    @login_fds, @login_labels = self.class.load_basic_form_class_vars(form_name, field_list)
  end


  # Loads the instance variables needed for the basic mode of the demo login page.
  def load_basic_demo_login_vars
    form_name = "demo_login"
    field_list = %w(instructions2 agree_chbox submit)
    @demo_login_fds, @demo_login_labels = self.class.load_basic_form_class_vars(form_name, field_list)
  end


  # Loads the instance variables needed for the basic mode of the two factor page.
  def load_basic_two_factor_vars
    form_name="two_factor_question"
    field_list = %w(verify_identity_grp user_name user_quest user_answ  cookie_checkbox)
    @fds, @labels = self.class.load_basic_form_class_vars(form_name, field_list)
  end


  # Renders account security page.
  # Parameters:
  # * user - the user object corresponding to the requested accountID
  def render_security_form(user)
    if non_default_html_mode?
      form_data = params[FORM_OBJ_NAME]
      if form_data && request.post? # the user submitted the form
        @p = ResetSecurityPresenter.new(form_data)
      else
        @p = ResetSecurityPresenter.current_settings(user)
      end
      @page_title = @p.form.form_title
      render :template=>'basic/login/reset_security', :layout=>'basic'
    else
      @data_hash = user.data_hash_for_reset_profile_security
      @action_url = '/accounts/reset_account_security'
      render_form('reset_account_security')
    end
  end


  # Renders two factor authorization form. This form presents a challenge
  # question when user logs in from a unregistered/new computer. After user
  # successfully answers the challenge question and checks the checkbox labeled
  # as "Remember the computer ...", a cookie is added to the browser
  # to identify the computer. The identified/registered computers do not
  # need to answer challenge question and bypass this step.
  # Parameters:
  # * param1 -  use name or object
  # Returns: none
  def render_two_factor(user)
    @action_url="/accounts/two_factor" # return the form back here
    cookies[:phr_user] = { :value => User.generate_cookie(user),
                            :expires => 1.year.from_now, :secure=>true } if cookies[:phr_user].nil?
    if non_default_html_mode?
      @form = Form.where("form_name"=>"two_factor_question").take
      load_basic_two_factor_vars
      render :template=>"basic/two_factor/two_factor", :layout=>"basic"
    else
      #@action_url="/accounts/two_factor" # return the form back here
      @user = user
      @user_masked_email = @user.masked_email # needed for reset_instr's default value
      render_form('two_factor_question')
      @user_name = nil
    end
  end


  # This method used for checking the challenge question and answers presence
  # in the form parameters.
  # Parameters:
  # * param1 - default parameter form_params
  # Returns:  true if Q/As are ok.
  #           false if not all present
  def check_challenge_questions(form_params)
    return form_params[:reset_link].blank? &&
              !form_params[:ch_answ1_1_1_1].blank? &&
              !form_params[:ch_answ2_1_1_1].blank?
  end


  # Checks if the user can be forwarded to the URI after login
  # Parameters:
  # * param1 - uri
  # Returns:  true/false
  def check_uri(uri)
    uri_allow = false
    if !uri.blank?
      @@regexWhiteList.each { |pattern|
        regex = Regexp.new(pattern)
        if  regex.match(uri)
          uri_allow = true
          break ;
        end
      }
    end
    return uri_allow
  end


  # Makes data hash for two factor authentication question page
  #  Parameters
  #   param1 - user name or User object
  #   Returns:  none
  def make_data_hash(u)
    if !u.blank?
      if (u.kind_of? String)
        user = User.where(name: u).first
      elsif u.kind_of? User
        user = u
      end
      if user != nil
        @data_hash = user.data_hash_for_two_factor
        if (@data_hash == nil)
          @page_errors << SECURITY_QUESTION_PROBLEM_MSG
        end
      else
        @page_errors << 'The user account for "'+ u.to_str + '" does not exist.'
      end
    else
      @page_errors << 'PLease provide an existing user account.'
    end
  end


  # #reset_session has a bug. env.delete clears the session information from env
  # enabling the regeneration of a new session_id. Without this, new session_id
  # does not get generated due to the bug.
  # Parameters:
  #    param1 : user object
  def reset_session_info(user)

    @old_session_id = session[:id]
    csrf_token = session[:_csrf_token]
    request.env.delete('rack.session.record')
    request.env.delete('rack.request.cookie_hash')
    request.env.delete('rack.request.cookie_string')

    # Prevent session fixation by issuing new session ID after login or login
    #  attempt
    page_view = session[:page_view]
    was_redirect = session[:was_redirect]

    reset_session
    # user is validated so far. Now we are going to transfer some session info
    # to the new session
    session[:user_id] = user.id
    session[:_csrf_token] =  csrf_token
    session[:status] = 'active'
    session[:page_view] = page_view
    session[:was_redirect] = was_redirect # does not seem to help in rails 2; will review further in rails 3
  end


  # Displays a flash message reminding user to update email address if no
  # longer valid. Displayed on login if last display > 3 months ago
  # Parameters
  #   param1 - user object
  #   Returns:  none
  def set_account_update_reminder(user)
    if user.last_email_reminder.blank?
      user.last_email_reminder = Date.today()
      user.save
    elsif user.last_email_reminder.to_s < Date.parse(3.months.ago.to_s).to_s
      basic_link ="<a href='#{account_settings_url}'>account settings</a>"
      popup_link ='<a href="javascript:void(0)" onclick="openPopup(this, '+
        '\'/accounts/change\', \'Account Settings\', \'\', \'account_settings\', true); '+
        'return false;" >account settings</a>'
      as_link = default_html_mode? ? popup_link : basic_link
        if user.email.blank?
        msg = "There is no email address associated with this account.  We '+
         'strongly recommend that you add one via the #{as_link} page.  "
      else
        msg = 'The email address associated with this account is '+
        "#{user.email}. If this is incorrect or you no longer have access to "+
        "this email account, please update your #{as_link} with a current "+
        "email address.  "
      end
      flash[:notice] = msg.html_safe + 'A correct email address is'+
        " essential to regain account access if you should forget your username. It "+
        "also allows us to communicate to you any urgent and important information."
      user.last_email_reminder = Date.today()
      user.save
    end
  end


  # A before filter for redirecting user to proper page if the user already
  # logged in. It is used by login and demo_login actions.
  def check_logged_in_user
    # If the user asked for a particular page view mode (basic versus default)
    # then switch to that and store it in the session; otherwise continue
    # with the current setting.
    session[:page_view] = "mobile" if mobile_agent?
    session[:page_view] = params[:format] if params[:format]

    # If the user is already logged in, redirect to the profiles management
    # page - or the admin page or basic mode page - whatever's appropriate
    if user = session[:user_id] && User.find_by_id(session[:user_id])
      if non_default_html_mode?
        redirect_to('/phr_records')
      elsif user.admin?
        redirect_to('/admin_home')
      else
        redirect_to('/phr_home')
      end
    end
  end

end
