#--
# $Log: data_controller.rb,v $
# Revision 1.18  2011/05/10 19:26:39  plynch
# Converted a symbol to a string to fix a problem
#
# Revision 1.17  2011/04/20 16:13:12  plynch
# Made sure the index files that are updated by the data controller remain readable by the group
#
# Revision 1.16  2010/09/16 22:21:29  plynch
# The data controller now uses a locks table to prevent concurrent updates.
#
# Revision 1.15  2010/09/15 21:40:45  plynch
# Disabled automatic ferret indexing.
#
# Revision 1.14  2010/08/03 15:48:12  lmericle
# added before_filter set_to_popup to application_controller & header and banner settings; removed debugger from data_controller
#
# Revision 1.13  2010/06/25 13:59:38  lmericle
# added before_filter for set_account_type_flag; added set_account_type_flag to application_controller
#
# Revision 1.12  2010/06/10 21:28:26  mujusu
# added header to data and rule forms
#
# Revision 1.11  2010/03/30 22:41:18  plynch
# Changes for the help management pages.
#
# Revision 1.10  2010/03/12 16:50:37  plynch
# A fix to keep new jobs from being submitted while a restart is in progress.
#
# Revision 1.9  2010/02/22 23:30:29  plynch
# Now gets the web server release lock before starting the update.
#
# Revision 1.8  2010/02/22 20:54:20  plynch
# Removed a debugging statement
#
# Revision 1.7  2010/02/22 20:26:31  plynch
# Revised the data controller and gave it a nicer user interface.
#
# Revision 1.6  2009/08/13 16:18:37  plynch
# Removed a debugging statement.
#
# Revision 1.5  2009/08/12 17:10:10  plynch
# Added more detail on errors, and a locking feature to keep an update
# of the same table from happening at the same time.
#
# Revision 1.4  2009/02/10 20:28:43  plynch
# The data controller now requests a restart after doing an update.
#
# Revision 1.3  2009/01/09 21:03:30  plynch
# Added data controller actions for updating help and instruction text.
#
# Revision 1.2  2008/08/25 18:40:21  plynch
# The data controller no longer waits for a data update to complete before
# returning its page.  This avoids time outs for lengthy updates.
#
# Revision 1.1  2008/05/27 22:27:32  plynch
# Added a new data controller that allows certain tables to be updated
# by submitted CSV files.
#
#++

require 'set'
require 'csv'

# This controller allows admin users to export and update "data" tables (for
# lists, etc.)  It does not allow the admin user to update the forms or rules;
# for that use the formbuilder and rule controllers.
#
# The tables this controller is allowed to edit are controlled by the
# DATA_CONTROLLER_TABLES constant specified in environment.rb.
class DataController < ApplicationController
  before_filter :admin_authorize
  before_filter :table_check, :only=>[:export]
  before_filter :show_header
  
  @@allowed_data_tables = Set.new(DATA_CONTROLLER_TABLES)

  # Shows the main page
  def index
    @user_name = User.find_by_id(session[:user_id]).name
    @title = 'Data List Updater'
    @last_file = session[:last_file]
    render(:layout=>'nonform')
  end

  
  # Shows the page for editing form form field help
  def help
    @form_names = []
    @form_codes = []
    Form.all.each {|f| @form_names << f.form_name; @form_codes << f.id}
    @user_name = User.find_by_id(session[:user_id]).name
    @title = 'Form Field Help'
    render(:layout=>'nonform')
  end


  # Produces a CSV export of the requested data table.
  def export
    # If we got here through the filters, the table name and user should be
    # okay.
    if params.size > 3
      condition_params = params.clone
      # Remove the controller, action, and table_name parameters.  The
      # rest should be a specification of column values for limiting the
      # records that are returned.
      condition_params.delete(:id)
      condition_params.delete(:controller)
      condition_params.delete(:action)
      condition_params.delete(:format)
    else
      condition_params = nil
    end

    table_class = get_table_name.singularize.camelize.constantize
    send_csv_data(table_class.csv_dump(condition_params))
  end


  # Allows the update of a data table via a CSV file.  Each row represents
  # a record to be updated.  If a record's ID is not in the file, it will
  # be left alone.  If a row in the file starts with a record's ID, the record
  # will be updated using the values.  (The header row in the file specifies
  # which field goes with which attribute.)  If a row consists of just
  # "delete 52" then record 52 is deleted.  If a row consists of "delete all"
  # the all records are deleted.
  def update
    # If we got here through the filters, the user should be
    # okay, but we still need to check the table.
    
    if request.post?
      table_name = nil
      update_data = nil
      update_file_name = nil
      form_name = nil
      if (!params[:update_file])
        flash[:error] = 'Please specify a file to upload.'
      else
        update_file = params[:update_file]
        update_file_name = update_file.original_filename
        begin
          update_file_text = update_file.read
          # The first line of the file should contain the table name in the second
          # field.
          update_data = CSV.parse(update_file_text)
        rescue Exception => e
          # update_data remains nil
        end
        if !update_data || update_data.length == 0
          flash[:error] = 'Could not parse the uploaded CSV file.'
        else
          table_name_row = update_data.shift
          if table_name_row.length < 2
            flash[:error] =
              'Could not find the table name in the uploaded file.'
          else
            table_name = table_name_row[1]
            if (table_name == 'field_descriptions')
              if table_name_row.length < 4
                flash[:error] =
                  'Could not find the form name in the uploaded file.'
              else
                form_name = table_name_row[3]
              end
            end
          end
        end
      end
      
      if table_name
        # lock_name is the name of a lock we use to prevent concurrent updates.
        # We used to allow concurrent updates for different tables, but tables
        # with a ferret index require that that the server be restarted
        # after a rebuild of the index, and that caused problems if there
        # was another table being updated.
        lock_name = 'Data Controller Update'
        if !form_name && !@@allowed_data_tables.member?(table_name)
          flash[:error] =
            "Updates of table \"#{table_name}\" are not permitted."
        elsif RestartManager.restart_requested?
          flash[:error] = 'The system is restarting.  Please wait one minute '+
             'before trying again.'
        elsif !(lock = Lock.create(:resource_name=>lock_name,
                                    :user_id=>@user.id)).valid?
          flash[:error] = 'An update is already in ' +
            'progress.  Please try again later.'
        else
          # The user has submitted a file.  Run the work for this in a background
          # thread, so that the browser doesn't time out waiting for a response.
          # (For large tables, the update can take minutes.  Rebuilding the Ferret
          # index can take another few minutes.)
          Thread.new do
            # Get the web server restart lock, so baseline update script does
            # not restart the web server while we are working.
            RestartManager.restart_lock
            mail_message = "The update from file #{update_file_name} has "+
              'completed.  Wait a minute for the server to '+
              'be restarted, and then you should be able to see your '+
              'changes.'
            begin
              user_email = @user.email
              table_class = table_name.singularize.camelize.constantize

              if (table_name=='field_descriptions')
                f = Form.find_by_form_name(form_name)
                f.help_text_parsed_csv_update(update_data, @user.id)
              else
                table_class.update_by_parsed_csv(update_data,
                  @user.id)
              end

              # Rebuild the Ferret index if this class has one or if its data
              # is indexed by another class that has one.
              ferret_class = table_class.respond_to?('ferret_class') ?
                table_class.ferret_class : table_class
              uses_ferret = ferret_class.respond_to?('disable_ferret')
              if (uses_ferret)
                ferret_class.rebuild_index
                # Make sure the index files are readable by the group
                index_path = File.join(Rails.root, 'index')
                system('chmod', '-R', 'g+r', index_path)
              end
              # Send an email to the user to let them know
            rescue Exception => e
              mail_message = "An error occurred. #{e.to_s}\n"+
                e.backtrace.join("\n")
            ensure
              lock.destroy
            end

            # The delivery of the message often fails in development mode,
            # due (as I understand) to classes being unloaded and reloaded
            # following the completion of the request.
            if (user_email)
              # N.B.:  See comment above
              DefMailer.deliver_message(user_email, 'Data update status',
                                        mail_message)
            end
            user_name = @user.name
            DefMailer.deliver_message(DATA_UPDATE_EMAILS,
              'Data update notification', "Table #{table_name} was updated "+
              "on #{HOST_NAME} by #{user_name} from file #{update_file_name} "+
              'using the data controller.')

            FileUtils.rm_rf(Rails.root.join('tmp', 'cache')) # clear the cached page fragments
            RestartManager.release_restart_lock
            RestartManager.request_restart if Rails.env=='production'
          end # thread
          flash[:notice] ='The update has been started, and will take a few '+
            'minutes.  If your user account settings include an email address, '+
            'you will be notified when the update is complete.'
        end # else the table was not locked
      end # else the user specified a table in the upload file
    end # if it was a post request
    redirect_to('/data')
  end # def update
  
  
  # An export method for exporting the label and instruction text for a form
  # via a CSV file.  Each row represents a field description to be updated.
  # The columns must contain (at least) id, help_text, and instructions.
  # The ids must belong to the specified form (via the :name parameter-- see
  # the routes file.)
  def export_form_text
    form_name = get_form_name
    f = Form.find_by_form_name(form_name)
    send_csv_data(f.help_text_csv_dump)
  end


  private
    
    # A before_filter that checks that the requested table is one the data
    # controller is allowed to modify.
    def table_check
      name = get_table_name
      unless @@allowed_data_tables.member?(name)
        render(:text=>"#{name} is not a table that can be accesssed.")
      end
    end

    # Returns the table name from the params
    def get_table_name
      return params[:id]
    end


    # Returns the form name from the params
    def get_form_name
      return params[:id]
    end

   
    # Sends the given CSV data back to the browser
    def send_csv_data(csv)
      headers['Content-Type'] = 'text/csv'
      send_data csv, :disposition => 'attachment'
    end

end
