#!/usr/bin/env ruby

# This daemon clears out old sessions from the database. Sleep time 
# determines the interval at which this daemon would clear the sessions
Rails.env ||= "production"

require File.dirname(__FILE__) + "/../../config/environment"

$running = true
Signal.trap("TERM") do 
  $running = false
end

while($running) do
  # Replace this with your code
  ActiveRecord::Base.logger.info "This daemon is still running at #{Time.now}.\n"
  yesterday = Time.now - 86400
  time_str = yesterday.strftime("%Y-%m-%d %H:%M:%S")
  expire_sessions = Session.where("updated_at  < '"+time_str+"'").load
  if !expire_sessions.nil? 
    expire_sessions.each do |sess|
      sess.destroy
    end
  end
  # wait for a day or so before waking up
  sleep 86400
end
