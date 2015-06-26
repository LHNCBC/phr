# A module mixin for validating dates in the PHR system.
module DateValidations
  # Validates a date and updates the _ET and _HL7 fields.  If the date
  # field has a corresponding _time field (e.g. mydate_time) then the time
  # will be included in the _ET and _HL7 fields.
  #
  # Parameters:
  # * field - the name of the date field in the record being validated.
  #   This should contain the date as the user entered it.
  # * reqs - a hash of booleans indicating what is required.  These flags
  #   can be obtained from UserData.date_requirements.  If this parameter is nil,
  #   it is assumed that nothing is required.  Expected keys are:
  #   1) required - true if the field is required
  #   2) month - true if a month must be specified (in addition to a year)
  #   3) day - true if a day must be specified
  #   4) min - the minimum date (DateTime) that is acceptable.  (Optional)
  #   5) max - the maximum date (DateTime) that is acceptable.  (Optional)
  def validate_date(field, reqs)
    reqs = {} if reqs.nil?
    time_field = field+'_time'
    has_time_field = respond_to?(time_field)
    if new_record? || send(field+'_changed?') ||
        (has_time_field && send(time_field+'_changed?'))
      month_abbrevs = %w{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
      needs_calc = false
      field_val = self.send(field)
      if field_val.blank?
        if reqs['required']
          errors.add(field, 'is required')
        else
          # Blank out the fields
          self.send(field+'=', '')
          self.send(field+'_ET=', self.send(field+'_HL7=', ''))
        end
      elsif field_val =~ /\A(\d\d\d\d)\s+(#{month_abbrevs.join("\|")})(\s+(\d\d?))?\Z/i
        year, month, day = [$1, $2, $4]
        if reqs['day'] && day.blank?
          errors.add(field, 'must be a full date')
        else
          month = month.titlecase
          month_num = month_abbrevs.index(month) + 1
          needs_calc = true
        end
      elsif field_val =~/\A(\d\d\d\d)(\/(\d\d?)(\/(\d\d?))?)?\Z/
        year, month_day, month_num, slash_day, day = [$1, $2, $3, $4, $5]
        if reqs['day'] && day.blank?
          errors.add(field, 'must be a full date')
        elsif reqs['month'] && month_num.blank?
          errors.add(field, 'must have a month as well as the year')
        else
          if month_num
            month_num = month_num.to_i
            month = month_abbrevs[month_num-1]
          end
          needs_calc = true
        end
      else
        errors.add(field, 'is not in the format YYYY/MM/DD')
      end

      if has_time_field
        time_num, minutes, seconds, fraction = parse_time(time_field)
        # Convert time_num to seconds
        time_num /= 1000000.0 if time_num
      end

      if errors[field].empty? && needs_calc
        year_num = year.to_i
        day_num = day.blank? ? nil : day.to_i
        range_pos = reqs['epoch_point']
        begin
          # Convert time_num to seconds, before using it to make the date
          date = complete_date(year_num, month_num, day_num, time_num, range_pos)
        rescue ArgumentError=>e # ArgumentError for an invalid date
          errors.add(field, 'is an invalid date')
        end

        if errors[field].empty?
          min_date = reqs['min']
          max_date = reqs['max']
          if min_date && min_date > date
            errors.add(field, "cannot be before #{min_date.strftime('%Y/%m/%d')}")
          end
          if max_date && max_date < date
            # max_date is actually set to the beginning of the next date, so we back up one
            # day when preparing a message for the user.
            errors.add(field, "cannot be after #{(max_date-86400).strftime('%Y/%m/%d')}")
          end
          if errors[field].empty?
            if day
              field_val = "#{year} #{month} #{day}"
            elsif month
              field_val = "#{year} #{month}"
            else
              field_val = year
            end
            self.send(field+'=', field_val)
            # ET is in microseconds, hence the "*1000".  Note that we
            # are truncating, not rounding-- see note in parse_time.
            self.send(field+'_ET=', (date.to_f*1000).to_i)
            self.send(field+'_HL7=', make_hl7_dtm(date, time_num.nil?, minutes,
                                                  seconds, fraction))
          end
        end
      end
    end
  end


  private

  # Returns a Time object based on the given year, month, and day values, and
  # on the given range point parameter which controls the second in the
  # specified range to which the the date is set.  If the date is invalid
  # an ArgumentError will be raised.
  #
  # Parameters:
  # * year_num - the year
  # * month_num - the month as a number, 1-12 (may be nil)
  # * day_num - the day as number, 1-31 (may be nil)
  # * time - the time of day, as a number of seconds (may be nil, and may be fractional)
  # * range_pos:  The position to chose in the range of time specified by the date
  #   parameters.  0=begining, 1=middle, 2=end
  def complete_date(year_num, month_num, day_num, time, range_pos)
    s_in_day = 86400
    end_of_day_s = s_in_day - 0.001 # less one ms
    mid_day_s = s_in_day/2
    if !month_num
      day_num = 1
      if range_pos==0
        month_num=1
      elsif range_pos==1
        month_num=7
      else # range_pos == 2
        month_num = 12
        day_num = 31
        time = end_of_day_s if !time
      end
    elsif !day_num
      if range_pos==0
        day_num = 1
      elsif range_pos==1
        day_num = (month_num==2) ? 14 : 15  # Middle of month
      else # range_pos == 2
        if month_num==2
          day_num = (year_num%100==0 && year_num%400!=0) ? 29 : 28
        elsif month_num==4 || month_num==6 || month_num==9 || month_num==11
          day_num = 30
        else
          day_num = 31
        end
        time = end_of_day_s if !time
      end
    elsif !time
      if range_pos==1
        time = mid_day_s
      elsif range_pos==2
        time = end_of_day_s
      end
    end
    rtn = Time.local(year_num, month_num, day_num)
    rtn += time if time
    return rtn
  end


  # Parses the given time field and normalizes its format.  If there is a format
  # problem, an error message will be added to this record's errors.
  #
  # Parameters:
  # * time_field - the name of the time field in this record.
  #
  # Returns:  nil if there is a format issue or if the field value is blank;
  # otherwise the epoch time value in microseconds (and as an integer, to avoid
  # possible rounding issues), followed by the parsed string
  # values of the minutes, seconds, and fractional sub-seconds, as entered
  # by the user (with nil values if not entered).
  def parse_time(time_field)
    time_field_val = self.send(time_field)
    if !time_field_val.blank?
      # We could use Time.parse, but that accepts more than we want to (e.g.
      # dates and time zones).
      # I am requiring AM or PM (not 24-time) because otherwise we don't know
      # what "1:23" means.
      format_msg = 'is not in the format 12:34 PM.'
      # HL7 DTM allows up to four digits after the decimal.  We will drop
      # any digits after that.  I read something about dropping excess digits
      # being better than rounding for time values so that you do not shift
      # times into the future (e.g., you would not round 2013/7 to 2014).
      if time_field_val !~ /\A\s*(\d?\d)(:(\d\d)(:(\d\d)(\.(\d{1,4})\d*)?)?)?\s*([AaPp]\.?[Mm]\.?)\s*\Z/
        errors.add(time_field, format_msg)
      else
        hours, sub_hour, minutes, sub_min, seconds, sub_sec, fraction, am_pm =
          [$1, $2, $3, $4, $5, $6, $7, $8]

        # Range checking
        hour_num = hours.to_i
        min_num = minutes.to_i if minutes
        sec_num = seconds.to_f if seconds
        if hour_num < 1 || hour_num > 12 || min_num && min_num > 59 || (sec_num && sec_num >= 60)
          errors.add(time_field, format_msg)
        else
          # Compute the time in seconds, and standardize the format of the field
          am_pm = am_pm.slice!(0, 1)
          pm = (am_pm == 'P' || am_pm == 'p')
          if pm
            hour_num24 = hour_num==12 ? 12 : 12 + hour_num
          else
            hour_num24 = hour_num==12 ? 0 : hour_num
          end
          std_format = hours
          time_num = hour_num24*3600000000 # in micro-s.
          if min_num
            std_format += ':'+minutes
            time_num += min_num * 60000000 # in micro-s
            if sec_num
              std_format += ':'+seconds
              time_num += sec_num * 1000000 # in micro-s
              if fraction
                std_format += '.'+fraction
                # Left pad fraction with zeros to make it four digits, then parse
                time_num += (fraction+('0'*(4-fraction.length))).to_i * 100 # in micro-s
              end
            end
          end
          std_format += pm ? ' PM' : ' AM'
          self.send(time_field+'=', std_format) if std_format != time_field_val
        end
      end
    end
    return time_num, minutes, seconds, fraction
  end


  # Builds and returns an HL7 date time string.  Avoids including precision
  # beyond what was entered by the user.
  #
  # Parameters:
  # * date - a Time object for the date/time being represented.
  # * date_only - true if no time should be included
  # * minutes - the minutes string, or nil if not entered
  # * seconds - the seconds string, or nil if not entered
  # * fraction - the digits beyond the decimal for the number of seconds,
  #   or nil if none were entered.
  def make_hl7_dtm(date, date_only, minutes, seconds, fraction)
    # Include time in HL7 when the time field has a value
    hl7_format = date_only ? '%Y%m%d' : '%Y%m%d%H'
    hl7_str = date.strftime(hl7_format)
    if minutes
      hl7_str += minutes
      if seconds
        hl7_str += seconds
        hl7_str += '.'+fraction if fraction
      end
    end
    return hl7_str
  end
end
