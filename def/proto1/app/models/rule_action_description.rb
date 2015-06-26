class RuleActionDescription < ActiveRecord::Base
  extend HasShortList
  default_scope -> { order("display_order") }

  def self.function_names
    RuleActionDescription.all.map(&:function_name)
  end # function_names
  
end # RuleActionDescription class
