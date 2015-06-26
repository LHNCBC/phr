class ObxObservation < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods

  belongs_to :obr_order
  belongs_to :loinc_panel, :foreign_key=>'loinc_num', :primary_key=>'loinc_num'
  belongs_to :loinc_item, :foreign_key=>'loinc_num', :primary_key=>'loinc_num'
  belongs_to :loinc_unit, :foreign_key=>'unit_code'
  validates_presence_of :obr_order_id

  # aliases for code fields.  We can't use alias_method, because
  # the database field methods aren't defined yet, but alias_attribute works.
  alias_attribute :obx5_value_C, :obx5_1_value_if_coded
  alias_attribute :obx6_1_unit_C, :unit_code

  # Validation method.  (Validates things needed for the basic mode.)
  def validate
    # If the unit code changed, use that coded value set the range data, unless
    # the user also changed the range.
    range_changed = obx7_reference_ranges_changed?
    if !range_changed && obx6_1_unit_C_changed? && loinc_unit
      self.obx7_reference_ranges = loinc_unit.norm_range
      self.test_normal_high = loinc_unit.norm_high
      self.test_normal_low = loinc_unit.norm_low
      self.test_danger_high = loinc_unit.danger_high
      self.test_danger_low = loinc_unit.danger_low
    end

    # Blank out the test_normal, etc. fields if the reference range changed
    # or there is no loinc_unit record.
    if range_changed || !loinc_unit
      # Blank out with an empty string, for the convenience of the basic
      # mode.  Forms return empty strings for empty fields.
      self.test_normal_high =
        self.test_normal_low =
        self.test_danger_high =
        self.test_danger_low = ''
    end

    # If there is no loinc_unit, and the unit code changed, and the obx7 didn't
    # change, blank it out too
    if !loinc_unit && obx6_1_unit_C_changed? && !range_changed
      self.obx7_reference_ranges = ''
    end

    # Synchronize code and display fields for the value and unit lists.
    # In the following arrays, the first element is the field name, and the
    # second is the method that returns a field value for a given code.
    [['obx5_value', 'obx_val_for_code'],
     ['obx6_1_unit', 'unit_val_for_code']].each do |field, value_for_code|
      cfield = self.class.send('code_field', field)
      if send(cfield+'_changed?')
        cfield_val = send(cfield)
        if cfield_val.blank?
          send(field+'=', '') unless send(field+'_changed?')
        else
          send(field+'=', send(value_for_code, cfield_val))
        end
      end
    end
    # Check for a blank value.  (We couldn't do validates_presence_of, because
    # the above code might fill in a missing value.)
    errors.add(:obx5_value, 'can\'t be blank') if obx5_value.blank?

    # If this is a new record, copy the date fields from the OBR.
    if new_record? && obr_order_id
      %w{test_date test_date_ET test_date_HL7}.each do |f|
        self.send(f+'=', obr_order.send(f))
      end
    end
  end

  # Create a set of accessor methods for panel data, for use in the Excel
  # export.
  %w{version_date loinc_num test_place
     test_date test_date_ET test_date_HL7 test_date_time summary due_date
     due_date_ET due_date_HL7 panel_name}.each {|panel_method|
    obx_method = panel_method.index('panel_') == 0 ? panel_method :
                                                    'panel_'+panel_method
    define_method(obx_method) {
      obr_order.send(panel_method)
    }
  }


  # Returns the current name of the test (in case the saved value has
  # changed.)
  def current_display_name
    loinc_item = LoincItem.find_by_loinc_num(loinc_num)
    return loinc_item.nil? ? '' : loinc_item.display_name
  end

  # Sets up an alias for loinc_num (the code field for the display name)
  # so that this model follows the convention that a list code field is named
  # with field_name + "_C" where field_name is the display value of a list.
  def obx3_2_obs_ident_C
    loinc_num
  end


  # Returns the display string for unit specified by the given unit code.
  #
  # Parameters:
  # * code - the unit code
  def unit_val_for_code(code)
    loinc_item.loinc_units.find(code).unit
  end


  # Returns the display string for obx value specified by the given value code.
  #
  # Parameters:
  # * code - the unit code
  def obx_val_for_code(code)
    loinc_item.answer_list.list_answers.find_by_code(code).answer_text
  end

  # Return an empty string if unit is null
  def obx6_1_unit
    unit = read_attribute("obx6_1_unit")
    unit.nil? ? "" : unit
  end

  # redefine test_date, test_date_ET and test_date_HL7
  # which have no data stored and use value in obr_orders instead

  def test_date
    obr_order.test_date
  end

  def test_date_ET
    obr_order.test_date_ET
  end

  def test_date_HL7
    obr_order.test_date_HL7
  end

  def test_date_time
    obr_order.test_date_time
  end

  # Returns the name of the code field for a field.
  #
  # Parameters:
  # * field - the data column (as a string)
  def self.code_field(field)
    if field == 'obx5_value'
      'obx5_1_value_if_coded'
    else
      super
    end
  end


  # Returns the ObxObservation that is the most recent (by test date) result
  # for this observation's test (and profile).
  def get_latest_obx_observation
    rtn = nil
    query_str ="select a.* from obx_observations a, " +
        " latest_obx_records b where a.id=b.last_obx_id and " +
        " b.loinc_num=? and " + " b.profile_id=? and a.obx5_value IS NOT NULL"
    results = ObxObservation.find_by_sql([query_str, loinc_num, profile_id])
    if !results.nil? && results.length >0
      rtn = results[0]
    end
    return rtn
  end


  # Returns a string which combines the test value with the age of this test
  # (or just the date, if the test was from today).
  def value_with_age
    return "#{obx5_value} #{self.class.formatted_test_age(test_date_ET, test_date)}"
  end


  # Returns a string with brackets around a string describing the age
  # of the given test date relative to the present.  If the date is still
  # the current date, the date string will be returned instead.
  #
  # Parameters:
  # * test_date_et - the "epoch time" of the test (the time in milliseconds
  #   since 1970).
  # * test_date a string for the test's date.
  def self.formatted_test_age(test_date_et,test_date)
    if test_date_et.blank?
      rtn = ""
    else
      et = (test_date_et/1000).to_i
      seconds = Time.now.to_i - et
      #calculate hours, days, weeks, months and years
      hours = (seconds/60.0/60).round(1)
      days = (seconds/60.0/60/24).round(1)
      weeks = (seconds/60.0/60/24/7).round(1)
      months = (seconds/60.0/60/24/30).round(1)
      years = (seconds/60.0/60/24/365).round(1)
      rtn = ""
      if days <0
        rtn = test_date
      elsif days <= 14
        if days <1
          rtn = 'today'
        elsif days <2
          rtn = 'yesterday'
        else
          rtn = days.to_i.to_s + " days ago"
        end
      elsif weeks <= 52
        rtn =  weeks.to_s + " weeks ago"
      else
        rtn = years.to_s + " years ago"
      end
    end
    return "[" + rtn + "]"
  end


  # Override the default ignored_columns methods in user_data.rb
  # For Obx records with no test values, they are treated as empty records,
  # thus are not saved.
  def self.ignored_columns
    column_names - ['obx5_value','obx5_1_value_if_coded']
  end
end
