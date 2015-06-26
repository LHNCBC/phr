module DataRule
  RULE_LBL_OPTIONS_VAR = 'ruleLbls'


  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods
   
    # TODO:: need to rewrite addLabel method so that the input parameter will 
    # be rule name only, rule label definitions should be stored as json in a 
    # similar way as rule actions are stored
    def combo_process_labels(asso_labels)
      labels_found = {}
      rules_used = Set.new
      js_part1 = ["var #{RULE_LBL_OPTIONS_VAR} = new RuleLabels();"]
      js_part2 = [""] # use empty string to make a empty line between part1 and part2
      asso_labels.each do |l|
        label_name = l.label
        # rule name referenced in a rule label should be dynamically retrieved
        # from rule_name_C
        asso_rule_name = l.rule_name
        fetch_rule_property = l.property
        js_part1 << "#{RULE_LBL_OPTIONS_VAR}.addLabel"+
          "('#{label_name}', '#{asso_rule_name}', '#{fetch_rule_property}');"
        js_part2 << "var #{label_name} = function()"+
          "{return #{RULE_LBL_OPTIONS_VAR}.getVal('#{label_name}')};"
        unless labels_found.keys.include?(label_name)
          labels_found[label_name] = l.readable_label 
        end
        rules_used.merge([asso_rule_name])

      end
      [js_part1 + js_part2, labels_found, rules_used]
    end

    # Returns JavaScript code for retrieving the value of a rule label
    def label_value_jsfunc(rule_label)
      rule_name = Rule.find(rule_label.rule_name_C).name
      case rule_label.rule_type
      when "fetch_rule"
        if rule_label.property == "Exist?"
          "Def.Rules.Cache.ruleVals_['#{rule_name}'] != null"
        else
          property_name = DbFieldDescription.find_by_id(rule_label.property_C).data_column
          "Def.Rules.Cache.getRuleVal('#{rule_name}')['#{property_name}']"
        end
      when "value_rule"
        "Def.Rules.Cache.getRuleVal('#{rule_name}')"
      end
    end

    # TODO:: needs to be replaced by the new parser-Frank
    # TODO:: check with quota_scanner in rule.rb#self.process_expression - 08/10/10 Frank
    def combo_process_expression(rule_expression, ref_rule_names, labels_found,
        parsing_errors, readable_format = false)
      #rule_expression should have balanced parenthesises
      validate_balance_of_parentheses(rule_expression)
      js_lines = []

      anyQuoteRegex = /(\\*)([\'\"])/;
      singleQuoteRegex = /(\\*)\'/;
      doubleQuoteRegex = /(\\*)\"/;
      remainder = rule_expression.blank? ? "" : rule_expression.dup;
      done = false;
      processedParts = [];
      while (remainder.length > 0 && !done)
        res = anyQuoteRegex.match(remainder);
        part = nil;
        quoteParts = [];
        if (res.nil?)
          done = true;  # this is the last piece
          part = remainder;
        else
          escChars = res[1];
          if (res[1].length > 0)
            raise 'Quotes may not be escaped outside of strings.';
          end
          part = remainder[0 ... res.begin(0)];
          quoteChar = res[2];

          # Find the end of the quotation.  Skip past escaped quotes.
          quoteParts = [quoteChar];
          foundEndQuote = false;
          remainder = remainder[res.begin(0)+1 .. -1];
          while (remainder.length > 0 && !foundEndQuote)
            if (quoteChar == "'")
              res = singleQuoteRegex.match(remainder);
            else
              res = doubleQuoteRegex.match(remainder);
            end

            # If we didn't find the end of the quote, throw an error.
            if (res.nil?)
              raise 'Quoted strings must be terminated';
            end

            endMatchIndex = res.begin(0)+res[0].length;
            # Down-case quoted strings for case-insensitive searching.
            quoteParts << remainder[0 ... endMatchIndex].downcase;
            remainder = remainder[endMatchIndex .. -1];

            # Check the number of escape characters.  If it is even, then the
            # quote is not escaped.
            if (res[1].length % 2 == 0)
              # The end of the quote.
              foundEndQuote = true;
            end
          end # while end of quote not found

          # If we didn't find the end quote, throw an exception
          if (!foundEndQuote)
            raise 'Quoted strings must be terminated';
          end
        end # else not last piece

        # "part" now conains a string to be processed, and quoteParts some parts
        # to be included afterward without processing (if any).
        processed_exp, js =
          combo_process_expression_part(part, ref_rule_names, labels_found,
            parsing_errors, readable_format)
        processedParts << processed_exp
        js_lines.concat(js)
        processedParts = processedParts.concat(quoteParts)
      end

      expression_rtn = processedParts.join('')

      return [js_lines, expression_rtn, ref_rule_names]
    end

    #    # TODO::need to move the method from rule.rb to here
    #    def combo_process_expression_part(expression, ref_rule_names, found_labels)
    #    end# end of combo_process_expression_part

    def data_hash_for_new_combo_rule_page
      {"expression_help"=> Rule.data_rule_helper}
    end

    ##
    # Creates a new fetch rule based on the input in an array
    #
    # Parameters:
    # * array_input - is an array like [rule_name, source_table_name, query_field,
    # operator_name, query_string]
    # sample of array_input:
    # [rule_name, source_table_name, conditions]
    # conditions = [[query_field, opeartor_name, query_string], [...], ..., [...]]
    def create_fetch_rule(array_input)
      array = array_input.clone
      rule_name = array.shift
      source_table_name = array.shift
      conditions = []
      array[0].each do |e|
        conditions <<  {
          :query_field => e[0],
          :operator_name  => e[1],
          :query_string => e[2]}
      end
      count = false
      options = RuleFetchCondition.fetch_rule_options(rule_name, source_table_name, count)
      options[:conditions] = conditions
      RuleFetchCondition.create_fetch_rule(options)
    end
    

    # Executes fetch rule on server side to improve the performance. Pre-fetched
    # records are the minimum amount of data needed in order to make client side
    # fetching working. This implementation assumes that fetch rules on table
    # obx_observations differ on loinc_num value and recency of test_date only.
    # Based on that assumption, list of individual fetch queries has been merged
    # into one main query with two eager loading queries only.
    #
    # Parameters:
    # * profile_id - a profile ID
    # * attr_list - list of attributes needs to be available in the fetched 
    #   result
    # 
    # Returns: a hash where the key is a rule name and the value is a record 
    #   containing only specified attributes (i.e. attr_list). The record is 
    #   also a hash where the key is an attribute name and the value is the 
    #   attribute's value.  
    #   
    # This method should be re-written to improve the performance after Ye 
    # finished modifying the latest_obx_observations table - Frank 11/22/2011
    def prefetched_obx_observations(profile_id, attr_list=nil)
      t = DbTableDescription.where(data_table: "obx_observations").includes({rule_fetches: [:rule]}).first
      attr_list ||= t.db_field_descriptions.map(&:data_column)
      loinc_numbers,  rule_to_loinc_order = Set.new , {}
      # Gets fetch-rule related info
      # 1) rule_to_loinc_order: a hash from rule_name to loinc_num/order joined string
      # 2) loinc_numbers: a set of loinc numbers need to be fetched
      t.rule_fetches.each do |e|
        cond = e.executable_fetch_query_ar[1][0]
        loinc_num = cond['conditions']["loinc_num"].values[0]
        loinc_numbers.add(loinc_num) 
        order = cond['order'].values[0] == "desc" ? "desc" : "asc"
        rule_to_loinc_order[e.rule.name] = [loinc_num, order].join("/")
      end

      # Finds all the recency records based on profile_id and loinc_numbers 
      cond = "profile_id = ? and loinc_num in (?)"
      recency_records = LatestObxRecord.where([cond, profile_id, loinc_numbers]).
        select(:profile_id, :loinc_num, :first_obx_id, :last_obx_id)
      
      # Caches the mapping from recency to obx_id 
      recency_by_obx = {}
      recency_records.each do |e| 
        recency_by_obx["#{e.loinc_num}/asc"] = e.first_obx_id 
        recency_by_obx["#{e.loinc_num}/desc"] = e.last_obx_id 
      end
      # Caches records of obxs in recency_by_obx 
      obx_cache = {}
      ObxObservation.find(recency_by_obx.values).map{|e| obx_cache[e.id] = e}

      # Gets list of pre-fetched records 
      rtn = {}
      rule_to_loinc_order.each do |rule_name, recency|
        if recency_by_obx[recency]
          obx_id = recency_by_obx[recency] 
          rtn[rule_name] = obx_cache[obx_id].attributes.delete_if{|k,v| !attr_list.include?(k)} 
        end
      end
      rtn
    end
    
    
    # To make a new JavaScript function name which make sure when the original
    # rule label value is in string format, it will return a lower cased string.
    RULE_LABEL_DOWNCASE_SUFFIX = "_downcase"

    # If the value of a label in rule expression is a string and the label is
    # used for case-insensitive comparison, then the value of this label should
    # be converted into a lower cased string.
    # Parameters:
    # * expression - an input expression
    # * js_lines - Lines of JavaScript codes used for declaring variables used
    #   in rule expression, rule case conditions etc.
    def downcase_label_value(expression, js_lines)
      exp = expression.gsub(/(((A|B)\d+)\(\))?(\s*==\s*|\s*!=\s*)(((A|B)\d+)\(\))?/) do |s|
        left_label  = $2
        right_label = $6
        left_label_dc  = $2 && ($2 + RULE_LABEL_DOWNCASE_SUFFIX)
        right_label_dc = $6 && ($6 + RULE_LABEL_DOWNCASE_SUFFIX)
        comp_op = $4

        rtn = ""
        if left_label_dc
          rtn += left_label_dc + "()"
          js_rtn = " var #{left_label_dc} = "+
                   "function(){return Def.Rules.toLowerCase(#{left_label}());}"
          js_lines.push(js_rtn) unless js_lines.include?(js_rtn)
        end
        rtn += comp_op
        if right_label_dc
          rtn += right_label_dc + "()"
          js_rtn = " var #{right_label_dc} = "+
                   "function(){return Def.Rules.toLowerCase(#{right_label}());}"
          js_lines.push(js_rtn) unless js_lines.include?(js_rtn)
        end
        rtn
      end
      [exp, js_lines]
    end # end of downcase_label_value

    # Returns a hash containing functions, constants, rules and fields which can
    # be used in a data rule
    def data_rule_helper
      exp_help_group = {}
#      exp_help_group['expression_rules'] =
#        Rule.find_all_by_rule_type([Rule::FETCH_RULE, Rule::VALUE_RULE]).map(&:name)
      exp_help_group['expression_functions'] =
        Rule.math_methods + Rule.rule_functions[0..7]
      exp_help_group['expression_constants'] = Rule.math_vars
      exp_help_group
    end
  end #CLASS_METHODS


  def validate_combo_rules
    rule_parse_errs = parse_combo_rules
    rule_parse_errs.map{|e| errors[:base]=(e)} unless rule_parse_errs.empty?
  end


  def parse_combo_rules
    rule_parse_errs = []
    begin
      rule_script, referenced_rules = build_combo_rule_function(rule_parse_errs)
    rescue
      rule_parse_errs << ($!.message)
      stacktrace = [$!.message].concat($!.backtrace).join("\n")
      puts stacktrace
      logger.debug(stacktrace)
    end

    if rule_parse_errs.empty?
      self.js_function = rule_script
      @built_js_function = true
      @rule_objs = referenced_rules.map{|r| Rule.find_by_name(r) }
    end
    rule_parse_errs
  end


  # TODO:: needs to be refactored when using new parser
  def build_combo_rule_function(parsing_errors =[])
    indent_level = 1 # for subsequent lines
    indent_per_level = '  '
    use_indent(indent_per_level, indent_level ) do
      tmp_errors = []

      case_rule_lines = [
        "Def.Rules.rule_#{name} = function(prefix, suffix) {",
        'var depFieldIndex = 0;', 'var selectedOrderNum = null;']

      ### add function definitions for the labels
      if rule_labels.size > 0
        js_declarations_lbl, labels_found_hash, ref_rule_names =
          Rule.combo_process_labels(rule_labels)
      else
        js_declarations_lbl = []
        labels_found_hash = {} # default, i.e., no exclusion criterion
        ref_rule_names = Set.new
      end
      case_rule_lines.concat(js_declarations_lbl)
      # Start with the exclusion criterion, which is in the expression field.
      if !expression.blank?
        js_declarations, expression_rtn, ref_rule_names =
          Rule.combo_process_expression(expression, ref_rule_names, labels_found_hash, tmp_errors)
        parsing_errors.concat(tmp_errors.map{|e| "Exclusion Criteria field: " + e}) if tmp_errors.size > 0
        tmp_errors =[]
      else
        # We still need to initialize those variables
        js_declarations = []
        expression_rtn = 'false' # default, i.e., no exclusion criterion
      end

      # Scan js_declarations for variable statements (which should be nearly
      # all of it.
      var_decls = js_declarations.grep(/\Avar /)
      # Add the javascript for the exclusion criterion to the case rule function.
      case_rule_lines.concat(js_declarations)
      case_rule_lines << "var exclusion = #{expression_rtn};"
      case_rule_lines << "var ruleCall = function(){return null;};"
      if rule_labels.empty?
        case_rule_lines << "var options= {'label': null};"
      else
        case_rule_lines << "var options= {'label':#{RULE_LBL_OPTIONS_VAR}};"
      end

      if is_reminder_rule
        case_rule_lines << "var getReminderCall = function(orderNum, options){"
#        case_rule_lines << "#{set_indent}('rule_id:#{id}; rule_name:#{name}');"
        case_rule_lines << "#{set_indent}try{"
        case_rule_lines << "#{set_indent}var reminder = Def.Rules.ruleActions_['#{name}.'+orderNum][0][2]['message'];"
        case_rule_lines << "#{set_indent}options['reminders'] = true;"
        case_rule_lines << "#{set_indent}var rtn = Def.Rules.fillMessageTemplate(reminder, [], options);"
        case_rule_lines << "#{set_indent}return rtn;"
        case_rule_lines << "#{set_indent}}catch(e){ throw 'Error in reminder message:' + e.message;}"
        case_rule_lines << "};"
      end

      case_rule_lines << 'if (!exclusion) {'

      # Process each case
      first_case = true
      case_computed_val_functions = []  # the JavaScript for the computed_values
      case_seq_nums = [] # the sequence numbers for the cases

      # Process the cases in order of their sequence number.  Although the
      # rule_cases association method pulls from the database in order, we might
      # at this point be working with a list that has been modified by adding
      # or revising rule_cases, so we can't rely on them being in order.
      rule_case_count = rule_cases.size
      rule_cases.sort_by {|rc| rc.sequence_num}.each_with_index do |rc, i|
        ## if this is the last rule case, then default case_expression to true
        if( i == rule_case_count - 1) && rc.case_expression.blank?
          rc.case_expression = "true"
        end

        if (!first_case)
          # Add an else block
          case_rule_lines << set_indent(1) + 'else {'
        end

        if (!rc.case_expression.blank?)
          case_decls, expression_rtn, case_ref_rules =
            Rule.combo_process_expression(rc.case_expression, ref_rule_names, labels_found_hash, tmp_errors)
          parsing_errors.concat(tmp_errors.map{|e| "Case on row #{i+1}: Case Expression has #{e}"}) if tmp_errors.size > 0
          tmp_errors =[]
          # Add any line in case_decls that is not already in var_decls.  For
          # each line that is a var statement, add it to var_decls (except for
          # the special variable case_val, which is used in JavaScript case
          # statements.)
          case_decls.each do |cd|
            if !var_decls.member?(cd)
              case_rule_lines << set_indent + cd
              if (cd =~ /\Avar (\S+) =/ && $1 != 'case_val')
                var_decls << cd
              end
            end
          end # each case_decls

          # Add case_ref_fields and case_ref_rules to the sets for the whole
          # function.  These are sets, so we don't have to check for uniqueness.
          ref_rule_names.merge(case_ref_rules)

          # Add the code for the cases' expression
          case_rule_lines << set_indent(1) + "if (#{expression_rtn}) {"
        end

        # Add code to remember the selected case sequence number.
        case_rule_lines << "#{set_indent}selectedOrderNum = #{rc.sequence_num};"
        case_seq_nums << rc.sequence_num;

        if is_reminder_rule
          # Reminder rule value is the reminder message itself.
          # getReminderCall function will throw exception if it finds invalid
          # labels being referenced.
          cv_js_lines, cv_expression_rtn, case_ref_rules = 
            [], "getReminderCall(selectedOrderNum, options)", []
        else
          cv_js_lines, cv_expression_rtn, case_ref_rules =
            Rule.combo_process_expression(rc.computed_value, ref_rule_names, labels_found_hash, tmp_errors)
          parsing_errors.concat(tmp_errors.map{|e| "Case on row #{i+1}: Rule Value field has #{e}"}) if tmp_errors.size > 0
          tmp_errors =[]
        end
        
        # Process the reminder message to make sure it has the valid label
        if is_reminder_rule
          llist = rc.rule_actions.first.parameters.scan(/#{}\{([^\}]*)\}/).flatten
          llist.each do |e|
            e = e.strip
            parsing_errors << "Label \"#{e}\" has not been defined." unless labels_found_hash[e]
          end
        end


        case_rule_lines << "#{set_indent(1)}var ruleCall = function(){"
        cv_js_lines.each do |e|
          case_rule_lines << "#{set_indent}#{e};"
        end
        case_rule_lines << "#{set_indent(-1)}return #{cv_expression_rtn};"
        case_rule_lines << "#{set_indent(-1)}};"

        # Merge the sets of referenced fields and rules
        ref_rule_names.merge(case_ref_rules)

        case_rule_lines << set_indent + '}'

        first_case = false
      end # each rule_cases

      # Now add the closing return statement, and join the function's lines
      # together.
      if ( set_indent.length > 0)
        stop = false
        while (!stop )
          set_indent(-1)
          case_rule_lines << set_indent + '}'
          stop = (set_indent.length == 0)
        end
      end

      case_rule_lines << "var ruleVal = ruleCall(prefix, suffix, null);"
      case_rule_lines <<
        "Def.Rules.processDataRuleCaseActions('#{name}', #{case_seq_nums.to_json}, "+
        "selectedOrderNum, prefix, suffix , null, ruleVal, options);"
      case_rule_lines << "return ruleVal;\n}\n"

      main_rule_function = case_rule_lines.join("\n  ")
      all_functions = [main_rule_function].join("\n")
      return [all_functions, ref_rule_names]
    end
  end


  # Create the data hash needed by the form.
  #
  # Parameters:
  # * error_list - list of error messages
  def data_hash_for_data_rule_page(error_list)
    if @rule_presenter_data
      %w(rule rule_label general rule_case ).each do |e|
        if rule_presenter_errors[e.to_sym]
          error_list.concat(rule_presenter_errors[e.to_sym])
        end
      end
      @rule_presenter_data.clone
    else
      case rule_type
      when Rule::FETCH_RULE
        get_fetch_rule_data_hash
      when Rule::VALUE_RULE, Rule::REMINDER_RULE
        get_combo_rule_data_hash
      else
        raise "The data rule '#{name}' has a wrong rule type '#{rule_type}'"
      end
    end
  end # data_hash_for_data_rule_page


  # Generates a hash which contains all the data for a fetch rule
  def get_fetch_rule_data_hash
    if new_record?
      data_hash = nil
    else
      data_hash = {
        "rule_name"=> name,
        "source_table"=>rule_fetch.source_table,
        "source_table_C"=>rule_fetch.source_table_C}

      major_fetch_conditions, other_fetch_conditions = [], []
      rule_fetch_conditions.each do |e|
        if e.condition_type == RuleFetch::MAJOR_QUALIFIER
          major_fetch_conditions << {
            'major_qualifier_group_id' => e.id,
            'major_qualifier_name'   => e.source_field,
            'major_qualifier_name_C' => e.source_field_C,
            'major_qualifier_value'   => e.non_date_condition_value,
            'major_qualifier_value_C' => e.non_date_condition_value_C
          }
        elsif e.condition_type == RuleFetch::OTHER_QUALIFIER
          other_fetch_conditions << {
            'non_date_fetch_qualifiers_group_id' => e.id,
            'non_date_qualifier_name'   => e.source_field,
            'non_date_qualifier_name_C' => e.source_field_C,
            'qualifier_value'   => e.non_date_condition_value || e.operator_1,
            'qualifier_value_C' => e.non_date_condition_value_C || e.operator_1_C
          }
        end
      end # each rule_fetch_condition
      data_hash["major_qualifier_group"] = major_fetch_conditions
      data_hash["non_date_fetch_qualifiers_group"] = other_fetch_conditions
    end
    return data_hash
  end # get_fetch_rule_data_hash


  # Returns a hash which contains data for either reminder_rule or
  # value_rule page
  def get_combo_rule_data_hash
    if new_record?
      Rule.data_hash_for_new_combo_rule_page
    else
      data_hash = {}
      data_hash['rule_id'] = id
      data_hash["rule_name"] = name
      data_hash['exclusion_criteria'] = expression

      fetch_rules_used, value_rules_used, rule_cases_table = [], [], []
      rule_labels.each do |rl|
        if rl.rule_type == "fetch_rule"
          fetch_rules_used << {
            'fetch_rules_used_id' => rl.id,
            'fetch_rule_label' => rl.label,
            'fetch_rule_name' => Rule.find(rl.rule_name_C).name,
            'fetch_rule_name_C' => rl.rule_name_C,
            'fetch_rule_property' => rl.property_display_name,
            'fetch_rule_property_C' => rl.property_C
          }
        elsif rl.rule_type="value_rule"
          value_rules_used << {
            'value_rules_used_id' => rl.id,
            'value_rule_label' => rl.label,
            'value_rule_name' => Rule.find(rl.rule_name_C).name,
            'value_rule_name_C' => rl.rule_name_C
          }
        end
      end # each rule_label

      rule_cases.each do |rc|
        action_table = []
        tmp = {'rule_case_id'=>rc.id,
          'case_order'=>rc.sequence_num,
          'case_expression'=>rc.case_expression,
          'computed_value'=>rc.computed_value,
          'case_actions'=>action_table}
        if is_reminder_rule
          # don't show "message=> and \," in reminder field on reminder rule page
          tmp_params= rc.rule_actions[0].parameters
          tmp_params= tmp_params.gsub(/\A\s*message\s*=>\s*/,"")
          tmp_params= tmp_params.gsub(/\\,/,",")
          tmp['reminder'] = tmp_params
        end
        rule_cases_table << tmp
      end # each rule case

      data_hash["fetch_rules_used"] = fetch_rules_used
      data_hash["value_rules_used"] = value_rules_used
      data_hash['rule_cases'] = rule_cases_table

      data_hash['expression_help'] = Rule.data_rule_helper

      data_hash
    end
  end # get_combo_rule_data_hash


  def executable_fetch_query(js_db = "taffy_db")
    raise "This is not a fetch rule!" unless is_fetch_rule
    table_name = DbTableDescription.find(rule_fetch.source_table_C).data_table
    # options[0] is used for qualifiers
    # options[1] is used for comparison
    options = [{},{}]
    rule_fetch.rule_fetch_conditions.each do |e|
      #index = e.condition_type =="Q" ? 0 : 1
      index = 0
      options[index] = e.executable_query(options[index], js_db)
    end
    options.reject{|e| e.empty? }
    #obsolete count column in rule_fetches table has been removed - 07/19/2010
    count = nil
    if options[0].empty?
      options[0] = {:conditions => {}, :limit => 1}
    end

    # to avoid empty tests being fetched when the form was first loaded
    if table_name == "obx_observations"
      query_str = js_db == "taffy_db" ?  {"!is" => ""} : {"!=" => ""}
      options[0][:conditions]["test_date_ET"] = query_str
      # Rules for fetching latest observation records should skip records with
      # empty obx5_value which has display_name as "Observation Value"
      options[0][:conditions]["obx5_value"] = query_str
    end

    [table_name, options, count]
  end


  # value rule or reminder rule should also be triggered by properties of fetch
  # rules in label sections
  #TODO::fetch rule trigger fields should be considered as well
  def find_trigger_fields_by_fetch_rule(a_rule)
    rtn = Set.new
    rule_labels.each do |e|
      if (e.rule_name == a_rule.name) && e.property_C && e.property_C > -1
        # fetch rule property could be "Exists?" which is not defined
        # in db_field_desccriptions table. Therefore we need to call method
        # RuleLabel#fetch_rule_property when we need to get property value
        rtn.add e.property
      end
    end
    rtn.to_a
  end


  ##########################################################
  ## begin of indentation methods
  def use_indent(step, count, &block)
    # initialize indent
    @step = step || "  "
    @count = count || 1
    @cur_indent = @step * @count

    yield

    # reset indent
    @count = nil
    @step = nil
    @cur_indent = nil
  end


  def set_indent(count=0)
    rtn = @cur_indent
    unless count == 0
      @count += count
      raise "indent going off the left margin" if @count < 0
      @cur_indent = @step * @count
    end
    rtn
  end # end of indentation methods
  ##########################################################
end
