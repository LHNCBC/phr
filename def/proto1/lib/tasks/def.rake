require 'fileutils'

namespace :def do
  # Copies needed 3rdparty files into the proto1 directory.  Needs to be run
  # from the proto1 directory.  Interestingly, that seems to be the default
  # current directory when you run rake from some directory under proto1.

  desc "copy needed 3rd party files into the proto1 directory"
  task :third_party do

    if (FileUtils.pwd !~ /\/proto1$/)
      puts 'This task must be run from the proto1 directory.'
      exit
    end


    # create soft links in def/bin directory
#    %w(bundle gem irb rake ruby rails rdebug).each do |s|
#      if (!File.exists?("../bin/#{s}"))
#        File.symlink("/depot/packages/ruby1.9/bin/#{s}", "../bin/#{s}");
#      end
#    end
#    %w(mysql).each do |s|
#      if (!File.exists?("../bin/#{s}"))
#        File.symlink("/usr/bin/#{s}", "../bin/#{s}");
#      end
#    end

    # Set up link for jQuery and its plugins
    FileUtils.mkdir_p("vendor/assets/javascripts")
    if (!File.exists?('vendor/assets/javascripts/jquery'))
      File.symlink('/depot/packages/jquery', 'vendor/assets/javascripts/jquery');
    end
    if (!File.exists?('vendor/assets/javascripts/jquery-ui'))
      File.symlink('/depot/packages/jquery-ui', 'vendor/assets/javascripts/jquery-ui');
    end
    if (!File.exists?('vendor/assets/javascripts/jqueryPlugins'))
#      File.symlink('/depot/packages/jqueryPlugins', 'vendor/assets/javascripts/sub/jqueryPlugins/packages');
      File.symlink('/depot/packages/jqueryPlugins', 'vendor/assets/javascripts/jqueryPlugins');
    end

#    # Set up link for javascript_test plugin (Being moved into javascript_test.rake)
#    if (!File.exists?('test/javascript/assets'))
#      File.symlink('../../lib/javascript_test/assets', 'test/javascript/assets');
#    end

    # Set up a softlink for javascript-stacktrace
    if (!File.exists?('vendor/assets/javascripts/stacktrace.js'))
      File.symlink('/depot/packages/javascript-stacktrace/stacktrace.js',
       'vendor/assets/javascripts/stacktrace.js')
    end

    # Set up softlinks for the apache server
    if (!File.exists?('../apache/current'))
      File.symlink('/usr/lib64/httpd',
       '../apache/current');
    end

    # Make sure obsolete links are removed
    # The vendor stylesheets and related images should be moved to the folder:
    # public/vender_assets (see the code immediately after this section
    %w(jquery-ui jeegoocontext).each do |link|
      image_link = "vendor/assets/images/#{link}"
      css_link = "vendor/assets/stylesheets/#{link}"
      [image_link, css_link].each do |link_path|
        if File.exists?(link_path)
          system("rm -rf #{link_path}")
        end
      end
    end

    # create links for vendor stylesheets in public folder
    # this will help us solving the problem related to the relative image paths
    # used in vendor's css files
    path = "public/vendor_assets"
    FileUtils.mkdir_p(path) unless File.exists?(path)

    source = "../../app/assets/javascripts/jqueryPluginsExt" +
      "/jeegoocontext_1_3/jeegoocontext/skins/cm_default/"
    target = "#{path}/jeegoocontext_css"
    File.symlink(source, target) unless File.exists?(target)

    source = "/depot/packages/jquery-ui/css/start"
    target = "#{path}/jquery-ui_css"
    File.symlink(source, target) unless File.exists?(target)

    # Set up directories for ModSecurity
    if (!File.exists?('../apache/logs/modsec/audit'))
      FileUtils.mkdir_p('../apache/logs/modsec/audit')
    end
    if (!File.exists?('../apache/logs/modsec/data'))
      FileUtils.mkdir_p('../apache/logs/modsec/data')
    end
    if (!File.exists?('../apache/logs/modsec/log'))
      FileUtils.mkdir_p('../apache/logs/modsec/log')
    end
    if (!File.exists?('../apache/logs/modsec/upload'))
      FileUtils.mkdir_p('../apache/logs/modsec/upload')
    end
    if (!File.exists?('../apache/logs/modsec/tmp'))
      FileUtils.mkdir_p('../apache/logs/modsec/tmp')
    end
    #puts 'Running sudo to set ownership of apache/logs/modsec...'
    #system('sudo chown -R webserv ../apache/logs/modsec')
  end


  # Delete and rebuild the ferret indexes.
  desc "delete and rebuild the ferret indexes"
  task :rebuild_ferret_index => :environment do
    # We have a few model classes that we are keeping around for a while
    # but are no longer using.  Skip the index rebuild for those.
    skip_models = Set.new
    ['drugs_multum.rb', 'drug_ingredient.rb', 'rxnorm2_drug.rb',
     'rxnorm_drug.rb'].each {|m| skip_models << m}

    # Determine which model classes use the HasSearchableLists module.
    model_dir_path = 'app/models'
    Dir.new('app/models').grep(/^\w.*\.rb$/) do |file_name|
      if (!skip_models.member?(file_name))
        file_lines = IO.readlines(model_dir_path+'/'+file_name)
        if (file_lines.grep(/^\s*extend HasSearchableLists/).size > 0) &&
           # move LoincItem to the last for rebuilding index due to a dependency issue
           (file_name != "loinc_item.rb")
          # Rebuild the index
          model_class = file_name[0..-4] # remove the .rb
          model_class = model_class.camelize.constantize
          start = Time.new.to_i
          puts "Rebuilding index for #{model_class}"
          model_class.rebuild_index
          rebuild_time = Time.new.to_i - start
          puts "   Finished rebuild of #{model_class} index in #{rebuild_time}"+
            ' seconds'
        end
      end
    end
    # fix the dependency issue
    puts "Rebuilding index for loinc_item"
    LoincItem.rebuild_index
  end


  # Task for enabling remote debugger for Phusion Passenger.
  desc "DEBUG=true, enable remote debugger for Phusion Passenger"
  task :restart do
    system("touch tmp/restart.txt")
    system("touch tmp/debug.txt") if ENV["DEBUG"] == 'true'

    puts "****************************************************************"
    puts "Please finish the following steps to start the remote debugging:"
    puts "1) Reload the application in your web browser"
    puts "2) Run the following command:   rdebug -c"
    puts "****************************************************************"
  end


  # Gets the VCS lock and sets an EXIT signal trap to release the lock
  # when the task finishes.
  #
  # Parameters:
  # * branch - the branch name for which the lock is needed.  If not specified,
  #   this will use the the branch from which this file was loaded.  (The branch
  #   could have been changed since that happened.)
  def get_vcs_lock_until_exit(branch = nil)
    Vcs::vcs_commit_lock(true, branch)
    Signal.trap('EXIT') do
      puts 'Exiting.'
      Vcs::release_vcs_lock(branch)
    end
  end


  # Reloads the database and copies the ferret indexes from the baseline
  # system (unless the DUMPFILE parameter is specified, in which case the
  # ferret indexes won't be changed).
  # Note:  A nightly dump file is available at
  # /proj/defExtra/proto1_development_latest.sql
  #
  # Parameters:
  # * DUMPFILE - the path to a dump file to be used.
  # * have_vcs_lock - if true, the task assums that a calling process has
  #   already obtained the needed VCS lock, and also does not remove it.
  # * version - the version number of the release whose dump file should be
  #   loaded.  Use this to reload for a release branch.
  desc 'Reloads database & Ferret indexes.  '+
       'Optional parameter: DUMPFILE=<path_to_dumpfile>'
  task :reload_db => :environment do
    Dir.chdir(Rails.root)
    version = ENV['version']
    db_file = ENV["DUMPFILE"]
    copy_indexes = !version.nil? || db_file.nil?
    caller_has_vcs_lock = ENV['have_vcs_lock'] == 'true'
    db_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/database.yml")).result)
    host = db_config['development']['host']

    if !db_file
      if version=='latest'
        branch = Vcs::current_branch_name
        # If this is the master branch, and a particular version of the database
        # has not been requested,
        if branch != 'master'
          puts 'At present, version=latest is only supported for the master branch.'
          exit
        else
          # Get the VCS lock so we can copy the baseline database and indexes.
          # (Specify the branch name when getting the lock, because when this
          # task is called from change_branch, the Vcs class has the previous
          # branch name.)
          if !caller_has_vcs_lock
            caller_has_vcs_lock = Vcs::lock_if_available(branch)
            if caller_has_vcs_lock  # if we got the lock above
              Signal.trap('EXIT') do
                puts 'Exiting.'
                Vcs::release_vcs_lock(branch)
              end
            end
          end

          # If we could get the lock, make a temporary dump file of the
          # master branch database.
          if caller_has_vcs_lock
            db_file = Tempfile.new('proto1_development_now').path
            if !Util.echo_system(
              "mysqldump --lock-tables --skip-triggers -h #{host} " +
              "proto1_development > #{db_file}")

              puts 'Could not create a dump file of the database.'
              exit
            end
          else
            puts 'The master branch lock file was in use, so we will use the '+
             'nightly dump file of the master branch database.'
            db_file = '/proj/defExtra/faster_baseline_database.dump'
          end
        end
      else
        if !version
          # Use the version from defPackVersion.txt
          version = `cat #{Rails.root}/public/defPackVersion.txt`.chomp
        end
        db_file = "/proj/defExtra/versions/#{version}/proto1_development_with_user_tables_#{version}.sql"
      end
    end

    # At this point we should have a db_file
    raise 'Could not determine database dump file to load' if !db_file
    raise "File #{db_file} does not exist." if !File.exists?(db_file)
    raise "File #{db_file} is not readable." if !File.readable?(db_file)

    # Recreate the database
    dev_db = db_config['development']['database']
    user = db_config['development']['username']
    mysql_cmd = "/usr/bin/env mysql -h #{host} -D #{dev_db} -u #{user}"
    Util.echo_system(
      "echo 'drop database #{dev_db}; create database #{dev_db}; ' | #{mysql_cmd}")

    puts 'Loading data from dump file ' + db_file
    DatabaseMethod.reloadDatabase(db_file)
    puts 'Recreating triggers'
    Rake::Task['def:recreate_triggers'].execute

    # Recreate the test admin account, but only if this is not the public
    # system or a build system (which gets copied to the public
    # systems).
    begin
      if (!PUBLIC_SYSTEM && !BUILD_SYSTEM)
        puts 'Recreating test_admin account'
        Rake::Task['def:create_test_admin'].execute
      end
    rescue Exception => e
      # When the User model has changes depending on something not yet available
      # in the current backup database, we need to run this task after finishing
      # database migration
      puts ">>> (Failed) Please run task def:create_test_admin after "+
        "finishing database migration."
    end

    if copy_indexes
      puts 'Copying Ferret indexes'
      Dir.chdir(Rails.root)
      system('rm -rf index/*') || (puts 'Could not delete old indexes' && exit)
      if version && version != 'latest'
        cmd = "tar xfz /proj/defExtra/versions/#{version}/ferret_indexes.tgz"
      else
        cmd = "(cd /proj/def/proto1; tar cf - index) | tar xf -"
      end
      puts cmd
      system(cmd) || (puts 'Could not copy indexes' && exit)
    end
  end


  desc "Recreate MySQL triggers from files at db/triggers/"
  task :recreate_triggers => :environment do
    trigger_dir = File.join(Rails.root, "/db/triggers")
    trigger_files = Dir.new(trigger_dir).entries
    trigger_files.each do |file_name|
      if file_name.match(/\ACREATE/)
        DatabaseMethod.reloadDatabase(trigger_dir + "/" + file_name)
      end
    end
  end

  desc "Drop all MySQL triggers"
  task :drop_triggers => :environment do
    trigger_dir = File.join(Rails.root, 'db/triggers')
    trigger_files = Dir.new(trigger_dir).entries
    trigger_files.each do |file_name|
      if file_name.match(/\ADROP/)
        DatabaseMethod.reloadDatabase(trigger_dir + "/" + file_name)
      end
    end
  end


  desc 'Change to a release branch for a tagged version, or back to '+
    'the master branch'
  task :change_branch => :environment do
    branch = ENV['branch']
    ENV.delete('branch') # so reload_db doesn't see it
    if !branch
      raise 'Specify branch=r41-branch to switch to the r41-branch, or '+
        'branch=master to switch to the master branch.'
    else
      # Before changing branches, delete the schema file, which is untracked.
      schema_file = File.join(Rails.root, 'db', 'schema.rb')
      File.delete(schema_file) if File.exists?(schema_file)
      # In the following command, we determine that the code probably needs
      # an update if either "git pull --dry-run" shows something for the branch,
      # or (if a fetch has been done for the branch but no merge has been done)
      # the local repository is ahead of the branch.
      code_needs_update = !`sh -c '#{Vcs::GIT_CMD} pull --dry-run 2>&1' | grep #{branch}`.blank? ||
        !`#{Vcs::GIT_CMD} log origin/#{branch} ^#{branch}`.blank?
      system("#{Vcs::GIT_CMD} checkout #{branch}") ||
        raise("Could not switch to #{branch}")
      Rake::Task['def:reload_db'].execute
      Rake::Task['db:migrate'].execute
      if code_needs_update
        puts
        if branch=='master'
          puts 'WARNING:  You should run git pull to update your files.'
        else
          puts 'WARNING:  It looks like your files are not up to date.  You '+
            'might want to run git pull and then rake db:migrate to make sure '+
            'your files and database are in sync.'
        end
      end
    end
  end


  desc "Import a profile's user data; " +
       "Required: PROFILE_ID=<p_id>, Optional: FILE_NAME=<f_name>, " +
       "REPLACE_ID=<true|false>, DELETE_EXISTING_PROFILE_DATA=<true|false>"
  task :import_a_profile_data =>:environment do
    profile_id = ENV["PROFILE_ID"]
    replace_id = ENV['REPLACE_ID'] == 'true'
    if profile_id.blank?
      raise "Parameter PROFILE_ID is required"
    else
      file_name = ENV["FILE_NAME"]
      profile_id = profile_id.to_i
      # drop 2 triggers
      puts 'Dropping triggers ...'
      Rake::Task['def:drop_triggers'].execute
      # delete existing profile data
      delete_existing_data = ENV["DELETE_EXISTING_PROFILE_DATA"] == 'true'
      if delete_existing_data
        puts 'Deleting existing profile data ...'
        Util.delete_a_profile_data(profile_id)
      end
      # import data
      puts 'Importing profile data ...'
      Util.import_a_profile_yml(profile_id, file_name, replace_id)
      # update tables affected by triggers (latest_obx_record)
      Util.update_latest_obx_records(profile_id.to_i)
      # recreate 2 triggers
      puts 'Recreating triggers ...'
      Rake::Task['def:recreate_triggers'].execute
    end
  end


  desc "Export a profile's user data; " +
       "Required: PROFILE_ID=<p_id>, Optional: FILE_NAME=<f_name>"
  task :export_a_profile_data =>:environment do
    profile_id = ENV["PROFILE_ID"]
    if profile_id.blank?
      raise "Parameter PROFILE_ID is required"
    else
      file_name = ENV["FILE_NAME"]
      profile_id = profile_id.to_i
      # export data
      puts 'Exporting profile data ...'
      Util.export_a_profile_yml(profile_id, file_name)
    end
  end


  # create demo user accounts with precreated sample data
  desc 'Create demo user accounts with precreated sample data.' +
       'optional parameter: NUM=<number of accounts to be created>'
  task :create_demo_accounts => :environment do
    num = ENV['NUM']
    if !num.nil? && num.to_i > 0
      Util.create_demo_accounts(num.to_i)
    else
      Util.create_demo_accounts
    end
  end


  desc "Creates the 'test admin' user (if this is a development system)"
  task :create_test_admin => :environment do
    raise 'This is not a development system' if PUBLIC_SYSTEM || BASELINE_SYSTEM
    test_admin_name = "test_admin"
    unless User.find_by_name(test_admin_name)
      u = User.new()
      u.name= test_admin_name
      u.password = u.password_confirmation = 'TBD - specify for your system' # satisfy validation
      u.hashed_password="TBD - specify for your system"
      u.salt= "TBD - specify for your system"
      u.admin=true
      u.user_id="00000"
      u.pin='1234'
      u.birth_date = '2004/12/4'
      u.email = 'emailaddress@your.organization.com'
      u.save!
      # Add security questions
      [0,1].each {|t| u.add_question(t, '1', '1'); u.add_question(t, '2', '1');}

      # Add a cookie for two-factor authentication.
      TwoFactor.create!(:user_id => u.id,
                :cookie=>'3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81')

      # Activate the new account
      error, flash = EmailVerification.match_token(u, u.email_verifications[0].token)
      raise "Failed on activating the new account #{u.name}" if error
    end
  end

  desc "Rebuilds js_function and associations for every rule "+
       "based on it's expression and actions"
  task :rebuild_rules => :environment do

    LoincFieldRule.destroy_all

    Rule.all.each do |r|
      r.save!
    end

    # Deletes orphan rule_cases and rule_actions
    [RuleCase, RuleAction].each do |klass|
      klass.all.select{|s| !s.valid?}.map do |e|
        if e.errors.full_messages.join.include?("orphan")
          print "Destroying orphan record: #{klass.to_s}/#{e.id} ... "
          e.destroy
          puts  klass.find_by_id(e.id) ? " Failed" : " Succeed"
        end
      end
    end
    puts "\n*** Rebuilding rule is done"
  end



  desc 'Gets the vcs commit lock'
  task :vcs_lock do
    wait = ENV['wait']=='true'
    require 'vcs'
    Vcs::vcs_commit_lock(wait)
  end

  desc 'Release the vcs commit lock'
  task :release_vcs_lock do
    require 'vcs'
    Vcs::release_vcs_lock
  end

  desc 'Gets the web server restart lock'
  task :restart_lock do
    require 'restart_manager'
    if !RestartManager.restart_lock
      raise 'Could not get the restart lock because a restart has been requested.'
    end
    puts 'got restart lock'
  end


  desc 'Release the web server restart lock'
  task :release_restart_lock do
    puts 'releasing restart lock'
    require 'restart_manager'
    RestartManager.release_restart_lock
  end


  desc 'Copies FFAR tables from the baseline database to the database '+
    'in the current environment.'
  task :update_ffar_tables => [:environment, :vcs_lock]  do
    begin
      # Do some more requisites.  We can't list them normally, because
      # we need to release the vcs lock if they fail.
      Rake::Task['def:vcs_update'].invoke

      # Do what db:abort_if_pending_migrations does, except throw an
      # exception instead of aborting.  (We need to release the vcs lock.)
      # This part of the code is based on the code in the rails task.
      pending_migrations =
        ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations
      if pending_migrations.any?
        raise "You have #{pending_migrations.size} pending migrations."
      end

      # Make sure the baseline area is not at a lower migration level, which
      # would like result in problems for the current environment's database.
      ActiveRecord::Base.establish_connection('baseline')
      baseline_schema_version = ActiveRecord::Migrator.current_version
      # While we're connected there, get the list of tables to copy
      tables_to_copy = DatabaseMethod.get_non_user_data_tables
      ActiveRecord::Base.establish_connection(Rails.env)

      env_schema_version = ActiveRecord::Migrator.current_version
      if (env_schema_version != baseline_schema_version)
        raise 'Your schema version level is not the same as the baseline\'s.'+
          '  Correct that problem and try again.'
      end

      DatabaseMethod.copy_tables('baseline', Rails.env, tables_to_copy)
    rescue
      puts $!
      puts $!.backtrace
      # continue to allow the vcs commit lock to be released
    end
    Vcs::release_vcs_lock
  end

  desc 'Create/update rules for displaying total scores in test panels'
  task :refresh_score_rules => :environment do
    ActiveRecord::Base.transaction do
      Rule.where(:rule_type=>"score").map(&:destroy)
      if ENV["DELETE"] != "true"
        Rule.load_score_rules
      end
    end
  end

  desc 'Switches the working area to the development or production mode'
  task :change_rails_mode do
    mode = ENV['mode']
    if !mode || !(mode=='development' || mode == 'production')
      puts 'Usage:  rake def:change_rails_mode mode=[development || production]'
    else
      rails_mode_file = "#{Rails.root}/../apache/conf/railsDevelopmentMode.txt"
      # Unblocks permissions for source files under uncompressed folders
      #system("chmod 755 #{Rails.root}/public/javascripts/uncompressed")
      if mode=='development'
        system("echo 'RailsEnv development' > #{rails_mode_file}")
        puts "Start to clean compiled asset files ..."
        Rake::Task['assets:clobber'].invoke
        system("cd #{Rails.root}; rake def:generate_help_page_asset_files RAILS_ENV=#{mode}")
        #system("rm `find #{Rails.root}/public/javascripts/compressed/ -name '*.js'`")
        #system("rm `find #{Rails.root}/public/javascripts/compressed/ -name '*.gz'`")
        #system("rm #{Rails.root}/public/stylesheets/*_packaged.css")
      else # production
        system("echo '' > #{rails_mode_file}")
        puts "Start to precompile asset files ..."
        Rake::Task['tmp:cache:clear'].invoke
#        system("cd #{Rails.root}; rake assets:precompile RAILS_ENV=production")
        system("cd #{Rails.root}; rake def:setup_assets RAILS_ENV=#{mode}")
        #Rake::Task['assets:precompile'].invoke
        #Rake::Task['asset:packager:build_all'].invoke
        #system("cd #{Rails.root}; script/compressFFARJS")
        #system("chmod 644 #{Rails.root}/public/javascripts/compressed/*.*")
        #Block access to uncompressed folder
        #system("chmod 700 #{Rails.root}/public/javascripts/uncompressed")
      end
      # system restart will clear the cache and thus re-generate compressed
      # form-based JavaScript files
      if File.exists?("#{Rails.root}/../apache/logs/httpd.pid")
        system("cd #{Rails.root}/../apache; ./apache.sh restart")
      end
    end
  end

  desc "Setup assets for the production mode"
  task :setup_assets do
    if ENV["RAILS_ENV"] == "production"
      precompile_cmd = "cd #{Rails.root}; rake assets:precompile"
      if !system(precompile_cmd)
        # Sometimes the asset precompilation fails, if so, usually running it a
        # second time fixes the problem.  It seems to be a bug in either Compass
        # or Sass.
        puts 'rake assets:precompile failed; trying again'
        system(precompile_cmd) || raise('rake assets:precompile failed twice.  Giving up.')
      end
      system("cd #{Rails.root}; rake def:generate_help_page_asset_files")
      system("cd #{Rails.root}; rake def:setup_images_for_help_pages")
    end
  end

  desc "Make images assets available for help pages in production mode"
  task :setup_images_for_help_pages do
    if ENV["RAILS_ENV"] == "production" && Rails.public_path.join("help").exist?
      # copy images assets from app/assets/images into public/assets as needed
      image_files = %w(blank.gif)
      files_not_found =[]
      source_dir = Rails.root.join("app/assets/images")
      target_dir = File.join(Rails.public_path,
                             Rails.application.config.assets.prefix)
      puts 'Copying of the images files for help pages: '
      image_files.each do |fn|
        sfile = File.join(source_dir, fn)
        if File.exists?(sfile)
          system("cp #{sfile} #{target_dir}/.")
          print "."
        else
          files_not_found << sfile
        end
      end
      puts "Copying is completed."
      puts "ListOfFilesNotFound: #{files_not_found}" if !files_not_found.empty?
    end
  end

  # Find and destroy any temporary accounts that have expired.
  desc "purge any temporary accounts that have expired"
  task :purge_expired_accounts => :environment do
    system("cd #{Rails.root}")
    system("PATH=$PATH:/proj/def/bin")
    system("export PATH")
    User.remove_expired_accounts
  end # purge_expired_accounts

  # Per Paul, due to the license issue with ruby-debug gems, we need to separate them
  # from the gems used on production systems
  desc "Install ruby-debug19 and dependencies on local dev machine"
  task :install_dev_gems_193 => :environment do
    FileUtils.chdir("/depot/packages/rubybuild/ruby_dev_gems")
    system("gem install --user-install linecache19-0.5.13.gem -- --with-ruby-include=/depot/packages/rubybuild/ruby_header")
    system("gem install --user-install ruby-debug-base19-0.11.26.gem -- --with-ruby-include=/depot/packages/rubybuild/ruby_header")
    system("gem install --user-install ruby-debug19-0.11.6.gem -- --with-ruby-include=/depot/packages/rubybuild/ruby_header")
    system("gem install --user-install timecop")

    # Adds the softlink for rdebug
    system("ln -s #{Gem.path[1]}/bin/rdebug ~/def/bin/rdebug")
    puts "*************************************************************************"
    puts "****** Please run 'rehash' command before using the rdebug command ******"
    puts "*************************************************************************"
  end

  desc "Install gems compatible with Ruby 2.0 on development machine"
  task :install_dev_gems => :environment do
    system("gem install --user-install timecop")
  end

  # Find and update any unassigned or incomplete captcha and login events
  desc "Updates incomplete/usassigned usage event data."
  task :update_unassigned_events => :environment do
    system("cd #{Rails.root}")
    system("PATH=$PATH:/proj/def/bin")
    system("export PATH")
    UsageReport.update_unassigned_events
  end # update_unassigned_events

  desc 'Imports a rule and its referenced rules into a form'
  task :import_rule => :environment do
    form_name = ENV['form']
    rule_name = ENV['rule']
    revert    = ENV['revert']

    # The rule should be a form rule
    rule = Rule.where(:name=>rule_name).where(["rule_type in (?)", [Rule::GENERAL_RULE, Rule::CASE_RULE]]).take
    form = Form.find_by_form_name(form_name)

    # missing input parameters
    if !form_name || !rule_name
      puts 'Usage:  rake def:import_rule form=a_form_name rule=a_rule_name'
    # wrong input parameters
    elsif !rule
      puts 'Error Message: Cannot find the form rule as specified.'
    # wrong input parameters
    elsif !form
      puts 'Error Message: Cannot find the form as specified.'
    else
      if revert == "true"
        # do reverting
        puts "Removing rule '#{rule.name}'..."
        # rule to be taken away from the form does not exist
        if !form.rules.include? rule
          puts "Reminder: '#{rule.name}' rule does not exist."
        # found error while removing the rule away from the form
        else
          Rule.transaction do
            rule.form_ids = rule.form_ids - [form.id]
            if !rule.save
              raise "Removing of rule: #{rule.name} failed. Error: #{rule.errors.full_messages.join("/")}"
            end
            puts "Removing of rule '#{rule.name}' from form '#{form.form_name}' is done."
          end
        end
      else
        # do importing
        puts "Importing rule '#{rule.name}'..."
        # rule to be imported into the form is already on the form
        if form.rules.include? rule
          puts "Reminder: '#{rule.name}' is an existing rule of form '#{form.form_name}'. Rule importing is cancelled."
        # found error while importing the rule into the form
        else
          existing_rules = form.rules
          Rule.transaction do
            Rule.complete_rule_list([rule], "uses_rules").each do |r|
              unless existing_rules.include? r
                r.forms << form
                if !r.save
                  raise "Importing of rule: #{r.name} failed. Error: #{r.errors.full_messages.join("/")}"
                end
              end
            end
            puts "Importing of rule '#{rule.name}' into form '#{form.form_name}' is done."
          end
        end
      end
    end
  end #import_rule


  desc "Regenerate the JS for the reminder rules (needed in the basic mode)"
  task :generate_reminder_rule_js => :environment do
    JsGenerator.remove(REMINDER_RULE_DATA_JS_FILE)
    JsGenerator.generate_reminder_rule_data_js
  end


  desc "Pre-load fragment caches for specified forms"
  task :preload_fragment_caches => :environment do
    require 'net/https'
    unless host = ENV['PRELOAD_HOST']
      raise "***** Please specify host name, e.g. PRELOAD_HOST=phr-master"
    end
    uri = URI.parse("https://#{host}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    puts "********* Started the preloading of fragment caches *************"
    failure_count=0
    http.start do |conn|
      puts conn.inspect
      if ENV['FORM']
        forms_cached = Form.where(:form_name=>ENV['FORM'].downcase.split("|"))
      else
        forms_cached = Form.where(["preload_fragment_cache =?", true])
      end
      #forms_cached.map(&:form_name).each do |fn|
      forms_cached.each do |fn|
        s = Time.now
        #fn = fn.downcase
        #uri=URI.parse("https://#{host}/form/test/#{fn}")
        fname = fn.form_name.downcase
        uri=URI.parse("https://#{host}/form/test/#{fname}")
        request = Net::HTTP::Get.new(uri.request_uri)
        response=conn.request(request)
        if response.code == "200"
          st = ""
        else
          failure_count +=1
          st = "*Failed: HTTP StatusCode #{response.code}* "
        end
        puts "#{fname}(#{(Time.now - s).round(3)} s) #{st}..."
        # now generate a read-only version if one is needed
        if fn.needs_read_only_version == true
          fname = fname + '_RO'
          uri=URI.parse("https://#{host}/form/test/#{fname}")
          request = Net::HTTP::Get.new(uri.request_uri)
          response=conn.request(request)
          if response.code == "200"
            st = ""
          else
            failure_count +=1
            st = "*Failed: HTTP StatusCode #{response.code}* "
          end
          puts "#{fname}(#{(Time.now - s).round(3)} s) #{st}..."
        end
      end
    end
    puts
    success_msg = "********* Success: Fragment caches were loaded for all specified forms *************"
    failure_msg = "********* Failure: Fragment caches were not loaded for #{failure_count} forms *************"
    puts failure_count == 0 ? success_msg : failure_msg
  end


  desc "Generates help page asset files"
  task :generate_help_page_asset_files => :environment do
    asset_hash = {"js" => Rails.application.config.assets.help_page_js_list,
                  "css"=> Rails.application.config.assets.help_page_css_list }

    non_prod = ENV["RAILS_ENV"] == "production" ? false : true

    helper = ActionView::Base.new
    %w(js css).each do |asset_type|
      asset_link_method = asset_type == "js" ? "javascript_include_tag" : "stylesheet_link_tag"

      # get list of asset files
      asset_list =  asset_hash[asset_type]
      # update asset filenames with the digest/hashtags
      text_list = asset_list.map do |asset_name|
        helper.send(asset_link_method, asset_name, :debug=>non_prod)
      end
      text = text_list.join("\n")

      # write into the asset file
      file = Rails.public_path.join("help", "help_page_#{asset_type}.shtml")
      File.open(file,"w"){|f| f.puts text}
    end
  end


  desc "Update health reminders for all profiles"
  task :update_health_reminders => :environment do
    s_total= Time.now
    post_opts = {"page_view" => 'basic', "debug" => "true"}
    profiles = User.all.map(&:profiles).flatten
    fd =FormData.new("phr")
    # JavaScript server uri for retrieving reminders.
    # See /lib/js_server/config.json for details
    file_path = Rails.root.join(JS_SERVER_CONF_FILE)
    js_config = JSON.parse(File.read(file_path))
    post_uri = js_config["uri"]

    s_gen = Time.now
    # Check to see if the REMINDER_RULE_DATA_JS_FILE exists
    # There are two cases when the file is missing:
    # 1) In the application source code git repository
    # 2) After creating, editing or deleting of any dat rule via the PHR data
    #    rule management pages (i.e.  /rules)
    asset_path = JsGenerator.get_asset_fullpath(REMINDER_RULE_DATA_JS_FILE)
    if !asset_path
      JsGenerator.generate_reminder_rule_data_js
    end
    js_files = [REMINDER_RULE_SYSTEM_JS_FILE, REMINDER_RULE_DATA_JS_FILE]
    if !Rails.application.config.assets.debug
      js_files = js_files.map { |e| JsGenerator.get_asset_fullpath(e) }
    else
      app_helper = ActionView::Base.new
      rtn = []
      js_files.map do |e|
        app_helper.javascript_include_tag(e).split("\n").map do |sub_file|
          # Tries to get the file names from javascript include tags
          # From '<script src="/assets/prototype.js?body=1"' To "/assets/prototype.js"
          js_file = sub_file.split("\/assets\/")[1].split(".js")[0].split("-")[0] + ".js"
          rtn << JsGenerator.get_asset_fullpath(js_file)
        end
      end
      js_files = rtn
    end
    d_gen = Time.now - s_gen
    post_opts = post_opts.merge({"js_files" => js_files.join(",")})


    outputs = []
    tab_space = "\t\t\t"
    outputs <<  %w(user_name taffydb_time post_request caching_reminder complete_action).join(tab_space.gsub(/\t$/, ""))
    s_outputs = []
    User.all.each do |user|
      s_sub_total = Time.now
      profiles = user.profiles
      if (!profiles.empty?)
        s_taffy = Time.now
        data_tables = nil
        autosaves = AutosaveTmp.where("user_id" => user.id, "base_rec" => true, "form_name" => "phr",
                                      "profile_id" => profiles.map(&:id))
        if (autosaves && (autosaves.size == profiles.size))
          pf ={}; profiles.each { |e| pf[e.id.to_s] = e.id_shown }
          data_tables = autosaves.map do |as|
            "\"#{pf[as.profile_id]}\"" + ":" + as.data_table
          end.join(",")
          data_tables = "[{#{data_tables}}]"
        else
          data_tables = {}
          profiles.each do |profile|
            user_data = fd.get_data_table_by_profile(profile.id)
            data_tables[profile.id_shown] = user_data
            # commented out per Frank 8/14/14
            # AutosaveTmp.set_autosave_base(user, profile.id, "phr", user_data, false, false)
          end
          data_tables = [data_tables].to_json
        end
        # JavaScript eval() cannot covert back the Hash object from its json
        # format. But it work okay with the Array object
        post_opts["profiles"] = data_tables
        d_taffy = Time.now - s_taffy

        # Sends post request to retrieve the reminders
        s_post = Time.now
        resp = Net::HTTP.post_form(URI(post_uri), post_opts)
        d_post = (Time.now - s_post)

        reminders_str = resp.body
        # Removes the anchors for the more/less links
        reminders_str = reminders_str.gsub(/\s*\(more\)\s*/, " ") if reminders_str.index("more")
        rtn = JSON.parse(reminders_str)[0]

        # Cache the reminders by
        # 1) Update the reminder creation timestamp on the profile
        # 2) Outdate the old reminders
        # 3) Create new reminder records if they cannot be found in the newly generated reminders list
        s_backup = Time.now
        rtn.each_key do |id_shown|
          message_map = rtn[id_shown][0]
          creation_date = rtn[id_shown][1]
          HealthReminder.update_reminders_for_profile(id_shown, message_map, creation_date)
        end
        d_backup = Time.now - s_backup
        d_sub_total = (Time.now - s_sub_total)

        list = [d_taffy, d_post, d_backup, d_sub_total].map { |e| (e * 1000).round(2) }.join(tab_space)
        user_tab = ""; (3 - user.name.length/8).times { user_tab +="\t" }
        s_outputs << user.name + user_tab + list
      end
    end
    outputs << s_outputs.join("\n")

    s_outputs=[]
    s_outputs << "Time for making generated js file is: #{(d_gen * 1000).round(2)}  ms"
    d_total = (Time.now - s_total)
    s_outputs << "Time for completing this action is: #{ (d_total*1000).round(2)}  ms"
    outputs << s_outputs.join("\n")

    puts outputs.join("\n\n")
  end


end  # def.rake

#namespace :db do
#  namespace :test do
#    task :prepare => ['db:abort_if_pending_migrations', :environment] do
#      DatabaseMethod.copy_development_db_to_test
#      ENV['RAILS_ENV']='test' # for db:fixtures:load
#      Rake::Task['db:fixtures:load'].execute('RAILS_ENV'=>'test')
#    end
#  end
#end
