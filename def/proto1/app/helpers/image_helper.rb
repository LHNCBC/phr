#
# This module handles adding html for images based on parameters
# in fields_definition table for records with control_type="image"
#
# This does NOT check for a hidden_field class, as it assumes that
# images will not be used for hidden fields.  Update this if that's
# not the case.  lm, Jan 2008
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


module ImageHelper

  # Create HTML for an image configured as specified by field_description
  #
  # Parameters:
  # * some_field - the field to display (a FieldDescripion)
  # * some_form - the form instance (from the template)
  # * tag_attrs - attributes for the image tag
  # * fd_suffix - a suffix to be appended to field names - used only
  #               when building fields in a horizontal table
  #
  # HACK ALERT ... YUCK!!
  # THIS method only works for the medlineplus health topic image
  #
  def make_image_content(some_field,
                         some_form,
                         tag_attrs,
                         fd_suffix)
    # only if it is not a in-column-header-only image
    if (!some_field.in_hdr_only)
      # initialize options based on field_description parameters
      source_path = some_field.getParam('source' )
      alt_text    = some_field.getParam('alt' )
      on_click    = some_field.getParam('onclick' )
      on_click_0  = some_field.getParam('onclick_arg_0' )
      on_click_1  = some_field.getParam('onclick_arg_1' )
      on_click_2  = some_field.getParam('onclick_arg_2')
      id = make_form_field_id(some_field.target_field, fd_suffix)

      # Assemble the onclick instruction.  It may have from 0 to 3
      # parameters.
      on_click_action = on_click
      if !on_click_0.blank?
        on_click_action += "(" + on_click_0
        if !on_click_1.blank?
          on_click_action += ",\'" + on_click_1 + "\'"
          if !on_click_2.blank?
            on_click_action += ",\'" + on_click_2 + "\'"
          end
        end
        on_click_action += ")"
      end

      # use Rails AssetTagHelper to create HTML for image
      img_tag_attrs = merge_tag_attributes(tag_attrs,
                         {:align=>"left",
                          :id => id,
                          :alt => alt_text,
                          :onclick => on_click_action})
      if (source_path =~ /\/blank.gif\z/)
        # Don't use image_tag, to avoid getting a timestamp on the URL,
        # which would result in an extra load of the blank.gif (which is also
        # apparently loaded by Dojo).
        output = tag('image', img_tag_attrs.merge('src'=>source_path))
      else
        output = image_tag(source_path, img_tag_attrs)
      end
    # otherwise no image cell in table rows
    else
      output ='<span></span>'
    end
    output  # return html for image

  end # end make_image_content

end # ImageHelper module

