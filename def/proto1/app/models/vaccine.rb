class Vaccine < ActiveRecord::Base
  extend HasShortList

  # The name of the column in the table that should be matched against
  # the "pattern" argument of HasShortList.get_list_items.
  def self.pattern_col
    'name'
  end
end
