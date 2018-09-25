require "tempfile"
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  include ActionView::Helpers::NumberHelper

  # The following code overwrites the default output for fields with errors.
  # Instead of the default div tag wrapping, an "error_field" class name is
  # added to the tag.  This code was based on code found on the web at:
  #   http://snippets.dzone.com/tag/field_error_proc
  ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
    error_style = "error_field"
    if html_tag =~ /<(input|textarea|select)[^>]+class=/
      class_attribute = html_tag =~ /class=['"]/
      html_tag.insert(class_attribute + 7, "#{error_style} ")
    elsif html_tag =~ /<(input|textarea|select)/
      first_whitespace = html_tag =~ /\s/
      html_tag[first_whitespace] = " class='#{error_style}' "
    end
    html_tag
  end


  # Encodes the given string for inclusion in HTML
  def htmlEncode(str)
    str.gsub!(/&/, '&amp;');
    str.gsub!(/\"/, '&quot;');
    str.gsub!(/\'/, '&#39;');
    str.gsub!(/</, '&lt;');
    str.gsub!(/>/, '&gt;');
    str
  end

  # make sure form submit is not using the ajax
  def form_tag_wo_ajax(*args)
    args[1] ||={}
    args[1] = args[1].merge("data-ajax"=>false)
    form_tag(*args)
  end


  # Returns a form-based JavaScript tempfile which includes the form-specific
  # JavaScript file if it exists. The Javascript tempfile will be compressed
  # using asset pipe line systerm in production mode.
  def generate_form_js_tempfile
    # The form field JS will be in @form_field_js (which is built up as the form
    # is generated.
    #
    # Append some more declarations that are needed.
    @form_field_js << <<-EOD
      Def.dataFieldlabelNames_ = #{@form.data_field_labelnames.to_json};
      Def.delay_navsetup_ = #{@form.delay_navsetup};
      Def.Rules.prefetchedRules_ = #{@prefetched_obx_observations.to_json};
      Def.Rules.fieldRules_ = #{@field_rules.to_json};
      Def.Rules.affectedFieldRules_ = #{@affected_field_rules.to_json};
      Def.Rules.ruleActions_ = #{@rule_actions.to_json};
      Def.Rules.formRules_ = #{@form_rules.to_json};
      Def.Rules.ruleTrigger_ = #{@rule_trigger.to_json};
      Def.Rules.caseRules_ = #{@case_rules.to_json};
      Def.Rules.fetchRules_ = #{@fetch_rules.to_json};
      Def.Rules.reminderRules_ = #{@reminder_rules.to_json};
      Def.Rules.valueRules_ = #{@value_rules.to_json};
      Def.Rules.dataRules_ = #{@data_rules.to_json};
      Def.Rules.dbFieldRules_ = #{@db_field_rules.to_json};
      Def.Rules.loincFieldRules_ = #{@loinc_field_rules.to_json};
      Def.Rules.hashSets_ = #{@hash_sets.to_json};
      #{@rule_scripts && @rule_scripts.join("\n")}
      Def.FieldsTable.ControlledEditTable.DELETED_MARKER='#{FormData::DELETED_MARKER}';
      Def.tipFields_ = #{@tip_fields.to_json};
      Def.FieldDefaults = #{@field_defaults.to_json};
      Def.data_['form_name'] = #{@form_name.to_json};
      Def.Autocompleter.Base.TABLE_FIELD_JOIN_STR = '#{TABLE_FIELD_JOIN_STR}';
      Def.formVSplit_ = #{@form.vsplit};
      Def.Asset.pageAssets_ = #{rails_assets["page_assets"].to_json};
      Def.Asset.prefix_ = '#{rails_assets["prefix"]}';
      // The following could be in a global JS file
      window.tip_delay = #{TOOLTIP_DELAY};
      window.access_close = '#{ACCESS_KEY_CLOSE}';
      Def.SET_VAL_DELIM = '#{SET_VAL_DELIM}';
      Def.REGEX_ = #{RegexValidator.code_to_attrs.to_json};
      Def.DUP_DRUG_SPECIAL_INGREDIENTS = {#{PhrDrug::MULTI_DOSE_INGREDIENTS.to_a.join(': 1, ')}: 1}
    EOD

    temp_file = Tempfile.new(Time.now.to_i.to_s)
    # Write the file
    File.open(temp_file.path, 'w') do |file|
      # Note:  ce_table_data needs to be declared before the controlled edit
      # table instances are constructed.
      # And the ce_table_data construction needs to know whether or not this
      # is a read-only form
      file.print "Def.formEditability_ = " + @form_editability.to_json + ";\n"
      file.print 'Def.FieldsTable.ControlledEditTable.ceTableData_='+
        @ce_table_data.to_json + ";\n"
      file.print @form_field_js

      # Now this is fun.  Write javascript code to the file that will
      # write the event observers to Def.fieldObservers as the
      # page is written.  We're doing this to avoid having function parameters
      # that reference current field values from being interpreted as strings
      # instead of as javascript when the function is run.
      # The field observers' section
      file.print "Def.fieldObservers_={\n"
      first_target= true
      indent = "  "
      @field_observers.each do |target, event_hash|
        pre_target = first_target ? (first_target= false; " ") : ","
        file.print "#{indent + pre_target}'#{target}':{\n"
        first_event = true
        event_hash.each do |event_type, func_array|
          pre_event = first_event ? (first_event = false; " ") : ","
          file.print "#{indent + indent + pre_event}'#{event_type}': [#{func_array.join(', ')}]\n"
        end
        file.print "#{indent}}\n"
      end
      file.print "}\n"  # end of Def.fieldObservers_

      # The field validations' section
      file.print "Def.fieldValidations_ = {\n"
      first_validator = true
      @field_validations.each do |target, func_array|
          pre_validator = first_validator ?  (first_validator = false; " ") : (",")
          file.print "#{indent + pre_validator}'#{target}': #{func_array}\n"
      end
      file.print "}\n"

      # Adds field validations listeners into Def.fieldObservers_
      file.print  "Def.loadFieldValidations();\n\n"

      # merge form specific Javascript if exists
      form_js_file = File.join(JS_ASSET,"form_js", @form.form_name.downcase+".js")
      if File.exist? form_js_file
        str = File.read(form_js_file)
        file.print str
      end

      if !@form_onload_js.empty?
        @form_onload_js.keys.each do |fun_call|
          file.puts "\nEvent.observe(window,'load',#{fun_call} ); \n"
        end
      end
    end # finished creating temp_file

    temp_file
  end


  # Builds HTML for including both JavaScript and CSS asset files used on popup
  # page generated by rules.js#openPopup()
  def popup_assets
    [javascript_include_tag("manifest_jquery"),
      javascript_include_tag("manifest_popup_page"),
      stylesheet_link_tag("manifest_popup_page", :media=>'all')].join("\n")
  end


  # Returns the external JavaScript links based on Rails environment mode. The
  # links are specific to individual forms.
  # Parameters:
  # * form_name name of the form for the generated JavaScripts
  # * form_cache_name name of fragment cache of a form which is used as the
  #   generated JavaScript file name
  #
  # NOTES:
  # The generated JavaScript file contains some dynamic information including
  # list of data rules etc. Whenever the content of the generated JavaScript
  # file gets changed (e.g. a rule data being created), system will clear the
  # related cache (i.e. fragment cached). Since this method call is inside the
  # fragment, it will be called again and the cached value will be updated
  # accordingly.
  def javascript_include_tag_for_form(form_name, form_cache_name)
    temp_file = generate_form_js_tempfile
    gen_form_js =  "#{GENERATED_JS_PREFIX}_#{form_cache_name.downcase}.js"
    filename = JsGenerator.generate_with_lock(temp_file, gen_form_js)
    if filename
      content_tag('script', nil, {src: '/assets/'+filename})
    else
      content_tag('script', nil, {src: '/assets/'+gen_form_js})
    end
  end


  # build stylesheet links for vendor css files
  def stylesheet_link_tag_for_vendor(*args)
    options = args.extract_options!
    args = args.map do |arg|
      if Rails.env == "production"
        # assume there could be a minimized version of that stylesheet with extension
        # _min.css in the same directory
        arg_in_prod =  arg.split(".css")[0] +  "_min.css"
        if File.exist?(Rails.root.join("public", arg_in_prod))
          arg_in_prod
        else
          arg
        end
      else
        arg
      end
    end
    args = args.push(options)
    stylesheet_link_tag *args
  end


  def rails_assets
    rtn = {}
    rtn["prefix"] = Rails.application.config.assets.prefix
    rtn["page_assets"] ={"popup" => popup_assets}
    rtn
  end

  # This method creates a string that specifies the time difference between
  # now and the timestamp passed into it.  The difference is expressed in
  # the context of how long ago the timestamp was.
  #
  # The difference is shown in the largest time unit applicable - seconds
  # if the difference is less than a minute, otherwise minutes if the time
  # difference is less than an hour, otherwise hours if the time difference is
  # less than a day, otherwise months if the time difference is less than a
  # year, otherwise months.
  #
  # Parameters:
  # * timestamp the date/time of the "ago" time.
  #
  # Returns:
  # * a string specifying how long ago the time stamp was
  #
  def how_long_ago(timestamp)
    ret_str = nil
    if timestamp.nil?
      ret_str =  "not available"
    else
      bef = timestamp.strftime("%Y|%m|%U|%d|%H|%M|%S").split("|")
      aft = Time.now.strftime("%Y|%m|%U|%d|%H|%M|%S").split("|")
      labels = ["year", "month", "week", "day", "hour", "minute", "second"]
      i = 0
      aft.each do |af|
        diff = aft[i].to_i - bef[i].to_i
        if diff >= 1
          ret_str = long_ago_diff_string(diff, labels[i])
          break
        end
        i += 1
      end
      if ret_str.nil?
        ret_str = 'less than 1 second ago'
      end
    end # if there wasn't/was a last updated timestamp
    return ret_str
  end # how_long_ago


  # This method takes a number and a time element and formats a string
  # expressing how long ago the parameters represent.
  #
  # Parameters:
  # * number the number of units
  # * unit the unit of time (seconds, minuutes, hours, days, months, years, etc.)
  #
  # Returns:
  # * a string that combines the two with the text "ago"
  #
  def long_ago_diff_string(number, unit)
    disp_number = number_with_precision(number, :precision=>1,
                                        :strip_insignificant_zeros=>true)
    if disp_number == "1.0" || disp_number == "1"
      ret_str = '1 ' + unit + ' ago'
    else
      ret_str = disp_number + ' ' + unit + 's ago'
    end
    return ret_str
  end # long_ago_diff_string

end
