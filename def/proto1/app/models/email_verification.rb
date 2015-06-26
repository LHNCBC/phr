class EmailVerification < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id
  validates_uniqueness_of :action, :scope =>[:user_id]
  validates_uniqueness_of :token

  # The expiration period for activating newly created user account
  NEW_ACCOUNT_ACTIVATION_DAYS = 7

  # Messages based on various token statuses
  TOKEN_MSGS ={
    "no_pending"=> "This user has no pending verification.",
    "blank" => "The verification token cannot be blank.",
    "invalid" => "The verification token is invalid.",
    "verified" => "The new user account has been activated successfully." }


  # Returns true if the verification token is expired and vice versa
  def expired
    created_at < NEW_ACCOUNT_ACTIVATION_DAYS.days.ago
  end


  # Verifies the input token and  returns any error message or success notice
  # Parameters:
  # * user a user record
  # * token the token to be verified
  def self.match_token(user, token)
    error_msg = flash_msg = pv = nil

    if !user.has_pending_token # including used, expired etc.
      error_msg = TOKEN_MSGS["no_pending"]
    else
      if token.blank?
        error_msg = TOKEN_MSGS["blank"]
      else
        the_token_type = user.inactive ? "new" : "other"
        pv = EmailVerification.where(:user_id => user.id, :token => token,
                                     :token_type => the_token_type, :used => false).take

        # In test mode, bypassing token matching for inactive new account with user name prefixed "bypass_activation_"
        if Rails.env == "test" && the_token_type == "new" &&  user.name.match(/\Abypass_activation_/)
          pv = EmailVerification.where(:user_id => user.id, :token_type => "new", :used => false).take
        end

        # Cannot find the token or token expired
        if !pv
          error_msg = TOKEN_MSGS["invalid"]
        end
      end
    end

    # activate user after a successful token verification
    if error_msg.nil?
      case the_token_type
      when "new" # user.inactive
        # mark user as active, mark pv as used
        User.transaction do
          user.inactive = false
          if !user.save
            error_msg = user.errors.messages.join
          else
            pv.used = true
            error_msg = pv.errors.messages.join if !pv.save
          end
          raise "Rollback" if error_msg
        end
        flash_msg = TOKEN_MSGS["verified"] if error_msg.nil?
      else
        raise "EmailVerification ID #{pv.id} has invalid token type."
      end
    end

    [error_msg, flash_msg]
  end


end
