class RegexValidator < ActiveRecord::Base
  extend HasShortList
  
  # HasShortList has a get_list_items method that allows us to get
  # a prefetched list of validators in the form builder.

  # Normalizes the input string and returns the resulting string
  def normalize(input_string)
    m = regex.match(input_string)
    if m
      ret = normalized_format
      while ret.include?('#{$')
        s_pos = ret.index('#{$')
        e_pos = ret.index('}')
        d_val = ret[(s_pos + 3)..(e_pos - 1)].to_i
        ret = ret.sub('#{$' + d_val.to_s + '}', m[d_val].to_s)
      end
    end
    ret
  end
  
  # Returns a hash from the code of a regex_validator record to the attributes 
  # of that record. The returned hash is needed when validating form field using 
  # regular expression at client side with JavaScript code
  def self.code_to_attrs
    rtn={}
    self.all.each do |e|
      rtn[e.code] = e.attributes
    end
    rtn
  end
  
  # Converts the regular expression in JavaScript into the one used in Ruby
  def regex_in_ruby
    regex.gsub("^","\\A").gsub("$","\\z")
  end

end
