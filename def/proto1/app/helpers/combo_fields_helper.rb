module ComboFieldsHelper
require 'util.rb'

  # Builds the appropriate type of input mechanism for a field 
  # with a control_type of 'combo_field'.
  #
  # A combo field is one that knows how to use different mechanisms to accept
  # input.  The initial mechanisms include a plain text field, a prefetch
  # autocompleter and a search autocompleter.  We have tentative plans to add
  # date fields and perhaps others later.
  #
  # Date fields added January 2010.
  #
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # Constants used to indicate the type of field to be mimicked.  Should
  # match the constants in the Def.ComboField javascription object and
  # comparison_operator.rb
  
  PLAIN_TEXT = 1
  PREFETCHED_LIST = 2
  SEARCH_FIELD = 3
  DATE_FIELD = 4
  
  # Builds the input mechanism for a field with a control_type of 
  # 'combo_field'.
  #
  # Parameters:
  # * some_field - the field to display (a FieldDescription)
  # * some_form - the form instance (from the template)
  # * tag_attrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the input field and hidden field(s)
  #   with all specified attributes, modifiers, labels, etc.
  #  
  def combo_field(some_field,
                  some_form,
                  tag_attrs={},
                  fd_suffix=nil)
                
    output = nil;
    # Create the plain text input field.  Add a tooltip span to it even
    # if it doesn't have a tooltip specified.  This is so that it's there
    # in case we need it.  A blank tooltip should not affect what the user
    # sees.  (But if a tooltip is specified, it will be shown)
        
    target = some_field.target_field
    target += fd_suffix if !fd_suffix.nil?
    # change target_field if it is within a loinc panel
    target = target_field_for_panel(target)
    field_id = make_form_field_id(target)

    tag_attrs = merge_tag_attributes(tag_attrs,
                                   {:autocomplete=>'off',
                                    :style=>'z-index: 2; opacity: 0;'})
   
    output = some_form.text_field(target.to_sym)
    add_common_event_handlers(some_field, true) ;
    @form_field_js << render({:partial=>'form/combo_field.rhtml', :handlers=>[:erb],
                              :locals=>{:field_id=>field_id}})

    return output 
  end # combo_field
  
  
  # Provides the information necessary to have a combo field mimic a specific
  # field.
  #
  # Parameters:
  # * db_field_id - the id of the db_fields_description row for which a field
  #   is to be created OR a negative value indicating that a plain text field
  #   should be created.  (See the mimicField function in combo_fields.js for
  #   an explanation of applicable use case.)
  # * form_field_id - the id (including prefix and suffix) of the form field
  #   that is to mimic a particular field type
  # * form_name - the name of the form that contains the form_field
  # * orig_ff_id - the id (NOT including prefix and suffix) of the form field
  #   being mimicked
  # * in_table - flag indicating whether or not the combo field is in a
  #   horizontal table
  #
  # Returns: an array containing the following elements in the following order:
  #  1. field type - which is expressed using one of the constants defined
  #     above, and that correspond to those used by the javascript ComboField
  #     object.  This element is required.
  #
  #  2. tooltip - if a tooltip is specified for the field, the text of it
  #     will be placed here.  if no tooltip is specified, this will contain
  #     an empty string (but not nil).
  #
  #  3. a hash of parameters used to construct a RecordDataRequester.  If the
  #     field to be mimicked is not a list field, this element will not exist.
  #
  #     If the field to be mimicked does not specify a RecordDataRequester,
  #     this element will be in the array, but will carry a null value.
  #
  #     The hash is the same hash that is created for text_fields that
  #     specify a RecordDataRequester, and contains values for the following
  #     keys: dataUrl, dataReqInput, dataReqOutput and outputToSameGroup.
  #
  #  4. a hash of parameters used to create the autocompleter for a list field.
  #
  #     If the field to be mimicked is not a list field, this element will not
  #     exist.  Otherwise (since a list field is currently our only other
  #     option) this element will carry the hash of parameters.
  #
  #     The parameters are the ones used to create text_fields that specify an
  #     autocompleter, and include parameters not needed for this task.  The
  #     parameters that are used by the combo field are based on the type of
  #     autocompleter being created:
  #
  #     for prefetched list autocompleters:  matchListValue, add_seqnum,
  #     optList, code_vals, auto_fill, is_user_data, and user_data_url.
  #
  #     for search list autocompleters:   matchListValue, quoted_button_id,
  #     resultsUrl, and autocomp.
  #
  #  5. an array containing specifications needed for fields whose contents
  #     depend on the value of another field.  If the db_field_descriptions
  #     row has a controlling_field_id and the db_field does not appear on
  #     the current form, this array will contain the data_column value of
  #     the db_field_descriptions row, plus the original form field name
  #     (the orig_ff_id parameter) passed in.  This is used in later processing
  #     to make sure that the field being created here contains the correct
  #     value or selection list.
  #
  #     If there is no controlling_field specified for the db_field_description
  #     this parameter will be null.
  #
  def get_combo_field_specs(db_field_id,
                            form_field_id,
                            form_name,
                            orig_ff_id,
                            in_table)

    specs = []
    tooltip_param = nil
    form = Form.find_by_form_name(form_name)
    split_ff_id = Util.split_full_field_id(form_field_id)
    
    # Create the empty observer hash and javascript string to hold any
    # observers and javascript that may be created for the field so that
    # they can be passed back.
    @field_observers = {}
    @form_field_js = ''

    # If we have a negative db_field_id, we're just creating a plain text
    # field based on no particular field.
    if (db_field_id.to_i < 0)
      specs, the_field = build_text_field_specs(form_field_id,
                                                form.id,
                                                split_ff_id[1])

    # Otherwise we're creating a field based on an existing one (somewhere).
    else
      db_field = DbFieldDescription.find_by_id(db_field_id)

      # Determine the control type based on the value from the predefined_fields
      # table and, if not a date field, from any master_table definition
      fd_ct = db_field.predefined_field.control_type

      if (fd_ct == 'calendar')
        specs, the_field = build_date_field_specs(form_field_id,
                                                  form.id,
                                                  split_ff_id[1],
                                                  db_field.display_name,
                                                  in_table,
                                                  split_ff_id[2])

      elsif (fd_ct == 'text_field' || fd_ct == 'search_field')
        if db_field.list_master_table
          search_table = db_field.list_master_table
        else
          search_table = db_field.item_master_table
        end

        # If there is no search table, this is a plain text field.
        if search_table.blank?
          specs, the_field = build_text_field_specs(form_field_id,
                                                    form.id,
                                                    split_ff_id[1])

        # Otherwise build the control_type_detail field value.
        else
          specs, the_field = build_list_field_specs(form_field_id,
                                                    form.id,
                                                    split_ff_id[1],
                                                    search_table,
                                                    db_field,
                                                    orig_ff_id)
        end # building a list field
      else
        # control_type not handled - do nothing
      end # processing based on control type

      # WE HAVE TEMPORARILY LOST ACCESS TO THE TOOLTIP.  PAUL PROMISES THAT
      # IT WILL BE BACK.
      # TEMPORARY FIX - GET THE FIRST TOOLTIP YOU CAN FIND, IF ANY, FROM
      # THE RELATED FIELD DESCRIPTION(S).
      tooltip_param = ''
      if !db_field.field_descriptions.nil? && fd_ct != 'calendar'
        db_field.field_descriptions.each do |fd|
          tt = fd.getParam('tooltip')
          if !tt.blank? && tooltip_param.blank?
            tooltip_param = tt.strip
          end
        end
      end
    end # if we are/aren't creating a plain text field from nothing

    # Get and set the specs that are the same for all
    # Get the common event handlers

    add_common_event_handlers(the_field, true) ;
    obs_output = 'var fldObservers = {};'
    @field_observers.each do |target, event_hash|
      obs_output += 'fldObservers["' + target + '"] = {};' + "\n"
      event_hash.each do |event_type, func_array|
        obs_output += "fldObservers['#{target}']['#{event_type}'] = " +
                      "[#{func_array.join(', ')}]\n;"
      end
    end

    specs[1] = tooltip_param
    specs[2] = obs_output
    specs[3] = @form_field_js
    return specs.to_json.html_safe  
  end # get_combo_field_specs
  
    
  # Provides the information necessary to have a combo field mimic a specific
  # field.
  #
  # Parameters:
  # * db_field_id - the id of the db_fields_description row for which a field
  #   is to be created OR a negative value indicating that a plain text field
  #   should be created.  (See the mimicField function in combo_fields.js for
  #   an explanation of applicable use case.)
  # * form_field_id - the id (including prefix and suffix) of the form field
  #   that is to mimic a particular field type
  # * form_name - the name of the form that contains the form_field
  # * orig_ff_id - the id (NOT including prefix and suffix) of the form field
  #   being mimicked
  # * in_table - flag indicating whether or not the combo field is in a
  #   horizontal table
  def get_combo_field_specs_by_list_desc(list_desc, target_field, form_name)
    specs = []
    # Create the empty observer hash and javascript string to hold any
    # observers and javascript that may be created for the field so that
    # they can be passed back.
    @field_observers = {}
    @form_field_js = ''

    specs, the_field = build_list_field_specs_by_list_desc(list_desc, target_field, 
      form_name)

    # Get and set the specs that are the same for all
    # Get the common event handlers
    add_common_event_handlers(the_field, true) ;
    obs_output = 'var fldObservers = {};'
    @field_observers.each do |target, event_hash|
      obs_output += 'fldObservers["' + target + '"] = {};' + "\n"
      event_hash.each do |event_type, func_array|
        obs_output += "fldObservers['#{target}']['#{event_type}'] = " +
                      "[#{func_array.join(', ')}]\n;"
      end
    end

    specs[1] = the_field.getParam('tooltip')
    specs[2] = obs_output
    specs[3] = @form_field_js
    return specs.to_json.html_safe  
  end # get_combo_field_specs_by_list_desc


  # Builds the specifications for a date field - or, more specifically, to
  # be used to mimic a date field.
  #
  # At the moment this actually creates a prefetched list field that presents
  # the first/last options (only).  This is for the 'simplified' fetch rule
  # form.  But the code is there to mimic a real date field, and it did
  # work (before I had to take it off - very frustrating).
  #
  # Parameters:
  # * form_field_id - the id (including prefix and suffix) of the form field
  #   that is to mimic a particular field type
  # * form_id - the id of the form that contains the combo field
  # * target - the target_field value for the combo field (id without
  #   prefix and suffix)
  # * display_name - the display_name of the field that the combo field is
  #   mimicking (test date, allergy name, etc)
  # * in_table - flag indicating whether or not this field is in a horizontal
  #   table
  # * suffix - suffix for the field
  #
  # Returns:  the specifications array, with the field-type specific values
  #           filled in, and
  #           the FieldDescription object constructed to get the specs
  #
  def build_date_field_specs(form_field_id,
                             form_id,
                             target,
                             display_name,
                             in_table,
                             suffix)
    # Commenting out this lovely creation of a real date field that I worked
    # so hard on (not a bit bitter) for the "streamlined" fetch rule form.
    # The streamlined version simply shows a menu of first/last for all
    # date fields.  Yeesh.   2/22/10  lm
    
#    the_field = FieldDescription.new(
#                       :id => form_field_id ,
#                       :form_id => form_id ,
#                       :control_type => 'calendar' ,
#                       :target_field => target ,
#                       :display_name => display_name,
#                       :control_type_detail => 'date_format=>CCYY\/[MM\/DD]\,' +
#                                               'tooltip=>YYYY\/[MM\/[DD]],' +
#                                               'calendar=>true')
#    specs = Array.new(5)
#    specs[0] = DATE_FIELD
#    specs[4] = dateField(the_field, nil, in_table, nil, suffix) ;
    
    the_field = FieldDescription.new(
          :id => form_field_id ,
          :form_id => form_id ,
          :control_type => 'text_field' ,
          :target_field => target ,
          :control_type_detail => {'search_table'=>'comparison_operators',
                                  'fields_displayed'=>['display_value'],
                                  'match_list_value'=>'true','auto'=>'1',
                                  'conditions'=>'operator_type=\'constraint\''},
          :list_code_column => 'id' ,
          :auto_fill => false )

    specs = Array.new(7)
    specs[0] = PREFETCHED_LIST
    specs[5] = prefetch_autocompleter_params(the_field, form_field_id)
    specs[6] = nil
    specs[4] = nil
    return specs, the_field
  end # build_date_field_specs


  # Builds the specifications for a plain text field - or, more specifically, to
  # be used to mimic a plain field.
  #
  # Parameters:
  # * form_field_id - the id (including prefix and suffix) of the form field
  #   that is to mimic a particular field type
  # * form_id - the id of the form that contains the combo field
  # * target - the target_field value for the combo field (id without
  #   prefix and suffix)
  #
  # Returns:  the specifications array, with the field-type specific values
  #           filled in, and
  #           the FieldDescription object constructed to get the specs
  #
  def build_text_field_specs(form_field_id, form_id, target)
    the_field = FieldDescription.new(:id => form_field_id,
                                     :form_id => form_id ,
                                     :control_type => 'text_field',
                                     :target_field => target)
    specs = Array.new(4)
    specs[0] = PLAIN_TEXT
    return specs, the_field
  end # build_text_field_specs


  # Builds the specifications for a list field - or, more specifically, to
  # be used to mimic a list field (prefetched list or search list).
  #
  # Parameters:
  # * form_field_id - the id (including prefix and suffix) of the form field
  #   that is to mimic a particular field type
  # * form_id - the id of the form that contains the combo field
  # * target - the target_field value for the combo field (id without
  #   prefix and suffix)
  # * search_table - the name of the table that contains the values for
  #   the list
  # * db_field - the DbFieldDescription object for the field to be mimicked
  # * orig_ff_id - the id (NOT including prefix and suffix) of the form field
  #   being mimicked
  #
  # Returns:  the specifications array, with the field-type specific values
  #           filled in, and
  #           the FieldDescription object constructed to get the specs
  #
  def build_list_field_specs(form_field_id,
                             form_id,
                             target,
                             search_table,
                             db_field,
                             orig_ff_id)

    dro = {}

    # Figure out if this is a prefetched or a search list
    search_table_class = search_table.singularize.camelize.constantize
    if search_table_class.is_a?HasSearchableLists
      fd_ct = 'search_field'
    else
      fd_ct = 'text_field'
    end

    # Build the control_type_detail parameters - easy ones first
    fd_ctd = {'auto'=>'1','match_list_value'=>'true'}
    # We are now making all combo fields require values that match the list.
    # The only place we use combo fields in the fetch rule form, and on that
    # form we want the combo field lists to require matching values, even when
    # the phr form field does not.
    #if db_field.match_list_value
    #  fd_ctd += ',match_list_value=>' + db_field.match_list_value.to_s
    #end
    if db_field.list_join_string
      fd_ctd['joinStr']= db_field.list_join_string
    end

    # Build the list parameters - i.e., the parameters that specify where to
    # get the data for the list (prefetch or search).  Only do this if:
    # 1) there is no controlling field specified for this one; OR
    # 2) if this is flagged as a major item; OR
    # 3) if this has a controlling field specified AND
    #    a) this has no major_item_ids; OR
    #    b) it has some but they don't include the controlling field specified.
    if db_field.controlling_field_id.blank? || db_field.is_major_item ||
       (!db_field.controlling_field_id.blank? &&
        (db_field.major_item_ids.nil? ||
         !(db_field.major_item_ids.include? db_field.controlling_field_id.to_s)))

      fd_ctd['search_table'] = search_table
      fd_ctd['fields_displayed'] = db_field.fields_saved
      if db_field.list_identifier
        fd_ctd['list_name'] = db_field.list_identifier
      end
      if db_field.list_conditions
        fd_ctd['conditions'] = db_field.list_conditions
      end

    # If there is a controlling field specified for this one and it's
    # not a major item, the field's values will come from another field.
    # Build the specs for that, which are NOT specs to go into the
    # control_type_detail field.  This will be used to go find and load
    # the data from the appropriate autocompleter.
    else
      if db_field.field_descriptions.find_by_form_id(form_id).nil?
        update_fields_params = [db_field.data_column, orig_ff_id]
      else
        # TBD!!!  Need to figure out what to do if the controlling field
        # IS on the form - as in, say, the PHR.  Need to find the list
        # that was created from the controlling field.
      end # if the controlling field is not on the form
    end # if this does not/does have a controlling field

    # Build the data_req_output hash, if any.  Find any db_table_description
    # rows that have a controlling_field_id that matches the db_field_id
    dep_fds = DbFieldDescription.where(controlling_field_id: db_field.id)

    # Build the data_req_output hash from all found (if any)
    dep_fds.each do |df|
      value_method = df.current_value_for_field
      if value_method.blank?
        value_method = df.list_values_for_field
      end
      output_field_array = dro[value_method]
      if !output_field_array
        output_field_array = []
        dro[value_method] = output_field_array
      end
      output_field_array << df.data_column
    end

    if dro.empty?
      dro = nil
    end

    # we need the form field - from the fetch rule form - to get the 
    # auto_fill parameter.
#    form_field = FieldDescription.find_by_form_id_and_target_field(form_id,
#                                                                   target)
    form_field = db_field.field_descriptions.find_by_target_field(orig_ff_id)

    afill = form_field.nil? ? false : form_field.auto_fill

    # Build the dummy field description
    the_field = FieldDescription.new(
                           :id => form_field_id ,
                           :form_id => form_id ,
                           :control_type => fd_ct ,
                           :target_field => target ,
                           :control_type_detail => fd_ctd ,
                           :list_code_column => db_field.list_code_column ,
                           :merge_user_list_data => db_field.merge_user_list_data ,
                           :auto_fill => afill ,
                           :data_req_output => dro )

    # Use to get the recordDataRequester parameters, if any
    req_params = data_req_params(the_field, db_field.id)
    if (req_params[:dataUrl].nil?)
      req_params = nil
    end

    if fd_ct == 'text_field'
      specs = Array.new(7)
      specs[0] = PREFETCHED_LIST
      specs[5] = prefetch_autocompleter_params(the_field, form_field_id)
      specs[6] = update_fields_params
    else
      specs = Array.new(6)
      specs[0] = SEARCH_FIELD
      specs[5] = search_autocompleter_params(the_field,
                                             form_field_id,
                                             db_field.id)
    end
    specs[4] = req_params
    return specs, the_field
  end # build_list_field_specs
  
  
  # Builds the specifications for a list field. Similar as the method 
  # build_list_field_specs except that this one is based on the list description 
  # record
  #
  # Parameters:
  # * list_desc - the list description record to be used for generating the 
  #   list field specs
  # * target - the target_field value for the combo field (id without
  #   prefix and suffix)
  # * form_name - the name of the form that contains the combo field
  #
  # Returns:  the specifications array, with the field-type specific values
  #           filled in, and
  #           the FieldDescription object constructed to get the specs
  #
  def build_list_field_specs_by_list_desc(list_desc, target, form_name)
    # Figure out if this is a prefetched or a search list
    search_table = list_desc.list_master_table || list_desc.item_master_table
    search_table_class = search_table.singularize.camelize.constantize
    if search_table_class.is_a?HasSearchableLists
      fd_ct = 'search_field'
    else
      fd_ct = 'text_field'
    end

    # Build the control_type_detail parameters - easy ones first
    fd_ctd = {'auto'=>'1', 'match_list_value'=>'true'}
    fd_ctd['search_table']=search_table
    fd_ctd['fields_displayed']=[list_desc.item_name_field]
    if list_desc.list_identifier
      fd_ctd['list_name'] = list_desc.list_identifier
    end
    if list_desc.list_conditions
      fd_ctd['conditions'] = list_desc.list_conditions
    end

    form = Form.find_by_form_name(form_name)
    fd = form.field_descriptions.find_by_target_field(target)
    fd_ctd['tooltip']= fd.getParam("tooltip") if fd.getParam("tooltip")
    
    # Build the dummy field description
    form_field_id = ["fe_", target, "_1"].join
    the_field = FieldDescription.new(
                           :id => fd.id,
                           :form_id => form.id ,
                           :control_type => fd_ct ,
                           :target_field => target ,
                           :control_type_detail => fd_ctd ,
                           :list_code_column => list_desc.item_code_field ,
                           :merge_user_list_data => nil, #db_field.merge_user_list_data ,
                           :auto_fill => true ,
                           :data_req_output => nil)
                         

    if fd_ct == 'text_field'
      specs = Array.new(7)
      specs[0] = PREFETCHED_LIST
      specs[5] = prefetch_autocompleter_params(the_field, form_field_id)
    else
      specs = Array.new(6)
      specs[0] = SEARCH_FIELD
      specs[5] = search_autocompleter_params_by_list_desc(the_field, form_field_id, list_desc.id)
    end
    return specs, the_field
  end # build_list_field_specs_by_list_desc

end # ComboFieldsHelper
