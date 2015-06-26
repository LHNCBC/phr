class PhrMedicalContactsController < BasicModeTableController

  # A map from database record fields to form field names.
  DB_TO_FORM_FIELDS = {'medcon_type'=>'medtact_type',
    'name'=>'medtact_name', 'phone'=>'medtact_ph',
    'fax'=>'medtact_fax',
    'email'=>'medtact_email', 'next_appt'=>'next_appt',
    'next_appt_time'=>'next_appt_time', 'comments'=>'medtact_comnt'
  }

  # POST /phr_records/[record id]/phr_medical_contacts
  # Handles the output of the form from "new"
  def create
    @data_rec = PhrMedicalContact.new
    handle_create(@data_rec, DB_TO_FORM_FIELDS)
  end


  # GET /phr_records/[record id]/phr_medical_contacts/1/edit
  # Displays a form for editing
  def edit
    @data_rec = @phr_record.phr_medical_contacts.find_by_id(params[:id])
    load_edit_vars
    render 'basic/table_edit'
  end


  # PUT /phr_records/[record id]/phr_medical_contacts/1
  # Handles the output of the form from "edit"
  def update
    @data_rec = @phr_record.phr_medical_contacts.find_by_id(params[:id])
    handle_update(@data_rec, DB_TO_FORM_FIELDS)
  end


  # DELETE /phr_records/[record id]/phr_medical_contacts/1
  def destroy
    handle_destroy('name')
  end


  private

  # Returns the fields that appear on the form (or whose code fields do).
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.form_fields
   %w{medtact_name medtact_type medtact_ph medtact_fax medtact_email next_appt
       next_appt_time medtact_comnt}
  end


  # Returns the field that is the section header for the other fields.
  def self.section_field
    'medicontact'
  end


  # Loads class variables
  def self.load_class_vars
    super
    # Add a label to the comment field description
    labels['comments'] = class_fds['medtact_comnt'].display_name = 'Comments'
  end


  # Loads the instance variables for information about the fields in a drug record.
  def load_instance_vars
    super
    if @data_rec # A PhrMedicalContact
      @record_name = @data_rec.name
      @categories = PhrMedicalContact.medcon_type_list
    end
  end


  # Loads instance variables needed by the "edit" record page.
  def load_edit_vars
    load_instance_vars
    @page_title = "Edit #{resource_title} Record for #{@record_name}"
  end


  # The name of the resource managed by this controller, in a format
  # fit for a page title.
  def resource_title
    'Contact'
  end


  # Returns the database fields we allow to be updated from the form.  For lists
  # we just list the text field here, though actually the code field (or the alt
  # field, for CWE lists) is set.
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.update_fields
    %w{name medcon_type phone fax email next_appt next_appt_time comments}
  end
end
