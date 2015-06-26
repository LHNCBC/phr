module ButtonsHelper

  # Builds the appropriate type of input mechanism for a field 
  # with a control_type of 'button'.
  #
  # PREVIOUSLY we used multiple control_types for buttons.  They are now
  # being consolidated to one control_type, where differentiating can
  # be expressed with the type parameter in the control_type_detail column.
  # See the reminders button on the main PHR for an example of how this
  # works, and the message_button method below.
  #
  # DO NOT CREATE ANY NEW CONTROL_TYPEs for buttons!!!  Thanks.  lm, 5/29/09
  #
  # This also includes code to build checkboxes.
  #
  # This does NOT check for a hidden_field class, as it assumes that
  # buttons and checkboxes will not be used for hidden fields.  Update
  # this if that's not the case.  lm, Jan 2008
  #
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # Makes a button control.  For a button that is to perform a form submit
  # function, do not specify a type in the control_type_detail column.
  # For general buttons that should NOT submit the form, specify a type
  # of 'button'.  For specialized buttons, such as the reminders message
  # button on the main PHR form, specify the type in the control_type_detail
  # column based on a matching method in the private code below.  See the
  # message_button method below.
  #
  # The value of the button will be taken from someField's default_value field,
  # and the label will be taken from someField's displayName field.
  #
  # The function to be run when the button is clicked should be specified
  # by the onclick parameter in the control_type_detail column.  Only one
  # onclick function may be specified.  If you need to run multiple functions
  # for a click event, bundle them.
  #
  # Parameters:
  # * some_field - the field (button) to display (a FieldDescripion)
  # * tag_attrs - attributes for the HTML field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the button with all specified
  #          attributes, modifiers, labels, etc.
  #
  def button(some_field,
             tag_attrs={},
             fd_suffix=nil)

    target = some_field.target_field
    target = target_field_for_panel(target)
    
    field_name = make_form_field_name(target, fd_suffix)
    field_id = make_form_field_id(target, fd_suffix)

    button_type = some_field.getParam('type')
    b_type = button_type.nil? ? 'submit' : 'button'
    ## Per Paul, comment out the following code because it affects the width
    ## of buttons on page localhost/classes/class_types
#    if !some_field.width.blank? && some_field.instructions.blank?
#      tag_attrs = merge_tag_attributes(tag_attrs, {:style=>'width: ' +
#                                                          some_field.width})
#    end
    tag_attrs = {'type'=>b_type, 'name'=>field_name,
                 'id'=>field_id}.merge(tag_attrs)

    if some_field.getParam('align')
      tag_attrs['align'] = some_field.getParam('align')
    end
    # Get the onclick parameter and add the appropriate info to the
    # field observers
    onclick_spec = some_field.getParam('onclick')
    if !onclick_spec.blank? 
      onclick_spec = onclick_spec.rstrip.chomp(';')
      param_start = onclick_spec.index('(') + 1
      func_name = onclick_spec[0..(param_start-2)]
      param_end = onclick_spec.length - 2
      params = String.new
      if (param_start < param_end)
        params = onclick_spec[param_start..param_end]
      end
      func_call = 'function(event){' + func_name + '(' + params + ');}'
      add_observer(target, 'click', func_call)
    end
    # Also stop event propagation, so that (for instance) the h2 tag behind a
    # button does not get a click when this field is clicked.
    add_observer(target, 'click',
      'function(event) {event.stopPropagation();}')

    # Add the default button class, if none was specified.
    tag_attrs[:class] = DEFAULT_BUTTON_STYLE if !tag_attrs[:class]

    output = content_tag('button', 
             content_tag('span', some_field.display_name), tag_attrs)

    # if this is a message button, call message_button for add button-specific
    # javascript to the buffer that accumulates javascript for the page.
    if (button_type == 'message_button')
      message_button(field_id)
    end

    # Buttons now can use the instructions column for text in a fields
    # group.  Normally the instructions column is only used for group
    # headers.
    # if instructions present, then look at width as well and add in a table
    # will work for vertical aligned table
    if(!some_field.instructions.blank?)
      if !some_field.width.blank?
        output ='<table><tbody><tr><td class="noborder" style="width:'+
          some_field.width+'">'+output+'</td><td class="noborder">'+
          some_field.instructions+'</td></tr></tbody></table>'
      else
        output = '<table><tbody><tr><td>'+output+'</td><td>'+
        some_field.instructions+'</td></tr></tbody></table>'
      end
    end

    return output
  end

  
  # Builds the input mechanism for a field with a control_type of 
  # 'check_box'.  Note that we do not use the normal field label
  # for a checkbox.  It makes everything go haywire.
  #
  # Parameters:
  # * someField - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * in_table - boolean indicating whether or not this field is to
  #   be placed in a table cell
  # * tagAttrs - attributes for the HTML tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the checkbox with all specified
  #          attributes, modifiers, labels, etc.
  #  
  def make_checkbox(someField, 
                    someForm,
                    in_table,
                    tagAttrs={}, 
                    fd_suffix=nil)
                   
    id = someField.target_field
    id += fd_suffix if fd_suffix

    on_click = someField.getParam('onclick')
    if !on_click.blank?
      add_observer(someField.target_field, 'click', 'function(event){' + on_click +'}')
    end

    #tagAttrs['checked']=true if (someField.getParam('checked')=='yes')
    tagAttrs['checked'] = true if (someField.default_value == 'yes')

    # Get the classes for the field
    class_array = someField.getParam('class');
    class_array = [] if !class_array
    attrs_class = tagAttrs['class']
    class_array << attrs_class if attrs_class
    tagAttrs['class'] = class_array.join(' ') if class_array.size > 0    
    
    answers = Array.new(2)
    have_yes = false
    have_no = false
    if (!someField.getParam('stored_yes').nil?)
      answers[0] = someField.getParam('stored_yes')
      log_this("in buttons_helper, got #{answers[0]}" + 
               ' for stored_yes parameter of ' + someField.target_field)
      have_yes = true
    else
      answers[0] = ''
    end
    if (!someField.getParam('stored_no').nil?)
      answers[1] = someField.getParam('stored_no')
      log_this("in buttons_helper, got #{answers[1]}" + 
               ' for stored_no parameter of ' + someField.target_field)      
      have_no = true
    end
    
    # if we have a have_no, we assume a yes value - or let rails
    # make up its own.    
    if (have_no == true)
      the_box = someForm.check_box(id, tagAttrs, answers[0], answers[1])
      log_this("the_box = #{the_box}")
    elsif (have_yes == true)
      # if we don't have a no value, we're only interested in one
      # response.  Used the check_box_tag method to create a checkbox
      # that only passes back a value if checked.
      tagAttrs[:name] = 'fe[' + id + ']'
      tagAttrs[:value] = answers[0]
      the_box = check_box_tag('fe_' + id, answers[0], tagAttrs['checked'], 
                              tagAttrs)
    else
      the_box = someForm.check_box(id, tagAttrs)
    end
    
    if (!in_table)
      the_box += label_tag "#{FORM_OBJ_NAME}_#{id}", someField.display_name,
        {:class=>'checkbox'}
      output = '<div id="' + id + '_div" class="field">' 
      if (someField.getParam('first') == 'FieldLabel')
        output += '' + add_required_icon(someField) +
                  ':&nbsp;&nbsp; ' + the_box + helpButton(someField) + '</div>' 
      else
        output += '' + the_box +
                  add_required_icon(someField) + helpButton(someField) +
                  '</div>'
      end
      # Stop event propagation, so that (for instance) the h2 tag behind a
      # checkbox does not get a click when this field is clicked.  # Put the
      # listener on the div containing the field
      @form_field_js << "$('#{someField.target_field}#{fd_suffix}_div')."+
        "observe('click', function(event) {event.stopPropagation();});\n"
    else
      output = the_box 
    end             
    return output.html_safe
  end
  

  # Builds the input mechanism for a field with a control_type of
  # 'radio_button_grp'.
  #
  # Parameters:
  # * someField - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * tagAttrs - attributes for the HTML tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the group of radio buttons with all
  #          specified attributes, modifiers, labels, etc.
  #
  def make_radio_button_grp(someField,
                    someForm,
                    tagAttrs={},
                    fd_suffix=nil)

    grp_id = make_form_field_id(someField.target_field)
    grp_name = make_form_field_name(someField.target_field, fd_suffix)
    grp_id += fd_suffix if fd_suffix

    orientation = someField.getParam('orientation')
    classes = someField.getParam('class')
    on_click = someField.getParam('onclick')
    buttons = someField.radio_group_param
    i = 0
    buttons.each do |radio_button|
      i += 1
      target_field = someField.target_field +  "_" + i.to_s + "R"
      id = make_form_field_id(target_field)
      id += fd_suffix if fd_suffix
      radio_button['id'] = id
      radio_button['name'] = make_form_field_name(target_field, fd_suffix)
      if !on_click.blank?
        add_observer(target_field, 'click', 'function(event){' + on_click +'}')
      end
    end

    # use the message_button partial to create the html for the button
    output = render({:partial=>'form/radio_group.rhtml', :handlers=>[:erb],
                     :locals=>{:grp_id=>grp_id,
                               :classes=>classes.join(' '),
                               :grp_name=>grp_name,
                               :buttons => buttons,
                               :orientation => orientation}})
    # return output
    output
  end


  # TO BE MOVED to conform with general button structure.  See notes above.
  # Builds the input mechanism for a field with a control_type of 
  # 'print_button'.  
  #
  # Parameters:
  # * someField - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * tagAttrs - attributes for the HTML field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the button with all specified
  #          attributes, modifiers, labels, etc.
  #  
  def print_button(someField, 
                  someForm, 
                  tagAttrs={}, 
                  fd_suffix=nil)
    
    # construct the id based on the field id and the current
    # level in the data hierarchy (if any)
    button_id = make_form_field_id(someField.target_field)
    button_id += fd_suffix if fd_suffix
    
    # use the message_button partial to create the html for the button
    output = render({:partial=>'form/print_button.rhtml', :handlers=>[:erb],
                     :locals=>{:fd=>someField, 
                               :button_id=>button_id}})
    @form_field_js <<
      "$('#{button_id}').printableView = new Def.PrintableView();\n"
    add_observer(someField.target_field, 'click',
      'function(event) {this.printableView.openPrintableView(event);}')
    # return output
    output
  end  # end print_button method

  # TO BE MOVED to conform with general button structure.  See notes above.
  # Builds the input mechanism for a field with a control_type of 
  # 'expcol_button'.  
  #
  # Parameters:
  # * someField - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * tagAttrs - attributes for the HTML field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the button with all specified
  #          attributes, modifiers, labels, etc.
  #  
  def expcol_button(someField, 
                  someForm, 
                  tagAttrs={}, 
                  fd_suffix=nil)
    
    # construct the id based on the field id and the current
    # level in the data hierarchy (if any)
    button_id = make_form_field_id(someField.target_field)
    button_id += fd_suffix if fd_suffix

    altText    = someField.getParam('alt', true)
    onClick    = someField.getParam('onclick', true )
    onClick_0  = someField.getParam('onclick_arg_0',true )
    img_class = ['sprite_icons-phr-show-all-orange',
                 'sprite_icons-phr-hide-all-orange']
    onClick_Action = [onClick[0] + "(\'" + onClick_0[0] +"\')",
        onClick[1] + "(\'" + onClick_0[1] +"\')"]

    # use the message_button partial to create the html for the button
    output = render({:partial=>'form/expcol_button.rhtml', :handlers=>[:erb],
                     :locals=>{:fd=>someField,
                               :img_class=>img_class,
                               :altText=>altText,
                               :onClickAction=>onClick_Action,
                               :button_id=>button_id}})
    # return output
    output
  end  # end expcol_button method
  
  
  # In Rails 3, jQuery is needed in order to have a confirmation message. 
  # This method tries to simulate the way Rails 2 was doing so that we can avoid 
  # using jQuery when we need a confirmation.
  def button_to_wo_js *args
    rtn = button_to *args
    if Rails.version.to_i > 2 && rtn.include?('data-confirm')
      rtn.gsub!(/data-confirm="([^"]*)"/, 
        "onclick=\"return confirm('" + args[2][:confirm] + "')\"")
    end
    rtn.html_safe
  end

  def button_to_wo_js_m(*args)
    rtn = button_to *args
    if Rails.version.to_i > 2 && rtn.include?('data-confirm')
      rtn.gsub!(/data-confirm="([^"]*)"/,
                "onclick=\"return confirm('" + args[2][:confirm] + "')\" data-inline=\"true\" ")
    end
    rtn.gsub!("<form","<form data-ajax=\"false\"")
    rtn.html_safe
  end


  private ###########################  Private Methods ###################

  # Performs processing specific to a message button.
  #
  # In this case, javascript to create a message manager related to the
  # button (to handle the messages) is added to the global @form_field_js
  # buffer, and "Javascript Required" code is returned to be added immediately
  # following the button.  (Javascript is required for the message manager).
  # ** JAVASCRIPT REQUIRED MESSAGE REMOVED.
  #
  # Parameters:
  # * field_id - the form field id of the button.  This should include
  #   the suffix plus any modifications necessary for buttons in a test
  #   panel
  #
  # Returns: nothing
  #
  def message_button(field_id)
    @form_field_js << "\n" + '$("' + field_id + '").messageManager = ' +
                      'new Def.MessageManager($("' + field_id + '"));' + "\n"
    @form_field_js << "\n" + 'Def.messageFieldIds_.push("'+field_id+'");' + "\n"
    # REMOVED 3/15/10 per Paul's request.  A single Javascript required
    # message at the page level will be displayed, rather than having multiple
    # messages.
    # Return the noscript tag for this one.  this will be added to
    # the button field definition, immediately following it.  It's needed
    # because the button relies on the message manager object created above.
    #return '<noscript>Javascript Required</noscript>'
  end  # end message_button method

  
  #
  # This method logs an informational message, using logger.debug.
  # I wrote this so that it is easy to turn off all logging for
  # this helper when it's not needed.  Trying to start to clean
  # out those logs.
  #
  # When you need log messages, uncomment the logger.debug line.
  # When you're done, comment it back out again.  Let's unclutter
  # those logs.  lm, 9/08
  #
  # Parameters:
  # * log_msg the message to be written.
  #
  # Returns:  nothing, but does write the message to the log.
  #
  def log_this(log_msg)
    # logger.debug 'BTN_HLPR:  ' + log_str
  end # log_this
   
end # ButtonsHelper
