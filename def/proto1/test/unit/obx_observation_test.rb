require 'test_helper'

class ObxObservationTest < ActiveSupport::TestCase

  def setup
    LoincUnit.destroy_all # to avoid duplicated id error for a new LoincUnit record of id 5593
  end

  # Tests the range and unit validation of an ObxObservation
  def test_range_and_unit_validation
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions', 'forms'])

     # Create some test data
    li = LoincItem.where(id: 57719).take; li.destroy if li
    li = LoincItem.create!({"component"=>"Heart rate", "related_names"=>"HEART RATE; PULSE RATE", "shortname"=>"Heart rate", "time_aspct"=>"Pt", "property"=>"NRat", "relatednames2"=>"; nRate; Number rate; Count/time; Point in time; Random; Misc; Miscellaneous; Unspecified; Other; Quantitative; QNT; Quant; Quan; Pulse; Heart beat; HEART RATE.ATOM; HEART RATE.ATOM", "loinc_class"=>"HRTRATE.ATOM", "scale_typ"=>"Qn", "common_tests"=>"Y", "curated_range_and_units"=>"60-100;/min", "excluded_from_phr"=>false, "hl7_v3_type"=>"PQ", "id"=>57719, "included_in_phr"=>true, "is_searchable"=>false, "example_units"=>"/min", "loinc_num"=>"8867-4", "has_top_level_panel"=>false, "is_panel"=>false, "loinc_system"=>"XXX", "norm_range"=>"60-100;/min", "classtype"=>2, "consumer_name"=>"Heart rate", "loinc_version"=>"2.32", "status"=>"ACTIVE", "long_common_name"=>"Heart rate"})
    LoincUnit.where(id: 5593..5595).each {|lu| lu.destroy}
    u = LoincUnit.new({"loinc_item_id"=>li.id, "id"=>5593, "unit"=>"/min", "norm_low"=>"60", "loinc_num"=>"8867-4", "danger_low"=>"40", "norm_high"=>"100", "source_type"=>"REGENSTRIEF", "norm_range"=>"60-100", "source_id"=>1, "danger_high"=>"130"})
    u.id = 5593; u.save!;# u.reload.id
    u = LoincUnit.new({"loinc_item_id"=>li.id, "id"=>5594, "unit"=>"bpm", "norm_low"=>nil, "loinc_num"=>"8867-4", "danger_low"=>nil, "norm_high"=>nil, "source_type"=>"REGENSTRIEF", "norm_range"=>nil, "source_id"=>1, "danger_high"=>nil})
    u.id = 5594; u.save!;# u.reload.id
    u = LoincUnit.new({"loinc_item_id"=>li.id, "id"=>5595, "unit"=>"bpm2", "norm_low"=>nil, "loinc_num"=>"8867-4", "danger_low"=>nil, "norm_high"=>nil, "source_type"=>"REGENSTRIEF", "norm_range"=>nil, "source_id"=>1, "danger_high"=>nil})
    u.id = 5595; u.save!;# u.reload.id
    obr = ObrOrder.create!(:test_date=>'2011/12/23', :latest=>1)
    obx = ObxObservation.create!(:loinc_num=>'8867-4', :obr_order_id=>obr.id,
      :obx5_value=>'4', :latest=>1)

    # Test range validation
    # Pick a unit with a range
    obx.unit_code = 5593
    obx.save!
    assert_equal('/min', obx.obx6_1_unit)
    assert_equal('60-100', obx.obx7_reference_ranges)
    assert_equal('100', obx.test_normal_high)

    # Change the unit to one without a range
    obx.unit_code = 5594; obx.reload_loinc_unit # reload the LoincUnit
    obx.save!
    assert_equal('bpm', obx.obx6_1_unit)
    assert(obx.obx7_reference_ranges.blank?)

    # Add a range
    obx.obx7_reference_ranges = '1-2'
    obx.save!
    assert_equal('bpm', obx.obx6_1_unit)
    assert_equal('1-2', obx.obx7_reference_ranges)

    # Change the unit to one without a range.  Again, the range should clear
    obx.unit_code = 5595; obx.reload_loinc_unit # reload the LoincUnit
    obx.save!
    assert_equal('bpm2', obx.obx6_1_unit)
    assert(obx.obx7_reference_ranges.blank?)

    # Add the range back, and also pick a new unit with a range.  The user
    # might be entering a range different from the default one for that unit,
    # so the user's range should prevail.
    obx.obx7_reference_ranges = '1-2'
    obx.unit_code = 5593; obx.reload_loinc_unit # reload the LoincUnit
    obx.save!
    assert_equal('/min', obx.obx6_1_unit)
    assert_equal('1-2', obx.obx7_reference_ranges)

    # Change the range, and also pick a new unit without a range.  Again,
    # the user's newly entered range should be taken.
    obx.obx7_reference_ranges = '3-4'
    obx.unit_code = 5594; obx.reload_loinc_unit # reload the LoincUnit
    obx.save!
    assert_equal('bpm', obx.obx6_1_unit)
    assert_equal('3-4', obx.obx7_reference_ranges)

    # Change the range and enter an unknown unit.
    obx.obx7_reference_ranges = '1-2'
    obx.obx6_1_unit = 'kPa'
    obx.save!
    assert_equal('kPa', obx.obx6_1_unit)
    assert_equal('1-2', obx.obx7_reference_ranges)

    # Change to another unknown unit.  The range should be left alone
    # (because the user maybe was just correcting a typo in the unit field).
    obx.obx6_1_unit = 'N*s'
    obx.save!
    assert_equal('N*s', obx.obx6_1_unit)
    assert_equal('1-2', obx.obx7_reference_ranges)

    # Enter and unknown unit and clear the code field, and enter a range
    # Allow the user's newly entered value to trump the list selection.
    obx.obx7_reference_ranges = '3-4'
    obx.obx6_1_unit_C = nil
    obx.obx6_1_unit = 'mJ'
    obx.save!
    assert_equal('mJ', obx.obx6_1_unit)
    assert_equal('3-4', obx.obx7_reference_ranges)
  end


  # Test the value field validation
  def test_value_validation
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items',
        'loinc_items', 'loinc_panels', 'loinc_units',
        'answer_lists', 'list_answers', 'answers'])
    obr = ObrOrder.create!("record_id"=>6, "test_date_HL7"=>"20110825",
      "loinc_num"=>"24356-8", "test_date"=>"2011 Aug 25", "latest"=>true,
      "version_date"=>"Thu Aug 25 17:34:28 -0400 2011",
      "test_date_ET"=>1314244800000,
      "panel_name"=>"Urinalysis Panel")

    # Test that we can't save a blank value
    obx = ObxObservation.new(:loinc_num=>'5767-9', :obr_order_id=>obr.id,
      :latest=>1)
    assert !obx.valid?

    # Test that assigning a value without a code does not lose the value.
    obx = ObxObservation.new(:loinc_num=>'5767-9', :obr_order_id=>obr.id,
      :obx5_value=>'green', :latest=>1)
    assert obx.valid?
    assert_equal 'green', obx.obx5_value

    # Test that assigning a code without a value finds the value for the code
    obx = ObxObservation.new(:loinc_num=>'5767-9', :obr_order_id=>obr.id,
      :obx5_value_C=>'1323', :latest=>1)
    assert obx.valid?
    assert !obx.obx5_value.blank?
    obx.save!

    # Test changing the value by changing the code
    old_val = obx.obx5_value
    obx.obx5_value_C = '1322'
    obx.save!
    assert_not_equal old_val, obx.obx5_value
    assert !obx.obx5_value.blank?

    # Test changing to a non-coded value.  For now the code gets set too,
    # though that might change.
    obx.obx5_value = 'green'
    obx.obx5_value_C = ''
    obx.save!
    assert_equal 'green', obx.obx5_value
    assert obx.obx5_value_C.blank?

    # Test that we can't edit the value to blank
    obx.obx5_value = ''
    assert !obx.valid?
  end
end
