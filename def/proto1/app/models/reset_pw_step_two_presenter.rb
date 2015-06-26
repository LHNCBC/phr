# A Presenter for the Reset Password Step 1 page.
class ResetPwStepTwoPresenter < PresenterBase
  attr_accessor :possible_user_name # user name from session
  attr_accessor :fixed_question # a challenge question
  attr_accessor :user_question # a challenge question


  # Initializes a new instance
  #
  # Parameters:
  # * form_params - (optional) form parameters, e.g. from a post
  def initialize(form_params = {})
    form_params = {} if !form_params # might be nil
    @data = DataRec.new(form_params)
    super(form_params)
  end


  # Returns an instance initialized for the given user.
  #
  # Parameters:
  # * form_params - form parameters, e.g. from a post
  # * user - the user object corresponding to the email address provided.
  def self.for_user(form_params, user)
    rtn = new(form_params)
    rtn.possible_user_name = user.name # because we do not know yet for sure who it is
    q_pair = user.random_question_pair
    if(q_pair[0].qtype == QuestionAnswer::FIXED_QUESTION)
      rtn.fixed_question =  q_pair[0].question
      rtn.user_question = q_pair[1].question
    else
      rtn.fixed_question =  q_pair[1].question
      rtn.user_question = q_pair[0].question
    end
    return rtn
  end


  # Returns a list of the target field names of the field descriptions used in
  # the basic mode's sign up page.
  def self.fields_used
    %w{user_name email_option_radio ch_quest1 ch_quest2 ch_answ1 ch_answ2}
  end


  # Returns the name of the form (forms table form_name) that describes
  # the form for which this is a presenter.
  def form_name 
    'reset_password_step2'
  end

end
