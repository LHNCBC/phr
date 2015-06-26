# Provides a calendar tool.
# The Calendar Helper methods create HTML code for different variants of the
# Dynarch DHTML/JavaScript Calendar.
#
# Author: Michael Schuerig,
#         <a href="mailto:michael@schuerig.de">michael@schuerig.de</a>, 2005
# Free for all uses. No warranty or anything. Comments welcome.
#
# Version 0.02:
# Always set calendar_options's ifFormat value to '%Y/%m/%d %H:%M:%S'
# so that the calendar recieves the object's time of day.  Previously,
# the '%c' formating used to set the initial date would be parsed by
# the JavaScript calendar correctly to find the date, but it would not
# pick up the time of day.
#
# Version 0.01:
# Original version by Michael Schuerig.
#
#
#
# == Prerequisites
#
# Get the latest version of the calendar package from
# <a href="http://www.dynarch.com/projects/calendar/">http://www.dynarch.com/projects/calendar/</a>
#
# == Installation
#
# You need to install at least these files from the jscalendar distribution
# in the +public+ directory of your project
#
#  public/
#      images/
#          calendar.gif [copied from img.gif]
#      javascripts/
#          calendar.js
#          calendar-setup.js
#          calendar-en.js
#      stylesheets/
#          calendar-system.css
#
# Then, in the head section of your page templates, possibly in a layout,
# include the necessary files like this:
#
#  <%= stylesheet_link_tag 'calendar-system.css' %>
#  <%= javascript_include_tag 'calendar', 'calendar-en', 'calendar-setup' %>
#
# == Common Options
#
# The +html_options+ argument is passed through mostly verbatim to the
# +text_field+, +hidden_field+, and +image_tag+ helpers.
# The +title+ attributes are handled specially, +field_title+ and
# +button_title+ appear only on the respective elements as +title+.
#
# The +calendar_options+ argument accepts all the options of the
# JavaScript +Calendar.setup+ method defined in +calendar-setup.js+.
# The ifFormat option for +Calendar.setup+ is set up with a default
# value that sets the calendar's date and time to the object's value,
# so only set it if you need to send less specific times to the
# calendar, such as not setting the number of seconds.
module CalendarHelper

  # Returns HTML code for a calendar that pops up when the calendar image is
  # clicked.
  #
  # _Original Example:_
  #
  #  <%= popup_calendar 'person', 'birthday',
  #        { :class => 'date',
  #          :field_title => 'Birthday',
  #          :button_image => 'calendar.gif',
  #          :button_title => 'Show calendar' },
  #        { :firstDay => 1,
  #          :range => [1920, 1990],
  #          :step => 1,
  #          :showOthers => true,
  #          :cache => true }
  #  %>
  #
  #  Replaced "method" argument with "field_desc, someForm" to match the
  #  method accessor with generic form prototype framework.
  #
  # Parameters:
  # * field_desc - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * in_table - a boolean value that indicates whether or not the
  #   field to be processed is to be located in a table cell.  Optional;
  #   set to false if not passed in.
  def popup_calendar( object, field_desc, someForm, in_table, html_options = {},
                      calendar_options = {})
    _calendar( object, field_desc, someForm, in_table, false, true,
      html_options, calendar_options)
  end


  # Returns HTML code for a date field and calendar that pops up when the
  # calendar image is clicked.
  #
  # _Example:_
  #
  #  <%= calendar_field 'person', 'birthday',
  #        { :class => 'date',
  #          :field_title => 'Birthday',
  #          :button_title => 'Show calendar' },
  #        { :firstDay => 1,
  #          :range => [1920, 1990],
  #          :step => 1,
  #          :showOthers => true,
  #          :cache => true }
  #  %>
  # 10/29/07 Added fd_suffix to make sure we attach to the correct field
  #
  # Parameters:
  # * field_desc - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  # * in_table - a boolean value that indicates whether or not the
  #   field to be processed is to be located in a table cell.  Optional;
  #   set to false if not passed in.
  def calendar_field( object, field_desc, someForm, fd_suffix, in_table = false,
                      html_options = {}, calendar_options = {})
    _calendar( object, field_desc, someForm, fd_suffix, in_table,
               true, true, html_options, calendar_options)
  end

  ### content from here to end of calendar helper should be private

  # Parameters:
  # * field_desc - the field to display (a FieldDescripion)
  # * someForm - the form instance (from the template)
  # * fd_suffix - a suffix to be appended to field name; indicates the
  #   level, if any, at which this field appears in the form hierarchy
  # * in_table - a boolean value that indicates whether or not the
  #   field to be processed is to be located in a table cell.  Optional;
  #   set to false if not passed in.
  def _calendar( object, field_desc, someForm, fd_suffix, in_table =false,
                 show_field = true, popup = true,
                 html_options = {}, calendar_options = {})
    button_image = html_options[:button_image] || 'calendar'

    target = field_desc.target_field
    target_field = target
    gen_target = target_field_for_panel(target+ '_calendar')
    target += fd_suffix if !fd_suffix.nil?
    # change target_field if it is within a loinc panel
    target = target_field_for_panel(target)
    date = value(object, target)
    input_field_id = "#{object}_#{target}"

    target_cal = target_field_for_panel(target_field+'_calendar')
    target_cal += fd_suffix if !fd_suffix.nil?
    calendar_id = "#{object}_#{target_cal}"

    ## Define format for date displays in text field
#    add_defaults(calendar_options, :ifFormat => '%Y/%m/%d %H:%M:%S')
#    add_defaults(calendar_options, :ifFormat => '%b %e, %Y')  # example April 4, 2007 or April 11, 2007
    add_defaults(calendar_options, :ifFormat => DATE_RET_FMT_D)  # example April 4, 2007 or April 11, 2007
#    add_defaults(calendar_options, :ifFormat => '%Y/%m/%d')  # example 2007/04/04 7
#    add_defaults(calendar_options, :daFormat => '%b %e, %Y')  # example 2007/04/04 7
    add_defaults(calendar_options, :daFormat => DATE_RET_FMT_D)  # example 2007/04/04 7
 #   add_defaults(calendar_options, :daFormat => '%Y/%m/%d')  # example 2007/04/04 7

    field_options = html_options.dup
    add_defaults(field_options,
      :value => date && date.strftime(calendar_options[:ifFormat]),
      :size => 12
    )

    rename_option(field_options, :field_title, :title)
    remove_option(field_options, :button_title)

    if show_field
      disp_size = field_desc.getParam("display_size", false)
      tag_attrs = Hash.new
      tag_attrs = { :size => disp_size, :autocomplete => "off" }
    
      if !someForm.nil?
        field = someForm.text_field(target.to_sym,tag_attrs )
      else
        field = 'INPUTFIELD'
      end
      date_format = field_desc.getParam("date_format")
      if (date_format.nil?)
        func_call = 'function(event){parseDateString(this, "' +
                                                field_desc.display_name + '");}'
        add_observer(gen_target, 'change', func_call)     
      end
    else
      tag_attrs = Hash.new 

      if !someForm.nil?
        field = someForm.hidden_field(target.to_sym,tag_attrs)
      else
        field = 'INPUTFIELD'
      end
    end # if we are/aren't showing the field

    cal = field_desc.getParam("calendar")
    if cal == 'true'
      if !in_table && !field_desc.help_text.blank?
        help_button = '<td class="date_help_cell">'+helpButton(field_desc)+'</td>'
      else
        help_button = ''
      end
      min_date = convert_to_datepicker_option(
                   get_field_property(field_desc, 'abs_min'))
      max_date = convert_to_datepicker_option(
                   get_field_property(field_desc, 'abs_max'))
      year_range_spec = format_datepicker_year_range(min_date, max_date)
      # Replace Calendar with Datepicker. -Ajay 04/04/2013
      @form_field_js << <<-END_CAL_JS
         var date_changed = false;
         $J( '##{input_field_id}' ).datepicker({ 
           //firstDay: 1,
           class: 'calendar',
           minDate: '#{min_date}',
           maxDate: '#{max_date}',
           changeMonth: true,
           changeYear: true,
           constrainInput: false,
           dateFormat: "yy M dd",
           showOn: "button",
           showOtherMonths: true,
           selectOtherMonths: true,
           showMonthAfterYear: true,
           buttonImage: '#{asset_path('blank.gif')}',
           buttonImageOnly: true,
           buttonText: "",
           onChangeMonthYear: function(year, month) {
             if(date_changed) {
               return;
             }
             date_changed = true;
             var d = $J(this).datepicker("getDate");
             if(d !== null) {
               d.setFullYear(year);
               d.setMonth(month - 1);
               //this.setValue(d.toLocaleFormat("%Y/%m/%d"));
               $J(this).datepicker("setDate", d);
Def.Logger.logMessage(['This log statement here to make acceptance tests (usage_stats) pass!']);
               appFireEvent(this, "change");
             }
             date_changed = false;
           },
           onSelect: function() {
             appFireEvent(this, "change");
             $J(this).datepicker("hide");
           },
           onClose: function() {
             Def.Navigation.moveToNextFormElem(this);
           }
           #{year_range_spec}
         });
         $J('##{input_field_id}')[0].next().addClassName('sprite_icons-calendar');
      END_CAL_JS

      field = '<td class="date_cell"><div class="date_container hasTooltip">'+field+'</div></td>'
      content = ('<tr>'+field + help_button +'</tr>').html_safe
      content_tag('table', content, :class=>'dateField')
    else
      field
    end # end if we don't have a calendar parameter, or it's false
  end  # _calendar
  
  def value(object_name, method_name)
    if object = self.instance_variable_get("@#{object_name}")
      object.send(method_name)
    else
      nil
    end
  end

  def add_mandatories(options, mandatories)
    options.merge!(mandatories)
  end

  def add_defaults(options, defaults)
    options.merge!(defaults) { |key, old_val, new_val| old_val }
  end

  def remove_option(options, key)
    options.delete(key)
  end

  def rename_option(options, old_key, new_key)
    if options.has_key?(old_key)
      options[new_key] = options.delete(old_key)
    end
    options
  end

  def format_js_hash(options)
    options.collect { |key,value| key.to_s + ':' + value.inspect }.join(',')
  end
  
    # generate date text from date format. Same as in date_helper getHelpText
  # Parameters:
  #   date_format : date format parameter
  # Return:
  #   regular expression
  def getDateText(date_format)
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
    return help_text
  end

  # Get specified attribute from field descriptions
  # field_desc - Field description object
  # prop - Property (or param) of field description object.
  def get_field_property(field_desc, prop)
    str = ''
    if (field_desc.blank? || prop.blank?)
      return str
    end

    str = field_desc.getParam(prop)
    if (!str.blank?)
      return str
    end

    if (field_desc.db_field_description)
      p = field_desc.db_field_description.send(prop)
      str = p.to_s
    end
    return str
  end

  # Utility function to convert range specification of PHR convention
  # to datepicker option format.
  #
  # Ex: t - 150Y => -150Y
  #            t => 0
  def convert_to_datepicker_option(dateProp)
    opt = ''
    if (!dateProp.blank?)
      opt = dateProp[/^\s*t(.*)$/, 1]
      opt.gsub!(/\s/, "")
      if (opt.blank?)
        opt = '0'
      end
    end
    return opt
  end
  module_function :convert_to_datepicker_option

  #Utility function to format yearRange with minDate and maxDate. Intended to be
  #used in datepicker configuration calls.
  #
  # It makes simple assumptions that min_date and max_date have only years,
  # as seen in db_field_desctriptions table. If it involves month and day specs,
  # then this needs to be updated to handle those specs.
  #
  # Ex: minDate: -150Y, maxDate: 0 => ',yearRange: -150:+0'
  #
  # Note: Notice comma before yearRange in the return string. Use accordingly
  def format_datepicker_year_range(min_date, max_date)
    ret = ",yearRange: 'c-20:c+20'"
    min = min_date.gsub(/[Y]\s*$/, "")
    max = max_date.gsub(/[Y]\s*$/, "")
    if (!min_date.blank? && !max_date.blank?)
      max.sub!(/^\s*([^+-]?\d+)/, '+\1')
      ret = ",yearRange: '" + min + ":" + max + "'"
    end
    return ret
  end
end
