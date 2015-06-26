class PhrDoctorQuestionsController < BasicModeTableController

  # POST /phr_records/[record id]/phr_doctor_questions
  # Handles the output of the form from "new"
  def create
    @data_rec = PhrDoctorQuestion.new
    handle_create(@data_rec)
  end


  # GET /phr_records/[record id]/phr_doctor_questions/1/edit
  # Displays a form for editing
  def edit
    @data_rec = @phr_record.phr_doctor_questions.find_by_id(params[:id])
    load_edit_vars
    render 'basic/table_edit'
  end


  # PUT /phr_records/[record id]/phr_doctor_questions/1
  # Handles the output of the form from "edit"
  def update
    @data_rec = @phr_record.phr_doctor_questions.find_by_id(params[:id])
    handle_update(@data_rec)
  end


  # DELETE /phr_records/[record id]/phr_doctor_questions/1
  def destroy
    handle_destroy('question')
  end


  private

  # Returns the fields that appear on the form (or whose code fields do).
  # This is defined as a method rather than a constant so it can be accessed from
  # the base class methods.
  def self.form_fields
    %w{date_entered category question_status question question_answer}
  end


  # Returns the field that is the section header for the other fields.
  def self.section_field
    'doctor_questions'
  end


  # Loads the instance variables for information about the fields in a drug record.
  def load_instance_vars
    super
    if @data_rec # A PhrDoctorQuestion
      @record_name = @data_rec.category
      @categories = PhrDoctorQuestion.category_list
      @statuses = PhrDoctorQuestion.question_status_list
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
    'Question'
  end


  # Set the "main" field in the table to be the question rather than
  # the first column field (which is not required to be there).
  def main_field_index
    3
  end
end
