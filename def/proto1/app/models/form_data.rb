# A class handles data operations for a form.
#
# Usage examples:
#    fd = FormData.new('PHR')
#    fd.save_data_to_db(data_table, profile_id, user_obj)
#    fd.get_data(profile_id)
#    ....
#


class FormData

  require 'spreadsheet'
  require 'stringio'
  #require 'pdf/writer'

  #require 'pdf/simpletable'
  require 'dictionary'  # dictionary is an implementation of ordered hash
  # using array. it could be replaced by the regular Hash
  # in Ruby 1.9 since the Hash is ORDERED since version 1.9
  # The marker that indicates a record ID is marked for deletion.  This
  # appears in front of the actual ID.
  DELETED_MARKER = 'delete '
  # column name for primary keys
  PRIMARY_KEY_COL = '_id_'
  # extra two columns to included in each taffy db table to keep the foreign key
  # relationships between the user tables
  PARENT_TABLE_COL = '_p_table_'
  FOREIGN_KEY_COL = '_p_id_'

  # Controls whether list field values in saved records should be updated to the
  # current values corresponding to the saved list item codes.  We used to
  # do that, and have decided against it, in part due to performance concerns.
  #UPDATE_LIST_VALUES = true

  # form_name
  @form_name = nil
  # ActiveRecord instance of this form
  @form = nil
  # a hash map that represents actual tables/columns in database:
  #   {table => {column => [ data_type, [target_fields]]}}
  @table_definition = nil
  @group_definition = nil

  # a flag to indicate if data tables exist for this form
  @has_datatable = nil

  # a hash map that represents form fields to table columns mapping:
  #   {target_field => [table, column, data_type]}
  @field_2_column_mapping = nil
  # a hash map that represents table column to form field-to-table mapping:
  #   {table|column => [target_fields]}
  @column_2_field_mapping = nil
  # a hash map that contains a display_name, hidden_field? and display_order
  # for every target_field in the form:
  #   {target_field => [dispay_name, hidden_field?, display_order]}
  @field_name_mapping = nil

  # child to parent table relationships
  #   {child table_name => parent table_name }
  @c_p_mapping = nil
  # parent to child chain table
  #   {parent table_name => { parent table_name => { child table_name => nil }
  #                         }
  #                         ...
  #    ...
  #   }
  @p_c_chain = nil

  # virtual field information (for one particular form)
  @db_virtual_master_fields = nil

  # A hash from table names to an SQL "order by" string listing the columns
  # by which data retrieved from the table should be ordered.
  @table_to_sql_order = nil

  # a mapping of table name to group header's element id on the form
  @table_2_group_mapping = nil

  # A map from table names to the set of fields in the database table that
  # are saved.
  @@table_to_db_fields = {}

  # Fields in user data tables that are not needed to be shown on the forms.
  NON_FORM_DATA_COLS =  Set.new(['id', 'version_date', 'deleted_at',
    'latest', 'profile_id'])

  # current datetime for saving records
  # value is set when save_data_to_db is called
  @current_time = nil

  attr_reader :table_definition, :group_definition, :p_c_chain,
      :c_p_mapping, :db_virtual_master_fields, :table_2_group_mapping

  # seconds constants needed for date conversions
  SECS_PER_DAY = 86400.0
  SECS_PER_WEEK = SECS_PER_DAY * 7
  # 365.2425 from  http://en.wikipedia.org/wiki/Leap_year#Gregorian_calendar
  SECS_PER_YEAR = SECS_PER_DAY * 365.2425
  SECS_PER_MONTH = SECS_PER_YEAR/12

  DATA_LOADING_ERROR_MSG = 'There was an error loading some unsaved data for ' +
                'this form.<br>We have loaded what was in the database, but ' +
                'were unable to get the unsaved data, which is now ' +
                'lost.<br>We regret the problem and will be working to ' +
                'prevent it from happening again.'
  #
  # public methods
  #

  # Data migration method to get the values for virtual fields and insert/update
  # the newly created columns in user data tables that keep the virtual fields
  # values
  #
  # Decision is made to remove virtual fields. This method is needed to have an
  # initial values of those virtual fields in user data tables.
  # It should be used when master tables are updated.
  #
  # Parameters:
  # * user_id id of current user
  #
  def update_all_virtual_fields(user_id)
    AutosaveTmp.delete_all
    profiles = Profile.all
    user_obj = User.find(user_id)
    profiles.each do |profile|
      update_virtual_fields_for_one_profile(profile.id, user_obj)
    end
  end


  #
  # update virtual fields for one profile's data
  #
  # Parameters:
  # * profile_id - id of a profile
  # * user_obj - the current user object
  #
  def update_virtual_fields_for_one_profile(profile_id, user_obj)
    data_table = get_data_table_w_updated_virtual_fields(profile_id)
    save_data_to_db(data_table, profile_id, user_obj, true)
  end


  #
  # Export data to CSV
  #
  # Parameters:
  # * profile_id - id of a profile record
  # * include_hidden_fields - a flag indicates if hidden fields are included
  #   default is false
  #
  # Returns:
  # * report_string - A string contains multiple lines of csv content
  #
   def export_csv(profile_id, access_level, include_hidden_fields = false)
    # get profile data in data_table format
    data_table, not_used, not_used, err_msg, except = get_data_table(
                                                       profile_id, access_level)
    # convert the data table to an ordered data hash
    data_hash_in_order = convert_to_data_hash_in_order(data_table)

    # get the form title
    report_title = FormData.find_template_field_values(@form.form_title,
        data_table)
    # create CSV content
    report_string = CSV.generate do |csv|
      # add the title first
      csv << [report_title]
      # add an empty line after each section
      csv << ['']

      create_csv_data(csv, data_hash_in_order,
        include_hidden_fields)
    end
    return report_string
  end


  #
  # Export data to Excel Spreadsheet
  #
  # Parameters:
  # * profile_id - id of a profile record
  # * include_hidden_fields - a flag indicates if hidden fields are included.
  #   default value is false.
  #
  # Returns:
  # * report_string - A string contains Excel file content
  #
  def export_excel(profile_id,  include_hidden_fields = false)

    Spreadsheet.client_encoding = 'UTF-8'
    # define some formats for excel
    @table_hdr_format = Spreadsheet::Format.new :color => :black,
        :weight => :bold,
        :size => 12
    @column_hdr_format = Spreadsheet::Format.new :color => :black,
        :weight => :bold,
        :size => 10
    @content_format = Spreadsheet::Format.new :color => :black,
        :weight => :normal,
        :size => 10

    # get profile data in data_table format
    data_table, not_used, err_msg, except = get_data_table(profile_id)
    # conver the data table to an ordered data hash
    data_hash_in_order = convert_to_data_hash_in_order(data_table)

    # get the form title
    report_title = FormData.find_template_field_values(@form.form_title,
        data_table)

    # create Excel content
    #report = StringIO.new
    #workbook = Spreadsheet::Workbook.new(report)
    workbook = Spreadsheet::Workbook.new

    worksheet = workbook.create_worksheet :name=> report_title
    @worksheet_row_num = 0
    # add title
    worksheet.row(@worksheet_row_num).replace [report_title]
    worksheet.row(@worksheet_row_num).default_format = @table_hdr_format
    @worksheet_row_num +=1
    # add an empty row
    worksheet.row(@worksheet_row_num).replace ['']
    worksheet.row(@worksheet_row_num).default_format = @content_format
    @worksheet_row_num +=1

    create_excel_data(worksheet,data_hash_in_order, include_hidden_fields)
    # temp solution
    # write content to a temp file then read back the content
    # Create a temp zip file
    tfile = Tempfile.new("excel")
    workbook.write(tfile.path)
    report_string = File.read(tfile.path)
    # Close the temp file, which will be deleted sometime
    tfile.close
    return report_string
  end

  #
  # Export data to pdf document
  #
  # Parameters:
  # * form_record_id - id of a profile record
  # * include_hidden_fields - a flag indicates if hidden fields are included.
  #   default value is false.
  #
  # Returns:
  # * report_string - A string containing the PDF content
  #
  def export_pdf(form_record_id, include_hidden_fields = false)

    # get form record data in data_table format
    data_table, not_used, not_used, err_msg, except = get_data_table(form_record_id)
    # convert the data table to an ordered data hash
    data_hash_in_order = convert_to_data_hash_in_order(data_table)
    table_name = ""
    # get the form title
    report_title = FormData.find_template_field_values(@form.form_title,
        data_table)
    # create a new PDF page
    pdf = PDF::Writer.new
    #get the path of the current directory
    #dir = Dir.pwd
    #pdf.image dir +"/public/images/banner.jpg"
    pdf.image Rails.application.assets.find_asset("banner.jpg").pathname.to_s
    pdf.select_font "Times-Roman"
    #empty lines
    pdf.text " "
    pdf.text " "
    pdf.text " "
    create_pdf_data(pdf,data_hash_in_order, table_name, include_hidden_fields)
    #get the pdf contents as a string
    report_string = pdf.render();
    return report_string
  end


  #
  # Save data from form to tables
  #
  # Parameters:
  # * data_hash - a data_hash hash map that is used to load data into a form
  #   data_hash is created from form_params by data_hash_from_params()
  # * profile_id - id of a profile record
  # * user_obj - the currently logged in user object
  #
  # Returns:
  # * True/False
  #
  def save_data(data_hash, profile_id, user_obj)
    data_table = convert_to_data_table(data_hash)
    @feedback, data_table = save_data_to_db(data_table, profile_id, user_obj)
  end


  #
  # Saves data to the user data tables for both the main phr form and
  # the test panels.
  #
  # Parameters:
  # * data_table - a hash map that contains the data structure
  # * profile_id - id of a profile record
  # * user_obj - currently logged in user object
  # * mass_save - added by Frank, don't know what it's for
  #
  # Returns:
  # * @feedback - has information on which rows were added, updated & deleted
  # # data_table - the updated data table
  #
  def save_data_to_db(data_table, profile_id, user_obj, mass_save = true)

    # set the version time
    @current_time = Time.now

    # keep the track of records that are newly added or deleted
    @feedback = {'data' => {'added'=>[], 'deleted'=>[], 'updated'=>[], 'empty'=>[], 'to_remove'=>[] },
                            'errors' => [],
                            'exception' => nil }
    if mass_save
      @mass_save = true
      reset_mass_saving
    end

    # pre-process, keep one obx record if all the obx records have no test
    # values for an obr record
    orig_data_table = preprocess_data_table(data_table)

    DbTableDescription.transaction do
      ret_val = save_data_on_one_level(@p_c_chain, data_table, nil,
          profile_id, user_obj)

      if !@feedback['errors'].empty?
        # stop saving data and roll back transaction
        logger.error "server side required field validation failed. transaction rolled back."
        raise ActiveRecord::Rollback
        @feedback['data'] = {'added'=>[], 'deleted'=>[], 'updated'=>[], 'empty'=>[], 'to_remove'=>[] }
      else
        mass_saving(user_obj) if @mass_save

        # update profle's update timestamp if there's a change
        if !@feedback['data']['added'].empty? || !@feedback['data']['deleted'].empty? ||
            !@feedback['data']['updated'].empty?
          profile = Profile.find(profile_id)
          profile.last_updated_at = @current_time
          profile.save!
        end

        # reorder the records
        @feedback['data']['deleted'] = @feedback['data']['deleted'].sort_by {|x| [x[0],x[1]]}.reverse
        @feedback['data']['empty'] = @feedback['data']['empty'].sort_by {|x| [x[0],x[1]]}.reverse

        orig_data_table = update_data_table(orig_data_table, @feedback['data'])
      end
    end

    rescue => e
      @feedback['exception'] = e
    ensure
      return @feedback, orig_data_table
  end # save_data_to_db


 #
  # Updates the data table for rows added and deleted.  Specifically:
  # 1) for rows added, this adds the newly assigned record id to the row; and
  # 2) this removes deleted rows from the data table.
  #
  # Updated rows don't cause any changes here, because any changed data has
  # already been written to the data table (on the client side), as was all
  # added data except record ids.
  #
  # Parameters:
  # * data_table - the hash map that contains the data table
  # * updates - the array that contains the update information, in the following
  #   format:
  #   {"added":[[table_name,row_number,record_id],...],
  #    "deleted":[[table_name,row_number,record_id]...],
  #    "updated":[[table_name,row_number,record_id]...],
  #    "empty":[[table_name,row_number,record_id]...]}
  #
  # Returns:
  # * @feedback - has information on which rows were added, updated & deleted
  # * data_table - the updated data table
  #
  def update_data_table(data_table, updates)
    updates['added'].each do |table_adds|
      data_table[table_adds[0]][table_adds[1] - 1]['record_id'] = table_adds[2]
    end

    # remove the records in the data tables
    to_be_removed = (updates['deleted']+updates['empty'])
    # sort by table_name, then by position, then reverse the order to make the
    # big position numbers first
    to_be_removed = to_be_removed.sort_by {|x| [x[0],x[1]]}.reverse
    updates['to_remove'] = to_be_removed

    to_be_removed.each do |table_deletes|
      data_table[table_deletes[0]].delete_at(table_deletes[1] - 1)
    end
    return data_table
  end


  # Gets a data db tables for taffydb, to load an existing  record to a form.
  # Includes obtaining unsaved changes from the autosave  data UNLESS the
  # current user only has read access to the profile.
  #
  # Parameters:
  # * profile_id - id of a profile record
  # * access_level - level of access the current user has to the profile
  #
  # Returns:
  # * data_table - a hash map that contains data following actual table structure
  # * recovered_data - an array containing data to indicate which fields were
  #   recovered from unsaved data
  # * from_autosave - a flag indicating whether or not the data_table was
  #   obtained from the autosave_tmps table
  # * err_msg - an error message if we experienced problems getting unsaved data
  # * except - the exception that was thrown for the data acquistion problem
  def get_data_table(profile_id, access_level)

    recovered_data = nil
    err_msg = nil
    excep = nil
    begin
      if !profile_id.nil?
        profile = Profile.find(profile_id)
      end
      if !profile_id.nil? && @form.autosaves &&
         (access_level == ProfilesUser::NO_PROFILE_ACTIVE ||
          access_level < ProfilesUser::READ_ONLY_ACCESS) &&
         AutosaveTmp.have_change_data(profile, @form_name)
        if AutosaveTmp::TEST_PANEL_FORMS.include?(@form_name)
          # DON'T TAKE THESE OUT - just commented out until I need them
          #retrieval_type = 'autosave'
          #start_time = Time.now
          data_table, recovered_data = AutosaveTmp.merge_tp_changes(profile)
        else
          data_table, recovered_data =
                               AutosaveTmp.merge_changes(profile, @form_name)
        end
      else
        data_table = {}
      end

      # Set the from_autosave flag based on whether or not we have any recovered
      # data.  It's possible to have a change data hash that contains no actual
      # changes - just "removed" row flags.  In that case there's nothing for
      # the user to make a decision on, and we don't want the message coming up.
      from_autosave = !recovered_data.nil?

    rescue Exception => excep
      err_msg = DATA_LOADING_ERROR_MSG
      data_table = {}
      from_autosave = false
    ensure

      if data_table.empty?
        # DON'T TAKE THESE OUT - just commented out until I need them
        #retrieval_type = 'db'
        #start_time = Time.now
        # should check if tables exist in database
        data_table = {}
        if !profile_id.nil?
          # for debugging
          @data_changed = {}
          @table_definition.each do |table_name, column_definition|
            tableClass = table_name.singularize.camelcase.constantize
            # get the current record for each record_id
            table_records = tableClass.where(latest: true, profile_id: profile_id).order(@table_to_sql_order[table_name])
            record_data_array = []

            # if record found
            if !table_records.nil?
              table_records.each do |record|
                record_data_array << needed_data(table_name, record)
              end
              # add the record_data array into data_table
              if !record_data_array.empty?
                data_table[table_name] = record_data_array
              end
            end # end of !table_records.nil?
          end # end of @table_definition.each
        end # end of !profile_id.nil?
      end # if we don't have anything in data_table yet

    # DON'T TAKE THIS OUT - just commenting out until I need it
#    finish = Time.now
#    File.open('TimingStats', 'a') {|f|
#      f.write(Time.now.to_s + ' | FormData.get_data_table | ' +
#              'Load ' + retrieval_type + ' data to ' + @form_name +
#              ' form | ' + (finish - start_time).to_s + ' seconds' + "\n")
#    }
      return data_table, recovered_data, from_autosave, err_msg, excep
    end # rescue
  end # get_data_table


  # Returns the data tables in a hash map based on the profile. This method is
  # used for generating reminders on JavaScript server.
  #
  # Parameters:
  # * profile_id - ID of a profile record
  def get_data_table_by_profile(profile_id)
    data_table = {}
    if profile_id
      @table_definition.each do |table_name, column_definition|
        tableClass = table_name.classify.constantize
        # get the current record for each record_id
        table_records = tableClass.where(latest: true, profile_id: profile_id).order(@table_to_sql_order[table_name])
        table_records = table_records.map do |record|
          needed_data(table_name, record)
        end # end of !table_records.nil?
        data_table[table_name] = table_records
      end # end of @table_definition.each
    end # end of !profile_id.nil?
    table_name = "obx_observations"
    table_records = Rule.prefetched_obx_observations(profile_id).values
    data_table[table_name] = table_records
    data_table
  end


  #
  # Retrieve data from tables for a form
  #
  # Parameters:
  # * profile_id - id of a profile record
  #
  # Returns:
  # * data_table - a hash map that contains data following actual table structure
  #
  def get_data_table_w_updated_virtual_fields(profile_id)

    if !profile_id.nil?
      data_table = {}
      if !profile_id.nil?
        # for debugging
        @data_changed = {}
        @table_definition.each do |table_name, column_definition|
          tableClass = table_name.singularize.camelcase.constantize
          # get the current record for each record_id
          table_records = tableClass.where(latest: true, profile_id: profile_id).order(@table_to_sql_order[table_name])
          record_data_array = []
          # if record found
          if !table_records.nil?
            table_records.each do |record|
              record_data = needed_data(table_name, record)
              # within one record
              # for each column, check if it's a virtual field or if it needs to
              # get data from master tables, instead of user table
              record_data.each do |column_name, value|
                # if is_virtual_or_master_field?(table_name, column_name)
                if has_controlled_virtual_field?(table_name, column_name)
                  virtual_master_field_info =
                              @db_virtual_master_fields[table_name][column_name]
                  # start with root controlling fields, set the value for the
                  # field
                  if is_root_controlling_field?(table_name, column_name)

                    # get the code value
                    code_column = column_name + '_C'
                    if is_column_valid?(table_name, code_column)
                      code_value = record_data[code_column]
                    else
                      code_value = record_data[column_name]
                    end
                    # use saved value if code_value is nil or empty
                    # otherwise get the value from master table
                    if !code_value.blank?
                      db_field = virtual_master_field_info[12]

                      # ActiveRecord object's methods are lost if it retrieved
                      # from the global cache $form_data_cache
                      if db_field.nil? || !db_field.respond_to?(
                                             'get_field_current_item_and_value')
                        field_id = virtual_master_field_info[13]
                        db_field = DbFieldDescription.find(field_id)
                        virtual_master_field_info[12] = db_field
                      end
                      record_instance, field_value =
                           db_field.get_field_current_item_and_value(value,
                                                                     code_value,
                                                                     nil)

                      # set the value
                      record_data[column_name] = field_value

                      # for debug
                      @data_changed[table_name + " | " + column_name] =
                                                                     field_value

                      controlled_fields = get_controlled_fields(table_name,
                                                                column_name)
                      # If no other fields depending on this field, usually this
                      # is a name-code pair's name column, get the value of this
                      # field.
                      # If there are fields controlled by this field, get the
                      # record object of this field and recursively process
                      # controlled fields.
                      if !controlled_fields.empty?
                        # get the record instance of the controlling field
                        controlled_fields.each do |controlled_field|
                          get_current_item_and_value(table_name,
                            controlled_field, record_instance, record_data)
                        end
                      end
                    end # end of code_value.blank?
                  end # end of is_root_controlling_field?
                end # end of is_virtual_or_master_field?
              end # end of column loop
              # add it into data array
              record_data_array << record_data
            end
            # add the record_data array into data_table
            if !record_data_array.empty?
              data_table[table_name] = record_data_array
            end
          end # end of !table_records.nil?
        end # end of @table_definition.each
      end # end of !profile_id.nil?
    end # if we do/don't need to do a recovery
    return data_table
  end # get_data_table_w_updated_virtual_fields


  # For TaffyDB implementation on client side
  #
  # Gets a data db and 2 mapping tables for taffydb, to load an existing
  # record to a form.  Includes obtaining unsaved changes from the autosave
  # data UNLESS the current user only has read access to the profile.
  #
  # Parameters:
  # * profile_id - id of a profile record
  # * access_level - level of access the current user has to the profile
  #
  # Returns:
  # * [data_table, taffy_mapping, taffy_model, table_2_grp_recnum]:
  # - +data_table+ - data hash that in the same format of the tables in
  #   database used for the creation of a taffydb.
  # - +taffy_mapping+ - a mapping table between fields on a form and records
  #   in a taffydb, for lookups from form fields to taffydb
  #   records and from taffydb record to form fields.
  # - +taffy_model+ - a database model record for inserting new empty records
  #   in taffydb when a new row is created in a form table.
  # - +table_2_grp_recnum+ -
  # * recovered_data arrays containing two hashes indicating unsaved changes:
  # - +added_rows+ - a hash with the row numbers of any rows added, by table
  # - +recovered_fields+ - a hash with the names and row numbers of any changed
  #   fields, by table
  # * from_autosave - a flag indicating whether or not the data_table was
  #   obtained from the autosave_tmps table
  # * err_msg - an error message, if any
  # * except - an exception thrown, if any
  #
  def get_taffy_db_data(profile_id, access_level)

    # Get data_table IF we've specified a profile_id.  If not we're just
    # getting the form structure.  This is for forms such as the phr home
    # form, where the data is actually loaded by calls from the client side.
    data_table = {}
    from_autosave = false
    if !profile_id.nil?
      data_table, recovered_data, from_autosave, err_msg, except =
                                        get_data_table(profile_id, access_level)
    end
    if !@has_data_table && data_table.empty?
      taffy_mapping = {}
      taffy_model = {}
      table_2_grp_recnum = Array.new
    else
      # calculate the table name to group header id and record num mapping
      # in the format of [{table_name=>[group_header_id, rec_num]}]
      table_2_grp_recnum = Array.new
      @table_2_group_mapping.each do |mapping|
        # mapping is in the format of [table_name, [group_header_id, g_h_id2,..]]
        table_name = mapping[0]
        group_header_ids = mapping[1]
        if !profile_id.nil? && !data_table[table_name].nil?
          record_length = data_table[table_name].length
          if from_autosave
            record_length -= 1
          end
        else
          record_length = 0
        end
        group_id_recnum = Array.new
        group_header_ids.each do |grp_hdr_id|
          group_id_recnum << [grp_hdr_id, record_length]
        end
        table_2_grp_recnum << [table_name, group_id_recnum]
      end

      # Don't add empty rows to the horizontal tables if the data came from
      # the autosave_tmps table (whether or not we ended up with any recovered
      # data to display).
      if !from_autosave && (access_level == ProfilesUser::NO_PROFILE_ACTIVE ||
         access_level < ProfilesUser::READ_ONLY_ACCESS)
        # existing record
        if !profile_id.nil?
          # add an empty row in each sub tables
          @table_definition.each do |table, column_defs|

            empty_record = {}
            column_defs.each do | column, defs|
              empty_record[column] = ""
            end
            data_array = data_table[table]
            # no data stored, add a empty record for the table
            if data_array.nil?
              data_table[table]=[empty_record]
            # has data, add an empty record after other records
            # only if its a repeating line table
            else
              db_table_record = DbTableDescription.find_by_data_table(table)
              data_array << empty_record if db_table_record.has_record_id
            end
          end
          # new record
        else
          data_table = {}
          @table_definition.each do |key, value|
            row = {}
            value.keys.each do |col_name|
              row[col_name] = ""
            end
            data_table[key]=[row]
          end
        end
      end # if the data is not from autosave_tmp

      # calculate the mapping table and model table based on data_hash
      data_hash = convert_to_data_hash(data_table)
      taffy_mapping ={}  # form element --> taffy db record
      suffix = ""
      taffy_mapping = parse_data_hash_for_id_2_db_mapping(data_hash,
                                                          suffix,
                                                          taffy_mapping)
      taffy_model = {}   # model row for inserting a new taffy record

      @table_definition.each do |key, value|
        model_row = {}
        value.keys.each do |col_name|
          model_row[col_name] = @column_2_field_mapping[key + '|' + col_name]
        end
        taffy_model[key]=model_row
      end
    end # if we won't, might have data
    return [data_table, taffy_mapping, taffy_model, table_2_grp_recnum],
           recovered_data, from_autosave, err_msg, except
  end # get_taffy_db_data


  #
  # private methods
  #
  private

  #
  # set value for controlled field
  # called by get_data_table
  #
  # Parameters:
  # * table_name - a user's data tabel name
  # * controlled_field - a name of a field in db_field_description that is
  #                      controlled by another field
  # * controlling_field_instance - a db_field_description record instance of
  #                                the controlling field
  # * record_data - the record data of the table_name to be modifed for the
  #                 virtual fields and master table fields
  #
  def get_current_item_and_value(table_name, controlled_field,
      controlling_field_instance, record_data)

    # get the master table value for the controlled_field
    # set the value for the controlled_field
    if is_virtual_or_master_field?(table_name, controlled_field)
      virtual_master_field_info = @db_virtual_master_fields[table_name][controlled_field]

      # get the code value
      code_column = controlled_field + '_C'
      if is_column_valid?(table_name, code_column)
        code_value = record_data[code_column]
      else
        code_value = record_data[controlled_field]
      end
      # saved value
      saved_value = record_data[controlled_field]

      db_field = virtual_master_field_info[12]
      # ActiveRecord object's methods are lost if it retrieved from the
      # global cache $form_data_cache
      if db_field.nil? || !db_field.respond_to?('get_field_current_item_and_value')
        field_id = virtual_master_field_info[13]
        db_field = DbFieldDescription.find(field_id)
        virtual_master_field_info[12] = db_field
      end

      record_instance, field_value = db_field.get_field_current_item_and_value(
          saved_value, code_value, controlling_field_instance)
      # set the value
      record_data[controlled_field] = field_value
      # for debug
      @data_changed[table_name + " | " + controlled_field] = field_value


      next_controlled_fields = get_controlled_fields(table_name, controlled_field)

      # check the next level
      # if controlled_field controls other field, get a record object of this
      # controlled_field, and process the next level recursively
      if !next_controlled_fields.empty?
        next_controlled_fields.each do |next_controlled_field|
          get_current_item_and_value(table_name,
              next_controlled_field, record_instance, record_data)
        end
      end
    end
  end


  #
  # Save data to tables on the one level in the parent-child chain
  #
  # Parameters:
  # * p_c_chain - parent-child relationship chain of tables
  # * data_table - a hash map that contains data following obr/obx table
  #   structure
  # * id_mapping - a hash mapping that contains mapping from index(sequence num)
  #   to database record key id
  # * profile_id - id of a profile record
  # * user_obj - the currently logged in user object
  #
  # Returns:
  # * True/False
  #
  def save_data_on_one_level(p_c_chain, data_table, id_mapping,
      profile_id, user_obj)

    p_c_chain.each do |table_name, c_table_chain|
      # save the data of p_table in data_table
      # process each table's data
      records = data_table[table_name]
      if !records.nil?
        next_id_mapping = Hash.new
        p_rec_id = nil
        record_position = 0
        records.each do |record|
          record_position += 1
          save_sub = false
          parent_table = true
          # this is a sub table
          if !id_mapping.nil?
            parent_table = false
            p_rec_index = record[FOREIGN_KEY_COL]
            p_rec_id = id_mapping[p_rec_index] unless p_rec_index.nil?
            if !p_rec_id.nil?
              save_sub = true
            end
          end

          db_key_id = nil
          # if this is a table without 'record_id' column, such as 'phrs' table
          # use 'profile_id' for historical data keeping
          db_table_record = DbTableDescription.find_by_data_table(table_name)
          # if sub table and its parent record has saved
          # or it is a parent table
          if parent_table || save_sub
            if !db_table_record.has_record_id
              db_key_id = save_one_record_without_record_id(record, table_name,
                  profile_id, user_obj, p_rec_id,
                  db_table_record.parent_table_foreign_key, record_position)
            else
              # normal tables
              db_key_id = save_one_record_with_record_id(record, table_name,
                  profile_id, user_obj, p_rec_id,
                  db_table_record.parent_table_foreign_key, record_position)
            end
          end
          # create a id_mapping between index (sequence num) and database key id
          next_id_mapping[record[PRIMARY_KEY_COL]] = db_key_id
        end

        # recursively process c_tables
        if !c_table_chain.nil?
          save_data_on_one_level(c_table_chain, data_table, next_id_mapping,
            profile_id, user_obj)
        end
      end # end if !records.nil?
    end
  end # save_data_on_one_level


  #
  # trim user input data
  #
  # Parameters:
  # * data_table - user's data table
  #
  # Returns:
  # * in data_table object
  #
  def trim_data(data_table)
    data_table.each do | table_name, record_data|
      record_data.each do |record|
        record.each do |column_name, value|
          if !value.blank? && value.class == String
            record[column_name]= value.strip
          end
        end
      end
    end
  end


  #
  # pre-process user data
  #
  # Parameters:
  # * data_table - user's data table
  #
  # Returns:
  # * in data_table object
  #
  def preprocess_data_table(data_table)
    # trim the string value
    trim_data(data_table)
    # record empty rows in the data table, except the last one
    # note obr/obx records are never empty (loinc_num has value)
    record_empty_rows(data_table)

    return data_table
  end


  #
  # record empty rows in the data table, except the last one
  # note obr/obx records are never empty (loinc_num has value)
  #
  # Parameters:
  # * data_table - user's data table
  #
  # Returns:
  # * in @feedback['empty']
  #
  def record_empty_rows(data_table)
    data_table.each do | table_name, record_data|

      index = 0
      length = record_data.length
      record_data.each do |record|
        index += 1
        # if the record is not the last one in the table
        if index != length
          empty = true
          record.each do |column_name, value|
            if !value.blank?
              empty = false
              break
            end
          end
          # if the record is empty
          if empty && index != length
            @feedback['data']['empty'] << [table_name, index, nil]
          end
        end

      end
    end

  end


  # Returns the needed data for this form for the given data table and record.
  #
  # Parameters:
  # * table_name - a database table name
  # * record - an model class instance for table_name
  #
  # Returns:
  # * an array of the column names that are needed for the form.
  def needed_data(table_name, record)
    # remove NON_FORM_DATA_COLS columns: "id", "version_date", "deleted_at",
    # "latest" and "profile_id".
    # Some attribute names might be overridden, so we call each one.
    rtn = {}
    @db_cols_needed_for_form = {} if !@db_cols_needed_for_form
    needed_cols = @db_cols_needed_for_form[table_name]
    if !needed_cols
      needed_cols = @table_definition[table_name].keys
      @db_cols_needed_for_form[table_name] = needed_cols
    end

    needed_cols.each do |name|
      if !NON_FORM_DATA_COLS.member?(name)
        rtn[name] = record.send(name)
      end
    end

    return rtn
  end


  #
  # Save one data record to a table that has "record_id" column
  # "record_id" is a record identifier that is used to keep all the historical
  # data of the same record. The latest data has the "latest" set to true.
  #
  # Parameters:
  # * record - a hash map that contains data record
  # * table_name - a database table name
  # * profile_id - id of a profile record
  # * user_obj - the currently logged in user object
  # * p_rec_id - a parent record id to be stored in the foreign key column
  # * parent_table_foreign_key - the name of the foreign key column
  # * position_in_taffydb - a position index in taffydb
  #
  # Returns:
  # * db_key_id - the saved record's id
  #
  def save_one_record_with_record_id(record, table_name, profile_id, user_obj,
      p_rec_id, parent_table_foreign_key, position_in_taffydb)
    record_data = {}
    record_id =nil
    db_key_id = nil
    table_class = table_name.singularize.camelcase.constantize
    record_id_name = 'record_id'
    # determine if the record is to be deleted
    record_id_value = record[record_id_name]
    matched = nil
    if !record_id_value.nil?
      matched = record_id_value.to_s.match(/\Adelete (.*)/)
    end
    # to delete this record
    if !matched.nil?
      record_id = matched[1].to_i
      # get this record
      if !p_rec_id.nil?
        last_record = table_class.where(["profile_id = ? and record_id = ? " +
                " and #{parent_table_foreign_key} = ? and latest = true",
            profile_id, record_id, p_rec_id]).take
      else
        last_record = table_class.where(["profile_id = ? and record_id = ? and latest = true",
            profile_id, record_id]).take
      end
      # set the flag 'latest' to false on the this record
      # this means this record will not be displayed on form any more
      if !last_record.nil?
        db_key_id = last_record.id
        delete_record(last_record)
        @feedback['data']['deleted'] << [table_name, position_in_taffydb,
            record_id]
      end

    # to update the record
    else
      # process each record field
      db_fields = @@table_to_db_fields[table_name]
      if !db_fields
        db_fields = Set.new(table_class.column_names)
        @@table_to_db_fields[table_name] = db_fields
      end
      record.each do |column_name, value|
        # check if the column name is valid (defined in database)
        # and it is not a virtual column
        if is_column_valid?(table_name, column_name) &&
              !is_column_virtual?(table_name, column_name) &&
              db_fields.member?(column_name)
          # if this is the record_id
          if column_name.upcase == record_id_name.upcase
            record_id = value
          end
          data_type = get_column_data_type(column_name,table_name)
          value = xss_sanitize(value, data_type)
          record_data[column_name] = change_data_type(value, data_type)
        end
      end
      # add additional column data to the new record
      record_data["profile_id"] = profile_id
      record_data["latest"] = true
      record_data["record_id"] = record_id  # for new record record_id is nil
      record_data["version_date"] = @current_time

      # add an foreign key value pointing to a parent record
      if !p_rec_id.nil?
        record_data[parent_table_foreign_key] = p_rec_id
      end

      # if this is a new record
      if record_id.blank?
        record_id = table_class.next_record_id(profile_id, p_rec_id,
          parent_table_foreign_key)
        # update the column data for 'record_id'
        record_data["record_id"] = record_id
        # create a new record, only if it is not empty and the required fields
        # have values
        if !is_data_empty?(table_class, record_data, parent_table_foreign_key) &&
              has_required_data?(table_name, record_data)
          db_record = create_record(table_name, record_data, user_obj)
          # record_id maybe changed by create_record method if @mass_save is true
          record_id = db_record && db_record.send(record_id_name)
          db_key_id = db_record && db_record.id
          @feedback['data']['added'] << [table_name, position_in_taffydb,
              record_id]
        end
      # if this is an update of the last record data
      else
        # get the last record
        if !p_rec_id.nil?
          last_record = table_class.where(["profile_id = ? and record_id = ? and " +
            "#{parent_table_foreign_key} = ? and latest = true", profile_id, record_id, p_rec_id]).take
        else
          last_record = table_class.where(["profile_id = ? and record_id = ? and latest = true", profile_id,
              record_id]).take
        end
        if !last_record.nil?
          db_key_id = last_record.id
          last_record_data = last_record.attributes
          last_record_data.delete('id')
          # copy the last value over if the column does not show up at all in
          # the new data
          record_data = carry_over_last_values_if_not_present(table_name,
            last_record_data, record_data)
          # save the record only if the record data is updated
          # and the required fields have values
          if !is_data_same?(table_name, last_record_data, record_data)
            # mark it deleted if all fields are empty
            if (is_data_empty?(table_class, record_data, parent_table_foreign_key))
              update_record(last_record, record_data, user_obj)
              delete_record(last_record)
              @feedback['data']['deleted'] << [table_name, position_in_taffydb,
                  record_id]
            # update record if the required field is not empty
            # client side validation should ensure the required field is not
            # empty if there's at least one more fields is not empty
            elsif has_required_data?(table_name, record_data)
              update_record(last_record, record_data, user_obj)
              @feedback['data']['updated'] << [table_name, position_in_taffydb,
                  record_id]
            end
          end
        end
      end
    end # end of update record

    return db_key_id
  end # save_one_record_with_record_id


  #
  # Save one data record to a table that has no "record_id" column
  # "profile_id" is used instead of "record_id" as a record identifier to keep
  # all the historical data of the same record. The latest data has the
  # "latest" set to true.
  #
  # Parameters:
  # * record - a hash map that contains data record
  # * table_name - a database table name
  # * profile_id - id of a profile record
  # * user_obj - the currently logged in user object
  # * p_rec_id - a parent record id to be stored in the foreign key column
  # * parent_table_foreign_key - the name of the foreign key column
  # * position_in_taffydb - a position index in taffydb
  #
  # Returns:
  # * db_key_id - the saved record's id
  #
  def save_one_record_without_record_id(record, table_name, profile_id,
      user_obj, p_rec_id, parent_table_foreign_key, position_in_taffydb)
    record_data = {}
    db_key_id = nil
    table_class = table_name.singularize.camelcase.constantize

    record_id_name = 'profile_id'
    # determine if the record is to be deleted
    record_id_value = record[record_id_name]
    matched = nil
    if !record_id_value.nil?
      matched = record_id_value.match(/\Adelete (.*)/)
    end
    # to delete this record
    if !matched.nil?
      # get this record
      if !p_rec_id.nil?
        last_record = table_class.where(["profile_id = ? and #{parent_table_foreign_key} = ? and latest = true",
            profile_id, p_rec_id]).take
      else
        last_record = table_class.where(["profile_id = ? and latest = true", profile_id]).take
      end
      # set the flag 'latest' to false on the this record
      # this means this record will not be displayed on form any more
      if !last_record.nil?
        db_key_id = last_record.id
        delete_record(last_record)
        @feedback['data']['deleted'] << [table_name, position_in_taffydb, nil]
      end

    # to update the record
    else
      #process each record
      record.each do |column_name, value|
        # check if the column name is valid (defined in database)
        # and it is not a virtual column
        if is_column_valid?(table_name, column_name) &&
              !is_column_virtual?(table_name, column_name)
          data_type = get_column_data_type(column_name,table_name)
          value = xss_sanitize(value, data_type)
          record_data[column_name] = change_data_type(value, data_type)
        end
      end

      # add additional column data to the new record
      record_data["profile_id"] = profile_id
      record_data["latest"] = true
      record_data['version_date'] = @current_time

      # add an foreign key value pointing to a parent record
      if !p_rec_id.nil?
        record_data[parent_table_foreign_key] = p_rec_id
        table_record = table_class.where("profile_id = ? and #{parent_table_foreign_key} = ? and latest = true",
                                         profile_id, p_rec_id).take
      else
        table_record = table_class.where("profile_id = ? and latest = true", profile_id).take
      end

      # if this is a new record
      if table_record.nil?
        # # create a new record,
        # if data is not empty and if the required fields have values
        if !is_data_empty?(table_class, record_data, parent_table_foreign_key) &&
              has_required_data?(table_name, record_data)
          db_record = create_record(table_name, record_data, user_obj)
          db_key_id = db_record && db_record.id
          @feedback['data']['added'] <<[table_name, position_in_taffydb, nil]
        end
      # if this is an update of an existing record
      else
        existing_record_data = table_record.attributes
        existing_record_data.delete('id')
        db_key_id = table_record.id
        # copy the last value over if the column does not show up at all in
        # the new data
        record_data = carry_over_last_values_if_not_present(table_name,
          existing_record_data, record_data)

        # save the record only if the record data is updated
        # and if the required fields have values
        if !is_data_same?(table_name, existing_record_data, record_data)
          # mark it deleted if all fields are empty
          if (is_data_empty?(table_class, record_data, parent_table_foreign_key))
            update_record(table_record, record_data, user_obj)
            delete_record(table_record)
            @feedback['data']['deleted'] << [table_name, position_in_taffydb,
                record_id]
          # update record if the required field is not empty
          # client side validation should ensure the required field is not
          # empty if there's at least one more fields is not empty
          elsif has_required_data?(table_name, record_data)
            update_record(table_record, record_data, user_obj)
            @feedback['data']['updated'] << [table_name, position_in_taffydb, nil]
          end
        end
      end
    end # end of update record

    return db_key_id
  end # save_one_record_without_record_id


  #
  # get column display names from a data_hash for a table
  # called by export_csv/export_excel functions
  #
  # Parameters:
  # * data_hash - a dictionary/hash that contains form data for a table record
  # * include_hidden_fields - a flag indicates if hidden fields are included
  #
  # Returns:
  # * column_headers - an array contains column header names
  #
  def get_column_hdrs(data_hash, include_hidden_fields = false)
    column_headers = []
    # get column header
    data_hash.each do |key, value|
      if (include_hidden_fields == false &&
              @field_name_mapping[key][1] == false ||
              include_hidden_fields == true)
        column_headers << @field_name_mapping[key][0]
      end
    end
    return column_headers
  end


  #
  # get record values from a data_hash for a table
  # called by export_csv/export_excel functions
  #
  # Parameters:
  # * data_hash - a dictionary/hash that contains form data for a table record
  # * include_hidden_fields - a flag indicates if hidden fields are included
  #
  # Returns:
  # * column_values - an array contains record values
  #
  def get_column_values(data_hash, include_hidden_fields = false)
    column_values = []
    # get column header
    data_hash.each do |key, value|
      if (include_hidden_fields == false &&
              @field_name_mapping[key][1] == false ||
              include_hidden_fields == true)
        column_values << value.to_s
      end
    end
    return column_values
  end


  #
  # create csv content with user's data
  #
  # Parameters:
  # * csv - a csv object
  # * data_hash_in_order - an ordered data_hash structure implemented as a
  #   Dictionary
  # * include_hidden_fields - a flag indicates if hidden fields are included
  #   default is false
  #
  # Returns: none
  #
  def create_csv_data(csv, data_hash_in_order,
      include_hidden_fields = false)
    data_hash_in_order.each  do |key, value|
      case value
      # Array means multiple records possible
      when Array
        # add group name
        group_name = @field_name_mapping[key][0]
        csv << [group_name]
        flatten_value = flatten_hash(value[0])
        # add column header before first record
        column_headers = get_column_hdrs(flatten_value,include_hidden_fields)
        csv << column_headers
        value.each do | rec|
          flatten_rec = flatten_hash(rec)
          column_values = get_column_values(flatten_rec,include_hidden_fields)
          csv << column_values
        end
        # add an empty line after each section
        csv << ['']
      # Hash, continue to parse
      when Dictionary
        # add group name
        group_name = @field_name_mapping[key][0]
        if group_name
          csv << [group_name]
          flatten_value = flatten_hash(value)
          column_headers = get_column_hdrs(flatten_value, include_hidden_fields)
          csv << column_headers
          column_values = get_column_values(flatten_value, include_hidden_fields)
          csv << column_values
          # add an empty line after each section
          csv << ['']
        end
      # Leaf node, not available on PHR form
      else
      end
    end
  end


  #
  # create excel content with user's data
  #
  # Parameters:
  # * excel - an excel worksheet object
  # * data_hash_in_order - an ordered data_hash structure implemented as a
  #   Dictionary
  # * include_hidden_fields - a flag indicates if hidden fields are included
  #   default is false
  #
  # Returns: none
  #
  def create_excel_data(worksheet, data_hash_in_order,
      include_hidden_fields = false)

    data_hash_in_order.each  do |key, value|
      case value
        # Array means multiple records possible
      when Array
        # add group name
        group_name = @field_name_mapping[key][0]
        worksheet.row(@worksheet_row_num).replace [group_name]
        worksheet.row(@worksheet_row_num).default_format = @table_hdr_format
        @worksheet_row_num +=1

        # add column header before first record
        flatten_value = flatten_hash(value[0])
        column_headers = get_column_hdrs(flatten_value,include_hidden_fields)
        worksheet.row(@worksheet_row_num).replace column_headers
        worksheet.row(@worksheet_row_num).default_format = @column_hdr_format
        @worksheet_row_num +=1

        value.each do | rec|
          flatten_rec = flatten_hash(rec)
          column_values = get_column_values(flatten_rec,include_hidden_fields)
          worksheet.row(@worksheet_row_num).replace column_values
          worksheet.row(@worksheet_row_num).default_format = @content_format
          @worksheet_row_num +=1
        end
        # add an empty line after each section
        worksheet.row(@worksheet_row_num).replace ['']
        worksheet.row(@worksheet_row_num).default_format = @content_format
        @worksheet_row_num +=1

        # Hash, continue to parse
      when Dictionary
        # add group name
        group_name = @field_name_mapping[key][0]
        worksheet.row(@worksheet_row_num).replace [group_name]
        worksheet.row(@worksheet_row_num).default_format = @table_hdr_format
        @worksheet_row_num +=1
        flatten_value = flatten_hash(value)
        column_headers = get_column_hdrs(flatten_value,
          include_hidden_fields)
        worksheet.row(@worksheet_row_num).replace column_headers
        worksheet.row(@worksheet_row_num).default_format = @column_hdr_format
        @worksheet_row_num +=1
        column_values = get_column_values(flatten_value,
          include_hidden_fields)
        worksheet.row(@worksheet_row_num).replace column_values
        worksheet.row(@worksheet_row_num).default_format = @content_format
        @worksheet_row_num +=1
        # add an empty line after each section
        worksheet.row(@worksheet_row_num).replace ['']
        worksheet.row(@worksheet_row_num).default_format = @content_format
        @worksheet_row_num +=1
        # Leaf node, not available on PHR form
      else
      end
    end
  end

  #
  # create PDF content with user's data
  #
  # Parameters
  #  pdf - a PDF writer object
  # * data_hash_in_order - an ordered data_hash structure implemented as a
  #   Dictionary
  # * table_name - a variale to hold the name of a non repeating table
  # * include_hidden_fields - a flag indicates if hidden fields are included
  #   default is false
  #
  # Returns: none
  #
  def create_pdf_data(pdf, data_hash_in_order,table_name,
      include_hidden_fields = false)
    non_repeatingline_table = false

    data_hash_in_order.each  do |key, value|
      case value
        # Array means multiple records possible
      when Array
        # add group name
        pdf_table = PDF::SimpleTable.new
        group_name = @field_name_mapping[key][0]
        pdf_table.title= group_name
        # add column header before first record
        column_headers = get_column_hdrs(value[0],include_hidden_fields)
        #determine the order of the columns in the table
        for posn in 0...column_headers.length
          pdf_table.column_order.push(column_headers[posn])
        end
        #set the column headings
        for posn in 0...column_headers.length
          pdf_table.columns[column_headers[posn]]=
              PDF::SimpleTable::Column.new(column_headers[posn])
          pdf_table.columns[column_headers[posn]].heading = column_headers[posn]
        end
        my_arr = Array.new
        value.each do | rec|
          h = Hash.new
          column_values = get_column_values(rec,include_hidden_fields)
          for posn in 0...column_values.length
            key = column_headers[posn]
            h[key]=column_values[posn]
          end
          my_arr << h
        end
        # position the table
        pdf_table.show_lines    = :all
        pdf_table.show_headings = true
        pdf_table.orientation   = :right
        pdf_table.position      = :left
        #add data to the table
        pdf_table.data.replace my_arr
        #render the table
        pdf_table.render_on(pdf)
        # add an empty line after each section
        pdf.text " "

        # Hash, continue to parse
      when Dictionary
        # add group name
        group_name = @field_name_mapping[key][0]
        if group_name != nil
          table_name = group_name
        end
        create_pdf_data(pdf, value, table_name, include_hidden_fields)
        # Leaf node, non-repeatingline table
      else
        non_repeatingline_table = true
        break
      end
    end
    if non_repeatingline_table
      #create new table
      pdf_table = PDF::SimpleTable.new
      #title of the table
      pdf_table.title= table_name

      column_headers = get_column_hdrs(data_hash_in_order,
        include_hidden_fields)
      #detrmine the order of the table columns
      for posn in 0...column_headers.length
        pdf_table.column_order.push(column_headers[posn])
      end
      for posn in 0...column_headers.length
        pdf_table.columns[column_headers[posn]]=
            PDF::SimpleTable::Column.new(column_headers[posn])
        pdf_table.columns[column_headers[posn]].heading = column_headers[posn]
      end
      #store the data in a array of hashes
      my_arr = Array.new
      column_values = get_column_values(data_hash_in_order,
        include_hidden_fields)
      h = Hash.new
      for posn in 0...column_values.length
        key = column_headers[posn]
        h[key]=column_values[posn]
      end
      my_arr << h
      #position the table
      pdf_table.show_lines    = :all
      pdf_table.show_headings = true
      pdf_table.orientation   = :right
      pdf_table.position      = :left
      pdf_table.data.replace my_arr
      #display table
      pdf_table.render_on(pdf)
      pdf.text " "
    end
  end


  # Retrieve the table definitions, form group definitions and, others
  #
  # Parameters:
  # * form - a Form record, or a form's name.
  #
  # Returns: none
  #
  def initialize(form)

    # initialize the gobal cache for FormData information
    $form_data_cache = {} if $form_data_cache.nil?

    if form.class == String
      @form = Form.find_by_form_name(form)
      if (!@form)
        raise  "Form #{@form_name} does not exist!!"
        return false
      end
      @form_name = form
    else
      @form = form
      @form_name = form.form_name
    end

    # check if the form/table information is available in the global cache
    if !$form_data_cache[@form_name].nil? &&
       !$form_data_cache[@form_name].empty? &&
       Rails.env =='production'

      cached_data = $form_data_cache[@form_name]

      @field_2_column_mapping = cached_data['field_2_column_mapping']
      @column_2_field_mapping = cached_data['column_2_field_mapping']
      @table_definition = cached_data['table_definition']
      @table_to_sql_order = cached_data['table_to_sql_order']
      @db_virtual_master_fields = cached_data['db_virtual_master_fields']
      @has_data_table = cached_data['has_data_table']
      @group_definition = cached_data['group_definition']
      @field_name_mapping = cached_data['field_name_mapping']
      @c_p_mapping = cached_data['c_p_mapping']
      @p_c_chain = cached_data['p_c_chain']
      @table_2_group_mapping = cached_data['table_2_group_mapping']

    else
      form_fields = get_column_mapping_and_table_definition[0]
      init_table_to_sql_order
      get_group_definition
      # get target_field to display_name mapping
      get_field_name_mapping
      # get db_table children:parent mapping
      get_child_parent_mapping
      # get parent to child chain table
      get_parent_child_chain(form_fields)
      # get table name to group header id mapping
      # Make a map from target field names to field_descriptions
      tf_to_ff = {}
      form_fields.each {|ff| tf_to_ff[ff.target_field] = ff}
      get_table_to_group_mapping(@p_c_chain, tf_to_ff)
      cached_data = Hash.new
      cached_data['field_2_column_mapping'] = @field_2_column_mapping
      cached_data['column_2_field_mapping'] = @column_2_field_mapping
      cached_data['table_definition']= @table_definition
      cached_data['table_to_sql_order'] = @table_to_sql_order
      cached_data['db_virtual_master_fields'] = @db_virtual_master_fields
      cached_data['has_data_table'] = @has_data_table
      cached_data['group_definition'] = @group_definition
      cached_data['field_name_mapping'] = @field_name_mapping
      cached_data['c_p_mapping'] = @c_p_mapping
      cached_data['p_c_chain'] = @p_c_chain
      cached_data['table_2_group_mapping'] = @table_2_group_mapping
      $form_data_cache[@form_name] = cached_data
    end
  end


  # get child to parent table relationships based on the information in
  # db_table_descriptions table.
  #
  # Note: Currently only child to parent relationship of N:1 is supported.
  #
  # Parameters: none
  #
  # Returns:
  # * c_p_mapping - a has map that represents child to parent relationships
  #
  def get_child_parent_mapping
    c_p_mapping = Hash.new
    db_table_records = DbTableDescription.all

    db_table_records.each do |rec|
      p_table_name = nil
      if !rec.parent_table_id.nil?
        p_rec =  DbTableDescription.find(rec.parent_table_id)
        p_table_name = p_rec.data_table
      end
      c_p_mapping[rec.data_table] = p_table_name
    end

    @c_p_mapping = c_p_mapping
    return c_p_mapping

  end


  #
  # get a parent-child relationship chain table
  #
  # Parameters:
  # * form_fields - the fields for @form (which we pass in because
  #   these have already be obtained for another purpose)
  #
  # Returns:
  # * p_c_chain - a hash map that represents the parent-child relationship
  #               example:
  #                   {"obr_orders"=>{"obx_observations"=>nil}}
  #
  def get_parent_child_chain(form_fields)

    p_c_chain = Hash.new
    table_names  = Array.new
    fields = form_fields
    fields.each do | field|
      if !field.db_field_description_id.blank?
        table_name = field.db_field_description.db_table_description.data_table
        table_names << table_name unless table_names.include?(table_name)
      end
    end
    # find the top level parents
    top_tables = get_top_level_tables(table_names)
    create_p_c_chain(top_tables, p_c_chain)
    @p_c_chain = p_c_chain
    return p_c_chain

  end

  #
  # create a parent-child relation mapping
  # called by get_parent_child_chain and itself
  #
  # Parameters:
  # * table_names - a list of tables that are children of same parent
  # * chain_hash - a hash map that represents their ancester's parent-child
  #                relationship
  #
  # Returns: none
  #          new relationship of these tables and their childen's are stored in
  #          the chain_hash object and hence returns to up level functions
  #
  def create_p_c_chain(table_names, chain_hash)
    table_names.each do |table_name|
      if has_child_tables?(table_name)
        sub_chain_hash = Hash.new
        chain_hash[table_name] = sub_chain_hash
        child_tables = get_child_tables(table_name)
        create_p_c_chain(child_tables, sub_chain_hash)
      else
        chain_hash[table_name] = nil
      end
    end
  end


  #
  # get all first ancestors or those within provided table names
  #
  # Parameters:
  # * table_names - an array of table names that ancestors are limited to
  #
  # Returns:
  # * rtn - an array of ancestor table names
  #
  def get_top_level_tables(table_names = nil)
    rtn = Array.new
    if !@c_p_mapping.nil?
      @c_p_mapping.each do |c_table, p_table|
        if p_table.blank?
          if table_names.nil?
            rtn << c_table
          elsif table_names.include?(c_table)
            rtn << c_table
          end
        end
      end
    end
    return rtn
  end


  #
  # check if a table has child tables
  #
  # Parameters:
  # * table_name - a database table name, specified in db_table_descriptions
  #                table
  # Returns:
  # * true/false
  #
  def has_child_tables?(table_name)
    rtn = false
    if !@c_p_mapping.nil? && @c_p_mapping.values.include?(table_name)
      rtn =true
    end
    return rtn
  end


  #
  # get a table's child tables
  #
  # Parameters:
  # * table_name - a database table name, specified in db_table_descriptions
  #                table
  # Returns:
  # * rtn - an array of table names
  #
  def get_child_tables(table_name)
    rtn = Array.new
    if !@c_p_mapping.nil?
      @c_p_mapping.each do |c_table, p_table|
        if table_name == p_table
          rtn << c_table
        end
      end
    end
    return rtn
  end


  #
  # Convert a data_table to data_hash according to actual table structure
  #    a data_hash structure that used by javascript to load data into a form
  #
  # Parameters:
  # * data_table - a hash map that contains data following actual table structure
  #
  # Returns:
  # * data_hash - a data_hash hash map that is used to load data into a form
  #            data_hash is created from form_params by data_hash_from_params()
  #
  # +data_hash+ example  -- PHR form:
  #  Note: Not every column name has to be listed fileds with empty value
  #        will not appear in data_hash
  # {
  # "demographics"=>
  #                 {"gender_code"=>"1",
  #                  "birth_year"=>"1",
  #                  "gender"=>"1",
  #                  "race_or_ethnicity"=>"1",
  #                  "birth_year_ET"=>"1"},
  # "mecial_contacts_grp"=>[
  #                       {"medical_record_comadd"=>
  #                                               {"medical_record_address"=>"1",
  #                                                "medical_record_comments"=>"1"},
  #                        "medical_record_name"=>"1",
  #                        "mecial_contacts_grp_id"=>"1",
  #                        "medical_record_type"=>"1",
  #                        "medical_record_phone"=>"1",
  #                        "medical_record_email"=>"1"
  #                       }
  #                       ],
  # "tests"=>
  #          {"mammogram"=>[
  #                        {"mamm_results"=>"1",
  #                         "mamm_results_code"=>"1",
  #                         "mamm_next_due"=>"1",
  #                         "mamm_next_due_ET"=>"1",
  #                         "mammogram_id"=>"1",
  #                         "mamm_date_performed"=>"1",
  #                         "mamm_date_performed_ET"=>"1"}
  #                        ],
  #           "colon_header"=>
  #                          {"colonoscopy"=>[
  #                                          {"colon_results"=>"1",
  #                                           "colon_next_due"=>"1",
  #                                           "colonoscopy_id"=>"1",
  #                                           "colon_date_performed_ET"=>"1",
  #                                           "colon_results_code"=>"1",
  #                                           "colon_date_performed"=>"1",
  #                                           "colon_next_due_ET"=>"1"}
  #                                          ],
  #                           "fobt"=>[
  #                                   {"fobt_results"=>"1",
  #                                    "fobt_next_due"=>"1",
  #                                    "fobt_date_performed"=>"1",
  #                                    "fobt_next_due_ET"=>"1",
  #                                    "fobt_id"=>"1",
  #                                    "fobt_date_performed_ET"=>"1"}
  #                                   ]
  #                          },
  #           ...
  #          }
  # ...
  # }
  #
  def convert_to_data_hash(data_table)
    data_hash = Hash.new
    data_hash = parse_group_definition(@group_definition, data_table)
    return data_hash
  end


  #
  # Convert a data_hash to data_table hashmap based on the actual data table
  # structure
  #
  # Parameters:
  # * data_hash - a data_hash hash map that is used to load data into a form
  #            data_hash is created from form_params by data_hash_from_params()
  #
  # Returns:
  # * data_table - a hash map that contains data following actual table structure
  #
  # +data_table+ examples: -- PHR form
  #  Note: Not every column name has to be included in data_hash
  #
  #   {"phr_fobt"=>
  #    [ {"fobt_next_due"=>"1",
  #       "fobt_next_due_HL7"=>"1",
  #       "fobt_date_performed_ET"=>"1",
  #       "fobt_date_performed"=>"1",
  #       "fobt_next_due_ET"=>"1",
  #       "fobt_date_performed_HL7"=>"1",
  #       "fobt_results"=>"1"},
  #      {"fobt_next_due"=>"2",
  #       "fobt_next_due_HL7"=>"2",
  #       "fobt_date_performed_ET"=>"2",
  #       "fobt_date_performed"=>"2",
  #       "fobt_next_due_ET"=>"2",
  #       "fobt_date_performed_HL7"=>"2",
  #       "fobt_results"=>"2"},
  #      ...
  #    ],
  #    "phr_doctor_questions"=>
  #    [ {"question"=>"1",
  #      "category_code"=>"1",
  #      "date_entered_HL7"=>"1",
  #      "date_entered_ET"=>"1",
  #      "question_status_code"=>"1",
  #      "category"=>"1",
  #      "question_status"=>"1",
  #      "date_entered"=>"1"},
  #      ...
  #    ]
  #    ...
  #   }
  #
  def convert_to_data_table(data_hash)
    data_table = Hash.new
    data_table = parse_data_hash(data_table,data_hash)
    # merge multiple records of tables that have no record_id into one records
    data_table.each do |table_name, records|
      db_table_record = DbTableDescription.find_by_data_table(table_name)
      if !db_table_record.has_record_id
        merged_record = {}
        records.each do |record|
          merged_record = merged_record.merge(record)
        end
        data_table[table_name] = [merged_record]
      end
    end
    return data_table

  end


  # to be modified when data_hash is removed
  #

  #
  # create a field id to [table,column,index] mapping table
  #
  # Parameters:
  # * data_hash - data_hash that contains the form data
  # * suffix - prior suffix of the field id
  # * taffy_mapping - prior mapping table
  # * index_in_table - record index in a table, if the up level is a table,
  #                    the defualt value is 0
  #
  # Returns:
  # * taffy_mapping - new mapping table
  #
  def parse_data_hash_for_id_2_db_mapping(data_hash, suffix, taffy_mapping,
      index_in_table=0)
    data_hash.each  do |key, value|
      case value
      # a repeating line table group
      when Array
        i =0
        length = value.length
        while i<length
          value[i].each do |target_field, field_value|
            # if it's hash, meaning a sub group within a repeating line table
            # the suffix needs to be extended
            if field_value.class == Hash
              taffy_mapping = parse_data_hash_for_id_2_db_mapping(value[i],
                  suffix + "_" + (i+1).to_s, taffy_mapping, i)
            # a simple repeating line table
            else
              table_name = get_table_name_by_target_field(target_field)
              column_name = get_column_name_by_target_field(target_field)

              field_suffix = suffix + "_" + (i+1).to_s
              taffy_mapping[FORM_OBJ_NAME + "_" + target_field + field_suffix] =
                  [table_name, column_name, i+1]
            end
          end
          i += 1
        end
      # a sub group
      when Hash
        taffy_mapping = parse_data_hash_for_id_2_db_mapping(value,
            suffix + "_1", taffy_mapping, index_in_table)
      # an end field
      when String, Integer, Float, BigDecimal, Numeric, nil
        field_suffix = suffix
        table_name = get_table_name_by_target_field(key)
        column_name = get_column_name_by_target_field(key)
        taffy_mapping[FORM_OBJ_NAME + "_" + key + field_suffix] =
            [table_name, column_name, index_in_table+1]
      end
    end
    return taffy_mapping
  end


  #
  # get a form's group definition including all fields in the groups
  # in the format of data_hash, where values are all nil
  #
  # Parameters: none
  #
  # Returns: none
  #
  def get_group_definition()

    # Get all top-level field definitions - i.e. all fields with no
    # group header field.
    top_fields = @form.top_fields

    group_definition = Hash.new

    top_fields.each do |field|
      one_group = get_one_group_field_definition(field)
      group_definition = group_definition.merge(one_group)
    end
    @group_definition = group_definition
  end


  #
  # get group/fields definition under one group/field
  # called by get_group_definition and itself
  #
  # Parameters:
  # * one_field - a FieldDescription object of a group field
  #
  # Returns:
  # * one_group - a group definition for the specified group field
  #
  def get_one_group_field_definition(one_field)

    one_group = Hash.new

    if one_field.nil?
      logger.warn "field is nil. something is wrong"
      return group_definition

    # it is a group header
    elsif one_field.control_type.downcase == 'group_hdr'
      sub_fields = one_field.subFields
      group_hash = Hash.new
      sub_fields.each do | sub_field|
        sub_group = get_one_group_field_definition(sub_field)
        group_hash = group_hash.merge(sub_group)
      end

      # this group has a table (1 row or multiple rows)
      if one_field.has_id_column?
        # add a record_id field if it is a multiple row table
        if one_field.has_id_column?
          group_hash[one_field.target_field.singularize + '_id'] = nil
        end
        one_group[one_field.target_field] = [group_hash]
        # this group has no table
      else
        one_group[one_field.target_field] = group_hash
      end
    # regular fields
    elsif !one_field.db_field_description_id.blank?
      one_group[one_field.target_field] = nil
    end
    return one_group
  end


  #
  # Create a target_field to display_name mapping for a form
  # Used by report/export functions
  #
  # Parameters: none
  #
  # Returns:
  # * column_name_mapping - a hash map that contains a display_name,
  # hidden_field? and display_order for every target_field in the form:
  #   {target_field => [dispay_name, hidden_field?, display_order]}
  #
  def get_field_name_mapping()
    column_name_mapping = Hash.new
    fields = FieldDescription.where(form_id: @form.id)
    fields.each do | field |
      display_name = field.display_name
      if display_name.blank?
        display_name = field.getParam('tooltip')
      end
      column_name_mapping[field.target_field] = [display_name,
        field.hidden_field?, field.display_order]
    end

    @field_name_mapping = column_name_mapping
    return column_name_mapping
  end


  #
  # get a form's group definition including all fields in the groups
  # in the format of data_hash, where values are all nil
  #
  # same as get_group_definition except that it uses Dictionary instead of Hash
  # to maintain orders in a hash.
  #
  # Parameters: none
  #
  # Returns: none
  #
  def get_group_definition_in_order()

    # Get all top-level field definitions - i.e. all fields with no
    # group header field.
    top_fields = @form.top_fields

    group_definition = Dictionary.new

    top_fields.each do |field|
      one_group = get_one_group_field_definition_in_order(field)
      group_definition = group_definition.merge(one_group)
    end

    return group_definition
  end


  #
  # get group/fields definition under one group/field
  # called by get_group_definition_in_order and itself
  #
  # same as get_one_group_field_definition except that it uses Dictionary
  # instead of Hash to maintain orders in a hash.
  #
  # Parameters:
  # * one_field - a FieldDescription object of a group field
  #
  # Returns:
  # * one_group - a group definition for the specified group field
  #
  def get_one_group_field_definition_in_order(one_field)

    one_group = Dictionary.new

    if one_field.nil?
      logger.warn "field is nil. something is wrong"
      return group_definition

    # it is a group header
    elsif one_field.control_type.downcase == 'group_hdr'
      sub_fields = one_field.subFields
      group_hash = Dictionary.new
      sub_fields.each do | sub_field|
        sub_group = get_one_group_field_definition_in_order(sub_field)
        group_hash = group_hash.merge(sub_group)
      end

      # this group has a table (1 row or multiple rows)
      if one_field.has_id_column?
        # add a record_id field if it is a multiple row table
        if one_field.has_id_column?
          group_hash[one_field.target_field.singularize + '_id'] = nil
        end
        one_group[one_field.target_field] = [group_hash]
        # this group has no table
      else
        one_group[one_field.target_field] = group_hash
      end
    # regular fields
    elsif !one_field.db_field_description_id.blank?
      one_group[one_field.target_field] = nil
    end
    return one_group
  end


  #
  # Convert a data_table to data_hash according to actual table structure
  #    a data_hash structure that used by javascript to load data into a form
  #
  # same as convert_to_data_hash except that it uses Dictionary instead of Hash
  # to maintain orders in a hash.
  #
  # Parameters:
  # * data_table - a hash map that contains data following actual table structure
  #
  # Returns:
  # * data_hash - a data_hash hash map that is used to load data into a form
  #            data_hash is created from form_params by data_hash_from_params()
  #
  def convert_to_data_hash_in_order(data_table)
    data_hash = Dictionary.new
    group_definition_in_order = get_group_definition_in_order
    data_hash = parse_group_definition_in_order(group_definition_in_order,
      data_table)
    return data_hash
  end


  #
  # Reorganize data_table to reflect the actual structures on a form
  # called by convert_to_data_hash_in_order or itself
  #
  # same as parse_group_definition except that it uses Dictionary instead of Hash
  # to maintain orders in a hash.
  #
  # Parameters:
  # * data_hash_def - a group definition for a form
  # * data_table - a data_table object that contains user's data
  # * record_index - a flag that indicates which row is being process in a table
  #   in data_table
  #
  # Returns:
  # * ret - a data_hash object that contains user's data in the structures
  #   defined on a form
  #
  def parse_group_definition_in_order(group_def_in_order, data_table,
      record_index=0)
    ret = Dictionary.new
    group_def_in_order.each  do |key, value|
      case value
        # Array means multiple records possible
      when Array
        record_array = []
        record_def = value[0] # always one item in the array
        # get records number for this record from data_table
        # pick on column to check how many data records there are
        record_num = get_record_count(record_def, data_table)
        # get record data one by one
        i = 0
        while i< record_num
          record = parse_group_definition_in_order(value[0], data_table, i)
          record_array << record
          i += 1
        end
        if !record_array.empty?
          ret[key] = record_array
        end
        # Hash, continue to parse
      when Dictionary
        sub_hash = parse_group_definition_in_order(value, data_table,
          record_index)
        if !sub_hash.empty?
          ret[key] = sub_hash
        end
        # Leaf node, get the value from data_table
      when nil
        ret[key] = get_field_value_by_target_field(key, data_table,
          record_index)
      end
    end
    return ret
  end


  # get mapping from data_table_descriptions and data_field_descriptions
  #
  # Creates a field-to-table mapping for a form based on the field
  # definitions found in the database.
  #
  # Parameters:
  # * form_name - the form_name of a form
  #
  # Returns:
  # * [the form fields, column_2_field_mapping, field_2_column_mapping, table_definition]
  #
  # - +field_2_column_mapping+ - a hash map that represents form fields to table
  #    columns mapping: {target_field => [table, column, data_type]}
  # - +column_2_field_mapping+ - a hash map that represents table column to
  #    form fieldfield-to-table mapping: {table|column => [target_fields]}
  # - +table_definition+ - a hash map that represents actual tables/columns in
  #    database:  {table => {column => [ data_type, is_virtual, required, [target_fields]]}}
  #
  #   +field_2_column_mapping+ example -- PHR form
  #    {{"fobt_date_performed"=>["phr_fobts", "fobt_data_performed", :string],
  #     {"fobt_next_due_ET"=>["phr_fobts", "fobt_next_due_ET", :integer],
  #     ...
  #    }
  #   +column_2_field_mapping+ example -- PHR form
  #    {"phr_fobts|fobt_date_performed"=>["fobt_date_performed"]
  #     "phr_fobts|fobt_next_due_ET"=>["fobt_next_due_ET", "other field if any"]
  #    }
  #   +table_definition+ example -- PHR form
  #   {
  #    "phr_fobts"=>
  #    {"fobt_results"=>[:string, false, false, [fobt_results]],
  #    "fobt_next_due_HL7"=>[:string, false, false, [fobt_next_due_HL7]],
  #    "fobt_next_due"=>[:string, false, false, [fobt_next_due]],
  #    "fobt_date_performed"=>[:string, false, false, [fobt_date_performed]],
  #    "fobt_next_due_ET"=>[:string, false, false, [fobt_next_due_ET]],
  #    "fobt_date_performed_HL7"=>[:string, false, false, [fobt_date_performed_HL7]],
  #    "fobt_date_performed_ET"=>[:string, false, false, [fobt_date_performed_ET]]}
  #   }
  #
  def get_column_mapping_and_table_definition
    # get all fields of the form
    form_fields = @form.fields.includes(:group_header, :db_field_description=>[:db_table_description,
      :controlling_field, :controlled_fields])

    field_2_column_mapping = Hash.new
    column_2_field_mapping = Hash.new
    table_definition = Hash.new
    db_fields_from_master_tables = Hash.new

    form_fields.each do | field|
      if !field.db_field_description_id.nil?
        table_name = field.db_field_description.db_table_description.data_table
        column_name = field.db_field_description.data_column
        is_virtual =  field.db_field_description.virtual
        required =  field.db_field_description.required
        tableClass = table_name.singularize.camelcase.constantize
        # get the column data type from database
        column_type = tableClass.columns_hash[column_name].type unless
        tableClass.columns_hash[column_name].nil?

        # mapping 1: field to column
        field_2_column_mapping[field.target_field] = [table_name, column_name,
          column_type]

        # mapping 2: column to fields
        # this is a 1-n mapping between a column in a data table and a field on a form
        key = table_name + "|" + column_name
        target_fields = column_2_field_mapping[key]
        if target_fields.nil?
          column_2_field_mapping[key] = [field.target_field]
        else
          target_fields << field.target_field
          column_2_field_mapping[key] = target_fields
        end

        # table definition
        table_def = table_definition[table_name]
        if table_def.nil?
          table_def = Hash.new
          table_definition[table_name] = table_def
        end

        column_def = table_def[column_name]
        if column_def.nil?
          column_def = [column_type, is_virtual, required, [field.target_field]]
          table_def[column_name] = column_def
        else
          target_fields = column_def[3]
          target_fields << field.target_field
          table_def[column_name] = column_def
        end

        # db fields that get data from master fields
        db_table_def = db_fields_from_master_tables[table_name]
        if db_table_def.nil?
          db_table_def = Hash.new
          db_fields_from_master_tables[table_name] = db_table_def
        end

        controlling_field_id = field.db_field_description.controlling_field_id
        if controlling_field_id.nil?
          controlling_field = nil
        else
          controlling_field = field.db_field_description.controlling_field.data_column
        end

        list_values_for_field = field.db_field_description.list_values_for_field
        current_item_for_field = field.db_field_description.current_item_for_field
        current_value_for_field = field.db_field_description.current_value_for_field

        list_master_table = field.db_field_description.list_master_table
        list_identifier = field.db_field_description.list_identifier
        item_master_table = field.db_field_description.item_master_table
        fields_saved = field.db_field_description.fields_saved
        list_code_column = field.db_field_description.list_code_column
        item_table_has_unique_codes = field.db_field_description.item_table_has_unique_codes
        list_join_string = field.db_field_description.list_join_string
        field_obj = field.db_field_description
        field_id = field.db_field_description.id
        has_controlled_virtual_field = field.db_field_description.has_controlled_virtual_field?

        db_column_def = db_table_def[column_name]
        if db_column_def.nil? && (!item_master_table.blank? || !controlling_field.blank?)
          db_column_def = [is_virtual, controlling_field,
            list_values_for_field, current_item_for_field,
            current_value_for_field, list_master_table,
            list_identifier, item_master_table,
            fields_saved, list_code_column,
            item_table_has_unique_codes, list_join_string,
            field_obj, field_id,
            has_controlled_virtual_field]
          db_table_def[column_name] = db_column_def
        end
      end

    end

    @field_2_column_mapping = field_2_column_mapping
      @column_2_field_mapping = column_2_field_mapping
    @table_definition = table_definition


    @db_virtual_master_fields = db_fields_from_master_tables

    if table_definition.nil? || table_definition.empty?
      @has_data_table = false
    else
      @has_data_table = true
    end

    return form_fields, column_2_field_mapping, field_2_column_mapping, table_definition
  end


  #
  # get table to group header id mappings
  # used for new javascripts dataloader
  #
  # Parameters:
  # * p_c_chain - parent-child relationship chain of tables
  # * tf_to_ff - a map from target field names to field description objects
  #   for the form.
  #
  # Returns:
  # * table_2_group - an array of the [table,group_header_id] array
  #
  def get_table_to_group_mapping(p_c_chain, tf_to_ff)
    table_definition= @table_definition
    table_2_group = Array.new
    p_c_chain.each do |table_name, c_table_chain|
      # get the group header id from the target_fields
      group_header_ids = Hash.new
      column_defs = table_definition[table_name]
      column_defs.each do |column, column_def|
        target_fields = column_def[3]
        target_fields.each do |target_field|
          grp_hdr_id = calculate_table_group_header_id(tf_to_ff[target_field])
          if !grp_hdr_id.blank?
            group_header_ids[grp_hdr_id] = nil
          end
        end
      end
      table_2_group << [table_name, group_header_ids.keys]

      # recursively process c_table_chain
      if !c_table_chain.nil?
        sub_mapping = get_table_to_group_mapping(c_table_chain, tf_to_ff)
        table_2_group.concat(sub_mapping) unless sub_mapping.empty?
      end
    end

    @table_2_group_mapping = table_2_group
    return table_2_group
  end


  # get the corresponding form table's group's element id based on the
  # field in that group
  #
  # Parameters:
  # * form_field - a field on the form
  #
  # Returns:
  # group_header_id - the group header field's element id for the form table
  # containing the given field, or nil if the field is not in a form table.
  def calculate_table_group_header_id(form_field)
    group_header_id = nil
    next_suffix = "_0"
    table_group = nil

    if !form_field.nil?
      group_header_field =form_field.group_header
      meet_a_table = false
      while !group_header_field.nil?
        suffix = next_suffix
        if group_header_field.has_a_table?
          if !meet_a_table
            table_group = group_header_field.target_field
            meet_a_table = true
          end
        end
        next_suffix = "_1" + suffix if meet_a_table
        group_header_field = group_header_field.group_header
      end
      group_header_id = FORM_OBJ_NAME+"_"+table_group + suffix if meet_a_table
    end

    return group_header_id
  end


  #
  # get a form field's corresponding data table name
  #
  # Parameters:
  # * target_field - a field's target_field
  #
  # Returns:
  # * rtn - a table name
  #
  def get_table_name_by_target_field(target_field)
    rtn = @field_2_column_mapping[target_field]
    if !rtn.nil?
      rtn = rtn[0]
    end
    return rtn
  end


  #
  # get a form field's corresponding column name in a data table
  #
  # Parameters:
  # * target_field - a field's target_field
  #
  # Returns:
  # * rtn - a column name
  #
  def get_column_name_by_target_field(target_field)
    rtn = @field_2_column_mapping[target_field]
    if !rtn.nil?
      rtn = rtn[1]
    end
    return rtn
  end


  #
  # Check if a data cloumn is a virtual field in the data table
  #
  # Parameters:
  # * table_name - a database table name
  # * column_name - a column name in the table
  #
  # Returns:
  # * True/False
  #
  def is_column_virtual?(table_name, column_name)
#    rtn = false
#    table_def = @table_definition[table_name]
#    if !table_def.nil?
#      col_def = table_def[column_name]
#      if !col_def.nil?
#        rtn = col_def[1]
#      end
#    end
#    return rtn
    return false
  end


  #
  # Check if a data column is used by a field in the current form
  #
  # Parameters:
  # * table_name - a database table name
  # * column_name - a column name in the table
  #
  # Returns:
  # * True/False
  #
  def is_column_used?(table_name, column_name)
    rtn = false
    target_fields = @column_2_field_mapping[table_name + "|" + column_name]
    # Bug fix-if no mapping then not used in the form since @column_2_field_mapping
    # based on form definitions in Field Description
    if target_fields.nil?
      return rtn
    end
    target_fields.each do |field|
      if !@field_name_mapping[field].nil?
        rtn = true
        break
      end
    end
    return rtn
  end


  #
  # get a form field's corresponding column data type in a data table
  #
  # Parameters:
  # * target_field - a field's target_field
  #
  # Returns:
  # * rtn - a data type symbol
  #
  def get_column_data_type_by_target_field(target_field)
    rtn = @field_2_column_mapping[target_field]
    if !rtn.nil?
      rtn = rtn[2]
    end
    return rtn
  end


  #
  # Check if a column name is defined in a table
  #
  # Parameters:
  # * table_name - a table's name where the column is to be checked within
  # * column_name - a column_name to be checked
  #
  # Returns:
  # * True/False
  #
  def is_column_valid?(table_name, column_name)

    if !@table_definition[table_name].nil? &&
          !@table_definition[table_name][column_name].nil? && column_name.to_s !="id"
      return true
    else
      return false
    end
  end


  #
  # Check if a data record has all the required fields
  #
  # Parameters:
  # * table_name - a database table name
  # * record_data - a hash map that contains a data record of the table
  #
  # Returns:
  # * True/False
  #
  def has_required_data?(table_name, record_data)
    rtn = true
    table_def = @table_definition[table_name]
    if !table_def.nil?
      table_def.each do |column_name, col_def|
        if col_def[2] && record_data[column_name].blank?
          rtn = false
          key = "#{table_name}|#{column_name}"
          if @column_2_field_mapping[key] &&
              @column_2_field_mapping[key][0] &&
              @field_name_mapping[@column_2_field_mapping[key][0]]
            field_name = @field_name_mapping[@column_2_field_mapping[key][0]][0]
          else
            field_name = column_name
          end
          @feedback['errors'] << "'#{field_name}' must not be left blank."
          break
        end
      end
    end
    return rtn
  end


  # not used
  #
  # Check if a data cloumn is a required field in the data table
  #
  # Parameters:
  # * table_name - a database table name
  # * column_name - a column name in the table
  #
  # Returns:
  # * True/False
  #
  def is_column_required?(table_name, column_name)
    rtn = false
    table_def = @table_definition[table_name]
    if !table_def.nil?
      col_def = table_def[column_name]
      if !col_def.nil?
        rtn = col_def[2]
      end
    end
    return rtn
  end


  #
  # Check if the user's input data is same as a record in a table or it is a
  #   subset of a record in a table
  # Parameters:
  # * table_name - a database table name
  # * existing_record_data - a hash map that contains a record in a table'
  #       NON_FORM_DATA_COLS columns ("id", "version_date", "deleted_at",
  #       "latest", and "profile_id") are ignored in copying data
  # * record_data - a hash map that contains user's data for the same table
  #
  # Returns:
  # * new_record_data - a hash map that combines new data with carried over
  #                     data
  #
  def carry_over_last_values_if_not_present(table_name, existing_record_data,
      record_data)

    # if no existing record, meaning this is a new record
    if existing_record_data.nil?
      new_record_data = record_data
      # if no user's input data, meaning no need to save
    elsif record_data.nil?
      new_record_data = nil
    else
      new_record_data = record_data.clone
      missing_columns = existing_record_data.keys - record_data.keys
      missing_columns.each do |column|
        case column
        when NON_FORM_DATA_COLS
        else
          # only if the column is not used in the current form
          if !is_column_used?(table_name, column)
            new_record_data[column] = existing_record_data[column]
          end
        end
      end # end of each
    end
    return new_record_data

  end


  #
  # check if the field needs additional process to get the latest name values
  # from master tables
  #
  # Parameters:
  # * table_name - a user data table name
  # * data_column - a column name in the user data table
  #
  # Returns:
  # * True/False
  #
  def is_virtual_or_master_field?(table_name, data_column)
    ret = false
    master_table_col_info = @db_virtual_master_fields[table_name][data_column]
    if !master_table_col_info.nil?
      controlling_field = master_table_col_info[1]
      item_master_table = master_table_col_info[7]
      if !controlling_field.blank? || !item_master_table.blank?
        ret = true
      end
    end
    return ret
  end


  #
  # check if the field needs additional process to get the values for
  # virtual fields from master tables
  #
  # Parameters:
  # * table_name - a user data table name
  # * data_column - a column name in the user data table
  #
  # Returns:
  # * True/False
  #
  def has_controlled_virtual_field?(table_name, data_column)
    ret = false
    master_table_col_info = @db_virtual_master_fields[table_name][data_column]
    if !master_table_col_info.nil?
      has_controlled_virtual_field = master_table_col_info[14]
      if has_controlled_virtual_field
        ret = true
      end
    end
    return ret
  end


  #
  # check if the data_column is a field that needs mater table info and
  # is not controlled by any other fields
  # (and controls other fields??)
  #
  # Parameters:
  # * table_name - a user data table name
  # * data_column - a column name in the user data table
  #
  # Returns:
  # * True/False
  #
  def is_root_controlling_field?(table_name, data_column)
    ret = false
    virtual_master_field_info = @db_virtual_master_fields[table_name]

    if !virtual_master_field_info.nil?
      col_info = virtual_master_field_info[data_column]
      # if it is not controlled by other fields
      if !col_info.nil? && col_info[1].blank?
#        # check if data_cololumn appears as a controlling field
#        controlling = false
#        virtual_master_field_info.each do |column_name, column_info|
#          if !column_info.empty? && column_info[1] == data_column
#            controlling = true
#            break
#          end
#        end
#        # if it's a controlling field too, it's a root controlling field
#        if controlling
#          ret = true
#        end

        ret = true
      end
    end
    return ret
  end


  #
  # get a list of fields that are controlled by a provided field
  # Parameters:
  # * table_name - a user data table name
  # * data_column - a column name in the user data table
  #
  # Returns:
  # * controlled_fields - an array that contains a list of columns that is
  #                       is controlled by data_column
  #
  def get_controlled_fields(table_name, data_column)
    controlled_fields = Array.new
    virtual_master_field_info = @db_virtual_master_fields[table_name]

    if !virtual_master_field_info.nil?
      # check if data_cololumn appears as a controlling field
      virtual_master_field_info.each do |column_name, column_info|
        if !column_info.empty? && column_info[1] == data_column
          controlled_fields << column_name
        end
      end
    end
    return controlled_fields
  end


  #
  # Check if the user's input data is same as a record in a table or it is a
  #   subset of a record in a table
  # Parameters:
  # * table_name - a database table name
  # * existing_record_data - a hash map that contains a record in a table.
  #       columns "id", "version_date", "deleted_at" and "latest" are ignored
  #       in the comparision.
  # * record_data - a hash map that contains user's data for the same table
  #
  # Returns:
  # * True/False
  #
  def is_data_same?(table_name, existing_record_data, record_data)

    ret = true
    # if no existing record, meaning this is a new record
    if existing_record_data.nil?
      ret = false
      # if no user's input data, meaning no need to save
    elsif record_data.nil?
      ret = true
    else
      column_def = @table_definition[table_name]
      column_def.keys.each do | column |
        case column
        # columns "id", "version_date", "deleted_at" and "latest" are ignored
        # in the comparision.
        #when 'id', 'version_date', 'deleted_at', 'latest'
        when NON_FORM_DATA_COLS
        else
          value = record_data[column]
          # value might be nil
          if value.blank?
            if !existing_record_data[column].blank?
              ret = false
              break
            end
            # if not nil, convert to string for comparision
          else
            existing_value = existing_record_data[column]
            # if new value is nil
            if existing_value.nil? || value.to_s != existing_value.to_s
              ret = false
              break
            end
          end # end of value might be nil
        end # end of case
      end # end of each
    end # end of existing_record_data.nil?
    return ret
  end


  #
  # Check if user's input data is empty
  #
  # Parameters:
  # * table_class - the model class for the database table
  # * record_data - a hash map that contains user's data for a table
  # * parent_table_foreign_key - the name of the foreign key column
  # Returns:
  # * True/False
  #
  def is_data_empty?(table_class, record_data, parent_table_foreign_key)

    ignored_columns = table_class.phr_ignored_columns

    record_data.each do |column, value|
      if !ignored_columns.include?(column)
        # if value is not nil, check value content
        if !value.nil? && value.to_s.length > 0
          return false
        end
      end
    end
    return true
  end


  #
  # Get data type of a column defined in a table
  # Parameters:
  # * column_name - a column_name to be checked
  # * table_name - a table's name where the column is to be checked within
  #
  # Returns:
  # * data_type or nil
  #
  def get_column_data_type(column_name, table_name)

    if !@table_definition[table_name].nil? &&
          !@table_definition[table_name][column_name].nil?
      return  @table_definition[table_name][column_name][0]
    else
      return nil
    end
  end


  #
  # Convert data from 'String' to a new type of a column defined in a table
  # Parameters:
  # * data_value - an original data value, it is always a "String", since it's
  #                   a parameter submitted from a web form
  # * new_type - a new data type (Ruby and Rails data type)
  #                   for exmaple, :integer, :string
  #
  # Returns:
  # * data_value - in new data type
  #
  def change_data_type(data_value, new_type)

    ret = data_value

    # if value is an empty string return nil
    if data_value.blank?
      ret = nil
      # if no new data_type, return value untouched
    elsif  !new_type.nil?
      case new_type
      when :string
      when :text
      when :float, :decimal
        ret = data_value.to_f
      when :integer
        ret = data_value.to_i
      when :boolean

      end
    end
    return ret
  end


  #
  # In order to prevent cross site scripting, we need to insert a space
  # immediately after any '<' characters in the data value except for
  # the ones already followed by "=" or space  (For list of encoded "<" codes,
  # see character encoding in http://ha.ckers.org/xss.html)
  # Parameters:
  # * data_value - an original data value needs to be sanitized
  # * data_type - an active record column data type
  def xss_sanitize(data_value, data_type)
    rtn = data_value
    if [:string, :text].include? data_type
      if rtn && (rtn.is_a? String)
        # Here we are also allowing ; as the character following <, but only in
        # order to push the ; from &lt; in the same capturing group.
        regex = Regexp.new(/(<|%3C|&(lt|#(0*60|x0*3c));?|\\(x|u00)3c)(?=[^;=\s])/i)
        rtn = rtn.gsub(regex) do |m|
          $1+" "
         end
      end
    end
    rtn
  end


  #
  # Reorganize data_hash to reflect the actual table structures in database
  # called by convert_to_data_table or itself
  #
  # Parameters:
  # * data_table - a data_table object to contain the coverted data
  # * data_hash - a data_hash object to be parsed and converted
  #
  # Returns
  # * data_table - a data_table object
  #
  def parse_data_hash(data_table, data_hash)

    data_hash.each do |key, value|
      case value
        # a record in a repeating table
      when Array
        # flatten sub hash tables if any
        # record is a hash
        value.each do |record|
          # if record.class == Hash
          record = flatten_hash(record)
          # end
          table_name = nil
          data_rec = Hash.new
          record.each do |target_field, field_value|
            table_name = get_table_name_by_target_field(target_field)
            column_name = get_column_name_by_target_field(target_field)
            if !table_name.nil?
              if data_table[table_name].nil?
                data_table[table_name] = Array.new
              end
              data_rec[column_name] = field_value
            end
          end
          if !data_table[table_name].nil?
            data_table[table_name] << data_rec
          end
        end
        # sub group
      when Hash
        data_table = parse_data_hash(data_table, value)
        # non-repeating table
      when String
        table_name = get_table_name_by_target_field(key)
        column_name = get_column_name_by_target_field(key)
        if !table_name.nil?
          if data_table[table_name].nil?
            data_table[table_name] = Array.new
            data_table[table_name] << Hash.new
          elsif !data_table[table_name][0][column_name].nil?
            logger.warn "multiple values for some field in non repeating table, " +
                key + ":" + value
          end
          data_table[table_name][0][column_name] = value
        end
      end
    end
    return data_table

  end


  # flatten hash table (recursively) (assume no array inside this hash)
  #
  # Parameters:
  # * data_hash - a data_hash object
  #
  # Returns:
  # * ret - a flattened hash object
  #
  # examples:
  # from:
  # {"medical_record_comadd"=>
  #                        {"medical_record_address"=>"1",
  #                         "medical_record_comments"=>"1"},
  #  "medical_record_name"=>"1",
  #  "mecial_contacts_grp_id"=>"1",
  #  "medical_record_type"=>"1",
  #  "medical_record_phone"=>"1",
  #  "medical_record_email"=>"1"
  # }
  #
  # to :
  # {"medical_record_address"=>"1",
  #  "medical_record_comments"=>"1",
  #  "medical_record_name"=>"1",
  #  "mecial_contacts_grp_id"=>"1",
  #  "medical_record_type"=>"1",
  #  "medical_record_phone"=>"1",
  #  "medical_record_email"=>"1"
  # }
  def flatten_hash(data_hash)
    case data_hash
    when Hash
      ret = Hash.new
    when Dictionary
      ret = Dictionary.new
    end

    data_hash.each  do |key, value|
      case value
      when Array
        logger.warn "This is an Array. Something is wrong!"
        logger.warn data_hash
        logger.warn "key:" + key
      when Hash, Dictionary
        sub_ret = flatten_hash(value)
        ret = ret.merge(sub_ret)
      when String, Integer, Float, BigDecimal, Numeric, nil
        ret[key]=value
      end
    end
    return ret
  end


  #
  # Reorganize data_table to reflect the actual structures on a form
  # called by convert_to_data_hash or itself
  #
  # Parameters:
  # * data_hash_def - a group definition for a form
  # * data_table - a data_table object that contains user's data
  # * record_index - a flag that indicates which row is being process in a table
  #   in data_table
  #
  # Returns:
  # * ret - a data_hash object that contains user's data in the structures
  #   defined on a form
  #
  def parse_group_definition(data_hash_def, data_table, record_index=0)
    ret = {}
    data_hash_def.each  do |key, value|
      case value
        # Array means multiple records possible
      when Array
        record_array = []
        record_def = value[0] # always one item in the array
        # get records number for this record from data_table
        # pick on column to check how many data records there are
        record_num = get_record_count(record_def, data_table)
        # get record data one by one
        i = 0
        while i< record_num
          record = parse_group_definition(value[0], data_table, i)
          record_array << record
          i += 1
        end
        if !record_array.empty?
          ret[key] = record_array
        end
        # Hash continue parse
      when Hash
        sub_hash = parse_group_definition(value, data_table, record_index)
        if !sub_hash.empty?
          ret[key] = sub_hash
        end
        # Leaf node, get the value from data_table
      when nil
        ret[key] = get_field_value_by_target_field(key, data_table, record_index)
      end
    end
    return ret
  end


  #
  # get a field value from a data_table by the field's target_field
  #
  # Parameters:
  # * target_filed - a field's target_field in a data_hash
  # * data_table - a hash map that contains data following actual table
  #   structure
  # * record_index - an index of record in an array in data_table
  #
  # Returns:
  # * value - the value for the field in the specified record
  #
  def get_field_value_by_target_field(target_field, data_table, record_index)
    value = nil
    table_name = get_table_name_by_target_field(target_field)
    column_name = get_column_name_by_target_field(target_field)
    data_records = data_table[table_name]
    # there are data retrieved from db
    unless data_records.nil?
      record = data_records[record_index]
      value = record[column_name]
    end
    return value
  end


  #
  # get the number of record of a table in data_table
  #
  # Parameters:
  # * record_def - a sub hash of group_defition hash map
  # * data_table - a hash map that contains data following actual table
  #   structure
  #
  # Returns:
  # * record_num - the total record number in the table that record_def belongs
  #
  def get_record_count(record_def, data_table)

    value = record_def.values[0]

    # leaf node
    if value.nil?
      target_field = record_def.keys[0]
      table_name = get_table_name_by_target_field(target_field)
      data_records = data_table[table_name]
      # there are data retrieved from db
      if !data_records.nil?
        record_num = data_records.length
      else
        record_num = 0
      end
      # otherwise go deeper to find a leaf node to get record num
    else
      record_num = get_record_count(value, data_table)
    end

    return record_num
  end


  # Initializes the @table_to_sql_order hashmap.  This should be called after
  # get_column_mapping_and_table_definition is called, because it relies
  # on @table_definition to get a list of tables.
  def init_table_to_sql_order
    @table_to_sql_order = {}
    @table_definition.keys.each do |table_name|
      # Find a list of fields that should control the sort order of items
      # retrieved from this table.
      td = DbTableDescription.find_by_data_table(table_name)
      dfs =td.db_field_descriptions.where(
        '(is_major_item=1 or controlling_field_id is not null) and predefined_field_id=1 and virtual=0')
      major = nil
      other = []
      # There should be one for which "is_major_item" is true; separate that
      # from the others (if there are others) and put that first in the order
      # list.
      dfs.each do |df|
        if df.is_major_item
          major = df.data_column
        else
          other << df.data_column
        end
      end
      order_list = major ? [major] : []
      order_list = order_list.concat(other) if !other.empty?
      if !order_list.empty?
        @table_to_sql_order[table_name] = order_list.join(',')
      end
    end
  end


  # Takes a template string and replaces tokens with form data from the
  # taffy database for the current form.  Currently template strings are
  # used for form titles and other info to show specific data items in
  # text strings on the form.  Tokens are specified by placing the
  # taffy database key within braces ({}).
  #
  # Simple conversions may be performed on the strings.  Any string conversion
  # method of the String class may be appended to a token name as long
  # as it does not require parameters.  The most obvious examples are case
  # conversions, e.g. downcase and upcase.  Specifying {phrs.gender.downcase}
  # will cause the downcase method to be run on the gender value.  Note that:
  # 1.  the String class method name must be used;
  # 2.  it must be the last "part" of the token specification; and
  # 3.  it must not require parameters.
  #
  # Other conversions may be signalled by preceding the token with the name of
  # the method providing the conversion and enclosing the token in parenthesis,
  # e.g. short_age({phrs.birth_date}).  Currently the conversion function
  # must take one and only one parameter, which is the token value.
  #
  # This was moved from application_controller.rb to here because it is
  # not an action, and thus not appropriate to the controller.
  #
  # Parameters:
  # * form_str - the template string
  # * taffy_data - the taffy data structure
  #
  # Returns:  the form_str with the toekns replaced by their values
  #
  def self.find_template_field_values(form_str, taffy_data)
    elems = form_str.scan(/\{([0-9a-zA-Z._-]*)\}/)
    string_subs_hash = Hash.new
    elems.each { |e|
      # e is an array with one element.  We want to use it as a string, so
      # rather than referencing the array element 3 times, we just create a
      # string variable for it.
      cur_elem = e[0]
      str_func = nil
      elems_hash = taffy_data
      tokens = cur_elem.split(".")
      tokens.each_with_index {|key, index|
        if !elems_hash[key].nil?
          elems_hash = elems_hash[key]
          elems_hash = elems_hash[0] if (elems_hash.class == Array)
        elsif index > 0
          str_func = key
        end
      }
      # If elems_hash is still a hash, it's still got all the original
      # taffy data in it, because no values were found for the element.
      # For example, the main PHR page header banner includes a string
      # with the profile name, gender and age in it.  If one of those
      # values are not found, the elems_hash will still be a hash of
      # all the demographics info, which we don't want to merge in below.
      # Instead we want the value for that element to show as nil, so
      # that the token will be entirely removed from the form string.
      if elems_hash.class == Hash
        elems_hash = nil
      end
      if !str_func.nil? && !elems_hash.nil?
        string_subs_hash.merge!({cur_elem=>(elems_hash.send str_func)})
      else
        string_subs_hash.merge!({cur_elem=>elems_hash})
      end
    }
    string_subs_hash.each_pair {|key, value|

      # Find the key string in the larger string and determine whether or
      # not it's got a function attached to it.  Do this whether or not we
      # have a corresponding value, because we have to replace the whole
      # thing, function name as well as key string, with either a value or
      # nothing.
      key_string = '{' + key + '}'
      key_start = form_str.index(key_string)
      kpos = key_start - 1
      if key_start > 0 && form_str[kpos,1] == '('
        while form_str[kpos,1] != ' ' && kpos >= 0
          kpos -= 1
        end
        func_name = form_str[kpos+1..key_start-2]
        key_string = func_name + '(' + key_string + ')'
      else
        func_name = nil
      end
      # If we have a value, do any indicated conversions on the value
      # and replace the key with the value.
      if !value.blank?
        if func_name.nil?
          form_str = form_str.sub(key_string, value)
        else
          converted_val = self.send(func_name, value)
          form_str = form_str.sub(key_string, converted_val)
        end
      else
        # Otherwise, if we have no value for this particular key, remove the
        # key along with the preceding text (any indicated conversion function
        # and a preceding comma).
        form_str = form_str.sub(key_string, '')
        form_str = form_str.sub(', ,', ',')
        form_str = form_str.sub(/,[ a-zA-Z0-9]*\{\}/,'')
      end
    }
    return form_str.squeeze(' ').chomp(' ')
  end


  # Takes a date string and converts it to 'short' format.  Currently this
  # is used for the banner on the main PHR page, where the string for a
  # birth date 100 years ago would be 100 y/o.
  #
  # This used to be a javascript rule function but was moved to the server
  # side since the birth date is available from the server.
  #
  # Also see method PanelData#mod_test_date_by_et for calculating elapsed time
  #
  # Parameters:
  # * birth_date - the date of birth expressed as a string
  # * now - Time for today. Make it as a parameter for easy testing
  # * spell_out - flag indicating whether or not to spell out "old". Default
  #   is false, and "/o" is used instead of " old".
  #
  # Returns: the short string version of the age.
  #
  def self.short_age(birth_date, now=Date.today, spell_out=false)
    age_string = ''
    if !birth_date.blank?
      # If there are no spaces, dashes or characters in the string, assume we
      # only have a year - but check to make sure.  If only have one thing, and
      # it's not a year, just go with less than 1 year old and leave it at that.
      # (If we have just a month and a year, the parse function will default
      # the day to 1).
      if (birth_date.index(/[ \/\-a-z]/)).nil?
        if birth_date.to_i == 0
          if !spell_out
            age_string = ' < 1 y/o'
          else
            age_string = ' 1 year old'
          end
        else
          years = (now.year - birth_date.to_i)
          if !spell_out
            age_string = years.to_s + ' y/o'
          else
            if years == 1
              age_string = years.to_s + ' year old'
            else
              age_string = years.to_s + ' years old'
            end
          end
        end

      else
        # Replaces the original implementation which assumes the seconds per
        # month is a constant which caused the following bug:
        # "4 m/o" was returned instead of "5 m/o" when it was executed on
        # March 1st and birth day is 5 month ago.
        bd_time = Date.parse(birth_date)
        age_string = case
        # age >= 1 year
        when (now  >= 1.year.since(bd_time))
          year_diff = now.year - bd_time.year
          year_diff = year_diff -1 if !((now.month > bd_time.month) ||
              (now.month == bd_time.month && now.day >= bd_time.day))
          if !spell_out
            year_diff.to_s + ' y/o'
          else
            if year_diff == 1
              '1 year old'
            else
              year_diff.to_s + ' years old'
            end
          end
        # 1 year > age >= 1 month
        when (now >= 1.month.since(bd_time))
          month_diff = now.month - bd_time.month
          month_diff += 12 if now.year != bd_time.year
          if !spell_out
            month_diff.to_s + ' m/o'
          else
            if month_diff == 1
              '1 month old'
            else
              month_diff.to_s + ' months old'
            end
          end
        # 1 month > age >= 1 week
        when (now >= 1.week.since(bd_time))
          day_diff = now.day - bd_time.day
          day_diff += bd_time.end_of_month.day if now.month != bd_time.month
          if !spell_out
            day_diff.div(7).to_s + ' w/o'
          else
            if day_diff.div(7) == 1
              '1 week old'
            else
              day_diff.div(7).to_s + ' weeks old'
            end
          end
        # 1 week > age >= 1 day
        when (now >= 1.day.since(bd_time))
          day_diff = now.day - bd_time.day
          day_diff += bd_time.end_of_month.day if now.month != bd_time.month
          if !spell_out
            day_diff.to_s + ' d/o'
          else
            if day_diff == 1
              '1 day old'
            else
              day_diff.to_s + ' days old'
            end
          end
        # age < 1 day
        else
          if !spell_out
            ' < 1 d/o'
          else
            ' < 1 day old'
          end
        end
      end # if we don't/do have a birth month
    end # if birth_date string isn't blank
    return age_string
  end # short_age


  # Creates a record using either ActiveRecord#import or ActiveRecord#save based
  # on the @mass_save flag.
  # When @mass_save is true, an ActiveRecord instance will be initialized which
  # will be pushed into list @mass_inserts for mass importing and then returned;
  # When @mass_save is false, a new ActiveRecord record will be created and then
  # returned;
  #
  # Parameters:
  # * table_name table name of the returning new record
  # * attributes new record attributes
  # * user the user object for the current user
  def create_record(table_name, attributes, user)
    table_class = table_name.classify.constantize
    if @mass_save && table_name != "obr_orders"
      # auto increment the record_id based on the size of @mass_inserts list
      if attributes["record_id"] && !@mass_inserts[table_name].nil?
        attributes["record_id"] += @mass_inserts[table_name].size
      end

      r = table_class.new(attributes)
      if @mass_inserts[table_name].nil?
        @mass_inserts[table_name] = [r]
      else
        @mass_inserts[table_name] << r
      end

    else
      r = table_class.new(attributes)
      user.accumulate_data_length(table_class.get_row_length(r))
      r.save(:validate => false)
    end
    return r
  end


  # Updates a record using either ActiveRecord#import or ActiveRecord#save based
  # on the @mass_save flag.
  #
  # Following procedure will be followed for updating in order to maintain the
  # relationship between obr_orders and obx_observations tables:
  # 1) Creates a duplicated record for the existing record as a backup by setting
  # its latest attribute value to false;
  # 2) Updates the existing record with the changed attributes and make sure
  # the latest attribute is true;
  #
  # When @mass_save is true, step 1 will required us to push an initialized
  # ActiveRecord instance into @mass_inserts. Step 2 will require us to push the
  # up-to-date attribute values into @mass_updates. ActiveRecord#import will be
  # used later on to finished the mass inserting /updating;
  #
  # When @mass_save is false, ActiveRecord#save(false) method will be used to
  # complete step 1 and 2.
  #
  # Parameters:
  # * existing_record the record to be updated
  # * changed_attributes changed attributes and their values
  # * user the user object for the current user
  #
  def update_record(existing_record, changed_attributes, user)
    # update the flag 'latest' to false on the latest existing record
    # this means this record will not be displayed on form any more
    existing_record_data = existing_record.attributes
    table_name = existing_record.class.name.tableize
    table_class = table_name.classify.constantize
    hist_table_name = 'hist_' + table_name
    hist_table_class = hist_table_name.classify.constantize

    existing_record.attributes = changed_attributes
    existing_record_data.merge!({'orig_id'=>existing_record_data.delete('id'),
                                 'latest'=>false })
    hist_record = hist_table_class.new(existing_record_data)

    if @mass_save && table_name != "obr_orders"
      # tries to collect all the modified fields (using set instead of array to
      # avoid duplications)
      if @mass_updates[table_name].nil?
        @mass_updates[table_name] = [ existing_record ]
      else
        @mass_updates[table_name] << existing_record
      end
      if @mass_update_fields[table_name].nil?
        @mass_update_fields[table_name] = Set.new(existing_record.changes.keys)
      else
        @mass_update_fields[table_name].merge(existing_record.changes.keys)
      end

      if @mass_inserts[hist_table_name].nil?
        @mass_inserts[hist_table_name] = [ hist_record ]
      else
        @mass_inserts[hist_table_name] << hist_record
      end

    else
      # copy the new data to the existing db record
      #since this is an update of an existing record, save it even it is empty
      existing_record.save(:validate => false)
      # create a copy in the hist table
      user.accumulate_data_length(hist_table_class.get_row_length(hist_record))
      hist_record.save(:validate => false)
    end
  end


  # Deletes a record by setting its "latest" attribute to false using either
  # ActiveRecord#import or ActiveRecord#save based on the @mass_save flag.
  #
  # When @mass_save is true, an array consists of the ID of the record and the
  # value for the "latest" attribute which should always be false will be pushed
  # into list @mass_deletes for mass deleting;
  #
  # When @mass_save is false, ActiveRecord#save(false) method will be used to
  # mark the value of "latest" attribute to false;
  #
  # Parameters:
  # * record the record to be deleted
  def delete_record(record)
    id = record.id
    record.latest = false
    record.deleted_at = @current_time
    columns_values = record.attributes
    columns_values.merge!({'orig_id'=>columns_values.delete('id')})

    table_name = record.class.name.tableize
    hist_table_name = 'hist_' + table_name
    hist_class = hist_table_name.classify.constantize
    if @mass_save
      # delete the original record
      if @mass_deletes[table_name].nil?
        @mass_deletes[table_name] = [ id ]
      else
        @mass_deletes[table_name] << id
      end

      # and inset a copy in the hist table
      if @mass_inserts[hist_table_name].nil?
        @mass_inserts[hist_table_name] = [ hist_class.new(columns_values) ]
      else
        @mass_inserts[hist_table_name] << hist_class.new(columns_values)
      end
    else
      # insert a copy of data in the hist table
      hist_class.new(record.attributes).save
      # delete the record in the normal user data table
      record.delete
    end
  end


  # Do mass inserting/deleting/updating for the input table using data from
  # instance varialbes @mass_inserts, @mass_updates, @mass_deletes
  #
  # Parameters:
  # * user the user object
  def mass_saving(user)

    # the default max_allowed_packet is 1MB for MySQL server and 16MB for client
    # do mass saving
    if !@mass_inserts.empty?
      data_length = 0
      @mass_inserts.each do | table_name, records |
        table_class = table_name.classify.constantize
        table_class.import records, :validate => false
        data_length += table_class.get_mass_insert_length(records)
      end
      user.accumulate_data_length(data_length)
    end

    if !@mass_updates.empty?
      @mass_updates.each do | table_name, records |
        table_class = table_name.classify.constantize
        # Converts from set to array
        updating_fields = @mass_update_fields[table_name].to_a
        field_names = [table_class.primary_key.to_s].concat updating_fields
        field_values =
            records.map{|record| field_names.map{|e| record.send(e)} }
        table_class.import field_names, field_values, :validate => false,
                           :on_duplicate_key_update => updating_fields

        user.accumulate_data_length(
            table_class.get_mass_insert_length(records))
      end

    end

    if !@mass_deletes.empty?
      @mass_deletes.each do | table_name, ids |
        table_class = table_name.classify.constantize
        table_class.where(["id in (?)", ids ]).delete_all
      end

      # how to calculate data lenth?
    end

    # reset mass saving data
    reset_mass_saving
  end


  # Setup instance variables as buffers for mass data saving
  def reset_mass_saving
    # array of instances of new records to be inserted for each table
    @mass_inserts = {}
    # array of instances of modified existing records to be saved for each table
    @mass_updates = {}
    # array of id and latest value for records to be deleted for each table
    @mass_deletes = {}
    # array of attributes needs to be updated for each table
    @mass_update_fields = {}
  end


end # form_data
