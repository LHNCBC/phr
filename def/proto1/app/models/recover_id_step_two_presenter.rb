# A Presenter for the Sign Up page.
class RecoverIdStepTwoPresenter < PresenterBase
  attr_accessor :possible_user, :question # user object and challenge question

  # Returns a list of the target field names of the field descriptions used in
  # the basic mode's sign up page.
  def self.fields_used
    %w{email recover_instr passwd_ans chall_quest chall_answ}
  end


  # Initializes a new instance, but without setting the user.  This is
  # mostly for testing.  Use the "for_user" method to get an instance
  # for diplaying the form or processing parameters.
  #
  # Parameters:
  # * form_params - (optional) form parameters, e.g. from a post
  # * user - the user object corresponding to the email address provided.
  def initialize(form_params = {})
    form_params = {} if !form_params # might be nil
    m = form_params.clone
    super(m)
  end


  # Returns an instance initialized for the given user.
  #
  # Parameters:
  # * form_params - form parameters, e.g. from a post
  # * user - the user object corresponding to the email address provided.
  def self.for_user(form_params, user)
    rtn = new(form_params)
    rtn.possible_user = user # because we do not know yet for sure who it is
    rtn.question = user.random_question.question
    return rtn
  end
  

  # Returns the name of the form (forms table form_name) that describes
  # the form for which this is a presenter.
  def form_name
    'forgot_id_step2'
  end


  # Validates the information on the sign up form, and returns a user object,
  # valid or not valid, and with error messages or not.
  #
  # Returns: the user object corresponding to email_from_session, and an array
  # of error messages (possibly empty)
  def process_form_params
    page_errors = []
    id_confirmed = false
    # Check to see if the user tampered with the email address on the form.
    # This check is not really needed by the code that follows, which relies on
    # the user object obtained from the session for the email address.
    if (!@form_params[:email_1].blank? && @possible_user.email != @form_params[:email_1])
      raise 'Recover ID step 2:  form email address does not match the session value.'
    end

    # Check the radio buttons if they were present, but they are not present in
    # the basic mode.
    radio = @form_params[:reset_option_radio_1_1]
    if !@form_params[:passwd_ans_1_1].blank?  && (!radio || radio == 'password')
      # When we used OpenID, OpenID accounts had a blank name.  Make sure
      # this one doesn't.  (We aren't using OpenID at present.)
      if !@possible_user.name.blank?
        id_confirmed = User.authenticate(@possible_user.name,
          @form_params[:passwd_ans_1_1], page_errors)
      end
    elsif !@form_params[:chall_answ_1_1].blank? &&
         (!radio || radio == 'challenge_q')
      # Check the answer to the challenge question
      id_confirmed = @possible_user.check_answer(@form_params[:chall_answ_1_1],
         page_errors)
    else
      page_errors << 'You must either answer the challenge question or enter
                        the correct account password.'
    end

    # email account id if correct password or challenge answer is entered
    if (id_confirmed)
      DefMailer.uid_notice(@possible_user.name, @possible_user.email).deliver_now
      @possible_user.reset_qa_answered_flag
      @possible_user.trial_update
      @possible_user.save!
    else      
      page_errors.each do |e|
        if e == User::INVALID_LOGIN
          index = page_errors.rindex(User::INVALID_LOGIN)
          page_errors[index] = 'Incorrect password entered for the account '+
            'associated with the provided email address.'
        end
      end
    end # if the user did/didn't enter something

    # Raise an error if the user's ID is not confirmed but the page_errors
    # are empty.  Calling code will rely on page_errors to determine
    # whether the user's ID was confirmed.  This case is not expected to occur.
    raise 'Unknown error' if !id_confirmed && page_errors.empty?
    return page_errors
  end
end
