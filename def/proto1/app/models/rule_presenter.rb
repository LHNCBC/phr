module RulePresenter

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
  end #CLASS_METHODS

  def rule_presenter_data
    @rule_presenter_data
  end
  def rule_presenter_errors
    @rule_presenter_errors
  end


  # Returns true if the data rule is saved and vice versa
  #
  # Parameters:
  # * rule_data - a hash which contains data of a data rule
  def save_data_rule(rule_data)
    @rule_presenter_data = rule_data
    # clears errors
    @rule_presenter_errors = {}
    @rule_presenter_error_flag = false
    # clears all rule_data caches
    @rule_presenter_caches = {}

    begin
      case rule_type
      when Rule::FETCH_RULE
        save_fetch_rule(rule_data)
      when Rule::VALUE_RULE, Rule::REMINDER_RULE
        save_combo_rule(rule_data)
      end    
    rescue Exception => e
      raise e if (e.message != 'rollback')
    end
    # only when saving was failed, then use @rule_presenter_data to carry the rule
    # data for correction
    @rule_presenter_data = nil unless has_rule_presenter_error
    !has_rule_presenter_error
  end # save_data_rule


  def create_or_find_rule
    if !new_record?
      # load existing rule
      self.name = @rule_presenter_data["rule_name"]
      collect_rule_presenter_errors(self) unless self.valid?
      # rule_expression will be validated during rule parsing process
      self.expression = @rule_presenter_data['exclusion_criteria']

      # load existing rule and association data into caches
      labels_cached = {}
      @rule_presenter_caches[:labels] = labels_cached
      cases_cached = {}
      @rule_presenter_caches[:cases] = cases_cached
      actions_cached = {}
      @rule_presenter_caches[:actions] = actions_cached
      rule_labels.each do |rl|
        labels_cached[rl.id] = rl
      end
      rule_cases.each do |rc|
        cases_cached[rc.id] = rc
        rc.rule_actions.each {|ra| actions_cached[ra.id] = ra}
      end
    else
      # create_new_rule
      # 1) create a valid default rule so that we can keep creating assoicated objectes
      # 2) validate the rule using data retrived from the form
      self.name="foo_#{Time.now.to_i.to_s}"
      self.expression = "false"
      self.save!

      self.name = @rule_presenter_data["rule_name"]
      collect_rule_presenter_errors(self) unless self.valid?
      # rule_expression will be validated during rule parsing process
      self.expression = @rule_presenter_data['exclusion_criteria']
    end
  end

  def save_rule_labels
    label_data = @rule_presenter_caches[:labels]
    model = rule_labels # used for create a new one
    saved = true

    if fetch_rules_used = @rule_presenter_data["fetch_rules_used"]
      fetch_rules_used.each_with_index do |e, i|
        options = {}
        options[:rec_id] = e["fetch_rules_used_id"].to_i
        options[:rec_id] = nil if options[:rec_id] == 0
        options[:attrs] = {
          :rule_type => "fetch_rule",
          :label => e["fetch_rule_label"],
          :rule_name => e["fetch_rule_name"],
          :rule_name_C => e["fetch_rule_name_C"],
          :property => e["fetch_rule_property"],
          :property_C => e["fetch_rule_property_C"]
        }
        options[:has_rec_info] = !e["fetch_rule_name"].blank? || !e["fetch_rule_property"].blank?
        options[:cache] = label_data
        options[:model] = model
        # concat with Rails' error message to identify the row which has an invalid
        options[:rec_identifier] = "Label #{e['fetch_rule_label']}: "
        tmp = save_record(options)
        saved = false if saved && !(tmp && tmp.errors.empty?)
      end
    end

    if value_rules_used = @rule_presenter_data["value_rules_used"]
      value_rule_visited = []
      value_rules_used.each_with_index do |e, i|
        # Value Rule must not self-referencing
        if e['value_rule_name'] == @rule_presenter_data['rule_name']
          collect_rule_presenter_errors "Label #{e['value_rule_label']}: must not refer to its parent rule which may cause a circular referencing."
        end
        # validates duplicated value rules in 'Value Rules Used' section
        if value_rule_visited.include? e["value_rule_name"]
          collect_rule_presenter_errors "Duplicated value rule name '#{e['value_rule_name']}' found in Value Rules Used section"
        elsif !e['value_rule_name'].blank?
          value_rule_visited << e['value_rule_name']
        end

        options ={}
        options[:rec_id] = e["value_rules_used_id"].to_i
        options[:rec_id] = nil if options[:rec_id] == 0
        options[:attrs] = {
          :rule_type => "value_rule",
          :label => e["value_rule_label"],
          :rule_name => e["value_rule_name"],
          :rule_name_C => e["value_rule_name_C"]
        }
        options[:has_rec_info] = !e['value_rule_name'].blank?
        options[:cache] = label_data
        options[:model] = model
        # concat with Rails' error message to identify the row which has an invalid
        options[:rec_identifier] = "Label #{e['value_rule_name']}: "

        tmp = save_record(options)
        saved = false if saved && !(tmp && tmp.errors.empty?)
      end
    end
    saved
  end

  def save_rule_cases
    saved = true
    rule_cases_data = @rule_presenter_data['rule_cases']
    if (!rule_cases_data || rule_cases_data.size == 0)
      collect_rule_presenter_errors ( 'Case rules must have at least one case.')
    else #(!@is_new_rule || rule.errors.size == 0)
      #rc_size = rule_cases_data.size # detecting the last rule_case
      rc_size = 0 # detecting the last rule_case
      rule_cases_data.each_with_index do |e, index| 
        if !e['computed_value'].blank? ||
            !e['case_expression'].blank? ||
            !e['reminder'].blank?
          rc_size = index + 1
        end
      end

      rule_cases_data.each_with_index do |case_data,index|
        case_id = case_data['rule_case_id'].to_i
        case_order = index + 1
        case_expression = case_data['case_expression']
        case_comp_val = is_reminder_rule ? (case_data["reminder"] ? "1" : nil) :
          case_data['computed_value']

        case_attrs = {:sequence_num=>case_order,
          :case_expression=>case_expression,
          :computed_value=>case_comp_val}

        # validates missing case_expression or reminder messages
        #        str =  is_reminder_rule ? "Reminder message" : "Rule Value"
        #msg = "Missing #{str} for Case Expression \"#{case_expression}\"."
        #collect_rule_presenter_errors  msg if case_comp_val.blank? && !case_expression.blank?
        msg = "Case on row #{index+1}: Case Expression must not be blank."
        # Only the last non-empty row can have empty case expression
        collect_rule_presenter_errors msg if !case_comp_val.blank? && case_expression.blank? && (index + 1 != rc_size)

        options = {}
        options[:rec_id] = case_id == 0 ? nil : case_id
        options[:attrs] = case_attrs
        options[:has_rec_info] = case_expression || case_comp_val
        options[:cache] = @rule_presenter_caches[:cases]
        options[:model] = rule_cases # used for create a new one
        # identify the rows with invalid fields
        options[:rec_identifier] = "Case on row #{index+1}: "

        rc = save_record(options)
        saved = false if saved && !(rc && rc.errors.empty?)

        # Adjust error message
        if is_value_rule
          rule_presenter_errors[:rule_case].map{|e|e.gsub!("Computed value", "Rule Value")} if rule_presenter_errors[:rule_case]
        end

        # create reminder action for reminder rule
        if is_reminder_rule
          rule_presenter_errors[:rule_case].map{|e|e.gsub!("Computed value", "Reminder")} if rule_presenter_errors[:rule_case]
          action_name = RuleActionDescription.find_by_function_name("add_message")
          affected_field = FieldDescription.find_by_target_field("reminders")
          default_action_data = {
            #"case_action_id" => nil,
            "action" => action_name.function_name,
            "action_C" => action_name.id,
            "parameters" => case_data["reminder"],
            "affected_field" => affected_field.target_field,
            "affected_field_C" => affected_field.id
          }

          # if the rule case is valid, then create reminder action
          if (rc && !rc.destroyed? && rc.errors.empty?)
            ras = rc.rule_actions
            ra = ras.empty? ? ras.build(default_action_data) : ras.first
            ra.parameters = default_action_data["parameters"]
            ra.save
            collect_rule_presenter_errors(ra)
          end
        end
      end
    end
    saved
  end #save_rule_cases


  def create_or_find_fetch_rule
    if !new_record?
      # collects error msg for this rule
      self.name = @rule_presenter_data["rule_name"]
      collect_rule_presenter_errors(self) unless self.save
       
      rule_fetch_condition_cached = {}
      @rule_presenter_caches[:rule_fetch_conditions] = rule_fetch_condition_cached
      rule_fetch_conditions.each do |e|
        rule_fetch_condition_cached[e.id] = e
      end
    else
      # tries to get a rule_id requird for creating rule_fetch object
      self.name="foo#{Time.now.to_i.to_s}"
      self.save!
       
      # collects error msg for this rule
      self.name = @rule_presenter_data["rule_name"]
      collect_rule_presenter_errors(self) unless self.save

      # creates valid new rule_fetch so that we can keep creating rule_fetch_conditions
      rule_fetch = self.create_rule_fetch(
        :source_table => "not_empty", :source_table_C => "not_empty")

      # validate this rule_fetch record
      rule_fetch.source_table = @rule_presenter_data["source_table"]
      rule_fetch.source_table_C = @rule_presenter_data["source_table_C"]
      collect_rule_presenter_errors(rule_fetch) unless rule_fetch.save
      remove_unwanted_error_messages_on_fetch_rule_form("rule_fetch")
    end
  end

  def save_rule_fetch_conditions
    fetch_conditions_cache = @rule_presenter_caches[:rule_fetch_conditions]
    model = rule_fetch_conditions # used for creating a new RuleFetchCondition instance
    saved = true
    list = []

    # take the hash from a form
    map={:operator_1 => "operator_1", :operator_1_C => "operator_1_C"}
    map[:cond_type] = "Major"
    map[:cond_type_s] = RuleFetch::MAJOR_QUALIFIER
    map[:section] = "1st Section"
    map[:group_name] = "major_qualifier_group"
    map[:rec_id] = "major_qualifier_group_id"
    map[:source_field] = "major_qualifier_name"
    map[:source_field_C] = "major_qualifier_name_C"
    map[:non_date_condition_value] = "major_qualifier_value"
    map[:non_date_condition_value_C] = "major_qualifier_value_C"
    map[:has_rec_info] = ['major_qualifier_name', 'major_qualifier_value']
    list << map

    map={:operator_1 => "operator_1", :operator_1_C => "operator_1_C"}
    map[:cond_type] = "Other"
    map[:cond_type_s] = RuleFetch::OTHER_QUALIFIER
    map[:section] = "2nd Section"
    map[:group_name] = "non_date_fetch_qualifiers_group"
    map[:rec_id] = "non_date_fetch_qualifiers_group_id"
    map[:source_field] = "non_date_qualifier_name"
    map[:source_field_C] = "non_date_qualifier_name_C"
    map[:non_date_condition_value] = "qualifier_value"
    map[:non_date_condition_value_C] = "qualifier_value_C"
    map[:has_rec_info] = ['non_date_qualifier_name', 'qualifier_value']
    list << map

    list.each do |map|
      if fetch_conditions = @rule_presenter_data[map[:group_name]]
        visited_list = []
        fetch_conditions.each_with_index do |e, i|
          # validates duplicated source field name in '#{map[:cond_type]} Qualifier' section
          if visited_list.include? e["source_field"]
            collect_rule_presenter_errors "Duplicated source field '#{e['source_field']}' found in #{map[:section]}"
          elsif !e['source_field'].blank?
            visited_list << e['source_field']
          end

          e = correcting_rule_data(e, map)
          options ={}
          options[:rec_id] = e[map[:rec_id]].to_i
          options[:rec_id] = nil if options[:rec_id] == 0
          options[:attrs] = {
            :condition_type => map[:cond_type_s],
            :source_field => e[map[:source_field]],
            :source_field_C => e[map[:source_field_C]],
            :operator_1 => e[map[:operator_1]],
            :operator_1_C => e[map[:operator_1_C]],
            :non_date_condition_value => e[map[:non_date_condition_value]],
            :non_date_condition_value_C => e[map[:non_date_condition_value_C]]
          }
          options[:has_rec_info] = !e[map[:has_rec_info][0]].blank? || !e[map[:has_rec_info][1]].blank?
          options[:cache] = fetch_conditions_cache
          options[:model] = model
          # concat with Rails' error message to identify the row which has an invalid
          options[:rec_identifier] = "#{map[:section]}/ Row #{i+1}: "

          tmp = save_record(options)
          saved = false if saved && !(tmp && tmp.errors.empty?)
        end
      end
    end
    #collect_rule_presenter_errors "Please specify at least one fetching condition"  unless has_rule_fetch_condition_list
    remove_unwanted_error_messages_on_fetch_rule_form("rule_fetch_condition")
    saved
  end

  def correcting_rule_data(record, map)
    rtn = record.dup
    rec_id = rtn[map[:source_field_C]]
    if !rec_id.blank?
      db_field = DbFieldDescription.find(rec_id)
      if db_field.is_date_type
        rtn[map[:operator_1]] = rtn[map[:non_date_condition_value]]
        rtn[map[:operator_1_C]] = rtn[map[:non_date_condition_value_C]]
        rtn[map[:non_date_condition_value]] = nil
        rtn[map[:non_date_condition_value_C]] =nil
      elsif db_field.field_type == "Set - String"
        op = ComparisonOperator.find_by_display_value("is")
        rtn[map[:operator_1]] = op.display_value
        rtn[map[:operator_1_C]] = op.id
      else
        op = ComparisonOperator.find_by_display_value("equal (=)")
        rtn[map[:operator_1]] = op.display_value
        rtn[map[:operator_1_C]] = op.id
      end
    end
    rtn
  end
  

  def has_rule_presenter_error(error_type = nil)
    if error_type
      error_type = error_type.to_sym if error_type.is_a? String
      @rule_presenter_errors[error_type] && @rule_presenter_errors[error_type].size > 0
    else
      @rule_presenter_error_flag
    end
  end

  def collect_rule_presenter_errors(input, row_iden = nil)
    added = true
    if (input.is_a? ActiveRecord::Base) && !input.errors.empty?
      model = input.class.name.underscore
      @rule_presenter_errors[model.to_sym] ||= []
      @rule_presenter_errors[model.to_sym].concat( input.errors.full_messages.map{|e| "#{row_iden}" + e})
    elsif (input.is_a? String)
      @rule_presenter_errors[:general] ||=[]
      @rule_presenter_errors[:general] << input
    else
      added = false
    end
    @rule_presenter_error_flag = added unless @rule_presenter_error_flag
    @rule_presenter_error_flag  
  end

  
  private


  # Saves a fetch rule and raises error if not saved successfully
  #
  # Parameters:
  # * rule_data - data of a fetch rule to be saved
  def save_fetch_rule(rule_data)
    Rule.transaction do
      create_or_find_fetch_rule
      save_rule_fetch_conditions

      raise 'rollback' if has_rule_presenter_error
      # make sure the destroyed rule_fetch_conditions being removed
      # from self.rule_fetch.rule_fetch_conditions
      self.reload unless has_rule_presenter_error
     
      # Caches executable_fetch_query for rule data loading and
      # obx_observations data pre-fetching 
      self.rule_fetch.update_attributes(
        :executable_fetch_query_js => self.executable_fetch_query,
        :executable_fetch_query_ar => self.executable_fetch_query("active_record"))
    end # transaction
  end # save_fetch_rule


  # Saves either a value rule or reminder rule and raises error if not saved
  # successfully
  #
  # Parameters:
  # * rule_data - a hash which contains data of a reminder or value rule
  def save_combo_rule(rule_data)
    Rule.transaction do
      # creates a new default rule which must be valid so that we can keep working on associated objects
      # finds an existing rule and caches its associate rule data
      # validates rule name
      # using new rule presenter data from the form to valid and retrieve error messages if any
      create_or_find_rule # TODO: may need to merge this with save_rule_labels and cases - Frank

      # do the similar thing as create_or_find_rule
      save_rule_labels
      save_rule_cases

      # detect errors from rule parsing process
      unless has_rule_presenter_error
        self.reload
        self.name = @rule_presenter_data['rule_name']
        self.expression = @rule_presenter_data['exclusion_criteria']
        rule_parse_errs = parse_combo_rules
        rule_parse_errs.map{|e| collect_rule_presenter_errors e} unless rule_parse_errs.empty?
      end

      raise 'rollback' if has_rule_presenter_error
      # saves the form field values into the rule and its associated objects
      self.save!
    end # transaction
  end # save_combo_rule


  def save_record(options)
    rec_id = options[:rec_id]
    has_rec_info = options[:has_rec_info]
    model = options[:model]
    attrs = options[:attrs]
    cache = options[:cache]
    rec = nil

    unless rec_id 
      if has_rec_info
        #create
        rec = model.create(attrs)
        collect_rule_presenter_errors(rec, options[:rec_identifier]) if !rec.errors.empty?
      end
    else
      rec = cache && cache[rec_id]
      unless rec
        #add_error "wrong #{model.build.class.name.underscore} ID was submitted"
        model_name = model.build.class.name.underscore
        @rule_presenter_errors[model_name.to_sym] ||=[]
        @rule_presenter_errors[model_name.to_sym] << "wrong #{model_name} ID was submitted"
      else
        if has_rec_info
          # update
          rec.update_attributes(attrs)
          collect_rule_presenter_errors(rec, options[:rec_identifier]) if !rec.errors.empty?
        else
          #delete
          rec.destroy
        end
      end
    end
    rec
  end

  def remove_unwanted_error_messages_on_fetch_rule_form(str)
    # at this moment, we only validates the visible user inputs, not the hidden
    # code which actually controls the display value of user's input

    case str
    when "rule_fetch"
      list = @rule_presenter_errors[:rule_fetch]
      list && list.delete_if{|e| e.include?("Source table c")}
      list && list.map{|e| e.gsub!("Source table","Table field")}
    when "rule_fetch_condition"
      list = @rule_presenter_errors[:rule_fetch_condition]
      # the operator_1 value is coming from:
      # 1) value field on browser if the corresponding source field's type is date
      # 2) auto generated based on the cooresponding source field type
      #
      # when operator_1 is empty, then the inputting value field on browser is empty.
      # therefore user will expect to see error msg like
      # "value field must not be blank."
      #
      # wrong input of value field will be either blank or invalid
      list && list.delete_if{|e| e.include?("Operator 1 c")} # neglect code fields

      list && list.each_with_index do |e, index|
        # when the value field with date source field is blank
        if e.include?("Operator 1 must not be blank")
          list[index] = [e.split(":")[0],"Value field must not be blank."].join(": ")
          # when the value field input is invalid
        elsif e.include?("Operator 1")
          list[index] = [e.split(":")[0],"Value field is invalid"].join(": ")
        end
      end


      list && list.each_with_index do |e, index|
        # when the value field input is blank
        if e.include?("Non date condition value must not be blank.")
          list[index] = [e.split(":")[0],"Value field must not be blank."].join(": ")
          # when the value field input is not valid
        elsif e.include?("Non date condition value c is invalid.")
          list[index] = [e.split(":")[0],"Value field is invalid."].join(": ")
        end
      end

      list.uniq! if list
    else
      # do nothing
    end
  end

end
