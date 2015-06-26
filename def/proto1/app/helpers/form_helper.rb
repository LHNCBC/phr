module FormHelper

  include ButtonsHelper
  include ComboFieldsHelper
  include DateFieldsHelper
  include FieldsGroupHelper
  include ImageHelper
  include RuleHelper
  include PanelTestHelper
  include TextFieldsHelper


  # Builds a field label and the appropriate type of input mechanism
  # (display only, answer lists, auto complete, etc) for a field.
  # This is the main controlling point for the form field building
  # process.
  #
  # Parameters:
  # * someField - the field to display (a FieldDescription)
  # * someForm - the form instance (from the template)
  # * in_table - a boolean value that indicates whether or not the
  #   field to be processed is to be located in a table cell.  Optional;
  #   set to false if not passed in.
  # * tagAttrs - attributes for the field tags
  # * fd_suffix - a suffix to be appended to field names; indicates the
  #   level, if any, at which this field appears in the form hierarchy.
  #
  # Returns:
  #  IF in_table is false,
  #     a string buffer containing the HTML created for the field
  #  ELSE
  #     an array containing the updated tagAttrs in the first element
  #     and a string buffer containing the HTML created for the field
  #     in the second element
  #
  # NOTE:  All fields, including group headers and subform buttons,
  #        need an id that consists of "fe_" followed by the corresponding
  #        target_field name.  This is required for field dependencies to
  #        work correctly (i.e., be able to find the target field).
  #
  def displayField(someField,
                   someForm,
                   in_table = false,
                   tag_attrs  = nil,
                   fd_suffix = nil)

    omit_field = false
    if @access_level == ProfilesUser::READ_ONLY_ACCESS
      classes = someField.getParam('class')
      if !classes.blank? && classes.include?('no_read_only')
        omit_field = true
      else
        ro_display = someField.getParam('read_only_display_name')
        if !ro_display.nil?
          if someField.control_type == 'static_text'
            someField.default_value = ro_display
          else
            someField.display_name = ro_display
          end
        end
      end
    end

logger.debug ''
logger.debug 'in displayField, processing target_field = ' +
             someField.target_field + '; fd_suffix = ' + fd_suffix.to_s +
             '; omit_field = ' + omit_field.to_s
logger.debug ''

    if !omit_field

      target = someField.target_field
      target += fd_suffix if !fd_suffix.blank?

      @next_line = '
      '.html_safe
      if (tag_attrs.blank?)
        tag_attrs = Hash.new
      end

      tag_attrs = add_common_attributes(someField, tag_attrs, fd_suffix)

      # add tooltip as an attribute
      tooltip = someField.getParam('tooltip')
      if (!tooltip.nil?)
        if someField.control_type == 'button' ||
           someField.control_type == 'calendar'
          merge_tag_attributes!(tag_attrs, {:title=>tooltip.strip.to_s})
        else
          merge_tag_attributes!(tag_attrs, {:tipValue=>tooltip.strip.to_s,
                                            :autocomplete=>'off'})
        end
      end

      # Now build the full output for the field based on the control
      # type for the field.  Please keep the case statement alphabetized
      # by control type so they're easy to find.  thanks.  lm

      output = nil;
      control_type = someField.control_type
      if @read_only_mode # e.g. controlled-edit table
        # Render fields using read-only controls
        if control_type == 'text_field' || control_type =='search_field' ||
           control_type == 'text_area' || control_type == 'calendar' ||
           control_type == 'time_field'
          control_type = 'static_text'
        end
        # TBD - check boxes?  (No current use case.)
      end

      # setup validations for the input field
      set_validator(someField)

      # PLEASE keep these when statements in alphabetical order by control_type
      case control_type
      when 'big_static_text'
        output = big_static_text(someField,
                                 someForm,
                                 tag_attrs,
                                 fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'button'
        output = button(someField, tag_attrs, fd_suffix)

      when 'calendar'
        output = dateField(someField,
                           someForm,
                           in_table,
                           tag_attrs,
                           fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'time_field'
        output = timeField(someField,
                           someForm,
                           in_table ,
                           tag_attrs,
                           fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'captcha_field'
        output = captcha_field(someField,
                               someForm,
                               tag_attrs,
                               fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'check_box', 'check_box_display'
        output = make_checkbox(someField,
                               someForm,
                               in_table,
                               tag_attrs,
                               fd_suffix)
      when 'combo_field'
        output = combo_field(someField,
                             someForm,
                             tag_attrs,
                             fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'expcol_button'
        output = expcol_button(someField,
                               someForm,
                               tag_attrs,
                               fd_suffix)

      when 'group_hdr'
        sub_fields = someField.sub_fields
        if (sub_fields.size > 0)
          output = process_fields_group(someField,
                                        sub_fields,
                                        someForm,
                                        tag_attrs,
                                        fd_suffix)
          # else treat it as an empty header
        else
          output = "<h2 class=\"emptyHeader\">#{someField.display_name}</h2>"
        end
      when 'hyperlinked_text'
        output = hyper_text(someField,
                            someForm,
                            tag_attrs,
                            fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end
      when 'image'
        output = make_image_content(someField,
                                    someForm,
                                    tag_attrs,
                                    fd_suffix)
      when 'loinc_panel'
        output = ''
        # keep track of the number of loinc panels processed
        @isLoincPanel = true
        @loincPanelSN = 1 if @loincPanelSN.nil?
        panel_grp_fields = someField.get_panel_fields()
        panel_grp_fields.each do |panelField|
          panel_output = displayField(panelField,
                                      someForm,
                                      in_table,
                                      tag_attrs,
                                      fd_suffix)

          if (in_table)
            output += panel_output[1]
          else
            output += panel_output
          end
          #   output += panel_output
        end
        @loincPanelSN +=1
        @isLoincPanel = nil

      # Specialized buttons are being phased on.  Use the generic button
      # structure.  See the reminders button on the main PHR for an example and
      # buttons_helper.rb for further info
      #when 'message_button'
      #  output = message_button(someField,
      #                          someForm,
      #                          tagAttrs,
      #                          fd_suffix)
      when 'panel_view'
        output = timeline_div(someField,
                               someForm,
                               tag_attrs,
                               fd_suffix)

      when 'password_field'
        output = passwd_field(someField, someForm, tag_attrs, fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'print_button'
        output = print_button(someField,
                              someForm,
                              tag_attrs,
                              fd_suffix)
      # a group of radio buttons
      when 'radio_button_grp'
        output = make_radio_button_grp(someField,
                              someForm,
                              tag_attrs,
                              fd_suffix)

      # used in panel flowsheet only
      when 'static_table'
        output = static_table(someField,
                             someForm,
                             in_table,
                             tag_attrs,
                             fd_suffix)

      when 'search_field'
        output = searchField(someField,
                             someForm,
                             in_table,
                             tag_attrs,
                             fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'static_text'
        output = static_text(someField,
                             someForm,
                             tag_attrs,
                             fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'template_field'
        output = template_field(someField, someForm, tag_attrs, fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

        #      when 'test_panel'
        #        output = ''
        #        # replace this field with corresponding panel group
        #        # Note: each panel has only one top level group currently
        #        # then handle it like 'group_hdr' field
        #        panel_grp_fields = someField.get_panel_fields()
        #        panel_grp_fields.each do |panelField|
        #          panel_output = displayField(panelField,
        #                       someForm,
        #                       in_table,
        #                       tagAttrs,
        #                       fd_suffix)
        #          output += panel_output
        #        end

      when 'text_area'
        output = text_area_field(someField,
                                 someForm,
                                 tag_attrs,
                                 fd_suffix)

        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'text_field'
        output = textField(someField,
                           someForm,
                           in_table ,
                           tag_attrs,
                           fd_suffix)
        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      when 'view_template_field'
        output = view_template_field(someField,
                             someForm,
                             tag_attrs,
                             fd_suffix)

        if (!in_table)
          output = add_field_division(output, someField, fd_suffix, tag_attrs)
        end

      # PLEASE add any new when statements in alphabetical order by control type
      #  - NOT here at the end (unless it fits alphabetically)
      #
      # If we've run out of control types, signal a problem.
      else
        raise 'Field processed with unrecognized control_type config.' +
              '  Display_name = ' + someField.display_name.to_s
      end #case

      # Note:  In the case of date fields, the date field event handler
      # that updates the _ET and _HL7 fields needs to run before the form rule
      # event handler, which is one of the "common event handlers" added below.
      add_common_event_handlers(someField)

      if (output.blank? && @form_data_display.blank?)
        logger.debug '!!!!!!!!!!  amassed no output for target_field ' +
                    someField.target_field
        output = 'Field info missing for ' + someField.display_name
      end

      if (!@extra_output.blank?)
        output += @extra_output
      end
      output = output.html_safe
      if (in_table)
        rtn =  Array[tag_attrs, output]
      else
        rtn =  output
      end
    end # if not omit_field
  end # displayField


  ########################### Utility Methods ########################

  # These methods are used by the other methods in this and other modules
  # to accomplish common tasks.  PLEASE keep them in alphabetical order
  # so that they're easy to find.  Thanks.  lm
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  # This adds the tag attributes to a field that are common to all, or
  # almost all, field/control types.
  #
  # Parameters:
  # * some_field - the field definition
  # * tag_attrs - the attributes hash to receive the attributes
  # * fd_suffix - the field suffix
  #
  # Returns: tag_attrs
  #
  def add_common_attributes(some_field, tag_attrs, fd_suffix)

    # Turn off Rails default field size of 30
    tag_attrs = merge_tag_attributes(tag_attrs, {:size=>nil})

    # Required attributes:
    tag_attrs = mark_as_required(some_field, tag_attrs)

    # DEFAULT VALUE attributes:
    # We used to put this as an attribute for the tag, but now the plan
    # is to only show the default value when the user arrives in the field.
    # However, we still need the default value for the value of buttons.
    default_val = some_field.field_default_value
    if (!default_val.blank?)
      if (some_field.control_type == 'button')
        tag_attrs = merge_tag_attributes(tag_attrs,
                                     {:value=>default_val})
      else
        @field_defaults = {} if !@field_defaults
        @field_defaults[some_field.target_field] = default_val
      end
    end

    # CLASS SPECIFICATION attribute
    if (!some_field.getParam('class').blank?)
      field_classes = some_field.getParam('class')
      tag_attrs = merge_tag_attributes(tag_attrs,
                                     {:class=>field_classes.join(' ')})
      if field_classes.index('hidden_field')
        # Turn off the browser's autofill if the field is hidden.
        tag_attrs['autocomplete']='off'
      end
    end

    # EDITABLE attributes
    editable = some_field.editable?(!@edit_action)
    if (!editable)
      merge_tag_attributes!(tag_attrs, {:readonly=>true,
                                        :class=>'readonly_field'})
      edit_param = some_field.getParam('edit')
      if (edit_param=='3' || edit_param=='4')
        merge_tag_attributes!(tag_attrs, {:class=>'inlineedit'})
      end
    end

    editor = some_field.editor
    if (editor && editor == 2)
      ref_fd = some_field.getEditorParam('ref_fd')
      val_fd = some_field.getEditorParam('val_fd')
      ref_target = target_field_for_panel(ref_fd)
      val_target = target_field_for_panel(val_fd)
      tag_attrs = merge_tag_attributes(tag_attrs, {:ref_fd=>ref_target,
                                                   :val_fd=>val_target,
                                                   :mFieldBoxListener=>true})
    end

    return tag_attrs
  end # add_common_attributes


  # This adds the event handlers to a field that are common to all, or
  # almost all, field/control types.
  #
  # Parameters:
  # * some_field - the field definition
  # * is_combo_field - optional flag indicating that this is being invoked
  #   for a combo_field that is mimicing another type; default is false.
  #   Not set for initial creation of the combo_field - just when it is
  #   being reset as another type.
  #
  # Returns: nothing
  #
  def add_common_event_handlers(some_field, is_combo_field = false)
    target = target_field_for_panel(some_field.target_field)

#    # setup validations for the input field
#    set_validator(some_field)

    # onChange event listener for TaffyDB on all fields that are connected
    # with user data.
    if !some_field.db_field_description_id.nil?
      # This should be added before the rule handler (for form rules) which is
      # added below, or else the data model and data rules might be out of date
      # when the form rules run.
      add_observer(target, 'change',
        'function(event){Def.DataModel.formFieldUpdateHandler(event);}')
    end

    # TOOLTIPS
    # Combo fields get the tooltip setup stuff whether or not they start out
    # with a tooltip.  This is because they can pick one up in the process of
    # being transformed to a certain field type.
    if (some_field.control_type != 'button') && (some_field.control_type != 'calendar')
      tooltip = some_field.getParam('tooltip')

      if (!tooltip.nil?) || (is_combo_field)
        add_observer(target, 'load', 'function(theField){Def.onTipSetup(theField);}')
        add_observer(target, 'focus', 'function(event){Def.onFocusTip(this);}')
        add_observer(target, 'blur', 'function(event){Def.onBlurTip(this);}')
        if !is_combo_field && @tip_fields[target].nil?
          @tip_fields[target] = [target]
        end
      end
    end

    # EDITABLE handlers
    # Due to a cross browser issue on IE9, Def.enterInlineEdit should be called before Def.clickedTextSelector.onclick
    # so that the backspace keydown event on a selected text field won't trigger page unload event
    # See #3182 for details - Frank
    editable = some_field.getParam('edit')
    # attributes handled in add_common_attributes
    if (editable && editable == '3' || (@edit_action && editable =='4'))
      add_observer(target, 'click',
        'function(event){Def.enterInlineEdit(this);}')
      add_observer(target, 'blur',
        'function(event){Def.leaveInlineEdit(this);}')
      add_observer(target, 'focus',
        'function(event){Def.focusInlineEdit(this);}')
    end

    # Things with input type="text" fields
    field_classes = some_field.getParam('class')
    if ((some_field.control_type=='text_field' ||
         some_field.control_type=='search_field' ||
         some_field.control_type=='calendar' ||
         some_field.control_type=='time_field') &&
         (field_classes.nil? ||
          (field_classes && !(field_classes.include?('hidden_field') ||
              field_classes.include?('fake_password')) )))
      # Large Edit Box editor
      if (some_field.editor == 1)
        add_observer(target, 'keydown', 'LargeEditBox.srcKeyEventHandler')
      else
        if (some_field.editor ==2) # multi-field edit box editor
          add_observer(target, 'keydown', 'MultiFieldBox.srcKeyEventHandler')
          add_observer(target, 'focus', 'MultiFieldBox.srcOnFocusHandler')
        end
        add_observer(target, 'focus', 'Def.ClickedTextSelector.onfocus')
        add_observer(target, 'click', 'Def.ClickedTextSelector.onclick')
        add_observer(target, 'blur', 'Def.ClickedTextSelector.onblur')
        add_observer(target, 'mousedown', 'Def.ClickedTextSelector.onmousedown')
      end
    end
    # Rules handler
    add_rule_handler(some_field, target)

    # check the field description for an onchange event handler that we
    # haven't anticipated above.
    onchange_spec = some_field.getParam('onchange')
    if !onchange_spec.blank?
      func_call = 'function(event){' + onchange_spec +'}'
      add_observer(some_field.target_field, 'change', func_call)
    end

    # check the field description for an onfocus event handler that we
    # haven't anticipated above.
    onfocus_spec = some_field.getParam('onfocus')
    if !onfocus_spec.blank?
      func_call = 'function(event){' + onfocus_spec +'}'
      add_observer(some_field.target_field, 'focus', func_call)
    end

    onblur_spec = some_field.getParam('onblur')
    if !onblur_spec.blank?
      func_call = 'function(event){' + onblur_spec +'}'
      add_observer(some_field.target_field, 'blur', func_call)
    end

    # If this is an autocompleter field that is flagged for list usage
    # tracking, add an onload observer to call the usage monitor function
    # that will set the event observers on the field
    if LIST_FIELDS_TRACKED.include?(some_field.target_field)
      func_call = 'function(theField){Def.UsageMonitor.setObservers(theField);}'
      add_observer(some_field.target_field, 'load', func_call)
    end

  end # add_common_event_handlers


  # This wraps the HTML for a field control in a field division and
  # adds a field label if appropriate.  This should not be invoked
  # for fields that are to be displayed in a horizontal table.
  #
  # This includes adding the help button after the input field, if
  # any help text is specified for the field AND the required icon
  # before the label if a label is appropriate for the field.
  #
  # The help button is not added here for fields with a control_type
  # of search_field.  It's added in _search_field.rhtml in that case
  # because it needs to come after the search button.
  #
  # Parameters:
  # * field_control - the HTML for the input field control
  # * someField - the field definition
  # * fd_suffix - the field suffix
  #
  # Returns: tag_attrs
  #
  def add_field_division(field_control, someField, fd_suffix, tagAttrs)

    label = build_field_label(someField, fd_suffix)
    classes = 'field'
    if (!tagAttrs[:class].blank?)
      #classes = 'field ' + tagAttrs[:class]
      # Make sure this wrapper will not be wrongly treated as a required field
      classes = 'field ' + tagAttrs[:class].gsub(/\s*required\s*/,"")
    end

    if (!label.blank?)
      output = '<div class="' + classes + '">' + @next_line +
               label + field_control
    else
      output = '<div class="' + classes + '">' + @next_line + field_control
    end

    if (someField.control_type != 'search_field')
      output +=  add_unit(someField) + add_range(someField)
      if (!(someField.control_type == 'calendar' && someField.getParam('calendar')))
        output += helpButton(someField)
      end
    end
    # No break needed here
    if !(someField.control_type == 'calendar' && !someField.help_text.blank?)
       output += @next_line #+ '<br clear=left>' # It seems this br is no longer needed; removing it helps the medical contacts comment field
    end
       output += '</div>'.html_safe
    return output

  end # add_field_division


  # This adds an entry to the @field_observers hash, which is used to
  # create event observers on form fields when the form is loaded.
  #
  # Parameters
  # * target_field - the target_field value for the field to get the
  #   observer.  The observer will be set on all instances of the field.
  #   The target_field_for_panel method will be run on this field before
  #   it is used, so no need to do so beforehand.  Although it won't hurt
  #   if it's already been done (other than to take up time).
  # * event_type - the type of event for which the observer is to be
  #   created.  Use one of the javascript event types, such as blur, change,
  #   etc.  (Omit the 'on', i.e., instead of 'onblur', just use 'blur').
  # * func_call - the function call to be executed when the event occurs.
  #   This should be as specified in the field description, or as applied
  #   to all fields matching certain qualifications.
  def add_observer(target_field, event_type, func_call)

    target_field = target_field_for_panel(target_field)
    if @field_observers[target_field].nil?
      @field_observers[target_field] = {event_type => [func_call]}
    elsif @field_observers[target_field][event_type].nil?
      @field_observers[target_field][event_type] = [func_call]
    elsif !@field_observers[target_field][event_type].include?(func_call)
      @field_observers[target_field][event_type] << func_call
    end

  end # add_observer

  # This wraps the HTML for a field control in a field division and appends a
  # readonly text INPUT if "show_range" is specified in control_type_detail.
  # range is stored in contro_type_detail like "range=>10 - 200"
  #
  # Parameters:
  # * the_field - the field definition
  #
  # Returns: the HTML for the unit
  #
  def add_range(the_field)
    ret_range = ""
    if (the_field.getParam('show_range',false) &&
            !the_field.getParam('range',false).nil?)
      range =the_field.getParam('range',false)
      ret_range = "<input type='text' readonly='readonly' " +
            "class='range readonly_field' value='" + range + "'/>"
    end
    return ret_range
  end


  # If the field is a required field, mark it as required using a class name
  # called 'required'
  #
  # Parameters:
  # * the_field the field to be marked
  # * tag_attrs the existing attributes hash
  def mark_as_required(the_field, tag_attrs={})
    the_field.required ?
      merge_tag_attributes(tag_attrs, {:class=>"required"}) : tag_attrs
  end


  # This checks to see if a field is flagged as "required" - as in, some
  # input must be provided for the field.  If it is, this method returns
  # the icon we are using to flag those.  Otherwise it returns an empty
  # string.
  #
  # This is basically pulled out as a separate method for 2 reasons:
  # 1) so that if we change how we flag fields in the database as required,
  #    we only have to change the code once; and
  # 2) similarly, if we change the icon we're using, we only have to change
  #    the code once.
  #
  # Parameters:
  # * the_field - the field to check
  #
  # Returns: the required icon if appropriate; otherwise an empty string
  #
  def add_required_icon(the_field)
    the_field.required ? image_tag(asset_path('blank.gif'),
      :class=>"requiredImg sprite_icons-phr-required", :alt=>"required field") : "".html_safe
  end


  # This wraps the HTML for a field control in a field division and appends a
  # readonly text INPUT if "show_unit" is specified in control_type_detail.
  # unit is stored in column units_of_measure.
  #
  # Parameters:
  # * the_field - the field definition
  #
  # Returns: the HTML for the unit
  def add_unit(the_field)
    ret_unit = ""
    if (the_field.getParam('show_unit',false) &&
            !the_field.units_of_measure.nil?)
      units = the_field.units_of_measure
      ret_unit = "<input type='text' readonly='readonly' " +
            "class='unit readonly_field' value='" + units + "'/>"
    end
    return ret_unit.html_safe
  end


  # This checks a field definition to see if a general field label
  # is appropriate, and if so, builds the html for a label for the
  # form field.  This does NOT check to see if the field will be
  # displayed in a table.  That checking should be done outside of
  # this function.  All other checking should be done within this
  # function (so that it's not in multiple places).
  #
  # The label includes the required icon for fields flagged as
  # requiring input.
  #
  # The label is common to most control types.  If a particular
  # control type should not use the standard label, add code to
  # exclude it here.  For example, the check_box does not use
  # the standard label (makes the form look Picasso-ish) nor is
  # a label generated for fields with no display_name.
  #
  # A label is also not generated if a field is displayed within
  # a horizontal table.  It is generated whether or not the display_name
  # column for the field is empty, because the absence/presence of a
  # label is used by some helpers to signal other things.  Probably
  # should be changed - but not now.  lm, March 2008.
  #
  # Parameters:
  # * someField - the field definition
  # * fd_suffix - the field suffix
  #
  # Returns: the html output for the label
  #
  def build_field_label(someField, fd_suffix)
    # add width for label
    # added by Ye temporarily for demo 5/28/2008
    label_width = someField.getParam('label_width')
    if (label_width)
      style = ' style="width:' + label_width + ';"'
    else
      style = ''
    end

    if (someField.control_type != 'check_box' &&
        someField.control_type != 'captcha_field' &&
       !someField.display_name.nil? && !someField.display_name.empty?)
        #&&
        #((someField.control_type != 'static_text') ||
        # (someField.control_type == 'static_text' &&
        #  !someField.display_name.blank?)))
        if !someField.display_name.blank?
          # The leading empty string is used for making sure the concatenation
          # resulted in a string which hasn't been html encoded before being
          # converted into a BufferSafe object
           output_label = ("" + @next_line + '<label for="' +
                    make_form_field_id(someField.target_field +
                    fd_suffix.to_s) + '" id="' +
                    make_form_field_id(someField.target_field + '_lbl' +
                    fd_suffix.to_s) + '"' + style + '>' +
                    add_required_icon(someField) +
                    @next_line + someField.display_name() +
                    ':&nbsp;&nbsp;</label>').html_safe
        else
          output_label = ''
        end
    else
      output_label = nil
    end
    return output_label
  end # build_field_label


  # Does the inverse of "humanize".  In other words, it takes a name
  # with uppercase letters and blanks between words, and translates
  # it to all lowercase letters with underscores between words.
  # Parameters:
  # * upper_with_blanks_name - the name to be dehumanized
  # Returns: the dehumanized name
  def dehumanize(upper_with_blanks_name)
    upper_with_blanks_name.to_s.gsub(/ /, "_").downcase
  end


  # Looks for name of instance variables in #{} and performs a replacement.
  # Done after form generation to prevent caching of user specific values.
  # Allowed values are limited to those encountered in
  # field_descriptions.default_value.
  #
  # Parameters:
  # * output_string - the name to be dehumanized
  # * regexArr - array of regex which need to be evaluated in output_string
  # Returns: nil
  def replace_embedded_vars(output_string, regexArr)
    # regexArr comes from regexMap, built in an initializer from the
    # default_value fields of field_descriptons records.  It contains the
    # portions of default_value strings that start and end with "#{...}".
    # We avoid doing an actual eval here by requiring that the content
    # between those symbols be an instance variable, whose value is presumably
    # safe to insert given that the variable name was mentioned in a
    # default_value of a field for the form.
    # The reason we do not do this subsitution when building the HTML for
    # the field_descriptions is that that HTML is cached for all users.
    regexArr.each do |a|
      # Replace the instance variable name with the value.
      # a = "#{@instance_var_name}"
      output_string.gsub!(a,instance_variable_get(a[2..-2]))
    end
  end


  # Returns the HTML for a help button for the given field, or an empty
  # string if the field doesn't have help text.
  # Parameters:
  # * someField - the field to display (a FieldDescripion)
  # Returns: the HTML for a help button for the given field, or an empty string
  # if the field doesn't have help text.
  def helpButton(someField)
    output = ''.html_safe;
    if (!someField.help_text.blank?)
      if (someField.help_text.index('/help') == 0)
        help_text = someField.help_text
        help_label = '';
      else
        # escape newlines
        help_text = someField.help_text.gsub(/\n/, '\\\\n<br>')
        rtn = htmlEncode(help_text)
        help_text.gsub!(/&\#39;/, '\\\\&#39;') # re-escape ' for JavaScript
      end
      output = @next_line +
               image_tag(asset_path('blank.gif'), :class=>"help eventsHandled",
               :alt=>"Help", :onclick=>"Def.Popups.openHelp(this, '#{help_text}');"+
                 " event.stopPropagation();")
    end
    return output
  end # helpButton


  # Creates the ID for a form field following the current conventions that
  # we are using.  Please use this instead of doing it yourself, so that if
  # we change the naming convention, we only have to change the code in a
  # few places.
  #
  # Javascript counterpart to this is make_form_field_id in the application_phr.js
  # file.  If you make a change here, please make the change there too.
  #
  # Parameters:
  # * field_name target_field value for the field description
  # * suffix current suffix in use.  Default is nil
  #
  # Returns: the form field ID for the given target field name and suffix
  #
  def make_form_field_id(field_name, suffix=nil)
    field_name = target_field_for_panel(field_name)
    field_name += suffix if suffix
    return FORM_OBJ_NAME + '_' + field_name
  end


  # Creates IDs for the two hidden date fields (epoch and HL7) that are
  # maintained for each visible date field.

  # Creates the name for a form field following the current conventions that
  # we are using.  Please use this instead of doing it yourself, so that if
  # we change the naming convention, we only have to change the code in a
  # few places.
  #
  # Javascript counterpart to this is make_form_field_name in the application_phr.js
  # file.  If you make a change here, please make the change there too.
  #
  # Parameters:
  # * field_name target_field value for the field description
  # * suffix current suffix in use.  Default is nil
  #
  # Returns: the form field name for the given target field name and suffix
  #
  def make_form_field_name(field_name, suffix=nil)
    field_name = target_field_for_panel(field_name)
    field_name += suffix if suffix
    return FORM_OBJ_NAME + '[' + field_name +']'
  end


  # Creates IDs for the two hidden date fields (epoch and HL7) that are
  # maintained for each visible date field.   Please use this instead of
  # creating the IDs yourself, so that if we change the naming convention,
  # or add more hidden date fields, we only have to change the code in a
  # few places.
  # Parameters:
  # * field_name target_field value for the base date field
  # * suffix current suffix in use.  Default is nil
  #
  # Returns: the epoch and HL7 ids (in that order)
  #
  def make_hidden_date_field_ids(field_name, suffix=nil)
    field_name = target_field_for_panel(field_name)
    return make_form_field_id(field_name + '_ET', suffix),
           make_form_field_id(field_name + '_HL7', suffix)
  end


  # Merges two hash tables of tag attributes.  In cases where both specify
  # the same attribute, and the attribute is an event (starts with "on"),
  # the attribute values are strung together, separated by a ;.  If the
  # attribute is not an event, the attribute value from the second hash
  # table overrides the value in the first unless merge set to true.
  #
  # This method returns a new merged hash table.  The input hash tables
  # are not changed.
  #
  # Parameters:
  # * first - the first hash table of tag attributes
  # * second - the second hash table of tag attributes
  # * merge - if true, merge and dont override. Default is false.
  #     Note:  As currently (and probably incorrectly) implemented,
  #     keys equal to :class are always merged, except that
  #     they are merged incorrectly (with semicolons) if
  #     merge is equal to true.  It would break existing code
  #     to fix that, so for now do not use the merge argument
  #     if you are merging :class.
  # Returns: a new merged hash table
  #
  def merge_tag_attributes(first, second, merge=false)
    first = first.dup if !first.blank?
    merge_tag_attributes!(first, second, merge)
  end # merge_tag_attributes

  # Merges two hash tables of tag attributes.  In cases where both specify
  # the same attribute, and the attribute is either a class or an event
  # (starts with "on"),
  # the attribute values are strung together, separated by a ;.  If the
  # attribute is not an event, the attribute value from the second hash
  # table overrides the value in the first unless merge set to true
  #
  # The method edits the first hash table, and returns it.  The second
  # input hash table is not changed, but the first is.
  #
  # Parameters:
  # * first - the first hash table of tag attributes
  # * second - the second hash table of tag attributes
  # * merge - if true, merge and dont override. default false.
  #     Note:  As currently (and probably incorrectly) implemented,
  #     keys equal to :class are always merged, except that
  #     they are merged incorrectly (with semicolons) if
  #     merge is equal to true.  It would break existing code
  #     to fix that, so for now do not use the merge argument
  #     if you are merging :class.
  # Returns: the edited first hash table
  #
  def merge_tag_attributes!(first, second, merge=false)
    if (first.nil?)
      if (second.nil?)
        rtn = {}
      else
        rtn = second
      end
    else
      rtn = first
      if (second)
        second.map do |key, value|
          if (rtn[key].nil?)
            rtn[key]=value
          else
            if (key.to_s[0,2] == 'on' || merge)
              rtn[key] = first[key] + '; ' + value
            elsif (key == :class)
              rtn[key] = first[key] + ' ' + value
            else
              rtn[key] = value
            end
          end
        end
      end
    end
    rtn
  end # merge_tag_attributes!


  # Reads a hash table of tag attributes and returns them as a string
  # that can be included in the page HTML.
  #
  # Parameters:
  # * attr - the hash table of tag attributes
  #
  # Returns:  html string
  #
  def readTagAttributes(attr)

    attrOut = " "
    attr.each {|key, value|
      attrOut << "#{key}='#{value}' "
    }
    return attrOut.chop

  end # readTagAttributes


  # This function checks a field definition to see if any field validation has
  # been predefined. If so, it will add change event listener to run through
  # all the field validations. For non-required/non-xss field, an onblur
  # event listener will be added to force user re-checking the invalid entry
  # before allowing them to leave the current field.
  # This method also adds validation codes to:
  # 1) show an updated list of the passed password formats on each key stroke;
  # 2) to handle delete/undelete events of the requied fields on controlled edit
  # table
  #
  # Parameters:
  # * the_field a field description record
  #
  # Returns: nothing
  #
  def set_validator(the_field)

    field_validations = the_field.get_validations
    if !field_validations.empty?
      target = target_field_for_panel(the_field.target_field)
      # The field validation listeners were added by calling the function
      # Def.loadFieldValidations() (see application_helper.rb for details)
      @field_validations[target] = field_validations

      field_validations.each do |func_type|
        # add onkeyup listener to password field to enable realtime password
        # format checking
        # keyup listener should response to only non-tab and non-return key events
        if func_type[0] === "password"
          add_observer(target, 'keyup',
            'function(event){Def.passwordCheckOnkeyup(this,event);}')
          break
        end
      end
    end
    
    # The delete/undeleted memu is available to the row which has a virtual 
    # field of class cet_actions. Only fields with a parent field meet this 
    # requirement.  And only when the user has more than read-only access.
    the_header = the_field.group_header
    if (@access_level == ProfilesUser::NO_PROFILE_ACTIVE ||
        @access_level < ProfilesUser::READ_ONLY_ACCESS) &&
       the_field.required? && the_header && the_header.controlled_edit
      vtype = the_field.get_validation("required")[1]
      # when deleted, the invalid required field should become valid because
      # the deletion made it disabled
      add_observer(target, 'delete',
        "function(event){Def.Validation.checkRequired(this, '#{vtype}');}")
      # re-validates the field upon undeleting so that if it was coming from an
      # invalid status, the field can become invalid again
      add_observer(target, 'undelete',
        "function(event){Def.Validation.checkRequired(this,'#{vtype}');}")
    end

  end # set_validator


  # Displays error messages collected in @saveErrorMessages, if there
  # are any.
  #
  # Parameters:
  # * saveObj - the object that was being saved.  This should be an
  #   object that uses the RecordValidator module, or that at least has
  #   an @saveErrorMessages data member.
  #
  # Returns: html for the error message(s)
  #
  def showSaveErrors(saveObj)
    if saveObj.saveErrorMessages.length > 0
      output = '<h2>The entry could not be saved because of the following '+
        'errors:</h2>' +
        '<ul>'
      saveObj.saveErrorMessages.each { |msg| output+='<li>'+msg+'</li>' +"\n" }
      output += '</ul>'
    end
    return output
  end


  # This function creates a target field value for a form field that will
  # appear in one of the dynamically generated panels.  It does this by
  # inserting the loincPanelSN into the 3rd position of the target_field value
  # if the field is within a Loinc Panel.  If the field is not within a
  # Loinc panel the target_field value is returned unchanged.
  #
  # Parameters:
  # * target_field the target_field value
  #
  # Returns: the updated target_field value - or the unchanged value if the
  # field is not in a Loinc panel.
  #
  def target_field_for_panel(target_field)
    #if @isLoincPanel && target_field[0,3] == 'tp_'
    if @isLoincPanel && target_field =~ /\Atp[0-9]*_/
      target_field = target_field.gsub(/\Atp([0-9]*)_/,
                                       'tp' + @loincPanelSN.to_s + '_')
    end
    return target_field
  end

end # FormHelper
