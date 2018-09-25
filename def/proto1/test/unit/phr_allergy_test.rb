require 'test_helper'

class PhrAllergyTest < ActiveSupport::TestCase

  def test_allergy_validation
    # Allergy validation populates list values from code fields.  Make sure
    # that works.
    # This used to also test the population of allergy_type and allergy_type_C,
    # but those fields have since been removed.
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
      'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
      'text_list_items'])
    p = PhrAllergy.new(:allergy_name_C=>'FOOD-9')
    assert(p.valid?)
    assert_equal('FOOD-9', p.allergy_name_C)
    assert_equal('Peanut', p.allergy_name)

    # Set both the code and the value
    p = PhrAllergy.new(:allergy_name_C=>'FOOD-9', :allergy_name=>'Peanut')
    p.valid?
    assert_equal('FOOD-9', p.allergy_name_C)
    assert_equal('Peanut', p.allergy_name)

    # Set a non-standard value
    p = PhrAllergy.new(:allergy_name=>'Ice Cream')
    p.valid?
    assert_nil(p.allergy_name_C)
    assert_equal('Ice Cream', p.allergy_name)

    # Set all the values, and check blank codes (should be like nil)
    p = PhrAllergy.new(:allergy_name=>'Ice Cream', :allergy_name_C=>'')
    p.valid?
    assert_nil(p.allergy_name_C)
    assert_equal('Ice Cream', p.allergy_name)

    # Test validation of the reaction field.  The process should populate
    # the name field from a code value.
    p.reaction_C = 'AL-REACT-23'
    p.valid?
    assert_equal('AL-REACT-23', p.reaction_C)
    assert_equal('Loss of consciousness', p.reaction)
  end
end
