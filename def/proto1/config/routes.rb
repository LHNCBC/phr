Proto1::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  root :to => "login#login"

  resource :feedback, :only=>[:new, :create]
  resource :contact, :only=>[:new, :create], :controller=>'feedback',
           :type=>'contact_us', :as=>:contact_us
  resources :usage_stats, :only => :create

  resources :phr_home, :only => :index
  get '/phr_home/export_one_profile/:id_shown(/:file_format/:file_name)' =>
                                                   'phr_home#export_one_profile'
  get '/phr_home/get_name_age_gender_updated_labels'
  get '/phr_home/get_removed_listings'
  get '/phr_home/get_one_active_profile_listing'
  get '/phr_home/get_initial_listings'
  get '/phr_home/get_others_listings'
  get '/phr_home/get_access_list'
  put '/phr_home/remove_access'

  # share invitations
  post '/share_invitation' => 'share_invitation#create'
  post '/share_invitation/accept_invitation(/:sent_to/:invite_data)' =>
                                      'share_invitation#accept_invitation'
  match '/share_invitation/accept_invitation' =>'share_invitation#accept_invitation',
      :as => 'accept_invitation', :via => [ :get]
  get '/share_invitation/get_pending_share_invitations'
  post '/share_invitation/update_invitations'


  ### Basic HTML Mode URLs
  get '/phr_records/archived'=>'phr_records#archived_index', :as=>"archived_phr_records"
  get '/phr_records/message_managers'=>'phr_records#message_managers',
    :as => "message_managers"
  put '/phr_records/:id/archive'=>'phr_records#archive', :as=>"archive_phr_record"
  put '/phr_records/:id/unarchive'=>'phr_records#unarchive', :as=>"unarchive_phr_record"

  resources :phr_records do
    member do
      post 'archive'
      post 'unarchive'
      get 'edit_phr'
      put 'update_phr'
      match 'export', :via => [:get, :post]
    end
    resources :phr_drugs do
      get 'search', :on => :member
    end
    resources :phr_conditions do
      get 'search', :on => :member
      match 'studies', :on=>:collection, :via=>[:get, :post]
    end
    resources :phr_surgical_histories do
      get 'search', :on => :member
    end
    resources :phr_doctor_questions
    resources :phr_medical_contacts
    resources :phr_allergies
    resources :phr_immunizations
    resources :phr_notes

    resources :reminder_options do
      get 'search', :on => :member
    end
    resources :date_reminders do
      get 'hidden', :on => :collection
      member do
        post 'unhide'
        post 'hide'
      end
    end
    resources :phr_panels do
      get 'search', :on => :member
      match 'flowsheet', :via => [:get, :post], :on => :collection
      match 'get_paginated_flowsheet_data_hash', :via => [:get], :on => :collection
      resources :items, :controller=>:phr_panel_items
    end
  end

  get '/phr_records/:id/reminders'=>'phr_records#reminders', :as => "phr_record_reminders"

  get '/captcha/show'=>'captcha#show', :as => "captcha"
  get '/captcha/audio'=>'captcha#audio', :as => "captcha_audio"
  post '/captcha/answer'=>'captcha#answer', :as => "captcha_answer"
  resources :phr_records, :as => "profiles", :controller=> "phr_records"
  ### End Basic HTML Mode URLs

  ### Account URLs
  # The login page
  match '/accounts/login(.:format)' => 'login#login', :form_name =>'login',
    :as => 'login',  :constraints => { :format => /(default|basic|mobile|)/ },
    :via => [:get, :post]

  # Deleting an account (GET goes to a confirmation page in basic mode)
  match '/accounts/delete_account'=> 'login#delete_account',
    :as=>'delete_account', :via=>[:get, :delete]

  constraints :format=>'' do  # disables URLs like /accounts/new.tmp
    # The signup page
    match '/accounts/new' => 'login#add_user', :as => "account_sign_up",
      :via => [:get, :post]
    # New account email verification page
    match '/accounts/email_verification' => 'login#email_verification', :as=>"email_verification",
          :via=> [:get, :post]

    # The login answer page
    #match '/accounts/answer'=>'login#answer'
    get '/accounts/get_reset_link' => "login#get_reset_link"
    match '/accounts/two_factor' => 'login#handle_two_factor', :form_name=>'login',
      :as => "confirmid", :via =>[:get, :post]
    match '/accounts/reset_account_security' =>'login#reset_account_security',
      :as => 'reset_account_security', :via => [ :get, :post]
    # The change password page
    match '/accounts/verify_password' => "login#verify_password",
      :via => [:get, :post, :put]
    # The change password page
    match '/accounts/change' => 'login#change_account_settings',
      :as => "account_settings" , :via => :all# includes all http verbs
    # the forgot password page
    match '/accounts/forgot_password' =>'login#forgot_password',
      :as => "reset_password_step_one", :via => [:get, :post]
    # The first page in the process for recovering an account ID.
    match '/accounts/forgot_id' =>'login#forgot_id',
      :as=>"recover_account_id_step_one", :via => [:get, :post]
    # the forgot password user name
    post '/accounts/forgot_id_step2' => 'login#forgot_id_step2',
      :as =>"recover_account_id_step_two"
    # Forgot password, reset via challenge questions (instead of reset link)
    match '/accounts/change_password' => 'login#change_password',
      :as=>"reset_password_step_two", :via => [:get, :post]
    match '/accounts/update_password' => 'login#update_password',
      :as => 'reset_password_step_three', :via =>[:get, :post]
    # The logout link (matches any http verb to make sure logout can be done)
    match '/accounts/logout' =>'login#logout', :via => :all

    get '/application/extend_session', :as=>'extend_session'
    get '/login/timeout_logoff'

    # The demo user login page
    match '/accounts/demo_login' => 'login#demo_login', :as=>'demo_login',
      :constraints => { :format => /(default|basic|mobile|)/ }, :via => [:get, :post]
  end
  ### End Account URLs

  # Acceptance test URLs
  get '/acceptance/:action', :controller => 'acceptance', :as => "acceptance"

  ### URLs for Rule form pages
  match '/forms/:form_name/rules' => "rule#show_rules", :as => "rules",
    :via => [:get, :post]
  # new general rule GET/POST request
  match '/forms/:form_name/rules/new' => "rule#new_rule",
    :rendering_form => "edit_general_rule",
    :type => Rule::GENERAL_RULE.to_s,
    :via  => [:get, :post]

  # existing general rule GET/PUT request
  match '/forms/:form_name/rules/:id;edit' => "rule#edit_rule",
    :rendering_form => 'edit_general_rule',
    :via  => [:get, :put]

  # new case rule GET/POST request
  match '/forms/:form_name/case_rules/new' => "rule#new_rule",
    :rendering_form => "edit_case_rule",
    :type => Rule::CASE_RULE.to_s,
    :via  => [:get, :post]

  # existing case rule GET/PUT request
  match '/forms/:form_name/case_rules/:id;edit'=> "rule#edit_rule",
    :rendering_form => 'edit_case_rule',
    :via  => [:get, :put]

  # URL for data rules
  match '/rules' =>'rule#index', :via => [:get, :post]

  # Get the rule names for a rule type
  post '/rule/get_rule_name_list'

  # Gets data for combo fields used on rule pages.
  post '/form/handle_combo_field_change'

  # new fetch rule GET/POST request
  match '/fetch_rules/new' => "rule#new_data_rule",
    :rendering_form =>'edit_phr_fetch_rule',
    :type => Rule::FETCH_RULE.to_s,
    :via  => [:get, :post]

  # existing fetch rule GET/PUT request
  match '/fetch_rules/:id;edit' => "rule#edit_data_rule",
    :rendering_form =>'edit_phr_fetch_rule',
    :via  => [:get, :put]

  # Route needed for search fields on the new fetch rule page
  post 'form/handle_data_req_for_db_field'

  # new reminder rule GET/POST request
  match '/reminder_rules/new' => "rule#new_data_rule",
    :rendering_form => "new_reminder_rule",
    :type => Rule::REMINDER_RULE.to_s,
    :via  => [:get, :post]

  # existing reminder rule GET/PUT request
  match '/reminder_rules/:id;edit' => "rule#edit_data_rule",
    :rendering_form => "new_reminder_rule",
    :via  => [:get, :put]

  # show all reminder rules
  get '/reminder_rules/show' => "rule#show_reminder_rules",
    :readable_format => false

  # show all reminder rules in readable format
  get '/reminder_rules/show_in_readable_format' => "rule#show_reminder_rules",
    :readable_format => true

  # new value rule GET/POST request
  match '/value_rules/new' => "rule#new_data_rule",
    :rendering_form => "new_value_rule",
    :type => Rule::VALUE_RULE.to_s,
    :via  => [:get, :post]

  # existing value rule GET/PUT request
  match '/value_rules/:id;edit' => "rule#edit_data_rule",
    :rendering_form => "new_value_rule",
    :via  => [:get, :put]
  ### End of URLs for Rule form pages

  ### Reminder URLs and Rule Data
  # Getting a list of reviewed reminders for a profile
  get '/form/get_reviewed_reminders'

  # Updating the list of reviewed reminders
  post '/form/update_reviewed_reminders'

  # Getting a count of the reviewed reminders for a profile
  get '/form/get_reminder_count'

  # Getting the last updated timestamps of a list of profiles
  get '/form/get_profiles_updatetimes'

  # Gets the latest obx_observation data for a profile (used by rules)
  match '/form/get_prefetched_obx_observations',
    :via  => [:get, :post]
  ### End Reminder URLs and Rule Data


  ###############################################
  ### URLs for New Class Management
  ###############################################

  # show action (including the delete action)
  # works for deletion( method:post, id:123)
  match '/class_types/' => 'classification#show_class_types',
    :form_name => "classifications", :via => [:get, :post]

  ## works for deletion( method:post, id:123)
  match '/classifications/:parent_id;parent_id' => 'classification#show',
    :form_name => "classifications", :via => [ :get, :post]

  # new action
  # 1) class
  match '/class_types/new' => "classification#new_class_type",
    :form_name => "classification",
    :node_type => Classification::CLASS_NODE_TYPE, :via => [ :get, :post]

  match '/classifications/:parent_id;parent_id/new' => "classification#new",
    :form_name => "classification",
    :node_type => Classification::CLASS_NODE_TYPE, :via => [ :get, :post]

  # 2) class item
  match '/class_types/new_item' => 'classification#new_class_type',
    :form_name => "classification",
    :node_type => Classification::CLASS_ITEM_NODE_TYPE, :via => [ :get, :post]

  match '/classifications/:parent_id;parent_id/new_item' => 'classification#new',
    :form_name => 'classification',
    :node_type => Classification::CLASS_ITEM_NODE_TYPE, :via => [ :get, :post]

  # edit action
  # 1) class
  match '/classifications/:id;edit' => 'classification#edit',
    :form_name => 'classification',
    :node_type => Classification::CLASS_NODE_TYPE, :via => [ :get, :put]

  # 2) class item
  match '/data_classes/:id;edit' => 'classification#edit',
    :form_name => 'classification',
    :node_type => Classification::CLASS_ITEM_NODE_TYPE, :via => [ :get, :put]

  # Gets the list needed by the new class item page
  post '/form/get_search_res_list_by_list_desc'

  ###############################################
  ## end of New Class Management URLs
  ###############################################

  ### Data Controller
  # Index page
  get '/data'=>'data#index'

  # Allow .csv formats for the data controller export
  get '/data/export/:id'=>'data#export', :format=>'csv'
  get '/data/export_form_text/:id'=>'data#export_form_text', :format=>'csv'
  post '/data/update'
  ### End Data Controller

  ### Help Text URLs
  match '/help_text'=>'help_text#index', :via => [ :get, :post]
  get '/help_text/list' # list of all help files
  match '/help_text/new', :via => [ :get, :post]
  match '/help_text/edit/:id'=>'help_text#edit', :via => [ :get, :post]
  ### End Help Text URLs

  ### Form builder URLs
  # The form builder is not used, but we keep the test code in place
  # in case we want to return to developing it.  The test code requires
  # that the routes be in place.
  get '/forms/new' =>'formbuilder#new_form', :form_name=>'FormBuilder'
  post '/forms' => 'formbuilder#save_form'
  get '/forms/:form_name;edit'=>'formbuilder#edit_form'
  ### Form builder URLs

  # Home page URLs (post-login)
  get '/admin_home' => 'form#form_index', :form_name=>'admin'

  # Restrict the display of the phr_index page to tests only
  class RestrictPhrIndexToTests
    def matches?(request)
      Rails.env == 'test'
    end
  end
  get '/profiles' => 'form#form_index', :form_name=>'phr', :as => "profiles_std",
                                     :constraints => RestrictPhrIndexToTests.new

  ### Profile URLs
  get '/profiles/:id;edit' => 'form#edit_profile_with_form',
    :form_name=>'phr', :as=>'edit_phr'
  get '/form/edit_profile_with_form' # for editing profile registration data

  # Research studies button on the PHR form - no - we're going to let this
  # # use the route below that goes to the show_sub_form action
  #get '/profiles/:id/research_studies'=>'form#show', :form_name=>'ct_search'

  # Saves form data
  post '/form/do_ajax_save'

  # Export url, by post
  post '/profiles' => 'form#export_profile', :form_name=>'phr'

  # test panel index page & research studies
  get '/profiles/:id/:subFormNames' => 'form#show_sub_form', :form_name=>'phr'

  # Returns updates to session notices
  get '/form/get_session_updates'

  # Retreiving a list of data for a user
  get '/form/get_user_data_list'

  # Retrieving a table of data for a user (e.g. for the flowsheet)
  get '/form/get_user_data_list_in_table'

  # Gets the flowsheet
  post '/form/get_loinc_panel_timeline_view'

  # Gets data about a panel (used for "Add More")
  post '/form/get_loinc_panel_data'

  # Handling an Ajax request for additional data about a field value.
  post '/form/handle_data_req'

  # Getting a list of search results for a field
  post '/form/get_search_res_list'
  post '/form/get_search_res_table' # Currently only needed for tests

  # Updating a reminder record
  post '/form/update_a_reminder'

  # A route for testing the behavior of controls on forms, but only accessible
  # if the system is not on a public machine or if the access is from localhost.
  class RestrictFormTest
    def matches?(request)
      !PUBLIC_SYSTEM or request.remote_ip == '127.0.0.1'
    end
  end
  # A route for testing the behavior of controls on forms
  get '/form/test/:form_name' => 'form#show', :constraints=>RestrictFormTest.new

  # Archiving/unarchiving profiles
  post '/form/archive_profile'
  post '/form/unarchive_profile'

  # Deleting a profile
  post '/form/delete_profile'
  ### End Profile URLs

  # Autosave URLs
  post '/form/auto_save'
  get '/form/get_autosave_data'
  post '/form/rollback_auto_save_data'
  post '/form/reset_autosave_base'
  get '/form/has_autosave_data'

  # Info button URLs
  get '/form/mplus_health_topic_links'
  get '/form/mplus_drug_links_for'

  # Page timer URLs
  get '/page_timer/load_time' => 'page_timer#page_load_time_chart'
  get '/page_timer/time_phr'
  get '/page_timer/save_load_time'
  post '/page_timer/get_chart_data'

  # A route for the error report controller.
  post '/error/new'

  # A route for the startup controller
  get '/startup/load_resources'

end

