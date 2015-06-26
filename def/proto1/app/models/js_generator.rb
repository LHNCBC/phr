require 'tempfile'
class JsGenerator
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
  
    
  # Returns the full path of the inputting asset file based on different modes
  # Parametes:
  # * file_name name of a Javascript asset file 
  def self.get_asset_fullpath(file_name)
    if Rails.application.config.assets.debug
      env = Rails.application.assets
      rs = env.find_asset(file_name)
      rs && rs.pathname.to_s
    else
      manifest = Rails.application.asset_manifest
      rs = manifest.assets[file_name]
      rs && File.join(manifest.dir, rs)
    end
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
    if asset = Rails.application.assets[filename]
      rjs = asset.pathname.to_s
      system("rm #{rjs}") if rjs
    end
    
    # remove assets in public/assets directory
    if !Rails.application.config.assets.debug
        manifest = Rails.application.asset_manifest(true)
        digested_file = manifest.assets[REMINDER_RULE_DATA_JS_FILE]
        manifest.remove(digested_file) if digested_file
        self.refresh_cached_assets("action_view")
    end
  end


  # Generates the specified JavaScript file based on the system mode
  # 
  # Parameters:
  # * temp_file - the temporary file which holds the content of the file to be 
  #   generated
  # * basename - Base name of the file to be generated
  def self.generate_with_lock(temp_file, basename)
    lockfile = AssetLockFile.convert_to_lockfile(basename)
    AssetLockFile.run_with_lock(lockfile) do 
      # dynamically generates js file and compress it if in production mode
      self.generate_wo_lock(temp_file,  basename)
    end       
  end

  
  # Parameters:
  # * temp_file a temp file
  # * basename the base name of the generated js file
  def self.generate_wo_lock(temp_file, basename)
    generated_js = File.join(JS_ASSET, basename)
    system('mv', temp_file.path, generated_js)
    #self.refresh_cached_assets("rails_env")
    Rails.logger.debug("NewlyGeneratedFile: #{generated_js}")
    # set correct permission for the source asset file (non-compiled)
    File.chmod(0644, generated_js)
    if !Rails.application.config.assets.debug
      manifest = Rails.application.asset_manifest(true)
      manifest.compile([basename])
      self.refresh_cached_assets("action_view")
      # set the correct permission for the compiled asset file
      File.chmod(0644, self.get_asset_fullpath(basename))
    end
  end


  # A method for refreshing cached assets in different places
  # Parameters:
  # * scope the place where the assets were cached
  def self.refresh_cached_assets(scope)
    case scope
      when "rails_env"
        Rails.application.refresh_cached_assets
      when "action_view"
        env = Rails.application.assets
        manifest_path = ActionView::Base.new.assets_manifest.dir
        ActionView::Base.instance_eval do
          # Need to fresh the assets_environment if the environment was cached in Sprockets::Index
          if Rails.application.config.assets.compile
            if Rails.application.assets.is_a? Sprockets::Index
              self.assets_environment = env
              self.assets_manifest    = Sprockets::Manifest.new(env, manifest_path)
            end
            # Replacing the existing static assets
          else
            self.assets_manifest = Sprockets::Manifest.new(manifest_path)
          end
        end
      else
        raise "Unknown input parameter for method JsGenerator.refresh_cached_assets"
    end
  end


end


