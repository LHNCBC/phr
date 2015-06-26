require 'test_helper'

class PhrConditionsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL

    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items', 'gopher_terms', 'gopher_term_synonyms',
        'word_synonyms'], true)
    DbTableDescription.define_user_data_models
    
    # Create a profile and a PHR record, for testing
    user = users(:PHR_Test)
    @profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << @profile
    p = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :profile_id=>@profile.id, :birth_date=>'1950/1/2')
  end


  # Tests index search, new, edit, create, update, and destroy
  def test_actions
    session_data = {:user_id=>users(:PHR_Test).id, :cur_ip=>'127.11.11.11'}
    form_data = {:phr_record_id=>@profile.id_shown}

    get :index, form_data, session_data
    assert_response :success
    assert_nil flash[:error]
    assert_nil flash[:notice]
    access_det = UsageStat.where(profile_id: @profile.id).
                           order('event_time desc').to_a
    assert_equal(1, access_det.size)
    det = access_det[0]
    assert_equal('valid_access', det.event)
    assert_equal("https://test.host/", det.data['url'][0,18])
    
    # Check the new action
    get :new, form_data, session_data
    assert_response :success
    assert_nil flash[:error]
    assert_select('input#phr_search_text')

    # Check the search action
    form_data[:phr] = {:search_text=>'ar'}
    form_data[:id] = 'new'
    get :search, form_data, session_data
    assert_response :success
    assert_select('ul') # the list
    assert_nil flash[:error]

    # Continue to the new page
    form_data[:code] = 2958
    form_data.delete(:search_text)
    get :new, form_data, session_data
    assert_response :success
    assert_select('input#phr_problem')
    assert_nil flash[:error]

    # Save the record
    form_data[:phr] = {:problem=>'Arm pain', :present_C=>'A',
                          :prob_desc=>'Ouch'}
    assert_equal 0, @profile.phr_conditions.size
    post :create, form_data, session_data
    assert_redirected_to phr_record_phr_conditions_path
    assert_equal 1, @profile.phr_conditions(true).size # true = reload
    assert_nil flash[:error]
    cond = @profile.phr_conditions.first

    # Create a second condition, for the research studies test.
    form_data[:phr] = {:problem=>'Joint pain', :present_C=>'A'}
    post :create, form_data, session_data
    assert_redirected_to phr_record_phr_conditions_path
    assert_equal 2, @profile.phr_conditions(true).size # true = reload

    # Try the research studies link (for basic mode)
    get :studies, {:phr_record_id=>@profile.id_shown}, session_data
    assert @response.body.index('Arm pain')
    assert @response.body.index('Joint pain')
    assert @response.body.index('Alabama')
    # Try submitting the research studies form
    post :studies, {:phr_record_id=>@profile.id_shown,
      :phr=>{:problem=>'Arm pain', :state_C=>'1-AL', :age_group_C=>1,
      :phr_record_id=>@profile.id_shown}}, session_data
    assert_equal 'http://clinicaltrials.gov/search?recr=Open&cond=Arm%20pain&age=1&state1=NA%3AUS%3AAL',
      @response.redirect_url

    # The intial fix for 3720 (not checked in) broke the display labels on the
    # index page (the column headers in the table).  Make sure that someone does
    # not revert to that fix and break it again.
    form_data = {:phr_record_id=>@profile.id_shown}
    get :index, form_data, session_data
    assert @response.body.index('Status'),
      'The conditions index page should contain a table with a "Status" header.'

    # Edit it
    form_data = {:id=>cond.id, :phr_record_id=>@profile.id_shown}
    get :edit, form_data, session_data
    assert_response :success
    assert_nil flash[:error]

    # Update it
    # Also test that we can update a field to blank.
    form_data[:phr] = {:present_C=>'I', :prob_desc=>''}
    put :update, form_data, session_data
    assert_redirected_to phr_record_phr_conditions_path
    assert_nil flash[:error]
    assert_equal('A', cond.present_C)
    cond.reload
    assert_equal('I', cond.present_C)
    assert_equal('', cond.prob_desc)

    # Delete it
    assert_equal 2, @profile.phr_conditions.size
    post :destroy, form_data, session_data
    assert_redirected_to phr_record_phr_conditions_path
    assert_nil flash[:error]
    assert_equal 1, @profile.phr_conditions(true).size
  end


  # Test the preparation of error messages (for the basic mode)
  def test_basic_mode_errors
    PhrConditionsController.load_class_vars # loads the labels
    cond = PhrCondition.new(:present_C=>'A')
    cond.validate
    errors = cond.build_error_messages(PhrConditionsController.labels)
    assert_equal('Medical condition must not be blank', errors[0])
  end

end
