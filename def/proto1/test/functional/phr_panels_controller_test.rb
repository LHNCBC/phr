require 'test_helper'

class PhrPanelsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  def test_actions
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items',
        'loinc_items', 'loinc_panels', 'loinc_units'])
    # Prior to the above copying of tables, define_user_data_models was run,
    # but list of tables might have been incomplete.  Run it again, because
    # for the tests below, it is important that PhrDataSanitizer be set up.
    DbTableDescription.define_user_data_models

    user = users(:PHR_Test)
    @profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << @profile
    p = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :profile_id=>@profile.id, :birth_date=>'1950/1/2')

    # The "new" page broke-- confirm that that works
    session_data = {:user_id=>users(:PHR_Test).id, :page_view=>'basic',
                    :cur_ip=>'127.11.11.11'}
    form_data = {:phr_record_id=>@profile.id_shown}
    get :new, form_data, session_data
    assert_response :success
    assert_nil flash[:error]

    access_det = UsageStat.where(profile_id: @profile.id).
                           order('event_time desc').to_a
    assert_equal(1, access_det.size)
    det = access_det[0]
    assert_equal('valid_access', det.event)
    assert_equal("https://test.host/", det.data['url'][0,18])

    # The "new" page "browse" link broke.  Confirm that works.
    form_data = {:phr_record_id=>@profile.id_shown, :browse=>1}
    get :new, form_data, session_data
    assert_response :success
    assert_nil flash[:error]

    # Check the flowhseet page for the case where there are no panels.
    # It will also be checked below after we create a panel.
    get :flowsheet, form_data, session_data
    assert_response :success
    assert_nil flash[:error]

    # Add a panel record
    form_data = {:phr_record_id=>@profile.id_shown,
      BasicModeController::FD_FORM_OBJ_NAME=>{:loinc_num=>'24356-8',
        :tp_panel_testdate=>'2012/5/21'}}
    assert_equal 0, @profile.obr_orders.size
    post :create, form_data, session_data
    assert_nil flash[:error]
    assert_equal [], @controller.page_errors
    assert_equal 1, @profile.obr_orders(true).size
    panel = @profile.obr_orders.first
    assert_redirected_to phr_record_phr_panel_items_url(@profile, panel)

    # Check the flowhseet page
    get :flowsheet, form_data, session_data
    assert_response :success
    assert_nil flash[:error]
    # Make sure the page shows up.  We had a bug where the page was mostly empty.
    assert_select 'input[type=submit]'

    # Add a record to the panel we created above
    panel.obx_observations.create!(:loinc_num=>'5767-9',
      :obx5_value=>'one<a>two', :latest=>1)

    # Submit the flowsheet form for the panel and check that the saved value is there
    form_data = {:phr_record_id=>@profile.id_shown,
       "commit"=>"Show Flowsheet",
      BasicModeController::FD_FORM_OBJ_NAME=>{"panels"=>{"24356-8"=>"1"},
        "group_by_C"=>"1", "date_range_C"=>"1", "start_date"=>"",
        "end_date"=>"", "in_one_grid"=>"0", "include_all"=>"0",
        "hide_empty_rows"=>"0"}}
    post :flowsheet, form_data, session_data
    # Check the returned content, making sure that things the the correct things
    # are html-escaped.  (Only user data should be escaped.)
    assert_select 'tr h3', /urinalysis/i # a panel header
    assert_select 'td a', false # false = asserting it is not there
    assert @response.body.index('one&lt; a&gt;two'), "Body was #{@response.body}" # should contain this
    assert @response.body.index('quot').nil? # should not contain this

    # Try posting with an invalid date, and confirm we get an error message
    form_data[BasicModeController::FD_FORM_OBJ_NAME] = {
      :start_date=>'asdf', :date_range_C=>'7'
    }
    post :flowsheet, form_data, session_data
    assert_response :success
    assert_not_nil flash[:error]

    # Try updating the list of selected values
    form_data[BasicModeController::FD_FORM_OBJ_NAME][:panels] =
      {'one'=>'1', 'two'=>'1'}
    post :flowsheet, form_data, session_data
    assert_response :success
    @profile = @profile.reload
    assert_equal ['one', 'two'], @profile.selected_panels

    # Remove one of the selected values
    form_data[BasicModeController::FD_FORM_OBJ_NAME][:panels] =
      {'one'=>'1', 'two'=>'0'}
    post :flowsheet, form_data, session_data
    assert_response :success
    @profile = @profile.reload
    assert_equal ['one'], @profile.selected_panels

  end
end
