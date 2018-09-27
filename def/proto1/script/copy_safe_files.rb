#!/proj/def/bin/ruby
# This transfers files from the phr safe branch to the appropriate
# directory for transfer to either GitHub or a VM.
#
# Specifically, files to be pushed to the master branch of the public GitHub
# site are copied to your ~/phr_github directory.
#
# Files to be pushed to the gh-pages branch of the public GitHub site are copied
# to your ~/gh_pages directory.
#
# Files to be transferred to a VM are copied to your ~/phr_vm directory and then
# tarred up so that the tar file can be imported to a VM Manager.
#
# Your ~/phr_github and ~/phr_ghpages directories should be set up to push
# to the public GitHub repository.
#

require 'rubygems'
require 'yaml'
require 'erb'
require 'fileutils'
ENV['RAILS_ENV'] = 'development'
home_dir = Dir.home()

# command and parameter help text; git branch info messages

HELP_TEXT =
'copy_safe_files.rb:  Copies files from the safe branch to the directory
specific to the distribution type (~/phr_github, ~/phr_ghpages,
or ~/phr_vm).  These directories should already exist, and the ~/phr_github and
~/phr_ghpages directories should already be set up to push to the public
GitHub site.

Usage:  copy_safe_files.rb distribution_type
where distribution_type = vm - for files to be tarred up for a PHR VM;
                          github - for files to be copied to ~/phr_github; or
                          ghpages - for files to be copied to ~/phr_ghpages.'

INVALID_PARAM = 'You must specify vm, github, or ghpages for the
distribution type.'

SWITCHED_BRANCH = 'You are now on the safe branch, which was just checked out.'

# The subdirectory (SAFE_DEF_DIRS) and files (SAFE_DEF_FILES) to be copied
# from the ~/def directory for the vm and github distributions
SAFE_DEF_DIRS = ["bin", "packages"]
SAFE_DEF_FILES = ["bashrc.def", "cshrc.def", "dependencies.yaml",
                  "LICENSE.md", "README.md"]

# The subdirectories (SAFE_PROTO1_DIRS) and files (SAFE_PROTO1_FILES) to be
# copied from the ~/def/proto1 directory for the github and vm distributions
SAFE_PROTO1_DIRS = ["app", "config", "db", "lib", "public",
                    "script", "test", "vendor"]
SAFE_PROTO1_FILES = ["Rakefile", "config.ru"]

GOODBYE = "Our work here is done.  It's all up to you now."


# Display instructions for running the script and feedback on invalid
# argument specification.
#
# Parameters:
# * bad_args flag indicating whether or not the user specified an invalid
#   (or missing) argument
#
# Returns:
# * nothing
#
def show_help(bad_args)
  puts HELP_TEXT
  if (bad_args)
    puts INVALID_PARAM
  end
end


# Make sure that the current directory is the ~/def directory (the def
# subdirectory of the user's home directory) and the current git branch
# is the safe branch.   If either of those conditions is not true, make
# them true.
#
# Parameters:
# * home_dir the user's home directory
#
# Returns:
# * nothing
#
def set_starting_point(home_dir)

  # Make ~/def the current directory
  set_start_dir = 'cd ' + home_dir + '/def'
  system(set_start_dir)

  # Figure out what branch we're on and then move us to the safe branch
  branch = `/bin/git rev-parse --abbrev-ref HEAD`
  branch = branch.chomp
  diffbranch = branch != 'safe'
  if (diffbranch)
    git_checkout = '/bin/git checkout safe'
    system(git_checkout)
    puts SWITCHED_BRANCH
  end
end # set_starting_point


# Confirms that the target directory exists and, if applicable, contains a
# .git subdirectory.  Specifically
#
# If the distribution type is github, the ~/phr_github directory must exist
# and must contain a .git subdirectory.
#
# If the distribution type is gh-pages, the ~/phr_gh-pages directory must exist
# and must contain a .git subdirecotry.
#
# If the distribution type is vm, the ~/ph_vm directory should exist, but if it
# does not it is created.  It does not need a .git subdirectory (and shouldn't
# really have one).
#
# Parameters:
# * home_dir the current user's home directory
# * dest the destination specified by the user
#
# Returns:
# * dirOK flag indicating whether or not the directory corresponding to the
#   destination specified exists and is in the required condition
#
def check_target_directory(home_dir, dest)

  # Figure out the destination directory name based on the user's input.
  # If it's missing for the vm, create it.  If it's missing for github or
  # ghpages, complain and set the dirOK flag false.

  dest_dir = home_dir + '/phr_' + dest
  dirOK = true
  if !Dir.exist?(dest_dir)
    if dest == 'vm'
      Dir.mkdir(dest_dir)
      puts 'Created the ' + dest_dir + ' directory.'
    else
      puts 'The ' + dest_dir + ' does not exist. It must exist AND '
      puts 'must be set up to connect to the public GitHub site.'
      dirOK = false
    end

  # If the directory is there but the .git subdirectory is missing for the
  # github or gh-pages directory, complain and set the dirOK flag false

  elsif dest != 'vm' && !Dir.exist?(dest_dir + '/.git')
    puts 'The ' + dest_dir +  ' exists but does not contain a .git subdirectory,
     '
    puts 'which should contain the files to connect it to the public GitHub site.'
    dirOK = false
  end
  if !dirOK
    puts 'Cannot continue ... exiting ...'
    end
  return dirOK
end # check_target_directory


# Takes care of copying the def directory specific files to created for
# either the github or vm targets.  The files are those specified by
# SAFE_DEF_FILES, SAFE_DEF_DIRS, SAFE_PROTO1_FILES and SAFE_PROTO1_DIRS.
#
# Parameters:
# * home_dir the current user's home directory
# * dest_dir the destination directory
#
# Returns:
# * nothing
#
def copy_def_files(home_dir, dest_dir)

  # Set the source and destination directories
  src_dir = home_dir + '/def'
  dest_dir = dest_dir + '/def'
  if !Dir.exist?(dest_dir)
    Dir.mkdir(dest_dir)
  end

  # Copy each directory to be copied at the ~/def level
  SAFE_DEF_DIRS.each do |dr|
    cp_cmd = 'cp -RfpP ' + src_dir + '/' + dr + ' ' + dest_dir + '/' + dr
    system(cp_cmd)
  end

  # Copy each file in the ~/def directory
  SAFE_DEF_FILES.each do |fl|
    cp_cmd = 'cp -fpP ' + src_dir + '/' + fl + ' ' + dest_dir + '/' + fl
    system(cp_cmd)
  end

  # Now set the source and destination directories down a level, to the
  # proto1 directory
  src_dir += '/proto1'
  dest_dir += '/proto1'
  if !Dir.exist?(dest_dir)
    Dir.mkdir(dest_dir)
  end
  # Copy each directory to be copied at the ~/def/proto1 level
  SAFE_PROTO1_DIRS.each do |dr|
    cp_cmd = 'cp -Rfp ' + src_dir + '/' + dr + ' ' + dest_dir + '/' + dr
    system(cp_cmd)
  end

  # Copy each file to be copied at the ~/def/proto1 level
  SAFE_PROTO1_FILES.each do |fl|
    cp_cmd = 'cp -fp ' + src_dir + '/' + fl + ' ' + dest_dir + '/' + fl
    system(cp_cmd)
  end

end # copy_def_files


# This processes the vm and ghpages specific files and directories.
#
# This takes care of creating any subdirectories that don't exist in the
# non-destination-specific directory hierarchy
# (e.g., def/proto1/vendor/assets/javascripts/javascript-stacktrace) as well
# as creating any symbolic links specified.
#
# Parameters
# * src_dir full directory path for the source of the files to copy
# * dest_dir full directory path for the destination of the files to copy
#
def copy_non_def_files(src_dir, dest_dir)

  # Process each file in the current source directory - except '.', '..' and
  # '.git'
  src_files = Dir.entries(src_dir)
  src_files.each do |sf|
    if sf != '.' && sf != '..' && sf != '.git'
      sfname = src_dir + '/' + sf
      dfname = dest_dir + '/' + sf

      # If the current file is really directory, make sure the corresponding
      # destination directory exists and then call this function on the
      # current directory and its corresponding destination directory
      if File.directory?(sfname)
        if !Dir.exist?(dfname)
          Dir.mkdir(dfname)
        end
        copy_non_def_files(sfname, dfname)

      # Otherwise the current file is either a file or a link.  Construct
      # the appropriate file copy/link create command and run it.
      else
        if File.symlink?(sfname)
          cp_cmd = 'ln -sf ' + File.readlink(sfname) + ' ' + dfname
        else
          cp_cmd = 'cp -fp ' + sfname + ' ' + dfname
        end
        system(cp_cmd)
      end
    end # if it's not ., .. or .git
  end # end do for each directory entry
end # copy_non_def_files


# This creates the tar file to be moved to the VM
#
# Parameters:
# * home_dir the current user's home directory
#
def create_vm_tar_file(home_dir)
  cur_dir = Dir.pwd
  tar_cmd =  'cd ' + home_dir + '/phr_vm; ' +
             'tar cf vm_files.tar --exclude="*.tar" * ;' +
             'cd ' + cur_dir
  system(tar_cmd)
end


# This moves the two markdown files, LICENSE.md and README.md that are in
# the def directory on the safe branch to the top-level directory - same
# level as the def directory - in the master branch on github.
#
# Parameter:
# * home_dir the current user's home directory
#
def move_github_md_files(home_dir)
  cur_dir = Dir.pwd
  mv_cmd =  'cd ' + home_dir + '/phr_github; ' +
            'mv -f def/LICENSE.md . ; mv -f def/README.md . ;' +
            'cd ' + cur_dir
  system(mv_cmd)
end


# ************************************************************************
# This is the actual start of processing
# ************************************************************************

# Check to see if the user asked for help, or didn't specify a valid
# argument.  If so, show the appropriate help and exit.
badarg = false
dest = ''
if ARGV.length == 1
  dest = ARGV[0].downcase
  if dest != 'vm' && dest != 'github' && dest != 'ghpages'
    badarg = true
  end
else
  badarg = true
end
if ARGV.length == 0 || ARGV[0] == '-h' || badarg 
  show_help(badarg)
  exit
else

  set_starting_point(home_dir)

  dirOK = check_target_directory(home_dir, dest)

  # if the destination directory is OK, do destination-specific processing
  if dirOK

    case dest
    when 'vm'
      copy_def_files(home_dir, home_dir + '/phr_vm')
      copy_non_def_files(home_dir + '/def/vm', home_dir + '/phr_vm')
      create_vm_tar_file(home_dir)

    when 'ghpages'
      copy_non_def_files(home_dir + '/def/gh-pages', home_dir + '/phr_ghpages')

    when 'github'
      copy_def_files(home_dir, home_dir + '/phr_github')
      move_github_md_files(home_dir)
    end # case
  end # if the target directory is ok

  # Say goodbye, Chet
  puts GOODBYE
end # if no initial problem
