class ReviewedReminder < ActiveRecord::Base

  # Returns a list of reviewed reminders based on the input profile and user information
  #
  # Parameters:
  # * user_id the ID of a user
  # * id_shown the id_shown of a user profile
  # * return_active_record a flag indicating if this method will return a list of active record objects
  #   or strings
  def self.filter_by_user_and_profile(user_id, id_shown, return_active_record = false)
    rtn = self.where(:user_id => user_id, :id_shown => id_shown, :latest=> true)
    return_active_record ? rtn : rtn.map(&:msg_key)
  end

  # Refresh the data table with list of latest reviewed reminders
  #
  # Parameters:
  # * user a user
  # * profile a user profile
  # * latest_reviewed_reminders the keys of the latest reviewed reminders
  def self.update_records(user, profile, latest_reviewed_reminders)
    unless latest_reviewed_reminders.is_a?(Set)
      latest_reviewed_reminders = Set.new(latest_reviewed_reminders)
    end

    # Remove the existing record from the latest_reviewed_reminders list and mark
    # out expired records
    exist_reminders = self.filter_by_user_and_profile(user.id, profile.id_shown, true)
    exist_reminders.each do |e|
      if latest_reviewed_reminders.include?(e.msg_key)
        latest_reviewed_reminders.delete(e.msg_key)
      else
        e.latest = false; e.save!
      end
    end

    # Create new records based on latest_reviewed_reminders list
    latest_reviewed_reminders.each do |new_msg_key|
      rec = self.new
      rec.user_id = user.id
      rec.id_shown = profile.id_shown
      rec.msg_key = new_msg_key
      rec.latest = true
      rec.save!
    end
  end

end