class RuleData
  # Loads the rule data into hash maps for use for rendering a form
  # template.  This also (because it is convenient) loads the parameter
  # fields, which contains the top-level fields of the form. The rule data
  # is loaded into the hash maps with the following keys:
  # * :field_rules - a hash map from target_field names to a ordered list of
  #   rule names to be run when the field's value changes
  # * :rule_actions - a hash map from rule names to actions to be performed
  #   when the rule is evaluated.  Each action consists of an action name,
  #   the target name of an affected field (to which the action is applied--
  #   this may be null), and a hash map of parameters to be passed to the
  #   action method.
  # * :form_rules - an list of rule names for all fields on the form, in the
  #   in which they should be run
  # * :rule_trigger - map of rule names to one field target name that triggers
  #   the rule.  (This is used for running the rules when the form loads.)
  # * :rule_scripts - an array of JavaScript functions for running the rules.
  # * :case_rules - a hash map from rule names to 1(which means true) if  rule
  #   has rule cases.
  # * :hash_sets - a hash map from rule names to set of drug names where the set
  #   is a hash map from drug names to 1(which means true).

  # The delimiter used for building a combination key of target field and loinc number
  FIELD_LOINC_NUM_DELIMITER = ":"
  
  # The default delimiter. Currently used in generating a combination key for 
  # data sub-tables (e.g. groups of tests in obx_observations) and data fields
  DEFAULT_DELIMITER = "|"
 
  # data_table_list links to all data rules which also need to be loaded to the form
  def self.load_data_to_form(form)
    # form.rules is an assoication object, it could be altered accidentally without noticing
    # use form.rule_ids instead
    all_rule_ids = form.rule_ids
    
    form.foreign_form_ids.each {|id| all_rule_ids.concat(Form.find(id).rule_ids) }
    all_rules = Rule.find(all_rule_ids.uniq)
    f_sorted_rules = Rule.complete_rule_list(all_rules)

    f_data_rules = required_data_rules_by_form(form, f_sorted_rules)
    
    options= load_data_from_fields(form) 
    options.merge!(load_data_from_rules( f_data_rules + f_sorted_rules))

    # load rule_set data
    options[:hash_sets] = RuleSet.load_rule_set_data(form)

    options
  end
  
  
  # Loads rule data into a hash map for generating health reminders. This method 
  # is used for generating health reminders using server side Javascript
  def self.load_reminider_rule_data
    f_data_rules = Rule.complete_rule_list(Rule.reminder_rules, "uses_rules")
    load_data_from_rules( f_data_rules )
  end


  #  def self.load_data_rules_by_tables(table_list)
  #    table_list = table_list.delete_if{|e| e.match(/_prefetched\z/)}
  #    table_ids = DbTableDescription.find_all_by_data_table(table_list).map(&:id)
  #    fetch_rules = RuleFetch.find_all_by_source_table_C(table_ids).map(&:rule)
  #    Rule.complete_rule_list(fetch_rules)
  #  end

  
  # Returns data rules required by this form. 
  def self.required_data_rules_by_form(form, form_rules)
    # 1) Gets all data rules directly used by from rules (so far, only value rules can be used by form rule)
    # 2) Gets all reminder rules if form has the reminders button
    # 3) Gets all other data rules used by the above data rules
    value_rules = form_rules.map{|r| r.uses_rules.select{|e| e.is_value_rule } }.flatten.uniq
    reminder_rules = form.show_reminders? ? Rule.reminder_rules : []
    Rule.complete_rule_list(value_rules + reminder_rules, "uses_rules")
  end

  private

  # Build a table of rules for each field on the form.
  # While we're at it, generate a list of the top-level main form fields.
  # Parameters:
  # * form the form where the rules will be working on
  def self.load_data_from_fields(form)
    field_rules = {}
    top_level_fields = []  # top-level main form fields
    # Add embedded fields 
    all_fields = form.fields + form.foreign_fields_with_rules
    all_fields.each do |f|
      top_level_fields << f if f.group_header_id.nil? && form.id == f.form_id
      rule_names = f.sorted_rules.map(&:name)
      field_rules[f.target_field] = rule_names if !rule_names.empty?
    end
    options={}
    options[:field_rules] = field_rules
    options[:fields]      = top_level_fields
    options
  end


  # Returns a hash containing the following rule data of a form. They are 
  # rule_scripts, rule_trigger, case_rules, rule_actions, fetch_rules, 
  # reminder_rules, db_field_rules, value_rules and data_rules
  #
  # Parameters:
  # * form_rule_objs - all the rules associated with a form.
  def self.load_data_from_rules(form_rule_objs)
#    form_rule_objs = Rule.find(form_rule_objs, 
#      :include => [:field_descriptions, :loinc_field_rules, 
#        {:rule_cases => :rule_actions}, :rule_actions])
    form_rules = []
    rule_scripts = []
    rule_trigger = {}
    case_rules = {}  # A set (map) of rule names for rules that are case rules
    rule_actions = {}
    
    fetch_rules = {} # same, for fetch rules
    reminder_rules = {} # same, for fetch rules
    db_field_rules = {} # same, for fetch rules
    value_rules = {} # same, for fetch rules
    data_rules = []
    # a hash from triggers to their rules. Each trigger has two pieces of 
    # information: a target_field and a loinc number joined with ":"
    loinc_field_rules = {}
    # a hash from a field to a list of rules which have actions on that field
    affected_field_rules = {}

    form_rule_objs.each do |r|
      form_rules << r.name
      rule_scripts << r.js_function

      # rule_trigger
      trigger =  r.field_descriptions[0]
      if trigger
        rule_trigger[r.name] = trigger.target_field
      else
        lfr = r.loinc_field_rules[0]
        rule_trigger[r.name] =
          [lfr.field_description.target_field, lfr.loinc_item.loinc_num].join(
          Rule::FIELD_LOINC_RULE_DELIMITER ) if lfr
      end

      # case_rules & fetch_rules
      if r.is_case_rule
        case_rules[r.name] = 1 if r.rule_cases.size > 0
      elsif r.is_fetch_rule
        fetch_rules[r.name] = 1
        data_rules << r.name
      elsif r.is_reminder_rule
        reminder_rules[r.name] = 1
        data_rules << r.name
      elsif r.is_value_rule
        value_rules[r.name] = 1
        data_rules << r.name
      end

      # fetch_rules
      if r.is_fetch_rule
        fetching_query = r.executable_fetch_query
        fetch_rules[r.name] = fetching_query
        
        db_table = fetching_query[0]
        conds = fetching_query[1][0]
        tmp_conds = conds[:conditions]
        conds = conds[:order].nil? ? tmp_conds : tmp_conds.merge(conds[:order])

        # Since different types of observations (AKA loinc_num) should have
        # different rules, when trigger field is in obx_observations table, we
        # should include loinc_num in rule trigger definition
        if db_table == "obx_observations"
          loinc_num = conds.delete("loinc_num").values.first
          db_table = self.generate_group_name(db_table,loinc_num)
        end
        
        column_list = conds.keys
        column_list.push("obx5_value") unless column_list.include?("obx5_value")
        column_list.each do |column|
          key = self.generate_group_name(db_table, column)
          db_field_rules[key] ||= Set.new
          db_field_rules[key].add(r)
        end


        # The value/reminder rules should be updated whenever any fetch rule 
        # attribute they are using was changed
        r.used_by_rules.each do |rr|
          rr.find_trigger_fields_by_fetch_rule(r).each do |col|
            key = self.generate_group_name(db_table, col)
            db_field_rules[key] ||= Set.new
            # fetch rule value needs to be updated (e.g. if gender field changed
            # from male to female, we need to re-run fetch rule demographic_info 
            # to get the latest gender value to be used by value/reminder rules 
            db_field_rules[key].add(r) 
            db_field_rules[key].add(rr)
          end
        end
        
      end

      # rule_actions
      if r.is_case_rule || r.is_reminder_rule
        r.rule_cases.each do |rc|
          actions = rule_action_data(rc)
          rule_actions[r.name+'.'+rc.sequence_num.to_s] = actions if actions
        end
      else
        action_data = rule_action_data(r)
        rule_actions[r.name] = action_data if action_data
      end
      
      if !r.is_data_rule
        # Load loinc rule data
        r.loinc_field_rules.each do |e|
          target_field = e.field_description.target_field
          loinc_num = e.loinc_item.loinc_num
          key = [target_field, loinc_num].join(FIELD_LOINC_NUM_DELIMITER)
          
          loinc_field_rules[key] ||= []
          loinc_field_rules[key] << r
        end
        
        # Loads a hash from field to list of rules which have actions on the field
        if r.is_case_rule
          actions = r.rule_cases.map(&:rule_actions).flatten
        else
          actions = r.rule_actions
        end
        actions.map(&:affected_field).each do |f|
          affected_field_rules[f] ||= []
          affected_field_rules[f].push(r.name)
        end
      end
      
    end # END of form_rule_objs.each
    # Updates loinc_field_rules to include missing rules which uses the existing rules
    loinc_field_rules.each do |k,v|
      loinc_field_rules[k] = Rule.complete_rule_list(v).map(&:name)
    end   
 
    # When db_field is on change, all related fetch rules should be updated
    # Also, all the data rules which uses the fetch rules should also be updated
    db_field_rules.each do |key, fetch_rules_v|
      db_field_rules[key] = Rule.complete_rule_list(fetch_rules_v.to_a).map(&:name)
    end
    
    options = {}
    options[:form_rules]   = form_rules
    options[:rule_scripts] = rule_scripts
    options[:rule_trigger] = rule_trigger # data rule do not need trigger
    options[:case_rules]   = case_rules
    options[:rule_actions] = rule_actions
    # following are related to fetch rule
    options[:fetch_rules]  = fetch_rules
    options[:reminder_rules]  = reminder_rules
    options[:db_field_rules]  = db_field_rules
    options[:value_rules]  = value_rules
    options[:data_rules] = data_rules
    options[:loinc_field_rules] = loinc_field_rules
    options[:affected_field_rules] = affected_field_rules
    options
  end
  
  # Returns an array of action attributes of the input rule_part
  # The action attributes are: action, affected_field, parsed_parameters
  def self.rule_action_data(rule_part)
    actions = nil
    rc = rule_part.rule_actions
    if !rc.empty?
      actions = []
      rc.each do |action|
        actions << [action.action, action.affected_field,
          action.parsed_parameters]
      end
    end
    return actions
  end
  
  
  # Returns a string by joinning the input array with the constant 
  # DEFAULT_DELIMITER
  # Also see JavaScript version of this method named generateGroupName in 
  # rules.js.
  # Parameters:
  # * args the list of input arguments 
  def self.generate_group_name(*args)
    args.join(DEFAULT_DELIMITER);
  end


end
