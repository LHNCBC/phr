class ReminderOption < ActiveRecord::Base
  belongs_to :profiles
  belongs_to :db_table_descriptions
  include UserData
  extend UserData::ClassMethods
  
  # Constant variable, default values
  TABLES_NEED_REMINDERS = {
      'phr_drugs'=>
          {'reminder_type'=>'Active Drugs', 'item_column'=>'name_and_route', 'due_date_column'=>'expire_date', 'due_date_type'=>'Resupply Date', 'cutoff_days'=>30, 'query_condition'=>'drug_use_status_C="DRG-A"'},
      'phr_immunizations'=>
          {'reminder_type'=>'Vaccinations', 'item_column'=>'immune_name', 'due_date_column'=>'immune_duedate', 'due_date_type'=>'Next Due', 'cutoff_days'=>30},
      'phr_medical_contacts'=>
          {'reminder_type'=>'Medical Appointments', 'item_column'=>'name','due_date_column'=>'next_appt','due_date_type'=>'Next Appt.', 'cutoff_days'=>30},
      'obr_orders'=>
          {'reminder_type'=>'Test Results & Trackers','item_column'=>'panel_name', 'due_date_column'=>'due_date', 'due_date_type'=>'Next Due', 'cutoff_days'=>30}
  }

  
  # Copy the default values for a profile if there's none
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
  # Returns: None
  #
  def self.initialize_options(profile_id)

    record_id = 1
    TABLES_NEED_REMINDERS.each do |table_name, option|
      db_table_id = DbTableDescription.find_by_data_table(table_name).id
      option_rec = ReminderOption.where(
          'profile_id=? AND db_table_description_id=? AND latest=?',
          profile_id, db_table_id, true).first

      if option_rec.nil?
        option['db_table_description_id'] = db_table_id
        option['profile_id'] = profile_id
        option['record_id'] = record_id
        option['latest'] = true
        ReminderOption.create!(option)
        record_id += 1
      else
        record_id = record_id > option_rec.record_id ? record_id : option_rec.record_id+1        
      end
    end
  end
  
end # reminder_option
