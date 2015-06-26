require 'csv'

class ActiveRecord::Base

  # This method searches the table for a record matching the given field data
  # (input_fields) and then returns data for the given output_fields.  The
  # return value is a hash from the output_field names to the value(s) for
  # the record that was found.
  #
  # This is intended to be called after the user has selected an item from an
  # autocompleter, when the program then needs to go back for additional
  # data about the selected item, but could be used with any table.
  #
  # Parameters:
  # * input_fields - a hash from field names (column names) for this table
  #   to values.  Together the entries in input_fields should specify a
  #   particular record in the table.
  # * output_fields - an array of field names specifying the data to be
  #   returned.  These field names can be method names defined in the model
  #   class rather than column in the actual database table.
  # * list_name - not used
  def self.find_record_data(input_fields, output_fields, list_name=nil)
    record = find_record(input_fields)

    rtn = {}
    output_fields.each {|of| rtn[of] = record.send(of)} if record
    return rtn
  end


  # Parses the given string, which represents a hash map, where
  # the values can be lists or hash maps.  Example of supported syntax:
  #    one=>two,three=>(four, five, six),seven=>{eight=>nine,ten=>eleven}
  # Currently used for the control_field_detail and dependencies fields.
  # Note:  This parser probably should not have been written.  If you need
  # something that does this, use the YAML class instead.
  def self.parse_hash_value(s)
    c_hsh = {}
    # "&& !s.strip.empty?" is added for Oracle database
    # if a column value is null, ActiveRecord reurns a empty string for that
    # column on Oracle database.
    # but it is a nil object on MySQL database
    if (!s.nil? && !s.strip.empty?)
      start_ind = 0
      end_ind = s.length
      while (start_ind < end_ind)
        # Parse the key for the first key/value pair.
        end_key = s.index('=>', start_ind)
        key = s[start_ind..end_key-1]

        # Parse the value for the key
        start_ind = end_key+2
        is_map = false
        is_list = false
        if (s[start_ind..start_ind]=='(')
          # The value is a list
          list_val = []
          c_hsh[key] = list_val
          start_ind += 1
          is_list = true
        elsif (s[start_ind..start_ind]=='{')
          # The value is a map
          map_val = {}
          c_hsh[key] = map_val
          start_ind += 1
          is_map = true
        end

        # Look for the next unescaped comma, which delimits the value.
        # In the case of a list value, we also look for a ')'.
        # In the case of a list value, we also look for a '}'.
        found = false
        start_val = start_ind
        while (!found && start_ind < end_ind)
          if (is_list)
            end_val = s.index(/,|\)/, start_ind)
          elsif (is_map)
            end_val = s.index(/,|\}/, start_ind)
          else
            end_val = s.index(',', start_ind)
          end
          if (end_val.nil?)
            val = s[start_val .. end_ind-1]
            # Get rid of the escapes
            val.gsub!(/\\(.)/, '\1')
            c_hsh[key] = val
            start_ind = end_ind
          else
            # See if the comma (or ')' or '}') was escaped
            backslash_count = 0
            prev_char = end_val - 1
            while (s[prev_char-backslash_count..prev_char-backslash_count] == '\\')
              backslash_count += 1
            end
            if (backslash_count.modulo(2) == 1)
              # The value was escaped
              if (end_val == end_ind-1) # the last character
                # Then, although it was escaped, we don't look further for more
                # of the value because we are at the end of the string.
                found = true
                c_hsh[key] = s[start_val .. end_val]
                start_ind = end_ind
              end # and else, we continue to get the rest of the value
            else # (backslashCount.modulo(2) == 0)
              # The comma/parenthesis/brace was not escaped.  We have the value.
              val = s[start_val .. end_val-1]
              # Get rid of the escapes
              val.gsub!(/\\(.)/, '\1')
              if (is_list || is_map)
                if is_list
                  list_val.push(val.strip)
                else
                  k, v = val.split('=>')
                  map_val[k] = v
                end
                if (s[end_val .. end_val] != ',')
                  # This was the last value in the list
                  found = true
                  # Advance endVal to the comma following the parenthesis
                  # so the startInd will be set right, but only if we haven't
                  # reached the end of the string.
                  if (end_val < end_ind-1)
                    end_val += 1
                  end
                else
                  # Advance startVal so the next list element doesn't have the
                  # text of the previous
                  start_val = end_val + 1
                end
              else
                c_hsh[key] = val
                found = true
              end
            end # if a value was found
            start_ind = end_val + 1
          end
        end # while value not found
      end
    end # if the string to be parsed is not nil
    return c_hsh
  end

  DISALLOWED_CSV_UPDATE_COLS = ['created_at', 'updated_at']
  # Finds records specified by conditition_params (or all
  # records if condition_params is nil) and returns a CSV formatted
  # representation of the data (including a header row).
  # Above that header row is a row containing the name of this table
  # in the second column.
  #
  # Parameters:
  # * condition_params - a hash from table column names to values.  This
  #   is used to narrow down the number of records returned.  Only records
  #   with matching values in the specified columns will be returned.  This
  #   is optional, and can be nil (in which case the data for all records
  #   is returned).
  #
  # Returns - the CSV formatted data
  def self.csv_dump(condition_params=nil)
    output = CSV.generate do |csv|
      # Output the table name
      csv << ['Table', self.table_name, '(Do not edit or remove this line.)']
      # Output the header row
      col_names = column_names
      # We used to excdlue created_at and updated_at from the export,
      # but it turns out that these are useful for viewing.  (However, we still
      # exclude them from the import.)
      #DISALLOWED_CSV_UPDATE_COLS.each {|c| col_names.delete(c)}
      csv << col_names

      # Now output each record
      where(condition_params).order(:id).each do |rec|
        row_data = []
        # Be careful not to call attribute accessor methods on rec, because
        # those might be overridden (e.g. GopherTerm's consumer_name).
        rec_attrs = rec.attributes
        #DISALLOWED_CSV_UPDATE_COLS.each {|c| rec_attrs.delete(c)}
        col_names.each {|cn| row_data << rec_attrs[cn]}
        csv << row_data
      end
    end
  end


  # Updates records based on a multi-line CSV string.  (Picture a CSV file
  # read into a string.)  The first line of the CSV data should be the table
  # column names, the first of which should be 'id'.  Rows that follow update
  # existing records if the 'id' column value is present.  New records are
  # created for rows that are missing a value in the 'id' column.  If the
  # first column is of the form 'delete id' where 'id' is an id value, then
  # the record with that ID is destroyed.  If the model class specifies that
  # related records are also destroyed when a record is destroyed, that will
  # happen too.  Be careful.
  #
  # The whole thing is done inside a transaction.  If anything goes wrong,
  # then everything is rolled back, and an exception will be raised.
  #
  # This method also takes care of making a backup file prior to starting.
  # However, the backup is only for this table.  Dependent tables (affected
  # by "delete") are not backed up.  A DataEdit record is created with
  # information about the user who did this update, and the location of
  # the backup file.
  #
  # Note: Unlike the csv_dump command, this one does not expect the first
  # line of the CSV to contain the table name.  (That will cause an error).
  #
  # Parameters:
  # * csv_string - the string containing the CSV data.
  # * user_id - the ID of the user doing the update
  def self.update_by_csv(csv_string, user_id)
    update_data = CSV.parse(csv_string)
    update_by_parsed_csv(update_data, user_id)
  end


  # This is the same as update_by_csv, but instead of a string of CSV, it
  # accepts the parsed CSV output of CSV.parse.  See update_by_csv
  # for details on what these two methods do.
  #
  # Parameters:
  # * update_data - the parsed CSV data in the format returned by
  #   CSV.parse.
  # * user_id - the ID of the user doing the update
  def self.update_by_parsed_csv(update_data, user_id)
    backup_file = make_table_backup
    col_name_set = Set.new(column_names)
    DISALLOWED_CSV_UPDATE_COLS.each {|c| col_name_set.delete(c)}
    self.transaction do
      header_row = nil
      update_data.each do |row|
        # The first row of update_data should be the header row
        # listing the record attribute names.
        if (!header_row)
          header_row = row
          if (header_row.length<1)
            raise 'The first row should be the header row with the ' +
               'column names'
          elsif (header_row[0].strip != 'id')
            raise 'The first column in the file should be the "id" '+
              "column (not \"#{header_row[0]}\")"
          end
        else
          # The first field should be an ID, or a string with the word
          # "delete".  Skip blank rows.
          if row.length > 0
            id_field = row[0]
            id_field = id_field.strip if id_field
            if id_field && id_field =~ /\Adelete (\d+)\z/
              # Delete this record
              id = $1.to_i
              rec = find_by_id(id)
              raise "No record found to delete for ID #{id}" if !rec
              rec.destroy
            else
              # Make a hash of the record field values, skipping the id and
              # any fields that are not a column in the table.
              field_vals = {}
              if (row.length > header_row.length)
                raise 'A row cannot exceed the number of fields in the '+
                      "header.  The row was #{row.inspect}"
              end

              # Skip over the ID field
              row[1..-1].each_with_index do |val, i|
                if col_name_set.member?(header_row[i+1])
                  field_vals[header_row[i+1]] = val.nil? ? val : val.strip
                end
              end

              if id_field.blank?
                # Create a new record
                create!(field_vals)
              elsif id_field =~ /\A-?(\d+)\z/
                # Update the record
                id = id_field.to_i
                rec = find_by_id(id)
                raise "No record found to update for ID #{id_field}" if !rec
                rec.update_attributes(field_vals)
                rec.save!
              else
                # Invalid id value
                raise "Invalid id column value: #{id}"
              end
            end # else not deleting
          end # if the row was not blank
        end # not header row
      end # each row

      # Create a DataEdit record to record the edit
      DataEdit.create(:user_id=>user_id, :data_table=>table_name,
        :backup_file=>backup_file)
    end # transaction
  end # update_by_csv


  # Makes a backup of this table.  Backup files are written to
  # DATA_CONTROLLER_BACKUP_DIR, which is specified in the mode-specific
  # environment files (e.g. environments/development.rb).
  #
  # Returns:  the pathname for the backup file.
  def self.make_table_backup
    database_name = DatabaseMethod.getDatabaseName
    file_name = File.join(DATA_CONTROLLER_BACKUP_DIR,
                          database_name+'.'+table_name)
    file_base = file_name
    # Make the file unique
    counter = 1
    while (File.exists?(file_name))
      counter += 1
      file_name = file_base + '_' + counter.to_s
    end

    File.open(file_name, 'w') do |file|
      file << csv_dump
    end

    return file_name
  end


  # Defines three methods, "list_name"_list for accessing list_items,
  # "list_name"_for_code(code_val) for retrieving the display string for
  # the given code from the list items, and "list_name"_item for retrieving
  # the ActiveRecord list item object for a given code.
  #
  # Parameters:
  # * list_name - the name of the list.  This determines the method names that
  #   are created
  # * list_items - a Proc for accessing the list items.  We cannot necessarily
  #   pass in the list items directly, because if this method is called at
  #   class initialization time, then in the test environment the database
  #   is still empty.
  def self.init_nonsearch_list(list_name, list_items, code_field, text_field)
    class_eval <<-ENDLIST
      @@#{list_name}_proc = list_items
      @@#{list_name}_list = nil
      @@#{list_name}_hash = nil
      @@#{list_name}_item_hash = nil
      def self.#{list_name}_list
        @@#{list_name}_list ||= @@#{list_name}_proc.call
      end
      def self.#{list_name}_for_code(code_val)
        if !@@#{list_name}_hash
          @@#{list_name}_hash = {}
          #{list_name}_list.each {|i| @@#{list_name}_hash[i.#{code_field}] = i.#{text_field}}
        end
        @@#{list_name}_hash[code_val]
      end
      def self.#{list_name}_item(code_val)
        if !@@#{list_name}_item_hash
          @@#{list_name}_item_hash = {}
          #{list_name}_list.each {|i| @@#{list_name}_item_hash[i.#{code_field}] = i}
        end
        @@#{list_name}_item_hash[code_val]
      end
ENDLIST
  end


  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # The following constants and methods are used to compute the size of data
  # being saved to the database.  Stored data sizes are maintained in the
  # users table, with access methods in the User class.  These are here to
  # provide access to each ActiveRecord class, since we want to track the
  # size of all user data saved.

  # size values for data types with no size explicitly specified
  NUM_AND_DATE_LENGTHS = {
    'date' => 3 ,
    'time' => 3 ,
    'datetime' => 8 ,
    'timestamp' => 4 ,
    'year' => 1 ,
    'int' => 4 ,
    'tinyint' => 1 ,
    'smallint' => 2 ,
    'mediumint' => 3 ,
    'bigint' => 8 ,
    'float' => 4 ,
    'real' => 8
    }

  # Hash used to maintain a list of each field/column in a database table
  # and the datatype of each of those fields.  The keys are the database
  # table names and the value for each key is another hash - this one
  # containing field/column names as keys and data types as values.
  @@field_types = {}

  # Populates the @@field_types hash with the fields and data types for the
  # specified table
  #
  # Parameters:
  # table_name - the name of the table to be added to the @@field_types hash
  #
  # Returns:
  # * the hash created for the specified table.
  #
  def self.set_field_types(table_name)
    table_fields = {}
    @@field_types[table_name] = table_fields
    table_fields['FIXED_LENGTH'] = 0
    col_names = self.column_names()
    cols_hash = self.columns_hash()
    col_names.each do |nm|
      ftype = cols_hash[nm].sql_type
      start_len_pos = ftype.index('(')
      stripped_ftype = start_len_pos ? ftype[0,start_len_pos] : ftype
      if NUM_AND_DATE_LENGTHS.include? stripped_ftype
          table_fields['FIXED_LENGTH'] += NUM_AND_DATE_LENGTHS[stripped_ftype]
      end
      table_fields[nm] = stripped_ftype
    end
    return table_fields
  end


  # Extracts the length specification from a field type spec, e.g. text(600)
  #
  # Parameters:
  # * ftype - the field type spec
  #
  # Returns:
  # * the length specifier
  def self.length_spec(ftype)
    ftype =~ /\(([\d]+)\)/
    return $1.to_i
  end


  # Gets the length of a field
  #
  # Parameters:
  # * field_value - the value in the field
  # * ftype - the field type specification, such as varchar(12)
  #
  # Returns:
  # * the amount of space the value will take up in the database
  #
  # Exceptions:
  # * raises an exception if the ftype parameter is nil
  # * raises an exception if the length cannot be determined (assumes faulty
  #   field type spec)
  #
  def self.get_field_length(field_value, ftype)
    if ftype.nil?
      raise 'ActiveRecordExtension.get_field_length called with nil field ' +
            'type.  field_value = ' + field_value.to_json
    end
    len = 0

    # Process field type specs with explicit lengths.  We don't process
    # fields with fixed lengths because they're already accounted for in
    # the 'FIXED_LENGTH' value.
    if !NUM_AND_DATE_LENGTHS.include? ftype
      if ftype == 'varchar' || ftype == 'text'
        len = 2
      end
      if !field_value.nil?
        len += field_value.to_s.length
      end
    end
    return len
  end # get_field_length


  # Gets the length of a row of data for the table
  #
  # Parameters:
  # * row_data - the hash containing the row data.  Keys are the
  #   field/column names, values are the values for that field/column
  #
  # Returns:
  # * the amount of space the row will take up in the database
  #
  def self.get_row_length(row_data)
    if @@field_types[self.table_name].nil?
      table_fields = set_field_types(self.table_name)
    else
      table_fields = @@field_types[self.table_name]
    end
    len = table_fields['FIXED_LENGTH']
    table_fields.each_key do |field_name|
#      logger.debug ''
#      logger.debug 'processing table_fields name ' + field_name.to_s
      if field_name != 'FIXED_LENGTH'
        if !row_data[field_name].nil?
          field_value = row_data[field_name]
        else
          field_value = nil
        end
        len += get_field_length(field_value, table_fields[field_name])
      end
    end
    return len
  end # get_row_length


  # Gets the length of an array of data rows for the table
  #
  # Parameters:
  # * inserts - the array containing the rows
  #   #
  # Returns:
  # * the total amount of space the rows will take up in the database
  #
  def self.get_mass_insert_length(inserts)
    start = Time.now
    total_length = 0
    inserts.each do |row|
      total_length += get_row_length(row)
    end
    logger.debug ''
    logger.debug 'get_mass_insert_length took ' + (Time.now - start).to_s +
                 ' seconds(?) to process ' + inserts.length.to_s +
                 ' inserts with a total_length of ' + total_length.to_s
    logger.debug ''
    return total_length
  end # get_mass_insert_length


  # Defines an alias for a column.
  #
  # Parameters:
  # * new_name - the new method that is being created as an alias for old_name
  # * old_name - the original method
  def self.alias_attribute(new_name, old_name)
    super
    # The Rails method (as of 2.3.8) does not define attribute_changed?, so
    # we add that.
    module_eval "def #{new_name}_changed?; self.#{old_name}_changed?; end"
  end

  # all the existing instance methods will be called when validating AR record
  validate :common_validations
  def common_validations
    if self.class.instance_methods.include?(:validate)
      validate
    end
  end


  # Validates a date and updates the _ET and _HL7 fields.  Currently this does
  # not change the max & min date parameters.  (TBD).
  #
  # Parameters:
  # * field - the name of the date field in the record being validated.
  #   This should contain the date as the user entered it.
  # * req - true if the field is required
  # * month_req - true if a month must be specified (in addition to a year)
  # * day_req - true if a day must be specified
  # * min_date - the minimum date (DateTime) that is acceptable.
  # * max_date - the maximum date (DateTime) that is acceptable.
  def validate_date(field, req, month_req, day_req, min_date=nil, max_date=nil)
    month_abbrevs = %w{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dev}
    needs_calc = false
    field_val = self.send(field)
    if field_val.blank?
      if req
        errors.add(field, 'is required')
      else
        # Blank out the fields
        self.send(field+'=', '')
        self.send(field+'_ET=', self.send(field+'_HL7=', ''))
      end
    elsif field_val =~ /\A(\d\d\d\d)\s+(#{month_abbrevs.join("\|")})\s+(\d\d?)\Z/i
      year, month, day = [$1, $2, $3]
      month = month.titlecase
      month_num = month_abbrevs.index(month) + 1
      needs_calc = true
    elsif field_val =~/\A(\d\d\d\d)(\/(\d\d?)(\/(\d\d?))?)?\Z/
      year, month_day, month_num, slash_day, day = [$1, $2, $3, $4, $5]
      if day_req && day.blank?
        errors.add(field, 'must be a full date')
      elsif month_req && month_num.blank?
        errors.add(field, 'must have a month as well as the year')
      else
        if month_num
          month_num = month_num.to_i
          month = month_abbrevs[month_num]
        end
        needs_calc = true
      end
    else
      errors.add(field, 'is not in the format YYYY/MM/DD')
    end

    if needs_calc
      year_num = year.to_i
      if !month_num
        month_num = 7 # July
        day_num = 1
      elsif day.blank?
        day_num = (month_num==2) ? 14 : 15  # Middle of month
      else
        day_num = day.to_i
      end

      begin
        date = DateTime.new(year_num, month_num, day_num)
      rescue ArgumentError=>e # ArgumentError for an invalid date
        errors.add(field, 'is an invalid date')
      end

      if errors[field].empty?
        if min_date && min_date > date
          errors.add(field, "cannot be before #{min_date.strftime('%Y/%m/%d')}")
        end
        if max_date && max_date < date
          errors.add(field, "cannot be after #{max_date.strftime('%Y/%m/%d')}")
        end
        if errors[field].empty?
          if day
            field_val = "#{year} #{month} #{day}"
          elsif month
            field_val = "#{year} #{month}"
          else
            field_val = year
          end
          self.send(field+'=', field_val)

          self.send(field+'_ET=', date.to_i)
          self.send(field+'_HL7=', date.strftime('%Y%m%d'))
        end
      end
    end
  end


  private

  # Used by find_record_data to search the table for a record matching the given
  # field data in input_fields.
  #
  # Parameters:
  # * input_fields - a hash from field names (column names) for this table
  #   to values.  Together the entries in input_fields should specify a
  #   particular record in the table.
  def self.find_record(input_fields)
    where(input_fields).take
  end

end

# The following line is a workaround for the bug introduced into rails 4.1 and will be removed in rails 4.2. Please
# see lib/rails_4_1_5_patches.rb for details. - Frank
require 'rails_4_1_5_patches'
module ActiveRecord::AttributeMethods::Serialization::ClassMethods
  # Replace YAML serialization with JSON, to avoid YAML's security issues
  # with unsanitized user data.
  def serialize_with_json(field)
    serialize_without_json(field, JsonProxy)
  end
  alias_method_chain :serialize, :json
end
