module DateFieldsHelper

  include CalendarHelper

  # Builds the appropriate type of input mechanism for a field 
  # with a control_type of 'calendar'.  It is assumed that this 
  # helper class can be expanded to include other types of dates, 
  # but for now it's just set to work for date fields that include 
  # a calendar as an input mechanism.
  #
  # This includes code to check the field for a "hidden_field" class
  # designation.  If that's found, the entire field division is marked
  # as "display: none".
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # Builds the input mechanism for entering a time. Essentially a text_field
  # except with other event javascript
  #
  # Parameters:
  # * someField - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * in_table - a boolean value that indicates whether or not the
  #   field to be processed is to be located in a table cell.  Optional;
  #   set to false if not passed in.
  # * tagAttrs - attributes for the date field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the input field with all specified
  #          attributes, modifiers, labels, etc.
  #
  def timeField(someField,
                someForm,
                in_table = false,
                tagAttrs={},
                fd_suffix=nil)

    timeOnly = someField.getParam('time_only') # true if there is no date field
    if timeOnly
      tagAttrs = merge_tag_attributes(tagAttrs, {:timeonly=>"true"})
    end

    return textField(someField, someForm, in_table, tagAttrs, fd_suffix)
  end  # end timeField method

  
  # Builds the input mechanism for a field with a control_type of 
  # 'calendar'.  This may or may not include a division spec to 
  # enclose the field within a division, depending on the parameters
  # passed in.  For now we're assuming all date fields get a calendar
  # button along with them.
  #
  # Parameters:
  # * someField - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * in_table - a boolean value that indicates whether or not the
  #   field to be processed is to be located in a table cell.  Optional;
  #   set to false if not passed in.
  # * tagAttrs - attributes for the date field tag
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  #
  # Returns: an HTML string containing the input field with all specified
  #          attributes, modifiers, labels, etc.
  #  
  def dateField(someField, 
                someForm,
                in_table = false,
                tagAttrs={}, 
                fd_suffix=nil)
                
    # use the calendar_field method in calendar_helper to set up the
    # input field and the button for the calendar
    output = calendar_field( :fe, someField, someForm, fd_suffix, in_table,
          { :class => 'ffar_calendar',
            :field_title => someField.display_name,
            :button_image => asset_path('blank.gif')},
          { :firstDay => 1,
            :range => [1920, 2999],
            :step => 1,
            :showOthers => true,
            :cache => true }
          )
    
    # based on the date format, figure out the appropriate javascript
    # regular expression for field validation as well as the hover text
    # with required/optional value tags. Assumes YYYY together as well
    # as MM and DD
    target = someField.target_field

    # Add default value processing
    func_call = 'function(event){Def.DateField.insertDefaultVal(this);}'
    add_observer(target, 'focus', func_call)

    # Add any additional attributes from tagAttrs.  (Couldn't find a way to
    # pass it in to calendar_field that worked.)
    if (!tagAttrs.nil? && tagAttrs.size > 0)
      attrs = ''
      tagAttrs.keys.each do |k|
        attrs += ' ' + k.to_s() + '="' + html_escape(tagAttrs[k]) + '"'
      end
      output = output.gsub('<input', '<input' + attrs)
    end   
    return output

  end  # end dateField method
  
  
  # Generate help text from the date format
  # Parameters:
  #   date_format : date format parameter
  # Return:
  #   regular expression
  #
  def getHelpText(date_format)
    lowercase = 0
    help_text = ''
    date_format.each_byte { |b| 
                lowercase += 1 if b.chr.eql?('[')  
                lowercase -= 1 if b.chr.eql?(']')  
                if lowercase > 0 && !(b.chr.eql?('[') || b.chr.eql?(']'))
                  help_text << (b.chr).downcase
                else
                  help_text << b.chr
                end
    }
    help_text = help_text.gsub(/[\[\]]/,'')
    return help_text.gsub(/YYYY/,'YYYY')
  end


  # Generates and returns the regular expression used to check the date input
  # by the user. This is based on the date format. if MM is not required and
  # we do not want MM, we can do with YYYY MM as the date format.
  # Parameters:
  #   data_format : data format parameter
  # Return:
  #   regular expression
  #
  def getRegexForDate(date_format)
    if !date_format.match(/\[(MM|DD)(?!\])/).nil? ||
       !date_format.match(/\[\[/).nil?
      if !date_format.match(/[ .\/-]\[MM\]/).nil?
        date_format = date_format.gsub(/\[MM\]/,'?(MM)?')
      end
      if !date_format.match(/\[MM\]/)
        date_format = date_format.gsub('\[MM\]','(MM)?')
      end
      if !date_format.match(/[ .\/-]\[DD\]/)
        date_format =  date_format.gsub('\[DD\]','?(DD)?')
      end
      if !date_format.match(/\[DD\]/)
        date_format = date_format.gsub('\[DD\]','(DD)?')
      end
      date_case1 = dateRegex(date_format)
      date_case1 = date_case1.gsub(/\)\?/,')')
      date_case2 = date_format.gsub(/[\[]+[\[\?\(\)MD \-\/\.\]]*/,'(?!( ?[0-9a-zA-Z]))')
      if date_case2.match(/\)\(/).nil?
        date_case2 = date_case2.gsub(/\(\?/,'?(?')
        date_case2 = date_case2.gsub(/YYYY/,'(19|20)(\\\\\\\\d\\\\\\\\d)')
      end
      date_format = date_case1+'|'+date_case2
    else
      date_format = dateRegex(date_format)
    end

    return date_format
  end
  
  # Generates a regular expression to be used to validate a date based on the
  # date format.
  # eg,  YYYY MM [DD]
  # Parameters:
  #   df : date format with YYYY  DD MM components
  # Returns the regular expression
  #
  def dateRegex(df)
    y = '(19|20)(\\\\\\\\d\\\\\\\\d)'
    m = "(0[1-9]|1[012])"
    d = "(0[1-9]|[12][0-9]|3[01])"
    s = "([- /.]?)"
    date_format = df.gsub(' [',' ?(')
    date_format = date_format.gsub('.[','.?(')
    date_format = date_format.gsub('-[','-?(')
    date_format = date_format.gsub('/[','/?(')
    date_format = date_format.gsub('[','(')
    date_format = date_format.gsub(']',')?')
    date_format = date_format.gsub('YYYY',y)
    date_format = date_format.sub('MM',m)
    date_format = date_format.sub('DD',d)
  end


end # DateFieldsHelper
