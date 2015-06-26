require 'test_helper'

class PhrRecordsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  def test_actions
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items', 'answer_lists', 'list_answers', 'answers'])
    DbTableDescription.define_user_data_models
    
    user = users(:PHR_Test)
    @profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << @profile
    p = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :birth_date=>'2001', :profile_id=>@profile.id)

    # The "edit" page broke-- confirm that that works
    session_data = {:user_id=>users(:PHR_Test).id, :cur_ip=>'127.11.11.11'}
    form_data = {:id=>@profile.id_shown}
    get :edit, form_data, session_data
    assert_response :success
    assert_nil flash[:error]

    access_det = UsageStat.where(profile_id: @profile.id).
                           order('event_time desc').to_a
    assert_equal(1, access_det.size)
    det = access_det[0]
    assert_equal('valid_access', det.event)
    assert_equal("https://test.host/", det.data['url'][0,18])

    # While we're at it, also check update
    form_data = {:id=>@profile.id_shown, :phr=>{:birth_date=>'2012/4/5',
       :gender_C=>p.gender_C, :pseudonym=>p.pseudonym}}
    post :update, form_data, session_data
    assert_redirected_to phr_records_path
    assert_nil flash[:error]

    # Test the create action
    # First test the creation with a missing required field
    post :create, {:phr=>{:birth_date=>'2012/10/2',
       :gender_C=>'M'}}, session_data
    # The create action above issues a redirect if the creation is successful
    # (so a :success response means the expected failure).
    assert_response :success
    assert_not_nil flash[:error]

    # Also test creation with a missing birthdate field (which is a required
    # field, but was by some bug allowed to be blank.)
    post :create, {:phr=>{
       :gender_C=>'M', :pseudonym=>'Fred'}}, session_data
    assert_response :success
    assert_not_nil flash[:error]

    # Now test create with something that should work
    sleep 1 # Age the creation times a bit before creating a new one
    post :create, {:phr=>{:birth_date=>'2012/10/2',
       :gender_C=>'M', :pseudonym=>'Fred'}}, session_data
    new_profile = Profile.order('created_at desc').first
    assert_redirected_to phr_record_path(new_profile.id_shown)

    # Test the view action for the created record.
    get :show, {:id=>new_profile.id_shown}, session_data
    assert_response :success

    # Test the export
    get :export, {:id=>new_profile.id_shown}, session_data
    assert_response :success
    assert !@response.body.index('Export').nil?
    post :export, {:id=>new_profile.id_shown, :phr=>{:file_format=>'2'}}, session_data
    assert_response :success

    # Test the handling of autosave data.  If there is autosave data,
    # the user should be redirected to a warning page which tells them
    # they cannot continue without dropping the data.

    # First create some autosave data.
    AutosaveTmp.create(:user_id=>user.id, :profile_id=>@profile.id,
      :form_name=>'phr', :base_rec=>false)
    assert @profile.has_autosave?
    # Attempt to view the profile
    get :show, {:id=>@profile.id_shown}, session_data
    # The page we get should say something about autosaved data
    assert @response.body.index('utosave') # The 'A' might be capital or lowercase
    # Ignore it and try again
    get :show, {:id=>@profile.id_shown}, session_data
    assert @response.body.index('utosave')
    # Now pass the paramater to drop the autosave data
    get :show, {:id=>@profile.id_shown, :drop=>true}, session_data
    # Now the page should not say something about autosave
    assert @response.body.index('utosave').nil?
    # ...and the autosave data should be gone
    assert !@profile.has_autosave?
    assert_nil AutosaveTmp.find_by_user_id_and_profile_id_and_base_rec(user.id,
      @profile.id, false)
  end
end
