class PhrConditionsController < BasicModeTableSearchController

  # POST /phr_records/[record id]/phr_conditions
  # Handles the output of the form from "new"
  def create
    @phr_condition = PhrCondition.new
    handle_create(@phr_condition)
  end


  # GET /phr_records/[record id]/phr_drugs/1/edit
  # Displays a form for editing
  def edit
    @phr_condition = @phr_record.phr_conditions.find_by_id(params[:id])
    load_edit_vars
    render 'basic/table_edit'
  end


  # PUT /phr_records/[record id]/phr_drugs/1
  # Handles the output of the form from "edit"
  def update
    @phr_condition = @phr_record.phr_conditions.find_by_id(params[:id])
    handle_update(@phr_condition)
  end


  # DELETE /phr_records/[record id]/phr_conditions/1
  def destroy
    handle_destroy('problem')
  end

  # The action for the submission from the search form
  def search
    handle_search('problem')
  end


  # The action for displaying and responding to the Research Studies form.
  def studies
    if request.get?
      @page_title = 'Research Studies'
      @studies_form = @@studies_form ||= Form.find_by_form_name('ct_search')
      @sub_title = @studies_form.sub_title
      if ! defined? @@studies_fds
        @@studies_fds = {}
        fields = %w{problem state age_group}
        fds = @studies_form.field_descriptions.where('target_field'=>fields)
        fds.each {|fd| @@studies_fds[fd.target_field] = fd}

        # Mock up a field description for 'problem'.  We are not getting
        # the data from the list, but from the user's records.
        problem_fd = @@studies_fds['problem']
        fake_problem_fd = OpenStruct.new(problem_fd.attributes)
        fake_problem_fd.control_type_detail = problem_fd.control_type_detail
        fake_problem_fd.code_field = 'problem'
        fake_problem_fd.list_code_column = 'problem'
        fake_problem_fd.control_type_detail['fields_displayed'] = ['problem']
        @@studies_fds['problem'] = fake_problem_fd

        @@states_list = TextList.find_by_list_name('state_choices').text_list_items
        @@state_code_to_abbrev = {}
        @@states_list.each {|s| @@state_code_to_abbrev[s.code] = s.item_text}
        @@age_list = TextList.find_by_list_name('ct_age_groups').text_list_items
      end
      @studies_fds = @@studies_fds
      @states_list = @@states_list
      @age_list = @@age_list
      @conditions = @phr_record.phr_conditions
    else
      url = 'http://clinicaltrials.gov/search?recr=Open&cond='
      form_params = params['phr']
      if (form_params)
        condition = form_params['alt_problem']
        condition = form_params['problem'] if condition.blank?
        url += URI.encode(condition)
        age_group = form_params['age_group_C']
        url += '&age='+age_group if !age_group.blank?
        state_code = form_params['state_C']
        if !state_code.blank? && state_code != '0-All'
          state_abbrev = @@state_code_to_abbrev[state_code]
          url += '&state1=NA%3AUS%3A'+state_abbrev if (state_abbrev)
        end
      end
      redirect_to url
    end
  end


  private

  # Returns the fields that appear on the form (or whose code fields do).
  # This is defined as a method rather than a oonstant so it can accessed from
  # the base class methods.
  def self.form_fields
    %w{problem present when_started cond_stop prob_desc}
  end


  # Returns the field that is the section header for the other fields.
  def self.section_field
    'problems_header'
  end


  # Loads the instance variables for information about the fields in a
  # conditions record.
  def load_instance_vars
    super
    if @phr_condition
      @record_name = @phr_condition.problem
      if !@record_name
        master_table_info = @phr_condition.gopher_term
        if master_table_info
          @record_name = master_table_info.consumer_name
          @phr_condition.problem = @record_name
        end
      end
      @statuses = PhrCondition.present_list
    end
  end


  # Initilizes a new table record based on the params array and stores
  # it in an instance variable for the view.
  def init_new_record_from_params
    @phr_condition = PhrCondition.new
    if code = params[:code]
      @phr_condition.problem_C = code
    else
      @condition_name = params[:name]
      @phr_condition.problem = @condition_name
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
    'Medical Condition'
  end
end
