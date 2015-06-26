class AnswerList < ActiveRecord::Base
  extend HasShortList

  has_many :list_answers, ->{order("sequence_num")}

  cache_recs_for_fields 'id'

  # Used by get_list_items to obtain the specified list items.
  #
  # Parameters:
  # * list_id - the answer_list id of the list.
  def self.get_named_list_items(list_id)
    list_id = list_id.to_i # will likely be a string
    ListAnswer.joins(:answer).where(answer_list_id: list_id)
  end


  # Returns the requested list items.  The return values will be instances
  # of a model class that will provide access to the fields of the list items.
  #
  # Parameters:
  # * name - the ID of the list, or nil if there is just one list
  #   for this model class.
  # * pattern - (optional) an SQL regex pattern to use in matching the item_text
  #   of the items from the list named by the name parameter
  # * ord - (optional) a list of fields by which the output should be
  #   ordered, normally as specified by the :order parameter in a field
  #   description's control_type_detail column
  # * conditions -  (optional) a condition, a list of conditions, or a hashmap
  #   of conditions to be added to the normal matching statement for rows
  #   to be included in the results from the list named by the name parameter.
  #   For example, if normally the rows are to be found using
  #   item_text REGEXP pattern, adding a condition would mean
  #   that the search would be based on condition-text AND
  #   item_text REGEXP pattern.  The :conditions parameter in
  #   the field description's control_type_detail column is
  #   usually where this is specified.
  def self.get_list_items(name, pattern=nil, ord=nil, cond=nil)
    # Override HasShortList's method to provide a default order on sequence_num
    ord = 'sequence_num' if !ord
    super(name, pattern, ord, cond)
  end


  # This method searches the table for a record matching the given field data
  # (input_fields) and then returns data for the given output_fields.  The
  # return value is a hash from the output_field names to the value(s) for
  # the record that was found.
  #
  # This is intended to be called after the user has selected an item from an
  # autocompleter, when the program then needs to go back for additional
  # data about the selected item, but could be used with any table.
  #
  # IF YOU CHANGE this - specifically the parameters - please test it for
  # ALL table classes.  The problem is that other tables use the version of
  # this in active_record_extensions.rb.  If you change the signature and
  # then the call to this, it could bomb on other classes.  THANKS.  lm, 2/2008
  #
  # Parameters:
  # * input_fields - a hash from field names (column names) for this table
  #   to values.  Together the entries in input_fields should specify a
  #   particular record in the table.
  # * output_fields - an array of field names specifying the data to be
  #   returned.  These field names can be method names defined in the model
  #   class rather than column in the actual database table.
  # * list_name - name of list/ or answer_list_id in this case
  def self.find_record_data(input_fields, output_fields, list_name)
    list_items = ListAnswer.join(:answer).where(input_fields)
    list_items.where(answer_list_id: list_name.to_i) if !list_name.blank?
    list_items.load

    rtn = {}
    output_fields.each {|of| rtn[of] = list_items[0].send(of)} if (list_items.size>0)
    return rtn
  end
end
