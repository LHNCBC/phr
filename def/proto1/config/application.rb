require File.expand_path('../boot', __FILE__)
require 'rails/all'

ActiveSupport::Deprecation.silenced = true
require File.expand_path("../suppress_deprecated_warning", __FILE__)

require File.expand_path("../constants", __FILE__)
require File.expand_path("../dependencies", __FILE__)

Bundler.require *Rails.groups(:assets => %w(development test))  if defined?(Bundler)

module Proto1
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Change the path that assets are served from
    # config.assets.prefix = "/assets"

    config.autoload_paths += [config.root.join('lib')]
    config.encoding = 'utf-8'
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.default_url_options =
      {:protocol=>'https', :host=>URL_HOST_NAME}


    config.action_mailer.smtp_settings = {
      # :address => "mailfwd.nih.gov" ,
      # Get the mail server name from the sendmail configuration file, because
      # the name (naturally) differs between insallation modes.
      :address=>`grep ^DS /etc/mail/sendmail.cf`.chomp[2..-1],
      :port => 25
    }
    #Settings in config/environments/* take precedence over those specified here
    # Skip frameworks you're not going to use (only works if using vendor/rails)
    # config.frameworks -= [ :action_web_service, :action_mailer ]

    # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
    # config.plugins = %W( exception_notification ssl_requirement )

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{Rails.root}/extras )

    # Force all environments to use the same logger level
    # (by default production uses :info, the others :debug)
    #config.log_level = :debug
    # NO.  Set the log_level to info for production systems and debug for
    #      development systems.  SQL statements, including their data, are
    #      written to the log at the debug level.  The ActionController base
    #      class writes all parameters (which might contain PII data) passed on
    #      calls to the server to the log at the debug AND info levels, but we
    #      have disabled logging of parameters for the public systems, so the info
    #      level is okay.
    cur_mode = Rails.env
    if PUBLIC_SYSTEM || cur_mode == 'production'
      config.log_level = :info # do NOT include more than :info, per comment above
    else
      config.log_level = :debug
    end

    # Make sure the production log level is not something other than :warn
    # on a public system, per the comment above about PII.
    if PUBLIC_SYSTEM && config.log_level == :debug
      raise 'log level is set incorrectly for a public system'
    end

    # Use the database for sessions instead of the file system
    # (create the session table with 'rake db:sessions:create')

    # If uncommented, a bug fix must be added. See Bug Fix for Oracle session store below.
    config.session_store = :active_record_store,    {
      :key => "_phr_session",
      # The "secret" below was generated with "rake secret", new as of Rails
      # 2.0.2.  See http://weblog.rubyonrails.org/2007/12/17/rails-2-0-2-some-new-defaults-and-a-few-fixes
      :secret => '5d97e405520ae76ec6df1b34e71a49e3bcbf243e612ebdb76e7a1be06ce344341ac47f18801c892a80e91d7d3c88cf204abc8428513a7c085626b255c7738ab2',
      # Generate a new secret each time we start up.  The has the drawback of
      # invalidating existing sessions, but protects us against accidentally
      # sending our secret key out when we share code.
      #:secret => `/depot/packages/ruby/bin/rake secret`,
      # Block javascript from reading session cookie
      :httpsonly => true,
      # cookie sent over SSL
      :secure=>true
    }

    #use numeric migration numbers
    config.active_record.timestamped_migrations = false

    # Use SQL instead of Active Record's schema dumper when creating the test database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector

    # Make Active Record use UTC-base instead of local time - nope, using local
    # config.active_record.default_timezone = :utc
    config.active_record.default_timezone = :local
    # Turn off time zone awareness conversions, messes up conversions in
    # UsageReport model class.
    config.active_record.time_zone_aware_attributes = false

    # See Rails::Configuration for more options
    config.force_ssl = REQUIRE_HTTPS

    if ENV['proxy_host'].nil?
      host = port = nil
    else
      host, port = ENV['proxy_host'].split(/:/)
    end
    config.cache_store = :file_store, Rails.root.join("tmp/cache")

    # The CSS files listed below are not manifest files. They can be found in
    # the files commented on the right side.
    precompile_css_list =  [
      'reminder_rules.css', #show_reminder_rules.erb
      'top_header_bar.css',# _header_template.rhtml.erb
      "manifest_form_layout_common.css", #form.rhtml.erb
      "manifest_base_package.css", # nonform.html.erb,  form.rhtml.erb, browser_support.html.erb
      "manifest_popup_page.css", # application_helper.rb#popup_assets
      "non_generated.css", # nonform.html.erb
      "data_index.css", # index.html.erb
      "load_time.css", # page_timer.rhtml
      'basic_html.css', # basic.erb
      'help_popup.css', # help_page_css.shtml
      'sprites.css', # used for loading images on help page etc
      'manifest_mobile.css', # used inside mobile.erb which the layout of mobile version PHR
      'atr.css' # used only for the acceptance tests (rake acceptance_tests)
    ]

    # Add form specific stylesheets
    # Cannot find the following files being used anywhere in our system. Will
    # keep them in the app/assets/stylesheets folder:
    # 1) 'two_factor_question.css'
    # 2) 'ct_search.css'
    # 3) 'forgot_id.css'
    form_css_dir = Rails.root.join("app/assets/stylesheets/#{FORM_CSS_DIR}")
    Dir.entries(form_css_dir).each do |e|
      if  e != "." && e != ".."
        precompile_css_list << "#{FORM_CSS_DIR}/#{e.gsub(/\.(erb|scss)/,"")}"
      end
    end

    # config.action_view.javascript_expansions = { :defaults => ['jquery', 'rails', 'etc'] }
    # form_js will be included in the generated_js files.
    config.assets.precompile += [
      'manifest_logged_in.js',
      'manifest_page_bottom.js',
      'maxlength.js', # required by browser_specific.js on IE only
      #'page_top.js',
      'manifest_popup_page.js',
      'manifest_jquery.js',
      'manifest_jquery_min.js',
      'manifest_mobile.js', # used by PHR version including jquery-mobile.js etc
      'manifest_jquery_sparkline_min.js',
      'manifest_jquery_sparkline.js',
      'manifest_jquery_show.js',
      'manifest_acceptance_test.js',
      REMINDER_RULE_SYSTEM_JS_FILE,
      REMINDER_RULE_DATA_JS_FILE,
      'manifest_page_timer.js',
      'help_popups.js'] + precompile_css_list

    # Defines the list of js and css assets used by any help popup pages.
    # The assets files being used in help_header.shtml and help_footer.shtml
    # should be generated using rake task generate_help_page_asset_files
    config.assets.help_page_js_list = %w(manifest_popup_page.js help_popups.js)
    config.assets.help_page_css_list = %w(help_popup.css sprites.css)

  end

  # Rails 3.2.3 changed the following setting to false as default which caused a
  # page rendering error when trying to edit help text. I googled but didn't
  # find the reason for that change. I reset it back to true to make to_json
  # method behave just like it was in Rails 2. - Frank
  ActiveSupport.escape_html_entities_in_json = true


  # Add new inflection rules using the following format
  # (all these examples are active by default):
  ActiveSupport::Inflector.inflections do |inflect|
  #   inflect.plural /^(ox)$/i, '\1en'
  #   inflect.singular /^(ox)en/i, '\1'
  #   inflect.irregular 'person', 'people'
  #   inflect.uncountable %w( fish sheep )
    inflect.uncountable 'feedback'
  end


  # Enable server side form validation
  #FormValidation.enable_form_validation("Personal Health Record")

 # Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# Rails.env ||= 'production'


# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

end

  # create logger function to return a logger object that was accessible before
  # a recent Rails update (2.3.2?)
  def logger
#    return ActionController::Base.logger
    return Rails.logger
  end

# changes to the database will be rolled back at the end of each test
# ("true" is the default.)
#Test::Unit::TestCase.use_transactional_tests = true


# Make the session cookie secure (i.e., set a flag that means it will only
# be sent along with https connections).
# Actually, don't do this.  Our whole session for the PHR is over https,
# and the RxTerms demo site doesn't use https at all (so it loses its session
# with this setting).
#ActionController::Base.session_options[:session_secure] = true


# include oracle adapter extensions
# require File.join(File.dirname(__FILE__), 'oracle_adapter_extension')
#require 'nih_adapter'


#require File.join(File.dirname(__FILE__), 'memory_profiler.rb')
#MemoryProfiler.start(:string_debug=>true)

# Enable server side form validation
#FormValidation.enable_form_validation("Personal Health Record")

