require 'test_helper'

class PhrDrugTest < ActiveSupport::TestCase

  def test_drug_validation
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
      'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
      'text_list_items'])

    p = PhrDrug.new
    p.valid?
    assert(p.errors[:name_and_route].length > 0)
    assert(p.errors[:drug_use_status].length > 0)

    p.name_and_route = 'one'
    p.drug_use_status_C = 'DRG-A'
    assert p.valid?

    p.drug_start = 'asdf'
    p.valid?
    assert(p.errors['drug_start'].length > 0)
  end


  def test_build_route_code_regex
    re = PhrDrug.build_route_code_regex('|23|RC2|')
    assert '|12|RC1|' !~ re
    assert '|23|RC2|' =~ re
    assert '|12|RC2|' =~ re

    re = PhrDrug.build_route_code_regex('|23|RC1|')
    assert '|12|RC1|' =~ re
    assert '|12|RC3|' =~ re
    assert '|12|RC2|' !~ re

    re = PhrDrug.build_route_code_regex('|23|RC3|')
    assert '|12|RC1|' =~ re
    assert '|12|RC3|' =~ re
    assert '|12|RC2|' !~ re
  end


  def test_dup_check
    # Note:  The tests here are ported from controlled_edit_table_test.html's
    # testDrugConflictCheck.  If you update this, update that one too.
    user = create_test_user
    DrugNameRoute.delete_all
    [{'drug_routes'=>'|Oral-pill|Systemic|',
      'name_and_route'=>'Warfarin (Oral-pill)', 'drug_classes_C'=>'|19|',
      'drug_ingredients'=>'|Warfarin|', 'drug_routes_C'=>'|R11|RC1|',
      'name_and_route_C'=>'13423', 'drug_ingredients_C'=>'|11289|',
      'drug_classes'=>'|Coumadins|'},
     {'drug_routes'=>'|Oral-pill|Systemic|',
      'name_and_route'=>'AUGMENTIN (Oral-pill)',
      'drug_ingredients'=>'|Clavulanate|Amoxicillin|',
      'drug_routes_C'=>'|R11|RC1|', 'name_and_route_C'=>'9375',
      'drug_ingredients_C'=>'|48203|723|'},
     {'drug_routes'=>'|Oral-pill|Systemic|',
      'name_and_route'=>'Amoxicillin/Clavulanate (Oral-pill)',
      'drug_ingredients'=>'|Clavulanate|Amoxicillin|',
      'drug_routes_C'=>'|R11|RC1|', 'name_and_route_C'=>'4843',
      'drug_ingredients_C'=>'|48203|723|'},
     {'drug_routes'=>'|Oral-liquid|Systemic|',
      'name_and_route'=>'Amoxicillin/Clavulanate (Oral-liquid)',
      'drug_ingredients'=>'|Clavulanate|Amoxicillin|',
      'drug_routes_C'=>'|R9|RC1|', 'name_and_route_C'=>'2878',
      'drug_ingredients_C'=>'|48203|723|'},
     {'drug_routes'=>'|Injectable|Systemic|',
      'name_and_route'=>'Clavulanate/Ticarcillin (Injectable)',
      'drug_ingredients'=>'|Ticarcillin|Clavulanate|',
      'drug_routes_C'=>'|R3|RC1|', 'name_and_route_C'=>'9682',
      'drug_ingredients_C'=>'|10591|48203|'},
     {'drug_routes'=>'|Oral-liquid|Systemic|',
      'name_and_route'=>'Amoxicillin (Oral-liquid)',
      'drug_ingredients'=>'|Amoxicillin|',
      'drug_routes_C'=>'|R9|RC1|', 'name_and_route_C'=>'12370',
      'drug_ingredients_C'=>'|723|'},
     {'drug_routes'=>'|Oral-liquid|Systemic|',
      'name_and_route'=>'Amoxicillin/Clavulante/Chocoloate (Oral-liquid)',
      'drug_ingredients'=>'|Clavulanate|Amoxicillin|Chocolate',
      'drug_routes_C'=>'|R9|RC1|', 'name_and_route_C'=>'X1',
      'drug_ingredients_C'=>'|48203|723|1234567'},
     {'drug_routes'=>'',
      'name_and_route'=>'Something not in the list',
      'drug_ingredients'=>'',
      'drug_routes_C'=>'', 'name_and_route_C'=>'',
      'drug_ingredients_C'=>''},
     {'drug_routes'=>'|Oral-pill|Systemic|',
      'name_and_route'=>'AUGMENTIN XR (Oral-pill)',
      'drug_ingredients'=>'|Clavulanate|Amoxicillin|',
      'drug_routes_C'=>'|R11|RC1|', 'name_and_route_C'=>'X2',
      'drug_ingredients_C'=>'|48203|723|'}
     ].each_with_index do |data_row, data_index|

       # Create ingredients
       ing_names = PredefinedField.parse_set_value(data_row['drug_ingredients'])
       ing_codes = PredefinedField.parse_set_value(data_row['drug_ingredients_C'])
       ing_names.each_with_index do |name, i|
         RxtermsIngredient.create!(:name=>name, :ing_rxcui=>ing_codes[i])
       end

       # Create DrugRoutes
       route_names = PredefinedField.parse_set_value(data_row['drug_routes'])
       route_codes = PredefinedField.parse_set_value(data_row['drug_routes_C'])
       route_names.each_with_index do |name, i|
         if !DrugRoute.find_by_name(name)
           DrugRoute.create(:name=>name, :code=>route_codes[i])
         end
       end
       
       # Create DrugNameRoute
       drug_name = data_row['name_and_route']
       if !(code=data_row['name_and_route_C']).blank?
         if !DrugNameRoute.find_by_text(drug_name)
           DrugNameRoute.create!(:text=>drug_name,
             :code=>code,
             :ingredient_rxcuis=>data_row['drug_ingredients_C'],
             :route_codes=>data_row['drug_routes_C'])
         end
       end

      # Create PhrDrug
      PhrDrug.create!(:profile_id=>user.profiles.first.id,
        :record_id=>data_index,
        :latest=>true, :name_and_route_C=>data_row['name_and_route_C'],
        :name_and_route=>drug_name, :drug_use_status_C=>'DRG-A')
    end

    # Duplicate AUGMENTIN
    phr_drug = PhrDrug.new(:profile_id=>user.profiles.first.id,
      :record_id=>20,
      :latest=>true, :name_and_route_C=>'9375',
      :name_and_route=>'AUGMENTIN (Oral-pill)')
    
    warnings = phr_drug.dup_check
    assert_equal(4, warnings.length,
       'dup_check should return an array of length 4')
    assert_equal(1, warnings[0].length, 'There should be one duplicate drug')
    assert_equal(phr_drug.name_and_route, warnings[0][0])
    assert_equal(1, warnings[1].length,
       'There should be 1 equivalent drugs with the same route')
    assert_equal('Amoxicillin/Clavulanate (Oral-pill)', warnings[1][0])
    assert_equal(2, warnings[2].length,
       'There should be 2 equivalent drugs with a similar route')
    # Compare the names as sets to avoid requiring a particular order
    assert_equal(Set.new(['Amoxicillin/Clavulanate (Oral-liquid)',
      'AUGMENTIN XR (Oral-pill)']), Set.new([warnings[2][0], warnings[2][1]]))

    assert_equal(3, warnings[3].length,
       'There should be 3 shared ingredient drugs')
    # Compare the names as sets to avoid requiring a particular order
    assert_equal(Set.new(['Clavulanate/Ticarcillin (Injectable)',
      'Amoxicillin (Oral-liquid)',
      'Amoxicillin/Clavulante/Chocoloate (Oral-liquid)']),
      Set.new([warnings[3][0][0], warnings[3][1][0], warnings[3][2][0]]))
    # Check the shared ingredients
    0.upto(2) do |i|
      name = warnings[3][i][0]
      shared_ing = warnings[3][i][1]
      if name == 'Clavulanate/Ticarcillin (Injectable)'
        assert_equal(['Clavulanate'], shared_ing)
      elsif name == 'Amoxicillin (Oral-liquid)'
        assert_equal(['Amoxicillin'], shared_ing)
      else # 'Amoxicillin/Clavulante/Chocoloate (Oral-liquid)'
        assert_equal(Set.new(['Clavulanate', 'Amoxicillin']),
          Set.new(shared_ing))
      end
    end

    # Test that the matches are not reported if the entered drug is inactive
    phr_drug.drug_use_status_C = 'DRG-I'
    assert_nil(phr_drug.dup_check,
      'Nothing should be returned for a new but inactive drug');

    # Test that the matches are not reported if the other drugs are inactive
    phr_drug.drug_use_status_C = '' # so it will be treated as active
    phr_drug.profile.phr_drugs.each {|d| d.drug_use_status_C = "DRG-I"; d.save!}
    assert_nil(phr_drug.dup_check,
      'Nothing should be returned if the other drugs are inactive');

    # Now make one active again
    d = phr_drug.profile.phr_drugs.where(
         name_and_route: 'Amoxicillin (Oral-liquid)').first
    d.drug_use_status_C = 'DRG-A'
    d.save!
    phr_drug.profile.phr_drugs.reload # reload the profile's phr_drugs

    warnings = phr_drug.dup_check

    assert_not_nil(warnings)
    assert_equal(4, warnings.length,
      'drugConflictCheck should again return an array of length 4');
    assert_equal(0, warnings[0].length, '0 duplicates');
    assert_equal(0, warnings[1].length, '0 equivalent, same route drugs');
    assert_equal(0, warnings[2].length, '0 equilvalent, similar route drugs');
    assert_equal(1, warnings[3].length, '1 shared ingredient drug');

    # Test what happens when drugs are present that are not in the list.
    PhrDrug.delete_all
    ['Something not in the list', 'A different something not in the list'
    ].each do |text|
      PhrDrug.create!(:latest=>1, :name_and_route=>text,
       :profile_id=>user.profiles.first.id,  :drug_use_status_C=>'DRG-A')
    end
    phr_drug = PhrDrug.new(:latest=>1, :profile_id=>user.profiles.first.id,
      :name_and_route=>'Something not in the list')
    warnings = phr_drug.dup_check
    assert_equal(4, warnings.length, 'non list drugConflictCheck should return an '+
      'array of length 4');
    assert_equal(1, warnings[0].length, 'non list drugConflictCheck: 1 duplicate');
    assert_equal(0, warnings[1].length, 'non list: 0 equivalent, same route drugs');
    assert_equal(0, warnings[2].length, 'non list: 0 equilvalent, similar route drugs');
    assert_equal(0, warnings[3].length, 'non list: 0 shared ingredient drug')
  end


  def test_has_multi_dose_ing
    d = DrugNameRoute.create!("route"=>"Oral Pill", "suppress"=>false,
      "drug_class_codes"=>"|19|", "code"=>"24931", "generic_id"=>611637,
      "text"=>"JANTOVEN (Oral Pill)", "synonyms"=>nil, "id"=>610753,
      "route_codes"=>"|122|RC1|", "old_codes"=>"", "is_brand"=>true,
      "ingredient_rxcuis"=>"|11289|", "code_is_old"=>false)
    RxtermsIngredient.create!("name"=>"Warfarin", "ing_rxcui"=>"11289",
      "id"=>39709, "old_codes"=>"", "code_is_old"=>false,
      "in_current_list"=>true)

    user = create_test_user
    p = PhrDrug.new(:profile_id=>user.profiles.first.id, :record_id=>1,
      :latest=>true, :name_and_route_C=>d.code)
    assert(p.has_multi_dose_ing)

    d = DrugNameRoute.create!("route"=>"Nasal", "suppress"=>true,
      "drug_class_codes"=>nil, "code"=>"16178", "generic_id"=>609408,
      "text"=>"SINEX (Nasal)", "synonyms"=>nil, "id"=>602040,
      "route_codes"=>"|R7|RC2|", "old_codes"=>"", "is_brand"=>true,
      "ingredient_rxcuis"=>"|8163|", "code_is_old"=>true)
    RxtermsIngredient.create!("name"=>"Phenylephrine", "ing_rxcui"=>"8163",
      "id"=>38047, "old_codes"=>"", "code_is_old"=>false,
      "in_current_list"=>true)
    p = PhrDrug.new(:profile_id=>user.profiles.first.id, :record_id=>1,
      :latest=>true, :name_and_route_C=>d.code)
    assert !p.has_multi_dose_ing
  end
end
