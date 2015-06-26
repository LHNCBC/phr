require 'test_helper'

class VaccineTest < ActiveSupport::TestCase
  fixtures :vaccines

  # Tests the get_list_items method in HasShortList
  def test_get_list_items
    # Try getting a full list
    list = Vaccine.get_list_items(nil, nil, ['id desc']);
    assert_equal(14, list.size, 'full list size')
    assert_equal('Flu shot', list[13].synonyms)

    # Try getting a list using just a condition
    list = Vaccine.get_list_items(nil, nil, nil, 'id=-11')
    assert_equal(1, list.size, 'condition')
    assert_equal('Polio vaccine, injected - IPV', list[0].name)
  end
end
