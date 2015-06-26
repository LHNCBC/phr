class ReminderOptionsController < BasicModeTableSearchController

# Fields we allow to be updated from the form.  For lists we just list
# the text field here, though actually the code field (or the alt field,
# for CWE lists) is set.
  UPDATE_FIELDS = %w{cutoff_days}

# GET /phr_records/[record id]/reminder_options/1/edit
# Displays a form for editing
  def edit
    @reminder_option = @phr_record.reminder_options.find_by_id(params[:id])
    @reminder_type = @reminder_option.reminder_type
    load_edit_vars
    render 'basic/table_edit'
  end


# PUT /phr_records/[record id]/reminder_options/1
# Handles the output of the form from "edit"
  def update
    @reminder_option = @phr_record.reminder_options.find_by_id(params[:id])
    handle_update(@reminder_option)
  end


  # DELETE /phr_records/[record id]/reminder_options/1
  def destroy
    handle_destroy('reminder_type')
  end


  private


  def self.field_form_name
    'reminder_options'
  end


  # Returns the fields that appear on the form (or whose code fields do).
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.form_fields
    %w(reminder_type due_date_type cutoff_days)
    # [ "reminder_type", "item_column", "due_date_column", "due_date_type", "cutoff_days", "query_condition"]
  end


  # Returns the field that is the section header for the other fields.
  def self.section_field
    'reminder_type'
  end

  # Loads instance variables needed by the "edit" record page.
  def load_edit_vars
    load_instance_vars
    @page_title = "Edit #{resource_title} Record for #{@reminder_type}"
  end


  # The name of the resource managed by this controller, in a format
  # fit for a page title.
  def resource_title
    'Reminder Options'
  end
end