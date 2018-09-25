require 'test_helper'

class DateRemindersControllerTest < ActionController::TestCase
  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  # Tests several actions in the controller.  (We have to create some test
  # data, so it is easier to test several in sequence.)
  def test_actions

    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items'])

    @user = create_test_user
    @profile = @user.profiles.create!
    @profile.phr = Phr.new(:birth_date=>'2000/5/2', :gender_C=>'F',
      :pseudonym=>'Ada', :latest=>true)
    @profile.phr.save!

    # Check the index page before there is a reminder
    session_data = {:page_view=>'basic', :user_id=>@user.id,
                    :cur_ip=>'127.11.11.11'}
    form_data = {:phr_record_id=>@profile.id_shown}

    get :index, params: form_data, session: session_data
    assert_response :success
    assert_not_nil @response.body.index('no date reminders')
    access_det = UsageStat.where(['profile_id = ?', @profile.id]).order('event_time desc').load
    assert_equal(1, access_det.size)
    det = access_det[0]
    assert_equal('valid_access', det.event)
    assert_equal("https://test.host/", det.data['url'][0,18])

    @profile.phr_medical_contacts.create!(:name=>'Dr. Z',
      :next_appt=>3.days.from_now.strftime('%Y/%-m/%-d'))

    get :index, params: form_data, session: session_data
    assert_response :success
    assert_nil @response.body.index('no date reminders') # there should be one
    assert_equal 1, @profile.date_reminders.size

    # Hide the reminder
    reminder = @profile.date_reminders[0]
    form_data[:id] = reminder.id
    post :hide, params: form_data, session: session_data
    assert_redirected_to phr_record_date_reminders_path
    assert_equal 0, @profile.date_reminders.reload.size
    assert_equal 1, @profile.hidden_date_reminders.size

    # Visit the hidden reminders page
    form_data.delete(:id)
    get :hidden, params: form_data, session: session_data
    assert_response :success
    assert_nil @response.body.index('no date reminders') # there should be one

    # Unhide the reminder
    form_data[:id] = @profile.hidden_date_reminders[0].id
    post :unhide, params: form_data, session: session_data
    assert_redirected_to hidden_phr_record_date_reminders_path
    assert_equal 0, @profile.hidden_date_reminders.reload.size
    assert_equal 1, @profile.date_reminders.reload.size

    # Check the hidden reminders page now to see what it looks like when empty
    form_data.delete(:id)
    get :hidden, params: form_data, session: session_data
    assert_response :success
    assert_not_nil @response.body.index('no hidden date reminders')
  end
end
