# A Presenter for the Reset Account Security page.
class ResetSecurityPresenter < PresenterBase
  # Returns a list of the target field names of the field descriptions used in
  # this page.
  def self.fields_used
    %w{cpchngpas_grp cpnew_passwd cpconfm_passwd sqsecquest_grp cp_fixquest
    cp_fixansw cp_selfquest cp_selfansw}
  end

  presenter_attrs([:question_list]) # the list of security questions

  # Initializes a new instance
  #
  # Parameters:
  # * form_params - (optional) form parameters, e.g. from a post
  def initialize(form_params = {})
    form_params = {} if !form_params # might be nil
    m = form_params.clone
    super(m)
    @data = DataRec.new(m)
  end


  # Returns an AccountSettingsPresenter for displaying the account
  # settings for the given user.
  #
  # Parameters:
  # * user - the user record
  def self.current_settings(user)
    form_params = {}
    fixed_questions = user.question_answers.where(qtype: 1)
    user_questions = user.question_answers.where(qtype: 0)
    (0..1).each do |i|
      qa = fixed_questions[i]
      form_params["cp_fixquest_1_#{1+i}".to_sym] = qa.question if qa
      qa = user_questions[i]
      form_params["cp_selfquest_1_#{1+i}".to_sym] = qa.question if qa
    end
    return new(form_params)
  end
  

  # Initializes class variables
  def init_class_vars
    super
    c = self.class
    if c.question_list.nil?
      c.question_list = c.fds['cp_fixquest'].list_items
    end
  end


  # Returns the name of the form (forms table form_name) that describes
  # the form for which this is a presenter.
  def form_name
    'reset_account_security'
  end
  
  
  # A hash map from profile attribute names to the form field ids.
  # This method is used by profile_data method in presenter_base.rb.
  #  
  # Sample structure of this map
  # { :password => password_field_id, 
  #    ... ,  
  #   :password_confirmation => password_conf_field_id,
  #   :question_answers => {
  #     0 => [[ s_question_1_id, s_answer_1_id], [s_question_2_id, s_answer_2_id]],
  #     1 => [[ f_question_1_id, f_answer_1_id], [f_question_2_id, f_answer_2_id]]
  #   }
  # }
  def profile_attr_to_field_id_map
    if !@pattr_to_id 
      map = {}
      map[:password] = :cpnew_passwd_1_1
      map[:password_confirmation] = :cpconfm_passwd_1_1
      fqas, sqas = [], []
      map[:question_answers] = {
        QuestionAnswer::FIXED_QUESTION => fqas,
        QuestionAnswer::USER_QUESTION => sqas
      }
      fqas << [:cp_fixquest_1_1, :cp_fixansw_1_1]
      fqas << [:cp_fixquest_1_2, :cp_fixansw_1_2]
      sqas << [:cp_selfquest_1_1, :cp_selfansw_1_1]
      sqas << [:cp_selfquest_1_2, :cp_selfansw_1_2]
      @pattr_to_id = map
    end
    @pattr_to_id
  end
  
end
