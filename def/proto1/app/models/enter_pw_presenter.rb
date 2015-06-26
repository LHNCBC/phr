# A Presenter for the "enter password" page which appears before account
# settings.
class EnterPwPresenter < PresenterBase

  
  # Returns the name of the form (forms table form_name) that describes 
  # the form for which this is a presenter.
  def form_name
    'verify_password'
  end


  # Returns a list of the target field names of the field descriptions used in
  # the basic mode's sign up page.
  def self.fields_used
    %w{verify_pass_instr password}
  end

end
