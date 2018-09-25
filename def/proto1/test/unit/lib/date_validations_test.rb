# To change this template, choose Tools | Templates
# and open the template in the editor.

#$:.unshift File.join(File.dirname(__FILE__),'..','lib')
$:.unshift File.join(File.dirname(File.absolute_path(__FILE__)),'..','..','..','lib')
require 'date_interpretation'
require 'date_validations'
require 'active_model'
require 'ostruct'

# Set up a class to mimic a model class with a date field.
class ModelWithDate < OpenStruct
  include DateValidations
  extend ActiveModel::Naming
  class <<self
    attr_accessor :birth_date_reqs
  end
  attr_reader :errors
  def initialize
    super
    @errors = ActiveModel::Errors.new(self)
  end
  def validate
    validate_date('birth_date', self.class.birth_date_reqs)
  end
  def birth_date_changed?
    true # always validate
  end
end

require 'test_helper'
class DateValidationsTest < ActiveSupport::TestCase
  def setup
    timecop_path = Dir[File.join(Gem.user_dir,"gems/timecop*/lib/")][0]
    require timecop_path + 'timecop'
  end

  def teardown
    Timecop.return
  end

  def test_validate_date # defined in active_record_extensions
    birth_date_reqs = (ModelWithDate.birth_date_reqs ||= {})
    birth_date_reqs.merge!('required'=>false, 'month'=>false, 'day'=>false)

    # Check that a date is not required
    assert_dates([nil, '', '  '])

    # Check that a correct format is required
    assert_dates_invalid(['123', '12/12/12/12', '12 1990 Apr', '12 12 12'])

    # For this field, check that a day is required, that a month is required,
    # and (as always) that a century is required.
    # Month and day no longer required
    assert_dates(['1999/3', '1999', '1999/12/11', '1999 Apr'])

    # Now check for valid formats
    assert_dates(['1999/12/30', '1999/3/4', '1999 Apr 2'])

    # Check for month & date range errors on valid formats
    assert_dates_invalid(['1999/0/5', '1999/13/5', '1999/5/0', '1999/5/32',
      '1999 Apr 33', '1999 Apr 0', '1999 ZZZ 4'])

    # Try making the date field required
    birth_date_reqs['required'] = true
    assert_dates_invalid([nil, '', '  '])

    # Allow the day to be optional
    birth_date_reqs['day'] = false
    day_optional = ['1999/3', '1999/11', '1999/3/2', '1999/11/2',
      '1999 Apr 25', '1999 Apr']
    month_optional = ['1999']
    assert_dates(day_optional)
    # now birth_date is optional
    assert_dates(month_optional)

    # Allow the month to be optional
    birth_date_reqs['month'] = false
    assert_dates(day_optional)
    assert_dates(month_optional)


    # Tests for the date/time selection when the date/time is not fully
    # specified.
    # Beginning of range
    birth_date_reqs['epoch_point'] = 0
    phrs = assert_dates(['1999', '1999/3', '1999/3/10'])
    # Display string check
    assert_equal('1999', phrs[0].birth_date)
    assert_equal('1999 Mar', phrs[1].birth_date)
    assert_equal('1999 Mar 10', phrs[2].birth_date)
    # Epoch time check
    assert_equal(915166800000, phrs[0].birth_date_ET)
    assert_equal(920264400000, phrs[1].birth_date_ET)
    assert_equal(921042000000, phrs[2].birth_date_ET)
    # HL7 string check
    assert_equal('19990101', phrs[0].birth_date_HL7)
    assert_equal('19990301', phrs[1].birth_date_HL7)
    assert_equal('19990310', phrs[2].birth_date_HL7)

    # Middle of range
    birth_date_reqs['epoch_point'] = 1
    phrs = assert_dates(['1999', '1999/3', '1999/3/10'])
    # Display string check
    assert_equal('1999', phrs[0].birth_date)
    assert_equal('1999 Mar', phrs[1].birth_date)
    assert_equal('1999 Mar 10', phrs[2].birth_date)
    # Epoch time check
    assert_equal(930801600000, phrs[0].birth_date_ET) # July 1st
    assert_equal(921474000000, phrs[1].birth_date_ET) # March 15th
    assert_equal(921085200000, phrs[2].birth_date_ET) # Noon on March 10th
    # HL7 string check
    assert_equal('19990701', phrs[0].birth_date_HL7)
    assert_equal('19990315', phrs[1].birth_date_HL7)
    assert_equal('19990310', phrs[2].birth_date_HL7)

    # End of range
    birth_date_reqs['epoch_point'] = 2
    phrs = assert_dates(['1999', '1999/3', '1999/3/10'])
    # Display string check
    assert_equal('1999', phrs[0].birth_date)
    assert_equal('1999 Mar', phrs[1].birth_date)
    assert_equal('1999 Mar 10', phrs[2].birth_date)
    # Epoch time check
    assert_equal(946702799999, phrs[0].birth_date_ET) # End of Dec. 31st
    assert_equal(922942799999, phrs[1].birth_date_ET) # End of March 31st
    assert_equal(921128399999, phrs[2].birth_date_ET) # End of March 10th
    # HL7 string check
    assert_equal('19991231', phrs[0].birth_date_HL7)
    assert_equal('19990331', phrs[1].birth_date_HL7)
    assert_equal('19990310', phrs[2].birth_date_HL7)

    # Test what happens when there is a maximum date limit.  There was
    # a problem in basic mode in which if you entered are "when
    # started" value of today, validation failed in morning hours
    # because the time by default is set to noon, which is future.
    # We will test both at 11:00 a.m. and 1:00 p.m.
    birth_date_reqs['epoch_point'] = 1
    now = Time.now
    eleven_oclock = Time.new(now.year, now.month, now.day, 11)
    one_oclock = Time.new(now.year, now.month, now.day, 13)
    Timecop.freeze(eleven_oclock)
    # Set the max date to be the beginning of the next day (no dates later than
    # today)
    birth_date_reqs['max'] = DateInterpretation.interpret_relative_date('t') + 86400
    yesterday = now.yesterday
    tomorrow = now.tomorrow
    assert_dates(["#{now.year}/#{now.month}/#{now.day}",
                  "#{yesterday.year}/#{yesterday.month}/#{yesterday.day}"])
    assert_dates_invalid(["#{tomorrow.year}/#{tomorrow.month}/#{tomorrow.day}"])
    Timecop.freeze(one_oclock)
    birth_date_reqs['max'] = DateInterpretation.interpret_relative_date('t') + 86400
    assert_dates(["#{now.year}/#{now.month}/#{now.day}",
                  "#{yesterday.year}/#{yesterday.month}/#{yesterday.day}"])
    assert_dates_invalid(["#{tomorrow.year}/#{tomorrow.month}/#{tomorrow.day}"])

    # Reset the required status to the original (for future tests)
    birth_date_reqs['required'] = false
    birth_date_reqs['day'] = true
    birth_date_reqs['month'] = true
    birth_date_reqs.delete('epoch_point')

    # Time field validations are done in obr_order_test (because ObrOrder
    # has a test_date_time).
  end

  # Asserts that the given date strings do not contain an error (for the
  # birth_date field), unless
  # the "expect_error" parameter is true, in which case it will assert that
  # the given dates produce an error.
  #
  # Parameters:
  # * dates - A list of date strings to be parsed
  # * expect_error - (default false) if true, this will assert that the
  #   date strings result in errors; if false it will assert that they do not.
  #
  # Returns:  an array of PHR records with birth_date set to the given dates
  def assert_dates(dates, expect_error=false)
    rtn = []
    dates.each do |val|
      p = ModelWithDate.new
      p.birth_date = val
      p.validate
      puts p.errors[:birth_date].inspect if !expect_error and p.errors[:birth_date].length > 0
      send(:assert_equal, expect_error, p.errors[:birth_date].length > 0,
        "(date value was '#{val.nil? ? 'nil' : val}')")
      rtn << p
    end
    return rtn
  end

  # Calls assert_dates with expect_error = true.
  def assert_dates_invalid(dates)
    assert_dates(dates, true)
  end
end
