# This is an application specific model class.  Avoid putting general framework
# code here.
class PhrImmunization < ActiveRecord::Base
  include TextListUserData
  extend TextListUserData::ClassMethods

  validate :validate_text_list_user_data

  # Returns the lists this class will use.  Each element will get passed to
  # init_nonsearch_list.
  def self.model_lists
    @lists ||= [[:immune_name, 'all_immunizations']]
  end

 # Returns the ID of the TextList for the primary field for this record.
  def self.primary_list_id
    137
  end

  # Returns the array of field names of the date fields to be validated.
  def self.date_fields
    @date_fields ||= %w{vaccine_date immune_duedate}
  end

  # Returns the column name of the field holding the primary list for the record.
  def self.primary_field
    'immune_name'
  end

  # Returns the list item matching the immune_name_C
  def immune_item
    immune_name_C.blank? ?  nil : TextList.get_list_items(
      "all_immunizations", nil, nil, {:code => immune_name_C})[0]
  end

  # Returns all class names related to this record
  def immune_classes
    immune_item && immune_item.classification_names
  end

  # Returns all class codes related to this record
  def immune_classes_C
    immune_item && immune_item.classification_codes
  end

  alias_method :immune_url, :info_link

  init_text_list_user_data
end
