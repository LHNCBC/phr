class PredefinedExpression < ActiveRecord::Base
  extend HasShortList

  # TBD - the following method is DEPRECATED, and will be deleted soon.
  # Use get_list_items instead.  (See module HasShortList).
  # Returns values from the logical_expressions table for the specified field in
  # the table.
  #
  # Parameters:
  #   name - the name of the field whose values are to be displayed, passed
  #          in as a string
  #   limit - a boolean to control whether or not to limit number of items
  #           returned to MAX_AUTO_COMPLETION_SIZE (see environment.rb).
  #   match_exp - an expression to be used to determine which conditions
  #               should be included in the returned list.  This may be
  #               either a straight expression ("condition_name = hide") OR
  #               one that requires a value from the current form
  #               (field_type = fieldname.field_type)
  #   ord - (optional) a field or list of fields by which the output should
  #         be ordered, normally as specified by the :order parameter in a
  #         field description's control_type_detail column
  #   conditions -  (optional) a condition, or list of conditions, to be added
  #                 to the normal matching statement for rows to be included in
  #                 the results from the list named by the name parameter.
  #                 For example, if normally the rows are to be found using
  #                 a match_val expression, adding a condition would mean
  #                 that the search would be based on condition-text AND
  #                 the match_val expression.  The :conditions parameter in
  #                 the field description's control_type_detail column is
  #                 usually where this is specified.
  #
  # The return value will be a list (implemented as an array) of two lists
  # (also implemented as arrays).
  #  * The first list will be nil.  For some classes the first list is a
  #    list of codes.  We retain the return format here, even though we have
  #    no codes to return, to maintain consistency in this call.
  #  * The second list will be the list of text strings for the list items.
  #
  def self.getListOptions(name, limit, match_exp, ord=nil, cond=nil)

    name_array = Array.new
    if (!name.index('.').nil?)
      name_array = name.split('.')
    end
    rtn = [];
    matches = PredefinedExpression.all
    matches = matches.order(ord) if ord
    matches = matches.limit(MAX_AUTO_COMPLETION_SIZE) if limit
    matches = matches.where(cond) if cond
    matches = matches.where(match_exp) if match_exp

    if (name_array.length == 0)
      matches.each do |m|
        rtn.push(m.send(name))
      end
    else
      matches.each do |m|
        names = Array.new(name_array.length)
        name_array.each do |nm|
          names.push(m.send(nm))
        end
        rtn.push(names)
      end
    end

    return [nil, rtn]
  end # getListOptions

end
