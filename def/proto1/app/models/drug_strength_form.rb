class DrugStrengthForm < ActiveRecord::Base
  belongs_to :drug_name_route
  
  # Returns an array of the amount strings for this drug (for the dose field)
  def amount_list
    rtn = []
    TextList.get_list_items(amount_list_name).each {|i| rtn<<i.item_text}
    return rtn
  end
end
