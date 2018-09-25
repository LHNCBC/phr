class PhrMedicalContact < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods

  belongs_to :profile

  validates_presence_of :name

  # Set up methods for accessing and working this model's lists
  # Contact type list
  init_nonsearch_list :medcon_type, # the field's name is "medcont_type"
    Proc.new{TextList.find_by_list_name('medirec_dr_types').text_list_items},
    :code, :item_text

  # A list of the fields that are dates
  DATE_FIELDS = %w{next_appt}

  # When validating, convert the dates to HL7 and epoch time.
  validate :validate_instance
  def validate_instance
    validate_cwe_field(:medcon_type)

    date_reqs = self.class.date_requirements(DATE_FIELDS, 'phr')
    DATE_FIELDS.each {|f| validate_date(f, date_reqs[f])}
  end
end
