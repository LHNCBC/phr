#--
# $Log: acceptance_controller.rb,v $
# Revision 1.12  2011/08/17 18:13:03  lmericle
# added display of line numbers for tests written in .sel file format
#
# Revision 1.11  2011/05/16 20:26:22  plynch
# page_timer_controller- now measures rails and apache times
# others- changed logger.info to logger.debug
#
# Revision 1.10  2009/06/19 18:47:07  plynch
# Modified the parsing of .sel files.
#
# Revision 1.9  2009/06/10 22:04:39  plynch
# Fixed a typo.
#
# Revision 1.8  2009/04/28 17:03:23  plynch
# Changes to allow parsing of "selenium" test files.
#
# Revision 1.7  2009/02/03 22:12:44  plynch
# Changes to fix some html encoding in error messages and static_text fields.
#
# Revision 1.6  2009/01/29 22:19:20  plynch
# Prevented the acceptance test from running in anything other than the test
# environment.
#
# Revision 1.5  2008/12/15 20:40:43  plynch
# Changes to add codes to AJAX lists;
# changes to autocompleters to make them behave more alike
# changes to test code.
#
# Revision 1.4  2008/07/21 17:02:54  plynch
# Added an action for reporting results.
#
# Revision 1.3  2008/07/11 18:20:05  plynch
# When parsing html test files, it now deletes html comments first.
#
# Revision 1.2  2008/06/03 18:11:54  plynch
# Moved the test window for the acceptance controller into an IFRAME, so you
# can watch the progress of the tests without causing fields to lose focus.
#
# Revision 1.1  2008/05/22 18:52:55  plynch
# Initial.
#
#++

require 'socket'

# This class is a controller for running acceptance tests.  The idea
# is that the user will open up a web page for running tests on this
# application, and the page will make AJAX calls to this class for loading
# test suite information and for reporting results.
class AcceptanceController < ApplicationController
  before_filter :require_test_env
  
  # A filter to require the test environment for these tests.
  def require_test_env
    rtn = true
    unless Rails.env == 'test'
      render(:text=>
        'The acceptance tests must be run in the Rails test environment.<br>'+
        'Please either run "rake acceptance_tests" to run all the tests, or '+
        '"rake acceptance_tests autorun=false" to run the tests individually.')
      rtn = false  # don't continue
    end
    return rtn
  end
 
  # Returns the acceptance test page that runs the tests.  If the parameter
  # "autorun" = "true", then the test page will start running the tests as soon
  # as the page loads.
  def run_tests
    @test_commands = self.class.get_test_commands
    @auto_run = params[:autorun]=='true'
  end

  
  # An AJAX action used for reporting a summary of the test results.
  # The expected format of the parameters is "testfile1=PASS,testfile2=FAIL..."
  # where "testfile1" and 2, etc., are the names of the test script files.
  def report_results
    # See if there is a rake command listening for the results.
    config = YAML.load_file('config/acceptance.yml')
    port_num = config['report_port']
    
    begin
      client = TCPSocket.new('localhost', port_num)
      # Print the test results
      params.each  do |testfile, result|
        # All of the parameters except the controller and action are test
        # filenames.
        if (testfile != 'controller' && testfile != 'action')
          client.puts testfile + ':  ' + result
        end
      end
      client.close
    rescue
      # If we're here, it is probably because we couldn't connect, which
      # means that the test was not being run via the rake command.
      # That's okay.
      logger.debug $!
    end

    render(:text=>'received')
  end
  
  
  
  # Loads the tests from the test/selenium directory and returns them.
  #
  # Returns:  A map from test files to an array of test commands in each file.
  # Each element of the test command array will be an array that contains
  # a Selenium style triple that defines the test command to be run.
  def self.get_test_commands
    # Get the path to the selenium directory.
    # __FILE__ points to this file.
    sel_dir = File.dirname(__FILE__) + '/../../test/selenium'
    rtn = {}
    Dir.new(sel_dir).entries.each do |filename|
      if (filename !~ /^\./ && filename != 'CVS' && !File.directory?(filename))
        # Parse the file
        if (filename =~ /\.html$/)
          rtn[filename] = parse_html(File.join(sel_dir,filename))
        elsif filename =~ /\.sel$/
          rtn[filename] = parse_selenese(File.join(sel_dir,filename))
        else
          # Just skip the file.
          #raise 'Unsupported file type'
        end
      end
    end
    return rtn
  end  
  
  
  # Reads the given HTML-formatted test suite, parses it, and returns
  # the values as an array of command parameter triplets.
  def self.parse_html(file_name)
    rtn = []
    File.open(file_name) do |file|
      file_text = file.readlines.join('')
      
      # Turn HTML comments that do not include HTML tags into "comment" commands
      # The comments must be outside of TR tags for this to work.
      # NOTE - comments that are at the end of the file don't get written
      # to the new file.  I would have fixed this but we're not using this
      # format any more.  lm, 8/2011
      re = Regexp.new('</tr>\\s*<!--([^<]*?)-->\\s*<tr>', Regexp::MULTILINE)
      file_text.gsub!(re,
        '</tr><tr><td>comment</td><td>\\1</td><td></td></tr><tr>')
      
      # Remove any HTML comments, which might have been used to comment out
      # some sections of a test.
      end_index = 0
      while (end_index && start_index = file_text.index('<!--'))
        end_index = file_text.index('-->', start_index+4)
        if (end_index)
          end_index += 3 # move past the end of comment marker
          file_text.slice!(start_index..end_index)
        end
      end
      
      # Each pair of tr tags is a command.  The td tags inside
      # each tr are the command's parameters.
      td_pat = '<td>\\s*(.*?)\\s*</td>'
      tr_pat = "<tr>\\s*#{td_pat}\\s*#{td_pat}\\s*#{td_pat}\\s*</tr>"
      re = Regexp.new(tr_pat, Regexp::MULTILINE)
      file_text.scan(re) do
        cmd = []
        if $1 == 'comment'
          [$1, ' ', $2].each {|m| cmd << m}
        else
          cmd << ' '
          [$1, $2, $3].each {|m| cmd << m if !m.blank?}
        end
        rtn << cmd
      end
    end
    return rtn
  end

  # Reads a "selenese"-formatted test suite, parses it, and returns
  # the values as an array of command parameter triplets.
  def self.parse_selenese(file_name)
    # The best reference for this format I've been able to find is here:
    #  http://wiki.openqa.org/display/SIDE/SeleniumOnRails
    rtn = []
    File.open(file_name) do |file|
      collected_comments = []
      line_no = 0
      file.readlines.each do |line|
         # Skip comments, which (in the absence of documentation) will start
         # with a #.
         line_no += 1
         if (!line.blank?)
           # Turn comments into a comment command
           if (line =~ /^\s*#/)
             collected_comments << line.sub(/^\s*#/, '')
           else
             if !collected_comments.empty?
               rtn << ['comment', line_no - 1, collected_comments.join(' ')]
               collected_comments.clear
             end
             # Remove the initial and trailing |
             line = line.slice(1, line.length-2)
             cmd = [line_no]
             line.split('|').each {|m| cmd << m.strip if !m.blank?}
             rtn << cmd
           end
         end
      end
      if !collected_comments.empty?
        rtn << ['comment', line_no, collected_comments.join(' ')]
      end
    end
    return rtn
  end
end
