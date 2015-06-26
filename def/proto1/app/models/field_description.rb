class FieldDescription < ActiveRecord::Base
  belongs_to :regex_validator
  belongs_to :predefined_field
  belongs_to :form
  belongs_to :db_field_description
  has_and_belongs_to_many :rules, join_table: 'rule_field_dependencies',
    :association_foreign_key=>'used_by_rule_id'
  has_many :sub_fields, -> { where('form_id!=-1').order("display_order") },
    class_name: "FieldDescription", foreign_key: "group_header_id"
  belongs_to :group_header, class_name: "FieldDescription", foreign_key: "group_header_id"
  alias_method :subFields, :sub_fields # TBD - remove uses of subFields
  has_many :loinc_field_rules, dependent: :destroy
  delegate :is_date_type, :to => :predefined_field
  serialize :controlled_edit_menu
  serialize :controlled_edit_actions
  serialize :radio_group_param
  serialize :control_type_detail
  serialize :data_req_output

  validates_uniqueness_of :target_field, :scope=>:form_id,
    :if => Proc.new {|fd| fd.form_id != -1}

  # Classes that are in our control_type_detail that are not cloneable.
  NOT_CLONEABLE = Set.new([Fixnum, TrueClass, FalseClass])

  # Control types for which field_default_value should not return default_value.
  NON_DEFAULT_CONTROL_TYPES = Set.new(['static_text',
      'big_static_text', 'panel_view', 'panel_edit'])

  # Control types for the fields which have subforms
  SUBFORM_CONTROL_TYPES = %w(test_panel loinc_panel)

  # Keys which are mapping to the subform names
  SUBFORM_KEYS = %w(panel_name)

  def validate
    if target_field.nil?
      errors.add(:target_field, 'Missing target_field value.  This value is ' +
          'used as the identifier for the row, and so is required.')
    end
    if control_type.nil?
      errors.add(:control_type, 'Missing control_type value.  This value is ' +
          'required.')
    end

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
            target_field.to_s + '.  This is no longer valid.')
      end
    elsif read_attribute('field_type').nil?
      write_attribute('field_type', predefined_field.field_type)
    end

    # Let's omit this, at least for now.  It was used by the form builder,
    # but things have changed so much that I suspect it will have to be
    # redesigned if/when we ever get back to the form builder.
    #if !control_type_detail.nil? &&
    #    control_type_detail.include?('search_table') &&
    #    (control_type_detail.include?('list_name') ||
    #     control_type_detail.include?('list_id')) &&
    #    !control_type_detail.include?('list_details_id')
    #  errors.add(:control_type_detail, 'A list_details_id parameter is ' +
    #    'now required for all list fields where the list has a name or id.')
    #end

    # For search fields, populate the value of list_code_column, so that
    # we don't have to determine its value on the fly during an AJAX
    # request.  Also do this for text_fields that are lists.
    if list_code_column.blank? && (control_type=='search_field' ||
        control_type=='text_field' && getParam('search_table'))
      errors.add(:list_code_column, 'is required for this type of field')
    end

    # target_field should not conflict with existing rule names
    rule_names = (form && form.rules.map(&:name)) || []
    rule_names += Rule.data_rules.map(&:name)
    if rule_names.include?(target_field)
      errors.add(:target_field, "must not conflict with rule name")
    end
  end

  def before_save
    # If the field to be saved is a subform field, then reset subform
    # association cache
    if FieldDescription::SUBFORM_CONTROL_TYPES.include?(self.control_type)
      Form.reset_subform_association_cache
    end
  end


  # A cache of control types and form IDs to field descriptions.
  @@control_type_and_form_id_to_form =
    ActiveRecordCacheMgr.create_cache('control_type_and_form_id_to_form')

  # A method that caches the return value of the Rails-supplied
  # find_all_by_control_type_and_form_id.
  def self.find_all_by_control_type_and_form_id(type, form_id)
    type_hash = @@control_type_and_form_id_to_form[form_id]
    @@control_type_and_form_id_to_form[form_id] = type_hash={} if !type_hash
    rtn = type_hash[type]
    if !rtn
      rtn = where(:control_type=>type, :form_id=>form_id).load
      type_hash[type] = rtn
    end
    return rtn
  end

  # Returns the value of the help_text field.  If the field is a URL,
  # and the view mode parameter is speficified (e.g. for Basic HTML mode), and
  # if a specialized help file for that mode exists, the URL will be altered
  # to point to that file.
  #
  # Parameters:
  # * view_mode - (optional) This may be the name of the view mode.  If not
  #   supplied, the default viewing mode will be assumed.  The only value
  #   we're using here at present is "basic", but others would work.
  def help_text(view_mode = nil)
#    field_val = super # call super will result in an wrong argument error
    field_val = self.read_attribute("help_text")
    if view_mode && field_val && field_val.index(HelpText::REL_HELP_DIR_SLASH) == 0
      help_file = field_val.slice(HelpText::REL_HELP_DIR_SLASH.length..-1)
      view_mode_file = "#{view_mode}_#{help_file}"
      if File.exists? File.join(HelpText::HELP_DIR, view_mode_file)
        field_val = HelpText::REL_HELP_DIR_SLASH + view_mode_file
      end
    end
    return field_val
  end


  # returns a consistent value to be used as an ID attribute for an
  # input field
  def field_id
    'fe_' + target_field
  end


  # Returns the list of fields (in this field's data table) to be searched,
  # as a list of symbols
  def fields_searched
    if (@fields_searched.nil?)
      @fields_searched = make_symbol_array(getParam('fields_searched'))
    end
    @fields_searched
  end


  # Returns the list of fields (in this field's data table) to be returned,
  # as a list of symbols.  (This only applies to AJAX list fields
  # (control_type="search_field"), and actually, we aren't using it there
  # either.  But, we could....)
  def fields_returned
    if (@fields_returned.nil?)
      @fields_returned = make_symbol_array(getParam('fields_returned'))
    end
    @fields_returned
  end


  # Returns the list of fields  (in this field's data table) to be displayed,
  # as a list of symbols
  def fields_displayed
    if (@fields_displayed.nil?)
      @fields_displayed = make_symbol_array(getParam('fields_displayed'))
    end
    @fields_displayed
  end

  # Returns the rules that depend on the value of this field, or that depend on
  # those rules, etc.  The rules are returned in the order they need to be
  # run.
  def sorted_rules
    # Pull the rules from the database that are directly affected by this field.
    field_rules = rules

    # Find the dependent rules, and sort them all together.
    Rule.complete_rule_list(field_rules)
  end


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


  # Sets the field type
  #
  # Parameters:
  # * new_field_type the new field type for the field.  The value should match
  #   a value in the field_type column of the predefined_fields table.
  def field_type=(new_field_type)
    pf = PredefinedField.find_by_field_type(new_field_type)
    raise 'Invalid field type' if !pf
    predefined_field = pf
    write_attribute(:field_type, new_field_type)
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

  # This is meant to contain the hash map of parameters after they're
  # retrieved from the control_field_details column of the field
  # description row (once).
  @fldParams = nil


  # Clears the cached control_type_detail parameters when control_type_detail
  # changes.
  #
  # Parameters:
  # * new_val - the new value
  def control_type_detail=(new_val)
    @fldParams = nil
    write_attribute('control_type_detail', new_val)
  end


  # Gets a parameter from the control_type_detail hash map.  Values can
  # be a string, an array of strings (the ones enclosed in parentheses), or a
  # hash map of string key/value pairs (the ones enclosed in braces).
  #
  # Parameters:
  # * pName - name of the parameter that you want
  # * mustHave - indicates whether or not an exception should be
  #   shown if the parameter is not found in the map
  #
  def getParam(pName, mustHave=false)
    if (@fldParams.nil?)
      @fldParams = controls_hash
    end
    if (!@fldParams[pName].nil?)
      rtn = @fldParams[pName]
      rtn = rtn.clone if !NOT_CLONEABLE.member?(rtn.class)
      return rtn
    elsif (mustHave)
      raise pName + ' was not found in the parameters loaded from the ' +
        'control_type_details field'
    else
      return nil
    end
  end

  # Gets a parameter from the editor_params hash map.  Values can
  # be a string, an array of strings (the ones enclosed in parentheses), or a
  # hash map of string key/value pairs (the ones enclosed in braces).
  #
  # Parameters:
  # * pName - name of the parameter that you want
  # * mustHave - indicates whether or not an exception should be
  #   shown if the parameter is not found in the map
  #
  def getEditorParam(pName, mustHave=false)
    editorParams = FieldDescription.parse_hash_value(editor_params)
    if (!editorParams[pName].nil?)
      return editorParams[pName]
    elsif (mustHave)
      raise pName + ' was not found in the parameters loaded from the ' +
        'control_type_details field'
    else
      return nil
    end
  end

  # Get the field's parent field if it is within a group
  #
  # Parameters:  none
  # Return: an object of the parent field
  #
  def parent_field
    p_field = nil
    if !group_header_id.blank?
      p_field = FieldDescription.find_by_id(group_header_id)
    end
    return p_field
  end

  # Updates the fldParams hash map - used to update control info
  # based on dependencies specified for a field
  def update_controls(pName, value)
    if (@fldParams.nil?)
      @fldParams = controls_hash
    end
    @fldParams[pName] = value
  end # update_controls


  # Removes a parameter from the control_type_detail field and from
  # the @fldParams hash - if it's there to be removed
  #
  # Parameters:
  # * pName name of the paramter to be removed
  #
  # Returns: nothing, but the @fldParams object should be updated as
  # well as the control_type_detail field of the current object
  #
  def remove_param(pName)
    if (@fldParams.nil?)
      @fldParams = controls_hash
    end
    pVal = @fldParams[pName]
    if !pVal.nil?
      @fldParams.delete(pName)
      rewrite_ctd
    end
  end # remove_param


  # Adds a parameter to the control_type_detail field and to
  # the @fldParams hash - if it's not already there
  #
  # Parameters
  # * pName name of the parameter to be added
  # * val value to be assigned to the parameter
  #
  # Returns: nothing, but the @fldParams object should be updated as
  # well as the control_type_detail field of the current object
  #
  def add_param(pName, val)
    if (@fldParams.nil?)
      @fldParams = controls_hash
    end
    pVal = @fldParams[pName]
    if !pVal.nil?
      errors.add(:control_type_detail, "Can't add parameter " + pName +
                 " - it's already there with value = " + pVal.to_s)
    else
      @fldParams[pName] = val
      rewrite_ctd
    end
  end # add_param


  # Rewrites the control_type_detail field with the current contents
  # of @fldParams.  If @fldParams is empty, gets it first.  Does NOT
  # check to see if control_type_detail has changed since @fldParams
  # was last acquired.
  #
  # Parameters:
  # * ctd_hash - the hash of control type detail parameters.  This
  #   is optional, and if not supplied, it will be obtained from the
  #   controls_hash method (if it has not already been loaded.)
  # Returns: nothing, but the control_type_detail field of the current
  # object is updated
  #
  def rewrite_ctd(ctd_hash = nil)
    if ctd_hash
      @fldParams = ctd_hash
    elsif (@fldParams.nil?)
      @fldParams = controls_hash
    end
    self.control_type_detail = @fldParams
  end # rewrite_ctd


  # Provides a hash map of the control_type_detail contents.  If there are
  # none, an empty hash will be returned.
  def controls_hash
    control_type_detail || {}
  end


  # Provides a hash map of the dependencies contents.  Values can
  # be a string, an array of strings (the ones enclosed in parentheses), or a
  # hash map of string key/value pairs (the ones enclosed in braces).
  def dependencies_hash
    FieldDescription.parse_hash_value(dependencies)
  end


  # Only for fields whose control_type is 'test_panel' or 'loinc_panel'
  # Get a list of top-level fileds (currently it should only contain one group
  # header) definitions for the panel based on parameter 'panel_name' in its
  # control_type_detail
  def get_panel_fields
    panel_grp_fields = []
    if control_type=='test_panel' or control_type=='loinc_panel'
      panel_name = getParam('panel_name',false)
      panel_obj = Form.find_by_form_name(panel_name)
      panel_grp_fields = FieldDescription.where(form_id: panel_obj.id).
                                          where('group_header_id IS NULL')
    end
    return panel_grp_fields
  end


  # Returns true if the field is a hidden field (one that should always be
  # hidden).  The return value is cached.  Caution:  The cached value is not
  # updated as it should be when the field description is changed.  (For now,
  # we don't have a need for that.)
  def hidden_field?
    if !defined? @is_hidden
      class_param = getParam('class')
      @is_hidden = !class_param.blank? && class_param.include?('hidden_field')
    end
    return @is_hidden
  end


  # If this is a group header for a horizontal fields table, this will return
  # true if each row should have an ID column.  The return value is cached.
  # Caution:  The cached value is not
  # updated as it should be when the field description is changed.  (For now,
  # we don't have a need for that.)
  def has_id_column?
    if !defined? @has_id_column
      @has_id_column = false
      if control_type.downcase == 'group_hdr'
        # Currently groups have repeatable fields only if their orientation
        # is horizontal and max_responses specified for the group is not 1.
        if getParam('orientation', false) == 'horizontal' &&
           (!max_responses.nil? && max_responses != 1 ||
             max_responses.nil?)
          @has_id_column = true
        end
      end
      #@has_id_column = max_responses.nil? || max_responses != 1
    end
    return @has_id_column
  end


  # return true if this is a group header for a horizontal fields table, no
  # matter whether the table is a single row table or not
  def has_a_table?
    has_a_table = false
    if control_type.downcase == 'group_hdr'
      # Currently groups have repeatable fields only if their orientation
      # is horizontal
      if getParam('orientation', false) == 'horizontal'
        has_a_table = true
      end
    end
    return has_a_table
  end


  # This HIGHLY DISTASTEFUL and PROFESSIONALLY PAINFUL hack has been TEMPORARILY
  # inserted to allow invocation of the same action twice by the same field for
  # a record data requester action.  Specifically, it's so that the source_table
  # field on the fetch rule page can distribute the list to two fields on the
  # form.  What we really need is a way to run this once and give the results
  # to 2 fields.  But I guess that will have to wait.
  #
  # The get_non_date_group_field_display_names method sets up a request to
  # get a sub_fields list based on preset conditions.  It would be really
  # great if there were a way to pass these conditions on invocation, instead
  # of hardcoding them (another distasteful coding practice).  But for the
  # moment we have to do it this way.
  def get_non_date_group_field_display_names2
    return get_non_date_group_field_display_names
  end
  def get_non_date_group_field_display_names3
    return get_non_date_group_field_display_names
  end
  def get_non_date_group_field_display_names
    rtn = []
    conditions_string = "control_type != 'calendar' AND " +
                        "target_field NOT like '%_C' AND " +
                        "target_field NOT like '%_ET' AND " +
                        "target_field NOT like '%_HL7' AND " +
                        "control_type != 'group_hdr' AND " +
                        "control_type != 'button' AND " +
                        "control_type != 'check_box_display' AND " +
                        "control_type != 'image' AND " +
                        "display_name is not null"
    if (target_field != 'panel_generator')
      rtn = get_field_lists('display_name', 'sub_fields', form.form_name,
                            target_field, conditions_string)
    else
      rtn = get_field_lists('display_name', 'sub_fields', 'loinc_panel_temp',
                            'tp_loinc_panel_temp', conditions_string)
    end
    return rtn

  end # get_non_date_group_field_display_names


  # This HIGHLY DISTASTEFUL and PROFESSIONALLY PAINFUL hack has been TEMPORARILY
  # inserted to allow invocation of the same action twice by the same field for
  # a record data requester action.  (see a pattern here?) See the non_date
  # versions of these methods.
  #
  def get_date_group_field_display_names2
    return get_date_group_field_display_names
  end
  def get_date_group_field_display_names
    rtn = []
    conditions_string = "control_type = 'calendar' AND " +
                        "target_field NOT like '%_C' AND " +
                        "target_field NOT like '%_ET' AND " +
                        "target_field NOT like '%_HL7'"
    if (target_field != 'panel_generator')
      rtn = get_field_lists('display_name', 'sub_fields', form.form_name,
                            target_field, conditions_string)
    else
      rtn = get_field_lists('display_name', 'sub_fields', 'loinc_panel_temp',
                            'tp_loinc_panel_temp', conditions_string)
    end
    return rtn

  end # get_date_group_field_display_names


  # This method submits a request to get_list_items and then creates two arrays,
  # a values array and a codes array, from the field_descriptions returned.
  #
  # The get_list_items method follows the convention used by other classes that
  # have a get_list_items method, where the actual objects are returned.  This
  # method is necessary when a list is requested via a record data requester,
  # which wants the values and codes already extracted from the objects.
  def get_field_lists(value_column, list_type, the_form,
                      the_target_field, the_conditions)

    fds = FieldDescription.get_list_items(list_type, nil, nil,
                                   [the_form, the_target_field, the_conditions])
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


  # The default_value column in the table has been used for other things than
  # actual field defaults.  This returns the default_value if it belongs
  # in the Def.FieldDefaults structure, and nil otherwise.
  def field_default_value
    NON_DEFAULT_CONTROL_TYPES.member?(control_type) ? nil : default_value
  end


  # The default value, but if it contains #{...} escapes, those will
  # be evaluated.
  def default_value_eval
    default_value =~ /#\{.*\}/ ? eval(%Q{"#{default_value}"}) : default_value
  end


  # Returns the requested list items.  The return values will be instances
  # of field_descriptions.  If 'name' is nil, an empty list will be returned.
  #
  # Parameters:
  # * name - the type of list to be returned:
  #   'sub_fields' is a request for the sub_fields of a group header.
  #   'form_fields' is a request for the fields on a form.
  #    these are currently the only types implemented; please use this format
  #    to implement others as needed.
  # * pattern - not currently used; included for consistency with other
  #    instances of get_list_items in other model classes (e.g. TextList)
  # * order - optional; a list of fields by which the output should be
  #    ordered, normally as specified by the :order parameter in a field
  #    description's control_type_detail column.
  #      May be used for the sub_fields list.  If not specified for the
  #       sub_fields list, the sort defaults to display_order.
  #      Used if specified by the form_fields list.  No default applied.
  # * conditions - specifies additional parameters needed by the list
  #    being requested, as follows:
  #     sub_fields list: an array containing two required elements: form
  #      name and the group header row's target_field value.  If additional
  #      criteria are required, include one more parameter in the conditions
  #      array.  Make that parameter a conditions string for a 'where'
  #      statement.  It will be "anded" to 'group_header_id = ' the id of
  #      the group header specified.
  #     form_fields list: an array containing at most two elements:  form name
  #      in the first position, and any other conditions expressed as a string
  #      and placed in the second element.
  #
  # Note that hidden fields are not automatically excluded from the list.
  #
  def self.get_list_items(name, pattern=nil, order=nil, conditions=nil)
    list_items = []
    case name
    when 'sub_fields'
      fm = Form.where(form_name: conditions[0]).take
      gh = fm.field_descriptions.where(target_field: conditions[1])
      list_items = gh.descendents(conditions[2], order)

    when 'form_fields'
      fm = Form.where(form_name: conditions[0]).take
      list_items = fm.field_descriptions
      list_items.where(conditions[1]) if conditions[1]
      list_items.order(order) if order
      # check for foreign fields - such as PHR test panel fields
      list_items = list_items + fm.foreign_fields(conditions[1], order)
    end # case form_fields
    return list_items
  end # get_list_items


  def get_user_data_list_info(profile_id, user)
    search_table_param = getParam('search_table')
    if (search_table_param.index('user ') == 0)  # as it should
      table_name = search_table_param[5..-1] # everything after 'user '
      form_type = table_name.singularize
      conditions = {}
      # add the profile_id
      # remove the "obr_order" special case later
      if !profile_id.nil? && form_type == "obr_order"
        conditions[:profile_id]=profile_id
        # if it's obr_order, add a condition that there must be records in the
        # obx_observations for each obr_oder records
        # Specail Code AGAIN!
        # Update: the panel records that have no obx records need to be
        # displayed too for the comment, where done, due date and etc. --Ye
        #  conditions[:obx_count] =
        #  "(select count(*) from obx_observations where obr_order_id=obr_orders.id)>0"
      end
      # add the unique selector to filter the datalist
      #  it's an array of columns in the table_name,
      #  i.e panel_name in obr_orders, pseudonym in phrs
      opt = {}
      array_unique = getParam('unique')
      if !array_unique.nil? && !array_unique.empty?
        opt[:group] = array_unique.join(",")
      end
      # add orders to the query830
      #  it's an array of columns in the table_name,
      array_order = getParam('order')
      if !array_order.nil? && !array_order.empty?
        opt[:order] = array_order.join(",")
      end

      table_recs_part = []
      table_recs_all = user.typed_data_records(form_type,conditions, opt)
      # if condition param specified, then utilize that to filter the returned
      # objects
      # note: becuase archived is in the profiles table, which is not part of
      #   the query used in the typed_data_records method that uses table_name
      #   (phrs, in this case), the results are filtered afterwards.
      #
      cond_param = getParam('conditions')
     # if looking for only archived or unarchived records.
      if cond_param && cond_param['archived']
        bool_flag = (cond_param['archived'].match(/(true|t|yes|y|1)\z/i) != nil)
        table_recs_all.each do |li|
          if li.profile.archived == bool_flag
            table_recs_part.push(li)
          end
        end
        table_recs = table_recs_part
      else
        table_recs = table_recs_all
      end

      col_names = getParam('fields_displayed') if table_recs
      code_field = list_code_column if table_recs
    end
    return [table_recs, col_names, code_field]
  end


  # Returns the descendents of a group header field description.  Must be
  # called on a field description object that is a group header.  Returns all
  # descendents to however many generations exist for the group header on
  # which this is called.
  #
  # Parameters:
  # * conditions - any conditions to be applied to the query to get the
  #   descendents; optional, expressed as a string if supplied
  # * order - any order to be applied to the descendents; optional, expressed
  #   as a string if supplied; no default.
  def descendents(conditions=nil, order=nil)
    rtn = []

    if control_type == 'group_hdr'
      ids = get_sub_header_ids
      rtn = FieldDescription.where(group_header_id: ids)
      rtn.where(conditions) if conditions
      rtn.order(order || 'display_order').load
    end
    return rtn
  end # descendents


  # Returns the IDs of all group header objects under the
  # current group header (and also the current group header itself).
  # If the field description on which this is called
  # is not a group header, an empty array is returned.
  #
  def get_sub_header_ids
    ids = []
    if control_type == 'group_hdr'
      ids << id
      subgroups = FieldDescription.where(
                    group_header_id: id, control_type: 'group_hdr').load
      while subgroups.length > 0
        subgroup_ids = subgroups.map {|fd| fd.id}
        ids.concat(subgroup_ids)
        subgroups = FieldDescription.where(
                    group_header_id: subgroup_ids, control_type: 'group_hdr').load
      end
    end # end if the current field description object is a group header
    return ids
  end


  # Returns the value of "required" from this record, or if that has not
  # been set (i.e. if it is null) then if this record has an associated
  # db_field_description, it returns the db_field_description's required
  # attribute.
  # (This is overridding a method provided by ActiveRecord.)
  def required
    rtn = read_attribute('required')
    if rtn.nil? && db_field_description
      rtn = db_field_description.required
    end
    return rtn
  end


  # The same as required, but returns false when required is nil.
  # (This is overridding a method provided by ActiveRecord.)
  def required?
    !!required
  end

  # Returns true if the field is on a normal line where any empty required fields
  # is valid if the entire line is empty.
  # If "required?" method call on the group header field returns true, then the
  # line which contains all the sub fields of the group header field will become
  # an abnormal line and all the required fields on that line have to be filled
  # out to make them valid.
  def on_normal_line
    the_parent_field = parent_field

    the_parent_field && the_parent_field.control_type == "group_hdr" &&
      the_parent_field.getParam("orientation") == "horizontal" &&
      !the_parent_field.required?
  end


  # Returns the list item records for the field, assuming this is a list field.
  # Currently this just supports TextLists, but it will be expanded as needed.
  # Note:  There is some similarity between this and some code in
  # text_fields_helper which is not readily extractable and which relies on
  # some complex and not-well written/designed code in TextList.get_list_items.
  # Perhaps one day that code can be replaced in favor of this.
  def list_items
    search_table = control_type_detail['search_table']
    if search_table == 'text_lists'
      list_name = control_type_detail['list_name']
      items =  TextList.find_by_list_name(list_name).text_list_items
    end
    return items
  end


  ## =================================================================== ##

  # The following method performs (hopefully) all the changes needed to
  # change a target_field name.  Even though this affects multiple tables
  # and model classes, we've placed it here because:
  # 1) we want to be able to write a unit test for it and need a
  #    location that fits within the predefined rails testing structure;
  #    and
  # 2) the target_field serves as the key to rows in the field_descriptions
  #    table and so it made sense that if any model class was to have this
  #    method, it would be this one.
  #
  # The change list contains the data for each place where a target_field
  # change should be made to keep the names consistent.  The list is an
  # array of hash objects that includes one hash for each table, with the
  # table name specified in object form, i.e. FieldDescription rather than
  # field_descriptions.
  #
  # The outermost structure is an array rather than a hash so that we can
  # control the order in which the changes are processed, since that is
  # important for some tables (such as the rules tables).
  #
  # Each table has an entry for the column(s) in the table where changes
  # might be needed.  The columns entry is an array, with one element for
  # each column.
  #
  # The entry for each column is an array with two elements:
  #  - the column name; and
  #  - a change method.
  #    - For columns where the target_field value is the only value,
  #      the method should be 'replace'.  For example, the target_field
  #      column in the field descriptions table would use the 'replace'
  #      method.
  #    - For columns that could contain additional information, the
  #      method should be 'sub'.  The control_type_detail column in
  #      the field descriptions table would use the sub method (which
  #      uses gsub to find and replace each occurrence of the value to
  #      be changed).
  #
  # This method runs through the change_list and makes the appropriate
  # change in each table column where it appears.
  #
  # NOTE that form_id is NOT requested by this method.  If you use the
  # target_field value for multiple forms, do NOT try to use this to
  # change the name for one form.  It will change it for all.  In that
  # case you'll need to use some other method that assures it only is
  # changed for the appropriate form in each affected table.
  #
  # Parameters:
  # * current_name - the current target_field value
  # * new_name - the new value for target_field
  #
  def FieldDescription.change_target_field(current_name, new_name)

    #  Please note that the order in which the changes are executed
    #  is significant, because of the following dependencies:
    #
    #  FieldDescription - the target_field must be changed before any
    #                     of the rule table changes are done, because
    #                     the validation for the rule tables includes
    #                     looking for the (new) target field
    #
    #  RuleAction - affected_field must be changed before parameters
    #               when the rule_action row is saved, validation includes
    #               -> looking for the affected_field -- with the new name
    @change_list = [
      {'FieldDescription'=>[['target_field', 'replace'],
          ['control_type_detail', 'sub']]},
      {'RuleCase'=>[['case_expression', 'sub'],
          ['computed_value', 'sub']]},
      {'RuleAction'=>[['affected_field', 'replace'],
          ['parameters', 'sub']]},
      {'Rule'=>[['expression', 'sub']]}
    ]


    @change_list.each do |upd_def|
      upd_def.each do |tbl, cols|
        tblClass = tbl.singularize.camelize.constantize
        cols.each do |cd|
          if (cd[1] == 'replace')
            recs = tblClass.where(cd[0] =>current_name)
            recs.each do |rc|
              rc.send(cd[0] + '=', new_name)
              rc.save
            end
          else
            recs = tblClass.where(cd[0] + " LIKE ?", "%#{current_name}%")
            reg_name = Regexp.new("(\\A|[^A-Za-z0-9_])#{current_name}(\\z|[^A-Za-z0-9_])")
            recs.each do |rc|

              val = rc.send(cd[0])
              # since rails 2.2.2 the attribute gets updated in memory probably because
              # val references the same object attribute in memory without validation.
              #  Consequent update does not trigger update when saved.
              need_to_json = !val.is_a?(String)
              new_val = need_to_json ? val.to_json : val.clone
              new_val.gsub!(reg_name, '\1' + new_name + '\2')
              new_val = JSON.load(new_val) if need_to_json
              rc.send(:attributes=, { cd[0] => new_val})
              rc.save!

            end
          end # if we're replacing or gsubbing
        end # do for each column to be changed
      end # do for each table
    end # do for each hash in the change_list
  end # change_target_field

  def complete_label_name
    res = [ self.display_name ]
    hdr = self.group_header
    while hdr
      res << ( hdr && hdr.display_name )
      hdr = hdr.group_header
    end
    res.compact.reverse.join(" >> ")
  end

  def label_name_and_path
    label_name = [ self.display_name ]
    path = []
    hdr = self.group_header
    while hdr
      path << hdr.display_name
      hdr = hdr.group_header
    end
    [label_name, path.reverse.join(" ")]
  end

  # Returns target field and loinc number of an loinc field in an Array. If
  # the input field is not an loinc field, then returns nil.
  # Parameters:
  # * loinc_target_field - a String specifying a loinc field using a loinc
  # number and a target field joined by a ":", e.g. "tp_test_value:8302-2"
  def self.loinc_field_info(loinc_target_field)
    re = Regexp.new("(tp_(\\w+)):([\\d-]+)")
    m = re.match(loinc_target_field)
    m ? [m[1], m[3]] : nil
  end


  # Un-serializes the data_req_output field and returns it.  If there is no
  # value in the field, it attempts to construct the data_req_output data
  # from the db_field_descriptions table.  (Eventually, that is what it will
  # always do; there is no need to specify the same information in two places.)
  # (See the field_descriptions documentation on the TWiki.)
  def data_req_output
    dro = self.read_attribute('data_req_output')
    dro || alt_data_req_output
  end


  # Constructs the data_req_output parameter based on the data table
  # definitions.  Eventually, when the data table definitions are reliable,
  # we will always do this.
  def alt_data_req_output
    rtn = nil
    if db_field_description
      dependent_fields = DbFieldDescription.where(
        :db_table_description_id=>db_field_description.db_table_description.id,
        :controlling_field_id=>db_field_description.id)
      dro_hash = {}
      dependent_fields.each do |df|
        form_field = df.field_descriptions.find_by_form_id(form.id)
        value_method = df.current_value_for_field
        if value_method.blank?
          value_method = df.list_values_for_field
        end
        output_field_array = dro_hash[value_method]
        if !output_field_array
          output_field_array = []
          dro_hash[value_method] = output_field_array
        end
        output_field_array << form_field.target_field
      end
      rtn = dro_hash.empty? ? nil : dro_hash
    end
    return rtn
  end


  # Returns true if the field is on a normal line and has at least one required
  # sibling field.
  # If the field is in a test panel, it will return true if there is at least
  # one required field in the same test panel.
  def has_required_nl_sibling
    if form.form_name == "loinc_panel_temp"
      !!form.field_descriptions.detect{|e| e.required? && !e.hidden_field?}
    else
      !!parent_field.sub_fields.detect{|e| e.required? && e.on_normal_line}
    end
  end


  # Returns true if the field is editable.
  #
  # Parameters:
  # * new_record - true if the field is being displayed as part of a new record
  def editable?(new_record)
    edit = getParam('edit')
    return edit.nil? || (edit != '0' && edit != '3' &&
                        (new_record || (edit !='2' && edit !='4')))
  end

  # Returns true if the field is a rule trigger
  def is_rule_trigger?
    rules.length > 0 || loinc_field_rules.length > 0
  end


  # Returns the tooltip for the field
  def tooltip
    getParam('tooltip')
  end


  ########################################
  #### BEGIN of find_matching_field section
  ########################################

  # Returns matching fields in list format. By default, it will return
  # a list of matching fields' code list and value list (e.g.
  # [code_list, value_list]). It can return a list of matching fields ActiveRecord
  # instances if specified in parameter
  # Parameters:
  # * term_list - list of searching terms
  # * return_ar_instances - when it is true, returns a list of ActiveRecord
  # instances
  def find_matching_field(term_list, return_ar_instances= false)
    rtn = nil
    table_name = getParam('search_table')
    if !(FieldDescription.public_tables.member?(table_name) || table_name.index('user ') == 0)
      raise "Search of table #{table_name} not allowed."
    end

    unless table_name.blank?
      if ["true", "1"].include?(getParam("prefetch"))
        # run prefetch
        rtn = term_list.map{|terms| prefetch_autocompleter_params(terms)}.compact.transpose
      else
        # run master table
        options={:exact => true}
        rtn = term_list.map do |terms|
          get_matching_field_vals(terms, options)
        end.compact.transpose
      end
    end

    # need to return list of active record instances
    if rtn && return_ar_instances
      tableClass = table_name.singularize.camelize.constantize
      rtn = tableClass.send("find_all_by_#{db_field_description.list_code_column}", rtn[0])
    end
    rtn
  end

  # Warning: So far, only used for create classes of problem
  # (medical conditions)
  #
  ## input:
  ##   terms - "Diabetes"
  ##   options - {:exact => true || false}
  ## output:
  ## [code_list, term_list] or
  ## [single_code, single_term] # when options[:exact] == true
  ##
  ## TODO: this method and next method was mostly copied from a controller
  ## may need further refactoring
  def get_matching_field_vals(terms, options)
    rtn = nil
    return rtn if self.target_field != "problem" # only works for fields similar as problem field

    options[:exact] ||= false
    # using limit = 1, then we can not find the exact matching record when there
    # is one,have to find a list of candidates then pick the exact matched one
    options[:limit] = MAX_AUTO_COMPLETION_SIZE
    # Add a wildcard to the end of the last term.  However, Ferret won't use
    # the query analyzer in parsing terms that end in a wild card, so we need
    # to parse that last term away from the rest of the string by adding a
    # space before it.  For example, 'one/two' => 'one/ two*'
    new_terms = options[:exact] ? terms : terms.sub(/([[:alnum:]\-\.]+)\z/, ' \1*')

    table_name = getParam('search_table')
    if !(FieldDescription.public_tables.member?(table_name) || table_name.index('user ') == 0)
      raise "Search of table #{table_name} not allowed."
    end
    tableClass = table_name.singularize.camelize.constantize

    list_name= getParam('list_name')
    highlighting = getParam('highlighting')
    if (highlighting.nil?)
      highlighting = false
    end

    search_cond = getParam('conditions')
    if (!search_cond.nil?)
      # search_cond should contain a bit of FQL for restricting the search
      # results
      new_terms = '('+new_terms + ') AND ' + search_cond
    end

    search_options = {:limit=> options[:limit]}
    order = getParam('order')
    search_options[:sort] = order if order
    # Return the result of find_storage_by_contents, plus the "highlighting"
    # variable.
    res = tableClass.find_storage_by_contents(list_name, new_terms,
      fields_searched, list_code_column.to_sym,
      fields_returned, fields_displayed,
      highlighting, search_options) << highlighting
    # return will be [code_list, value_list]
    if res
      rtn = [res[1], []]
      res[1].each_with_index do |e, index|
        rtn[1] << res[3][index][0]
      end
    end

    # search an exactly matched record will return  [code, value]
    if options[:exact] && rtn
      rtn = rtn.transpose.select{|e| e[1] == terms}[0]
    end
    rtn
    #res ?  [res[1][0], res[3][0][0]] : nil # e.g. format is: [code, value]
  end # get_matching_field_vals

  # Copied from form_controller, trying to find matching field
  # Used for build classes of problems etc
  # TODO: may need further refactoring
  def prefetch_autocompleter_params(terms)
    raise "This is not a prefetch field" unless %w(true 1).include? getParam("prefetch")
    # Get the data for the field:
    #
    # List fields can now contain lists of user data, which must be obtained
    # after the form is built (because the form is cached) via an AJAX call.
    # Such lists are indicated by the search_table parameter starting with
    # the string "user ".
    search_table = getParam('search_table')
    if search_table.nil?
      col_names = nil
    else
      is_user_data = search_table.index('user ') == 0

      # Prefetched list fields may be dynamically loaded during runtime.
      # Check to see if this is the case.
      is_dynamically_loaded = search_table == 'dynamically_loaded'

      list_data = nil
      if (!is_user_data)
        # Get the table name, convert it to its class name, & get the data
        if (!is_dynamically_loaded)
          table_class = search_table.singularize.camelize.constantize
        end

        # Get the column names to be returned for the list items.
        col_names = getParam('fields_displayed')

        # Get the list name, which is either in the list_id parameter
        # or the list_name parameter.  This applies only to tables
        # that are accessed via text_lists (list_name) or answer_lists
        # (list_id).  For tables that are accessed directly, list_name
        # and list_id need not be specified.  Exception to this
        # is the forms table, where the list name needs to indicate
        # form type ('form' or 'panel').
        # If list_name is not specified for a text_lists list, no
        # values will be prefetched.  (Assume that the values will
        # be loaded during run time by some other field).
        if (!is_dynamically_loaded)
          list_name = getParam('list_id')
          list_name = getParam('list_name') if list_name.nil?
          if table_class.respond_to?('get_list_items')
            list_data = table_class.get_list_items(
              list_name,
              nil,
              getParam('order'),
              getParam('conditions'))
          end
        end
      end
    end # if we have a search table

    found_rec = list_data.select{|e| e.send(col_names[0]) == terms }[0]
    found_rec ? [found_rec.code, found_rec.send(col_names[0])] : nil
  end # prefetch_autocompleter_params

  ### Used by find_matching_field method only
  def self.public_tables
    @@public_tables ||= Set.new(['gopher_terms', 'rxnorm3_drugs', 'icd9_codes',
        'list_details', 'drug_name_routes', 'drug_strength_forms', 'allergy_types',
        'text_lists', 'vaccines', 'predefined_fields','answer_lists',
        'regex_validators','loinc_items', 'loinc_units', 'field_descriptions',
        'rxterms_ingredients', 'drug_classes', 'db_table_descriptions',
        'db_field_descriptions', 'forms'])
  end
  ########################################
  #### END of find_matching_field section
  ########################################


  # Returns two booleans indicating whether this field description (if a date
  # field) requires a month and day, respectively.  If the field description
  # is not a date field, or a determination cannot be made, both booleans will
  # be false.
  def get_date_format_requirements
    month_req = false
    day_req = false
    if control_type == 'calendar' && control_type_detail
      tooltip = control_type_detail['date_format']
      if tooltip == 'YYYY/MM/DD'
        day_req = true
        month_req = true
      elsif tooltip == 'YYYY/MM/[DD]'
        day_req = false
        month_req = true
      end
    end
    [month_req, day_req]
  end


  # Returns the target_field name of the code field corresponding to this field
  # (assuming the field is a list).
  def code_field
    return target_field + '_C'
  end


  # Returns the name of the subform defined in this field
  def get_subform_name
    rtn = nil
    SUBFORM_KEYS.each do |e|
      rtn = getParam(e,false)
      break unless rtn.blank?
    end
    rtn
  end


  # Returns the field validation definition based on the validation type. The
  # returned object is an array where the first element is the type of validation
  # and the second one is a array of parameters used for validation.
  #
  # Parameters:
  # * vtype validation type
  def get_validation(vtype)
    rtn = case vtype
    when 'xss'
      db_field_description && rails_data_type &&
        %w(string text).include?(rails_data_type) && []
    when 'regex'
      regex_validator && regex_validator.code.to_s
    when 'date'
      v_date_format =  getParam('date_format') || ''
      v_epoch_point =  getParam('epoch_point') || ''
      control_type == 'calendar' && [v_date_format, v_epoch_point]
    when 'time'
      control_type == "time_field" && [ ]
    when 'abs_range'
      max = getParam("abs_max") || ''
      min = getParam("abs_min") || ''
      !(max + min).blank? && [max, min]
    when "date_range"
      min = getParam('abs_min')
      if min.blank?
        min = db_field_description  && db_field_description.abs_min &&
          db_field_description.abs_min.to_s
        min = '' if min.blank?
      end
      max = getParam('abs_max')
      if max.blank?
        max = db_field_description  && db_field_description.abs_max &&
          db_field_description.abs_max.to_s
        max = '' if max.blank?
      end
      min_err = min_err_msg || ''
      max_err = max_err_msg || ''

      !(max + min).blank? && [ display_name, min, max, min_err, max_err ]
    when 'uniqueness'
      getParam('unique_field_value') && [ ]
    when 'password'
      getParam("password") && control_type == "password_field" && [ ]
    when "confirmation"
      getParam("confirmation")
    when 'required'
      !hidden_field? &&
        (  ## common required field
        ( required? && !on_normal_line && "common" ) ||
          ## normalLine required field
        ( parent_field && has_required_nl_sibling && "normalLine")
      )
    else # nothing here so far
      raise "unknown validation type."
    end

    if (rtn)
      rtn = [rtn] if (rtn.is_a? String)
      rtn.unshift(vtype)
    else
      nil
    end
  end


  # Return list of field validation definitions of a form field
  def get_validations
    rtn = []
    if !display_only? && !new_record?
      %w(xss regex password date time date_range uniqueness confirmation
      required).each do |vtype|
        tmp = self.get_validation(vtype)
        rtn << tmp if tmp
      end
    end
    rtn
  end


end # field_description.rb
