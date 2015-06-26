# begin of Rails 4 gems
# protected_attributes gem should appear before active_support was loaded
require 'protected_attributes'
# requiring 'activerecord-session_store' gem
require 'active_record/session_store'
require 'active_record/deprecated_finders'
# end of Rails 4 gems
require 'active_support/all' # fix:cattr_accessor in acts_as_ferret is not working
require "acts_as_ferret"
require "acts_as_tree"
require "paper_trail"
require  File.expand_path('../../app/models/has_searchable_lists', __FILE__)
require 'ruport'
require 'ruport/acts_as_reportable'
require 'rack/recaptcha'
#require 'ruby-prof'
require 'activerecord-import'
require 'sass-rails'
require 'compass-rails'
#require 'rubygems'
#require 'ruby-openid', :lib =>"openid"

# Include the application settings file, if it exists.  This needs to be done
# before the Rails initializer, which seems to load the application classes,
# the code for which depends on constants that might be overridden in
# this settings file.
config_dir = File.dirname(__FILE__)
app_settings_file = File.join(config_dir, 'app_settings.rb')
require app_settings_file if File.exists?(app_settings_file)

# Also include installation-specific settings.
require File.expand_path("../../app/models/installation_change", __FILE__)
require File.join(config_dir, 'installation',
  InstallationChange.installation_name, 'installation_config.rb')

 # include oracle adapter extensions
  # require File.join(File.dirname(__FILE__), 'oracle_adapter_extension')
  #require 'nih_adapter'
   
  #require File.join(File.dirname(__FILE__), 'memory_profiler.rb')
  #MemoryProfiler.start(:string_debug=>true)

# In ruby 2.0, the license problem with ruby debugger is gone. so the debugger
# gem will be specified in Gemfile and installed together with Rails 4 etc. 
# Make sure ruby-debug is loaded on development systems  
if Rails.env != "production" && !PUBLIC_SYSTEM && !BUILD_SYSTEM
  # The debugger in ruby 2.0 has issue trying to stepping over, instead it always
  # try to step into. The byebug gem is a good replacement as it does not have
  # that issue and behaves very similar as the previous version of ruby debugger.
  debugger_in_use =  RUBY_VERSION.start_with?("1.9") ? 'debugger' : 'byebug'
  begin
    require debugger_in_use
  rescue Exception => e
    puts e.message
    puts "The gem #{debugger_in_use} was missing in the Gemfile under directory #{Rails.root}/../packages/ruby/"
  end
end
