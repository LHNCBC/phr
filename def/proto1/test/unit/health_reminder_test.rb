require 'test_helper'

class HealthReminderTest < ActiveSupport::TestCase
  def setup
    @profile = Profile.new
    @profile.id_shown = "abcde123"
    @profile.save!
    @user = User.new
    @user.email = "aaa@aaa#{rand(1000)}.com"
    @user.name = "book#{rand(1000)}"
    @user.save!
  end

  def test_reminder_caches
    key_1, m_1 = ["fasfsdfdsaf 1", '1 this is the message']
    key_2, m_2 = ["fasfsdfdsaf 2", '2 this is the message']
    key_3, m_3 = ["fasfsdfdsaf 3", '3 this is the message']
    map = {key_1 => m_1, key_2=> m_2, key_3=>m_3}
    date = Time.zone.now.httpdate
    # Clean up the reminder cache first
    HealthReminder.expire_cache(@profile)
    assert !HealthReminder.has_cache?(@profile)
    # Confirm that there is no cached reminders
    actual = HealthReminder.load_details([@profile], true, @user.id)
    expected = {@profile.id_shown=>[{},nil,[]]}
    assert_equal actual.to_json, expected.to_json

    # Create health reminder cache for the profile
    HealthReminder.update_reminders_for_profile(@profile.id_shown, map, date)
    @profile.reload

    # Confirm that reminders have been cached for the profile
    actual = HealthReminder.load_details([@profile], true, @user.id)
    expected = {@profile.id_shown=>[{key_1=>m_1, key_2=>m_2, key_3=>m_3}, @profile.reminders_created_on.to_s(:db), []]}
    assert_equal actual.to_json, expected.to_json

    # After reviewing reminder key_1
    ReviewedReminder.update_records(@user, @profile, [key_1])
    reviewed_reminders = ReviewedReminder.filter_by_user_and_profile(@user.id, @profile.id_shown)
    assert_equal reviewed_reminders, [key_1]
    actual = HealthReminder.load_details([@profile], true, @user.id)
    expected = {@profile.id_shown=>[{key_1=>m_1, key_2=>m_2, key_3=>m_3}, @profile.reminders_created_on.to_s(:db), [key_1]]}
    assert_equal actual.to_json, expected.to_json

    # After reviewing reminder key_2 and key_3
    ReviewedReminder.update_records(@user, @profile, [key_2, key_3])
    reviewed_reminders = ReviewedReminder.filter_by_user_and_profile(@user.id, @profile.id_shown)
    assert_equal reviewed_reminders, [key_2, key_3]
    actual = HealthReminder.load_details([@profile], true, @user.id)
    expected = {@profile.id_shown=>[{key_1=>m_1, key_2=>m_2, key_3=>m_3}, @profile.reminders_created_on.to_s(:db), [key_2, key_3]]}
    assert_equal actual.to_json, expected.to_json

    # Correct the wrongly marked reviewed reminders when non reminder was ever being reviewed
    ReviewedReminder.update_records(@user, @profile, [])
    reviewed_reminders = ReviewedReminder.filter_by_user_and_profile(@user.id, @profile.id_shown)
    assert_equal reviewed_reminders, []
    actual = HealthReminder.load_details([@profile], true, @user.id)
    expected = {@profile.id_shown=>[{key_1=>m_1, key_2=>m_2, key_3=>m_3}, @profile.reminders_created_on.to_s(:db), []]}
    assert_equal actual.to_json, expected.to_json
 
  end

end
