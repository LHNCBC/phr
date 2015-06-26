#!/proj/def/bin/ruby
# Methods to look for duplicated profile ids - where the profile id has been
# used for more than one profile.
#

require 'rubygems'
require 'mysql2'
require 'yaml'
require 'erb'
require 'fileutils'
require 'json'

# script description and usage info
def show_help
  puts <<END_HELP
duplicated_profile_ids_check.rb:  Looks for profile IDs that have been used for
more than one profile, basically through some problem with the code that would
allow that to happen.   (This has happened in the past).

Two groups of problem ids are addressed by this script. The first is those
that are duplicated within the deleted_profiles table.  The second is those
that are duplicated between the deleted_profiles and profiles table.



END_HELP
end

if ARGV[0] == '-h'
  show_help
  exit
end



def set_up_db_stuff
  # Read the database connection information from the database.yml file
  db_config_file = File.dirname(__FILE__) + '/../config/database.yml'
  db_config = YAML.load(ERB.new(File.read(db_config_file)).result)['development']

  # Connect to the database
  @conn = Mysql2::Client.new(:host=>db_config['host'],
                             :username=>db_config['username'],
                             :database=>db_config['database'],
                             :password=>db_config['password'])
end

def dups_in_deleted_profiles
  dups1_list = @conn.query('select profile_id from deleted_profiles group by ' +
                           '(profile_id) having count(profile_id) > 1').to_a
  if dups1_list.count == 0
    puts "No duplicated profile_ids were found in the deleted_profiles table."
  else
    puts "Duplicated profile_ids were found in the deleted_profiles table."
    puts dups1_list.to_json
  end # if any rows with duplicated profile_ids where found in deleted_profiles
end # dups_in_deleted_profiles


def reused_profile_ids

  # get counts from data tables, base rec
  reused = @conn.query('select profile_id from deleted_profiles where ' +
                       'profile_id in (select id from profiles)').to_a
  if reused.size == 0
    puts "No reused profile_ids were found in the profiles table."
  else
   puts "Reused profile_ids were found in the profiles table."
   puts reused.to_json 
  end # if reused ids were found
end # reused_profile_ids

set_up_db_stuff
dups_in_deleted_profiles
reused_profile_ids
