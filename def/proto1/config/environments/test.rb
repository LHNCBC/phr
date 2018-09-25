require 'webrick'
ActiveSupport::Deprecation.silenced = false

Proto1::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  config.eager_load = false


  # RAILS 2.2.2 caching config
  #config.action_controller.page_cache_directory = Rails.root.join "tmp/cache/"
  #config.action_controller.cache_store = :file_store, Rails.root + "/tmp/cache/"
  #config.cache_store = :file_store, Rails.root + "/tmp/cache"
  config.autoload_paths += %W( #{Rails.root.join("app/sweepers")} )

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Tell ActionMailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Directory for table backups made by the data controller
  DATA_CONTROLLER_BACKUP_DIR = '/proj/defExtra/dataTableBackups/test'

  #Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

#  # This is a fix for WEBrick's javascript mime type, which is needed when we
#  # run "rake test:javascripts".  Firebug 1.4 won't let you see files in the
#  # script tab unless the mime type for it is something it recognizes as text.
#  WEBrick::HTTPUtils::DefaultMimeTypes['js'] = 'application/x-javascript'
  config.active_support.deprecation = :stderr

  # To make it possible to debug JavaScript files when trying to pass acceptance
  # tests
  config.assets.debug = true
  config.assets.compress = false
  config.assets.digest = true
  config.assets.compile = true

  # Keep the tests running in the same order
  config.active_support.test_order = :sorted

  # turn off paper_trail to speed up tests
  config.after_initialize do
    PaperTrail.enabled = false
  end
end



