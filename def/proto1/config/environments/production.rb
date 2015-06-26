Proto1::Application.configure do 
  # Settings specified here will take precedence over those in config/environment.rb

  # This setting was advised by rails when it was missing, via a repeated warning.  I do
  # not know what the options are, and have not found documentation for it.
  config.active_support.deprecation = :notify
  config.eager_load = true

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true
  # In Rails 4, config.threadsafe! is deprecated. Rails applications behave by default as thread safe
  # in production as long as config.cache_classes and config.eager_load are set to true.
  #config.threadsafe!

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  #config.action_controller.fragment_cache_store = [:file_store, "#{Rails.root}/tmp/cache"] 
  #ActionController::Caching::Pages.page_cache_directory
  # New option for production available as of Rails 2.0.2
  # See http://weblog.rubyonrails.org/2007/12/17/rails-2-0-2-some-new-defaults-and-a-few-fixes
  #config.action_view.cache_template_loading = true
  # RAILS 2.2.2 caching config
  #config.action_controller.page_cache_directory = Rails.root.join "public/cache/"
  #config.action_controller.cache_store = :file_store, Rails.root + "/tmp/cache/"

  #config.cache_store = :file_store, Rails.root + "/tmp/cache"
  config.autoload_paths += %W( #{Rails.root.join("app/sweepers")} )
  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host                  = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Directory for table backups made by the data controller
  DATA_CONTROLLER_BACKUP_DIR = '/proj/defExtra/dataTableBackups'


# Compress JavaScripts and CSS
config.assets.compress = true
 
# Choose the compressors to use
config.assets.js_compressor  = :uglifier
config.assets.css_compressor = :yui
 
# Don't fallback to assets pipeline if a precompiled asset is missed
config.assets.compile = false
 
# Generate digests for assets URLs.
config.assets.digest = true
 
# Defaults to Rails.root.join("public/assets")
# config.assets.manifest = YOUR_PATH
 
# Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
# config.assets.precompile += %w( search.js )
end

