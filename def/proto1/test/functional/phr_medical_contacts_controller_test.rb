require 'test_helper'

class PhrMedicalContactsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  def test_actions
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items', 'drug_name_routes', 'drug_strength_forms'])

    DbTableDescription.define_user_data_models

    user = users(:PHR_Test)
    @profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << @profile
    p = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :profile_id=>@profile.id, :birth_date=>'1950/1/2')

    form_data = {:phr_record_id=>@profile.id_shown}
    session_data = {:user_id=>users(:PHR_Test).id, :cur_ip=>'127.11.11.11'}

    get :index, params: form_data, session: session_data
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
      {:medcon_type_C=>'CARD', :medtact_name=>'Hart', :date=>'2004/1/3'}

    post :create, params: form_data, session: session_data
    assert_redirected_to :controller=>'phr_medical_contacts', :action=>:index
    assert_nil flash[:error]

    pmc = @profile.phr_medical_contacts.first
    assert_equal('Hart', pmc.name)

    # Try an edit, and confirm that we get a backup record.
    form_data[:id] = pmc.id
    form_data[:phr][:medtact_name] = 'Isaac'
    post :update, params: form_data, session: session_data
    pmc = @profile.phr_medical_contacts.reload.first
    assert_equal('Isaac', pmc.name)
    # Find the backup
    assert_equal(1, HistPhrMedicalContact.where(profile_id: @profile.id,
                                                record_id: pmc.record_id).count)
    assert_equal('Hart', HistPhrMedicalContact.where(profile_id: @profile.id,
                                                     record_id: pmc.record_id,
                                                     latest: 0).first.name)

    # Edit again, and confirm we now have two backups
    form_data[:phr][:medtact_name] = 'Jacob'
    post :update, params: form_data, session: session_data
    pmc = @profile.phr_medical_contacts.reload.first
    assert_equal('Jacob', pmc.name)
    assert_equal(2, HistPhrMedicalContact.where(profile_id: @profile.id,
                                                record_id: pmc.record_id).count)

    # Don't edit again but update, and confirm the number of backups doesn't change
    post :update, params: form_data, session: session_data
    pmc = @profile.phr_medical_contacts.reload.first
    assert_equal('Jacob', pmc.name)
    assert_equal(2, HistPhrMedicalContact.where(profile_id: @profile.id,
                                                record_id: pmc.record_id).count)
  end
end
