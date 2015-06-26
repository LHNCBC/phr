# This is an application specific model class.  Avoid putting general framework
# code here.
class PhrAllergy < ActiveRecord::Base
  include TextListUserData
  extend TextListUserData::ClassMethods

  def validate
    super
    validate_cwe_field(:reaction)
  end

  # Returns the lists this class will use.  Each element will get passed to
  # init_nonsearch_list.
  def self.model_lists
    @lists ||= [[:allergy_name, 'all_allergens'], [:reaction, 'Allergic Reactions']]
  end

  # Returns the ID of the TextList for the primary field for this record.
  def self.primary_list_id
    136
  end

  # Returns the array of field names of the date fields to be validated.
  def self.date_fields
    @date_fields ||= %w{reaction_date}
  end

  # Returns the column name of the field holding the primary list for the record.
  def self.primary_field
    'allergy_name'
  end

  alias_method :allergy_url, :info_link

  init_text_list_user_data
end
