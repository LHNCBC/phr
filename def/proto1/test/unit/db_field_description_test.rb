require 'test_helper'

class DbFieldDescriptionTest < ActiveSupport::TestCase
  def test_max_field_length
    DatabaseMethod.copy_development_tables_to_test(
      ['db_table_descriptions', 'db_field_descriptions'], false)
    dbf = DbFieldDescription.find_by_data_column('drug_strength_form')
    assert_equal(255, dbf.max_field_length)
  end
  
  def test_abs_max_as_date
    dbf = DbFieldDescription.new(:abs_max=>'t')
    now = Time.now
    start_of_tomorrow = (now + 86400).to_date.to_time
    assert_equal(start_of_tomorrow, dbf.abs_max_as_date)
    dbf.abs_max = 't-50Y'
    # Careful.  Dates do not satisfy the commutative property of addition:
    # (2014/2/28 + 1 day) - 50 years = 1964/3/1
    # (2014/2/28 - 50 years) + 1 day = 1964/2/29
    next_day_after_50_years_ago = now - 50.years + 1.day
    assert_equal(next_day_after_50_years_ago.to_date.to_time,
                 dbf.abs_max_as_date)
    dbf.abs_max = ' t +  50y '
    next_day_after_50_years_from_now = now + 50.years + 1.day
    assert_equal(next_day_after_50_years_from_now.to_date.to_time,
                 dbf.abs_max_as_date)
    dbf.abs_max = nil
    assert_nil(dbf.abs_max_as_date)
    dbf.abs_max = ''
    assert_nil(dbf.abs_max_as_date)
    dbf.abs_max = 'abc'
    assert_raise(StandardError) {dbf.abs_max_as_date}
  end


  def test_abs_min_as_date
    dbf = DbFieldDescription.new(:abs_min=>'t')
    today = Time.now.to_date.to_time
    assert_equal(today, dbf.abs_min_as_date)
    dbf.abs_min = 't-50Y'
    assert_equal(today - 50.years, dbf.abs_min_as_date)
  end
end
