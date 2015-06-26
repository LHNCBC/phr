class ShareInvitationController < ApplicationController

#  include SanitizeHelper
  require 'action_view/helpers/sanitize_helper'
#  include TextFieldsHelper
  require 'action_view/helpers/text_helper'
  require 'date'
  before_action :authorize, :except => [:accept_invitation]

  # The around filter to enforce that a request be made by an ajax call for
  # methods that expect it. The filter is location in the ApplicationController.
  around_action :xhr_and_exception_filter,
    only: [:create, :get_pending_share_invitations, :update_invitations]

  # Return messages; constants here so can be used in testing
  NO_INVITE_DATA_RESP =
                  "Missing invite_data parameter for share invitation request."
  NO_ID_SHOWN_RESP = "Missing id_shown parameter for share invitation request."
  NO_TARGET_NAME_RESP =
                   "Missing target_name parameter for share invitation request."
  NO_EMAIL_RESP = "Missing target_email parameter for share invitation request."
  NO_ISSUER_NAME_RESP =
                   "Missing issuer_name parameter for share invitation request."
  NO_MSG_RESP =
              "Missing personalized_msg parameter for share invitation request."
  INVALID_ID_SHOWN_RESP =
                      "Invalid id_shown parameter for share invitation request."
  NOT_OWNER_RESP = "Invalid share invitation request; not owner user."

  ALREADY_HAS_ACCESS_RESP = " already has access to this PHR."
  PENDING_INVITE_RESP = "An invitation to access this PHR has already been " +
                        "sent to %{someone} and has not yet expired."
  HAS_ACCOUNT_RESP = 'Already has account'
  NO_ACCOUNT_RESP = 'No account found'

  RUNTIME_ERR_USER_RESP = "Something has gone wrong and the invitation " +
                          "could not be sent.&nbsp;&nbsp;Our apologies.<br>" +
                          "<br>" + PhrHomeController::ERR_MSG_END
  INVALID_INVITE_ACTION_RESP = "A problem was found with an invitation " +
                               "you were responding to.&nbsp;&nbsp;Our " +
                               "apologies.<br>" + PhrHomeController::ERR_MSG_END


  # The xhr_and_exception_filter around action is specified for this
  # method in the ApplicationController.
  #
  # This handles requests from the client to send an invitation to share access
  # to a PHR.  It checks the parameters passed in and, if the request is valid,
  # calls send_invitation to send the email, and then call create_invitation in
  # the ShareInvitation model class to store data for the invitation.
  #
  # A request is considered invalid if: it is missing any of the expected
  # parameters (as noted below); if the profile id_shown passed in is invalid
  # or if the current user is not the owner of that profile; or if the user
  # being invited to share access already has access to the profile.
  # 
  # This also returns an error if one occurs while trying to send the email,
  # or if an error occurs storing the invitation data, or if the amount of data
  # stored for the user has exceeded the limits.  The data size is figured after
  # the share invitation is stored.  In the case of a data size problem, the
  # user should get a message and be logged out.
  # 
  # Parameters (in params):
  # * :id_shown the profile id_shown or the PHR to be shared
  # * :invite_data a hash containing
  #     target_email - the email to which the invitation is to be sent
  #     target_name - the name of the person who is to receive the invitation
  #     issuer_name - the name (not username, but name - which we don't keep
  #                   on file) of the person issuing the invitation
  #     personalized_msg - a personalized message if the issuer provided one.
  #   All of those elements must be supplied, although the personalized_msg
  #   may be blank (but not nil).
  #
  # Returns:
  # * success or errors, as noted above
  #
  def create
    flash.keep
    feedback = Hash.new

    id_shown = params[:id_shown]
    invite_data_str = params[:invite_data]
    if !invite_data_str.nil?
      invite_data = JSON.parse(invite_data_str)
    end
    begin

      # Only proceed if we got the parameters.
      if invite_data_str.nil? || invite_data.blank?
        raise RuntimeError, NO_INVITE_DATA_RESP
      elsif id_shown.blank?
        raise RuntimeError, NO_ID_SHOWN_RESP
      elsif invite_data["target_email"].blank?
        raise RuntimeError, NO_EMAIL_RESP
      elsif invite_data["target_name"].blank?
        raise RuntimeError, NO_TARGET_NAME_RESP
      elsif invite_data["issuer_name"].blank?
        raise RuntimeError, NO_ISSUER_NAME_RESP
      elsif invite_data["personalized_msg"].nil?
        raise RuntimeError, NO_MSG_RESP
      else
        # Get the profile and make sure this user has owner access to
        # this profile.  If the user doesn't, a security error will be raised
        # by get_profile->require_profile.  We don't need to do anything with
        # this user's access level, as we're prohibiting all access levels
        # except owner access.  But it does get returned.
        @access_level, @profile = get_profile("issue sharing invitation",
                                              ProfilesUser::OWNER_ACCESS,
                                              id_shown)
        profile_id = @profile.id
        # Check to see if there's already a pending invitation for
        # the target_email and the profile (that hasn't expired)

        pending_invite = ShareInvitation.where(
              "profile_id = ? AND date_responded is NULL " +
              "AND target_email = ? AND expiration_date > ?",
               profile_id, invite_data["target_email"], 1.day.ago)
        if !pending_invite.empty?
          ret_msg = PENDING_INVITE_RESP % {someone: invite_data["target_email"]}
        else
          # Check to see if we have a user with the target email
          target_user = User.find_by_email(invite_data["target_email"])
          # If we already have a user with the target email, make sure the
          # target user doesn't already have access to the profile.
          add_row = true
          if target_user
            has_access = target_user.profiles.find_by_id(profile_id)
            if has_access
              ret_msg = invite_data["target_name"] + ALREADY_HAS_ACCESS_RESP
              add_row = false
            else
              target_user_id = target_user.id
            end
          else
            target_user_id = nil
          end
          if add_row
            expire_date = 30.days.from_now
            # For now, all access requests are for read-only access.
            access_level_requested = ProfilesUser::READ_ONLY_ACCESS

            # first let's send the emails - to make sure they don't fail
            # need invite_data plus target_user_id - to know if needs account
            accept_key = send_invitation(@profile, invite_data, expire_date)

            # Now create the row.  Evidently using new/initialize requires
            # that we create a hash of the parameters instead of passing them
            # directly
            attributes = {:profile_id => profile_id,
                          :issuing_user_id => @user.id,
                          :target_user_id => target_user_id,   
                          :target_email => invite_data["target_email"],
                          :date_issued => DateTime.now,
                          :expiration_date => expire_date,
                          :access_level => access_level_requested,  
                          :issuer_name => invite_data["issuer_name"] ,
                          :target_name => invite_data["target_name"],
                          :accept_key => accept_key}

            ShareInvitation.new(attributes)

            u_data = {"access_level" => access_level_requested}
            report_params = [['access_invite_sent',
                              Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                              u_data]].to_json
            UsageStat.create_stats(@user,
                                   profile_id,
                                   report_params,
                                   request.session_options[:id],
                                   session[:cur_ip],
                                   false)
          end # if the target user doesn't already have access to this phr
        end # if there is not already an invitation for this request
        # Call check_for_data_overflow, which is defined in ApplicationController
        # and will run the check on the current @user object.
        check_for_data_overflow
      end # if we're not missing parameters

    # rescue any errors.  Three that we could be expecting are
    # 1.  a data overflow error - from the check above; 
    # 2.  a security error, from the check above to make sure that the
    #     current user owns the current profile; and
    # 3.  parameter errors (missing or invalid parameters).

    # For case #1 (data overflow), we want the client to log out.
    rescue DataOverflowError => ovError
      feedback['do_logout'] = true
      feedback['exception'] = 1
      feedback['exception_type'] = 'data_overflow'
      feedback['exception_msg'] = ovError.message
      flash.keep[:error] = flash.now[:error]
    rescue SecurityError => secError
      SystemError.record_server_error(secError, request, session)
      feedback['exception'] = 1
      feedback['exception_type'] = 'security_error'
      feedback['exception_msg'] = RUNTIME_ERR_USER_RESP
      if Rails.env == "test"
        feedback['security_error'] = 
        ShareInvitationController::INVALID_ID_SHOWN_RESP + ' ' + secError.message
      end      
    # Otherwise we have case #2 or #3
    rescue RuntimeError => runtime_error
      SystemError.record_server_error(runtime_error, request, session)
      feedback['exception'] = 1
      feedback['exception_type'] = runtime_error.class
        feedback['exception_msg'] = RUNTIME_ERR_USER_RESP
      if Rails.env =="test"
        feedback['runtime_error'] = runtime_error.message
      end
    rescue Exception => other_error
      SystemError.record_server_error(other_error, request, session)
      feedback['exception'] = 1
      feedback['exception_type'] = other_error.class
      feedback['exception_msg'] = other_error.message
    end # begin

    if !feedback['exception'].nil?
      render :status => 500,
             :json => feedback.to_json
    else
      render :status => 200,
             :json => ret_msg
    end
  end # create


  # This handles an acceptance of a shared access invitation.  It first checks
  # the validity of the acceptance.   An acceptance is considered invalid if
  #  - the invitation cannot be found using the accept_key value passed to
  #    this as part of the url;
  #  - the 'sent to' email address returned in the url does not match the
  #    one on file to which the invitation was sent;
  #  - the invitation has already been accepted; or
  #  - the invitation has expired.
  #
  #  In any of those cases the user is presented with a page noting the problem
  #  and further processing ceases.
  #
  # If the acceptance is valid, the system determines whether or not the
  # user currently has an account with the system.  If not, the invitee is
  # presented with the registration/Sign Up page.  The text for the popup
  # message that is displayed over the registration page explains that an
  # account must be created before the access can be granted.  The access
  # is not actually implemented until after the registration process is
  # completed, by other code that is called.
  #
  # If the invitee already has an account with the system, a page is displayed
  # that confirms the access and provides a link to login if the invitee wishes
  # to do so.  In this case the access is implemented (set up in the database).
  #
  # Parameters (in params):
  # * :email the email address returned; should be the one to which the
  #    invitation was sent
  # * :invite_data the accept_key which was generated when the invitation was
  #    created
  #   Both of those elements must be supplied.
  #
  # Returns:
  # * success or errors, as noted above
  #
  def accept_invitation

    @sent_to = params[:email]
 
    # Get the invitation data from the database
    @show_header = false
    @banner_class = "full_banner"
    invite = ShareInvitation.where("accept_key = ? AND target_email = ?",
                                   params[:invite_data], @sent_to).take

    # Process an invalid invitation request.  This would happen if the user
    # messed with the parameters or if they typed in an incorrect url.
    if invite.nil? || invite.target_email != @sent_to
      render(:layout=>'nonform', :action=>'reject_accept')

    # Process a request for an invitation that's already been accepted
    elsif !invite.date_responded.nil? && invite.response != 'expired'
      @response_date = invite.date_responded.strftime("%A, %B %-d, %Y at %l:%M %P")
      @host = request.host
      @action = invite.response
      render(:layout=>'nonform', :action=>'previously_responded')

    # Process an invitation that has expired
    elsif invite.expiration_date <= 1.day.ago
      @issuer_name = invite.issuer_name
      @prof_name_possessive = 
                      Profile.find_by_id(invite.profile_id).phr.pseudonym + "'s"
      @expire_date = invite.expiration_date.strftime("%A, %B %-d, %Y")
      render(:layout=>'nonform', :action=>'invite_expire')

    # Process a valid invitation
    else
      @prof_name_possessive = 
                      Profile.find_by_id(invite.profile_id).phr.pseudonym + "'s"

      # Process an invitation for someone who does not have an account
      # Send the user to the registration page, and set the page so that the
      # email address must be the sent_to address.  Include an alert message
      # letting them know they need an account
      if invite.target_user_id.nil?

        @page_load_data = {"email_val" => invite.target_email,
                           "msg_title" => "Thanks for your interest!  " +
                                          "Please create an account",

                           "msg" => "<p>You will need a PHR account to access " +
             @prof_name_possessive + " health information.  Please complete " +
                 "our Sign Up form to create an account.*  At any time you " +
                 "can then: " +
                 "<ol><li>Log in with your new username and password; and</li>" +
                  "<li>View " + @prof_name_possessive + " health information " +
                       "from the PHR Home page that will be displayed.</li>" +
              "</ol></p>" +
              "<p>You can also use this account for your own PHR.</p>" +
              "<p>* The email address that your invitation was sent to is " +
              "already shown in the email address section.  For security " +
              "purposes, you will not be able to change it on this form.</p>" +
              "<p>If you already have an account registered with a different " +
              "email address, please ask " + invite.issuer_name + " to send " +
              "you an invitation at that address.",
                           "invite_key" => invite.accept_key
        }
        @action_url = "/accounts/new"
        @exp_account_name = EXP_ACCOUNT_NAME # needed to render a default_value
        @form = Form.where(:form_name=>'signup').take
        @form_subtitle = @form.sub_title.html_safe
        render_form('signup')
      else
        # Process an invitation to someone who already has an account
        # - create the access and then let the user know it's been created
        target_user_obj = User.find_by_id(invite.target_user_id)
        ShareInvitationController.implement_access(target_user_obj,
                                                   invite, nil)
        @access_level = ProfilesUser::ACCESS_TEXT[invite.access_level - 1]
        @prof_name_possessive = 
                      Profile.find_by_id(invite.profile_id).phr.pseudonym + "'s"
        @host = request.host
        @system_name = PHR_SYSTEM_NAME
        render(:layout=>'nonform', :action=>'current_user_acceptance')

      end # if the invitee does not/does already have an account
    end # if we found the invitation
  end # accept_invitation


  # This handles completion of the process of granting shared access to a phr
  # for someone who did not have an account.  This is called after the user
  # has successfully created an account as requested when they accepted the
  # invitation.  It updates the share_invitations table to show that the
  # invitation was accepted and updates the profiles_users table to create
  # the access connection.  It is also called when a user who already has an
  # account accepts the invitation.
  #
  # This also calls send_invitation_accepted to send an email to the owner of
  # the PHR being shared, to let them know that the invitation was accepted
  #
  # Parameters:
  # * user_id the id of the user (object) for which access is being implemented
  # * invite the invitation being accepted.  May be nil, in which case the
  #          invite_key is used to get the invitation
  # * invite_key the key for the invite being accepted.  Specified when the
  #           invitation is not supplied
  #
  # Returns: nothing
  #
  def self.implement_access(user_obj, invite=nil, invite_key=nil)
    if invite.nil?
      invite = ShareInvitation.where(accept_key: invite_key).take
    end
    invite.grant_access(user_obj)
    ShareInvitationController.send_invitation_accepted(invite)
  end # implement_access


  # This is called when a user explicitly declines an invitation via the
  # pending invitations list.
  #
  # This calls the ShareInvitation model class method to mark the invitation
  # as declined and calls send_invitation_accepted to send an email to the
  # owner of the PHR being shared, to let them know that the invitation was
  # declined.
  #
  # Parameters:
  # * user_id the id of the user (object) for which access is being declined
  # * invite the invitation being declined.  May be nil, in which case the
  #          invite_key is used to get the invitation
  # * invite_key the key for the invite being declined.  Specified when the
  #           invitation is not supplied
  #
  # Returns: nothing
  #
  def self.access_declined(user_obj, invite=nil, invite_key=nil)
    if invite.nil?
      invite = ShareInvitation.where(accept_key: invite_key).take
    end
    invite.decline_access(user_obj)
    ShareInvitationController.send_invitation_declined(invite)
  end # access_declined


  # When a share invitation is accepted, this is called to send an email to the
  # owner of a PHR being shared, to let them know that the invitation was
  # accepted.
  #
  # Parameters:
  # * invite the invitation being accepted.
  #
  # Returns: nothing
  #
  def self.send_invitation_accepted(invite)
    sender = User.find_by_id(invite.issuing_user_id)
    profile = Profile.find_by_id(invite.profile_id)
    prof_name_possessive = profile.phr.pseudonym + "'s"
    DefMailer.invitation_accepted(sender.email,
                                  invite.issuer_name,
                                  invite.target_name,
                                  invite.target_email,
                                  prof_name_possessive,
                                  SHARE_INVITE_FROM_LINES.html_safe).deliver
  end # send_invitation_accepted


  # When a share invitation is explicitly declined, this is called to send an
  # email to the owner of a PHR being shared, to let them know that the
  # invitation was declined.
  #
  # Parameters:
  # * invite the invitation being declined.
  #
  # Returns: nothing
  #
  def self.send_invitation_declined(invite)
    sender = User.find_by_id(invite.issuing_user_id)
    profile = Profile.find_by_id(invite.profile_id)
    prof_name_possessive = profile.phr.pseudonym + "'s"
    DefMailer.invitation_declined(sender.email,
                                  invite.issuer_name,
                                  invite.target_name,
                                  invite.target_email,
                                  prof_name_possessive,
                                  SHARE_INVITE_FROM_LINES.html_safe).deliver
  end # send_invitation_declined


 


  # This gets a list of pending shared access invitations for the current user.
  # The xhr_and_exception_filter around action is specified for this
  # method in the ApplicationController.
  #
  # Parameters:
  # * none - list is generated for the current user
  # 
  # Returns:
  # * the output from the _pending_invites_field template, which is used to
  #   display the list.
  #
  def get_pending_share_invitations
    @pending_invites_list = ShareInvitation.where(
          'target_email = ? and date_responded is NULL and expiration_date > ?',
                                 @user.email, 1.day.ago)
    @list_size = @pending_invites_list.size
    if @list_size == 1
      @invite_desc = "an invitation"
      @plural = ''
    else
      @invite_desc = @list_size.to_s + ' invitations'
      @plural = 's'
    end
    render :partial => 'form/pending_invites_field.rhtml',
           :handlers => [:erb]

  end # get_pending_share_invitations


  # This updates pending invitations for the current user based on actions
  # (accept or decline) the user specifies on the pending invitations list
  # available from the phr home page.
  #
  # The xhr_and_exception_filter around action is specified for this
  # method in the ApplicationController.
  #
  # Parameters:
  # * invite_actions passed as a parameter in the http request.  This is a
  #   hash where the key is the profile_id in question, and the value is the
  #   action (accept or decline) specified by the user.
  #
  # Returns:
  # * a hash with two elements
  #    * key = acceptances; value = number of acceptances processed
  #    * key = has_pending; value = boolean indicating whether or not the
  #      user has remaining pending invitations.
  #   These two values are used to update the phr_home page as appropriate
  #   on return from this action.
  def update_invitations
    feedback = {}
    ret = {}
    ret['acceptances'] = 0
    ret['has_pending'] = true
    begin
      actions_str = params[:invite_actions]
      actions = JSON.parse(actions_str)
      actions.each_pair do |prof_id, action|
        invite = ShareInvitation.where('target_email = ? AND ' +
                                       'date_responded is NULL AND ' +
                                       'profile_id = ? AND expiration_date > ?',
                                        @user.email, prof_id, 1.day.ago).take
        if (!invite.nil?)
          if action == 'accept'
            ShareInvitationController.implement_access(@user, invite)
            ret['acceptances'] += 1
          else
            ShareInvitationController.access_declined(@user, invite)
          end
        else
          raise RuntimeError, INVALID_INVITE_ACTION_RESP
        end
      end # do for each action
    rescue RuntimeError => runtime_error
      SystemError.record_server_error(runtime_error, request, session)
      feedback['exception'] = 1
      feedback['exception_type'] = runtime_error.class
        feedback['exception_msg'] = RUNTIME_ERR_USER_RESP
      if Rails.env =="test"
        feedback['runtime_error'] = runtime_error.message
      end
    rescue Exception => other_error
      SystemError.record_server_error(other_error, request, session)
      feedback['exception'] = 1
      feedback['exception_type'] = other_error.class
      feedback['exception_msg'] = other_error.message
    end # begin

    if !feedback['exception'].nil?
      render :status => 500,
             :json => feedback.to_json
    else
      ret['has_pending'] =
          ShareInvitation.has_pending_share_invitations?(@user.email)
      render json: ret, status: :ok
    end
  end # update_invitations
  
 
  # This method handles sending the sharing invitation via email.  It assembles
  # the email from the parameters supplied and passes it along to the DefMailer
  # model to actually send the email.
  #
  # The only parameters supplied by the user are those that are not available
  # from the server directly.  (Expiration date, system name, "from" lines, as
  # well as the body of the email itself are all available from the server).
  # This is to avoid possible injection attacks as much as possible.  Note that
  # the full message is also run through the sanitize method in the
  # ActionView SanitzeHelper.
  #
  def send_invitation(profile, invite_data, expire_date)

    # Get the body of the message from the field_description row for the
    # standard_msg that's displayed on the send invitation form presented to
    # the user.

    fm = Form.find_by form_name: 'phr_home'
    mfld = FieldDescription.find_by form_id: fm.id, target_field: 'standard_msg'
    msg = mfld.default_value
    lfld = FieldDescription.find_by form_id: fm.id, target_field: 'dummy_accept_btn'
    link_text = lfld.display_name

    # Set up a hash that associates data with span ids in the message
    span_data = {
      "target_name" => invite_data["target_name"],
      "issuer_name" => invite_data["issuer_name"],
      "issuer_name2" => invite_data["issuer_name"],
      "issuer_id" => @user.name,
      "msg_prof" => profile.phr.pseudonym + "'s",
      "phr_system_name" => PHR_SYSTEM_NAME ,
      "expire_date" => expire_date.strftime("%A, %B %-d, %Y") ,
      "from_lines" => SHARE_INVITE_FROM_LINES }

    # If the user didn't specify a personal message, cut the email off after the
    # "from" lines.  Otherwise add it to the span_data hash
    if invite_data["personalized_msg"].empty?
      end_pt = msg.index('<div id="personal_msg"')
      msg = msg[0, end_pt]
    else
      span_data["personalized_msg"] = invite_data["personalized_msg"]
    end

    # Substitute the hash data for the span elements in the message
    span_data.each do |span_id, insert_value |
      span_string = '<span id="' + span_id + '"></span>'
      msg = msg.gsub(span_string, insert_value)
    end

    # Generate an accept_key using the current @user object and pass it
    # along with the message.  We'll also return it to be stored in the
    # share_invitations row created for this invitation.
    accept_key = @user.generate_random_str

    # Call DefMail.share_invitation to send the actual message.   The body
    # of the message is sanitized via a call in share_invitation.rhtml.erb,
    # but be sure to sanitize the email address before sending it on (since
    # it's not in the body of the email).
    DefMailer.share_invitation(view_context.sanitize(invite_data["target_email"]),
                               msg, accept_key, link_text, request.host).deliver
    return accept_key
  end # send_invitation

end # share_invitation_controller
