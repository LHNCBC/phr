require 'test_helper'
class DrugNameRouteTest < ActiveSupport::TestCase
  fixtures :drug_name_routes, :drug_strength_forms
  fixtures :rxterms_ingredients
  fixtures :clinical_maps

  def setup
    # Turn off ferret indexing.  We're not testing Ferret searching here,
    # but we are creating and deleting DNRs.
    DrugNameRoute.disable_ferret
    Classification.destroy_all
  end
  
  def teardown
    DrugNameRoute.enable_ferret
  end
  
  def test_find_record_data
    results = DrugNameRoute.find_record_data(
      {:code=>'10000', :text=>'Aminobenzoate (Oral-pill)'},
      ['id', 'route'])
    assert_equal(2, results.size(), 'results size check')
    assert_equal(-2, results['id'])
    assert_equal('Oral-pill', results['route'])
  end
  
  def test_patient_route
    assert_equal('By Mouth', drug_name_routes(:one).patient_route)
    assert_nil(drug_name_routes(:bad_route).patient_route)
  end
  
  def test_clinician_route
    assert_equal('PO', drug_name_routes(:one).clinician_route)
    assert_nil(drug_name_routes(:bad_route).clinician_route)
  end
  
  def test_strength_form_array
    dnr = drug_name_routes(:strength_form_array_test)
    assert_equal([[['Caps', '50 mg'],['Tabs', '60 mg']], [501, 502]],
      dnr.strength_form_array)
  end

  
  def test_ingredient_names
    assert_equal('|Amobarbital|Secobarbital|',
      drug_name_routes(:one).ingredient_names)
    assert_equal('|bbb|aaa|ccc|',
      drug_name_routes(:ing_name_order_test).ingredient_names)
  end

  
  def test_drug_class_names
    root_id="12345"
    drug_class = Classification.create!({:class_name=>'Drug', :class_code=>'drug',
       :list_description_id=>171, :class_type_id=>root_id})
    drug_class.subclasses.create!({:class_name=>'zclass1', :class_code=>'1',
        :list_description_id=>171, :sequence=>1, :class_type_id => drug_class.id})
    drug_class.subclasses.create!({:class_name=>'aclass2', :class_code=>'2',
       :list_description_id=>171,:sequence=>2, :class_type_id => drug_class.id})
    RxtermsIngredient.create!({:name=>'A', :ing_rxcui=>'1', :in_current_list=>1})
    RxtermsIngredient.create!({:name=>'Z', :ing_rxcui=>'2', :in_current_list=>1})
    RxtermsIngredient.create!({:name=>'B', :ing_rxcui=>'3', :in_current_list=>1})
    dnr = DrugNameRoute.create!({:text=>'D1', :code=>'10',
      :drug_class_codes=>'|1|2|', :ingredient_rxcuis=>'|1|2|3|'})
    assert_equal('|zclass1|aclass2|', dnr.drug_class_names)
    dnr = DrugNameRoute.create!({:text=>'D2', :code=>'11',
      :drug_class_codes=>'|2|', :ingredient_rxcuis=>'|3|2|1|'})
    assert_equal('|aclass2|', dnr.drug_class_names)
  end
end
