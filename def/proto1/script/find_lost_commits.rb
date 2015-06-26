#!/proj/def/bin/ruby

# Looks for commits on the current branch that are on the current branch but not
# on the master branch and that perhaps should be.  A different branch name
# other than master can be passed in as an argument.
master_branch = ARGV && ARGV[0] ? ARGV[0] : 'master'

# There is a file that lists commits we've already checked and do not need to do so again.
EXCLUSIONS_FILE = File.join(File.dirname($0), 'branch-only-commits.txt')

require 'set'
exclusions = Set.new
if File.exists? EXCLUSIONS_FILE
  lines = File.readlines(EXCLUSIONS_FILE)
  lines.each { |line| exclusions << line.chomp }
end

first_time = true
`git cherry #{master_branch} | grep ^+ `.split(/\n/).each do |commit_sha|
  if first_time
    first_time = false
    puts <<END_HEADER 
The following commits look like they only exist on the release branch.  Please
check to make sure the changes are also on the master branch (if they should be
there too) and then add the SHA1s to the script/branch-only-commits.txt file on
the release branch.  Be sure to mention branch-only-commits.txt in the commit
message for that file to avoid having that commit show up as lost.

END_HEADER
  end
  commit_sha.chomp!
  commit_sha =~ /\+ (.*)/
  commit_sha = $1 # (remove the +)
  if !exclusions.member?(commit_sha)
    # Further exclude certain types of commits (e.g. packUpdate updates).
    log_message = `git log -1 #{commit_sha}`
    if !log_message.index('updated by packUpdate') &&
       !log_message.index('branch-only') &&
       !log_message.index('via the help_text page')

      # See if this commit does exist but for some reason wasn't detected.
      # If a commit on the other branch exists with the same author, message,
      # and timestamp, we will assume the two are the same or equivalent.
      brief_log_message = `git log -1 --format=%s #{commit_sha}`.strip
      # Throw away cherry pick messages
      brief_log_message = brief_log_message.split(' (cherry pick')[0]
      # Look for a commit containing that message
      brief_log_message.gsub!(/'/, '\\\'')
      master_sha = `git log -1 --format=%H #{master_branch} --grep='#{brief_log_message}'`.strip
      if !master_sha.empty?
        master_timestamp = `git log -1 --format=%at #{master_sha}`
        commit_timestamp = `git log -1 --format=%at #{commit_sha}`
        master_author = `git log -1 --format=%ae #{master_sha}`
        commit_author = `git log -1 --format=%ae #{commit_sha}`
      end
      if (master_sha.empty? || (master_timestamp != commit_timestamp || master_author != commit_author))
        puts log_message
        puts '--------------------'
      end
    end
  end
end
