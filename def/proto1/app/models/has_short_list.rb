# A module for model classes that has a short list that gets displayed
# to the user.

module HasShortList

  # The name of the column in the table that should be matched against
  # the "pattern" argument of get_list_items.  This must be overridden
  # by classes that extend this module (as self.pattern_col).
  def pattern_col
    raise 'HasShortList.pattern_col not implemented'
  end

  # Returns the requested list items.  The return values will be instances
  # of a model class that will provide access to the fields of the list items.
  #
  # Parameters:
  # * name - the name or ID of the list, or nil if there is just one list
  #   for this model class.
  # * pattern - not used (TBD - remove)
  # * ord - (optional) a list of fields (either an array or as a comma-delimited
  #   string) by which the output should be ordered, normally as specified by the
  #   :order parameter in a field description's control_type_detail column
  # * conditions -  (optional) a condition that can be passed into the .where
  #   method on an ActiveRecord Relation, and an array of such conditions.
  #   The :conditions parameter in the field description's control_type_detail column is
  #   usually where this is specified.
  def get_list_items(name=nil, pattern=nil, ord=nil, conditions=nil)
    # Models that implement this module just have one list, so name = nil.
    list_items = get_named_list_items(name)
    list_items = list_items.order(ord) if ord

    case conditions
    when Array
      conditions.each {|c| list_items = list_items.where(c)}
    else
      list_items = list_items.where(conditions)
    end

    return list_items.load
  end # getListOptions


  # Returns the named list items (as an unloaded relation), or all items
  # if there is just one list for this model class.  Classes that use
  # this module can override this method and then not have to override
  # the full get_list_items method.
  def get_named_list_items(name = nil)
    # By default, just return all the items.
    self.all
  end
end
