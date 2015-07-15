class AddNeedsReadOnly < ActiveRecord::Migration

  # Adds the needs_read_only_version column to the forms table.  This is used
  # to flag forms that need a read-only version of the form built when forms
  # are being preloaded for production mode.

  # The flag is set only for forms that non-admin users can access to input,
  # update, and delete their data.  Specifically, it's set for:
  # the date_reminders form, so that the user cannot choose to hide a reminder
  #   and so that the 'Date Reminders Settings' button is not shown (so that
  #   the user cannot change the settings);
  # the panel_view form, so that the user cannot make changes to the flowsheet (by
  #   not providing the right-click popup menu that allows editing of an entry
  #   AND blocking display of the Add Tests and Trackers button used to bring up
  #   the panel_edit form; and
  # the PHR form, so that the user cannot enter or update any of the health summary
  #   data (by blocking the right-click popup menu that allows editing of an
  #   entry, preventing blanks lines at the end of a section that allow
  #   addition of a new entry, and blocking display of the Add Tests and Trackers
  #   button used to bring up the panel_edit form).
  #

  def self.up
    if MIGRATE_FFAR_TABLES
      Form.transaction do
        add_column :forms, :needs_read_only_version, :boolean, :default=>false
        Form.reset_column_information
        form_names = ['date_reminders', 'panel_view', 'PHR']
        fms = Form.where("form_name IN (?)", form_names)
        fms.each do |fm|
          fm.needs_read_only_version = true
          fm.save!
        end
      end # transaction
    end # if MIGRATE_FFAR_TABLES
  end #up

  def self.down
    if MIGRATE_FFAR_TABLES
      Form.transaction do
        remove_column :forms, :needs_read_only_version
      end # transaction
    end # if MIGRATE_FFAR_TABLES
  end # down
end
