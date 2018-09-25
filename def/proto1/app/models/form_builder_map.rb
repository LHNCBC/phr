class FormBuilderMap < ActiveRecord::Base

  # OBSOLETE - REPLACED BY get_hash
  # The form_builder_maps table contains flags indicating which field
  # option fields should be shown for which field types.  It's used to
  # control the display of the various fields based on the user's choice
  # of field type.
  
  # This method creates an html table that can be used to determine
  # which fields should be displayed for a field definition based
  # on the field type selected.  This is called when the FormBuilder
  # form is being created, and the the output is written to a hidden
  # table at the end of the form.  The table is then used by the
  # set_fb_fields javascript method to determine when to hide or 
  # display the form fields in question.
  #
  # Parameters: none
  # Returns:  the map in the form of an html table
  #
  def self.get_map  
    the_map = '<table id="fbFieldsMapTable">'
    map_rows = FormBuilderMap.all
    
    predef_fields = PredefinedField.where(form_builder: true)
    predef_fields.each do |pd|
      the_map += '<tr><td>' + pd.field_type + '</td>'
      mfld_name_sym = pd.fb_map_field.downcase.to_sym    
      map_rows.each do |mr|
        the_map += '<td>' + mr.field_name + '</td>'
        the_map += '<td>' + mr.send(mfld_name_sym).to_s + '</td>'
      end
      the_map += '</tr>'
    end
    the_map += '</table>'
    #logger.debug 'in form_builder_map - the_map = ' + the_map.to_s
    return the_map
  end # get_map

  
  # This method creates a hash that can be used to determine which
  # fields should be displayed for a field definition based on the
  # field type selected.  This is called when the FormBuilder form
  # is being created, and the the output is written to a hidden
  # hash at the end of the form.  The hash is then used by the
  # set_fb_fields javascript method to determine when to hide or 
  # display the form fields in question.
  #
  # Parameters: none
  # Returns:  the hash
  #
  def self.get_hash  
    the_map = Hash.new
    map_rows = FormBuilderMap.all
    
    predef_fields = PredefinedField.where(form_builder: true)
    predef_fields.each do |pd|
      the_map[pd.field_type] = Hash.new
      mfld_name_sym = pd.fb_map_field.downcase.to_sym  
      #logger.debug 'in form_builder_map.get_hash:'
      #logger.debug '  processing predefined field type = ' + pd.field_type      
      map_rows.each do |mr|
        the_map[pd.field_type][mr.field_name] = mr.send(mfld_name_sym)
      end
    end
    return the_map
  end # get_hash
  
 
  # This method creates a hash table that is used to indicate the
  # unchanging portion of the suffix for a field whose display setting
  # is dependent on the field type specified (i.e., the fields listed
  # in the form_builder_map table).
  #
  # The hash is built here, with the field name serving as the key and
  # a blank written for its value.  The suffix values are filled in
  # by the fields_group_helper module, while the fields are being 
  # built.
  #
  # A summary element is also placed in the hash, and is used to indicate
  # when the table has been populated.  This blocks overwriting of the
  # values on subsequent passes through the fields by the helper code.
  #
  # Because the fields managed by this table are all dependent on a field
  # type definition, they all appear within a field group.  So no attempt
  # is made to assign suffix values in any other helper code.
  #/
  def self.get_fields_hash
    the_hash = Hash.new
    the_hash['fields_hash_populated'] = false
    the_fields = FormBuilderMap.select(:field_name)
    logger.debug 'in form_builder_map.get_fields_hash:'
    the_fields.each do |fn|
      #logger.debug '  writing ' + fn.field_name + ' to hash'
      the_hash[fn.field_name] = ''
    end
    return the_hash
  end # get_fields_hash
  
  
  # This method creates a hash that is used to determine whether
  # or not to store various form field values for a field definition.
  # The determination is based on the field type chosen for the 
  # definition.  This is called when a FormBuilder form is being
  # saved.
  #
  # The structure of the hash is:
  # {field_type=>[array of form fields applicable for the type]}
  # 
  # The hash can be either an inclusion or an exclusion hash.  If
  # an inclusion hash is requested, the form fields in the array
  # for a field type are the fields to be included for that type.
  # An exclusion hash will contain form fields that to be 
  # excluded for the field type.
  #
  # Parameters:
  # * exclusion - optional boolean indicating whether or not this
  #   is a request for an exclusion hash.  Default is true.
  #
  # Returns:  the hash
  #  
  def self.get_exclusions_hash(exclusion=true)
  
    the_hash = Hash.new
    map_rows = FormBuilderMap.all
    list_type = !exclusion
    
    predef_fields = PredefinedField.where(form_builder: true)
    predef_fields.each do |pd|
      #logger.debug 'in form_builder_map.get_exclusions_hash:'
      #logger.debug '  processing predefined field type = ' + pd.field_type
      #logger.debug '  fb_map_field = ' + pd.fb_map_field.to_s
      applicable_form_fields = Array.new
      mfld_name_sym = pd.fb_map_field.downcase.to_sym    
      map_rows.each do |mr|
        if (mr.send(mfld_name_sym) == list_type)
          applicable_form_fields << mr.field_name
        end
      end
      the_hash[pd.field_type] = applicable_form_fields
    end
    return the_hash
  end # get_exclusions_hash
  
  
end # FormBuilderMap class
