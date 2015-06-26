class HelpText
  require 'vcs'

  # The GIT command
  GIT_COMMAND = '/usr/local/bin/git'

  # The list of installation mode codes.
  @@mode_codes = nil

  # The list of installation mode names
  @@mode_names = nil

  # A hash from installation mode codes to (user friendly) names
  @@mode_code_to_name = {}

  # A hash from installation mode codes to installation directory names
  @@mode_code_to_inst_dir_name = nil

  # The location of the help directory relative to the document root.
  REL_HELP_DIR = '/help'

  # The location of the help directory relative to the document root, with
  # a traling slash.
  REL_HELP_DIR_SLASH = '/help/'

  # The location of the help directory
  HELP_DIR = "#{Rails.root}/public#{REL_HELP_DIR}"

  # The path name of a particular help text
  @file_pn = nil

  # The file name of the help text
  @file_name

  # A code for referencing the help text later. This code is not stable (when
  # help text files are created or deleted), and may get reused.
  @code = nil

  # The installation mode code for the file.
  @mode_code = nil

  # The updated help HTML for this HelpText, if any.
  @help_html = nil

  # True if the instance needs saving.
  @changed = false

  # The error message (if any) resulting from the last save
  @error = nil

  # An attribute that is true if a save had to be postponed until later.
  @change_pending = false


  attr_reader :file_name, :code


  # Returns a list of all help text file names, irrespective of whether the
  # the files are shared or specific to an installation.
  def self.get_all_file_names
    help_files = filtered_path_names("#{HELP_DIR}/*html")
    # Just in case the installation specific files are not in the help directory
    # (which would be strange), add those to the list.
    help_files.concat(get_installation_path_names(
        InstallationChange::INSTALLATION_NAME_DEFAULT))
    help_files.concat(get_installation_path_names(
        InstallationChange::INSTALLATION_NAME_ALTERNATE))

    file_names = Set.new
    help_files.each do |f|
      file_names << File.basename(f)
    end
    file_names.to_a.sort
  end


  # Returns a list of HelpText instances for the given installation
  # mode.  If the specified mode is the "Shared" mode, then the files that
  # a shared across installation modes will be returned.  Otherwise, the files
  # that are specialized for the given installation will be returned.
  #
  # Parameters:
  # * mode_code - one of the codes from the TextList
  #   help_text_installation_modes, specifying the installation mode.
  def self.get_help_for_mode(mode_code)
    init_class if !@@mode_names
    if (!mode_code || !@@mode_code_to_name[mode_code])
      raise "Unknown installation mode '#{mode_code}'"
    end
    rtn_pathnames = []
    case mode_code
    when '1' then # Common/Shared files
      inst_specific_files = Set.new
      @@mode_code_to_inst_dir_name.values.each do |inst_dir|
        get_installation_path_names(inst_dir).each do |pn|
          inst_specific_files << File.basename(pn)
        end
      end
      help_files = filtered_path_names("#{HELP_DIR}/*html")
      help_files.each do |pn|
        file_name = File.basename(pn)
        if !inst_specific_files.member?(file_name)
          rtn_pathnames << pn
        end
      end
    else
      rtn_pathnames = get_installation_path_names(
        @@mode_code_to_inst_dir_name[mode_code])
    end

    sorted_files = rtn_pathnames.sort
    rtn_help_texts = []
    file_num = 1
    sorted_files.each do |f|
      rtn_help_texts << HelpText.new(f, "#{mode_code}_#{file_num}")
      file_num +=1
    end

    return rtn_help_texts
  end


  # Returns the installation mode string for the given mode code.
  def self.get_inst_mode_label(code)
    init_class if !@@mode_names
    return @@mode_code_to_name[code]
  end


  # Returns the HelpText instance for the given code.  (Note that codes are
  # not stable when files are deleted or created, so the caller should check
  # the returned HelpText.file_name.
  def self.find(code)
    mode, file_num = parse_code(code)
    hts = self.get_help_for_mode(mode)
    return hts[file_num.to_i - 1]
  end

  # Returns the HelpText instance for the given mode and file name.
  def self.find_by_mode_and_file_name(mode, file_name)
    hts = self.get_help_for_mode(mode)
    rtn = nil
    hts.each do |h|
      if file_name == h.file_name
        rtn = h
        break
      end
    end
    return rtn
  end

  
  # Returns the list of help files
  def self.list_files
    HelpText.init_class if !@@mode_names

    common_files = Dir.new(HELP_DIR).sort.delete_if {|f| !f.match(/\.shtml$/)}
    mode_files = {}
    @@mode_code_to_inst_dir_name.each do |code, mode|
      mode_path = "#{HELP_DIR}/installation/#{mode}"
      help_files =Dir.new(mode_path).sort.delete_if {|f| !f.match(/\.shtml$/)}
      mode_files[mode]= help_files
    end

    return common_files, mode_files
  end


  # Returns the file name (without the path) for the help text.
  def file_name
    return @file_name || File.basename(@file_pn)
  end


  # Returns the file text for this HelpText instance.
  def file_text
    @help_html || File.read(@file_pn)
  end


  # Returns the installation mode code for this HelpText.
  def mode_code
    if !@mode_code
      @mode_code = HelpText.parse_code(@code)[0]
    end
    return @mode_code
  end


  # Assigns new text for this HelpText.
  def file_text=(new_html)
    @help_html = new_html
    @changed = true
  end


  # Returns true if an attempt to save or delete the help_text was delayed and
  # will be done later.
  def change_pending?
    @change_pending
  end


  # Returns true if this is help text file is shared by all installation modes.
  def is_shared?
    return mode_code == '1'
  end


  # Creates a new help text and saves it.
  #
  # Parameters:
  # * file_name - a unique file name for the help file.
  # * help_html - the html for the help text.
  # * mode_code - the code for the installation mode for this file
  # * user_email - (optional) an email address to which a notification should
  #   be sent when the save has been completed.
  #
  # Returns the created help text.  The caller should check error_msg to see
  # if there was an error (or if the save is being postponed until the VCS
  # lock is available).
  def self.create(file_name, help_html, mode_code, user_email=nil)
    ht = HelpText.new(nil, nil, file_name, help_html, mode_code)
    ht.save(user_email)
    return ht
  end


  # Saves the help text.  If the VCS lock cannot be obtained, this will
  # start a background thread and do the save when the lock is available.
  # In that case, the method will return false and the error_msg method
  # will return a message for the user explaining the delay.
  #
  # Parameters:
  # * user_email - (optional) an email address to which a notification should
  #   be sent when the save has been completed.
  def save(user_email=nil)
    if @changed
      msg = "Help file #{file_name} was saved."
      with_locks(msg, user_email) {save_check_in_and_release(user_email)}
    end
  end

  
  # Returns the error message from the last save attempt, or nil if there
  # was no error.  (An error message is also set if the save is delayed
  # by the need to wait for the VCS lock.)
  def error_msg
    @error
  end


  # Returns the installation mode string for this help text.
  def get_inst_mode_label
    return @@mode_code_to_name[HelpText.parse_code(@code)[0]]
  end


  # Deletes the help text.
  #
  # Parameters:
  # * user_email - (optional) an email address to which a notification should
  #   be sent when the save has been completed.
  #
  # Returns true if successful, or false if either there was a problem
  # or the deletion had to wait (in which case change_pending? will return
  # true).
  def destroy(user_email=nil)
    msg = "Help file #{file_name} was deleted."
    with_locks(msg, user_email) {delete_check_in_and_release(user_email)}
  end


  private

  # Returns the list of pathnames of installation-specific files
  #
  # Parameters:
  # * installation_mode - the mode name from (InstallationChange for the
  #   installation whose files are being requested.)
  def self.get_installation_path_names(installation_mode)
    filtered_path_names(
      "#{HELP_DIR}/installation/#{installation_mode}/*html")
  end

  
  # Returns a list of help file pathnames matching the given path glob pattern,
  # but filtered to exclude things like the directories and backup ~ files.
  #
  # Parameters:
  # * glob_pattern - a glob-style pattern for matching pathnames.
  def self.filtered_path_names(glob_pattern)
    rtn = []
    Dir.glob(glob_pattern).each do |pn|
      if pn !~ /~\z/ && !File.directory?(pn)
        rtn << pn
      end
    end
    return rtn
  end


  # Initializes the class variables
  def self.init_class
    @@mode_names = []
    @@mode_codes = []
    @@mode_code_to_inst_dir_name = {
      '2'=> InstallationChange::INSTALLATION_NAME_DEFAULT,
      '3'=> InstallationChange::INSTALLATION_NAME_ALTERNATE
    }
    TextList.find_by_list_name('help_text_installation_modes'
    ).text_list_items.each do |tli|
      @@mode_names << tli.item_text
      @@mode_codes << tli.code
      @@mode_code_to_name[tli.code] = tli.item_text
    end
  end


  # Parses the code.
  #
  # Parameters
  # * code - a HelpText code
  #
  # Returns:  The mode code and a file number (which is a 1-based index into
  # the list of files for the mode).
  def self.parse_code(code)
    return code.split(/_/)
  end


  # Constructor.  There are really two ways of constructing it, depending on
  # whether this is a new HelpText or an existing HelpText.  For an existing
  # HelpText, the path_name and code should be specified, and other parameters
  # should be left nil.  For a new help text, the path_name and code must be
  # left nil (especially since they are unknown if the HelpText is new)
  # and the file_name, help_html, and mode_code parameters must be present.
  # Ideally, there would be two separate methods with different numbers of
  # arguments, and maybe one would be private and one public.  But, that is
  # not the way Ruby works.
  #
  # Parameters
  # * path_name - The file pathname of a particular help text.
  # * code - A code for referencing the help text later. This code is not stable,
  #   and may get reused as files change.
  # * file_name - a unique file name for the help file.
  # * help_html - the html for the help text.
  # * mode_code - the code for the installation mode for this file
  def initialize(path_name, code, file_name=nil, help_html=nil, mode_code=nil)
    if !code
      # This is a new HelpText require the needed arguments
      if file_name.nil? || help_html.nil? || mode_code.nil?
        raise 'For a new HelpText, file_name, html_html, and mode_code must '+
          'all be specified.'
      end
      @changed = true # because it is new
    else
      # Make sure the path_name is specified.
      if !path_name
        raise 'For an existing HelpText, both the path_name and code '+
          'parameters must be specified.'
      end
    end
    @help_html = help_html
    @file_name = file_name
    @mode_code = mode_code
    @file_pn = path_name
    @code = code
    HelpText.init_class if !@@mode_names
  end



  # Assumes that the VCS lock has been obtained, saves the file data,
  # checks in the change.  Does not release locks.
  #
  # Parameters
  # * user_email - (optional) the email address of the user making the change.
  #   This is used in the commit message to identify who made the change.
  #
  # Returns:  true if successful, or false if not, in which case an
  # error_msg will be set.
  def save_and_check_in(user_email=nil)
    error = nil
    is_new = @code.nil?
    help_dir_pn = nil
    is_shared = is_shared?
    help_dir_pn = File.join(HELP_DIR, file_name) # the installed location
    if !is_new # existing file
      vcs_file_pns = [@file_pn]
    else # new file
      vcs_file_pns = []
      if is_shared
        vcs_file_pns << help_dir_pn
      else
        InstallationChange.installation_modes.each do |mode_dir|
            vcs_file_pns << File.join(HELP_DIR, 'installation', mode_dir,
                                  @file_name)
        end
      end

      # Make sure the files do not exist yet.
      (is_shared ?
          vcs_file_pns : [help_dir_pn].concat(vcs_file_pns)).each do |pn|
        if File.exists?(pn)
          error = "File #{pn} already exists; a new help text file with that "+
            'name cannot be created.'
          break
        end
      end
    end

    if !error
      # Change the line endings to unix style (\r\n to \n)
      @help_html.gsub!(/\r\n/, "\n")

      # Write the file(s)
      vcs_file_pns.each do |pn|
        File.open(pn, "w") {|f| f.write(@help_html)}
        File.chmod(0644, pn)
        # If this is a new help text, add the file to GIT
        if is_new
          if !system("#{GIT_COMMAND} add #{pn}")
            error = "Could not add #{pn} to GIT."
            break
          end
        end

        # Check the file in
        commit_msg = user_email ?
          "Updated by #{user_email} via the help_text page." :
          'Updated via the help_text page by a user without an email address.'
        if !system("#{GIT_COMMAND} commit -m '#{commit_msg}' #{pn}")
          error = "Could not commit the change to #{pn}."
          break
        end
      end

      if !error
        # If this was for an installation, install the file if the installation
        # mode matches the current one, or if this was a new file (in which case
        # both installation modes temporarily have the same text, until one
        # is edited).
        if !is_shared && (is_new || InstallationChange.installation_name ==
              @@mode_code_to_inst_dir_name[mode_code])
          File.open(help_dir_pn, "w", 0644) {|f| f.write(@help_html)}
        end
      end
    end

    @error = error
    return error.nil?
  end


  # Assumes that the VCS lock has been obtained, saves the file data,
  # checks in the change, and releases the VCS lock.
  #
  # Parameters
  # * user_email - (optional) the email address of the user making the change.
  #   This is used in the commit message to identify who made the change.
  #
  # Returns:  true if successful, or false if not, in which case an
  # error_msg will be set.
  def save_check_in_and_release(user_email=nil)
    begin
      save_and_check_in(user_email)
    rescue
      @error = 'An error occurred while trying to save your change.'
    end
    # Release the VCS lock, even if there was an error.
    Vcs.release_vcs_lock
    RestartManager.release_restart_lock

    return @error.nil?
  end


  # Assumes that the VCS lock has been obtained, deletes the file,
  # checks in the change, and releases the VCS lock.
  #
  # Parameters
  # * user_email - (optional) the email address of the user making the change.
  #   This is used in the commit message to identify who made the change.
  #
  # Returns:  true if successful, or false if not, in which case an
  # error_msg will be set.
  def delete_check_in_and_release(user_email=nil)
    error = nil
    help_dir_pn = nil
    is_shared = is_shared?
    help_dir_pn = File.join(HELP_DIR, file_name) # the installed location

    # Delete the file, and also the copy in the installed location if the
    # file is shared.
    if !File.exists?(@file_pn)
      error = "Could not delete file #{@file_pn} because it no longer exists."
      # but continue, in case we can still remove the file from the VCS.
    else
      File.delete(@file_pn)
    end
    File.delete(help_dir_pn) if !is_shared && File.exists?(help_dir_pn)

    # VCS delete the file
    if !system("#{GIT_COMMAND} rm #{@file_pn}")
      error = "Could not remove #{@file_pn} from the VCS" if !error
    else
      # Check in the change
      commit_msg = user_email ?
        "Deleted by #{user_email} via the help_text page." :
        'Deleted via the help_text page by a user without an email address.'
      if !system("#{GIT_COMMAND} commit -m '#{commit_msg}' #{@file_pn}")
        error = "Could not commit the removal of #{@file_pn}." if !error
      end
    end

    # Release the VCS lock, even if there was an error.
    Vcs.release_vcs_lock
    RestartManager.release_restart_lock

    @error = error
    return error.nil?
  end


  # Gets the restart and VCS locks, and then yields to given block to perform
  # a change to the help files.  If there
  # will be a delay in getting the locks, the method returns after setting
  # variables change_pending? and error_msg (which will tell the user they
  # will get a message after their change is completed).
  #
  # Parameters:
  # * completion_msg - If there is a delay in getting the locks, this is the
  #   body of the email message the user will receive after the change is
  #   finally complete
  # * user_email - an email address to which the message should be sent.
  # * (block) a block for doing the needed change after the locks are obtained.
  #
  # Returns true if successful, or false if either there was a problem
  # or the deletion had to wait (in which case change_pending? will return
  # true).
  def with_locks(completion_msg, user_email)
    @error = nil
    got_restart_lock = RestartManager.lock_if_available
    got_vcs_lock = got_restart_lock ? Vcs.lock_if_available : false
    if (got_restart_lock && got_vcs_lock)
      yield
    elsif RestartManager.restart_requested?
      # This is a repeat of the check done by the controller, just in case
      # a request has been made.
      @error = 'A restart has been requested.  Please wait one minute before'+
        ' trying again.'
    else
      @change_pending = true
      # Note:  The following won't work in development mode, because the
      # thread persists through a reload of all the classes.
      Thread.new do
        RestartManager.restart_lock if !got_restart_lock # waits for the lock
        # If a server restart was requested, restart_lock returns false.
        # However, inside this thread, there is nothing we can do better than
        # to try to save the text before the restart happens.
        Vcs.vcs_commit_lock(true) if !got_vcs_lock # waits for the lock
        yield

        # The delivery of an email often fails in development mode,
        # due (as I understand) to classes being unloaded and reloaded
        # following the completion of the request.
        if (user_email)
          msg = @error ? @error : completion_msg
          # N.B.:  See comment above
          DefMailer.deliver_message(user_email, 'Help file update status',
            msg)
        end
        @change_pending = false
      end
      @error = 'Someone else was doing something that prevented your '+
        'change from being completed immediately, but it will be made when '+
        'they have finished.  You will get an '+
        'email when the change is done.' if !@error
    end
    return @error.nil?
  end

end
