# A controller that handles the phr_home page
class PhrHomeController < ApplicationController

  include PhrExporter
  include FlowsheetGenerator
  helper :phr_home
  include PhrHomeHelper
  include ApplicationHelper

  before_action :authorize

  # The around filter to enforce that a request be made by an ajax call for
  # methods that expect it. The filter is location in the ApplicationController.
  around_action :xhr_and_exception_filter,
    except: [:index, :export_one_profile, :get_other_profiles_section]

  # Labels used on the PHR Home page.  Defined here, and passed to the
  # client javascript (Def.PHRHome) when the page is loaded.  Although the
  # labels ultimately show on the home page, they are used on both the
  # server side (here) by the helper class and on the client side when
  # making additions, deletions, etc to the page.
  FORM_LABELS = {'main_form' => "Health Summary",
                 'tests' => "Test Results and Trackers",
                 'demographics' => "Demographics",
                 'import' => "Import",
                 'export' => "Download",
                 'remove' => "Make Inactive",
                 'share_invite' => "Share Access to this PHR",
                 'share_invite_btn' => "Send Invitation" ,
                 'share_list' => "See Others with Access",
                 'share_list2' => "No Others have Access" ,
                 'restore' => "Restore",
                 'delete' => "Delete" ,
                 'reminders_checking' => "Checking for reminders",
                 'remove_my_access' => "Remove My Access to this PHR",
                 'remove_this_access' => 'remove access'
                 }

  # Tooltips used on the PHR Home page.  Defined here, and passed to the
  # client javascript (Def.PHRHome) when the page is loaded.
  #
  FORM_TOOLTIPS = {"name" => "Show menu of options for this health record",
              "wedgie_up" => "Hide menu of options for this health record" ,
              "health_rem" => "View reminders for important vaccinations, " +
                              "cancer screenings, and other services that " +
                              "may be due",
              "date_rem" => "View upcoming and/or overdue appointment and " +
                            "prescription refill reminders and customize your " +
                            "reminder settings",
              "health_summary" => "View, add or edit health information " +
                                  "including medical conditions/surgeries, " +
                                  "medications/allergies, vaccinations, and " +
                                  "medical contacts",
              "tests" => "View, add or edit lab and procedure results and " +
                         "health tracker entries",
              "demographics" => "View or edit the name, age, gender and " +
                                "ethnicity associated with this record",
              "import" => "Import an electronic document (e.g., hospital " +
                          "discharge or office visit summary, radiology " +
                           "report) given to you by a healthcare provider.  " +
                           "This document is also called a CDA or CCD, and " +
                           "you may be able to merge some of the information " +
                           "directly into your personal health record.",
              "export" => "Download this health record to a spreadsheet file " +
                           "on your computer",
              "share_invite" => "TOOLTIP FOR SHARE ACCESS BUTTON",
              "share_list" => "TOOLTIP FOR SHARE LIST BUTTON",
              "remove" => "Make this health record inactive and move it to " +
                          "the Inactive PHRs section below.  Making it " +
                          "inactive will not delete the record",
              "restore" => "Make this health record active and move it to the " +
                           "My Personal Health Records section above",
              "delete" => "Delete this health record.  Once deleted, you will " +
                          "not be able to access this record or any of the " +
                          "the data it contains.",
              "remove_my_access" => "TOOLTIP FOR REMOVE MY ACCESS BUTTON",
              "remove_this_access" => "TOOLTIP FOR REMOVE THIS ACCESS LINK"
              }

  # Constants defined on the server that are also used on the client.  Packaged
  # into one array object to make it easier to pass them as well as add to and
  # delete from them.
  #
  PHR_HOME_CONSTANTS = [FORM_LABELS, FORM_TOOLTIPS, PHR_SYSTEM_NAME,
                        SHARE_INVITE_FROM_LINES, ProfilesUser::READ_ONLY_NOTICE]

  # Constant defining the error message text to be appended to error-specific
  # message text.
  ERR_MSG_END = "Please contact us using the Feedback page to provide " +
                "further information.  Thank you."


  # This method initiates display of the PHR Home page.  It obtains various
  # data objects that are required for the page and then calls the show method
  # in the application controller, which transfers that data to the client-side
  # loadPage method.
  #
  # The actual user's phr data is not supplied by this method, to avoid placing
  # user data in the page cache.  It is obtained from the client side when the
  # loadPage function is run.
  #
  # Parameters: none
  # Returns: none
  #
  def index
    session[:page_view] = 'default'
    if @user.nil? && !session[:user_id].nil?
      @user = current_user
    end

    # set @page_load_data to the values to be transferred from the server
    # to the client
    @page_load_data = Array.new(PHR_HOME_CONSTANTS)
    logging_in = params[:logging_in] == 'true'
    @page_load_data << logging_in
    params[:form_name] = 'phr_home'
    show
  end # index


  # This method processes a request to export a profile.  Checks are performed
  # here to make sure the current user owns the specified profile and that the
  # file format is specified correctly.  If the checks pass, the
  # handle_export_request in the phr_exporter module actually performs the
  # export.
  #
  # This method is not invoked via an ajax call, because of the way the
  # export request processing in the form controller and the phr export
  # controller was written.
  #
  # Parameters:
  # * id_shown - the id_shown for the profile
  # * file_format - the requested format for the export file.
  #   1 = CSV; 2 = Excel
  # * file_name - the name it o use for the export file.  If it's not
  #   specified, a name is contructed from the phr's pseudonym followed by
  #   the year, month, date, hours, minutes, seconds.
  #
  # Returns:
  # * if an error occurs, and error page is displayed
  #
  def export_one_profile
    # be optimistic
    status = 200
    # put this is in a begin/end block in case an exception is thrown by
    # the get_profile method.
    begin
      id_shown = params[:id_shown]
      @access_level, @profile = get_profile("export profile",
                                            ProfilesUser::READ_ONLY_ACCESS,
                                            id_shown)
      file_format = params[:file_format]
      if file_format.nil? ||
         (file_format != '1' && file_format != '2' && file_format != '3')
        status = 500
      else
        file_name = params[:file_name]
        if file_name.nil?
          file_name = (@profile.phr.pseudonym.delete " ") + ' ' +
                       DateTime.now.strftime("%Y%b%d%H%M%S")
        end
        handle_export_request(@profile, file_format, file_name)
      end
    rescue Exception => e
      status = 500
      SystemError.record_server_error(e, request, session)
    end # rescue
    # This is placed in a separate if block in case a status of 500
    # is returned from handle_export_request or we hit a problem with
    # the file format parameters passed in.
    if (status == 500)
      render_html_status_page(500)
    end
  end # export_one_profile


  # This method handles loading of the PHR Home page.  It is invoked from the
  # client-side loadPage method, to delay loading user data until population
  # of the page caches is complete.  This keeps the user data out of the caches.
  #
  # The actual display of the active and removed profiles is defined by the
  # _profiles_list.rhtml.erb and _removed_profile_listing.rhtml.erb views,
  # which are specified as templates in the field descriptions for the
  # phr_home form.
  #
  # This method is invoked through the xhr_and_exception_filter.
  #
  # Parameters: none
  # Returns: a hash containing the following:
  #  'active' => the html for the active profiles section
  #  'removed' => the html for the removed profiles section
  #  'other' => the html for the other profiles section
  #  'user_name' => the login name for the current user
  #  'has_pending_invites' => flag indicating whether or not there are pending
  #   shared access invitations for the current user
  #
  def get_initial_listings
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating the phrs for " +
                               @user.name + ".  " + ERR_MSG_END
    sections = {}
    sections['active'] = get_active_profiles_section
    sections['removed'] = get_removed_profiles_section
    sections['other'] = get_other_profiles_section
    sections['user_name'] = @user.name
    sections['has_pending_invites'] =
                     ShareInvitation.has_pending_share_invitations?(@user.email)
    render json: sections, status: :ok

  end # get_initial_listings


  # This method returns the listings for inactive (removed/archived) profiles.
  #
  # This method is invoked through the xhr_and_exception_filter.
  #
  # Parameters: none
  # Returns: renders the removed phrs list unless an error occurs
  #
  def get_removed_listings
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating the inactive phrs for " +
                               @user.name + ".  " + ERR_MSG_END

    sections = {}
    sections['removed'] = get_removed_profiles_section
    render json: sections, status: :ok

  end # get_removed_listings


  # This method returns the listings for "other" profiles.
  #
  # This method is invoked through the xhr_and_exception_filter.
  #
  # Parameters: none
  # Returns: renders the others phrs list unless an error occurs
  #
  def get_others_listings
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating the shared phrs for " +
                               @user.name + ".  " + ERR_MSG_END

    listings_hash = get_other_profiles_section
    render json: listings_hash, status: :ok

  end # get_others_listings


  # This method handles loading of the PHR Home page.  It is invoked from the
  # client-side loadPage method, to delay loading user data until population
  # of the page caches is complete.  This keeps the user data out of the caches.
  #
  # The actual display of the active and removed profiles is defined by the
  # _profiles_list.rhtml.erb and _removed_profile_listing.rhtml.erb views,
  # which are specified as templates in the field descriptions for the
  # phr_home form.
  #
  # This method is invoked through the xhr_and_exception_filter.
  #
  # Parameters: none
  # Returns: renders the active phrs list unless an error occurs
  #
  def get_active_profiles_section
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating the active phrs for " +
                               @user.name + ".  " + ERR_MSG_END

    active_profs = @user.active_profiles
    @profile_ids_shown = {}
    if active_profs.nil?
      @profiles = nil
      ret_block = {"count" => 0}
      ret_block["ids"] = {}
    else
      @profiles = active_profs.sort{|a,b|
                                     a.phr.pseudonym.casecmp(b.phr.pseudonym)}
      ret_block = {"count" => @profiles.length}
      u_data = {"url" => get_url, "action_name" => "get_active_profiles"}
      report_params = [['valid_access',
                        Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                        u_data]].to_json
      @profiles.each do |prof|
        UsageStat.create_stats(@user,
                               prof.id,
                               report_params,
                               request.session.id,
                               session[:cur_ip],
                               false)
      end
    end # if there are active profiles

    # Create the html for the active profiles list.  Even if there are no
    # active profiles, we go ahead and create the section.
    ret_block["listings"] = render_to_string(
                                    :partial =>'form/profiles_list_field.rhtml',
                                    :handlers => [:erb])

    ret_block["ids"] = @profile_ids_shown
    return ret_block
  end # get_active_profiles_section


  # This method handles an ajax request for the removed profiles listing for
  # all removed/archived profiles belonging to the current user (@user).  The
  # listing  is the html obtained from the removed_profiles_list_field view
  # (_removed_profiles_list_field.rhtml.erb).
  #
  # This method is invoked through the xhr_and_exception_filter.
  #
  # Parameters: none
  #
  # Returns:
  # * the html for the removed profiles list, unless an error occurred
  # * an error status and message if an error occurred
  #
  def get_removed_profiles_section
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating the removed " +
                               "phrs.  " + ERR_MSG_END

    removed_profs = @user.archived_profiles
    if removed_profs.nil?
      @removed_profiles = nil
      ret_block = {"count" => 0}
    else
      @removed_profiles = removed_profs.sort{|a,b|
                          a.phr.pseudonym.downcase <=> b.phr.pseudonym.downcase}
      ret_block = {"count" => @removed_profiles.length}
      # Create valid_access usage stats event for each removed profile
      #the_url = get_url(request)
      u_data = {"url" => get_url, "action_name" => "get_archived_profiles"}
      report_params = [['valid_access',
                        Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                        u_data]].to_json
      @removed_profiles.each do |prof|
        UsageStat.create_stats(@user,
                               prof.id,
                               report_params,
                               request.session.id,
                               session[:cur_ip],
                               false)
      end
    end # if we have removed profiles
    ret_block["listings"] = render_to_string(
                            :partial =>'form/removed_profiles_list_field.rhtml',
                            :handlers => [:erb])
    return ret_block
  end # get_removed_profiles_section


  # This method provides the "other" profiles listing for all profiles shared
  # with, but not belonging to the current user (@user).  The listing is the
  # html obtained from the other_profiles_list_field view
  # (_other_profiles_list_field.rhtml.erb).
  #
  # This is called by other methods in this controller, not by a client
  # request.
  #
  # Parameters: none
  #
  # Returns:
  # * the html for the other profiles list, unless an error occurred
  # * an error status and message if an error occurred
  #
  def get_other_profiles_section

    other_profs = @user.other_profiles
    @other_profile_ids_shown = {}
    if other_profs.nil?
      @other_profiles = nil
      ret_block = {"count" => 0}
    else
      @other_profiles = other_profs.sort{|a,b|
                          a.phr.pseudonym.downcase <=> b.phr.pseudonym.downcase}
      ret_block = {"count" => @other_profiles.length}
      # Create valid_access usage stats event for each other profile
      u_data = {"url" => get_url, "action_name" => "get_other_profiles"}
      report_params = [['valid_access',
                        Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                        u_data]].to_json
      @other_profiles.each do |prof|
        UsageStat.create_stats(@user,
                               prof.id,
                               report_params,
                               request.session.id,
                               session[:cur_ip],
                               false)
      end
    end # if we do have other profiles

    ret_block["listings"] = render_to_string(
                              :partial =>'form/other_profiles_list_field.rhtml',
                              :handlers => [:erb])
    ret_block["ids"] = @other_profile_ids_shown
    return ret_block
  end # get_other_profiles_section


  # This method handles an ajax request for the listing for a single active
  # profile belonging to the current user (@user).  The listing is the html
  # obtained from the profile_listing view (_profile_listing.rhtml.erb).  This
  # is called when an inactive (removed/archived) phr is restored to active
  # status.
  #
  # This method is invoked through the xhr_and_exception_filter.
  #
  # Parameters:
  # * row_num - the string version of the row number to be used in the listing
  # * id_shown - the id shown for the profile
  #
  # Returns:
  # * the html for the removed profiles list, unless an error occurred
  # * an error status and message if an error occurred
  #
  def get_one_active_profile_listing
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error accessing this phr.  " +
                               ERR_MSG_END
    row_s = params[:row_num]
    id_shown = params[:id_shown]
    @access_level, @profile = get_profile("get one active profile listing",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          id_shown)
    render(:partial =>'form/profile_listing.rhtml',
           :handlers => [:erb],
           :locals=>{:row_s=>row_s, :profile=>@profile})
  end # get_active_profile_listing


  # This method handles an ajax request for the name, age & last updated text
  # for a single profile belonging to the current user (@user).  The text is
  # returned as an array as described below.  This is called after the user
  # has updated the demographics data for a single profile.  The last updated
  # text will definitely change, and the name and age could also change.
  #
  # This method is invoked through the xhr_and_exception_filter.
  #
  # Parameters:
  # * pseudonym - the pseudonym for the profile
  # * id_shown - the id shown for the profile
  #
  # Returns:
  # * a three or four element array containing
  #   1) the name in the first element;
  #   2) the age in the second element;
  #   3) the last updated string in the third element; and
  #   4) IF gender is requested, the gender in the last element; OR
  # * an error status and message if an error occurred
  #
  def get_name_age_gender_updated_labels
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error accessing this phr.  " +
                               ERR_MSG_END
    @access_level, @profile = get_profile("get profile name and age",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          params[:id_shown])
    pseudonym = params[:pseudonym]
    new_phr = @user.phrs.where(:pseudonym => pseudonym)
    ret = new_phr[0].name_age_gender_label(true, false)
    ret << how_long_ago(@profile.last_updated_at)
    render :status => 200, :json => ret
  end # get_name_age_gender_updated_labels


  # This method returns the list of other users who have access to a profile
  # (where "other" here means "not the current user").
  #
  # This method is invoked through the xhr_and_exception_filter.
  #
  # Parameters: none
  # Returns: renders the access list unless an error occurs
  #
  def get_access_list
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating the others who " +
                               "have access to the phr.  " + ERR_MSG_END

    id_shown = params[:id_shown]
    @access_level, @profile = get_profile("get list of others with access",
                                          ProfilesUser::OWNER_ACCESS, id_shown)
    @access_list = Array.new(@profile.users)
    @access_list.each do |accessor|
      if accessor.id == @user.id
        @access_list.delete(accessor)
      end
    end
    @access_list_size = @access_list.size
    @prof_name = @profile.phr.pseudonym
    render(:partial =>'form/access_list_field.rhtml',
           :handlers => [:erb],
           :locals=>{:prof_id => @profile.id, :id_shown => id_shown})

  end # get_access_list


  # This method removes access to a profile from a user.
  #
  # This method is invoked through the xhr_and_exception_filter.
  #
  # Parameters - in params
  # * user_id the id of the user object from which access is to be removed. If
  #   passed in nil, @user is assumed
  # * id_shown the id_shown value for the profile
  # Returns: nothing (unless it blows up, which is handled by the filter
  #
  def remove_access
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating and/or removing " +
                               "access to the phr.  " + ERR_MSG_END

    user_id = params[:user_id]
    # if a blank user_id was passed in, that means that an "other" user is
    # requesting to remove his/her own access to a profile owned by someone
    # else.  In this case only READ_ONLY_ACCESS is required
    if user_id.blank?
      logger.debug ''
      logger.debug 'in remove access, user_id passed in blank'
      user_id = @user.id
      access_needed = ProfilesUser::READ_ONLY_ACCESS
      logger.debug 'user_id now = ' + user_id.to_s
      logger.debug ''
    # Otherwise this is the owner requesting that access be removed from
    # someone else.  Owner access is required for this.
    else
      access_needed = ProfilesUser::OWNER_ACCESS
    end
    id_shown = params[:id_shown]
    @access_level, @profile = get_profile("remove access to a profile",
                                          access_needed, id_shown)
    ProfilesUser.remove_access(user_id, @profile.id)

    # assume that an error above will throw an exception (because it does)
    # so we can just render nothing here, which will return success    
    render nothing: true

  end # remove_access

end # PhrHomeController
