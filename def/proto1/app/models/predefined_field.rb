class PredefinedField < ActiveRecord::Base
  extend HasShortList
  has_many :field_descriptions
  has_many :db_field_descriptions
  has_and_belongs_to_many :comparison_operators

  cache_recs_for_fields 'id'

  def PredefinedField.getFieldTypeInfo(name)
    matches = PredefinedField.find_by_field_type(name)
    return matches      
  end

  def is_date_type
    ["DT - date", "DTM - date/time"].include? field_type
  end


  # This returns the list of comparison operators used for
  # the current field type.
  #
  # Returns: an array containing two elements.  The first element is
  # an array containing the operator display values.  The second element
  # is an array containing the corresponding comparison_operators ids.
  def comp_operators
    list_values = []
    list_codes = []
    comparison_operators.each do |op|
      list_values << op.display_value
      list_codes << op.id
    end
    return [list_values, list_codes]
  end # comp_operators
  

  # The name of the column in the table that should be matched against
  # the "pattern" argument of HasShortList.get_list_items.
  def self.pattern_col
    'field_type'
  end

  # Formats a value for the "String - Set" field type.
  #
  # Parameters:
  # * set_vals - the array of values that make up the set value.
  # * sort - true (default) if the values sould be sorted prior to putting
  #   then into the string format.
  #
  # Returns:  A string composed of the sorted values in set_vals delimited with
  # | characters, and surrounded by them.
  # If set_vals is empty, or nil, nil is returned.
  def self.make_set_value(set_vals, sort=true)
    rtn = nil
    if set_vals and !set_vals.empty?
      set_vals = set_vals.sort if sort
      rtn = SET_VAL_DELIM + set_vals.join(SET_VAL_DELIM) + SET_VAL_DELIM
    end
    return rtn
  end


  # Parses a value from a field of field type "String - Set" and returns
  # the individual values in an array.  An empty array is returned if there
  # are no values.
  #
  # Parameters:
  # * set_val - the string version of the set value as returned by
  #   make_set_value.
  def self.parse_set_value(set_val)
    (!set_val || set_val.blank?) ? [] : set_val.slice(1..-2).split(/\|/)
  end
end
