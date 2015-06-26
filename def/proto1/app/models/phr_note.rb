# This is an application specific model class.  Avoid putting general framework
# code here.
class PhrNote < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods

  # A list of the fields that are dates
  DATE_FIELDS = %w{note_date}

  # When validating, convert the dates to HL7 and epoch time.
  def validate
    date_reqs = self.class.date_requirements(DATE_FIELDS, 'phr')
    DATE_FIELDS.each {|f| validate_date(f, date_reqs[f])}
  end

end
