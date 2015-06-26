# Tasks for the Acceptance Test Runner
require 'socket'
require 'yaml'

# A class with utility methods for the acceptance_tests task.
class AcceptanceTestUtil

  # A method for shutting down the test server.
  def self.stop_test_server
    if test_server_running?
      puts 'Shutting down test server...'
      # The perl command replaces sequences of spaces with the tab character,
      # so that the cut command can properly parse the lines into fields.
      system("ps -ef |grep -v grep| grep '#{SERVER_CMD} '| perl -ne "+
        "'s/ +/\t/g; print' |cut -f 2 |xargs kill")
    end
  end
  
  # Returns true if the test server appears to be running
  def self.test_server_running?
    ps_lines = `ps -ef |grep -v grep | grep 'ruby #{SERVER_CMD} '`
    !ps_lines.blank?
  end

  def self.test_server_done_taking_its_own_sweet_time_starting_up?
    netstat_lines =
      `netstat --listen -np --numeric-ports 2>&1 |grep ':#{RAILS_PORT} '|grep LISTEN`
    !netstat_lines.blank?
  end
 
  # Starts the test server
  def self.start_test_server
    system("#{SERVER_CMD} &")
  end


  # Finds the ports for the Apache and mongrel servers in the apache configuration file, 
  # returns both
  def self.get_server_ports
    ssl_config_path = Rails.root.join('../apache/conf/extra/httpd-ssl.conf')
    ssl = File.read(ssl_config_path)
    # The apache port is on the second virtual host line.
    first = true
    apache_port = nil
    ssl.scan(/<VirtualHost \*:(\d+)/) { |m|
      if first
        first = false
      else
        apache_port = $1
      end
    }

    ssl.match(/ RewriteRule \^\/\(\.\*\)\$ http:\/\/127.0.0.1:(\d+)/)
    mongrel_port = $1

    return apache_port, mongrel_port
  end


  # The port used by the server
  APACHE_PORT, RAILS_PORT = [443, 3000]

  # The command for starting the test server.
  SERVER_CMD = "script/rails server -e test -p #{RAILS_PORT}"

end


# Starts a web browser running the acceptance tests, and listens on a port
# for a connection from the AcceptanceController for a report of the test
# results.  (The :environment dependency loads the Rails environment.)
#
# This task now supports the command-line argument:  autorun=false
# When that is present, the test page will open but will not automatically run
# all of the tests.
desc "run customized acceptance tests"
task :acceptance_tests=>:environment do
  # Rails.env is not set in this acceptance test.
  # It is required to be in 'test' mode to update sequence in Oracle db.
  Rails.env = "test"
  
  # Make sure the test server is not already running.
  if AcceptanceTestUtil.test_server_running?
    puts 'It looks like the test server is already running.  (There is a ruby '+
      "script/rails server process running on port #{AcceptanceTestUtil::RAILS_PORT})."+
      '  Please check to make '+
      'sure you are not already running this rake task in another window, and'+
      '/or kill the process.'
    raise 'Acceptance tests could not be run'
  end

  # See if we are supposed to run all the tests and get a report.
  autorun = ENV['autorun'] != 'false'

  # See if we should skip copying the test database.  (Sometimes, if we
  # are re-running the tests, it is not necessary to do this time consuming
  # step.)
  skipcopy = ENV['skipcopy'] == 'true'

  if autorun
    # Get the port number from the configuration file
    config = YAML.load_file('config/acceptance.yml')
    port_num = config['report_port']
  
    # Listen for the test result report
    server = TCPServer.new('localhost', port_num)
  end

  if !skipcopy
    puts 'Copying development database to test database...'
    DatabaseMethod.copy_development_db_to_test
    Rake::Task['def:recreate_triggers'].execute
  end

  puts "Found ATR port #{AcceptanceTestUtil::APACHE_PORT} in apache configuration."
  puts "Found mongrel port #{AcceptanceTestUtil::RAILS_PORT} in apache configuration."

  
  # Start the test server.  Use a non-standard port.
  puts 'Starting test server...'
  Dir.chdir(Rails.root)
  AcceptanceTestUtil.start_test_server
  # Wait a bit for the server to start up

  while 
    !AcceptanceTestUtil.test_server_done_taking_its_own_sweet_time_starting_up?
    puts 'putz putz putz'
    sleep 1
  end
  
  # Start the tests
  puts 'Running firefox...'
  base_url = "https://#{FULL_HOST_NAME}:#{AcceptanceTestUtil::APACHE_PORT}/acceptance/run_tests"
  if autorun
    system("firefox #{base_url}?autorun=true &")
    puts 'Waiting for test results...'
    socket = server.accept
    pass = true
    socket.each_line do |line|
      pass = pass && line =~ /:  PASS$/
      puts line
    end
    
  else
    # Set up signal handlers to shut down the test server when the user
    # kills the process or hits control-C.
    # Actually, this does not seem to be needed.  If you hit control-C, both
    # the rask task and the server exit; I'm not sure why.
    #['TERM', 'INT'].each do |sig|
    #  Signal.trap(sig) {AcceptanceTestUtil.stop_test_server; exit}
    #end
    
    system("firefox #{base_url} &")
    puts 'When finished with the acceptance test page, hit control-C to shut '+
      'down the server.'
    sleep 1000000
  end
  
  # Shut down the test server
  AcceptanceTestUtil.stop_test_server
  raise 'Tests failed' if autorun && !pass

end

