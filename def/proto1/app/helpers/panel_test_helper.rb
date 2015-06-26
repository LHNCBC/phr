#
# This module handles most of the panel test fields processing on the
# ruby/server side. 
#
module PanelTestHelper

  def timeline_div(someField,
                    someForm,
                    tagAttrs,
                    fd_suffix)
    div_id = make_form_field_id(someField.target_field)
    div_id += fd_suffix if fd_suffix

    output = "<div id='#{div_id}' class='panel_timeline_grp'></div>"

    return output

  end

  # used in panel flowsheet only
  def static_table(some_field,
                  some_form,
                  in_table,
                  tag_attrs,
                  fd_suffix)

    target = some_field.target_field
    target += fd_suffix if !fd_suffix.nil?
    # change target_field if it is within a loinc panel
    target = target_field_for_panel(target)




    # Create the input field, designating the target field for it.
    output = some_form.text_field(target.to_sym, tag_attrs)

    # Get the autocompleter parameters and merge them with any data_req
    # parameters.  Then feed them to the appropriate partial, sending the
    # output to the buffer that holds the javascript to be output to a
    # separate file (not directly on the page).
    id = make_form_field_id(target)

    sysform_name = retrieve_sysform_name(some_form)
    locals = prefetch_autocompleter_params(some_field, id, sysform_name)
    locals = locals.merge(data_req_params(some_field))

    column_num = some_field.getParam('col_num')
    
    # Construct an url for accessing the data list for the field via AJAX
    user_data_url = url_for({:controller=>'form',
                             :action=>'get_user_data_list_in_table'})
    locals[:user_data_url] = user_data_url
    locals[:fd_id] = some_field.id
    locals[:col_num] = column_num
    
    @form_field_js << render({:partial=>'form/panel_static_table.rhtml', :handlers=>[:erb],
                              :locals=>locals})

    # Return the output buffer, which contains the html for the actual
    # text input field.
    return output

  end
end # PanelTestHelper

