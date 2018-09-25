# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  #audit Rule, RuleCase, RuleAction, TextListItem, GopherTerm, GopherTermSynonym,
  #  Classification, DataClass
  # For the session timeout, cache the session's page view so we can keep
  # the user in the same view (e.g. basic HTML mode) when a new session is started.
  sliding_session_timeout SESSION_TIMEOUT.minutes, :cache_session_info
  after_action :last_session, :except=>[:get_session_updates]
  after_action :set_last_session, :only=>[:get_session_updates]
  protect_from_forgery :except => :index
  #before_action :require_ssl # see comments for require_ssl method
  before_action :clean_sessions,  :only => [:login]
  before_action :set_to_popup
  after_action  :clear_login_token,  :only => [:login]
  before_action :slow_scanners, :except=>[:get_search_res_list]
  after_action :store_response_info, :except=>[:get_search_res_list]
  before_action :set_content_type
  before_action :set_cache_buster

  around_action :session_data_checks

  rescue_from Exception, :with => :rescue_action


  def render_to_body(options)
#    raise options.inspect
    opts = options.clone
    if mobile_html_mode?
      #logger.debug("\n\n (mobile version)render_to_body: options :" + options.inspect)
      case options[:layout]
        when Proc
          # when the "render 'foo/bar' " was used, we need to add layout and template manually
          logger.debug("\n\n (mobile layout string)render_to_body: options :" + options[:layout].call.inspect)
          layout_call = options[:layout].call
          if layout_call == "layouts/mobile" || layout_call == "layouts/basic"
            options[:layout] = "layouts/mobile"
            # rebuild template using :file or :prefixes options (make sure remove those options when new template is in place)
            old_template = options.delete(:file) || (options.delete(:prefixes)[0]+ "/" + options[:template])
            if !old_template.match(/^mobile/)
              if old_template.match(/^basic/)
                options[:template] = old_template.gsub("basic/", "mobile/")
              else
                options[:template] = "mobile/#{old_template}"
              end
            end
          end
        when String
          # Convert the template for basic mode into the one for mobile mode. For example:
          # 1) "basic/login/signup.html.erb" ===> "mobile/login/signup.html.erb"
          # 2) "phr_records/profile_index.html.erb" ===> "mobile/phr_records/profile_index.html.erb"
          old_template = options[:template] if options[:template].is_a?(String)
          if !old_template.match(/^mobile/)
            if old_template.match(/^basic/)
              options[:template] = old_template.gsub("basic/", "mobile/")
            else
              options[:template] = "mobile/#{old_template}"
            end
          end
          # Make sure the layout is for mobile version
          if options[:layout].is_a?(String) && options[:layout]!= "layouts/mobile"
            options[:layout] = "layouts/mobile"
          end
        else
          #raise "the layout is missing"
      end
      #logger.debug("\n\nfinal (mobile version)render_to_body: options :" + options.inspect)
    end
    super(options)
end

  # Sets the content type header for all requests
  def set_content_type
    response.headers["Content-Type"] = 'text/html; charset=UTF-8'
  end


  # Sets the HTTP header so that nothing should be cached in browsers
  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  # An around filter to prevent session data changes from one request being
  # overwritten by another request that is running in parallel.
  def session_data_checks
    starting_sess_hash = {}
    session.keys.each do |key|
      starting_sess_hash[key] = session[key]
    end
    session_id = request.session.id
    yield
    mismatch = false
    session.keys.each do |key|
      if starting_sess_hash[key].nil? || starting_sess_hash[key] != session[key]
        mismatch = true
        break
      end
    end
    if mismatch == false
      if session_id
        db_session = ActiveRecord::SessionStore::Session.find_by_session_id(session_id)
        if db_session
          session.update(db_session.data)
        end
      end
    end
  end # session_data_checks


  # Slows down scanners so we don't get pounded
  def slow_scanners
    # ***LOAD_TESTING change***: Comment out the following line to disable brake logic
    # for load testing. -Ajay 07/09/2014
    Brake.slow_scanners(request)
  end


  # Another part of slowing down the scanners.  We need to check the response
  # type; if it is redirect we do not want to slow the next requst.
  def store_response_info
    # ***LOAD_TESTING change***: Cooment out to disable brake.
    Brake.store_response_info(response, session)
  end


  # The variable that holds the page errors.  For some reason (and I think there
  # was one, though it might not have been a good one), we're not
  # using flash[:error] for a lot of pages.
  attr_reader :page_errors

  # start @flag_account_type out as nil.  If it's an experimental/test
  # account, we'll fill it in when the user logs in.
  @temp_account_type = nil

  # After login, user can be forwarded to a URL fitting one of these patterns.
  @@regexWhiteList = ['\/registration\/[0-9a-zA-Z]*;edit\\z',
        '\/registration\/new\\z',
        '\/profiles\/[0-9a-zA-Z]*;?(edit|export|print)?\\z',
        '\/profiles\/new\\z',
        '\/profiles\/[0-9a-zA-Z]*;?\/[a-zA-Z]*;?\/?[a-zA-Z]*\\z',
        '\/profiles\/?[0-9a-zA-Z]*\\z',
        '\\A\/phr_records(\\z|\/)',
        '\/classes\/[a-zA-Z]+',
        '\/accounts\/[a-zA-Z]*',
        '\/acceptance\/[0-9a-zA-Z]*',
        '\/rules',
        '\/data',
        '\/fetch_rules\/',
        '\/usage_stats\/',
        '\/phr_home\/',
        '\/share_invitation\/',
        '\/forms\/[a-zA-Z]*\/[a-zA-Z]*\/[0-9a-zA-Z]*;edit\\z',
        '\/forms\/[a-zA-Z]*\/[a-zA-Z]*\/new\\z',
        '\/forms\/?\\z',
        '\/forms\/new\\z',
        '\/forms\/[a-zA-Z]*;edit\\z'
       ]

  FORM_READ_ONLY_EDITABILITY = 'READ_ONLY'
  FORM_READ_WRITE_EDITABILITY = 'READ_WRITE'

  RECOVERY_MSG = "We found unsaved data changes for this form.<br />" +
                 "The information on this page includes those changes, " +
                 "outlined in green." +
                 "<ul><li>To keep the changes, click on the Save " +
                 "button at either the top or the bottom of this page.</li>" +
                 "<li>To discard the changes, click on the Close " +
                 "button at the top or the bottom of this page.</li></ul>"

  AUTOSAVE_OVERFLOW_MSG = '<center><b>WARNING</b><br>' +
                          'The amount of data on this form exceeds the ' +
                          'amount that the autosaving function can handle.' +
                          '<br>Changes, additions and deletions will not be ' +
                          'autosaved.  Please be sure to click on the Save ' +
                          'button at the bottom of this page often.</center>'

  # This is a dummy method being called from the idle.js javascript
  # to reset the server session.
  def extend_session
    time_min = params[:extend_by]
    session[:expires_at] = time_min.to_f.minutes.from_now
    render(:plain=>"Your PHR session has been extended, and will expire "+
      "#{SESSION_TIMEOUT} minutes from now.")
  end


  def initialize
    super
    # A list of errors messages to show the user.
    @page_errors = []
  end


  # Shows a single form without user data and without requiring a login.
  # This can show blank versions of forms that normally have user data
  # (for testing or system initialization.)
  #
  # This was moved from the form controller to here in the application
  # controller so that the phr home controller can access it.  Oct 2013, lm
  def show
    @form_name = params[:form_name]
    @form_name = params[:id] if !@form_name

    # At this point, if @form_name is nil, don't proceed.  It is probably a
    # scanner sending a bad request.
    if @form_name.nil?
      render :file=>'public/400.html', :layout=>false, :status=>:bad_request
    else
      # Check to see if this is a request to build a read-only version of
      # a form.  If so, set the access level flag and chop the indicator
      # off the end of the form name
      idx = @form_name.index('_RO')
      if !idx.nil?
        @access_level = ProfilesUser::READ_ONLY_ACCESS
        @form_name = @form_name[0..(idx - 1)]
      end

      # Set the action URL to be the current URL.  (This will give
      # handle_post the current URL so it can determine the next action.)
      @action_url = request.path

      # add data for taffy db
      # note: basically a second copy of the data are added. In the future, it
      # should use only one copy of the data and probably the data_hash should be
      # nixed.
      @form = Form.find_by_form_name(@form_name)
      fd = FormData.new(@form)

      # We don't have a user or a profile, but we call get_taffy_db_data to get
      # (empty) data structures needed by the form's layout and the JavaScript.
      taffydb_data, @recovered_data, from_autosave, err_msg, except =
                                                  fd.get_taffy_db_data(nil,
                                                ProfilesUser::NO_PROFILE_ACTIVE)
      # recovered data is not currently used, because none of the forms
      # that use this implement the autosave function.

      # Make sure there is no user data in taffydb_data.  There shouldn't be,
      # but just in case, we check here.
      data_table = taffydb_data[0]
      data_table.keys.each do |table_name|
        table = data_table[table_name]
        table.each do |row|
          row.each do |field_name|
            raise 'Unexpected user data found' if !row[field_name].blank?
          end
        end
      end

      # add the form_name
      if !taffydb_data.empty?
        taffydb_data << [@form_name, nil]
      end
      @form_data = taffydb_data
      # if no profile id, no autosave yet
      if !err_msg.nil?
        flash.now[:notice].nil? ? flash.now[:notice] = err_msg :
                                  flash.now[:notice] << '<br>' + err_msg
        SystemError.record_server_error(except, request, session)
      end
      render_form(@form_name)
    end
  end # def show


  # This method gets the url from a specified request object and removes the
  # authenticity token if one is included in the url.  This is written to be
  # used when we need to write the url to a usage stats event row, where we
  # want to store the address and any parameters other than the authenticity
  # token.
  #
  # This method is a public version of the private get_url method.  It's here
  # in the public area so that functional tests can use it, but unlike get_url,
  # it requires a request object to be specified.  So it's not automatically
  # getting it from the current request object.
  #
  # Parameters: request_obj the request object containing the url
  # Returns: the adjusted url
  #
  def get_specified_url(request_obj)

    # Get the url from the request object, stripping out the authenticity_token
    # if it's there.  We don't need to store that with the usage stats data,
    # but we do want to retain any other parameters.

    uri = URI(request_obj.url)
    if (uri.query.nil?)
      the_url = request_obj.url
    else
      query_parts = CGI::parse(uri.query)
      the_url = uri.scheme + '://' + uri.host + uri.path + '?'
      query_parts.delete('authenticity_token')
      the_url += URI.encode_www_form(query_parts)
    end
    return the_url
  end


  protected

  # Renders an HTML error page for the given status code.  Note that only
  # a few status codes are supported; for options see the files in the public
  # folder named [status code].html.
  def render_html_status_page(html_status_code)
    render(:file=>"#{Rails.root}/public/#{html_status_code}.html", :layout=>false,
           :status=>html_status_code)
  end


  # This method is required by paper_trial to include user when auditing
  # changes to the models, e.g. rule modifications
  def current_user
    @user ||= User.find_by_id(session[:user_id])
  end


  # This prevents session being logged out with invalid request. Instead user
  # sees a exception
  def handle_unverified_request
    if @expiry
      end_user_session('no_logout')
    else
      redirect_to '/errors/400.txt'
    end
  end


  def clear_login_token
    pattern = /<input name=\"authenticity_token\" type=\"hidden\" value=\".*\" \/>/
    response.body.sub!(pattern,'')
  end


  # A before filter to require SSL requests, except when REQUIRE_HTTPS is
  # set to false.  Remove 4/9/14, lm - duplicated below.
#  def require_ssl
#    redirect_to '/errors/400.txt' if !request.ssl? && REQUIRE_HTTPS
#  end


  # This is the around filter that is used for methods we're expecting to be
  # invoked via an ajax call.  It checks for that, and if the invocation is
  # wrong, displays an error page.
  #
  # Otherwise processing yields to the method called.  If an exception is raised
  # in that method, it is handled here, using the @exception_error_message
  # that should be set by the called method.
  #
  # This is currently used by selected methods, as defined above in the
  # around_action (formerly around_filter) statement above.
  #
  def xhr_and_exception_filter
    if (!request.xhr?)
      render_html_status_page(403)
    else
      @status = 200
      begin
        yield
      rescue Exception => e
        @status = 500
        SystemError.record_server_error(e, request, session)
        render :status => @status ,
               :json => @exception_error_message.to_json
      end
    end # if this is an Ajax request or from a test
  end # xhr_and_exception_filter


  # A before filter to set the @from_popup flag if the current request
  # is for a popup window.
  # removed 4/9/14 lm, duplicated below
#  def set_to_popup
#    if params[:from] && params[:from] == 'popup'
#      @to_popup = true
#    else
#      @to_popup = false
#    end
#  end


  #
  # Called by convert_params_to_panel_records only
  # to return a hash map of one panel's data by matching the suffix string
  #
  # Parameters
  # * start_str - a suffix string of a field to be matched
  # * hash_map - an existing internal panel hash map
  #
  # Returns
  # * a panel hash map whose fields' suffixes match the suffix string
  def get_panel_hash_startingby(start_str, hash_map)
    rtn = {}
    panel_info = {}
    found = false
    hash_map.each do |key, value|
      i = key.index(start_str)
      # found a match
      if !i.nil? && i == 0
        found = true
        level = key.scan(/_/).length
        case level
        # '_1_1', panel name, loinc num
        when 2
          existing_value = panel_info["0"]
          if existing_value.nil?
            panel_info["0"] = value
          else
            panel_info["0"] = existing_value.merge(value)
          end
        # '_1_1_1', panel info: date, place
        when 3
          existing_value = panel_info["0"]
          if existing_value.nil?
            panel_info["0"] = value
          else
            panel_info["0"] = existing_value.merge(value)
          end
        # '_1_1_1_1, test info: name, value, etc
        when 4
          test_key = key.scan(/[0-9]+\z/)
          panel_info[test_key[0]]=value
        else
        end
      end
    end
    if found
      rtn[start_str] = panel_info
    end
    return rtn
  end



  # Renders the given form using the show.rhtml template.  The following
  # instance variables are used if set:
  # * @action_url - the URL for submitting the form
  # * @data_hash - the data for the form
  #
  # Parameters
  # * form_name - the name of the form to show
  def render_form(form_name, form_cache_name=nil)

    # JavaScript for form field elements (e.g. initialization JS)
    # This receives the javascript that is to be written to the
    # form's generated javascript file, to keep all the javascript
    # out of the page (and hopefully speed loading time).
    @form_field_js = ''

    # A hash containing all the functions binded to the form load event
    @form_onload_js = {}

    @form_name = form_name
    set_account_type_flag

    # Get the form object if we don't already have it.
    # For the tests, sometimes @form is cached from a previous page access,
    # so make sure the form name is right if @form is present.
    @form = Form.where(:form_name=>form_name).first if !@form || @form.form_name!=form_name
    @header_type = @form.header_type
    @show_banner_on_popup = @form.show_banner_on_popup
    if @to_popup || !@form.show_toolbar
      @show_header = false
    else
      @show_header = true
    end

    if !@form_data.nil? && !@form_data.empty?
      @profile_banner = FormData.find_template_field_values(@form.form_title,
          @form_data[0])
    else
      @profile_banner = nil
    end

    if @profile
      @profile_name = @profile.phr.pseudonym
    else
      @profile_name = ''
      @access_level = ProfilesUser::NO_PROFILE_ACTIVE if @access_level.nil?
    end

    @form_field_js << "\n" + 'Def.NO_PROFILE_ACTIVE = ' +
                      ProfilesUser::NO_PROFILE_ACTIVE.to_s + ';' + "\n"
    @form_field_js << 'Def.OWNER_ACCESS = ' +
                      ProfilesUser::OWNER_ACCESS.to_s + ';' + "\n"
    @form_field_js << 'Def.READ_WRITE_ACCESS = ' +
                      ProfilesUser::READ_WRITE_ACCESS.to_s + ';' + "\n"
    @form_field_js << 'Def.READ_ONLY_ACCESS = ' +
                      ProfilesUser::READ_ONLY_ACCESS.to_s + ';' + "\n"

    @form_field_js << 'Def.FORM_READ_ONLY_EDITABILITY = "' +
                      FORM_READ_ONLY_EDITABILITY + '";' + "\n"
    @form_field_js << 'Def.FORM_READ_WRITE_EDITABILITY = "' +
                      FORM_READ_WRITE_EDITABILITY + '";' + "\n\n"


    if @form_subtitle.nil?
      @form_subtitle = @form.sub_title
    end

    if @access_level == ProfilesUser::READ_ONLY_ACCESS && !@profile.nil?
      @access_notice_text =
        ProfilesUser::READ_ONLY_NOTICE % {owner: @profile.owner.name}
    else
      @access_notice_text = ''
    end
    # @unique_values_by_field should NOT be cached.
    # e.g. when new pseudonym was created
    @unique_values_by_field = ServersideValidator.unique_values_by_field(
                               @form.id, session[:user_id]) if session[:user_id]

    # If there is an urgent notice for the page, get it.
    @urgent_notice = SystemNotice.urgent_notice

    did_redirect = false

    if @form_autosaves && @access_level < ProfilesUser::READ_ONLY_ACCESS
      # Only reset the autosave data if we're not recovering leftovers.
      if (!defined?(@from_autosave) || !@from_autosave)
        AutosaveTmp.set_autosave_base(@profile,
                                      @form_name,
                                      @access_level,
                                      @form_data[0].to_json,
                                      false,
                                      false)
        begin
          check_for_data_overflow(@profile.owner)
        rescue DataOverflowError
          did_redirect = true
          redirect_to(login_url)
        end
      end
      if !did_redirect
        if @recovered_data.nil? || @recovered_data.empty?
          session[:showing_unsaved] = false
        else
          flash.now[:notice].nil? ? flash.now[:notice] = RECOVERY_MSG :
                                    flash.now[:notice] << '<br>' + RECOVERY_MSG
          session[:showing_unsaved] = true
        end # if we don't/do have recovered data
      end
    end # if this forms autosaves data
    if !did_redirect
      @form_cache_name = form_cache_name || form_name
      if @access_level == ProfilesUser::READ_ONLY_ACCESS
        @form_cache_name += '_RO'
        @form_editability = FORM_READ_ONLY_EDITABILITY
      else
        @form_editability = FORM_READ_WRITE_EDITABILITY
      end
      #using_cache_files = read_fragment(:id=>'part1'+@form_name)
      @using_cache_files = read_fragment(Rails.env + '/layout_part3' +
                                         @form_cache_name)
      unless @using_cache_files
        @data_hash= nil unless defined?(@data_hash)
        if session[:data_hash]
          @data_hash = session[:data_hash]
          session[:data_hash] = nil
        end

        @form_data = nil unless defined?(@form_data)
        @tip_fields = {}
        # Data for the controlled-edit tables
        @ce_table_data = {}

        # Create the field observers hash.
        @field_observers = {}
        @field_validations = {}
        @field_defaults = {} # hash for field defaults

        @form_style, @print_style = @form.get_styles_by_form

        ## Using cache to avoid nested/recursive calls for getting associated
        #  objects of rules/fields on the form.
        #  This cache will be used in the following lines of codes:
        #    load_rule_data
        #    render(:template=>'form/show', :layout=>'form')
        RuleAndFieldDataCache.cache_rule_and_field_associations(@form)

        @dateFields = @form.retrieve_date_fields
        session[:data_view] = @form.data_view
        load_rule_data(@form)

        @target_form = nil
      end # unless
      # determine the banner type
      if @header_type != 'N' # "none" (no banner; needed for rxterm demo form)
        if !@to_popup || (@to_popup &&
              (@show_banner_on_popup.nil? || @show_banner_on_popup == true)) &&
            (@header_type.nil? || @header_type == 'F')
          @banner_class = 'full_banner'
        else
          @banner_class = 'simple_banner'
        end
      end
      logger.debug 'at end of render_form, about to render'

      render(:template=>'form/show.rhtml',:layout=>'form.rhtml')
    end # if didn't do a redirect on a security error
  end # end of render_form


  # Renders the given form using the show.rhtml template.  The following
  # instance variables are used if set:
  # * @action_url - the URL for submitting the form
  # * @data_hash - the data for the form
  #
  # Parameters
  # * form_name - the name of the form to show
  def do_redirect()
    target = get_param('target')
    flash_hash = get_param('flash_hash')
    if (!flash_hash.nil?)
      flash_hash.each_pair do |key, value|
        flash[key] = value
      end
    end
    redirect_to(target)
  end # do_redirect


  # Returns the value of the given parameter from the params array.  This works
  # around a parsing bug that messes up the keys.
  def get_param(key)
    rtn = params[key]
    if (rtn.nil?)
      rtn = params['amp;'+key.to_s]
    end
    rtn
  end


  # Checks to see if the data stored for the specified user has exceeded
  # the defined limits for stored data.  If a user is not specified, the
  # current user - @user - is assumed.
  #
  # Checking may be specified for a user other than @user when a user who
  # doesn't own a profile has write access to it and makes changes.  Any
  # change in data size for a profile is recorded for the owner, whether or
  # not that person is the one who made changes.
  #
  # If the limits have been exceeded this stores a SystemError in the
  # database, puts a message in the flash, ends the user session, and
  # re-raises the error so that the calling controller can send an indication
  # back to the client that the session has been logged out.
  #
  def check_for_data_overflow(target_user = @user)
    begin
      target_user.check_data_overflow
    rescue DataOverflowError => err_msg
      SystemError.record_server_error(err_msg, request, session)
      flash.now[:error].nil? ? flash.now[:error] = err_msg.message :
                               flash.now[:error] << '<br>' + err_msg.message ;
      end_user_session('data_overflow')
      raise
    end
  end


  # Handles uncaught exceptions.  This extends the default handling by storing
  # information about the error in the database and sending a notification
  # email (in production mode).
  #
  # Parameters:
  # * exception - the uncaught exception
  def rescue_action(exception)
    SystemError.record_server_error(exception, request, session)
    # Don't call super on the public systems, because it prints an exception
    # stacktrace to the logs and that might contain PII data.
    if request.xhr? && !PUBLIC_SYSTEM
      render :status => :failed,
        :plain => {'errors' => @page_errors}.to_json
    else
      is_routing_error = exception.class ==  ActionController::RoutingError ||
        exception.class == AbstractController::ActionNotFound
      if is_routing_error
        # Routing errors don't go through the before_actions, so we add a
        # needed call here to Brake.
        slow_scanners
      end
      if PUBLIC_SYSTEM
        if is_routing_error
          render_html_status_page(404)
        else
          render_html_status_page(500)
        end
      else
        raise exception
      end
    end
  end


  # Returns search results for a search for given terms within a specified
  # table's column, using Ferret.  This method is public so that it can be
  # tested, but it is not intended to be called directly as a controller
  # action.  It is thought that it should be safe, because the method
  # requires parameters that cannot be specified in an URL.  This could be
  # moved into the has_searchable_list.rb class, and defined on the models
  # just like find_storage_by_contents.
  #
  # This method obtains search parameters from a field_descriptions object.
  # See get_matching_search_vals for the version that gets the parameters
  # from a db_field_descriptions object.
  #
  # Parameters:
  # * field_desc - the field description record for the field
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
  # <span> tags around the terms that matched the query.\
  #
  def get_matching_field_vals(field_desc, terms, limit)
    table_name = field_desc.getParam('search_table')
    if !search_allowed?(table_name)
      raise "Search of table #{table_name} not allowed."
    end

    table_class = table_name.singularize.camelize.constantize

    list_name=field_desc.getParam('list_name')
    highlighting = field_desc.getParam('highlighting')
    if (highlighting.nil?)
      highlighting = false
    end

    search_cond = field_desc.getParam('conditions')

    search_options = {:limit=>limit}
    order = field_desc.getParam('order')
    search_options[:sort] = order if order

    fields_searched = field_desc.fields_searched
    fields_returned = field_desc.fields_returned
    fields_displayed = field_desc.fields_displayed

    # Return the result of find_storage_by_contents, plus the "highlighting"
    # variable.
    table_class.find_storage_by_contents(list_name, terms, search_cond,
                                        fields_searched, field_desc.list_code_column.to_sym,
                                        fields_returned, fields_displayed,
                                        highlighting, search_options) << highlighting
  end # get_matching_field_vals

  # Returns true if the table name can be safely searched.
  #
  # Parameters:
  # * table_name - the value of a search_table parameter for a field.
  def search_allowed?(table_name)
    # The table name either has to start with "user " (indicating that
    # the data will be restricted to the user's data) or has to be a member
    # of @@public_tables.
    return @@public_tables.member?(table_name) || table_name.index('user ') == 0
  end

  # Set up a set of table names that can be safely searched by any user.
  # The parameter 'search_table' in FieldDescription.control_type_detail
  # should be checked against this list.  A user who is logged in might
  # have additional tables that can be searched, but those won't be in this
  # list.  (Those table names (as specified in the field descriptions) should
  # start with the prefix 'user ', e.g. 'user phrs'.)
  @@public_tables = Set.new(['gopher_terms', 'rxnorm3_drugs', 'icd9_codes',
    'list_details', 'drug_name_routes', 'drug_strength_forms',
    'text_lists', 'vaccines', 'predefined_fields','answer_lists',
    'regex_validators','loinc_items', 'loinc_units', 'field_descriptions',
    'rxterms_ingredients', 'drug_classes', 'db_table_descriptions',
    'db_field_descriptions', 'forms', 'rule_action_descriptions',
    'comparison_operators', 'rules', 'loinc_names', 'classifications',
    'data_classes'])

  # Override the original method to facilitate the testing of codes where this
  # method was used
  def verify_recaptcha
    if Rails.env =="test" || (!defined?(BYPASS_CAPTCHA).nil? && BYPASS_CAPTCHA == true)
      return params['g-recaptcha-response'] == "correct_response"
    else
      super
    end
  end

  private

  # A method to cache the value of the session page_view parameter.  Used
  # when a session times out to keep the user in basic HTML mode.
  def cache_session_info
    @page_view=session[:page_view]
    @expiry = true
  end


  # Returns suggested values via a fuzzy search based on the configuration
  # of the given field description.
  #
  # Parameters:
  # * field_desc - the field description whose list is to be searched
  # * field_val - the value for which close matches will be returned
  #
  # Returns:  The results of find_fuzzy_items (see active_record_extentions.rb).
  def get_suggestions_for_field(field_desc, field_val)
    table_name = field_desc.getParam('search_table')
    if !search_allowed?(table_name)
      raise "Search of table #{table_name} not allowed."
    end
    table_class = table_name.singularize.camelize.constantize
    return table_class.find_fuzzy_items(nil, field_val,
      field_desc.getParam('conditions'), field_desc.fields_searched,
      field_desc.list_code_column.to_sym, field_desc.fields_displayed)
  end


  # Every so often on login attempts clean up the session table which can get
  # bloated with stale sessions. Records > 10 hrs (36000) deleted right now.
  def clean_sessions
    # Clean it on average once every 20 logins
    if request.request_method != 'GET' and (rand(100) % 20 == 0)
      ActiveRecord::Base.connection.execute( "
        DELETE FROM sessions
        WHERE NOW() - updated_at > 36000
      " )
    end
  end


  def clear_login_token
    pattern = /<input name=\"authenticity_token\" type=\"hidden\" value=\".*\" \/>/
    response.body.sub!(pattern,'')
  end

  # A before filter to require SSL requests, except when REQUIRE_HTTPS is
  # set to false.
  def require_ssl
    redirect_to '/errors/400.txt' if !request.ssl? && REQUIRE_HTTPS
  end


  # This method keeps track of when last session expiry time was updated.
  # This allows to set session expiry back to old value for periodic system
  # notice update requests which otherwise would cause sessions to never expire.
  def last_session
    session[:last_expires_at] = session[:expires_at]
  end

  # Update the session expiry time to that before the request for system update
  # notice
  def set_last_session
    session[:expires_at] = session[:last_expires_at]
  end

  # A before filter to set the @from_popup flag if the current request
  # is for a popup window.
  def set_to_popup
    if params[:from] && params[:from] == 'popup'
      @to_popup = true
    else
      @to_popup = false
    end
  end


  # Returns false if user is being redirected and true if user is authorized to
  # continue
  def authorize

    rtn = true
    unless !session[:user_id].blank? && @user = User.find_by_id(session[:user_id])
      # Store the original URI so we can take the user there after they log in,
      # but only if the request method was a GET (e.g. not a DELETE).
      session[:original_uri] = request.path if request.request_method == 'GET'
      flash[:notice] = "Please log in."
      # It might be that the user accessed a basic mode URL, but were not
      # logged in yet.
      if request.fullpath =~ /^\/phr_records/
        session[:page_view] = 'basic' if default_html_mode?
      else
        # It could also be that their session timed out while they
        # were in basic mode.  When a session times out, the current page_view
        # is cached.  Restore that before redirecting to the login page.
        session[:page_view] = @page_view if @page_view and !session[:page_view]
      end
      redirect_to(login_url)
      rtn = false
    else
      # Set the @session_timeout that is used by basic mode to tell
      # the user how much time they have until their keyboard catches on fire.
      @session_timeout = SESSION_TIMEOUT
      # Paul and Lee believe that this check is unnecessary and muddles the
      # process.  Data overflow is checked when the user logs in and whenever
      # any user data is saved, including autosave and usage data.  If overflow
      # is found the user is logged out and cast into oblivion.
      #check_for_data_overflow
    end
    return rtn
  end


  # A before filter used to verify user name before the user logs in. For example, when
  # user tries to recover the forgotten password. It also being used in a before
  # filter in usage_stats_controller.rb.
  def verify_user
    user_name = session[:user_name]
    @user = User.find_by_name(user_name)  if !user_name.blank?
    if @user.nil?
      flash[:error] = User.non_exist_user_error(user_name)
      redirect_to login_path
    end
  end


  # Checks if the user is logged in the current session
  # Returns true - if user logged in
  #         false -if user not logged in
  def logged_in?
    return !session[:user_id].blank? && User.find_by_id(session[:user_id]) ? true : false
  end


  # A before filter for verifying user name and reset key. Redirect to login page if proper
  # reset key or user name is not presented.
  # Parameters:
  # * params with user and reset_key information is used by request from the password reset link
  # * session with user and reset_key information is used by other requests
  def reset_preconditions
    # checks
    if  !params[:user].blank? && !params[:reset_key].blank?
      session[:user] = params[:user]
      session[:reset_key] = params[:reset_key]
    end

    if session[:user].blank? || session[:reset_key].blank?
      flash[:error] = 'The request is invalid'
    else
      @user = User.find_by_name(session[:user])
      if @user && @user.verify_reset_key(session[:reset_key])
        # prevent user from making a second post without getting a new reset key
        @user.clear_reset_key  if request.post?
      else
        flash[:error] = self.class.incorrect_reset_pw_key
      end
    end
    redirect_to login_path  if flash[:error]
  end


  # Returns the value of the "incorrect password reset key" message.
  # We cannot define it directly as a class constant or variable like
  # the other messages because it uses a route helper which is not
  # always defined when the class is loaded.
  def self.incorrect_reset_pw_key
    if !defined? @@incorrect_reset_key
      @@incorrect_reset_key = ('The reset request has expired or is incorrect. Please '+
          'try again or use the <a href="'+Rails.application.routes.url_helpers.new_contact_us_path+
          '">'+SUPPORT_PAGE_NAME+'</a> page for assistance.').html_safe
    end
    @@incorrect_reset_key
  end


  # Sets class instance variable to show header template field.
  # Note: Whether to show header or not is decided by the 'show_toolbar' value
  #   in the 'forms' table for each form. This method as a before_action is
  #   needed only because some pages are rendered with a 'noform' layout,
  #   thus the 'render_form' method, where @show_header is set, is not called.
  #   For pages with a 'noform' layout, a header tool bar is always needed.
  def show_header
    @show_header = true
  end


  # Sets the text to be displayed for experimental/test or demo accounts.
  # Invoked with a before_action directive in controllers where
  # appropriate
  # Not currently used for experimental/test accounts, 8/2012 lm
  def set_account_type_flag
    if @user
      if @user.account_type == EXP_ACCOUNT_TYPE
        exp = @user.created_on + 182
        @temp_account_type = 'This is your ' + EXP_ACCOUNT_NAME + ' Account. ' +
            'This data will be discarded 30 days after it is last accessed, ' +
            'or on ' + Date::MONTHNAMES[exp.mon()] + ' ' + exp.day().to_s + ', ' +
            exp.year().to_s + ', whichever comes first.'
      elsif @user.account_type == DEMO_ACCOUNT_TYPE
        @temp_account_type = "This is a Demo Account. Please don't enter " +
            "your real data. All data entered into demo accounts will be " +
            "deleted every morning at 3:00 A.M. EST."
      end
    end
  end


  # verifies password
  # Returns false if user is being redirected and true if user is authorized to
  # continue
  def verify_password
    form_params = params[:fe]
    rtn = false
    @action_url = request.path

    if !@user
      # Not sure when this would happen
      redirect_to('/')
    else
      if (request.post? || request.put?) && session[:password_verified_token] &&
         session[:password_verified_token] == params['password_verified_token']
        rtn = true # the password has previsouly been verified for this page
        # Also reset @password_verified_token in case the page protected by
        # this filter needs to redisplay.
        @password_verified_token = session[:password_verified_token]
      else
        if !request.put? && !request.post?
          render_enter_pw_form
          rtn = false
        else
          # Assume a verify_password form submission
          user = User.verify_password(@user.name,form_params[:password_1_1],
                                      @page_errors)
          if user && @page_errors.blank?
            # The user correctly entered their password
            user.trial_update
            user.save!
            @password_verified_token = SecureRandom.hex(20)
            session[:password_verified_token] = @password_verified_token
            @data_hash = user.data_hash_for_update_account_settings
            rtn = true # continue on to the action
          else
            render_enter_pw_form
            rtn = false
          end
        end
      end
    end
    return rtn
  end


  # Returns true if the session is in basic html mode and vice versa
  def basic_html_mode?
    session[:page_view] == 'basic'
  end


  # Returns true if the session is in mobile html mode and vice versa
  def mobile_html_mode?
    session[:page_view] == 'mobile'
  end


  # Returns true if the session is in default html mode and vice versa
  def default_html_mode?
    session[:page_view].blank? || session[:page_view]== 'default'
  end


  # Returns true if the session is in non-default html mode and vice versa
  def non_default_html_mode?
    !default_html_mode?
  end


  # Returns true if the request is coming from a mobile browser and vice versa
  def mobile_agent?
    found = false
    if agent = request.user_agent && request.user_agent.downcase
      #logger.debug("%%%%%%%%%%% mobile request.user_agent is #{agent}")
      MOBILE_BROWSERS.each do |m|
        if agent.match(m)
          #logger.debug("%%%%%%%%%%% mobile matched on #{m}")
          found = true
          break
        end
      end
    end
    return found
  end


  # Shows the "enter password" form
  def render_enter_pw_form
    if non_default_html_mode?
      @p = EnterPwPresenter.new(params[:fe])
      @page_title = @p.form.form_title
      @hide_account_settings = true
      render :template=>'basic/login/enter_pw', :layout=>'basic'
    else
      @action_url = request.path
      render_form('verify_password')
    end
  end


  # A before_action method for checking to make sure the user is logged in as
  # an admin user. If they are not logged in as an admin user, they are
  # redirected to the login page.
  # Returns:  true if the user can continue with the requested action
  def admin_authorize
    rtn = true
    if !is_admin_user?
      session[:original_uri] = request.path
      flash[:notice] = "Please log in as an admin user."
      redirect_to(login_url)
      rtn = false
    end
    return rtn
  end


  # Checks if user has admin priviledges
  # Returns:  true if admin user
  #           false if not
  def is_admin_user?
    @user = User.find_by_id(session[:user_id]) if !session[:user_id].blank?
    return !(@user.blank? || !@user.admin)
  end


  # Loads the rule data into instance variables for use when rendering a form
  # template.  This also (because it is convenient) loads the parameter
  # @fields, which contains the top-level fields of the form. The rule data
  # is loaded into the following variables:
  # * @field_rules - a hash map from target_field names to a ordered list of
  #   rule names to be run when the field's value changes
  # * @rule_actions - a hash map from rule names to actions to be performed
  #   when the rule is evaluated.  Each action consists of an action name,
  #   the target name of an affected field (to which the action is applied--
  #   this may be null), and a hash map of parameters to be passed to the
  #   action method.
  # * @form_rules - an list of rule names for all fields on the form, in the
  #   in which they should be run
  # * @rule_trigger - map of rule names to one field target name that triggers
  #   the rule.  (This is used for running the rules when the form loads.)
  # * @rule_scripts - an array of JavaScript functions for running the rules.
  # * @case_rules - a hash map from rule names to 1(which means true) if  rule
  #   has rule cases.
  # * @hash_sets - a hash map from rule names to set of drug names where the set
  #   is a hash map from drug names to 1(which means true).
  def load_rule_data(form)
    options       = RuleData.load_data_to_form(form)
    @fields       = options[:fields]
    @field_rules  = options[:field_rules]
    @affected_field_rules  = options[:affected_field_rules]
    @rule_actions = options[:rule_actions]
    @form_rules   = options[:form_rules]
    @rule_trigger = options[:rule_trigger]
    @rule_scripts = options[:rule_scripts]
    @case_rules   = options[:case_rules]
    @fetch_rules  = options[:fetch_rules]
    @reminder_rules  = options[:reminder_rules]
    @value_rules  = options[:value_rules]
    @data_rules = options[:data_rules]
    @hash_sets    = options[:hash_sets]
    @loinc_field_rules = options[:loinc_field_rules]
    @db_field_rules = options[:db_field_rules]
  end


  # A recursive method used by data_hash_from_params to load the data_hash
  # with the data for the given field (and any sub fields).
  #
  # Parameters:
  # * form_params - the field data parameters from the form submission
  # * fd_list - the FieldDescriptions whose data in form_params is to be loaded
  #   into data_hash (along with the data for any sub-fields).
  # * field_to_max_row - A hash map of target field names to the maximum
  #   row number present in the form_params map.  (This lets us know when
  #   to stop checking for more rows
  # * fd_suffix - the suffix that should be used for the fields in fd_list.
  #   If the fields are in a table, this should end in an _, and the method
  #   will append row numbers as needed.
  # * table_id_col - if the fields are in a table, this should be the table's
  #   id column name (target field + '_id').  Otherwise it should be nil.
  # * max_row - if the fields are in a table, this should be the maximum row
  #   number for all of the fields (obtained from field_to_max_row).
  #
  # Returns:  A data hash if !table_name; otherwise an array of data_hashes,
  #   one for each row.  If there is no data for the given suffix, the hash
  #   (or array) will be empty.
  def load_data_hash_for_fields(form_params, fd_list, field_to_max_row,
      fd_suffix='', table_id_col=nil, max_row=1)
    rtn = []
    continue_for_next_row = true # If there is no table, we have one "row"
    1.upto(max_row) do |row_num|
      data_hash = {}
      cur_suffix = table_id_col ? fd_suffix+row_num.to_s : fd_suffix
      fields_have_non_blank_val = false
      fd_list.each do |fd|
        if (fd.control_type == 'group_hdr')
          sub_table_id_col = fd.getParam('orientation') == 'horizontal' ?
            fd.target_field.singularize + '_id': nil
          sub_suffix = cur_suffix + (sub_table_id_col ? '_' : '_1')
          sub_fields = fd.subFields
          # Determine the maximum row count for the sub field group
          # (if it is a table).
          sub_max_row = 1
          if (sub_table_id_col)
            sub_fields.each do |sf|
              field_max = field_to_max_row[sf.target_field]
              sub_max_row = field_max if field_max && field_max > sub_max_row
            end
          end
          group_data = load_data_hash_for_fields(form_params, fd.subFields,
            field_to_max_row, sub_suffix, sub_table_id_col, sub_max_row)
          if !group_data.empty?
            data_hash[fd.target_field] = group_data
            fields_have_non_blank_val = true
          end
        else
          param_key = (fd.target_field + cur_suffix).to_sym
          fd_val = form_params[param_key]
          if !fd_val.blank?
            data_hash[fd.target_field] = fd_val
            fields_have_non_blank_val = true
          end
        end
      end
      if !table_id_col # not in a table
        rtn = data_hash
        continue_for_next_row = false
      else
        # See if there is an ID value for the current row of the table.
        id_param = (table_id_col+cur_suffix).to_sym
        id_val = form_params[id_param]
        if !id_val.blank?
          data_hash[table_id_col] = id_val
          fields_have_non_blank_val = true
        end
        if data_hash.empty?
          continue_for_next_row = false
        else
          # Make sure the rows's data hash has a non-blank field in it (at least
          # a non-blank ID).  Otherwise, we will skip it.
          if (fields_have_non_blank_val)
            rtn << data_hash
          end
        end
      end
      row_num += 1
    end
    return rtn
  end


  # Expires the cache for the given system form.
  #
  # Parameters:
  # * form_name - the system form name
  def expire_form_cache(form_name)
    #expire_fragment(Regexp.new('app/'+form_name+'/', 'i'))
    form_name = form_name.downcase
    expire_fragment(Regexp.new("#{Rails.env}/(layout_)?part\\d+#{form_name}"))
    # also expires the forms which are using this form
    uforms = Form.find_by_form_name(form_name).used_by_forms
    uforms.each{|f| expire_form_cache(f.form_name)} if !uforms.empty?
  end


  # takes a full form field id and splits it into its 3 parts:
  #  prefix
  #  target_field value
  #  suffix
  # Modeled on the same function in rules.js.  6/26/08 lm.
  #
  # Parameters:
  # * form_field_id - the ID to be split
  # * has_prefix - a flag indicating whether or not the field
  #   has a prefix.  Default is true.  This is used when splitting
  #   data returned by the form, where the prefix is omitted.
  #
  # Returns: A 3 element array; elements in the order listed above
  #
  def split_full_field_id(form_field_id, has_prefix=true)

    suffix = form_field_id[/(_\d+)+\z/]
    if suffix.nil?
      suffix = ''
    end
    if has_prefix
      prefix = form_field_id[/\A[^_]+_/]
      if prefix.nil?
        prefix = ''
      end
      field_name =
        form_field_id[prefix.length..(form_field_id.length - suffix.length - 1)]
    else
      field_name = form_field_id[0,(form_field_id.length - suffix.length)]
      prefix = ''
    end
    return [prefix, field_name, suffix]
  end

  # Merge two data_hash structures, i.e. the general form's data_hash and
  # panel group's data_hash. Merge the values if the keys are same, not to
  # pick one of the values, like the merge function of Hash class.
  #
  # Parameters:
  # * data_hash1 one data_hash object
  # * data_hash2 another data_hash object
  #
  # Returns:
  # * data_hash the merged data_hash object
  def merge_data_hash(data_hash1, data_hash2)
    data_hash = {}

    data_hash1.each do |key, value|
      if data_hash2.has_key?(key)
        value2 = data_hash2[key]
        # its value is also a hash, check the key/value recursively
        # Note: by form's data_hash definition, both value and value2 should
        # have the same object type, be it either Hash or Array.
        # if not, the data_hash is not generated correctly. Check your code!
        if value2.class == Hash && value.class == Hash
          sub_data_hash = merge_data_hash(value, value2)
          data_hash[key] = sub_data_hash
        # the value is an array, (not a hash), merge the values
        else
          data_hash[key] = value.concat(value2)
        end
      # not a common key, copy the key/value to the new data_hash
      else
        data_hash[key] = value
      end
    end

    # add key/value that are in data_hash2 but not in data_hash1
    # (those are not processed above)
    data_hash2.each do |key, value|
      if !data_hash1.has_key?(key)
        data_hash[key] = value
      end
    end
    return data_hash
  end


  # This method gets a profile for the current user, using the current request
  # and session objects.
  #
  # This uses the User.require_profile method to not only obtain the profile
  # object, but to also make sure the user has the appropriate access to that
  # object.  A security error is raised if not, which should be handled by
  # the calling method.
  #
  # Parameters:
  # * action_desc a short description of the action being requested, such as
  #   "archive profile" or "get autosave data"
  # * min_access the minimum access level required for the request.  For most
  #   (but not all) requests to display a form, this would be
  #   ProfilesUser::READ_ONLY_ACCESS (using the access values defined in the
  #   ProfilesUser model class).  Some forms, such as the Add Tests & Measures
  #   (or whatever) form require at least ProfilesUser::READ_WRITE_ACCESS.
  #   And some actions, such as sharing access to a phr, require
  #   ProfilesUser::OWNER_ACCESS.
  # * id_shown the id_shown for the profile to acquire.  This may be an actual
  #   profile id, but the id_shown value is greatly preferred
  # * use_real flag indicating that the id_shown parameter is an actual id.
  #   Optional parameter.  Default value is false
  #
  # Returns:
  # * the access level currently held by the current user for the profile
  # * the requested profile, if the user has the appropriate access to it
  # OR a SecurityError for an invalid request
  #
  def get_profile(action_desc, min_access, id_shown, use_real=false)
    return @user.require_profile(get_url,
                                 request.session.id,
                                 session[:cur_ip],
                                 action_desc,
                                 min_access,
                                 id_shown,
                                 use_real)
  end # get_profile


  # This method gets the url from the current request object and removes the
  # authenticity token if one is included in the url.  This is written to be
  # used when we need to write the url to a usage stats event row, where we
  # want to store the address and any parameters other than the authenticity
  # token.
  #
  # Although it's used mostly by the get_profile method (above), it's broken
  # out separately for those places where the get_profile method is not
  # wanted, but the adjusted url is need to specify as a usage stats
  # parameter (as used in the phr home controller).
  #
  # Parameters: none
  # Returns: the adjusted url
  #
  def get_url

    # Get the url from the request object, stripping out the authenticity_token
    # if it's there.  We don't need to store that with the usage stats data,
    # but we do want to retain any other parameters.

    uri = URI(request.url)
    if (uri.query.nil?)
      the_url = request.url
    else
      query_parts = CGI::parse(uri.query)
      the_url = uri.scheme + '://' + uri.host + uri.path + '?'
      query_parts.delete('authenticity_token')
      the_url += URI.encode_www_form(query_parts)
    end
    return the_url
  end


  # This method performs the steps required to end a user session.  It is
  # used by the logout method of the login controller as well as the
  # check_for_data_overflow method in this controller.
  #
  # Parameters:
  # * end_type optional parameter used to indicate what is ending the session
  #
  def end_user_session(end_type='user_requested')

    # If we're not actually doing a logout (see handle_unverified_request)
    # don't record a logout in the usage stats

    if end_type != 'no_logout'

      if @user.nil? && !session[:user_id].nil?
        @user = current_user
        if !@profile.nil?
          # make sure the user is authorized for the current profile if
          # there is one (Paul's request)
          @access_level, @phr_record = get_profile("end_user_session",
                                                   ProfilesUser::READ_ONLY_ACCESS,
                                                   @profile.id,
                                                   true)
          profile_id = @profile.id
        else
          profile_id = nil
        end
      end

      if end_type == 'logout'
        end_type = 'user_requested'
      end

      report_params = [['logout',
                        Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                        {"type"=>end_type}]].to_json
      UsageStat.create_stats(@user,
                             profile_id ,
                             report_params,
                             request.session.id,
                             session[:cur_ip],
                             false)
    end # if no logout is being performed

    # keep the page_view that is needed for basic mode
    page_view = session[:page_view]

    # Now clear out the session info
    # Without calling this method, IE 9/10 somehow keeps the session info. So a
    # user cannot really log out.
    reset_session

#    session[:user_id] = nil
#    session[:_csrf_token] = nil
    request.env.delete('rack.session.record')
    request.env.delete('rack.request.cookie_hash')
    request.env.delete('rack.request.cookie_string')
    session[:page_view] = page_view
    @user = nil
  end # end_user_session

  # Creates a data_hash like structure (the structure used to load data into
  # the form fields by JavaScript) out of the parameters returned from a
  # form submission.
  #
  # Parameters:
  # * form_params - the hash of key/value pairs returned for a form's fields
  #   when a form is submitted (i.e., params[:fe]).
  # * form - the Form instance or form name for the form that was submitted
  #
  # Returns:  The data_hash version of the parameters.
  def data_hash_from_params(form_params, form)
    form = Form.find_by_form_name(form) if form.class == String
    # Create a hash map from target field names to the maximum row count
    # (the last suffix component) for the field name.  This will help us
    # in knowing how many rows of data to check for.
    field_to_max_row = {}
    form_params.keys.each do |k|
      k = k.to_s # k might be a symbol
      k =~ /\A(.*?)(_\d+)*_(\d+)\z/
      target_field = $1
      if (target_field)
        row_num = $3.to_i
      else
        target_field = k
        row_num = 1
      end
      max_row = field_to_max_row[target_field]
      if (!max_row || max_row < row_num)
        field_to_max_row[target_field] = row_num
      end
    end

    data_hash =
        load_data_hash_for_fields(form_params, form.top_fields, field_to_max_row)
    return data_hash
  end

end # application_controller
