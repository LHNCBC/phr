require 'test_helper'

class PhrSurgicalHistoriesControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL

    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms',
        'gopher_terms', 'gopher_term_synonyms', 'text_lists', 'text_list_items',
        'word_synonyms'], true, 'text_lists'=>'list_name in ("Gender")',
        'text_list_items'=>'text_list_id in (21)')

    # Create a profile and a drug record, for testing
    user = users(:PHR_Test)
    @profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << @profile
    p = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :profile_id=>@profile.id, :birth_date=>'1950/1/2')
  end


  # Tests controller actions.  Just "search" for now.
  def test_actions
    session_data = {:user_id=>users(:PHR_Test).id, :cur_ip=>'127.11.11.11'}
    form_data = {:phr_record_id=>@profile.id_shown}

    # Check the search action
    form_data[:phr] = {:search_text=>'ar'}
    form_data[:id] = 'new'
    get :search, form_data, session_data
    assert_response :success
    assert_select('ul') # the list

    access_det = UsageStat.where(profile_id: @profile.id).
                           order('event_time desc').to_a
    assert_equal(1, access_det.size)
    det = access_det[0]
    assert_equal('valid_access', det.event)
    assert_equal("https://test.host/", det.data['url'][0,18])

  end

end
