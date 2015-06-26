# A Presenter for the Sign Up page.
#
# NOTE that we have hidden a couple of sections of the registration page,
# specifically the account type and the account recovery identifiers which
# are/were the date of birth and 4-digit pin.  If you need to restore any of
# those, you'll need to check in the following methods: initialize, fields_used,
# presenter_attrs, init_class_vars, and process_form_params for the commented
# out code.  lm 8/9/12.
#
class SignUpPresenter < PresenterBase
  # Validation messsages
  TOS_MISSING = ('Terms of Service section:<ul>' +
    '<li>We cannot complete the signup process until you agree to the Terms ' +
    'of Service, by clicking in the box labeled "Please check here to ' +
    'indicate that you have read and agreed to the Terms of Service ' +
    'Agreement."</li></ul>').html_safe


  # Returns a list of the target field names of the field descriptions used in
  # the basic mode's sign up page.
  def self.fields_used
#    %w{signup_policy instructions2 agree_chbox signup_account
#    user_name uid_instr password passwd_instr confirm_password
#    experimental_instructions experimental signup_quest su_fix_quest su_fixansw
#    su_selfquest su_selfansw email_grp email sec_email email_instr1
#    account_recovery dob pin}
    %w{signup_policy instructions2 agree_chbox signup_account
    user_name uid_instr password passwd_instr confirm_password
    signup_quest su_fix_quest su_fixansw
    su_selfquest su_selfansw email_grp email sec_email email_instr1}
  end


  presenter_attrs([
   #:acc_type_list, # the list items for the account type field
   :question_list # the list of security questions
  ])


  # Initializes a new instance
  #
  # Parameters:
  # * form_params - (optional) form parameters, e.g. from a post
  def initialize(form_params = {})
    form_params = {} if !form_params # might be nil
    m = form_params.clone
    super(m)
    # Create a DataRec for displaying the form_params back on the form.  We
    # need to map the birth_date field back to "dob"; it is an unusual case
    # (for this form) in which the dob field description actually does have a
    # db_field_description defined, so the helper code will call 'birth_date'.
#    m[:birth_date] = m[:dob_1]
    @data = DataRec.new(m)
  end
  

  # Initializes class variables
  def init_class_vars
    super
    c = self.class
#    if c.acc_type_list.nil?
#      c.acc_type_list = c.fds['experimental'].list_items
    if c.question_list.nil?
      c.question_list = c.fds['su_fix_quest'].list_items
    end
  end


  # Returns the name of the form (forms table form_name) that describes
  # the form for which this is a presenter.
  def form_name
    'signup'
  end


  # Validates the information on the sign up form, and returns a user object,
  # valid or not valid, and with error messages or not.
  #
  # Returns:  the user object, and an array of error messages (possibly empty)
  def process_form_params
    page_errors = []
#    attrs = {:name=>:user_name_1, :password=>:password_1, :email=>:email_1,
#     :birth_date=>:dob_1, :pin=>:pin_1, :email_confirmation=>:sec_email_1}
    attrs = {:name=>:user_name_1, :password=>:password_1,
             :password_confirmation=>:confirm_password_1, :email=>:email_1,
             :email_confirmation=>:sec_email_1}
    attrs.each {|k,v| attrs[k] = @form_params[v]}
#    temporary = @form_params[:experimental_1_1] == EXP_ACCOUNT_NAME
#    attrs[:account_type] = temporary ? 'E' : 'R'

    user = User.new(attrs)
    user.valid?

    # Do some additional validation
    # Make sure the user has agreed to the terms of service
    page_errors << TOS_MISSING if @form_params[:agree_chbox_1] != '1'

    qa_errors = User.questions_input_checks(@form_params[:su_fix_quest_1_1],
      @form_params[:su_fixansw_1_1],
      @form_params[:su_fix_quest_1_2],
      @form_params[:su_fixansw_1_2],
      @form_params[:su_selfquest_1_1],
      @form_params[:su_selfansw_1_1])
    
    ret = (user.errors.size == 0) && (qa_errors.size() == 0)

    # Build the errors array section by section.
    if !ret
      if (user.errors[:name].size > 0 || user.errors[:password].size > 0 || 
            user.errors[:password_confirmation].size > 0)
        page_errors << 'Account ID and password section:<ul>'.html_safe
        if (user.errors[:name].size > 0)
          user.get_attribute_errors(page_errors, :name)
        end
        if (user.errors[:password].size > 0)
          user.get_attribute_errors(page_errors, :password)
        end
        if (user.errors[:password_confirmation].size > 0)
          user.get_attribute_errors(page_errors, :password_confirmation, 'Password confirmation:')
        end
        page_errors << '</ul>'.html_safe
      end
      if (!qa_errors.empty?)
        page_errors << 'Security questions section:<ul>'.html_safe
        page_errors.concat(qa_errors)
        page_errors << '</ul>'.html_safe
      end
      if (user.errors[:email].size > 0 || user.errors[:email_confirmation].size > 0)
        page_errors << 'E-mail address section:<ul>'.html_safe
        if (user.errors[:email].size > 0)
          user.get_attribute_errors(page_errors, :email)
        end
        if (user.errors[:email_confirmation].size > 0)
          user.get_attribute_errors(page_errors, :email_confirmation, 'Email confirmation:')
        end
        page_errors << '</ul>'.html_safe
      end

#      if (user.errors.invalid?(:pin) || user.errors.invalid?(:birth_date))
#        page_errors << 'Account recovery identifiers section:<ul>'
#        if (user.errors.invalid?(:pin))
#          page_errors << 'Please enter a four digit PIN.'
#        end
#        if (user.errors.invalid?(:birth_date))
#          user.get_attribute_errors(page_errors, :birth_date, 'Birth date')
#        end
#        page_errors << '</ul>'
#      end
    end
    return user, page_errors
  end
  
    
  # A hash map from profile attribute names to the form field ids.
  # This method is used by profile_data method in presenter_base.rb.
  # 
  # sample structure of this map
  # { :question_answers => {
  #  0 => [[ s_question_1_id, s_answer_1_id], [s_question_2_id, s_answer_2_id]],
  #  1 => [[ f_question_1_id, f_answer_1_id], [f_question_2_id, f_answer_2_id]]
  # }}
  def profile_attr_to_field_id_map
    if !@pattr_to_id 
      map = {}
      fqas, sqas = [], []
      map[:question_answers] = {
        QuestionAnswer::FIXED_QUESTION => fqas,
        QuestionAnswer::USER_QUESTION => sqas
      }
      fqas << [:su_fix_quest_1_1, :su_fixansw_1_1]
      fqas << [:su_fix_quest_1_2, :su_fixansw_1_2]
      sqas << [:su_selfquest_1_1, :su_selfansw_1_1]
      sqas << [:su_selfquest_1_2, :su_selfansw_1_2]
      @pattr_to_id = map
    end
    @pattr_to_id
  end

end
