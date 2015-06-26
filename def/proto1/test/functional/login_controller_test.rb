require 'test_helper'

class LoginControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
    @request.env['rack.session.record'] = Session.new
    @request.env['rack.session.record'].session_id = 'sessionidhere'

  end

  def test_demo_login
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
                                                    'forms', 'db_table_descriptions', 'db_field_descriptions',
                                                    'usage_stats'])

    # mark all demo accounts used
    User.where(:account_type=>DEMO_ACCOUNT_TYPE).update_all("used_for_demo=1")
    users = User.where(:account_type=>DEMO_ACCOUNT_TYPE, :used_for_demo=>false)
    assert_empty users

    # add 3 demo accounts
    Util.create_demo_accounts
    # user1 = create_test_user({:account_type=>DEMO_ACCOUNT_TYPE, :used_for_demo=>false, :name=>'PHR_Demo1', :email=>'demo1@two.three.four'})
    # user2 = create_test_user({:account_type=>DEMO_ACCOUNT_TYPE, :used_for_demo=>false, :name=>'PHR_Demo2', :email=>'demo2@two.three.four'})
    users = User.where(:account_type=>DEMO_ACCOUNT_TYPE, :used_for_demo=>false)
    assert_equal 3, users.length

    get :demo_login, {}, {}
    assert_response :success

    # checkbox not checked
    post :demo_login, {:fe=>{:agree_chbox_1=>'0'}}
    assert_response :success
    assert @response.body.index('Please mark the checkbox')
    assert_not_nil flash[:error]

    # demo login, 3 times
    post :demo_login, {:fe=>{:agree_chbox_1=>'1'}}
    assert_redirected_to '/phr_home?logging_in=true'
    assert_nil flash[:error]
    get :logout
    assert_response :success
    post :demo_login, {:fe=>{:agree_chbox_1=>'1'}}
    assert_redirected_to '/phr_home?logging_in=true'
    assert_nil flash[:error]
    get :logout
    assert_response :success
    post :demo_login, {:fe=>{:agree_chbox_1=>'1'}}
    assert_redirected_to '/phr_home?logging_in=true'
    assert_nil flash[:error]
    get :logout
    assert_response :success

    # 3 demo accounts are used
    users = User.where(:account_type=>DEMO_ACCOUNT_TYPE, :used_for_demo=>false)
    assert_empty users

    # one more demo login and there are [DEMO_ACCOUNT_INCREMENTAL - 1] demo account left
    post :demo_login, {:fe=>{:agree_chbox_1=>'1'}}
    assert_redirected_to '/phr_home?logging_in=true'
    assert_nil flash[:error]
    users = User.where(:account_type=>DEMO_ACCOUNT_TYPE, :used_for_demo=>false)
    assert_equal 2, users.length
    get :logout
    assert_response :success

    # need to test concurrent demo logins (how?)
  end

  def test_login_page
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions', 'db_field_descriptions',
        'usage_stats'])
    user = create_test_user

    get :login, {}, {}
    assert_response :success

    # Try an invalid login attempt (empty form data)
    post :login, {:fe=>{:user_name_1_1=>'', :password_1_1=>''}}, {}
    assert_response :success
    assert @response.body.index('Please enter')

    # Try an invalid login attempt (missing all form data)
    post :login, {}, {}
    assert_response :bad_request
    assert @response.body.index('Bad Request')

    # Check the basic mode
    session_info = {:page_view=>'basic'}
    get :login, {}, session_info
    assert_response :success
    assert_not_nil @response.body.index('Current page mode:  Basic HTML')

    # Try a bad login attempt
    post :login, {:fe=>{:user_name_1_1=>user.name, :password_1_1=>'wrong'}},
      session_info
    assert_response :success
    assert @response.body.index('invalid')

    # Try an invalid login attempt (empty form data)
    post :login, {:fe=>{:user_name_1_1=>'', :password_1_1=>''}},
      session_info
    assert_response :success
    assert @response.body.index('Please enter')

    # Try an invalid login attempt (missing all form data)
    post :login, {}, session_info
    assert_response :bad_request
    assert @response.body.index('Bad Request')

    # Try a good login attempt
    post :login, {:fe=>{:user_name_1_1=>user.name, :password_1_1=>'A password'}},
      session_info
    assert_response :success
    assert @response.body.index('/accounts/two_factor') # confirm identity page

    # Try going through the two factor page
    session_info[:user_name] = user.name
    session_info[:password] = 'A password'
    post :handle_two_factor, {:form_name=>'login', :fe=>{:user_answ_1_1=>'1',
        :cookie_checkbox_1_1=>'1', :user_name_1_1=>user.name}}, session_info
    assert_redirected_to '/phr_records'

    # Make sure the login got recorded on successful completion of
    # the challenge question login
    rept = user.usage_stats.order('id desc').first
    assert_equal(@request.env["REMOTE_ADDR"], rept.ip_address)
    assert_equal('login', rept.event)

    # Log out and confirm we get the basic mode login page
    get :logout
    assert_response :success
    assert_not_nil @response.body.index('Current page mode:  Basic HTML')

    # Switch to standard mode
    session_info = {:page_view=>nil}
    get :login, {}, session_info
    assert_response :success
    assert_nil @response.body.index('Current page mode:  Basic HTML')

    # The NIH scan reported being able to access URLs like /accounts/demo-login.tmp
    # which look like backup files (to the scanner).  Make sure our routes do
    # not allow that.
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path('/accounts/demo_login.tmp')
      #assert_recognizes({}, '/accounts/demo_login.tmp') # should be an invalid route
    end
    # But make sure that the the basic/default login URL work
    assert_routing '/accounts/login.basic',
      {:controller=>'login', :action=>'login', :format=>'basic', :form_name=>'login'}
    assert_routing '/accounts/login.default',
      {:controller=>'login', :action=>'login', :format=>'default', :form_name=>'login'}

    @request.env['rack.session.record'] = Session.new
    @request.env['rack.session.record'].session_id = 'sessionidhere'
    session_info[:user_id] = user.id

    # Log in and confirm we get the /phr_home page - because there is already
    # a user id in the session info.
    # event gets logged in the usage stats
    post :login, {:fe=>{:user_name_1_1=>user.name, :password_1_1=>'A password'}},
      session_info
    assert_redirected_to '/phr_home'

    # Log out and confirm we are still in standard mode
    get :logout
    assert_response :success
    assert_nil @response.body.index('Current page mode:  Basic HTML')

    # now test to make sure the ip address is getting set in the usage data
    session_info[:cur_ip] = @request.env["REMOTE_ADDR"]
    put :logout, {}, session_info
    rept = user.usage_stats.order('id desc').first
    assert_equal(@request.env["REMOTE_ADDR"], rept.ip_address)
    assert_equal('logout', rept.event)
    assert_equal('user_requested', rept.data["type"])

    # Reset the session and the session_info so this will be a "new" login.
    # If the session_info has a user_id, this will be interpreted as a login
    # from someone who's already logged in, and will just go to the appropriate
    # next page for the user.
    @request.env['rack.session.record'] = Session.new
    @request.env['rack.session.record'].session_id = 'sessionidhere'
    session_info[:user_id] = nil

    post :login, {:fe=>{:user_name_1_1=>user.name, :password_1_1=>'A password'}},
      session_info

    rept = user.usage_stats.order('id desc').first
    assert_equal(@request.env["REMOTE_ADDR"], rept.ip_address)
    assert_equal('login', rept.event)
    assert_equal({"old_session"=>""}, rept.data)


    # Try to log in when data overflow condition exists; check usage stats
    # Set the daily size to overflow and clear the user id from the
    # session_info object so the login request won't assume this user is
    # already logged in.
    user.daily_data_size = 10000001
    session_info[:user_id] = nil
    user.save!
    post :login, {:fe=>{:user_name_1_1=>user.name, :password_1_1=>'A password'}},
      session_info
    assert_response :success
    assert @response.body.index(' <title>Welcome to the')
    rept = user.usage_stats.order('id desc').first
    assert_equal(rept.event, 'logout')
    assert_equal({"type"=>"data_overflow"}, rept.data)
  end # test_login_page


  # Tests the basic HTML mode signup page.  Might test the regular mode later.
  def test_account_signup
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'text_lists', 'text_list_items', 'db_table_descriptions',
        'db_field_descriptions'])

    get :add_user, {}, {:page_view=>'basic'}
    assert_redirected_to captcha_path

    get :add_user, {}, {:passed_basic_captcha=>true, :page_view=>'basic'}
    assert_response :success

    # Make sure the fixed question list does not use coded values.  Currently,
    # this is one of three cases where the processing does not expect codes
    # but rather the display strings themselves.  It is not important that it
    # remain such a case, but we don't want it to change accidentally without
    # the processing code being updated (as happened).
    assert_nil @response.body.index('fe_su_fix_quest_C_1_1')
    assert_not_nil @response.body.index('fe_su_fix_quest_1_1')

    # If there are flash errors when we post, we should still have the flag
    # set (from passing the captcha)
    post :add_user, {:fe=>{}}, {:passed_basic_captcha=>true, :page_view=>'basic'}
    assert @controller.page_errors.size > 0
    assert @request.session[:passed_basic_captcha]

    # Test a successful account signup
#    form_params = {:fe=>{:agree_chbox_1=>'1', :user_name_1=>'pl_temp1',
#      :password_1=>'abcABC123', :confirm_password_1=>'abcABC123',
#      :experimental_1_1=>EXP_ACCOUNT_NAME, :su_fix_quest_1_1=>'one',
#      :su_fixansw_1_1=>'1', :su_fix_quest_1_2=>'two', :su_fixansw_1_2=>'2',
#      :su_selfquest_1_1=>'1', :su_selfansw_1_1=>'1', :su_selfquest_1_2=>'2',
#      :su_selfansw_1_2=>'1', :dob_1=>'1993/2/3', :pin_1=>'1234',
#      :admin=>'1', :admin_1=>'1'}
#    }
    form_params = {:fe=>{:agree_chbox_1=>'1', :user_name_1=>'pl_temp1',
      :password_1=>'abcABC123', :confirm_password_1=>'abcABC123',
      :su_fix_quest_1_1=>'one', :su_fixansw_1_1=>'1', :su_fix_quest_1_2=>'two',
      :su_fixansw_1_2=>'2', :su_selfquest_1_1=>'1', :su_selfansw_1_1=>'1',
      :su_selfquest_1_2=>'2', :su_selfansw_1_2=>'1',
      :email_1=>'iamanemail@address.com',
      :email_confirmation_1=>'iamanemail@address.com',
      :admin=>'1', :admin_1=>'1'}
    }

    post :add_user, form_params, {:passed_basic_captcha=>true, :page_view=>'basic'}

    assert @controller.page_errors.size == 0, @controller.page_errors.inspect
    assert_redirected_to login_path
    assert_nil @request.session[:passed_basic_captcha]
    assert_not_nil flash[:notice]
    # Make sure the created user is not an admin (in spite of the params above)
    assert !User.where(name: 'pl_temp1').first.admin

    # Confirm that if we post again we will be redirected to the captcha.
    post :add_user, form_params, @request.session.to_hash
    assert_redirected_to captcha_path
  end


  # Tests the verify identity and account settings pages.
  def test_account_settings
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'text_lists', 'text_list_items', 'db_table_descriptions',
        'db_field_descriptions'])
    session_data = {:user_id=>users(:PHR_Test).id, :page_view=>'basic'}
    get :change_account_settings, {}, session_data
    assert_response :success
    assert_select 'input[type="password"]' # confirm that we got the password page
    # The above test turned out to be insufficient to catch the accidental
    # rendering of the sign up form (which also has a password).
    assert_select 'title', 'Verify Identity'

    # Post the password form to get to the account settings page
    post :change_account_settings, {:fe=>{:password_1_1=>'A password'}},
      session_data
    assert_response :success
    assert @response.body.index(users(:PHR_Test).email)
    assert_select 'input#fe_cenew_email_1_1'
    assert_select 'a[href="/phr_records"]' # no images in basic mode

    # Make sure we don't have codes being used for the fixed question fields.
    assert_nil @response.body.index('fe_cp_fixquest_C_1_1')
    # Try posting a change to the account_settings page
    session_data[:password_verified_token] = '1234'
    post :change_account_settings, {:fe=>{:cenew_email_1_1=>'one',
      :cenew_semail_1_1=>'two', :save_changes_1=>1},
      :password_verified_token=>'1234'},
      session_data
    # The emails don't match, so there should be an error
    assert_response :success
    assert_nil flash[:notice]
    assert_not_nil flash[:error]
    assert_not_equal [], @controller.page_errors
    flash[:error] = nil # clear the error messages in flash

    # Try again with a matching email
    post :change_account_settings, {:fe=>{:cenew_email_1_1=>'two@three.four',
      :cenew_semail_1_1=>'two@three.four', :save_changes_1=>1},
      :password_verified_token=>'1234'},
      session_data
    assert_redirected_to phr_records_path
    assert_not_nil flash[:notice]
    assert_nil flash[:error]

    # Also check the non-basic mode
    session.delete(:page_view)
    session.delete(:fe)
    session.delete(:password_verified_token)

    get :change_account_settings, {}, {:user_id=>users(:PHR_Test).id}
    assert_response :success
    assert_select 'input[type="password"]' # confirm that we got the password page
    assert_select 'title', 'Verify Identity'

    post :change_account_settings, {:fe=>{:password_1_1=>'A password',
      :save_changes_1=>1}},
      {:user_id=>users(:PHR_Test).id}
    assert_response :success
    assert_equal '{', @response.body.slice(0..0) # a JS response
  end
  
  
  def test_forgot_id
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions','db_field_descriptions', 'users',
        'question_answers'])
    get :forgot_id, {}, {}
    assert_response :success

    user = create_test_user

    # error condition
    assert_raise(ActionView::MissingTemplate) {
      post :forgot_id_step2, {:fe=>{:email_1=>user.email,
        :chall_answ_1_1=>'1', :reset_option_radio_1_1=>'challenge_q'}}
    }

    # Test that we get sent back to the forgot_id page in standard mode
    # for an invalid email address.
    param_data ={:recaptcha_response_field => 'correct_response'}
    post :forgot_id , {:fe=>{:user_email_1=>'wrong email'}}.merge(param_data)
    assert_response :success
    assert @response.body.index('does not exist') # error message for invalid email address
    
    # good condition
    post :forgot_id, {:fe=>{:user_email_1=>user.email}}.merge(param_data)
    assert_response :success
    
    post :forgot_id_step2, {:fe=>{:email_1=>user.email,
        :chall_answ_1_1=>'1', :reset_option_radio_1_1=>'challenge_q'}}
    expected = "Your account ID has been sent to your email box:
                    #{user.email}."
    assert_redirected_to login_path
    assert_equal(flash[:notice],expected)
  end


  def test_forgot_id_basic_mode
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions','db_field_descriptions', 'users',
        'question_answers'])

    # Check that the user first has to pass the captcha
    session_data = {:page_view=>'basic'}
    get :forgot_id, {}, session_data
    assert_redirected_to captcha_path
    post :forgot_id, {}, session_data
    assert_redirected_to captcha_path
    # Check that posting to forgot_id_step2 without the right session data
    # does not work
    assert_raise(ActionView::MissingTemplate) {get :forgot_id_step2, {}, session_data}
    assert_raise(ActionView::MissingTemplate) {post :forgot_id_step2, {}, session_data}

    # Check that once the captcha is passed, the user gets to the page, but
    # make sure it is the basic mode page (no images).
    session_data[:passed_basic_captcha] = true
    get :forgot_id, {}, session_data
    assert_response :success
    assert_nil @response.body.index('<img')

    # Create a user account for testing.
    u = create_test_user

    # Try a post with a blank email
    # Try a post with an invalid email
    post :forgot_id, {FORM_OBJ_NAME=>{}}, session_data
    assert_response :success
    assert_not_nil @controller.page_errors

    # Try a post with an invalid email
    post :forgot_id, {FORM_OBJ_NAME=>{:user_email_1=>'asdf'}}, session_data
    assert_redirected_to captcha_path
    assert !flash[:error].blank?
    assert_nil session[:passed_basic_captcha]

    # Try with a correct email (with the passed captcha flag set)
    flash[:error] = nil # for some reason, the error message won't go away if the previous response is a redirect
    post :forgot_id, {FORM_OBJ_NAME=>{:user_email_1=>'one2@two.three.four'}},
      session_data
    assert_response :success
    assert_equal [], @controller.page_errors
    # Check that we get the basic version of the second page
    assert_nil @response.body.index('<img')
    step2_indicator = 'tep 2'
    assert_not_nil @response.body.index(step2_indicator)

    # Some of the processing of the second page is also tested in the
    # presenter test, RecoverIdStepTwoPresenterTest.
    # Try an invalid answer
    post :forgot_id_step2, {FORM_OBJ_NAME=>{:chall_answ_1_1=>'wrong'}}
    assert_response :success
    assert !@controller.page_errors.blank?

    # Try a correct response
    post :forgot_id_step2, {FORM_OBJ_NAME=>{:chall_answ_1_1=>'1'}}
    assert_equal [], @controller.page_errors
    assert_redirected_to login_path
    get :login # follows the redirect to clear the sessions

    session[:user_email] = nil # for some reason, the user_email in the session won't go away automatically
    # Try a correct response but without the user's email in the session
    assert_raise(ActionView::MissingTemplate) {
      post :forgot_id_step2, {FORM_OBJ_NAME=>{:chall_answ_1_1=>'1'}}, {}
    }
  end
  
  
  def test_forgot_password
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions','db_field_descriptions', 'users',
         'question_answers'])
    get :forgot_password, {}, {}
    assert_response :success
    assert_select 'title','Password Reset (Step 1 of 3)'

    user = create_test_user
    param_data = { :recaptcha_response_field => 'correct_response'}
    post :forgot_password, {:fe=>{:user_name_1 => user.name}}.merge(param_data)
    assert_redirected_to reset_password_step_two_path
    #follow rediret
    get :change_password, {}, {:user_name => user.name}
    assert_select 'title','Password Reset (Step 2 of 3)'

    post :change_password, {:fe=>{
      :ch_answ1_1_1_1=>'1', :ch_answ2_1_1_1=>'1',
      :email_option_radio_1_1=>'questions'}}
    assert_redirected_to reset_password_step_three_path

    new_password = "NewPassword#{Time.now.to_i}"
    post :update_password, {:fe=>{:cpconfm_passwd_1=>new_password,
      :cpnew_passwd_1=>new_password}}
    assert_redirected_to login_path
    assert_equal flash[:notice], "Password changed successfully."

    post :login, {:fe=>{:user_name_1_1=>user.name, :password_1_1=>new_password}},{}
    assert_response :success
    assert_select "title", "Your Computer Is Not Recognized"
    
    #post :login, {:fe=>{:user_name_1=>'phr_demo', :password_1=>'ABCD1234', 
    #    :reset_key=>assert_select("input#fe_reset_key")}}
    #assert_response :success
   # assert @response.body.index('/accounts/two_factor') # confirm identity page
    #assert @response.body.index('invalid')
  end


  def test_forgot_password_basic_mode
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions','db_field_descriptions', 'users',
        'question_answers'])
    session_data = {:page_view=>'basic'}
    get :forgot_password, {}, session_data
    assert_redirected_to captcha_path
    post :forgot_password, {}, session_data
    assert_redirected_to captcha_path

    session_data[:passed_basic_captcha] = true
    get :forgot_password, {}, session_data
    assert_response :success
    assert_template 'basic/login/reset_pw_step_one'

    # Create a user account for testing.
    u = create_test_user

    # Try posting with a blank user name
    post :forgot_password, {:fe=>{}}, session_data
    assert_response :success # back to same page
    assert @controller.page_errors[0] == "Please specify a user name."
    assert_select 'title','Password Reset (Step 1 of 3)'

    # Try the same thing again to make sure we don't have to pass the captcha
    # again.
    post :forgot_password, {FORM_OBJ_NAME=>{}}, session_data
    assert_response :success # back to same page
    assert @controller.page_errors[0] == "Please specify a user name."
    assert_select 'title','Password Reset (Step 1 of 3)'

    # Try an invalid user name.  The user should be sent back to the captcha.
    wrong_user_name = u.name+"#{Time.now.to_i}"
    post :forgot_password, {FORM_OBJ_NAME=>{:user_name_1=>wrong_user_name}}, session_data
    assert_redirected_to captcha_path
    assert_equal flash[:error], User.non_exist_user_error(wrong_user_name)
    assert_nil session[:passed_basic_captcha]
    
    # Now try a valid user name
    form_data = {FORM_OBJ_NAME=>{:user_name_1=>u.name}}
    flash[:error] = nil
    session[:user_name] = nil
    post :forgot_password, form_data, session_data
    assert_redirected_to reset_password_step_two_path
    assert_nil flash[:error]
    assert @controller.page_errors.empty?

    # Try to follow the redirect
    get :change_password,{},{:user_name =>u.name}
    assert_not_nil @response.body.index('radio') # radio buttons on the next page
    assert session[:user_name] == u.name

    # Try submitting without answers
    session_data[:user_name] = u.name
    post :change_password, {FORM_OBJ_NAME=>{
        :email_option_radio_1_1=>'questions'}}
    assert_response :success
    assert !@controller.page_errors.empty?

    # Try submitting wrong answers
    post :change_password, {FORM_OBJ_NAME=>{
        :email_option_radio_1_1=>'questions', :ch_answ1_1_1_1=>'wrong',
        :ch_answ2_1_1_1=>'wrong_too'}}
    assert_response :success
    assert !@controller.page_errors.empty?

    # Try submitting correct answers
    post :change_password, {FORM_OBJ_NAME=>{
        :email_option_radio_1_1=>'questions', :ch_answ1_1_1_1=>'1',
        :ch_answ2_1_1_1=>'1'}}
    assert_redirected_to reset_password_step_three_path

  end


  # We had a problem where if you went to the recover account ID page in
  # basic mode (and were taken to the basic mode's captcha page), and then you
  # returned to the login page, switched to the standard mode, and signed in,
  # then the next page after signing in was the standard mode's recover ID page.
  def test_captcha_uri_issue
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions','db_field_descriptions', 'users',
        'question_answers', 'text_lists', 'test_list_items'])

    session_data = {:page_view=>'basic'}
    get :forgot_id, {}, session_data
    assert_redirected_to captcha_path

    # Now return to the default mode's login page
    session[:page_view] = 'default'
    get :login, {}
    # Log in
    user = create_test_user
    post :login, {:fe=>{:user_name_1_1=>user.name, :password_1_1=>'A password'}}
    assert_response :success
    assert @response.body.index('/accounts/two_factor') # confirm identity page
    # Answer the challenge question
    session[:user_name] = user.name
    session[:password] = 'A password'
    post :handle_two_factor, {:form_name=>'login', :fe=>{:user_answ_1_1=>'1',
        :cookie_checkbox_1_1=>'1', :user_name_1_1=>user.name}}
    assert_redirected_to '/phr_home?logging_in=true'
  end


  def test_reset_security_basic_mode
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions','db_field_descriptions', 'users',
        'question_answers', 'text_lists', 'test_list_items'])

    # Confirm we get redirected to the login page without a valid key
    u = create_test_user
    session_data = {:page_view=>'basic'}
    get :reset_account_security, {:user=>u.name}, session_data
    assert_redirected_to login_url
    assert_not_nil flash[:error]

    flash[:notice] = flash[:error] = nil # for some reason this does not get reset
    get :reset_account_security, {:user=>u.name, :reset_key=>'a'}, session_data
    assert_redirected_to login_url
    assert_not_nil flash[:error]

    # Now make the key valid and try again
    flash[:notice] = flash[:error] = nil # for some reason this does not get reset
    u.reset_key = 'a'
    u.last_reset = Time.now
    u.save!
    get :reset_account_security, {:user=>u.name, :reset_key=>u.reset_key}, session_data
    assert_response :success

    # Attempt a post.  It should return with errors on the page.
    flash[:notice] = flash[:error] = nil # for some reason this does not get reset
    post :reset_account_security, {FORM_OBJ_NAME=>{}}
    assert_response :success
    assert_equal flash[:error], @controller.class.class_variable_get("@@no_changes")

    # Confirm that we can submit the form a second time.  Provide a new password
    # so that the form posts successfully.
    flash[:notice] = flash[:error] = nil # for some reason this does not get reset
    post :reset_account_security, {
      FORM_OBJ_NAME=>{:cpnew_passwd_1_1=>'AAAbbb111',
        :cpconfm_passwd_1_1=>'AAAbbb111'}}
    assert_not_nil flash[:notice]
    assert_nil flash[:error]
    assert_redirected_to login_url

    # Confirm that we can't post again now that it updated.  (The user should
    # have to get another reset key.)
    flash[:notice] = flash[:error] = nil # for some reason this does not get reset
    post :reset_account_security, {
      FORM_OBJ_NAME=>{:cpnew_passwd_1_1=>'AAAbbb111',
        :cpconfm_passwd_1_1=>'AAAbbb111'}}
    assert_nil flash[:notice]
    assert_not_nil flash[:error]
    assert_redirected_to login_url

    # Confirm that the original key does not work either.
    flash[:notice] = flash[:error] = nil # for some reason this does not get reset
    get :reset_account_security, {:user=>u.name, :reset_key=>'a'}, session_data
    assert_not_nil flash[:error]
    assert_redirected_to login_url
    flash[:notice] = flash[:error] = nil # for some reason this does not get reset
    post :reset_account_security, {  # Try posting again with the key we set above
      FORM_OBJ_NAME=>{:cpnew_passwd_1_1=>'AAAbbb111',
        :cpconfm_passwd_1_1=>'AAAbbb111'}}
    assert_nil flash[:notice]
    assert_not_nil flash[:error]
    assert_redirected_to login_url
  end

  
  def test_account_deletion
    session_info = {}
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions','db_field_descriptions', 'users',
        'question_answers', 'text_lists', 'test_list_items'])
    user = create_test_user

    get :login, {}, {}
    assert_response :success

    # Test a good login attempt
    post :login, {:fe=>{:user_name_1_1=>user.name, :password_1_1=>'A password'}}
    assert_response :success
    assert @response.body.index('/accounts/two_factor') # confirm identity page

    # Try going through the two factor page
    session_info[:user_name] = user.name
    session_info[:password] = 'A password'
    post :handle_two_factor, {:form_name=>'login', :fe=>{:user_answ_1_1=>'1',
        :cookie_checkbox_1_1=>'1', :user_name_1_1=>user.name}}, session_info
    assert_redirected_to '/phr_home?logging_in=true'
    
    # add a profile to test deletion later
    @profile = Profile.create!(:id_shown=>'Test_123')
    user.profiles << @profile
    id_shown = @profile.id_shown
   
    delete :delete_account, {:password => 'A password'} # , session_info
    assert_response :success
    assert_not_nil(@response.body.index('Valid'))
    
    # Check for delete profiles
    p = DeletedProfile.where(id_shown: id_shown).first
    assert_not_nil(p)
    
    pr = Profile.where(id_shown: p.id_shown).load
    assert_not_nil(pr)

    # Confirm that the user was deleted.
    assert_nil User.find_by_id(user.id)
    
    # Now test for failure conditions
    DatabaseMethod.copy_development_tables_to_test(['users','question_answers'])  
    user = create_test_user    
    
    # Reset the session and the session_info so this will be a "new" login.
    # If the session_info has a user_id, this will be interpreted as a login
    # from someone who's already logged in, and will just go to the appropriate
    # next page for the user.
    @request.env['rack.session.record'] = Session.new
    @request.env['rack.session.record'].session_id = 'sessionidhere'
    session_info[:user_id] = nil

    post :login, {:fe=>{:user_name_1_1=>user.name, :password_1_1=>'A password'}},
      session_info

    # session_info
    assert_response :success
    assert @response.body.index('/accounts/two_factor') # confirm identity page

    # Go through the two factor page to log in
    session_info = {}
    session_info[:user_name] = user.name
    session_info[:password] = 'A password'
    post :handle_two_factor, {:form_name=>'login', :fe=>{:user_answ_1_1=>'1',
        :cookie_checkbox_1_1=>'1', :user_name_1_1=>user.name}} # , session_info
    assert_redirected_to '/phr_home?logging_in=true'
    
    session_info = {:user_id=>user.id}
    delete :delete_account, {:password => 'A password2'}, session_info
    assert_response :success
    assert_not_nil(@response.body.index(
        'The account ID and password combination is invalid.'))
    
    delete :delete_account, {:password => 'A password2'}, session_info
    assert_response :success
    assert_not_nil(@response.body.index(
        'The account ID and password combination is invalid.'))
    
    delete :delete_account, {:password => 'A password2'}, session_info
    assert_response :success
    assert_not_nil(@response.body.index(
        'The account ID and password combination is invalid.'))
    
    delete :delete_account, {:password => 'A password2'}, session_info
    assert_response :success
    assert_not_nil(@response.body.index(
        'Your password verification attempts exceeded the maximum allowed. '))

    # Try the basic mode
    user = User.find_by_id(user.id) # to get the current attribute values
    user.password_trial = 0 # reset the trial limit
    user.lasttrial_at = nil
    user.save!
    assert_equal(0, User.find_by_id(user.id).password_trial)
    session_info[:page_view] = 'basic'
    get :delete_account, {}, session_info
    assert @response.body.index('Enter your password')
    # Enter an incorrect password
    delete :delete_account, {:password => 'Wrong password'}
    assert_response :success
    assert @response.body.index('Enter your password')
    assert flash[:error].size > 0
    assert_not_nil User.find_by_id(user.id)
    # Now try the correct password
    delete :delete_account, {:password => 'A password'}
    assert_redirected_to :login
    assert_nil User.find_by_id(user.id)

  end # test_account_deletion


  def test_reset_account_security
    # Load the reset_security_form to be used in get request '/login/reset_account_security'
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions','db_field_descriptions', 'users',
        'question_answers', 'text_lists', 'test_list_items'])
    u = create_test_user
    reset_link = :reset_account_security

    # both reset_key and user_name are missing
    get reset_link
    assert_redirected_to login_path
    assert_equal flash[:error], 'The request is invalid'

    # missing either reset_key or user_name, e.g. the user_name
    get reset_link, { :reset_key => u.reset_key }
    assert_redirected_to login_path
    assert_equal flash[:error], 'The request is invalid'

    # both reset_key and user_name are present
    # 1) user_name is wrong 
    # ( WARNING: error message shouldn't tell if user_name is correct or not as
    #   this could make it possible for hacker to guess username without passing
    #   recaptcha )
    wrong_user_name = "wrong_user_name"
    u.setup_reset_key
    get reset_link, { :reset_key => u.reset_key, :user=>wrong_user_name }
    assert_redirected_to login_path
    assert_equal flash[:error], ApplicationController.incorrect_reset_pw_key
    # 2) reset_key is wrong
    wrong_reset_key = "wrong_reset_key"
    get reset_link, { :reset_key => wrong_reset_key, :user => u.name}
    assert_redirected_to login_path
    assert_equal flash[:error], ApplicationController.incorrect_reset_pw_key

    # 3) both user_name and reset_key are correct
    u.setup_reset_key
    flash[:error] = nil
    get reset_link, { :reset_key => u.reset_key, :user => u.name }
    assert_response :success
    assert_select 'title',  "Reset Account Security Settings"

    # 4) update password with wrong params, user will be allow to try again
    # on the same page
    post reset_link, {:fe =>{}}
    assert_response :success
    assert_select 'title',  "Reset Account Security Settings"
    assert_not_nil flash[:error]

    # 4) update the password with success
    new_password = "NewPassword#{Time.now.to_i}"
    password_only = {
        :cpnew_passwd_1_1 => new_password,
        :cpconfm_passwd_1_1 => new_password ,
        :cp_fixquest_1_1 => 'Dummy Fixed Question 1?' , :cp_fixansw_1_1 => '' ,
        :cp_fixquest_1_2 => 'Dummy Fixed Question 2?',  :cp_fixansw_1_2 => '' ,
        :cp_selfquest_1_1 => 'Dummy Question 1?',  :cp_selfansw_1_1 => '',
        :cp_selfquest_1_2 => 'Dummy Quest 2?',     :cp_selfansw_1_2 => ''
    }
    post reset_link, {:fe => password_only}
    assert_redirected_to login_path
    assert_equal flash[:notice], "Security question(s) and/or password have been updated for user:  #{u.name}."

    # 5) test re-post without getting a new reset_key
    post reset_link, {:fe=>password_only}
    assert_redirected_to login_path
    assert_not_nil flash[:error]

    # 6) the original reset_key became invalid after a successful post
    get reset_link, { :reset_key => u.reset_key, :user => u.name }
    assert_redirected_to login_path
    assert_not_nil flash[:error]
  end


  def test_mobile_mode_auto_switching
    # When the request is coming from a mobile browser, PHR should be switched to mobile mode automatically
    table_list = %w(field_descriptions forms db_table_descriptions db_field_descriptions usage_stats)
    DatabaseMethod.copy_development_tables_to_test(table_list)

    ua_firefox_pc = "mozilla/5.0 (x11; linux x86_64; rv:24.0) gecko/20100101 firefox/24.0"
    ua_iphone = "mozilla/5.0 (iphone; cpu iphone os 7_0 like mac os x; en-us) "+
      "applewebkit/537.51.1 (khtml, like gecko) version/7.0 mobile/11a465 safari/9537.53"

    # When tested on a browser of a PC
    @request.user_agent = ua_firefox_pc
    # If no format found in parameter or session, standard mode login page will be displayed
    get :login
    assert_select "#page_view", false # Only standard mode has no page_view element
    # Switch PHR mode by adding format parameter
    get :login, {:format => "mobile"}
    assert_select "#page_view", "mobile"
    assert session["page_view"] == "mobile"
    # After a format is accepted
    # If no new format provided, login page will show mode based on the page_view in the session
    get :login
    assert_select "#page_view", "mobile"
    # If a new format provided, it will replace the existing format
    get :login, {:format => "basic"}
    assert_select "#page_view", "basic"


    # When tested in a mobile browser
    @request.user_agent = ua_iphone
    # No format is session
    session[:page_view] = nil
    # Mobile mode login page will be displayed
    get :login
    assert_select "#page_view", "mobile"
    # We can switch PHR mode using format parameter
    get :login, {:format => "basic"}
    assert_select "#page_view", "basic"
  end


  def test_email_verification
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions', 'forms'])

    a_username = "user_#{Time.now.to_i}"
    a_password = "Password009"
    a_email_addr = "ddd@ddd.ddd"
    # Create a new user
    u = User.new
    u.name = a_username
    u.password = u.password_confirmation = a_password
    u.email = u.email_confirmation = a_email_addr
    assert u.save
    # User is inactive
    assert u.inactive

    vtoken = u.email_verifications.select{|e| e.token_type == "new" && e.used != true && e.expired != true}[0]
    data_default ={:fe => {:user_name_1=>a_username, :password_1=>a_password, :verification_token_1 =>""}}
    correct_token = vtoken && vtoken.token

    # Try to activate the new user with
    # Wrong user login
    data = data_default.deep_dup
    data[:fe][:user_name_1] += "_#{Time.now.to_i}" # wrong username
    post :email_verification, data
    assert_response :success
    assert_equal assigns["page_errors"][0], User::INVALID_LOGIN


    # Try to activate the new user with correct user/pwd and
    # -- blank token
    post :email_verification, data_default
    assert_response :success
    assert_equal assigns["page_errors"][0], EmailVerification::TOKEN_MSGS["blank"]
    # -- Invalid token including non-existing, used, expired tokens
    data = data_default.deep_dup
    # --- non-existing
    data[:fe][:verification_token_1] = correct_token + "_wrong_suffix"
    post :email_verification, data
    assert_response :success
    assert_equal assigns["page_errors"][0], EmailVerification::TOKEN_MSGS["invalid"]
    # --- expired token
    valid_data = data_default.deep_dup
    valid_data[:fe][:verification_token_1] = correct_token
    vtoken.created_at = 10.days.ago
    assert vtoken.save
    post :email_verification, valid_data
    assert_response :success
    assert_equal assigns["page_errors"][0], EmailVerification::TOKEN_MSGS["no_pending"]
    # -- valid token
    vtoken.created_at = 1.days.ago
    assert vtoken.save
    post :email_verification, valid_data
    assert_response :success
    assert_equal flash[:notice], EmailVerification::TOKEN_MSGS["verified"], flash[:notice]

    # For an active user
    # There should be no pending verification token
    post :email_verification, data_default
    assert_response :success
    assert_equal assigns["page_errors"][0], EmailVerification::TOKEN_MSGS["no_pending"]
  end


end
