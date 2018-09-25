#
# This module handles most of the fields group table processing on the
# ruby/server
# side.  There is a little bit of fields table specific processing in
# form_helper, but just the minimum to take care of the interplay between
# that module and this one.
#
# I had wanted to implement this as a class, but we couldn't seem to get
# it to access all the form_helper methods needed to build individual
# fields, so for now we just made it a module.
#
module FieldsGroupHelper

  @@CE_TABLE_INSTRUCTIONS = "Click the mouse's right button to edit " +
                            'previously saved rows.'

  # The process_fields_group method creates and returns a populated fields
  # table for a fields group with orientation = horizontal.  Other tables
  # and groups may be nested within the table that is built and returned.
  # AND it also creates the HTML for a vertical group that's not contained
  # within a table, Paul.
  #
  # Parameters:
  # * header_field - the field_description row for the field designated
  #                  as the header field for the group
  # * fields_list - an array of field_description rows for the fields
  #                 that make up the group
  # * the_form - the form object for the containing form
  # * grp_hdr_attrs - attributes for the group header field
  # * fd_suffix - the current fields suffix in use.  Starts out nil, which
  #               signals a top-level field group.
  #
  def process_fields_group(header_field,
                           fields_list,
                           the_form,
                           grp_hdr_attrs ,
                           fd_suffix=nil)
    orientation = header_field.getParam('orientation')
    if orientation.nil?
      orientation = 'horizontal'
    end

    if (header_field.target_field[0,3] != 'tp_' &&
        orientation == 'horizontal' &&
        ( header_field.max_responses != 1 ||
         (header_field.max_responses == 1 && header_field.show_rowid)))
      fi = 0
      fields_list.each do |fd|
        class_array = fd.getParam('class')
        place = fd.getParam('place')
        if ((class_array.nil? || !class_array.include?('info_button')) &&
            (place.nil? || place != 'in_hdr'))
          if fd.target_field != header_field.target_field + '_row_id'
            # Add a row number column
            id_fd = FieldDescription.new({
                             :target_field => header_field.target_field +
                                              '_row_id',
                             #:field_type => 'ST - string data',
                             :control_type => 'static_text',
                             :control_type_detail => {'class'=>['readonly','rowid']},
                             :width => '1.8em' ,
                             :min_width => '1.8em',
                             :default_value => '1'})

            fields_list.insert(fi, id_fd)
            if header_field.controlled_edit &&
              (@access_level == ProfilesUser::NO_PROFILE_ACTIVE ||
               @access_level < ProfilesUser::READ_ONLY_ACCESS)
              # Also add an action button column - unless the user only
              # has read-only access to the profile.
              edit_fd = FieldDescription.new({
                  :target_field => header_field.target_field +
                    '_edit',
                  :control_type => 'image',
                  :control_type_detail => {
                    'source'=>asset_path('blank.gif'),
#                    'source'=>asset_path('menu.png'),
                    'onclick'=>'true', # for JAWS - clickable
                    'class'=>['cet_action'],
                    'alt'=>'button to show edit row menu'},
                  :width => '22px' ,
                  :min_width => '22px',
                  :form_id=>header_field.form.id,
                  :group_header_id=>header_field.id})
              fields_list.insert(fi+1, edit_fd)
            end
          end
          break ;
        else
          fi += 1
        end
      end
    end
    header_row_field_html, fields_list =
      build_header_row_fields(fields_list, the_form, fd_suffix)
    # Update the fields suffix now.

    if (fd_suffix.blank?)
      header_tag = 'h2'
      fd_suffix = '_0'
    else
      header_tag = 'h3'
      fd_suffix += '_0'
    end

    # Write the table/section headers first

    ret_table = String.new

    # Set up the graphic and callback for the arrows that expand
    # and collapse a table.

    header_id = make_form_field_id(header_field.target_field)
    label_id = header_id + '_lbl' + fd_suffix
    instructions_id = header_id + '_ins' + fd_suffix
    header_id += fd_suffix


    # Only output the header and table start specs on the first pass
    # through.
    open_param = header_field.getParam('open')
    expcol_div_id = header_id + '_expcol'

    group_status = nil
    if (open_param == '2')
      # Don't include the arrow; this group is not closable.
      group_button = ''
      open = true
    else
      open = header_field.getParam('open') == '1'
      group_status = open ? 'group_expanded' : 'group_collapsed'
      show_text = open ? 'Hide' : 'Show'
      img_class = open ? 'sprite_icons-expcol_group_expanded' :
        'sprite_icons-expcol_group_collapsed'
      arrow_img = image_tag(asset_path('blank.gif'),
        :alt => 'expand/collapse section button', :class=>img_class)
      group_button = content_tag("div", show_text.html_safe + arrow_img, {
          :id=>header_id + '_expcol_button',
          :class=>"hide_show_button #{group_status}"})
    end

    if grp_hdr_attrs[:class].blank?
      grp_hdr_attrs[:class] = 'fieldGroup'
    else
      grp_hdr_attrs[:class] += ' fieldGroup'
    end
    grp_hdr_attrs[:class] += ' ' + group_status if group_status
    grp_hdr_attrs[:id] = header_id
    if !header_field.max_responses.blank?
      grp_hdr_attrs[:max_responses] = header_field.max_responses
      if (grp_hdr_attrs[:max_responses] > 1 && header_field.show_max_responses)
        grp_hdr_attrs[:class] += ' showMaxResponses'
        if !@form_onload_js["Def.showMaxResponsesRows"]
          @form_onload_js["Def.showMaxResponsesRows"] = true
        end
      end
    end

    # instructions above the group header is no longer needed
#    if (header_field.controlled_edit)
#      ce_instr = @next_line + '<div class="guidance" id="' +
#        instructions_id + '">' + @@CE_TABLE_INSTRUCTIONS + '</div>'
#    end

    # check the header to see if we're supposed to print instructions
    if (!header_field.instructions.blank? &&
          header_field.instructions.length > 0)
      ce_instr = @next_line + content_tag('div',
          header_field.instructions.html_safe,
          {:class=>"guidance", :id=> instructions_id})
    else
      ce_instr = ""
    end


    ret_table = tag('div', grp_hdr_attrs, true)
    ret_table += (@next_line + ce_instr) unless ce_instr.blank?
    skip_header_tag = !grp_hdr_attrs[:class].index('no_group_hdr').nil?
    if !skip_header_tag
      header_tag_attrs = {:class=>'groupHeader'}
      if open_param != '2'
        @form_field_js << "$('#{header_id}').down('#{header_tag}')."+
          "observe('click', function() { expColSection('#{expcol_div_id}')});\n"
      end

      ret_table += content_tag(header_tag,
        @next_line + group_button + @next_line +
        content_tag("span", header_field.display_name, :id=>label_id ) +
        helpButton(header_field) + header_row_field_html,
        header_tag_attrs)
    end

    # Add the division that contains the actual table.  This is
    # what gets toggled for display or not displayed by the arrow.
    # We include the fields suffix here that should be used for
    # children of this header (not for the header itself)
    param_class_array = header_field.getParam('class')
    exp_collapse = 'expand_collapse'
    if !param_class_array.nil? && param_class_array.include?("no_group_hdr")
      exp_collapse = ''
    end
    #style = open ? '" ' : '" style="display: none;" '
    options = {:class=>"fieldExpColDiv #{exp_collapse}",
      :id=>expcol_div_id, :suffix=>fd_suffix}
    options[:style]="display: none;" if !open
    ret_table += @next_line + tag('div', options)

#    # check the header to see if we're supposed to print instructions
#    # under the header line
#    if (!header_field.instructions.blank? &&
#          header_field.instructions.length > 0)
#      ret_table += @next_line + '<div class="guidance" id="' +
#        instructions_id + '">' + header_field.instructions + '</div>'
#    end

    # If this is a vertical field group, the fields are to appear in
    # a vertical row (the first at the top of the group, the next below
    # it, the next below that, etc).  Call displayField to build each
    # field, indicating that field labels should be generated as normal.
    # -- only do this the first time through.  We don't need a model
    #    version of this.

    if (orientation == 'vertical')
      ret_table += vertical_field_group(header_field, fields_list, the_form,
        fd_suffix)
    else
      ret_table += horizontal_field_group(header_field, fields_list, the_form,
        fd_suffix, header_id)
    end # if vertical/horizontal field group

    # close out the divs (expand/collapse and whole thing); return the table
    ret_table += '</div></div>'.html_safe + @next_line
    return ret_table

  end # process_fields_group method


  private ###########################  Private Methods ###################

  # These methods provide additional functionality to the main field
  # groups processing method.  PLEASE keep them in alphabetical order
  # so that they're easy to find.  Thanks.  lm
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



  # Builds and returns the HTML for the fields that appear in the same row as
  # the header for the group.  On return, the fields_list parameter will
  # have these fields removed.
  #
  # Parameters:
  # * fields_list - an array of field_description rows for the fields
  #                 that make up the group
  # * the_form - the form object for the containing form
  # * fd_suffix - the current fields suffix in use.  Starts out nil, which
  #               signals a top-level field group.
  #
  # Returns the HTML for the fields, having them included in a 'inline_fields'
  # span if there are at least one fields, otherwise the HTML is empty;
  # plus the revised fields_list (which is the input fields_list minus the
  # processed check boxes).
  def build_header_row_fields(fields_list, the_form, fd_suffix)

    # We want to put any checkboxes that appear at the start of the list
    # of fields inside the header tag, so they appear on the same line as
    # the header.  Hm - also want them to be flagged for the header.
    # Pass the displayField in_table as false because although the boxes
    # are in the table header, they won't be displayed in a table cell.
    # Makes a difference in how much or how little html we get back.
    fields_array = fields_list.to_a
    field_html = ''.html_safe
    while ((next_field=fields_array[0]) &&
            next_field.getParam('place') == 'in_hdr')
      field_html += displayField(next_field, the_form, false, {}, fd_suffix)
      fields_array.shift
    end

    if !field_html.blank?
      field_html = content_tag('span', field_html, :class=>"inline_fields")
    end
    return field_html, fields_array
  end


  # Builds the HTML for a table row of a horizontal field group table.
  #
  # Parameters:
  # * fields_list - an array of field_description rows for the fields
  #    that make up the group
  # * fd_suffix - the suffix for the field group.
  # * is_model - whether this is a model row or not.
  # * hidden_cols - an array of booleans that indicate which columns are
  #    hidden fields.
  # * label_cells - whether cells in the row should be labeled
  # * the_form - the Rails form object for the containing form
  # * func_call - the call to the repeating line function, if appropriate
  #    for this group.  Will be added to blur observers for fields in the row.
  # Returns: the HTML for the row
  def build_table_row(fields_list, fd_suffix, is_model,
                      hidden_cols, label_cells, the_form, func_call)

    row_suffix = is_model ? fd_suffix : fd_suffix.chop + '1'
    row_id = is_model ? 0 : 1

    row_fields = []
    embedded_rows = []
    tagAttrs = []

    fields_list.each do |fd|
      # Get field info from displayField.  Check to make sure we got something.
      # If the form is being displayed in read-only mode, there may be a field
      # marked for omission that is still in the fields_list.
      field_html = displayField(fd, the_form, true, nil, row_suffix)
      if !field_html.nil?
        row_field_html = field_html[1]
        if row_field_html.include?("images")
          Rails.logger.debug("The field #{fd.inspect} has images in it")
        end
        case fd.control_type
        when 'group_hdr'
          embedded_rows << row_field_html
        else
          tag_attrs = Hash.new
          fd_classes = fd.getParam("class")
          if fd.control_type == 'calendar'
            tag_attrs[:class]='dateField rowEditText' # For CSS purposes
          elsif fd.control_type == 'image' && fd.in_hdr_only
            tag_attrs[:class] = fd_classes.join(' ')
          elsif (fd.control_type == 'text_field' ||
                 fd.control_type=='search_field')
             # Add a white background for editable cells
             tag_attrs[:class] = 'rowEditText' if fd.editable?(@edit_action)
          end
          if !func_call.nil?
            add_observer(fd.target_field, 'change', func_call)
          end

          # prepend a label if we're labeling the cells, and it's not a button
          if label_cells && fd.control_type!='button' &&
              !fd.display_name.nil? && fd.control_type != 'hyperlinked_text'
            row_field_html = (fd.display_name + ': ').html_safe + row_field_html
          end
          row_fields << row_field_html

          if !fd_classes.nil?
            if fd_classes.include?('info_button') && fd.control_type == 'image'
              tag_attrs[:class] = 'info_button'
            elsif fd_classes.include?("rowid")
              tag_attrs = merge_tag_attributes!(tag_attrs, {:class=>'rowid'})
            elsif fd_classes.include?("cet_action") &&
              (@access_level == ProfilesUser::NO_PROFILE_ACTIVE ||
               @access_level < ProfilesUser::READ_ONLY_ACCESS)
              tag_attrs = merge_tag_attributes!(tag_attrs, {:class=>'cet_action'})
            elsif fd_classes.include?('sprite_icons-record_warning')
              tag_attrs = merge_tag_attributes!(tag_attrs, {:class=>'record_warning'})
            end
          end

          if fd.control_type == 'hyperlinked_text' ||
             (!tag_attrs['class'].nil? &&
              tag_attrs['class'].include?('hdr_url_btn'))
            tag_attrs = merge_tag_attributes!(tag_attrs,
                   {:id=>make_form_field_id(fd.target_field,row_suffix)+'_td'})
          end
          # evidently we need an entry in the array for each field in the row?
          tagAttrs << ((!tag_attrs.blank?) ? tag_attrs : "")
        end # case
      end # if we got something back from displayField
    end

    num_cols = hidden_cols.inject(0) {|sum, e| sum+(e ? 0 : 1)}
    row_local_vars = {:row_id=>row_id, :row_suffix=>row_suffix,
      :row_fields=>row_fields,
      :hidden_cols=>hidden_cols, :labeled_fields=>label_cells,
      :num_cols=>num_cols, :embedded_rows=>embedded_rows, :tagAttrs=>tagAttrs }
      #:row_id_field=>row_id_field, :row_fields=>row_fields,
    return render(:partial=>'form/horizontal_field_group_row.rhtml', :handlers=>[:erb],
      :locals=>row_local_vars).html_safe
  end # build_table_row


  # This method creates the full HTML for a column header cell, from
  # the <th> to the </th> tags.
  #
  # Parameters:
  # * col_head - a string containing the html for the header
  # * target_field - the unadorned name of the field we're creating -
  #   without an object prefix or level suffix
  # * suffix - the suffix for the field, indicates the level in the
  #   form hierarchy at which the data appears
  # * col_class - the class(es) to be assigned to the header
  #
  # Returns: the full HTML for the column header
  #
  def column_hdr(col_head, target_field, suffix, col_class)

    id = make_form_field_id(target_field, suffix)
    return content_tag("th", col_head,
      { :id => id ,
        :class => col_class} )
  end # column_hdr


  # Returns an array of column header HTML (th tags plus inner HTML) for the
  # columns of the horizontal field group table, and an array of booleans to
  # signal which columns are hidden.
  #
  # Parameters:
  # * fields_list - an array of field_description rows for the fields
  #                 that make up the group
  # * make_headers - whether column headers should be generated.  If this is
  #   false, the first of the two returned arrays will be empty.
  def column_info(fields_list, make_headers)
    headers = []
    hidden_cols = []
    fields_list.each do |fd|
      unless fd.control_type == 'group_hdr' ||
        (@access_level == ProfilesUser::READ_ONLY_ACCESS &&
         !fd.control_type_detail["class"].nil?  &&
         fd.control_type_detail["class"].include?("no_read_only"))
        if make_headers
          # This will need to be revised to use the templates.
          headers << create_field_header(fd)
        else
          # add empty header so that rhtml can still iterate and put cols
          # in the table with style attrs.
          headers << ''
        end
        hidden_cols << fd.hidden_field?
      end
    end
    return headers, hidden_cols
  end


  # This method determines the settings and attributes for the column
  # header(s) for a field.  It returns the full HTML for the column
  # header cell.
  #
  # Parameters:
  # * fd - the field for which we are constructing a header
  #
  # Returns: the full HTML for the header, from <th> to </th>
  #
  def create_field_header(fd)

    if (fd.hidden_field?)
      col_class = 'fieldsTableHeader hidden_field'
    elsif (fd.control_type == 'image' || fd.control_type =='check_box')
      col_class = 'fieldsTableHeader nosort'
    else
      col_class = 'fieldsTableHeader'
    end

    col_head = add_required_icon(fd) # might return ''
    if fd.control_type == 'image' && fd.in_hdr_only
      source_path = fd.getParam('source' )
      alt_text    = fd.getParam('alt' )
      on_click    = fd.getParam('onclick' )
      img_tag_attrs = {:align=>"center",
                       :alt => alt_text,
                       :title => alt_text,
                       :onclick => on_click}
      col_class += ' ' + fd.getParam("class").join(' ')
      col_head += image_tag(source_path, img_tag_attrs)
    elsif fd.display_name && fd.control_type != 'sub_form_button'
      col_head += fd.display_name
    end
    col_head += helpButton(fd)

    # wraps col_head in th tag
    ret_hdr  = column_hdr(col_head, fd.target_field, '_hd', col_class)
    return ret_hdr

  end # create_field_header



  # This method determines the widths for each column in the table,
  # based on the field specifications and types.  The widths are
  # provided as percentages of the total table width.
  #
  # Parameters:
  # * fields_list - a list of the field description records that define
  #   each field
  #
  # Returns: an array of widths for each column
  #
  def determine_column_widths(fields_list)

    widths = Array.new
    min_widths = Array.new
    # determine absolute width of the table and each column
    fields_list.each do |fd|
      if fd.control_type == 'group_hdr'
        break # a group_hdr field is the start of an embedded row
      end
      fd_width = fd.width
      if !fd_width
        if (fd.field_type[0,2] == 'DT')
          fd_width = DEF_DATE_FLD_WIDTH
        elsif (fd.field_type[0,2] == 'NM')
          fd_width = DEF_INT_FLD_WIDTH
        else
          fd_width = DEF_STRING_FLD_WIDTH
        end
      end

      fd_min_width = fd.min_width
      if !fd_min_width && fd.field_type[0,2] == 'DT'
        fd_min_width = fd_width
      end
      widths << fd_width
      min_widths << fd_min_width
    end # each field

    return [widths, min_widths]
  end # determine_column_widths


  # Processes a horizontal field group and returns the HTML for the fields
  # inside (arranged as a repeating-line table).
  #
  # Parameters:
  # * header_field - the field_description row for the field designated
  #                  as the header field for the group
  # * fields_list - an array of field_description rows for the fields
  #                 that make up the group
  # * the_form - the form object for the containing form
  # * fd_suffix - the suffix for the field group.
  # * header_id - the ID of the group's DOM node
  #
  # Returns: the HTML for the fields in the field group.  It does not
  # include the header for the group.
  def horizontal_field_group(header_field, fields_list, the_form,
                             fd_suffix, header_id)
    ret_table = ''
    # Set a flag that we use to determine if the fields in the table
    # will have column headers (label_cells is false) or will have
    # labels within the cells (label_cells is true)

    label_cells = (header_field.getParam('labels') == 'label')

    # Only output the table-level html the first time through.

    # Build the table-level html.  Include the class sortable if the
    # table is to be sorted, which will be picked up later in processing
    # by the sorting algorithms.  A table is sortable if the specs do
    # not include a parameter prohibiting sorting AND if it can have
    # more than one row (max_responses either = 0 or > 1).
    # TODO - RIGHT NOW WE'RE NOT SORTING TABLES THAT USE FIELD
    #        LABELS.  IMPLEMENT LATER.   THE PROBLEM IS THAT WE
    #        DON'T WANT THE SORT FLAGS ON THE FIRST ROW(S) OF THE
    #        TABLE, WHICH ARE MODEL ROWS.  11/7/07.  lm

    table_id = header_id + '_tbl'

    # SORTING TEMPORARILY DISABLED.  The controlled edit table stuff
    # has broken it and we are not taking the time, at the moment to
    # fix it.  Maybe later.
    # determine table class based on if the table is sortable
    #if ((header_field.max_responses == 1) ||
    #      (header_field.getParam('sortable') == 'false') || (label_cells))
    #  sortable_class = ''
    #else
    #  sortable_class = ' sortable'
    #end
    #table_class = 'fieldsTable' + sortable_class

    # sortable table is needed again, for date reminder table
    # it applies to a table only when the sortable is set to true
    # by default a table is not sortable. (it was before)  --6/9/2010 ye
    if (header_field.max_responses != 1 && header_field.getParam('sortable') == 'true')
      sortable_class = ' sortable'
    else
      sortable_class = ''
    end
    table_class = 'fieldsTable' + sortable_class

    table_partial_vars = {:table_class=>table_class, :table_id=>table_id,
      :fd_suffix=>fd_suffix}

    # Determine the column widths
    w_arr = determine_column_widths(fields_list)
    widths = w_arr[0]
    min_widths = w_arr[1]

    # Create the table cell that contains the delete button and
    # start the input row line - if we're using column headers.
    # If we're using column headers put an empty beginning column
    # header into the table for it.
    # -- NOPE - NOT USING THIS YET.
    #del_id = 'fe_delete_row_' + header_field.target_field
    #del_id += fd_suffix if (!fd_suffix.nil?)

    #delete_img = image_tag("/icons/cancel.png",
    #                       :alt => 'delete row button',
    #                       :id  => del_id,
    #                       :class => 'eventsHandled',
    #                       :onclick => 'deleteRow(this)')

    # Add the event handler to automatically add rows to the table if
    # specified - unless the user only has read access to the profile
    if header_field.auto_add_row &&
       (@access_level == ProfilesUser::NO_PROFILE_ACTIVE ||
        @access_level < ProfilesUser::READ_ONLY_ACCESS)
      func_call = 'function(event){Def.FieldsTable.repeatingLine(this, ' +
        header_field.max_responses.to_s + ');}'
    else
      func_call = nil
    end

    fields_headers, hidden_cols =
      column_info(fields_list, !label_cells)


    # Assume we have an id field, and create a hidden field for it and
    # a header field.
    # only if this table contains more than 1 row.
    # max_responses == 0 or nil means infinite
    # RECORD ID is now a row in the field_descriptions table - no need for this
    #if header_field.has_id_column?
    #  id_field_col =
    #    column_hdr('', header_field.target_field.singularize, '_hd',
    #    'fieldsTableHeader hidden_field nosort')
    #else
    #  id_field_col = nil
    #end

    table_partial_vars[:fields_headers] = fields_headers

    # Create table rows
    model_row_html = build_table_row(fields_list, fd_suffix, true, hidden_cols,
                                     label_cells, the_form, func_call)

    if header_field.controlled_edit
      # Create the read-only version of the model row.
      prev_read_only_flag = @read_only_mode
      @read_only_mode = true
      read_only_model_row =
        build_table_row(fields_list, fd_suffix, false, hidden_cols,
                        label_cells, the_form, func_call)
      @read_only_mode = prev_read_only_flag

      set_up_controlled_edit_table(header_field, fields_list, header_id,
        read_only_model_row)

      # Don't create the blank repeating line row-- do that on the client side.
      first_row_html = ''
    else
      first_row_html = build_table_row(fields_list, fd_suffix, false,
                                       hidden_cols, label_cells, the_form,
                                       func_call)
    end

    # Generate the table
    table_partial_vars[:model_row] = model_row_html
    table_partial_vars[:first_row] = first_row_html
    #table_partial_vars[:id_field_col] = id_field_col
    table_partial_vars[:widths] = widths
    table_partial_vars[:min_widths] = min_widths
    table_partial_vars[:hidden_cols] = hidden_cols
    table_partial_vars[:fields_list] = fields_list
    ret_table = render(:partial=>'form/horizontal_field_group.rhtml', :handlers=>[:erb],
      :locals=>table_partial_vars)
    return ret_table.html_safe
  end  #horizontal_field_group


  # This method removes an input field size specification from the line
  # passed in.  The Rails field creation methods often insert a size
  # specification for a field, whether a size option is specified or not.
  # For horizontal tables of fields we don't want that size specification
  # there, because we're sizing fields within table cells, where the cell
  # size is a percentage of the horizontal line space.
  #
  # The size for the input field that goes into the cell is in relation
  # to the cell itself, and for that we want the contents of the cell to
  # almost fill it.  For fields in tables with column headers, we're
  # specifying 97% for the input field, to almost fill the cell.  For
  # tables with in-line labels, we're trying 50% to see if that will work.
  # For calendar fields in tables with column headers, we're specifying
  # 90% to leave room for the calendar image.
  #
  # Parameters:
  # * spec - the HTML for the input field
  # * label_cells -  a boolean indicating whether or not the cells will
  #   contain a field label
  # * control_type - the control type for the current field.  Used to
  #   recognize calendar fields.
  #
  # Returns: the HTML with any size specification adjusted
  #
  def set_size(spec, label_cells, control_type)
    if (!spec.blank?)
      if (control_type == 'calendar')
        sz = '100%'
      elsif (label_cells)
        sz = '50%'
      else
        sz = '97%'
      end
      ix = spec.index('size="')
      while (!ix.blank?)
        ix21 = spec.index('style="z-index: 2; opacity: 0;"')
        if(!ix21.blank?)
          ix22 = spec.index('"', ix21 + 7)
          spec= spec.to(ix21+6) + 'width: '+ sz +'; '+
            spec.from(ix21 + 7)
          ix = spec.index('size="')
          ix2 = spec.index('"', ix + 6)
          spec = spec.to(ix - 1) + spec.from(ix2 + 1)
          ix = spec.index('size="', ix2 + 1)
        else
          ix2 = spec.index('"', ix + 6)
          spec = spec.to(ix - 1) + ' style="width: ' + sz + '" ' +
            spec.from(ix2 + 1)
          ix = spec.index('size="', ix2 + 1)
        end
      end
    end
    return spec
  end # set_size


  # Sets up JavaScript calls and data structures needed for the controlled
  # edit tables.
  #
  # Parameters:
  # * ce_table - a field description that is a controlled edit table.
  # * fields_list - an array of field_description rows for the fields
  #                 that are in ce_table
  # * field_group_id - id of the table's field group's DOM node
  # * read_only_model_row - the HTML for the read-only version of the model
  #   row.
  def set_up_controlled_edit_table(ce_table, fields_list, field_group_id,
      read_only_model_row)

    # Compute an array of booleans (0/1) that indicates whether the fields
    # are editable.
    editable_field = []
    # Nope - record ids are not fields in the field_descriptions
    #if (ce_table.has_id_column?)
    # editable_field << 1 # so ID field can be sent back with edited row data
    #end
    edit_allowed_fields = ce_table.edit_allowed_fields.split(',')
    edit_allowed_set = Set.new(edit_allowed_fields)
    target_field_names = Set.new
    fields_list.each do |f|
      tf = f.target_field
      target_field_names << tf
      editable_field << edit_allowed_set.member?(tf) ? 1 : 0
    end

    # Add warnings for fields that shouldn't have duplicates
    conflict_checker = nil
    fields_list.each do |f|
      if f.cet_no_dup
        tf = f.target_field  # the field shown to the user
        # See if there is a code field for this field.
        code_field = tf + '_C'
        if target_field_names.member?(code_field)
          code_field = '\'' + code_field + '\''
        else
          code_field = 'null'
        end

        # The cet_no_dup_check is in the format
        # ConflictCheckerClass.check_method.  The idea is that each table
        # should have just one conflict checker instance, but that individual
        # fields might need different method calls on the checker instance.
        # So, if cet_no_dup_check is set, the class name should be the same
        # for all fields in the table, but the method names will vary.
        if f.cet_no_dup_check
          conflict_checker, warn_method = f.cet_no_dup_check.split('.')
        else
          warn_method = 'warnAboutDuplicates'
        end
        # Use a timeout to allow the data model to get updated before
        # the duplicate check.
        add_observer(f.target_field, 'change',
          'function() {setTimeout(function() {'+
             '$("'+field_group_id+'").ce_table.conflictChecker_.'+warn_method+
             '(this, '+code_field+');'+
          '}.bind(this), 1)}')
      end
    end

    ce_data = {
      :is_editable_field => editable_field,
      :read_only_model_row => read_only_model_row
    }
    if ce_table.controlled_edit_menu
      ce_data[:controlled_edit_menu] = ce_table.controlled_edit_menu
      ce_data[:controlled_edit_actions] = ce_table.controlled_edit_actions
    end

    # Compute the record ID target_field from the header field target field.
    record_id_tf = ce_table.target_field.singularize + '_id'

    @ce_table_data[ce_table.target_field] = ce_data
    if conflict_checker
      conflict_checker = ', new Def.FieldsTable.ControlledEditTable.'+
        conflict_checker +'()'
    else
      conflict_checker = ''
    end
    @form_field_js << 'new Def.FieldsTable.ControlledEditTable("'+
      field_group_id+'", "'+record_id_tf+'"'+conflict_checker+');' << "\n";

  end

  # Processes a vertical field group and returns the HTML for the fields
  # inside.
  #
  # Parameters:
  # * header_field - the field_description row for the field designated
  #                  as the header field for the group
  # * fields_list - an array of field_description rows for the fields
  #                 that make up the group
  # * the_form - the form object for the containing form
  # * fd_suffix - the suffix for the field group.
  #
  # Returns: the HTML for the fields in the field group.  It does not
  # include the header for the group.
  def vertical_field_group(header_field, fields_list, the_form, fd_suffix)

    ret_table = ''.html_safe
    fd_suffix = fd_suffix.chop + '1'

    if !@fb_variable_flds.nil? &&
        @fb_variable_flds['fields_hash_populated'] == false
      first_0 = fd_suffix.index('_0')
      if !first_0.nil?
        aft_pos = first_0 + 2
        aft_len = fd_suffix.length - aft_pos ;
        if (aft_len > 0)
          aft_suffix = fd_suffix[aft_pos, aft_len]
          if !@fb_variable_flds[header_field.target_field].nil?
            @fb_variable_flds[header_field.target_field] =
              aft_suffix.chop.to_s + '0'
          end # if we have an entry for this header
        end # if there is anything beyond the _0
      end # if we found _0 in the string
    end # if we have the fields hash and aren't done setting it

    fields_list.each do |sf|
      if !@fb_variable_flds.nil? &&
          @fb_variable_flds['fields_hash_populated'] == false &&
          !@fb_variable_flds[sf.target_field].nil?
        if @fb_variable_flds[sf.target_field] != ''
          @fb_variable_flds['fields_hash_populated'] = true
        else
          @fb_variable_flds[sf.target_field] = aft_suffix.to_s
        end # if we haven't already set the after-suffix for this field
      end # if we have the fields hash, it hasn't been fully populated
      # and the current field is listed in it.

      ret_table += @next_line + displayField(sf, the_form, false, {},
                                             fd_suffix).to_s + @next_line
    end # do for each field in the vertical group

    return ret_table
  end#vertical_field_group

end # FieldsGroupHelper module

