require 'set'
require 'thread'
require 'json'

class FormController < ApplicationController
  include FlowsheetGenerator
  include PhrExporter

  # layout 'form', :progressive => true
  # sliding_session_timeout 30.seconds #sliding_session_timeout 120.minutes
  if REQUIRE_LOGIN_FOR_AJAX
    # Always allow access to get_session_updates (which also retrieves system
    # messages about, e.g., imminent reboots).
    open_methods = [:get_session_updates, :show]
  else
    open_methods =
      [:get_search_res_list, :get_search_res_table, :handle_data_req,
      :get_session_updates, :show]
    # Also turn off CSRF protection for those methods. (Use Case:  RxTerms-- no
    # login, and no user data at risk)
  end

  protect_from_forgery :except=>open_methods
  before_filter :authorize, :except=>open_methods
  before_filter :show_header, :except => open_methods
  #before_filter :set_account_type_flag, :except => open_methods

  # The around filter to enforce that a request be made by an ajax call for
  # methods that expect it. The filter is location in the ApplicationController.
  around_action :xhr_and_exception_filter,
    only: [:archive_profile,
           :delete_profile,
           :delete_profile_permanently,
           :do_ajax_save,
           :get_autosave_data,
           :get_loinc_panel_data,
           :get_loinc_panel_timeline_view,
           :get_obr_datastore,
           :get_one_saved_panel_data,
           :get_prefetched_obx_observations,
           :get_profiles_updatetimes,
           :get_reminder_count,
           :get_reviewed_reminders,
           :get_user_data_list,
           :get_user_data_list_in_table,
           :has_autosave_data,
           :reset_autosave_base,
           :rollback_auto_save_data,
           :unarchive_profile,
           :update_a_reminder,
           :update_reviewed_reminders, ]

  helper :calendar, :combo_fields

  ABBR_MONTHS = {
     'Jan'      => 1, 'Feb'      => 2, 'Mar'      => 3, 'Apr'      => 4,
     'May'      => 5, 'Jun'      => 6, 'Jul'      => 7, 'Aug'      => 8,
     'Sep'      => 9, 'Oct'      =>10, 'Nov'      =>11, 'Dec'      =>12
  }


  # See MySQL documentation on regular expressions.
  MYSQL_ESCAPE = { '\\' =>'\\\\' ,
                   '\.' =>"[[.period.]]" ,
                   '\[' =>"[[.left-square-bracket.]]" ,
                   '\]' => "[[.right-square-bracket.]]" ,
                   " "  => "[[.space.]]" ,
                   '\/' => "[[.slash.]]" ,
                   '\'' => "[[.apostrophe.]]" ,
                   '\(' => "[[.left-parenthesis.]]" ,
                   '\)' => "[[.right-parenthesis.]]" ,
                   '\+' => "[[.plus-sign.]]" ,
                   '%'  => "[[.percent-sign.]]" ,
                   '\{' => "[[.left-brace.]]" ,
                   '\}' => "[[.right-brace.]]" ,
                   "_"  => "[[.underscore.]]"
  }
  EXCEPTION_ERR_MSG_END = "Please contact us using the Feedback page to " +
                          "provide further information.  Thank you."


  # Shows a list of forms
  def index
    @public_forms = Form.where(access_level: 1).order('form_title').to_a;
    @protected_forms = Form.where(access_level: 2).order('form_title').to_a;
    @private_forms = nil
    if (!PUBLIC_SYSTEM)
      @private_forms = Form.where(access_level: 0).order('form_title').to_a;
    end
    render(:layout=>false)
  end


  # Shows an index page for managing a list of saved form records.
  def form_index
    # The form that shows the index is related to the :form_name, and is
    # constructed by the make_index_form_name method.
    params[:form_name] = make_index_form_name(params[:form_name])
    if params[:form_name] == 'admin_index' && !is_admin_user?
      redirect_to("/phr_home")
    else
      # The phr_index form is one of the places we let the user access to
      # switch back to the default page view mode (from the basic HTML mode).
      # Store that preference in the session.
      session[:page_view] = 'default' if params[:form_name] == 'phr_index'
      show
    end

  end


  # Checks to see if unsaved data exists for a specified profile or form for a
  # specified profile.  This does not pass a value for the named_form_only
  # parameter of the AutosaveTmp.have_change_data method.  If that's needed,
  # update this.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  # Parameters:
  # * profile_id the id_shown value for the profile in question
  # * form_name - the name of the form for which we are checking.  If this is
  #   blank, a list of forms with change data will be returned
  #
  # Returns:
  # * a boolean indicating whether or not there is change data for the
  #   specified form - if a form name is specified.  Otherwise
  # * an array that contains the names of the forms for which data exists
  #   if no form name was specified
  #
  def has_autosave_data
    # verify ownership of the profile by the current user
    @access_level, @profile = get_profile("checking to see what autosave data exists",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          params[:profile_id])
    ret = AutosaveTmp.have_change_data(@profile, params[:form_name])
    render :json => ret.to_json
  end


  # Gets the base and changed data hashes from the autosave_tmps table
  # when the form being loaded has recovered data in it.  This requires
  # at least write access, as we don't include any autosave functionality
  # for read-only access.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  # Parameters:
  # * profile_id the id_shown value for the profile in question
  # * form_name - the name of the form for which we need autosave data
  # * get_changes - flag indicating whether or not to return any change
  #   data, or just return the base record
  #
  # Returns:
  # * an array containing the base record data table and, if get_change was
  #   specified as true, the change record
  #
  def get_autosave_data
    # verify ownership of the profile by the current user
    @access_level, @profile = get_profile("getting autosave data",
                                          ProfilesUser::READ_WRITE_ACCESS,
                                          params[:profile_id])
    ret = AutosaveTmp.get_autosave_data_tables(@profile,
                                               params[:form_name],
                                               params[:get_changes])
    status = 200
    begin
      check_for_data_overflow(@profile.owner)
    rescue DataOverflowError
      status = 500
      ret = 'do_logout'
    end
    render :status => status,
           :json => ret.to_json
  end


  # This method stores the form data being sent back in increments
  # from the browser into the autosave_tmps database table.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.   This action requires at least read-write access.
  #
  # Parameters:
  # * profile_id the id_shown value for the profile in question
  # * form_name he name of the form containing the data to be saved
  # * data_table the data_table to be saved.
  #
  # Returns:
  # * a string indicating that things went OK (which only gets sent if
  #   an exception wasn't raised) or a string indicating that the user
  #   should be logged out ('do_logout'), which is sent when the data
  #   stored by the user exceeds our limits, and indicates that the user
  #   should be logged out of the system
  #
  def auto_save
    # verify ownership of the profile by the current user
    @access_level, @profile = get_profile("saving autosave data",
                                          ProfilesUser::READ_WRITE_ACCESS,
                                          params[:profile_id])
    # Access level already confirmed as at least write access
    AutosaveTmp.save_change_rec(@profile,
                                params[:form_name],
                                @access_level,
                                params[:data_tbl])
    status = 200
    ret = 'ok'
    begin
      check_for_data_overflow(@profile.owner)
    rescue DataOverflowError
      status = 500
      ret = 'do_logout'
    end
    render :status => status,
           :json => ret.to_json
  end


  # Rolls back changes that have been made to the current form.  This is called
  # when the user clicks on the "Cancel" button on a form that has autosave
  # data.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.   This action requires at least read-write access.
  #
  # Parameters:
  # * profile_id the id_shown value for the profile in question
  # * form_name the name of the form containing the data to be saved
  # * do_close whether or not the form will be closed after the save
  # This also uses the whoing_unsaved setting from the session object
  #
  # Returns:
  # * nothing (which only gets sent if an exception wasn't raised)
  #
  def rollback_auto_save_data
    # verify ownership of the profile by the current user
    @access_level, @profile = get_profile("rolling back autosave data",
                                          ProfilesUser::READ_WRITE_ACCESS,
                                          params[:profile_id])
    # Access level already confirmed as at least write access
    AutosaveTmp.rollback_autosave_changes(@profile,
                                          params[:form_name],
                                          @access_level,
                                          session[:showing_unsaved],
                                          params[:do_close])
    session[:showing_unsaved] = false
    render(:nothing => true)
  end


  # This method sets/resets the the base autosave record.  This requires
  # at least read-write access.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.   This action requires at least read-write access.
  #
  # Parameters:
  # * profile_id the id_shown value for the profile in question
  # * form_name the name of the form containing the data to be saved
  # * data_tbl the data table to replace the current base record
  # * do_close whether or not the form will be closed after the save
  #
  # * a string indicating that things went OK (which only gets sent if
  #   an exception wasn't raised) or a string indicating that the user
  #   should be logged out ('do_logout'), which is sent when the data
  #   stored by the user exceeds our limits, and indicates that the user
  #   should be logged out of the system
  #
  def reset_autosave_base
    # Verify ownership of the profile by the current user
    @access_level, @profile = get_profile("resetting autosave base data",
                                          ProfilesUser::READ_WRITE_ACCESS,
                                          params[:profile_id])
    # Access level already confirmed as at least write access
    AutosaveTmp.set_autosave_base(@profile,
                                  params[:form_name] ,
                                  @access_level,
                                  params[:data_tbl] ,
                                  params[:do_close] ,
                                  false)
    status = 200
    ret = 'ok'
    begin
      check_for_data_overflow(@profile.owner)
    rescue DataOverflowError
      status = 500
      ret = 'do_logout'
    end
    render :status => status,
           :json => ret.to_json
  end # reset_autosave_base


  # A method for an AJAX call to get updates for a user's session.
  # (At the moment we just use this to get any new urgent system messages, and
  # for that we do not require that the user be logged in.)
  def get_session_updates
    # Check for an urgent system message.
    since = params[:since].to_i;
    notice = SystemNotice.urgent_notice(since)
    update = notice ? {:urgent_notice=>notice} : {}
    render(:text=>update.to_json)
  end


  # Get the last updated timestamps for a list of profiles
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  # Parameters:
  # * profile_id an array of id_shown values for the profiles whose last updated
  #   times are being requeste
  #
  # Returns:
  # * an array of last update times for the specified profiles
  #   (which only gets sent if an exception wasn't raised)
  #
  def get_profiles_updatetimes
    id_shown_array = params[:profile_id]
    timestamps = []
    id_shown_array.each do |id_shown|
      if id_shown
        # Verify ownership and access level of the profile by the current user
        @access_level, @profile = get_profile("getting profile update times",
                                              ProfilesUser.READ_ONLY_ACCESS,
                                              id_shown)
        timestamps << @profile.last_updated_at
      end
    end
    render(:json=>timestamps)
  end


  # Shows a sub form of one profile, such as test panel index page,
  # date_reminders and its setting page, and panel_edit page
  # There's no test panel data involved when the page is initially loaded.
  # The test panel data on the panel_edit page when it is in the 'edit' mode
  # is loaded through an ajax call after the page is loaded.
  #
  # The exception to this is when there is unsaved data for one of the
  # test panel forms.  In that case the unsaved data is loaded into the
  # panel_edit form and the form is displayed with a message.
  #
  def show_sub_form
    id_shown = params[:id]
    sub_form_name = params[:subFormNames]

    if id_shown.nil? || sub_form_name.nil?
      render_html_status_page(404)
    else
      begin
        # Verify ownership of the profile by the current user
        @access_level, @profile = get_profile("getting data for a subform, " +
                                              "name = " + sub_form_name,
                                               ProfilesUser::READ_ONLY_ACCESS,
                                               id_shown)
        profile_id = @profile.id

        case sub_form_name
        # test panel flowsheet
        when 'panels'
          @form_name = "panel_view"
          phr = @profile.phr
          @form_record_id_shown = id_shown
          @form_record_name = phr.pseudonym
        # reminder option page
        when 'reminder_options'
          @form_name = "reminder_options"
          ReminderOption.initialize_options(profile_id)
        # date_reminders page
        when 'reminders'
          @form_name = 'date_reminders'
          # create or update the reminders
          DateReminder.update_reminders(profile_id, @user)
        when 'panel_edit'  # there's loinc_num, maybe a obr_id too
          @form_name = 'panel_edit'
          # panel_taffydb_data = nil
        # other forms
        else
          @form_name = sub_form_name
        end
        @form = Form.where("form_name = ?", @form_name).take
        @form_autosaves = @form.autosaves

        # If the user has unsaved test panel data, set the form name to
        # panel_edit.  It doesn't matter if the user requested the panel_view
        # or panel_edit form - if there are unsaved changes, they're getting
        # the panel_edit form, with a message and the changes highlighted.
        # Unless, of course, the autosaves flag on the form record gets reset.
        # 9/11/14 lm - only do this if the user has at least write access to
        # the profile.  Otherwise no autosave data is displayed.
        if @form_name == 'panel_view' && !profile_id.nil? && @form_autosaves &&
           @access_level < ProfilesUser::READ_ONLY_ACCESS &&
           AutosaveTmp.have_change_data(@profile, @form_name)
          @form_name = 'panel_edit'
          @form = Form.where("form_name = ?", @form_name).take
          @form_autosaves = @form.autosaves
          @diverted_to_panel_edit = true
        end

        taffydb_data, @from_autosave = get_form_taffy_data(profile_id)
        session[:showing_unsaved] = !@recovered_data.nil?
        # add the form_name
        if !taffydb_data.empty?
          taffydb_data << [@form_name, id_shown]
        else
          taffydb_data = [{},{},{},[],[@form_name, id_shown]]
        end

        @form_data = taffydb_data
        render_form(@form_name)
      rescue Exception => e
        flash_msg = 'Error locating this profile.  It could be that the ' +
          'profile does not exist, or that ' + @user.name + ' does not have ' +
          'permission to access this profile, or something else entirely.<br>' +
          'The error has been logged.'
        flash[:notice].nil? ? flash[:notice] = flash_msg :
                              flash[:notice] << '<br>' + flash_msg
        SystemError.record_server_error(e, request, session)
        redirect_to('/phr_home')
      end # begin/rescue
    end # if request is valid
  end # show_sub_form


#  # Shows a single form without user data and without requiring a login.
#  # This can show blank versions of forms that normally have user data
#  # (for testing or system initialization.)
#  def show
#    MOVED to application_controller so that phr_home_controller can access
#    Oct 2013, lm
#  end # def show


  # Handles auto-completion for fields that do not use pre-fetched lists
  # WHAT?  um - possible we could have a bit of a better description here?
  #  this looks pretty specific ...
  def get_clinical_map_text
    # Get the request parameters and the field's text
    route = get_param(:route)
    patient_view = session[:data_view]
    if(patient_view == 1)
      code_vals = ClinicalMap.getTextByLookup(route,true)
    else
      code_vals = ClinicalMap.getTextByLookup(route,false)
    end
    # return (and render the template for this method)
    theList = code_vals[1]
    render(:text=>theList.to_json)
  end


  # Handles search requests for fields whose completion lists are (at request)
  # derived from a search in the database.
  #
  # Parameters:
  # * field_desc_id - the id of the field description record for the field
  # * terms - a string containing the search terms
  # * limit - a limit on the number of results returned
  #
  # Returns:
  # * A JSON version of the return structure from get_matching_field_vals.
  #   (See the documentation for that method.)
  def get_search_res_list(field_desc_id=Integer(get_param(:fd_id)||0),
    terms=get_param(:terms),
    db_id=get_param(:db_id).to_i)

    # This might be a request for a list of suggestions rather that direct
    # search results.  (The suggestion request re-uses this URL).
    if get_param(:suggest)
      get_list_suggestions(field_desc_id, get_param(:field_val))
    else
      #require 'ruby-prof'
      #RubyProf.start
      if (field_desc_id > 0)
        field_desc = FieldDescription.find_by_id(field_desc_id)
        results = get_matching_field_vals(field_desc, terms, get_search_limit)
      else
        db_field_desc = DbFieldDescription.find_by_id(db_id)
        results = get_matching_search_vals(db_field_desc, terms, get_search_limit)
      end
      render(:text=>results.to_json)

      #result = RubyProf.stop
      #printer = RubyProf::GraphPrinter.new(result)
      #printer.print(File.new('log/profile.txt', 'w'), 0)
    end
  end


  # Handles search requests for fields whose completion lists are (at request)
  # derived from a search in the database. Similar as the method named
  # get_search_res_list except that this one uses list description record
  # for generating the completion list.
  #
  # Parameters:
  # * field_desc_id - the id of the field description record for the field
  # * terms - a string containing the search terms
  # * list_id - the id of the list description record describing the completion
  #   list returned
  #
  # Returns:
  # * Same structure as the return from get_matching_field_vals. May also
  #   (See the documentation for that method.)
  def get_search_res_list_by_list_desc(field_desc_id=Integer(get_param(:fd_id)||0),
    terms=get_param(:terms), list_id =get_param(:list_id).to_i)

    # Searches matching results
    list_desc = ListDescription.find_by_id(list_id)
    table_name = list_desc.list_master_table || list_desc.item_master_table
    if !search_allowed?(table_name)
      raise "Search of table #{table_name} not allowed."
    end

    table_class = table_name.singularize.camelize.constantize
    list_name = list_desc.list_identifier
    highlighting = false
    search_cond = list_desc.list_conditions
    search_options = {:limit=>get_search_limit}
    fields_returned = [] # field_desc.fields_returned
    fields_searched = [ list_desc.item_name_field ]
    fields_displayed = fields_searched
    list_item_code_sym = list_desc.item_code_field.to_sym

    if get_param(:suggest) # do fuzzy search
      results = table_class.find_fuzzy_items(nil, terms, search_cond,
        fields_searched, list_item_code_sym, fields_displayed)
    else
      results = table_class.find_storage_by_contents(list_name, terms, search_cond,
        fields_searched, list_item_code_sym,
        fields_returned, fields_displayed,
        highlighting, search_options) << highlighting
    end

    # This might be a request for a list of suggestions rather that direct
    # search results.  (The suggestion request re-uses this URL).
    # Append the headers to the results before sending them to the browser
    field_desc = FieldDescription.find_by_id(field_desc_id)
    headers = field_desc && field_desc.getParam('headers')
    if headers
      @table_headers ? @table_headers : []
      results << headers
    end

    render(:text=>results.to_json)
  end # get_search_res_list_by_list_desc


  # Returns the information needed to display a list of possible corrections
  # for a search field value that did not match its list.
  #
  # Parameters:
  # * field_desc_id - the id of the field description record for the field
  # * field_val - the current value of the search field
  #
  # Returns:
  # * A JSON version of the return structure from the field's search table
  #   class' find_fuzzy_items method.  (See the documentation for that method.)
  def get_list_suggestions(field_desc_id=Integer(get_param(:fd_id)||0),
                           field_val=get_param(:field_val))
    field_desc = FieldDescription.find_by_id(field_desc_id)
    render(:text=>get_suggestions_for_field(field_desc, field_val).to_json)
  end


  # Returns a requested list of items obtainable through the current user's User
  # instance.  This is used for prefetched-list fields whose contents
  # come from user data (e.g. a list of PHRs).
  #
  # This method is invoked through the xhr_and_exception_filter, which will make
  # sure that it was called via an Ajax call and will handle any exceptions
  # thrown, e.g., from get_profile if the user does not have access to the profile
  #
  # Parameters:
  # * field_desc_id - the ID of the field description for the field requesting
  #   the list.  The control_type_detail of the field should contain a
  #   specification of the data for the list.  Three types of supported syntax
  #   are planned (but only the first below is implemented):
  #   1. The search_table parameter in control type detail contains something
  #      like "user phrs".  The presence of "user " is the indicator that
  #      the data is to be obtained from the user table (probably via a call
  #      to this method.)  The "phrs" (or whatever follows the space) is the
  #      name of the top level form table from which the data is to be obtained.
  #      The fields_displayed parameter specifies the column(s) of the table
  #      that are to be used in the list.
  #   2. The search_table parameter contains something like
  #      "user phr(:id) phr_drugs".  In this case the ":id" is intended
  #      to come from the params hash, and specifies the profile number.
  #      the "phr_drugs" indicates that what is requested is data from the
  #      phr_drugs table for the specified phr form record.
  #   3. The search_table parameter contains something like "user phr_drugs",
  #      and the data_req_input parameter contains something like
  #      "{profile_id=>profile_id}" and the implication is that the
  #      phr record id is coming in from the form as part of a handle_data_req
  #      request.
  def get_user_data_list
    fd = FieldDescription.find_by_id(params[:fd_id].to_i)
    p_id = session[:profile_id]
    # Verify ownership of the profile by the current user
    @access_level, @profile = get_profile("getting a list of data for a profile",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          p_id, true)
    @table_recs,@col_names,@code_field=fd.get_user_data_list_info(p_id,@user)
    render(:layout=>false)

  end

  # similar to get_user_data_list except it returns an HTML table representation
  # format of the list content
  #
  # This method is invoked through the xhr_and_exception_filter, which will make
  # sure that it was called via an Ajax call and will handle any exceptions
  # thrown, e.g., from get_profile if the user does not have access to the profile
  def get_user_data_list_in_table

    fd = FieldDescription.find_by_id(params[:fd_id].to_i)
    id_shown = params[:id_shown]
    @col_num = params[:col_num]

    # Verify ownership of the profile by the current user
    @access_level, @profile = get_profile("getting a table of data for a profile",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          id_shown, false)
    @prev_panel_selection = @profile.selected_panels || Set.new
    @table_recs,@col_names,@code_field=fd.get_user_data_list_info(@profile.id,
                                                                  @user)
    render(:layout=>false)
  end

  # This method is called by some of the AJAX autocompleters after the user
  # has selected an item from the list to retrieve additional data.
  # The return value is a JSON formatted hash map from data fields in the
  # fields_data_req control_type_detail parameter to corresponding values.
  # The values may in some cases be arrays.  However, it is expected that
  # the incoming data fully specifies the record for which the data is to
  # be retrieved.
  def handle_data_req

    field_desc_id=get_param(:fd_id).to_i
    field_desc = FieldDescription.find_by_id(field_desc_id)
    # Get the table to be searched, and make sure it is okay to
    # search this table.
    table_name = field_desc.getParam('search_table')
    if !search_allowed?(table_name)
      raise "Search of table #{table_name} not allowed."
    end

    # Construct a hash of data that we know about we are searching for.
    input_fields = {}
    code_val = get_param(:code_val)
    if (code_val)
      input_fields[field_desc.list_code_column] = code_val
    else
      # We don't have a code, so we use the value.
      # Break up the field value into display field values (undo the preparation
      # of the list items).  If our data starts to have dashes in unfortunate
      # places, we'll have to add a means of working around that.  (Perhaps
      # by storing separate data fields along with the list items; but that
      # requires more bandwidth for the AJAX response.)
      field_val = get_param(:field_val)
      fields_displayed = field_desc.getParam('fields_displayed')
      if fields_displayed.size == 1
        field_vals = [field_val]
      else
        field_vals = field_val.split(TABLE_FIELD_JOIN_STR)
      end

      fields_displayed.each_with_index {|f, i| input_fields[f] = field_vals[i]}
    end

    # get the panel serial number if the field is within a panel
    p_sn = get_param(:p_sn)

    # Add data from data_req_input.
    data_req_input = field_desc.getParam('data_req_input')
    if data_req_input
      # modify target field if the field is within a panel
      # for exampel, tp_test_range --> tp1_test_panel
      if (p_sn)
        data_req_input.each {|k, v|
          modified_target_field = v.gsub(/\Atp([0-9]*)_/, 'tp' + p_sn.to_s + '_')
          input_fields[k] = get_param(modified_target_field)
        }
      else
        data_req_input.each {|k, v| input_fields[k] = get_param(v) }
      end
    end

    output_fields = field_desc.data_req_output

    if (table_name.index('user ') == 0)
      # This is a user data table.  The text following the 'user '
      # is the name of the data table.  Go through the @user instance
      # to ensure we get data that should be accessible to this user.
      form_type = table_name[5..-1].singularize
      recs = @user.typed_data_records(form_type, input_fields)
      results = {}
      # Get the values of the output fields for the record found.
      if (recs.size>0)
        output_fields.keys.each {|of| results[of] = recs[0].send(of)}
      end
    else
      tableClass = table_name.singularize.camelize.constantize
      if (table_name == 'answer_lists')
        results = tableClass.find_record_data(input_fields, output_fields.keys,
                                              field_desc.getParam('list_id'))
      else
        results = tableClass.find_record_data(input_fields, output_fields.keys,
                                              field_desc.getParam('list_name'))
      end
    end
    # Now replace the keys in results with the corresponding target field names.
    rtn = {}
    results.each {|k,v|
      form_field_names = output_fields[k]
      form_field_names.each { |ar|
        # modify target field if the field is within a panel
        # for exampel, tp_test_range --> tp1_test_panel
        if (p_sn)
          modified_target_field = ar.gsub(/\Atp([0-9]*)_/, 'tp' +
          p_sn.to_s + '_')
          rtn[modified_target_field] = v
        else
          rtn[ar] = v
        end
      }
    }

    render :text => rtn.to_json
  end # handle_data_req


  # This method is called by some of the AJAX autocompleters after the user
  # has selected an item from the list to retrieve additional data.
  # This method mirrors the handle_data_req method, but it obtains the
  # needed search information from a db_field_descriptions row rather than
  # a field_descriptions row.
  def handle_data_req_for_db_field

    db_field_id=get_param(:db_id).to_i
    db_field = DbFieldDescription.find_by_id(db_field_id)
    # Get the table to be searched, and make sure it is okay to
    # search this table.
    if db_field.list_master_table
      search_table = db_field.list_master_table
    else
      search_table = db_field.item_master_table
    end
    if !search_allowed?(search_table)
      raise "Search of table #{search_table} not allowed."
    end

    # Construct a hash of data that we know about we are searching for.
    input_fields = {}
    code_val = get_param(:code_val)
    if (code_val)
      input_fields[db_field.list_code_column] = code_val
    else
      # We don't have a code, so we use the value.
      # Break up the field value into display field values (undo the preparation
      # of the list items).  If our data starts to have dashes in unfortunate
      # places, we'll have to add a means of working around that.  (Perhaps
      # by storing separate data fields along with the list items; but that
      # requires more bandwidth for the AJAX response.)
      field_val = get_param(:field_val)
      fields_displayed = db_field.fields_saved
      if fields_displayed.size == 1
        field_vals = [field_val]
      else
        if db_field.list_join_string
          field_vals = field_val.split(db_field.list_join_string)
        else
          field_vals = field_val.split(TABLE_FIELD_JOIN_STR)
        end
      end

      fields_displayed.each_with_index {|f, i| input_fields[f] = field_vals[i]}
    end

    # get the panel serial number if the field is within a panel
    p_sn = get_param(:p_sn)


    if false
      # Add data from data_req_input.
      data_req_input = field_desc.getParam('data_req_input')
      if data_req_input
        # modify target field if the field is within a panel
        # for exampel, tp_test_range --> tp1_test_panel
        if (p_sn)
          data_req_input.each {|k, v|
            modified_target_field = v.gsub(/\Atp([0-9]*)_/, 'tp' + p_sn.to_s + '_')
            input_fields[k] = get_param(modified_target_field)
          }
        else
          data_req_input.each {|k, v| input_fields[k] = get_param(v) }
        end
      end
    end # if false

    #output_fields = field_desc.data_req_output
    dep_flds = DbFieldDescription.where(controlling_field_id: db_field_id).to_a
    output_fields = {}
    dep_flds.each do |df|
      value_method = df.current_value_for_field
      if value_method.blank?
        value_method = df.list_values_for_field
      end
      if !value_method.blank?
        output_fields[value_method] = df.data_column
      end
    end
    if output_fields.empty?
      output_fields = nil
    end

    if (search_table.index('user ') == 0)
      # This is a user data table.  The text following the 'user '
      # is the name of the data table.  Go through the @user instance
      # to ensure we get data that should be accessible to this user.
      data_table = search_table[5..-1]
      recs = @user.typed_data_records(data_table, input_fields)
      results = {}
      # Get the values of the output fields for the record found.
      if (recs.size>0)
        output_fields.keys.each {|of| results[of] = recs[0].send(of)}
      end
    else
      tableClass = search_table.singularize.camelize.constantize
      results = tableClass.find_record_data(input_fields, output_fields.keys,
                                            db_field.list_identifier)
    end
    # Now replace the keys in results with the corresponding target field names.
    rtn = {}

    results.each {|k,v|
      form_field_names = output_fields[k]
      form_field_names = [form_field_names] if form_field_names.is_a? String
      form_field_names.each { |ar|
        # modify target field if the field is within a panel
        # for example, tp_test_range --> tp1_test_panel
        if (p_sn)
          modified_target_field = ar.gsub(/\Atp([0-9]*)_/, 'tp' +
          p_sn.to_s + '_')
          rtn[modified_target_field] = v
        else
          rtn[ar] = v
        end
      }
    }
    render :text => rtn.to_json
  end # handle_data_req_for_db_field



  # Returns the data a javascript ComboField needs to switch to a new field
  # input method (plain text or some form of a list).
  #
  # Parameters obtained from the params hashmap:
  # * db_id - the id of the db_fields_description row for which a field is to
  #   be mimicked/created
  # * ff_id - the id (including prefix and suffix) of the form field
  #   that is to mimic a particular field type
  # * form_name - the name of the form that the form_field is on
  # * orig_ff_id - the id (NOT including prefix and suffix) of the form field
  #   being mimicked
  #
  # Returns: a JSON string of an array containing the following elements in
  #  the following order:
  #  1. field type - which is expressed using one of the constants defined in
  #     the combo_fields_helper and that correspond to those used by the
  #     javascript ComboField object.  This element is required.
  #
  #  2. tooltip - if a tooltip is specified for the field, the text of it
  #     will be placed here.  If no tooltip was specified, this will contain
  #     an empty string (but not nil).
  #
  #  3. a hash of parameters used to construct a RecordDataRequester.  If the
  #     field to be mimicked is not a list field, this element will not exist.
  #     If the field to be mimicked does not specify a RecordDataRequester,
  #     this element will be in the array, but will carry a null value.
  #
  #  4. a hash of parameters used to create the autocompleter for a list field.
  #     If the field to be mimicked is not a list field, this element will not
  #     exist.  Otherwise (since a list field is currently our only other
  #     option) this element will carry the hash of parameters.
  #
  #  5. an array of parameters needed to update existing autocompleters or
  #     fields that are dependent on other field values for their values.
  #
  #  This request is actually passed through to the get_combo_field_specs method
  #  in the combo_fields_helper.  The parameter hashes returned are the same
  #  hashes used to create the javascript for the autocompleters and
  #  record data requester objects when creating the fields normally.  See the
  #  get_combo_field_specs method in combo_fields_helper for details.
  #
  def handle_combo_field_change
    render :inline => '<%= get_combo_field_specs(params[:db_id],
                                                 params[:ff_id],
                                                 params[:form_name],
                                                 params[:orig_ff_id],
                                                 params[:in_table])%>'
  end # handle_combo_field_change


  # Returns search results for a search for given terms within a specified
  # table's column, using Ferret.  This method is public so that it can be
  # tested, but it is not intended to be called directly as a controller
  # action.  It is thought that it should be safe, because the method
  # requires parameters that cannot be specified in an URL.  This could be
  # moved into the has_searchable_list.rb class, and defined on the models
  # just like find_storage_by_contents.
  #
  # This method obtains search parameters from a db_field_descriptions object.
  # See get_matching_field_vals for the version that gets the parameters
  # from a field_descriptions object.
  #
  # Parameters:
  # * db_field_desc - the db_field_description record for the field
  # * terms - a string containing the search terms
  # * limit - a limit on the number of results returned
  #
  # Returns:
  # The total count available, an array of codes for the returned records,
  # a hash map (described below), an array of record data (each of which
  # is an array whose elements are
  # the values of the fields specified in the field_displayed parameter),
  # and (finally) a boolean indicating whether or not the array of record data
  # has HTML tags around the matched parts of the strings.
  # The hash map is from fields_returned elements to corresponding lists of
  # field values.  This structure was chosen to
  # minimize the size of the JSON version of the return data, because
  # the returned fields data gets included in the output sent back to
  # the web browser.  If highlighting is turned on, :display values will have
  # <span> tags around the terms that matched the query.
  #
  def get_matching_search_vals(db_field_desc, terms, limit)
    if db_field_desc.list_master_table.blank?
      table_name = db_field_desc.item_master_table
    else
      table_name = db_field_desc.list_master_table
    end
    if !search_allowed?(table_name)
      raise "Search of table #{table_name} not allowed."
    end

    table_class = table_name.singularize.camelize.constantize

    list_name = db_field_desc.list_identifier
    # NOT CURRENTLY USING THE HIGHLIGHTING FEATURE.  WILL NEED TO ADD
    # BACK IN IF THE FEATURE IS RESTORED.   lm, 9/2009
    highlighting = false

    search_cond = db_field_desc.list_conditions

    search_options = {:limit=>limit}
    # NOT CURRENTLY SPECIFYING ORDER FOR THESE, ALTHOUGH THIS CAPABILITY
    # SHOULD BE RESTORED ANY DAY NOW.  9/23/09 LM
    #order = field_desc.getParam('order')
    #search_options[:sort] = order if order

    # NOT CURRENTLY USING THIS, but is included below, so set to empty array
    fields_returned = [] # field_desc.fields_returned

    # We need to specify which fields to search and which to get back
    # with the search results.  The db_field_descriptions don't provide that
    # information, so just use fields_saved.  That means fields_searched won't
    # include synonym fields (if there are any), so this might not be ideal.
    fields_searched = db_field_desc.fields_saved
    fields_displayed = db_field_desc.fields_saved

    # Return the result of find_storage_by_contents, plus the "highlighting"
    # variable.
    table_class.find_storage_by_contents(list_name, terms, search_cond,
                                        fields_searched, db_field_desc.list_code_column.to_sym,
                                        fields_returned, fields_displayed,
                                        highlighting, search_options) << highlighting
  end # get_matching_search_vals


  # Retrieve mplus drug relationships for a selected drug
  #
  # Parameters:
  # * drug_name - the selected drug
  #
  # Returns:
  # An array of length 2 arrays.  Each entry is URL and page title for an
  # MplusDrug page related to drugs that meet query constraints.
  # Returns array size zero if no matches meet query conditions.
  #
  def mplus_drug_links_for
    drug_name = get_param(:drugName)
    drug = DrugNameRoute.where("text = ?", drug_name).take
    mplus_drugs = drug ? drug.info_link_data : []
    # render the output array as json text
    render(:text=>mplus_drugs.to_json)
  end


  # Retrieve mplus health topic relationships for a named medical problem or
  # problem code (the key_id in gopher_terms).
  # It is expected that the paramter map will contain either "problem_code"
  # or "problem_name".
  #
  # Returns:
  # An array of length 2 arrays.
  # Each entry is URL and page title for a Mplus health topic page related to the named medical problem.
  # Returns array size zero if no matches meet query conditions.
  def mplus_health_topic_links
    mplus_topics = GopherTerm.info_link_data(get_param(:problem_code),
      get_param(:problem_name))
    # render the output array as json text
    render(:text=>mplus_topics.to_json)
  end


  # Editing an existing profile using a form - specifically either the
  # phr form or the phr_home (registration data only) form
  def edit_profile_with_form
    begin # block that will be "rescued"
      #RubyProf.start  # Periodically we profile this, so I've left it here
      #so I don't forget how.
      id_shown = params[:id]
      # Verify ownership of the profile by the current user
      @access_level, @profile = get_profile("getting data for editing",
                                            ProfilesUser::READ_ONLY_ACCESS,
                                            id_shown)
      if !params[:render_to].nil?
        render_to = params[:render_to]
      else
        render_to = 'form'
      end
      @form_name = params[:form_name]
      @form = Form.where("form_name = ?", @form_name).take
#      fd = FormData.new(@form)
      @edit_action = true

      # Set the action URL to be the current URL.  (This will give
      # handle_post the current URL so it can determine the next action.)
      if !request.url.nil?
        @action_url = request.url
      end

      taffydb_data, @from_autosave = get_form_taffy_data(@profile.id)
      session[:showing_unsaved] = !@recovered_data.nil?
      # add the form_name
      if !taffydb_data.empty?
        taffydb_data << [@form_name, id_shown]
      end
      @form_data = taffydb_data
      @form_autosaves = @form.autosaves

      # If this was called via an ajax call, set the autosave base value
      # if we have no recovered data and the form uses autosave.
      # Then check for a data overflow error in case resetting the base
      # causes us to overflow the data limit.  If this was not called via
      # an ajax call, this will be taken care of in the ApplicationController's
      # render_form method.  This is only called if the user has at least
      # write access to the profile.  If the user only has read access, no
      # autosave data will have been retrieved.
      if render_to == 'json'
        status = 200
        if @recovered_data.nil? && @form.autosaves &&
           @access_level < READ_ONLY_ACCESS
          AutosaveTmp.set_autosave_base(@profile,
                                        @form_name ,
                                        @access_level,
                                        taffydb_data[0].to_json ,
                                        false ,
                                        false )
          begin
            check_for_data_overflow(@profile.owner)
          rescue DataOverflowError
            status = 500
            ret = 'do_logout'
          end
        end
        if status != 500
          ret = @form_data
        end
        render :status => status ,
               :json=>ret.to_json

      # Else this was not invoked via an ajax call.  The render_form
      # method in the application controller will take care of that
      # autosave stuff and overflow checking.
      else
        render_form(@form_name)
      end

    rescue Exception => e
      flash_msg = 'Error locating this profile.  It could be that the ' +
        'profile does not exist, or that ' + @user.name + ' does not have ' +
        'permission to access this profile, or something else entirely.<br>' +
        'The error has been logged.'
      flash[:notice].nil? ? flash[:notice] = flash_msg :
                            flash[:notice] << '<br>' + flash_msg
      SystemError.record_server_error(e, request, session)
      redirect_to('/phr_home')
    end # rescue
  end # edit_profile_with_form


  # Gets the data from the data model for a form to be displayed.
  # This code was duplicated in edit_profile_with_form and get_loinc_panel_data,
  # so it was pulled out into its own method.
  #
  # Parameters:
  # * profile_id - the profile id
  # also reads instance variable @form
  # Returns
  # * taffydb_data
  # also sets instance variables @recovered_data and prefetched_obx_observations
  #
  def get_form_taffy_data(profile_id)
    fd = FormData.new(@form)

    # add data for taffy db
    # note: basically a second copy of the data are added. In the future, it
    # should use only one copy of the data and probably the data_hash should be
    # nixed.
    non_panel_taffydb_data, @recovered_data, from_autosave, err_msg, except =
                                 fd.get_taffy_db_data(profile_id, @access_level)
    if !@form.has_panel_data
      taffydb_data = non_panel_taffydb_data
    else
      # Load embedded Loinc Test Panels
      pd = PanelData.new(@user)

      # If the data came from the autosave_tmps table, it includes test panel
      # data.  If it didn't come from the autosave_tmps table, there is no
      # test panel data.  The get_panel_group_taffydb_data method will get the
      # test panel data only if it's not already there.
      if !from_autosave
        test_data_table = nil
      else
        test_data_table = non_panel_taffydb_data[0]
        # if a test has an answer list, and the user typed value was autosaved,
        # the list is removed from the data_table during the merging of the
        # autoaved data.
        # the answer lists are in the base records, but not in the incremental
        # saves. hence the value is replaced with the value in the incremental
        # saves. the auto save code does not check the content of the data
        # so here we add the list back into the data_table if there's missing
        # lists.
        # Note: the addtional processing time is about 0.04s for a test panel
        # with 7 tests
        pd.reset_answer_lists(test_data_table)

      end

      panel_taffydb_data = pd.get_panel_group_taffydb_data(@form,
                                                           profile_id,
                                                           test_data_table)
      if panel_taffydb_data.empty?
        taffydb_data = non_panel_taffydb_data
      else
        # Since no obx_observation data was loaded into the taffy_db's
        # obx_observations table, client side fetching will return nothing,
        # even if there is some qualified data on the server side.  To fix
        # this problem, we need to pre-run related fetch rules on the server
        # side and load the results into the taffy_db on the client side .
        # This ensures that the client side fetching will return the expected
        # obx_observation data if there is any.
        if test_data_hash = panel_taffydb_data[0]
          @prefetched_obx_observations =
            Rule.prefetched_obx_observations(profile_id)
          test_data_hash[PanelData::OBX_TABLE+'_prefetched'] =
            @prefetched_obx_observations.values
        end

        #re-organize table_2_group, from hash to array
        # if this next line bombs, it's usually because something's wrong
        # with what came back for the data table from the
        # fd.get_taffy_db_data call.  Check to see if the data table
        # returned was {}.
        obr_mapping = panel_taffydb_data[3][OBR_TABLE].map
        obx_mapping = panel_taffydb_data[3][OBX_TABLE].map
        panel_taffydb_data[3]=[[OBR_TABLE, obr_mapping],[OBX_TABLE, obx_mapping]]

        # Merge the test panels' taffy db data with the other data.
        # Table names should be different, which means other fields on the form
        # cannot use obr/obx tables for storage.

        if !non_panel_taffydb_data.empty?
          taffydb_data = Array.new
          # data table
          if !from_autosave
            taffydb_data << non_panel_taffydb_data[0].merge(panel_taffydb_data[0])
          else
            taffydb_data << non_panel_taffydb_data[0]
          end
          # mapping
          taffydb_data << non_panel_taffydb_data[1].merge(panel_taffydb_data[1])
          # model table
          taffydb_data << non_panel_taffydb_data[2].merge(panel_taffydb_data[2])
          # table_2_group_mapping
          taffydb_data << non_panel_taffydb_data[3].concat(panel_taffydb_data[3])
        else
          taffydb_data = panel_taffydb_data
        end
      end # if we don't/do have panel data
    end # if this form doesn't use panel data
    if !err_msg.nil?
      flash.now[:notice].nil? ? flash.now[:notice] = err_msg :
                                flash.now[:notice] << '<br>' + err_msg
      SystemError.record_server_error(except, request, session)
    end
    return taffydb_data, from_autosave
  end # get_form_taffy_data


  # Returns a hash map containing all the latest fetch rule values of the
  # obx_observations table.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def get_prefetched_obx_observations
 
    # Verify ownership of the profile by the current user
    @access_level, @profile = get_profile("getting prefetched obx observations",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          params[:profile_id])

    # get rules which are using the fetch rules of table obx_observations
    pref_obxs =  Rule.prefetched_obx_observations(@profile.id)
    rule_list = Rule.where(name: pref_obxs.keys).to_a
    complete_rules = Rule.complete_rule_list(rule_list, "used_by_rules")
    render :json => [pref_obxs, complete_rules.map(&:name)].to_json
  end


  # Update a reminder record, ajax call from the date_reminders page
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def update_a_reminder
    # Verify ownership of the profile by the current user
    @access_level, @profile = get_profile("updating a reminder",
                                          ProfilesUser::READ_WRITE_ACCESS,
                                          params[:profile_id])

    data_table_str = params[:data_table]
    data_table = JSON.parse(data_table_str)

    form_name = params[:form_name]

    # save form data
    form = Form.where("form_name = ?", form_name).take
    if !form.nil?
      fd = FormData.new(form_name)
      updated_form_records, data_table = fd.save_data_to_db(data_table,
                                                            @profile.id,
                                                            @user)
    end
    # return feedback
    render(:json => updated_form_records.to_json)
  end


  # Save the form data by an ajax call, for phr only for now - nope - used
  # by registration create and update also.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def do_ajax_save

    # feedback to return
    feedback = {'data' => {'added'=>[], 'deleted'=>[], 'updated'=>[], 'empty'=>[], 'to_remove'=>[] },
                'errors' => [],
                'exception' => nil }
    profile_id = nil
    id_shown = params[:profile_id]
    data_table_str = nil
    data_table_str = params[:data_table]
    data_table = JSON.parse(data_table_str)
    message_map_str = params[:message_map]
    message_map = message_map_str && JSON.parse(message_map_str)
    # create a new profile (in profile registration only)
    if id_shown.blank?
      # pseudonym should not be empty if profile_id is empty
      if (has_pseudonym?(data_table))
        @profile = Profile.create!
        @user.profiles << @profile
        profile_id = @profile.id
        id_shown = @profile.id_shown
        @access_level = ProfilesUser::OWNER_ACCESS
      # deny the access/save. the request might be from a test page (!?)
      # such as /form/test/phr
      else
        msg = 'We are unable to process a save request without a profile ' +
              'id and registration info.'
        logger.debug msg
        feedback["errors"] << msg
        # this should skip all save code and return an error
      end
    # get the profile
    else
      # Verify ownership of the profile by the current user.  If the current
      # user does not have at least write access, an error will be raised
      @access_level, @profile = get_profile("save via ajax call",
                                            ProfilesUser::READ_WRITE_ACCESS,
                                            id_shown)
      profile_id = @profile.id
    end

      # if a valid profile is found or created.
    if profile_id 
      HealthReminder.update_reminders_for_profile(@profile.id_shown,
                                                  message_map,
                                                  Time.now) if message_map
      form_name = params[:form_name]
      do_close = params[:no_close] != true
      if do_close
        action_url = params[:act_url]
        action_condition_str = params[:act_condition]
        action_condition = JSON.parse(action_condition_str)
      end

      saved = false

      # save form data
      form = Form.where("form_name = ?", form_name).take
      if !form.nil?
        fd = FormData.new(form)
        updated_form_records, data_table = fd.save_data_to_db(data_table,
                                                              profile_id,
                                                              @user)

        feedback['data']['added'] += updated_form_records['data']['added']
        feedback['data']['deleted'] += updated_form_records['data']['deleted']
        feedback['data']['updated'] += updated_form_records['data']['updated']
        feedback['data']['empty'] += updated_form_records['data']['empty']
        feedback['data']['to_remove'] += updated_form_records['data']['to_remove']
        feedback['errors'] += updated_form_records['errors']
        feedback['exception'] = updated_form_records['exception']

        saved = !updated_form_records['exception'] &&
                updated_form_records['errors'].empty?
        # save panel data only if other form data is saved
        if saved &&
            (data_table.keys.include?('obx_observations') ||
             data_table.keys.include?('obr_orders'))
          # if there is no test panel data this should
          # just come back as not having saved anything.
          pd = PanelData.new(@user)
          updated_panel_records, data_table = pd.save_data_to_db(data_table,
                                                                 profile_id,
                                                                 @user)

          feedback['data']['added'] += updated_panel_records['data']['added']
          feedback['data']['deleted'] += updated_panel_records['data']['deleted']
          feedback['data']['updated'] += updated_panel_records['data']['updated']
          feedback['data']['empty'] += updated_panel_records['data']['empty']
          feedback['data']['to_remove'] += updated_panel_records['data']['to_remove']
          feedback['errors'] += updated_panel_records['errors']
          feedback['exception'] = updated_panel_records['exception']

          saved = !updated_panel_records['exception'] &&
                  updated_panel_records['errors'].empty?
        end # if no exception so far and have test panel data
      end  # !form.nil?

      # if all the data is saved
      if saved
        # create or update the reminders
        DateReminder.update_reminders(profile_id, @user)

        # Reset the base autosave record with the updated
        # data_table returned by the call(s) to save_data_to_db.
        # The write/owner access check is not performed here because
        # we wouldn't have gotten this far if we didn't have it.
        if form.autosaves
          AutosaveTmp.set_autosave_base(@profile,
                                        form_name ,
                                        @access_level,
                                        data_table.to_json ,
                                        do_close ,
                                        false)
          session[:showing_unsaved] = false
        end
        # check user data limit
        begin
          check_for_data_overflow(@profile.owner)
        rescue DataOverflowError => ovError
          feedback['do_logout'] = true
          feedback['exception'] = 1
          feedback['exception_type'] = 'data_overflow'
          feedback['exception_msg'] = ovError.message
          flash.keep[:error] = flash.now[:error]
        rescue Exception => other_error
          SystemError.record_server_error(other_error, request, session)
          feedback['exception'] = 1
        end
        # find the next url
        if (do_close)
          action = ActionParam.get_action(action_url, id_shown, action_condition)
          if !action.nil?
            next_url = action.get_next_page_url(id_shown)
          else
            next_url = nil
          end
          feedback['target'] = next_url
        end

        if form
          @unique_values_by_field = ServersideValidator.unique_values_by_field(
              form.id, session[:user_id]) if session[:user_id]
          feedback['unique'] = @unique_values_by_field.to_json.html_safe
        end

      end  # if saved
    end # if the profile is valid

    if feedback['exception'] || !feedback['errors'].empty?
      render :status => 500,
             :json => feedback.to_json
    else
      render(:json => feedback.to_json)
    end
  end # do_ajax_save


  # Return the total number of unread health reminders and unhidden due date
  # reminders.
  # #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def get_reminder_count
    # Verify ownership of the profile by the current user
    @access_level, @profile = get_profile("get reminder count",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          get_param(:p_id))
    duedate_cnt = DateReminder.get_reminder_count(@profile.id)
    # for now, the health reminders are generated on the client side
    health_cnt = 0
    render :json => [health_cnt, duedate_cnt]
  end


  # New function for LOINC Panels, to display a dynamically created Test Panel
  # group.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def get_loinc_panel_data
    # get the name of the current form
    form_name = get_param(:form_name)
    form = Form.where("form_name = ?", form_name).take
    # get panel sequence num, to be part of the id
    if get_param(:p_seqno).blank?
      p_seqno = 1
    else
      p_seqno = get_param(:p_seqno).to_i
    end
    # get the number of existing panels already displayed in the new panel
    # section
    if get_param(:p_skip).blank?
      existing_panel_num = 0
    else
       existing_panel_num = get_param(:p_skip).to_i
    end
    # get existing obr/obx record num
    if get_param(:obr_index).blank?
      obr_index = 0
    else
      obr_index = get_param(:obr_index).to_i
    end
    if get_param(:obx_index).blank?
      obx_index = 0
    else
      obx_index = get_param(:obx_index).to_i
    end
    # get suffix_prefix of the field's id
    if get_param(:suffix_prefix).blank?
      suffix_prefix = ''
    else
      suffix_prefix = get_param(:suffix_prefix)
    end
    # get obr_id if there's one
    if !get_param(:obr_id).blank?
      obr_record_id = get_param(:obr_id)
    end

    not_found = false
    # get a LOINC number
    if !get_param(:p_num).blank?
      loinc_num=get_param(:p_num)
      # Verify ownership of the profile by the current user
      @access_level, @profile = get_profile("get test panel data",
                                            ProfilesUser::READ_ONLY_ACCESS,
                                            params[:p_form_rec_id])
      profile_id = @profile.id
      loinc_item = LoincItem.where("loinc_num = ?", loinc_num).take
      if loinc_item.nil?
        not_found = true
      else
        # it is a panel item
        if loinc_item.is_panel? && loinc_item.has_top_level_panel?
          loinc_panel = LoincPanel.where("loinc_num = ?", loinc_num).
                                   where("id=p_id").take
          if loinc_panel.nil?
            not_found = true
          else
            pd = PanelData.new(@user)
            # get the taffy db data for the panel
            one_panel_taffy_db_data, obr_index, obx_index =
                pd.get_one_panel_taffy_db_data(loinc_panel, obr_index,
                obx_index, p_seqno, existing_panel_num,suffix_prefix,
                profile_id, obr_record_id, false)
          end
        # it is a single test
        elsif loinc_item.is_test?
          pd = PanelData.new(@user)
          # get the taffy db data for the single test
          one_panel_taffy_db_data, obr_index, obx_index =
              pd.get_one_panel_taffy_db_data(loinc_item, obr_index,
              obx_index, p_seqno, existing_panel_num,suffix_prefix,
              profile_id, obr_record_id, true)
        # it is a sub panel?
        elsif loinc_item.is_panel?
          not_found = true
        end
      end
    # no LOINC number provided
    else
      not_found = true
    end

    if not_found
      render(:nothing=>true, :status=>404)
    else
      # return the panel data hash as a JSON object
      # re-organize the table_to_group mapping, from hash to array
      if !one_panel_taffy_db_data.empty?
        obr_mapping = one_panel_taffy_db_data[3][OBR_TABLE].map
        obx_mapping = one_panel_taffy_db_data[3][OBX_TABLE].map
        one_panel_taffy_db_data[3]=[[OBR_TABLE, obr_mapping],
                                    [OBX_TABLE, obx_mapping] ]
      end
      status = 200
      ret = one_panel_taffy_db_data.to_json

      # Set/add the contents of the data table to the autosave tmp record
      # - IF the user has at least write access to the data.  Users that
      # only have read access don't see or have anything to do with
      # autosave data.
      if form.autosaves && @access_level < ProfilesUser::READ_ONLY_ACCESS
        AutosaveTmp.set_autosave_base(@profile,
                                      form_name,
                                      @access_level,
                                      one_panel_taffy_db_data[0].to_json,
                                      false ,
                                      true)
        begin
          check_for_data_overflow(@profile.owner)
        rescue DataOverflowError
          status = 500
          ret = 'do_logout'
        end
      end # if this form autosaves

      render :status => status,
             :text => ret

    end # if data was found for the specified loinc value
  end # get_loinc_panel_data


  # get panel info for panel tree structure
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def get_obr_datastore
    # Verify ownership of the profile by the current user
    @access_level, @profile = get_profile("get obr panel data",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          get_param[:id])
    profile_id = @profile.id

    panel_data= PanelData.new(@user)
    data_store = panel_data.get_data_store(profile_id)
    render(:json=>data_store.to_json)
  end


  # get the html text of the saved test panels' timeline view
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def get_loinc_panel_timeline_view
 
    # Verify ownership of the profile by the current user
    @access_level, @profile = get_profile("get panel timeline view",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          get_param(:id))

    loinc_nums = get_param(:l_nums)
    # keep the loinc_nums in profile table
    loinc_nums = Set.new(loinc_nums.split(','))
    save_pref = get_param(:sf)=='true'
    # calls from the flowsheet page need to save the preference
    if save_pref
      @profile.selected_panels = loinc_nums
      @profile.save!
    end

    in_one_grid = get_param(:in_one) == 'true'
    include_all = get_param(:all) == 'true'
    start_date = get_param(:sd)
    end_date = get_param(:ed)
    end_date_str = get_param(:eds)
    group_by_code = get_param(:gbc)
    date_range_code = get_param(:drc)

    timeline_html, panel_info = flowsheet_html_and_js(@profile, loinc_nums,
        in_one_grid, include_all, group_by_code, date_range_code, start_date,
        end_date, end_date_str)
    ret_value = timeline_html + "<@SP@>" + panel_info.to_json
    render(:text => ret_value)
  end


  # get a obr records and associated obx records
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def get_one_saved_panel_data
    obr_id = get_param(:obr_id)
    # Verify ownership of profile by the current user
    @access_level, @profile = get_profile("get data for one saved panel",
                                          ProfilesUser::READ_ONLY_ACCESS,
                                          get_param(:id))
    profile_id = @profile.id

    panel_data= PanelData.new(@user)

    data_table = panel_data.get_one_saved_panel_data(profile_id, obr_id)
    render(:json=>data_table.to_json)
  end


# This just isn't used anymore.  9/9/14 lm
#  # export a profile, from a "post"
#  def export_profile
#
#    if request.post?
#      map = params[:fe]
#      form_name = params[:form_name]
#      phrindex_form = Form.where("form_name = ?", form_name + "_index").take
#      data_hash = data_hash_from_params(map, phrindex_form)
#      file_option = data_hash['saved_phrs']['file_option']
#      file_format = file_option['file_format_C']
#      # passwords are not needed any more.
#      id_shown = data_hash['saved_phrs']['record_name_C']
#      if id_shown.nil? || file_format.nil? ||
#         file_format != '1' && file_format != '2' && file_format != '3'
#        # TBD -- we need an error message here...
#        redirect_to('/phr_home')
#        return
#      end
#
#      profile = get_profile("export a profile", id_shown)
#      handle_export_request(profile, file_format)
#    end # if this is a post request
#  end # export_profile


  # The handler method for archiving a profile.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def archive_profile
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating the phr to " +
                               "make inactive.  " + EXCEPTION_ERR_MSG_END
    id_shown = params[:profile_id]
    # Verify ownership of the profile by the current user
    # This will raise an exception if the id_shown is missing
    @access_level, @profile = get_profile("archive a profile",
                                           ProfilesUser::OWNER_ACCESS,
                                           id_shown)
    @profile.archived = true
    @profile.save!
    render(:nothing=>true, :status=>200)
  end # archive_profile


  # The handler method for unarchiving a profile
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def unarchive_profile
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating the phr to " +
                               "restore.  " + EXCEPTION_ERR_MSG_END
    id_shown = params[:profile_id]
    # Verify ownership of the profile by the current user
    # This will raise an exception if the id_shown is missing
    @access_level, @profile = get_profile("unarchive a profile",
                                          ProfilesUser::OWNER_ACCESS,
                                          id_shown)
    @profile.archived = false
    @profile.save!
    render(:nothing=>true, :status=>200)
  end # unarchive_profile


  # The handler method for performing a "SOFT DELETE" of a profile.  This
  # archives associated records but doesn't actually delete them.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def delete_profile
    # Set the error message in case something is thrown from the call to the
    # user object. The message will be displayed by the xhr_and_exception filter.
    @exception_error_message = "There was an error locating the phr to " +
                               "delete.  " + EXCEPTION_ERR_MSG_END
    id_shown = params[:profile_id]
    # Verify ownership of the profile by the current user
    # This will raise an exception if the id_shown is missing
    @access_level, @profile = get_profile("soft delete a profile",
                                          ProfilesUser::OWNER_ACCESS,
                                          id_shown)
    @profile.soft_delete
    render :status => status , :json => "OK".to_json
  end # delete_profile
  

  # The handler method for performing a "HARD DELETE" of a profile.  This
  # actually deletes the profile and associated records.
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def delete_profile_permanently
    id_shown = params[:profile_id]
    if id_shown
      # Verify ownership of the profile by the current user
      @access_level, @profile = get_profile("hard delete a profile",
                                            ProfilesUser::OWNER_ACCESS,
                                            id_shown)

      condition = {}
      condition[:profile_id] = @profile.id

      DbTableDescription.all.each { |tab|
        condition[:latest] = 'All'
        form_type = tab.data_table
        typed_data_records = @user.typed_data_records(form_type,condition)
        typed_data_records.each { |rec|
          rec.delete
        }
      }
      pu = ProfilesUser.where(profile_id: @profile.id).to_a
      pu.each do |p|
       p.destroy
      end
      @profile.delete
      render(:nothing=>true, :status=>200)
    else
      render(:nothing=>true, :status=>404)
    end
  end


  # Refresh the reviewed_reminders table with the latest complete list reviewed
  # reminders
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def update_reviewed_reminders
    id_shown = params[:profile_id]
    if id_shown
      # Verify ownership of the profile by the current user
      @access_level, @profile = get_profile("update the reviewed reminders",
                                            ProfilesUser::READ_ONLY_ACCESS,
                                            id_shown)
      reviewed_reminders = JSON.parse(params[:reviewed_reminders])
      ReviewedReminder.update_records(@user, @profile, reviewed_reminders)
      render(:nothing=>true, :status=>200)
    else
      render(:nothing=>true, :status=>404)
    end
  end


  # Returns the list of reviewed reminders per profile id
  #
  # The xhr_and_exception_filter "around" action is used to make sure this
  # was invoked via an ajax call AND to handle any exceptions thrown - which
  # will happen if the user does not have the correct access level to the
  # profile specified.
  #
  def get_reviewed_reminders
    id_shown = params[:profile_id]
    if id_shown
      # Verify ownership of the profile by the current user
      @access_level, @profile = get_profile('get a list of reviewed reminders',
                                            ProfilesUser::READ_ONLY_ACCESS,
                                            id_shown)
      reviewed_reminders = ReviewedReminder.filter_by_user_and_profile(@user.id,
                                                                       id_shown)
      render(:json => reviewed_reminders.to_json)
    else
      render(:nothing=>true, :status=>404)
    end
  end



  private ###########################  Private Methods ###################


  # Check if pseudonym has value in the phrs table in the data_table
  # Parameters:
  # * data_table - the data table from the client
  # Returns:
  # True/False
  def has_pseudonym?(data_table)
    ret = false
    if data_table && data_table['phrs'] && data_table['phrs'][0]['pseudonym'] &&
        data_table['phrs'][0]['pseudonym'].strip.length > 0
      ret = true
    end
    return ret
  end


  # Creates an autocompletion pattern for an SQL REGEXP search from the
  # text input by the user.
  # Parameters:
  # * input_text - the text in the autocompletion input field
  def make_autocomp_pattern(input_text)
    # escape special characters in the user entered value
    # Examine each user entered character separately to avoid multi-escaping escape characters.
    escaped_field_text = ""
    input_text.scan(/./) do |aChar|
      result = MYSQL_ESCAPE[Regexp.escape(aChar)];
      if ( result.nil? )
        result = aChar
      end
      escaped_field_text << result
    end

    # Construct an SQL regex pattern for matching the list items
    if( !escaped_field_text.index("-square-bracket").nil? )
      escaped_field_text
    else
       '[[:<:]]' + escaped_field_text # match at the beginning of a word
    end
  end


  # Given a resource name (in the REST sense, e.g. a 'phrs' to indicate a
  # collection of PHR forms), creates the name of its associated index form.
  def make_index_form_name(resource_name)
    return resource_name + '_index'
  end

  # Returns the number of search results to return in response to
  # an AJAX search request.
  def get_search_limit
    limit = get_param(:limit)
    limit = limit.to_i if limit
    if (limit.nil? || limit==0)
      if (!get_param(:autocomp).nil?)
        limit = MAX_AUTO_COMPLETION_SIZE
      else
        limit = MAX_SEARCH_RESULTS
      end
    end

    return limit
  end

# COMMENTED OUT 2/23/11, lm.  I don't think we're using this, and so am not
# updating it for changes related to autosave data.  If this hasn't blown up
# by 4/9/11, I will delete it.
#  # The handler method for saving a new form record.  After creating the new
#  # record, it puts the id_shown into params[:id], so that the handle_post
#  # method can use it.  (This is SOP for our post handlers).
#  def save_new
#    # Create the entry in UsersFormRecords
#    form_name = params[:form_name]
#    fr = Profile.create!
#    @user.profiles << fr
#
#    # Put the id_shown of the form record into the params map, and call save.
#    params[:id] = fr.id_shown
#    save(fr.id) # give the save method the ID so it doesn't need to find it.
#  end


  # Generates Date String from HL7 date format.
  # Parameter:
  # value date in CCYYMMDD format (HL7)
  #  Return : Date in NNN d,y format. eg.Jan 2,2001
  def getDateFromHL7(value)
    if value.nil? || value == ""
      return  ''
    end
    if (value.length == 8)
      value.insert(4,'/')
      value.insert(7,'/')
      val =  Date.strptime(value,'%Y/%m/%d').strftime(DATE_RET_FMT_D)
    elsif (value.length == 6 )
      value.insert(4,'/')
      val =  Date.strptime(value+'/01','%Y/%m/%d').strftime(DATE_RET_FMT_M)
    elsif (value.length == 4)
      val =  Date.strptime(value+'/01/01','%Y/%m/%d').strftime(DATE_RET_FMT_Y)
    else
      val = ''
    end
    val
  end

  # Generates Date String in HL7 date format.
  # Parameter:
  #  value : Date in NNN d,y format.
  #          eg.   Jan 2,2001
  #                Jan 2, 2001
  #                Jan 2001
  #                2001
  # Return date in CCYYMMDD format (HL7)
  def getHL7Date(value)
    if value.nil? || value == ""
      return  ''
    end
    parse_monthpat = ABBR_MONTHS.keys.join('|')
    if !(value.match(parse_monthpat)).nil?
      if !(value.match(', ')).nil?
        val =  Date.strptime(value,'%b %d, %Y').strftime('%Y%m%d')
      elsif !(value.match(',')).nil?
        val =  Date.strptime(value,'%b %d,%Y').strftime('%Y%m%d')
      else
        hl7year = value.match(/\d\d\d\d\z/).to_s
        value= value.gsub(/\d\d\d\d\z/,'01,'+hl7year)
        val =  Date.strptime(value,'%b %d,%Y').strftime('%Y%m')
      end
    else
      hl7year = value.match(/\d\d\d\d\z/).to_s
      value= value.gsub(/\d\d\d\d\z/,'Jan 01,'+hl7year)
      val =  Date.strptime(value,'%b %d,%Y').strftime('%Y')
    end
    val
  end # getHL7Date

end #end form_controller
