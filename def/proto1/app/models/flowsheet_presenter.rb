# A Presenter for the Flowsheet-- for now just for the basic mode.
class FlowsheetPresenter < PresenterBase

  attr_reader :panel_list # An array of panel names and loinc numbers
  attr_reader :selected_panels # A set of loinc numbers previously selected
  attr_reader :using_group_by # true if the user selected a "group by" other than "None"

  presenter_attrs([:group_by_list, # the "group by" list
      :date_range_list, :date_field_reqs]) # date range list

  # Returns a list of the target field names of the field descriptions used in
  # this page.
  def self.fields_used
    %w{group_by date_range start_date end_date in_one_grid include_all
       show_record_too}
  end

  # Creates a new flowsheet presenter
  #
  # Parameters:
  # * phr_record - a Profile instance for the profile containing the data
  #   for the flowsheet.  (This is optional, but if not provided there will
  #   be no profile data.)
  # * form_params - Parameters from the form which should be used if the form
  #   is redisplayed
  def initialize(phr_record=nil, form_params=nil)
    form_params = {} if !form_params # might be nil
    m = form_params.clone
    super(m)
    @data = DataRec.new(m)
    if !form_params.empty?
      @using_group_by = form_params[:group_by_C] != '1' # i.e. not "None"
    end
    if phr_record
      @phr_record = phr_record
      @panel_list = @phr_record.obr_orders.select(
                                           'distinct loinc_num, panel_name').to_a
      @selected_panels = Set.new(@phr_record.selected_panels) || Set.new
    end
  end


  # Initializes class variables
  def init_class_vars
    super
    c = self.class
    if c.group_by_list.nil?
      c.group_by_list = c.fds['group_by'].list_items
      c.date_range_list = c.fds['date_range'].list_items
      c.date_field_reqs = DataRec.date_requirements(['start_date', 'end_date'],
        'panel_view')
    end
  end


  # Returns the name of the form (forms table form_name) that describes
  # the form for which this is a presenter.
  def form_name
    'panel_view'
  end


  # Processes parameters from the form, and returns any errors messages.
  def process_params
    errors = nil
    if @form_params[:date_range_C] == '7' # 'Customize'
      @data.validate_date('start_date', date_field_reqs['start_date'])
      @data.validate_date('end_date', date_field_reqs['end_date'])
      start_errs = @data.errors[:start_date]
      end_errs = @data.errors[:end_date]
      if !start_errs.empty? || !end_errs.empty?
        errors = []
        start_errs.each {|e| errors << "Start date #{e}"} if start_errs
        end_errs.each {|e| errors << "End date #{e}"} if end_errs
      end
    end
    if @phr_record
      panel_params = @form_params[:panels]
      if panel_params
        panel_nums = []
        panel_params.each {|k,v| panel_nums << k if v=='1'}
        if panel_nums.empty?
          errors =
            ['No panels were selected to be displayed in the flowsheet.']
        end
        @phr_record.selected_panels = panel_nums
        @phr_record.save!
        @selected_panels = Set.new(panel_nums)
      end
    end
    return errors
  end

end
