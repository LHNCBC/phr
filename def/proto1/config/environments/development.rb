Proto1::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  config.eager_load = false

  # Enable the breakpoint server that script/breakpointer connects to
  # Deprecated in Rails 2.0
  #config.breakpoint_server = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching             = false
  #config.action_view.cache_template_extensions         = false
  #config.action_view.debug_rjs                         = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Directory for table backups made by the data controller
  DATA_CONTROLLER_BACKUP_DIR = '/proj/defExtra/dataTableBackups'

  # Remote debugger settings under Phusion Passenger
  debug_file = File.join(Rails.root, 'tmp', 'debug.txt')
  if File.exists?(debug_file)
    remote_debugger = RUBY_VERSION.start_with?("1.9") ? Debugger : Byebug
    remote_debugger.wait_connection = true
    remote_debugger.start_server
    File.delete(debug_file)
  end
  config.active_support.deprecation = :log

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  config.assets.digest = true

end




