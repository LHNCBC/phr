class PhrSurgicalHistoriesController < BasicModeTableSearchController

  # POST /phr_records/[record id]/phr_surgical_histories
  # Handles the output of the form from "new"
  def create
    @phr_surgery = PhrSurgicalHistory.new
    handle_create(@phr_surgery)
  end


  # GET /phr_records/[record id]/phr_surgical_histories/1/edit
  # Displays a form for editing
  def edit
    @phr_surgery = @phr_record.phr_surgical_histories.find_by_id(params[:id])
    load_edit_vars
    render 'basic/table_edit'
  end


  # PUT /phr_records/[record id]/phr_surgical_histories/1
  # Handles the output of the form from "edit"
  def update
    @phr_surgery = @phr_record.phr_surgical_histories.find_by_id(params[:id])
    handle_update(@phr_surgery)
  end


  # DELETE /phr_records/[record id]/phr_surgical_histories/1
  def destroy
    handle_destroy('surgery_type')
  end


  # The action for the submission from the search form
  def search
    handle_search('surgery_type')
  end


  private

  # Returns the fields that appear on the form (or whose code fields do).
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.form_fields
    %w{surgery_type surgery_when surgery_comments}
  end


  # Returns the field that is the section header for the other fields.
  def self.section_field
    'surgical_history'
  end


  # Loads the instance variables for information about the fields in a drug record.
  def load_instance_vars
    super
    if @phr_surgery
      @record_name = @phr_surgery.surgery_type
      if !@record_name
        master_table_info = @phr_surgery.gopher_term
        if master_table_info
          @record_name = master_table_info.consumer_name
          @phr_surgery.surgery_type = @record_name
        end
      end
    end
  end


  # Initilizes a new table record based on the params array and stores
  # it in an instance variable for the view.
  def init_new_record_from_params
    @phr_surgery = PhrSurgicalHistory.new
    if code = params[:code]
      @phr_surgery.surgery_type_C = code
    else
      @phr_surgery.surgery_type = params[:name]
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
    'Surgery'
  end
end