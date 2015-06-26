class RuleAction < ActiveRecord::Base
  has_paper_trail
  belongs_to :rule_part, :polymorphic=>true  # relies on rule_part_type; (p.347)

  # The names of the currently supported actions.  The actions are supported
  # by the Def.Rules.Actions portion of rules.js.
#debugger
#  ACTIONS = TextList.get_list_items('rule_actions')
#  VALID_NAMES = Set.new()
#  ACTIONS.each do |a|
#    VALID_NAMES << a.item_name
#  end
  
  # The disallowed control types for a set_value/set_or_clear_value action.
  INVALID_SET_VALUE_TYPES =
    Set.new(['group_hdr', 'print_button', 'expcol_button'])

  NO_AFFECTED_FIELD_NEEDED = Set.new(['execute_javascript'])
    
  # A validation method.  This runs when "save" is called.  If it finds
  # errors, it adds them to the "errors" hash.  See AWDWR2, p.361.
  def validate
  
    if !defined? @@valid_names
      RuleAction.populate_actions_cache
    end

    if rule_part.blank?
      if self.new_record?
        errors.add(:rule_part, 'must be associated with a rule_part when created')
      else
        errors[:base]=('This is an orphan rule action.')
        return
      end
    end

    if action
      # Note:  When setting a field, you need to include the self. prefix.
      # Otherwise ruby thinks you are declaring a new local variable.
      # ALSO NOTE that we are downcasing action names because we use
      # the ruby naming format convention (lowercase with underscores
      # between words) for action names rather than the javascript naming
      # convention (even though they're javascript methods.  It's easier
      # for a user specifying action names).
      self.action = action.strip.downcase
    end
    if action.blank? 
      errors.add(:action, 'no action specified')
    elsif !@@valid_names.include?(action)
      errors.add(:action, action + ' is invalid')
    else
      # Check the parameters for the action
      self.parameters.strip! if parameters
      case action
      when 'add_message','add_table_messages'
        handle_single_param_validation('message')
      when 'show_error'
        handle_single_param_validation('message')
      when 'hide_sub_columns','show_sub_columns',
           'disable_sub_columns','enable_sub_columns'
        handle_single_param_validation('column')
      when 'set_value', 'set_or_clear_value'
        handle_single_param_validation('value')
      when 'set_tooltip'
        handle_single_param_validation('field', true)
      when 'set_column_header'
        handle_single_param_validation('header', true)
      when 'set_field_label', 'set_group_header_label'
        handle_single_param_validation('label', true)
      when 'set_group_header_instructions'
        handle_single_param_validation('instructions', true)
      when 'update_shared_list'
        expected = {'listName'=>['string',true],
                    'keyName'=>['field',true],
                    'valName'=>['field',true],
                    'codeName'=>['field',true],
                    'condition'=>[['field','operator','string'],false]}
        handle_multiple_param_validation(expected)
      when 'hide_loinc_panel', 'show_loinc_panel','hide_loinc_test','show_loinc_test'
        validate_loinc_number
      when 'set_autoincrement_value'
        expected = {'prefix'=>['string',false],
                    'beginning_value'=>['string',true],
                    'suffix'=>['string',false]}
        handle_multiple_param_validation(expected)
      when 'execute_javascript'
        handle_single_param_validation('javascript', true)
      else
        # This is an action that does not use parameters.  Make sure it
        # is blank.
        if !parameters.blank?
          errors.add(:parameters, 'should be blank for action ' +action)
        end
      end
    end # check of parameters

    # Also check the affected field, to see if it is on the forms for the
    # rule for which this is an action.
    self.affected_field.strip! if affected_field
    if (!affected_field.blank? || !NO_AFFECTED_FIELD_NEEDED.include?(action))
      if (affected_field.blank?)
        errors.add(:affected_field,
          'should specify a field affected by the action')
      elsif field_info = FieldDescription.loinc_field_info(affected_field)
        # Validates the existence of loinc number and target field
        target_field, loinc_number = field_info
        unless LoincItem.find_by_loinc_num(loinc_number)
          errors.add(:affected_field,
            " must be a field with valid loinc number if it is a loinc field")
        end
        rule = rule_part.class == RuleCase ? rule_part.rule : rule_part
        form = rule.forms[0]
        form_field = form.field_descriptions.find_by_target_field(target_field)
        if !form_field
          embedded_field = FieldDescription.where(["form_id in (?) and target_field like ?",
                form.foreign_form_ids, target_field]).first
          if !embedded_field
            errors.add(:affected_field,
              " must be a field with valid target field if it is a loinc field")
          end
        end
      elsif !(rule_part_type == "RuleCase" && rule_part.rule.is_data_rule)
        # rule_part is either a Rule, or a RuleCase (which belongs to a Rule)
        affected_fd = check_field_on_all_forms
        if !affected_fd
          errors.add(:affected_field, 'must be one of the fields on each form '+
           'to which this rule is applied')
        elsif (action == 'add_message' &&
               affected_fd.control_type!='button')
          errors.add(:affected_field, 'must be a field of type button '+
            'when the action is add_message')
        elsif ((action == 'set_value' || action == "set_or_clear_value") &&
               INVALID_SET_VALUE_TYPES.member?(affected_fd.control_type))
          bad_types = INVALID_SET_VALUE_TYPES[0, -2].join(', ')+', or '+
            +INVALID_SET_VALUE_TYPES.last
          errors.add(:affected_field, 'cannot be a field of type '+bad_types+
            " when the action is #{action}")
        end
      end
    end
  end # def validate


  # This method resets the valid actions cache.  It needs to be run when
  # a new action is added to the database list of rule actions.  It is also
  # run when validate is first run, to populate the cache.
  def self.populate_actions_cache
    # actions = TextList.get_list_items('rule_actions')
    @@valid_names = RuleActionDescription.function_names
#    raise 'function names returns ' +
#          RuleActionDescription.function_names.join(' ')
  end # def populate_actions_cache
  
  
  # Handles the validation of the parameters field for the case where
  # there is only a single value allowed.  The user is permitted to enter
  # the value without specifying the parameter name.
  #
  # Parameters:
  # * param_name the name of the parameter that should be in the field.
  # * optional flag indicating whether or not the parameter is optional.
  def handle_single_param_validation(param_name, optional=false)

    # don't do checking if the parameter's optional and we don't have one
    if (!(parameters.blank? && optional))
      # Allow either a string with no =>, or a string that has
      # just one parameter, param_name.
      if (parameters.blank?)
        errors.add(:parameters, 'should specify a '+param_name)
      elsif (parameters !~ /=>/)
        # The syntax for this field is difficult, so we allow the user
        # to just type in a message without specifying the the parameter name.
        self.parameters = param_name+'=>'+parameters
        # Escape any single quotes that are in the message (that aren't
        # already escaped).
        self.parameters = self.parameters.gsub(/(\\*),/) do |match|
          # If there is an even number of backslashes, add another so that
          # the comma is escaped.
          $1.length % 2 == 1 ? match : '\\' + match
        end
      else
        # Parse the parameters and confirm they parse okay.
        begin
          parsed_p = RuleAction.parse_hash_value(parameters)
          if (parsed_p.size != 1 || !parsed_p[param_name])
            errors.add(:parameters, 'for an '+action+' action should '+
               'contain just one parameter, "'+param_name+'"')
           end
        rescue
          # At present, there is no detailed error checking during the
          # parsing.
          errors.add(:parameters, 'has bad syntax.  Be sure to include a \ '+
            'before any commas that aren\'t meant to separate parameter values.')
        end
      end
    end # if the parameter's required or we have one (required or not)
  end # handle_single_param_validation

  def validate_loinc_number
    # make sure the parameters is a hash like string
    if !parameters.nil? 
      if parameters !~ /=>/
        param_value = parameters.strip
        self.parameters = "loinc_number=>#{param_value}"
      else
        param_value = RuleAction.parse_hash_value(parameters)["loinc_number"]
      end
    end
    
    if param_value.blank? || !LoincItem.find_by_loinc_num(param_value)
      errors.add(:parameters, "the loinc number #{param_value} is not valid.")
    end
  end
  
  # Handles the validation of the parameters field for the case where
  # multiple parameters are allowed. 
  #
  # A hash containing the validation data for each parameter is passed in.
  # The parameter name serves as the key to the hash elements.  Each hash
  # element should contain an array of 2 elements.  The first element is the 
  # data type expected for the value.  The second is a flag indicating
  # whether or not the parameter is required.
  #
  # See the do_type_validations method for the data types currently validated.
  # 
  # If the parameter data type is an array, an array is specified for the
  # data type, where the array contains the expected type for each element,
  # in the same order in which the elements should appear in the array.
  #
  # If the parameter type is a hash, a hash is specified for the data type.
  # That hash should contain a key for the hash parameter name and a data
  # type for the value for that parameter.  Oh goody.
  #   
  # An error is signalled for any parameters that are not specified in the
  # expected hash.
  #
  # Any errors found are loaded to the errors object.  This must be checked
  # to ascertain success.
  #  
  # Parameters:
  # * expected hash containing the specifications for each parameter.
  # 
  def handle_multiple_param_validation(expected)
    
    if (parameters.blank?)
      errors.add(:parameters, expected.length_to_s + ' are required for ' +
                 'the ' + action + ' action, but none were specified.')
    else
      specified = parsed_parameters.clone 
      expected.each do |exp_name, exp_details|
      
        if !specified[exp_name].nil?
          spec = specified.delete(exp_name)
          exp_type = exp_details[0]
          do_type_validation(exp_name, exp_type, spec)
        
        elsif exp_details[1] == true
          errors.add(:parameters, 'Missing ' + exp_name + ' parameter.  ' +
                      'This parameter is required for action = ' +
                      action + '.')
        end # if we do/don't have that parameter
      end # do for each expected parameter
      
      # If there are any parameters left, list them as unrecognized.
      if specified.length > 0
        extra_list = String.new
        specified.each_pair do |param_name, param_val|
          extra_list << param_name + '=>' + param_val + ', '
        end
        extra_list.chomp!(', ')
        errors.add(:parameters, 'Unrecognized parameters specified ' +
                   'for action = ' + action + '.  Parameters are:  ' +
                   extra_list)
      end # if we have leftover parameters
    end # if the parameters are/aren't blank
  end # handle_multiple_param_validation  
  
  
  # This method invokes the appropriate type validation method for
  # a parameter based on the expected type of the parameter.  This
  # is in its own method because parameter checking may be recursive,
  # specifically in the case of parameters that accept arrays and
  # hashes.  
  #
  # Parameter types supported are as checked in this method.  At some
  # point they should probably be elsewhere, but for now they're here.
  #  
  # Parameters:
  # * exp_name name of the parameter
  # * exp_type expected type of the parameter
  # * spec the parameter specified
  #   
  def do_type_validation(exp_name, exp_type, spec)
    
    if (exp_type.class.to_s == 'String')
      exp_type.downcase!
      case exp_type
      when 'string'
        validate_simple_type(exp_name, exp_type, 'String', spec)
      when 'integer', 'fixnum'
        validate_simple_type(exp_name, exp_type, 'Fixnum', spec)
      when 'number', 'float'
        validate_simple_type(exp_name, exp_type, 'Float,Fixnum', spec)
      when 'operator'
        validate_operator_param(exp_name, spec)
      when 'field' 
        validate_field_param(exp_name, spec)
      else
        errors.add(:parameters, 'Unexpected type indicated for ' +
                   exp_name + ' parameter.  Indicated type = ' +
                   exp_type + ' (for action = ' + action + ')')
      end        
    elsif (exp_type.class.to_s == 'Array')
      validate_array_param(exp_name, exp_type, spec)
    elsif (exp_type.class.to_s == 'Hash')
      validate_hash_param(exp_name, exp_type, spec)
    else
      errors.add(:parameters, 'Unexpected type indicated for ' +
                 exp_name + ' parameter.  Indicated type = ' +
                 exp_type.to_s + ' (for action = ' + action + ')')
    end
  end # do_type_validation
  
  
  # This method validates one of the simple data types possible for
  # a parameter and adds an error message to errors if the type of the
  # value passed in is not as specified.
  #
  # Parameters:
  # * param_name name of the parameter
  # * type_name name of the data type (string, integer, etc)
  # * match_class name of the class that represents the data type
  # * value parameter value
  #
  def validate_simple_type(param_name, type_name, match_class, value)
    
    val_class = value.class.to_s  
    if !match_class.include? ','
      if (val_class != match_class)
        errors.add(:parameters, param_name + ' value should be of type ' + 
                   type_name + ', but ' + value.to_s + ' is of type ' +
                   val_class + ' (for action = ' + action + ')')
      end
    else
      classes = match_class.split(',')
      if (!classes.include?(val_class))
        errors.add(:parameters, param_name + ' value should be of type ' +
                   type_name + ', but ' + value.to_s + ' is of type ' +
                   val_class + ' (for action = ' + action + ')')
      end
    end                 
  end # validate_simple_type
  
  
  # This method validates an operator parameter to see if the value
  # specified is one of the ones currently considered valid, and adds 
  # error message to errors if the test fails.  
  #
  # At the moment the moment the valid operators are defined within 
  # this method - but at some point that should be changed.
  #
  # Parameters:
  # * param_name name of the parameter
  # * operator the parameter value specified
  #  
  def validate_operator_param(param_name, operator)
    operators = ['==', '!=', '<', '>', '<=', '>=']
    if (operator.class.to_s != 'String' || !operators.include?(operator))
      errors.add(:parameters, param_name + ' value (' + operator.to_s + ')' +
                 'was not recognized.  It needs to be one of the ' +
                 'following operators: [' + operators.join(', ') + ']' +
                 ' (for action = ' + action + ')')
    end
  end # validate_operator_param
  
  # This method validates a parameter that is supposed to be the
  # name of a form field.  It checks for the field on all forms
  # used by the rule to which this action is attached, and adds
  # an error message to errors if the form field is not found on
  # all applicable forms.  
  #
  # Parameters:
  # * param_name name of the parameter
  # * field_name the parameter value specified
  #    
  def validate_field_param(param_name, field_name)
  
    have_fd = check_field_on_all_forms(field_name)
    if !have_fd
      errors.add(:parameters, param_name + ' value must be the name of ' +
                 'a field on each form to which this rule is applied for ' +
                 'action = ' + action + '.  ' + 
                 field_name + ' was not found for at least one form.' )
    end
  end # validate_field_param
  
  
  # This method validates a parameter that is supposed to be an
  # array.  The exp_type passed in should be an array, where each
  # element specifies the type for the corresponding element in
  # the actual parameter.  Each type specification and parameter
  # is sent to the do_type_validation method to determine how to
  # validate the parameter, which means this can recurse to however
  # many levels are needed.
  #
  # There is no provision for specifying that any parameters in the
  # array are optional.  It is assumed that they are all required.
  #
  # If an invalid type is found, or the two arrays are not the same
  # length an error message is added to errors.  
  #
  # Parameters:
  # * param_name name of the parameter
  # * exp_type the array specifying a data type for each element
  #   in the parameter array
  # * spec_array the array specified for the parameter.
  #      
  def validate_array_param(param_name, exp_type, spec_array)
  
    if (exp_type.length != spec_array.length)
      errors.add(:parameters, 'Incorrect number of array elements specified ' +
                 'for the ' + param_name + ' parameter.  Should be an ' +
                 'array of ' + exp_type,length.to_s + ' elements, but only ' +
                 'has ' + spec_array.length.to_s + ' elements.  (action = ' +
                 action + ').')
    else
      0.upto(exp_type.length - 1) do |i|
        do_type_validation(param_name + '[' + i.to_s + ']', 
                           exp_type[i], spec_array[i])
      end
    end
  end # validate_array_param
  
  
  # This method validates a parameter that is supposed to be a hash.
  # The exp_type passed in should be a hash, where each element is
  # a param_name=>type pair.  Each type specification and parameter
  # is sent to the do_type_validation method to determine how to
  # validate the parameter, which means this can recurse to however
  # many levels are needed.
  #
  # There is no provision for specifying that any parameters in the
  # hash are optional.  It is assumed that they are all required.
  #
  # If an invalid type is found, or a parameter is not found, or there
  # are parameters left over after checking is complete, an error message is added to errorss.  
  #
  # Parameters:
  # * param_name name of the parameter
  # * exp_type the hash specifying a data type for each element
  #   in the parameter hash
  # * spec_hash the hash specified for the parameter.
  #        
  def validate_hash_param(param_name, exp_type, spec_hash)
    exp_type.each_pair do |exp_key, exp_type_name|
      do_type_validation(param_name + '.' + exp_key, exp_type_name,
                         spec_hash.delete(exp_key))
    end
    if spec_hash.length > 0
      extra_list = String.new
      spec_hash.each_pair do |param_name, param_val|
        extra_list << param_name + '=>' + param_val + ', '
      end
      extra_list.chomp!(', ')
      errors.add(:parameters, 'Unrecognized parameters specified ' +
                 'for action = ' + action + '.  Parameters are:  ' +
                 extra_list)
    end # if we have leftover parameters    
  end # validate_array_param
  
  
  
  # Returns the value of parameters, parsed into a hash map.
  # For the format of the parameters field, see parse_hash_value.
  def parsed_parameters
    rtn = RuleAction.parse_hash_value(parameters)
    
    # For set_value action, we need to convert
    # "value"=>"''" or "value"=>"\"\"" into "value" =>""
    if rtn && rtn["value"] && rtn["value"].length == 2
      rtn["value"].gsub!(/(\"\"|\'\')/,"")
    end
    rtn
  end
  
  
  # Checks whether a field name is defined as a field on all of the 
  # rule's forms.  If no field name is passed in, the affected field
  # is assumed to be the target.
  #
  # Parameters:
  # * field_name optional parameter that specifies the name of the field
  #   to look for.  If not specified, the affected_field is used.
  #
  # Returns: the field description record (from the first form) if the field
  # exists on all forms; otherwise nil
  #
  def check_field_on_all_forms(field_name=nil)
    return nil unless rule_part
    
    if field_name.nil?
      field_name = affected_field
    end
    rule = rule_part
    rule = rule.rule if (rule.class.name == 'RuleCase')
    rtn = nil
    rule.forms.each do |f|
      fd = Rule.find_fields(field_name, f.id)[0]
      if (fd)
        rtn = fd if !rtn
      else
        rtn = nil
        break # it didn't exist on this form
      end
    end
    rtn
  end # check_field_on_all_forms

  # Clears actions cache
  def self.clear_actions_cache
    @@valid_names.clear if defined? @@valid_names
  end

  # Overwrites setter method for parameters so that rule variables used in parameters
  # can be renamed from rule name into unique prefixed rule id
  def parameters=(str)
    str = str && str.gsub(/\$\{([^\};]*)(;([^\}]*))?\}/) do |s|
      rule_name, suffix = $1, $2
      r = Rule.find_by_name(rule_name)
      if r
        "${#{Rule::RULEKEY_PREFIX}_#{r.id}#{suffix}}"
      else
        errors.add(:parameters, "has invalid rule name '#{rule_name}'.")
        s
      end
    end
    super str
  end

  # Overwrites getter method so that returning parameters will replace its rule
  # variables with matching rule names 
  def parameters
    saved_param = attributes["parameters"]
    if saved_param
      saved_param.gsub(Rule.regex_for_rule_key) do |s|
        rule_id = $1
        r = Rule.find_by_id(rule_id)
        if r
          rtn = r.name
        else
          errors.add(:parameters, "has invalid rule id '#{rule_id}'.")
          rtn = s
        end
      end
    end
  end

end
