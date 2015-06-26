class HealthReminder < ActiveRecord::Base

  # 1) Update the reminder creation timestamp on the profile
  # 2) Outdate the old reminders
  # 3) Create new reminder records if they cannot be found in the newly generated reminders list
  #
  # Parameters:
  # * 1) id_shown id_shown of a profile
  # * 2) new_reminder_map hash map from reminder hash keys to reminder messages
  # * 3) creation_date the date when reminders are generated
  def self.update_reminders_for_profile(id_shown, new_reminder_map, creation_date)
    creation_date = Time.zone.parse(creation_date) if creation_date.is_a?(String)
    profile = Profile.where(:id_shown => id_shown).take
    # updates the creation date for reminders
    profile.reminders_created_on = creation_date
    profile.save!

    # 1) For the newly generated reminder list, remove the ones listed as current reminders
    # 2) For existing reminders, outdate them if not listed in the new reminders list
    new_msg_keys = new_reminder_map.keys
    profile.health_reminders.each do |e|
      if new_msg_keys.include?(e.msg_key)
        # the reminder still valid, review status unchanged
        new_msg_keys.delete(e.msg_key)
      else
        # outdate the old reminder
        e.latest = false
        e.save!
      end
    end
    # create brand new health reminder records
    new_msg_keys.each do |k|
      rd = HealthReminder.new
      rd.id_shown = profile.id_shown
      rd.msg_key = k
      rd.msg = new_reminder_map[k]
      rd.latest = true
      rd.save!
    end
  end


  # Returns a hash from id_shown to reminder details including reminder message map, reminder creation date and list of
  # reminder message keys
  #
  # Parameters:
  # * profiles a list of profiles
  # * load_status a flag indicating whether a list of reviewed reminders needs to be included in the result
  # * user_id ID of a user
  def self.load_details(profiles, load_status, user_id)
    rtn={}
    profiles.each do |profile|
      id_shown = profile.id_shown
      has_cache = self.has_cache?(profile)
      # Load health reminders from the cache
      msgs = {}
      profile.health_reminders.each do |rec|
        msgs[rec.msg_key]= rec.msg
      end if has_cache
      date = profile.reminders_created_on.to_s(:db) if has_cache
      rtn[id_shown]=[msgs, date ]
      # Load reviewed reminders from reviewed_reminders table
      if load_status
        reviewed_msgs = ReviewedReminder.filter_by_user_and_profile(user_id, id_shown)
        rtn[id_shown] << reviewed_msgs
      end
    end
    rtn
  end


  # Makes the reminder cache of the input profile invalid
  #
  # Parameters:
  # * profile a profile record
  def self.expire_cache(profile)
    profile.reminders_created_on = nil
    profile.save!
  end


  # Returns true if the reminders_created_on is nil or expired and vice versa
  #
  # Parameters:
  # * profile a profile record
  def self.has_cache?(profile)
    !profile.reminders_created_on.nil? &&
    ( REMINDER_UPDATE_INTERVAL.hours.ago(Time.now) < profile.reminders_created_on)
  end

end
