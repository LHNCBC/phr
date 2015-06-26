class ClinicalMap < ActiveRecord::Base
  # Returns the answers for the given list.
  # The return value will be a list of two lists.  The first list
  # will be the list of codes (nil, because this list doesn't have codes),
  # and the second will be the list of text strings for the list items.
  # Parameters:
  #   name - the name of the list, passed in as a string (presumably from
  #          the field_descriptions.control_type_detail field).
  # patient - if true, return patient-text, else clinician text
  def self.getTextByLookup(name,patient=nil)
    rtn = [];
    route = ClinicalMap.find_all_by_lookup_field(name)
    if(patient == true)
      route.each do |m|
        rtn.push(m.patient_text)
      end
    else 
      route.each do |m|
        rtn.push(m.clinician_text)
      end
    end 
    [nil, rtn]
  end
end
