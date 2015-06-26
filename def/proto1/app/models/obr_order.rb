class ObrOrder < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods

  has_many :obx_observations, ->{ where('latest=1').order('display_order')}, dependent: :destroy
  belongs_to :loinc_panel, :foreign_key=>'loinc_num', :primary_key=>'loinc_num'
  belongs_to :loinc_item, :foreign_key=>'loinc_num', :primary_key=>'loinc_num'
  
  DATE_FIELDS = %w{test_date due_date}


  # Peforms validation and other updates that happen when fields change
  def validate
    # Validate the dates.  Normally, the requirements for the date fields
    # would be taken from the field_descriptions table.  (See PhrDrug for
    # an example.)  However, there currently no tooltips for
    date_reqs = self.class.date_requirements(DATE_FIELDS, 'loinc_panel_temp')
    DATE_FIELDS.each {|f| validate_date(f, date_reqs[f])}

    if test_date_changed? || test_date_time_changed?
      # Copy the new test date values to all of this OBR's OBXs.
      obx_observations.each do |obx|
        %w{test_date test_date_time test_date_ET test_date_HL7}.each do |f|
          obx.send(f+'=', self.send(f))
        end
        obx.save!
      end
    end
  end


  # Returns a date that can be displayed to the user but which can also be
  # sorted in a table.
  def sortable_date
    # Base it off of the HL7 format.
    test_date_HL7 =~ /(\d\d\d\d)((\d\d)(\d\d)?)?/
    rtn = $1
    rtn += "/#{$3}" if $3
    rtn += "/#{$4}" if $4
  end


  def is_single_test_panel?
    return single_test
  end
end
