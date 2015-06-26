module DbFieldValidationMethods
  def self.included(base); base.extend ClassMethods; end
  ERROR_MESSAGES = {
    :date_formats_not_match =>
      "is invalid because its HL7 and ET fields do not reflect the same date",
    :name_code_not_match => "Display value and its code do not match"
  }
  module ClassMethods

    # Loads validations for the current data table based on the definitions in
    # validation_opts field of db_field_descriptions table
    def load_data_field_validation
      db_table = DbTableDescription.where(data_table: self.to_s.tableize).first
      db_table.db_field_descriptions.each do |df|
        df_name = df.data_column.to_sym
        unless df.validation_opts.blank?
          df.validation_opts.each do |v_type, v_options|
            v_options ?
              self.send("phr_validates_#{v_type.to_s.downcase}_of", df_name, v_options) :
              self.send("phr_validates_#{v_type.to_s.downcase}_of", df_name)
          end
        end
      end
    end

    # Validates selectable field (CNE or CWE field)
    # This method should be mixed into data table model to make it working
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_selectable_of(*attr_names)
      error_message =
        DbFieldValidationMethods::ERROR_MESSAGES[:name_code_not_match]
      configuration = {:message => "is invalid. #{error_message}",
        :with_exception => false}
      configuration.update(attr_names.extract_options!)
      validates_each(attr_names,configuration) do |record, attr_name, value|
        # get db_field based on record and attr_name
        data_table = record.class.name.tableize
        t = DbTableDescription.where(data_table: data_table).first
        db_field = t.db_field_descriptions.where(data_column: attr_name.to_s).first
        # get code value
        code = record.send(db_field.code_field)

        has_error =  false
        # check to see if there is a list attached
        if db_field.item_master_table.blank?
          has_error = true
          extra_msg = "has no selectable list attached"
        elsif code.blank?
          if !value.blank?
            # for CWE list, code could be blank
            # for CNE list, code must not be blank, i.e.
            has_error = !configuration[:with_exception]
          end
        else
          if record.send("latest") != false
            matching_value = db_field.get_field_current_list_value(record)
            has_error = matching_value.blank? || matching_value!=value
          end
        end
        record.errors.add(attr_name, :code,
          :default => extra_msg || configuration[:message],
          :value => value) if has_error
      end
    end

    # Validates the size of the input field
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_size_of(*attr_names)
      attr_names = set_default_options(attr_names)
      validates_size_of(*attr_names)
    end
    
    # Validates phone format
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_phone_of(*attr_names)
      attr_names = set_default_options(attr_names)
      run_regex_validator("Phone number (US or international)", *attr_names)
    end

    # Validates email format
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_email_of(*attr_names)
      attr_names = set_default_options(attr_names)
      run_regex_validator("E-Mail Address", *attr_names)
    end

    # Validates type of a numerical field
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_numericality_of(*attr_names)
      attr_names = set_default_options(attr_names)
      validates_numericality_of(*attr_names)
    end

    # Validates formats of date field and checks to see if the value of its
    # corresponding HL7 and ET fields are reflecting the same date
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_date_of(*attr_names)
      # validates the format of DATE field
      run_regex_validator("Date", *attr_names)
      # checks the corresponding HL7 and ET fields to make sure three fields all
      # point to the same date
      configuration = {:message => ""}
      configuration.update(attr_names.extract_options!)
      validates_each(attr_names, configuration) do |record, attr_name, value|
        if record.errors[attr_name].blank?
          has_error = false
          if value.blank?
            # The corresponding HL7 date and ET date should be blank as well
            if !record.send("#{attr_name}_HL7").blank? ||
                !record.send("#{attr_name}_ET").blank?
              has_error = true
            end
          else
            # Convert normal date to hl7 date
            #
            # Removes white space(s) which may cause exception when doing parsing
            # using ruby's Date.parse method
            date_str = value.split.join("-")
            hl7_date_converted = Date.parse(date_str).to_s.gsub("-","")
            # hl7 date should match to normal date
            hl7_date = record.send("#{attr_name}_HL7")

            if (hl7_date != hl7_date_converted)
              has_error = true
            else
              # compare epoch time with the date
              et_date = record.send("#{attr_name}_ET")
              et_date_converted = Time.parse(date_str).to_i * 1000
              if et_date != et_date_converted
                has_error = true
              end
            end
          end
          not_match_msg = ERROR_MESSAGES[:date_formats_not_match]
          record.errors.add(attr_name, :date, :default => not_match_msg,
            :value => value) if has_error
        end
      end
    end

    # Validates time format, e.g. 8:44 AM or 8:44 PM
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_time_of(*attr_names)
      attr_names = set_default_options(attr_names)
      run_regex_validator("Time", *attr_names)
    end

    # Validates required field
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_required_of(*attr_names)
      configuration = {:unless => Proc.new{|rec| rec.blank_record? }}
      configuration.update(attr_names.extract_options!)
      validates_presence_of(attr_names, configuration)
    end

    # Validates uniqueness of field values
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_unique_of(*attr_names)
      attr_names = set_default_options(attr_names)
      validates_uniqueness_of(*attr_names)
    end

    # Validates format of the input field
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def phr_validates_format_of(*attr_names)
      validates_format_of(*attr_names)
    end

    # Set the default of allow_nil parameter to true
    #
    # Parameter:
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    # * default_options default configuration options stored in a hash
    def set_default_options(attr_names, default_options = {:allow_nil => true})
      conf = default_options.update(attr_names.extract_options!)
      attr_names.push(conf)
    end
    
    # Validates formats using regular expression and error message stored in
    # regex_validators table
    #
    # Parameter:
    # * regex_validator_desc the description of a regex_validator
    # * attr_names an array that consists of field names and variable options. 
    #   The options are the same as the parameters passed to the RAILS's 
    #   validation method
    def run_regex_validator(regex_validator_desc, *attr_names)
      rec = RegexValidator.where(description: regex_validator_desc).first
      if rec.nil?
        logger.error("RegexValidator has no DESCRIPTION=#{regex_validator_desc}")
      else
        error_msg = rec.error_message
        rec_regex = rec.regex
        rec_regex.gsub!("^","\\A")
        rec_regex.gsub!("$","\\z")
        rec_regex = Regexp.new(rec.regex)

        configuration = {
          :message => error_msg,
          :with =>  rec_regex,
          :allow_nil => true
        }
        configuration.update(attr_names.extract_options!)
        ori_conf = configuration.dup
        ori_attr_names = attr_names.dup
        # validates the format
        attr_names.push(configuration)
        validates_format_of *attr_names

        # After passing validation, normalizes field value into standard format
        # before saving
        validates_each(ori_attr_names, ori_conf) do |record, attr_name, value|
          if record.errors[attr_name].empty?
            rtn = rec.normalize(value)
            record.send((attr_name.to_s) + "=", rtn) if rtn
          end
        end
      end
    end
    
  end# end of ClassMethods

  # Used by the :if/:unless options of RAILS's validates_presence_of methods
  def blank_record?
    attrs = self.send("attributes")
    %w(id created_at created_by updated_at updated_by).each do |e|
      attrs.delete(e)
    end
    attrs.to_a.map{|e| e[1].blank? ?  nil : e[1]}.compact.empty?
  end

end # end of DbFieldValidationMethods
