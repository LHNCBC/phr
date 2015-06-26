# A base class for basic mode controllers that deal with tables of resources
# (e.g. phr_drugs and a phr_conditions, but not phrs) and for which the value
# for the main field is selected through a search page.
class BasicModeTableSearchController < BasicModeTableController
  layout 'basic'
  helper :phr_records

  # A limit on the number of terms returned for a search
  SEARCH_COUNT_LIMIT = 50

  # GET /phr_records/[record id]/phr_drugs/new
  def new
    code = params[:code]
    if !code && !params[:name]
      show_search_form
    else
      init_new_record_from_params
      load_new_vars
      render 'basic/table_new'
    end
  end


  private

  # Displays the search form
  def show_search_form
    load_search_vars
    render 'basic/table_search'
  end
  

  # Does the work for a "search" action.
  #
  # Parameters:
  # * search_field - the name of the field description describing the field
  #   whose contents are selected from the search results.
  # * form_name - the name of the form containing the search_field field
  #   description
  def handle_search(search_field, form_name = 'phr')
    form_params = params[:phr]
    if form_params
      @search_text = form_params[:search_text]
      if !@search_text.blank?
        phr_form = Form.find_by_form_name(form_name)
        fd = phr_form.field_descriptions.find_by_target_field(search_field)
        @total_hits, @item_codes, returned_field_data, @displayed_data =
          get_matching_field_vals(fd, @search_text, SEARCH_COUNT_LIMIT)
        if @total_hits == 0
          @item_codes, @displayed_data =
            get_suggestions_for_field(fd, @search_text)
        end
        @displayed_data.each_with_index do |e, i|
          @displayed_data[i] = e.join(TABLE_FIELD_JOIN_STR)
        end
      end
    end
    show_search_form
  end


  # Loads variables needed by the search action.
  def load_search_vars
    @table = self.class.get_resource_name
    @page_title = "#{resource_title} Name Lookup"
  end

end
