=begin
ActionController::Request.class_eval do
  def reset_session
    # session may be a hash, if so, we do not want to call destroy
    # fixes issue 6440
    session.destroy if session and session.respond_to?(:destroy)
    self.session = {}
  end
end
=end
