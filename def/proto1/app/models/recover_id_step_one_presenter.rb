# A Presenter for the Recover Account ID Step 1 page.
class RecoverIdStepOnePresenter < PresenterBase
  # Returns a list of the target field names of the field descriptions used in
  # the basic mode's sign up page.
  def self.fields_used
    %w{email_grp user_email}
  end


  # Initializes a new instance
  #
  # Parameters:
  # * form_params - (optional) form parameters, e.g. from a post
  def initialize(form_params = {})
    form_params = {} if !form_params # might be nil
    m = form_params.clone
    super(m)
  end
  

  # Returns the name of the form (forms table form_name) that describes
  # the form for which this is a presenter.
  def form_name
    'forgot_id'
  end

end
