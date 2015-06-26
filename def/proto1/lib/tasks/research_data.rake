require 'fileutils'

namespace :def do

  # Creates research data from usage data
  desc "Pulls usage stats data from the usage_stats table to the research_data table."
  task :research_data_import => :environment do

    to_pull = ENV['include']
    if !to_pull || !(to_pull=='new' || to_pull == 'all')
      puts 'Usage:  rake def:research_data_import include=[new || all]'
    else
      status, response_hash = ResearchData.get_research_data(to_pull)
      if status == 20
        puts 'Successful completion, ' + response_hash['row_count'].to_s +
             ' rows were written to the research_data table.'
      else
        if (!File.directory?('researchData'))
          if (File.exists?('researchData'))
            File.rename('researchData', 'researchDataFile')
            puts 'A file named researchData exists in the proto1 directory.\n' +
                 'This name is reserved for a directory to contain ' +
                 'informational output from this task,\n' +
                 'so the file has been renamed to researchDataFile and ' +
                 'a directory named researchData has been created.'
          end
          FileUtils.mkdir('researchData')
        end
        dt = Date.today()
        filename = 'researchData/ResearchDataImport_' << dt.year.to_s <<
                   dt.month.to_s << dt.day.to_s
        if (File.exists?(filename))
          num = 1
          filename << '_'
          new_filename = filename << num.to_s
          while (File.exists?(new_filename))
            filename.chomp!(num.to_s)
            new_filename = filename << (num += 1).to_s
          end
          filename = new_filename
        end

        File.open(filename, "w") do |file|
          case status
          when 40
            msg = 'Import completed with some errors reported.'
          when 50
            msg =  'An exception was thrown during processing.'
          else
            msg = 'Import ended with an unexpected error.'
          end # case
          file.puts msg
          msg << ' See ' + filename << ' for details.'
          puts msg
          if !response_hash['row_count'].nil?
            file.puts response_hash['row_count'].to_s << ' rows were ' <<
              'written to the research_data_table.'
            file.puts ''
          end
          if !response_hash['exception_msg'].nil?
            file.puts 'The import threw the following exception:'
            file.puts response_hash['exception_msg']
            file.puts ''
          end
          if !response_hash['problems'].nil?

            file.puts 'The following types of problems were found:'
            response_hash['problems_counts'].each do |prob_type, count|
              buff = ' '
              count_str = count.to_s
              buff_char = 10 - count_str.length
              1.upto(buff_char) do |x|
                buff += ' '
              end
              file.puts buff + count_str + ' ' + prob_type + 's'
            end
            file.puts ''

            if response_hash['problems'].size == 1
              file.puts 'Problems were found with data for the following user:'
            else
              file.puts 'Problems were found with data for the following ' <<
                response_hash['problems'].size.to_s << ' users.'
            end

            response_hash['problems'].each_pair do |user, session_rows|

              if session_rows.size == 1
                file.puts '1 session for user ' + user.to_s
              else
                file.puts session_rows.size.to_s + ' sessions for user ' + user.to_s
              end

              session_rows.each_pair do |session_id, rows|
                file.puts ' '
                if rows.size == 1
                  file.puts '1 row for session id ' + session_id.to_s
                else
                  file.puts rows.size.to_s + ' rows for session id ' +
                    session_id.to_s
                end

                rows.each do |event_time, row|
                  file.puts 'problem: ' + row[0][0].to_s
                  file.puts '  ' + row[0][1].to_json
                  ## MOVE THIS TO OUTPUT SESSION DATA ONCE.
                  file.puts 'session rows:'
                  row[0][2].each do |rec|
                    file.puts ' ' + rec.id.to_s + ' ' +
                                    rec.event_time.to_json + ' ' +
                                    rec.event + ' ' +
                                    rec.data.to_json
                  end
                  file.puts ' '
                  # the event_time is also in the row, no need to print here
                end # do for each row
              end # do for each sesion
            end # do for each user
          end # if we have problems


        end # do for the file
      end # if import was not entirely (or at all) successful
    end # if the appropriate parameters were supplied
  end # namespace

end  # research_data.rake
