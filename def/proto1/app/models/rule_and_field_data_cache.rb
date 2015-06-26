# A class for caching associate objects of rules/fields on the form
class RuleAndFieldDataCache

  @@rule_to_used_by_rules,
  @@rule_to_field_descriptions,
  @@rule_to_rule_cases,
  @@rule_to_rule_actions,
  @@field_description_to_sub_fields,
  @@field_description_to_rules=nil

  #@@cached_form_ids=[]
  @@class_cache_version = {}

  # Resets all the caches
  def self.reset
    @@rule_to_used_by_rules,
    @@rule_to_field_descriptions,
    @@rule_to_rule_cases,
    @@rule_to_rule_actions,
    @@field_description_to_sub_fields,
    @@field_description_to_rules = nil

    #@@cached_form_ids = []
    @@class_cache_version = {}
  end

  # Caches associated objects to each rule and field on the form
  #
  # Parameters
  # * form - an instance of Form object
  def self.cache_rule_and_field_associations(form)
    #unless is_a_cached_form?(form)
    ##TODO:: in development mode, cached AR record will miss customized methods
    # set to true to temperory 
    if true#need_an_update?(form)
      reset
      cache_associations_to_form_rules(form)
      cache_associations_to_form_fields(form)
      #@@cached_form_ids << form.id
      update_cache_version(form)
    end
  end

  # Returns true if the class_cache_version of this class is different than
  # the one stored in table class_cache_verion and vice versa
  # Parameters:
  # * form - all the cache are belong to this form
  def self.need_an_update?(form)
    @@class_cache_version[form.form_name.to_sym] !=
      ClassCacheVersion.latest_version(self, form)
  end

  # Updates the class_cache_version of this class with the one found in database
  # table class_cache_version
  # Parameters:
  # * form - all the cache are belong to this form
  def self.update_cache_version(form)
    @@class_cache_version[form.form_name.to_sym] =
      ClassCacheVersion.latest_version(self, form)
  end

  # Returns used_by_rules associated with rule_id
  #
  # Parameters:
  # * rule_id - an rule id
  def self.get_used_by_rules_by_rule(rule_id)
    @@rule_to_used_by_rules &&
      @@rule_to_used_by_rules[rule_id]
  end

  # Returns field_descriptions associated with rule_id
  #
  # Parameters:
  # * rule_id - an rule id
  def self.get_field_descriptions_by_rule(rule_id)
    @@rule_to_field_descriptions &&
      @@rule_to_field_descriptions[rule_id]
  end

  # Returns rule_actions associated with rule_id
  #
  # Parameters:
  # * rule_id - an rule id
  def self.get_rule_actions_by_rule(rule_id)
    @@rule_to_rule_actions &&
      @@rule_to_rule_actions[rule_id]
  end

  # Returns rule_cases associated with rule_id
  #
  # Parameters:
  # * rule_id - an rule id
  def self.get_rule_cases_by_rule(rule_id)
    @@rule_to_rule_cases &&
      @@rule_to_rule_cases[rule_id]
  end

  # Returns rules associated with field_description with id = field_id
  #
  # Parameters:
  # * field_id - an field description id
  def self.get_rules_by_field(field_id)
    @@field_description_to_rules &&
      @@field_description_to_rules[field_id]
  end

  def self.get_sub_fields_by_field(field_id)
    @@field_description_to_sub_fields &&
      @@field_description_to_sub_fields[field_id]
  end

  private

  # Caches following associated objects to each rule of the form:
  # 1) used_by_rules
  # 2) field_descriptions
  # 3) rule_actions
  # 4) rule_cases
  #
  # Parameters:
  # * form - an form object
  def self.cache_associations_to_form_rules(form)
    alist = form.rules.includes([:used_by_rules,
                  :field_descriptions,
                  :rule_actions,
                  :rule_cases])
    alist.each do |r|
      @@rule_to_used_by_rules ||= {}
      @@rule_to_used_by_rules[r.id] = r.used_by_rules

      @@rule_to_field_descriptions ||= {}
      @@rule_to_field_descriptions[r.id] = r.field_descriptions

      @@rule_to_rule_actions ||= {}
      @@rule_to_rule_actions[r.id] = r.rule_actions

      @@rule_to_rule_cases ||= {}
      @@rule_to_rule_cases[r.id] = r.rule_cases
    end
  end

  # Caches following associated objects to each field_description on the form:
  # 1) rules
  # 2) sub_fields
  #
  # Parameters:
  # * form - an form object
  def self.cache_associations_to_form_fields(form)
    alist = form.field_descriptions.includes(:rules)

    @@field_description_to_sub_fields ||={}
    alist.each do |f|
      @@field_description_to_sub_fields[f.group_header_id] ||= []
      if f.group_header_id && !@@field_description_to_sub_fields[f.group_header_id].include?(f)
        @@field_description_to_sub_fields[f.group_header_id]  << f
      end

      @@field_description_to_rules ||={}
      @@field_description_to_rules[f.id] = f.rules
    end

    # Sorts sub_fields by display_order
    @@field_description_to_sub_fields.keys.each do |k|
      @@field_description_to_sub_fields[k].sort!{|a,b| a.display_order <=> b.display_order}
    end
 end

end #END OF RuleDataCache

module RuleWithCache
  # Returns cached used_by_rules if exist. If there is no cached used_by_rules,
  # then returns associated used_by_rules using has_many relationship
  def used_by_rules_with_cache
    RuleAndFieldDataCache.get_used_by_rules_by_rule(self.id) ||
      used_by_rules_without_cache
  end

  # Returns cached field_descriptions if exist. If there is no cached
  # field_descriptions, then returns associated field_descriptions using
  # has_many relationship
  def field_descriptions_with_cache
    RuleAndFieldDataCache.get_field_descriptions_by_rule(self.id) ||
      field_descriptions_without_cache
  end

  # Returns cached rule_actions if exist. If there is no cached rule_actions
  # then returns associated rule_actions using has_many relationship
  def rule_actions_with_cache
    RuleAndFieldDataCache.get_rule_actions_by_rule(self.id) ||
      rule_actions_without_cache
  end

  # Returns cached rule_cases if exist. If there is no cached rule_cases
  # then returns associated rule_cases using has_many relationship
  def rule_cases_with_cache
    RuleAndFieldDataCache.get_rule_cases_by_rule(self.id) ||
      rule_cases_without_cache
  end

  # Overwrite association methods with cache
  def self.included(base)
    base.alias_method_chain :used_by_rules, :cache
    base.alias_method_chain :field_descriptions, :cache
    base.alias_method_chain :rule_actions, :cache
    base.alias_method_chain :rule_cases, :cache
    base.after_save {|record| record.forms.map{|f| ClassCacheVersion.update(RuleAndFieldDataCache, f)}}
    base.before_destroy {|record| record.forms.map{|f| ClassCacheVersion.update(RuleAndFieldDataCache, f)}}
  end
end
Rule.class_eval{ include RuleWithCache }

module FieldDescriptionWithCache
  # Returns cached rules if exist. If there is no cached rules, then returns
  # associated rules using has_many relationship
  def rules_with_cache
    RuleAndFieldDataCache.get_rules_by_field(self.id) ||
      rules_without_cache
  end

  # Returns cached sub_fields if exist. If there is no cached sub_fields, then
  # returns associated sub_fields using has_many relationship
  def sub_fields_with_cache
    RuleAndFieldDataCache.get_sub_fields_by_field( self.id) ||
      sub_fields_without_cache
  end

  # Overwrite association methods with cache methods
  def self.included(base)
    base.alias_method_chain :rules, :cache
    base.alias_method_chain :sub_fields, :cache
    base.after_save {|record| ClassCacheVersion.update(RuleAndFieldDataCache, record.form)}
    base.before_destroy {|record| ClassCacheVersion.update(RuleAndFieldDataCache, record.form)}
  end
end
FieldDescription.class_eval{ include FieldDescriptionWithCache }
