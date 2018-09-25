require 'test_helper'

class PhrPanelItemsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  def test_actions
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items',
        'loinc_items', 'loinc_panels', 'loinc_units',
        'answer_lists', 'list_answers', 'answers'])
    # Prior to the above copying of tables, define_user_data_models was run,
    # but list of tables might have been incomplete.  Run it again, because
    # for the tests below, it is important that HistObxObservation be set up.
    DbTableDescription.define_user_data_models

    user = users(:PHR_Test)
    @profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << @profile
    p = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :profile_id=>@profile.id, :birth_date=>'1950/1/2')

    # An OBX without a list
    obr = ObrOrder.create!("record_id"=>5, "test_date_HL7"=>"20110825",
      "loinc_num"=>"34566-0", "test_date"=>"2011 Aug 25", "latest"=>true,
      "version_date"=>"Thu Aug 25 17:34:28 -0400 2011",
      "test_date_ET"=>1314244800000, "profile_id"=>@profile.id,
      "panel_name"=>"Vital Signs Panel")
    obx = ObxObservation.create!("test_normal_low"=>"60", "record_id"=>1,
      "obx6_1_unit"=>"/min",
      "lastvalue_date"=>"65  [21.2 weeks ago]", "last_date_HL7"=>"20110330",
      "unit_code"=>"5593", "required_in_panel"=>true,
      "obx7_reference_ranges"=>"60-100", "obx3_2_obs_ident"=>"Heart rate",
      "obr_order_id"=>obr.id, "last_date_ET"=>1301460025344,
      "last_date"=>"2011 Mar 30", "test_normal_high"=>"100",
      "obx2_value_type"=>"PQ", "id"=>9910, "test_date_HL7"=>"20110825",
      "obx5_value"=>"124", "loinc_num"=>"8867-4", "test_danger_low"=>"40",
      "test_danger_high"=>"130", "test_date"=>"2011 Aug 25",
      "latest"=>true, "disp_level"=>1,
      "version_date"=>"Thu Aug 25 17:34:28 -0400 2011",
      "test_date_ET"=>1314244800000, "profile_id"=>@profile.id,
      "last_value"=>"65")

    # Confirm that this record can be pulled into an edit page
    form_data = {:phr_record_id=>@profile.id_shown, :phr_panel_id=>obr.id,
      :id=>obx.id}
    phr_data = {}
    form_data[BasicModeController::FD_FORM_OBJ_NAME] = phr_data
    session_data = {:user_id=>users(:PHR_Test).id, :cur_ip=>'127.11.11.11'}
    get :edit, params: form_data, session: session_data
    assert_response :success

    access_det = UsageStat.where(profile_id: @profile.id).
                           order('event_time desc').to_a
    assert_equal(1, access_det.size)
    det = access_det[0]
    assert_equal('valid_access', det.event)
    assert_equal("https://test.host/", det.data['url'][0,18])

    # Confirm that we can update the value and units
    phr_data[:alt_tp_test_value]='1234'
    phr_data[:tp_test_unit_C] = '5594' # 'bpm'
    put :update, params: form_data, session: session_data
    assert_redirected_to :controller=>'phr_panel_items', :action=>:index
    assert_nil flash[:error]
    assert_equal(phr_data[:alt_tp_test_value],
      ObxObservation.find_by_id(obx.id).obx5_value)
    assert_equal('bpm',
      LoincUnit.find_by_id(ObxObservation.find_by_id(obx.id).unit_code).unit)

    # Now test an OBX with a list.  (There were several things that broke about
    # this.)  First, create an OBR that has OBXes with coded list values.
    obr = ObrOrder.create!("record_id"=>6, "test_date_HL7"=>"20110825",
      "loinc_num"=>"24356-8", "test_date"=>"2011 Aug 25", "latest"=>true,
      "version_date"=>"Thu Aug 25 17:34:28 -0400 2011",
      "test_date_ET"=>1314244800000, "profile_id"=>@profile.id,
      "panel_name"=>"Urinalysis Panel")
    form_data[:phr_panel_id] = obr.id
    # Test the generation of the "new" panel item page
    form_data[:loinc_num] = '5767-9'
    get :new, params: form_data, session: session_data
    assert_response :success
    form_data.delete(:loinc_num)

    # Try to create an OBX with a standard list value.
    phr_data = {}
    form_data[BasicModeController::FD_FORM_OBJ_NAME] = phr_data
    phr_data[:loinc_num] = '5767-9'
    phr_data[:tp_test_value_C] = '1323'
    assert_equal 0, obr.obx_observations.size
    post :create, params: form_data, session: session_data
    assert_nil flash[:error]
    assert_redirected_to phr_record_phr_panel_items_url(@profile, obr)
    assert_equal 1, obr.obx_observations.reload.size

    # Confirm that the correct value shows on the next page.
    get :index, params: {:phr_record_id=>@profile.id_shown,
      :phr_panel_id=>obr.id}, session: session_data
    assert_not_nil @response.body.index('sl cldy')

    # Confirm that the correct value is selected if we pull up the page for
    # editing.
    obx = obr.obx_observations.first
    get :edit, params: {:phr_record_id=>@profile.id_shown, :phr_panel_id=>obr.id,
      :id=>obx.id}
    assert_select 'select option[selected="selected"][value="1323"]'

    # Delete the obx and try again with a non-standard value.
    obx = obr.obx_observations.first
    obx.destroy
    assert_equal 0, obr.obx_observations.reload.size
    phr_data[:tp_test_value_C] = ''
    phr_data[:alt_tp_test_value] = 'green'
    post :create, params: form_data, session: session_data
    assert_nil flash[:error]
    assert_redirected_to phr_record_phr_panel_items_url(@profile, obr)
    assert_equal 1, obr.obx_observations.reload.size
  end
end
