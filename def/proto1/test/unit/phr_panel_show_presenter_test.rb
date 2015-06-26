require 'test_helper'

# Tests PhrPanelShowPresenter
class PhrPanelShowPresenterTest < ActiveSupport::TestCase

  # Disable validation of ObrOrder; that is not what we are testing here,
  # and disabling it lets us avoid copying certain tables.
  class ObrOrder < ::ObrOrder
    def validate
    end
  end

  def test_panel_headers
    DatabaseMethod.copy_development_tables_to_test(
      %w{loinc_names loinc_panels loinc_items})

    # Create an OBR for testing.
    obr = ObrOrder.create!("record_id"=>5, "test_date_HL7"=>"20110825",
      "loinc_num"=>'46637-5', "test_date"=>"2011 Aug 25", "latest"=>true,
      "version_date"=>"Thu Aug 25 17:34:28 -0400 2011",
      "test_date_ET"=>1314244800000)

    # Add an OBX that should have two headings (level 3)
    obx1 = ObxObservation.new(:loinc_num=>'46652-4', :obx5_value=>'one',
     :latest=>true)
    obr.obx_observations << obx1

    # Add another one after this, but in the same heading group, to make sure
    # the the headings are not repeated.
    obx2 = ObxObservation.new(:loinc_num=>'46653-2', :obx5_value=>'two',
     :latest=>true)
    obr.obx_observations << obx2

    # Add another OBX that should have one heading, but which occurs after some
    # level 2 headings (to make sure the level two headings are included with
    # the this level 1 heading).
    obx3 = ObxObservation.new(:loinc_num=>'46693-8', :obx5_value=>'three',
     :latest=>true)
    obr.obx_observations << obx3

    p = PhrPanelShowPresenter.new(obr)
    test_info = p.test_info
    assert_equal 6, test_info.size
    assert_equal 2, test_info[0][0] # display level
    assert_equal String, test_info[0][1].class # a header

    assert_equal 3, test_info[1][0] # display level
    assert_equal String, test_info[1][1].class # a header

    assert_equal 4, test_info[2][0] # display level
    assert_equal ObxObservation, test_info[2][1].class # a panel item row
    assert_equal 'one', test_info[2][1].obx5_value

    assert_equal 4, test_info[3][0] # display level
    assert_equal ObxObservation, test_info[3][1].class # a panel item row
    assert_equal 'two', test_info[3][1].obx5_value

    assert_equal 2, test_info[4][0] # display level
    assert_equal String, test_info[4][1].class # a header

    assert_equal 3, test_info[5][0] # display level
    assert_equal ObxObservation, test_info[5][1].class # a panel item row
    assert_equal 'three', test_info[5][1].obx5_value
  end
end
