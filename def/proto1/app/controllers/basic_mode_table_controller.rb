# A base class for basic mode controllers that deal with tables of resources
# (e.g. phr_drugs and a phr_conditions, but not phrs.)
class BasicModeTableController < BasicModeController
  before_filter :authorize
  before_filter :load_phr_record
  layout 'basic'
  helper :phr_records

  # A limit on the number of terms returned for a search
  SEARCH_COUNT_LIMIT = 50

  # GET /phr_records/[record id]/[table_name]
  # Note:  The subclass must define "load_instance_vars" to set up variables
  # needed view the view, resource_title, and a (class) form_fields method.
  # Optionally, the class may define a main_field_index method
  # which specifies the index of the field in form_fields which should be the
  # row heading field when the records are listed in a table.  (By default,
  # the first field is used.
  def index
    load_instance_vars
    @records = @phr_record.send(@table)
    @db_fields = self.class.update_fields # for now, show all these fields
    @page_title = "#{resource_title.pluralize} for #{@phr_record.phr.pseudonym}"
    @main_field_index = respond_to?(:main_field_index, true) ? main_field_index : 0
    render 'basic/table_index'
  end


  # GET /phr_records/[record id]/phr_drugs/new
  def new
    @data_rec = self.class.get_resource_class.new
    load_new_vars
    render 'basic/table_new'
  end


  # Class methods.  These are public so they can be accessed by
  # instances.

  # Loads the class variables for information about the fields in the table.
  # Expects form_fields to be defined as a method returning the list of the
  # target_field names.  Requires that the subclass define a method
  # "form_fields" returning the target field names of the fields on forms
  # produced by this controller.
  def self.load_class_vars
    # Store the "class" variables as instance variables on the class object,
    # so that the variables are not shared amongst subclasses.
    if !defined? @class_fds
      class << self
        attr_accessor :class_fds, :labels, :section_fd  # so they are visible to instances
      end
      field_form = Form.find_by_form_name(field_form_name)
      fds = field_form.field_descriptions
      fd_hash = {} # hash of field names to FieldDescription objects
      form_fields.each {|f| fd_hash[f] = fds.find_by_target_field(f)}

      label_hash = {} # hash of database field names to display labels
      fd_hash.each do |name, fd|
        label_hash[fd.db_field_description.data_column] = fd.display_name
      end
      self.class_fds = fd_hash
      self.labels = label_hash
      if @section_fd.nil? && self.respond_to?('section_field')
        self.section_fd = fds.find_by_target_field(section_field)
      end
    end
  end


  # Returns the name of the table for the resource managed by this controller.
  # In most cases this will be the same a get_resource_name, but for the phr_panels
  # resource the table name is obr_orders.  Sub-classes can override this
  # to provide those kinds of differences.
  def self.get_resource_table
    @table_name ||= get_resource_name
  end

  
  # Returns the class for the table for the resource managed by this controller.
  def self.get_resource_class
    # Cache it as an instance variable on the class, so that subclasses
    # have their own variable.
    @table_class ||= get_resource_table.classify.constantize
  end


  # Returns the name of the resource, pluralized, for use in routes.
  def self.get_resource_name
    @resource_name ||= name.match(/(.*)Controller\Z/)[1].tableize
  end


  # Returns the fields we allow to be updated from the form.  For lists we just
  # list the text field here, though actually the code field (or the alt field,
  # for CWE lists) is set.
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.update_fields
    form_fields # the same, for now, and maybe always.
  end

  # Returns the form name of the form containing the fields in form_fields.
  def self.field_form_name
    'phr'
  end


  # End of public class methods.

  
  private

  # Loads the instance variables for information about the fields in the table.
  def load_instance_vars
    c = self.class
    c.load_class_vars
    @fds = c.class_fds
    @labels = c.labels
    @table = c.get_resource_name  # in the views "@table" is the resource
    @section_fd = c.section_fd
  end


  # Displays the search form
  def show_search_form
    load_search_vars
    render 'basic/table_search'
  end


  # Returns a structure (determined by the model class) containing information
  # for duplicate record warnings.  If there are no warnings, nil will
  # be returned.
  #
  # Params:
  # * record - the record to be checked as to whether duplication warnings are
  #   needed.
  def dup_warning_data(record)
    # If the record supports checking for duplicates, and if the user hasn't yet
    # okayed duplicates, check for them.
    @dup_warning_data = nil
    if record.respond_to?('dup_check') && !params[:dup_ok]
      record.valid? # finish filling in values after the update from the form
      @dup_warning_data = record.dup_check
    end
  end


  # Does the work for a "create" action.
  #
  # Parameters:
  # * record - the user data table record being created (e.g. a phr_drugs record)
  # * db_to_form_field - a map from database field names to field names used
  #   on the form.  This is optional; if not provided it will be assumed that
  #   the the same names are used for both.
  def handle_create(record, db_to_form_field=nil)
    update_record_with_params(record, self.class.update_fields, db_to_form_field)
    record.profile_id = @phr_record.id

    @dup_warning_data = dup_warning_data(record)
    if !@dup_warning_data && save_record(record)
      redirect_to send('phr_record_'+self.class.get_resource_name+'_path'),
        :notice=>CHANGES_SAVED
    else
      load_new_vars
      if !@dup_warning_data
        flash.now[:error] = record.build_error_messages(@labels)
      end
      render 'basic/table_new'
    end
  end


  # Does the work of an "update" action
  #
  # Parameters:
  # * record - the user data table record being updated (e.g. a phr_drugs record)
  # * db_to_form_field - a map from database field names to field names used
  #   on the form.  This is optional; if not provided it will be assumed that
  #   the the same names are used for both.
  def handle_update(record, db_to_form_field=nil)
    update_record_with_params(record, self.class.update_fields, db_to_form_field)
    
    @dup_warning_data = dup_warning_data(record)
    if !@dup_warning_data && save_record(record)
      redirect_to send('phr_record_'+self.class.get_resource_name+'_path'),
        :notice=>CHANGES_SAVED
    else
      load_edit_vars
      if !@dup_warning_data
        flash.now[:error] = record.build_error_messages(@labels)
      end
      render 'basic/table_edit'
    end
  end


  # Does the work for a "destroy" action.
  #
  # Parameters:
  # * name_field - the field in the data record being destroyed that best
  #   describes the record.
  # * redirect_params - Additional parameters to include in the redirect URL
  #   if all goes well.
  def handle_destroy(name_field, redirect_params={})
    table = self.class.get_resource_table
    data_rec = @phr_record.send(table).find(params[:id])
    name = data_rec.send(name_field)
    delete_record(data_rec)
    flash[:notice] = "Deleted record for #{name}."
    redirect_to send('phr_record_'+self.class.get_resource_name+'_path',
      redirect_params)
  end


  # Loads variables needed by the search action.
  def load_search_vars
    @table = self.class.get_resource_name  # in the views "@table" is the resource
    @page_title = "#{resource_title} Name Lookup"
  end


  # Loads instance variables needed by the "new" record page.  Assumes
  # the subclass defines resource_title and load_instance_vars.
  def load_new_vars
    load_instance_vars
    @page_title = "New #{resource_title} Record"
  end

end
