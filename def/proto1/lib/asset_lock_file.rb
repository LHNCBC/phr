require 'fileutils'
class AssetLockFile
  # The interval for checking lock file. The unit of the interval is second.
  @@lock_check_interval = (1.0/24.0)
  
  # The full path to the directory for lock files
  @@lock_path = File.expand_path('../../tmp/cache/asset_lock_files', __FILE__)
  
  # A flag indicating whether verbose output is needed 
  @@print = false
  
  # The maximum number of seconds the system will be waiting when the 
  # wait_for_lock method was called
  @@max_wait_seconds = 2 
  
  # Used in testing so that we can skip the waiting
  cattr_accessor :max_wait_seconds
  
  # Removes the directory used for storing lock files
  def self.clear_locks
    FileUtils.remove_dir(@@lock_path) if File.directory?(@@lock_path)
  end
  
  
  # Returns all lock files stored 
  def self.show_locks
    Dir.entries(@@lock_path)  if File.directory?(@@lock_path)
  end
  
  
  # Converts the name of a regular Javascript file into the name of lock file
  # E.g. popup.js => popup_js.lock
  # 
  # Parameters:
  # * basename basename of a Javascript file 
  def self.convert_to_lockfile(basename)
    basename.split(".")[0]+ ".js_lock"
  end
  
  
  # Runs the block of code with a lock to avoid race condition
  # 
  # Parameters:
  # * base_lock_file basename of the lock file
  def self.run_with_lock(base_lock_file, &block)
    FileUtils.mkdir_p(@@lock_path)
    fullpath = self.get_lock_file_path(base_lock_file)
    if File.exists?(fullpath)
      self.wait_for_lock(fullpath)
    else
      self.create_lock_file(fullpath)
    end
    begin
      yield
    rescue
      raise
    ensure
      self.release_lock_file(fullpath)
    end
  end
  
  
  # Creates a lock by adding a lock file
  # Parameters:
  # * lock_file full path of the lock file 
  def self.create_lock_file(lock_file)
    FileUtils.mkdir_p(@@lock_path)
    system('touch '+lock_file) || raise("Could not create lock file #{lock_file}")
    puts "got lock (#{lock_file})" if @@print
    Rails.logger.debug "got asset file lock (#{lock_file})" 
  end
  
  
  # Releases the lock by removing the lock file
  # Parameters:
  # * lock_file full path of the lock file 
  def self.release_lock_file(lock_file)
    system("rm -f #{lock_file}")
    puts 'vcs lock was released' if @@print
    Rails.logger.debug 'asset file lock was released' 
  end
  
  
  # Wait for the lock to go away, If the lock stays over a certain period of 
  # time, an error message will be thrown.
  # Parameters:
  # * lock_file name of the lock file
  # * wait a flag indicating whether or not 
  def self.wait_for_lock(lock_file)
    if File.exists?(lock_file)
      wait_count = 0
      max_count  = (@@max_wait_seconds/@@lock_check_interval).to_i
      if wait_count <= max_count
        puts 'Waiting for it to go away...' if @@print
        Rails.logger.debug 'Found asset lock : #{lock_file}' 
        Rails.logger.debug 'Waiting for the asset file lock to go away...' 
        while (File.exists?(lock_file) )
          # If waited for a long time, but the generating of new Javascript file
          # still not done, raise an error message
          if wait_count > max_count
            raise "The lock file #{lock_file} has been there for more than"+
              " #{@@max_wait_seconds*@@lock_check_interval} seconds."+
              " Looks like the code for generating new Javascript file wasn't" + 
              " working properly."
          end
          sleep(@@lock_check_interval)
          print '.' if @@print
          wait_count +=1
        end
        Rails.logger.debug 'The asset file lock was released.' 
      end
    end
  end

  
  # Returns the full path for the lock file
  # 
  # Parameters:
  # * lock_file name of the lock file
  def self.get_lock_file_path(lock_file)
    if lock_file.blank?
      raise("Please provide lock file name!")
    else
      File.join(@@lock_path, lock_file)
    end
  end
  
end
