class DataOverflowError < RuntimeError
  # This class allows us to attach the user_id to the error that
  # gets raised when overflow is detected.
  attr :user_id
  def initialize(user_id)
    @user_id = user_id
  end
end
 
