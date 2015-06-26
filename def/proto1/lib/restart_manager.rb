# A module for initiating and controlling requests to restart the server.

# The restart is currently performed by a cron job which checks once per minute
# for the existence of a file which indicates that a restart was requested.

module RestartManager

  # The file that indicates the restart should not take place.  This file needs
  # to be removed prior to a restart request being processed.
  RESTART_LOCK = '/tmp/restart_lock'

  # The file whose presence signals that a restart of the server should be
  # performed.
  # This used to be stored inside proto1/tmp, but now the web app does not
  # have permission to write there, so it now just goes in /tmp.
  # RESTART_FILE = "#{File.dirname(__FILE__)}/../tmp/RESTART"
  # If we want to this to support more than one PHR system per machine,
  # will need to change this file to make it unique.  For the cases where
  # this file gets used (the data controller), we only have one PHR on
  # each build system machine.
  RESTART_FILE = '/tmp/PHR_RESTART'

  # Puts the restart lock file in place to prevent restarts from occurring.
  # If the restart lock is already in place (put there by some other process),
  # this method waits until the file goes away, and then gets the restart
  # lock again.
  #
  # Returns:  true if the lock was obtained, or false if it could not be
  # obtained because a restart has already been requested.
  def self.restart_lock
    require 'vcs'
    rtn = false
    Vcs::wait_for_lock(RESTART_LOCK, true)
    if !restart_requested?
      system('touch '+RESTART_LOCK)
      rtn = true
    end
  end

  
  # Returns true if the the restart lock file exists
  def self.is_locked?
    File.exists?(RESTART_LOCK)
  end


  # Removes the restart lock file, so that a restart can be done if needed.
  def self.release_restart_lock
    system("rm -f #{RESTART_LOCK}")
  end


  # Signals that a restart should be performed, but first waits until the
  # restart_lock is gone.
  def self.request_restart
    Vcs::wait_for_lock(RESTART_LOCK, true)
    system("touch #{RESTART_FILE}")
  end

  
  # Returns true if a restart of the system has been requested
  def self.restart_requested?
    File.exists?(RESTART_FILE)
  end


  # Gets the restart lock if it is available, but does not wait if it is
  # not.
  #
  # Returns:  true if the lock was obtained, and false if it was not.
  def self.lock_if_available
    rtn = !restart_requested? && !File.exists?(RESTART_LOCK)
    create_lock if rtn
    return rtn
  end

  private


  # Creates the lock file (without checking)
  def self.create_lock
    system('touch '+RESTART_LOCK)
  end
end
