require 'test_helper'

class UsageStatTest < ActiveSupport::TestCase

  fixtures :users
  fixtures :profiles
  fixtures :profiles_users
  fixtures :usage_stats # Added an empty fixture to meet the assumptions of the following tests
  DUMMY_IP = '123.4.5.6'

  SECS_FMT = UsageStat::FRAC_SECOND_FORMAT

  # Tests the creation of user stats data in the user_stats table.  Tests events
  # that are reported directly on the server, such as captcha, login and logout
  # events.  Events that are reported from the client are tested in the
  # UsageStatsControllerTest (since they go through the controller).
  #
  def test_create_stats
    occ_data = []

    # test with ALL parameters empty
    rept_data = occ_data.to_json
    UsageStat.create_stats(nil, nil, rept_data, nil, nil)
    all_rept = UsageStat.all
    assert_equal(0, all_rept.size)
 
    date_time = Time.new.strftime(SECS_FMT)
    sess_id = '12345678'

    # test an invalid type? - there are no invalid types as far as this
    # code is concerned.

    # test 1 captcha event
    occ_data = [['captcha_failure', date_time,
                 {"mode"=>"basic","source"=>"basic_mode","type"=>"visual"}]]
    rept_data = occ_data.to_json

    UsageStat.create_stats(nil, nil, rept_data, sess_id, DUMMY_IP, false)
    ca = UsageStat.where(['session_id = ? AND user_id is NULL',sess_id]).load

    assert_equal(1, ca.size)
    car = ca[0]
    assert_equal(date_time, car.event_time.strftime(SECS_FMT),
                 "Incorrect event_time on 1 captcha event test")
    assert_equal(DUMMY_IP, car.ip_address)
    assert_equal('captcha_failure', car.event)
    assert_equal('basic', car.data["mode"])
    assert_equal('basic_mode', car.data["source"])
    assert_equal('visual', car.data["type"])
    assert_nil(car.profile_id)

    # test 3 captcha events
    sess_id = '22345678'
    date_time = Time.new.strftime(SECS_FMT)

    occ_data = [['captcha_failure', date_time,
                 {"mode"=>"basic","source"=>"basic_mode","type"=>"audio"}],
                ['captcha_success', date_time,
                 {"mode"=>"basic","source"=>"basic_mode","type"=>"visual"}],
                ['captcha_success', date_time,
                 {"mode"=>"basic","source"=>"basic_mode","type"=>"audio"}]]
    rept_data = occ_data.to_json

    UsageStat.create_stats(nil, nil, rept_data, sess_id, DUMMY_IP, false)
    ca = UsageStat.where(['session_id = ? AND user_id is NULL',
                                      sess_id]).order("id").load
    assert_equal(3, ca.size)
    type_counts = {}
    ca.each do |ca_row|
      if type_counts[ca_row.event].nil?
        type_counts[ca_row.event] = [ca_row.data]
      else
        type_counts[ca_row.event] << ca_row.data
      end
      assert_equal(date_time, ca_row.event_time.strftime(SECS_FMT),
                   "Incorrect event_time on 3 captcha events test")
      assert_nil(ca_row.profile_id)
      assert_equal(DUMMY_IP, ca_row.ip_address)
    end
    # We should have one of the failure event and two of the success event
    type_counts.each do |event_type, data_array|
      case
      when event_type == 'captcha_failure'
        assert_equal(1, data_array.size)
        assert_equal('basic', data_array[0]["mode"])
        assert_equal('basic_mode', data_array[0]["source"])
        assert_equal('audio', data_array[0]["type"])
      when event_type == 'captcha_success'
        assert_equal(2, data_array.size)
        assert_not_equal(data_array[0]["type"], data_array[1]["type"])
        data_array.each do |data_hash|
          assert_equal('basic', data_hash["mode"])
          assert_equal('basic_mode', data_hash['source'])
          assert(["visual","audio"].include?(data_hash["type"]))
        end
      else
        assert_equal('OK', 'invalid event type found in 3-captcha test',
                     event_type)
      end # case
    end

    # test login
    sess_id = '32345678'
    date_time = Time.new.strftime(SECS_FMT)

    @user = users(:PHR_Test)
    occ_data = [['login', date_time, {"old_session"=>"old session id"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(@user, nil, rept_data, sess_id, DUMMY_IP, false)
    ca = UsageStat.where(['session_id = ? AND user_id = ?',
                                      sess_id, @user.id]).order("id").load
    assert_equal(1, ca.size)
    car = ca[0]
    assert_equal(date_time, car.event_time.strftime(SECS_FMT),
                 "Incorrect event_time on 1 login event test")
    assert_equal(DUMMY_IP, car.ip_address)
    assert_equal('login', car.event)
    assert_equal("old session id", car.data["old_session"])
    assert_nil(car.profile_id)

    # test logout (timeout, user requested, data overflow)
    sess_id = '42345678'
    date_time = Time.new.strftime(SECS_FMT)

    occ_data = [['logout', date_time, {"type"=>"user_requested"}],
                ['logout', date_time, {"type"=>"timeout"}],
                ['logout', date_time, {"type"=>"data_overflow"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(@user, nil, rept_data, sess_id, DUMMY_IP, false)
    ca = UsageStat.where(['session_id = ? AND user_id = ?', sess_id, @user.id]).order("id").load

    assert_equal(3, ca.size)
    data_counts = {}
    ca.each do |car|
      assert_equal(date_time, car.event_time.strftime(SECS_FMT),
                   "Incorrect event_time on 3 logout events test")
      assert_equal(DUMMY_IP, car.ip_address)

      assert_equal('logout', car.event)
      if data_counts[car.data["type"]].nil?
        data_counts[car.data["type"]] = 1
      else
        data_counts[car.data["type"]] += 1
      end
      assert_nil(nil, car.profile_id)
    end
    # We should have 3 different data values
    assert_equal(3, data_counts.size)
    data_counts.each_pair do |key, count|
      assert(['user_requested', 'timeout', 'data_overflow'].include?(key))
      assert_equal(1, count)
    end

    # test list_values
    sess_id = 'list session'
    start_time = Time.new.strftime(SECS_FMT)

    # Find the first user with an active profile
    the_users = User.all
    num = 0
    while the_users[num].active_profiles.nil? ||
          the_users[num].active_profiles == []
      num += 1
    end
    a_user = the_users[num]
    profile_id = a_user.profiles[0].id 
    end_time = Time.new.strftime(SECS_FMT)

    occ_data = [['list_value', end_time, {"field_id" => "fe_problem_1",
                                          "start_val" => "",
                                          "val_typed_in" => "Knee pain",
                                          "used_list" => "false",
                                          "start_time" => start_time}],
                ['list_value', end_time, {"final_val" => "measles",
                                          "start_val" => "Knee pain",
                                          "val_typed_in" => "mea",
                                          "field_id" => "fe_problem_1",
                                          "used_list" => "false",
                                          "start_time" => start_time}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(a_user, profile_id, rept_data, sess_id, DUMMY_IP, false)
    ca = UsageStat.where(['session_id = ? AND user_id = ?', sess_id, a_user.id]).order("id").load

    assert_equal(2, ca.size)
    data_counts = {}
    ca.each do |car|
      assert_equal(end_time, car.event_time.strftime(SECS_FMT),
                   "Incorrect event_time on 2 list_value events test")
      assert_equal(DUMMY_IP, car.ip_address)
      assert_equal('list_value', car.event)
      assert_equal(profile_id, car.profile_id)
      car.data.each_pair do |key, value|
        if data_counts[key].nil?
          data_counts[key] = []
        end
        data_counts[key] << value
      end
    end
    # We should have 5 different data value keys
    assert_equal(6, data_counts.size)
    data_counts.each_pair do |key, val_array|
      case key
      when 'field_id'
        assert_equal(2, val_array.size)
        assert_equal(val_array[0], val_array[1])
        assert_equal('fe_problem_1', val_array[0])
      when 'start_val'
        assert_equal(2, val_array.size)
        assert_not_equal(val_array[0], val_array[1])
        val_array.each do |val|
          assert(['', 'Knee pain'].include?(val))
        end
      when 'val_typed_in'
        assert_equal(2, val_array.size)
        assert_not_equal(val_array[0], val_array[1])
        val_array.each do |val|
          assert(['Knee pain', 'mea'].include?(val))
        end
      when 'used_list'
        assert_equal(2, val_array.size)
        assert_equal(val_array[0], val_array[1])
        assert_equal('false', val_array[0])
      when 'final_val'
        assert_equal(1, val_array.size)
        assert_equal('measles', val_array[0])
      when 'start_time'
        assert_equal(2, val_array.size)
        assert_equal(val_array[0], val_array[1])
        assert_equal(start_time, val_array[0],
                     "Incorrect start_time on 2 list_value events test")
      else
        flunk('invalid key in data field for 2 list_value events test')
      end
    end
    
  end # test_create_stats


  # This tests the update_unassigned_events method.  This is done by loading
  # various events into the database using the create_stats method, and then
  # running the update_unassigned_events once.  Then the data that should have
  # been updated is tested to make sure that it is.
  #
  # I used this approach rather than inserting a little data, running the
  # method, inserting more, running the method, etc, because I wanted to make
  # sure that there aren't unexpected side effects from running the update.
  #
  def test_update_unassigned_events

    # CASE A:
    #   test a login with a following non-login event
    #   test a captcha with a following login and no preceding logout
    # data:
    #   a captcha for session a
    #   a login for user a, session a, info_button for user a, session b
    # expected results:
    #   login should end up with session b
    #   captcha should end up with user a, session b
    
    user_a = users(:PHR_Test)
    session_a = 'SESSIONA'
    session_b = 'SESSIONB'
    t = Time.now
    t_str = t.strftime(SECS_FMT)
    t10_str = (t + 10.seconds).strftime(SECS_FMT)
    t20_str = (t + 20.seconds).strftime(SECS_FMT)
    t30_str = (t + 30.seconds).strftime(SECS_FMT)
    t40_str = (t + 40.seconds).strftime(SECS_FMT)

    occ_data = [['captcha_success', t_str,
                 {"mode"=>"full","source"=>"registration","type"=>"visual"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(nil, nil, rept_data, session_a, DUMMY_IP, false)
    
    occ_data = [['login', t10_str,
                 {"old_session"=>session_a}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_a, nil, rept_data, nil, DUMMY_IP, false)

    occ_data = [['info_button_opened', t20_str,
                 {"info_url"=>"http://urlfor@infobutton"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_a, nil, rept_data, session_b, DUMMY_IP, false)

    # CASE B:
    #   test a login with a following login event
    # data:
    #   a login for user b, session c, login for user b, session d
    # expected results:
    #   both logins should remain unchanged

    user_b = users(:phr_admin)
    session_c = 'SESSIONC'
    session_d = 'SESSIOND'

    occ_data = [['login', t_str,
                 {"old_session"=>session_c}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_b, nil, rept_data, nil, DUMMY_IP, false)
    sleep 1
    occ_data = [['login', t10_str,
                 {"old_session"=>session_d}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_b, nil, rept_data, nil, DUMMY_IP, false)

    # CASE C:
    #   test a login with no following event
    # data:
    #   a login for user c, session e
    # expected results:
    #   login should remain unchanged

    user_c = users(:standard_account)
    session_e = 'SESSIONE'

    occ_data = [['login', t_str,
                 {"old_session" => session_e}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_c, nil, rept_data, nil, DUMMY_IP, false)

    # CASE D:
    #   test a login with a following captcha event
    # data:
    #   a login for user d, session f, captcha for session f
    # expected results:
    #   login should remain unchanged

    user_d = users(:standard_account_2)
    session_f = 'SESSIONF'

    occ_data = [['login', t_str,
                 {"old_session" => session_f}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_d, nil, rept_data, nil, DUMMY_IP, false)
    sleep 1
    occ_data = [['captcha_success', t10_str,
                 {"mode"=>"full","source"=>"registration","type"=>"visual"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(nil, nil, rept_data, session_f, DUMMY_IP, false)

    # CASE E:
    #   test a captcha with a following login and a preceding logout
    # data:
    #   a logout for user e, session g, captcha for session g,
    #     login for user e session g
    #   2 info_button_opened events for user e, session h
    # expected results:
    #   logout should remain unchanged
    #   captcha should change to session h, user e
    #   login should change to session h

    user_e = users(:standard_account_3)
    session_g = 'SESSIONG'
    session_h = 'SESSIONH'

    occ_data = [['logout', t_str, {"type" => "user_requested"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_e, nil, rept_data, session_g, DUMMY_IP, false)
    sleep 1
    occ_data = [['captcha_success', t10_str,
                 {"mode"=>"full","source"=>"forgot_password","type"=>"visual"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(nil, nil, rept_data, session_g, DUMMY_IP, false)
    sleep 1
    occ_data = [['login', t20_str, {"old_session"=>session_g}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_e, nil, rept_data, nil, DUMMY_IP, false)
    sleep 1
    occ_data = [['info_button_opened', t30_str,
                 {"info_url"=>"http://urlfor@infobutton2"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_e, nil, rept_data, session_h, DUMMY_IP, false)
    sleep 1
    occ_data = [['info_button_opened', t40_str,
                 {"info_url"=>"http://urlfor@infobutton3"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_e, nil, rept_data, session_h, DUMMY_IP, false)

    # CASE F:
    #   test a captcha with no following login but a preceding logout
    # data:
    #   a logout user f, session i, captcha session i
    # expected results:
    #   captcha should change to user f

    user_f = users(:standard_account_4)
    session_i = 'SESSIONI'

    occ_data = [['logout', t_str, {"type" => "user_requested"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(user_f, nil, rept_data, session_i, DUMMY_IP, false)
    sleep 1
    occ_data = [['captcha_success', t10_str,
                 {"mode"=>"full","source"=>"forgot_password","type"=>"visual"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(nil, nil, rept_data, session_i, DUMMY_IP, false)

    # CASE G:
    #   test a captcha with no following login and no preceding logout
    # data:
    #   captcha session j
    # expected results:
    #   no change to captcha

    session_j = 'SESSIONJ'
    occ_data = [['captcha_success', t_str,
                 {"mode"=>"full","source"=>"registration","type"=>"visual"}]]
    rept_data = occ_data.to_json
    UsageStat.create_stats(nil, nil, rept_data, session_j, DUMMY_IP, false)

    # Now run the update_unassigned_events method
    UsageStat.update_unassigned_events
 
    # Now check to see if things are as we expect

    # CASE A:
    #   test a login with a following non-login event
    #   test a captcha with a following login and no preceding logout
    # data:
    #   a captcha for session a
    #   a login for user a, session a, info_button_opened for user a, session b
    # expected results:
    #   login should end up with session b
    #   captcha should end up with user a, session b
    user_a_login = UsageStat.find_by_user_id_and_session_id_and_event(
                                             user_a.id.to_s, session_b, 'login')
    assert_not_nil(user_a_login)
    user_a_captcha = UsageStat.find_by_user_id_and_session_id_and_event(
                                   user_a.id.to_s, session_b, 'captcha_success')
    assert_not_nil(user_a_captcha)

    # CASE B:
    #   test a login with a following login event
    # data:
    #   a login for user b, session c, login for user b, session d
    # expected results:
    #   both logins should remain unchanged
    user_b_login_c = UsageStat.find_by_user_id_and_session_id_and_event(
                                             user_b.id.to_s, session_c, 'login')
    assert_nil(user_b_login_c)
    user_b_login_d = UsageStat.find_by_user_id_and_session_id_and_event(
                                             user_b.id.to_s, session_d, 'login')
    assert_nil(user_b_login_d)

   # CASE C:
    #   test a login with no following event
    # data:
    #   a login for user c, session e
    # expected results:
    #   login should remain unchangedu
    user_c_login = UsageStat.find_by_user_id_and_session_id_and_event(
                                             user_c.id.to_s, session_e, 'login')
    assert_nil(user_c_login)

    # CASE D:
    #   test a login with a following captcha event
    # data:
    #   a login for user d, session f, captcha for session f
    # expected results:
    #   login should remain unchanged
    user_d_login = UsageStat.find_by_user_id_and_session_id_and_event(
                                             user_d.id.to_s, session_f, 'login')
    assert_nil(user_d_login)
    session_f_captcha = UsageStat.where( "user_id IS NULL AND " +
                                       'session_id = "' + session_f + '" AND ' +
                                       'event = "captcha_success"').load
    assert_not_nil(session_f_captcha)
 
    # CASE E:
    #   test a captcha with a following login and a preceding logout
    # data:
    #   a logout for user e, session g, captcha for session g,
    #     login for user e session g
    #   2 info_button_opened events for user e, session h
    # expected results:
    #   logout should remain unchanged
    #   captcha should change to session h, user e
    #   login should change to session h
    user_e_logout = UsageStat.find_by_user_id_and_session_id_and_event(
                                            user_e.id.to_s, session_g, 'logout')
    assert_not_nil(user_e_logout)
    session_g_captcha = UsageStat.find_by_user_id_and_session_id_and_event(
                                   user_e.id.to_s, session_h, 'captcha_success')
    assert_not_nil(session_g_captcha)
    user_e_login = UsageStat.find_by_user_id_and_session_id_and_event(
                                             user_e.id.to_s, session_h, 'login')
    assert_not_nil(user_e_login)

    # CASE F:
    #   test a captcha with no following login but a preceding logout
    # data:
    #   a logout user f, session i, captcha session i
    # expected results:
    #   captcha should change to user f
    session_i_captcha = UsageStat.find_by_user_id_and_session_id_and_event(
                                   user_f.id.to_s, session_i, 'captcha_success')
    assert_not_nil(session_i_captcha)

    # CASE G:
    #   test a captcha with no following login and no preceding logout
    # data:
    #   captcha session j
    # expected results:
    #   no change to captcha
    session_j_captcha = UsageStat.where('user_id IS NULL AND ' +
                                       'session_id = "' + session_j + '" AND ' +
                                       'event = "captcha_success"').load
    assert_not_nil(session_j_captcha)

  end  # test_update_unassigned_events


  # This tests that the non-user usage event limit is working correctly.
  #
  def test_non_user_access_limit
 
    date_time = Time.new.strftime(SECS_FMT)
    sess_id = '12345678'
 
    # Create the smallest occurrence data and report data we can
    occ_data = [['login', date_time, {}]]
    rept_data = occ_data.to_json

    # Reset the limit on non user accesses so that this test doesn't
    # take 3 mintues to run.  Have to use class_eval because you can't
    # reset a constant at the instance level.
    class_eval("UsageStat::MAX_NON_USER_ACCESSES = 5")

    1.upto(UsageStat::MAX_NON_USER_ACCESSES) do |x|
      UsageStat.create_stats(nil, nil, rept_data, sess_id, DUMMY_IP, false)
    end
    # Confirm that we have the max number of usage reports with
    # with no user id
    cur_count = UsageStat.where('user_id IS NULL').count
    assert_equal(UsageStat::MAX_NON_USER_ACCESSES, cur_count)

    # Now try to add another
    UsageStat.create_stats(nil, nil, rept_data, sess_id, DUMMY_IP, false)

    # Check that we have the same number of reports
    new_count = UsageStat.where('user_id is NULL').count
    assert_equal(cur_count, new_count)

  end # test_non_user_access_limit


  # This tests the our_time method that converts a date/time value that
  # includes fractional seconds to a string that includes fractional seconds.
  #
  def test_our_time
    date_time = Time.now
    date_time_str = date_time.strftime(SECS_FMT)

    # Test passing in a Time value with and without a conversion to local time
    assert_equal(date_time_str, UsageStat.our_time(date_time, false))

    assert_equal(date_time_str, UsageStat.our_time(date_time.utc, true))

    # Test passing in a time string
    assert_equal(date_time_str, UsageStat.our_time(date_time_str, false))

    assert_equal(date_time_str,
                 UsageStat.our_time(date_time.utc.strftime(SECS_FMT), true))

  end # test_our_time
  
end # usage_stats_test
