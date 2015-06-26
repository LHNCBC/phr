require 'test_helper'

class DrugStrengthFormTest < ActiveSupport::TestCase
  fixtures :drug_strength_forms
  fixtures :text_lists
  fixtures :text_list_items

  # Replace this with your real tests.
  def test_amount_list
    s = drug_strength_forms('aminobenzoate-pill')
    expected = ["1/2 Tsp", "1 Tsp"]
    assert_equal(expected, s.amount_list)
  end
end
