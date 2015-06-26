# Contains the controller code for generating a flowsheet table.
module FlowsheetGenerator

  # Number of flowsheet columns to be loaded on each request in mobile mode
  COLUMNS_PER_PAGE=100

  private

  # Returns the html and JavaScript for the flowsheet table(s).
  # 
  # Parameters:
  # * profile - the PHR from which the flowsheet should be generated
  # * loinc_numbers - the selected panel loinc numbers
  # * in_one_grid - true if all panels should be combined into a single
  #   flowsheet.
  # * include_all - true if for each test, all values should be included
  #   regardless of which panel it came from.
  # * group_by_code - a code from the TextList 'group_by' that controls
  #   how the records should be grouped by time
  # * date_range_code - a code from the TextList 'date_range' that controls
  #   the date range for which records are included in the flowhseet.
  # * start_date - the epoch time string for the start date for a range
  #   dates to include in the flowsheet.  This only has an effect if
  #   date_range_code is set to '7' ("Customize").
  # * end_date - the epoch time string for the start date for a range
  #   dates to include in the flowsheet.  This only has an effect if
  #   date_range_code is set to '7' ("Customize").
  # * end_date_str - the string value of the end date. It could be in the format
  #   of 'yyyy', 'yyyy Mon', or 'yyyy Mon dd'
  def flowsheet_html_and_js(profile, loinc_numbers, in_one_grid,
        include_all, group_by_code, date_range_code, start_date, end_date,
        end_date_str)

    start_date = start_date.blank? ? nil : start_date.to_i
    end_date = end_date.blank? ? nil : end_date.to_i
    end_date_str = nil if end_date_str.blank?

    pd = PanelData.new(@user)
    phr = profile.phr

    timeline_html = ''
    panel_info = {}
    if !loinc_numbers
      loinc_numbers = Set.new(profile.selected_panels)
    end

    id_shown = profile.id_shown
    template_dir = basic_html_mode? ? 'basic' : (mobile_html_mode? ?  'mobile' : 'form')
    template = File.join(template_dir, 'test_panel_timeline')
    if !loinc_numbers.blank?
      if !in_one_grid
        loinc_numbers.each do |loinc_num|
          data = pd.get_panel_timeline_data_def(loinc_num, profile.id,
            start_date, end_date, end_date_str, group_by_code, date_range_code,
            include_all)
          paginating_panel_info(data) if mobile_html_mode?
          @panel_def = data[0]
          @panel_data = data[1]
          @panel_date = data[2]
          one_panel_info = data[3]
          @form_record_id_shown = id_shown
          @form_record_name = phr.pseudonym
          if template_dir == 'form' && @panel_date.empty?
            output = render_to_string({:partial=>template+ '_empty',
                :formats => [:rhtml], :handlers => [:erb] })
          else
            output = render_to_string({:partial=>template,
                :formats => [:rhtml], :handlers => [:erb] })
          end
          timeline_html += output
          panel_info.merge!(one_panel_info)
        end
      else
        data = pd.get_panel_timeline_data_def_in_one_grid(loinc_numbers,
          profile.id, start_date, end_date, end_date_str, group_by_code,
          date_range_code, include_all)
        paginating_panel_info(data) if mobile_html_mode?
        @panel_def= data[0]
        @panel_data = data[1]
        @panel_date = data[2]
        @form_record_id_shown = id_shown
        @form_record_name = phr.pseudonym
        if template_dir == 'form' && @panel_date.empty?
          output = render_to_string({:partial=>template+ '_empty',
                                     :formats => [:rhtml], :handlers => [:erb] })
        else
          output = render_to_string({:partial=>template,
                                     :formats => [:rhtml], :handlers => [:erb] })
        end
        timeline_html = output
      end
    end
    #      ret_value = {:html=>timeline_html, :info=>panel_info}
    #      render(:json => ret_value.to_json)
    timeline_html.gsub!(/\n\s+/,'')
    return timeline_html, panel_info
  end


  # Converts the entire panel_info (i.e. panel_data and panel_date) into a page of panel_info based on the page number
  # and the specified maximum number of columns per page
  #
  # The sample hash structure of the input parameters
  # date: [{column_key_1=>[header data]}, {column_key_2=>[header data]} ]
  # data: [{column_key_1=>[panel data on line 1], column_key_2=>[panel data on line 1]},
  #        {column_key_1=>[panel data on line 2], column_key_2=>[panel data on line 2]},
  #        ...
  #       ]
  def paginating_panel_info(data, exist_cols= 0, column_numbers=COLUMNS_PER_PAGE)
    panel_data = data[1]
    panel_date = data[2]
    keys = panel_date.map{|e| e.keys[0]}
    s_index = exist_cols.to_i
    e_index = s_index + column_numbers.to_i - 1
    keys = keys[s_index..e_index] if keys
    if keys
      panel_date = panel_date.select{ |e| keys.include?(e.keys[0])}
      panel_data = panel_data.map{|e| e.select{|k,v| keys.include?(k)}}
    else
      panel_date = []
      panel_data = []
    end
    data[1] = panel_data
    data[2] = panel_date
  end


  # Returns a hash of flowsheet source data for loading more columns to the mobile flowsheet table
  def paginated_flowsheet_data_hash(profile, loinc_number, include_all, group_by_code,
    date_range_code, start_date, end_date, end_date_str,
    hide_empty_row=nil, using_group_by=nil, exist_cols=nil, columns_per_page=nil)

    start_date = start_date.to_i if !start_date.blank?
    end_date = end_date.to_i if !end_date.blank?

    pd = PanelData.new(@user)
    data = pd.get_panel_timeline_data_def(loinc_number, profile.id, start_date, end_date,
        end_date_str, group_by_code, date_range_code, include_all)

    paginating_panel_info(data, exist_cols, columns_per_page)
    # if panel date exists
    if (!data[2].empty?)
      hide_empty_panel_data_rows(data) if hide_empty_row
      using_group_by_only(data) if using_group_by
    end
    {"panel_def"=>data[0], "panel_date"=> data[2], "panel_data"=> data[1] }
  end


  # Hide the empty panel data rows using the "no_data" attribute
  def hide_empty_panel_data_rows(data)
    panel_def = data[0]
    panel_data = data[1]
    rtn = []
    panel_def.each_with_index do |e, index|
      # skip the header row which is the first element in panel_def
      rtn << panel_data[index-1] if !e["no_data"] && index > 0
    end
    data[1] = rtn
  end


  # Select any column whose key has a tag 'sum' when using group by
  def using_group_by_only(data)
    # get the keys for the columns displayed when using group by
    the_sum_keys = []
    panel_date = data[2]
    panel_date.each do |e|
      the_key = e.keys[0]
      the_sum_keys << the_key if the_key.include?("sum")
    end

    # select the columns for display when using group by
    panel_data = data[1]
    rtn =[]
    panel_data.map do |row|
      rtn << row.select {|k,v| the_sum_keys.include?(k)}
    end
    data[2] = rtn
  end
end
