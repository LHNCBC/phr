class RuleCase < ActiveRecord::Base
  has_many :rule_actions, :dependent => :destroy, :as => :rule_part
  belongs_to :rule
  acts_as_reportable
  has_paper_trail

  # This gets called when a RuleCase is saved.
  validate :validate_instance
  def validate_instance
    if rule.blank?
      if new_record?
        errors.add(:rule, 'must be associated with a rule when created')
      else
        errors.add(:base, "This is an orphan rule case")
        return
      end
    end

    # Make sure the sequence number is a unique (with respect to other
    # cases for this rule) positive integer.
    if (sequence_num.blank? || sequence_num < 1)
      errors.add(:order, 'must be a positive integer') # order is the field name
    else
      seq_set = Set.new
      rule.rule_cases.each do |rc|
        seq_set << rc.sequence_num if rc.id != id
      end
      if (seq_set.member?(sequence_num))
        errors.add(:order, 'cannot have the same value for two cases')
      end
    end

    # Make sure the computed value field is not blank
    if (computed_value.blank?)
      errors.add(:computed_value, 'must not be blank.')
    end

    # Note-- the case expression field can be blank, though that will
    # only work for the last case.  We defer checking that until
    # the generation of the JavaScript (in the Rule class).
  end

  # Following two pairs of getter/setter methods: case_expression and
  # computed_value are used for renaming rule variable in rule expressions so
  # that user can change rule name without modifying attributes which use the
  # rule variables
  #
  # Converts rule name code found from case_expression attribute into rule name
  # and returns the converted case_expression
  def case_expression
    case_exp =  attributes["case_expression"];
    case_exp && Rule.rename_rule_vars(case_exp, "prefixed_id", "name")
  end

  # Converts rule names in case_expression into rule name code with rule ids
  # before saving it
  #
  # Parameters:
  # * input_exp original case_expression where rules are represented with
  # corresponding rule names
  def case_expression=(input_exp)
    super input_exp && Rule.rename_rule_vars(input_exp, "name", "prefixed_id")
  end

  # Converts rule name code found from computed_value attribute into rule name
  # and returns the converted computed_value
  def computed_value
    comp_val = attributes["computed_value"]
    comp_val && Rule.rename_rule_vars(comp_val, "prefixed_id", "name")
  end

  # Converts rule names in computed_value into rule name code with rule ids
  # before saving it
  #
  # Parameters:
  # * input_exp original computed_value where rules are represented with
  # corresponding rule names
  def computed_value=(input_exp)
    super input_exp && Rule.rename_rule_vars(input_exp, "name", "prefixed_id")
  end

  # Beginning of reminder report part
  # Following four methods are used for generating rule_case part of reminder
  # rule report in a readable format
  #
  # Returns a hash containing rule labels of current rule and their descriptions
  def label_descriptions
    unless @lfh
      @lfh = {}
      rule.rule_labels.map{|e| @lfh[e.label] = e.readable_label}
    end
    @lfh
  end # end of label_descriptions


  # Parses and returns a readable case_expression with no labels in it
  def expression_in_readable_format
    exp = case_expression || ""
    Rule.combo_process_expression(exp, Set.new,
      label_descriptions, [], true)[1]
  end # end of expression_in_readable_format


  # Parses and returns a readable reminder message with no labels in it
  def message_in_readable_format
    message = rule_actions[0].parsed_parameters['message']
    message.gsub!(/(\{([^\}]*)\})/) do |s|
      "{#{label_descriptions[$2]}}"
    end
    message.gsub("message=>","")
  end # end of message_in_readable_format


  # Parses and returns a readable rule expression with no labels in it
  def rule_expression_in_readable_format
    Rule.combo_process_expression(rule.expression, Set.new,
      label_descriptions, [], true)[1]
  end # end of rule_expression_in_readable_format
  # End of reminder report part

end
