class ListDescription < ActiveRecord::Base
  extend HasShortList
  def validate 
    # Should have an item_master_table or a list_master_table
    if item_master_table.blank? && list_master_table.blank?
      errors[:base]="Missing item_master_table or list_master_table."
    end
  end
end
