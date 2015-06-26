class UsageStat < ActiveRecord::Base
  belongs_to :user
  serialize :data
  
  # The maximum number of events not connected to a user that we store at
  # any one time.  
  
  MAX_NON_USER_ACCESSES = 12000
  # The format string used for datetime objects in the usage stats data.
  # This allows us to record fractional seconds down to the microsecond
  # (6 digits).  We don't really need THAT much precision, but the ruby
  # gem that works with MySQL for the fractional seconds seems to insist
  # on using 6 digits.
  FRAC_SECOND_FORMAT = "%Y-%m-%d %H:%M:%S.%6N"

  # Hash used to define the events from the client that don't need a user object
  # associated with them.  The login and captcha events don't need a user
  # associated with them - but those events are sent to this model class from
  # the server.   But some events sent from the client also don't need a user,
  # such as the form access events for Help when issued from the login page.
  NO_USER_OK = {"/accounts/logout" => {"form_opened" => {"form_name" => "help"},
                                       "form_closed" => {"form_name" => "help"},
                                       "focus_on"    => {"form_name" => "help"},
                                       "focus_off"   => {"form_name" => "help"}}}

  # Creates a new UsageStat object.
  #
  # Parameters:
  # * user_obj the user object if we have one.  It is possible that we will not
  #   have a user object for this call.  This will be the case for "prelogin"
  #   events - events that we track but that occur before the user has logged in.
  #   For example, we track use of the captcha object which comes up on the
  #   registration page and also on the "forgot id" page.  In both instances we
  #   don't have a user object when the event occurs.  This is OK.
  #
  # * profile_id the profile id, which may be nil - particularly when we don't
  #   have a user object, but also for events which occur at the user, rather
  #   than the profile, level (login, captcha, etc).
  #
  # * report_data an array containing arrays containing three elements:
  #   event type; date/time stamp for the event; event-specific data for the
  #   event.  This parameter is required.  See the Statistics design document
  #   on our TWIKI for a description of the event-specific data.
  #
  # * session_id the id of the session that generated the event.  This
  #   parameter is required.
  #
  # * ip_addr the ip_address from which this request originated.  This parameter
  #   is required.
  #
  # * convert_time an optional flag used to indicate whether or not to convert
  #   the date/time stamps in the report data.   Date/time stamps get converted
  #   to non-local time when they are sent from the client, because we use the
  #   Date.toISOString() javascript function to get a string that includes the
  #   fractional secons.  So this means we need to convert them to the
  #   local time for the server before storing them.  Date/time stamps created
  #   for events reported directly from the server do not have this problem and
  #   so don't require conversion to local time.  All time values are converted
  #   to a format using the FRAC_SECOND_FORMAT fractional time format string. 
  #   This parameter just adds conversion to local time.  The default value for
  #   the flag is true.
  #
  # Returns:
  # * nothing
  #
  def self.create_stats(user_obj,
                        profile_id,
                        report_data,
                        session_id,
                        ip_addr,
                        convert_time = true)

    # If there is no user_object specified, check first to make sure we
    # haven't hit the limit of the non-user accesses we will store.
    if (user_obj || store_non_user_accesses)

      # Parse the report data
      occurrence_data = JSON.parse(report_data)

      # Process the each array of data (in the occurrence_data array)
      adds = []
      occurrence_data.each do |event|
        do_add = true

        # If this is the last_active event, try to find a current last_active
        # event for this session.  If found, just update the date_time
        # parameter.
        if (event[0] == 'last_active')
          event[2]['date_time'] = our_time(event[2]['date_time'], convert_time)
          #if !last_active_id.nil?
            #if prev = UsageStat.find_by_id(last_active_id)
            if prev = UsageStat.where(session_id: session_id,
                                      event: 'last_active').take
              prev.data['date_time'] = event[2]['date_time']
              prev.save!
              do_add = false
            end
          #end
        end # if this is a 'last_active' event

        # Add the event - unless this was a "last_active" update.  Note that
        # we can't include the event_time in the create statement because
        # no matter what I do, it doesn't use the fractional second format
        # to store the data.  The insert statement that it creates drops off
        # the fractional value.   So we use the ActiveRecord execute statement
        # to store the date in the fractional format.  To minimize use of the
        # execute statement we use the rails create statement to create the
        # row and just use the execute statement to supply the full datetime.

        if do_add
          the_time = our_time(event[1], convert_time)
          if (event[0] == 'list_value')
            event[2]['start_time'] = our_time(event[2]['start_time'],
                                              convert_time)
          end
          user_id = user_obj.nil? ? nil : user_obj.id
          new_row = UsageStat.create!(:user_id => user_id,
                                      :session_id => session_id,
                                      :ip_address => ip_addr,
                                      :profile_id => profile_id,
                                      :event => event[0],
                                      :data => event[2])
          update_stmt = "UPDATE usage_stats SET event_time = '" + the_time +
                        "' WHERE id = " + new_row.id.to_s
          ActiveRecord::Base.connection.execute(update_stmt)
          adds << new_row
          if (event[0] == 'last_active')
            last_active_id = new_row.id
          end
        end # if we're adding a row
      end # do for each occurrence

      # If we created new objects figure the space used and update the user
      # object (if we have one).  We track this to protect against a
      # disk-filling denial-of-service attack.
      if !adds.empty? && !user_obj.nil?
        user_obj.usage_stats.concat(adds)
        accumulate_len = 0
        adds.each do |row|
          accumulate_len += UsageStat.get_row_length(row)
        end
        user_obj.accumulate_data_length(accumulate_len)
      end
    end # if we have a user object or are still storing non-user objects
  end # create_stats


  # This method looks for unassigned/incomplete login and captcha events and
  # attempts to complete the missing information.
  #
  # Incomplete login events are those that are not connected to a session id.
  # When a user logs in, the session id that is current at the time is deleted
  # and a new session id is created.  This is to block session hijacking
  # attempts.  The problem that it causes is that the new session id is not
  # assigned until after the login event is recorded - and after any code
  # executed during the login finishes.   So login events are initially written
  # with no session ids.
  #
  # This method attempts to find the appropriate session id for a login that is
  # missing one by finding the next event stored for the user id and ip address
  # of the target login event and, unless that subsequent event is also a login
  # or a captcha event, storing the session id from the subsequent event in
  # the data for the target login event.
  #
  # We assume that if the event immediately following the login is another login
  # or a captcha event, something went wrong and the session for the first login
  # was never used.
  #
  # Unassigned captcha events are those that are missing a user id.  This
  # method looks for the appropriate user id in two ways.
  #
  # After attempting to complete the session id of a login event, this method
  # checks to see if there are any captcha events with the old session id that
  # is stored in the login event's data column and a missing user_id.  If any
  # are found, they are assigned to the user who performed the login, with
  # the session id assigned to the login.
  #
  # After all incomplete logins are processed, this method checks for any
  # captcha events that are still missing a user id.  If any are found, this
  # searches for a logout event that immediately preceding the captcha event
  # that has the same user_id and session_id.  If a logout event is found,
  # the captcha event is assigned to the user who performed the logout.
  #
  def self.update_unassigned_events

    # Get any incomplete login reports.  
    logins = UsageStat.where("session_id is NULL AND user_id is NOT NULL " +
                   "AND event = 'login'").order("event_time")
 
    logins.each do |login |
      # Get the old session id that is stored in the data field of the
      # details row for the current row.
      old_session_id = login.data['old_session']
      next_stat = UsageStat.where("user_id = ? AND ip_address = ? AND " +
                                  "event_time > ?", 
                                  login.user_id, login.ip_address,
                                  login.event_time.strftime(FRAC_SECOND_FORMAT)).
                            order('event_time').first

      # If it's not for a login or captcha event it should have
      # the session id we want.  Since the user goes to a new page after
      # successfully logging in, and we are logging page open events, it's
      # pretty highly likely that the next event after a successful login will
      # be a page open that results from the login.
      if next_stat && next_stat.event != 'login' &&
         next_stat.event[0,6] != 'captcha'
        login.session_id = next_stat.session_id
        login.save!
      end # if we have a next stat

      # Check to see if there were any captcha events that preceded the login.
      # They would have the session id that we just replaced, and not be
      # assigned to a user.
      login_caps = UsageStat.where(["user_id is NULL AND event like " +
                                    "'captcha%' AND session_id = ?", old_session_id])
      login_caps.each do |lcap|
        lcap.user_id = login.user_id
        if !login.session_id.nil?
          lcap.session_id = login.session_id
        end
        lcap.save!
      end
    end # do for each login usage_stat without a session id

    # do one more check - to see if we have captcha events floating around
    # that belong to a user (as opposed to non-user captchas).  We can tell
    # that if there is a logout event for the session recorded for the captcha.
    caps = UsageStat.where("user_id is NULL AND event like 'captcha%'")
 
    caps.each do |cap|
      logout = UsageStat.order("event_time desc").limit(1).
                         where(["event = 'logout' AND " +
                                "session_id = ?", cap.session_id])
      if logout.length > 0
        cap.user_id = logout[0].user_id
        cap.save!
      end
    end
  end # update_unassigned_events
  
  
  # This determines whether or not we can store a non-user access event
  # to the database, based on whether or not we have hit the limit on how many
  # non-user accesses we will store in the database.  
  # Returns:
  # * true OK to store
  # * false do not store
  def self.store_non_user_accesses
    return UsageStat.where("user_id IS NULL").count < MAX_NON_USER_ACCESSES
  end


  # This converts a time value to a fractional time string.  In the case of times
  # received from the client, the convert flag should be passed in as true
  # to do the conversion to local time for the server.  We do the conversion(s)
  # in multiple places.
  #
  # Parameters:
  # * the_time the time value to be converted.  This may be a string or a Time
  #   object
  # * convert flag indicating whether or not the conversion needs to include
  #   a conversion to localtime
  # Returns:
  # * the fractional time string
  #
  def self.our_time(the_time, convert)
    time_val = (the_time.class == String) ? the_time.to_time(:utc) : the_time
    if (convert)
      time_str = time_val.localtime.strftime(FRAC_SECOND_FORMAT)
    else
      time_str = time_val.strftime(FRAC_SECOND_FORMAT)
    end
    return time_str
  end # our_time


  # This checks to see if a usage stats request that has no user object
  # associated with it is valid, i.e., that it is OK for the request to
  # have no user.  The determination is made by checking the NO_USER_OK
  # hash to see if the referring page, event type, and one of the parameters
  # match on the combinations defined in NO_USER_OK.
  #
  # Parameters:
  # * referer the (parital) url of the page that submitted the request
  # * report_data the data to be written to the data column of the
  #   usage_stats table
  # Returns:
  # * true for a valid event, or set of events
  # * false for an invalid event
  #
  def self.no_user_ok(referer, report_data)
    events_ok = false
    # If the referer is not found in NO_USER_OK, no need to check further
    if !NO_USER_OK[referer].nil?

      ref_hash = NO_USER_OK[referer]
      # Parse the report data
      occurrence_data = JSON.parse(report_data)
      # Process the each array of data (in the occurrence_data array)
      # There could be multiple events in the hash, so check each one
      occurrence_data.each do |event|
        # If the event type is not in the hash for the referer, no need to
        # check further
        if !ref_hash[event[0]].nil?
          # There are usually multiple parameters in the parameter hash;
          # look for the one that matches what's in NO_USER_OK
          event[2].each do |p_name, p_value|
            if !ref_hash[event[0]][p_name].nil? &&
               ref_hash[event[0]][p_name] == p_value
              events_ok = true
              break # out of parameter checks
            end # if we found a matching parameter
          end # parameter checks
          if events_ok == false
            break # out of event checks
          end
        end # if we found an invalid event
      end # event checks
    end # if the referring page even has an entry in the NO_USER_OK hash
    return events_ok
  end # no_user_ok

  
  # This pulls joined data from the usage_reports and usage_report_details
  # tables.  It excludes valid_access event data and can pull either all
  # data currently in the usage tables or just data that hasn't yet been pulled.
  # NOW ALL FROM usage_stats
  # 
  # This is used by the ResearchData get_research_data method.
  #
  # Parameters:
  # * include all - pull all data; new - just pull data not yet exported
  # Returns:
  # * the joined data
  #
  def self.research_data(include)
    #where_clause = "event != 'valid_access' and event != 'invalid_access'"
    where_clause = "event NOT LIKE '%alid_access'"
    if include == "new"
      where_clause += " and exported = false"
    end
    ret = UsageStat.where(where_clause).order('user_id, session_id, event_time, event')
    return ret.load
  end # research_data


  # This method flags usage_stats rows as exported for rows whose id is in
  # the ids array passed in.
  #
  # Parameters:
  # * ids the array of ids to be updated
  #
  # Returns:
  # * nothing
  #
  def self.update_exports(ids)
    UsageStat.where('id IN (?)',ids).update_all(:exported=>true)
  end # update_exports

end # usage_stat
