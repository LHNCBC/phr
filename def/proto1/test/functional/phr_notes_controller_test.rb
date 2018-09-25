require 'test_helper'

class PhrNotesControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end
  
  def test_actions
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items'])

    DbTableDescription.define_user_data_models

    user = users(:PHR_Test)
    @profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << @profile
    p = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :profile_id=>@profile.id, :birth_date=>'1950/1/2')

    form_data = {:phr_record_id=>@profile.id_shown}
    session_data = {:user_id=>users(:PHR_Test).id, :cur_ip=>'127.11.11.11'}

    # Get an empty list of notes
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

    # Create a note
    form_data[:phr] =
      {:note_text=>'Howdy', :note_date=>'2004/1/3'}
    post :create, params: form_data, session: session_data
    assert_redirected_to :controller=>'phr_notes', :action=>:index
    assert_nil flash[:error]
    note = @profile.phr_notes.first
    assert_equal('Howdy', note.note_text)

    # Get a list of notes
    get :index, params: form_data, session: session_data, flash: {notice: nil}
    assert_response :success
    assert_nil flash[:error]
    assert_nil flash[:notice]
    assert @response.body.index('Howdy')

    # Try an edit
    form_data[:id] = note.id
    form_data[:phr][:note_text] = 'Hello, sir'
    post :update, params: form_data, session: session_data
    note = @profile.phr_notes.reload.first
    assert_equal('Hello, sir', note.note_text)

    # Delete the note
    post :destroy, params: {:phr_record_id=>@profile.id_shown, :id=>note.id}, session:session_data
    assert_nil flash[:error]
    assert_redirected_to :controller=>'phr_notes', :action=>:index
    assert_nil @response.body.index('Howdy')
    assert_equal 0, @profile.phr_notes.reload.size
  end
end
