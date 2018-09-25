require 'test_helper'
require 'form_controller'

# Re-raise errors caught by the controller.
class FormController; def rescue_action(e) raise e end; end

class FormControllerTest < ActionController::TestCase

  fixtures :drug_name_routes
  fixtures :drug_strength_forms
  fixtures :clinical_maps
  fixtures :field_descriptions
  fixtures :gopher_terms, :gopher_terms_mplus_hts
  fixtures :text_lists
  fixtures :text_list_items
  fixtures :forms
  fixtures :rules
  fixtures :rules_forms
  fixtures :rule_actions
  fixtures :rule_cases
  fixtures :action_params
  fixtures :users
  fixtures :two_factors
  fixtures :profiles_users, :profiles, :phrs
  fixtures :db_table_descriptions

  def setup
    @controller = FormController.new
    @request    = ActionController::TestRequest.create(@controller.class)
    @response   = ActionDispatch::TestResponse.new
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL

    # Also copy the ferret index files
    if (File.exists?('index/test'))
      FileUtils.rm_r('index/test')
    end
    FileUtils.cp_r('index/development', 'index/test')

  end


  def test_load_rule_data
    # This tests some of the load_rule_data functionality.
    get :show, params: {:form_name=>'PHR'}, session: {:user_id=>users(:PHR_Test).id}

    # Test that @rule_actions was set up correctly.
    assert_not_nil(assigns['rule_actions'])
    # Currently the only rule with an action is rule "b", so there should just
    # be one element in @rule_actions.  (Now there is also a rule case
    # with an action.)
    assert_equal(2, assigns['rule_actions'].length)
    assert_not_nil(assigns['rule_actions']['b'])
  end


  # Tests the handle_data_req method
  def test_handle_data_req
    # Define the user data table model classes
    DbTableDescription.define_user_data_models

    get :handle_data_req, params: {:field_val=>'Aminobenzoate (Oral-liquid)',
      :fd_id=>field_descriptions(:phr_drug_name).id}, session:
      {:user_id=>users(:PHR_Test).id}
   # expected = "{\"drug_code\": \"10001\", \"route\": \"By Mouth\", " +
   #   "\"drug_name_route_id\": 2, \"strength_and_form\":" +
   #   " [[\"         10 MG/ML Susp\"], [581629]]}"
    #expected = "{drug_code: \"10001\", route: \"By Mouth\", "+
    #  "drug_name_route_id: 2, strength_and_form:"+
    #  " [\"         10 MG/ML Susp\"]}"
=begin
    expected = "{\"route\":\"By Mouth\",\"strength_and_form\":[[\" "+
 "        10 MG/ML Susp\"],[581629]],\"drug_code\":\"10001\","+
      "\"drug_name_route_id\":-3}"
    assert_equal(expected, @response.body)
=end
    expected = {"route"=>"By Mouth",
      "strength_and_form"=>[["10 MG/ML Susp"],[581629]],
      "drug_code"=>"10001",
      "drug_name_route_id"=>-3}
    assert_equal(expected, JSON.load(@response.body))

    # Now try the same thing but with a code value instead of a field value.
    get :handle_data_req, params: {:code_val=>'-3',
      :fd_id=>field_descriptions(:phr_drug_name).id}, session:
      {:user_id=>users(:PHR_Test).id}
    assert_equal(expected, JSON.load(@response.body))

    get :handle_data_req, params: {:field_val=>'10 MG/ML Susp',
      :fd_id=>field_descriptions(:phr_drug_strength).id,
      :drug_name_route_id=>-3}
    #expected = "{\"rxcui\":581629,\"dose\":[\"1/2 Tsp\",\"1 Tsp\"]}"
    #assert_equal(expected, @response.body)
    expected = {"rxcui"=>581629,"dose"=>["1/2 Tsp","1 Tsp"]}
    assert_equal(expected, JSON.load(@response.body))

    # Test that the user cannot search the users table.
    # Field Description 75 is configured to search the users table.
    assert_raise RuntimeError do
      get :handle_data_req, params: {
        :fd_id=>field_descriptions(:test_for_not_allowing_search1).id}, session:
        {:user_id=>users(:PHR_Test).id}
    end

    # Test that the user cannot search the phrs table.
    # Field Description 76 is configured to search the phrs table.
    assert_raise RuntimeError do
      get :handle_data_req, params: {
        :fd_id=>field_descriptions(:test_for_not_allowing_search2).id}, session:
        {:user_id=>users(:PHR_Test).id}
    end

    # Test that the user can search the phrs they own
    get :handle_data_req, params: {
      :fd_id=>field_descriptions(:test_for_allowing_search2).id,
      :field_val=>'father'}, session:
      {:user_id=>users(:PHR_Test).id}
    test_phr = phrs(:Father)
    expected = {"real_id"=>test_phr.id, "visible_id"=>test_phr.id_shown}
    actual = ActiveSupport::JSON.decode(@response.body)
    assert_equal(expected, actual)
  end

  # Test that the autocompletion lookups is working on the PHR form
  def test_get_search_res_list
    get :get_search_res_list, xhr: true,
        params: {:field_val => 'Aminobenzoate (Oral-liquid)',
                 :fd_id => field_descriptions(:phr_drug_name).id, suggest: 1},
        session: {:user_id => users(:PHR_Test).id}
    assert_response(:success)
    expected = [["607465", "596393", "607658", "590047", "605149"],
                [["Aminobenzoate (Oral Liquid)"], ["Aminobenzoate (Oral-liquid)"], ["Aminobenzoic Acid (Oral Liquid)"],
                 ["Aminobenzoic Acid (Oral-liquid)"], ["Aminobenzoate (Oral Pill)"]]]
    actual = ActiveSupport::JSON.decode(@response.body)
    assert_equal(expected, actual)
  end

  # Tests mplus_health_topic_links.
  def test_mplus_health_topic_links
    # Test passing in the code
    post :mplus_health_topic_links, params: {:problem_code=>gopher_terms(:one).key_id}, session:
      {:user_id=>users(:PHR_Test).id}
    assert_response(:success)
    expected = [['http://somewhere1', 'Page One'],
                ['http://somewhere2', 'Page Two']]
    actual = ActiveSupport::JSON.decode(@response.body)
    assert_equal(expected, actual)

    # Test passing in the problem name.  For some reason, we have to clear
    # the value of problem_code, which appears to get cached somehow.
    post :mplus_health_topic_links, params: {:problem_name=>'Cigarette Smoker',
      :problem_code=>nil}, session:
      {:user_id=>users(:PHR_Test).id}
    assert_response(:success)
    expected = [['http://somewhere3', 'Page Three']]
    actual = ActiveSupport::JSON.decode(@response.body)
    assert_equal(expected, actual)
  end


# export_profile is no longer used.
#  # Tests the export function
#  def test_export_profile
#    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
#        'db_field_descriptions', 'db_table_descriptions', 'forms',
#        'loinc_items', 'loinc_panels', 'loinc_units', 'answer_lists',
#        'list_answers', 'answers'], false)
#    user = users(:PHR_Test)
#    profile = profiles(:phr_test_phr1)
#
#    # Create some data for the profile
#    obr = ObrOrder.create!(:latest=>1, :test_date=>'2012/4/2')
#    obx = ObxObservation.create!("test_normal_low"=>"60", "record_id"=>1,
#      "obx6_1_unit"=>"/min",
#      "lastvalue_date"=>"65  [21.2 weeks ago]", "last_date_HL7"=>"20110330",
#      "unit_code"=>"5593", "required_in_panel"=>true,
#      "obx7_reference_ranges"=>"60-100", "obx3_2_obs_ident"=>"Heart rate",
#      "obr_order_id"=>obr.id, "last_date_ET"=>1301460025344,
#      "last_date"=>"2011 Mar 30", "test_normal_high"=>"100",
#      "obx2_value_type"=>"PQ", "id"=>9910, "test_date_HL7"=>"20110825",
#      "obx5_value"=>"124", "loinc_num"=>"8867-4", "test_danger_low"=>"40",
#      "test_danger_high"=>"130", "test_date"=>"2011 Aug 25",
#      "latest"=>true, "disp_level"=>1,
#      "version_date"=>"Thu Aug 25 17:34:28 -0400 2011",
#      "test_date_ET"=>1314244800000, "profile_id"=>profile.id,
#      "last_value"=>"65")
#
#    obr = ObrOrder.create!("record_id"=>7, "loinc_num"=>"X0020-1",
#      "test_date_HL7"=>"2010", "latest"=>true, "test_date"=>"2010",
#      "panel_name"=>"Risk Factors", "profile_id"=>profile.id,
#      "test_date_ET"=>1262322000000, "version_date"=>Time.now)
#
#    obx = ObxObservation.create!({"record_id"=>1,
#      "lastvalue_date"=>"Yes  [51.1 weeks ago]", "last_date_HL7"=>"20110407",
#      "required_in_panel"=>true, "obx3_2_obs_ident"=>"Smoked in last year?",
#      "obx5_1_value_if_coded"=>"LA32-8", "obr_order_id"=>obr.id,
#      "last_date_ET"=>1302148800000, "last_date"=>"2011 Apr 07",
#      "obx2_value_type"=>"CWE", "value_score"=>"N", "test_date_HL7"=>"2010",
#      "obx5_value"=>"No", "loinc_num"=>"X0021-1", "test_date"=>"2010",
#      "latest"=>true, "disp_level"=>1,
#      "version_date"=>Time.now,
#      "test_date_ET"=>1262322000000, "profile_id"=>profile.id,
#      "last_value"=>"Yes"})
#
#    post :export_profile, params: {"form_name"=>"phr",
#      "fe"=>{"action_1"=>"Export",
#             "file_pwd_1_1"=>"a",
#             "record_name_1"=>"female_1940",
#             "record_name_C_1"=>profile.id_shown,
#             "file_format_C_1_1"=>"2",
#             "confirm_pwd_1_1"=>"a",
#             "file_format_1_1"=>"Excel"}}, session:
#      {:user_id=>user.id, :cur_ip=>'127.11.11.11'}
#    assert_response(:success)
#    assert_nil flash[:error]
#  end


  def test_do_ajax_save
    # At the moment this ONLY tests the processing of a data overflow
    # condition.  Actually - it doesn't even do that yet, but that's the
    # intent for this.  9/25. lm
#    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
#        'db_field_descriptions', 'db_table_descriptions', 'forms'], false)
#    # Define the user data table model classes
#    DbTableDescription.define_user_data_models
#    user = users(:PHR_Test)
#    profile = profiles(:phr_test_phr1)
  end # test_do_ajax_save


  # This actually tests the require_profile method that is in the User class.
  # I can't test it with a unit test, because unit tests don't have access
  # to the http request object.  So I needed to test it from a controller.
  #
  # Also, I'm not using the get_profile method in the application_controller,
  # even though that's what is used to get to the require_profile method in
  # the operational code.  I'm not using it because it does not allow
  # specification of the request object to be used - which in this case is
  # one we create for the test.
  #
  # The require_profile method is used to make sure that the profile a user
  # is requesting belongs to that user.  It also records requests to access
  # the profile.
  def test_user_require_profile

    session_data = {:cur_ip=>'127.11.11.11'}
    our_user = users(:temporary_account_3)
    our_profile = profiles(:standard_profile_3)

    # Test with parameters that look for a profile.  Use valid and invalid
    # parameters.

    # 1. valid user, profile id, minimum access level
    level, prof = our_user.require_profile(
                                    @controller.get_specified_url(@request),
                                    @request.session.id,
                                    session_data[:cur_ip],
                                    "testing User.require_profile",
                                    ProfilesUser::READ_ONLY_ACCESS,
                                    our_profile.id, true)
    assert(ProfilesUser::OWNER_ACCESS, level)
    assert_not_nil(prof)

    # 2. valid user, profile_id_shown, minimum access level
    level, prof = our_user.require_profile(
                                    @controller.get_specified_url(@request),
                                    @request.session.id,
                                    session_data[:cur_ip],
                                    "testing User.require_profile",
                                    ProfilesUser::READ_WRITE_ACCESS,
                                    our_profile.id_shown, false)
    assert(ProfilesUser::OWNER_ACCESS, level)
    assert_not_nil(prof)

    # 3. invalid user/profile combination
    sneaky_user = users(:PHR_Test)
    assert_raise(SecurityError) {
      level, prof = sneaky_user.require_profile(
                                         @controller.get_specified_url(@request),
                                         @request.session.id,
                                         session_data[:cur_ip],
                                         "testing User.require_profile",
                                         ProfilesUser::READ_ONLY_ACCESS,
                                         our_profile.id, true)
    }
    # 4. invalid "use_real_id" flag
    assert_raise(SecurityError) {
      level, prof = our_user.require_profile(
                                      @controller.get_specified_url(@request),
                                      @request.session.id,
                                      session_data[:cur_ip],
                                      "testing User.require_profile",
                                      ProfilesUser::OWNER_ACCESS,
                                      our_profile.id, false)
    }
    # 5. invalid profile_id_shown parameter
    assert_raise(SecurityError) {
      level, prof = our_user.require_profile(
                                      @controller.get_specified_url(@request),
                                      @request.session.id,
                                      session_data[:cur_ip],
                                      "testing User.require_profile",
                                      ProfilesUser::READ_WRITE_ACCESS,
                                      'xyz', false)
    }
    # 6.  invalid access level
    read_only_user = users(:standard_account_2)
    assert_raise(SecurityError) {
       level, prof = read_only_user.require_profile(
                                      @controller.get_specified_url(@request),
                                      @request.session.id,
                                      session_data[:cur_ip],
                                      "testing User.require_profile",
                                      ProfilesUser::READ_WRITE_ACCESS,
                                      our_profile.id, true)
    }
    # Now make sure the access attempts get reported in the database correctly.
    accesses = UsageStat.where(user_id: [our_user.id, sneaky_user.id,
                                        read_only_user.id]).
                         order('id').load
    assert_equal(6, accesses.size)
    0.upto(5).each do |num|
      det = accesses[num]
      if (num <= 1)
        assert_equal('valid_access', det.event)
      else
        assert_equal('invalid_access', det.event)
      end
      assert_equal("https://test.host", det.data['url'][0,18])
    end

    # Now test missing parameters - make sure an exception is thrown
    assert_raise(RuntimeError) {
      prof = our_user.require_profile(nil,
                                      @request.session.id,
                                      session_data[:cur_ip],
                                      "testing User.require_profile",
                                      ProfilesUser::READ_ONLY_ACCESS,
                                      our_profile.id, true)
    }
    assert_raise(RuntimeError) {
      prof = our_user.require_profile(@controller.get_specified_url(@request),
                                      nil, nil,
                                      "testing User.require_profile",
                                      ProfilesUser::READ_ONLY_ACCESS,
                                      our_profile.id, true)
    }

  end # test_user_require_profile


  test "show should return error code for missing form_name/id parameter" do
    # Add a route to get to show, which is not normally accessible.
    Rails.application.routes.draw do
      get '/form/show'=>'form#show'
    end
    get :show, params: {}
    assert_equal(400, @response.status)
    # Also, there should be something for the user to see, in case a user
    # mistyped a URL.
    assert(!@response.body.blank?)
    Rails.application.reload_routes!
  end


  def  test_update_reviewed_reminders
    # prepare user and profile
    user = users(:PHR_Test)
    profile = user.profiles.first

    # server side table shows all reminders are unread for the given user/profile
    reminders = ReviewedReminder.filter_by_user_and_profile(user.id, profile.id_shown)
    reminders.map{|e| e.latest = false; e.save!}
    assert ReviewedReminder.filter_by_user_and_profile(user.id, profile.id_shown).empty?

    # save the review status on server side after one reminder of the profile was reviewed by the user
    form_data={"profile_id"=> profile.id_shown, "reviewed_reminders"=>["msg_key_1"].to_json}
    session_data = {"user_id"=> user.id, "cur_ip" => "127.11.11.11" }
    get :update_reviewed_reminders, xhr: true, params: form_data, session: session_data
    assert_response :success

    # server side table show that one reminder was reviewed
    reviewed_reminders = ReviewedReminder.filter_by_user_and_profile(user.id, profile.id_shown)
    assert reviewed_reminders == ["msg_key_1"]

  end


  private #############  Private Methods ##########################

  # This gets called by the two methods that test the different methods of
  # searching.
  # TBD - this test needs to be revised.  The test code is very out of date.
  def shared_get_matching_field_vals_tests(method_to_test)
    # Test a single-list table
    field_desc = FieldDescription.find_by_display_name('Drug, Multum, search, list')
    assert_not_nil(field_desc)
    res = @controller.send(method_to_test, field_desc, 'tablet', 15)
    assert(res.size == 2)
    count = res[0]
    assert_equal(6546, count)
    drugs = res[1]
    assert_equal(15, drugs.size)
    assert_equal(String, drugs[1][:display][:drug_name].class)

    res = @controller.send(method_to_test, field_desc,
      'decongestant allergy tablet', 15)
    assert_equal(3, res[0])
    assert_equal(3, res[1].size)
#    assert_equal('Benadryl <span>Allergy</span> <span>Decongestant</span>, '+
#      '25 mg-60 mg oral <span>tablet</span>',
    assert_equal('Benadryl Allergy Decongestant, '+
      '25 mg-60 mg oral tablet',
      res[1][0][:display][:drug_name])

    # Test a multi-list table (with multiple fields)
    field_desc = FieldDescription.find_by_display_name('ICD9 with Synonyms')
    res = @controller.send(method_to_test, field_desc, '002.0', 15)
    assert_equal(2, res[0])
    assert_equal(2, res[1].size)
    assert_equal('002.0', res[1][0][:code])

    res = @controller.send(method_to_test, field_desc, 'back hand', 15)
    assert(7, res[0])
    assert(7, res[1].size)

    # Make sure the other lists are not included in the search
    res = @controller.send(method_to_test, field_desc, 'checkbox', 15)
    assert(0, res[0])
    assert(0, res[1].size)

  end
end
