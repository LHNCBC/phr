require 'test_helper'

class PageLoadTimeTest < ActiveSupport::TestCase
  
  def test_get_load_time
    page_url = PageLoadTime.get_page_url
    apache_log_path = rails_log_path = 'tmp'

    # set up the apache testing log files
    apache_time = nil
    log_file = Rails.root.join(apache_log_path, 'defAccessLog')
    File.open(log_file, "w") do |f|
      3.times do
        apache_time = (rand(100)+1.0)/10.0
        f.puts "GET #{page_url} time=#{apache_time}"
      end
    end
    
    # set up the rails testing log files
    rails_time = view_time = db_time = nil
    log_file = Rails.root.join(rails_log_path, "#{Rails.env}.log")
    File.open(log_file, "w") do |f|
      3.times do
        rails_time = (rand(100)+1.0)/10.0
        view_time = (rand(100)+1.0)/10.0
        db_time = (rand(100)+1.0)/10.0
        msg = "Completed 200 OK in #{rails_time}ms (Views: #{view_time}ms | ActiveRecord: #{db_time}ms)"
        msg << "[ #{page_url} ]"
        f.puts msg
      end
    end
    #puts ("The correct load times are: apache-#{apache_time}, rails-#{rails_time}, view-#{view_time}, db-#{db_time}")
    
    load_times = PageLoadTime.get_load_times(apache_log_path, rails_log_path)
    assert_equal load_times["apache_time"], (apache_time - 0.5).round
    assert_equal load_times["rails_time"], (rails_time - 0.5).round
    assert_equal load_times["view_time"], (view_time - 0.5).round
    assert_equal load_times["db_time"], (db_time - 0.5).round
  end
  
end



    