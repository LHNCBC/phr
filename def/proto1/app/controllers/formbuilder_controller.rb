class FormbuilderController < ApplicationController
  before_action :admin_authorize
  helper :calendar
  helper :form

  FORM_BUILDER_FORM_NAME = 'FormBuilder'
  BOTH_CONST = "BOTH"
  ONLY_CONST = " only"
  ALL_CONST = "ALL"
  PREFIX = "fe_"
  
  # parameters that may or may not apply to a particular list
  # field specification.  See the process_list_field method.
  VARIABLE_LIST_PARAMS = ['auto', 'conditions', 'fields_displayed',
                          'fields_returned', 'fields_searched',
                          'list_id', 'list_name', 'match_list_value',
                          'order', 'prefetch']
                          
  # control_type_detail parameters that don't match up to a form builder
  # field name but that are handled programmatically, i.e. match_list_value
  # is set based on whether a list field is type CNE or CWE.
  PROGRAMMATIC_PARAMS = ['prefetch', 'auto',
                         'fields_returned', 'list_name', 'list_id',
                         'match_list_value']
  # ACTIONS:
  
  # This action shows a blank form builder form for creating a new form.
  #
  # Parameters: none
  #
  # Returns: nothing explicitly, but sets it up so that an empty
  # form builder form is displayed.
  #
  def new_form
    #@fb_field_types_map = FormBuilderMap.get_map
    @fb_field_types_map = FormBuilderMap.get_hash
    @fb_variable_flds = FormBuilderMap.get_fields_hash    
    @action_url = '/forms' # post back to create form
    render_form('FormBuilder')
  end  
  
  
  # This action is invoked when the user asks to edit an existing
  # form definition.  This extracts the definition data from the
  # <b>forms</b> and <b>field_descriptions</b> tables and writes
  # it to the @data_hash object.  The @data_hash object will be
  # unloaded and the data written to the form fields on the client
  # side.
  #
  # There is some special data handling involved in this process:
  #
  # * "internal" fields - such as code fields added for list fields and _ET
  #   (epoch time) and _HL7 (HL7 date) fields added for date fields will be 
  #   loaded (by code that loads forms other than the Form Builder) to the
  #   form being defined, but are not loaded here to the form builder form.  
  #   The form designer has no control over these fields, and so does not need
  #   to see them.
  #
  # * "exception" fields:
  #   * the <b>group_header_name</b> and <b>regex_validator</b> fields are 
  #     displayed on the form, but the values are not stored in the 
  #     field_descriptions table.  Instead, the <b>id</b>s for those fields are
  #     stored in the <b>group_header_id</b> and <b>regex_validator_id</b> form
  #     builder fields, which correspond to columns in the field_descriptions
  #     row.  Since only the codes are stored, the <b>group_header_name</b> and
  #     <b>regex_validator</b> fields are filled as the data hash is created
  #     here, using their respective <b>id</b> values to get the appropriate
  #     text.
  #
  #   * the <b>ctd_edit</b> and <b>ctd_edit_C</b> fields don't quite follow
  #     convention, in that the text string for the edit code is shown in the
  #     <b>ctd_edit</b> form field that is displayed to the user and the code is
  #     stored in the <b>ctd_edit_C</b> field that is hidden from the user. 
  #     BUT, the form display code expects the code to be in <b>ctd_edit</b>,
  #     not <b>ctd_edit_C</b>.  So the code that's read in for the
  #     <b>ctd_edit_C</b> parameter is used to get the text string to be placed
  #     in the <b>ctd_edit</b> form field.
  #    
  #   * <u>list fields</u>.  There are multiple parameter (ctd_) fields involved
  #     in the definition of a form field for a list field (CNE or CWE).  And
  #     other data that has not separate fields, because the user never sees
  #     them.
  # 
  # If all goes well, the data is loaded to the data_hash and the user
  # moved to the form, with the data safely loaded to it.  If we run into a
  # problem, an error message is generated and the originating form is
  # redisplayed with the error message
  #
  # Parameters:
  # * form_name - the name of the form to be edited
  #
  # Returns:  nothing explicitly, but the @data_hash is created (unless
  # there are problems getting the form or loading the data).
  #  
  def edit_form
      
    # Get the form name, the form, and the FormBuilder form definitions.
    # If any of those things are missing we can't continue.    
    form_name = params[:form_name]   
    if form_name.nil?
      @page_errors << "No form name given.<br>" +
                      "Cannot edit the unknown.<br>" +
                      "Form name is vital.<br>"
      success = false
    else
      success = true
      target_form = Form.find_by_form_name(form_name)
      if target_form.nil?
        @page_errors << "With searching comes loss<br>" +
                        "and the presence of absence.<br>" +
                        "Form " + form_name + " not found.<br>"
        success = false
      else        
        # Get the FormBuilder form definition (not the definition of
        # the form we're editing; the FormBuilder definition).
        fb_form = Form.find_by_form_name(FORM_BUILDER_FORM_NAME) 
        top_fb_defs = fb_form.top_fields
        if fb_form.nil? || top_fb_defs.nil?
          @page_errors << "Chaos reigns within.<br>" +
                          "FormBuilder definitions are gone.<br>" +
                          "Seek help to go on."
          success = false
        else
          # Get the exclusions table.  We need this to bypass processing
          # form fields that don't apply to a current field type.
          exclusions = FormBuilderMap.get_exclusions_hash(true)      
          if exclusions.nil?
            @page_errors << "Chaos reigns within.<br>" +
                            "Exclusions table is gone.<br>" +
                            "Seek help to go on."
            success = false
          end        
        end # if the FormBuilder form definitions are/aren't hosed
      end # if we don't/do have the requested form
    end # if a form name wasn't/was specified
    
    if success    
      # Get the field definitions for the current form
      form_fields = target_form.fields
      
      # Build the data hash based on the form builder definition, and fill
      # it with the data defined for the subject form
      @data_hash = Hash.new
      top_fb_defs.each { |fb_def|
      
        # Load the form-level data from target_form into the top level fields
        # defined for this particular form.  e.g, the form builder
        # form_name field will be loaded with the form name from the
        # target_form data.  Bypass any FormBuilder display_only fields.
        if !fb_def.predefined_field.display_only
          @data_hash[fb_def.target_field] =
                                          target_form.send(fb_def.target_field)
          log_this ' wrote ' + @data_hash[fb_def.target_field].to_s + ' to ' +
                   '@data_hash[' + fb_def.target_field + ']'
          # if this field gets its value from a text list, call
          # get_text_list_val to get the value to be displayed 
          # (which can differ from what's stored).
          if !fb_def.control_type_detail.nil? && 
             fb_def.control_type_detail.include?('search_table=>text_lists')
            if fb_def.control_type_detail.include?('match_list_value=>true')
              @data_hash[fb_def.target_field] =
              get_text_list_val(fb_def, true, @data_hash[fb_def.target_field])
            else
              list_val = 
              get_text_list_val(fb_def, true, @data_hash[fb_def.target_field])
              if !list_val.nil?
                @data_hash[fbdef.target_field] = list_val
              end
            end # if the value must come from the list or may vary 
          end # end if the field gets its value from a text list
        end # end if the field is not a display-only field
      
        # If the top level field to be loaded with data is the group that
        # contains all of the field descriptions, process each field definition.
        # The data hash for this particular top level field needs an
        # array with one element for each field description defined for
        # this particular form.  Run through each field description
        # object, passing it to the load_field_def method along with the 
        # top level field definition.  The method will return one 
        # hash for each field description object, which is added
        # to the group array, which is then written to the data_hash
        # for the top_level field.
        if fb_def.target_field == 'field_description'
          field_defs_array = Array.new
          form_fields.each { |fdata|
            
            # OMIT fields for the target_form that are internal fields -
            # those that are created and used programmatically and never
            # seen by the form designer or user.  The form designer doesn't
            # need to do anything with them.            
            if !(fdata.target_field[-3,3] == '_ET' ||
                 fdata.target_field[-4,4] == '_HL7' ||
                 fdata.target_field[-2,2] == '_C')
                 
              # Get a copy of the field's control_type_detail field in the form 
              # of a hash, and pass that along.  Fields with data located in
              # control_type_detail will be loaded with data from the hash,
              # and each parameter will be removed from the hash as it's loaded.
              ctd_parameters = fdata.controls_hash
              
              # Pass along the exclusions list for the current field type
              grp_hash, ctd_parameters = load_field_def(fb_def, fdata,
                                                   exclusions[fdata.field_type],
                                                   ctd_parameters)
                                                   
              # Do processing that can only be done after we've gone through
              # all the fields.  (I wanted to do this at the end of
              # load_field_def, but since that's called recursively for nested
              # field groups, it wasn't the right place to do it).
              if grp_hash['supported_ft'] == true
              
                # Check to see if we have any leftover parameters in the
                # control_type_detail column for this particular field.  If so,
                # and if they're not ones we expect to be leftover (handled
                # programmatically only), put a note about them in the
                # not_yet_msg field.                
                if !fdata.control_type_detail.nil?
                  params_list = String.new
                  ctd_parameters.each do |key, val|
                    if !PROGRAMMATIC_PARAMS.include?(key)
                      log_this('writing ' + key + ' to unsupported params list')       
                      params_list << key + '(=>' + to_formatted_s(val) + '), '
                    end # if the parameter is not handled programmatically
                  end # end do for each leftover parameter 
                  if !params_list.nil? && params_list != ''
                    if grp_hash['not_yet'].nil?
                      grp_hash['not_yet'] = Hash.new
                    end
                    grp_hash['not_yet']['not_yet_msg'] = 
                            '<br><center>Hm. Missing something?<br>' +
                            'Parameter(s) shown below?<br>'  +
                            ' - Not supported yet.<br>'
                    grp_hash['not_yet']['not_yet_msg'] << 
                                  params_list.chomp(',') + '</center>'
                  end # if any leftovers are not handled programmatically
                end # if there are any leftover parameters
              end # if this is a supported field type
              
              # Ok, we're done with this field
              field_defs_array << grp_hash
            end # end do if this is not a field we omit 
          } # end do for each field definition
          @data_hash[fb_def.target_field] = field_defs_array
        end # end if this is the group header for the field definitions
      } # end do for each top-level field of the form
    end # if we were able to get the form and form builder definitions
    
    #@fb_field_types_map = FormBuilderMap.get_map
    @fb_field_types_map = FormBuilderMap.get_hash
    @fb_variable_flds = FormBuilderMap.get_fields_hash
    @edit_action = true
    @action_url = '/forms'
    render_form('FormBuilder')
   
  end # edit_form   
  
  
  # This action controls storing data from the form builder form to the
  # forms and field_descriptions tables.
  #
  # Parameters: 
  # * fe - the form object returned from the browser.  It is a hash
  #   of name/value pairs where the form field id is the key and
  #   the value, if any, typed into the field is the value.
  #
  # Returns: nothing explicitly, but sets it up so that the 
  # form that called this one is displayed.
  #
  def save_form
  
    # Get the form data object, which is a hash that contains
    # form field name/value pairs for each input field on the
    # form.  We'll use a clone of it, because as we use form
    # name/value pairs we delete them from the hash.  Then, 
    # when we've parsed everything we can see if we have anything
    # left over.  Sort of like taking a car apart and then putting
    # it back together.  If no parts are left over, everything's
    # great - right?
    fe = get_param(:fe)

    # Check now for the save_and_close button in the fe object.
    # We won't actually use it until we're done saving, but we
    # destroy the fe object as we process it, so grab this before
    # we try to make it a field.
    save_and_close = fe.delete('save_and_close')
    
    # Get default values for the form builder form - NOT the form 
    # being created here.  We need those to determine whether or not
    # a field description line is empty.  Empty lines still get the
    # default values.    
    fb_form = Form.find_by_form_name(FORM_BUILDER_FORM_NAME)
    fb_vals = FieldDescription.where(form_id: fb_form.id).to_a
    #def_vals = FieldDescription.where("form_id = ? AND default_value IS NOT NULL", fb_form.id.to_s)
    fb_defs = Hash.new
    fb_fields = Hash.new
    fb_vals.each do |fv|
      fb_fields[fv.target_field] = fv
      if (!fv.default_value.nil?)
        fb_defs[fv.target_field] = fv.default_value
      end
    end
  
    # find current form, if it exists in the database.  Use the 
    # form id - not the form name.
    form_id = fe['id'].to_i
    if !form_id.nil? && form_id > 0
      cur_form = Form.find_by_id(form_id)
    else
      cur_form = nil
    end
        
    # Create the data structures needed to store the data:
    # form_tbl_cols is an array that contains one definition object
    #               for each column in the forms table
    # form_tbl_row  is a hash set up to receive the data for one
    #               form object to be stored in the forms table.
    #               The key is the column name (form_name, form_title, etc.)
    form_tbl_cols = Form.columns
    form_tbl_row  = Hash.new
    ror_types = Hash.new
    form_tbl_cols.each do |fc|
      form_tbl_row[fc.name] = fc.default      
      # overwrite the table-defined default with the form defined
      # default - hoping that nothing will blow up.  :)
      if !fb_defs[fc.name].nil?
        form_tbl_row[fc.name] = fb_defs[fc.name]
      end
      ror_types[fc.name] = fc.type
    end
    
    # Get and store the data for the top-level table, which is the 
    # forms table.    
    form_id = store_form_data(fe, form_tbl_row, ror_types, cur_form, fb_fields)
    
    # Only go on if we got a valid form_id back for the forms table store
    if !form_id.nil?
    
      # fd_tbl_cols is an array that contains one definition object
      #             for each column in the field_descriptions table
      # fd_tbl_row  is a hash set up to receive the data for one full
      #             field object to be stored in the field descriptions table.
      #             The key is the field name (display_name, target_field, etc.)
      #             This is initially loaded with the default values for the
      #             fields - first with any defined at the database table 
      #             level and then with any defined for the form builder
      #             form (and if they clash, we'll crash.  oh goody).
      #             This is cloned each time to receive the contents
      #             from the form, so the defaults are always there to 
      #             compare against to determine if we're looking at an
      #             empty line.      
      fd_tbl_cols = FieldDescription.columns
      fd_tbl_row = Hash.new
      fd_tbl_cols.each do |tc|
        fd_tbl_row[tc.name] = tc.default
        # again, use the form-defined default if there is one
        if !fb_defs[tc.name].nil?
          fd_tbl_row[tc.name] = fb_defs[tc.name]
        end
        ror_types[tc.name] = tc.type
        log_this('fd_tbl_row[' + tc.name + '] just received default ' +
                    'value [' + tc.default.to_s + ']')
        log_this('ror_types[' + tc.name + '] just received column type ' +
                    tc.type.to_s)
      end
      fd_tbl_row['form_id'] = form_id
      ror_types['form_id'] = 'integer'  # need this?
      
      if !cur_form.nil?
        cur_fields = FieldDescription.where(form_id: form_id).order('id').to_a
      else
        cur_fields = nil
      end
      
      store_field_descriptions(fe, fd_tbl_row, ror_types, cur_fields, fb_fields)

      
      if (!save_and_close.nil? && save_and_close == '1')
        redirect_to('/form/index')
      end
    else
      @page_errors << "Alert!  We are stuck!<br>" +
                      "Trouble storing form-level data.<br>" +
                      "Oops!  None specified.<br>"
    end # if we do/don't have a form to save

  end # save_form
  


  ###################################################################
  
  # SUPPORTING FUNCTIONS:
  
  # A.  Support for loading data from an existing form:
  
  # This creates one data hash for one field definition, where the 
  # the data is loaded from the fld_data object passed in.
  # in.
  #
  # Parameters:
  # * hdr_fld_def - field definition for the form builder
  #   group header field.  Used to get the form fields that 
  #   need to be filled in with the definition data from fld_data
  # * fld_data - definition data for the field to be loaded
  # * excludes - the exclusions table for the current field type
  # * ctd_params - a hash of this field definition's control_type_detail
  #   parameters
  #
  # Returns: the hash for the group and the uns_msgs buffer
  #
  def load_field_def(hdr_fld_def, fld_data, excludes, ctd_params)

    grp_hash = Hash.new
    if excludes.nil?
      log_this 'excludes NIL for header field  = ' +
               hdr_fld_def.target_field 
    end  

    # Check to see if the field type is currently supported.
    # If not, we will only obtain the first-line fields to show
    # along with a "not supported" message
    unsupported_ft = fld_data.predefined_field.form_builder.to_s == 'false' 
             
    # If it's supported, initialize a flag that indicates whether
    # or not the value for the field comes from text_list table.
    # See below.
    from_text_list = false

    # Process each form builder column for this field definition,
    # obtaining the data for the column from the target data.
    log_this 'in load_field_def, processing subfields of ' +
             hdr_fld_def.target_field
    hdr_fld_def.subFields.each { |gdef|  
      log_this 'processing subfield ' + gdef.target_field

      # Fill fields that are not display_only
      if (!gdef.predefined_field.display_only)
        log_this '  processing as not display_only'
        
        # Check to see if we're looking for the id field.  The
        # target_field value doesn't match the column name here
        # because we already have an id field on the form - which
        # is the form id.        
        if (gdef.target_field == 'field_id')
          grp_hash[gdef.target_field] = fld_data.id
          log_this ' wrote ' + fld_data.id.to_s + ' to grp_hash[' +
                   gdef.target_field + ']'
                   
        # Form builder target_field names with the 'ctd_' preface
        # are ones that contain parameters to be written to the
        # control_type_detail column in the target form.  
        elsif (gdef.target_field[0,4] == 'ctd_' && !unsupported_ft)
        
          # If the current one is NOT excluded for the current field
          # type, call load_ctd_field to process it.                
          if excludes.nil? || !excludes.include?(gdef.target_field)
            grp_hash, ctd_params = load_ctd_field(gdef.target_field, 
                                                  grp_hash, ctd_params)
                     
          # Else the parameter's excluded for this field type.  Just 
          # remove it from the parameters hash so it won't show up as
          # an unsupported parameter.
          else
            ctd_params.delete(gdef.target_field)
          end
                      
        # Form builder target_field names with the 'd_' preface are
        # used to specify a default value for the field being defined.
        # (And '_default_value' is appended to the target_field names.)
        # Because different field types use different types of input 
        # fields, we have one of each type for default value entry.
        # The appropriate type gets the value from the target_data and
        # the rest of the 'd_' fields for this field definition are left
        # empty.  Again, block for unsupported field types        
        elsif (gdef.target_field[0,2] == 'd_' && !unsupported_ft)
          if (fld_data.control_type == 'search_field' &&
              gdef.target_field == 'd_text_field_default_value')
            grp_hash[gdef.target_field] = fld_data.default_value
            log_this ' wrote ' + fld_data.default_value.to_s + 
                     ' to grp_hash[' + gdef.target_field + ']'
                     
          # compare the control type just to that part of the 
          # target_field name that's not the preceding _d or the
          # trailing _default_val          
          elsif (fld_data.control_type == gdef.target_field[2..-15])
            grp_hash[gdef.target_field] = fld_data.default_value
            log_this ' wrote ' + fld_data.default_value.to_s + 
                     ' to grp_hash[' + gdef.target_field + ']'          
          end
          
        # No data is stored for the form builder group_header_name
        # field.  Instead, an id is stored.  If we are trying to fill
        # the group_header_name field, get the display_name value of
        # the fld_data row with the group_header_id specified.  If
        # no group_header_id is specified for this field definition,
        # don't bother.  Again, block for unsupported field types.        
        elsif (gdef.target_field == 'group_header_name' && !unsupported_ft)
          if (!fld_data.group_header_id.nil? && fld_data.group_header_id > 0)
            grp_hash['group_header_name'] = 
              FieldDescription.find_by_id(fld_data.group_header_id).display_name
            log_this ' wrote   #{grp_hash[\'group_header_name\']}
                      to grp_hash[\'group_header_name\']'               
          end
          
        # Same thing for the group_header_name_C field.
        elsif (gdef.target_field == 'group_header_name_C' && 
               !unsupported_ft)
          if (!fld_data.group_header_id.nil? && fld_data.group_header_id > 0)
            grp_hash['group_header_name_C'] = 
              FieldDescription.find_by_id(fld_data.group_header_id).target_field
            log_this ' wrote ' + grp_hash['group_header_name_C'] + 
                     ' to grp_hash[\'group_header_name_C\']'               
          end
                   
        # Same thing with the regex_validator field.  If one was 
        # specified for this field definition, we only have the id.
        # Get the description from the regex_validators table - if
        # we have an id.  And not an unsupported_ft.        
        elsif (gdef.target_field == 'regex_validator' && !unsupported_ft)
          if (!fld_data.regex_validator_id.nil?  && 
              fld_data.regex_validator_id > 0)
            grp_hash['regex_validator'] = fld_data.regex_validator.description
            log_this ' wrote ' + grp_hash['regex_validator'].to_s + 
                     ' to grp_hash[\'regex_validator\']'                
          end
          
        # If this is the 'required' field, translate the boolean
        # that is stored in the database to the appropriate list
        # option.  This should be generalized, but right now I'm
        # not sure of the best way to do it.  Feel free to fix
        # this.  lm, 8/12/08  (right now that's the only boolean
        # column in the field_descriptions table).  You know the 
        # unsupported field type drill.       
        elsif (gdef.target_field == 'required' && !unsupported_ft)
          if (fld_data.required == true)
            grp_hash['required'] = 'Yes'
          else
            grp_hash['required'] = 'No'
          end
          log_this ' wrote ' + grp_hash['required'] + 
                   ' to grp_hash[required]'
        
        # Else if this is the supported_ft flag, set it based on
        # the value of unsupported_ft
        elsif (gdef.target_field == 'supported_ft')
          grp_hash['supported_ft'] = (!unsupported_ft).to_s
          log_this('supported_ft set to ' + grp_hash['supported_ft'].to_s)
                    
        # Otherwise assume we're at just a normal field with no special
        # processing requirements.  (Wow - took a lot to get here)
        # We still need to check the exclusions table to make sure 
        # the field's not excluded for this type.  (Some excluded fields are
        # NOT control_type_detail parameters).
        else
          if excludes.nil? || !excludes.include?(gdef.target_field)       
            grp_hash[gdef.target_field] = fld_data.send(gdef.target_field)
            log_this ' wrote ' + grp_hash[gdef.target_field].to_s + 
                     ' to grp_hash[' + gdef.target_field + ']' 
          end
        end  
      # If this is the not_yet_msg field, it needs to be filled with
      # an "unsupported field_type message where appropriate.
      elsif (gdef.target_field == 'not_yet_msg')
        log_this('are at the not_yet_msg field; unsupported_ft = ' +
                 unsupported_ft.to_s)
        if unsupported_ft
          grp_hash['not_yet_msg'] = 
            '<br><center>You have jumped ahead!<br>' +
            'Field type <b>' + fld_data.field_type + 
            '</b> is not supported<br>' +
            '- yet.  No access here.</center>'
        end

      # And, finally, if this subfield is a group header (which is a
      # display-only field) for a nested group set up an array for the
      # group and call this method recursively to get a hash for each 
      # field in the group from the fld_data passed in.  For unsupported
      # field types, only load the "not yet supported" group.
      elsif gdef.control_type == 'group_hdr'
        if ((gdef.target_field == 'not_yet' && unsupported_ft) ||
            !unsupported_ft)
          log_this('sending subfield to load_field_def')
          new_hash, ctd_params = load_field_def(gdef, fld_data, 
                                                excludes, ctd_params)
          grp_hash[gdef.target_field] = new_hash      
          log_this('just loaded group for group_hdr ' + gdef.target_field)
        end
      end # if is not display-only, is the not_yet_msg, or is a group header

      # If a form field value comes from a list in the text_lists, go get the
      # display value for it.  What gets written to the database column is the
      # item_name value, but what gets displayed to the form designer is the
      # item_text value.  And they're not always the same value.  Do this as 
      # long as the field type is supported and it's not one that is a 
      # special case.
    
      if !unsupported_ft && !gdef.control_type_detail.nil? &&
         gdef.target_field != 'ctd_edit' && gdef.target_field != 'ctd_edit_C' &&
         gdef.target_field != 'ctd_class_no_group_hdr' &&
         gdef.target_field != 'required' &&
         gdef.control_type_detail.include?('search_table=>text_lists') &&
         !excludes.nil? && !excludes.include?(gdef.target_field)
        if gdef.control_type_detail.include?('match_list_value=>true')
          grp_hash[gdef.target_field] = 
              get_text_list_val(gdef, true, grp_hash[gdef.target_field]) 
        else
          list_val = 
              get_text_list_val(gdef, true, grp_hash[gdef.target_field]) 
          if !list_val.nil?
            grp_hash[gdef.target_field] = list_val
          end
        end # if the value must come from the list or may vary
      end      

      
    } # end processing for each form builder field to be filled in  
      
    return grp_hash, ctd_params
    
  end # load_field_def
  
  #
  # Loads data to a ctd_ form field.  These fields get data from the
  # control_type_detail column of the field description.  This performs
  # any special acquisition and parsing of the data from the 
  # control_type_detail column before it's written to the ctd_ form field.
  #
  # Parameters:
  # * targ_field - name of the ctd_ form field to receive the data
  # * grp_hash - the hash that is being built with the form data
  # * ctd_params - a hash of this field definition's control_type_detail
  #   parameters
  #
  # Returns:  the updated hash and the ctd_params hash
  #
  def load_ctd_field(targ_field, grp_hash, ctd_params)
    
    log_this('in load_ctd_field, looking to fill form field ' + targ_field)
    
    # if we're trying to fill the list name for a list field, where we get
    # the list name depends on the list.  Oh goody.  Go get the right name
    # and, while we're at it, the id for the list_details row for the 
    # list/search table.  Start with the search_table spec in the field
    # definition's control_type_detail field.    
    if (targ_field == 'ctd_search_tbl_name')
      search_table = ctd_params.delete('search_table')

      if !search_table.nil?
        list = ListDetail.find_by_id(ctd_params['list_details_id'])
        
        if list.nil?
          # There is code in the field_descriptions validation method to
          # prevent this from happening, but just in case something
          # gets slipped by it
          grp_hash['ctd_search_tbl_name'] = search_table
        else
          grp_hash['ctd_search_tbl_name'] = list.display_name
        end
      end
      
    # Otherwise if we're trying to fill the ctd_edit form field, get the
    # text that corresponds to the code currently in that parameter, 
    # and transfer the code to the _C field.
    elsif ((targ_field == 'ctd_edit' || targ_field == 'ctd_edit_C') &&
           ctd_params.include?('edit'))
      edit_list = TextList.find_by_list_name('editable_choices')
      edit_item = edit_list.text_list_items.find_by_code(ctd_params['edit'])
      choice = edit_item.item_text
      grp_hash['ctd_edit'] = choice
      grp_hash['ctd_edit_C'] = ctd_params.delete('edit') 
      
    # If we're trying to fill a class field, process for the ones we 
    # currently support
    elsif (targ_field[0,9] == 'ctd_class')

      cls_ary = ctd_params.delete('class')
      log_this('looking for class, found ' + cls_ary.to_s)
      
      cls_name = targ_field[10..-1]
      if cls_name == 'no_group_hdr'
        if !cls_ary.nil? && cls_ary.include?(cls_name)
          grp_hash[targ_field] = 'NO'
        else
          grp_hash[targ_field] = 'YES'
        end
      else
        if !cls_ary.nil?        
          cls_name = 'hidden_field' if cls_name == 'hidden'          
          if cls_ary.include?(cls_name)
            grp_hash[targ_field] = cls_name 
          end
        end # if we have a class parameter
      end # if we are/aren't processing the ctd_class_no_group_hdr form field
      
      
    # Otherwise the ctd_ form field name should match up to the
    # control_type_detail parameter (without the ctd_ prefix)
    
    else
      grp_hash[targ_field] = ctd_params.delete(targ_field[4..-1])
      log_this('looking for ' + targ_field[4..-1])
      log_this('found ' + grp_hash[targ_field].to_s)
    end
    
    # If the parameter written is an array or hash object, format the value
    # into a string
    
    if grp_hash[targ_field].instance_of?(Array)
      ary_val = grp_hash[targ_field]
      grp_hash[targ_field] = ary_val.join(', ')
      
    elsif grp_hash[targ_field].instance_of?(Hash)
      hstr = String.new
      grp_hash[targ_field].each do |key, value|
        hstr += key + '=>' + value + ','
      end
      grp_hash[targ_field] = hstr.chomp(',')
    end

    return grp_hash, ctd_params
    
  end # load_ctd_field        
               
  # This method gets the value to be displayed for a text_list_item
  # from the item_text value.  This is used for form fields that 
  # allow the user to choose an option from a list, such as the 
  # options for the group header field open/close parameter or
  # the editable field parameter.  The item_text value from 
  # text_list_items is displayed, but the item_name value is stored
  # to the database.  So when we load the data to display to the 
  # form designer, we need to convert what's in the database (item_name)
  # to what is to be displayed (item_text).
  #
  # This does check to see if the value passed in (db_val) is null.
  # If it is, no check is made and the value returned is null. 
  #
  # A null value is also returned if a db_val is specified but it's not
  # found in the list.  So if the field allows non-matching values,
  # check the return before assigning it to the field!
  #
  # Parameters:
  # * fd - the field description for the form field that uses the
  #   list (ctd_open, ctd_edit, etc)
  # * db_val - the value that has been stored in the database for the
  #   form field
  # 
  # Returns:  the display value (item_text)
  #
  def get_text_list_val(fd, display, lookup_val)
    ret_val = nil
    if !lookup_val.nil? && lookup_val != ''
      fd_ctd = fd.controls_hash
      if !fd_ctd.nil? && !fd_ctd['search_table'].nil? &&
         fd_ctd['search_table'] == 'text_lists'
        fld_list = TextList.find_by_list_name(fd_ctd['list_name'])
        if display
          list_item = fld_list.text_list_items.find_by_item_name(lookup_val)
          if !list_item.nil?
            ret_val = list_item.item_text
          end    
        else
          list_item = fld_list.text_list_items.find_by_item_text(lookup_val)
          if !list_item.nil?
            ret_val = list_item.item_name
          end    
        end
      end
    end # if the db value passed in is not null
    return ret_val
  end # get_text_list_val
  
  
  # This method obtains the data for the form table and creates a new
  # Form object for it in the database.
  #
  # Parameters:
  # * fe - the form object returned from the form; hash that contains
  #   form field name => value pairs for each form field (except checkboxes
  #   that weren't checked)
  # * form_tbl_row - a hash containing one element for each column in the
  #   forms table.  Key is the column name.
  # * ror_types - the corresponding RubyOnRails datatype for each column.
  #   Key is, again, the column name.
  # * cur_form - the current form as it exists in the database.  If we
  #   are creating a new form, this will be nil.
  #
  # returns the id of the Form object stored in the database
  #
  def store_form_data(fe, form_tbl_row, ror_types, cur_form, fb_fields)
  
    not_on_form = Hash.new
    new_tbl_row = get_one_data_row(fe, fb_fields, form_tbl_row.clone, 
                                   ror_types, nil, not_on_form)
    ret_id = nil
    
    # Check to make sure data has been entered for the form.  If all
    # form object fields returned are empty or just have the default
    # value defined for the field, the form has not been defined.
    # Don't store anything.  (If the user was working on an existing
    # form and didn't make any changes to the form-level data, the
    # form-level data will still be saved and we'll get the id back).    
    if new_tbl_row != form_tbl_row
      log_this('getting ready to store form, with form_name = ' +
               new_tbl_row['form_name'])
      if cur_form.nil?    
        saved = Form.create!(new_tbl_row)
      else
      
        # For any columns that are in the database but not accessed by
        # the form, remove the columns from new_tbl_row.  This keeps the
        # database column from being updated with a null value that will
        # be in the form data for that column (since the form user can't
        # access the form).
        not_on_form.each_key do |col_name|
          log_this('looking for column ' + col_name + ' in new_tbl_row')
          if new_tbl_row.has_key?(col_name)
            log_this('removing column ' + col_name + ' from new_tbl_row')
            new_tbl_row.delete(col_name)
          end
        end
        
        # Now update the row
        saved = Form.update(cur_form.id, new_tbl_row)
      end
      ret_id = saved.id
    end
    return ret_id
  end # store_form_data
  
  
  # This method obtains the data for the field_descriptions table and 
  # creates a new FieldDescription object in the database for each
  # field description defined on the form.
  #
  # Parameters:
  # * fe - the form object returned from the form; hash that contains
  #   form field name => value pairs for each form field (except checkboxes
  #   that weren't checked)
  # * fd_tbl_row - a hash containing one element for each column in the
  #   field_descriptions table.  Key is the column name.  Includes
  #   default value for the field, if one was specified.
  # * ror_types - the corresponding RubyOnRails datatype for each column.
  #   Key is, again, the column name.
  # * cur_fields - an array of the the current fields as they exist in the
  #   database.  If we are creating a new form, this will be nil.
  #  
  def store_field_descriptions(fe, fd_tbl_row, ror_types, cur_fields, fb_fields)
    
    # Get the field descriptions data from the form
    all_fd_rows, fd_tbl_row = get_field_data(fe, fd_tbl_row, 
                                             ror_types, fb_fields)
        
    # Get the left over form fields, if any.  These are ones where 
    # there's a field on the form, but not one in the table that 
    # directly corresponds.    
    extra_form_data = get_extra_form_data(fe, fb_fields)
    
    # Get the hash list of form fields to exclude for the field type
    # chosen for the field.  Not all fields on the form apply to all
    # field types, and we don't want to store extra data for a definition
    # if it's not applicable to that field type.  (And because we have
    # default data for field definitions, there may be something in a
    # non-applicable field even if the form designer never saw it).    
    exclusions = FormBuilderMap.get_exclusions_hash(true)

    # Set up the headers and sub_fields lists that we need to assign
    # group header id values.  Actually used below as we store the
    # rows.
    
    headers = Hash.new
    sub_fields = Hash.new
    
    # Process each row to merge extra data in as well as perform
    # any conversions, derivations, and data inclusions necessary
    # for the various types of fields.
    
    suffix = 1
    all_fd_rows.each do |row|  
 
      # If this is a field with an unsupported field_type, bypass
      # it entirely.  We don't allow the user any access to it,
      # and aren't set up to store it properly.  So don't bother.
      # (It was allowed to go through the retrieval methods so that
      # the data for it was removed from the form (fe) object).
      
      pdf = PredefinedField.find_by_id(row['predefined_field_id'])
      log_this('in store_field_descriptions, processing row with ' +
               'target_field = ' + row['target_field'] +
               ' and pdf.form_builder = ' + pdf.form_builder.to_s)     
      
      if pdf.form_builder
    
        if row['target_field'].nil? || row['target_field'] == ''
          log_this('TARGET_FIELD MISSING for row with display_name = ' +
                   row['display_name'].to_s + '; field_type = ' +
                   row['field_type'].to_s + '; suffix = ' + suffix.to_s)
        end
    
        # Get the "extra" fields for this row.  Don't bother if
        # the field is one that was added programmatically - any
        # "extra" we pick up would be for a blank line.
        # REVISIT.  HUH?
        if (row['target_field'][-2,2] != '_C' &&
            row['target_field'][-3,3] != '_ET'&&
            row['target_field'][-4,4] != '_HL7')
          extra = extra_form_data[suffix]
          if extra.nil?
            log_this('no extra data found for field w/suffix = ' + suffix.to_s)
          end
        end
      
        # get the current field description from the database, if there is one
        this_field_def = nil
        log_this('in store_field_description; looking for existing desc; ' +
                 'row[id] = ' + row['id'].to_s)          
        if !cur_fields.nil? && !row['id'].nil?
          f = 0
          while f < cur_fields.length && cur_fields[f].id != row['id'].to_i
            log_this(' cur_fields[' + f.to_s + '].id, which = ' +
                     cur_fields[f].id.to_s + ', did NOT match')       
            f += 1
          end 
          if f < cur_fields.length
            log_this(' cur_fields[' + f.to_s + '].id, which = ' +
                     cur_fields[f].id.to_s + ', DID match')       
            this_field_def = cur_fields.delete_at(f)
          end
          # if we don't find a field definition for an existing form
          # we assume that we're working with a field newly defined
          # for the form.
        end      
      
        # Check to make sure we have a valid field description.
        # If it's an existing one it's valid.  If it's new, it must
        # have more than just default data in it.
        have_data = check_for_user_entry(this_field_def, row, 
                                         extra, fd_tbl_row)
        if have_data
                  
          # Remove any form fields on the exclusion list for the field type
          # specified        
          row, extra = do_excludes(exclusions, row, extra)
               
          # STILL A PROBLEM.
          #Check the display_order value.  If it's nil
          # PROCESSED.  No - can do here and just hold the last
          # number used.  what about ones added - we tack them
          # on at the end.
          # Build gaps into the display order so that we can insert
          # derived fields next to their base field.  Do this only
          # if we're building a new form.  We'll have to take our
          # chances once the updates begin - or figure out a better
          # way later.
          # CHANGE THIS.  RENUMBER EACH TIME.        
          #if cur_fields.nil? 
          #  if row['display_order'].nil?
          #    row['display_order'] = 0
          #  else
          #    row['display_order'] = row['display_order'].to_i * 5
          #  end
          #end
                       
          # Create the extra fields that go with certain control/field types
          # -- only for a new field.  (We assume they're there for old fields).
          # (Note that the conditions below should be mutually exclusive).
          if this_field_def.nil?
            if (row['control_type'] == 'calendar')      
              all_fd_rows = create_extra_calendar_fields(row, all_fd_rows)
            
            elsif (row['field_type'][0,3] == 'CNE' || 
                   row['field_type'][0,3] == 'CWE')
              all_fd_rows = create_extra_list_field(row, all_fd_rows)
            end
          end # creating new hidden fields for a new field definition
        
          # New or not, if this is a list field, go do all that processing
          # that's specific to list fields.       
          if (row['field_type'][0,3] == 'CNE' || 
              row['field_type'][0,3] == 'CWE')
            row, extra = process_list_field(row, extra, this_field_def)
          end

          # If we have an edit value for this field, substitute
          # the code for the value.  The parameter name for the
          # control_type_detail field needs to be edit, not edit_C,
          # so we do this little tap dance here.
        
          if !extra.nil? && !extra['ctd_edit'].nil?
            extra['ctd_edit'] = extra.delete('ctd_edit_C')
          end
        
          # Now process the remaining form fields for this field definition.
          # We are assuming that the form field names start with: 
          #  ctd_ for control type detail parameters;
          #  ctd_class_ for control type detail class parameters; or
          #  d_ for default value fields.
          # anything else we don't really know how to handle.
               
          if !extra.nil?
            row = process_extra_fields(extra, row)
          end 
          log_this('back from process_extra_fields, ' +
                   'group_header_name_C = ' +
                   row['group_header_name_C'].to_s)
                   
          ## field validations here ##################################
          ## required fields?
          ## 
        
          # OK, hopefully we've got all the data for this row.  
          # If it's a new form, or a new field for the form, store it.
          if this_field_def.nil?
          
            # If a group header was specified for this field, try to 
            # get the id from the headers hash.
            if !row['group_header_name_C'].nil? &&
               row['group_header_name_C'] != ''
              row['group_header_id'] = headers[row['group_header_name_C']]
              group_header_name_C = row['group_header_name_C']
              log_this('just stored group_header_id = ' +
                       row['group_header_id'].to_s +
                       ' for field with target_field = ' + 
                       row['target_field'] + 
                       ' and group_header_name_C = ' +
                       group_header_name_C)
                       
            # Else it's blank.  Make sure the athe group_header_id
            # field is set to null
            else
              row['group_header_id'] = nil
              group_header_name_C = nil
            end
            
            # We don't store the group_header_name_C.  Delete it, 
            # whether or not it has anything in it.
            row.delete('group_header_name_C')
              
            # Now save the row
            fd = FieldDescription.create!(row)
            
            # If a group header was specified for this field and we didn't
            # get an id for it from the header hash, put it on the 
            # sub_fields hash, which will be used later to go get the
            # group header id.  Evidently the group header field specified
            # hasn't been saved yet, so we'll have to get the id after it's
            # saved.
            if !group_header_name_C.nil? && row['group_header_id'].nil?
              if sub_fields[row['target_field']].nil?
                sub_fields[row['target_field']] = Array.new
              end
              sub_fields[row['target_field']] << fd.id  
              log_this('added id = ' + fd.id.to_s + ' to sub_fields for ' +
                        row['target_field'])
            end
            
            # If this field is a group header, put its id in the headers hash
            if row['field_type'] == 'Group Header'
              headers[row['target_field']] = fd.id
              log_this('added id = ' + fd.id.to_s + ' to headers for ' +
                       row['target_field'])
            end
            
          # Otherwise update the field_description object with any
          # changes and, if there were any changes, store it.
          else
            is_changed = false
            
            # If this row is a group header, put its id in the headers hash
            if row['field_type'] == 'Group Header'
              headers[row['target_field']] = row['id']
              log_this('added id = ' + row['id'].to_s + ' to headers for ' +
                       row['target_field'])              
            end
            
            # Process each field in the row
            row.each do |fld_name, value|
            
              # If we're processing the group_header_id field and there's no
              # group header target_field specified, wipe out whatever might 
              # be in the group_header_id field.            
              if fld_name == 'group_header_id' && 
                (row['group_header_name_C'].nil? || 
                 row['group_header_name_C'] == '')
                row['group_header_id'] = nil
              end
              
              # Processing for the group_header_name_C.
              if fld_name == 'group_header_name_C' 
              
                # Only bother doing something with it if it has a value AND
                # that value signals a change from what was there before.
                if (!value.nil? && value != '' &&
                    (row['group_header_id'].nil? ||
                     (!row['group_header_id'].nil? && 
                      row['group_header_id'] !=
                                    headers[row['group_header_name_C']])))
                  is_changed = true
                  
                  # If the id for the named group header is in the headers hash,
                  # use it here.  Otherwise put this on the sub_fields list to
                  # have the id for the group header filled in later.                  
                  if !headers[row['group_header_name_C']].nil?
                    row['group_header_id'] =
                                      headers[row['group_header_name_C']]
                    log_this('group_header_id set to ' +
                              headers[row['group_header_name_C']] +
                              ' for field with target_field = ' +
                              row['target_field'] + 
                              ' and group_header_name_C' +
                              ' = ' + row['group_header_name_C'])
                  else
                    if sub_fields[row['group_header_name_C']].nil?
                      sub_fields[row['group_header_name_C']] = Array.new
                    end
                    sub_fields[row['group_header_name_C']] << row['id']
                    log_this('added id = ' + row['id'].to_s + 
                             ' to sub_fields for ' + 
                             row['group_header_name_C'])
                      
                  end # if we could/couldn't get a group header id
                end # if a group header name was specified and it's a change          
                
              # If this is not the group_header_name field, process it normally.
              else
                the_fld = this_field_def.send(fld_name)
                log_this('for fld_name = ' + fld_name.to_s + ' the_fld = ' +
                          the_fld.to_s + ' (which should be the value for ' +
                          'the field from the table) and the form value = ' +
                          value.to_s)
                if the_fld != value
                  this_field_def.send((fld_name+'='), value)
                  is_changed = true
                end
              end # end if this is/isn't the group_header_name form field
            end # processing each field/column in the row
            
            # remove the group_header_name_C.  It's not stored.
            row.delete('group_header_name_C')
            
            if is_changed
              this_field_def.save!
              log_this('just saved field ' + this_field_def.target_field)
            else
              log_this('field definition for ' +  this_field_def.target_field +
                       ' was not changed; did not save')
            end
          end # if we're creating or updating
        end # if this row has any user-entered data(which should be the value for the field from the table
      end # if this is not an "unsupported field type" field
      suffix += 1      
    end # end processing each row
    
    # If we have anything in the sub_fields hash, we need to 
    # update those fields with the id of the group header 
    # they specified.  Didn't have it before - should have it
    # now.
    if !sub_fields.nil? && sub_fields.length > 0
      sub_fields.each do |gh_target_field, sub_array|
        sub_array.each do |sub_id|
          sub_fld = FieldDescription.find_by_id(sub_id)
          sub_fld.group_header_id = headers[gh_target_field]
          sub_fld.save!
          log_this('just assigned group_header_id = ' +
                   sub_fld.group_header_id.to_s + ' to field with ' +
                   'target_field = ' + sub_fld.target_field)
        end # do for each subfield waiting
      end # do for each group header that has one or more subfields waiting
    end # if we have fields waiting for a group_header_id value
    
    # if we have any field descriptions left over from the table - ?
    #  means weren't updated.
    # if we have any rows left over from the form - ?
    #  means the code's not right.
    
    # so how do we know if someone deleted a row?  They can't.

  end # store_field_descriptions
  
  
  # This method gets the form data for the field descriptions and writes
  # it to an array of arrays.  The first level field suffixes are used
  # as an index to the array, i.e. the field description with the suffix
  # starting with _1 is written to array element 1; the field description
  # with the suffix starting with _2 is written to array element 2; etc.
  # The data written here includes ONLY the form fields where the 
  # target_field name of the form field description matches the target_field
  # name of the the field_descriptions table row.  No "extra" fields are
  # included here.
  #
  # Parameters:
  # * fe - the form object returned from the form; hash that contains 
  #   form field name => value pairs for each form field (except check boxes
  #   that were not checked)
  # * fd_tbl_row - a hash containing one element for each column in the
  #   field_descriptions table.  Key is the column name.  This may be 
  #   updated during processing, by the removal of any table columns that
  #   are not accessible via the form.  This keeps the table columns of an
  #   existing record from being updated with a null value.
  # * ror_types - the corresponding RubyOnRails datatype for each column.
  #   Key is, again, the column name.
  #
  # Returns:  the array of field descriptions and the updated fd_tbl_row
  #
  def get_field_data(fe, fd_tbl_row, ror_types, fb_fields)
  
    have_data = true
    cur_suffix = 0
    all_fd_rows = Array.new
    not_on_form = Hash.new
    
    # Get the data for one field description at a time, and load it
    # into the all_fd_rows array.  We clone the fd_tbl_row hash each time
    # and fill in the fields in the hash.  This will include only fields
    # where the target_field name of the form field matches the target_field
    # name of the field_descriptions table.    
    while have_data
      suffix = '_' + (cur_suffix + 1).to_s
      all_fd_rows[cur_suffix] = get_one_data_row(fe, fb_fields,
                                                 fd_tbl_row.clone, 
                                                 ror_types, suffix,
                                                 not_on_form)
      if (!all_fd_rows[cur_suffix].nil?)      
       
        # For any columns that are in the database but not accessed by
        # the form, remove the columns from both all_fd_rows[cur_suffix] 
        # AND fd_tbl_row.  This keeps the database column from being updated
        # with a null value that will be in the form data for that column 
        # (since the form user can't access the form).
        if (!not_on_form.nil?)
          not_on_form.each_key do |col_name|
            log_this('looking for column ' + col_name + ' in all_fd_rows[' +
                     cur_suffix.to_s + ']')
            if all_fd_rows[cur_suffix].has_key?(col_name)
              log_this('removing column ' + col_name + ' from all_fd_rows[' +
                        cur_suffix.to_s + '] AND from fd_tbl_row')
              all_fd_rows[cur_suffix].delete(col_name)
              fd_tbl_row.delete(col_name)
            end
          end 
          not_on_form = nil 
        end # if not_on_form has columns to process   
        
        log_this('have fd data for suffix = _' + (cur_suffix + 1).to_s)
        log_this('all_fd_rows.length = ' + all_fd_rows.length.to_s)
        cur_suffix += 1
         
      else
        have_data = false
        all_fd_rows.delete_at(cur_suffix)
        log_this('deleted all_fd_rows(' + cur_suffix.to_s + ')')
        log_this('all_fd_rows.length = ' + all_fd_rows.length.to_s)        
      end

    end # do while we have data
    log_this('all_fd_rows.length = ' + all_fd_rows.length.to_s) 
    return all_fd_rows, fd_tbl_row 
  end # get_field_data
  
  
  # This method obtains the data for one row of the indicated table.
  # It does check to see if the row contains any data, beyond the
  # default data defined for the row type.  If it doesn't, the return
  # is nil.
  #
  # Parameters:
  # * fe - the form object returned from the form; hash that contains
  #   form field name => value pairs for each form field (except checkboxes
  #   that weren't checked)
  # * row_hash - a hash containing one element for each column in the
  #   table.  Key is the column name.
  # * ror_types - the corresponding RubyOnRails datatype for each column.
  #   Key is, again, the column name.
  # * suffix - the current suffix, which is used to search for 
  #   field_description rows
  # * no_access_cols - optional parameter that, if passed in, should be an
  #   an empty hash to receive the names of columns that exist in the 
  #   database table but that are not accessible via the form.
  #
  # Returns: the row_hash, with values stored for the columns - if any
  # non-default data was found; otherwise nil
  #  
  def get_one_data_row(fe, fb_fields, row_hash, ror_types, 
                       suffix, no_access_cols=nil)
    have_data = false
    if (!suffix.nil?)
      log_this('in get_one_data_row, suffix = ' + suffix)
    else
      log_this('in get_one_data_row, suffix is nil')
    end

    # Look for data one column at a time
    row_hash.each_key {|key|

      # find the form field for the table column
      # - if we're looking for field descriptions, use 'field_id' for
      #   the name of the form field that corresponds to the id column
      #   in the table
      if key == 'id' && !suffix.nil?
        fkey = 'field_id'
      else
        fkey = key
      end
      log_this(' looking for form field = ' + fkey + '; data type = ' +
               ror_types[key].to_s)
            
      val = fe.delete(fkey + suffix.to_s)
      if val.nil? && !suffix.nil?
        comp_val = fkey + suffix
        flen = comp_val.length
        fe.keys.each { |skey|
          if val.nil? && skey[0,flen] == comp_val
            val = fe.delete(skey)
          end
        } # running through the fe hash
      end # if we didn't find the form field on the first try, and we
          # have a suffix.  No sense in doing this for top-level fields.
          
      # If we didn't find a value, it means there is no form field
      # for the table column.  If we have a no_access_cols hash, add
      # the column to the hash.  The exception is the form_id column.
      # Don't dump that one!
      if val.nil? && fkey != 'form_id'
        log_this( ' for form field = ' + fkey + ' found val = nil') 
        if (!no_access_cols.nil?)
          no_access_cols[fkey] = "NOT ON FORM"
        end
      
      elsif !val.nil?
        log_this(' for form field = ' + fkey + ' found val = ' + val.to_s)
        # if we found something, write it to the row_hash
        if val != ""       
          if !have_data
            have_data = (val != row_hash[key])
          end
          
          # Check to see if the value for this field comes from
          # a list in the text_lists/text_list_items tables.  If so,
          # what gets displayed (and written to the form field) is 
          # not what we want to store.  Replace the displayed value
          # with the value to be stored.
          if fb_fields[key] && 
             !fb_fields[key].control_type_detail.nil? && 
             fb_fields[key].control_type_detail.include?('search_table=>text_lists')
            list_val = get_text_list_val(fb_fields[key], false, val)
            if !list_val.nil?
              val = list_val
            end
          end
          if ror_types[key] == 'boolean'.to_sym
            log_this('BOOLEAN ALERT: about to translate val = ' + val)        
            val = ((val.downcase.include? "y") || 
                   (val.downcase.include? "t") || val == "1")
            log_this('BOOLEAN ALERT: val translated to ' + val.to_s)
          end
          row_hash[key] = val
          log_this('row_hash[' + key + '] set to ' + val.to_s)
        end
      end       
      val = nil 
    } # end processing each column for the table row
    if have_data
      return row_hash
    else
      return nil
    end
  end # get_one_data_row
  
  
  # This method extracts the rest of the data from the form object.
  # This will be data from form fields that don't correspond to 
  # fields in the field_descriptions table.
  #
  # The fe object will also include all data for form fields with
  # suffix '_0_xxx', because those are the fields for the first/model
  # row of the horizontal table containing the field definitions.
  # The user never sees or has access to that data, so it's not requested
  # by the get_field_data method.  So we clean up here.
  #
  # It builds a hash of that data, with the key being the initial suffix -
  # i.e., the first digit of a suffix.  So keys will be 1, 2, 3, 4 ...
  # instead of _1, _1_1, _1_2, _2, _3, _4, _4_1, etc.
  # The suffix is used to match the data up with the right 
  # field_description.
  #
  # extra_data is a hash with key = suffix number
  #     { 1 => {target_field name => value,
  #             target_field name => value, .. } ,
  #       2 => {target_field name => value, .. } ,
  #       ... }
  # 
  # Parameters:
  # * fe - the form object returned from the form
  #
  # Returns:  the extra_data hash
  #
  def get_extra_form_data(fe, fb_fields)
    extra_data = Hash.new
    log_this('in get_extra_form_data')
    
    # process each key/value pair left in the fe hash
    fe.keys.each do |fkey|
      val = fe.delete(fkey)
      log_this('  processing fe object w/key = ' + fkey + ', val = ' + val)
        
      ## no booleans right now in the "extra" data.  The
      ## control_type_detail string is just that - a string.
      ## And the other "extras" don't take a boolean.
      #if ###### determine if reading a boolean here
      #  val = (val.downcase.include? "y") || 
      #         (val.downcase.include? "t") || val == "1")
      #end
     
      name_ary = split_full_field_id(fkey, false)
      suffix_num = name_ary[2][1,name_ary[2].length - 1]
      next_underscore = suffix_num.index('_')
      if !next_underscore.nil?
        suffix_num = suffix_num[0..next_underscore - 1].to_i
      else
        suffix_num = suffix_num.to_i
      end
          
      # don't do anything more with it if the suffix number
      # is zero.  We're just dumping that data
      if suffix_num > 0
      
        # Check to see if the value for this field comes from
        # a list in the text_lists/text_list_items tables.  If so,
        # what gets displayed (and written to the form field) is 
        # not what we want to store.  Replace the displayed value
        # with the value to be stored.  
        fname = name_ary[1]
        if !fb_fields[fname].nil? &&
           !fb_fields[fname].control_type_detail.nil? && 
           fb_fields[fname].control_type_detail['search_table']=='text_lists'
          list_val = get_text_list_val(fb_fields[fname], false, val)
          log_this('  found ' + list_val.to_s + ' for lookup val = ' + val.to_s)
          if !list_val.nil?
            val = list_val
          end
        end
        log_this('  writing val for key = ' + fkey + ' to hash for ' +
                 'suffix = ' + suffix_num.to_s)
        if !extra_data.has_key?(suffix_num)
          extra_data[suffix_num] = {name_ary[1]=>val}
        else
          extra_data[suffix_num] = 
                     extra_data[suffix_num].merge({name_ary[1]=>val})
        end
      end # if this isn't part of the model row
    end # removing the rest of the data from the fe object
    return extra_data
  end # get_extra_form_data
  
  
  # This method checks to make sure that this is not an empty
  # field description - i.e., that the user actually entered some
  # data.  If this is an update of an existing field, we assume that
  # there is some user-entered data.  (If the user has blanked out 
  # everything, the validation code should pick that up, since required 
  # fields will be blanked out.  So we don't worry about that here).
  #
  # If this is a newly entered field we check for a field type and
  # field name, and for another other data that doesn't match the
  # defaults defined for the fields.
  #
  # Parameters:
  # * this_field_def - the current field description from the database
  #   if there is one.
  # * row - the field data retrieved from the form for this field.
  # * extra - the extra data retrieved from the form for this field. 
  # * fd_tbl_row - a hash containing one element for each column in the
  #   field_descriptions table.  Key is the column name.  Includes default
  #   value for the field, if one was specified.  
  #
  # Returns:  boolean indicating whether or not we should consider this
  # a non-empty field description
  #
  def check_for_user_entry(this_field_def, row, extra, fd_tbl_row)
  
    # check to see if this is a new field definition.  If it has
    # something in this_field_def, it's not.  Assume we have data.
    
    have_data = !this_field_def.nil?
    
    # [the extra field_type qualifiers are to bypass a temporary
    # problem with the rules.  Should be removed when the problem is
    # fixed.  lm, 8/11/08]
    
    if !have_data && !row['field_type'].nil?  &&
       row['field_type'] != '1' && row['field_type'] != '2' &&
       row['field_type'] != '3' && row['field_type'] != '4' &&
       row['field_type'] != '5' && row['field_type'] != '6' &&
       row['field_type'] != '7' && row['field_type'] != '8' &&
       row['field_type'] != '9' && row['field_type'] != '10'
       
      # check each row until we find some non-default data
      
      did_log = false
      row.each { |fld_name, val|
        if !have_data && fld_name != 'field_type'
          if !fd_tbl_row[fld_name].nil?
            have_data = !val.nil? && val != "" && 
                        val != fd_tbl_row[fld_name]
          elsif !extra.nil? && !extra[fld_name].nil?
            have_data = !val.nil? && val != "" && val != extra[fld_name]
          else
            have_data = !val.nil? && val != ""
          end
        end # if we haven't found user-entered data yet
        if !did_log & have_data
          log_this('found data for row field ' + fld_name + 
                   ' with value = ' + val.to_s)
          if (!extra.nil?)
            log_this(' .. extra[' + fld_name + '] = ' + extra[fld_name].to_s)
          end
          log_this(' .. fd_tbl_row[' + fld_name + '] = ' +
                   fd_tbl_row[fld_name].to_s)
          did_log = true
        end
      } # do for each field in the row
    end # if this is a new field definition
    return have_data
  end # check_for_user_entry
  

  # This method removes any form fields that don't apply to the field
  # type chosen for the current field description.  This is necessary
  # because default values may be defined for fields that don't apply.
  # If we don't get rid of the form fields here, they'll get written to
  # the database anyway.  So, for example, a list field could end up
  # with specifications for a checkbox in its control_type_details field.
  #
  # Excluded fields are removed from either the row or the extra data
  # objects, depending on where they appear.  (In other words, both are
  # checked).
  #
  # Parameters:
  # * exclusions - the hash containing the exclusions for each field type.
  # * row - the row of the field data from the form.
  # * extra - the extra fields data for the field. 
  #
  # Returns:  the row and extra data objects
  #
  def do_excludes(exclusions, row, extra)
  
    excludes = exclusions[row['field_type']]
    log_this('PROCESSING EXCLUDES FOR FIELD_TYPE = ' + row['field_type'].to_s)
    log_this('  exclusions for this type are:  ' + excludes.join(' '))
    log_this('  row keys=>values are: ')           
    row.each do |key, value|
      log_this('    ' + key.to_s + ' => ' + to_formatted_s(value))  
    end
    if !extra.nil?
      log_this('  extra keys are: ')
      extra.each do |key, value|
        log_this('    ' + key.to_s + ' => ' + to_formatted_s(value))
      end
    end        
    if !excludes.nil?
      excludes.each do |ex|
        if !row[ex].nil?
          row.delete(ex)
          log_this('  just deleted form field ' + ex) 
        end
        if !extra.nil? && !extra[ex].nil?
          extra.delete(ex)
          log_this('  just deleted extra field ' + ex)
        end
      end # do for each exclude
    end # if we have any exclusions for this field type
    
    return row, extra
  end # do_excludes
  
 
  # This method creates extra fields for a newly defined calendar
  # field.  Two fields are added for each calendar field defined:
  # an 'epoch value' (_ET) field and an _ HL7 field.
  # 
  # This should only be invoked for a new calendar field.  These
  # extra fields should already exist for existing calendar fields.
  #
  # The new fields are assigned display_order values that are 1 and
  # 2 up from the value of the base field.
  #
  # Parameters:
  # * row - the form data for the calendar field
  # * all_fd_rows - the array of field description rows
  #
  # Returns:  all_fd_rows, with the new field descriptions added at the end
  #
  def create_extra_calendar_fields(row, all_fd_rows)
  
    # Until we get the display_order sorted out, just use the same order value
    # for these.  They won't see the fields on the form and at least it will
    # keep them together.
    
    et = row.clone
    #et['display_order'] = et['display_order'].to_i + 1
    et['display_name'] = et['display_name'] + ' epoch value'
    et['target_field'] = et['target_field'] + '_ET'
    et['control_type'] = 'text_field'
    et['control_type_detail'] = 'class=>(hidden_field)'
    et['required'] = false
    et['help_text'] = nil
    et['default_value'] = nil
    et['field_type'] = 'NM - numeric'  
    all_fd_rows << et
          
    hl7 = row.clone
    #hl7['display_order'] = hl7['display_order'].to_i + 2
    hl7['display_name'] = hl7['display_name'] + ' HL7 value'
    hl7['target_field'] = hl7['target_field'] + '_HL7'
    hl7['control_type'] = 'text_field'
    hl7['control_type_detail'] = 'class=>(hidden_field)'
    hl7['required'] = false
    hl7['help_text'] = nil
    hl7['default_value'] = nil
    hl7['field_type'] = 'DT - date'        
    all_fd_rows << hl7
  
    return all_fd_rows  
  end # create_extra_calendar_fields
  
 
  # This method creates an extra field for a newly defined list
  # field (field type CNE or CWE).  The field added is the "code field",
  # which will receive the code for the value chosen for the list.
  # 
  # This should only be invoked for a new list field.  The code field
  # should already exist for existing list fields.
  #
  # The new field is assigned a display_order value that is 1 up from
  # the value of the base field.
  #
  # Parameters:
  # * row - the form data for the list field
  # * all_fd_rows - the array of field description rows
  #
  # Returns:  all_fd_rows, with the new field description added at the end
  #
  def create_extra_list_field(row, all_fd_rows)
  
    # Until we get the display_order sorted out, just use the same order value
    # for this.  They won't see the field on the form and at least it will
    # keep them together.
    
    log_this('in create_extra_list_field')
    log_this('field_type = ' + row['field_type'].to_s)
    cd = row.clone
    #cd['display_order'] = cd['display_order'].to_i + 1
    cd['display_name'] = cd['display_name'] + ' code'
    cd['target_field'] = cd['target_field'] + '_C'
    cd['control_type'] = 'text_field'
    cd['control_type_detail'] = 'class=>(hidden_field)'
    cd['required'] = false
    cd['help_text'] = nil
    cd['default_value'] = nil
    cd['field_type'] = 'ST - string data'  
    cd['predefined_field_id'] = 
      PredefinedField.find_by_field_type('ST - string data').id
    all_fd_rows << cd          
    
    return all_fd_rows
  end # create_extra_list_field
  
 
  # This method processes a list field description (field type CNE or CWE).
  #
  # Parameters:
  # * row - the data from the form that corresponds to fields in the table
  # * extra - the extra fields from the form
  # * this_field_def - the current field description from the database
  #   if there is one.
  #
  # Returns:  the row and extra data objects
  #
  def process_list_field(row, extra, this_field_def)
  
    # Don't do any list processing if the list_details_id is
    # missing.  Just remove the list parameters from the extra
    # hash.
    
    if extra['ctd_list_details_id'].nil? ||
       extra['ctd_list_details_id'] == ''
      not_used = extra.delete('ctd_search_tbl_name')
      not_used = extra.delete('ctd_fields_displayed')
      not_used = extra.delete('ctd_order')
      not_used = extra.delete('ctd_fields_searched')
      
    # Else we do have a list_details_id value. 
    else
    
      # Get the list specs from the list_details row and write
      # them to a hash so we can modify them if needed.            
      log_this("about to look for listDetail with name = " +
                extra.delete('ctd_search_tbl_name').to_s +
                " and id = " + extra['ctd_list_details_id'].to_s)
      lst_dets = ListDetail.find_by_id(extra['ctd_list_details_id'])
      list_controls =
          ListDetail.parse_hash_value(lst_dets.control_type_template)
      list_controls['list_details_id'] = extra.delete('ctd_list_details_id')
      log_this('controls for the list are: ')
      list_controls.each do |key, value|
        log_this('  ' + key.to_s + ' => ' + to_formatted_s(value))
      end
            
      # If the list chosen has more than one field to be displayed
      # the user will have been presented with choices.  Go get them.
      # Otherwise the user was not presented with choices, so we'll
      # just use the list controls from list_details.            
      if !extra['ctd_fields_displayed'].nil?
          
        # We assume that the fields_displayed and fields_searched parameters in
        # the template specify both fields*.  We also assume there's no order
        # parameter in the template.  *except in those cases where there are
        # additional fields in fields_searched.  For those, all fields are in
        # the fields_searched parameter.  Basically, the BOTH/ALL selection for
        # fields_displayed and fields_searched parameters is the default and we
        # can simply use what's in list_controls.  There's no default for the
        # order parameter, so if the form designer gets to specify it, we need
        # to parse it.              
        disp_choice = extra.delete('ctd_fields_displayed').chomp(ONLY_CONST)
        log_this('  ctd_fields_displayed specified as ' + disp_choice)
              
        # if the form designer specified BOTH for fields to be displayed, the
        # other choices were presented, and we need to parse for them too.
        if disp_choice == BOTH_CONST
              
          # only one field may be selected for the list order
          list_controls['order'] = '(' + 
                              extra.delete('ctd_order').chomp(ONLY_CONST) + ')'
          log_this('  list_controls["order"] just set to ' +
                   list_controls['order'])
                 
          # the search choice may contain multiple fields.  If it does, we need
          # to close up any blank spaces and replace the & before the final 
          # choice with a comma
          srch_choice = extra.delete('ctd_fields_searched').chomp(ONLY_CONST)
          log_this('srch_choice = ' + srch_choice)
          if srch_choice.include? ','
            split_choice = srch_choice.split(' ')
            log_this('split_choice = ' + split_choice.join('|'))
            split_choice.delete('&')
            log_this('split_choice = ' + split_choice.join('|'))
            split_choice.each do |s|
              s.chomp!(',')
            end
            srch_choice = split_choice.join(',')
            log_this('srch_choice = ' + srch_choice)
          end
              
          # If the user chose BOTH or ALL for fields searched,
          # use what we got from the list_details table, because
          # both, or all, fields are listed for fields_searched
          # in the list_details table.  Otherwise use what the
          # user specified.        
          if srch_choice != BOTH_CONST && srch_choice != ALL_CONST
            list_controls['fields_searched'] = '(' + srch_choice + ')'
            log_this('  list_controls["fields_searched"] just set to '+ 
                     list_controls['fields_searched'])
          end
        
        # Otherwise the form designer did not choose BOTH for display, and
        # thus the other choices are automatically what the user chose for 
        # fields_displayed
        else
          disp_choice = '(' + disp_choice + ')'
          list_controls['fields_displayed'] = disp_choice
          log_this('  list_controls["fields_displayed"] just set to ' +
                   list_controls['fields_displayed'])
          list_controls['fields_searched'] = disp_choice
          log_this('  list_controls["fields_searched"] just set to ' +
                   list_controls['fields_searched'])
          list_controls['order'] = disp_choice
          log_this('  list_controls["order"] just set to ' +
                   list_controls['order'])
          not_used = extra.delete('ctd_order')
          not_used = extra.delete('ctd_fields_searched')
        end
      end # if the list has more than one field to display
            
      # If there's a data_req_output clause, assume that a target ending with a 
      # _C is for the target field, and preface the _C with the target_field
      # name.
      if !list_controls['data_req_output'].nil?
        log_this('Processing data_req_output parameter; looking to ' +
                 'replace _C with target_field + _C')
        updated_hash = Hash.new
        list_controls['data_req_output'].each do |key, val|
          log_this(' looking at value = ' + val)
          if val == '_C'
            val = row['target_field'] + '_C'
          end
          updated_hash[key] = val
        end
        list_controls['data_req_output'] = updated_hash
      end
    
      # field type CNE = coded with no exceptions.    
      if row['field_type'][0,3] == 'CNE'
        list_controls['match_list_value'] = true
        log_this('  added match_list_value=>true to list controls')
      end    
    
      # If this is an existing field description, run through the parameters
      # in its control_type_detail field.  Check any that aren't there:
      # - if they're list-related parameters, don't do anything with them.  The
      #   user could have changed the source list to a type that doesn't use
      #   that particular parameter.  For example, if the user switches from
      #   a prefetched list to a search list, there will be a leftover prefetch
      #   parameter that we don't want transferred.
      # - any non-list parameters that are already in list_controls are
      #   added to it so they'll transfer to the updated row.
      # Then clear out control_type_detail in the row form data so it can be
      # rewritten.  (If the parameter's already there it means we got it from
      # the updated data - which takes precedence over what was in the existing
      # field description).    
      if !this_field_def.nil? 
        FieldDescription.parse_hash_value(row['control_type_detail']).each do
          |param, value|
          if list_controls[param].nil? &&
             !VARIABLE_LIST_PARAMS.include?(param)
            list_controls[param] = value
          end
        end # end do for each existing parameter
        row['control_type_detail'] = nil
      end

      # Now write the list controls to the control_type_detail field -
      # whether or not this is a new field
      if row['control_type_detail'].nil?
        row['control_type_detail'] = String.new
      end
      list_controls.each do |param, value|
        value = to_formatted_s(value)  
        log_this('  adding ' + param + '=>' + value + ', to ' +
                 row['control_type_detail'])
        row['control_type_detail'] << param + '=>' + value + ','
      end
      row['control_type_detail'].chomp!(',')
    end # if we have a list_details_id value
    
    return row, extra
  end # process_list_field
  
  
  # This method processes the "extra" fields that have not yet been been
  # (say, by the list processing, or other previous processing).  The "extra"
  # fields are the form fields that do not have a direct match in the 
  # field_descriptions table, either because they are stored, in some form, 
  # in the control_type_details field or the default value field, or because
  # we don't actually store the user's input for that field.  (For example, 
  # the user enters a regex validator by name, but we only store the ID).
  #
  # At the conclusion of this method the extra hash object should be empty.
  #
  # Parameters:
  # * extra - the hash object containing the extra form field data
  # * row - the hash object containing the data parsed so far for the
  #   current field definition and the one that will receive the
  #   (possibly parsed) extra data.
  #
  # Returns:  the updated row
  #  
  def process_extra_fields(extra, row)
  
    # create a hash of the current parameters in control_type_detail 
    # (if any)    
    if row['control_type_detail'].nil? || 
       row['control_type_detail'].length == 0
      ctd_hash = Hash.new
    else
      ctd_hash = FieldDescription.parse_hash_value(row['control_type_detail'])
    end
    row['control_type_detail'] = String.new
    
    # Process each "extra" field.  There should only be ones that are used by
    # the current field_type, since we called do_excludes before calling this.
    # If that changes, change this.    
    #Ruby 1.9.3 won't allow updating hash while iterating. Work around is to use
    #the keys list for iterating. -Frank 
    #extra.each do |key, value|
    extra.keys.each do |key|
      value = extra[key]
      # data for the control_type_detail column
      if key[0,4] == 'ctd_'
        key = key[4..(key.length - 1)]
        
        # handle any non-class parameters first (they're easier)
        if key[0,6] != 'class_'
          if (value.nil? || value == '')
            ctd_hash.delete(key)
            log_this('deleting ctd ' + key + ' parameter - no ' +
                     'value specified')
          else
            ctd_hash[key] = value
          end
          
        # now the class parameters.  more complicated
        else        
          if key == 'class_hidden' 
            if value == 'hidden_field'
              val_act = [['hidden_field', 'add']]
            else
              val_act = [['hidden_field', 'remove']]
            end
          elsif key == 'class_no_group_hdr'
            if value == 'NO'
              val_act = [['no_group_hdr', 'add']]
            else
              val_act = [['no_group_hdr', 'remove']]
            end
          else
            cls_key = key[6, key.length-6]
            if value == cls_key
              val_act = [[cls_key, 'add']]
            else
              val_act = [[cls_key, 'remove']]
            end
          end
          log_this('Processing class parameter. Key = ' + key +
                   '; value = ' + value.to_s)
          updated_hash = process_class_field(ctd_hash['class'], 
                                                  val_act)
          if (updated_hash.nil? || updated_hash.length == 0)
            ctd_hash.delete('class')
            log_this('ctd_hash["class"] removed')
          else
            ctd_hash['class'] = updated_hash
            log_this('ctd_hash["class"] set to ' +
                     to_formatted_s(ctd_hash['class']))
          end
        end
        
      # default data
      elsif key[0,2] == 'd_'
        log_this('checking control type = ' + row['control_type'].to_s + 
                 '; default key = ' + key + '; value = ' + value)
        if (row['control_type'] == key[2,row['control_type'].length] ||
            (row['control_type'] == 'search_field' &&
             key == 'd_text_field_default_value'))
          row['default_value'] = value
          log_this('just wrote ' + value.to_s + ' to the default ' +
                   'value field.')
        end
        
      # If this is the group_header_name field, check to see if
      # it's empty.  If so, make sure the group_header_name_C
      # is empty.  Then we just abandon it.
      elsif (key == 'group_header_name') 
        if value == '' || value.nil?
          # If we haven't processed the group_header_name_C
          # yet, set the value in the extra hash to nothing.  
          # Otherwise we've processed it, so blank out the value
          # in the row.
          if row['group_header_name_C'].nil?
            extra['group_header_name_C'] = ''
          else
            row['group_header_name_C'] = ''
          end
        end               
        
      # Although we don't store the group_header_name_C, we don't 
      # process it here.  We process it right before we store
      # the field_description row.  So for now, carry it in the
      # row array.
      elsif key == 'group_header_name_C' 
        # Check to see if the group_header_name in extra is blank.
        # If so, blank out the target field here.
        if !extra['group_header_name'].nil? &&
           extra['group_header_name'] == ''
          value = ''
        end
        log_this('adding row["group_header_name_C"] = ' + value + 
                 ' to row for ' + row['display_name'])
        row['group_header_name_C'] = value
        
      # We just abandon the regex_validator field value.  When the
      # user chooses a validator from the list, the id is placed
      # in the regex_validator_id column.  We don't store the name
      # itself - will just get it when we redisplay the form.
      # We also discard the group_header_name field, as we no longer
      # need that.
      elsif (key == 'regex_validator' || key == 'group_header_name') 
        ## Do nothing 
        
      # I give up.
      else
        @page_errors << "We know not how to<br>" + 
                        "process the form field with name<br>" + 
                        "<i>" + key + "</i>.  Do you?<br>"                     
      end  
    end # do for the extra data for this row
    
    # (Re)write the control_type_detail field
    if !ctd_hash.nil?
      ctd_hash.each do |param, value|
        log_this('  adding ' + param.to_s + '=>' + 
                 to_formatted_s(value) + ', to ' +
                 row['control_type_detail'].to_s)
        row['control_type_detail'] << param + '=>' + 
                                      to_formatted_s(value) + ','
      end
      row['control_type_detail'].chomp!(',')      
    end
    return row
  end # process_extra_fields
  
  
  # This method processes an "extra" field that is one of the class designation
  # fields, such as whether or not a field should be hidden (hidden_field).
  # It takes care of adding the class designation, if it's not already
  # there, if the designation should be added, and removing it, if it's there,
  # if it should be removed.
  # 
  # Parameters:
  # * cur_ctd_hash_val - the current value for the class designation (either nil
  #   for a new field or with the value previously stored for an existing field)
  # * val_act - an array of value/action pairs.  Usually this will be one
  #   pair, but this is set up to accept multiple pairs.  The value specifies
  #   the value to be written to or removed from the cur_ctd_hash_val and the
  #   action specifies whether to <b>add</b> it (if it's not already there) or
  #   <b>remove</b> it (if it's there).
  #
  # Returns: the updated cur_ctd_hash_val
  #
  def process_class_field(cur_ctd_hash_val, val_act)

    val_act.each do |va|
      if va[1] == 'add'
        if cur_ctd_hash_val.nil?
          cur_ctd_hash_val = Array.new
        end
        if !cur_ctd_hash_val.include?(va[0])
          cur_ctd_hash_val << va[0]
        end
      else
        if !cur_ctd_hash_val.nil? &&
           cur_ctd_hash_val.include?(va[0])
          cur_ctd_hash_val.delete(va[0])
        end
      end # if the value is to be added or removed
      
    end # do for each value/action pair
    
    return cur_ctd_hash_val
 
  end # process_class_field
  
  # This method creates a formatted string from an array, hash, or
  # regular string (in case you pass in something that you're not
  # sure is a string).
  #
  # The formatting is a tad more readable than the mushed-together 
  # version provided by ruby's to_s methods, and is useful for things
  # like writing arrays and hashes to fields in the database.  
  #
  # Note - I put this in because I kept having to do it in the rest of
  # the code.
  #
  # Parameters:
  # * str - the string to be formatted
  # * enclosures - a boolean indicating whether or not enclosing 
  #   characters should be included in the string returned.  Parentheses
  #   are used for arrays; curly braces for hashes; and nothing is used
  #   for strings.  This parameter is optional; the default is <b>true</b>.
  # * separator - a separator string to be used for arrays.  This parameter
  #   is optional; the default is ',' with no spaces.
  #
  # Returns: the formatted string
  #
  def to_formatted_s(str, enclosures=true, separator=',')
  
    new_str = String.new
    if str.instance_of?(Array)
      if enclosures
        new_str = '(' + str.join(separator) + ')'
      else
        new_str = str.join(separator)
      end
    elsif str.instance_of?(Hash)
      hstr = String.new
      str.each do |key, val|
        hstr += key + '=>' + val.to_s + ','
      end
      if enclosures
        new_str = '{' + hstr.chomp!(',') + '}'
      else
        new_str = hstr.chomp!(',')
      end
    else      
      new_str = str.to_s
    end
    return new_str
  end # to_formatted_s
  
  
  # This method logs an informational message, using logger.debug.
  # Before logging the message it calls to_formatted_s on the string,
  # using the parameter defaults.  It then writes the message to the
  # log, preceding it with FB_CNTR: so that form builder controller 
  # messages are a tad easier to find in the log.
  #
  # Parameters:
  # * log_msg the message to be written.
  #
  # Returns:  nothing, but does write the message to the log.
  #
  def log_this(log_msg)
    if false
      log_str = to_formatted_s(log_msg)
      logger.debug 'FB_CNTR:  ' + log_str
    end
  end # log_this
 
end # formbuilder_controller
