class InstallationChange < ActiveRecord::Base
  # The installation mode name for the alternate installation
  INSTALLATION_NAME_ALTERNATE = 'TBD - alternate'
  # The installation display name for an alternate installation
  INSTALLATION_DISPNAME_ALTERNATE = 'TBD - Alternate Installation name'

  # The installation mode name for the default mode 
  INSTALLATION_NAME_DEFAULT = 'default'
  # The installation display name for the default mode 
  INSTALLATION_DISPNAME_DEFAULT = 'TBD - YOUR PHR NAME'

  # The path to the file containing the name of the current installation mode.
  INSTALLATION_MODE_FILE = File.expand_path(
    "../../../public/installation_name.txt", __FILE__)

  # Changes the installation mode to the one specified.
  #
  # Parameters:
  # * inst_name - the name of the installation mode to switch to
  def self.change_installation(inst_name)
    InstallationChange.where(installation: inst_name).to_a.each do |ic|
      ic.perform
    end

    # Copy files into place
    copy_installation_files(Rails.root, inst_name)

    # Update INSTALLATION_MODE_FILE
    system("echo #{Shellwords.escape(inst_name)} > #{Shellwords.escape(INSTALLATION_MODE_FILE)}")
  end


  # Returns the name of the current installation mode.
  def self.installation_name
    File.exists?(INSTALLATION_MODE_FILE) ?
      File.read(INSTALLATION_MODE_FILE).chomp :
      INSTALLATION_NAME_DEFAULT
  end


  # Returns the display name of the current installation.
  def self.installation_display_name
    mode_name = InstallationChange.installation_name
    return mode_name == INSTALLATION_NAME_DEFAULT ?
                          INSTALLATION_DISPNAME_DEFAULT :
                          INSTALLATION_DISPNAME_ALTERNATE
  end


  # Returns true if the system is in the default installation mode (i.e.
  # not in the alternate mode, but the default mode.)
  def self.in_default_mode?
    InstallationChange.where(
        :installation=>INSTALLATION_NAME_DEFAULT).count == 0
  end


  # Returns a list of installation mode names
  def self.installation_modes
    [INSTALLATION_NAME_DEFAULT, INSTALLATION_NAME_ALTERNATE]
  end


  # Processes this installation change instance.  If this is not for the default
  # installation, a default InstallationChange will be created so that the
  # change can be undone when returning to the default installation.
  #
  # Parameters:
  # * create_default_ic - (default true) If this is false, then an installation
  #   change for returning to the default installation will not be created even
  #   if this InstallationChange is not for the default installation.
  def perform(create_default_ic = true)
    rec =
      table_name.singularize.camelize.constantize.find_by_id(record_id)
    inst_name = installation
    default_inst_str = InstallationChange::INSTALLATION_NAME_DEFAULT
    inst_name_is_default = inst_name == default_inst_str
    if !inst_name_is_default && create_default_ic
      # Create a default entry (to allow us to restore the default settings)
      # if one does not already exist.
      ic_params =  {installation: default_inst_str, table_name: table_name,
                    column_name: column_name, record_id: record_id}
      default_ic = InstallationChange.where(ic_params).take
      unless default_ic
        old_val = rec.send(column_name)
        InstallationChange.create!(ic_params.merge('value'=>old_val))
      end
    end

    val = value
    if (rec.send(column_name).class == Integer)
      val = val.to_i
    end
    rec.send(column_name+'=', val)
    rec.save!
    if inst_name_is_default
      delete
    end
  end


  private
  # Used by change_installation to copy installation specific files into
  # place.
  #
  # Parameters:
  # * start_dir - the name of the directory into which installation specific
  #   files should be installed, if there are any for start_dir.
  #   Sub-directories will also be checked.
  # * inst_name - the name of the installation
  def self.copy_installation_files(start_dir, inst_name)
    inst_dir = File.join(start_dir, 'installation', inst_name)
    if File.exists?(inst_dir)
      Dir.entries(inst_dir).each do |fn|
        if (fn!= '.' && fn != '..' && fn != 'CVS')
          from_file = File.join(inst_dir, fn)
          puts("Copying #{from_file} to #{start_dir}")
          FileUtils.copy(from_file, File.join(start_dir, fn), :preserve=>true)
        end
      end
    end

    # Now look for sub-directories and process them
    Dir.entries(start_dir).each do |fn|
      if (fn!= '.' && fn != '..' && fn != 'CVS')
        fn_path = File.join(start_dir, fn)
        if File.directory?(fn_path) && !File.symlink?(fn_path)
          copy_installation_files(fn_path, inst_name)
        end
      end
    end
  end

end
