class PageLoadTime < ActiveRecord::Base

  @@page_url = '/profiles/772695c5ee;edit'


  # This gets called when a record is saved
  validate :validate_instance
  def validate_instance
    # Make sure fields aren't blank
    [:url, :remote_ip, :user_agent, :when_recorded, :load_time].each do |field|
       errors.add(field, 'can not be blank') if self.send(field.to_s).blank?
     end
  end


  # get the chart data based on selected options
  def self.get_chart_data(modes=[], ips=[], agents=[])

    chart_data_array = PageLoadTime.get_chart_data_for_one_page(@@page_url,
        modes, ips, agents)

    return chart_data_array

  end


  # the ONE url for the test phr page
  def self.get_page_url
    @@page_url
  end


  # get unique remote ips
  def self.unique_ips
    PageLoadTime.unique_values('remote_ip')
  end


  # get unique user agents ordered by browser type and version number reversely
  def self.unique_agents
    records = PageLoadTime.unique_values('user_agent')

    # Sorts the unique agents by browser type and version number (latest version
    # first). Here is an example of user_agent string: "Mozilla/5.0 (windows
    # nt 6.1; wow64; rv:20.0) gecko/20100101 firefox/20.0"
    rtn = records.sort_by do |e|
      name = e.split(" ").last;
      n, s = name && name.split("/");
      sn = s && s.split(".").first;
      n && sn.to_i;
    end.reverse

    rtn.map do |e|
      label = e.include?("Firefox") ? ("Firefox" + e.split("Firefox")[1]) : e
      [e, label]
    end
  end


  # get unique rails modes
  def self.unique_modes
    PageLoadTime.unique_values('rails_mode')
  end


  # get unique test page url.
  # not used. only one url for now
  def self.unique_urls
    PageLoadTime.unique_values('url')
  end


  # Return a hash containing the page loading time spend on the apache server,
  # rails server, view generating and database processing.
  #
  # Parameter:
  # * apache_log_path the path to apache log file
  # * rails_log_path the path to rails log file
  def self.get_load_times(apache_log_path ='../apache/logs', rails_log_path='log')
    time_page = @@page_url
    line = 200
    tail_file = Rails.root.join(apache_log_path, 'defAccessLog')
    grep_regex = 'GET '+ time_page
    tail_output = self.tail(line, tail_file, grep_regex )
    # Avoid using logger.debug as the method being tested is using the log as its input
    #puts ("\nlog_out: #{tail_output.inspect}")
    last_page_line = tail_output.split("\n").last
    re = / time=(\d+)/
    m = last_page_line.match(re)
    apache_time = Integer(m[1])

    line = 500
    tail_file = Rails.root.join(rails_log_path, "#{Rails.env}.log")
    grep_regex = "Completed.*#{time_page}"
    # Hope that the access is
    tail_output = self.tail(line, tail_file, grep_regex)
    # Avoid using logger.debug as the method being tested is using the log as its input
    #puts ("\nlog_out: #{tail_output.inspect}")
    last_page_line = tail_output.split("\n").last
    re = (/200 OK in (\d+)(\.(\d+))?ms \(Views: (\d+)(\.(\d+))?ms \| ActiveRecord: (\d+)(\.(\d+))?ms/)
    # Avoid using logger.debug as the method being tested is using the log as its input
    #puts ("\nlast page line: #{last_page_line}; regex: #{re.inspect}")
    m = last_page_line.match(re)
    rails_time, view_time, db_time = m[1].to_i, m[4].to_i, m[7].to_i

    { "apache_time" => apache_time,
      "rails_time" => rails_time,
      "view_time" => view_time,
      "db_time" => db_time }
  end


  # Return the result from a tail command line
  # Parameters:
  # * line the number of lines used
  # * tail_file the file being tailed
  # * regex the regular expression used for filtering the tail result
  def self.tail(line, tail_file, regex)
    puts ("\ntail file is(#{tail_file}) regex(#{regex})")
    tail_file = Shellwords.shellescape(tail_file)
    regex = Shellwords.shellescape(regex)

    `tail -#{line} #{tail_file} | grep #{regex}`
  end


  private

  # get the load time data of one page
  def self.get_chart_data_for_one_page(url, mode=[], ip=[], agent=[])
    data_lines = ['load_time', 'apache_time', 'rails_time', 'view_time',
        'db_time']

    cond = {:url=>url}

    if !mode.empty?
      cond[:rails_mode] = mode
    end
    if !ip.empty?
      cond[:remote_ip] = ip
    end
    if !agent.empty?
      cond[:user_agent] = agent
    end

    load_times = PageLoadTime.where(cond).order(:when_recorded)

    chart_data_array = []
    data_lines.each do | data_line|
      data_points = []
      load_times.each do | record |
        data_points.push [record.when_recorded.to_i*1000, record.send(data_line)]
      end
      if data_line == 'apache_time'
        time_unit = 'micro sec'
      else
        time_unit = 'ms'
      end
      chart_data = {
          'name' => data_line + " (#{time_unit})",
          'data' => data_points,
          'norm_max' => nil,
          'norm_min'=> nil,
          'units' => time_unit,
          'type' => nil
      }
      chart_data_array.push(chart_data)
    end

    return chart_data_array

  end


  # get the unique values of one column in the table
  def self.unique_values(column_name)

    records = PageLoadTime.select(column_name).distinct.order(column_name)

    records.map {|rec| rec.send(column_name)}



  end

end
