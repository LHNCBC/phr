require 'test_helper'

class PredefinedFieldTest < ActiveSupport::TestCase
  fixtures :predefined_fields

  # Tests make_set_value
  def test_make_set_value
    assert_equal('|1|2|', PredefinedField.make_set_value([2, 1]))
    assert_equal('|1|2|', PredefinedField.make_set_value([2, 1], true))
    assert_equal('|2|1|', PredefinedField.make_set_value([2, 1], false))
    assert_equal('|one|three|two|',
      PredefinedField.make_set_value(['one', 'two', 'three']))
    assert_equal('|one|two|three|',
      PredefinedField.make_set_value(['one', 'two', 'three'], false))
  end
end
