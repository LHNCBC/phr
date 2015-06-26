require 'test_helper'

class UsageStatsControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :profiles
  fixtures :profiles_users
  fixtures :usage_stats # Added an empty fixture to meet the assumptions of the following tests

  DT_FORMAT = UsageStat::FRAC_SECOND_FORMAT

  def setup
    @controller = UsageStatsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  # This tests usage status event reports that come in from the client.  This
  # does not include testing from events that are reported directly from the
  # server (such as login, logout, etc).
  def test_create
 
    @user = users(:PHR_Test)
    @profile = profiles(:phr_test_phr1)

    # Test posting an empty report.  Set the user id in the sessions object
    # for this first request.  We don't need to set it after that.
    report_obj = {}
    post :create, {:report => report_obj.to_json}, {:user_id => @user.id}
    assert_response :success
    rep_data = @user.usage_stats
    assert_equal(0, rep_data.size)

    occ_data = []

    # Get the date into the format that comes from the client
    # For some reason the time that gets sent with the ajax request
    # are adjusted to the Greenwich Mean Time (GMT).  So when it gets to
    # the server, the UsageStat.create_stats method
    # converts it back to local time.  This is NOT done for times that
    # are created on the server (such as login, logout and timeout events),
    # but those are tested in the UsageStatTest (unit) since they go directly
    # to that.
    date_time = Time.new
    # Don't use the fixed number for the utc offset as it maybe different between summer and winter
    #js_date_time = (date_time + (60 * 60 * 4)).strftime(DT_FORMAT)
    js_date_time = (date_time.clone.utc).strftime(DT_FORMAT)
    sleep(1)
    # Send a request for an existing user with no profile specified
    occ_data << ['form_opened', js_date_time, {"form_name"=>"phr_home",
                                    "form_title"=>"My Personal Health Records"}]
    post :create, {:report => occ_data.to_json},
                  {:user_id => @user.id, :cur_ip => '123.4.5.6'}
    assert_response :success

    # Send a request for an existing user, request has 2 occurrences.
    # Clear the occurrence data before sending so that we don't resend the
    # form_opened event.  This is what happens normally - the client-side
    # data is cleared after it's sent to the server
    occ_data.clear
    occ_data << ['reminders_more', js_date_time, nil]
    occ_data << ['reminders_url', js_date_time, {"url" => "an@url.here"}]

    post :create, {:id_shown => @profile.id_shown ,
                   :report => occ_data.to_json}
    assert_response :success
    # check database contents
    rep_data = UsageStat.where(user_id: @user.id).order('id desc').to_a
    assert_equal(4, rep_data.size)
    rep_data.each do |row|
      assert_not_nil(row.session_id)
      assert_equal('123.4.5.6', row.ip_address)
      case row.event
      when "form_opened"
        assert_equal(date_time.strftime(DT_FORMAT),
                     row.event_time.strftime(DT_FORMAT))
        assert_nil(row.profile_id)
        assert_equal("phr_home", row.data['form_name'])
        assert_equal("My Personal Health Records", row.data['form_title'])
      when "reminders_more"
        assert_equal(date_time.strftime(DT_FORMAT),
                     row.event_time.strftime(DT_FORMAT))
        assert_equal(@profile.id, row.profile_id)
        assert_nil(row.data)
      when "reminders_url"
        assert_equal(date_time.strftime(DT_FORMAT),
                     row.event_time.strftime(DT_FORMAT))
        assert_equal(@profile.id, row.profile_id)
        assert_equal("an@url.here", row.data['url'])
      when "valid_access"
        assert(date_time.strftime(DT_FORMAT) < row.event_time.strftime(DT_FORMAT))
        assert_equal(@profile.id, row.profile_id)
        assert_equal("https://test.host/usage_stats?report=%7B%7D", row.data['url'])
      else
        puts "who is this?"
        puts row.to_json
      end # case
    end # each

    # Now test the last_active events.  First make sure there are no
    # last_active in the database for this user
    la_data = UsageStat.where(user_id: @user.id, event: 'last_active')
    assert_equal(0, la_data.size)

    # send a last_active event
    occ_data.clear
    la_time = (date_time.clone.utc).strftime(DT_FORMAT)
    la_time_conv = UsageStat.our_time(la_time, true)
    sleep(1)
    occ_data << ['last_active', js_date_time, {'date_time' => la_time}]

    post :create, {:id_shown => @profile.id_shown ,
                   :report => occ_data.to_json}
    assert_response :success

    # Check that there is just one last_active row in the database and
    # check its contents.  The date_time value will have been converted
    # since this is supposedly coming from the client, so check it against
    # a converted version of what we sent.
    la_data = UsageStat.where(user_id: @user.id, event: 'last_active')
    assert_equal(1, la_data.size)
    row = la_data.to_a[0]
    assert_equal(date_time.strftime(DT_FORMAT),
                 row.event_time.strftime(DT_FORMAT))
    assert_equal(@profile.id, row.profile_id)
    assert_equal(la_time_conv, row.data['date_time'])

    # Now advance the time and send another last_active event
    new_date_time = Time.new + 10
    la_time = (new_date_time.clone.utc).strftime(DT_FORMAT)
    la_time_conv = UsageStat.our_time(la_time, true)
    sleep(1)

    occ_data.clear
    occ_data << ['last_active', js_date_time, {'date_time' => la_time}]

    post :create, {:id_shown => @profile.id_shown ,
                   :report => occ_data.to_json}
    assert_response :success

    # Make sure we STILL only have one last_active event, and check
    # its contents to make sure it has the new date/time.
    la_data = UsageStat.where(user_id: @user.id, event: 'last_active')
    assert_equal(1, la_data.size)   
    row = la_data.to_a[0]
    assert_equal(date_time.strftime(DT_FORMAT),
                 row.event_time.strftime(DT_FORMAT))
    assert_equal(@profile.id, row.profile_id)
    assert_equal(la_time_conv, row.data['date_time'])
  end # test_create
end