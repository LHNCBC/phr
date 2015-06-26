require 'test_helper'

class ObrOrderTest < ActiveSupport::TestCase

  def setup
    # Data needed for the date field validation
    PredefinedField.create!("predef_type"=>"HL7",
      "field_type"=>"ST - string data", "control_type"=>"text_field",
      "form_builder"=>true, "hl7_code"=>"ST", "rails_data_type"=>"string",
      "fb_map_field"=>"ST", "display_only"=>false)
    pf = PredefinedField.create!({"fb_map_field"=>"DT", "display_size"=>8,
                                  "help_text"=>"Specifies the century and year with optional precision to month and day.",
                                  "predef_type"=>"HL7", "regex_validator_id"=>"12", "form_builder"=>true,
                                  "hl7_code"=>"DT", "field_type"=>"DT - date", "rails_data_type"=>"string",
                                  "control_type"=>"calendar"})
    #   (obr_orders)
    db_td = DbTableDescription.create!({"data_table"=>"obr_orders", "omit_from_tables_list"=>true, "has_record_id"=>true,
                                        "description"=>"Panel Data Table for Test Panels"})
    #     (test_date)
    db_fd = db_td.db_field_descriptions.create!({ "required"=>true, "data_column"=>"test_date", "max_responses"=>0,
                                                   "html_parse_level"=>0, "display_name"=>"Test Date",
                                                   "predefined_field_id"=>5, "field_type"=>"DT - date"})
    fd = db_fd.field_descriptions.create!({"form_id"=>52, "help_text"=>"/help/when_done.shtml",
                                           "control_type_detail"=>{"date_format"=>"YYYY/[MM/[DD]]", "calendar"=>"true"},
                                           "target_field"=>"tp_panel_testdate", "group_header_id"=>1297, "editor"=>0,
                                           "max_responses"=>1, "suggestion_mode"=>0, "html_parse_level"=>0,
                                           "min_width"=>"8.9em", "display_order"=>30, "display_name"=>"When done",
                                           "auto_fill"=>true, "predefined_field_id"=>5, "field_type"=>"DT - date",
                                           "width"=>"8.9em", "control_type"=>"calendar"})
    #     (test_date_ET)
    db_fd = db_td.db_field_descriptions.create!({"data_size"=>20, "data_column"=>"test_date_ET", "max_responses"=>0,
                                                 "html_parse_level"=>0,  "predefined_field_id"=>39, "field_type"=>"Integer"})
    #     (test_date_HL7)
    db_fd = db_td.db_field_descriptions.create!({"data_column"=>"test_date_HL7", "max_responses"=>0, "html_parse_level"=>0,
                                                 "predefined_field_id"=>5, "field_type"=>"DT - date"})
    #     (due_date)
    db_fd = db_td.db_field_descriptions.create!({"data_column"=>"due_date", "max_responses"=>0, "html_parse_level"=>0,
                                                 "display_name"=>"Due Date", "predefined_field_id"=>5, "field_type"=>"DT - date"})
    fd = db_fd.field_descriptions.create!({"form_id"=>52, "help_text"=>"/help/due_date_test.shtml",
                                           "control_type_detail"=>{"date_format"=>"YYYY/[MM/[DD]]", "calendar"=>"true"},
                                           "target_field"=>"tp_panel_duedate", "group_header_id"=>1297, "editor"=>0,
                                           "max_responses"=>1, "suggestion_mode"=>0, "html_parse_level"=>0,
                                           "display_order"=>55, "display_name"=>"Next Due", "auto_fill"=>true,
                                           "predefined_field_id"=>5, "field_type"=>"DT - date", "control_type"=>"calendar"})
    #     (due_date_ET)
    db_fd = db_td.db_field_descriptions.create!({"data_size"=>20, "data_column"=>"due_date_ET", "max_responses"=>0,
                                                 "html_parse_level"=>0, "predefined_field_id"=>39, "field_type"=>"Integer"})
    #     (due_date_HL7)
    db_fd = db_td.db_field_descriptions.create!({"data_column"=>"due_date_HL7", "max_responses"=>0, "html_parse_level"=>0,
                                                 "predefined_field_id"=>5, "field_type"=>"DT - date"})
    #   (obx_observations)
    db_td = DbTableDescription.create!({"parent_table_id"=>1, "data_table"=>"obx_observations", "has_record_id"=>true,
                                        "parent_table_foreign_key"=>"obr_order_id", "description"=>"Observations"})
    #     (test_date)
    db_fd = db_td.db_field_descriptions.create!({"data_column"=>"test_date", "max_responses"=>0, "html_parse_level"=>0,
                                                 "display_name"=>"Observation Date", "predefined_field_id"=>5,
                                                 "field_type"=>"DT - date"})
    fd = db_fd.field_descriptions.create!({"form_id"=>52, "help_text"=>"The date when the test was performed, or an approximation.",
                                           "control_type_detail"=>{"date_format"=>"YYYY/[MM/[DD]]", "display_size"=>"15",
                                                                   "class"=>["hidden_field"], "calendar"=>"true"},
                                           "target_field"=>"tp_test_date", "group_header_id"=>1302, "editor"=>0,
                                           "max_responses"=>1, "suggestion_mode"=>0, "html_parse_level"=>0,
                                            "display_order"=>180, "display_name"=>"When Done", "auto_fill"=>true,
                                            "predefined_field_id"=>5, "field_type"=>"DT - date", "control_type"=>"calendar"})
    #     (test_date_ET)
    db_fd = db_td.db_field_descriptions.create!({"data_size"=>20, "data_column"=>"test_date_ET", "max_responses"=>0,
                                                 "html_parse_level"=>0, "omit_from_field_lists"=>true,
                                                 "predefined_field_id"=>39, "field_type"=>"Integer"})
    #     (test_date_HL7)
    db_fd = db_td.db_field_descriptions.create!({"data_column"=>"test_date_HL7", "max_responses"=>0, "html_parse_level"=>0,
                                                 "omit_from_field_lists"=>true, "predefined_field_id"=>5,
                                                 "field_type"=>"DT - date"})
    # (test_date_time)
    db_fd = db_td.db_field_descriptions.create!(
      "data_column"=>"test_date_time",
      "max_responses"=>0,
      "field_type"=>"ST - string data",
      "predefined_field_id"=>1,
      "html_parse_level"=>0,
      "virtual"=>false,
      "omit_from_field_lists"=>false,
      "is_major_item"=>false,
      "item_table_has_unique_codes"=>false)

    db_fd.field_descriptions.create!("form_id"=>52, "display_order"=>31,
      "target_field"=>"tp_panel_testdate_time",
      "display_name"=>"Time done",
      "control_type"=>"time_field",
      "control_type_detail"=>{"display_size"=>"15", "class"=>["time"]},
      "required"=>false, "max_responses"=>1, "group_header_id"=>1297,
      "help_text"=>"/help/when_done_time.shtml",
      "field_type"=>"ST - string data", "predefined_field_id"=>1,
      "html_parse_level"=>0, "controlled_edit"=>false, "width"=>"12em",
      "min_width"=>"4em", "editor"=>0,
      "cet_no_dup"=>false, "auto_fill"=>true, "in_hdr_only"=>false,
      "suggestion_mode"=>0, "wrap"=>false)

    # Now reset the ObrOrder's (possibly incomplete) knowledge of the
    # validation for the date fields
    def ObrOrder.reset_date_requirements
        @date_requirements = nil
    end
    ObrOrder.reset_date_requirements
  end


  # Tests time field validation
  def test_time_field
    # Note:  Date validation is exercised in phr_test.rb.
    order = ObrOrder.new(:test_date=>'2013/5/7')
    order.valid?
    assert(order.test_date_time.blank?)
    assert(order.errors[:test_date_time].blank?)
    assert_equal(1367942400000, order.test_date_ET) # 12 PM on 2013/5/7
    assert_equal('20130507', order.test_date_HL7)

    # Try different legal time formats
    [['11 AM', 1367938800000, '2013050711'],
     ['1:23 AM', 1367904180000, '201305070123'],
     ['12:34 PM', 1367944440000, '201305071234'],
     ['1:23 a.m.', 1367904180000, '201305070123'],
     ['12:34 P.M.', 1367944440000, '201305071234'],
     ['1:23:02 a.m.', 1367904182000, '20130507012302'],
     ['1:23:02.251 a.m.', 1367904182251, '20130507012302.251'],
     ['1:23:02.2511 a.m.', 1367904182251, '20130507012302.2511'],
     ['1:23:02.25107 a.m.', 1367904182251, '20130507012302.2510'],
     ['1:23:02.25187 a.m.', 1367904182251, '20130507012302.2518'],
     ['1:23:02.200 a.m.', 1367904182200, '20130507012302.200']
    ].each do |str, et, hl7|
      order.test_date_time = str
      order.valid?
      assert(order.errors[:test_date_time].blank?,
        "'#{str}' #{order.errors[:test_date_time].inspect}")
      assert_equal(et, order.test_date_ET, str)
      assert_equal(hl7, order.test_date_HL7, hl7)
    end

    # Try some invalid time formats
    ['1:23', '91:23 AM', '00:23 AM', '11:77 AM', 'asdf'].each do |time_str|
      order.test_date_time = time_str
      order.valid?
      assert(!order.errors[:test_date_time].blank?, time_str)
    end
  end


  # Tests the validation of an ObxObservation
  def test_obx_validation
    # Create some test data
    panel_li = LoincItem.create!({"time_aspct"=>"Pt", "shortname"=>"Diabetes tracking Pnl", "component"=>"Diabetes tracking panel", "relatednames2"=>"; Diabetes tracking Pnl; Point in time; Random; Pan; Panl; PHR panels", "property"=>"-", "scale_typ"=>"-", "loinc_class"=>"PANEL.PHR", "unitsrequired"=>"N", "is_searchable"=>true, "included_in_phr"=>true, "id"=>49790, "loinc_num"=>"55399-0", "loinc_system"=>"^Patient", "is_panel"=>true, "has_top_level_panel"=>true, "status"=>"ACTIVE", "loinc_version"=>"2.32", "consumer_name"=>"Diabetes tracking panel", "classtype"=>2, "long_common_name"=>"Diabetes tracking panel"})
    li = LoincItem.create!({"component"=>"Heart rate", "related_names"=>"HEART RATE; PULSE RATE", "shortname"=>"Heart rate", "time_aspct"=>"Pt", "property"=>"NRat", "relatednames2"=>"; nRate; Number rate; Count/time; Point in time; Random; Misc; Miscellaneous; Unspecified; Other; Quantitative; QNT; Quant; Quan; Pulse; Heart beat; HEART RATE.ATOM; HEART RATE.ATOM", "loinc_class"=>"HRTRATE.ATOM", "scale_typ"=>"Qn", "common_tests"=>"Y", "curated_range_and_units"=>"60-100;/min", "excluded_from_phr"=>false, "hl7_v3_type"=>"PQ", "id"=>57719, "included_in_phr"=>true, "is_searchable"=>false, "example_units"=>"/min", "loinc_num"=>"8867-4", "has_top_level_panel"=>false, "is_panel"=>false, "loinc_system"=>"XXX", "norm_range"=>"60-100;/min", "classtype"=>2, "consumer_name"=>"Heart rate", "loinc_version"=>"2.32", "status"=>"ACTIVE", "long_common_name"=>"Heart rate"})

    obr = ObrOrder.create!(:loinc_num=>'55399-0', :test_date=>'2010/11/17',
      :latest=>1)
    assert(obr.valid?)
    obx1 = ObxObservation.create!(:loinc_num=>'8867-4', :obr_order_id=>'-1',
      :obx5_value=>'4', :obr_order_id=>obr.id, :latest=>1)
    assert_equal(1290013200000, obr.test_date_ET)
    assert(obx1.valid?)
    obx2 = ObxObservation.create!(:loinc_num=>'8867-4', :obr_order_id=>'-1',
      :obx5_value=>'4', :obr_order_id=>obr.id, :latest=>1)
    assert(obx2.valid?)

    # Now see if the test_date information was copied.
    [obx1, obx2].each_with_index do |o, i|
      assert_equal('2010 Nov 17', o.test_date, "Iteration #{i}")
      assert_equal(1290013200000, o.test_date_ET, "Iteration #{i}")
      assert_equal('20101117', o.test_date_HL7, "Iteration #{i}")
    end

    # Now update the OBR date, and confirm it gets copied to the OBXs.
    # Reload the obx_observations association (because we added new ones).
    obr.obx_observations(true)
    obr.test_date = '2010/11/18'
    obr.save!
    [obx1, obx2].each_with_index do |o, i|
      o = ObxObservation.find(o.id) # Reload the cached attributes
      assert_equal('2010 Nov 18', o.test_date, "Iteration #{i}")
      assert_equal(1290099600000, o.test_date_ET, "Iteration #{i}")
      assert_equal('20101118', o.test_date_HL7, "Iteration #{i}")
    end
  end


  # This tests UserData#update_field_from_vals
  def test_update_field_from_vals
    obr = ObrOrder.create(:test_place=>'one')
    assert_equal('one', obr.test_place)
    obr.update_field_with_vals(:test_place, '', 'one')
    assert_equal('one', obr.test_place)
    obr.update_field_with_vals(:test_place, 'one', '')
    assert_equal('one', obr.test_place)
    obr.update_field_with_vals(:test_place, '', '')
    assert_equal('', obr.test_place)
    obr.update_field_with_vals(:test_place, nil, '   ')
    assert_equal('', obr.test_place)
    obr.update_field_with_vals(:test_place, 'one', '')
    assert_equal('one', obr.test_place)
    obr.update_field_with_vals(:test_place, '', 'two')
    assert_equal('two', obr.test_place)
    obr.update_field_with_vals(:test_place, 'three', 'two')
    assert_equal('three', obr.test_place)
    obr.update_field_with_vals(:test_place, 'four', 'five')
    assert_equal('five', obr.test_place)
  end
end
