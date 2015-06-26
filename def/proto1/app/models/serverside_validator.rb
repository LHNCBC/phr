class ServersideValidator
  VALIDATE_TYPE ={
    :auto_completer => "auto_list",
    :calendar => "calendar"
  }

  # Validates all the input data
  # Parameters:
  # * opts - request params with input field data and form name information
  def self.validate_input(opts)
    vdef = validation_def(opts["formName"])
    return vdef.empty? ? nil : validate(opts["fe"], vdef)
  end

  private

  # Validate the input data hash based on the validation definition 
  # Parameters:
  # * data_hash - hash map with all input field data, e.g. {"gender_1" => "Male" }
  # * validate_def - describes all the validation criteria, e.g. 
  # { "gender" =>["auto_list",["Female","Male"]], 
  #   "when_started" =>["calendar", ["YYYY/MM/DD", ["t-100Y","t"]]]}
  def self.validate(data_hash, validate_def)
    error_list = []

    v_target_fields = validate_def.keys 
    data_hash.each do |k, v|
      field_id = "fe_#{k}"
      # get target_field
      tf = k.match(/([^\d]*)((_\d)*)\z/)[1]

      if v_target_fields.include?(tf) && v.strip.length > 0
        case validate_def[tf][0]
          # validate input value to match autocompleter list
          # {:gender =>["auto_list", ["Female","Male"]]}
        when VALIDATE_TYPE[:auto_completer]
          value_list = validate_def[tf][1]
          if !value_list.include?(v)
            error = "Not match to the autocompleter list"
            tmp =["Field: #{field_id}", "Value: #{v}","Error: #{error}"].join("; ")
            error_list << "<li>#{tmp}</li>"
          end
          #validate date format and range
          #{:birth_year =>["calendar", ["YYYY/[MM/[DD]]", ['t-100Y','t']]}
        when VALIDATE_TYPE[:calendar]
          format = validate_def[tf][1][0]
          range = validate_def[tf][1][1]
          error = validate_date_format(format, v)
          error = validate_date_range(range, v) unless error
          if error
            tmp =["Field: #{field_id}", "Value: #{v}","Error: #{error}"].join("; ")
            error_list << "<li>#{tmp}</li>"
          end
        end
      end
    end
    error_list.empty?  ? nil :
      "Following fields are not validate:<ul>#{error_list.join}</ul>"
  end


  # Validates the input date field against a specified format
  # Parameters:
  # * format - the predefined date format for the input date field
  # * date_value - the value of the input date field
  def self.validate_date_format(format, date_value)
    rg = Regexp.new(/\A(YYYY)(\/([\[])?(MM)(\/([\[])?(DD)([\]])?)?([\]])?)?\z/)
    m = rg.match(format)
    if m
    ccyy, mm_dd_part, left_a, mm, dd_part, left_b, dd, right_b, right_a =
      m[1],m[2],m[3],m[4],m[5],m[6],m[7],m[8],m[9]
    else
      raise "The input format #{format} is wrong"
    end

    rtn = []
    rtn[1] = "[1-9]\\d\\d\\d" if ccyy == "YYYY"
    rtn[2], rtn[7] ="(", ")?" if left_a == "[" && right_a =="]"
    rtn[3] = "\\/(0[1-9]|1[0-2])" if mm == "MM"
    rtn[4], rtn[6] ="(", ")?" if left_b == "[" && right_b =="]"
    rtn[5] = "\\/(0[1-9]|[1-2]\\d|3[0-1])" if dd == "DD"
    rtn[0], rtn[8] = "\\A","\\z"
    rtn = rtn.join

    rg = Regexp.new(rtn)
    rg.match(date_value) ? nil : "Please use the correct format #{format}"
  end


  # Validates the input date field against a specified date range
  # Parameters:
  # * range - predefined date range
  # * date_value - the value of the input date field
  def self.validate_date_range(range, date_value)
    if date_value.length == 4
      date_value += "/1"
    end
    mid = DateTime.parse(date_value)

    min, max = range.map(&:dup)
    [min, max].each do |e|
      e.gsub!("Y", ".years")
      e.gsub!("t", "DateTime.now")
    end
    min = eval(min)
    max = eval(max)
    (mid > min) && (mid < max) ? nil :
      "Please use correct date range [#{min.to_date.to_s}, #{max.to_date.to_s}]"
  end


  # Extracts a hash map with all the details for validation
  # Parameters:
  # * form_name - name of a form
  def self.validation_def(form_name)
    fm = Form.where(form_name: form_name).first
    rtn = {}
    rtn.merge!(self.auto_list_vdef(fm.id))
    rtn.merge!(self.calendar_vdef(fm.id))
    rtn
  end

  # Extracts validation details related to the fields with auto-completer list
  # Parameters:
  # * form_id - ID of a form
  def self.auto_list_vdef(form_id)
    conditions =
      [ "form_id = ? and control_type_detail like '%match_list_value=>true%'",
        form_id ]
    rtn ={}
    FieldDescription.where(conditions).each do |fd|
      rtn[fd.target_field] = [ VALIDATE_TYPE[:auto_completer],
                               self.auto_list_vdef_by_field(fd)]
    end
    rtn
  end

  # Returns a hash from target field to it's unique value list
  # Parameters:
  # * form_id - input form id
  # * user_id - ID of the current user
  def self.unique_values_by_field(form_id, user_id)
    conditions =
      [ "form_id = ? and control_type_detail like '%unique_field_value%'",
        form_id ]
    rtn ={}
    FieldDescription.where(conditions).each do |fd|
      data = fd.db_field_description.db_table_description
      table_name = data.data_table.downcase
      form_type = table_name.singularize
      typed_data_records = User.find(user_id).typed_data_records(form_type)
      rtn[fd.target_field] = typed_data_records.map do |e|
        e.send(fd.db_field_description.data_column)
      end.compact.uniq
    end
    rtn
  end
  

  # Extracts validation details related to the date fields
  # Parameters:
  # * form_id - ID of a form
  def self.calendar_vdef(form_id)
    conditions = ["form_id =? and control_type = ?", form_id, "calendar"]
    rtn = {}
    FieldDescription.where(conditions).each do |fd|
      rtn[fd.target_field] = [ VALIDATE_TYPE[:calendar],
                               self.calendar_vdef_by_field(fd)]
    end
    rtn
  end

  # Finds validation details related to a date/calendar field
  # Parameters:
  # * field - date/calendar field which needs to be validated
  def self.calendar_vdef_by_field(field)
    format = field.getParam("date_format")
    min = field.getParam("abs_min")
    max = field.getParam("abs_max")
    range = min ? [min, max] : nil
    [format, range]
  end

  # Copied from text_fields_helper.rb#text_field_with_list
  # Finds auto-completer list which needs to be matched
  # Parameters:
  # * field - the field whose value should match to one of the value in the
  # attached auto-completer list
  def self.auto_list_vdef_by_field(field)
    search_table = field.getParam('search_table')
    is_user_data = search_table.index('user ') == 0
    is_dynamically_loaded = search_table == 'dynamically_loaded'

    listData = nil
    if (!is_user_data)
      col_names = field.getParam('fields_displayed')
      if (col_names.nil?)
        col_names = field.getParam('show')
      end

      if (!is_dynamically_loaded)
        tableClass = search_table.singularize.camelize.constantize
        list_name = field.getParam('list_id')
        list_name = field.getParam('list_name') if list_name.nil?
        if tableClass.respond_to?('get_list_items')
          listData = tableClass.get_list_items(
            list_name, nil, field.getParam('order'), field.getParam('conditions')
          )
        end
      end
    end
    listData ? listData.map{|e| e.send(col_names[0])} : []
  end

end
