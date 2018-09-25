class Profile < ActiveRecord::Base
  has_and_belongs_to_many :users, -> { readonly(false) }

  has_one :phr, -> { where(latest: true)}
  has_many :phr_drugs, -> { where(latest: true).order('drug_use_status_C, name_and_route') }
  has_many :phr_conditions, -> { where(latest: true).order('present_C, problem') }
  has_many :phr_surgical_histories,-> {where(latest: true).order('surgery_type')}
  has_many :phr_user_files, ->{order 'upload_date DESC'}
  has_many :phr_medical_contacts, ->{where(latest: true).order('name')}
  has_many :phr_doctor_questions, ->{where(latest: true).order("question_status_C, category, date_entered desc")}
  has_many :phr_allergies, ->{ where(latest: true).order('allergy_name')}
  has_many :phr_immunizations, ->{where(latest: true).order('immune_name')}
  has_many :phr_notes, ->{where(latest: true).order('note_date desc')}
  has_many :obr_orders, ->{where(latest: true).order('panel_name, test_date_ET desc')}
  has_many :obx_observations, ->{where(latest: true).order('obx3_2_obs_ident, test_date_ET desc')} # for the export
  # Add a means of getting a unique list of the names of the profiles's panels
  has_many :obr_order_exemplars,  -> { select('distinct(loinc_num), panel_name').where(latest: true).order('panel_name')}, class_name: 'ObrOrder'
  has_many :date_reminders,  ->{where(latest: true, hide_me: false).order('due_date_ET desc')}
  has_many :hidden_date_reminders,  ->{where(latest: true, hide_me: true).order('due_date_ET desc')}, class_name: 'DateReminder'
  has_many :autosave_tmps, ->{order('form_name, base_rec')}, dependent: :destroy
  has_many :health_reminders, ->{where(latest: true)}, class_name: "HealthReminder", primary_key: "id_shown", foreign_key: "id_shown"
  has_many :share_invitations
  has_many :reminder_options, ->{ where(latest: true) }

  has_one :owner_prof_user, -> {where access_level: ProfilesUser::OWNER_ACCESS}, class_name: 'ProfilesUser'
  has_one :owner, through: :owner_prof_user, :source => :user
  serialize :selected_panels, JSON


  # Returns the most recent ObrOrder of each type.  It also includes the
  # relatednames2 field from the ObrOrder's loinc_items record.
  def latest_obr_orders
    # See http://kristiannielsen.livejournal.com/6745.html which analyzes
    # the efficiency of different options.
    # The final "group by" is to handle the case where there are multiple entries
    # with exactly the same HL7 time.
    join_sql = ActiveRecord::Base.send(:sanitize_sql_array,
      ['o1 inner join '+
      '(select loinc_num, max(test_date_hl7) as test_date_hl7 from obr_orders '+
      'where profile_id=? group by loinc_num) o2 '+
      'on (o1.loinc_num = o2.loinc_num and o1.test_date_hl7 = o2.test_date_hl7)'+
      ' inner join loinc_items on o1.loinc_num = loinc_items.loinc_num '+
      'group by loinc_num', id])
    return ObrOrder.select('o1.*, loinc_items.relatednames2').joins(join_sql).order('o1.panel_name')
  end


  # Returns an identifying string used in constructing routes.
  def to_param
    id_shown # default is id
  end


  validate :create_validation, :on => :create

  def create_validation
    # If the id_shown field is empty, fill it.
    self.id_shown = Profile.make_new_id_string if ! id_shown
  end


  # This makes the "ID" string the user sees in URLs.  We use this in place
  # of the profile_id for security reasons.
  def self.make_new_id_string
    id_upper_bound = 16**16 # e.g., big enough for 16 hexadecimal characters
    s = nil
    loop do
      s = rand(id_upper_bound).to_s(16)
      break if !Profile.find_by_id_shown(s) # no collision
    end
    return s
  end


  # Deletes the profile without deleting the associated data records.
  # This also cleans up the join table with users.
  def soft_delete
    create_deleted
    destroy
  end

  # Creates a corresponding ProfileDelete object and returns.
  # The new object is saved before the delete method on this object is called.
  def create_deleted
    # for now, there is only one user associated with an account.
    DeletedProfile.create!(
      :user_id => self.users[0].id ,
      :profile_id => self.id ,
      :id_shown => self.id_shown ,
      :archived => self.archived,
      :selected_panels => self.selected_panels,
      :created_at => self.created_at,
      :updated_at => self.updated_at)
  end

  # Checks to see if there is any unsaved data for the current profile.
  # This isn't checking to see if there are ANY autosave rows for the profile,
  # just if there are any change records with data in them.
  def has_autosave?
    return AutosaveTmp.have_change_data(self, nil).length > 0
  end


  # Deletes all autosave data - base records and change records - for the
  # current profile
  def delete_autosave
    autosave_tmps.delete_all
  end


  # Returns the code value for level of access the specified user has for this
  # profile.
  #
  # Parameters:
  # * user_id the id of the user to check
  #
  # Returns: access indicator, as defined in ProfilesUser
  #
  def user_access_level(user_id)
    begin
      ret = ProfilesUser.where("user_id = ? AND profile_id = ?",
                               user_id, self.id)[0].access_level
    rescue Exception
      # assume user has no connection to the profile and thus no
      # access_level value.
      ret = nil
    end # begin
    return ret
  end


  # Exports the profile's data.
  #
  # Parameters:
  # * form_name - the form name (phr)
  # * report_format - the code for the report file format.  This should be one
  #   of the codes of the list items in the TextList "file_format_list".
  # * user_id - id of the user requesting the export
  # * file_name - the name for the file being created.  Optional.  If not
  #   supplied, the default file name will be used, which is currently the
  #   pseudonym of the profile.
  #
  # Returns: the file content (as a string) and the name for the file
  #
  def export(form_name, report_format, user_id, file_name=nil)
    # 1 -- csv
    if report_format == '1'
      # Prepare CSV content
     fd = FormData.new(form_name)
     report_string = fd.export_csv(id, user_access_level(user_id))
      file_ext = '.csv'
    # 2 -- excel
    elsif report_format == '2'
      # Prepare Excel content
      #report_string = fd.export_excel(id)
      report_string = export_excel
      file_ext = '.xls'
    # 3 -- pdf.  Not currently used.
#    elsif report_format == '3'
#      # Prepare PDF content
#      fd = FormData.new(form_name)
#      report_string = fd.export_pdf(id)
#      file_ext = '.pdf'
#    end
    elsif report_format == '4'
      # XML format
      file_ext = '.xml'
      report_string = 'This space reserved for XML'
    else
      raise "Unsupported export format '#{report_format}'"
    end
    if !file_name.nil?
      fname = "#{file_name}#{file_ext}"
    else
      fname = "#{self.phr.pseudonym}#{file_ext}"
    end
    return report_string, fname
  end # export


  # Produces an Excel export of the profile's data.  Returns a string
  # containing the excel data.
  def export_excel
    require 'spreadsheet'
    # Load the configuration file.
    config = YAML::load(File.open('config/excel_export.yml'))
    title_config = config['page_title']
    page_hdr_format = Spreadsheet::Format.new :weight=>title_config['weight'],
        :size=>title_config['size']
    header_cfg = config['column_header']
    @header_format = Spreadsheet::Format.new :weight=>header_cfg['weight'],
        :size=>header_cfg['size']
    text_cfg = config['normal_text']
    content_format = Spreadsheet::Format.new  :weight=>text_cfg['weight'],
        :size=>text_cfg['size']

    Spreadsheet.client_encoding = 'UTF-8'
    workbook = Spreadsheet::Workbook.new

    # Load the DbTableDescriptions and DbFieldDescriptions all at once,
    # because we will use most of them.  Likewise, load the associated
    # FieldDescriptions, because in most cases we will need the field label
    # from the FieldDescription.  Build hash structures to hold the objects.
    db_field_desc_ids = []
    @table_to_db_fields = {} # table_name => data_column => DbFieldDescription
    DbTableDescription.all.each do |dbt|
      data_table = dbt.data_table
      dbfs = dbt.db_field_descriptions
      col_name_to_dbf = {}
      dbfs.each do |dbf|
        db_field_desc_ids << dbf.id
        col_name_to_dbf[dbf.data_column] = dbf
      end
      @table_to_db_fields[data_table] = col_name_to_dbf
    end
    fds = FieldDescription.where(db_field_description_id: db_field_desc_ids)
    @fd_labels = {}
    fds.each {|fd| @fd_labels[fd.db_field_description_id] = fd.display_name}

    config['sheets'].each do |sheet_cfg|
      title = sheet_cfg['sheet_title']
      worksheet = workbook.create_worksheet :name=>title
      worksheet.default_format = content_format
      row_num = 0
      sheet_cfg['rows'].each do |row_cfg|
        # Each row_cfg is a hash with one key
        case row_cfg.keys[0]
        when 'blank'
          num_rows = Integer(row_cfg['blank'])
          row_num += num_rows
        when 'text'
          worksheet.row(row_num).replace [row_cfg['text']]
        when 'table'
          table_cfg = row_cfg['table']
          data_table = table_cfg['name']
          # Under no circumstances allow export of the users table to a user.
          # This is for export of one profile's data; trying to export data
          # from users would be dangerous, because we could easily misconfigure
          # and include data for other users. If things are so badly configured,
          # it is better to leave the export broken until we perform a close review.
          raise 'Configuration error (excel_export.yml)' if data_table=='users'
          # As an additional protection, require that data_table be in
          # a white list of allowed tables.  Note that this white list is
          # only for the Excel export, and does not control the CSV export, which
          # relies on the profile data from FormData.
          allowed_tables = Set.new(['obr_orders', 'obx_observations', 'phrs',
            'phr_allergies', 'phr_conditions', 'phr_doctor_questions',
            'phr_drugs', 'phr_immunizations', 'phr_medical_contacts',
            'phr_notes', 'phr_surgical_histories'])
          if !allowed_tables.member?(data_table)
            raise "excel_export.yml:  Table \"#{data_table}\" not allowed"
          end
          data_table_cls = data_table.singularize.camelize.constantize
          if table_cfg['vertical'] # a vertical layout
            row_num = export_excel_vertical_record(worksheet, row_num,
              table_cfg, data_table_cls)
          else
            row_num = export_excel_data_table(worksheet, row_num,
              table_cfg, data_table_cls)
          end
        end
      end
    end

    output = StringIO.new
    workbook.write(output)
    return output.string
  end


  # Sorts an array of arrays.  It is required that all data in a given
  # column be of comparable types (e.g. it won't handle mixtures of strings
  # and numbers.)
  # This is public only because it needed a test.
  #
  # Params:
  # * data - the data to be sorted.  The order of data will be changed by this
  #   call.  (We do not return a copy for efficiency.)
  # * sort_col_nums - controls how to sort the arrays.  The column numbers
  #   start at 1 (for the first element in the array), rather than 0.
  #   The first column number in sort_col_nums will
  #   be the primary column on which the sort is performed, and then within
  #   equal elements in that sort, the  arrays will be sorted according to
  #   the second column number, and so on.  A negative column number means to
  #   sort in reverse (which is why we don't start at 0.)
  def self.multi_column_sort(data, sort_col_nums)
    sort_indices = sort_col_nums.map{|i| i.abs - 1}
    data.sort! do |a,b|
      sort_result = 0
      sort_indices.each_with_index do |sort_index, i|
        if sort_col_nums[i] > 0
          sort_result = a[sort_index] <=> b[sort_index]
        else # sort in reverse order
          sort_result = b[sort_index] <=> a[sort_index]
        end
        raise "It looks like data on column #{sort_col_nums[i].abs} are not all "+
              "of the same type-- check '#{a[sort_index]}' and "+
              "'#{b[sort_index]}'" if sort_result.nil?
        break if sort_result != 0
      end
      sort_result
    end
  end

  private

  # Used by export_excel to process a table record that will be displayed
  # "vertically", with one field per row.  It is assumed that there is just
  # one record per profile in cases where you would want a vertical output.
  #
  # Parameters:
  # * worksheet - The worksheet being written
  # * row_num - the starting row number for new output in the worksheet
  # * table_cfg - the configuration data for the table.  (See a "table" section
  #   of the excel_export.yml file).
  # * data_table_cls - the Ruby model class for the data table containing
  #   the record to be output.
  #
  # Returns: the next available row number in the worksheet
  def export_excel_vertical_record(worksheet, row_num, table_cfg,
       data_table_cls)
    data_table = data_table_cls.table_name
    field_name_to_dbf = @table_to_db_fields[data_table]
    # For a vertical layout, we assume there is just one record.
    rec = self.send(data_table.singularize)
    max_width = 0
    max_label_length = 0
    field_name_to_label = {}
    field_val = ''
    fields = table_cfg['fields']
    fields.each do |field_cfg|
      # Each field_cfg is a hash with one key, the field name.
      field_name = field_cfg.keys[0]
      field_opts = field_cfg[field_name]

      db_fd = field_name_to_dbf[field_name]
      if rec
        field_val = db_fd ? db_fd.get_field_current_value(rec) :
                          rec.send(field_name)
        field_val = '' if field_val.blank?
      end
      field_label = get_field_label(field_name, field_opts, field_name_to_label,
                                    data_table)
      if field_label.length > max_label_length
        max_label_length = field_label.length
      end
      row = worksheet.row(row_num)
      row.replace [field_label, field_name, field_val]
      row.set_format(0, @header_format) # make the labels look like headers
      width = field_opts['width']
      if width == 0  # hide the row
        worksheet.row(row_num).hidden = true
      elsif width and width > max_width
        max_width = width
      end
      row_num += 1
    end

    # Set column widths
    if max_label_length > 0
      worksheet.column(0).width = max_label_length
    end
    worksheet.column(1).hidden = true # has data column names
    worksheet.column(2).width = max_width if max_width > 0
    return row_num
  end


  # Used by excel_export to output a table of records (horizontally,
  # with column headers).
  #
  # Parameters:
  # * worksheet - The worksheet being written
  # * row_num - the starting row number for new output in the worksheet
  # * table_cfg - the configuration data for the table.  (See a "table" section
  #   of the excel_export.yml file).
  # * data_table_cls - the Ruby model class for the data table containing
  #   the record to be output.
  #
  # Returns: the next available row number in the worksheet
  def export_excel_data_table(worksheet, row_num, table_cfg, data_table_cls)
    data_table = data_table_cls.table_name
    field_name_to_dbf = @table_to_db_fields[data_table]
    recs = self.send(data_table)
    # Find field labels, set column widths, and collect field values.
    recs_values = []
    field_labels = [''] # start data values in the 2nd column
    field_names = ['Field names (ignore this row)']
    field_name_to_label = {}
    skip_rows = [] # rows that are filtered out with the "filter" configuration
    fields = table_cfg['fields']
    fields.each_with_index do |field_cfg, field_index|
      # Each field_cfg is a hash with one key, the field name.
      field_name = field_cfg.keys[0]
      field_names << field_name
      field_opts = field_cfg[field_name]
      field_labels << get_field_label(field_name, field_opts,
                                      field_name_to_label, data_table)
      set_column_options(worksheet, field_index+1, field_opts)

      filter_val = field_opts['filter']
      db_fd = field_name_to_dbf[field_name]
      recs.each_with_index do |rec, i|
        one_rec_vals = recs_values[i]
        if !one_rec_vals
          one_rec_vals = []
          recs_values[i] = one_rec_vals
        end
        # obr/obx does not get latest value through db_field_descriptions table
        # for now it only gets user saved data from obx_observations table
        if data_table == OBX_TABLE
          field_val = rec.send(field_name)
        else
          field_val = db_fd ? db_fd.get_field_current_value(rec) :
              rec.send(field_name)
        end
        if filter_val &&
           (field_val == filter_val || field_val.nil? && filter_val == 'nil')
          # skip this row
          skip_rows << i
        else
          one_rec_vals << prepare_value_for_spreadsheet(field_val)
        end
      end
    end

    # Delete any rows in skip_rows
    skip_rows.reverse.each {|i| recs_values.delete_at(i)}

    # Sort, if requested.
    sort_col_nums = table_cfg['sort']
    self.class.multi_column_sort(recs_values, sort_col_nums) if sort_col_nums

    # Shift the data values to start in the second column.
    recs_values.each {|row| row.unshift('')}

    # Now write out the rows
    # Before the data, output a hidden row containing the field names.
    # We put this after the column labels to keep from messing up the default
    # behavior of Excel's sort function.
    label_row = worksheet.row(row_num)
    label_row.replace field_labels
    label_row.default_format = @header_format
    row_num += 1
    label_row = worksheet.row(row_num)
    label_row.replace field_names
    label_row.hidden = true
    row_num += 1

    recs_values.each do |row_vals|
      worksheet.row(row_num).replace row_vals
      row_num += 1
    end

    return row_num
  end


  # For the Excel export of a data table, this sets options on a column based on
  # a field's configuration in the excel_export.yml file.
  #
  # Parameters:
  # * worksheet - the worksheet being built (an instance of the Spreadsheet
  #   gem's Worksheet class)
  # * col_num - the column number whose format is being set
  # * field_opts - the configuration options for the field
  def set_column_options(worksheet, col_num, field_opts)
    width = field_opts['width']
    col_hidden = false
    if width
      if width == 0
        worksheet.column(col_num).hidden = true
        col_hidden = true
      else
        worksheet.column(col_num).width = width
      end
    end

    # Wrap columns that are not hidden.
    format_opts = {}
    format_opts[:text_wrap] = true if !col_hidden

    # Set alignment
    horizontal_align = field_opts['horizontal_align']
    if horizontal_align
      format_opts[:horizontal_align] = horizontal_align.to_sym
    end

    worksheet.column(col_num).default_format = Spreadsheet::Format.new(
      format_opts)
  end


  # Prepares a field value for inclusion in the row data of an Excel
  # spreadsheet.  (For example, it makes sure nil values are replaced with
  # empty strings.)
  #
  # Parameters:
  # * field_val the value to be prepared
  #
  # Returns:  the prepared value
  def prepare_value_for_spreadsheet(field_val)
    if !field_val
      field_val = ''
    elsif field_val.is_a?(String)
      if Util.integer?(field_val)
        field_val = Integer(field_val)
      elsif Util.float?(field_val)
        field_val = Float(field_val)
      end
    end
    return field_val
  end


  # Returns a field label for the given field name, and updates the given
  # field_name_to_label hash with the return value.
  #
  # Parameters:
  # * field_name - the name of the field for which a label is needed
  # * field_opts - the configuration options for the field as specified
  #   in the excel_export.yml file.
  # * field_name_to_label - a hash from field names to previously returned
  #   labels.
  # * db_table_desc - the DbTableDescription record for the table whose fields'
  #   labels are being computed.
  def get_field_label(field_name, field_opts, field_name_to_label, data_table)
    field_label = field_opts['label']
    if field_label.blank?
      # See if it is associated with another field.
      if field_name =~ /(.*)(_C|_ET|_HL7)\Z/
        associated_field_label = field_name_to_label[$1]
        if associated_field_label
          case $2  # $2 is the suffix
          when '_C'
            field_label = associated_field_label + ' code'
          when '_ET'
            field_label = associated_field_label + ' (epoch time)'
          when '_HL7'
            field_label = associated_field_label + ' (HL7 format)'
          end
        end
      else
        # Get the field label by finding the field_description that
        # uses the db_field_description for this data field.
        db_field_desc = @table_to_db_fields[data_table][field_name]
        if db_field_desc
          fd = db_field_desc.field_descriptions[0] # pick the first
          field_label = fd ? fd.display_name : db_field_desc.display_name
          # Remove any trailing asterisks.
          field_label.chop! if field_label && field_label[-1..-1] == '*'
        end
      end
      field_label = field_name if field_label.blank?
    end
    # Make the first letter of each word upper case.  titleize doesn't work
    # for labels like "RxNorm Code".
    field_label = field_label.gsub(/(^| )([a-z])/) {|m| $1+$2.upcase}
    # Replace _ with space
    field_label = field_label.gsub(/_/, ' ')
    field_name_to_label[field_name] = field_label
    return field_label
  end
end
