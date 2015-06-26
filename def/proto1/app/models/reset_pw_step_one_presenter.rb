# A Presenter for the Reset Password Step 1 page.
class ResetPwStepOnePresenter < PresenterBase
  # Returns a list of the target field names of the field descriptions used in
  # the basic mode's sign up page.
  def self.fields_used
    %w{user_name}
  end


  # Returns the name of the form (forms table form_name) that describes
  # the form for which this is a presenter.
  def form_name
    'forgot_password'
  end

end
