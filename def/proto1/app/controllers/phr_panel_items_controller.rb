class PhrPanelItemsController < BasicModeTableController
  before_action :load_obr, :except=>[:index]

  # A map from database record fields to form field names.
  DB_TO_FORM_FIELDS = {'obx5_value'=>'tp_test_value',
    'obx6_1_unit'=>'tp_test_unit', 'obx7_reference_ranges'=>'tp_test_range'}


  # GET /phr_records/:profile_id/phr_panels/:phr_panel_id/items
  def index
    @all = params[:more]=='true'
    @obr = @phr_record.obr_orders.find(params[:phr_panel_id])
    loinc_to_obx = {}
    @obr.obx_observations.each {|obx| loinc_to_obx[obx.loinc_num] = obx}
    @test_info = []
    PanelData.get_panel_timeline_def(@obr.loinc_num).each do |pd|
      # The panel title level 1, so skip that.  Also skip the panel_info
      # fields (e.g. comment).
      start_level = 2
      display_level = pd['disp_level']  # (the indent level)
      if display_level >= start_level and !pd['panel_info']
        if pd['is_test']
          loinc_num = pd['loinc_num']
          obx = loinc_to_obx[loinc_num]
          if @all || pd['required'] || obx
            @test_info << [display_level, pd['name'], obx, loinc_num]
          end
        else
          @test_info << [display_level, pd['name']]
        end
      end
    end
    @page_title =
      "Panel Values for #{@obr.panel_name}, #{@obr.test_date}"
  end


  # Show a page for added a new OBX (panel value)
  def new
    @data_rec = new_obx_from_params
    @data_rec.lastvalue_date = '(none)' if @data_rec.lastvalue_date.blank?
    load_new_vars
  end


  # Handles the response from the page return by the "new" action.
  def create
    @data_rec = new_obx_from_params
    update_record_with_params(@data_rec, self.class.update_fields,
      DB_TO_FORM_FIELDS)
    if save_record(@data_rec)
      redirect_to phr_record_phr_panel_items_path,
        :notice=>CHANGES_SAVED
    else
      load_new_vars
      flash.now[:error] = @data_rec.build_error_messages(@labels)
      render :action=>'new'
    end
  end


  # Shows a page for editing a saved OBX (panel value).
  def edit
    @data_rec = @obr.obx_observations.find(params[:id])
    load_edit_vars
  end


  # PUT /phr_records/[record id]/phr_panel/[panel id]/items/i
  # Handles the output of the form from "edit"
  def update
    @data_rec = @obr.obx_observations.find(params[:id])
    update_record_with_params(@data_rec, self.class.update_fields,
      DB_TO_FORM_FIELDS)
    if save_record(@data_rec)
      redirect_to phr_record_phr_panel_items_path(@phr_record, @obr.id),
        :notice=>CHANGES_SAVED
    else
      load_edit_vars
      flash.now[:error] = @data_rec.build_error_messages(@labels)
      render :action=>'edit'
    end
  end


  # DELETE /phr_records/[record id]/phr_allergies/1
  def destroy
    obx = @obr.obx_observations.find(params[:id])
    name = obx.obx3_2_obs_ident
    delete_record(obx)
    redirect_to phr_record_phr_panel_items_path,
      :notice=>"Deleted record for #{name}."
  end


  # End of action methods

  # Class Methods

  # Returns the form name of the form containing the fields in form_fields.
  def self.field_form_name
    PhrPanelsController.field_form_name
  end


  def self.form_fields
    PhrPanelsController::OBX_FORM_FIELDS
  end


  # Returns the name of the table for the resource managed by this controller.
  def self.get_resource_table
    # Cache it as an instance variable on the class, so that subclasses
    # have their own variable.
    #
    # Used by the edit action.
    @table_name ||= 'obx_observations'
  end


  # Returns the fields we allow to be updated from the form.  For lists we just
  # list the text field here, though actually the code field (or the alt field,
  # for CWE lists) is set.
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.update_fields
    %w{obx5_value obx6_1_unit obx7_reference_ranges}
  end


  private


  # Loads the OBR (panel) record from the params
  def load_obr
    @obr = @phr_record.obr_orders.find(params[:phr_panel_id])
  end


  # Raises an exception if the requested loinc number (in the params) is not found
  # within the current panel.  (In that case, the user is probably playing
  # around with the system.)
  #
  # Returns the loinc number if it is okay.
  def require_loinc_num
    loinc_num = params[:loinc_num]
    if !loinc_num # (then this is the edit page)
      loinc_num = params[BasicModeController::FD_FORM_OBJ_NAME][:loinc_num]
    end
    # Confirm that loinc_num is actually in this panel
    found_loinc = false
    PanelData.get_panel_timeline_def(@obr.loinc_num).each do |pd|
      if pd['loinc_num'] == loinc_num
        found_loinc = true
        break
      end
    end
    if !found_loinc
      raise "Loinc number #{loinc_num} does not belong to panel #{@obr.loinc_num}"
    end
    return loinc_num
  end


  # Returns a new ObxObservation partially initialized from the params hash.
  # The returned obx will have the obr_order_id, profile_id, loinc_num,
  # lastvalue_date, last_value, last_date(_ET,_HL7) fields set.
  def new_obx_from_params
    @data_rec = ObxObservation.new(:obr_order_id=>@obr.id,
      :loinc_num=>require_loinc_num, :profile_id=>@obr.profile_id)
    @data_rec.obx3_2_obs_ident = @data_rec.loinc_item.display_name
    latest_obx = @data_rec.get_latest_obx_observation
    if latest_obx
      @data_rec.lastvalue_date = latest_obx.value_with_age
      @data_rec.last_value = latest_obx.obx5_value
      @data_rec.last_date = latest_obx.test_date
      @data_rec.last_date_ET = latest_obx.test_date_ET
      @data_rec.last_date_HL7 = latest_obx.test_date_HL7
    end
    return @data_rec
  end


  # The name of the resource managed by this controller, in a format
  # fit for a page title.
  def resource_title
    'Panel Value'
  end


  # Loads things needed by both the "new" and the "edit" pages
  def load_new_edit_vars
    load_instance_vars
    value_answer_list = @data_rec.loinc_item.answer_list
    @value_list = value_answer_list.list_answers if value_answer_list
    @unit_list = @data_rec.loinc_item.loinc_units
    # For these pages, change the unit list so that the unit values
    # also display the range values, because they go together.
    @fds['tp_test_unit'].control_type_detail['fields_displayed'] =
      ['unit_with_range']
  end


  # Loads instance variables needed by the "edit" record page.
  def load_edit_vars
    load_new_edit_vars
    @page_title = "Edit Value for #{@data_rec.obx3_2_obs_ident}"
  end


  # Loads instance variables needed by the "new" record page.
  def load_new_vars
    load_new_edit_vars
    @page_title = "New Value for #{@data_rec.obx3_2_obs_ident}"
    # Set a default value for the units
    if @unit_list && @unit_list.size > 0
      @data_rec.obx6_1_unit_C = @unit_list[0].id
    end
  end
end
