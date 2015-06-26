class ResearchData < ActiveRecord::Base

  # instance variables used to hold onto opening paired events that haven't
  # been paired with a corresponding closing paired event.
  @pending_opens = {}
  @pending_logins = {}
  @pending_focus = {}

  # instance variable used to hold onto problem event rows
 @problems = {}
 @problems_counts = {}

#  @stray_data_values = []
#  @unmatched_end_events = []
#  @unknown_event_types = []

  # instance variable used to hold onto ids of usage_reports rows to be updated
  # as exported
  @update_ids = []

  # Number of research data rows created
  @row_count = 0

 
  # This method controls the acquistion and processing of usage data to be
  # written to the research_data table.  Processing includes aquiring the
  # rows from the UsageStat class, processing them based on event type,
  # and creating a report on the success or failure of the conversion.
  #
  # Parameter:
  # * include specifies what usage data to process. 'all' specifies all current
  #   usage data; 'new' specifies just current usage data that has not been
  #   flagges as previously exported.
  #
  # Returns:
  # * status a code indicating the completion status for the export.  20 indicates
  #   successful completion with no problemmatic rows; 40 indicates completion
  #   with some error/problemmatic rows not exported; 50 indicates an exception
  #   was thrown and the export was not completed.
  #
  # * response_hash a hash including the count of the research_data rows written
  #   and a listing of any problemmatic rows.
  #
  def self.get_research_data(include)
    response_hash = {}
    have_errors = false
    cur_rp = nil    # for exception reporting if needed

    # First make sure that any unassigned events (login and prelogin events
    # not assigned to a session where possible) have been assigned
    UsageStat.transaction do
      UsageStat.update_unassigned_events
    end

    ResearchData.transaction do
      begin
        # Get the data and process each row based on the event type
        usage_data = UsageStat.research_data(include)
        usage_data.each do |rp|
          cur_rp = rp
          logger.debug ''
          logger.debug 'processing rp = ' + rp.to_json
          if !rp.data.nil?
            logger.debug 'rp.data.class = ' + rp.data.class.to_s
            rp.data = JSON.load(rp.data)
            logger.debug 'rp.data after Psych = ' + rp.data.to_json
            logger.debug 'rp.data.class after Psych = ' + rp.data.class.to_s
          end
          case rp.event
          when 'captcha_success' , 'captcha_failure'
            process_captcha_events(rp)
          when 'focus_on' , 'focus_off'
            ResearchData.process_focus_events(rp)
          when 'form_opened' , 'form_closed'
            ResearchData.process_form_events(rp)
          when 'info_button_opened'
            ResearchData.process_info_button_events(rp)
          when 'last_active'
            ResearchData.process_last_active_events(rp)
          when 'list_value'
            ResearchData.process_list_events(rp)
          when 'login' , 'logout'
            ResearchData.process_login_out_events(rp)
          when 'reminders_url' , 'reminders_more'
            ResearchData.process_reminder_events(rp)
          else
            add_problem(rp.user_id, rp.session_id, rp, 'unknown event type')
          end # rp.event case
        end # report loop
        response_hash['row_count'] = @row_count

        # Pass the updated_ids array back to the UsageStat data so that
        # the rows with those ids can be updated
        UsageStat.update_exports(@update_ids)

        # Clear the pending_focus, pending_opens and pending_logins of any
        # empty keys
        if !@pending_focus.empty?
          process_leftover_form_pendings(@pending_focus,
                                         'unmatched focus_off event')
        end # if we have pending focus events

        if !@pending_opens.empty?
          process_leftover_form_pendings(@pending_opens,
                                         'unmatched form_opened event')
        end # if we have pending opens
        if !@pending_logins.empty?
          process_leftover_session_pendings(@pending_focus,
                                            'unmatched login event')
        end

        # Now check to see if we have any left-over or unexpected data
        have_errors = !@problems.empty?
        if have_errors
          logger.debug ''
          logger.debug 'ERRORS FOUND - see ResearchDataImport_xxx for listings'
          logger.debug ''
          response_hash['problems'] = @problems
          response_hash['problems_counts'] = @problems_counts
        end # if have errors
      rescue Exception => e
        response_hash['exception_msg'] = e.message
        logger.debug ''
        logger.debug 'EXCEPTION: ' + e.message
        logger.debug ' cur_rp = ' + cur_rp.to_json
      end # rescue
    end # transaction
    status = !response_hash['exception_msg'].nil? ? 50 :
             have_errors ? 40 : 20
    return status, response_hash
  end # get_research_data


  # This method processes any leftover form-level "pending" rows, which are rows
  # that represent the start of a pair of events - currently a focus_off event
  # that needs to be paired with a focus_on event or a form_opened event that
  # needs to be paired with a form_closed event.
  #
  # This first clears the "pending" hashes of any keys that have no pending
  # rows.  The pending hashes are built out with user ids, session ids, and
  # form names as needed and are not cleared when a row is removed, to avoid
  # having to rebuild the has for the same user/session.
  #
  # This then processes leftover events to try to determine why no matching
  # event was found.  NOT WRITTEN YET.
  #
  # Any rows that remain after that process are then written to the @problems
  # hash to be reported to the user.
  #
  # Parameters:
  # * pending_hash the hash to be processed
  # * problem_desc the problem description to be written to the @problems hash
  #   for any rows that remain unexplained.
  #
  def self.process_leftover_form_pendings(pending_hash, problem_desc)

    # Clear out the empty keys
    pending_hash.each_pair do |user, session_rows|
      session_rows.each_pair do |session_id, forms|
#        forms.each_pair do |form_name, row|
#          if row.empty?
#            forms.delete(form_name)
#          end
#        end # form rows
        if forms.empty?
          session_rows.delete(session_id)
        end
      end # session_rows
      if session_rows.empty?
        pending_hash.delete(user)
      end
    end # pending_hash

    # THIS IS WHERE WE NEED TO FIGURE OUT WHY THEY ARE LEFTOVER.
    # is this specific to type, or would it apply to all?
    # should we assume no ending = crash or something?

    # Write any remaining problems
    if !pending_hash.empty?
      pending_hash.each_pair do |user_id, session_rows|
        session_rows.each_pair do |session_id, forms|
          forms.each_pair do |form_name, row|
              add_problem(user_id, session_id, row, problem_desc)
          end # forms
        end # session_rows
      end # pending_hash
    end # if we still have pending events

  end # process_leftover_form_pendings


  # This method processes any leftover session-level "pending" rows, which are
  # rows that represent the start of a pair of session-level events - currently
  # a login event that needs to be paired with a logout event.
  #
  # This first clears the "pending" hashes of any keys that have no pending
  # rows.  The pending hashes are built out with user and session ids as
  # needed and are not cleared when a row is removed, to avoid having to
  # rebuild the has for the same user/session.
  #
  # This then processes leftover events to try to determine why no matching
  # event was found.  NOT WRITTEN YET.
  #
  # Any rows that remain after that process are then written to the @problems
  # hash to be reported to the user.
  #
  # Parameters:
  # * pending_hash the hash to be processed
  # * problem_desc the problem description to be written to the @problems hash
  #   for any rows that remain unexplained.
  #
  def self.process_leftover_session_pendings(pending_hash, problem_desc)

    # Clear out the empty keys
    pending_hash.each_pair do |user, session_rows|
      session_rows.each_pair do |session_id, rows|
        if rows.empty?
          session_rows.delete(session_id)
        end
      end # session_rows
      if session_rows.empty?
        pending_hash.delete(user)
      end
    end # @pending_hash

    # THIS IS WHERE WE NEED TO FIGURE OUT WHY THEY ARE LEFTOVER.
    # is this specific to type, or would it apply to all?
    # should we assume no ending = crash or something?

    # Write any remaining problems
    if !pending_hash.empty?
      pending_hash.each_pair do |user_id, session_rows|
        session_rows.each_pair do |session_id, rows|
#debugger
          rows.each do |row|
            add_problem(user_id, session_id, row[1], problem_desc)
          end
        end
      end
    end # if we still have pending events

  end # process_leftover_session_pendings


  # This method adds a problem row to the @problems hash.  It takes care
  # of building out the hash for user_id, session_id and event_time as needed.
  #
  # Parameters:
  # * user_id the current user_id, used to group events by user
  # * session_id the current session_id, used to group events by session within
  #   a user_id
  # * row the row in which the problem was found
  # * problem the description of the problem found
  #
  def self.add_problem(user_id, session_id, row, problem)
    logger.debug 'add_problem called for problem = ' + problem
    logger.debug '                       row = ' + row.to_json
    logger.debug
    if @problems[user_id].nil?
      @problems[user_id] = {}
    end
    if @problems[user_id][session_id].nil?
      @problems[user_id][session_id] = {}
    end
    if @problems[user_id][session_id][row.event_time].nil?
      @problems[user_id][session_id][row.event_time] = []
    end
    @problems[user_id][session_id][row.event_time] << [problem, row,
                                       get_data_by_session(user_id, session_id)]
    if @problems_counts[problem].nil?
      @problems_counts[problem] = 1
    else
      @problems_counts[problem] += 1
    end
  end

  def self.get_data_by_session(user_id, session_id)

    if user_id.nil?
      id_clause = 'IS NULL '
    else
      id_clause = '= "' + user_id.to_s + '"'
    end

    UsageStat.research_data('all', 'user_id ' + id_clause +
                                     ' and session_id = "' + session_id + '"')


  end # get_data_by_session

  # This method processes a captcha event row - captcha_success and
  # captcha_failure.  Processing includes creating a research_data row for
  # the event and checking to make sure no invalid/unexpected parameters
  # were found in the data column.
  #
  # Parameter:
  # * rp the usage data row to be processed
  #
  def self.process_captcha_events(rp)
    ResearchData.create(
      :user_id => rp.user_id,
      :session_id => rp.session_id,
      :ip_address => rp.ip_address,
      :profile_id => rp.profile_id,
      :event => rp.event,
      :event_time => rp.event_time,
      :captcha_mode => rp.data.delete('mode'),
      :captcha_source => rp.data.delete('source'),
      :captcha_type => rp.data.delete('type')
    )
    @row_count +=1
    @update_ids << rp.usage_report_id
    if !rp.data.empty?
      add_problem(rp.user_id, rp.session_id, rp, 'stray data values')
    end
  end


  # This method processes a focus event row - focus_off and focus_on.
  #
  # These two types of events are processed as pairs, and each matched pair
  # is converted to one row to be written to the ResearchData.
  #
  # focus_off events are assumed to precede focus_on events, so when a focus_off
  # event is received by this method it is held in the pending_focus hash.
  # When the corresponding focus_on event is received, it is matched to the
  # focus_off event and a single research_data row is created that includes
  # the start time (focus_off event time) and end time (focus_on event time)
  # of the period where the user's focus was off the current form.  The event
  # name written for this is 'focus_off' to indicate that this was the time
  # that the user's focus was elsewhere.
  #
  # Processing includes checking to make sure no invalid/unexpected parameters
  # were found in the data columns of the usage data rows.
  #
  # Parameter:
  # * rp the usage data row to be processed
  #
  def self.process_focus_events(rp)
    if rp.event == 'focus_off'
      @pending_focus[rp.user_id] ||= {}
      @pending_focus[rp.user_id][rp.session_id] ||= {}
      @pending_focus[rp.user_id][rp.session_id][rp.data["form_name"]] = rp
    else
      if @pending_focus[rp.user_id].nil? ||
         @pending_focus[rp.user_id][rp.session_id].nil? ||
         @pending_focus[rp.user_id][rp.session_id][rp.data["form_name"]].nil?
        add_problem(rp.user_id, rp.session_id, rp, 'unmatched focus_on event')
      else
        f_off = @pending_focus[rp.user_id][rp.session_id].delete(rp.data["form_name"])
        ResearchData.create(
          :user_id => rp.user_id,
          :session_id => rp.session_id,
          :ip_address => rp.ip_address,
          :profile_id => rp.profile_id,
          :event => 'focus_off',
          :event_start => f_off.event_time,
          :event_stop => rp.event_time,
          :form_name => rp.data.delete("form_name"),
          :form_title => rp.data.delete("form_title")
        )
        @row_count += 1
        @update_ids << f_off.usage_report_id
        @update_ids << rp.usage_report_id
        f_off.data.delete("form_name")
        f_off.data.delete("form_title")
        if !f_off.data.empty?
          add_problem(rp.user_id, rp.session_id, f_off, 'stray data values')
        end
        if !rp.data.empty?
          add_problem(rp.user_id, rp.session_id, rp, 'stray data values')
        end
      end # if we got the matching focus_off row
    end # if this is a focus_off or a focus_on event
  end # process_focus_events


  # This method processes a form event row - form_opened and form_closed.
  #
  # These two types of events are processed as pairs, and each matched pair
  # is converted to one row to be written to the ResearchData.
  #
  # form_opened events are assumed to precede form_closed events, so when a
  # form_opened event is received by this method it is held in the pending_opens
  # hash.  When the corresponding form_closed event is received, it is matched
  # to the form_opened event and a single research_data row is created that
  # includes the start time (form_opened event time) and end time (form_closed
  # event time) of the period where the form was open.  The event name written
  # for this is 'form_open' to indicate that this was the time that the form was
  # open.
  #
  # Processing includes checking to make sure no invalid/unexpected parameters
  # were found in the data columns of the usage data rows.
  #
  # Parameter:
  # * rp the usage data row to be processed
  #
  def self.process_form_events(rp)
    if rp.event == 'form_opened'
      @pending_opens[rp.user_id] ||= {}
      @pending_opens[rp.user_id][rp.session_id] ||= {}
      @pending_opens[rp.user_id][rp.session_id][rp.data["form_name"]] = rp
    else
      if @pending_opens[rp.user_id].nil? ||
         @pending_opens[rp.user_id][rp.session_id].nil? ||
         @pending_opens[rp.user_id][rp.session_id][rp.data["form_name"]].nil?
        add_problem(rp.user_id, rp.session_id, rp, 'unmatched form_closed event')
      else
        f_open = @pending_opens[rp.user_id][rp.session_id].delete(rp.data["form_name"])
        ResearchData.create(
          :user_id => rp.user_id,
          :session_id => rp.session_id,
          :ip_address => rp.ip_address,
          :profile_id => rp.profile_id,
          :event => 'form_open',
          :event_start => f_open.event_time,
          :event_stop => rp.event_time,
          :form_name => rp.data.delete("form_name"),
          :form_title => rp.data.delete("form_title")
        )
        @row_count += 1
        @update_ids << f_open.usage_report_id
        @update_ids << rp.usage_report_id
        f_open.data.delete("form_name")
        f_open.data.delete("form_title")
        if !f_open.data.empty?
          add_problem(rp.user_id, rp.session_id, f_open, 'stray data values')
        end
        if !rp.data.empty?
          add_problem(rp.user_id, rp.session_id, rp, 'stray data values')
        end
      end # if we got the open row
    end # if this is a form_opened or a form_closed event
  end # process_form_events


  # This method processes an info_button_p[emed event row.  Processing includes
  # creating a research_data row for the event and checking to make sure no
  # invalid/unexpected parameters were found in the data column.
  #
  # Parameter:
  # * rp the usage data row to be processed
  #
  def self.process_info_button_events(rp)
    ResearchData.create(
      :user_id => rp.user_id,
      :session_id => rp.session_id,
      :ip_address => rp.ip_address,
      :profile_id => rp.profile_id,
      :event => rp.event,
      :event_time => rp.event_time,
      :info_url => rp.data.delete("info_url")
    )
    @row_count += 1
    @update_ids << rp.usage_report_id
    if !rp.data.empty?
      add_problem(rp.user_id, rp.session_id, rp, 'stray data values')
    end
  end


  # This method processes a last_active event row.  Processing includes creating
  # a research_data row for the event and checking to make sure no
  # invalid/unexpected parameters were found in the data column.
  #
  # Parameter:
  # * rp the usage data row to be processed
  #
  def self.process_last_active_events(rp)
    ResearchData.create(
      :user_id => rp.user_id,
      :session_id => rp.session_id,
      :ip_address => rp.ip_address,
      :profile_id => rp.profile_id,
      :event => 'user_activity',
      :event_start => rp.event_time,
      :event_stop => rp.data.delete("date_time")
    )
    @row_count +=1
    @update_ids << rp.usage_report_id
    if !rp.data.empty?
      add_problem(rp.user_id, rp.session_id, rp, 'stray data values')
    end
  end


  # This method processes a list_value event row.  Processing includes creating
  # a research_data row for the event and checking to make sure no
  # invalid/unexpected parameters were found in the data column.
  #
  # Parameter:
  # * rp the usage data row to be processed
  #
  def self.process_list_events(rp)
    ResearchData.create(
      :user_id => rp.user_id,
      :session_id => rp.session_id,
      :ip_address => rp.ip_address,
      :profile_id => rp.profile_id,
      :event => rp.event,
      :event_start => rp.data.delete("start_time"),
      :event_stop => rp.event_time,
      :list_field_id => rp.data.delete("field_id") ,
      :list_start_val => rp.data.delete("start_val"),
      :list_val_typed_in => rp.data.delete("val_typed_in"),
      :list_final_val => rp.data.delete("final_val"),
      :list_input_method => rp.data.delete("input_method"),
      :list_displayed_list => rp.data.delete("list"),
      :list_used_list => rp.data.delete("used_list"),
      :list_on_list => rp.data.delete("on_list"),
      :list_expansion_method => rp.data.delete("list_expansion_method"),
      :list_dup_warning => rp.data.delete("duplicate_warning"),
      :list_suggestion_list => rp.data.delete("suggestion_list"),
      :list_used_suggestion => rp.data.delete("used_suggestion"),
      :list_escape_key => rp.data.delete("escape_key"),
      :list_scenario => rp.data.delete("scenario")
    )
    @row_count += 1
    @update_ids << rp.usage_report_id
    if !rp.data.empty?
      add_problem(rp.user_id, rp.session_id, rp, 'stray data values')
    end
  end # process_list_events


  # This method processes a log in/out event row - login and logout.
  #
  # These two types of events are processed as pairs, and each matched pair
  # is converted to one row to be written to the ResearchData.
  #
  # login events are assumed to precede logout events, so when a login event
  # is received by this method it is held in the pending_logins hash.  When
  # the corresponding logout event is received, it is matched to the login
  # event and a single research_data row is created that includes the start time
  # (login event time) and end time (logout event time) of the period where the
  # user was logged in.  The event name written for this is 'logged_in' to
  # indicate that this was the time that the user was logged in.
  #
  # Processing includes checking to make sure no invalid/unexpected parameters
  # were found in the data columns of the usage data rows.
  #
  # Parameter:
  # * rp the usage data row to be processed
  #
  def self.process_login_out_events(rp)
    if rp.event == 'login'
      @pending_logins[rp.user_id] ||= {}
      @pending_logins[rp.user_id][rp.session_id] = rp
    else
      if @pending_logins[rp.user_id].nil? ||
         @pending_logins[rp.user_id][rp.session_id].nil?
        add_problem(rp.user_id, rp.session_id, rp, 'unmatched logout event')
      else
        login = @pending_logins[rp.user_id].delete(rp.session_id)
        ResearchData.create(
          :user_id => rp.user_id,
          :session_id => rp.session_id,
          :ip_address => rp.ip_address,
          :profile_id => rp.profile_id,
          :event => 'logged_in',
          :event_start => login.event_time,
          :event_stop => rp.event_time,
          :login_old_session => login.data.delete("old_session") ,
          :logout_type => rp.data.delete("type")
        )
        @row_count += 1
        @update_ids << login.usage_report_id
        @update_ids << rp.usage_report_id
        if !login.data.empty?
          add_problem(rp.user_id, rp.session_id, login, 'stray data values')
        end
        if !rp.data.empty?
          add_problem(rp.user_id, rp.session_id, rp, 'stray data values')
        end
      end # if we got the open row
    end # if this is a login or a logout event
  end # process_login_out_events


  # This method processes a reminders event row - reminders_url and
  # reminders_more.  Processing includes creating a research_data row for
  # the event and checking to make sure no invalid/unexpected parameters
  # were found in the data column.
  #
  # Parameter:
  # * rp the usage data row to be processed
  #
  def self.process_reminder_events(rp)
    if rp.event == 'reminders_url'
      ResearchData.create(
        :user_id => rp.user_id,
        :session_id => rp.session_id,
        :ip_address => rp.ip_address,
        :profile_id => rp.profile_id,
        :event => rp.event,
        :event_time => rp.event_time,
        :reminder_url => rp.data.delete("reminder_url")
      )
    else
      ResearchData.create(
        :user_id => rp.user_id,
        :session_id => rp.session_id,
        :ip_address => rp.ip_address,
        :profile_id => rp.profile_id,
        :event => rp.event,
        :event_time => rp.event_time,
        :reminder_topic => rp.data.delete("topic")
      )
    end
    @row_count += 1
    @update_ids << rp.usage_report_id
    if !rp.data.empty?
      add_problem(rp.user_id, rp.session_id, rp, 'stray data values')
    end
  end # process_reminder_events

end # ResearchData
