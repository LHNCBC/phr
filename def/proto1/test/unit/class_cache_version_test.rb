require 'test_helper'

class ClassCacheVersionTest < ActiveSupport::TestCase
  def setup
    @form = Form.create(:form_name => "test_form")
  end

  def test_latest_version
    assert @form.valid?, "testing form is not valid."

    # When therer is nothing in the table, it will return 0
    actual = 0
    expected = ClassCacheVersion.latest_version(RuleAndFieldDataCache, @form)
    assert_equal  expected, actual 

    # "Update" method will increment version by 1
    ClassCacheVersion.update(RuleAndFieldDataCache, @form)

    actual = 1
    expected = ClassCacheVersion.latest_version(RuleAndFieldDataCache, @form)
    assert_equal  expected, actual 
  end
end
