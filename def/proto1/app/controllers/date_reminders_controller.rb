# A controller for the basic mode date reminders pages.
class DateRemindersController < BasicModeController
  before_action :authorize
  before_action :load_phr_record

  helper :phr_records

  layout 'basic'

  def index
    DateReminder.update_reminders(@phr_record.id, @user) # recalculate
    @page_title = "Date Reminders for #{@phr_record.phr.pseudonym}"
    @reminders = @phr_record.date_reminders
    @hidden = false # to be used by mobile mode
  end


  # Shows hidden date reminders
  def hidden
    @hidden=true # to be used by mobile mode
    @page_title = "Hidden Date Reminders for #{@phr_record.phr.pseudonym}"
    @reminders = @phr_record.hidden_date_reminders
  end


  # Hides one reminder
  def hide
    # Go through the @phr_record to make sure the user owns this reminder.
    reminder = @phr_record.date_reminders.find_by_id(params[:id])
    if reminder
      reminder.hide_me = true
      reminder.save!
    end
    redirect_to phr_record_date_reminders_path
  end


  # Unhides one reminder
  def unhide
    # Go through the @phr_record to make sure the user owns this reminder.
    reminder = @phr_record.hidden_date_reminders.find_by_id(params[:id])
    if reminder
      reminder.hide_me = false
      reminder.save!
    end
    redirect_to hidden_phr_record_date_reminders_path
  end
  
end
