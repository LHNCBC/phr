class RuleSet < ActiveRecord::Base
  validates_presence_of :name
  has_and_belongs_to_many :forms, -> { order("id") }
  # Returns a hash like set. Each key of that hash represents a set name while 
  # it's value represents a set of items extracted from the corresponding
  # [content] column of rule_sets table. 
  #   
  # Example: 
  #  A table with one record ==>  
  #    name: "abc", content: "item 1, item 2"
  #  Resulting hash like set ==> 
  #    {"abc" =>{"item name 1"=>1, "item name 2"=>1}}
  # 
  # This hash like set will help us checking if an item is in a set or not
  # e.g. we need to check if item_b is in set_b or not
  #   @hash_like_set[set_b][item_b] == 1 ? true : false
  def self.load_rule_set_data(form)
    rtn={}
    res={}
    form.rule_sets.each do |rs|
      rs.content.split(',').map{|e| rtn[e.strip.downcase] =1}
      res[rs.name] = rtn
      rtn ={}
    end
    res
  end
  
  # Returns a specific hash with all the rule sets info so that it can be 
  # loaded/displayed on the rules form
  def self.data_hash_for_display
    rule_set_table = self.all.map do |each_set|
      { 'edit_rule_set'    => "#{each_set.id};edit",
        'delete_rule_set'  => "#{each_set.id}",
        'rule_set_name'    => each_set.name,
        'rule_set_content' => each_set.content
      }
    end
    {'rule_sets' => rule_set_table}
  end 
  
  # Returns a structure that contains the data needed for the 'edit rule set' 
  # form (which displays a form for editing a rule set).
  #
  # Parameters:
  # * errors - a list of errors for the page to which any error messages
  #     should be appended
  # * rule_set_data - a optional hash map of values that has the same structure 
  #    as the returned data hash, and that contains form field values previously
  #    entered by the user.  (This is used for restoring a form's values
  #    is a submit fails.)
  def data_hash_for_set_edit_page(error_list, rule_data=nil)
    # Create the data hash needed by the form.
    error_list.concat(errors.full_messages)
    if rule_data
      data_hash = rule_data.clone
    else
      data_hash = {'rule_set_name'=>name, 'rule_set_content'=>content}
    end

    exp_help_group = {}
    data_hash['expression_help'] = exp_help_group
    exp_help_group['expression_fields'] = []#Rule.common_expression_fields(forms) 
    exp_help_group['expression_rules'] = []#allowed_expression_rules.sort
    return data_hash
  end

  
end
