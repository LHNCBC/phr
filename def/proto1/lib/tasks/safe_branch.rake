
namespace :def do

  # This task creates a tar file for either the VM or the GitHub version of
  # the PHR files.
  desc 'Creates a safe branch tar file. Specify which distribution as a ' +
       'parameter in the format "dist=[distribution name]", where dist ' +
       'should be either VM or GitHub.'
  task :safe_branch_files => :environment do

    dist = ENV['dist']
    if !dist
      raise 'Specify which distributions as a parameter as in ' +
             '"dist=[distribution name", using VM or GitHub as appropriate.'
      exit
    end
    dist.downcase!

    # Files and directories that need to be included in the tar file
    # All names are relative to the ~/def directory.
    safe_list = ['bashrc.def', 'bin', 'cshrc.def', 'dependencies.yaml',
                 'Gemfile',  'LICENSE.md', 'packages', 'README.md',
                 'proto1/app', 'proto1/config', 'proto1/config.ru',
                 'proto1/db', 'proto1/index', 'proto1/lib',
                 'proto1/public',  'proto1/Rakefile', 'proto1/script',
                 'proto1/test', 'proto1/tmp',  'proto1/vendor']

    # Start at the def-xxx directory, where xxx is the distribution name,
    # and work through the directory hierarchy.  For any xxx directories found,
    # copy the contents of the xxx directory to the non-specific version.
    # For example, the contents of def/proto1/tasks/vm would be copied to
    # def/proto1/tasks, where each file from the vm version would overwrite
    # the version in the non-specific directory.
    system("cd ~/def")

    orig_dir = '~/def/'
    dist_dir = orig_dir + dist + '/'
    safe_list.each do |fd|
      # if fd is a directory, send it to the process_directory method to
      # check for and process distribution-specific subdirectories.
      if File.directory?(fd)
        process_directory(orig_dir, fd, dist_dir)
      end
    end

    tar cvf safe_files.tar safe_list.join(' ')
  end # task safe_branch_files

  def process_directory(orig_dir, dir_name, dist_dir)
    # check to see if there is a distribution-specific directory
    dist_name = dist_dir + dir_name
    if Dir.exists(dist_name)
      Dir.entries(dist_name).each do |f|
        if File.directory?(f)
          process_directory(orig_dir + dir_name + '/', f, dist_name + '/')
        else
          dist_file = dist_name + '/' + f
          orig_file = orig_dir + dir_name + '/' + f
          system("cp #{dist_file} #{orig_file}")
        end
      end

    end # if there is a distribution-specific directory
  end # process_directory

end # namespace