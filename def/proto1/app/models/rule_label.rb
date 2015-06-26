class RuleLabel < ActiveRecord::Base
  belongs_to :rule
  validates_inclusion_of :rule_type, :in => %w(fetch_rule value_rule)
  validates_presence_of :label
  acts_as_reportable

  def validate
    # When two required fields were entered
    if !label.blank? && !rule_type.blank?
      # rule_name_C is required and should be valid
      # rule_name is the name of the rule with id of rule_name_C
      data_rule_used = Rule.find_by_id(rule_name_C)
      if !data_rule_used
        errors[:base]=("The rule_name_C value is invalid.")
      elsif data_rule_used.name != rule_name
        rule_name = data_rule_used.name
      end


      # PROPERTY_C is required and should be valid
      if data_rule_used && rule_type == "fetch_rule"
        if property_C.blank?
          errors.add(:property_C, "must not be blank.")
        elsif property_C > -1
          # fetch rule property_C must be valid
          db_field = DbFieldDescription.find_by_id(property_C)
          if !db_field
            errors.add(:property_C, "is invalid.")
          end
        end
      end
    end
  end


  # Overwrites property method so that it will return property based on
  # property_C
  def property
    if property_C
      if property_C == -1
        "is_exist"
      else
        db_field = DbFieldDescription.find(property_C)
        db_field.data_column + (db_field.is_date_type ? "_ET" : "")
      end
    end
  end

  
  # Overwrites rule_name method so that it will return property based on
  # rule_name_C
  def rule_name
    if rule_name_C && r= Rule.find(rule_name_C)
      r.name
    end
  end


  # Returns the description of the label
  def readable_label
    if label.match(/\AA/)
      n = property_display_name
      rule_name +
        (n == "Exist?" ? "" : "[#{n.downcase.include?("date") ? "Date" : n}]")
    else
      rule_name
    end
  end

  
  # Returns the display name of the property field
  def property_display_name
    if property_C
      property_C == -1 ? "Exist?" : DbFieldDescription.find(property_C).display_name
    end
  end

end

