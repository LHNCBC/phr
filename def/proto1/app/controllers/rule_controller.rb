class RuleController < ApplicationController
  before_action :admin_authorize
  before_action :show_header
  before_action :set_paper_trail_whodunnit

  helper FormHelper
  include FormHelper
  include ComboFieldsHelper
  include TextFieldsHelper

  protect_from_forgery

  # Shows the data rules (the rules that are not form-specific)
  def index
    if request.post?
      rule_type_code = params['fe']['rule_type_C']
      rule_type = nil
      case rule_type_code
      when 'RT1'
        rule_type = 'fetch'
      when 'RT2'
        rule_type = 'value'
      when 'RT3'
        rule_type = 'reminder'
      end
      if params['new']
        redirect_to "/#{rule_type}_rules/new"
      elsif params['edit']
        rule_id = params['fe']['rule_name_C']
        redirect_to "/#{rule_type}_rules/#{rule_id};edit"
      elsif params['view_all']
        redirect_to "/#{rule_type}_rules/show"
      elsif params['view_all_in_readable_format']
        redirect_to "/#{rule_type}_rules/show_in_readable_format"
      elsif params['delete'] && rule_type
        rule_id = params['fe']['rule_name_C']
        r = Rule.find(rule_id.to_i)
        rule_name = r.name
        if r.used_by_rules.empty?
          fn_list = r.used_by_forms.map(&:form_name)
          r.destroy
          expire_combo_rule =  (rule_type == "fetch" || rule_type == "value")
          rule_change_callback(fn_list, expire_combo_rule, true)
          flash[:notice] = "Rule \"#{rule_name}\" was deleted."
        else
          flash[:notice] = "Rule \"#{rule_name}\" deletion failed because it is being used by other rules."
        end
        redirect_to :action => "index"
      end
    end

    if !request.post?
      # Show the page
      @user_name = User.find_by_id(session[:user_id]).name
      rule_types = TextList.find_by_list_name('data_rule_types').text_list_items
      @rule_type_names = []
      @rule_type_codes = []
      @title = 'Rule Management'
      rule_types.each do |t|
        @rule_type_names << t.item_text;
        @rule_type_codes << t.code
      end
      render(:layout=>'nonform')
    end
  end # index

  # An AJAX handler to returns a list of data rules of a specified type.
  def get_rule_name_list
    type_code = params['code_val']
    rule_type = nil
    case type_code
    when 'RT1' # fetch rule
      rule_type = Rule::FETCH_RULE
    when 'RT2'
      rule_type = Rule::VALUE_RULE
    when 'RT3'
      rule_type = Rule::REMINDER_RULE
    end
    names = []
    codes = []
    Rule.where(:rule_type=>rule_type, :editable=>true).order(:name).each do |r|
      names << r.name
      codes << r.id
    end
    render(:plain=>{:rule_name=>[names, codes]}.to_json)
  end # get_rule_name_list


  # Shows the the reminder rules
  #
  # Parameters:
  # * readable_format - a boolean indicating whether we need to show rule
  #   expression and case expressions in a readable format (ie. without labels etc)
  def show_reminder_rules
    @readable_format = params[:readable_format] == 'true'
    # The following code uses two gems:  "ruport" (a table report generation
    # tool) and acts_as_reportable (an ActiveRecord extension for ruport).
    # See:  http://ruportbook.com/outline.html and http://www.rubyreports.org/
    rule_data = {}
    reminder_rules = Rule.reminder_rules
    # For each rule, generate html tables for the fetch rules, value rules, and
    # rule cases.
    reminder_rules.each do |r|
      tables = {}
      unless (@readable_format)
        t = r.rule_labels.report_table(:all,
          :conditions=>'rule_type="value_rule"',
          :only=>[:label, :rule_name],
          :methods => :rule_name)
        if t.count > 0
          t.column_names = ['Label', 'Rule Name']
          tables[:value_rules] = t.to_html
        end
        t = r.rule_labels.report_table(:all,
          :conditions=>'rule_type="fetch_rule"',
          :only=>[:label, :rule_name, :property],
          :methods => [:rule_name, :property_display_name])
        if t.count > 0
          t.column_names = ['Label', 'Rule Name', 'Property']
          tables[:fetch_rules] = t.to_html
        end
      end

      if r.rule_cases.count > 0
        # For the cases, we want to show the message, which is stored in the
        # parameters field.  We don't want to show the "message=>" part.  Ruport
        # will accept a symbol of a method name to call, so we create the one
        # needed.
        unless (@readable_format)
          ::RuleCase.class_eval do
            def message
              rule_actions[0].parsed_parameters['message']
            end
          end
          t = r.rule_cases.report_table(:all, :only=>[:case_expression],
            :methods=>:message, :order=>:sequence_num)
          tables[:expression] = r.expression
        else
          t = r.rule_cases.report_table(:all,
            :only =>  [:expression_in_readable_format],
            :methods=>[:expression_in_readable_format,
                       :message_in_readable_format],
            :order=>:sequence_num)
          tables[:expression] = r.rule_cases.first.rule_expression_in_readable_format
        end

        if t.count > 0
          t.column_names = ['Case Expression', 'Reminder']
          tables[:cases] = t.to_html
        end
      end
      rule_data[r.name] = tables
    end
    @rules = reminder_rules.sort {|x, y| x.name <=> y.name}
    @rule_data = rule_data
    render(:layout=>'nonform')
  end # show_reminder_rules


  # Shows the rules for a form.
  #
  # Parameters:
  # * form_name - name of the form which owns the rules being showed
  def show_rules
    @system_form_name = params[:form_name]
    @system_form = Form.find_by_form_name(@system_form_name)
    if (request.post?)
      # This should be a delete request
      begin
        delete_rule
        rule_change_callback(@system_form_name, true, true)
      rescue
        flash.now[:notice] = $!.message
      end
      # Now show the form with the remaining rules
    end
    @data_hash = Rule.data_hash_for_rule_form(@system_form)
    @action_url = "/forms/#{@system_form_name}/rules"
    form_name = 'rules'
    set_form_rule_page_title(form_name)
    render_form(form_name)
  end # show_rules


  # Upon receiving GET request, displays a form for entering a new rule or
  # modify the new rule carried over from a failed POST request.
  # Upon receiving POST request, creates a new rule using data received.
  #
  # Parameters:
  # * form_name - name of the form which owns the new rule
  # * type - type of the new rule
  # * rendering_form - name of the form to be displayed for entering new rule data
  # * fe - data used for creating a new rule (see actions: save_case_rule and
  #   save general_rule)
  def new_rule
    @system_form_name = params[:form_name]
    @system_form = Form.find_by_form_name(@system_form_name)
    @form_name = params[:rendering_form]
    @form = Form.find_by_form_name(@form_name)
    is_a_case_rule = params[:type].to_i == Rule::CASE_RULE
    @rule_data = nil # a data_hash like version of the submitted data (if any)
    @page_errors = []

    if (request.post?)
      redirected, rule, @rule_data = is_a_case_rule ?
        save_case_rule(true, @system_form, @form, @page_errors) :
        save_general_rule(true, @system_form, @form, @page_errors)
      if redirected # the save succeeded
        # Delete the form's cache
        rule_change_callback(@system_form_name, false, false)
      end
    end

    if (!request.post? || !redirected)
      # Change the form title to say "New" instead of "Edit"
      set_form_rule_page_title(@form_name)
      @form_title.sub!('Edit', 'New')
      if (!request.post?)
        @data_hash = is_a_case_rule ?
          Rule.data_hash_for_new_case_rule_page(@system_form) :
          Rule.data_hash_for_new_general_rule_page(@system_form)
      else
        @data_hash = is_a_case_rule ?
          rule.data_hash_for_case_edit_page(@page_errors, @rule_data) :
          rule.data_hash_for_general_edit_page(@page_errors, @rule_data)
      end
      @action_url = request.fullpath
      # For case rule form or general rule form, form cache will include the
      # AutoCompleter drop down list(s) which could be differed from various
      # system forms
      form_cache_name = "#{@form_name}_AND_#{@system_form_name}"
      render_form(@form_name, form_cache_name)
    end
  end # new_rule


  # Upon receiving GET request, displays a form for editing the existing rule
  # stored in database or carried over from a failure PUT request.
  # Upon receiving PUT request, updates the existing rule using data received.
  #
  # Parameters:
  # * form_name - name of the form which owns the rule
  # * id - ID of the rule
  # * fe - data used for editing the rule of the given id (see actions:
  #   save_case_rule and save general_rule)
  def edit_rule
    @system_form_name = params[:form_name]
    @system_form = Form.find_by_form_name(@system_form_name)
    @form_name = params[:rendering_form]
    @form = Form.find_by_form_name(@form_name)
    rule = @system_form.rules.find(params[:id])
    is_a_case_rule = rule.rule_type == Rule::CASE_RULE
    @rule_data = nil # a data_hash like version of the submitted data
    @page_errors = []

    if (request.put?)
      redirected, rule, @rule_data = is_a_case_rule ?
        save_case_rule(false, @system_form, @form, @page_errors) :
        save_general_rule(false, @system_form, @form, @page_errors)
      if redirected # the save succeeded
        # Delete the form's cache
        rule_change_callback(@system_form_name, false, false)
      end
    end
    if (!request.put? || !redirected)
      # Show the edit page
      @edit_action = true
      @data_hash = is_a_case_rule ?
        rule.data_hash_for_case_edit_page(@page_errors, @rule_data) :
        rule.data_hash_for_general_edit_page(@page_errors, @rule_data)
      @form_submission_method = :put # i.e. update the record (see _form_fields)
      @action_url=request.fullpath # submit the form back here

      # For case rule form or general rule form, form cache will include the
      # AutoCompleter drop down list(s) which could be differed from various
      # system forms
      form_cache_name = "#{@form.form_name}_AND_#{@system_form.form_name}"
      set_form_rule_page_title(@form_name)
      render_form(@form.form_name, form_cache_name)
    end
  end # edit_rule


  # Upon receiving GET request, displays a form for entering a new data rule
  # (including fetch_rule, reminder rule and value rule) or modifying a new data
  # rule with data carried over from a failed POST request.
  # Upon receiving POST request, creates a new data rule using received data.
  #
  # Parameters:
  # * rendering_form - name of the form to be displayed for creating a new data rule
  # * type - type of the new rule
  # * fe - a hash which contains data displayed on the form
  def new_data_rule
    @page_errors = []
    @form_name = params[:rendering_form]
    @form = Form.find_by_form_name(@form_name)
    rule = Rule.new(:rule_type => params[:type]) ###
    is_fetch_rule = rule.is_fetch_rule

    if request.post?
      rule_data = data_hash_from_params(params[:fe], @form)
      saved = rule.save_data_rule(rule_data)
      if saved # the save succeeded
        redirect_to('/rules')
        form_names = rule.used_by_forms.map(&:form_name)
        # newly created data rules needed in the data rule form cache
        rule_change_callback(form_names, true, true)
      end
    end

    if (!request.post? || !saved)
      @form.form_title.sub!('Edit', 'New')
      @data_hash = rule.data_hash_for_data_rule_page(@page_errors)
      # Fetch rule, adds combo field specs to data_hash
      if is_fetch_rule
        @data_hash = @data_hash &&
          add_combofieldspecs_to_fetch_data(@data_hash, @form_name)
      end
      @action_url = "new"
      render_form(@form.form_name)
    end
  end #new_data_rule


  # Upon receiving GET request, displays a form for modifying an existing data
  # rule using data pulled from database or carried over from a failed updating.
  # Upon receiving PUT request, updates the data rule using data received.
  #
  # Parameters:
  # * rendering_form - name of the form to be displayed for editing the existing
  #   data rule
  # * id - ID of the existing data rule
  # * fe - a hash which contains data displayed on the data rule form
  # * type - type of the data rule
  def edit_data_rule
    @page_errors = []
    @form_name = params[:rendering_form]
    @form = Form.find_by_form_name(@form_name)
    rule = Rule.find(params[:id])
    is_fetch_rule = rule.is_fetch_rule

    if (request.put?)
      rule_data = data_hash_from_params(params[:fe], @form)
      saved = rule.save_data_rule(rule_data)
      if saved
        redirect_to('/rules')
        form_names = rule.used_by_forms.map(&:form_name)
        rule_change_callback(form_names, is_fetch_rule, true)
      end
    end

    if (!request.put? || !saved)
      @form.form_title.gsub!("New", "Edit")
      # Show the edit page
      @edit_action = true
      @data_hash = rule.data_hash_for_data_rule_page(@page_errors)
      if is_fetch_rule
        # add combo field specs to data_hash
        @data_hash = add_combofieldspecs_to_fetch_data(@data_hash, @form_name)
      end

      @form_submission_method = :put # i.e. update the record (see _form_fields)
      @action_url=request.fullpath # submit the form back here

      render_form(@form_name)
    end
  end # edit_data_rule


  private


  # Sets the page title (@form_title) for the form rule pages
  #
  # Parameters:
  # * form_name - the name of the (rule) form being displayed
  def set_form_rule_page_title(form_name)
    @form = Form.where(form_name: form_name).take
    @form_title = @form.form_title % {system_form_name: @system_form_name}
  end


  # Saves the data for a general rule, based on parameter data from the form.
  #
  # Parameters
  # * is_new_rule - whether this is data for a new rule (true) or an existing
  #   one (false)
  # * system_form - the Form table record for the form being edited
  # * rule_form - the Form table record for the general rule page
  # * page_errors - an array for storing errors (if any) generated during the
  #   save attempt.  This is just for errors are are not also stored in the
  #   returned rule object.
  #
  # Returns - a boolean indicating whether a redirect command was issued,
  #  the rule object that was saved/created (or the invalid
  #  object if the save failed), and a data_hash-like version of the submitted
  #  form data.
  def save_general_rule(is_new_rule, system_form, rule_form, page_errors)
    @form = Form.find_by_form_name('edit_general_rule')
    rule_data = data_hash_from_params(params[:fe], @form)
    rule_data["id"] = params[:id]
    rule = nil
    error = false
    begin
      Rule.transaction do
        if is_new_rule
          rule = Rule.add_new_rule(rule_data['rule_name'],
            rule_data['rule_expression'],
            system_form.id)
        else
          rule = Rule.update(rule_data["id"],
                             { :name       => rule_data['rule_name'],
                               :expression => rule_data['rule_expression'] })
        end

        error = rule.errors.size > 0

        # Note that when saving, we want to use the errors
        # attribute of ModelRecord to store errors on the objects.  However,
        # that means we have to be careful to use the same instances of the
        # records (because the error messages are not stored in the database)
        # when building the data hash.
        cached_actions_hash = {}
        rule.rule_actions.each {|ra| cached_actions_hash[ra.id] = ra}
        rule_actions_data = rule_data['rule_actions']
        # Try to save the action data, but only if we have an non-nil id for the
        # rule.
        if (!rule.id.nil?)
          error = !save_action_data(rule, rule_actions_data,
            cached_actions_hash) || error
        end
        raise 'rollback' if error
      end # transaction

      if (error)
        # Throw an exception to role back the transaction
        raise 'validation'
      end
      redirected = true
      # Use rules_url (defined by the map.rules statement in routes.rb)
      # to send the browser back to the rules page.
      redirect_to(rules_url(:form_name=>system_form.form_name))

    rescue
      # If this was not the exception from a validation error (the messages
      # for which are stored in the errors attributes of the ActiveRecords),
      # and if it was not the exception for rolling back the transaction,
      # then if is probably a programming error.  Add the message to the
      # page errors.  (What the user will do with it, who knows, but at
      # least we can see it.)
      if ($!.message != 'validation' && $!.message != 'rollback')
        page_errors << 'System error - ' + $!.message
      end
    end # begin, rescue

    return redirected, rule, rule_data
  end # save_general_rule


  # Saves the data for a case rule, based on parameter data from the form.
  #
  # Parameters
  # * is_new_rule - whether this is data for a new rule (true) or an existing
  #   one (false)
  # * system_form - the Form table record for the form being edited
  # * rule_form - the Form table record for the general rule page
  # * page_errors - an array for storing errors (if any) generated during the
  #   save attempt.  This is just for errors are are not also stored in the
  #   returned rule object.
  #
  # Returns - a boolean indicating whether a redirect command was issued,
  #  the rule object that was saved/created (or the invalid
  #  object if the save failed), and a data_hash-like version of the submitted
  #  form data.
  def save_case_rule(is_new_rule, system_form, rule_form, page_errors)
    @form = Form.find_by_form_name('edit_case_rule')
    rule_data = data_hash_from_params(params[:fe], @form)
    rule_data["id"] = params[:id]
    rule = nil
    error = false
    redirected = false
    begin
      Rule.transaction do
        error = false
        if is_new_rule
          rule = Rule.new(:name=>rule_data['case_rule_name'],
            :expression=>rule_data['exclusion_criteria'],
            :rule_type=>Rule::CASE_RULE)
          rule.forms << system_form
          rule.save
        else
          rule = Rule.update(rule_data["id"],
                             { :name       => rule_data["case_rule_name"],
                               :expression => rule_data['exclusion_criteria'] })
        end

        # Note that when saving, we want to use the errors
        # attribute of ModelRecord to store errors on the objects.  However,
        # that means we have to be careful to use the same instances of the
        # records (because the error messages are not stored in the database)
        # when building the data hash.
        cached_cases_hash = {}
        cached_actions_hash = {}
        rule.rule_cases.each do |rc|
          cached_cases_hash[rc.id] = rc
          rc.rule_actions.each {|ra| cached_actions_hash[ra.id] = ra}
        end

        rule_cases_data = rule_data['rule_cases']
        # Require that there be at least one case.
        if (!rule_cases_data || rule_cases_data.size == 0)
          page_errors << 'Case rules must have at least one case.'
        elsif (!is_new_rule || rule.errors.size == 0)
          # Attempt the rest of the save.  (To proceed, we need "rule" to have
          # an id.)
          rule_cases_data.each do |case_data|
            case_id = case_data['rule_case_id']
            case_id = case_id.blank? ? nil : case_id.to_i
            case_order = case_data['case_order']
            case_expression = case_data['case_expression']
            case_comp_val = case_data['computed_value']
            case_attrs = {:sequence_num=>case_order,
              :case_expression=>case_expression,
              :computed_value=>case_comp_val}
            actions_data = case_data['case_actions']
            if (case_id)
              rule_case = cached_cases_hash[case_id]
              if !rule_case
                page_errors << 'An invalid rule case ID was submitted.'
              else
                if (!case_order && !case_expression && !case_comp_val)
                  # Delete the rule case -- the user has cleared the top
                  # row of data
                  rule_case.destroy
                else
                  # Update the rule case
                  rule_case.update_attributes(case_attrs)
                  error = !save_action_data(rule_case, actions_data,
                    cached_actions_hash) || error
                end
              end
            elsif (case_order || case_expression || case_comp_val)
              # A new rule case
              rule_case = RuleCase.new(case_attrs)
              rule.rule_cases << rule_case # saves rule_case

              # If there is an error, we can't continue trying to save
              # because the actions need a valid id for the rule_case.
              if (rule_case.errors.empty?)
                error = !save_action_data(rule_case, actions_data,
                  cached_actions_hash) || error
              end
            end
            error = error || !rule_case.errors.empty?
          end
        end

        # Save the rule, if it hasn't been already
        # when create a case rule, we have to save the rule again to generate
        # the needed js_function based on it's rule_cases because rule_cases
        # were not available when we first saved the case_rule (see line 227)
        rule.save
        error = error || rule.errors.size > 0

        raise 'rollback' if error
      end # transaction

      if (error)
        # Throw an exception to role back the transaction
        raise 'validation'
      end
      redirected = true
      # Use rules_url (defined by the map.rules statement in routes.rb)
      # to send the browser back to the rules page.
      redirect_to(rules_url(:form_name=>system_form.form_name))

    rescue
      # If this was not the exception from a validation error (the messages
      # for which are stored in the errors attributes of the ActiveRecords),
      # and if it was not the exception for rolling back the transaction,
      # then if is probably a programming error.  Add the message to the
      # page errors.  (What the user will do with it, who knows, but at
      # least we can see it.)
      if ($!.message != 'validation' && $!.message != 'rollback')
        @page_errors << 'System error - ' + $!.message
        stacktrace = [$!.message].concat($!.backtrace).join("\n")
        logger.debug(stacktrace)
        puts stacktrace # for when we're running tests
      end
    end # begin, rescue

    return redirected, rule, rule_data
  end #save_case_rule


  # Saves the action data for a rule or rule case.
  #
  # Parameters:
  # * rule_part - the rule or rule case
  # * actions_data - an array of table entries from the actions table
  #   of a rule or rule case
  # * cached_actions_hash - a hash of action IDs for the this rule_part
  #   to the RuleAction objects.  We cache these so we don't lose error
  #   messages that can be placed on the objects.
  #
  # Returns true if the save succeeded without errors
  def save_action_data(rule_part, actions_data, cached_actions_hash)
    error = false
    if (actions_data)  # a case might not have any actions
      # and fetch rules no longer have actions
      actions_data.each do |action_data|
        action_id = rule_part.class.to_s == "Rule" ?
          action_data['rule_action_id'] :
          action_data['case_action_id']
        action_id = action_id.blank? ? nil : action_id.to_i
        action_display_name = action_data['rule_action_name']
        action_row =
          RuleActionDescription.find_by_display_name(action_display_name)
        action_name = action_row.nil? ? action_display_name :
          action_row.function_name
        parameters = action_data['rule_action_parameters']
        affected_field = action_data['affected_field']
        action_C = action_data['rule_action_name_C']
        affected_field_C = action_data['affected_field_C']
        action_attrs = {:action => action_name,
          :affected_field => affected_field,
          :parameters => parameters,
          :action_C => action_C,
          :affected_field_C => affected_field_C }
        if (action_id)
          action = cached_actions_hash[action_id]
          if !action
            @page_errors << 'An invalid rule action ID was submitted'
          else

            if (!action_name && !parameters && !affected_field)
              # Delete the action

              action.destroy
            else
              # Update the action
              action.update_attributes!(action_attrs)
            end
          end
        elsif (action_name || parameters || affected_field)
          # A new action.
          action = RuleAction.new(action_attrs)
          rule_part.rule_actions << action
          action.save!
        end # if action_id, elsif...
        error = error || action.errors.size > 0
      end # each rule_actions
    end
    return !error
  end # save_action_data

  # Looks in params for an ID of a rule that should be deleted.  This
  # also expects the @system_form variable to have been set with the Form
  # instance from which we are deleting a rule.
  def delete_rule
    params[:fe].each do |k, v|
      if (m = /\Adelete_((general|case|fetch)_rule)(_\d+)\z/.match(k))
        record_id = v.to_i
        record = @system_form.send("rules").find_by_id(record_id)
        record.destroy if record
        break
      end
    end
  end #delete_rule


  # Generates combo field specs based on source_field and other parameters.
  # In fetch rule data hash, replaces the non_date_condition_value of the source
  # field with the newly generated specs so that the AutoCompleter content of
  # that field matches to the selected source field value
  #
  # Parameters:
  # * data_hash - a hash contains data of a fetch rule
  # * this_form_name - name of the fetch rule form (i.e. edit_phr_fetch_rule form)
  def add_combofieldspecs_to_fetch_data(data_hash, this_form_name)
    major_qualifier_options = {
      "group_data" => data_hash["major_qualifier_group"],
      "form_field_id" => 'fe_major_qualifier_value_1',
      "target_field_map" => {
        "non_date_condition_value" => "major_qualifier_value",
        "operator_1" => "operator_1",
        "source_field" => "major_qualifier_name",
        "source_field_C" => "major_qualifier_name_C"
      }}

    other_qualifier_options = {
      "group_data" => data_hash["non_date_fetch_qualifiers_group"],
      "form_field_id" => 'fe_non_date_qualifier_value_1',
      "target_field_map" => {
        "non_date_condition_value" => "qualifier_value",
        "operator_1" => "operator_1",
        "source_field" => "non_date_qualifier_name",
        "source_field_C" => "non_date_qualifier_name_C"
      }}

    list = [major_qualifier_options, other_qualifier_options].map do |opts|
      rtn = []
      qualifier_group  = opts["group_data"]
      form_field_id    = opts["form_field_id"]
      target_field_map = opts["target_field_map"]

      non_date_cond_val_key = target_field_map["non_date_condition_value"]
      operator_1_key        = target_field_map["operator_1"]
      source_field_c_key    = target_field_map["source_field_C"]
      source_field_key      = target_field_map["source_field"]

      qualifier_group && qualifier_group.each do |q|
        non_date_cond_val = q[non_date_cond_val_key]
        operator_1        = q[operator_1_key]
        source_field_c    = q[source_field_c_key]
        source_field      = q[source_field_key]

        this_val = non_date_cond_val || operator_1
        qv_combo_specs = get_combo_field_specs(
          source_field_c,
          form_field_id,
          this_form_name,
          source_field,
          true)
        logger.debug '^^^ got combo_specs for major_qualifier_value, specs: ' +
          qv_combo_specs.to_json

        qv_val = ['cmb_spec', this_val, {'responseText' => qv_combo_specs}]
        rtn << q.merge(non_date_cond_val_key => qv_val)
      end
      rtn
    end

    data_hash.merge!({'major_qualifier_group' => list[0],
                      'non_date_fetch_qualifiers_group' => list[1]})
    return data_hash
  end # add_combofieldspecs_to_fetch_data


  # Callback when there is any change happens to the rule system
  # Parameters:
  # * forms - Names of forms which maybe affected by the rule changes
  # * expire_combo_rule_flag - A flag indicating whether the caches for both
  #   new_reminder_rule and new_value_rule forms need to be expired
  # * expire_server_js_flag - A flag indicating whether the generated JavaScript
  #   file used at JavaScript server should be expired
  def rule_change_callback(forms, expire_combo_rule_flag = true,
      expire_server_js_flag = true)
    forms = [forms] if forms.is_a? String
    forms.each do |form|
      expire_form_cache(form)
    end
    if expire_combo_rule_flag
      expire_form_cache("new_reminder_rule")
      expire_form_cache("new_value_rule")
    end
#    forms.each do |form|
#      JsGenerator.clear(form)
#    end
    if expire_server_js_flag
      JsGenerator.remove(REMINDER_RULE_DATA_JS_FILE)
    end
  end

end
