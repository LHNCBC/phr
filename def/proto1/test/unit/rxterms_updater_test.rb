require 'test_helper'

class RxtermsUpdaterTest < ActiveSupport::TestCase
  def setup
    # Turn off ferret indexing.  We're not testing Ferret searching here,
    # but we are creating and deleting DNRs.
    DrugNameRoute.disable_ferret
    RxtermsIngredient.delete_all
    DrugStrengthForm.delete_all
    DrugNameRoute.delete_all
    DrugNameRouteCode.delete_all
    DatabaseMethod.copy_development_tables_to_test(['drug_routes'], false)
  end

  def teardown
    DrugNameRoute.enable_ferret
  end

  # Tests the get_rxterm_fields method
  def test_get_rxterm_fields
    rxterms_updater = RxtermsUpdater.new
    line = 'one||three'
    assert_equal(['one', '', 'three', nil, nil, nil, nil, nil, nil, nil, nil,
                  nil, nil, nil], rxterms_updater.get_rxterm_fields(line))
  end


  # Tests the get_max_strength_digits method.
  def test_get_max_strength_digits
    rxterms_updater = RxtermsUpdater.new
    dsf1 = DrugStrengthForm.create!(:text=>"4 MG Disintegrating Tabs",
      :rxcui=>104894, :amount_list_name=>"Tabs_Dose_Type", :strength=>"4 MG",
      :form=>"Disintegrating Tabs", :drug_name_route_id=>123)
    dsf2 = DrugStrengthForm.create!(:text=>"18 MG Disintegrating Tabs",
      :rxcui=>312087, :amount_list_name=>"Tabs_Dose_Type", :strength=>"120 MG",
      :form=>"Disintegrating Tabs", :drug_name_route_id=>123)

    assert_equal(3, rxterms_updater.get_max_strength_digits([dsf1, dsf2]))

    dsf1 = DrugStrengthForm.create!(:text=>"4 MG Disintegrating Tabs",
      :rxcui=>104894, :amount_list_name=>"Tabs_Dose_Type", :strength=>"mixed",
      :form=>"Disintegrating Tabs", :drug_name_route_id=>123)
    dsf2 = DrugStrengthForm.create!(:text=>"18 MG Disintegrating Tabs",
      :rxcui=>312087, :amount_list_name=>"Tabs_Dose_Type", :strength=>"mixed",
      :form=>"Disintegrating Tabs", :drug_name_route_id=>123)
    assert_equal(0, rxterms_updater.get_max_strength_digits([dsf1, dsf2]))
  end


  # Tests the post_update_processing method
  def test_post_update_processing
    rxterms_updater = RxtermsUpdater.new
    dnr2 = DrugNameRoute.create!(:text=>"Ondansetron (Oral Pill)",
      :route=>"Oral Pill", :suppress=>false)
    dsf1 =  DrugStrengthForm.create!(:text=>" 4 MG Disintegrating Tabs",
      :rxcui=>104894, :amount_list_name=>"Tabs_Dose_Type", :strength=>"4 MG",
      :form=>"Disintegrating Tabs", :suppress=>false)
    dnr2.drug_strength_forms << dsf1
    dsf2 =  DrugStrengthForm.create!(:text=>" 8 MG Disintegrating Tabs",
      :rxcui=>312087, :amount_list_name=>"Tabs_Dose_Type", :strength=>"123 MG",
      :form=>"Disintegrating Tabs", :suppress=>false)
    dnr2.drug_strength_forms << dsf2

    # Get the dsfs from the dnr, so we stay in sync.
    dsf1 = dnr2.drug_strength_forms[0]
    if dsf1.rxcui == 312087
      dsf2 = dsf1
      dsf1 = dnr2.drug_strength_forms[1]
    else
      dsf2 = dnr2.drug_strength_forms[1]
    end

    name_to_dnr = {dnr2.text=>dnr2}
    name_to_dsfs = {dnr2.text=>[dsf1, dsf2]}

    rxterms_updater.post_update_processing(name_to_dnr, name_to_dsfs)
    assert_equal('  4 MG', dsf1.strength)
    assert_equal('123 MG', dsf2.strength)
    assert_equal(false, dnr2.suppress)
    # Also test the status in the database
    assert_equal(false, DrugNameRoute.find(dnr2.id).suppress)

    # Try suppressing just one dsf.
    dsf1.suppress = true
    dsf1.save!
    rxterms_updater.post_update_processing(name_to_dnr, name_to_dsfs)
    assert_equal(false, dnr2.suppress)

    # Try suppressing both dsfs
    dsf2.suppress = true
    dsf2.save!
    rxterms_updater.post_update_processing(name_to_dnr, name_to_dsfs)
    assert_equal(true, dnr2.suppress)
  end


  # Tests the handling of duplicate name-route-strength-form combinations,
  # which sometimes exist due to problems in RxNorm.
  def test_duplicate_strength_forms
    rxterms_updater = RxtermsUpdater.new
    dnr2 = DrugNameRoute.create!(:text=>"Ondansetron (Oral Pill)",
      :route=>"Oral Pill", :suppress=>false)
    dsf1 =  DrugStrengthForm.create!(:text=>" 4 MG Disintegrating Tabs",
      :rxcui=>104894, :amount_list_name=>"Tabs_Dose_Type", :strength=>"4 MG",
      :form=>"Disintegrating Tabs", :suppress=>false)
    dnr2.drug_strength_forms << dsf1
    dsf2 =  DrugStrengthForm.create!(:text=>" 8 MG Disintegrating Tabs",
      :rxcui=>312087, :amount_list_name=>"Tabs_Dose_Type", :strength=>"4 MG",
      :form=>"Disintegrating Tabs", :suppress=>false)
    dnr2.drug_strength_forms << dsf2
    # Also check that if the lower rxcui is suppressed, it does not count
    # in considerations of duplicates.
    # Also try reversing the order of creation (rxcuis out of order).
    dsf3 =  DrugStrengthForm.create!(:text=>" 8 MG Disintegrating Tabs",
      :rxcui=>312088, :amount_list_name=>"Tabs_Dose_Type", :strength=>"8 MG",
      :form=>"Disintegrating Tabs", :suppress=>true)
    dnr2.drug_strength_forms << dsf3
    dsf4 =  DrugStrengthForm.create!(:text=>" 8 MG Disintegrating Tabs",
      :rxcui=>312090, :amount_list_name=>"Tabs_Dose_Type", :strength=>"8 MG",
      :form=>"Disintegrating Tabs", :suppress=>false)
    dnr2.drug_strength_forms << dsf4
    dsf5 =  DrugStrengthForm.create!(:text=>" 8 MG Disintegrating Tabs",
      :rxcui=>312089, :amount_list_name=>"Tabs_Dose_Type", :strength=>"8 MG",
      :form=>"Disintegrating Tabs", :suppress=>false)
    dnr2.drug_strength_forms << dsf5

    name_to_dnr = {dnr2.text=>dnr2}
    name_to_dsfs = {dnr2.text=>[dsf1, dsf2, dsf3, dsf4, dsf5]}

    rxterms_updater.post_update_processing(name_to_dnr, name_to_dsfs)
    assert_equal(false, dsf1.suppress)
    assert_equal(true, dsf2.suppress)
    assert_equal(true, dsf3.suppress)
    assert_equal(true, dsf4.suppress)
    assert_equal(false, dsf5.suppress)
  end


  # Tests the get_strength_number method.
  def test_get_strength_number
    rxterms_updater = RxtermsUpdater.new
    assert_equal('123', rxterms_updater.get_strength_number(' 123 mg'))
    assert_nil(rxterms_updater.get_strength_number('howdy'))
    assert_nil(rxterms_updater.get_strength_number('howdy 2'))
  end

  # Tests the compute_dnr_code method (indirectly).
  def test_compute_dnr_code
    DatabaseMethod.copy_development_tables_to_test(['drug_routes'])
    assert_equal(0, DrugNameRoute.count)
    assert_equal(0, DrugNameRouteCode.count)
    # Cases:
    # A suppressed DNR
    # A brand pack
    # A brand non-pack
    # A generic with more than one ingredient
    # A drug with "XR" in the name
    # A drug with "EC" in the name
    # A drug with "U500" in the name
    # A drug with "70/30" in the name
    rxterms_data = [
      '102166|197739|SBD|Glycopyrrolate 2 MG Oral Tablet [Robinul]|Oral Tablet|Glycopyrrolate 2 MG Oral Tablet|ROBINUL|ROBINUL (Oral Pill)|Oral Pill|Tabs|2 mg|||TRUE',
      '750268|748868|BPCK|{21 (Ethinyl Estradiol 0.02 MG / Levonorgestrel 0.1 MG Oral Tablet) / 7 (Inert Ingredients 1 MG Oral Tablet) } Pack [Aviane 28]|Pack|{21 (Ethinyl Estradiol 0.02 MG / Levonorgestrel 0.1 MG Oral Tablet) / 7 (Inert Ingredients 1 MG Oral Tablet) } Pack|AVIANE 28|AVIANE 28 (Pack)|Pack|Pack|mixed|||',
      '102303|198290|SBD|Tocainide 600 MG Oral Tablet [Tonocard]|Oral Tablet|Tocainide 600 MG Oral Tablet|TONOCARD|TONOCARD (Oral Pill)|Oral Pill|Tabs|600 mg|||',
      '106078||SCD|Hydrocortisone 10 MG/ML / Neomycin 5 MG/ML Topical Cream|Topical Cream|Hydrocortisone 10 MG/ML / Neomycin 5 MG/ML Topical Cream||Hydrocortisone/Neomycin (Topical)|Topical|Cream|10-5 mg/ml|||',
      '103171|562028|SBD|12 HR Orphenadrine 100 MG Extended Release Tablet [Norflex]|Extended Release Tablet|12 HR Orphenadrine 100 MG Extended Release Tablet|NORFLEX|NORFLEX XR (Oral Pill)|Oral Pill|12 Hrs XR Tabs|100 mg|||',
      '104099|198051|SBD|Omeprazole 20 MG Enteric Coated Capsule [Losec]|Enteric Coated Capsule|Omeprazole 20 MG Enteric Coated Capsule|LOSEC|LOSEC EC (Oral Pill)|Oral Pill|EC Caps|20 mg|||',
      '249220||SCD|Regular Insulin, Human 500 UNT/ML Injectable Solution|Injectable Solution|Regular Insulin, Human 500 UNT/ML Injectable Solution||Insulin, human Regular U500 (Injectable)|Injectable|Sol|500 unt/ml|||',
      '213441|311048|SBD|NPH Insulin, Human 70 UNT/ML / Regular Insulin, Human 30 UNT/ML Injectable Suspension [Humulin 70/30]|Injectable Suspension|NPH Insulin, Human 70 UNT/ML / Regular Insulin, Human 30 UNT/ML Injectable Suspension|HUMULIN 70/30|HUMULIN 70/30 (Injectable)|Injectable|Susp|70-30 unt/ml|||'
    ]
    brand_data = ['750268|2', '102303|3', '103171|5',
      '104099|6', '213441|8']
    ingredient_data = [
      '750268|Ethinyl Estradiol|4124', '750268|Inert Ingredients|748794',
         '750268|Levonorgestrel|6373',
      '102303|Tocainide|42359',
      '106078|Hydrocortisone|5492', '106078|Neomycin|7299',
      '103171|Orphenadrine|7715',
      '104099|Omeprazole|7646',
      '249220|Regular Insulin, Human|253182',
      '213441|NPH Insulin, Human|253181', '213441|Regular Insulin, Human|253182']

    update_rxterms_tables(rxterms_data, brand_data, ingredient_data)
    # A suppressed record that was not in the database before should still
    # not be there.
    assert_nil(DrugNameRoute.find_by_text('ROBINUL (Oral Pill)'))
    name_and_code = [
      ['AVIANE 28 (Pack)', '127||750268'],
      ['TONOCARD (Oral Pill)', '122||3'],
      ['Hydrocortisone/Neomycin (Topical)', '136||5492|7299'],
      ['NORFLEX XR (Oral Pill)', '122|XR|5'],
      ['LOSEC EC (Oral Pill)', '122|EC|6'],
      ['Insulin, human Regular U500 (Injectable)', '108|U500|253182'],
      ['HUMULIN 70/30 (Injectable)', '108|70/30|8']
    ]
    name_and_code.each do |nc|
      code = DrugNameRoute.find_by_text(nc[0]).code
      long_code = DrugNameRouteCode.find_by_code(code).long_code
      assert_equal(nc[1], long_code)
    end

    # Make sure the code field does not change during an update.
    drug_name = name_and_code[1][0]
    c = DrugNameRoute.find_by_text(drug_name).code
    update_rxterms_tables(rxterms_data, brand_data, ingredient_data)
    assert_equal(c, DrugNameRoute.find_by_text(drug_name).code)

    # Do something that causes the code to change, and confirm that it does.
    brand_data[1] = '102303|4'
    update_rxterms_tables(rxterms_data, brand_data, ingredient_data)
    assert_not_equal(c,
      DrugNameRoute.where(text: drug_name, code_is_old: false).take.code)
  end


  # Tests update_tables.
  def test_update_tables
    # The structure of this test parallels that of test_load_ingredients, except
    # that DSFs are checked too.
    rxterms_data = [
      '102166|197739|SBD|Glycopyrrolate 2 MG Oral Tablet [Robinul]|Oral Tablet|Glycopyrrolate 2 MG Oral Tablet|ROBINUL|ROBINUL (Oral Pill)|Oral Pill|Tabs|2 mg|||TRUE',
      '750268|748868|BPCK|{21 (Ethinyl Estradiol 0.02 MG / Levonorgestrel 0.1 MG Oral Tablet) / 7 (Inert Ingredients 1 MG Oral Tablet) } Pack [Aviane 28]|Pack|{21 (Ethinyl Estradiol 0.02 MG / Levonorgestrel 0.1 MG Oral Tablet) / 7 (Inert Ingredients 1 MG Oral Tablet) } Pack|AVIANE 28|AVIANE 28 (Pack)|Pack|Pack|mixed|||',
      '102303|198290|SBD|Tocainide 600 MG Oral Tablet [Tonocard]|Oral Tablet|Tocainide 600 MG Oral Tablet|TONOCARD|TONOCARD (Oral Pill)|Oral Pill|Tabs|600 mg|||',
      '106078||SCD|Hydrocortisone 10 MG/ML / Neomycin 5 MG/ML Topical Cream|Topical Cream|Hydrocortisone 10 MG/ML / Neomycin 5 MG/ML Topical Cream||Hydrocortisone/Neomycin (Topical)|Topical|Cream|10-5 mg/ml|||',
      '103171|562028|SBD|12 HR Orphenadrine 100 MG Extended Release Tablet [Norflex]|Extended Release Tablet|12 HR Orphenadrine 100 MG Extended Release Tablet|NORFLEX|NORFLEX XR (Oral Pill)|Oral Pill|12 Hrs XR Tabs|100 mg|||',
      '104099|198051|SBD|Omeprazole 20 MG Enteric Coated Capsule [Losec]|Enteric Coated Capsule|Omeprazole 20 MG Enteric Coated Capsule|LOSEC|LOSEC EC (Oral Pill)|Oral Pill|EC Caps|20 mg|||',
      '104098|198051|SBD|Omeprazole 40 MG Enteric Coated Capsule [Losec]|Enteric Coated Capsule|Omeprazole 40 MG Enteric Coated Capsule|LOSEC|LOSEC EC (Oral Pill)|Oral Pill|EC Caps|40 mg|||',
      '249220||SCD|Regular Insulin, Human 500 UNT/ML Injectable Solution|Injectable Solution|Regular Insulin, Human 500 UNT/ML Injectable Solution||Insulin, human Regular U500 (Injectable)|Injectable|Sol|500 unt/ml|||',
      '213441|311048|SBD|NPH Insulin, Human 70 UNT/ML / Regular Insulin, Human 30 UNT/ML Injectable Suspension [Humulin 70/30]|Injectable Suspension|NPH Insulin, Human 70 UNT/ML / Regular Insulin, Human 30 UNT/ML Injectable Suspension|HUMULIN 70/30|HUMULIN 70/30 (Injectable)|Injectable|Susp|70-30 unt/ml|||'
    ]
    brand_data = ['750268|2', '102303|3', '103171|5',
      '104099|6', '104098|6', '213441|8']
    ingredient_data = [
      '750268|Ethinyl Estradiol|4124', '750268|Inert Ingredients|748794',
         '750268|Levonorgestrel|6373',
      '102303|Tocainide|42359',
      '106078|Hydrocortisone|5492', '106078|Neomycin|7299',
      '103171|Orphenadrine|7715',
      '104099|Omeprazole|7646', '104098|Omeprazole|7646',
      '249220|Regular Insulin, Human|253182',
      '213441|NPH Insulin, Human|253181', '213441|Regular Insulin, Human|253182']
    update_rxterms_tables(rxterms_data, brand_data, ingredient_data)

    # Assignment of codes is tested in test_compute_dnr_codes, so we don't
    # do that here.
    # Check that DSFs were assigned correctly.
    dnr = DrugNameRoute.find_by_text('LOSEC EC (Oral Pill)')
    assert(!dnr.suppress)
    assert_equal(2, dnr.drug_strength_forms.size)
    assert_equal(['20 mg', '40 mg'],
      dnr.drug_strength_forms.collect {|s| s.strength}.sort)
    tonocard_code = DrugNameRoute.find_by_text('TONOCARD (Oral Pill)').code
    losec_code = DrugNameRoute.find_by_text('LOSEC EC (Oral Pill)').code
    norflex_code = DrugNameRoute.find_by_text('NORFLEX XR (Oral Pill)').code

    # Try suppressing one drug, changing the name of another, and changing the
    # codes of two (by changing brand codes).
    rxterms_data[1] += 'TRUE' # suppress AVIANE 28
    rxterms_data[2] =
      '102303|198290|SBD|Tocainide 600 MG Oral Tablet [Tonocard]|Oral Tablet|Tocainide 600 MG Oral Tablet|TONOCARD|TON of CARDs (Oral Pill)|Oral Pill|Tabs|600 mg|||'
    brand_data[3] = '104099|7' # Losec
    brand_data[4] = '104098|7' # Losec
    brand_data[2] = '103171|4' # Norflex
    old_dnr_count = DrugNameRoute.count
    update_rxterms_tables(rxterms_data, brand_data, ingredient_data)
    # There should be two more DNR records
    assert_equal(2, DrugNameRoute.count - old_dnr_count)
    # Check the suppressed drug
    assert_equal(true, DrugNameRoute.find_by_text('AVIANE 28 (Pack)').suppress)
    assert_equal(1, DrugNameRoute.where(text: "AVIANE 28 (Pack)").count)
    # Check the name change
    assert_equal(0, DrugNameRoute.where(text: "TONOCARD (Oral Pill)").count)
    assert_equal(1, DrugNameRoute.where(text: "TON of CARDs (Oral Pill)").count)
    assert_equal(tonocard_code,
      DrugNameRoute.where(text: 'TON of CARDs (Oral Pill)').take.code)
    # Check the result of a code change
    dnr = DrugNameRoute.where(text: 'LOSEC EC (Oral Pill)',
      code_is_old: false).take
    assert_equal(false, dnr.suppress)
    assert_equal("|#{losec_code}|", dnr.old_codes)
    dsf_ids = dnr.drug_strength_forms.collect{|s| s.id}.sort
    assert_not_equal(losec_code, dnr.code)
    dnr = DrugNameRoute.find_by_code(losec_code)
    assert_equal(true, dnr.suppress)
    assert_equal(true, dnr.code_is_old)
    old_dsf_ids = dnr.drug_strength_forms.collect{|s| s.id}.sort
    assert_not_equal(dsf_ids, old_dsf_ids)

    # Change the name of a DNR whose code changed
    # Change the code of a DNR whose name changed
    # Change a code back to its original value
    rxterms_data[5] = '104099|198051|SBD|Omeprazole 20 MG Enteric Coated Capsule [Losec]|Enteric Coated Capsule|Omeprazole 20 MG Enteric Coated Capsule|LOSEC|LOSEC TWO EC (Oral Pill)|Oral Pill|EC Caps|20 mg|||'
    rxterms_data[6] = '104098|198051|SBD|Omeprazole 40 MG Enteric Coated Capsule [Losec]|Enteric Coated Capsule|Omeprazole 40 MG Enteric Coated Capsule|LOSEC|LOSEC TWO EC (Oral Pill)|Oral Pill|EC Caps|40 mg|||',
    brand_data[1] = '102303|33' # TONOCARD
    brand_data[2] = '103171|5' # Norflex
    old_dnr_count = DrugNameRoute.count
    update_rxterms_tables(rxterms_data, brand_data, ingredient_data)
    # There should be one more DNR record
    assert_equal(1, DrugNameRoute.count - old_dnr_count)
    # Check the code-name change
    old_dnr = DrugNameRoute.find_by_text('LOSEC EC (Oral Pill)')
    new_dnr = DrugNameRoute.find_by_text('LOSEC TWO EC (Oral Pill)')
    assert_not_nil(old_dnr)
    assert_not_nil(new_dnr)
    assert_equal(false, new_dnr.code_is_old)
    # Chck the name-code change
    new_dnr = DrugNameRoute.where(text: 'TON of CARDs (Oral Pill)',
      suppress: false)
    old_dnr = DrugNameRoute.where(text: 'TON of CARDs (Oral Pill)',
      suppress: true)
    assert_equal(2, DrugNameRoute.where(text: "TON of CARDs (Oral Pill)").count)
    # Check the code that reverted
    new_dnr = DrugNameRoute.where(text: 'NORFLEX XR (Oral Pill)', suppress: false).take
    old_dnr = DrugNameRoute.where(text: 'NORFLEX XR (Oral Pill)', suppress: true).take
    assert_equal(false, new_dnr.code_is_old)
    assert_equal("|#{new_dnr.code}|#{old_dnr.code}|", new_dnr.old_codes)
    assert_equal(true, old_dnr.code_is_old)
    assert_equal("|#{new_dnr.code}|", old_dnr.old_codes)

    # Try a name reversion & code change for a record that went through
    # code,name changes (in two steps).  The code should be able to find the old
    # record.  This is not really important, but is a good exercise of the code.
    rxterms_data[5] = '104099|198051|SBD|Omeprazole 20 MG Enteric Coated Capsule [Losec]|Enteric Coated Capsule|Omeprazole 20 MG Enteric Coated Capsule|LOSEC|LOSEC EC (Oral Pill)|Oral Pill|EC Caps|20 mg|||'
    rxterms_data[6] = '104098|198051|SBD|Omeprazole 40 MG Enteric Coated Capsule [Losec]|Enteric Coated Capsule|Omeprazole 40 MG Enteric Coated Capsule|LOSEC|LOSEC EC (Oral Pill)|Oral Pill|EC Caps|40 mg|||',
    brand_data[3] = '104099|77' # Losec
    brand_data[4] = '104098|77' # Losec
    old_dnr_count = DrugNameRoute.count
    update_rxterms_tables(rxterms_data, brand_data, ingredient_data)
    # There should be 1 more DrugNameRoute.
    assert_equal(1, DrugNameRoute.count - old_dnr_count)
    oldest_dnr = DrugNameRoute.find_by_code_is_old_and_text(true,
      'LOSEC EC (Oral Pill)')
    assert_not_nil(oldest_dnr)
    old_dnr = DrugNameRoute.find_by_code_is_old_and_text(true,
      'LOSEC TWO EC (Oral Pill)')
    assert_not_nil(old_dnr)
    new_dnr = DrugNameRoute.find_by_code_is_old_and_text(false,
      'LOSEC EC (Oral Pill)')
    assert_equal("#{old_dnr.old_codes}#{old_dnr.code}|", new_dnr.old_codes)
    assert_not_equal(oldest_dnr.code, new_dnr.code)
    assert_not_equal(old_dnr.code, new_dnr.code)

    # Try updating a drug which previously did not have a code (for whatever
    # reason).
    DrugNameRoute.create!(:text=>'Test drug (Oral Pill)')
    assert_nil(DrugNameRoute.find_by_text('Test drug (Oral Pill)').code)
    update_rxterms_tables(['4|1|SBD|field4|field5|field6|field7|Test drug (Oral Pill)|Oral Pill|EC TEST Caps|20 mg|||'],
      ['4|2000'], [])
    assert_not_nil(DrugNameRoute.find_by_text('Test drug (Oral Pill)').code)
    assert_equal(1,
      DrugNameRoute.where('text="Test drug (Oral Pill)"').count)
    assert_equal(1, DrugStrengthForm.where(form: 'EC TEST Caps').count)
  end


  # Tests the padding of strength fields and the construction of the text
  # attribute.
  def test_pad_strength_fields
    dsf_list = [DrugStrengthForm.new(:strength=>'1 mg', :form=>'Tabs'),
      DrugStrengthForm.new(:strength=>'10 mg', :form=>'Tabs')]
    rxterms_updater = RxtermsUpdater.new
    rxterms_updater.pad_strength_fields(dsf_list)
    assert_equal(' 1 mg', dsf_list[0].strength)
    assert_equal('10 mg', dsf_list[1].strength)
    assert_equal(' 1 mg Tabs', dsf_list[0].text)
    assert_equal('10 mg Tabs', dsf_list[1].text)

    # Try a "pack"
    dsf_list = [DrugStrengthForm.new(:strength=>'mixed', :form=>'Pack')]
    rxterms_updater.pad_strength_fields(dsf_list)
    assert_equal('mixed', dsf_list[0].strength)
    assert_equal('mixed Pack', dsf_list[0].text)
  end


  def test_load_ingredients
    ingredient_data = ['102376|Dextrothyroxine|3292', '102377|Albuterol|435',
      '102378|Albuterol|435', '102166|Glycopyrrolate|4955',
      '102250|Hydrocortisone|5492', '102361|Isoproterenol|6054']
    ingred_file = write_ingredient_file(ingredient_data)
    rx_updater = RxtermsUpdater.new
    rx_updater.load_ingredients(ingred_file)
    # Check that we don't get duplicate ingredient entries when there is more
    # than one drug that uses the ingredient.
    assert_equal(5, RxtermsIngredient.count)
    # Check that the file loaded correctly
    check_ing('3292', 'Dextrothyroxine', true, false, '')
    assert_equal('Albuterol', RxtermsIngredient.find_by_ing_rxcui('435').name)

    # Now try letting one ingredient be obsolete, one getting its name changed,
    # and two getting their codes changed.
    ingredient_data = ['102376|Dextrothyroxine TWO|3292',
      '102166|Glycopyrrolate|4956', '102250|Hydrocortisone|5492',
      '102361|Isoproterenol|6055']
    ingred_file = write_ingredient_file(ingredient_data)
    rx_updater.load_ingredients(ingred_file)
    # Check the obsolete ingredient
    check_ing('435', 'Albuterol', false, false, '')
    # Check the modified name
    check_ing('3292', 'Dextrothyroxine TWO', true, false, '')
    assert_nil(RxtermsIngredient.find_by_name('Dextrothyroxine'))
    # Check the effect of the modified code
    check_ing('4955', 'Glycopyrrolate', false, true, '')
    check_ing('4956', 'Glycopyrrolate', true, false, '|4955|')
    # Confirm the other changed code was also updated
    assert_equal(2, RxtermsIngredient.where(name: "Isoproterenol").count)
    # Check the ingredient that stayed the same
    check_ing('5492', 'Hydrocortisone', true, false, '')

    # Change the code of an ing whose name changes
    # Change the name of an ing whose code changed.
    # Change a code back to its original value.
    ingredient_data = ['102376|Dextrothyroxine TWO|3293',
      '102166|Glycopyrrolate TWO|4956', '102250|Hydrocortisone|5492',
      '102361|Isoproterenol|6054']
    ingred_file = write_ingredient_file(ingredient_data)
    rx_updater.load_ingredients(ingred_file)
    # Check the code change on the changed name ingredient
    check_ing('3292', 'Dextrothyroxine TWO', false, true, '')
    check_ing('3293', 'Dextrothyroxine TWO', true, false, '|3292|')
    # Check the name change on the changed code ingredient
    check_ing('4955', 'Glycopyrrolate', false, true, '')
    check_ing('4956', 'Glycopyrrolate TWO', true, false, '|4955|')
    # Check the code that changed back
    check_ing('6055', 'Isoproterenol', false, true, '|6054|')
    check_ing('6054', 'Isoproterenol', true, false, '|6054|6055|')

    # Change a code back for an ing whose code changes and then its name changed
    # Change a name back for an ing whose name changed and then its code changed
    # Add a new record.
    # Reinstate the obsolete ingredient.
    ingredient_data = ['102376|Dextrothyroxine|3293',
      '102166|Glycopyrrolate TWO|4955', '102250|Hydrocortisone|5492',
      '102361|Isoproterenol|6054', '102377|Albuterol|435',
      '102303|Tocainide|42359'
      ]
    ingred_file = write_ingredient_file(ingredient_data)
    rx_updater.load_ingredients(ingred_file)
    # Check the name-code-name change
    check_ing('3292', 'Dextrothyroxine TWO', false, true, '')
    check_ing('3293', 'Dextrothyroxine', true, false, '|3292|')
    # Check the code-name-code change
    check_ing('4956', 'Glycopyrrolate TWO', false, true, '|4955|')
    check_ing('4955', 'Glycopyrrolate TWO', true, false, '|4955|4956|')
    # Check the new record
    check_ing('42359', 'Tocainide', true, false, '')
    # Check the reinstated ingredient
    check_ing('435', 'Albuterol', true, false, '')

    # Change a name (back) and code for an ing whose name changed
    # Change a name (back) and a code for an ing whose name changed and then its
    # code changed
    # Change a name (back) and a code for an ing whose code changed and then its
    # name changed
    # (In general, if the name and code changes at the same time, we can only
    # detect that by a manual review.  However, in the third of these cases,
    # we can detect it.)
    ingredient_data = ['96058|Nitrofurazone|7455', '96304|Primidone|8691',
      '94617|Lidocaine|6387']
    ingred_file = write_ingredient_file(ingredient_data)
    rx_updater.load_ingredients(ingred_file)
    ingredient_data = ['96058|Nitrofurazone TWO|7455',
      '96304|Primidone TWO|8691', '94617|Lidocaine|6388']
    ingred_file = write_ingredient_file(ingredient_data)
    rx_updater.load_ingredients(ingred_file)
    ingredient_data = ['96058|Nitrofurazone TWO|7455',
      '96304|Primidone TWO|8692', '94617|Lidocaine TWO|6388']
    ingred_file = write_ingredient_file(ingredient_data)
    rx_updater.load_ingredients(ingred_file)
    ingredient_data = ['96058|Nitrofurazone|7456',
      '96304|Primidone|8693', '94617|Lidocaine|6389']
    ingred_file = write_ingredient_file(ingredient_data)
    rx_updater.load_ingredients(ingred_file)

    # Check the name change followed by the name reversion and code change.
    # We have no record of the old name in this case, so it should be treated
    # like a new entry.  The old one should just be obsolete.
    check_ing('7455', 'Nitrofurazone TWO', false, false, '')
    check_ing('7456', 'Nitrofurazone', true, false, '')
    # Check the name,code change followed by the name reversion and code change.
    # Again, because the name changed first, we do not have a record of the
    # original name, and so the reversion will look like a completely new
    # entry.  (These two cases might not be ideal, but are the expected
    # behavior of the code.)
    check_ing('8691', 'Primidone TWO', false, true, '')
    check_ing('8692', 'Primidone TWO', false, false, '|8691|')
    check_ing('8693', 'Primidone', true, false, '')
    # Check the code,name change followed by the name reversion and code change.
    # In this case the original name is preserved by the first code change,
    # so it can be found.
    check_ing('6387', 'Lidocaine', false, true, '')
    check_ing('6388', 'Lidocaine TWO', false, true, '|6387|')
    check_ing('6389', 'Lidocaine', true, false, '|6387|6388|')
  end


  # Used by test_load_ingredients to check the fields of an RxtermsIngredient
  #
  # Parameters:
  # * rxcui - a string containing the RxCUI of the ingredient to be checked
  # * name - the name of the ingredient
  # * in_current_list - the expected value of the in_current_list field
  # * code_is_old - the expected value of the code_is_old field
  # * old_codes - the expected value of the old_codes field
  def check_ing(rxcui, name, in_current_list, code_is_old, old_codes)
    rx_ing = RxtermsIngredient.find_by_ing_rxcui(rxcui)
    assert_equal(name, rx_ing.name)
    assert_equal(in_current_list, rx_ing.in_current_list)
    assert_equal(code_is_old, rx_ing.code_is_old)
    assert_equal(old_codes, rx_ing.old_codes)
  end


  def test_compute_dnr_classes_and_ingredients
    DatabaseMethod.copy_development_tables_to_test(['data_classes',
      'classifications', 'list_descriptions', 'rxterms_ingredients', 'drug_routes'])

    drug_data = ['197436||SCD|Captopril 25 MG / Hydrochlorothiazide 15 MG Oral Tablet|Oral Tablet|Captopril 25 MG / Hydrochlorothiazide 15 MG Oral Tablet||Captopril/Hydrochlorothiazide (Oral Pill)|Oral Pill|Tabs|25-15 mg||HCTZ|',
      '211518|252972|SBD|Beclomethasone 0.084 MG/ACTUAT Nasal Spray [Vancenase AQ DS]|Nasal Spray|Beclomethasone 0.084 MG/ACTUAT Nasal Spray|VANCENASE AQ DS|VANCENASE AQ DS (Nasal)|Nasal|Spray|0.084 mg/puff|||',
      '213767|350713|SBD|Beclomethasone 0.042 MG/ACTUAT Inhalant Solution [Vanceril]|Inhalant Solution|Beclomethasone 0.042 MG/ACTUAT Inhalant Solution|VANCERIL|VANCERIL (Inhalant)|Inhalant|Sol|0.042 mg/puff|||',
      '102303|198290|SBD|Tocainide 600 MG Oral Tablet [Tonocard]|Oral Tablet|Tocainide 600 MG Oral Tablet|TONOCARD|TONOCARD (Oral Pill)|Oral Pill|Tabs|600 mg|||',
      '102361|282455|SBD|Isoproterenol 0.2 MG/ML Injectable Solution [Isuprel HCl]|Injectable Solution|Isoproterenol 0.2 MG/ML Injectable Solution|ISUPREL HCL|ISUPREL HCL (Injectable)|Injectable|Sol|0.2 mg/ml|||'
      ]
    brand_data = ['211518|1', '213767|2', '102303|3', '102361|4']

    ingredient_data = ['197436|Captopril|1998', '197436|Hydrochlorothiazide|5487',
      '211518|Beclomethasone|1347', '213767|Beclomethasone|1347',
      '102303|Tocainide|42359'
      ]

    update_rxterms_tables(drug_data, brand_data, ingredient_data)

    # Captopril/Hydrochlorothiazide (Oral Pill)
    dnr = DrugNameRoute.find_by_text('Captopril/Hydrochlorothiazide (Oral Pill)')
    dnr_classes = Set.new(dnr.drug_class_codes[1..-2].split(/\|/))
    expected_classes = Set.new
    expected_classes << '1' # Ace Inhibitors
    expected_classes << '9' # antihypertensive
    expected_classes << '27' # Thiazides

    assert_equal(expected_classes, dnr_classes)
    dnr_ingredients = Set.new(dnr.ingredient_rxcuis[1..-2].split(/\|/))
    expected_ings = Set.new
    expected_ings << '1998' # Cataporil
    expected_ings << '5487' # Hydrochlorothiazide
    assert_equal(expected_ings, dnr_ingredients)

    # VANCENASE AQ DS (Nasal)
    dnr = DrugNameRoute.find_by_text('VANCENASE AQ DS (Nasal)')
    # This one should not have classes, because it is route "Nasal", which
    # is neither "systemic" nor "mixed".
    assert_equal(nil, dnr.drug_class_codes)
    assert_equal('|1347|', dnr.ingredient_rxcuis) # Beclomethasone

    # VANCERIL (Inhalant)
    dnr = DrugNameRoute.find_by_text('VANCERIL (Inhalant)')
    assert_equal('|21|', dnr.drug_class_codes) # Glucocorticoids
    assert_equal('|1347|', dnr.ingredient_rxcuis) # Beclomethasone

    # TONOCARD (Oral Pill)
    # The ingredients for this are not in the ingredient_names data, so there
    # should not be classes.
    dnr = DrugNameRoute.find_by_text('TONOCARD (Oral Pill)')
    assert_equal(nil, dnr.drug_class_codes)
    assert_equal('|42359|', dnr.ingredient_rxcuis) # Tocainide

    # ISUPREL HCL (Injectable)
    # The ingredient for this is not in the ingredient_names data, so there
    # should not be classes.  Also, it is not in the "ingredient_data" list,
    # so there should not be ingredients.
    dnr = DrugNameRoute.find_by_text('ISUPREL HCL (Injectable)')
    assert_equal(nil, dnr.drug_class_codes)
    assert_equal(nil, dnr.ingredient_rxcuis)

  end

  # Tests the method assign_route_codes
  def test_assign_route_codes
    assert_equal(0, DrugNameRouteCode.count)
    DatabaseMethod.copy_development_tables_to_test(['drug_classes',
      'ingredient_names', 'drug_classes_ingredient_names', 'drug_routes'])
    assert_equal(0, DrugNameRouteCode.count)
    update_rxterms_tables([
      '197436||SCD|Captopril 25 MG Oral Tablet|Oral Tablet|Captopril 25 MG Oral Tablet||Captopril (Oral Pill)|Oral Pill|Tabs|25-15 mg||HCTZ|',
      '197437||SCD|OtherGeneric 25 MG Oral Tablet|Oral Tablet|OtherGeneric 25 MG Oral Tablet||OtherGeneric (Oral Pill)|Oral Pill|Tabs|25-15 mg||HCTZ|',
      '211518|197436|SBD|Beclomethasone 0.084 MG [Vancenase AQ DS]|Nasal Spray|Beclomethasone 0.084 MG|VANCENASE AQ DS|VANCENASE AQ DS (Nasal)|Nasal|Spray|0.084 mg/puff|||TRUE',
      '211519|197437|SBD|Beclomethasone 0.09 MG [Vancenase AQ DS]|Nasal Spray|Beclomethasone 0.09 MG|VANCENASE AQ DS|VANCENASE AQ DS (Nasal)|Nasal|Spray|0.09 mg/puff|||',
      '213767|197437|SBD|Beclomethasone 0.042 MG/ACTUAT Inhalant Solution [Vanceril]|Inhalant Solution|Beclomethasone 0.042 MG/ACTUAT Inhalant Solution|VANCERIL|VANCERIL (Inhalant)|Inhalant|Sol|0.042 mg/puff|||TRUE',
      '213768|197437|SBD|Beclomethasone 0.05 MG/ACTUAT Inhalant Solution [Vanceril]|Inhalant Solution|Beclomethasone 0.05 MG/ACTUAT Inhalant Solution|VANCERIL|VANCERIL (Inhalant)|Inhalant|Sol|0.05 mg/puff|||TRUE',
      '645745|603725|SBD|Brompheniramine 1.6 MG/ML Extended Release Suspension [Tanacof]|Extended Release Suspension|Brompheniramine 1.6 MG/ML Extended Release Suspension|TANACOF|TANACOF XR (Oral Liquid)|Oral Liquid|XR Susp|8 MG/5ML|||',
      ],
      ['211518|1', '211519|2', '213767|3', '213768|4', '645745|5'])

    dnr = DrugNameRoute.find_by_text('Captopril (Oral Pill)')
    assert_equal('|122|RC1|', dnr.route_codes)
    # Test that it works for a second case of the same route string.
    dnr = DrugNameRoute.find_by_text('OtherGeneric (Oral Pill)')
    assert_equal('|122|RC1|', dnr.route_codes)
    dnr = DrugNameRoute.find_by_text('VANCENASE AQ DS (Nasal)')
    assert_equal('|114|RC2|', dnr.route_codes)
  end


  # Tests the method assign_generic_dnrs
  def test_assign_generic_dnrs
    update_rxterms_tables([
      '197436||SCD|Captopril 25 MG Oral Tablet|Oral Tablet|Captopril 25 MG Oral Tablet||Captopril (Oral Pill)|Oral Pill|Tabs|25-15 mg||HCTZ|',
      '197437||SCD|OtherGeneric 25 MG Oral Tablet|Oral Tablet|OtherGeneric 25 MG Oral Tablet||OtherGeneric (Oral Pill)|Oral Pill|Tabs|25-15 mg||HCTZ|',
      '211518|197436|SBD|Beclomethasone 0.084 MG [Vancenase AQ DS]|Nasal Spray|Beclomethasone 0.084 MG|VANCENASE AQ DS|VANCENASE AQ DS (Nasal)|Nasal|Spray|0.084 mg/puff|||TRUE',
      '211519|197437|SBD|Beclomethasone 0.09 MG [Vancenase AQ DS]|Nasal Spray|Beclomethasone 0.09 MG|VANCENASE AQ DS|VANCENASE AQ DS (Nasal)|Nasal|Spray|0.09 mg/puff|||',
      '213767|197437|SBD|Beclomethasone 0.042 MG/ACTUAT Inhalant Solution [Vanceril]|Inhalant Solution|Beclomethasone 0.042 MG/ACTUAT Inhalant Solution|VANCERIL|VANCERIL (Inhalant)|Inhalant|Sol|0.042 mg/puff|||TRUE',
      '213768|197437|SBD|Beclomethasone 0.05 MG/ACTUAT Inhalant Solution [Vanceril]|Inhalant Solution|Beclomethasone 0.05 MG/ACTUAT Inhalant Solution|VANCERIL|VANCERIL (Inhalant)|Inhalant|Sol|0.05 mg/puff|||TRUE',
      '645745|603725|SBD|Brompheniramine 1.6 MG/ML Extended Release Suspension [Tanacof]|Extended Release Suspension|Brompheniramine 1.6 MG/ML Extended Release Suspension|TANACOF|TANACOF XR (Oral Liquid)|Oral Liquid|XR Susp|8 MG/5ML|||',
      ],
      ['211518|1', '211519|2', '213767|3', '213768|4', '645745|5'])

    # Test that a non-suppressed record is preferred in selecting a generic.
    dnr = DrugNameRoute.find_by_text('VANCENASE AQ DS (Nasal)')
    generic_dsf2 = DrugNameRoute.find_by_text('OtherGeneric (Oral Pill)')
    assert_equal(generic_dsf2.id, dnr.generic_id)

    # Test that if all records are suppressed, a generic is still assigned.
    dnr = DrugNameRoute.find_by_text('VANCENASE AQ DS (Nasal)')
    assert_equal(generic_dsf2.id, dnr.generic_id)

    # Test the case where the generic record is missing
    dnr = DrugNameRoute.find_by_text('TANACOF XR (Oral Liquid)')
    assert(dnr.generic_id.blank?)

    # Test that a generic drug is not assigned a generic.
    assert(generic_dsf2.generic_id.blank?)
  end


  # Used by the test methods for RxtermsUpdater.update_tables to create a
  # temporary file containing the given data and call the update_tables method.
  #
  # Parameters:
  # * rxterms_data - an array of lines of data (excluding the header row) for
  #   the test version of the RxTerms update file.
  # * brand_data - an array of lines of data (excluding the header row)
  #   for the RxTerms brand name file.
  # * ingredient_data - an array of lines of data (excluding the header row)
  #   for the RxTerms ingredient file.  (This is optional).
  def update_rxterms_tables(rxterms_data, brand_data, ingredient_data=[])
    rxterms_updater = RxtermsUpdater.new
    file = Tempfile.new('drug_name_route_test')
    # Write the header row, and then the data lines
    file.write('RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED')
    file.write("\n")
    rxterms_data.each do |line|
      file.write(line)
      file.write("\n")
    end
    file.close

    ing_file_path = write_ingredient_file(ingredient_data)
    brand_file_path = write_brand_file(brand_data)

    rxterms_updater.update_tables(file.path, ing_file_path, brand_file_path)
  end


  # Creates a temporary file for the given ingredient data.
  #
  # Parameters:
  # * ingredient_data - an array of lines of data (excluding the header row)
  #   for the RxTerms ingredient file.
  #
  # Returns:  the path name of the file
  def write_ingredient_file(ingredient_data)
    ing_file = Tempfile.new('rxterms_ing_test')
    ing_file.write('RXCUI|INGREDIENT|ING_RXCUI')
    ing_file.write("\n")
    ingredient_data.each do |line|
      ing_file.write(line)
      ing_file.write("\n")
    end
    ing_file.close
    @ing_file = ing_file # cache the reference so the Tempfile does not get deleted
    return ing_file.path
  end

  # Creates a temporary file for the given brand name data.
  #
  # Parameters:
  # * ingredient_data - an array of lines of data (excluding the header row)
  #   for the RxTerms ingredient file.
  #
  # Returns:  the path name of the file
  def write_brand_file(brand_data)
    brand_file = Tempfile.new('rxterms_brand_test')
    brand_file.write('RXCUI|BN_RXCUI')
    brand_file.write("\n")
    brand_data.each do |line|
      brand_file.write(line)
      brand_file.write("\n")
    end
    brand_file.close
    @brand_file = brand_file # cache the reference so the Tempfile does not get deleted
    return brand_file.path
  end
end
