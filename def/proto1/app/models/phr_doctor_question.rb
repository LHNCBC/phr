class PhrDoctorQuestion < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods

  belongs_to :profile

  # Set up methods for accessing and working this model's lists
  # Category list
  init_nonsearch_list :category, # the field's name is "category"
    Proc.new{TextList.find_by_list_name('Question Categories').text_list_items},
    :code, :item_text
  # Status list
  init_nonsearch_list :question_status,
    Proc.new{TextList.find_by_list_name('question_status').text_list_items},
    :code, :item_text

  # A list of the fields that are dates
  DATE_FIELDS = %w{date_entered}

  validates_presence_of :question

  # When validating, convert the dates to HL7 and epoch time.
  def validate
    validate_cwe_field(:category)

    validate_cne_field(:question_status)

    date_reqs = self.class.date_requirements(DATE_FIELDS, 'phr')
    DATE_FIELDS.each {|f| validate_date(f, date_reqs[f])}
  end
end
