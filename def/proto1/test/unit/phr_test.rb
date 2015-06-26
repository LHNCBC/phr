require 'test_helper'

class PhrTest < ActiveSupport::TestCase

  # Tests the uniqueness requirement of the pseudonym field
  def test_pseudonym
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items'])    
    p = Phr.new(:latest=>1)
    p.valid?
    assert(p.errors[:base].length > 0) # no user
    u = create_test_user
    pf = Profile.create!
    u.profiles << pf
    p.profile = pf
    p.valid?
    assert(p.errors[:base].empty?)
    assert(p.errors[:pseudonym].length > 0) # missing pseudonym
    p.pseudonym = 'ABC'
    p.valid?
    assert(p.errors[:pseudonym].empty?)
    # Make it valid and save
    p.gender_C = 'M'
    p.birth_date = '1950/10/11'
    p.save!
    # Now make a second with the same pseudonym
    p = Phr.new(:pseudonym=>'ABC', :gender_C=>'M', :latest=>1,
      :birth_date=>'1960/2/3')
    pf = Profile.create!
    u.profiles << pf
    p.profile = pf
    p.valid?
    assert(p.errors[:pseudonym].length > 0)
    # Now make a second user with a profile with the same pseudonym, which
    # should be okay.
    # but wait a sec so that the create_test_user method doesn't generate a
    # duplicate id_shown for the profile and throw an error.  9/17/14 lm
    sleep(1)
    u = create_test_user(:name=>'ABC123', :email=>'iamanemail2@address.com')
    pf = Profile.create!
    u.profiles << pf
    p = Phr.new(:pseudonym=>'ABC', :gender_C=>'M', :latest=>1,
      :birth_date=>'1960/2/3')
    pf.phr = p
    assert(p.valid?)
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
      p = Phr.new
      p.birth_date = val
      p.valid?
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
