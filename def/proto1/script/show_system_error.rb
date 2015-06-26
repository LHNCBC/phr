#!/proj/def/bin/ruby
# Shows information from the system_errors table.  Be careful not to
# save this information to a machine that should not have PII.  Use
# -h for help.

require 'rubygems'
require 'mysql2'
require 'yaml'
require 'erb'

# A method for showing usage information
def show_help
  puts <<END_HELP
show_system_error.rb:  Shows information from the system_errors table.  Be careful not to
save this information to a machine that should not have PII.
 - With no arguments:  Displays the most recent error
 - With -l (the letter) as an argument:  Lists the most recent record IDs and the times
 - With a number as an argument:  Show the system error with that record ID
 - With a user name as an argument:  Sudo to that user before running the script
END_HELP
end

if ARGV.length>0 && ARGV[0]=='-h'
  show_help
  exit
end

user = nil
list = nil
rec_num = nil
ARGV.each do |arg|
  if arg =~ /\A[a-zA-Z]\w*\z/
    user = arg
  elsif arg =~ /\A\d+\Z/
    rec_num = arg
  elsif arg == '-l'
    list = arg
  end
end

if user
  # Change user.
  if `id -un`.chomp != 'irvmgr'
    puts
    puts "CHANGING USER TO #{user}..."
    exec("sudo -u #{user} sh -c 'HOME=/proj; /proj/def/proto1/script/show_system_error.rb #{list} #{rec_num}'")
  end
end

# Read the database connection information from the database.yml file
db_config_file = File.dirname(__FILE__) + '/../config/database.yml'
db_config = YAML.load(ERB.new(File.read(db_config_file)).result)['development']

# Connect to the database
conn = Mysql2::Client.new(:host=>db_config['host'], :username=>db_config['username'],
                          :database=>db_config['database'], :password=>db_config['password'])

# Shows one record
#
# Parameters:
# * record - a hash of key/value pairs for the record's fields
def show_record(record)
  record.each_key do | k |
    printf("%-20s  %s\n", k+':', record[k]) if k != 'exception'
  end
  puts "Stack trace:  #{record['exception']}" if record['exception']
end

if ARGV.length == 0
  result_set = conn.query('select * from system_errors order by updated_at desc limit 1')
  result_set.each {|row| show_record(row)}
elsif ARGV[0] =~ /\A\d+\Z/
  result_set = conn.query("select * from system_errors where id=#{ARGV[0]}")
  result_set.each {|row| show_record(row)}
elsif ARGV[0] == '-l'
  # Print help information
  result_set = conn.query('select id,updated_at from system_errors order by updated_at desc limit 20')
  result_set.each do |record|
    puts "id: #{record['id']};  updated_at: #{record['updated_at']}"
  end
end
