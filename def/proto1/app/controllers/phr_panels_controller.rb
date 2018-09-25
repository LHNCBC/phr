class PhrPanelsController < BasicModeTableSearchController
  include FlowsheetGenerator

  around_action :xhr_and_exception_filter, :only=>[:get_paginated_flowsheet_data_hash]

  # The panel (OBR) fields that appear on the form (or whose code fields do).
  OBR_FORM_FIELDS = %w{tp_panel_testdate tp_panel_testdate_time
    tp_panel_testplace tp_panel_summary tp_panel_duedate}

  # The test record (OBX) fields that appear on the form (or whose code fields
  # do).
  OBX_FORM_FIELDS = %w{tp_test_name tp_test_value tp_test_lastvalue_date
    tp_test_unit tp_test_range}

  # Both OBX and OBR fields
  ALL_FORM_FIELDS = OBR_FORM_FIELDS + OBX_FORM_FIELDS

  # What are currently calling the section for the panels.
  PANELS_SECTION_TITLE = "Test Results & Trackers"

  # A map from database record fields to form field names.
  DB_TO_FORM_FIELDS = {'test_date'=>'tp_panel_testdate',
    'test_date_time'=>'tp_panel_testdate_time',
    'test_place'=>'tp_panel_testplace',
    'summary'=>'tp_panel_summary', 'due_date'=>'tp_panel_duedate'}

  # Displays the top level Test & Measures page, showing existing panel records.
  # If the requested format is JSON, this returns JSON for a DataTables table
  # for showing saved panels and the last entry date.
  def index
    @saved_panel_info = @phr_record.latest_obr_orders
    respond_to do |format|
      format.html {
        if params[:panel]
          # Load the panel records for this panel
          @panel_orders = @phr_record.obr_orders.where(loinc_num: params[:panel]).all
          @order_loinc_num = params[:panel]
        end
        @page_title = PANELS_SECTION_TITLE
        # Load @section_fd, for the help link
        f = Form.find_by_form_name(BasicModeTableController.field_form_name)
        @section_fd = f.field_descriptions.find_by_target_field(self.class.section_field)
        # index.html.erb
      }
      format.json {
        row_data = []
        @saved_panel_info.each do |obr|
          panel_link = render_to_string :partial=>'saved_panel_link', :locals=>{:obr=>obr}
          row_data << [obr.test_date, panel_link, obr.relatednames2]
        end
        render :json=> {:aaData => row_data}
      }
    end
  end


  # Shows the pages for creating a new panel
  def new
    code = params[:code]
    if !code
      if !params[:browse] and !params[:class]
        show_search_form
      else
        show_browse_form
      end
    else
      init_new_record_from_params
      load_new_vars
      render 'basic/table_new'
    end
  end


  # Handles the output of the form from "new"
  def create
    init_new_record_from_params
    # Update the other fields
    update_record_with_params(@data_rec, self.class.update_fields,
      DB_TO_FORM_FIELDS)
    @data_rec.profile_id = @phr_record.id
    if save_record(@data_rec)
      redirect_to phr_record_phr_panel_items_url(@phr_record, @data_rec),
        :notice=>CHANGES_SAVED + '  You may now enter panel values.'
    else
      load_new_vars
      flash.now[:error] = @data_rec.build_error_messages(@labels)
      render 'basic/table_new'
    end
  end


  # Shows the data for a saved panel.
  # GET /phr_records/[record id]/phr_panels/1
  def show
    load_instance_vars
    @obr = @phr_record.obr_orders.find(params[:id])
    @obr_form_fields = OBR_FORM_FIELDS
    @p = PhrPanelShowPresenter.new(@obr)
    @page_title = "#{@obr.panel_name} Record"
  end


  # GET /phr_records/[record id]/phr_panels/1/edit
  # Displays a form for editing
  def edit
    @data_rec = @phr_record.obr_orders.find(params[:id])
    load_edit_vars
    render 'basic/table_edit'
  end


  # The action for the submission from the search form
  def search
    handle_search('new_panel_list', 'panel_edit')
  end


  # Handles the output of the form from "edit"
  def update
    @data_rec = @phr_record.obr_orders.find(params[:id])
    update_record_with_params(@data_rec, self.class.update_fields,
      DB_TO_FORM_FIELDS)
    if save_record(@data_rec)
      redirect_to phr_record_phr_panel_path, :notice=>CHANGES_SAVED
    else
      load_edit_vars
      flash.now[:error] = @data_rec.build_error_messages(@labels)
      render 'basic/table_edit'
    end
  end


  # DELETE /phr_records/[record id]/phr_panels/1
  def destroy
    @data_rec = @phr_record.obr_orders.find(params[:id])
    handle_destroy('panel_name', :panel=>@data_rec.loinc_num)
  end


  # GET/POST /phr_records/[record id]/phr_panels/flowsheet
  def flowsheet
    @page_title = 'Panel Flowsheet'
    if request.get?
      # Get a list of saved types of panels
      @p = FlowsheetPresenter.new(@phr_record)
    else # assume post
      form_params = params[BasicModeController::FD_FORM_OBJ_NAME]
      @p = FlowsheetPresenter.new(@phr_record, form_params)
      flash.now[:error] = err = @p.process_params
      if !err
        if mobile_html_mode?
          # build list of loinc numbers for the panels
          # will become nil if no panel_items parameter available
          panel_item = form_params[:panel_item]
          panel_items = panel_item && [panel_item]
          @ajax_req_params = params.to_json # used for loading more flowsheet columns
        end
        in_one_grid = form_params[:in_one_grid] == '1'
        include_all = form_params[:include_all] == '1'
        @hide_empty_rows = form_params[:hide_empty_rows] == '1'
        @flowsheet, panel_info = flowsheet_html_and_js(@phr_record, panel_items,
          in_one_grid, include_all, form_params[:group_by_C],
          form_params[:date_range_C], @p.data.start_date_ET,
          @p.data.end_date_ET, @p.data.end_date)
      end
    end
  end


  # Returns paginated flowsheet columns in a hash format when an Ajax
  # request is received. This method is currently used for loading more
  # columns onto an existing mobile flowsheet table using Ajax call.
  def get_paginated_flowsheet_data_hash
    if mobile_html_mode?
      form_params = params[BasicModeController::FD_FORM_OBJ_NAME]
      p = FlowsheetPresenter.new(@phr_record, form_params)
      flash.now[:error] = err = p.process_params
      if err
        raise err
      else
        panel_item = form_params[:panel_item]
        include_all = form_params[:include_all] == '1'
        hide_empty_rows = form_params[:hide_empty_rows] == '1'

        panel_info = paginated_flowsheet_data_hash(@phr_record,
          panel_item, include_all, form_params[:group_by_C],
          form_params[:date_range_C], p.data.start_date_ET,
          p.data.end_date_ET, p.data.end_date,
          hide_empty_rows, p.using_group_by,
          params[:exist_cols], params[:columns_per_page])

        render :status=>200, :json=>panel_info.to_json
      end
    else
      raise "The method is not avaible in non-mobile mode."
    end
  end

  # End of actions

  # Start of class methods

  # Returns the form name of the form containing the fields in form_fields.
  def self.field_form_name
    'loinc_panel_temp'
  end


  # Returns the fields that appear on the form (or whose code fields do)
  def self.form_fields
    ALL_FORM_FIELDS
  end


  # Returns the fields we allow to be updated from the form.  For lists we just
  # list the text field here, though actually the code field (or the alt field,
  # for CWE lists) is set.
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.update_fields
    ['test_date', 'test_date_time', 'test_place', 'summary', 'due_date']
  end


  # Returns the name of the resource, pluralized, for use in routes.  In most
  # cases this will be the same a get_resource_table, but for the phr_panels
  # resource the table name is obr_orders.  Sub-classes can override this
  # to provide those kinds of differences.
  def self.get_resource_table
    'obr_orders'
  end

  # End of public class methods


  private

  # A class to use for the list items for the "where done" field
  class WhereDoneItem
    attr_accessor :item_text
    def initialize(p)
      @item_text = p
    end
  end


  # Displays the search form
  def show_search_form
    load_search_vars
    render 'search'
  end


  # Displays a page for selecting a panel (for a new record) from a list
  def show_browse_form
    @link_params = {}
    if !params[:class]  # haven't picked a class yet
      @code_param = :class
      @item_name = 'a panel class'
      @items = []
      Classification.where('p_id=1').order(:class_name).
        collect {|c| @items << [c.class_code, c.class_name]}
    else # haven't picked a name yet
      class_code = params[:class]
      @code_param = :code
      @item_name = 'a panel name'
      @items = []
      # Re-use the find_record_data method from the regular mode.
      item_data = Classification.find_record_data({'class_code'=>class_code},
        ['get_sublist'], 'panel_class')
      names, codes = item_data['get_sublist']
      names.each_with_index {|n, i| @items<<[codes[i], n]}
    end
    load_instance_vars
    @page_title = "New #{resource_title} Panel"
    render 'basic/table_select'
  end


  # Returns the field that is the contains the help and display label
  # for this section of the user's PHR.
  def self.section_field
    'tests'
  end


  # The name of the resource managed by this controller, in a format
  # fit for a page title.
  def resource_title
    'Tests & Measures'
  end


  # Loads variables needed by both the new and edit pages.
  def load_new_edit_vars
    load_instance_vars
    place_names = PanelData.get_merged_where_done_list(@user)[0]
    @places = []
    place_names.each {|p| @places << WhereDoneItem.new(p)}
  end


  # Loads instance variables needed by the "edit" record page.
  def load_edit_vars
    load_new_edit_vars
    @page_title = "Edit #{@data_rec.panel_name} Record"

  end


  # Loads instance variables needed by the "new" record page.  Assumes
  # the subclass defines resource_title and load_instance_vars.
  def load_new_vars
    load_new_edit_vars
    @page_title = "New #{@data_rec.panel_name}"
  end


  # Initilizes a new table record based on the params array and stores
  # it in an instance variable for the view.
  def init_new_record_from_params
    loinc_num = params[:code] ||
      params[BasicModeController::FD_FORM_OBJ_NAME][:loinc_num]
    if !LoincItem.find_by_loinc_num(loinc_num)
      raise "Invalid loinc number: #{loinc_num}"
    end
    @data_rec = ObrOrder.new(:loinc_num=>loinc_num)
    @data_rec.panel_name = @data_rec.loinc_item.display_name
  end

end
