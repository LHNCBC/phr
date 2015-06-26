class PhrDrugsController < BasicModeTableSearchController

  # Fields we allow to be updated from the form.  For lists we just list
  # the text field here, though actually the code field (or the alt field,
  # for CWE lists) is set.
  UPDATE_FIELDS = %w{drug_use_status drug_strength_form expire_date
      why_stopped name_and_route instructions drug_start stopped_date}


  # POST /phr_records/[record id]/phr_drugs
  # Handles the output of the form from "new"
  def create
    @phr_drug = PhrDrug.new
    handle_create(@phr_drug)
  end


  # GET /phr_records/[record id]/phr_drugs/1/edit
  # Displays a form for editing
  def edit
    @phr_drug = @phr_record.phr_drugs.find_by_id(params[:id])
    load_edit_vars
    render 'basic/table_edit'
  end


  # PUT /phr_records/[record id]/phr_drugs/1
  # Handles the output of the form from "edit"
  def update
    @phr_drug = @phr_record.phr_drugs.find_by_id(params[:id])
    handle_update(@phr_drug)
  end


  # DELETE /phr_records/[record id]/phr_drugs/1
  def destroy
    drug = @phr_record.phr_drugs.find(params[:id])
    name = drug.name_and_route
    delete_record(drug)
    flash[:notice] = "Deleted record for #{name}."
    redirect_to(phr_record_phr_drugs_path)
  end


  # The action for the submission from the search form
  def search
    handle_search('name_and_route')
  end


  private

  # Returns the fields that appear on the form (or whose code fields do).
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.form_fields
    %w{name_and_route drug_use_status drug_strength_form instructions
      drug_start stopped_date why_stopped expire_date}
  end


  # Returns the field that is the section header for the other fields.
  def self.section_field
    'drugs'
  end


  # Loads the instance variables for information about the fields in a drug record.
  def load_instance_vars
    super
    if @phr_drug
      @drug_name = @phr_drug.name_and_route
      drug_info = @phr_drug.drug_name_route
      if drug_info
        @strengths = drug_info.drug_strength_forms
        if !@drug_name
          @drug_name = drug_info.text
          @phr_drug.name_and_route = @drug_name
        end
      end
      @statuses = PhrDrug.drug_use_status_list
      @reasons = PhrDrug.why_stopped_list
    end
  end


  # Initilizes a new table record based on the params array and stores
  # it in an instance variable for the view.
  def init_new_record_from_params
    @phr_drug = PhrDrug.new
    if code = params[:code]
      @phr_drug.name_and_route_C = code
    else
      @drug_name = params[:name]
      @phr_drug.name_and_route = params[:name]# @drug_name
    end
  end


  # Loads instance variables needed by the "edit" record page.
  def load_edit_vars
    load_instance_vars
    @page_title = "Edit #{resource_title} Record for #{@drug_name}"
  end


  # The name of the resource managed by this controller, in a format
  # fit for a page title.
  def resource_title
    'Drug'
  end
end