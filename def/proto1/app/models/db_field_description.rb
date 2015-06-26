class DbFieldDescription < ActiveRecord::Base
  cache_associations
  extend HasShortList
  belongs_to :regex_validator
  belongs_to :predefined_field
  belongs_to :db_table_description
  has_many :field_descriptions
  has_many :field_validations
  belongs_to :controlling_field, :class_name=>'DbFieldDescription'
  has_many :controlled_fields, :class_name=>'DbFieldDescription', :foreign_key=>'controlling_field_id'
  has_and_belongs_to_many :rules, :join_table=>'rule_db_field_dependencies'
  serialize :fields_saved
  validates_uniqueness_of :data_column, :scope=>:db_table_description_id

  delegate :is_date_type, :to => :predefined_field

  cache_recs_for_fields 'id'

  def validate
    # For some reason, accessing predefined_field_id by the method does not
    # always work here, so we use read/write_attribute.
    if read_attribute('predefined_field_id').nil?
      if !field_type.nil?
        pdf = PredefinedField.find_by_field_type(field_type)
        if pdf.nil?
          errors.add(:field_type, field_type + ' is not a valid field type.')
        else
          write_attribute('predefined_field_id', pdf.id)
        end
      end
      if read_attribute('predefined_field_id').nil?
        errors.add(:predefined_field_id, 'Predefined_field_id is nil for ' +
            data_column.to_s + '.  This is no longer valid.')
      end
    elsif read_attribute('field_type').nil?
      write_attribute('field_type', predefined_field.field_type)
    end

    # controlling_field_id has to be a valid db_field id
    if controlling_field_id
      unless DbFieldDescription.find_by_id(controlling_field_id)
        errors.add(:controlling_field_id,
          " is not a valid ID of DbFieldDescription")
      end
    end

    # more validation to be added for special fields (not others)
    # 1. fields_saved.length > 1 ==> !list_join_string.blank?
    # 2. !controlling_field_id.blank? && !list_master_table.blank? ==> !list_identifier.blank?
    # 3. !item_master_table.blank? ==> !list_code_column.blank?
    # 4 either !controlling_field_id.blank? or !list_code_column.blank?
  end # validate


  # Returns the HL7 data type code (e.g. 'ST') of the field, or nil if there
  # isn't one.
  def hl7_data_type_code
    rtn = nil
    if (predefined_field)
      rtn = predefined_field.hl7_code
    elsif (read_attribute(:field_type) =~ /\A(\w+) - /)  # backward compatibility
      rtn = $1
    end
    return rtn
  end


  # Returns the rails_data_type from predefined_field, or string if there
  # isn't one.
  def rails_data_type
    rtn = nil
    if (predefined_field)
      rtn = predefined_field.rails_data_type
      # default rails data type is string
    else
      rtn = 'string'
    end
    return rtn
  end


  # Override the default ActiveRecord-generated method for field_type.  When
  # possible, we want to base this value on hl7_data_type.
  def field_type
    rtn = nil
    if (predefined_field)
      rtn = predefined_field.field_type
    else
      rtn = read_attribute(:field_type)
    end
    return rtn
  end


  # Returns the maximum character length if this is a string field, or the
  # byte length for other field types.  If this is a virtual field (not really
  # stored) then the return value is nil.
  def max_field_length
    return virtual ? nil :
      db_table_description.model_class.columns_hash[data_column].limit
  end


  # Return the display_only value from predefined_fields
  def display_only?
    rtn=nil
    if (predefined_field)
      rtn = predefined_field.display_only
    end
    return rtn
  end


  # Makes an array of symbols from an array of strings.  If the given array
  # is either empty or nil, an empty array will be returned.
  def make_symbol_array(str_array)
    rtn = []
    if (!str_array.nil?)
      str_array.each do |s|
        rtn << s.to_sym
      end
    end
    rtn
  end


  # Returns a list of fields for the current table.  The return
  # values will be instances of db_field_descriptions.
  #
  # The following fields are automatically excluded:
  #   field_type starts with DT (date fields)
  #   data_column ends with _C or _ET or _HL7 (code fields)
  #   omit_from_fields flag is true
  #
  # Parameters:
  # * table_id - the id of the table whose db_field_descriptions should be
  #    returned
  # * conditions - a string of conditions to be added at the end of the
  #    set used to omit certain fields from the list.  This would be in
  #    addition to the ones automatically excluded (see above).  This
  #    parameter is optional; default is nil.
  # Returns:  the db_field_description objects as noted above
  #
  def get_field_display_names(table_id, conditions=nil)
    conditions_string = "db_table_description_id = " + table_id.to_s + " AND " +
                        "data_column NOT like '%_C' AND " +
                        "data_column NOT like '%_ET' AND " +
                        "data_column NOT like '%_HL7' AND " +
                        "omit_from_field_lists is false"
    # removed from conditions string - combining date and non-date fields
    #                   "field_type NOT like 'DT%' AND " +
    if !conditions.nil?
      conditions_string += " " + conditions
    end
    return get_field_lists('display_name', 'display_name', conditions_string)
  end # get_field_display_names


  # DEPRECATED.  Date and non-date fields now in same section.  Remove
  #              when when old edit_phr_fetch_rule form is removed.
  # Returns a list of non-date fields for the current table.  The return
  # values will be instances of db_field_descriptions.
  #
  # The following fields are automatically excluded:
  #   field_type starts with DT (date fields)
  #   data_column ends with _C or _ET or _HL7 (code fields)
  #   omit_from_fields flag is true
  # UPDATED 1/8/10 to include dates - combining the 2 lines
  #
  # Parameters:
  # * table_id - the id of the table whose db_field_descriptions should be
  #    returned
  # * conditions - a string of conditions to be added at the end of the
  #    set used to omit certain fields from the list (see above).  This
  #    parameter is optional; default is nil.
  # Returns:  the db_field_description objects as noted above
  #
  def get_non_date_field_display_names(table_id, conditions=nil)
    conditions_string = "db_table_description_id = " + table_id.to_s + " AND " +
                        "data_column NOT like '%_C' AND " +
                        "data_column NOT like '%_ET' AND " +
                        "data_column NOT like '%_HL7' AND " +
                        "omit_from_field_lists is false"
    # removed from conditions string - combining date and non-date fields
    #                   "field_type NOT like 'DT%' AND " +
    if !conditions.nil?
      conditions_string += " " + conditions
    end
    return get_field_lists('display_name', 'display_name', conditions_string)
  end # get_non_date_field_display_names


  # DEPRECATED.  Date and non-date fields now in same section.  Remove
  #              when when old edit_phr_fetch_rule form is removed.
  # Returns a list of date fields for the current table.  The return
  # values will be instances of db_field_descriptions.
  #
  # The following fields are automatically excluded:
  #   field_type does NOT start with DT (date fields)
  #   data_column ends with _C or _ET or _HL7 (code fields)
  #   omit_from_fields flag is true
  #
  # Parameters:
  # * table_id - the id of the table whose db_field_descriptions should be
  #    returned
  # * conditions - a string of conditions to be added at the end of the
  #    set used to omit certain fields from the list (see above).  This
  #    parameter is optional; default is nil.
  # Returns:  the db_field_description objects as noted above
  #
  def get_date_field_display_names(table_id, conditions=nil)
    conditions_string = "db_table_description_id = " + table_id.to_s + " AND " +
                        "field_type like 'DT%' AND " +
                        "data_column NOT like '%_C' AND " +
                        "data_column NOT like '%_ET' AND " +
                        "data_column NOT like '%_HL7' AND " +
                        "omit_from_field_lists is false "
    if !conditions.nil?
      conditions_string += " " + conditions
    end
    return get_field_lists('display_name', 'display_name', conditions_string)
  end # get_date_field_display_names


  # This method submits a request to get_list_items and then creates two arrays,
  # a values array and a codes array, from the db_field_descriptions returned.
  #
  # The get_list_items method follows the convention used by other classes that
  # have a get_list_items method, where the actual objects are returned.  This
  # method is necessary when a list is requested via a record data requester,
  # which wants the values and codes already extracted from the objects.
  #
  def get_field_lists(value_column, the_order, the_conditions)

    fds = DbFieldDescription.get_list_items(nil, nil, the_order, the_conditions)
    list_values = []
    list_codes = []
    if !fds.nil?
      fds.each do |fd|
        list_values << fd.send(value_column)
        list_codes << fd.id
      end
    end
    return [list_values, list_codes]

  end # get_field_lists


  # Returns a list of operators appropriate for the type of the
  # current field.
  #
  # Parameters:  none
  # Returns:  an array of arrays - operator values and their associated codes
  def get_field_operators
    return predefined_field.comp_operators
  end # get_field_operators


  # Returns a list of operators with operator_type = 'set_handling' that
  # is appropriate for the type of the current field.  Basically, if the
  # current field is not a set type, the "list" will consist of one
  # entry with a display value of 'N/A'.
  #
  # Parameters:  none
  # Returns:  an array of arrays - operator values and their associated codes
  def get_set_handling_operators
    rtn = []
    if predefined_field.comp_operators
      predefined_field.comp_operators.each do |op|
        if op.operator_type == 'set_handling'
          rtn << op
        end
      end
    end
    return rtn
  end # get_field_operators


  # Returns a list of field names for fields that are dependent on the
  # current field (the db_field_description object on which this was called).
  #
  # Parameters:  none
  # Returns:  an array of arrays - operator values and their associated codes
  #
  def get_dependent_field_names
     conditions = "AND is_major_item is false AND (major_item_ids is null " +
                  " OR (major_item_ids is NOT NULL AND (" +
                  "major_item_ids = '" + id.to_s + "' OR major_item_ids LIKE " +
                  "'" + id.to_s + ",%' OR major_item_ids LIKE '%," +
                  id.to_s + "' OR major_item_ids LIKE '%," + id.to_s + ",%')))"
    return get_non_date_field_display_names(db_table_description_id, conditions)
  end # get_dependent_field_names


  # Returns true if this field description is a field that holds a display value
  # from a coded list.
  def coded_list_value?
    if !@is_coded_list_value
      # It's a coded list display field if it has an item master table
      # and there an associated code field.
      @is_coded_list_value = !item_master_table.blank? &&
        db_table_description.data_table.singularize.camelize.constantize.new.
        respond_to?(code_field)
    end
    return @is_coded_list_value
  end


  # Returns the current field value for this field in the given data model
  # record.  If the field is not a list field, or if the list's code is no
  # longer in the list, then the returned value will be the value from the
  # given record.
  #
  # Note:  This has the same purpose as "get_current_field_value" (a private
  # method) but takes different arguments.
  #
  # Parameters:
  # * data_record - a saved user data model record with a field described
  #   by this db_field_descripton.
  def get_field_current_value(data_record)
    rtn = nil
    if coded_list_value? && !data_record.send(code_field).blank?
      # The field is a for a coded list, and there is a code saved
      rtn = get_field_current_list_value(data_record) # might return nil
    end
    return rtn ? rtn : data_record.send(data_column)
  end


  # Finds the value of the current db_field which has a selectable list based
  # on the current selected code value and its controlling fields
  #
  # Parameters:
  # * data_record a user data record which has the selected code value and the
  # code values of its controlling fields (e.g. a record from phr_drugs table
  # which has the following fields: drug_strength_form, name_and_route and their
  # code fields where name_and_route is controlling field of drug_strenght_form
  # field)
  def get_field_current_list_value(data_record)
    list_value = nil
    # db_field should be attached with a list
    if !item_master_table.blank?
      # a list of controlling fields linked using controlling_field_id along
      # with selected code values for each field
      controlling_fields = []
      if controlling_field_id.blank?
        db_field = self
        list_code = data_record.send(code_field)
        controlling_fields << [db_field, list_code]
      else
        db_field = self
        while !db_field.controlling_field_id.blank?
          controlling_fields <<
            [db_field, data_record.send(db_field.code_field)]
          # find controlling db_field
          db_field = DbFieldDescription.find(db_field.controlling_field_id)
        end
        controlling_fields <<
          [db_field, data_record.send(db_field.code_field)]
      end

      controlling_field = nil
      controlling_fields.reverse.each do |db_field, list_code|
        # get list_item and list_value, then uses the list_item as
        # controlling field to find list_value in the db_field(s) being
        # controlled recursively
        controlling_field, list_value =
          db_field.get_field_current_item_and_value("", list_code,
          controlling_field, true)
      end
    end
    return list_value
  end


  # Returns the current record's item_master_table record instance for the name
  # field, based on the conditions provided in list_identifier and/or
  # list_code_column.
  #
  # Parameters:
  # * saved_value - existing field value saved in the table
  # * code_value - a correspoding code value for the name field in the existing
  #                user data table
  # * controlling_field_instance - a record instance that controls this field
  # * always_check_master_table - force to get the current value from master table
  #                               if true
  # Returns
  # * record_instance
  # * field_value
  #
  def get_field_current_item_and_value(saved_value, code_value,
      controlling_field_instance = nil, always_check_master_table = false)
    err_msg = "Error: db_fields_descriptions: id=>#{id}\n"+
        "content is not correct in list_master_table, item_master_table " +
        "and/or list_code_column"
    show_err = false
    record_instance = nil
    field_value = nil

    if !list_code_column.nil?
      condition = {list_code_column.to_sym=>code_value}
    else
      condition = nil
    end

    # root field
    if controlling_field_id.blank?
      # if code is unique in item_master_table
      if item_table_has_unique_codes
        if !item_master_table.blank? && !list_code_column.blank?
          record_instance = get_current_item(item_master_table, condition)
          field_value = get_current_field_value(saved_value, record_instance,
              always_check_master_table)
        end
      # code is not unique
      else
        # there's list_master_table, which has a get_list_items method
        # only 2 tables exist: answer_lists and text_lists
        if !list_master_table.blank?
          # there must be a list_identifier and a item_master_table
          # and a list_code_column
          if !list_identifier.blank? && !item_master_table.blank? &&
                !list_code_column.blank? && !current_item_for_field.blank?
            # get the instance
            record_instance = get_current_item(list_master_table, condition,
                current_item_for_field, list_identifier)
            field_value = get_current_field_value(saved_value, record_instance,
                always_check_master_table)
          else
            show_err = true
          end
        # no list_master_table
        # then there's item_master_table and a list_code_column
        elsif !item_master_table.blank? && !list_code_column.blank?
          # get the instance
          record_instance = get_current_item(item_master_table, condition)
          field_value = get_current_field_value(saved_value, record_instance,
              always_check_master_table)
        else
          show_err = true
        end
      end
    # dependent field,
    else
      # there must be a controlling_field_instance
      if !controlling_field_instance.blank?
        # there's a method to return a record instance
        if !current_item_for_field.nil?
          if !item_master_table.blank? && !list_code_column.blank?
            record_instance = get_current_item_by_controlling_field(
                controlling_field_instance, condition, current_item_for_field)
            field_value = get_current_field_value(saved_value, record_instance,
                always_check_master_table)
          else
            show_err = true
          end
        # no current_item_for_field
        else
          # has no other fields dependent on this field,
          # the a record instance is not needed, get the value only
          if !has_controlled_fields?
            if !current_value_for_field.nil?
              record_instance = nil
              field_value = get_current_field_value(saved_value,
                  controlling_field_instance, always_check_master_table)
            # not direct method to get field value
            else
              # if code is unique in item_master_table
              if item_table_has_unique_codes
                if !item_master_table.blank? && !list_code_column.blank?
                  record_instance = get_current_item(item_master_table, condition)
                  field_value = get_current_field_value(saved_value,
                      record_instance, always_check_master_table)
                else
                  show_err = true
                end
               # code is not unique
              else
                if !fields_saved.nil?
                  record_instance =nil
                  field_value = get_current_field_value(saved_value,
                      controlling_field_instance, always_check_master_table)
                else
                  show_err = true
                end
              end
            end
          # has other fields dependent on this field
          else
            # no such cases
          end
        end
      else
        logger.debug "controlling_instance is not provided."
      end
    end
    if show_err
      logger.debug err_msg
    end

    return [record_instance, field_value]
  end


  # Returns the name of the code field corresponding to this field.  It does
  # not check to see whether this field has a code field; the assumption is that
  # the caller knows there is one.
  def code_field
    return data_column + '_C'
  end


  # Returns a flag that indicates if there's any VIRTUAL fields controlled by
  # this field
  def has_controlled_virtual_field?

    has_one = false
    controlled_fields.each do |field|
      if field.virtual
        has_one = true
        break
      end
      has_one = field.has_controlled_virtual_field?
      if has_one
        break
      end
    end
    return has_one
  end


  # Returns the value of abs_max as a Time object.
  # Currently allowed formats are limited.  You can use "t" for today, and write
  # t-50Y for 50 years ago, or t+2Y for two years from now.  If abs_max
  # is blank, nil will be returned.  Note that in order to allow the time to be compared
  # as a maximum, we actually have to return the first moment of the next day.
  def abs_max_as_date
    rtn = abs_min_as_date(abs_max)
    rtn += 86400 if rtn # plus one day (to the start of the next day for a limit)
    return rtn
  end


  # Returns the value of abs_min (or the given string) as a Time object.  See
  # abs_max_as_date for supported formats.  The start of the day will be
  # returned.  If abs_min is blank, nil will be returned.
  #
  # Parameters
  # * str - the string to be parsed.  If not given, this will use abs_min.
  def abs_min_as_date(str = abs_min)
    DateInterpretation.interpret_relative_date(str)
  end



  private


  #
  # get a table's record instance
  #
  # Parameters:
  # * table_name - a table's name
  # * condition - a hashmap of search condition
  # * method - optional, a method to return an arrray of record instances,
  #            other than the default 'find' method
  # * param - optional, extra parameters needed by the method
  #
  # Returns:
  # * record_instance - one record instance of the table_name table
  #
  def get_current_item(table_name, condition, method = nil, param=nil)
    tableClass = table_name.singularize.camelcase.constantize
    if method.nil?
      records = tableClass.where(condition).load
    else
      # for get_list_items method
      if !param.nil?
        records = tableClass.send(method,param,nil,nil,condition)
      end
    end
    if records.nil? || records.length != 1
      logger.debug "Error: db_fields_descriptions: id=>#{id}\n"+
          "does not return exactly one record for #{condition.inspect}"
    else
      record_instance = records[0]
    end
    return record_instance
  end


  #
  # get a table's record instance by calling a method on the controlling field
  #
  # Parameters:
  # * cotnrolling_field - the field controlls this field
  # * condition - a hashmap of search condition
  # * method - optional, a method to return an arrray of record instances,
  #            other than the default 'find' method
  #
  # Returns:
  # * record_instance - one record instance of item_master_table
  #
  def get_current_item_by_controlling_field(controlling_field, condition, method)
    # for get_sublist_items method
    records = controlling_field.send(method,condition)
    if records.nil? || records.length != 1
      logger.debug "Error: db_fields_descriptions: id=>#{id}\n"+
          "does not return exactly one record for #{condition}"
    else
      record_instance = records[0]
    end
    return record_instance

  end

  #
  # Return a field's value giving its record instance
  #
  # Parameters:
  # * saved_value - existing field value saved in the table
  # * record_instance - a field's item_master_table record instance
  #                     or a controlling field's record instance
  # * always_check_master_table - force to get the current value from master
  #                               table if true
  # Returns:
  # * field_value - the value of a field
  #
  def get_current_field_value(saved_value, record_instance,
      always_check_master_table=false)
    field_value = saved_value
    if !record_instance.nil?
      if always_check_master_table || UPDATE_LIST_VALUES || self.virtual
        # record_instance is the controlling field's record instance
        if current_value_for_field.blank?
          field_values = []
          fields_saved.each do |field_saved|
            field_values << record_instance.send(field_saved)
          end
          field_value = field_values.join(list_join_string)
        # record_insntance is this field's item_master_table record instance
        else
          field_value = record_instance.send(current_value_for_field)
        end
      end
    else
      logger.debug "Error: record_instance is nil in get_current_field_value " +
          " for db_field_descriptions record where id=#{id}\n" +
          " saved field value is used instead."
    end
    return field_value
  end


  #
  # check if this field controlls other fields
  #
  # Returns:
  # * True/False
  #
  def has_controlled_fields?
    ret = false
    controlled_fields = DbFieldDescription.where(:controlling_field_id=>id).load
    if controlled_fields.length >0
      ret = true
    end
    return ret
  end
end # db_field_description.rb
