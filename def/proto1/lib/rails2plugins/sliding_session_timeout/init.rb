require File.expand_path('../lib/sliding_session_timeout', __FILE__)

# 
ActionController::Base.send :include, SlidingSessionTimeout
