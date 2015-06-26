require 'test_helper'

class PhrAllergiesControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  def test_actions
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items', 'drug_name_routes', 'drug_strength_forms'])
    # Prior to the above copying of tables, define_user_data_models was run,
    # but list of tables might have been incomplete.  Run it again, because
    # for the tests below, it is important that HistPhrAllergy be set up.
    DbTableDescription.define_user_data_models

    # Primarily, we want to test the creation and update processes
    # to exercise update_record_with_params.
    user = users(:PHR_Test)
    @profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << @profile
    p = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :profile_id=>@profile.id, :birth_date=>'1950/1/2')

    form_data = {:phr_record_id=>@profile.id_shown}
    session_data = {:user_id=>users(:PHR_Test).id, :cur_ip=>'127.11.11.11'}

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

    form_data[:phr] =
      {:allergy_name_C1=>'FOOD-2', :reaction_date=>'asdf'}
    post :create, form_data, session_data
    assert_response :success
    assert_not_nil flash[:error] # for the date

    form_data[:phr][:reaction_date] = '2010/12/14'
    post :create, form_data, session_data
    assert_redirected_to :controller=>'phr_allergies', :action=>:index
    assert_nil flash[:error]

    allergy = @profile.phr_allergies.first
    assert_equal('Chocolate', allergy.allergy_name)
    assert_equal('FOOD-2', allergy.allergy_name_C)

    # Pick from a different allergy list and try again (but leave the old
    # value there)
    form_data[:phr][:allergy_name_C2] = 'DRUG-CLASS-2'
    form_data[:id] = allergy.id
    put :update, form_data, session_data
    assert_redirected_to :controller=>'phr_allergies', :action=>:index
    assert_nil flash[:error]
    allergy = @profile.phr_allergies(true).first
    assert_equal('Aminoglycosides', allergy.allergy_name)
    assert_equal('DRUG-CLASS-2', allergy.allergy_name_C)

    # Now change the first allergy list value and make sure the value changes
    form_data[:phr][:allergy_name_C2] = 'FOOD-7'
    form_data[:phr][:allergy_name_C1] = allergy.allergy_name_C
    put :update, form_data, session_data
    assert_redirected_to :controller=>'phr_allergies', :action=>:index
    assert_nil flash[:error]
    allergy = @profile.phr_allergies(true).first
    assert_equal('Gluten', allergy.allergy_name)
    assert_equal('FOOD-7', allergy.allergy_name_C)

    # Now use the alt field
    form_data[:phr][:alt_allergy_name] = 'Ice Cream'
    put :update, form_data, session_data
    assert_redirected_to :controller=>'phr_allergies', :action=>:index
    assert_nil flash[:error]
    allergy = @profile.phr_allergies(true).first
    assert_equal('Ice Cream', allergy.allergy_name)
    assert(allergy.allergy_name_C.blank?)

    # Create a new record using the alt field
    form_data[:phr] =
      {:alt_allergy_name=>'Lima Beans', :reaction_date=>'2010/12/14'}
    post :create, form_data, session_data
    assert_redirected_to :controller=>'phr_allergies', :action=>:index
    assert_nil flash[:error]
    allergy = @profile.phr_allergies(true).find_by_allergy_name('Lima Beans')
    assert_not_nil(allergy)
    assert(allergy.allergy_name_C.blank?)
  end
end
