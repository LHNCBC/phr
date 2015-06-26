class PhrNotesController < BasicModeTableController

  # POST /phr_records/[record id]/phr_notes
  # Handles the output of the form from "new"
  def create
    @data_rec = PhrNote.new
    handle_create(@data_rec)
  end


  # GET /phr_records/[record id]/phr_notes/1/edit
  # Displays a form for editing
  def edit
    @data_rec = @phr_record.phr_notes.find_by_id(params[:id])
    load_edit_vars
    render 'basic/table_edit'
  end


  # PUT /phr_records/[record id]/phr_notes/1
  # Handles the output of the form from "edit"
  def update
    @data_rec = @phr_record.phr_notes.find_by_id(params[:id])
    handle_update(@data_rec)
  end


  # DELETE /phr_records/[record id]/phr_notes/1
  def destroy
    handle_destroy('note_date')
  end


  private

  # Returns the fields that appear on the form (or whose code fields do).
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.form_fields
    %w{note_date note_text}
  end


  # Returns the field that is the section header for the other fields.
  def self.section_field
    'notes'
  end


  # Loads instance variables needed by the "edit" record page.
  def load_edit_vars
    load_instance_vars
    @page_title = "Edit #{resource_title} Record for Note from #{@data_rec.note_date}"
  end


  # The name of the resource managed by this controller, in a format
  # fit for a page title.
  def resource_title
    'Note'
  end

end
