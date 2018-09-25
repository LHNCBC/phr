# A module for routines that intepret/parse date/time strings.
module DateInterpretation
  require 'active_support'
  require 'active_support/core_ext' # for Integer.years

  # Returns the value of the given string as a Time object.
  # Currently allowed formats are limited.  You can use "t" for today, and write
  # t-50Y for 50 years ago, or t+2Y for two years from now.  If the string
  # is blank, nil will be returned.  The time returned will be the beginning
  # of the specified day.
  #
  # Parameters
  # * str - the string to be parsed.  If not given, this will use abs_max.
  def self.interpret_relative_date(str)
    rtn = nil
    if !str.blank?
      if str !~ /\A\s*t\s*(([+-])\s*(\d+)Y)?\s*\Z/i
        raise StandardError.new('Invalid date limit string')
      else
        plus_minus, num_years = $2, $3
        rtn = DateTime.now
        offset = num_years.to_i.years
        if plus_minus=='+'
          rtn += offset
        else
          rtn -= offset
        end
        # Convert to a date to drop the time, then convert back to time
        rtn = rtn.to_date.to_time
      end
    end
    return rtn
  end
end
