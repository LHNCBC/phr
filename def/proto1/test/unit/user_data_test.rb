$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test_helper'

class UserDataTest < ActiveSupport::TestCase
  def setup
    timecop_path = Dir[File.join(Gem.user_dir,"gems/timecop*/lib/")][0]
    require timecop_path + 'timecop'
  end

  def teardown
    Timecop.return
  end

  def test_date_requirements_get_reset
    # Date requirements need to get reset at least on a daily basis,
    # because they can contain min/max values which are relative to the current
    # date.
 
    # Create a test class that is a UserData.
    test_class = Class.new do
      include UserData
      extend UserData::ClassMethods
    end

    # Create a test form
    if !Form.find_by_form_name('some_form')
      test_form = Form.create!(form_name: 'some_form')
    end

    # First, confirm that in the same day, the requirements are not reset.
    # (We cache the values for performance.)
    reqs1 = test_class.date_requirements(['some_field'], 'some_form')
    reqs2 = test_class.date_requirements(['some_field'], 'some_form')
    assert(reqs1.equal?(reqs2)) # assert the hashes are the same object
    
    # Now change the date to tomorrow, and try again.
    Timecop.freeze(Time.now.tomorrow)
    reqs3 = test_class.date_requirements(['some_field'], 'some_form')
    assert(!reqs1.equal?(reqs3))
  end
end
