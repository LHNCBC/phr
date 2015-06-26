# A module for doing VCS-related stuff.
require 'etc'

module Vcs
  # The path to git.  Use the full path to git to avoid getting our git script
  # (which requires this file, resulting in an infinite loop).
  GIT_CMD = '/usr/local/bin/git'

  # The number of seconds between checks for the existence of the lock file.
  LOCK_CHECK_INTERVAL = 5
  
  
  # Returns the current branch name, or nil if it cannot be determined
  def self.current_branch_name
    # GIT_CMD won't exist on the staging and production systems
    return File.exists?(GIT_CMD) ?
      `#{GIT_CMD} symbolic-ref HEAD`.chomp.split(/\//)[-1] : nil
  end


  # Returns the VCS commit lock file pathname.
  #
  # Parameters:
  # * branch - the branch name for which the lockfile is needed.  If not
  #   specified, the default will be the name of the branch the code was on when
  #   this class was loaded.
  def self.get_vcs_lock_file_path(branch = VCS_COMMIT_LOCK_BRANCH)
    branch = VCS_COMMIT_LOCK_BRANCH if branch == nil
    if (branch == VCS_COMMIT_LOCK_BRANCH) && defined?(VCS_COMMIT_LOCK)
      rtn =  VCS_COMMIT_LOCK
    else
      dir = '/proj/defExtra/vcsLockFiles/'
      filename = 'vcs_lock' # default for when we can't determine a branch name
      # Add the branch name if we can.  Note that on the staging and production
      # systems, git is not installed, so we can't get a branch name.
      filename += '_for_' + branch if branch
      rtn = dir + filename
    end
    return rtn
  end
  
  
  # The branch name at the time VCS_COMMIT_LOCK is determined
  VCS_COMMIT_LOCK_BRANCH = current_branch_name
  
  # The lock file for the vcs commit lock (used when we need to keep someone
  # else from checking in changes).
  VCS_COMMIT_LOCK = get_vcs_lock_file_path
  
  
    
  # Checks to see if the given lock file is present, and if "wait" is true,
  # waits for it to go away.  If "wait" is false, the process exits.
  #
  # Parameters:
  # * lock_file_pn - the lock file pathname
  def self.wait_for_lock(lock_file_pn, wait)
    if File.exists?(lock_file_pn)
      # Get info about who has the lock and when they got it.
      permissions, linkCount, user, group, size, month, day, time =
        `ls -l #{lock_file_pn}`.split
      print "The lock file (#{lock_file_pn}) already exists.\n" +
        "The lock is held by user '#{user}' and was created on #{month} "+
        "#{day}, #{time}.\n"
      if (!wait)
        exit 1
      else
        puts 'Waiting for it to go away...'
        STDOUT.flush
        while (File.exists?(lock_file_pn))
          sleep(LOCK_CHECK_INTERVAL)
          print '.'
          STDOUT.flush
        end
        print "\a" # Alert the user
      end
    end
  end


  # Gets the vcs commit lock
  #
  # Parameters:
  # * wait - true if the method should wait until the lock is available.
  #  (The default is false, which means the process will exit.)
  # * branch - the branch name for which the lock is needed.  If not specified,
  #   this will use the current branch name.
  def self.vcs_commit_lock(wait = false, branch = nil)
    lock_file = get_vcs_lock_file_path(branch)
    wait_for_lock(lock_file, wait)
    # At this point, the lock is available-- we either waited for it or exited
    
    create_lock(branch)
  end


  # Gets the VCS lock for this branch if it is available, but does not wait or
  # exit if it is not.
  # 
  # Parameters:
  # * branch - (optional) the branch for which the lock file needed.  If this
  #   is not supplied, the current branch is assumed.
  #
  # Returns:  true if the lock was obtained, and false if it was not.
  def self.lock_if_available(branch = nil)
    lock_file = get_vcs_lock_file_path(branch)
    rtn = !File.exists?(lock_file)
    create_lock(branch) if rtn
    return rtn
  end


  # Returns true if the user running this process (or optionally, the user with
  # the specified username) has the VCS lock.
  #
  # Parameters
  # * branch - the name of the branch whose lock is in question.  If nil,
  #   the current branch will be assumed.
  # * user_name - (optional) a name for the user whose name will be checked
  #   against the owner of the lock.
  def self.i_have_lock?(branch = nil, user_name=nil)
    lock_file = get_vcs_lock_file_path(branch)
    rtn = false
    if File.exists?(lock_file)
      file_owner = Etc.getpwuid(File.stat(lock_file).uid).name
      if user_name
        rtn = file_owner == user_name
      else
        rtn = file_owner == ENV['USER'] || file_owner == ENV['SUDO_USER']
      end
    end
    return rtn
  end


  # Releases the vcs commit lock.  Raises an exception if the user does
  # not have the lock.
  #
  # Parameters:
  # * branch - the branch name for which the lock is needed.  If not specified,
  #   this will use the the branch from which this file was loaded.  (The branch
  #   could have been changed since that happened.)  
  def self.release_vcs_lock(branch = nil)
    lock_file = get_vcs_lock_file_path(branch)
    if !File.exists?(lock_file) || !i_have_lock?
      branch = branch ? branch : VCS_COMMIT_LOCK_BRANCH
      raise "You do not hold the lock for branch #{branch}"
    else
      puts 'releasing vcs lock'
      system("rm -f #{lock_file}")
    end
  end

  private


  # Creates the lock file.  If the file exists, an exception with be raised.
  #
  # Parameters:
  # * branch - the branch name for which the lock is needed.  If not specified,
  #   this will use the the branch from which this file was loaded.  (The branch
  #   could have been changed since that happened.)
  def self.create_lock(branch = nil)
    lockfile = get_vcs_lock_file_path(branch)
    raise("#{lockfile} already exists!") if File.exists?(lockfile)
    system('touch '+lockfile) || raise('Could not create lock file')
    puts "got vcs commit lock (#{lockfile})"

    # Set up a signal handler here after getting the VCS lock.  We don't want
    # to set it before getting the lock, because then the handler might
    # delete someone else's lock, if the user hits control-C while waiting
    # for the lock.
    Signal.trap('INT') do
      puts 'Signal handler caught interrupt; releasing VCS lock.'
      self.release_vcs_lock(branch)
      exit
    end
    Signal.trap('HUP') do
      puts 'Signal handler caught SIGHUP; releasing VCS lock.'
      self.release_vcs_lock(branch)
      exit
    end
    Signal.trap('TERM') do
      puts 'Signal handler caught SIGTERM; releasing VCS lock.'
      self.release_vcs_lock(branch)
      exit
    end    
  end
end
