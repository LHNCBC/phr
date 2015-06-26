class TextList < ActiveRecord::Base
  has_many :text_list_items, -> {order("sequence_num")}, dependent: :destroy
  validates_uniqueness_of :list_name

  extend HasShortList

  # Returns the named list's items (as an unloaded ActiveRecord CollectionProxy), or
  # an empty relation if no name is provide.  (For this class, one
  # should be provided, but we are here overriding a more general method
  # from has_short_list.rb.
  def self.get_named_list_items(name = nil)
    TextList.where(list_name: name).take.text_list_items
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
  # * list_name - name of list
  def self.find_record_data(input_fields, output_fields, list_name)
    list = TextList.find_by_list_name(list_name) if !list_name.blank?
    list_items = TextListItem.where(input_fields)
    list_items = list_items.where(text_list_id: list.id) if list
    list_items.load

    rtn = {}
    output_fields.each {|of| rtn[of] = list_items[0].send(of)} if (list_items.size>0)
    return rtn
  end

  private

  def self.build_order_options(ord)
    order_list = ["sequence_num"]
    case ord.class.name
    when "String" then
      order_list.unshift(ord) unless ord.blank?
    when "Array" then
      order_list = ord + order_list unless ord.empty?
    when "NilClass" then
      # do nothing
    else
      raise "The input type is unknown."
    end
    order_list.join(", ")
  end
end
