class UsageStatsController < ApplicationController
  before_filter :usage_stats_user_filter
  

  # Handles usage stats received from the client.  This returns an error
  # (status = 500) if the amount of data stored for the user has exceeded the
  # limits.  The user should get a message and be logged out.  Otherwise this
  # returns nothing.
  # 
  # Parameters (in params):
  # * :report the event report array that should contain data for all the events
  #   being reported by the client for this request
  # * :id_shown the profile id shown, if any, for the events.  This is not the
  #   same as the actual id of the profile data.
  #
  # Returns:
  # * an error if a data overflow error is detected; otherwise nothing
  #
  def create
    flash.keep
    feedback = Hash.new
    report_param = params[:report]

    # Only proceed if we actually got a report.  (The client side code should
    # prevent an empty report  - but ...).
    # I'm not sure what providing a failure response for a blank report would 
    # help in this case, so am not bothering.  If you can think of a reason
    # it would be useful, by all means add it and handle it in usageMonitor.js
    # and usage_stats_controller_test.rb

    if !report_param.blank? && report_param != '{}'
      begin

        # Get the id shown, if we have one.  If we do, call the get_profile
        # method to make sure this user has access to this profile.
        # If the user doesn't, a security error will be raised.  I'm specifying
        # read access as the minimum here because some things, like removing
        # the current user's access to someone else's profile, can be from
        # someone with just read access.

        if params[:id_shown].blank?
          profile_id = nil
        else
          @access_level, @profile = get_profile("create usage event row",
                                                ProfilesUser::READ_ONLY_ACCESS,
                                                params[:id_shown])
          profile_id = @profile.id
        end
        UsageStat.create_stats(@user,
                               profile_id,
                               report_param,
                               request.session_options[:id] ,
                               session[:cur_ip])

        # Call check_for_data_overflow, which is defined in ApplicationController
        # and will run the check on the current @user object.  ONLY do this if
        # we have a current @user object.  In some cases we will not, and that
        # will be OK.  See the usage_stats_user_filter below.
        if @user
          check_for_data_overflow
        end

      # rescue any errors.  Two that we could be expecting are
      # 1.  a data overflow error - from the check above; and
      # 2.  a security error, from the check (way above) to make sure
      #     the that the current user owns the current profile, if one was
      #     specified.

      # For case #1 (data overflow), we want the client to log out.
      rescue DataOverflowError => ovError
        feedback['do_logout'] = true
        feedback['exception'] = 1
        feedback['exception_type'] = 'data_overflow'
        feedback['exception_msg'] = ovError.message
        flash.keep[:error] = flash.now[:error]

      # Otherwise we have case #2
      rescue Exception => other_error
        SystemError.record_server_error(other_error, request, session)
        feedback['exception'] = 1
      end # begin
    end # if the report is not blank
    if !feedback['exception'].nil?
      render :status => 500,
             :json => feedback.to_json
    else
      render :nothing => true
    end
  end # create


  private


  # A before filter used to verify the user name both before and after
  # the user is logged in (where verifying before = during the login process).
  def usage_stats_user_filter

    # If the session data has a user id, verify by the authorize method
    if session[:user_id]
      authorize

    # Otherwise check to see if the event(s) need a user associated with them.
    # If they do, verify by the verify_user method.  Otherwise don't bother.
    # Note that not all events sent from the client need a user associated
    # with them.
    else
      if !UsageStat.no_user_ok(URI(request.referer).path, params[:report])
        verify_user
      end
    end
  end

end # usage_stats_controller
