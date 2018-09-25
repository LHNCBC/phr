# A helper for the basic HTML mode.
module PhrRecordsHelper
  # Returns the HTML for a text field for the basic mode.
  #
  # Parameters:
  # * label - the label for the field
  # * form_obj_name - a string for the form object name Rails uses in
  #   constructing field IDs and name attributes.
  # * field_id - an ID for the field (e.g. a target field name)
  # * help_url - the URL for a help page about the field
  # * attrs - attitional attributes for the form field tag
  def basic_text_field(label, form_obj_name, field_id, help_url=nil, attrs={})
    hb = help_button(help_url) if help_url
    label = label(form_obj_name, field_id, label)
    label += '&nbsp;(read only)'.html_safe if attrs[:readonly]
    label+(':&nbsp;'.html_safe)+text_field(form_obj_name, field_id, attrs)+ hb
  end


  # Returns the HTML for a text area for the basic mode.
  #
  # Parameters:
  # * label - the label for the field
  # * form_obj_name - a string for the form object name Rails uses in
  #   constructing field IDs and name attributes.
  # * field_id - an ID for the field (e.g. a target field name)
  # * help_url - the URL for a help page about the field
  # * attrs - attitional attributes for the form field tag
  def basic_text_area(label, form_obj_name, field_id, help_url=nil, attrs={})
    hb = help_button(help_url) if help_url
    label = label(form_obj_name, field_id, label)
    label += '&nbsp;(read only)'.html_safe if attrs[:readonly]
    label+(':&nbsp;'.html_safe)+text_area(form_obj_name, field_id, attrs)+hb
 end


  # Returns the HTML for a password field for the basic mode.
  #
  # Parameters:
  # * label - the label for the field
  # * form_obj_name - a string for the form object name Rails uses in
  #   constructing field IDs and name attributes.
  # * field_id - an ID for the field (e.g. a target field name)
  # * help_url - the URL for a help page about the field
  # * attrs - attitional attributes for the form field tag
  def basic_password_field(label, form_obj_name, field_id, help_url=nil, attrs={})
    hb = help_button(help_url) if help_url
    # Per our security team, turn off autocomplete.  Most browsers will ignore
    # this setting, but it will make the scanner happy.
    attrs[:autocomplete] = 'off'
    label(form_obj_name, field_id, label)+": "+
      password_field(form_obj_name, field_id, attrs) + hb
  end


  # Returns the HTML for a radio button list for the basic mode.
  #
  # Parameters:
  # * label - the label for the field
  # * field_id - an ID for the field (e.g. a target field name)
  # * items - the labels and values for the radio buttons.  This should be
  #   an array of two dimensional arrays, each of which is like [label, value].
  # * checked_code - the code of the item that should be checked
  # * help_url - the URL for a help page about the field
  # * form_obj_name - a string for the form object name Rails uses in
  #   constructing field IDs and name attributes.
  def basic_radio_field(label, field_id, items, checked_code, help_url=nil,
      form_obj_name = BasicModeController::FD_FORM_OBJ_NAME)
    hb = help_button(help_url) if help_url
    rtn = [label(form_obj_name, field_id, label)]
    items.each do |label, value|
      options = value==checked_code ? {:checked=>true} : {}
      rtn << radio_button(form_obj_name, field_id, value, options)
      rtn << label(form_obj_name, "#{field_id}_#{value}", label)
    end
    rtn << hb if hb
    return rtn.join(' ').html_safe
  end


  # Returns the HTML for a checkbox.
  #
  # Parameters:
  # * label - the label for the field
  # * field_id - an ID for the field (e.g. a target field name)
  # * checked - if true the checkbox will be initially checked
  # * help_url - the URL for a help page about the field
  # * form_obj_name - the form object name (the key for the form parameters in
  #   the params hash).  If this is not specified,
  #   BasicModeController::FD_FORM_OBJ_NAME will be used.
  def basic_checkbox(label, field_id, checked=false, help_url= nil,
      form_obj_name=BasicModeController::FD_FORM_OBJ_NAME)
    rtn = [check_box(form_obj_name, field_id, {:checked=>checked} ),
      label(form_obj_name, field_id, label)]
    rtn << help_button(help_url) if help_url
    return rtn.join(' ').html_safe
  end


  # Returns the HTML for a prefetched list field for the basic mode.
  #
  # Paramters:
  # * label - the label for the field
  # * field_id - an ID for the field (e.g. a target field name)
  # * help_url - the URL for a help page about the field
  # * items - the items for the list.  These should be objects that respond
  #   to the code_field and display_field values as methods.
  # * code_field - the field on one of the records in items that holds the code
  #   for the item.
  # * display_field - the field on one of the records in items that holds the
  #   display string for the item.
  # * selected_val - the code for the selected item
  # * selected_val_str - the display string corresponding to the code.  This
  #   is only used if selected_val is not in the list; in that case we add
  #   selected_val_str to the list of items so it can be there to be selected.
  # * include_blank - whether to include a blank option
  def basic_prefetched_list(label, form_obj_name, field_id, help_url, items,
      code_field, display_field, selected_val, selected_val_str, include_blank=true)
    # Convert codes to strings, or the "selected" item won't be found.
    ics = Set.new # items' codes
    list_data = items ?
      items.collect {|i| ics << i.send(code_field); [i.send(display_field), i.send(code_field).to_s]} : []
    # Add the selected value, if there was one.  Don't add it if it was blank,
    # as we can't distinguish between no value and a blank (empty string) value,
    # and if a blank value is allowed for the list, then include_blank will be
    # true and the list will have a blank line anyway.
    list_data << [selected_val_str, selected_val] if !selected_val.blank? && !ics.member?(selected_val)
    hb = help_url ? '&nbsp;'.html_safe + help_button(help_url) : ''
    label(form_obj_name, field_id, label) + (':&nbsp;'.html_safe) +
      select(form_obj_name, field_id, list_data,
             {:selected=>selected_val.to_s, :include_blank=>include_blank}) + hb
  end


  # Returns a control for accessing the help from the given URL.
  #
  # Parameters:
  # * help_url - the URL for the help page
  # * label - the label for the help link (optional)
  def help_button(help_url, label='Help')
    "<a href=\"#{help_url}?go_back=false\" target=\"_blank\">#{label}</a>".html_safe if help_url
  end


  # Returns the HTML for a radio button list for the given field description.
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * items - the labels and values for the radio buttons.  This should be
  #   an array of two dimensional arrays, each of which is like [label, value].
  # * checked_code - the code of the item that should be checked
  def fd_radio_field(field_desc, items, checked_code)
    basic_radio_field(field_desc.display_name,
      field_desc.target_field, items, checked_code,
      get_help_url(field_desc))
  end


  # Returns the HTML for a button based on the given field description.
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * suffix - (optional) a suffix to add to the field name
  def fd_button(field_desc, suffix="")
    field_name = field_desc.target_field+suffix
    submit_tag field_desc.display_name, :name=>"#{FORM_OBJ_NAME}[#{field_name}]"
  end


  # Returns the HTML for a checkbox for the given field description.
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * data_rec - the data record, used for the field's default value
  # * form_obj - the form object name (the key for the form parameters in the
  #   params hash).  If this is not specified,
  #   BasicModeController::FD_FORM_OBJ_NAME will be used.
  # * suffix - (optional) a suffix to add to the field name
  def fd_checkbox(field_desc, data_rec,
      form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')

    field_name = field_desc.target_field+suffix
    val = field_val(field_desc, field_name, data_rec)
    val = true if val == '1' # In form params, checkbox values are '1' when checked
    rtn = basic_checkbox(field_desc.display_name, field_name,
      val, get_help_url(field_desc), form_obj)
    add_required(field_desc, rtn)
  end


  # Returns the HTML for a group of radio buttons for the given field
  # description.
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * data_rec - the data record, used for the field's default value
  # * form_obj - the form object name (the key for the form parameters in the
  #   params hash).  If this is not specified,
  #   BasicModeController::FD_FORM_OBJ_NAME will be used.
  # * suffix - (optional) a suffix to add to the field name
  def fd_radio_group(field_desc, data_rec=nil,
      form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')

    group_name = field_desc.target_field + suffix
    rtn = ''
    val = field_val(field_desc, group_name, data_rec)
    use_first_val = val.nil?
    field_desc.radio_group_param.each_with_index do |radio_data, i|
      button_id = "#{form_obj}_#{field_desc.target_field}_#{i}R#{suffix}"
      checked = use_first_val ? i==0 : val==radio_data['value']
      rtn += render(:partial=>'basic/radio_button',
        :locals=>{:button_id=>button_id, :form_obj=>form_obj,
        :button_group=>group_name, :label=>radio_data['label'],
        :value=>radio_data['value'], :checked=>checked})
    end
    return rtn.html_safe
  end


  # Returns the HTML for a prefetched list for the given field description
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * data_rec - the data record, used for the field's default value
  # * list_items - the list items (ActiveRecord objects).  These need to respond
  #     to the field_desc's list_code_column and fields_displayed settings.
  # * include_blank - true if a blank line should be added to the list
  # * form_obj - the form object name (the key for the form parameters in the
  #   params hash).  If this is not specified,
  #   BasicModeController::FD_FORM_OBJ_NAME will be used.
  # * suffix - (optional) a suffix to add to the field name
  # * use_codes - (optional, default true) - if false, the list will not
  #   attempt to use codes, but the list items themselves will be the selected
  #   value.  The only known cases for this are the "Where done" field on the
  #   test panels and the fixed questions on the account sign up/settings pages.
  def fd_prefetched_list(field_desc, data_rec, list_items, include_blank=true,
      form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='', use_codes=true)
    include_blank = true if include_blank.nil?  # might be nil
    form_obj = BasicModeController::FD_FORM_OBJ_NAME if !form_obj
    suffix = '' if !suffix

    help_url = get_help_url(field_desc)
    ctd = field_desc.control_type_detail
    db_fd = field_desc.db_field_description
    list_display_column = ctd['fields_displayed'][0]
    if use_codes
      code_field_name = field_desc.code_field + suffix
      if data_rec
        code_value = db_fd ? data_rec.send(db_fd.code_field) :
                             data_rec.send(code_field_name)
      end
      list_code_column = db_fd ? db_fd.list_code_column :
                                 field_desc.list_code_column
    else
      # In this case the list does not really use codes; we store the values
      # only.  The only known case for this is the "Where done" field on the
      # test panels.
      code_field_name = field_desc.target_field + suffix
      code_value = field_val(field_desc, code_field_name, data_rec) if data_rec
      list_code_column = list_display_column
    end
    display_value = field_val(field_desc, list_display_column, data_rec)

    add_alt_field = ctd['match_list_value'] != 'true'
    # Don't include a select field if there is no list
    use_select_field = list_items && list_items.size != 0
    if use_select_field
      rtn = basic_prefetched_list(field_desc.display_name,
        form_obj, code_field_name, help_url, list_items, list_code_column,
        list_display_column, code_value, display_value,
        include_blank)
    else
      rtn = ''.html_safe
    end

    if add_alt_field
      label = field_desc.display_name
      label = '&nbsp; Unlisted '.html_safe + label if use_select_field
      opts = {}
      if code_value.blank?
        opts[:value] = display_value
      end
      # Don't repeat the help link if we have already output one for the
      # list field.
      help_url = nil if use_select_field
      rtn += basic_text_field(label,
        form_obj, 'alt_'+field_desc.target_field,
        help_url, opts)
    end
    add_required(field_desc, rtn)
  end


  # Returns the HTML for a plain text field, based on the given field description
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * data_rec - (optional) the data record, used for the field's default value
  # * field_attrs - extra attributes for the field
  # * form_obj - the form object name (the key for the form parameters in the
  #   params hash).  If this is not specified,
  #   BasicModeController::FD_FORM_OBJ_NAME will be used.
  # * suffix - (optional) a suffix to add to the field name
  def fd_text_field(field_desc, data_rec = nil, field_attrs={},
      form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')
    help_url = get_help_url(field_desc)
    field_id = field_desc.target_field + suffix
    if !field_attrs[:value] && data_rec
      field_attrs[:value] = field_val(field_desc, field_id, data_rec)
    end
    # Some fields need more than one line, and this is controlled via the
    # wrap attribute.  For the readonly fields, which at present are only
    # for the benefit of the form processing, don't allow more than 1 line.
    if field_desc.wrap? && !field_attrs[:readonly]
      field_attrs[:rows] = 3 if !field_attrs[:rows]
      rtn = basic_text_area(field_desc.display_name, form_obj, field_id,
        help_url, field_attrs)
    else
      rtn = basic_text_field(field_desc.display_name, form_obj, field_id,
        help_url, field_attrs)
    end
    add_required(field_desc, rtn)
  end


  # Returns the HTML for a plain text area, based on the given field description
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * data_rec - (optional) the data record, used for the field's default value
  # * field_attrs - extra attributes for the field
  # * form_obj - the form object name (the key for the form parameters in the
  #   params hash).  If this is not specified,
  #   BasicModeController::FD_FORM_OBJ_NAME will be used.
  # * suffix - (optional) a suffix to add to the field name
  def fd_text_area(field_desc, data_rec = nil, field_attrs={},
      form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')
    help_url = get_help_url(field_desc)
    field_id = field_desc.target_field + suffix
    if !field_attrs[:value] && data_rec
      field_attrs[:value] = field_val(field_desc, field_id, data_rec)
    end
    field_attrs[:rows] = field_desc.control_type_detail['rows']
    field_attrs[:cols] = field_desc.control_type_detail['cols']
    rtn = basic_text_area(field_desc.display_name, form_obj, field_id,
        help_url, field_attrs)
    add_required(field_desc, rtn)
  end


  # Returns the HTML for a password field, based on the given field description.
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * field_attrs - extra attributes for the field
  # * form_obj - the form object name (the key for the form parameters in the
  #   params hash).  If this is not specified,
  #   BasicModeController::FD_FORM_OBJ_NAME will be used.
  # * suffix - (optional) a suffix to add to the field name
  def fd_password(field_desc, field_attrs,
      form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')
    field_id = field_desc.target_field + suffix
    help_url = get_help_url(field_desc)
    rtn = basic_password_field(field_desc.display_name, form_obj, field_id,
        help_url, field_attrs)
    add_required(field_desc, rtn)
  end

  # Returns the HTML for a "static text" field based on a field_description
  # Parameters:
  # * field_desc - used for obtaining the field's text
  # * data_rec - (not used)
  def fd_static_text(field_desc, data_rec=nil)
    "<div>#{field_desc.default_value}</div>".html_safe
  end


  # Returns the HTML for a "big static text" field based on a field_description
  # Parameters:
  # * field_desc - used for obtaining the field's text
  def fd_big_static_text(field_desc)
    height = field_desc.getParam('height')
    height_style = height ?
      " class=\"scrolling_text\" style=\"height: #{height};\"" : ''
    "<div #{height_style}>#{field_desc.default_value}</div>".html_safe
  end


  # Returns the HTML for a labeled data record field value where the field
  # value is just plain text (i.e. no form field).  This is different
  # from fd_static_text in that the value is taken from the data record.
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * data_rec - the data record, used for the field's default value
  # * suffix - (optional) a suffix to add to the field name
  def fd_labeled_text_value(field_desc, data_rec, suffix='')
    label = field_desc.display_name ? field_desc.display_name : ''
    "#{label}:  #{field_val(field_desc, field_desc.target_field+suffix,
                            data_rec)}".html_safe
  end


  # Returns the HTML for a date field  based on a field_description
  #
  # Parameters:
  # * field_desc - the field description record used for obtaining the field's
  #   label and name
  # * data_rec - the data record, used for the field's default value
  # * form_obj - the form object name (the key for the form parameters in the
  #   params hash).  If this is not specified,
  #   BasicModeController::FD_FORM_OBJ_NAME will be used.
  # * suffix - (optional) a suffix to add to the field name
  def fd_date_field(field_desc, data_rec,
      form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')
    ctd = field_desc.control_type_detail
    help_url = get_help_url(field_desc)
    opts = {}
    field_name = field_desc.target_field + suffix
    if data_rec
      opts[:value] = field_val(field_desc, field_name, data_rec)
    end
    label = field_desc.display_name
    label += " (date format #{ctd['tooltip']})" if ctd['tooltip']
    rtn = basic_text_field(label, form_obj, field_name, help_url, opts)
    add_required(field_desc, rtn)
  end


  # Returns the HTML for a fieldset tag for a field group.
  # tag is not included.)  Usage: <%= fd_field_set(fd) do %> ... <%end%>
  # Parameters:
  # * field_desc - the field description record for the field group
  # * block - the HTML that should be written inside the fieldset.
  def fd_fieldset(field_desc)
    field_set_tag(field_desc.display_name) {
      hb = "".html_safe
      if help_url = get_help_url(field_desc)
        hb << content_tag("div", help_button(help_url, 'Section Help'))
      end
      if field_desc.instructions
        hb << content_tag("div", field_desc.instructions, {:class=>"instructions"})
      end
      hb << yield
    }
  end


  # Returns the HTML for a hidden field that uses our standard generic form
  # object name.
  #
  # Parameters:
  # * data_rec - the data record
  # * field_name - the field name for this hidden field.  This should also be
  #   the column name in data_rec from which the value should be obtained.
  def phr_hidden_field(data_rec, field_name)
    hidden_field BasicModeController::FD_FORM_OBJ_NAME, field_name,
        :value=>data_rec.send(field_name)
  end


  private

  # Returns the help URL for the given field description, or nil if there
  # is no URL.
  #
  # Parameters:
  # * field_desc - the field description record for the field
  def get_help_url(field_desc)
    field_desc.help_text && field_desc.help_text.index('/')==0 ?
      field_desc.help_text('basic') : nil
  end


  # Adds a required notice to the output, if necessary, and returns the
  # modified output.
  #
  # Parameters:
  # * field_desc - the field description record for the field
  # * output - the current output for the field
  def add_required(field_desc, output)
    if field_desc.required
      output += ' (required)'
    end
    output.html_safe
  end

  # Returns the value in data_rec for the field described by the field_desc
  # field_description.  Returns nil if data_rec is nil.
  #
  # Parameters:
  # * field_desc - the field description record for the field
  # * field_name - the name of the field on the form (including any suffix)
  # * data_rec - the data record (which may be nil, in which case the return
  #   value will be nil.
  def field_val(field_desc, field_name, data_rec)
    if data_rec
      db_fd = field_desc.db_field_description
      data_col =  db_fd ? db_fd.data_column : field_name
      rtn = data_rec.send(data_col)
    end
    return rtn
  end


  ###########################################################################
  #
  # The methods listed as follows are the ones created for mobile version
  #
  ###########################################################################

  def add_required_m(field_desc, output)
    if field_desc.required
      output += ' (required)'
      #output +=
      #"<a href=\"#\" class=\"ui-btn ui-btn-inline ui-btn-corner-all ui-icon-star ui-btn-icon-left\">(required)</a>".html_safe
    end
    output.html_safe
  end



  def help_button_m(help_url, label='Help')
    help_button(help_url, label)
#    help_icon_class ="ui-btn ui-btn-inline ui-btn-corner-all ui-icon-info ui-btn-icon-notext"
#    "<a href=\"#{help_url}?go_back=false\" target=\"_blank\" class=\"#{help_icon_class}\">#{label}</a>".html_safe if help_url
  end

  def basic_password_field_m(label, form_obj_name, field_id, help_url=nil, attrs={}, required=false)
    label_name = mobile_label(label, help_url, required)
    # Per our security team, turn off autocomplete.  Most browsers will ignore
    # this setting, but it will make the scanner happy.
    attrs[:autocomplete] = 'off'
    label(form_obj_name, field_id, label_name)+
      password_field(form_obj_name, field_id, attrs)

  end

  def basic_text_area_m(label, form_obj_name, field_id, help_url=nil, attrs={}, required=false)
    label_name=mobile_label(label, help_url, required)
    label = label(form_obj_name, field_id, label_name)
    label += '(read only)'.html_safe if attrs[:readonly]
    label+text_area(form_obj_name, field_id, attrs)
  end

  def basic_text_field_m(label, form_obj_name, field_id, help_url=nil, attrs={}, required=false)
    label_name = mobile_label(label, help_url,required)

    label = label(form_obj_name, field_id, label_name)
    label += '(read only)'.html_safe if attrs[:readonly]
    label+text_field(form_obj_name, field_id, attrs)
  end

  def basic_text_field_ms(label, form_obj_name, field_id, help_url=nil, attrs={}, required=false)
    label_name = mobile_label(label, help_url,required)

    label = label(form_obj_name, field_id, label_name)
    label += '(read only)'.html_safe if attrs[:readonly]
    label+ label(form_obj_name, field_id, attrs)
  end

  def fd_label_m(label, form_obj_name, field_id, help_url=nil, required=false)
    label_name = mobile_label(label, help_url,required)
    label(form_obj_name, field_id, label_name)
  end




  def basic_checkbox_m(label, field_id, checked=false, help_url= nil, required=false,
                       form_obj_name=BasicModeController::FD_FORM_OBJ_NAME)
    label = mobile_label(label, help_url, required)
    label = label(form_obj_name, field_id, label)
    rtn = [check_box(form_obj_name, field_id, {:checked=>checked} ),label]
    return rtn.join(' ').html_safe
  end


  def basic_prefetched_list_m(label, form_obj_name, field_id, help_url, items,
                              code_field, display_field, selected_val, selected_val_str, include_blank=true, required=false)
    # Convert codes to strings, or the "selected" item won't be found.
    ics = Set.new # items' codes
    list_data = items ?
      items.collect {|i| ics << i.send(code_field); [i.send(display_field), i.send(code_field).to_s]} : []
    # Add the selected value, if there was one.  Don't add it if it was blank,
    # as we can't distinguish between no value and a blank (empty string) value,
    # and if a blank value is allowed for the list, then include_blank will be
    # true and the list will have a blank line anyway.
    list_data << [selected_val_str, selected_val] if !selected_val.blank? && !ics.member?(selected_val)
    label = mobile_label(label, help_url, required)


    label(form_obj_name, field_id, label) +
      select(form_obj_name, field_id, list_data,
             {:selected=>selected_val.to_s, :include_blank=>include_blank})
  end


  def mobile_label(label, help_url, required)
    hb = help_button(help_url) if help_url
    label_name = "<b style='color:gray'>#{label}</b><br>".html_safe
    label_name += "<small>".html_safe
    label_name +=  help_button(help_url).html_safe if help_url
    label_name += "#{required ? "(Required)" : "" }</small>".html_safe
  end



  def fd_button_m(field_desc, suffix="")
    field_name = field_desc.target_field+suffix
    submit_tag_m field_desc.display_name, :name=>"#{FORM_OBJ_NAME}[#{field_name}]"
  end


  def submit_tag_m(*args)
    submit_tag( args[0], (args[1] ? args[1] : {}).merge({"data-inline"=>"true"}))
  end


  def fd_checkbox_m(field_desc, data_rec,
                    form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')

    field_name = field_desc.target_field+suffix
    val = field_val(field_desc, field_name, data_rec)
    val = true if val == '1' # In form params, checkbox values are '1' when checked
    rtn = basic_checkbox_m(field_desc.display_name, field_name,
                           val, get_help_url(field_desc), field_desc.required, form_obj)
    #add_required(field_desc, rtn)
  end


  def fd_popup_button(popid, legend, content)
    popup_legend="<legend>#{legend}</legend>".html_safe
    popup_legend_class="ui-btn ui-corner-all ui-shadow ui-icon-plus ui-btn-icon-right"
    hb = link_to(popup_legend,"##{popid}",  "class"=>popup_legend_class, "data-transition"=>"pop","data-rel"=>"popup")
    popup_class="ui-btn ui-corner-all ui-shadow ui-icon-delete ui-btn-icon-left ui-btn-inline"
    #popup_class_notext="ui-btn ui-icon-delete ui-btn-icon-notext ui-btn-left"
    hb += ('<div data-role="popup" id="'+popid+'" data-overlay-theme="b" class="ui-content">' +
      '<div >'+content+'</div>' +
      #'<a href="#" data-rel="back" data-role="button" data-theme="b" data-icon="delete"  class="'+popup_class+'">Close</a>' +
      '<a href="#" data-rel="back" data-theme="b" class="'+popup_class+'">Close</a>' +
      '</div>').html_safe
  end


  def fd_prefetched_list_m_src(field_desc, data_rec, list_items, include_blank=true,
                               form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='', use_codes=true)
    include_blank = true if include_blank.nil?  # might be nil
    form_obj = BasicModeController::FD_FORM_OBJ_NAME if !form_obj
    suffix = '' if !suffix

    help_url = get_help_url(field_desc)
    ctd = field_desc.control_type_detail
    db_fd = field_desc.db_field_description
    list_display_column = ctd['fields_displayed'][0]
    if use_codes
      code_field_name = field_desc.code_field + suffix
      if data_rec
        code_value = db_fd ? data_rec.send(db_fd.code_field) :
          data_rec.send(code_field_name)
      end
      list_code_column = db_fd ? db_fd.list_code_column :
        field_desc.list_code_column
    else
      # In this case the list does not really use codes; we store the values
      # only.  The only known case for this is the "Where done" field on the
      # test panels.
      code_field_name = field_desc.target_field + suffix
      code_value = field_val(field_desc, code_field_name, data_rec) if data_rec
      list_code_column = list_display_column
    end
    display_value = field_val(field_desc, list_display_column, data_rec)

    add_alt_field = ctd['match_list_value'] != 'true'
    # Don't include a select field if there is no list
    use_select_field = list_items && list_items.size != 0
    if use_select_field
      rtn = basic_prefetched_list_m(field_desc.display_name,
                                    form_obj, code_field_name, help_url, list_items, list_code_column,
                                    list_display_column, code_value, display_value,
                                    include_blank, field_desc.required)
    else
      rtn = ''.html_safe
    end

    if add_alt_field
      label = field_desc.display_name
      label = 'Unlisted '.html_safe + label if use_select_field
      opts = {}
      if code_value.blank?
        opts[:value] = display_value
      end
      # Don't repeat the help link if we have already output one for the
      # list field.
      help_url = nil if use_select_field
      rtn1 = basic_text_field_m(label,
                                form_obj, 'alt_'+field_desc.target_field,
                                help_url, opts, field_desc.required)
    end
    [rtn, rtn1]
  end



  def fd_prefetched_list_m(*args)
    r1,r2 =fd_prefetched_list_m_src(*args)
    r1+r2
  end

  def fd_prefetched_list_mb(*args)
    r1, r2 = fd_prefetched_list_m_src(*args)
    rtn = "".html_safe
    rtn += wrap_with_field_contain{ r1 }
    # show unlisted item input as needed
    rtn += wrap_with_field_contain{ r2 } if !r2.blank?
    rtn

  end


  def fd_text_field_m(field_desc, data_rec = nil, field_attrs={},
                      form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')
    help_url = get_help_url(field_desc)
    field_id = field_desc.target_field + suffix
    if !field_attrs[:value] && data_rec
      field_attrs[:value] = field_val(field_desc, field_id, data_rec)
    end
    # Some fields need more than one line, and this is controlled via the
    # wrap attribute.  For the readonly fields, which at present are only
    # for the benefit of the form processing, don't allow more than 1 line.
    if field_desc.wrap? && !field_attrs[:readonly]
      field_attrs[:rows] = 3 if !field_attrs[:rows]
      rtn = basic_text_area_m(field_desc.display_name, form_obj, field_id,
                              help_url, field_attrs, field_desc.required)
    else
      rtn = basic_text_field_m(field_desc.display_name, form_obj, field_id,
                               help_url, field_attrs, field_desc.required)
    end
=begin
    # looks like this tooltip info is duplicated with the help link
    # for now, will disable this info link and use the help link only
    tooltip = field_attrs[:title]
    tooltip_id = field_attrs[:title_id]
    # the tooltip or info button
    tooltip_html=('<a href="#popupInfo_'+tooltip_id+'" data-rel="popup" data-transition="pop" class="my-tooltip-btn ui-btn ui-alt-icon ui-nodisc-icon ui-btn-inline ui-icon-info ui-btn-icon-notext" title="Learn More"> Learn more</a>'+
    '<div data-role="popup" id="popupInfo_'+tooltip_id+ '" class="ui-content" data-theme="a" style="max-width:350px;">'+
       (tooltip)+'</div>').html_safe
    rtn + tooltip_html
=end
    #add_required_m(field_desc, rtn)
  end

  def fd_text_field_mc(*args)
    rtn = "<div class=\"ui-field-contain\">".html_safe
    rtn += fd_text_field_m(*args).html_safe
    rtn += "</div>".html_safe
  end

  def fd_text_field_mb(*args)
    wrap_with_field_contain do
      fd_text_field_m(*args)
    end
  end

  def wrap_with_field_contain
    "<div class='ui-field-contain'>".html_safe + yield +
      "</div>".html_safe
  end


  def link_to_m(body, url, html_options={})
    html_options = html_options.merge("class"=>"ui-btn ui-btn-inline ui-corner-all ui-shadow")
    link_to(body, url, html_options)
  end

  # to be used in the panel on the login page
  def link_to_mp(body, url, html_options={})
    html_options = html_options.merge("class"=>"ui-btn")
    link_to(body, url, html_options)
  end

  def link_to_m_legend(a, b)
    a="<legend>#{a}</legend>".html_safe
    link_to(a, b, "class"=>"ui-btn  ui-corner-all ui-shadow")
  end




  def fd_text_area_m(field_desc, data_rec = nil, field_attrs={},
                     form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')
    help_url = get_help_url(field_desc)
    field_id = field_desc.target_field + suffix
    if !field_attrs[:value] && data_rec
      field_attrs[:value] = field_val(field_desc, field_id, data_rec)
    end
    field_attrs[:rows] = field_desc.control_type_detail['rows']
    field_attrs[:cols] = field_desc.control_type_detail['cols']
    rtn = basic_text_area_m(field_desc.display_name, form_obj, field_id,
                            help_url, field_attrs, field_desc.required)
    #add_required_m(field_desc, rtn)
  end

  def fd_password_m(field_desc, field_attrs,
                    form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')
    field_id = field_desc.target_field + suffix
    help_url = get_help_url(field_desc)
    rtn = basic_password_field_m(field_desc.display_name, form_obj, field_id,
                                 help_url, field_attrs, field_desc.required)
    #add_required_m(field_desc, rtn)
  end

  def fd_password_mb(*args)
    wrap_with_field_contain do
      fd_password_m(*args)
    end
  end


  def fd_labeled_text_value_m(field_desc, data_rec, suffix='')
    label = field_desc.display_name ? field_desc.display_name : ''
    "<small>#{label}:  #{field_val(field_desc, field_desc.target_field+suffix,
                                   data_rec)}</small>".html_safe
  end

  def fd_date_field_m(field_desc, data_rec,
                      form_obj=BasicModeController::FD_FORM_OBJ_NAME, suffix='')
    ctd = field_desc.control_type_detail
    help_url = get_help_url(field_desc)
    opts = {}
    field_name = field_desc.target_field + suffix
    if data_rec
      opts[:value] = field_val(field_desc, field_name, data_rec)
      opts[:placeholder] = " (date format #{ctd['tooltip']})" if ctd['tooltip']
    end
    label = field_desc.display_name
    #label += " (date format #{ctd['tooltip']})" if ctd['tooltip']
    rtn = basic_text_field_m(label, form_obj, field_name, help_url, opts, field_desc.required)
    #add_required_m(field_desc, rtn)
  end


  def fd_date_field_mb(*args)
    wrap_with_field_contain do
      fd_date_field_m(*args)
    end
  end


  def fd_fieldset_ma(field_desc)
    legend = "<b class='fieldset'>#{field_desc.display_name}</b>".html_safe
    field_set_tag(legend) {
      hb = "".html_safe
      if help_url = get_help_url(field_desc)
        hb << content_tag("div", help_button(help_url, 'Section Help'))
      end
      if field_desc.instructions
        hb << content_tag("div", field_desc.instructions, {:class=>"instructions"})
      end
      hb << yield
    }
  end

  def fd_fieldset_m_bak(field_desc)
    content_tag(:div, field_desc.display_name) {hb = "<b>#{field_desc.display_name}></b>".html_safe; hb<< "22222222222"}
  end
  def fd_fieldset_m(field_desc)
    content_tag(:div ) {
      hb = "<br><br>".html_safe
      if help_url = get_help_url(field_desc)
        hb << content_tag("div", help_button(help_url, 'Section Help'))
      end
      if field_desc.instructions
        hb << content_tag("div", field_desc.instructions, {:class=>"instructions"})
      end

      hb << yield
      hb << "<hr></br>".html_safe
      hb
    }
  end


  def fd_collapsible(field_name, &block)
    options={"data-role"=>"collapsible", "data-collapsed"=>"false"}
    output = tag(:div, options, true)
    output.safe_concat(content_tag(:legend, field_name)) unless field_name.blank?
    output.concat(capture(&block)) if block_given?
    output.safe_concat("</p></div>")
  end

end
