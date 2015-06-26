class DataClass < ActiveRecord::Base
  has_paper_trail
  validates_presence_of :item_code
  validates_presence_of :classification_id
  validates_uniqueness_of :sequence, :scope => :classification_id

  belongs_to :parent, :class_name => "Classification",
    :foreign_key => "classification_id"
end
