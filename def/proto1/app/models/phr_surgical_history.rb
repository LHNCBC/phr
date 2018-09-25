class PhrSurgicalHistory < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods

  belongs_to :gopher_term, :foreign_key=>:surgery_type_C, :primary_key=>:key_id
  belongs_to :profile


  # A list of the fields that are dates
  DATE_FIELDS = %w{surgery_when}

  # When validating, convert the dates to HL7 and epoch time.
  validate :validate_instance
  def validate_instance
    # Validate the surgery name and code
    if surgery_type_C_changed?
      surgery_info = GopherTerm.find_by_key_id(surgery_type_C)
      self.surgery_type = surgery_info.consumer_name
    elsif surgery_type_changed?
      surgery_info = GopherTerm.find_by_consumer_name(surgery_type)
      surgery_info = GopherTerm.find_by_primary_name(surgery_type) if !surgery_info
      self.surgery_type_C = surgery_info.key_id if surgery_info
    end

    if surgery_type.blank?
      errors.add(:surgery_type, 'must not be blank')
    end

    date_reqs = self.class.date_requirements(DATE_FIELDS, 'phr')
    DATE_FIELDS.each {|f| validate_date(f, date_reqs[f])}
  end


  # Returns information for links about this procedure.  If one link is found,
  # that will be the return value; otherwise the return value will be an array
  # where each element is a two-element array consisting of a URL and a label
  # for the URL.
  def info_link
    data = gopher_term.info_link_data if gopher_term
    if !data ||data.size == 0
      data = 'http://search.nlm.nih.gov/medlineplus/query?' +
             'MAX=500&SERVER1=server1&SERVER2=server2&' +
             'DISAMBIGUATION=true&FUNCTION=search&PARAMETER=' +
             URI.escape(surgery_type)
    end
    return data
  end
end
