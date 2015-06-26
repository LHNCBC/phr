require 'test_helper'

class ReviewedReminderTest < ActiveSupport::TestCase
  fixtures :users
  fixtures :profiles
  
  def setup
    @profile = Profile.first
    @user = User.first
  end
  
  test "update records" do
     list_a = %w(reminder_a reminder_b reminder_c)
     list_b = %w(reminder_c reminder_d)
     
     # When the reviewed_reminderes table was empty
     ReviewedReminder.destroy_all
     ReviewedReminder.update_records(@user, @profile, list_a)
     assert ReviewedReminder.filter_by_user_and_profile(@user.id, @profile.id_shown).size == list_a.size
     # When the reviewed_reminders table is not empty
     ReviewedReminder.update_records(@user, @profile, list_b)
     actual = ReviewedReminder.filter_by_user_and_profile(@user.id, @profile.id_shown).sort
     expected = list_b.sort
     assert actual == expected
    end
    
  end
