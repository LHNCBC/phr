# Per Clem at Saturday meeting 12/10/2010, only user data should be sanitized
# and Paul confirmed that there will be no HTML tag in these fields for now, so
# the sanitizing was simplified to only add a space right after less than sign
# (for less than or equal sign, no need to do anything)
module PhrDataSanitizer
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    def sanitize_user_data
      include PhrDataSanitizer::InstanceMethods
      before_validation :sanitize_fields
    end
  end

  module InstanceMethods
    def sanitize_fields
      self.class.columns.each do |column|
        if [:string, :text].include? column.type
          field = column.name.to_sym
          value = self[field]
          if value && (value.is_a? String)
            self[field] = value.gsub(/(<)([^=\s])/, '\1 \2')
          end
        end
      end
    end
  end
end