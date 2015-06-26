require 'fileutils'

namespace :def do

  desc 'Change to a release branch for a tagged version, or back to '+
    'the master branch'
  task :change_branch2 => :environment do
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
      system("echo Before code_needs_update; /usr/local/bin/git status")

      code_needs_update = !`sh -c '#{Vcs::GIT_CMD} fetch --dry-run 2>&1' | grep #{branch}`.blank? ||
        !`#{Vcs::GIT_CMD} log origin/#{branch} ^#{branch}`.blank?

      system("/usr/local/bin/git status; echo Running #{Vcs::GIT_CMD} checkout #{branch}; #{Vcs::GIT_CMD} checkout #{branch}") ||
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


end  # def.rake
