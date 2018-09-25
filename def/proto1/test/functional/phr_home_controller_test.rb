require 'test_helper'
require 'phr_home_controller'
require 'date'

# Re-raise errors caught by the controller.
class PhrHomeController; def rescue_action(e) raise e end; end

class PhrHomeControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :profiles_users, :profiles, :phrs
 
  def setup
    @controller = PhrHomeController.new
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions', 'db_field_descriptions',
        'usage_stats', 'text_lists', 'text_list_items'])
    @request    = ActionController::TestRequest.create(@controller.class)
    @response   = ActionDispatch::TestResponse.new
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
    timecop_path = Dir[File.join(Gem.user_dir,"gems/timecop*/lib/")][0]
    require timecop_path + 'timecop'
  end

 
  # This tests the get_initial_listings method that populates the page after
  # page load.
  def test_get_initial_listings

    # Test requesting the page for a user with active, other, and removed phrs
    get :index, params: {:form_name=>'phr_home'}, session: {:user_id=>users(:phr_home_user).id}
    get :get_initial_listings, xhr: true, params: {}, session: {:user_id=>users(:phr_home_user).id,
                                          :cur_ip=>'127.11.11.11'}
    assert_response :success
    @profiles = assigns(:profiles)
    assert_not_nil(@profiles)
    assert_equal(3, @profiles.length)
    assert_equal('Ides of March', @profiles[0].phr.pseudonym)
    assert_equal('Liberty', @profiles[1].phr.pseudonym)
    assert_equal('Thankful', @profiles[2].phr.pseudonym)
    @other_profiles = assigns(:other_profiles)
    assert_equal('Happy New Year', @other_profiles[0].phr.pseudonym)
    @removed_profiles = assigns(:removed_profiles)
    assert_equal('Formerly Spring', @removed_profiles[0].phr.pseudonym)
    assert_equal('Just a blur', @removed_profiles[1].phr.pseudonym)
    assert_equal('Long Gone', @removed_profiles[2].phr.pseudonym)
 
    # While we're here, make sure the listing for the others section has
    # everything it should.  We do this in separate tests for the active
    # and removed sections, because there are separate methods to get those
    # listings.  A separate method is not needed for the others section,
    # so check here.

    ret = JSON.parse(response.body)
    oListings = ret['other']['listings']
    check_include = ['other_profile_line_1', 'o_icon_cell_1', 'o_wedgie_cell_1',
                     'o_name_cell_1', 'o_last_updated_cell_1',
                     'o_envelope_cell_1', 'o_health_reminders_cell_1',
                     'o_calendar_cell_1', 'o_date_reminders_cell_1',
                     'owner_cell_1', 'other_profiles_list', 'o_links_cell_1_1',
                     'o_links_cell_1_2','o_links_cell_1_3', 'o_links_cell_1_4',
                     'o_links_cell_1_5', 'o_access_cell_1',
                     PhrHomeController::FORM_LABELS["main_form"],
                     PhrHomeController::FORM_LABELS["export"],
                     PhrHomeController::FORM_LABELS["tests"],
                     PhrHomeController::FORM_LABELS["remove_my_access"],
                     PhrHomeController::FORM_LABELS["demographics"] ]
 
    check_include.each do |str|
      assert((oListings.include? str), 'Missing ' + str)
    end
 
    check_omits = [PhrHomeController::FORM_LABELS['import'],
                   PhrHomeController::FORM_LABELS['remove'],
                   PhrHomeController::FORM_LABELS['restore'],
                   PhrHomeController::FORM_LABELS['delete'],
                   PhrHomeController::FORM_LABELS['share_invite'],
                   PhrHomeController::FORM_LABELS['share_list'] ]
    check_omits.each do |str|
      assert_not((oListings.include? str), 'Includes ' + str)
    end

    # And check the user name
    uname = ret['user_name']
    assert_equal(users(:phr_home_user).name, uname)
 
    # Test for a user with only active profiles
    get :index, params: {:form_name=>'phr_home'}, session: {:user_id=>users(:phr_home_user2).id}
    get :get_initial_listings, xhr: true, params: {}, session: {:user_id=>users(:phr_home_user2).id,
                                          :cur_ip=>'127.11.11.11'}
    assert_response :success
    @profiles = assigns(:profiles)
    assert_not_nil(@profiles)
    assert_equal(2, @profiles.length)
    assert_equal('Happy New Year', @profiles[0].phr.pseudonym)
    assert_equal('Teddy Taxes', @profiles[1].phr.pseudonym)
    assert(assigns(:removed_profiles).empty?)
    assert(assigns(:other_profiles).empty?)

    # Test for a user with only removed profiles
    get :index, params: {:form_name=>'phr_home'}, session: {:user_id=>users(:phr_home_user3).id}
    get :get_initial_listings, xhr: true, params: {}, session: {:user_id=>users(:phr_home_user3).id,
                                          :cur_ip=>'127.11.11.11'}
    assert_response :success
    assert(assigns(:profiles).empty?)
    assert_not(assigns(:removed_profiles).empty?)
    assert(assigns(:other_profiles).empty?)

    # Test for a user with no profiles
    get :index, params: {:form_name=>'phr_home'}, session: {:user_id=>users(:phr_home_user4).id}
    get :get_initial_listings, xhr: true, params: {}, session: {:user_id=>users(:phr_home_user4).id,
                                          :cur_ip=>'127.11.11.11'}
    assert_response :success
    assert(assigns(:profiles).empty?)
    assert(assigns(:removed_profiles).empty?)
    assert(assigns(:other_profiles).empty?)
    
  end # test_get_initial_listings


  # This tests the controller method that handles an export/download request
  # and passes it on - if it's valid. Not testing file name parameter here
  # because it's optional (so no error is returned if it's missing) and a
  # successful return doesn't indicate the filename used - so it can't be
  # verified.
  def test_export_one_profile

    # confirm error return for missing id_shown and file_format parameters
    assert_raise ActionController::UrlGenerationError do
      get :export_one_profile, params: {},
                               session: {:user_id=>users(:phr_home_user).id,
                               :cur_ip=>'127.11.11.11'}
    end
 
    # confirm error return for missing id_shown parameter
    assert_raise ActionController::UrlGenerationError do
      get :export_one_profile, params: {:file_format=>"1"}, session:
                               {:user_id=>users(:phr_home_user).id,
                               :cur_ip=>'127.11.11.11'}
    end

    user1 = User.find_by_id(-15)
    user1_prof = user1.active_profiles.find_by_id(-41)
    # confirm error return for missing file_format parameter
    assert_raise ActionController::UrlGenerationError do
      get :get_export_one_profile, params: {:id_shown=>user1_prof.id_shown}, session:
                                   {:user_id=>users(:phr_home_user).id,
                                    :cur_ip=>'127.11.11.11'}
    end

    user2 = User.find_by_id(-16)
    user2_prof = user2.active_profiles.find_by_id(-46)
    # confirm error return for invalid id_shown parameter
    get :export_one_profile, params: {:id_shown=>'xyz',
                              :file_format=>"2"}, session:
                             {:user_id=>users(:phr_home_user).id,
                              :cur_ip=>'127.11.11.11'}
    assert_template file: '500.html'
    assert response.status == 500

    # confirm error return for invalid file_format parameter
    get :export_one_profile, params: {:id_shown=>user1_prof.id_shown,
                              :file_format=>"12"}, session:
                             {:user_id=>users(:phr_home_user).id,
                              :cur_ip=>'127.11.11.11'}
    assert_template file: '500.html'
    assert response.status == 500

    # confirm success for valid parameters
    get :export_one_profile, params: {:id_shown=>user1_prof.id_shown,
                              :file_format=>"2"}, session:
                             {:user_id=>users(:phr_home_user).id,
                              :cur_ip=>'127.11.11.11'}
    assert_response(:success)

  end # test_export_one_profile


  # This tests the method that returns the table listing the user's removed
  # profiles, if any, along with the restore and delete links specific to each
  # profile.
  def test_get_removed_listings

    get :get_removed_listings, xhr: true, params: {}, session: {:user_id=>users(:phr_home_user).id,
                                          :cur_ip=>'127.11.11.11'}
    ret = JSON.parse(response.body)
    rListings = ret['removed']['listings']
    check_include = ['removed_profile_line_1', 'removed_profile_line_2',
                     'removed_profile_line_3', 'rem_icon_cell_1',
                     'rem_icon_cell_2', 'rem_icon_cell_3', 'rem_name_cell_1',
                     'rem_name_cell_2', 'rem_name_cell_3', 'restore_cell_1',
                     'restore_cell_2', 'restore_cell_3', 'delete_cell_1',
                     'delete_cell_2', 'delete_cell_3',
                     PhrHomeController::FORM_LABELS["restore"],
                     PhrHomeController::FORM_LABELS["delete"]]

    check_include.each do |str|
      assert((rListings.include? str), 'Missing ' + str)
    end

  end # test_get_removed_listings


  # This tests the method that assembles and returns the html lines for
  # one active profile
  def test_get_one_active_profile_listing

    user1 = User.find_by_id(-15)
    user1_prof = user1.active_profiles.find_by_id(-41)
    user1_phr = user1.phrs.find_by_id(-41)
    user1_phr.birth_date = (DateTime.now - 100.years).strftime("%Y/%m/%d")
    user1_phr.save!

    get :get_one_active_profile_listing, xhr: true, params: {:id_shown=>user1_prof.id_shown,
                                                :row_num=>"12"}, session:
                                               {:user_id=>users(:phr_home_user).id,
                                                :cur_ip=>'127.11.11.11'}
    # this can actually use the assert_selects, because what gets returned is
    # the html for the section without being enclosed in a hash.
    assert_select 'tr#main_profile_line_12' do
      assert_select 'td#icon_cell_12', 1
      assert_select 'td#wedgie_cell_12', 1
      assert_select 'td#name_cell_12', 1
      assert_select 'td#last_updated_cell_12', 1
      assert_select 'td#envelope_cell_12', 1
      assert_select 'td#health_reminders_cell_12', 1
      assert_select 'td#calendar_cell_12', 1
      assert_select 'td#date_reminders_cell_12', 1
    end
    assert_select "tr.links_line_12", 3
    assert_select "td#links_cell_12_1", {count: 1,
                           text: PhrHomeController::FORM_LABELS["main_form"]}
    assert_select "td#links_cell_12_2", {count: 1,
                           text: PhrHomeController::FORM_LABELS["import"]}
    assert_select "td#links_cell_12_3", {count: 1,
                           text: PhrHomeController::FORM_LABELS["tests"]}
    assert_select "td#links_cell_12_4", {count: 1,
                           text: PhrHomeController::FORM_LABELS["export"]}
    assert_select "td#links_cell_12_5", {count: 1,
                           text: PhrHomeController::FORM_LABELS["demographics"]}
    assert_select "td#links_cell_12_6", {count: 1,
                           text: PhrHomeController::FORM_LABELS["remove"]}
    assert_select "td#links_cell_12_7", {count: 1,
                           text: PhrHomeController::FORM_LABELS["share_invite"]}
    assert_select "td#links_cell_12_8", {count: 1,
                           text: PhrHomeController::FORM_LABELS["share_list2"]}
  end # test_get_active_profile_listing


  # This tests the method that assembles and returns the html for a single
  # profile's name and age string, including the name link for that profile.
  def test_get_name_age_gender_updated_labels

    Timecop.freeze(Time.local(2014, 4, 1, 12, 0, 0))
    # reset the two dates involved - birth date and last updated
    # so that we can know what the return should be

    user1 = User.find_by_id(-15)
    user1_prof = user1.active_profiles.find_by_id(-40)
    user1_phr = user1.phrs.find_by_id(-40)
    user1_phr.birth_date = (DateTime.now - 10.days).strftime("%Y/%m/%d")
    user1_phr.save!

    # Set the last updated date to a value less than 3 hours, and make sure
    # the minutes are truncated.
    user1_prof.last_updated_at = DateTime.now - 3.hours
    user1_prof.last_updated_at -= 1.minutes
    user1_prof.save!

    get :get_name_age_gender_updated_labels, xhr: true, params: {:id_shown=>user1_prof.id_shown,
                                             :pseudonym=>user1_phr.pseudonym}, session:
                                            {:user_id=>users(:phr_home_user).id,
                                             :cur_ip=>'127.11.11.11'}
    assert_equal("[\"Liberty\",\"1 week old\",\"4 hours ago\"]", @response.body)
    Timecop.return

  end # test_get_name_age_gender_updated_labels
  
end # class PhrHomeControllerTest