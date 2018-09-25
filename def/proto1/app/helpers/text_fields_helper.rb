module TextFieldsHelper
  # Builds the appropriate type of input mechanism for a field
  # with a control_type of 'text_field' OR 'search_field'
  #
  # The input mechanism may or may not include field labeling data,
  # depending on the parameters passed in.  No data is loaded into
  # the field within these procedures.  Note, though, that any default
  # data specified for any type of field is set as a field attribute
  # (in tagAttrs) before any type-specific processing, such as this,
  # is called.
  #
  # The 'text_field' and 'search_field' types are combined in this
  # helper class because they are closely related.  The 'search_field'
  # type is really a variation of a 'text_field', and specifies a
  # text field as its input mechanism.
  #
  # This includes code to check the field for a "hidden_field" class
  # designation.  If that's found, the entire field division is marked
  # as "display: none".   This is ONLY done for text fields.  It's not
  # done for search fields (how do you specify a search string in a
  # hidden field?).  If for some reason the hidden field concept
  # should be extended to those control types, update this file.
  # lm, January 2008.
  #
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  # Builds the input mechanism for a field with a control_type of
  # 'text_field'.
  #
  # Parameters:
  # * some_Field - the field to display (a FieldDescripion)
  # * some_Form - the form instance (from the template)
  # * in_table - flag indicating whether or not this field is in a
  #   horizontal table
  # * tag_attrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the input field with all specified
  #          attributes, modifiers, labels, etc.
  #
  def textField(some_field,
                some_form,
                in_table,
                tag_attrs={},
                fd_suffix=nil)

    # Set the maximum number of characters that can be entered.
    if !tag_attrs['maxlength'] && some_field.db_field_description
      max_length = some_field.db_field_description.max_field_length
      tag_attrs['maxlength'] = max_length if max_length
    end

    output = nil;
    if @dro_targets.nil?
      @dro_targets = Array.new
    end

    if !some_field.data_req_output.nil?
      dro = some_field.data_req_output
      dro.each_value do |fld_array|
        fld_array.each do |dt|
          if !@dro_targets.include?(dt)
            @dro_targets << dt
          end
        end
      end
    end # if this field has a data_req_output hash
    # get the input field definition based on whether or not
    # the field has an associated list
    if (some_field.getParam("search_table", false) == nil)
      output = non_list_text_field(some_field,
                                some_form,
                                in_table,
                                tag_attrs,
                                fd_suffix)
    else
      output = text_field_with_list(some_field,
                                 some_form,
                                 in_table,
                                 tag_attrs,
                                 fd_suffix)
    end

    # Check to make sure we have some output, and flag it if we don't
    if (output.nil?)
      output = 'ERROR on field = ' + some_field.display_name +
               '; no input field generated.'
    end

    return output
  end # textField


  # Builds the input mechanism for a field with a control_type of
  # 'search_field'.
  #
  # Parameters:
  # * someField - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * in_table - a boolean value that indicates whether or not the
  #   field to be processed is to be located in a table cell.  Optional;
  #   set to false if not passed in.
  # * tagAttrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the input field with all specified
  #          attributes, modifiers, labels, etc.
  #
  def searchField(some_field,
                  some_form,
                  in_table = false,
                  tag_attrs={},
                  fd_suffix=nil)

    # Set the maximum number of characters that can be entered.
    if !tag_attrs['maxlength'] && some_field.db_field_description
      max_length = some_field.db_field_description.max_field_length
      tag_attrs['maxlength'] = max_length if max_length
    end

    # Create the form field id and get the parameters hash needed to create
    # a search autocompleter.  Then provide that to the partial used to
    # create the javascript that creates the autocompleter, and feed that
    # javascript to the form_field_js buffer.  It will get written to a
    # page-specific javascript file on form creation.
    id = make_form_field_id(some_field.target_field, fd_suffix)

    locals_hash = search_autocompleter_params(some_field, id)
    @form_field_js <<
               render({:partial=>'form/search_field_autocomp.rhtml', :handlers=>[:erb],
                       :locals=>locals_hash.merge(data_req_params(some_field))})

    # Now use the search_field partial to create the HTML for the field that
    # includes a find button if one is wanted and the text input field.
    html_text_field = non_list_text_field(some_field,
                                       some_form,
                                       in_table,
                                       tag_attrs,
                                       fd_suffix)
    return render({:partial=>'form/search_field.rhtml', :handlers=>[:erb],
                   :locals=>locals_hash.merge({:text_field=>html_text_field,
                                               :in_table=>in_table})})
  end # searchField


  # This type of control is basically just a div with an ID, and the data
  # value is static text.  (HTML characters will be interpreted by the browser.)
  # The contents can be set programmatically with JavaScript, or loaded from the
  # default_value field of field_descriptions record.
  #
  # Parameters:
  # * someField - the field description object to display
  # * someForm - the form instance (from the template)
  # * tagAttrs - attributes for the div tag
  # * fd_suffix - a suffix to be appended to div name; indicates the
  #   level, if any, at which this text appears in the form hierarchy
  #
  # Returns: an HTML string containing the div with all specified
  #          attributes
  #
  def static_text(someField,
                  someForm,
                  tag_attrs={},
                  fd_suffix=nil)

    # Set the field name to the appropriate suffix level
    field_id = make_form_field_id(someField.target_field, fd_suffix)
    param_class_array = someField.getParam('class')
    class_array = ['static_text']
    if (param_class_array)
      # Copy it, so we don't modify the params version, which gets cached.
      class_array.concat(param_class_array)
    end
    # Required fields in controlled edit table may become editable once being
    # switched into REVISE mode. Therefore, they need to be monitored by required
    # field validation system.
    if someField.required? && someField.group_header.controlled_edit
      class_array << 'required'
    end
    tag_attrs = tag_attrs.merge(:id=>field_id, :class=>class_array.join(' '))

    # Check the html parse level, which determines the extent to which HTML
    # tags should be encoded/escaped.
    if someField.html_parse_level != 0
      tag_attrs.merge!(:htmlParseLevel=>someField.html_parse_level)
    end

    # Bullet lists have a maxRowChars attribute we need to add.
    if (class_array) # bullet lists have a class attribute
      max_row_chars = someField.getParam('maxRowChars')
      tag_attrs['maxRowChars'] = max_row_chars if max_row_chars
    end

    # Do not include the default value for things that are not static text.
    # (This gets called for text fields in controlled edit tables, when
    # @read_only_mode is set.)
    default_val =
      someField.control_type=='static_text' ? someField.default_value : ''
    default_val ||= ""
    default_val = default_val.html_safe
    if class_array.member?('form_hdr_fld')
      return content_tag('span', default_val, tag_attrs)
    else
      return content_tag('div', default_val, tag_attrs)
    end

  end

  # This type of control is basically just a div with an ID, and the data
  # value is hyperlinked text with URL href
  # Parameters:
  # * someField - the field description object to display
  # * someForm - the form instance (from the template)
  # * tagAttrs - attributes for the div tag
  # * fd_suffix - a suffix to be appended to div name; indicates the
  #   level, if any, at which this text appears in the form hierarchy
  #
  # Returns: an HTML string containing the div with all specified
  #          attributes
  #
  def hyper_text(someField,
                  someForm,
                  tag_attrs={},
                  fd_suffix=nil)

    # Set the field name to the appropriate suffix level
    field_id = make_form_field_id(someField.target_field, fd_suffix)
    param_class_array = someField.getParam('class')
    class_array = ['static_text']
    if (param_class_array)
      # Copy it, so we don't modify the params version, which gets cached.
      class_array.concat(param_class_array)
    end
    tag_attrs = tag_attrs.merge(:id=>field_id, :class=>class_array.join(' '))

    # Check the html parse level, which determines the extent to which HTML
    # tags should be encoded/escaped.
    if someField.html_parse_level != 0
      tag_attrs.merge!(:htmlParseLevel=>someField.html_parse_level)
    end

    href_url = someField.getParam('href')
    if href_url != ''
      tag_attrs.merge!(:style=>'text-decoration:underline; color:blue;')
    end

    target = someField.target_field ;
    # Get the onclick parameter and add the appropriate info
    # Cannot use field observers as span is not a element in call
    # forms.elements. So, add explicitly as a inline onclick event.
    onclick_spec = someField.getParam('onclick')
    if !onclick_spec.blank?
      onclick_spec = onclick_spec.rstrip.chomp(';')
      param_start = onclick_spec.index('(') + 1
      func_name = onclick_spec[0..(param_start-2)]
      param_end = onclick_spec.length - 2
      params = String.new
      if (param_start < param_end)
        params = onclick_spec[param_start..param_end]
      end
      func_call = func_name + '(' + params + ')'
      tag_attrs.merge!(:onclick=>func_call)
      #func_call = 'function(event){' + func_name + '(' + params + ');}'
      #add_observer(target, 'click', func_call)
    end

    # Bullet lists have a maxRowChars attribute we need to add.
    #if (class_array) # bullet lists have a class attribute
    #  max_row_chars = someField.getParam('maxRowChars')
    #  tag_attrs['maxRowChars'] = max_row_chars if max_row_chars
    #end

    # Do not include the default value for things that are not static text.
    # (This gets called for text fields in controlled edit tables, when
    # @read_only_mode is set.)
    label =
      someField.control_type=='hyper_text' ? someField.default_value : ''

    if !someField.display_name.empty?
      label = someField.display_name
    end
    return content_tag(:a,label,tag_attrs)

  end

  # Returns HTML for a text area control.  The number of rows of visible
  # text can be set via the "rows" parameter of the control_type_details field.
  # Similarly, the number of columns can be set via the "cols" parameter.
  # Parameters:
  # * someField - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * tagAttrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the input field with all specified
  #          attributes
  def text_area_field(someField,
                      someForm,
                      tag_attrs={},
                      fd_suffix=nil)

    # Set the field name to the appropriate suffix level
    field_id = make_form_field_id(someField.target_field, fd_suffix)
    field_name = make_form_field_name(someField.target_field, fd_suffix)
    tag_attrs = tag_attrs.merge(:id=>field_id, :name=>field_name)

    num_rows = someField.getParam('rows')
    tag_attrs[:rows] = num_rows if num_rows
    num_cols = someField.getParam('cols')
    tag_attrs[:cols] = num_cols if num_cols
    width = someField.width
    tag_attrs = merge_tag_attributes(tag_attrs,{:style=>'width:'+width},true) if width

    output = content_tag('textarea', someField.default_value, tag_attrs)

    return output
  end


  # This returns the HTML for a templated text field (a.k.a. "fill in the
  # blanks.)
  #
  # Parameters:
  # * some_field - the field to display (a FieldDescripion)
  # * some_form - the form instance (from the template)
  # * tag_attrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  def template_field(some_field, some_form, tag_attrs, fd_suffix)
    text_field = non_list_text_field(some_field, some_form,
                                  merge_tag_attributes(tag_attrs,
                                  {:class=>'eventsHandled'}),fd_suffix)
    template_id = some_field.getParam('template_id')
    template = TextTemplate.find_by_id(template_id).template
    field_id = make_form_field_id(someField.target_field, fd_suffix)
    output = text_field + helpButton(some_field)
    @form_field_js << render({:partial=>'form/template_field.rhtml', :handlers=>[:erb],
                     :locals=>{:id=>field_id,
                               :template=>template}})
  end

  #
  # This returns the HTML for a CAPTHA text field
  # Parameters:
  # * some_field - the field to display (a FieldDescripion)
  # * some_form - the form instance (from the template)
  # * tag_attrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  def captcha_field(some_field, some_form, tag_attrs, fd_suffix)
     render({:partial=>'form/captcha_field.rhtml', :handlers=>[:erb],
         :locals=> {:required =>some_field.required, :class_names=> tag_attrs[:class]}}).html_safe
  end

  # This returns the HTML for a header templated text field (for now username)
  #  (Should be parametrized later for other fields/templates. file name would
  #  be a parameter)
  # Parameters:
  # * some_field - the field to display (a FieldDescripion)
  # * some_form - the form instance (from the template)
  # * tag_attrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  def view_template_field(some_field, some_form, tag_attrs, fd_suffix)
    field_id = make_form_field_id(some_field.target_field, fd_suffix)
    template = some_field.getParam('template')
    output = render({:partial=>'form/'+template+'_field.rhtml', :handlers=>[:erb],:locals=>{:id=>field_id}})
  end

  def big_static_text(someField,
                  someForm,
                  tag_attrs={},
                  fd_suffix=nil)

    # Set the field name to the appropriate suffix level
    field_id = make_form_field_id(someField.target_field, fd_suffix)
    class_array = someField.getParam('class')
    param_class_array = [] if (!class_array)
    class_array = ['big_static_text']
    if (param_class_array)
      # Copy it, so we don't modify the params version, which gets cached.
      class_array.concat(param_class_array)
    end
    tag_attrs = tag_attrs.merge(:id=>field_id, :class=>class_array.join(' '))

    width = someField.getParam('width')
    tag_attrs = merge_tag_attributes(tag_attrs,{:style=>'width:'+width},true) if width
    height = someField.getParam('height')
    tag_attrs = merge_tag_attributes(tag_attrs,
                {:style=>'height:'+height},true) if height
    tag_attrs = merge_tag_attributes(tag_attrs,
                {:style=>'overflow:auto'},true) if (height || width)

    output = content_tag('div', someField.default_value.html_safe, tag_attrs)

    return output
  end

  # Returns the HTML for a password field.  This is called "passwd_field"
  # to avoid the conflict with the Rails "password_field" (which ultimately
  # gets used).
  #
  # Parameters:
  # * some_field - the field to display (a FieldDescripion)
  # * some_form - the form instance (from the template)
  # * tag_attrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  def passwd_field(some_field, some_form, tag_attrs, fd_suffix)
    target = some_field.target_field
    target += fd_suffix if !fd_suffix.nil?
    # change target_field if it is within a loinc panel
    target = target_field_for_panel(target)

      tag_attrs = merge_tag_attributes(tag_attrs,
                        {:autocomplete=>'off'})
    output = some_form.password_field(target.to_sym, tag_attrs)
    return output
  end

  ########################### Public Utility Methods ###########################

  # These methods are used by the other methods in this AND other modules
  # to accomplish common tasks.  PLEASE keep them in alphabetical order
  # so that they're easy to find.  Thanks.  lm
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  # Returns the local variables related to the data request that can occur
  # after a user makes a selection from an autocompletion list.
  #
  # Parameters:
  # * some_field - the FieldDescription for which the autocompleter is being
  #   constructed.
  #
  # Returns:
  #    A hash map for the parameters needed by the
  # _answer_list_prefetch.rhtml and _search_field.rhtml files.  The values are
  # returned this way for easy merging with the :locals hashmap used by the
  # render command.
  def data_req_params(some_field, db_field_id=nil)
    data_url = nil;
    data_req_input = nil;
    field_group_header = some_field.group_header
    output_to_same_group = true

    data_req_output = some_field.data_req_output
    if data_req_output
      # The presence of data_req_output means the field should issue a
      # data request after the user makes a selection.
      if db_field_id
        data_url_options = {:controller=>'form',
                            :action=>'handle_data_req_for_db_field',
                            :db_id=>db_field_id}
      else
        data_url_options = {:controller=>'form',
                            :action=>'handle_data_req',
                            :fd_id=>some_field.id}
      end
      if (!@isLoincPanel.nil?)
        data_url_options.merge!({:p_sn=>@loincPanelSN})
      end
      data_url = url_for(data_url_options)

      data_req_input = some_field.getParam('data_req_input')
      data_req_input_fields = nil
      if data_req_input
        data_req_input_fields = []
        data_req_input.each do |key, value|
          data_req_input_fields << target_field_for_panel(value)
        end
      end
      data_req_output_fields = nil
      data_req_output_fields = []
      data_req_output.each do |key, val_array|
        # As we go through the output fields, we need to check to see whether
        # they are in the same row of a table as some_field.
        if (output_to_same_group)
          other_field =
            some_field.form.field_descriptions.find_by_target_field(val_array)
          if (!other_field.nil?)
            other_group_header = other_field.group_header
            output_to_same_group = other_group_header == field_group_header
          else
            output_to_same_group = false
          end
        end
        data_req_output_fields.concat(
          val_array.collect {|v| target_field_for_panel(v)})
      end
    end


    return {:dataUrl=>data_url,
            :dataReqInput=>data_req_input_fields,
            :dataReqOutput=>data_req_output_fields,
            :outputToSameGroup=>output_to_same_group}
  end # data_req_params


  # Creates a hash of parameters needed for a prefetch autocompleter.
  #
  # Parameters:
  # * some_field - the field description object for the form field to which
  #   the autocompleter will be attached
  # * id - the form field id to be assigned to the :id key in the hash
  # * sysform_name - the system form name
  #
  # Returns: a hash containing the parameters
  #
  def prefetch_autocompleter_params(some_field, id, sysform_name =nil)

    heading_map = nil

    # Get the data for the field:
    #
    # List fields can now contain lists of user data, which must be obtained
    # after the form is built (because the form is cached) via an AJAX call.
    # Such lists are indicated by the search_table parameter starting with
    # the string "user ".
    search_table = some_field.getParam('search_table')
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
        col_names = some_field.getParam('fields_displayed')

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

        # To avoid having a list that is generated by another field
        # (through a recordDataRequester), either don't specify the
        # search_table - or the list_name if it's a TextList - OR
        # if the search_table must be specified for subsequent processing,
        # specify a condition that can never evaluate to true (1=2).
        #
        if !is_dynamically_loaded &&
           (!@dro_targets || !@dro_targets.include?(some_field.target_field))
          list_name = some_field.getParam('list_id')
          list_name = some_field.getParam('list_name') if list_name.nil?
          if table_class.respond_to?('get_list_items')
            field_conditions = some_field.getParam('conditions')
            if field_conditions &&
               ["PHR","SYSTEM_FORM"].include?(field_conditions[0]) &&
               sysform_name
              field_conditions[0] = sysform_name
            end
            # Get the list items and the map from items to headings
            # The map might not be there.
            list_data = table_class.get_list_items(
                                              list_name,
                                              nil,
                                              some_field.getParam('order'),
                                              field_conditions)
            if list_data.length > 0
              item_class= list_data[0].class
              if item_class.respond_to?('map_to_heading_code')
                heading_map = item_class.map_to_heading_code(list_data)
              end
            end
          end
        end
      end
    end # if we have a search table
    if !list_data
      list_data = []
      code_vals = nil
    else
      code_vals = get_list_item_codes(list_data, some_field.list_code_column)
    end

    # Get the rest of the parameters to be passed to the autocompleter
    match_list = some_field.getParam("match_list_value", false)
    add_seqnum = some_field.getParam("add_seqnum", false)
    user_data_url = nil

    if (is_user_data)

      # Construct an url for accessing the data list for the field via AJAX
      user_data_url = url_for({:controller=>'form',
                               :action=>'get_user_data_list',
                               :fd_id=>some_field.id})
    end

    order = some_field.getParam('order') ;
    # Create the local variables for the template
    default_val = @field_defaults ? @field_defaults[some_field.target_field] :
      some_field.field_default_value
    locals = {:id=>id,
              :code_vals=>code_vals,
              :order=>order,
              :matchListValue=>match_list,
              :auto_fill=>some_field.auto_fill,
              :suggestionMode=>some_field.suggestion_mode,
              :item_to_heading=>heading_map,
              :default_value=>default_val
             }

    option_list = make_auto_completion_list_items(list_data, col_names)
    # special handling for merging a list with data from a user table
    merge_data_param = some_field.merge_user_list_data
    if !merge_data_param.blank? && @user
      # assume there's just one column in the "field_displayed"
      option_list = get_merged_user_list_data(merge_data_param,
        option_list)
    end

    locals = locals.merge({:is_user_data=>is_user_data,
        :user_data_url=>user_data_url,
        :add_seqnum=>add_seqnum,
        :optList=>option_list,
        :added=>'false'})

    return locals
  end # prefetch_autocompleter_params


  def retrieve_sysform_name(form_instance)
    form_instance && (t = form_instance.instance_variable_get("@template")) &&
      (s = t.instance_variable_get("@system_form")) && s.form_name
  end



  # Creates a hash of parameters needed for a search autocompleter.
  #
  # Parameters:
  # * someField - the field description object for the form field to which
  #   the autocompleter will be attached
  # * id - the form field id to be assigned to the :id key in the hash
  #
  # Returns: a hash containing the parameters
  #
  def search_autocompleter_params(some_field, id, db_id=nil)

    # Results for a search field can be displayed either as a list.
    # Create an URL to be used to display the results as a list
    action_name = 'get_search_res_list'
    results_url_options = {:controller=>'form',
                           :action=>action_name,
                           :fd_id=>some_field.id,
                           :db_id=>db_id
                           }
    results_url = url_for(results_url_options)

    # Get the rest of the parameters needed for the autocompleter
    no_button = some_field.getParam('no_button')=='1'
    #quoted_button_id = no_button ? 'null' : '\''+id + '_button\''
    button_id = no_button ? nil : "#{id}_button"

    match_list = some_field.getParam("match_list_value", false)
    if (match_list.nil?)
      match_list = false
    end
    locals_hash = {:id=>id,
                   :resultsUrl=>results_url,
                   :autocomp=>some_field.getParam('auto')=='1',
                   :some_field=>some_field,
                   :no_button=>no_button,
                   #:quoted_button_id=>quoted_button_id,
                   :button_id=>button_id,
                   :matchListValue=>match_list,
                   :suggestionMode=>some_field.suggestion_mode
                  }
    return locals_hash
  end # search_autocompleter_params


  # Creates a hash of parameters needed for a search autocompleter based on
  # list description record
  #
  # Parameters:
  # * someField - the field description object for the form field to which
  #   the autocompleter will be attached
  # * form_field_id the id of the form field for the autocompleter
  # * list_id - the id of list description record
  #
  # Returns: a hash containing the parameters
  def search_autocompleter_params_by_list_desc(some_field, form_field_id, list_id)
    # Results for a search field can be displayed either as a list.
    # Create an URL to be used to display the results as a list

    action_name = 'get_search_res_list_by_list_desc'
    results_url_options = {:controller=>'form',
                           :action=>action_name,
                           :fd_id=>some_field.id,
                           :list_id=>list_id}
    results_url = url_for(results_url_options)

    # Get the rest of the parameters needed for the autocompleter
    no_button = some_field.getParam('no_button')=='1'
    #quoted_button_id = no_button ? 'null' : '\''+ form_field_id + '_button\''
    button_id = no_button ? nil : "#{form_field_id}_button"

    match_list = some_field.getParam("match_list_value", false)
    if (match_list.nil?)
      match_list = false
    end
    locals_hash = {:id=>form_field_id,
                   :resultsUrl=>results_url,
                   :autocomp=>some_field.getParam('auto')=='1',
                   :some_field=>some_field,
                   :no_button=>no_button,
                   #:quoted_button_id=>quoted_button_id,
                   :button_id=>button_id,
                   :matchListValue=>match_list,
                   :suggestionMode=>some_field.suggestion_mode
                  }
    return locals_hash
  end # search_autocompleter_params_by_list_desc


  private ###########################  Private Methods ###################

  # Creates a text field that does not have an associated list (but might
  # have JavaScript validation).
  #
  # Parameters:
  # * some_field - the field to display (a FieldDescripion)
  # * some_form - the form instance (from the template)
  # * in_table - flag indicating whether or not this field is in a
  #   horizontal table
  # * tag_attrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  # * target - (optional) the target field name, plus a suffix, plus any
  #   needed modifications if the field is a panel field.  If this is not
  #   provided, it will be computed.
  # Returns: an HTML string containing the input field with all specified
  #          attributes
  #
  def non_list_text_field(some_field,
                       some_form,
                       in_table,
                       tag_attrs={},
                       fd_suffix=nil, target=nil)
    if !target
      target = some_field.target_field
      target += fd_suffix if !fd_suffix.nil?
      # change target_field if it is within a loinc panel
      target = target_field_for_panel(target)
    end

    # If this field is not in a horizontal table and there's a width
    # specification, add it to the attributes
    if (!in_table && !some_field.width.nil?)
      merge_tag_attributes!(tag_attrs, {:style=>'width: ' + some_field.width})
    end

    if some_field.wrap?
      text_field_type = :text_area
      merge_tag_attributes!(tag_attrs, {:class=>'wrap', :spellcheck=>false})
      # At the moment, the only case we have for this is when the field
      # is in a table.
      add_observer(some_field.target_field, 'keyup',
        'Def.FieldsTable.resizeTableFieldHeight')
    else
      text_field_type = :text_field
    end

    output = some_form.send(text_field_type,
      target.to_sym, merge_tag_attributes!(tag_attrs, {:autocomplete=>'off'}))

    return output
  end # non_list_text_field


  # Creates a text field that has an associated list (and might also
  # have JavaScript validation).
  #
  # Parameters:
  # * some_field - the field to display (a FieldDescripion)
  # * some_form - the form instance (from the template)
  # * in_table - flag indicating whether or not this field is in a
  #   horizontal table
  # * tag_attrs - attributes for the text field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the input field with all specified
  #          attributes
  #
  def text_field_with_list(some_field,
                           some_form,
                           in_table,
                           tag_attrs={},
                           fd_suffix=nil)

    # Get the classes for the field
    class_array = some_field.getParam('class');
    class_array = [] if !class_array
    attrs_class = tag_attrs['class']
    class_array << attrs_class if attrs_class
    tag_attrs['class'] = class_array.join(' ') if class_array.size > 0

    target = some_field.target_field
    target += fd_suffix if !fd_suffix.nil?
    # change target_field if it is within a loinc panel
    target = target_field_for_panel(target)
    html_output = non_list_text_field(some_field, some_form, in_table,
                                      tag_attrs, fd_suffix, target)

    # Get the autocompleter parameters and merge them with any data_req
    # parameters.  Then feed them to the appropriate partial, sending the
    # output to the buffer that holds the javascript to be output to a
    # separate file (not directly on the page).

    id = make_form_field_id(target)

    sysform_name = retrieve_sysform_name(some_form)
    locals = prefetch_autocompleter_params(some_field, id, sysform_name)
    locals = locals.merge(data_req_params(some_field))
    @form_field_js << render({:partial=>'form/answer_list_prefetch.rhtml', :handlers=>[:erb],
                                :locals=>locals}).html_safe
    # Return the output buffer, which contains the HTML for the actual
    # text input field.
    return html_output

  end # text_field_with_list


  ########################## Private Utility Methods ###########################

  # These methods are used by the other methods ONLY in this module
  # to accomplish common tasks.  PLEASE keep them in alphabetical order
  # so that they're easy to find.  Thanks.  lm
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  # merge the data from a user table and the list data
  # one display column only for now
  #
  # Parameters:
  # * strParam - the parameter set in field_descriptions table's
  #           merge_user_list_data column, in the following format:
  #           <type>.<user_table_name>.<text_column>.<code_column>
  #
  #           type: 'PERUSER', required, search in the current user's data
  #                             (or per form_record?)
  #                 'ALLUSER', required, all user's data
  #           user_table_name: required,
  #           text_column: required, where the text is stored
  #           code_column: optional, where the code is stored, not used for now
  #
  #         Example: 'PERUSER.obr_orders.test_place'
  #
  # * listData - regular list data
  #
  # Returns: the merged list data array
  #
  def get_merged_user_list_data(strParam, listData)
    merged_list = [] | listData
    params = strParam.split('.')
    if !params.nil? && (params.length ==3)
      table_name = params[1]
      column_name = params[2]
#      query_str = 'SELECT DISTINCT ' + column_name + ' FROM ' + table_name +
#         ' a '
      table_class = table_name.singularize.camelcase.constantize
      results = table_class.select(column_name).distinct
      # per user
      if params[0] == 'PERUSER'
#        query_str = query_str + ' , profiles_users b WHERE a.profile_id=' +
#            'b.profile_id and b.user_id=' + @user.id.to_s
        results.joins("INNER JOIN profiles_users ON " +
            "#{table_name}.profile_id=profiles_users.profile_id AND " +
            "profiles_users.user_id=#{@user.id.to_s}")
        # or checking form_record_id is needed??
      end
 #     query_str = query_str + ' ORDER BY a.' + column_name + ' ASC '
      results.order("#{table_name}.#{column_name} ASC")

#      results = table_class.find_by_sql(query_str)
      if results.exists?
        results.each do |record|
          item = record.send(column_name)
          if !item.blank? && !listData.include?(item)
            merged_list << item
          end
        end
      end
    end
    return merged_list
  end


  # Constructs the array of strings seen by the user when viewing an
  # auto-completion list (and returns it).  This also takes care of
  # html-encoding the strings.
  #
  # Parameters:
  # * list_data - an array of model objects containing the data for the items
  #   in the list
  # * fields - the names of the fields of the model objects that should be
  #   combined into the displayed list item.  (Example: ['code', 'item_text']).
  #
  # Returns: the array of strings
  #
  def make_auto_completion_list_items(list_data, fields)
    rtn = []
    if fields
      list_data.each do |li|
        item_strings = []
        fields.each {|f| item_strings << li.send(f)}
        rtn << item_strings.join(TABLE_FIELD_JOIN_STR)
      end
    end
    return rtn
  end # make_auto_completion_list_items


  # Constructs and returns an array of list item codes.  The returned
  # code values will be strings.
  #
  # Parameters:
  # * list_data - an array of model objects containing the data for the items
  #   in the list
  # * code_field - the name of the field in the model objects that contains
  #   the code.  If this is nil, 'code' will be used, unless the model objects
  #   don't respond to that method, in which case the 'id' field will be used.
  def get_list_item_codes(list_data, code_field=nil)
    rtn = []
    if list_data.size > 0
      if !code_field
        code_field = 'code'
        if !list_data[0].respond_to?(code_field)
          code_field = 'id'
        end
      end
      list_data.each {|li| rtn << li.send(code_field).to_s}
    end
    return rtn
  end

end # TextFieldsHelper
