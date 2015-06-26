require 'test_helper'

class SavingFormRecordsTest < ActionDispatch::IntegrationTest
  fixtures :users
  fixtures :two_factors
#  fixtures :db_table_descriptions
  
  # Tests creating a page, saving it, editing it, and saving it again.
  # Updated 10/2010 to work with combination of phr management & registration
  # pages.  Registration page no longer exists; management data saved to
  # server via an ajax call rather than a page submission.  lm.
  def test_saving_form_record
    DatabaseMethod.copy_development_tables_to_test(
     ['forms', 'field_descriptions', 'rules', 'rules_forms',
      'rule_actions', 'rule_cases', 'rule_fetches', 'rule_fetch_conditions',
      'rule_dependencies', 'rule_field_dependencies',
      'text_lists', 'text_list_items',
      'regex_validators', 'action_params', 'predefined_fields',
      'comparison_operators', 'comparison_operators_predefined_fields',
      'db_table_descriptions', 'db_field_descriptions'])
    
    # Define the user data table model classes (after the db_table_descriptions
    # table is copied above).
    DbTableDescription.define_user_data_models

    https! # Set the request to be SSL
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', {:fe=>{:user_name_1_1=>users(:PHR_Test).name,
                            :password_1_1=>'A password'}}
    assert_redirected_to('/phr_home?logging_in=true')

    # set up parameters to be sent by the ajax call to create a new profile
    params = {}
    params[:profile_id] = ""
    params[:data_table] = {:phrs=>[{:race_or_ethnicity_C=>'',
                                    :birth_date_ET=>'',
                                    :pseudonym=>'somebody',
                                    :birth_date_HL7=>'',
                                    :birth_date=>'12/01/1932',
                                    :gender=>'Male',
                                    :gender_C=>'M',
                                    :race_or_ethnicity=>''}]}.to_json
    params[:form_name] = "phr_index"
    params[:no_close] = "false"
    params[:act_url] = "https://localhost/profiles"
    params[:act_condition] = {:save=>"1", :action_C_1=>"1"}.to_json
    params[:message_map] = nil

    xml_http_request :post, '/form/do_ajax_save', params
    assert_response(:success)
    @response.body =~ %r{/profiles/([[:alnum:]]+);edit}
    assert_not_nil($1)
    id = $1

    # Check that a FormRecord was created with that id_shown value.
    profile = Profile.find_by_id_shown(id)
    assert_not_nil(profile)

    # Check that a PHR was saved for that form record
    phr = Phr.find_by_profile_id_and_latest(profile.id,true)
    assert_not_nil(phr)
    
    # Check the birth year
    assert_equal('12/01/1932', phr.birth_date)

    # Check the profile update timestamp is updated
    assert_not_nil(profile.last_updated_at)


    # check server side validation, required field only

    # updating the newly create phrs record with an empty required pseudonym
    # should return an error.
    params = {}
    params[:profile_id] = id
    params[:data_table] = {:phrs=>[{:race_or_ethnicity_C=>'',
                                    :birth_date_ET=>'',
                                    :pseudonym=>'',
                                    :birth_date_HL7=>'',
                                    :birth_date=>'12/01/1932',
                                    :gender=>'Male',
                                    :gender_C=>'M',
                                    :race_or_ethnicity=>''}]}.to_json
    params[:form_name] = "phr_index"
    params[:no_close] = "false"
    params[:act_url] = "https://localhost/profiles"
    params[:act_condition] = {:save=>"1", :action_C_1=>"1"}.to_json
    params[:message_map] = nil

    xml_http_request :post, '/form/do_ajax_save', params
    assert_response(500)
    assert_equal(1, JSON.parse(@response.body)["errors"].length)

    phr = Phr.find_by_profile_id_and_latest(profile.id,true)
    assert_not_nil(phr)

    # Check the pseudonym is not empty
    assert_equal('somebody', phr.pseudonym)


    # set up parameters to be sent by the ajax call to create a new profile,
    # expect a 500 error if the required pseudonym is empty
    params = {}
    params[:profile_id] = ""
    params[:data_table] = {:phrs=>[{:race_or_ethnicity_C=>'',
                                    :birth_date_ET=>'',
                                    :pseudonym=>'',
                                    :birth_date_HL7=>'',
                                    :birth_date=>'12/01/1999',
                                    :gender=>'Male',
                                    :gender_C=>'M',
                                    :race_or_ethnicity=>''}]}.to_json
    params[:form_name] = "phr_index"
    params[:no_close] = "false"
    params[:act_url] = "https://localhost/profiles"
    params[:act_condition] = {:save=>"1", :action_C_1=>"1"}.to_json
    params[:message_map] = nil

    xml_http_request :post, '/form/do_ajax_save', params
    assert_response(500)
    assert_equal(1, JSON.parse(@response.body)["errors"].length)

    # expect a message in 'errors' if the required birth date is empty
    params = {}
    params[:profile_id] = ""
    params[:data_table] = {:phrs=>[{:race_or_ethnicity_C=>'',
                                    :birth_date_ET=>'',
                                    :pseudonym=>'Another one',
                                    :birth_date_HL7=>'',
                                    :birth_date=>'',
                                    :gender=>'Male',
                                    :gender_C=>'M',
                                    :race_or_ethnicity=>''}]}.to_json
    params[:form_name] = "phr_index"
    params[:no_close] = "false"
    params[:act_url] = "https://localhost/profiles"
    params[:act_condition] = {:save=>"1", :action_C_1=>"1"}.to_json
    params[:message_map] = nil

    xml_http_request :post, '/form/do_ajax_save', params
    assert_response(500)
    assert_equal(1, JSON.parse(@response.body)["errors"].length)


    # save a test panel data
    data={:obr_orders =>
              [{:panel_name=>'Calcium',
                :loinc_num=>'49765-1',
                :test_place=>'',
                :single_test=>1,
                :_id_=>0,
                :test_date_ET=>'1395288000000',
                :test_date_HL7=>'20140320',
                :test_date=>'2014 Mar 20'}
              ],
          :obx_observations =>
              [{:record_id=>'',
                :obx3_2_obs_ident=>'Calcium',
                :obx5_value=>'123',
                :lastvalue_date=>'',
                :last_value=>'',
                :last_date=>'',
                :obx6_1_unit=>'',
                :unit_code=>'',
                :obx7_reference_ranges=>'',
                :loinc_num=>'49765-1',
                :obx5_1_value_if_coded=>'',
                :value_score=>'',
                :obx2_value_type=>'',
                :disp_level=>1,
                :is_panel_hdr=>false,
                :last_date_ET=>'',
                :last_date_HL7=>'',
                :test_normal_high=>'',
                :test_normal_low=>'',
                :required_in_panel=>true,
                :code_system=>'',
                :test_date=>'2014 Mar 20',
                :test_date_ET=>'1395288000000',
                :test_date_HL7=>'20140320',
                :test_date_time=>'',
                :value_real=>'',
                :test_danger_high=>'',
                :test_danger_low=>'',
                :_p_table_=>'obr_orders',
                :_p_id_=>0}
              ]
        }

    params = {}
    params[:profile_id] = id
    params[:data_table] = data.to_json
    params[:form_name] = "panel_edit"
    params[:no_close] = "true"
    params[:act_url] = "https://localhost/profiles/#{id}/panel_edit?from=popup"
    params[:act_condition] = {:save=>"1"}.to_json
    params[:message_map] = nil

    xml_http_request :post, '/form/do_ajax_save', params

    assert_response(:success)

    # obr data is saved
    obr = ObrOrder.find_by_profile_id_and_loinc_num_and_latest(profile.id,"49765-1",true)
    assert_not_nil(obr)
    assert_equal(1395288000000, obr.test_date_ET )
    assert_equal("Calcium", obr.panel_name)
    # obx data is saved
    obx = ObxObservation.find_by_profile_id_and_obr_order_id(profile.id, obr.id)
    assert_not_nil(obx)
    assert_equal('Calcium', obx.obx3_2_obs_ident)
    assert_equal('123', obx.obx5_value)
    assert_equal('49765-1', obx.loinc_num)

    # check obr_orders records with empty "When Done" cannot be saved.
    data={:obr_orders =>
              [{:panel_name=>'Calcium',
                :loinc_num=>'49765-1X',
                :test_place=>'',
                :single_test=>1,
                :_id_=>0,
                :test_date_ET=>'',
                :test_date_HL7=>'',
                :test_date=>''}
              ],
          :obx_observations =>
              [{:record_id=>'',
                :obx3_2_obs_ident=>'Calcium',
                :obx5_value=>'123',
                :lastvalue_date=>'',
                :last_value=>'',
                :last_date=>'',
                :obx6_1_unit=>'',
                :unit_code=>'',
                :obx7_reference_ranges=>'',
                :loinc_num=>'49765-1X',
                :obx5_1_value_if_coded=>'',
                :value_score=>'',
                :obx2_value_type=>'',
                :disp_level=>1,
                :is_panel_hdr=>false,
                :last_date_ET=>'',
                :last_date_HL7=>'',
                :test_normal_high=>'',
                :test_normal_low=>'',
                :required_in_panel=>true,
                :code_system=>'',
                :test_date=>'2014 Mar 20',
                :test_date_ET=>'1395288000000',
                :test_date_HL7=>'20140320',
                :test_date_time=>'',
                :value_real=>'',
                :test_danger_high=>'',
                :test_danger_low=>'',
                :_p_table_=>'obr_orders',
                :_p_id_=>0}
              ]
    }

    params = {}
    params[:profile_id] = id
    params[:data_table] = data.to_json
    params[:form_name] = "panel_edit"
    params[:no_close] = "true"
    params[:act_url] = "https://localhost/profiles/#{id}/panel_edit?from=popup"
    params[:act_condition] = {:save=>"1"}.to_json
    params[:message_map] = nil

    xml_http_request :post, '/form/do_ajax_save', params

    assert_response(:success)
    # but no error messages
    assert_equal(0, JSON.parse(@response.body)["errors"].length)
    # and obr data not saved (and no obx data either)
    obr = ObrOrder.find_by_profile_id_and_loinc_num_and_latest(profile.id,"49765-1X",true)
    assert_nil(obr)


    # when all test values are missing, then there's an error message
    data={:obr_orders =>
              [{:panel_name=>'Calcium',
                :loinc_num=>'49765-1Y',
                :test_place=>'',
                :single_test=>1,
                :_id_=>0,
                :test_date_ET=>'1395288000000',
                :test_date_HL7=>'20140320',
                :test_date=>'2014 Mar 20'}
              ],
          :obx_observations =>
              [{:record_id=>'',
                :obx3_2_obs_ident=>'Calcium',
                :obx5_value=>'',
                :lastvalue_date=>'',
                :last_value=>'',
                :last_date=>'',
                :obx6_1_unit=>'',
                :unit_code=>'',
                :obx7_reference_ranges=>'',
                :loinc_num=>'49765-1Y',
                :obx5_1_value_if_coded=>'',
                :value_score=>'',
                :obx2_value_type=>'',
                :disp_level=>1,
                :is_panel_hdr=>false,
                :last_date_ET=>'',
                :last_date_HL7=>'',
                :test_normal_high=>'',
                :test_normal_low=>'',
                :required_in_panel=>true,
                :code_system=>'',
                :test_date=>'2014 Mar 20',
                :test_date_ET=>'1395288000000',
                :test_date_HL7=>'20140320',
                :test_date_time=>'',
                :value_real=>'',
                :test_danger_high=>'',
                :test_danger_low=>'',
                :_p_table_=>'obr_orders',
                :_p_id_=>0}
              ]
    }

    params = {}
    params[:profile_id] = id
    params[:data_table] = data.to_json
    params[:form_name] = "panel_edit"
    params[:no_close] = "true"
    params[:act_url] = "https://localhost/profiles/#{id}/panel_edit?from=popup"
    params[:act_condition] = {:save=>"1"}.to_json
    params[:message_map] = nil

    xml_http_request :post, '/form/do_ajax_save', params
    # no error message (obx5_value is not required!!??)
    assert_equal(0, JSON.parse(@response.body)["errors"].length)
    # and obr data is saved
    obr = ObrOrder.find_by_profile_id_and_loinc_num_and_latest(profile.id,"49765-1Y",true)
    assert_not_nil(obr)
    # obx data is not saved
    obx = ObxObservation.find_by_profile_id_and_obr_order_id(profile.id, obr.id)
    assert_nil(obx)


    # We use do_ajax_save for the main phr form too
    # AND we pass it the data model data table.  Commenting this out,
    # per conversation with Ye.  We don't save this way anymore.  lm, 3/11/11
#    post '/profiles/' + id + ';edit', {:fe=>{:pseudonym=>'somebody1',
#                          :pregnant_1=>'Yes', :pregnant_C_1=>'25968', :save=>1,
#                          :tp1_invisible_field_panel_loinc_num_1_1=>'34566-0',
#                          :tp1_invisible_field_panel_name_1_1=>'Vital Signs Pnl',
#                          :tp1_panel_summary_1_1_1=>'summary test',
#                          :tp1_panel_testdate_1_1_1=>'2009 Feb 19',
#                          :tp1_test_value_1_1_1_1 => '90',
#                          :tp1_test_loinc_num_1_1_1_1 => '8867-4'
#      }}
#    phr = Phr.find_by_profile_id_and_latest(profile.id,true)
#    assert_not_nil(phr)
#    # check smoke
#    logger.debug 'phr = ' + phr.to_json
#    assert_equal('Yes', phr.pregnant)
#    assert_equal('25968',phr.pregnant_C)
#
#    # Check test panel data
#    test_panel = ObrOrder.find_by_loinc_num_and_profile_id('34566-0',
#      profile.id)
#    assert_equal('2009 Feb 19',test_panel.test_date)
#    assert_equal('summary test',test_panel.summary)
#
#    test_data = ObxObservation.find_by_loinc_num_and_profile_id('8867-4',
#      profile.id)
#    assert_equal('90',test_data.obx5_value)
#    assert_equal('2009 Feb 19',test_data.test_date)
#
#    # Now edit the smoke by submitting the form again, this time using
#    # the edit URL.
#    post '/profiles/' + id + ';edit', {:fe=>{:pseudonym=>'somebody',
#                     :pregnant_1=>'No', :pregnant_C_1=>'25969',
#                     :save_and_close=>1}}
#    assert_redirected_to('/profiles')
#    phr = Phr.find_by_profile_id_and_latest(profile.id, true)
#    assert_equal('No', phr.pregnant)
#    assert_equal('25969',phr.pregnant_C)
#    
  end
end
