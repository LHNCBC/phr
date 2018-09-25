class DateReminder < ActiveRecord::Base
  belongs_to :profiles
  belongs_to :db_table_descriptions
  include UserData
  extend UserData::ClassMethods
  
  # Get the reminder options in the reminder_option table
  # populate the table with default data if there's no data for the profile
  #
  # Parameters:
  # * profile_id - a profile's id
  #
  # Returns: None
  #
  def self.get_reminder_options(profile_id)

    # populate the table with defualt options
    ReminderOption.initialize_options(profile_id)
    
    reminder_option = {}
    option_records = ReminderOption.where("profile_id=? AND latest=?", profile_id, true).order('reminder_type desc')
    option_records.each do |record|
      opt = {}
      opt['reminder_type'] = record.reminder_type
      opt['item_column'] = record.item_column
      opt['due_date_column'] = record.due_date_column
      opt['due_date_type'] = record.due_date_type
      opt['cutoff_days'] = record.cutoff_days
      opt['query_condition'] =record.query_condition
      reminder_option[record.db_table_description_id] = opt
    end
    
    return reminder_option
  end
  

  # Calculate the due date reminders for a profile and store them into the
  # date_reminders table (update the records if there are previous reminders
  # for the same records)
  #
  # Currently there are 4 tables need to check for due date:
  #   TYPE                        TABLE                  COLUMN
  # -------------------------------------------------------------------
  #   Active Drugs                phr_drugs              expire_date
  #   Immunizations               phr_immunizations      immune_duedate
  #   Medical Appointments        phr_medical_contacts   next_appt
  #   Test Results & Trackers     obr_orders             due_date
  #
  # Parameters:
  # * profile_id - a profile's id
  # * user_obj - the current user object
  #
  # Returns: None
  #
  def self.update_reminders(profile_id, user_obj)
    now = Time.now

#    now_et = Time.gm(now.year,now.month,now.day,now.hour,now.min,now.sec).to_i * 1000
#    now_date = now.strftime("%Y %b %d")
#    now_hl7 = now.strftime("%Y/%m/%d")

    start_of_today = Time.gm(now.year,now.month,now.day,0,0,0).to_i * 1000
    ms_in_a_day = 24 * 60 * 60 *1000

    # data table to be used by FormData
    reminder_array = []

    # a set of table id and record id in the reminder records
    reminder_user_table_records = {}

    # get the current reminder options
    reminder_options = DateReminder.get_reminder_options(profile_id)

    # process each category
    reminder_options.each do |db_table_id, options|
      table_name = DbTableDescription.find(db_table_id).data_table
      tableClass = table_name.singularize.camelcase.constantize
      cutoff_days = options['cutoff_days'].to_i

      cond_str = "profile_id=? and latest=? and #{options['due_date_column']} IS NOT NULL"

      if !options['query_condition'].blank?
        cond_str += " AND " + options['query_condition']
      end
      user_records = tableClass.where(cond_str, profile_id, true)

      # filter records for test panel to have only the latest records
      # for each panel
      if table_name == 'obr_orders'
        user_records = DateReminder.process_obr_records(user_records)
      end

      user_records.each do | record |
        reminder_rec = {}
        make_inactive = false
        # if it has a expire_date_ET
        due_date_et = record.send(options['due_date_column']+ "_ET")
        if !due_date_et.blank?
          # past due
          if due_date_et < start_of_today
            ms_past = start_of_today - due_date_et
            day_past = ms_past / ms_in_a_day + 1
            reminder_rec['reminder_status'] = day_past.to_s + ' days past due'
          # due today
          elsif due_date_et < start_of_today + ms_in_a_day
            reminder_rec['reminder_status'] = 'Due today'
          # due within the cutoff days
          elsif due_date_et < start_of_today + ms_in_a_day * cutoff_days
            ms_due = due_date_et - start_of_today
            day_due = ms_due / ms_in_a_day
            reminder_rec['reminder_status'] = 'Due in ' + day_due.to_s + ' days'
          # else if the due date is beyond the cutoff days
          else
            # set it to be inactive
            make_inactive = true
          end
        end
        if !reminder_rec.empty? || make_inactive
          # add the rest column data
          reminder_rec['profile_id'] = profile_id
          reminder_rec['db_table_description_id'] = db_table_id
          reminder_rec['record_id_in_user_table'] = record.record_id
          reminder_rec['reminder_type'] = options['reminder_type']
          reminder_rec['reminder_item'] = record.send(options['item_column'])
          reminder_rec['date_type'] = options['due_date_type']
          reminder_rec['due_date'] = record.send(options['due_date_column'])
          reminder_rec['due_date_HL7'] = record.send(options['due_date_column']+"_HL7")
          reminder_rec['due_date_ET'] = due_date_et
          reminder_rec['hide_me'] = 0

          # merge with the existing data in the date_reminders table
          existing_rec = DateReminder.where(
              'profile_id=? AND db_table_description_id=? AND record_id_in_user_table=? AND latest=?',
              profile_id, db_table_id, record.record_id,true).first
          # found an active existing record
          if !existing_rec.nil?
            if make_inactive
              reminder_rec['record_id'] = 'delete ' + existing_rec.record_id.to_s
            else
              reminder_rec['record_id'] = existing_rec.record_id
            end
            reminder_rec['hide_me'] = existing_rec.hide_me
            # if drug name changed or due_date changed, show the record even if
            # it was previously hidden
            if reminder_rec['reminder_item'] != existing_rec.reminder_item ||
                reminder_rec['due_date_ET'] != existing_rec.due_date_ET
              reminder_rec['hide_me'] = 0
            end
            reminder_array << reminder_rec
            reminder_user_table_records[[db_table_id,record.record_id]] = true
          # no active existing record,
          # no change if it's beyond the cutoff day, otherwise add a new record
          elsif !make_inactive
            reminder_array << reminder_rec
            reminder_user_table_records[[db_table_id,record.record_id]] = true
          end

        end
      end # end of user records
    end # end of data table

    # get all existing reminder records
    # and delete (set latest false) on those records that are no longer in the
    # new reminder record set
    previous_records = DateReminder.where('profile_id=? AND latest=?', profile_id, true)
    deleted_at = Time.now
    previous_records.each do |prev_rec|
      # if the record is not in the new reminder set
      # (deleted, or drugs made inactive)
      if !reminder_user_table_records[[prev_rec.db_table_description_id,
          prev_rec.record_id_in_user_table]]
        prev_rec.latest = false
        prev_rec.deleted_at = deleted_at
        prev_rec.save!
      end
    end

    # add to the data_table
    data_table = {}
    if !reminder_array.empty?
      data_table['date_reminders'] = reminder_array
      # save the data
      fd = FormData.new('date_reminders')
      updated_form_records = fd.save_data_to_db(data_table, profile_id, user_obj)
    end
  end # update_reminders


  # Process the obr_orders records so that only the most recent record for
  # each panel remains.
  # 
  # Parameters:
  # * obr_records - an array of all obr_orders records
  #
  # Returns:
  # * latest_obr_records - an array of latest obr records for each panel
  #
  def self.process_obr_records(obr_records)
    # sort the records by loinc_num, then by test_date_et DESC
    obr_records = obr_records.sort_by {|rec| [rec.loinc_num, -rec.test_date_ET]}

    # pick the first one, (remove the rest)
    latest_obr_records = []
    current_loinc_num = ''
    obr_records.each do |obr_rec|
      if current_loinc_num != obr_rec.loinc_num
        latest_obr_records.push(obr_rec)
        current_loinc_num = obr_rec.loinc_num
      end
    end

    return latest_obr_records
    
  end


  # get the due date reminders for a profile stored in the date_reminders table
  #
  # Currently there are 4 tables need to check for due date:
  #   TYPE                        TABLE                  COLUMN
  # -------------------------------------------------------------------
  #   Active Drugs                phr_drugs              expire_date
  #   Immunizations               phr_immunizations      immune_duedate
  #   Medical Appointments        phr_medical_contacts   next_appt
  #   Test Results & Trackers     obr_orders             due_date
  #
  # Parameters:
  # * profile_id - a profile's id
  #
  # Returns:
  # * taffydb_data - a taffy db data model structure
  #                  see get_taffy_db_data of FormData
  #
  def self.get_reminders(profile_id)
    fd = FormData.new('date_reminders')
    taffydb_data, recovered_fields, from_autosave, err_msg, except =
                                                fd.get_taffy_db_data(profile_id)

    return taffydb_data
  end


  # get the number of active reminders for a profile
  # Parameters:
  # * profile_id - a profile's id
  #
  # Returns:
  #  the total number of due date reminder for the profile
  def self.get_reminder_count(profile_id)
    reminder_count = DateReminder.where("profile_id=? AND latest=? AND hide_me=?", profile_id, true, false).
        select("count(*) rc ").first
    return reminder_count.rc
  end

end # date_reminder
