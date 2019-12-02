require 'tempfile'
require "uglifier"
require "digest"
require 'fileutils'

# Manages the creation and path information for our generated JavaScript files
class JsGenerator
  # True if we are using the minimized, fingerprinted assets under
  # public/assets.
  @@using_production_assets = (Rails.env != 'development')
  @@production_asset_dir = Rails.root.join('public' +
     Rails.application.config.assets.prefix) # prefix starts with /
  @@development_js_dir = Rails.root.join('app/assets/javascripts')

  # Generates JavaScript file using the named specified by the constant
  # REMINDER_RULE_DATA_JS_FILE. The file should contain
  # rule data used for creating health reminders only. When a data rule was
  # created/edited/deleted, this file should be cleared using the 'remove' method
  # (see rule_controller.rb#rule_change_callback)
  # Parameters:
  # * temp_file a temp file object whose content will be used to replace the one in
  # the existing gnd_reminder_rule_data.js file
  def self.generate_reminder_rule_data_js(temp_file=nil)
    temp_file ||= self.reminder_rule_data_tempfile
    basename = File.basename(REMINDER_RULE_DATA_JS_FILE)
    self.generate_with_lock(temp_file, basename)
    temp_file.close
  end


  # Returns the full path of an asset file, or nil if a precompiled version 
  # is not found.
  # This method assumes that there is only one precompiled version available
  # (which should be fine for our purposes, since we delete the old ones when
  # there is a change).
  #
  # Parameters:
  # * file_name - name of a Javascript asset file
  def self.get_asset_fullpath(file_name)
    rtn = nil
    if @@using_production_assets
      file_wo_ext = min_name = File.basename(file_name, '.js')
      cwd = Dir.pwd
      FileUtils.mkdir_p(@@production_asset_dir, {mode: 0755})
      Dir.chdir @@production_asset_dir
      matches = Dir.glob(file_wo_ext+'-'+('?'*32)+'.js')
      file_name = matches && matches.length >= 1 && matches[0]
      rtn = File.join(@@production_asset_dir, file_name) if file_name
      Dir.chdir cwd
    else
      file_path = File.join(@@development_js_dir, file_name)
      rtn = file_path if File.exists?(file_path)
    end
    return rtn
  end


  # Returns a tempfile containing rule data written in Javascript code. This file
  # will be used for creating health reminders only.
  def self.reminder_rule_data_tempfile
    # Loads the latest rule definition JavaScript codes into the generated files
    options = RuleData.load_reminider_rule_data
    rule_def_js =<<-EOD
      Def.Rules.fetchRules_ = #{options[:fetch_rules].to_json};
      Def.Rules.reminderRules_ = #{options[:reminder_rules].to_json};
      Def.Rules.valueRules_ = #{options[:value_rules].to_json};
      Def.Rules.dataRules_ = #{options[:data_rules].to_json};
      Def.Rules.ruleActions_ = #{options[:rule_actions].to_json};
      #{options[:rule_scripts] && options[:rule_scripts].join("\n")}
    EOD
    temp_file = Tempfile.new(Time.now.to_i.to_s)
    File.open(temp_file.path, 'w') do |file|
      file.puts rule_def_js
    end
    temp_file
  end # reminder_rule_data_tempfile


  # Removes the JavaScript asset
  # Parameters:
  # * filename the name of the asset file needs to be removed
  def self.remove(filename)
    # remove assets in app/assets/javascripts directory
    path = Rails.root.join('app/assets/javascripts', filename)
    File.delete(path) if File.exist?(path)

    # remove assets in public/assets directory
    remove_production(filename)
  end


  # Removes the asset from the public/assets folder, if it exists
  # Parameters:
  # * filename the development name of the asset file needs to be removed
  def self.remove_production(filename)
    if @@using_production_assets
      path = get_asset_fullpath(filename)
      File.delete(path) if path and File.exist?(path)
    end
  end

  # Generates the specified JavaScript file based on the system mode
  #
  # Parameters:
  # * temp_file - the temporary file which holds the content of the file to be
  #   generated
  # * basename - Base name of the file to be generated
  # Returns - The result of generate_wo_lock
  def self.generate_with_lock(temp_file, basename)
    lockfile = AssetLockFile.convert_to_lockfile(basename)
    filename = nil
    AssetLockFile.run_with_lock(lockfile) do
      # dynamically generates js file and compress it if in production mode
      filename = self.generate_wo_lock(temp_file,  basename)
    end
  end


  # Assumes that a lock file has already been created, and moves the file at
  # temp_file into its place with the name provided in the "basename" parameter.
  #
  # Parameters:
  # * temp_file a temp file
  # * basename the base name of the generated js file
  # Returns:  nil for development mode; otherwise it returns the filename of the
  #  the generated file.  This will include a fingerprint when the assets are in
  #  production mode.
  def self.generate_wo_lock(temp_file, basename)
    generated_js = File.join(JS_ASSET, basename)
    system('mv', temp_file.path, generated_js)
    #self.refresh_cached_assets("rails_env")
    Rails.logger.debug("NewlyGeneratedFile: #{generated_js}")
    # set correct permission for the source asset file (non-compiled)
    File.chmod(0644, generated_js)
    filename = basename
    if @@using_production_assets
      remove_production(basename) # remove the old file
      # Create minimized, fingerprinted file, not using Sprockets, which caches
      # things in places not easy to reset.
      minified_content = Uglifier.compile(File.read(generated_js))
      fingerprint = Digest::MD5.hexdigest(minified_content)
      filename = File.basename(basename, '.js') + '-' + fingerprint + '.js'
      if (!File.exists?(@@production_asset_dir))
        FileUtils.mkdir_p(@@production_asset_dir, {mode: 0755})
      end
      min_path = File.join(@@production_asset_dir, filename)
      f = File.new(min_path, "w")
      f.syswrite(minified_content)
      f.close
      File.chmod(0644, min_path)
    end
    return filename
  end


end
