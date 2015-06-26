module RuleHelper

  # Checks to see if the field has associated rules, and adds the needed
  # event handler so that the rules are run for the field.
  #
  # Parameters:
  # * some_field - the field
  # * target is the target_field value for the field processed to modify
  #   it, if needed, for LOINC panel fields
  #
  # Returns:  nothing
  #
  def add_rule_handler(some_field, target)
    # See if some_field is used by any rules.
    if some_field.is_rule_trigger?
      add_observer(target, 'change', 
                   'function(event){Def.Rules.runRules(this);}')
    end
  end # add_rule_handler

end
