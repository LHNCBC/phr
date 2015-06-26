require 'test_helper'
require 'util'

# Tests code in the util.rb library.
class UtilTest < ActiveSupport::TestCase

  def test_integer?
    assert_equal(true, Util.integer?('0'))
    assert_equal(true, Util.integer?('1'))
    assert_equal(true, Util.integer?('-1'))
    assert_equal(true, Util.integer?('+10'))
    assert_equal(true, Util.integer?('200'))
    assert_equal(true, Util.integer?('-23'))
    assert_equal(false, Util.integer?('-0'))
    assert_equal(false, Util.integer?('+0'))
    assert_equal(false, Util.integer?('01'))
    assert_equal(false, Util.integer?('abc'))
  end

  def test_float?
    # Repeat the integer tests
    assert_equal(false, Util.float?('0'))
    assert_equal(false, Util.float?('1'))
    assert_equal(false, Util.float?('-1'))
    assert_equal(false, Util.float?('+10'))
    assert_equal(false, Util.float?('200'))
    assert_equal(false, Util.float?('-23'))
    assert_equal(false, Util.float?('-0'))
    assert_equal(false, Util.float?('+0'))
    assert_equal(false, Util.float?('01'))
    assert_equal(false, Util.float?('abc'))

    assert_equal(true, Util.float?('0.123'))
    assert_equal(true, Util.float?('-0.123'))
    assert_equal(true, Util.float?('+0.123'))
    assert_equal(true, Util.float?('-.123'))
    assert_equal(true, Util.float?('+.123'))
    assert_equal(true, Util.float?('.123'))
    assert_equal(true, Util.float?('52.123'))
    assert_equal(true, Util.float?('+52.123'))
    assert_equal(true, Util.float?('-52.123'))
    assert_equal(false, Util.float?('00.123'))
    assert_equal(false, Util.float?('-00.123'))
    assert_equal(false, Util.float?('+00.123'))
  end


  def test_array_to_english
    assert_equal('', [].to_english)
    assert_equal('one', ['one'].to_english)
    assert_equal('one and two', ['one', 'two'].to_english)
    assert_equal('one, two, and three', ['one', 'two', 'three'].to_english)
    assert_equal('one, two, three, and four', ['one', 'two', 'three', 'four'].to_english)
  end


  def test_create_demo_accounts
    Util.create_demo_accounts(2, DEMO_SAMPLE_DATA_FILES)
    Util.create_demo_accounts(1, ['db/demo_profile_4.yml']) # 4 is Daisy duck, which is big
  end
end
