 
module SlidingSessionTimeout
  
  def self.included(controller)
    controller.extend(ClassMethods)
  end
  
  module ClassMethods
    
    def sliding_session_timeout(seconds, expiry_func=nil)
      @sliding_session_timeout = seconds
      @sliding_session_expiry_func = expiry_func
      
      prepend_before_filter do |c|
        if c.session[:sliding_session_expires_at] && c.session[:sliding_session_expires_at] < Time.now
          c.send @sliding_session_expiry_func unless @sliding_session_expiry_func.nil?
          c.send :reset_session
        else
          # use variable seconds to replace @sliding_session_timeout because the value 
          # stored in @sliding_session_timeout may be missing
          c.session[:sliding_session_expires_at] = Time.now + seconds
        end
      end # before_filter
      
    end # sliding_session_timeout
  
  end # ClassMethods

end
