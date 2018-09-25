# A base class for user data tables, but as a module, so we don't have to
# create a table, "user_datas".
module UserData
  module ClassMethods # Intended to be class methods on the class that extends this
    # Returns a hash from the given data column names of date fields to hashes of
    # requirements we enforce on the date fields.  This method is here due to the
    # fact that we currently define these requirements in the
    # (db_)field_descriptions tables.  In the future, it would be nice to define
    # the requirements directly in the model classes, but that would require
    # some rewriting of the regular (non-basic) mode.
    #
    # Parameters:
    # * date_fields - an array of data column names for date fields.  The names
    #   can also be target_fields of field_descriptions records if there is
    #   no relevant user data table.
    # * form - the preferred form who tooltip must be inspected.  (Again,
    #   this should not really be defined there, but in the model class.)
    def date_requirements(date_fields, form)
      # Drop the cached values if the date has changed.
      if @cache_created_date && (Time.now - @cache_created_date > 1.day)
        @cache_created_date = nil
        @date_requirements = nil
      end
      @cache_created_date = Time.now.to_date.to_time if !@cache_created_date
      if (!defined? @date_requirements) || @date_requirements.nil? ||
          @date_requirements[form].nil?
        rtn = {}
        db_td = nil
        db_td = DbTableDescription.find_by_data_table(table_name) if respond_to?(:table_name)
        form_rec = nil
        date_fields.each do |field|
          reqs = {}
          if db_td # usually defined, but not always so for tests
            db_fd = db_td.db_field_descriptions.find_by_data_column(field)
            if db_fd # usually defined, but not always so for tests
              reqs['required'] = db_fd.required
              fds = db_fd.field_descriptions
              fd = fds[0]
              if fds.size > 1
                fds.each do |f|
                  if f.form.form_name == form
                    fd = f
                    break
                  end
                end
              end
            end
          else
            # Assume date field is a field description target field name.
            form_rec = Form.find_by_form_name(form) if !form_rec
            fd = form_rec.field_descriptions.find_by_target_field(field)
          end
          if fd # usually defined, but not always so for tests
            reqs['month'], reqs['day'] = fd.get_date_format_requirements
            reqs['max'] = db_fd.abs_max_as_date if db_fd
            reqs['min'] = db_fd.abs_min_as_date if db_fd
            ctd = fd.control_type_detail
            reqs['epoch_point'] = ctd.nil? ? 1: ctd['epoch_point'] || 1
            rtn[field] = reqs
          end
        end
        @date_requirements ||= {}
        @date_requirements[form] = rtn
      end
      return @date_requirements[form]
    end


    # Returns the next available record_id (for a new record) within the scope
    # of the given profile ID and "parent record".
    #
    # Parameters
    # * profile_id - the profile ID for which a new record ID in this table
    #   is needed.
    # * p_rec_id - (optional) for tables that have the concept of
    #   a parent record, the ID of that record
    # * parent_table_foreign_key - (optional unless p_rec_id is given) the name of
    #   the column containing p_rec_id
    def next_record_id(profile_id, p_rec_id=nil, parent_table_foreign_key=nil)
      if !p_rec_id.nil?
        last_record_id = self.where("profile_id = ? and " +
              "#{parent_table_foreign_key} = ?",
            profile_id, p_rec_id).maximum('record_id')
      else
        last_record_id = self.where("profile_id = ? ",
            profile_id).maximum('record_id')
      end
      if !last_record_id.nil?
        record_id = last_record_id +1
      else
        record_id = 1
      end
      return record_id
    end


    # Returns the name of the code field for a field.
    #
    # Parameters:
    # * field - the data column (as a string)
    def code_field(field)
      return field + '_C'
    end


    #
    # Returns the default columns that are not checked in the save code for emptiness
    #
    def phr_ignored_columns
      ['version_date','deleted_at','latest', 'profile_id', 'record_id']
    end

  end # ClassMethods module

  include DateValidations

  # Validates a CNE list field whose list is constant for the class.  The list
  # should have been set up via init_nonsearch_list.  In the process, the
  # field value will be populated based on the value in the code field.
  #
  # Parameters:
  # * field - the data column containing the list string (as a symbol).  We
  #   assume that "field" + "_C" is the associated code field.
  def validate_cne_field(field)
    field_str = field.to_s
    c_field = self.class.code_field(field_str)
    if new_record? || send(c_field + '_changed?')
      c_val = send(c_field)
      if c_val.blank?
        errors.add(field, 'is a required field')
      else
        # Set the value based on the code
        new_val = self.class.send(field_str+'_for_code', c_val)
        if !new_val
          errors.add(field, 'must match a list value')
        else
          send(field_str+'=', new_val)
        end
      end
    end
  end


  # Validates a CWE list field whose list is constant for the class.  The list
  # should have been set up via init_nonsearch_list.  In the process, the
  # field value will be populated based on the value in the code field.  (No
  # real validation is done for CWE fields, because we allow non-coded values,
  # but this is called during the validation process, just as for CNE fields.)
  #
  # Parameters:
  # * field - the data column containing the list string (as a symbol).  We
  #   assume that "field" + "_C" is the associated code field.
  def validate_cwe_field(field)
    field_str = field.to_s
    c_field = self.class.code_field(field_str)
    if new_record? || send(c_field + '_changed?')
      c_val = send(c_field)
      # If the code field is blank, but the display field hasn't chanegd,
      # then the user is clearing the field, so we need to clear the display
      # field.
      if c_val.blank?
        send(field_str+'=', '') if !send(field_str + '_changed?')
      else # Set the value based on the code
        new_val = self.class.send(field_str+'_for_code', c_val)
        send(field_str+'=', new_val)
      end
    end
  end


  # Assembles error messages for this record based on the given hash of
  # field names (as strings) to display names.
  #
  # Parameters:
  # * display_labels - a hash of data column names (strings) to display labels
  def build_error_messages(display_labels)
    all_errs = []
    errors.each do |attr, err_message|
      all_errs << "#{display_labels[attr.to_s]} #{err_message}"
    end
    return all_errs
  end


  # Updates a field with one of the two given values, using whichever is
  # different from the current value.  If both are different, the second
  # value wins.  If one is the empty string, and the other is the current value,
  # no change will be made.  Nil, empty string, and whitespace values are
  # considered to be equal.  The current use case for this is for updating the
  # "where done" field of obr_records when the user submits a form from the
  # basic mode, which has two fields for entering CWE list values.
  #
  # Parameters:
  # * field - the field to be updated (if an update is needed)
  # * val1 - the first value
  # * val2 - the second value
  def update_field_with_vals(field, val1, val2)
    cur_val = send(field)
    cur_val = '' if cur_val.blank?
    if val2 != cur_val && !val2.blank?
      send(field.to_s+'=', val2)
    elsif val1 != cur_val && !val1.blank?
      send(field.to_s+'=', val1)
    elsif val1.blank? && val2.blank? && !cur_val.blank?
      send(field.to_s+'=', '')
    end
  end

end
