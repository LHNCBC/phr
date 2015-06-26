class Rule < ActiveRecord::Base

  extend HasShortList
  include DataRule
  include RulePresenter

  acts_as_reportable # ruport gem
  has_paper_trail
  
  validates_uniqueness_of :name, :case_sensitive => false
  validate :create_validation, :on => :create


  # Sets up a method "used_by_rules" which provides access to the collection
  # of rules that directly use this rule.
  has_and_belongs_to_many :used_by_rules, class_name: 'Rule',
    join_table: 'rule_dependencies',
    association_foreign_key: 'used_by_rule_id'

  # Sets up a method "uses_rules" which provides access to the collection
  # of rules that this rule directly uses.
  has_and_belongs_to_many :uses_rules, class_name: 'Rule',
    join_table: 'rule_dependencies',
    foreign_key: 'used_by_rule_id'

  # Sets up a method "fields" that provides access to the collection of
  # fields that this rule directly uses.
  has_and_belongs_to_many :field_descriptions,
    join_table: 'rule_field_dependencies',
    foreign_key: 'used_by_rule_id'

  has_and_belongs_to_many :db_field_descriptions,
    join_table: 'rule_db_field_dependencies'

  has_and_belongs_to_many :forms, join_table: 'rules_forms'
  has_many :rule_actions, :dependent=>:destroy, :as=>:rule_part
  has_many :rule_cases, ->{ order("sequence_num") }, dependent: :destroy
  has_many :loinc_field_rules, dependent:  :destroy
  has_one :rule_fetch, dependent:  :destroy
  delegate :rule_fetch_conditions, :to => :rule_fetch
  delegate :db_table_description, :to => :rule_fetch
  has_many :rule_labels, dependent:  :destroy

  before_save :update_associations
  before_destroy :raise_error_if_used_by_other_rules


  # A value for the rule_type field for general, form-specific rules.
  GENERAL_RULE = 1

  # A value for the rule_type field for case rules (which are form specific).
  CASE_RULE = 2

  # A value for the rule_type field for fetch rules.
  FETCH_RULE = 3

  # A value for the rule_type field.
  SCORE_RULE = 4

  # Constant to specify rule type.
  VALUE_RULE = 5

  # Constant to specify rule type.
  REMINDER_RULE = 6

  # A template for a summary of a case rule
  CASE_RULE_TEMPLATE = ERB.new(%{
    Exclusions:  <%=r.expression%><br>
    <% r.rule_cases.each do |rc| %>
    Case:  <%=rc.case_expression%><br>
      <% rc.rule_actions.each do |ra| %>
      Action: <%=ra.action%>  Affected Field: <%=ra.affected_field%><br>
      <%end%>
    <%end%>
    })

  # template for display of fetch qualifiers and comparisons
  FETCH_RULE_TEMPLATE = ERB.new(%{
    <% if r.rule_fetch.has_conditions %>
      <% major_qualifiers = r.rule_fetch.major_qualifiers %>
      <% if !major_qualifiers.nil? %>
        Major Qualifiers:<br>
        <% major_qualifiers.each do |mq| %>
          <%=mq.condition_string%><br>
        <%end%>
      <%end%>
      <% other_qualifiers = r.rule_fetch.other_qualifiers %>
      <% if !other_qualifiers.nil? %>
        Other Qualifiers:<br>
        <% other_qualifiers.each do |oq|  %>
          <%=oq.condition_string%><br>
        <%end%>
      <%end%>
    <%end%>
    })

  # Fetch rule properties other than the column names of source table for the
  # fetch rule
  DEF_FETCH_RULE_PROPERTIES = ["Exist?"]

  # Loinc number for any loinc panel fields
  PANEL_LOINC_NUM = "34566-0"

  # The suffix used for filtering loinc related functions
  LOINC_FUNC_SUFFIX = "loincFn"

  # The prefix used for renaming rule variable from rule name to a combination of
  # prefix and rule id. Purpose of doing that is to make sure any rule name change
  # won't affect rule expressions which references the renamed rule through the 
  # rule variable.
  RULEKEY_PREFIX = "%%rule"

  # Hash map from JavaScript code to common user readable text and symbols
  READABLE_FORMAT_MAP = {
    "!=" => " <> ",
    "!"  => "NOT ",
    ">=" => " >= ",
    "<=" => " <= ",
    "<"  => " < ",
    ">"  => " > ",
    "==" => " == "}

  # List of loinc panel target fields
  @@loinc_panel_names =["tp_panel_testdate"]

  # A delimiter used for construct a string with loinc number and target field
  # for loinc fields
  FIELD_LOINC_RULE_DELIMITER =":"


  # A list of allowed JavaScript Math constants
  @@math_vars = nil

  # A list of allowed JavaScript Math functions
  @@math_methods = nil

  # A hash of allowed JavaScript Math constants
  @@math_var_hash = nil

  # A hash of allowed JavaScript Math functions
  @@math_method_hash = nil

  # A hash of allowed boolean operators, and the JavaScript operators
  # they turn into.
  @@boolean_ops = nil

  # A list of field operation methods in Def.FieldOps
  @@field_ops = nil

  # A regular expression instance for matching any field operation method in
  # @@field_ops
  @@field_ops_regex =  nil

  # A list of rule functions
  @@rule_functions = nil

  # Set of rule functions that need parens
  @@rule_function_parens = Set.new

  # The name of the variable that is used to hold a value for the current
  # year.
  @@year_var_name = 'thisYear'

  # The parameters field parsed into individual parameters.
  @params = nil

  cattr_reader :math_vars, :math_methods, :field_ops, :rule_functions

  # Initializes the class variables
  def self.class_init
    if (@@math_var_hash.nil?)
      @@math_var_hash = {}
      @@math_vars = %w(PI E)
      @@math_vars.each { |v| @@math_var_hash[v] = 1 }
      
      @@math_method_hash = {}
      @@math_methods = %w(abs ceil floor round exp pow sqrt log min max)
      @@math_methods.each {|m| @@math_method_hash[m] = 1}

      @@boolean_ops = {}
      @@boolean_ops['AND'] = '&&'
      @@boolean_ops['OR'] = '||'
      @@boolean_ops['NOT'] = '!'
      @@boolean_ops['FALSE'] = 'false'
      @@boolean_ops['TRUE'] = 'true'

      # The first four items of @@field_ops will be displayed on form rule
      # editing pages
      @@field_ops =
        %w(column_max column_blank column_contains latest_from_table
           latest_from_form field_blank select_fields field_length is_hidden
           has_list latest_with_conditions column_conditions is_test_due) <<
           "getVal_#{LOINC_FUNC_SUFFIX}"
      # @@field_ops_regex = Regexp.new(@@field_ops.join("|"))

      # The first eight items of @@rule_functions will be displayed in the
      # expression helper section of rule editing pages
      @@rule_functions = %w(today time_in_years find_month find_year
      years_elapsed_since convert_to_kg convert_to_meter field_exists_on_form
      index_of today_by_type intersect_with_set
      extract_values_from_fields get_drug_set to_date count_words
      alspac_hd_parser sum current_age is_blank phr_bar)
      @@rule_function_parens = Set.new # set of rule functions that need parens
      ['today'].each {|fn| @@rule_function_parens << fn}

     @@field_ops_regex = Regexp.new(@@field_ops.join("|"))
    end
  end
  self.class_init

  # Regular expression used for scanning various tokens, including Math variables,
  # Math methods, boolean operators, rule names, target_field, function names (
  # both general and field related functions), rule labels and case statements etc.
  def self.regex_for_rule_expression
    Regexp.new("((#{@@field_ops.join("|")})"+
        "\\(\\s*(([^\"\'\(\)]*)\\s*,\\s*)?)?([A-Za-z]\\w*|:)")
  end


  # Returns all existing rules of a specified type
  def self.general_rules; Rule.where({rule_type: GENERAL_RULE}); end
  def self.case_rules; Rule.where({rule_type: CASE_RULE}); end
  def self.fetch_rules; Rule.where({rule_type: FETCH_RULE}); end
  def self.reminder_rules; Rule.where({rule_type: REMINDER_RULE}); end
  def self.value_rules; Rule.where({rule_type: VALUE_RULE}); end
  def self.data_rules
    Rule.where({rule_type: [VALUE_RULE, REMINDER_RULE, FETCH_RULE]})
  end
  def self.score_rules; Rule.where({rule_type: SCORE_RULE}); end

  # rule type checking
  def is_general_rule; rule_type == GENERAL_RULE; end
  def is_case_rule; rule_type == CASE_RULE; end
  def is_fetch_rule; rule_type == FETCH_RULE; end
  def is_reminder_rule; rule_type == REMINDER_RULE; end
  def is_value_rule; rule_type == VALUE_RULE; end
  def is_data_rule; is_fetch_rule || is_reminder_rule || is_value_rule; end

  # TODO::need to be moved into data_rule.rb later
  # Parses the expression into executable JavaScript codes or readable expression
  # text for generating reminder rules report
  # Parameters:
  #
  # * expression - a saved rule expression or case expression
  # * ref_rule_names - Being used in generating JavaScript code. If a rule is in
  #   the ref_rule_names list, then we can reference that rule with a predefined
  #   rule variable. Otherwise, we need to first define the new rule variable
  #   before referencing it in JavaScript code
  # * found_labels - A hash from label name to its description defines all the
  #   labels being used in expression
  # * parsing_errors - list of error messages
  # * readable_format - A boolean indicating whether the returning text should
  #   be JavaScript code or readable text (ie. without labels)
  def self.combo_process_expression_part(expression, ref_rule_names,
      found_labels, parsing_errors, readable_format = false)
    labeled_value_rules_hash = {}
    found_labels.each do |label, rule_name|
      if label.first == "B"
        labeled_value_rules_hash[rule_name] = label
      end
    end

    rule_names = Rule.data_rules.map(&:name)
    # used for case_expression, computed_value, exclusion_criteria
    name_regex = Rule.regex_for_rule_expression
    js_lines = []

    # Make sure all = signs in the expression are part of ==
    expression = Rule.equal_sign_substitution(expression)

    # Lowercase all strings in quotes, so that comparsions are done lowercase.
    expression.gsub!(/([\'\"])(.*?)\1/) { |s| $1+$2.downcase+$1 }

    # Edit the expression, and check for illegal names at the same time.
    js_lines = []

    # replace symbols with words used for showing readable reminder rules
    if readable_format
      expression.gsub!(/(!=|!|>=|<=|>|<|==)/) do |s|
        READABLE_FORMAT_MAP[s]
      end
      expression.gsub!(/\s+/, " ")
    end

    expression.gsub!(name_regex) do |s|
      function_name = $2
      var_name = $5
      var_names = $4
      rtn = s
      upcase_s = s.upcase
      if @@math_var_hash[s]
        rtn = 'Math.' + upcase_s
      elsif @@math_method_hash[s]
        rtn = 'Math.' + s.downcase
      elsif @@boolean_ops[upcase_s] # checks for OR, AND operators
        rtn = readable_format ? upcase_s : @@boolean_ops[upcase_s]
        #parsing label in combo rule
      elsif (found_labels[s])
        rtn = readable_format ? found_labels[s] : "#{s}()"
      elsif (rule_names.member?(s))
        # when user enters a value rule name which has been labeled
        # then we should ask user to use that label
        if(labeled_value_rules_hash.keys.member?(s))
          parsing_errors <<
            "value rule '#{s}' being labeled as '#{labeled_value_rules_hash[s]}'"
        else
          rule_var = s + "_rule_val"
          if(!ref_rule_names.member?(s))
            ref_rule_names << s
            # See line 1109 for comments
            js_lines << "var #{rule_var} = function(){return Def.Rules.Cache.getRuleVal('#{s}');};"
          end
        end
        rtn = rule_var + "()"
      elsif (@@rule_functions.member?(s))
        rtn = 'Def.Rules.RuleFunctions.'+s
        rtn += '()' if @@rule_function_parens.member?(s)
      elsif (s == ':')
        rtn = ':'
      else
        parsing_errors << "Unknown expression '#{s}'"
      end
      rtn
    end
    
    return downcase_label_value(expression, js_lines)
  end# end of combo_process_expression_part


  # This gets called to validate a rule when it is saved.
  def validate
    if name.blank?
      errors[:base]=('Rule Name must not be blank.')
    elsif  name !~ /\A[[:alpha:]]\w*\z/
      errors.add(:name, 'must start with a letter, and contain only ' +
          'alphanumeric or _ characters.')
    end

    is_data_rule ? validate_data_rule : validate_form_rule
  end


  def validate_data_rule
    # data rule_name should not conflict with any target_field
    tf_names = FieldDescription.all.map(&:target_field).uniq
    if tf_names.include?(name)
      errors[:base]=("Rule name must not conflict with any target field")
    end

    if is_reminder_rule || is_value_rule
      validate_combo_rules
    elsif is_fetch_rule
      # Fetch rule does not use other rules
      if (!uses_rules.empty?)
        errors[:base]=("Fetch rule can not have uses_rules")
      end
    end
  end


  # This is the original validate method for validating form rules 
  def validate_form_rule

    if name
      begin
        # Rule.lookup_field supposed to raise an Exception since rule name can
        # not be the same as any target field on the same form
        Rule.lookup_field(name, forms[0].id)
        # If Rule.lookup_field did not raise Exception, then it means there is
        # a rule whose name is same as some target_field in the same form.
        # We need to fail the validation
        errors[:base]=("Rule name *#{name}* can not be the same as any"+
            " target_field in the same form")
      rescue
        # do nothing
      end
    end

    if (!is_case_rule && rule_cases.size > 0)
      errors[:base]=('A rule that is not a case rule cannot have cases')
    end
    # We would like to test here that case rules must have cases, but
    # we can't easily do that, because rule actions need to validate in
    # a way that requires access to a saved rule.
    #elsif (is_case_rule && rule_cases.size == 0)
    #  errors[:base]=('A case rule must have at least one case.')
    #end

    # Check that for case rules, the sequence numbers must be unique, and that
    # if a case expression is blank it is the last one.
    max_case_index = rule_cases.size-1
    used_sequence_nums = Set.new
    # Process the cases in order of their sequence number.  Although the
    # rule_cases association method pulls from the database in order, we might
    # at this point be working with a list that has been modified by adding
    # or revising rule_cases, so we can't rely on them being in order.
    rule_cases.sort_by {|rc| rc.sequence_num}.each_with_index do |rc, i|
      if (used_sequence_nums.member?(rc.sequence_num))
        errors.add(:order, 'must be unique')
      else
        used_sequence_nums << rc.sequence_num
      end
      if rc.case_expression.blank? && i<max_case_index
        rc.errors.add(:case_expression, 'cannot be blank except for the last '+
            'case.  (Check the order numbers.)')
      end
    end

    if (expression.blank? && !is_case_rule )
      #if (expression.blank? && !is_case_rule)
      # This is not a case or fetch rule, so the expression needs to non-blank.
      errors.add(:rule_expression, 'must not be blank')
    else
      begin
        built_js_function = true # (maybe-- see below)
        if (is_case_rule)
          if rule_cases.size>0
            rule_script, referenced_fields, referenced_rules,referenced_loincs =
              build_case_rule_function
          else
            built_js_function = false
          end
        else
          rule_script, referenced_fields, referenced_rules, referenced_loincs =
            Rule.build_expression_function(name, expression, forms[0].id)
        end

        if (built_js_function)
          self.js_function=rule_script

          # Check that the referenced fields exist on all forms to which this rule
          # has been applied.
          all_field_objs = []
          rule_objs = nil
          all_loinc_param_objs =[]
          # so far each rule will only have one form
          # can not think of a case for a rule has multiple forms
          forms.each do |form|
            # referenced_fields is a Set object.
            field_objs, rule_objs, loinc_param_objs =
              Rule.check_field_and_rule_names(self, referenced_fields,
              referenced_rules, referenced_loincs, form.id)
            all_field_objs.concat(field_objs)
            all_loinc_param_objs.concat(loinc_param_objs)

            # rule_objs should remain the same for each form
          end
        end
      rescue
        errors.add(:rule_expression, ' - ' + $!.message)
        stacktrace = [$!.message].concat($!.backtrace).join("\n")
        logger.debug(stacktrace)
        # any use @response.body.include? to verify if the errors msg was
        # included in the response
        # (see rule_controller_test.rb#test_latest_blood_pressure_rule-line 199)
        # puts stacktrace # for when we're running tests
      end

      #      # Validates existing associations by comparing them with newly built
      #      # associations and find invalid or missing associated objects
      #      if(errors.empty? && !self.new_record? && !self.changed?)
      ##        validate_existing_associations(all_field_objs,
      ##          "field_descriptions", "target_field")
      ##        validate_existing_associations(rule_objs, "uses_rules", "name")
      #        # find all the missing rules of test panel
      #        missing_rules = all_loinc_param_objs.map do |ln, fld|
      #          find_by_attributes = %w(rule_id loinc_item_id field_description_id)
      #          r = LoincFieldRule.send("find_by_#{find_by_attributes.join("_and_")}",
      #                                  self.id, ln.id, fld.id)
      #          r ? nil : [ln, fld]
      #        end.compact
      #
      #        # create error messages for these missing rule of test panel
      #        unless missing_rules.empty?
      #          missing_rules.map do|ln, fld|
      #            err_msg = "The rule of test panel [rule:#{self.name}, loinc_item:"+
      #              "#{ln.loinc_num}, target_field:#{fld.target_field}] is missing.\n"
      #            err_msg += "\nPlease run command >> rake def:rebuild_rules\n"
      #            errors[:base]=(err_msg)
      #          end
      #        end
      #      end
      # pass these instance variables to the method: update_associations
      @built_js_function = built_js_function
      @all_field_objs =  all_field_objs
      @rule_objs= rule_objs
      @all_loinc_param_objs= all_loinc_param_objs
    end
  end # validate

  # For form rule, replace its associations using the ones stored in instance
  # variables. For fetch rule, replace its association db_field_descriptions
  # with the ones stored in rule_fetch_conditions table. For data rule, clear
  # association forms.
  #
  # List of instance variables used as inputs:
  # * @built_js_function a flag indicating whether we should rebuild JavaScript
  # function for this rule
  # * @all_field_objs list of field_descriptions associated with this rule
  # * @rule_objs list of rules used by this rule
  # * @all_loinc_param_objs list of two element arrays which has a loinc item
  # and a field_description
  def update_associations
    if (errors.empty? && @built_js_function)
      # Delete the information about what fields and rules this rule used.
      # 'delete_all' deletes associations, not the objects
      uses_rules.delete_all
      field_descriptions.delete_all

      if (!@all_field_objs.nil?)
        @all_field_objs.each {|fd| field_descriptions << fd}
      end
      if (!@rule_objs.nil?)
        @rule_objs.each {|r| uses_rules << r}
      end

      #LoincFieldRule.destroy_all(:rule_id => self.id)
      self.loinc_field_rules = []
      if (!@all_loinc_param_objs.nil?)
        @all_loinc_param_objs.each do |ln, fld|
          self.loinc_field_rules.build( :field_description => fld,
            :loinc_item => ln)
          end
      end
    end

    # update associated db_field_descriptions for fetch rule
    if is_fetch_rule
      db_field_descriptions.delete_all
      forms.delete_all

      rf_conds = rule_fetch && rule_fetch_conditions
      if rf_conds
        db_flds = rf_conds.map do |e|
          DbFieldDescription.find_by_id(e.source_field_C)
        end.uniq
        db_flds_wo_obs = db_flds.select do |e|
          e.db_table_description.data_table != "obx_observations"
        end
        db_flds_wo_obs.each{|f| db_field_descriptions << f}
      end
    end

    # Reminder/value rules should also be loaded onto the forms whose fields' values
    # may affect the values of fetch rules being used by these reminder/value rules
    if is_reminder_rule || is_value_rule
      forms.delete_all
    end

  end # update_associations

  # Returns list of forms where this rule will be loaded onto
  def used_by_forms
    if is_fetch_rule
      fetch_rule_forms
    elsif is_value_rule
      value_rule_forms
    elsif is_reminder_rule
      reminder_rule_forms
    elsif !is_data_rule
      forms
    end
  end


  # This gets called to validate a rule when it is created and saved.
  def create_validation
    unless is_data_rule
      if forms.nil? || forms.empty? #|| forms.size > 1
        errors[:base]=(
          'A rule must be associated with exactly one form when created.')
      else
        # Make sure a rule with this name does not already exist for this form.
        has_rule = false
        forms[0].rules.each do |r|
          if r.name == name
            has_rule = true
            break;
          end
        end
        if (has_rule)
          errors.add(:rule_name,
            'must be different from other rule names for this form')
        end
      end
    end
  end


  # This gets called to validate an updated rule when it is saved.
  # Also see create_validation method
  #def update_validation; end


  # Returns true if the this rule depends on (either directly or indirectly)
  # the given rule name, or if this rule has the same name as the given rule.
  def depends_on_rule?(other_rule_name)
    # Do a breadth-first search looking for rule other_rule_name.
    rtn = false
    nodes_to_check = [self]
    i = 0;
    while (!rtn && i<nodes_to_check.length)
      next_node = nodes_to_check[i]
      if (next_node.name == other_rule_name)
        rtn = true
      else
        nodes_to_check.concat(next_node.uses_rules)
      end
      i += 1
    end

    return rtn
  end


  # Finds all rules that use or used by (directly or indirectly) the
  # given collection of rules, and sorts them (together with the input rules)
  # into the order in which they need to be run.  The return value is the
  # sorted list of rules.
  #
  # Parameters:
  # * input_rules - a collection of Rule objects
  # * association_method - specify the relationship between input rules and the
  # additional rules to be included in the returning rule list
  def self.complete_rule_list(input_rules, association_method = "used_by_rules")
    unless %w(used_by_rules uses_rules).include? association_method
      raise "Second parameter '#{association_method.inspect}' of "+
            "Rule#complete_rule_list is not valid."
    end
    # A list of the rules in reverse order of how they should be run.
    rev_list = []
    # Keep track of which rules have been seen already in the (depth-first)
    # search.
    visited = Set.new

    # Start the depth-first search.
    input_rules.each do |r|
      rule_visit(r, rev_list, visited, association_method) if (!visited.member?(r))
    end

    return association_method == "used_by_rules" ? rev_list.reverse : rev_list
  end



  # Adds a new rule to the database and associates the rule with form form_id.
  # Any error messages resulting from validation will be accessible via the
  # errors method.
  #
  # Parameters:
  # * name - the name for the rule.  If this rule name already exists, an
  #   exception will be raised.
  # * rule_expression - an expression for the rule (e.g. 'age + 5 > 69')
  # * form_id - an ID of a form to associate with the rule.
  #
  # Returns:  the new Rule.  If valid, it was saved.  Otherwise (valid? returns
  # false) there will be error messages in "errors".
  def self.add_new_rule(name, rule_expression, form_id, type=GENERAL_RULE)
    form = Form.find_by_id(form_id)
    if (form.nil?)
      raise "Form id #{form_id} does not exist."
    end

    rule = Rule.new(:name => name,
      :expression => rule_expression,
      :rule_type => type)
    rule.forms << form

    rule.save # will try to validate the rule first
    return rule
  end


  # Adds an action to a rule.
  #
  # Parameters:
  # * action - the name of the action (e.g. hide)
  # * parameters - a string version of a hashmap in the format supported
  #   by the parse_hash_value method.  This may be nil.
  # * affected_field - the target_field name of the field on which the action
  #   acts (if any).
  #
  # Returns the new action object.
  #
  # NOTE that if you are accessing this through a migration or through
  #      any other code, you need to check for errors yourself.  Do this
  #      by checking the action_obj returned as follows:
  # ret_obj = the_rule.add_action(action, params, affected_field)
  # if !ret_obj.errors.empty?
  #   raise 'You lose!  Action ' + action + ' not added!'
  #
  def add_action(action, parameters=nil, affected_field=nil)
    action_obj = RuleAction.new(:action=>action, :parameters=>parameters,
      :affected_field=>affected_field)
    rule_actions << action_obj  # saved here, when added to the rule
    return action_obj
  end


  # Updates an existing rule with a new expression.  If the new expression
  # references rules or fields that are not already associated with the forms
  # that use the rule, an exception will be raised.
  #
  # Returns the saved rule.  If errors prevented the save, they will be
  # available via "errors".
  def self.update_rule(name, rule_expression)
    old_rule = Rule.find_by_name(name)
    if (old_rule.nil?)
      raise "Rule #{name} could not be updated because it does not exist."
    end

    old_rule.expression = rule_expression
    old_rule.save
    return old_rule
  end


  # Associates this rule with the given form.  (Note:  Do not use Rule.forms <<
  # to do that, because there is some additional set up that needs to be done.)
  def apply_to_form(form_id)
    # TBD - Not needed yet, but probably will be.
    # This will need to check the affected fields of the rule's actions to make
    # sure they exist on form form_id.
  end


  # Removes the rule from the given form.
  def remove_from_form(form_id)
    # TBD - Not needed yet, but probably will be.
  end


  # Completely deletes the rule from the database.  If this rule is used
  # by other rules, an exception will be raised.
  #
  # Parameters:
  # * name - the name of the rule to be deleted
  def self.delete(name)
    r = find_by_name(name)
#    if (r.used_by_rules.size > 0)
#      raise "Cannot delete rule #{name} because it is used by other rules."
#    end
    r.destroy
  end

  
  # Constructs and returns the JavaScript function for this case rule,
  # as well as a set of referenced field names and a set of referenced rule
  # names.
  def build_case_rule_function
    # We will construct an overall function for the case rule, plus
    # a function for the computed value of each case.
    # For the case rule function, we will keep track of which variables
    # have already been declared, so we don't do unnecessary computations.

    case_rule_lines = [
      "Def.Rules.rule_#{name} = function(prefix, suffix) {",
      'var depFieldIndex = 0;', 'var selectedOrderNum = null;']

    # Get the form ID of one of the forms to which this rule is applied.
    # We'll need that for determining field types when fields are referenced
    # by the rule.
    form_id = forms[0].id

    # Start with the exclusion criterion, which is in the expression field.
    if !expression.blank?
      js_declarations, expression_rtn,
        ref_field_names, ref_rule_names, ref_loinc_params =
        Rule.process_expression(expression, form_id)
    else
      # We still need to initialize those variables
      js_declarations = []
      expression_rtn = 'false' # default, i.e., no exclusion criterion
      ref_field_names = Set.new
      ref_rule_names = Set.new
      ref_loinc_params = Set.new
    end

    # Scan js_declarations for variable statements (which should be nearly
    # all of it.
    var_decls = js_declarations.grep(/\Avar /)
    # Add the javascript for the exclusion criterion to the case rule function.
    case_rule_lines.concat(js_declarations)
    case_rule_lines << "var exclusion = #{expression_rtn};"
    case_rule_lines << 'if (!exclusion) {'
    indent_level = 1 # for subsequent lines
    indent_per_level = '  '
    cur_indent = indent_per_level * indent_level

    # Process each case
    first_case = true
    case_computed_val_functions = []  # the JavaScript for the computed_values
    case_seq_nums = [] # the sequence numbers for the cases

    # Process the cases in order of their sequence number.  Although the
    # rule_cases association method pulls from the database in order, we might
    # at this point be working with a list that has been modified by adding
    # or revising rule_cases, so we can't rely on them being in order.
    rule_cases.sort_by {|rc| rc.sequence_num}.each_with_index do |rc, i|
      if (!first_case)
        # Add an else block
        case_rule_lines << cur_indent + 'else {'
        indent_level += 1
      end
      cur_indent = indent_per_level * indent_level

      if (!rc.case_expression.blank?)
        case_decls, expression_rtn,
          case_ref_fields, case_ref_rules, case_ref_loinc_params =
          Rule.process_expression(rc.case_expression, form_id)
        # Add any line in case_decls that is not already in var_decls.  For
        # each line that is a var statement, add it to var_decls (except for
        # the special variable case_val, which is used in JavaScript case
        # statements.)
        case_decls.each do |cd|
          if !var_decls.member?(cd)
            case_rule_lines << cur_indent + cd
            if (cd =~ /\Avar (\S+) =/ && $1 != 'case_val')
              var_decls << cd
            end
          end
        end # each case_decls

        # Add case_ref_fields and case_ref_rules to the sets for the whole
        # function.  These are sets, so we don't have to check for uniqueness.
        ref_field_names.merge(case_ref_fields)
        ref_rule_names.merge(case_ref_rules)
        ref_loinc_params.merge(case_ref_loinc_params)

        # Add the code for the cases' expression
        case_rule_lines << cur_indent + "if (#{expression_rtn}) {"
        indent_level += 1
        cur_indent = indent_per_level * indent_level
      end

      # Add the the case's computed value. This gets evaluated by
      # processActions(...), so it needs to be its own function.
      case_function, case_ref_fields, case_ref_rules, case_ref_loinc_params =
        Rule.build_expression_function('', rc.computed_value, form_id)
      # Adjust the function name and save the function for later
      case_computed_val_functions << case_function.sub('Def.Rules.rule_',
        'Def.Rules.ruleCaseVal_'+name+'_'+rc.sequence_num.to_s)

      # Add code to remember the selected case sequence number.
      case_rule_lines << "#{cur_indent}selectedOrderNum = #{rc.sequence_num};"
      case_seq_nums << rc.sequence_num;

      # Merge the sets of referenced fields and rules
      ref_field_names.merge(case_ref_fields)
      ref_rule_names.merge(case_ref_rules)
      ref_loinc_params.merge(case_ref_loinc_params)

      indent_level -= 1
      cur_indent = indent_per_level * indent_level
      case_rule_lines << cur_indent + '}'

      first_case = false
    end # each rule_cases

    # Now add the closing return statement, and join the function's lines
    # together.
    while (indent_level > 0)
      indent_level -= 1
      cur_indent = indent_per_level * indent_level
      case_rule_lines << cur_indent + '}'
    end
    case_rule_lines <<
      "return this.processCaseActions('#{name}', #{case_seq_nums.to_json}, "+
      "selectedOrderNum, prefix, suffix, null);\n}\n"

    main_rule_function = case_rule_lines.join("\n  ")
    all_functions =
      [main_rule_function].concat(case_computed_val_functions).join("\n")
    return [all_functions, ref_field_names, ref_rule_names, ref_loinc_params]
  end


  # Returns a JavaScript function for the given expression, as well as a
  # set of referenced field names and a set of referenced rule names.
  #
  # Parameters:
  # * name - the name of the rule for which the expression is being processed.
  #   This will be the name of the returned JavaScript function.
  # * expression - the expression (e.g. as entered by a form builder user)
  #   to be parsed and processed.
  # * form_id - the ID of a form to which the rule is (or will be) applied
  #
  # Returns:
  # * A string of JavaScript codes used for declaring JavaScript variables
  # * a set of referenced field names
  # * a set of referenced rule names
  def self.build_expression_function(name, rule_expression, form_id)
    js_declarations, expression_rtn,
      ref_field_names, ref_rule_names, ref_loinc_params =
      self.process_expression(rule_expression, form_id)
    js_declarations.unshift(
      "Def.Rules.rule_#{name} = function(prefix, suffix, depFieldIndex) {")
    js_declarations.push("return #{expression_rtn};\n}\n")
    return [js_declarations.join("\n  "), ref_field_names,
      ref_rule_names, ref_loinc_params]
  end


  # Returns JavaScript for the given expression, as well as a
  # set of referenced field names and a set of referenced rule names.
  #
  # Parameters:
  # * rule_expression - the expression (e.g. as entered by a form builder user)
  #   to be parsed and processed.
  # * form_id - the ID of a form to which the rule is (or will be) applied
  #
  # Returns:
  # * An array of javascript declarations (and possibly other code) that next
  #   to be interpreted prior to the second return value
  # * A javascript expression which, after the JavaScript lines in the first
  #   argument have been interpreted, will evaluate to the value of the rule
  #   expression parameter.
  # * a set of referenced field names
  # * a set of referenced rule names
  # * a set of referenced observation field identifiers made of loinc number and
  # target fields
  def self.process_expression(rule_expression, form_id)
    #rule_expression should have balanced parenthesises
    validate_balance_of_parentheses(rule_expression)
    # We want to allow the user to put anything they want inside quotation
    # marks,
    # e.g. somefield = 'Fred'.  This means we don't want to process or check
    # the contents inside quotes.  To do that, we will break up the expression
    # into pieces around the quotes (ignoring for escaped quotes within quotes)
    # and process the pieces one at a time.  Pieces that are quoted strings
    # will be included in the result without processing.

    ref_field_names = Set.new
    # Tries to make sure rule trigger is a non-sub-field if non-sub-field is 
    # available (see comments for parameter ref_sub_field_names of method
    # process_expression_part for details)
    ref_sub_field_names = Set.new
    ref_rule_names = Set.new
    ref_loinc_params = Set.new

    # Get a set of the rule names
    rule_names = Set.new(Rule.all.map(&:name))

    # An array of javascript lines, accumulated during processing.
    js_lines = []

    # Keep track of whether the expression is a case statement
    uses_case = false

    expression_list = Rule.quote_scanner(rule_expression)
    processed_parts = []
    expression_list.each do |part, quote_parts|
      processed_exp, js, uses_case =
        process_expression_part(part,
        ref_field_names, ref_sub_field_names, ref_rule_names, ref_loinc_params,
        rule_names, uses_case, form_id)
      processed_parts << processed_exp
      js_lines.concat(js)
      processed_parts = processed_parts.concat(quote_parts)
    end
 
    # If a case statement was used, we assume here the whole thing is a case
    # statement, and add the closing break and default code
    if (uses_case)
      js_lines << processed_parts.join('')
      js_lines <<
        "  break;\n  default:\n    throw new Def.Rules.Exceptions.NoVal();\n  }"
      expression_rtn = 'case_val'
    else
      # The full, processed expression should now be the concatenation of the
      # strings in processedParts.
      expression_rtn = processed_parts.join('')
    end

    ref_field_names = ref_field_names.merge(ref_sub_field_names)
    return [js_lines, expression_rtn, ref_field_names,
      ref_rule_names, ref_loinc_params]
  end # process_expression

  # Returns a list of two elements sub lists. Each sub list consists of a
  # un-quoted rule expression and a list of quoted strings
  # Parameters:
  # * rule_expression - rule expression which may include some quoted strings
  def self.quote_scanner(rule_expression)
    any_quote_regex = /(\\*)([\'\"])/;
    single_quote_regex = /(\\*)\'/;
    double_quote_regex = /(\\*)\"/;
    remainder = rule_expression.blank? ? "" : rule_expression.dup;
    done = false;
    processed_parts = [];
    while (remainder.length > 0 && !done)
      res = any_quote_regex.match(remainder);
      part = nil;
      quote_parts = [];
      if (res.nil?)
        done = true;  # this is the last piece
        part = remainder;
      else
        # We are outside of a quote, and just found one.  Throw an error if it
        # has any escape characters in front of it.
        esc_chars = res[1];
        if (res[1].length > 0)
          raise 'Quotes may not be escaped outside of strings.';
        end
        part = remainder[0 ... res.begin(0)];
        quote_char = res[2];

        # Find the end of the quotation.  Skip past escaped quotes.
        quote_parts = [quote_char];
        found_end_quote = false;
        remainder = remainder[res.begin(0)+1 .. -1];
        while (remainder.length > 0 && !found_end_quote)
          if (quote_char == "'")
            res = single_quote_regex.match(remainder);
          else
            res = double_quote_regex.match(remainder);
          end

          # If we didn't find the end of the quote, throw an error.
          if (res.nil?)
            raise 'Quoted strings must be terminated';
          end

          end_match_index = res.begin(0)+res[0].length;
          # Down-case quoted strings for case-insensitive searching.
          quote_parts << remainder[0 ... end_match_index].downcase;
          remainder = remainder[end_match_index .. -1];

          # Check the number of escape characters.  If it is even, then the
          # quote is not escaped.
          if (res[1].length % 2 == 0)
            # The end of the quote.
            found_end_quote = true;
          end
        end # while end of quote not found

        # If we didn't find the end quote, throw an exception
        if (!found_end_quote)
          raise 'Quoted strings must be terminated';
        end
      end # else not last piece

      processed_parts << [part, quote_parts]
    end
    processed_parts
  end


  # Raises error message if the rule_expression has unbalanced parentheses in it
  # Parameters:
  # * rule_expression - expression of a rule
  def self.validate_balance_of_parentheses(rule_expression)
    unless rule_expression.blank?
      lp = rp = []
      unbalanced_parentheses_msg = "parentheses not balanced"
      rule_expression.each_char do |c|
        if c == "("
          lp << c
        elsif c == ")"
          raise unbalanced_parentheses_msg if lp.empty?
          lp.pop
        end
      end

      raise unbalanced_parentheses_msg unless lp.empty?
    end
  end

  # This is used by process_expression (above) to process a part of an
  # expression.
  # (Expressions are broken into parts to handle quoted strings.)
  #
  # Parameters:
  # * expression - the piece of the expression text to be processed.
  # * ref_field_names - a set of the field names encountered so far
  # * ref_sub_field_names - a set of the sub-field names encountered so far. The 
  #    reason to add this parameters is to avoid tp_test_value being treated as 
  #    a trigger field during form loading period, 
  #    For example, the show_when_done_field_only rule was unnecessaryly 
  #    repeated for n times when calling runFormRules function on form loading 
  #    (where n matches to the number of fields in tp_test_value column of a 
  #    panel. The n can be >150 for some panel (e.g. searching it using keyword 
  #    'uri' in add test and panel page). Sine the column tp_test_value was 
  #    wrongly selected as the trigger, that rule has to be evaluated for each 
  #    field in tp_test_value column.
  #    The fix here is trying to re-order the rule's field_descritpions list to 
  #    change the trigger to non-column field (e.g. tp_panel_testdate). That way 
  #    we can minimize the number of rule evalulation from n to 1 (also see 
  #    trigger method in rule.rb for details). - Frank
  # * ref_rule_names - a set of the rule names encountered so far
  # * rule_names - the set of names that should be regarded as rule names
  #   when processing the expression.
  # * uses_case - whether a case statement has been found yet
  # * form_id - the ID of a form to which the rule is (or will be) applied
  #
  # Returns: The edited expression part, and an array of javascript lines
  #   that declare variables needed by the javascript expression
  def self.process_expression_part(expression, 
      ref_field_names, ref_sub_field_names, ref_rule_names, ref_loinc_params,
      rule_names, uses_case, form_id)
    # Make a regular expression that matches any name, and check that the
    # names are valid.
    name_regex = regex_for_rule_expression

    # Make sure all = signs in the expression are part of ==
    expression = self.equal_sign_substitution(expression)

    # Lowercase all strings in quotes, so that comparsions are done lowercase.
    expression.gsub!(/([\'\"])(.*?)\1/) { |s| $1+$2.downcase+$1 }

    # Edit the expression, and check for illegal names at the same time.
    js_lines = []

    expression.gsub!(name_regex) do |s|
      function_name = $2
      var_name = $5 
      var_names = $4
      rtn = s
      upcase_s = s.upcase
      if @@math_var_hash[s]
        rtn = 'Math.' + upcase_s
      elsif @@math_method_hash[s]
        rtn = 'Math.' + s.downcase
      elsif @@boolean_ops[upcase_s]
        rtn = @@boolean_ops[upcase_s]
      elsif (rule_names.member?(s))
        rule_var = s + '_rule_val'
        if (!ref_rule_names.member?(s))
          ref_rule_names << s
          # Get the value of the rule from the cached values hash
          #
          # Declare the referenced rule value as a function so that it will
          # be evaluated only when it's needed to avoid the exception as a
          # result of retrieving the value of a not needed (conditionally)
          # referenced rule
          # (e.g. when a rule was referenced in the right part of an OR statement
          # while the left part was true, retrieval of the value of the
          # referenced rule is not needed)
          js_lines << "var #{rule_var} = function(){ return Def.Rules.Cache.getRuleVal('#{s}');};"
        end
        rtn = rule_var + "()"
      elsif (@@rule_functions.member?(s))
        rtn = 'Def.Rules.RuleFunctions.'+s
        rtn += '()' if @@rule_function_parens.member?(s)
      elsif (s == 'case')
        if (!uses_case)
          # This is the first case statement we've found.  Insert the "switch".
          rtn = "var case_val=null;\n  switch(true) {\n  case"
          uses_case = true
        else
          # Put in the "break" for the preceeding case
          rtn = "    break;\n  case"
        end
      elsif (s == ':')
        if (uses_case)
          # assume this is a : following a case label.
          rtn = ': case_val =';
        else
          # What would this be?  This case probably won't happen.
          rtn = ':'
        end
      elsif (function_name)
        # We used to distinguish between column-oriented methods in Def.FieldOps
        # and others, but so far we just want to treat all of the methods the
        # same way.

        if function_name =~ @@field_ops_regex
 
          # A function NOT related to loinc panel fields
          if !function_name.include?(LOINC_FUNC_SUFFIX)
            if ["column_conditions","is_test_due"].include? function_name
              var_names = var_names ? "#{var_names},#{var_name}" : var_name
              var_name_list = var_names.split(",").map(&:strip)
              var_name_list.map{|e| ref_field_names << e}
              rtn = "Def.FieldOps.#{function_name}(prefix, suffix, "+
                "'#{var_name_list.join("|")}'"
            else
              # This is a method call to a Def.FieldOps column method.
              # Rewrite the method call into its full form.
              # Assume that var_name is a field name.

              hl7_code = "column_max" != function_name ? '' :
                lookup_field(var_name, form_id).hl7_data_type_code
              rtn = "Def.FieldOps.#{function_name}(selectField"+
                "(prefix,'#{var_name}',suffix,depFieldIndex, true).id,'"+
                hl7_code + '\''
              # Add the variable to the list of referenced fields.
              ref_sub_field_names << var_name
            end
            # A function works on loinc panel fields
            # input expression  ==>
            #   getVal_loincFn(loinc_num, target_field)
            # variables matched ==>
            #   func_name: getVal_loincFn
            #   var_name:  target_field
            #   var_names: loinc_num
          else
            # replace missing input with an empty string
            var_name_list = var_names.split(",").map(&:strip)
            var_name_list << var_name
            input_list = var_name_list.dup
            loinc_num = var_name_list.shift
            var_name_list.each do |e|
              target_field = e
              # Validate loinc_num and target_field
              lookup_loinc(loinc_num)
              lookup_field(target_field, form_id)
              # Update reference fields lists
              loinc_param = [loinc_num, target_field].join(FIELD_LOINC_RULE_DELIMITER)
              ref_loinc_params << loinc_param
            end

            # Build part of js_function
            rtn = "Def.FieldOps.#{function_name}(prefix, suffix, "+
              "'#{input_list.join("','")}'"
          end
        else
          # There are no other valid cases yet.
          raise "Invalid function name #{function_name}"
        end
      else # assume a field name
        # Set up the variable this field, if we haven't already
        field_var = "#{s}_field_val"
        if (!ref_field_names.member?(s))
          # Try to find the field in the database, to determine its control
          # type.  We don't know (here) what form to look in.  There could
          # be more two fields on different forms with different control types
          # with the same target name, but that is not something we should
          # support, since rules can be applied to multiple forms.  So,
          # assume the control types are the same if the field is on more than
          # one form.
          fd = lookup_field(s, form_id)
          js_lines <<
            "var #{field_var} = parseFieldVal(selectField(prefix,'#{s}'"+
            ',suffix,depFieldIndex, true));'
          ref_field_names << s;
        else
          # If rule parser found a target field again in the rear part of a long
          # expression, even though the target field already be recorded as a
          # trigger, we still need to double check to make sure the variable
          # which holds the target field value was not missed
          # (e.g. try to create a new rule using expression:
          # "field_blank(a_target_field) AND a_target_field != \"abc\"").
          field_def =  "var #{field_var} = parseFieldVal(selectField(prefix,'#{s}'"+
            ',suffix,depFieldIndex, true));'
          unless js_lines.include?(field_def)
            js_lines << field_def
          end
        end
        # Change the field name to the field variable name.
        rtn = field_var
      end
      rtn
    end

    return expression, js_lines, uses_case
  end# end of process_expression_part

  # Make sure all = signs in the expression are part of ==
  def self.equal_sign_substitution(expression)
    expression.gsub(/(\A|[^=!<>])=([^=<>]|\z)/, '\1==\2')
  end


  # Checks that is it okay for the rule, when applied to the given form,
  # to directly reference the given
  # fields and rules.  If there is a problem an exception is raised.  Otherwise,
  # this method returns the FieldDescription and Rule objects (as two arrays)
  # corresponding to the fields and rules parameters.
  #
  # Parameters:
  # * rule - the rule for which the check is being made
  # * field_names - the target field names the rule references
  # * rule_names - the names of the rules the rule references
  # * form_id - the ID of the form to which the rule is or will be applied
  def self.check_field_and_rule_names(rule, field_names, rule_names,
      loinc_params, form_id)
    field_objs = []
    rule_objs = []
    loinc_param_objs = []

    field_names.each do |field_name|
      found_fd_list = self.find_fields(field_name, form_id)
      raise(
        "Rule #{rule.name} references field #{field_name}, which does not "+
          " exist on form #{form_id}") if found_fd_list.empty?
      field_objs += found_fd_list
    end

    rule_names.each do |rule_name|
      if (rule.name == rule_name)
        raise "Rule #{rule.name} cannot reference itself."
      end

      ref_rule = Rule.find_by_name(rule_name)
      if (ref_rule.nil?)
        raise "Rule #{rule.name} references rule #{rule_name}, which does not"+
          'exist.'
      end

      # Make sure ref_rule has been applied to form form_id
      if (ref_rule.forms.find_by_id(form_id).nil? && !ref_rule.is_data_rule)
        raise "Rule #{rule.name} references rule #{rule_name}, which has not"+
          " been applied to form #{form_id}"
      end

      # Now check to make sure the referenced rule does not introduce a
      # circular dependency.
      if (ref_rule.depends_on_rule?(rule.name))
        raise "Rule #{rule.name} cannot reference rule #{rule_name},"+
          ' because that would create a cyclical dependency.'
      end

      # If rule name is same as a target field in expression, it will introduce
      # a circular dependency
      #      if rule.expression && rule.expression.include?(rule.name)
      if field_names.include?(rule.name)
        raise "Rule name:#{rule.name} can not be the same as the target field "+
          "name in the expression!"
      end

      rule_objs << ref_rule
    end

    # Checks to see if the loinc number is valid
    loinc_params.each do |ln_tf|
      loinc_num, target_field = ln_tf.split(FIELD_LOINC_RULE_DELIMITER)
      ln = LoincItem.find_by_loinc_num(loinc_num) unless loinc_num.blank?
      raise "The loinc number #{loinc_num} "+
        "does not exist in loinc_items table!" unless ln

      # target_field which related to a loinc number NO LONGER being included 
      # in the field_names (see the beginning of this function), thus it needs
      # to be validated here!!! - Frank   10-03-2011
      # 
      # target_fields must exist because it has been checked at the beginning
      # of this function
      found_fields = self.find_fields(target_field, form_id)
      raise(
        "Rule #{rule.name} references field #{target_field}, which does not "+
          " exist on form #{form_id}") if found_fields.empty?
   
      loinc_param_objs << [ln, found_fields[0]]
    end

    return field_objs, rule_objs, loinc_param_objs
  end # END OF check_field_and_rule_names

  # Returns a list of FieldDescription objects which has the specified
  # target_field in a form and its sub forms
  #
  #  Parameters:
  #  * target_field - target field name
  #  * form_id - a form id
  def self.find_fields(target_field, form_id)
    res =
      FieldDescription.find_by_target_field_and_form_id(target_field, form_id)
    res.nil? ?
      fields_from_other_forms(target_field, form_id) : [res]
  end

  # A form displayed on a webpage(main form) consists of many fields of its own 
  # and some fields coming from other forms. 
  # This method is to return a list of fields coming from other forms.
  #  
  # Parameters:
  # * field_name - target field name
  # * form_id - ID of the main form
  def self.fields_from_other_forms(field_name, form_id)
    Form.find_by_id(form_id).foreign_form_ids.map do |fid|
      FieldDescription.find_by_target_field_and_form_id(field_name, fid)
    end.compact
  end

  # Returns a structure that contains the data needed for the 'rule' form
  # (which displays a read-only form showing the rules for a form).
  #
  # Parameters:
  # * form - the Form instance for which the rules are needed
  def self.data_hash_for_rule_form(form)
    # Create the data hash needed by the form (for showing the rules)
    rules = form.rules

    # hide score rules
    rules = rules.select{|e| e.rule_type != SCORE_RULE}

    rule_table = []
    case_rule_table = []
    fetch_rule_table = []
    data_hash = {'general_rules'=>rule_table}
    data_hash['case_rules'] = case_rule_table
    data_hash['fetch_rules'] = fetch_rule_table
    rules.each do |r|
      row = {}
      if !r.is_case_rule && !r.is_fetch_rule
        #if !is_case_rule
        rule_table << row
        row['edit_general_rule'] = "#{r.id};edit"
        row['delete_general_rule'] = "#{r.id}"
        row['rule_name_ro'] = r.name
        row['rule_expression_ro'] = r.expression
        r.rule_actions.each do |ra|
          if (row.nil?)
            # This is not the first iteration.  Make a new row and add it.
            row = {}
            rule_table << row
          end
          row['rule_action_ro'] = ra.action
          row['rule_affected_field_ro'] = ra.affected_field
          row = nil
        end
      elsif r.is_case_rule
        # A case rule
        case_rule_table << row
        row['edit_case_rule'] = "#{r.id};edit"
        row['delete_case_rule'] = "#{r.id}"
        row['case_rule_name'] = r.name
        row['case_rule_summary'] = CASE_RULE_TEMPLATE.result(binding)
      elsif r.is_fetch_rule
        fetch_rule_table << row
        row['edit_fetch_rule'] = "#{r.id};edit"
        row['delete_fetch_rule'] = "#{r.id}"
        row['fetch_rule_name'] = "#{r.name}"
        row['source_table'] = r.rule_fetch.source_table
        row['qualifiers_comparisons'] = FETCH_RULE_TEMPLATE.result(binding)
        r.rule_actions.each do |ra|
          if (row.nil?)
            # This is not the first iteration.  Make a new row and add it.
            row = {}
            rule_table << row
          end
          row['fetch_action'] = ra.action
          row['fetch_affected_field'] = ra.affected_field
          row = nil
        end
      else
        # we don't know what type of rule this is!
      end
    end

    return data_hash
  end


  # Returns a structure that contains the data needed for the 'edit general
  # rule' form (which displays a form for editing a general rule).
  #
  # Parameters:
  # * errors - a list of errors for the page to which any error messages
  #     should be appended
  # * rule_data - a optional hash map of values that has the same structure as
  #    the returned data hash, and that contains form field values previously
  #    entered by the user.  (This is used for restoring a form's values
  #    is a submit fails.)
  def data_hash_for_general_edit_page(error_list, rule_data=nil)
    # Create the data hash needed by the form.
    error_list.concat(errors.full_messages)
    if rule_data
      data_hash = rule_data.clone
    else
      data_hash = {'rule_id' => id, 'rule_name'=>name, 'rule_expression'=>expression}
      action_table = []
      data_hash['rule_actions'] = action_table
    end

    rule_actions.each do |ra|
      error_list.concat(ra.errors.full_messages)
      if (!rule_data)
        action_table << {'rule_action_name'=>ra.action,
          'affected_field'=>ra.affected_field,
          'rule_action_id'=>ra.id,
          'rule_action_parameters'=>ra.parameters}
      end
    end
    data_hash['expression_help'] = Rule.form_rule_helper(forms, name)
    return data_hash
  end


  # Returns a structure that contains the data needed for the 'new general
  # rule' form (which displays a form for entering a new general rule).
  #
  # Parameters:
  # * system_form - the Form instance for which the rule is being created.
  def self.data_hash_for_new_general_rule_page(system_form)
    data_hash = {}
    data_hash['expression_help'] = Rule.form_rule_helper([system_form])
    return data_hash
  end


  # Returns a structure that contains the data needed for the 'new case
  # rule' form (which displays a form for entering a new case rule).
  #
  # Parameters:
  # * system_form - the Form instance for which the rule is being created.
  def self.data_hash_for_new_case_rule_page(system_form)
    # At present, this is exactly the same as the data hash for the new
    # general rule page.
    return self.data_hash_for_new_general_rule_page(system_form)
  end

  def self.data_hash_for_new_fetch_rule_page(system_form)
  end

  # Returns a structure that contains the data needed for the 'edit case
  # rule' form (which displays a form for editing a case rule).
  #
  # Parameters:
  # * errors - a list of errors for the page to which any error messages
  #     should be appended
  # * rule_data - a optional hash map of values that has the same structure as
  #    the returned data hash, and that contains form field values previously
  #    entered by the user.  (This is used for restoring a form's values
  #    if a submit fails.)
  def data_hash_for_case_edit_page(error_list, rule_data=nil)
    # Create the data hash needed by the form.
    error_list.concat(errors.full_messages)
    if rule_data
      data_hash = rule_data.clone
    else
      data_hash = {'rule_id' => id,
        'case_rule_name'=>name, 'exclusion_criteria'=>expression}
      rule_cases_table = []
      data_hash['rule_cases'] = rule_cases_table
    end

    rule_cases.each do |rc|
      error_list.concat(rc.errors.full_messages)
      if (!rule_data)
        action_table = []
        rule_cases_table << {'rule_case_id'=>rc.id,
          'case_order'=>rc.sequence_num,
          'case_expression'=>rc.case_expression,
          'computed_value'=>rc.computed_value,
          'case_actions'=>action_table}
      end

      rc.rule_actions.each do |ra|
        error_list.concat(ra.errors.full_messages)
        if (!rule_data)
          action_table << {'rule_action_name'=>ra.action,
            'affected_field'=>ra.affected_field,
            'case_action_id'=>ra.id,
            'rule_action_parameters'=>ra.parameters}
        end
      end
    end # each rule case

    data_hash['expression_help'] = Rule.form_rule_helper(forms, name)
    return data_hash
  end


  # Returns a hash containing functions, constants, rules and fields on forms in
  # form_list and which can be used in a new/existing rule 
  #
  # Parameters:
  # * form_list list of forms which own the rule being created/edited
  # * rule_name name of the existing rule which may use the functions, constants,
  # rules and fields in the returning hash
  def self.form_rule_helper(form_list, rule_name=nil)
    exp_help_grp = {}
    exp_help_grp['expression_fields'] = Rule.common_expression_fields(form_list)
    exp_help_grp['expression_rules'] = 
      Rule.allowed_expression_rules(form_list, rule_name)
    exp_help_grp['expression_functions'] =
        Rule.math_methods + Rule.field_ops[0..3] + Rule.rule_functions[0..7]
    exp_help_grp['expression_constants'] = Rule.math_vars
    exp_help_grp
  end
  
    
  # Returns a a sorted list of fields that are on all of the forms in the
  # form_list and which can be used in an expression for a rule.
  #
  # Parameters:
  # * form_list - the Form instance for which the rule is being created.
  def self.common_expression_fields(form_list)
    return common_expression_fields_set(form_list).sort
  end


  # Returns a a sorted list of fields that are on all of the forms in the
  # form_list and which can be used in an expression for a rule.  This is
  # the same as common_expression_fields, but it returns a set instead of
  # the sorted list.  (The common_expression_fields method calls this one.)
  #
  # Parameters:
  # * form_list - the Form instance for which the rule is being created.
  def self.common_expression_fields_set(form_list)
    common_fields = nil
    skip_control_types = Set.new(['group_hdr', 'static_text', 'message_button',
        'button', 'print_button', 'expcol_button'])
    form_list.each do |f|
      fields = Set.new
      f.field_descriptions.each do |fd|
        if (!skip_control_types.member?(fd.control_type) &&
              fd.target_field !~ /_EpochTime\z/)
          fields << fd.target_field
        end
      end
      if common_fields.nil?
        common_fields = fields
      else
        common_fields = common_fields & fields
      end
    end
    return common_fields
  end


  # Returns a list of rules that are on all of the forms in the form_list and
  # which can be used in an expression for a new/existing rule
  #
  # Parameters:
  # * form_list list of forms
  # * rule_name name of an existing rule (default to nil if it's for a new rule)
  def self.allowed_expression_rules(form_list, rule_name = nil)
    common_rules = []
    form_list.each do |f|
      if (common_rules.empty?)
        common_rules = f.rules
      else
        common_rules = common_rules & f.rules
      end
    end

    # Now check each rule in common rules to make sure there wouldn't be
    # a cyclical dependency if this rule used it.
    common_rules = common_rules.select{|r| !r.depends_on_rule?(rule_name)}
    return common_rules.map(&:name).sort
  end

  
  # Returns autocompleter list in an Array for fetch_rule_property field on
  # new_reminder_rule and new_value_rule forms
  def get_fetch_rule_properties
    rtn=[[],[]]
    if rule_fetch
      source_table_id = rule_fetch.source_table_C
      table_fields = DbFieldDescription.where(["virtual=? and db_table_description_id=? and display_name not like ?",
           false, source_table_id, "record id"]).load.compact.map{|e| [e.display_name, e.id]}.sort
      rtn[0] = table_fields.map(&:first)
      rtn[1] = table_fields.map(&:last)
      DEF_FETCH_RULE_PROPERTIES.map{|e| rtn[0] << e; rtn[1] << -1}
    end
    rtn
  end

  # Regular expression for matching rule id embedded rule variables in
  # rule expressions
  def self.regex_for_rule_key
    /#{Rule::RULEKEY_PREFIX}_((-|\+)?[0-9]+)/
  end

  # Switches rule variable naming convention between using rule name and using
  # prefixed rule id
  # Paramaters:
  # * rule_expression - rule expression which may use rule variables
  # * source - the current rule variable naming convention
  # * target - the intended rule variable naming convention
  def self.rename_rule_vars(rule_expression, source, target)
    source_opts = {
      :name =>[
        Rule.quote_scanner(rule_expression),
        # list of two elements arrays where first element is an expression
        # and the second is a list of quoted strings which don't need to be parsed
        Rule.regex_for_rule_expression,
        ## regexp for scanning
        0, #match_index
        "name" # rule field name of the token value
      ],
      :prefixed_id =>[
        rule_expression.blank? ? [] : [[rule_expression]],
        Rule.regex_for_rule_key, # regexp for scanning
        1, #match_index
        "id" # rule field name of the token value
      ]}

    case source
    when "name", "prefixed_id"
      rtn = []
      expression_list, regexp, match_index, token_field = source_opts[source.to_sym]
      expression_list.each do |sub_list|
        input_exp, quotes = sub_list
        tmp = input_exp.gsub(regexp) do |s|
          tk = match_index == 0 ? s : (match_index ==1 ? $1 : $2)
          r = Rule.send("find_by_#{token_field}", tk)
          r ?  r.send(target) : s
        end
        rtn << tmp
        rtn.concat quotes if quotes
      end
      rtn.join
    else
      raise "Rule#rename_rule_vars don't know how to rename rule variable " +
        "from '#{source.blank? ? 'blank' : source}'. Please use either 'name' or 'prefixed_id'"
    end
  end

  # Overwrites js_function setter method so that it will convert the rule name
  # into a unique key with rule id
  # 
  # Parameters:
  # * js_str a string of JavaScript codes translated from rule expression
  def js_function=(js_str)
    # Replaces foo_rule_val with %%rule_123_rule_val
    # where foo is a rule name, 123 is the id of that rule
    js_str = js_str.gsub(/(\w+)_rule_val/) do |s|
      if r = Rule.find_by_name($1)
        "#{RULEKEY_PREFIX}_#{r.id}_rule_val"
      else
        errors[:base]=("Rule name '#{$1}' is not valid.")
        s
      end
    end

    # Replaces getRuleVal('foo') with getRuleVal('%%rule_123')
    # where foo is a rule name, 123 is the id of that rule
    js_str = js_str.gsub(/getRuleVal\(\'(.*)\'\)/) do |s|
      if r = Rule.find_by_name($1)
        "getRuleVal('#{RULEKEY_PREFIX}_#{r.id}')"
      else
        errors[:base]=("Rule name '#{$1}' is not valid.")
        s
      end
    end

    # Replaces addLabel('XXXX','foo','YYYY') with addLable('XXXX', '%%rule_123', 'YYYY')
    # where foo is a rule name, 123 is the id of that rule, see RuleLabels class in rules.js
    js_str = js_str.gsub(/addLabel\('(\w+)',\s*'(\w+)',\s*'(\w*)'\)/) do |s|
      if r = Rule.find_by_name($2)
        "addLabel('#{$1}', '#{RULEKEY_PREFIX}_#{r.id}', '#{$3}')"
      else
        errors[:base]=("Rule name '#{$2}' is not valid.")
        s
      end
    end

    super js_str
  end

  # Overwrites js_function getter method so that the returning js_function will
  # have its rule variables replaced by their corresponding rule names
  def js_function
    rtn = attributes["js_function"]
    if rtn
      # Replace %%rule_123 with foo
      # where foo is a rule name with id 123
      rtn = rtn.gsub(Rule.regex_for_rule_key) do |s|
        rule = $1 && Rule.find_by_id($1)
        if rule
          rule.name
        else
          errors[:base]=("The rule referenced in js_function with id '#{$1}' is invalid.")
          s
        end
      end
    end
    rtn
  end

  # Overwrites expression setter method so that it will convert the rule name into
  # a unique key with rule id
  #
  # Parameters:
  # *input_exp original rule_expression string entered by user
  def expression=(input_exp)
    super Rule.rename_rule_vars(input_exp,"name", "prefixed_id")
  end

  # Overwrites expression getter method so that the returning expression will
  # have its rule variables replaced by their corresponding rule names
  def expression
    Rule.rename_rule_vars(attributes["expression"], "prefixed_id", "name")
  end

  # Returns a rule key with rule id to be using in rule expressions
  def prefixed_id
    "#{RULEKEY_PREFIX}_#{self.id}"
  end

  # Raises an error when trying to destroy a rule which is used by other rules
  # also see method: self.delete(name)
  def raise_error_if_used_by_other_rules
    if (self.used_by_rules.size > 0)
      raise "Cannot delete rule #{name} because it is used by other rules."
    end
  end
    
  # Returns the rule trigger to be used to run the runFormRules JavaScript 
  # function on client side
  def trigger
    if trigger = field_descriptions[0]
      trigger.target_field 
    else
      if lfr = loinc_field_rules[0]
        l = [lfr.field_description.target_field, lfr.loinc_item.loinc_num]
        l.join(Rule::FIELD_LOINC_RULE_DELIMITER ) 
      end
    end
  end
  
  private ################################################################

  # A recursive function used in the depth-first search to build an ordered
  # set of rules.  This searches in the direction of rules that use or being 
  # used by the given rules.
  # (This is the "visit" function in a depth-first search, which is
  # being used to do a topological sort of the rules for this field.)
  #
  # Parameters:
  # * rule - the (not yet visited) node to visit.
  # * rev_list - the list of rules to run, in reverse order of the order
  #   in which they should be run.  (The last element should be run first.)
  # * visited - a set of rules that have been visited.
  # * association_method - relationship between the give rules and rules to be 
  # searched (e.g. used_by_rules, uses_rules)
  def self.rule_visit(rule, rev_list, visited, association_method)
    visited << rule
    #rule.used_by_rules.each do |dr|
    rule.send(association_method).each do |dr|
      rule_visit(dr, rev_list, visited, association_method) if (!visited.member?(dr))
    end
    rev_list << rule
  end




  # Returns the FieldDescription object for the given target field name.  Throws
  # an exception if there isn't such a field.
  #
  # Parameters:
  # * field_name - the field name to retrieve
  # * form_id - the ID of a form to which the rule is (or will be) applied
  def self.lookup_field(field_name, form_id)
    fd = FieldDescription.find_by_target_field_and_form_id(field_name, form_id)
    return fd if fd
    field_objs_tmp = fields_from_other_forms(field_name, form_id)
    if field_objs_tmp.empty?
      raise( "Target field #{field_name} does not exist on form #{form_id}")
    end
    field_objs_tmp[0]
  end

  # Returns the LoincItem object for the given loinc number.  Throws an exception
  # if there is no such loinc number.
  #
  # Parameters:
  # * loinc_num - a loinc number.
  def self.lookup_loinc(loinc_num)
    if loinc_num && ( li= LoincItem.find_by_loinc_num(loinc_num) )
      return li if li
    end
    raise "The loinc number: " + loinc_num.to_s + " is not valid!!"
  end


  # Pre-build list of rules for displaying total scores of test panels if any
  #
  # Pre-assumption:
  # 1) Any answer_list for scoring should have a true flag in "has_score" field
  # 2) Any loinc_item linked to an answer_list with scores will be used for
  # calculating the total score
  # 3) Assuming in each test panel, there is only one loinc_panel for displaying
  # the total score. The formula value of this loinc_panel should be "sum"
  def self.load_score_rules
    # get loinc panel scoring groups in a hash map from root loinc panel to list
    # of leaf loinc panels
    lp_scoring_groups = {}
    answer_lists_with_scores = AnswerList.where({has_score: true})
    loinc_items_with_scores =
      LoincItem.where([
        "answerlist_id in (?) and included_from_phr = 1",
        answer_lists_with_scores.map(&:id)])
    loinc_items_with_scores.each do |loinc_item|
      loinc_item.loinc_panels.each do |loinc_panel|
        root = loinc_panel.root
        if root.loinc_item.included_from_phr
          lp_scoring_groups[root] ||= []
          unless lp_scoring_groups[root].include? loinc_panel
            lp_scoring_groups[root] << loinc_panel
          end
        end
      end
    end

    # find the loinc panels for displaying total scores
    total_score_lps = LoincPanel.where(["formula like ?","sum"])
    total_score_lps.each do |ts_lp|
      scoring_lps = lp_scoring_groups[ts_lp.root]
      raise "Don't know which loinc panels to use to get the #{ts_lp.display_name}" if scoring_lps.empty?

      panel_name = scoring_lps[0].parent.display_name +
        "_of_" +
        ts_lp.root.display_name
      ts_ln = ts_lp.loinc_num
      scoring_lns = scoring_lps.map(&:loinc_num)
      
      # build score rules based on:
      # 1) panel_name
      # 2) loinc number of loinc panel for showing total score (ts_ln) 
      # 3) loinc numbers of scoring loinc panels (scoring_lns)
      Rule.transaction do
        rule_name = panel_name.gsub(/(\.|\s+|-)/,"_")
        rule_name = "totalScore_#{rule_name}"

        rule_exp = scoring_lns.map do |score_ln|
          "getVal_loincFn(#{score_ln}, tp_test_score)"
        end.join( "+ '/' + ")
        rule_exp = "sum(#{rule_exp})"
        form = Form.find_by_form_name("phr")

        r = Rule.new(
          :name => rule_name,
          :expression => rule_exp,
          :rule_type => SCORE_RULE,
          :forms => [form])
        r.save!

        if ts_ln
          ra = r.rule_actions.build(
            :action => "set_or_clear_value",
            :parameters => "value=>javascript{Def.Rules.Cache.getRuleVal('#{rule_name}')}",
            :affected_field  => "tp_test_value:#{ts_ln}")
          ra.save!
        else
          raise "Don't know where to put the sum of test scores"
        end
        puts "   rule *" + r.name + "* was created!"
      end
    end

    ## print all scoring panels and their sub fields
    #keys = lp_scoring_groups.keys.sort_by{|e| e.display_name}
    #h=[]
    #keys.each do |k|
    #  h << { (k.display_name + "/" + lp_scoring_groups[k][0].parent.display_name)  =>
    #      lp_scoring_groups[k].map{|e| [e, AnswerList.find(e.loinc_item.answerlist_id).list_name]}.sort_by{|e| e[1]}.
    #      map{|e| {e[0].display_name => e[1]}}}
    #end
    #puts h.to_json + "\n\n\n"
  end

  protected

  # Returns list of forms this rule will be loaded onto if it's a fetch rule
  def fetch_rule_forms
    rtn = Set.new
    used_by_reminder_rule = false
    used_by_rules.each do |r|
      if r.is_value_rule
        rtn.merge(r.value_rule_forms)
      elsif r.is_reminder_rule && !used_by_reminder_rule
      # all reminder rule has same form list
        used_by_reminder_rule = true
        rtn.merge(r.reminder_rule_forms)
      end
    end
    rtn.to_a
  end

  # Returns list of forms this rule will be loaded onto if it's a value rule
  def value_rule_forms
    rtn = Set.new
    used_by_reminder_rule = false
    used_by_rules.each do |r|
      if r.is_value_rule
        rtn.merge(r.value_rule_forms)
      elsif r.is_reminder_rule && !used_by_reminder_rule
      # all reminder rule has same form list
        used_by_reminder_rule = true
        rtn.merge(r.reminder_rule_forms)
      elsif !r.is_data_rule # when it is a form rule
        rtn.merge(r.forms)
      end
    end
    rtn.to_a
  end

  # Returns list of forms this rule will be loaded onto if it's a reminder rule
  def reminder_rule_forms
    Form.all.map{|e| e.show_reminders? ? e : nil}.compact
  end

end
