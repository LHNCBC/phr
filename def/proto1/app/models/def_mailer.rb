class DefMailer < ActionMailer::Base

  default :from => "TBD - YOUR EMAIL FOR REPLIES",
    :date => Proc.new { Time.now },
    :content_type => "text/html"

  # Used for creating a general email message.
  #def message(email_addr, subject, message)
  # "message" is a reserved method, see delivery_methods.rb#83)
  def build_message(email_addr, subject, message)
    mail(:to => email_addr, 
         :from => TBD - YOUR_SUPPORT_EMAIL ,
         :subject => subject) do |format|
       format.text { render :plain => message }
    end
  end

  def deliver_message(email_addr, subject, message)
    build_message(email_addr, subject, message).deliver_now
  end

  # Used for creating a message for sending a user their login ID.
  def uid_notice(user_id, email_addr)
    @user = user_id
    subject =  'Confirmation of your Personal Health Record (PHR) Account ID'
    mail(:to => email_addr, :subject => subject)
  end


  # Used for creating a message for sending a user their login ID.
  def reset_link(user_name,reset_key,email_addr)
    subject = 'Personal Health Record (PHR) password and security questions'
    @reset_key = reset_key
    @user = user_name
    mail(:to => email_addr, :subject => subject)
  end


  # Sends a link via email for activating a newly registered account
  def verify_reg_email(user_name, email_token, email_addr)
    subject = "Action Required – Click the New User Activation Link to Complete Your PHR Registration"
    @user_name = user_name
    @email_token = email_token
    @email_addr = email_addr
    mail(:to => email_addr, :subject =>subject )
  end


  # Used for creating a message for contacting support.
  #
  # Parameters:
  # * support_email_addr - the email address for PHR support
  # * form_data - a hash of variables and values from the contact form
  # * host - this server's hostname
  def contact_support(support_email_addr, form_data, host)
    subject = "Personal Health Record (PHR) Feedback"
    @form_data = form_data
    @host = host
    mail(:to => support_email_addr, :subject => subject)
  end


  # Used for creating a message for notifying user of profile update .  This
  # gets called for changes from the account settings page and for updates
  # via the "forgot password" link.
  def profile_update(user_name, email_addr)
    subject = 'Your Personal Health Record (PHR) account settings have been changed'
    @user = user_name
    mail(:to => email_addr, :subject => subject)
  end


   # Used for creating a message for notifying user of a password reset
  def password_reset(user_name,email_addr)
    subject = 'Your Personal Health Record (PHR) password has been changed'
    @user = user_name
    mail(:to => email_addr, :subject => subject)
  end


  # Used to send a message inviting someone to share access to a phr.
  #
  # Parameters:
  # * invitee_email_addr - the email address for person being invited
  # * form_data - the message txt
  # * accept_key - the key used to find the invitation on acceptance
  # * link_text - wording for the link used to accept the invitation
  # * host - this server's hostname
  def share_invitation(invitee_email_addr, form_data, accept_key, link_text, host)
    subject = "Invitation to Share Personal Health Record (PHR) Information"
    @form_data = form_data
    @sent_to = invitee_email_addr
    @accept_key = accept_key
    @link_text = link_text
    @host = host
    mail(:to => invitee_email_addr, :subject => subject)
  end


  # Used to send a message letting a phr owner know that an invitation
  # to share access has been accepted
  #
  # Parameters:
  # * issuer_email - the email address of the person who sent the invitation
  # * issuer_name - the name of the person who sent the invitation
  # * target_name - the name of the person who received the invitation
  # * target_email - the email address to which the invitation was sent
  # * prof_name_possessive - the name of the profile to be shared, in
  #   possessive form
  #   from_lines the "from" lines for the email
  def invitation_accepted(issuer_email,
                          issuer_name,
                          target_name,
                          target_email,
                          prof_name_possessive,
                          from_lines)
    subject = "Your Invitation was Accepted"
    @issuer_name = issuer_name
    @target_name = target_name
    @target_email = target_email
    @prof_name_possessive = prof_name_possessive
    @from_lines = from_lines
    mail(:to => issuer_email, :subject => subject)
  end


  # Used to send a message letting a phr owner know that an invitation
  # to share access has been declined
  #
  # Parameters:
  # * issuer_email - the email address of the person who sent the request
  # * issuer_name - the name of the person who sent the invitation
  # * target_name - the name of the person to who received the invitation
  # * target_email - the email address to which the invitation was sent
  # * prof_name_possessive - the name of the profile to be shared, in
  #   possessive form
  #   from_lines the "from" lines for the email
  def invitation_declined(issuer_email,
                          issuer_name,
                          target_name,
                          target_email,
                          prof_name_possessive,
                          from_lines)
    subject = "Your Invitation was Declined"
    @issuer_email = issuer_email
    @issuer_name = issuer_name
    @target_name = target_name
    @target_email = target_email
    @prof_name_possessive = prof_name_possessive
    @from_lines = from_lines
    mail(:to => issuer_email, :subject => subject)
  end
end
