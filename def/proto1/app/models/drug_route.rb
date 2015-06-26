class DrugRoute < ActiveRecord::Base
  acts_as_tree
  extend HasShortList
end
