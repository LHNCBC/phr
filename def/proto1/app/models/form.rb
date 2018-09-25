class Form < ActiveRecord::Base
  extend HasShortList

  has_and_belongs_to_many :rules, -> { order "rule_id desc" }, join_table: 'rules_forms'
  has_and_belongs_to_many :rule_sets, -> { order 'rule_set_id'}
  has_many :field_descriptions, -> { order('display_order').includes(:predefined_field) },
    dependent: :destroy
  has_many :top_fields, -> { where('field_descriptions.group_header_id IS NULL').order('display_order').includes(:predefined_field) },
    :class_name=>'FieldDescription'
  has_many :visible_fields, -> { where('control_type_detail not like "%hidden_field%"').order('display_order').includes(:predefined_field)}, class_name: 'FieldDescription'
  serialize :form_js, JSON
  validates_uniqueness_of :form_name, :case_sensitive=>false
  validates_presence_of :form_name

  before_destroy :remove_orphan_rules

  # Removes all orphan rules resulting from form deletion
  def remove_orphan_rules
    rules.select{|r| r.forms.size == 1}.map(&:destroy)
  end

  # gets all fields for this form.  (Note:  This is now a duplicate
  # of the field_descriptions call provided by has_many.  TBD- remove.)
  alias_method :fields, :field_descriptions

  # A cache of form names to forms.
  @@form_name_to_form = ActiveRecordCacheMgr.create_cache('form_name_to_form',
    Proc.new{|form_name| Form.where("UPPER(form_name) = ?", form_name).take })

  # The cache of association information between forms and subforms
  @@subform_association_cache = nil

  # A cache of all form specific CSS files
  @@form_css_files = nil

  # Returns the form with the given form name.
  # This function hides sensitivity of form_name, which might come in request URL
  # and is unpredictable. (Oracle is case sensitive.)
  def self.find_by_form_name(form_name)
    form_name = form_name.upcase
    return @@form_name_to_form[form_name] # loads the form instance if missing
  end


  # Retrieves all the date fields for a given form.
  #
  # Returns an array of target field names for the date fields.
  def retrieve_date_fields
    # Note:  This method was moved here from form_controller.rb.
    # (It was originally named retrieveDateFields.)
    date_fields = Array.new
    fields = field_descriptions.where({control_type: 'calendar'})
    if fields
      fields.each do |f|
        date_fields.push(f.target_field)
      end
    end
    date_fields
  end


  # Returns the rules used by this form.  The rules are returned in the order
  # they need to be run.
  def sorted_rules
    directly_used_rules = rules
    Rule.complete_rule_list(directly_used_rules)
  end


  # Used by HasShortList.getListItems to get the instances whose form_type matches
  # "name".
  def self.get_named_list_items(name = nil)
    name.nil? ? self.all : self.where(form_type: name)
  end


  # Returns a list of fields that belong to subforms of the main form.  For
  # example, this will include test panel fields for the PHR form.
  #
  # Parameters:
  # * conditions - any SQL conditions to be applied to the find statement for
  #   the field descriptions, or nil if none are needed
  # * order - a SQL order by statement to be applied to the find statement for
  #   the field descriptions, or nil if none is needed.
  #
  def foreign_fields(conditions, order)
    if !conditions.nil?
      conds_clause = ' AND ' + conditions
    else
      conds_clause = ''
    end
    ret = []
    if !foreign_form_ids.nil?
      foreign_form_ids.each do |fmid|
        conds_clause = 'form_id = ' + fmid.to_s + conds_clause
        if !order.nil?
          ret = ret + FieldDescription.where(conds_clause).order(order)
        else
          ret = ret + FieldDescription.where(conds_clause)
        end
      end
    end
    return ret
  end


  # Returns a list of fields which belong to forms including the main form;
  # includes rule any rule objects
  def foreign_fields_with_rules
    return FieldDescription.includes(:rules).where({form_id: foreign_form_ids})
  end


  # Returns IDs of forms which should be loaded into this main form
  def foreign_form_ids
    uses_forms.map(&:id)
  end


  # Returns the subform association cache if exists. Otherwise popuplates the
  # cache and returns it
  def self.subform_association_cache
    if !@@subform_association_cache || Rails.env == "test"
      form_to_subforms = {}
      subform_to_forms = {}
      subform_cts = FieldDescription::SUBFORM_CONTROL_TYPES
      FieldDescription.where({control_type: subform_cts}).each do |fld|
        # Some fields have no form associated with them (e.g. the field with
        # form_id -7)
        if fld.form
          subform_name = fld.get_subform_name
          form_name = fld.form.form_name
          subform_names = form_to_subforms[form_name] ||= []
          subform_names << subform_name unless subform_names.include? subform_name
          form_names = subform_to_forms[subform_name] ||= []
          form_names << form_name unless form_names.include? form_name
        end
      end
      @@subform_association_cache ={:form_to_subforms => form_to_subforms,
        :subform_to_forms => subform_to_forms}

    end
    # Keep the following line for debugging purpose
    #puts @@subform_association_cache.inspect
    @@subform_association_cache
  end


  # Resets the subform acssociation cache
  def self.reset_subform_association_cache
    @@subform_association_cache = nil
  end


  # Returns list of forms which are using this form
  def used_by_forms
    subform_to_forms = Form.subform_association_cache[:subform_to_forms]
    parent_forms = subform_to_forms[form_name]
    parent_forms ? Form.where({form_name: parent_forms}) :  []
  end


  # Returns list of forms this form is using
  def uses_forms
    form_to_subforms = Form.subform_association_cache[:form_to_subforms]
    subforms = form_to_subforms[form_name]
    subforms ? Form.where({form_name: subforms}) : []
  end


  # Returns a hash from target field to label name information for all the data
  # fields on the main form and any form embedded on the main form
  def data_field_labelnames
    res={}
    foreign_fields_ary = FieldDescription.where({form_id: foreign_form_ids})
    (fields + foreign_fields_ary).each do |fd|
      non_data_field_types =%w(button group_hdr expcol_button image check_box_display)
      if !(non_data_field_types.include?(fd.control_type) || fd.hidden_field? )
        res[fd.target_field] = fd.label_name_and_path
      end
    end
    res
  end

  # Returns a CSV formatted data string for the help and instruction text
  # associated with this form's fields.  This method returns the minimal
  # amount of information needed by someone editing the help and instruction
  # text.  It also returns the default values of fields, because some on-form
  # help is in static_text fields, which use the default value as the location
  # of the text.  The columns returned are the record id,
  # display_name, the group header name ('Section Name'), help_text,
  # instructions, and default_value.
  #
  # Note:  The first line of the output contains the table name for the forms
  # fields.  This should be left alone if the file is to be submitted
  # through the data controller.
  def help_text_csv_dump
    output = CSV.generate do |csv|
      csv << ['Table', 'field_descriptions', 'Form', form_name,
        '(Do not edit or remove this line.)']
      # Output the header row
      col_names = ['id', 'display_name', 'Section Name', 'control_type',
                   'help_text', 'instructions', 'default_value',
                   'width', 'min_width', 'tooltip']
      csv << col_names

      # Now output each record
      field_descriptions.each do |rec|
        row_data = []
        col_names.each do |cn|
          if cn=='Section Name' # group header name
            if rec.group_header_id
              gh = FieldDescription.find_by_id(rec.group_header_id)
              row_data << gh.display_name
            else
              row_data << ''
            end
          else
            row_data << rec.send(cn)
          end
        end # each column
        csv << row_data
      end # each record
    end # csv construction

    return output
  end

  # Updates the help text, instructions, display_name, and (for static_text
  # only) the default values of the field descriptions described by the given
  # CSV string.
  #
  # Parameters:
  # * csv_string - the string containing the CSV data.
  # * user_id - the ID of the user doing the update
  def help_text_csv_update(csv_string, user_id)
    update_data = CSV.parse(csv_string)
    help_text_parsed_csv_update(update_data, user_id)
  end


  # This is like help_text_csv_update (see that for details) except that
  # it takes parsed CSV data instead of a CSV string.
  #
  # Parameters:
  # * update_data - the parsed CSV data in the format returned by
  #   CSV.parse.
  # * user_id - the ID of the user doing the update
  def help_text_parsed_csv_update(update_data, user_id)
    backup_file = FieldDescription.make_table_backup
    id_index = nil
    help_index = nil
    instruction_index = nil
    default_value_index = nil
    display_name_index = nil
    width_index = nil
    min_width_index = nil
    tooltip_index = nil
    update_data.each do |row|
      if (!id_index)
        row.each_with_index do |col_name, i|
          if col_name=='id'
            id_index = i
          elsif col_name == 'help_text'
            help_index = i
          elsif col_name == 'instructions'
            instruction_index = i
          elsif col_name == 'display_name'
            display_name_index = i
          elsif col_name == 'default_value'
            default_value_index = i
          elsif col_name == 'width'
            width_index = i
          elsif col_name == 'min_width'
            min_width_index = i
          elsif col_name == 'tooltip'
            tooltip_index = i
          end
        end
        if !id_index || !help_index || !instruction_index ||
            !display_name_index || !width_index || !min_width_index || !tooltip_index
          raise 'The CSV file must contain the columns "id", "help_text", '+
            '"display_name", "instructions", "width", "min_width", and "tooltip".'
        end
      else
        fd = field_descriptions.find_by_id(row[id_index])
        if !fd
          raise "No field description with id #{row[id_index]} found in form"+
            " #{form_name}"
        end
        fd.help_text = row[help_index]
        fd.instructions = row[instruction_index]
        fd.display_name = row[display_name_index]
        fd.width = row[width_index]
        fd.min_width = row[min_width_index]
        if default_value_index && fd.control_type == 'static_text'
          fd.default_value = row[default_value_index]
        end
        if row[tooltip_index].blank?
          fd.remove_param('tooltip')
        else
          fd.update_controls('tooltip', row[tooltip_index])
          fd.rewrite_ctd
        end
        fd.save!
      end
    end

    # Create a DataEdit record to record the edit
    DataEdit.create(:user_id=>user_id, :data_table=>self.class.table_name,
      :backup_file=>backup_file)
  end

  # Returns true if there is a reminder button on the form and vice versa
  def show_reminders?
    !fields.select{|e| e.target_field == "reminders"}.empty?
  end


  # Creates (and returns) a FieldDescription for a field with the given field
  # type and adds it to this form.  By default, the control type is just a plain
  # text field.
  #
  # Parameters:
  # * target_field - the "target field" name for the field (a single-word
  #   identifier which should be unique within the form's field_descriptions.
  # * display_name - the label for the field
  # * display_order - a number for ordering the field's position relative
  #   to other fields in the same group
  # * field_type - the field type of the field.  This should match one of the
  #   field types in the predefined_fields table.
  # * field_group - the "group header" field description for the field group
  #   to which this field should be added.  (This is optional.)
  # * other - an optional hash of other attribute values for this
  #   FieldDescription.
  def add_field(target_field, display_name, display_order, field_type,
                field_group=nil, other={})
    pf = PredefinedField.find_by_field_type(field_type)
    group_id = field_group ? field_group.id : nil
    fd = FieldDescription.create({:target_field=>target_field,
      :display_name=>display_name, :predefined_field_id=>pf.id,
      :display_order=>display_order, :form_id=>self.id,
      :control_type=>'text_field', :group_header_id=>group_id}.merge(other))
    self.field_descriptions << fd
    fd.save!
    return fd
  end


  # Adds a horizontal field group to the form.
  #
  # Parameters:
  # * target_field - the "target field" name for the field (a single-word
  #   identifier which should be unique within the form's field_descriptions.
  # * display_name - the label for the field
  # * display_order - a number for ordering the field's position relative
  #   to other fields in the same group
  # * db_rec_id - the DbFieldDescription record for the record_id field
  #   in the user data table.  record_id fields are required when a profile
  #   can have more than one record in the table.  If you use
  #   DbTableDescription.create_multi_rec_table to create the DbTableDescriptoin
  #   for this group, it will create db_rec_id for you.
  # * cet - true if this is to be a controlled-edit table
  # * cet_fields - if cet is true, this should be the list of fields that can
  #   be edited after a record is saved.  The format is a string (not an array)
  #   of the target_field names separated by commas (without a space after the
  #   comma).
  def add_horizontal_field_group(target_field, display_name, display_order,
       db_rec_id, cet=false, cet_fields=nil)
    group = field_descriptions.create!(:display_order=>display_order,
      :display_name=>display_name, :target_field=>target_field,
      :control_type=>'group_hdr', :predefined_field_id=>24,
      :control_type_detail=>{'open'=>'1', 'orientation'=>'horizontal'},
      :controlled_edit=>cet, :edit_allowed_fields=>cet_fields)
    # Also create the record_id field, which is needed for tables which can
    # have multiple records.
    add_record_id_field(group.target_field, display_order+1,
      {:db_field_description_id=>db_rec_id.id})
    return group
  end

  # Creates (and returns) a FieldDescription for a string field and adds it to
  # this form.
  #
  # Parameters:
  # * target_field - the "target field" name for the field (a single-word
  #   identifier which should be unique within the form's field_descriptions.
  # * display_name - the label for the field
  # * display_order - a number for ordering the field's position relative
  #   to other fields in the same group
  # * field_group - the "group header" field description for the field group
  #   to which this field should be added.  (This is optional.)
  # * other - an optional hash of other attribute values for this
  #   FieldDescription.
  def add_string_field(target_field, display_name, display_order,
      field_group=nil, other={})
    add_field(target_field, display_name, display_order, 'ST - string data',
      field_group, other)
  end


  # Creates (and returns) a FieldDescription for a time field and adds it to
  # this form.
  #
  # Parameters:
  # * target_field - the "target field" name for the field (a single-word
  #   identifier which should be unique within the form's field_descriptions.
  # * display_name - the label for the field
  # * display_order - a number for ordering the field's position relative
  #   to other fields in the same group
  # * field_group - the "group header" field description for the field group
  #   to which this field should be added.  (This is optional.)
  # * other - an optional hash of other attribute values for this
  #   FieldDescription.
  def add_time_field(target_field, display_name, display_order, field_group=nil,
                    other={})
    attrs = {:control_type=>'time_field'}.merge(other)

    # Add the "time" class
    time_class = 'time'
    ctd_hash = attrs[:control_type_detail]
    if !ctd_hash
      attrs[:control_type_detail] = {'class'=>[time_class]}
    elsif !ctd_hash['class']
      ctd_hash['class'] = [time_class]
    else
      ctd_hash['class'] << time_class
    end

    add_field(target_field, display_name, display_order, 'ST - string data',
      field_group, attrs)
  end


  # Creates and returns a static text field (FieldDescription) for this form.
  #
  # Parameters:
  # * target_field - the "target field" name for the field (a single-word
  #   identifier which should be unique within the form's field_descriptions.
  # * display_order - a number for ordering the field's position relative
  #   to other fields in the same group
  # * text - the content for the static text field.
  # * field_group - the "group header" field description for the field group
  #   to which this field should be added.  (This is optional.)
  # * display_name - a label for the text (optional).
  def add_static_text(target_field, display_order, text, field_group=nil,
    display_name=nil)
    add_field(target_field, display_name, display_order, 'Label/Display Only',
     field_group, :control_type=>'static_text', :default_value=>text)
  end


  # Adds a field for a record ID for a table.
  #
  # Parameters:
  # * table_target_field - the target_field name of the horizontal field group
  #   containing the table to which the record ID field needs to be added.
  # * display_order - a number for ordering the field's position relative
  #   to other fields in the same group.  (It should be the first in the row.)
  # * other - an optional hash of other attribute values for this
  #   FieldDescription.
  def add_record_id_field(table_target_field, display_order, other={})
    table_field = FieldDescription.find_by_form_id_and_target_field(self.id,
      table_target_field)
    target_field = table_target_field.singularize + '_id'
    add_field(target_field, 'record id', display_order, 'Integer', table_field,
      {:control_type_detail=>{'class'=>['hidden_field']}}.merge(other))
  end


  # Creates (and returns) the three FieldDescriptions for a date field (the user
  # readable field, the epoch time field, and the HL7 field) and adds them to
  # this form.
  #
  # Parameters:
  # * target_field - the "target field" name for the field (a single-word
  #   identifier which should be unique within the form's field_descriptions.
  # * display_name - the label for the field
  # * display_order - a number for ordering the field's position relative
  #   to other fields in the same group
  # * day_req - whether the day of the month is required
  # * month_req - whether the month is required (assumed true if day_req)
  # * field_group - the "group header" field description for the field group
  #   to which this field should be added.  (This is optional.)
  # * other - an optional hash of other attribute values for this
  #   FieldDescription.
  def add_date_field(target_field, display_name, display_order, day_req,
      month_req=true, field_group=nil, other={})
    if day_req
      format = 'YYYY/MM/DD'
    elsif month_req
      format = 'YYYY/MM/[DD]'
    else
      format = 'YYYY/[MM/[DD]]'
    end
    user_field = add_field(target_field, display_name, display_order,
       'DT - date', field_group, {:control_type=>'calendar',
       :control_type_detail=>
         {'date_format'=>format,'tooltip'=>format,'calendar'=>'true'},
       :width=>'6.8em'
      }.merge(other))
    hidden_other = other.merge(:control_type_detail=>{'class'=>['hidden_field']})
    et_field =
      add_field(target_field+'_ET', nil, display_order, 'Integer', field_group,
        hidden_other)
    hl7_field = add_string_field(target_field+'_HL7', nil, display_order,
      field_group, hidden_other)
    return user_field, et_field, hl7_field
  end


  # Return form specific styles and form specific print styles in two
  # separate lists
  def get_styles_by_form
    form_styles, print_styles = [ ], [ ]

    if @@form_css_files.nil?
      @@form_css_files = Set.new
      form_css_dir = Rails.root.join('app/assets/stylesheets', FORM_CSS_DIR)
      if File.exist?(form_css_dir)
        files = Dir.entries(form_css_dir)
        files = files.map{|e| e.split(".")[0] }
        @@form_css_files.merge(files) if !files.empty?
      end
    end

    form_name_downcase = form_name && form_name.downcase
    # get form styles
    if (!form_style.blank?)
      form_style.split(/,/).each do |style|
        if @@form_css_files.include?(style)
          form_styles << "#{FORM_CSS_DIR}/#{style}.css"
        end
      end
    else
      style = form_name_downcase
      if @@form_css_files.include?(style)
        form_styles << "#{FORM_CSS_DIR}/#{style}.css"
      end
    end
    # define css file name for print in the format: form_name + "-print.css"
    # for now, there's only one print style for each form
    style = form_name_downcase+"-print"
    if @@form_css_files.include?(style)
      print_styles << "#{FORM_CSS_DIR}/#{style}.css"
    end
    [form_styles, print_styles]
  end


#  # list of db_table_descriptions for form to store it's data
#  def data_tables
#    fields.map(&:db_field_description).compact.map(&:db_table_description).compact.uniq
#  end
#
#  # Returns data rules required by this form. Reminder rules will be excluded
#  # only if this form does not have reminder button of target field "reminders"
#  def required_data_rules
#    table_ids = data_tables.map(&:id)
#    fetch_rules = RuleFetch.where({source_table_C: table_ids}).map(&:rule)
#    Rule.complete_rule_list(fetch_rules).delete_if do |e|
#      e.is_reminder_rule && !show_reminders?
#    end
#  end
end

