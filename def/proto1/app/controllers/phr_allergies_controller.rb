class PhrAllergiesController < BasicModeTableController

  # GET /phr_records/[record id]/phr_allergies
  def new
    form_params = params[BasicModeController::FD_FORM_OBJ_NAME]
    @other_name = form_params[:other_name] if form_params
    if !params[:name_C] && @other_name.blank?
      @link_params = {}
      @no_type = true
      @code_param = :name_C
      @item_name = 'an allergen name'
      @items = PhrAllergy.allergy_name_list.collect {|i| [i.code, i.item_text]}
      load_new_vars
      render 'basic/table_select'
    else
      @data_rec = PhrAllergy.new
      if params[:name_C]
        @data_rec.allergy_name_C = params[:name_C]
      elsif @other_name
        @data_rec.allergy_name = @other_name
      end
      @data_rec.valid? # to load the display strings for those fields
      load_new_vars
      render 'basic/table_new'
    end
  end


  # POST /phr_records/[record id]/phr_allergies
  # Handles the output of the form from "new"
  def create
    @data_rec = PhrAllergy.new
    handle_create(@data_rec)
  end


  # GET /phr_records/[record id]/phr_allergies/1/edit
  # Displays a form for editing
  def edit
    @data_rec = @phr_record.phr_allergies.find_by_id(params[:id])
    load_edit_vars
    render 'basic/table_edit'
  end


  # PUT /phr_records/[record id]/phr_allergies/1
  # Handles the output of the form from "edit"
  def update
    @data_rec = @phr_record.phr_allergies.find_by_id(params[:id])
    handle_update(@data_rec)
  end


  # DELETE /phr_records/[record id]/phr_allergies/1
  def destroy
    handle_destroy('allergy_name')
  end


  private

  # Returns the fields that appear on the form (or whose code fields do).
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.form_fields
    %w{allergy_name reaction reaction_date allergy_comment}
  end


  # Returns the field that is the section header for the other fields.
  def self.section_field
    'allergies'
  end


  # Loads the instance variables for information about the fields in a drug record.
  def load_instance_vars
    super
    if @data_rec # A PhrAllergy
      @record_name = @data_rec.allergy_name
      @reactions = PhrAllergy.reaction_list
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
    'Allergy'
  end
end
