# User class for all accounts (both users and administrators)
class User < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods

  require 'email_validator.rb'
  require 'cgi'
  require 'uri'
  require 'securerandom'
  
#  has_and_belongs_to_many :profiles
#  has_and_belongs_to_many :active_profiles, -> { where(archived: 0).includes("phr")}, class_name: 'Profile'
#  has_and_belongs_to_many :archived_profiles, -> { where(archived: 1).includes("phr")}, class_name: 'Profile'
#  has_and_belongs_to_many :other_profiles, -> { where(archived: 0).includes("phr")}, class_name: 'Profile'
  has_many :profiles_users
  has_many :read_only_profiles, -> { readonly }, through: :profiles_users, :source => :profile
  has_many :profiles, through: :profiles_users
  has_many :owned_profiles, -> {where(access_level: ProfilesUser::OWNER_ACCESS)}, class_name: 'ProfilesUser'
  has_many :active_profiles, -> {where(archived: 0).includes("phr")}, through: :owned_profiles, :source => :profile
  has_many :archived_profiles, -> {where(archived: 1).includes("phr")}, through: :owned_profiles, :source => :profile
  has_many :shared_profiles, -> {where.not(access_level: ProfilesUser::OWNER_ACCESS)}, class_name: 'ProfilesUser'
  has_many :other_profiles, -> {where(archived: 0).includes("phr")}, through: :shared_profiles, :source => :profile
  has_and_belongs_to_many :accessible_profiles, -> { where(archived: 0).includes("phr")}, class_name: 'Profile'
  has_many :two_factors, dependent:  :destroy
  has_many :question_answers, dependent:  :destroy
  has_many :usage_stats
  has_many :phrs, :through => :profiles
  has_many :email_verifications
  
  # set the regular usertype as 5, and set the openid user type as 6
  USERTYPE_REGULAR = 5
  USERTYPE_OPENID = 6
  
  TOTAL_DATA_SIZE_LIMIT = 400 * 1000000  # MB using the computer storage value
  DAILY_DATA_SIZE_LIMIT =  10 * 1000000
  
  # The max_trial meaning the maximum trial of login operation.
  MAX_TRIAL = 3

  # An error message for invalidly formatted email addresses
  INVALID_EMAIL_FORMAT =
    'The email address is not a valid format for an email address.'

  @@invalid_account = "Invalid password for the account ID."
  @@max_login_exceed = "Your login attempts"+
            " exceeded the maximum allowed. To protect your account, further "+
            " attempts are not allowed for one hour. Please try again"+
            " after one hour or contact support."
  @@max_verify_exceed = "Your password verification attempts"+
            " exceeded the maximum allowed. To protect your account, further "+
            " attempts are not allowed for one hour. Please try again"+
            " after one hour or contact support."
  @@email_unique = "This email address is already associated with an account.
             Please enter another email address."
  @@inactive_account_email="Looks like you already created a new account using the same email address." +
            " Please check your email box to activate the new account."+
            " You can delete the account if you don't need it."
  
  DATA_LIMIT_EXCEEDED = 'The amount of data stored for this account exceeds ' +
            'the amount of data this system can handle.  ' +
            'This account has been locked so that we can research ' +
            'the problem and determine a solution.  ' +
            'Please use the "PHR Support" form (link at the bottom of the ' +
            'LOGIN page) to get in touch with us about this problem.'
  INVALID_LOGIN = 'The account ID and password combination is invalid.'
  INACTIVE_ACCOUNT = "The user account is inactive. Please check your email and follow the direction to activate it."

  # Arrays of table names for tables linked directly or indirectly to the user
  # object.  These are set up as class accessor methods, rather than as class
  # variables, so that they can be accessed outside of the class.  At the moment
  # they are accessed by the unit tests.  See the tests of the
  # remove_expired_accounts method.

  # Tables that are linked to the user via the user_id. PLEASE KEEP THESE IN
  # ALPHABETICAL ORDER!!  thanks.
  def self.user_id_tables
    return ['autosave_tmps', 'question_answers', 'user_preferences']
  end

  # Tables that are linked to the user's profile(s) via the profile_id. PLEASE
  # KEEP THESE IN ALPHABETICAL ORDER!!  thanks.
  def self.profile_id_tables
    return ['date_reminders', 'obr_orders', 'obx_observations', 'phr_allergies',
      'phr_conditions', 'phr_doctor_questions', 'phr_drugs',
      'phr_immunizations', 'phr_medical_contacts',
      'phr_surgical_histories', 'phrs', 'reminder_options']
  end
     
  # Error messages used by user account creation validations.  These also are
  # set up as class accessor methods, rather than as class variables, so that
  # they can be accessed outside of the class.  At the moment they're accessed
  # by the unit test - as in User.missing_userid_msg.
  def self.missing_userid_msg
    return 'A PHR Account ID must be specified.'
  end

  def self.duplicate_userid_msg
    return 'The specified Account ID is already being used.  Please specify ' +
      'a different username.'
  end

  def self.duplicate_openid_msg
    return 'The specified identity URL is already being used.  Perhaps you ' +
      'have already created an account?'
  end

  def self.invalid_userid_msg
    return ('Invalid Account ID.  The PHR Account ID must:<ul>' +
      '<li>be at least 6 characters and at most 32 characters long; and</li>' +
      '<li>start with a letter (upper or lower case). </li></ul>' +
      'Account IDs may contain characters from these 3 categories:<ol>' +
      '<li>upper case letters (A-Z);</li>' +
      '<li>lower case letters (a-z);</li>' +
      '<li>digits (0-9).</li></ol>' +
      'Account IDs may not contain any special characters EXCEPT for ' +
      'underscores (_).  Spaces are not allowed.').html_safe
  end

  def self.need_both_passwords_msg
    return 'You must specify a password and then retype it in the second ' +
      'password box.  One or both of those entries are missing.'
  end

  def self.passwords_must_match_msg
    return 'Your password and the password confirmation do not match.  ' +
      'Remember that they are case sensitive (A does not equal a).'
  end

  def self.invalid_password_msg
    return ('Invalid password.  A PHR Password must:<ul>' +
      '<li>be between 8 characters and 32 characters long;</li>' +
      '<li>contain at least one character from 3 out of these 4 ' +
      'categories:<ol>' +
      '<li>upper case letters (A-Z);</li>' +
      '<li>lower case letters (a-z);</li>' +
      '<li>digits (0-9); and</li>' +
      '<li>special characters (! _ *, etc).</li></ol></li></ul>').html_safe
  end

  def self.need_both_predef_questions_msg
    return 'You must select two different security questions from the ' +
      'predefined list. One or both are missing.'
  end

  def self.predef_questions_must_not_match_msg
    return ('You must pick two <i>different</i> predefined security ' +
      'questions - not the same question twice.').html_safe
  end

  def self.need_both_predef_answers_msg
    return 'Answers are required for both of the predefined security ' +
      'questions.  One or both are missing.'
  end

  def self.self_questions_must_not_match_msg
    return ('You must create two <i>different</i> security questions - not ' +
      'the same question twice.').html_safe
  end

  def self.need_self_question_msg
    return 'The required security question is missing.'
  end
  
  def self.need_self_answer_msg
    return 'The required answer for the self-created security ' +
      'question is missing.'
  end

  def self.email_addresses_must_match_msg
    return 'The two email addresses that you entered do not match.  They ' +
      'need to match.'
  end

  def self.invalid_email_address_msg
    return 'The format of the email address you entered is invalid.  It '  +
      'should start with a username, which should be followed ' +
      'by an ampersand (@), which should be followed by your email ' +
      "provider's domain name (e.g. nih.gov)"
  end

  before_validation Proc.new { |user| 
    user.email.downcase! if !user.email.blank?
    user.email_confirmation.downcase! if !user.email_confirmation.blank?
  }
  validates_presence_of   :name, :message => self.missing_userid_msg
  validates_uniqueness_of :name, :message => self.duplicate_userid_msg,
    :case_sensitive=>false
  validates_format_of :name,
    :with=> Regexp.new(USER_NAME_REGEX),
    :message=> User.invalid_userid_msg, :if => Proc.new { |user|
    !user.name.blank? && user.name_changed? }
  validate :password_and_confirmation_checks, :unavailable_email_checks
#  validates :password, :confirmation=>{:message=>User.passwords_must_match_msg},
#    :presence=>{:message=>User.need_both_passwords_msg},
#    :if=>Proc.new{|u| u.hashed_password_changed? || u.new_record?}

#  validates :password, :presence=>{:message=>User.need_both_passwords_msg},
#    :if=>Proc.new{|u| u.hashed_password_changed? || u.new_record?}
#  validates :password, :confirmation=>{:message=>User.passwords_must_match_msg},
#    :if=>Proc.new{|u| !u.password.blank? && !u.password_confirmation.blank? &&
#      (u.hashed_password_changed? || u.new_record?)}
#  validates :password_confirmation,
#    :presence=>{:message=>User.need_both_passwords_msg},
#    :if=>Proc.new{|u| u.hashed_password_changed? || u.new_record?}
#  validates_format_of :pin, :with=>/\A\d\d\d\d\Z/, :if=>Proc.new {|u| u.pin_changed? || u.new_record?}
#  validate :validate_birth_date, :if=>Proc.new {|u| u.birth_date_changed? || u.new_record?}

  validates :email, :presence=>true
  attr_accessor :email_confirmation
  validates_confirmation_of :email,
    :message=>User.email_addresses_must_match_msg

  validates_format_of :email,
      :with=> Regexp.new(EMAIL_REGEX),
      :message=> EMAIL_ERROR_MESSAGE, :if=>Proc.new {|u| u.email_changed? || u.new_record?}
#  validates_format_of :email,
#    :with=>/\A([a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z])?\Z/,
#    :message=>INVALID_EMAIL_FORMAT, :if=>Proc.new {|u| u.email_changed? || u.new_record?}
  before_create  :pending_new_account_for_activation

  # Initializes a new instance.
  #
  # Parameters:
  # * attrs - the attribute hash.  We check this with a white list.
  def initialize(attrs={})
    attrs = {} if !attrs # attrs might be nil
    super
    self.usertype = USERTYPE_REGULAR
    self.password_trial = 0
    self.lasttrial_at = Time.now
    self.admin = 0 # For security, we always set this to false initially
    self.salt = new_salt
    
    if !attrs[:expiration_date] && attrs[:account_type] == 'E'
      attrs[:expiration_date] = Time.now.advance(:days => 30)
    end

    # DO NOT add admin to this list!
#    allowed_fields = [:name, :password, :email, :email_confirmation,
#      :birth_date, :pin, :expiration_date, :account_type]
    allowed_fields = [:name, :password, :password_confirmation,
                      :email, :email_confirmation, :expiration_date]
    allowed_fields.each do |field|
      val = attrs[field]
      self.send(field.to_s+'=', val) if val
    end
  end


  # This method creates a random string to encrypt the password
  #
  # Returns:  random string
  def new_salt
    # (Moved from LoginController)
    object_id.to_s + rand.to_s
  end


  # Validates the date of birth field
#  def validate_birth_date
#    date_reqs = self.class.date_requirements(['birth_date'], 'signup')
#    validate_date('birth_date', date_reqs['birth_date'])
#  end


  # Checks to see whether or not this user is the owner of the
  # specified profile.
  #
  # Parameters:
  # * profile_id the id of the profile to check
  #
  # Returns: true/false to indicate ownership
  #
  def has_owner_access?(profile_id)
    begin
      ret = ProfilesUser.where("user_id = ? AND profile_id = ?",
                               self.id, profile_id)[0].access_level ==
                                                  ProfilesUser::OWNER_ACCESS
    rescue Exception
      # assume user has no connection to the profile and thus no
      # access_level value.
      ret = false
    end # begin
    return ret
  end


  # Returns the code value for level of access this user has for the
  # specified profile.
  #
  # Parameters:
  # * profile_id the id of the profile to check
  #
  # Returns: access indicator, as defined in ProfilesUser
  #
  def access_level(profile_id)
    begin
      ret = ProfilesUser.where("user_id = ? AND profile_id = ?",
                               self.id, profile_id)[0].access_level
    rescue Exception
      # assume user has no connection to the profile and thus no
      # access_level value.
      ret = nil
    end # begin
    return ret
  end


  # Returns the text value for level of access this user hs for the
  # specified profile.
  #
  # Parameters:
  # * profile_id the id of the profile to check
  #
  # Returns: access indicator, as defined in ProfilesUser
  #
  def access_level_text(profile_id)
    begin
      ret = ProfilesUser::ACCESS_TEXT[self.access_level(profile_id) - 1]
    rescue Exception
      # assume user has no connection to the profile and thus no
      # access_level value.
      ret = nil
    end # begin
    return ret
  end


  # Checks to see whether or not this user is the owner of the
  # specified profile.
  #
  # Parameters:
  # * profile_id the id of the profile to check
  #
  # Returns: true/false to indicate ownership
  #
  def has_owner_access?(profile_id)
    begin
      ret = self.access_level(profile_id) == ProfilesUser::OWNER_ACCESS
    rescue Exception
      # assume user has no connection to the profile and thus no
      # access_level value.
      ret = false
    end # begin
    return ret
  end


  # Returns the user's data records of the given table type, but the type of the
  # returned objects is the model class for the table type (e.g. Phr).
  #
  # Parameters
  # * table_name - the name of the data table.
  # * conditions - some field/value pairs to add as conditions for selecting the
  #   returned model class objects.  Field values in the returned records must
  #   match (exactly) the specified conditions.
  # * opt - other options
  #
  # Returns:  The data records for the given user (as instances of the table
  # model class) or an empty array if there are none.
  def typed_data_records(table_name, conditions={}, opt={})
    # String value is case sensitive in Oracle Get the user's profile IDs
    if !conditions.nil? && !conditions[:profile_id].nil?
      profile_ids = conditions[:profile_id]
    else
      #profile_ids = self.profiles.collect {|p| p.profile_id}
      profile_ids = self.profiles.collect {|p| p.id}
    end
    rtn = []
    if (profile_ids.size > 0 && !table_name.nil?)
      begin
        table_cls = table_name.singularize.camelize.constantize
        # Take this opportunity to define an id_shown method on the table class,
        # so that instances can know what that value is (e.g. for
        # data_req_output)
        if !table_cls.respond_to?('id_shown')
          table_cls.class_eval do
            belongs_to :profile

            def id_shown
              profile.id_shown
            end
          end
        end
        # if condition[:latest] comes in as a argument, either all or true/false
        #  conditions[:latest] = true by default.
        if conditions[:latest] == 'All'
          conditions.delete(:latest)
        else
          conditions[:latest] = true unless !conditions[:latest].nil?
        end
        conditions[:profile_id] = profile_ids
        # convert the conditions into a string, since there's a "obx_count"
        # that's is a string, and can't be written in a hash format
        if !conditions[:obx_count].nil?
          sql_conditions =[conditions[:obx_count]]

          if !conditions[:latest].nil?
            sql_conditions[0] += " AND latest=?"
            sql_conditions << conditions[:latest]
          end
          if !conditions[:profile_id].blank?
            sql_conditions[0] += " AND profile_id IN(?)"
            sql_conditions << conditions[:profile_id]
          end
          opt[:conditions] = sql_conditions
        else
          opt[:conditions] = conditions
        end
        
        options = opt.clone
        c = options.delete(:conditions)
        o = options.delete(:order)
        s = options.delete(:select)
        g = options.delete(:group)
        if !options.keys.empty?
          raise "These SQL keywords \"#{options.keys.join(" ")}\" are missing"+
          " in the final sql query." 
        end
        rtn = table_cls.where(c)
        rtn = rtn.send(:order, o) if o
        rtn = rtn.send(:select, s) if s
        rtn = rtn.group(g) if g
      rescue NameError => error_msg
        logger.debug '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        logger.debug 'NameError exception thrown in User.typed_data_records.'
        logger.debug '  table_name = ' + table_name
        logger.debug '  conditions = ' + conditions.to_json
        logger.debug '  opt = ' + opt.to_json
        logger.debug error_msg.backtrace.join("\n")
        logger.debug '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      end
    end
    return rtn
  end # typed_data_records

  # Returns true if the user has archived profiles and vice versa
  def has_archived_phr_records
    archived_profiles.length > 0
  end

  # Returns true if the user has active profiles and vice versa
  def has_active_phr_records
    active_profiles.length > 0
  end

  # Returns true if the user has shared profiles and vice versa
  def has_shared_phr_records
    shared_profiles.size > 0
  end


  # Returns the requested profile if the user has permission to see it.
  # An exception is thrown if the given profile ID is not one that belongs
  # to the user (regardless of whether such a profile exists at all).
  #
  # In general, you should not call this directly.  Use the get_profile
  # method in the application_controller.  Much easier.
  #
  # Parameters:
  # * req_url - the url extracted from the http request and stripped of the
  #   the authentication token
  # * session_id - the session id for the current session
  # * ip_addr - the ip_address for the request originator
  # * action_desc - a short description of the calling action
  # * min_access - the minimum access level required for the request.  For most
  #   (but not all) requests to display a form, this would be
  #   ProfilesUser::READ_ONLY_ACCESS (using the access values defined in the
  #   ProfilesUser model class).  Some forms, such as the Add Tests & Measures
  #   (or whatever) form require at least ProfilesUser::READ_WRITE_ACCESS.
  #   And some actions, such as sharing access to a phr, require
  #   ProfilesUser::OWNER_ACCESS.
  # * prof_id - the id_shown attribute of the profile, unless the second
  #   parameter is provided and is true, in which case this is the "id"
  #   attribute of the profile record.  (In most cases we use id_shown,
  #   because we don't want the real id getting to the browser.)
  # * use_real_id - whether id_shown is actually the id rather than id_shown.
  #
  # Returns:
  # * access_level the level of access this user has for the profile
  # * profile the profile object
  # OR raises a SecurityError for an invalid request
  #
  def require_profile(req_url, session_id, ip_addr,
                      action_desc, min_access, prof_id, use_real_id=false)

    # Make sure we have the parameters required
    if prof_id.nil? || action_desc.nil? || min_access.nil? ||
       req_url.nil? || session_id.nil? || ip_addr.nil?
       msg = 'We are unable to process a request; something has gone ' +
             'wrong in our code.  We apologize and will research the ' +
             'problem immediately.  Please contact us using the Feedback/' +
             SUPPORT_PAGE_NAME + ' page for further information, and again, ' +
             'our apologies.'
      logger.debug msg + ' -- Missing parameters in User.require_profile.'
      raise msg         
    else

      if use_real_id
        # Use find_by_id to avoid find's throwing of exceptions
        profile = profiles.find_by_id(prof_id)
      else
        profile = profiles.find_by_id_shown(prof_id)
      end

      u_data = {"url" => req_url, "action" => action_desc}

      # If this user doesn't have any access to the requested profile, or
      # has access but not at the required level, record the attempt and
      # throw them out.
      this_level = access_level(profile)
      if profile.nil? || this_level > min_access
        report_params = [['invalid_access',
                          Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                          u_data]].to_json
        UsageStat.create_stats(self,
                               nil,
                               report_params,
                               session_id,
                               ip_addr,
                               false)
        # Let folks know what happened.
        err_msg = "User #{name} attempted to access profile "+
          "#{use_real_id ? 'with id' : ''} #{prof_id} "+
          'which either is not associated with this account or is without ' +
          'the required level of access.'
        logger.debug err_msg
        raise SecurityError, err_msg
      end

      # Otherwise the user owns the profile or has the required level of
      # access.  Record that and go on.
      report_params = [['valid_access',
                        Time.now.strftime(UsageStat::FRAC_SECOND_FORMAT),
                        u_data]].to_json
      UsageStat.create_stats(self,
                             profile.id,
                             report_params,
                             session_id,
                             ip_addr,
                             false)
      return this_level, profile
    end # if we are/aren't missing some parameters
  end

  
  # This method extracts the error message or messages for a single attribute of
  # a User object, if any, and writes them to the page_errors array provided,
  # which it returns.
  #
  # This uses the obj.errors[attribute] method to get the message that was
  # stored without having the attribute name prepended to the message.  Since
  # the field labels on the form don't usually match the column names used in
  # the database (!), we don't want the column name included in the error
  # messages.  Won't make any sense to the user.  For example, what we call an
  # Account ID on the form is stored in the name column in the database.  How
  # the heck would the user know that?
  #
  # Parameters:
  # * page_errors the array to receive the error messages
  # * attr_symbol the attribute name, expressed as a symbol
  # * field_label - (optional) a label to prepend to the error messages
  #
  # Returns:  the page_errors array, updated if appropriate
  #
  def get_attribute_errors(page_errors, attr_symbol, field_label=nil)
    if (self.errors[attr_symbol].any?)
      errors_obj = self.errors[attr_symbol]
      if errors_obj.instance_of? Array
        if field_label
          errors_obj.each_with_index {|e,i| errors_obj[i] = "#{field_label} #{e}"}
        end
        page_errors.concat(errors_obj)
      else
        errors_obj = "#{field_label} #{errors_obj}" if field_label
        page_errors << errors_obj
      end
    end
    return page_errors
  end

  
  # Returns an error message indicating the user name does not exist
  # Parameters:
  # * user_name a user name
  def self.non_exist_user_error(user_name)
    user_name.blank? ? 
      "Please specify a user name." :
      "The user account for '#{user_name}' does not exist." 
  end


  # Adds a security question to the user.  This does not do any error
  # checking; it just adds it.
  #
  # Parameters:
  # * qtype - question type (0-fixed, 1-self-defined)
  # * question - the security question string
  # * answer - the answer for security question
  #
  # Returns:  the added question
  def add_question(qtype, question, answer)
    qa = QuestionAnswer.new(
      :user_id=>self.id,
      :qtype=>qtype,
      :question=>question)
    qa.answer=answer # encrypts answer
    self.question_answers << qa
    return qa
  end


  # To be called from script/console to update answers from previously entered
  # questions.
  # Parameters:
  # * param1  - question_id user's index in database
  # * param2  - new answer
  # Returns:   Done update !! - if successful Update
  #   failed !! - if failed
  def update_answer(question_id,answer)
    # hash_answer = encrypted_answer(answer, self.salt)
    qa = QuestionAnswer.find_by_user_id_and_id(self.id,question_id)
    if qa 
      qa.answer = answer
      qa.save!
      return ' Done update !! for Question '+qa.question
    else
      return ' Update failed !! for Question id '+question_id.to_s
    end
  end


  # To be called from script/console to get fixed and user questions with ids.
  # Returns: none. prints out list of questions with ids
  def get_user_questions()
    qa = QuestionAnswer.where({user_id: self.id})
    qa.each { |q|
      puts " Q id: " +q.id.to_s+ " Question: "+ q.question
    }
    return 
  end


  # This method updates email in the database and collects the errors in
  # page_errors.
  #
  # Parameters:
  # * new_email: the new email 
  # * new_confirmation_email: the new confirmation email
  # * page_errors - the errors to show on the page
  #
  # Returns:   1 - the update operation is successful and record updated
  #            0 - No record updated.
  #           -1 - the update operation had errors
  def update_email(new_email,new_confirmation_email, page_errors)
    if new_email.blank? && new_confirmation_email.blank?
      ret = 0
    else
      self.email = new_email
      self.email_confirmation = new_confirmation_email
      if self.save
        ret = 1
      else
        self.get_attribute_errors(page_errors, :email);
        self.get_attribute_errors(page_errors, :email_confirmation);
        ret = -1
      end
    end
  end


  # This method updates password in the database and collects the errors in
  # page_errors
  # 
  # Parameters:
  # * pwd new password
  # * pwd_conf new confirmation password
  # * page_errors: the errors to show on the page
  #
  # Returns:   1 - the update operation is successful and record updated
  #            0 - No record updated.
  #           -1 - the update operation had errors
  def update_password(pwd, pwd_conf, page_errors)
    if pwd.blank? && pwd_conf.blank?
      ret = 0
    else
      self.password = pwd
      self.password_confirmation = pwd_conf
      if  self.save
        ret = 1
      else
        self.get_attribute_errors(page_errors, :password);
        ret = -1
      end
    end
  end


  # This method updates security questions and answers from reset_security
  # functions
  #
  # Parameters:
  # * qas_hash: a hash from question answer type to list of question answers
  # For example:
  #  { 0=>[[self_question_1, self_answer_1],[self_question_2, self_answer_2]],
  #    1=>[[fiexed_question_1, fixed_answer_1],[fixed_question_2, fixed_answer_2]] }
  #  
  # * page_errors:  holds errors if any.
  # 
  # Returns:   1 - the update operation is successful and record updated
  #            0 - No record updated.
  #            -1 - the update operation had errors
  def update_security_question(qas_hash, page_errors)
    errors = []
    updated = false

    # questions/answers are required fields except for the following case:
    # the question was not changed and the answer was empty. In that case, the 
    # question/answer will be treated as unchanged
    qas_hash && qas_hash.each do |qa_type, new_qas|
      old_qas = self.question_answers.where({qtype:qa_type})
      
      # When two non-duplicated questions need to be updated, the validation may
      # fail when the new question currently being saved duplicates with another 
      # old question.
      # The workaround here is to modify the second existing question before 
      # updating the first question. 
      # We have two fixed questions and one self-created question, therefore 
      # only fixed questions need to have this workaround
      if (QuestionAnswer::FIXED_QUESTION == qa_type) 
          count =0
          new_qas.each do |new_qa|
            count +=1 if !new_qa[0].blank? && !new_qa[1].blank?
          end
          if (count==2) && (old_qas && old_qas.size==2) 
            old_qa = old_qas[1]  
            if  (old_qa.question.strip == new_qas[0][0].strip)
              old_qa.question+= "bak"
              old_qa.save!
            end
          end 
      end
      # end of the workaround for the uniqueness validation error  
      
      new_qas.each_with_index do |new_qa,i|
        new_quest, new_ans = new_qa
        saved_qa = old_qas && old_qas[i]
        if (!new_quest.blank? && !new_ans.blank?)
          if saved_qa
            saved_qa.question= new_quest
            saved_qa.answer = new_ans
          else
            # create a new one 
            saved_qa = self.add_question(qa_type, new_quest, new_ans)
          end
          if !saved_qa.save
            errors.concat(saved_qa.errors.full_messages)
          else
            updated = true if !updated
          end
        end

      end
    end
    
    errors.empty? ? (updated ? 1 : 0) : (page_errors.concat(errors); -1)
  end
  
  
  # This method updates regular account profile content into database and collects
  # errors in page_errors
  # 
  # Parameters:
  # * data_hash the data hash from user object properties to their values
  # (see PresenterBase#profile_data for details)
  # * page_errors: the errors to show on the page
  # Returns:   1 - the update operation is successful and record updated
  #            0 - No record updated.
  #           -1 - the update operation had errors
  def update_profile_to_db(data_hash, page_errors)
    n_email = data_hash[:email]
    n_email_conf = data_hash[:email_confirmation]
    n_pwd = data_hash[:password]
    n_pwd_conf = data_hash[:password_confirmation]
    n_qas = data_hash[:question_answers]
    
    ret1 = update_email(n_email, n_email_conf, page_errors)
    ret2 = update_password(n_pwd, n_pwd_conf, page_errors)
    ret3 = update_security_question(n_qas, page_errors)

    if (ret1 <  0) || (ret2 < 0) || (ret3 < 0)  
      ret = -1
    elsif (ret1 == 0) && (ret2 == 0) && (ret3 == 0)
      ret = 0
    else
      self.answered = 1
      self.save
      ret = 1
    end
  end

  
  # This method creates data hash for the change-profile web page. The
  # change-profile web page needs to show the content of the user's profile.
  #
  # Parameters:
  #  None
  # Returns:  data_hash - the data hash structure
  #
  def data_hash_for_update_account_settings
   
    ceemail_subtable = {
      'ceold_email' =>self.email
    }
    sqsecquest_tb = self.profile_qa_reset_hash   
    data_hash={
      'cechngmai_grp'=> ceemail_subtable,
      'sqsecquest_grp'=>sqsecquest_tb
    }
    return data_hash
  end

  
  # This method creates data hash for the change/reset-profile web pages. This
  # has common QA data hash which is used by both pages.
  #
  # Parameters:
  # * param1  - none
  #
  # Returns:  sqsecquest_tb - the data hash with user questions
  #
  def profile_qa_reset_hash

    fqs = self.question_answers.where({qtype:QuestionAnswer::FIXED_QUESTION})
    sqs = self.question_answers.where({qtype:QuestionAnswer::USER_QUESTION})

    if sqs.length >= 1 and fqs.length > 1
      fix_questtable = fqs.map do |e|
        {'cp_fixquest' =>e.question,
          'cp_fixansw' =>nil}
      end
      self_questtable = sqs.map do |e|  
        {'cp_selfquest' =>e.question,
        'cp_selfansw' =>nil} 
      end
    end
    sqsecquest_tb = {
      'fix_quest'=>fix_questtable,
      'self_quest'=>self_questtable,
    }

    return sqsecquest_tb
    
  end

    
  # Generate the reset_key and last_reset timestampe to be used to reset acount settings
  # including password and security questions
  def setup_reset_key
    self.reset_key= self.generate_random_str
    self.last_reset= Time.now.to_s
    self.save!
  end
  
  
  # Checks to see if the input reset key is valid
  # Parameters:
  # * reset_key_input the reset key needs to be verified using information 
  # stored in this user record
  def verify_reset_key(reset_key_input)
    !reset_key_input.blank? && self.last_reset && self.reset_key &&
        (self.last_reset > 1.hours.ago) && (self.reset_key == reset_key_input)
  end
  
  
  # Clears the reset_key. When user successfully used the reset_key in a post request,
  # the reset_key should be cleared/expired
  def clear_reset_key
    self.last_reset = self.reset_key = nil
    self.save!
  end

  
  # This method creates the hash table for reset password form
  #   Parameters:
  # * param1  - none
  #   Returns:  the data hash structure if created NULL: otherwise
  def data_hash_for_reset_password
    fq, sq = random_question_pair

    # ########################### #start quest_table = {}
    quest_table = {
      'ch_quest1'=>fq.question,
      'ch_answ1'=>nil,
      'ch_quest2'=>sq.question,
      'ch_answ2'=>nil
    }

    online_sub_tb = {
      'online_reset'=>quest_table
    }
    online_tb = {
      'select_on_grp'=>online_sub_tb,
      'user_name'=>self.name
    }
    # #end ############################
    data_hash={
      'select_opt_grp'=>online_tb
    }
    return data_hash
  end

  # This method creates the hash table for reset password form
  #   Parameters:
  # * param1  - none
  #   Returns:  the data hash structure if created NULL: otherwise
  def data_hash_for_reset_profile_security
   
    sqsecquest_tb = self.profile_qa_reset_hash
    data_hash={
      'sqsecquest_grp'=>sqsecquest_tb
    }
    return data_hash
    
  end


  # Returns a random question, picking a new one if self.answered==1 (i.e.
  # the user answered the current one).  Otherwise, the previously returned
  # random question will be returned (so that the user can't cycle through
  # the questions to pick one that is easier).
  def random_question
    # Return the question for which asked = 2, which is the signal that this
    # is the question to use when asking just one question.
    q = nil
    random_question_pair.each {|rq|
      q = rq if rq.asked == 2}
    return q
  end


  # Returns a pair of random questions, the first of which will be a fixed question
  # and the other of which will be a user-defined question.  A new pair will be
  # chosen if self.answered==1 (i.e. the user answered a question from the
  # current pair).  Otherwise, the previously returned pair
  # will be returned (so that the user can't cycle through
  # the questions to pick one that is easier).
  def random_question_pair
    if answered != 0
      rtn = new_random_question_pair
    else
      rtn = question_answers.where('asked != 0').order('qtype DESC')
      if rtn.empty?
        rtn = new_random_question_pair
      end
    end
    return rtn
  end


  # This method creates the hash table for forgot_id form Parameters:
  # * param1  - none
  # Returns:  the data hash structure if created NULL: otherwise
  def data_hash_for_forgot_id
    q = random_question

    # make sure fixed and user questions exists.
    if q.question.blank?
      return nil
    end

    quest_table = {
      'chall_quest'=>q.question
    }

    verify_quest_tb = {
      'challenge_grp'=>quest_table,
      'email' => self.email
    }

    data_hash={
      'verify_id_grp'=>verify_quest_tb
    }
    return data_hash
    
  end

  
  # This method resets the flags associated with QA answer trials.
  # Parameters:
  # * param: none
  # Returns:  null
  def reset_qa_answered_flag
    self.answered = 1
    self.answer_trial = 0
    self.last_answer_trial_at = Time.now
  end

  # This is a method to update the number of password trials. We reset the
  # max_trial and last access time.
  #
  # Parameters:
  # * param1 - user: the form User object
  # Returns:  NULL
  def trial_update
    self.password_trial = 0
    self.lasttrial_at = Time.now
    if (self.account_type == 'E')
      self.expiration_date = Time.now.advance(:days => 30)
    end
  end

  
  # This method creates the hash table for two factor check
  #
  # Parameters:
  # * param1  - none
  # Returns:  the data hash structure if created
  #           NULL: other wise
  #
  def data_hash_for_two_factor
    q = random_question
    # ########################### #start quest_table = {}
    quest_table = {
      'user_name'=>self.name,
      'user_quest'=>q.question,
      'user_answ'=>nil
    }

    verify_quest_tb = {
      'verify_quest'=>quest_table
    }

    data_hash={
      'verify_identity_grp'=>verify_quest_tb
    }
    return data_hash
  end


  # Get one demo account that has not been previously used
  # Returns user object if a demo user account is available
  def self.get_an_available_demo_account
    user = self.where(["account_type=? and used_for_demo=? and admin=?",
                DEMO_ACCOUNT_TYPE, false, false]).take
    demo_act_total = User.get_demo_account_total

    # if no more available demo user accounts
    while (!user && demo_act_total <= DEMO_ACCOUNT_TOTAL - DEMO_ACCOUNT_INCREMENTAL) do
      # create more demo accounts
      Util.create_demo_accounts
      user = self.where(["account_type=? and used_for_demo=? and admin=?",
                         DEMO_ACCOUNT_TYPE, false, false]).take
      demo_act_total += DEMO_ACCOUNT_INCREMENTAL
    end

    return user

  end


  # Get the total number of demo user accounts
  def self.get_demo_account_total
    return self.where(["account_type=? and admin=?", DEMO_ACCOUNT_TYPE, false]).
        select("count(*) total").take.total
  end


 # Case insensitive user name/password. authenticate user
 # Parameters:
 # param1: name : user id
 # param2: password, password to be verified.
 # param3: page_error hash
 # Returns user object if user can be authenticated
  def self.authenticate(name, password,page_errors)
    user = self.where(["LOWER(name) = ?", name.downcase]).take
    if user
      if user.inactive
        page_errors << INACTIVE_ACCOUNT
        user = nil
      elsif (!reguser_trial_limit(user, page_errors))
        user = nil
      elsif  (User.encrypted_password(password, user.salt) != user.hashed_password)
        page_errors << INVALID_LOGIN 
        user = nil    
      else
        begin
          user.check_data_overflow
        rescue DataOverflowError => err_msg
          page_errors << err_msg
          raise
        end
      end
    elsif user.blank?
      UseridGuessTrial.guess_trial(name, page_errors)      
    end
    user
  end


 # Before a new user was created, put the new account into pending for activation status.
 # And email user a new account activation link
  def pending_new_account_for_activation
    if new_record?
      vtoken = self.generate_random_str
      self.email_verifications.build(:token=>vtoken, :token_type=>"new")
      #DefMailer.verify_reg_email(self.name, vtoken, self.email).deliver_now
    end
  end


 # Verifies password for a user. similar to authenticate except different error
 # messages/logic.
 # Parameters:
 # param1: name : user id
 # param2: password, password to be verified.
 # param3: page_error hash
 # Returns user object if user can be authenticated
  def self.verify_password(name,password,page_errors)
    user = self.where(["LOWER(name) = ?", name.downcase]).take
    if user
       if !reguser_trial_limit(user, page_errors)
         user = nil
       elsif (User.encrypted_password(password, user.salt) != user.hashed_password)
         user = nil
         page_errors <<   @@invalid_account
       end
    elsif user.blank?
      page_errors << "Username #{name} does not exist in this system."
    end
    user
  end

  
  def after_destroy
    if User.count.zero?
      raise "Can't delete last user"
    end
  end

 
  # 'password' is a virtual attribute
  def password
    @password
  end
  
  # Overrides the default assignment of password to set encrypted password.
  # Parameter:
  #   param1 : pwd text password
  # Return: none
  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    password_test = User.check_password(pwd)
    if password_test
      self.salt = new_salt if self.salt.blank?
      self.hashed_password = User.encrypted_password(self.password, self.salt)
    end
  end

  # Add a virtual password confirmation attribute
  attr_accessor :password_confirmation

  
  # This method checks if the email address is unique and does not already exist
  # in in the system
  # Parameters:
  # * param1  - mail: new email address
  # Returns:  true - the original email is changed
  #           false - the original email is not changed
  def is_email_unique(email)
    if email.empty?
      return true
    else
      u = User.find_by_email(email)
      return u.nil?
    end # end email.empty
  end


  # This method checks if the email address is unique and does not already exist
  # in the system
  # Parameters:
  # * param1  - name:  user name
  # Returns:  true - the original email is changed
  #           false - the original email is not changed
  def self.is_username_unique(name)
    if name.blank?
      return false
    else
      u = User.find_by_name(name)
      return u.nil?
    end
  end

  
  # Validation method for the password field.
  def password_and_confirmation_checks
    # Note that the password is a virtual attribute; it will be nil unless
    # someone changes the value.  (We only store the hashed version.)
    rtn = false
    if password.nil? && !hashed_password_changed?
      rtn = true # no update to the password since the last save
    else
      # hashed_password_changed? means someone changed the password with
      # a valid password.  (See password=).  However, someone could have
      # set password to something else afterward, so we need to check it again.
      # First check to make sure the password and password confirmation fields
      # are not blank.
      if password.blank? || password_confirmation.blank?
        errors.add(:password, User.need_both_passwords_msg)
      elsif password != password_confirmation
        errors.add(:password, User.passwords_must_match_msg)
      elsif !User.check_password(password)
        errors.add(:password, User.invalid_password_msg)
      end
    end
    return rtn
  end


  # Return true if the user have any pending email verification and vice versa
  def has_pending_token
    the_token_type = self.inactive ? "new" : "other"
    self.email_verifications.any? do |e|
      e.used !=true && e.expired !=true && e.token_type == the_token_type
    end
  end


  # Checks the availability of email address used for signing up a new user account
  # Also tries to remind user if the duplicated email is associated with an inactivated new account
  def unavailable_email_checks
    if (new_record? || email_changed?) && !email.blank?
      rec = User.where(:email => email).take
      if rec
        msg = @@email_unique
        msg += @@inactive_account_email if rec.inactive
        errors.add(:email, msg)
      end
    end
  end


  # Validates the security questions and answers specified by the user on the
  # signup page.  We do this here, rather than in the QuestionAnswer model
  # class, because:
  # 1.  this is where it's been done so far and I don't want to restructure
  #   everything at this time; and
  # 2.  we want to verify that the questions and answers are valid before we try
  #   to save the user object.
  #
  # This should probably be moved to the appropriate model class when this is
  # overhauled.   lm, 4/8/10.
  #
  # Parameters:
  # * predef_q1  the first predefined question chosen by the user
  # * predef_a1  the user's answer to the first predefined question
  # * predef_q2  the second predefined question chosen by the user
  # * predef_a2  the user's answer to the second predefined question
  # * selfdef_q1  the first self-defined question specified by the user
  # * selfdef_a1  the user's answer to the first self-defined question
  #
  # Returns:  an array containing any error messages generated - or an
  #           empty array if no errors were found
  #
  def self.questions_input_checks(predef_q1,  predef_a1,
      predef_q2,  predef_a2,
      selfdef_q1, selfdef_a1)
    qa_errors = []
    if predef_q1.nil? || predef_q1.empty? || predef_q2.nil? || predef_q2.empty?
      qa_errors << self.need_both_predef_questions_msg
    elsif predef_q1 == predef_q2
      qa_errors << self.predef_questions_must_not_match_msg
    end
    if predef_a1.nil? || predef_a1.empty? || predef_a2.nil? || predef_a2.empty?
      qa_errors << self.need_both_predef_answers_msg
    end
    if selfdef_q1.nil? || selfdef_q1.empty?
      qa_errors << self.need_self_question_msg
    end
    if selfdef_a1.nil? || selfdef_a1.empty?
      qa_errors << self.need_self_answer_msg
    end
    return qa_errors
  end # questions_input_check


  # Validates the format of a password.  Specifically, it checks to make sure
  # the password:
  # 1.  has at least 8 characters; and
  # 2.  has at least 3 out of the 4 character groups: upper case letters; lower
  #   case letters; digits; and special characters.
  # Parameters:
  # * user_name the password to check
  # Returns:  boolean indicating whether or not the password is valid
  def self.check_password(password)
    if password.nil?
      ok = false
    else
      ok = true
      !(password =~ /[A-Z]/).nil? ? count = 1 : count = 0
      count += 1 if !(password =~ /[a-z]/).nil?
      count += 1 if !(password =~ /[0-9]/).nil?
      special_char = false
      password.each_char do |c|
        if !special_char
          special_char = (c =~ /[a-z]|[A-Z]|[0-9]/) == nil
        end # if the special_char flag has not been set
      end # do for each character
      count += 1 if special_char == true
    end # if password is/isn't nil
    return ok && password.length >= 8 && password.length <= 32 && count >= 3
  end # check_password


  # This method encrypts the password
  # Parameters:
  # * password: raw string of the password.
  # * salt: the random string generated by create_new_salt(user)
  #
  # Returns:  the encrypted password
  def self.encrypted_password(password, salt)
    # Add in a constant to make the hash harder to guess
    string_to_hash = password + 'b89266' + salt
    return Digest::SHA256.hexdigest(string_to_hash)
  end

  
  # This method checks if the answer for a security question is correct or not.
  # Parameters:
  # * param1  - answer: the answer for question
  # * param2  - page_errors: the errors to show on the page
  #  Returns:  true - the answer is correct false - otherwise
  def check_answer(answer,page_errors)
    check_lock = self.qa_attempt_limit(page_errors)
    if check_lock
      right_answer = random_question.right_answer?(answer)
      if (!right_answer)
        page_errors << "The answer for the security question is not correct."
      end
      return right_answer
    else
      return false
    end
  end


  # This method generates a cookie hash using users salt and current time
  # Parameters:
  # * param1 - user object
  # Returns:  random string
  def self.generate_user_cookie(u)
    # 'random_str' makes it harder to guess
    string_to_hash = Time.now.to_s + "random_str" + u.salt  
    return Digest::SHA256.hexdigest(string_to_hash)
  end


  # This method generates a cookie hash using users salt and current time
  # Parameters:
  # * param1 - user name or user object
  # Returns:  random string
  def self.generate_cookie(user)
    if !user.blank? && user.is_a?(String)
      u = User.find_by_name(user)
    else
      u = user
    end
    return generate_user_cookie(u)
  end


  # Checks for any expired accounts, and removes all data for any found.
  # Accounts expire if:
  # 1.  The account is flagged as temporary (test, experimental, whatever); and
  # 2.  EITHER a.  the account has not been accessed in the last 30 days; OR b.
  #   the account was created more than 6 months ago.
  #
  # This uses 2 arrays of table names:
  # 1.  a user_id_tables array that contains the names of all tables with data
  #   linked to the account by the user_id - except the profiles_users join
  #   table; and
  # 2.  a profile_id_tables array that contains the names of all tables with
  #   data linked to a user's profile(s) by the profile_id.
  #
  # If you add or delete tables to the system that contain user data, the
  # appropriate array needs to be updated. The arrays are actually defined in
  # accessor methods at the class level.
  #
  # Parameters:  none Returns:  nothing
  #

  # Commented out 6/19/2014, per conversation with Paul.  We are no longer
  # using temporary accounts, have not used them in years, and don't expect
  # to ever use them.   lm.
#  # not working!!
#  def self.remove_expired_accounts
#
#    ActiveRecord::Base.transaction do
#      # Find any expired accounts
#      cond = ("account_type = 'E' AND (" +
#          '(expiration_date < curdate() AND ' +
#          'expiration_date > 0000-00-00) OR ' +
#          '(created_on > 0000-00-00 AND ' +
#          "created_on < DATE_SUB(curdate(), interval 6 MONTH)))")
#      User.where(cond).each do |u|
#        uid = u.id
#        # Remove data linked to this user object by the user_id field
#        self.user_id_tables.each do |table_name|
#          table_class = table_name.singularize.camelize.constantize
#          table_class.where({user_id: uid}).each do |u_rec|
#            u_rec.destroy
#          end
#        end # do for each table linked by the user_id
#
#        # Find the profile_id(s) used to link profile detail to this user object
#        u.profiles.each do |p|
#          pid = p.id
#
#          # Remove data linked to this profile object by the profile_id field
#          self.profile_id_tables.each do |table_name|
#            table_class = table_name.singularize.camelize.constantize
#            table_class.where({profile_id: pid}).each do |p_rec|
#              p_rec.destroy
#            end
#          end # do for each table linked by the profile_id
#        end # do for each profile_id
#
#        u.profiles.destroy_all
#        u.destroy
#      end # do for each user object
#
#    end # transaction
#  end # remove_expired_accounts


  # generates random string to be used as key for reset_link - and other things
  # Parameters: None
  # Returns:  randomly generated string
  def generate_random_str
    random_str1 =  Digest::SHA256.hexdigest(Time.now.to_s+"rndstr1"+self.salt )
    random_str2 =  Digest::SHA256.hexdigest(SecureRandom.hex)
    return random_str1+random_str2
  end
  

  # This method checks the answer for security question is correct or not.
  #
  # Parameters:
  # * param1  - fix_answer: the answer for fixed question
  # * param2  - self_answer: the answer for self-defined question
  # * param3  - page_errors: the errors to show on the page
  #   Returns:  true - the answer is correct
  #             false - otherwise
  def is_answer_correct(fix_answer, self_answer, page_errors)
    check_lock = self.qa_attempt_limit(page_errors)
    if check_lock
      # password failed to validate the user, use security questions now...
      fq, sq = random_question_pair
      fix_right_answer = fq.right_answer?(fix_answer)
      self_right_answer = sq.right_answer?(self_answer)

      if (!fix_right_answer)
        page_errors << "The answer provided for your fixed security question is "+
          'incorrect.'
      end
      if (!self_right_answer)
        page_errors << "The answer provided for your self-defined security question"+
          ' is incorrect.'
      end
      return (fix_right_answer  and self_right_answer)
    else
      return false
    end
  end

  
  # This is a method to check the number of password trials. If the number is
  #  equal to a threshold specified by @@max_trial, we freeze the account for
  #  @@min_hold_time. We add the password_trial by one at the beginning of the
  # login. If the user can successfully login the account, we reset the
  # max_trial and last access time.
  #
  # Parameters:
  # * param1 - user_name: the account name, which is unique in User table.
  # * param2 - page_errors: the errors on the web pages
  #
  # Returns:  true- the user's trial limit is cleared, meaning the user can
  #                 continue to login
  #           false- the user's trial limit is not cleared, meaning the user can
  #                 not continue to login but wait until the min_hold_time time-
  #                  out.
  def self.reguser_trial_limit(user, page_errors)
    max = 1 # hours account to be locked.
    if user
      if user.password_trial and user.password_trial < MAX_TRIAL
        if user.lasttrial_at and
            (Time.now.to_i - Time.at(user.lasttrial_at.to_i).to_i > max*3600)
          user.password_trial = 1
        else
          user.password_trial += 1
        end
        user.lasttrial_at = Time.now
        user.save!        
      elsif user.password_trial and user.password_trial == MAX_TRIAL
        if user.lasttrial_at and
            (Time.now.to_i - Time.at(user.lasttrial_at.to_i).to_i > max*3600)
          user.password_trial = 1
          user.lasttrial_at = Time.now
          user.save!
        else
          page_errors << @@max_verify_exceed
          return false
        end
      else # password_trial is null
        user.password_trial = 1
        user.lasttrial_at = Time.now
        user.save!
      end
    else
      page_errors << @@invalid_account
      return false
    end
    return true
  end


  # This is a method to check the number of answer trials to the challenge
  # question. We check the number of trial. If the number is equal to a
  # threshold specified by USER::MAX_TRIAL, we freeze the account for a certain time
  # specified by max. We increment answer_trial by one at the beginning of the
  # login. If the user can successfully login the account, we reset the
  # max_trial and last access time.
  #
  # Parameters:
  # * param1 - user_name: the account name, which is unique in User table.
  # * param2 - page_errors: the errors on the web pages
  #
  # Returns:  true- the user's trial limit is cleared, meaning the user can
  #                 continue to login
  #           false- the user's trial limit is not cleared, meaning the user can
  #                 not continue to login but wait until the min_hold_time time-
  #                  out.
  def qa_attempt_limit(page_errors)
    max = 1 # hours account to be locked.
    
    if self.answer_trial and self.answer_trial < MAX_TRIAL
      self.answer_trial += 1
      self.last_answer_trial_at = Time.now
      self.save
    elsif self.answer_trial and self.answer_trial == MAX_TRIAL
      if self.last_answer_trial_at and
          (Time.now.to_i - Time.at(self.last_answer_trial_at.to_i).to_i > max*3600)
        self.answer_trial = 0
        self.last_answer_trial_at = Time.now
        self.save
      else
        page_errors << "We are sorry, but your invalid answer"+
          " attempts have exceeded the maximum allowed.  Further attempts"+
          " are locked for next #{max.to_s} hour(s). Please try again"+
          " later or contact support."
        return false
      end
    else # answer_trial is null
      self.answer_trial = 0
      self.last_answer_trial_at = Time.now
      self.save
    end
    return true
  end
  
  
  # This method returns a partially hidden email to display as flash message etc.
  def masked_email
    # (Was originally hide_email in LoginHelper).
    if !email.blank?
      email_at = email.split('@')
      user_first = email_at[0][0]
      email_user = email_at[0].gsub(/[a-zA-Z0-9]/,'x')
      email_user[0] = user_first
      email_dot = email_at[1].split('.')
      em_char = (email_dot[0])[0]
      em_domain = email_dot[0].gsub(/[a-zA-Z0-9]/,'x')
      em_domain[0] = em_char
      email_suff = ''
      arr_size = email_dot.length
      i = 1

      while i+1 < arr_size
        email_suff += email_dot[i].gsub(/[a-zA-Z0-9]/,'x')+'.'
        i +=1
      end

      email_suff += email_dot[arr_size-1]
      email_str = email_user+'@'+em_domain+'.'+email_suff
      return email_str
    else
      return ''
    end
  end

  
  # This adds a value to the user's total and daily data size values in the
  # User record and saves the values to the database.
  #
  # It also checks the daily_size_time value, updates it if the day is before
  # today, and replaces the current daily_size value with the value passed in,
  # effectively resetting that counter.
  # 
  # Parameters:
  # * adder - the value to be added to the two size values.  As you would 
  #   expect, passing in a negative adder will decrease the total size and
  #   the daily size - unless the daily size is being reset.  In that case
  #   the daily size will be set to zero.
  # Returns:
  # * nothing
  #
  def accumulate_data_length(adder)
    self.total_data_size += adder
    now = Date.today

    if self.daily_size_date.nil? ||
       self.daily_size_date != now
      self.daily_size_date = now
      self.daily_data_size = adder > 0 ? adder : 0
    else
      self.daily_data_size += adder
    end
    self.save!
  end  # accumulate_data_length
  
  
  # This checks the current total and daily size values for this user's data
  # against the project limits.  If either one exceeds its respective limit
  # the limit_lock flag on the user record is set to true and the record is
  # saved.   A security error is then thrown with the appropriate message.
  #
  # The calling method is expected to take care of writing the error to the
  # database, logging the user out of his/her session, and letting the user
  # know what happened.
  #
  def check_data_overflow
    now = Date.today
    if !self.limit_lock
      if self.daily_size_date != now
        self.daily_size_date = now
        self.daily_data_size = 0
        self.save!
      end
      if self.total_data_size > TOTAL_DATA_SIZE_LIMIT ||
         self.daily_data_size > DAILY_DATA_SIZE_LIMIT
        self.limit_lock = true
        self.save!
      end
    end
    if self.limit_lock
      raise DataOverflowError.new(self.id), DATA_LIMIT_EXCEEDED
    end
  end # check_data_overflow


  private

  
  # Returns a new pair of randomly chosen questions, the first of which will be a
  # fixed question and the other of which will be a user-defined question.  This is
  # for internal use only.  Outside callers should use "random_question_pair",
  # so that a user can't cycle through the questions to get easier ones.
  def new_random_question_pair
    # Pick a new question
    question_answers.update_all(:asked=>0)
    rtn = []
    [QuestionAnswer::FIXED_QUESTION, QuestionAnswer::USER_QUESTION].each do |qtype|
      q = question_answers.where({qtype: qtype}).sample
      rtn << q
      q.asked = 1
    end
    # Set one of them to be the question asked when only one question
    # is asked.
    q1 = rtn.sample
    q1.asked = 2
    rtn.each {|q| q.save!}
    self.answered = 0
    save!
    return rtn
  end

end # User model class
