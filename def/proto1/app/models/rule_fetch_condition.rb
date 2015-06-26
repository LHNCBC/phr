class RuleFetchCondition < ActiveRecord::Base
  belongs_to :rule_fetch

  MAJOR_QUALIFIER = 'M'
  OTHER_QUALIFIER = 'O'

  # Accessor that provides a condition with its columns assembled into a
  # readable string (without blanks for null column values)
  #
  def condition_string
    str = []
    str << source_field
    #if !operator_1.blank?
      str << operator_1
    #end
#    if !operator_2.blank?
#      str << operator_2
#    end
    if !non_date_condition_value.blank?
      str << non_date_condition_value
#    else
#      str << condition_date.to_s
    end
    return str.join(' ')
  end


  # Adds, updates, and deletes conditions for a fetch rule.
  #
  # If the source_field for a condition is blank, it is assumed that the
  # condition is to be deleted, and do so.
  #
  # Otherwise it adds or updates the condition based on whether or not the
  # condition already exists in the table.
  #
  # Parameters:
  # * condition_data - array of the condition data to be added or updated.
  #     The array should contain one hash for each condition to be
  #     added or updated.  Each hash should contain data for all columns
  #     appropriate to the condition based on whether or not the source_field
  #     is or is not a date field.
  # * fetch_id - the id of the fetch rule for which the condition is being
  #     defined or updated.  Written to the rule_fetch_id column
  # * ref_fields - a set to receive the ids of all field definitions referenced
  #     by the conditions.  May or may not be empty when passed in.
  # Returns:
  # * ref_fields, with any fields referenced by the conditions passed in
  #     added to the set
  def self.update_add_conditions(condition_data, fetch_id, ref_fields)
    condition_data.each do |cd|
      fc = nil
      fc_id = cd.delete(:condition_id)
      if (!fc_id.nil?)
        fc = RuleFetchCondition.find_by_id(fc_id)
        if (!fc.nil?)
          if cd[:source_field].blank?
            fc.destroy
          else
            fc.update_attributes!(cd)
          end
        end
      end
      # Check again for an empty id, just in case the find_by_id above
      # didn't find anything.  Don't know why that would happen, but
      # there are lots of things that happen that I can't explain.
      if (fc.nil?)
        cd[:rule_fetch_id] = fetch_id
        fc = RuleFetchCondition.create!(cd)
      end
      if fc.errors.size == 0 && !cd['source_field'].blank?
        ref_fields << DbFieldDescription.find_by_id(fc.source_field_C)
      end
    end # do for each condition
    return ref_fields
  end # update_add_conditions


  # Performs validations on fetch conditions before they are saved or
  # updated.
  #
  # Problems are documented via messages written to the errors object that
  # is automatically created for the class.
  #
  def validate

    # validate the id of the parent fetch rule
    if rule_fetch_id.nil?
      errors.add(:rule_fetch_id, 'must not be nil')
    else
      base_rule = RuleFetch.find_by_id(rule_fetch_id)
      if base_rule.nil?
        errors.add(:rule_fetch_id, 'must be the id of an existing fetch rule')
      end
    end

    # Makes sure user receives warning when do saviing while having empty value fields
    source_field = source_field_C && DbFieldDescription.find_by_id(source_field_C)
    conditioned_on_date_field =
      source_field && source_field.predefined_field.field_type == "DT - date"
    if !source_field_C.blank?  && !conditioned_on_date_field
      if non_date_condition_value.blank?
        errors.add(:non_date_condition_value, "must not be blank.")
      elsif non_date_condition_value_C.blank?
        errors.add(:non_date_condition_value_C, "is invalid.")
      end
    end



#    # Fills out operator and non_date_condition_value fields based on the type of
#    # source_field and validates the fields
#    # 1) make sure source_field not empty and valid
#    # 2) make sure value field is not empty and valid
#    # 2.5) get field type of source_field
#    # 3) if move the condition value into operator 1 if it is a date field
#    # 4) else find proper op for operator 1 field
#    # 5) validate operator_1 and operator_1_C
#    ##
#    if !source_field.blank? && !source_field_C.blank?
#      db_field_1 = DbFieldDescription.find_by_id(source_field_C)
#      errors.add(:source_field_C, "'#{source_field_C}' does not exist.") unless db_field_1
#
#      db_field_2 = db_field_1.db_table_description.db_field_descriptions.find_by_display_name(source_field)
#      errors.add(:source_field, "'#{source_field}' does not exist.") unless db_field_2
#
#      if (db_field_1 != db_field_2)
#          errors[:base]=("Source field '#{source_field}' does not match source_field_C '#{source_field_C}'") # end of 1)
#      end
#
#      if db_field_1 == db_field_2
#        vf = self.non_date_condition_value && self.non_date_condition_value.clone
#        vfc = self.non_date_condition_value_C && self.non_date_condition_value_C.clone
#        errors.add(:non_date_condition_value, "must not be blank.") if vf.blank?
#          #errors.add(:non_date_condition_value_C, "must not be blank.") if vfc.blank?
#
#        if !vf.blank? && !vfc.blank?
#            case db_field_1.predefined_field.field_type # END OF 2.5)
#            when "DT - date", "DTM - date/time"
#              # validates operator_1 and it's code
#              unless ["Last/most recent date", "First/oldest date"].include?(vf)
#                errors.add(:non_date_condition_value, "'#{vf}' is invalid.")
#              end
#              dv = ComparisonOperator.find_by_id(vfc).display_value
#              unless ["Last/most recent date", "First/oldest date"].include?(dv)
#                errors.add(:non_date_condition_value_C, "'#{vfc}' is invalid.")
#              end
#
#              if errors.empty?
#                self.operator_1 = vf #if self.non_date_condition_value
#                self.operator_1_C = vfc #if self.non_date_condition_value_C
#                self.non_date_condition_value = nil
#                self.non_date_condition_value_C = nil
#              end
#            when "Set - String"
#              op = ComparisonOperator.find_by_display_value("is")
#              self.operator_1 = op.display_value
#              self.operator_1_C = op.id
#            else
#              op = ComparisonOperator.find_by_display_value("equal (=)")
#              self.operator_1 = op.display_value
#              self.operator_1_C = op.id
#            end # END OF 4)
#          end
#
#        end
#      end

   
    # validate the condition type and comparison type if this is a comparison
    check_required_column('condition_type')

    # put condition_type checking back in after all tables updated, no need
    # to revert migration 830
#    if (!condition_type.nil?)
#      if (condition_type != MAJOR_QUALIFIER &&
#          condition_type != OTHER_QUALIFIER)
#        errors.add(:condition_type, 'invalid condition type (' +
#                                     condition_type + ')')
#      end
#    end

#      elsif (condition_type == 'C')
#        basis_msg = base_rule.check_comparison_basis
#        if (!basis_msg.nil?)
#          errors.add(:condition_type, basis_msg)
#        end


    # validate the other required columns
    check_required_column('source_field')
    check_required_column('source_field_C')
    check_required_column('operator_1_C')

    # Make sure the operator is not blank and is one we recognize
    # The taffy_operator method will raise an exception if the operator
    # is not recognized; no need to add an error for it.
    if (operator_1.nil?)
      errors.add(:operator_1, 'must not be blank')
    else
      validate_operator_column(:operator_1)
    end

    # Do checks for non-date conditions
    if (!non_date_condition_value.blank?)
      if (!operator_2.blank?)
        errors.add(:operator_2, 'used only for source fields that are date ' +
            'fields.')
      end
      if (!condition_date.blank?)
        errors.add(:condition_date, 'must not be specified when a condition ' +
            'value is specified.  One of these is ' +
            'wrong.')
      end
      if (!condition_date_ET.blank?)
        errors.add(:condition_date_ET, 'must not be specified when a ' +
            'condition value is specified.')
      end
      if (!condition_date_HL7.blank?)
        errors.add(:condition_date_HL7, 'must not be specified when a ' +
            'condition value is specified.')
      end

#    # Do checks for date conditions
#    else
#      if (condition_date.blank? && !operator_2.blank?)
#        errors.add(:condition_date, 'Date must be specified if a recency ' +
#                                    'qualifier is specified.')
#      elsif (!condition_date.blank? && operator_2.blank?)
#        errors.add(:operator_2, 'Recency qualifier must be specified if a ' +
#                                'date is specified.')
#      end
#      if (!condition_date.blank?)
#        if (condition_date_ET.blank?)
#          errors.add(:condition_date_ET, 'missing epoch value for date')
#        end
#        if (condition_date_HL7.blank?)
#          errors.add(:condition_date_HL7, 'missing HL7 value for date')
#        end
#      end
#      if (!operator_2.nil?)
#        validate_operator_column(:operator_2)
#      end
     end # if condition does or doesn't have non-date value
  end # validate


  # Checks a column whose value is required to make sure that a value
  # is there.  If not, adds a messge to the errors object.
  #
  # Parameters:
  # * column_name - name of the column to be checked
  # Returns:  none
  #
  def check_required_column(column_name)
    val = self.send(column_name)
    if val.blank?
      errors.add(column_name, 'must not be blank')
    end
  end # check_required_column


  # Checks operator column to see if the operator name is valid. If not, addes
  # a messsage to the errors object
  #
  # Parameters:
  # * column_name - name of the column to be checked
  def validate_operator_column(column_name)
    val = self.send(column_name)
    if !val.blank?
      r = ComparisonOperator.find_by_display_value(val)
      errors.add(column_name, "has an invalid operator '#{val}' " +
                 "for field '#{self.send("source_field")}'") unless r
    end
    ### TODO: by using the following validation code, it will fail some
    ###       rule_fetch tests. since the fetch rule UI has not done yet, I will
    ###       keep this validation as loose as it was until the UI is working-Frank
    #
    #    val = self.send(column_name)
    #    if !val.blank?
    #      query_field = DbFieldDescription.find_by_id(source_field_C)
    #      fd = query_field.field_descriptions[0]
    #      if fd.field_type == "DT - date"
    #        case column_name
    #        when :operator_1
    #          g = ComparisonOperator.find_by_display_value("recency_values")
    #        when :operator_2
    #          g = ComparisonOperator.find_by_display_value("recency_qualifiers")
    #        else
    #          raise "The input column_name is invalid. Use :operator_1 or :operator_2 instead."
    #        end
    #        r = ComparisonOperator.find_by_parent_id_and_display_value(g.id, val)
    #        errors.add(column_name, " has an invalid date operator '#{val}' for field '#{query_field.data_column}'") unless r
    #      else
    #        r = fd.predefined_field.comparison_operators.find_by_display_value(val)
    #        errors.add(column_name, "has an invalid operator '#{val}' for field '#{query_field.data_column}'") unless r
    #      end
    #    end
  end # validate_operator_column


  # Adds new query conditions from current instance to the opt hash
  # passed in, and returns it.
  #
  # Parameters:
  # opt - hash of options currently defined for a query
  # Returns:
  # opt - with options based on the current condition added as appropriate
  def executable_query(opt, js_db)
    # validates input data source js_db
    unless RuleFetch::DATA_SOURCE_NAMES.include? js_db
      raise "\n*** The data source: '#{js_db}' for fetching is unknown." +
            "\n*** Please choose one from the following list: " +
            "#{RuleFetch::DATA_SOURCE_NAMES.inspect}"
    end

    op_type = "#{js_db}_operator"
    opt_cond = opt[:conditions] || {}
    db_field = DbFieldDescription.find(source_field_C)
    query_field = db_field.data_column

    if db_field.is_date_type
      query_field += "_ET"
      # if there is recency values operator
      if operator_1_C
        op_1 = RuleFetchCondition.comparison_operator(db_field, operator_1_C)
        # "All" option in operator_1 will be neglected
        if(op_1.display_value != "All dates")
          opt[:order] = {query_field => op_1.send(op_type) }
          opt[:limit] = 1
        end
      end

      # if there is recency qualifiers operator
      if condition_date_ET
        op_2 = RuleFetchCondition.comparison_operator(db_field, operator_2_C)
        opt_cond[query_field] = {op_2.send(op_type) => condition_date_ET}
      end
    else
      query_operator = RuleFetchCondition.comparison_operator(db_field,
                                                 operator_1_C).send(op_type)
      query_string = non_date_condition_value

      if non_date_condition_value_C
        query_field += "_C"
        if query_field == "obx3_2_obs_ident_C"
          query_field = "loinc_num"
        end
        query_string = non_date_condition_value_C
      end

      ##### beginning of drug_classes_C specific code
      # TODO: Should be removed when the classes were loaded into taffy as array
      # if the search operator is a set operator
      if op_type == "active_record_operator"
        if ["Set - String", "Multiple String Value"].include? db_field.field_type
          query_operator = "like"
          query_string = "%|#{query_string}|%"
        else
          ar_qstring = RuleFetchCondition.comparison_operator(db_field,
                                                 operator_1_C).active_record_query_string
          query_string = ar_qstring.gsub("H", query_string) if ar_qstring
        end
      else
        if ["Set - String", "Multiple String Value"].include? db_field.field_type
          query_operator = "like"
          query_string = "|#{query_string}|"
        else
      end
      ##### end of drug_classes_C specific code
      end
      opt_cond[query_field] = {query_operator => query_string}
    end
    opt.merge!(:conditions => opt_cond) unless opt_cond.empty?

    opt[:limit] = 1 # make sure always returns one record
    return opt
  end # executable_query

  # Returns a comparison operator
  #
  # Parameters:
  # * field - form field corresponding to the query source field
  # * operator_name_or_id - the id or display_value of an operator in
  # comparison_operators table
  ##
  def self.comparison_operator(field, operator_name_or_id)
    field.predefined_field.comparison_operators.find_by_id(operator_name_or_id) ||
      field.predefined_field.comparison_operators.find_by_display_value(operator_name_or_id)
  end

  ####################################################
  ##### fetch rule creation code without UI
  ##### TODO: should be removed when the UI is working
  ####################################################
  #
  # options example:
  # options ={
  #   :rule_name => "abc rule";
  #   :source_table_name => "Drugs",
  #   :count => true,
  #   :conditions =>[
  #     { :query_field => "Medical Condition",      # display_name in db_field_descriptions table
  #       :operator_name => "Contains",             # item_name in text_list_items table
  #       :query_string => "Atrial fibrillation" }] # find the matching code from the list
  # }
  ##
  def self.create_fetch_rule(options)
    raise "missing options for creating phr fetch rule" if options.empty?

    fetch_rule_form = Form.find_by_form_name("data_rule_form")
    source_table_name = options[:source_table_name]
    count = options[:count]
    r = nil

    ActiveRecord::Base.transaction do
      r = Rule.new(
        :name => options[:rule_name],
        :rule_type => Rule::FETCH_RULE,
        :forms => [fetch_rule_form]
      )
      r.save!

      source_table = DbTableDescription.find_by_description(source_table_name)
      raise "wrong source table name: '#{source_table_name}', check with DbTableDescription" unless source_table
      rf = RuleFetch.new(
        :rule => r,
        :source_table => source_table_name,
        :source_table_C => source_table.id,
        :count => count
      )
      rf.save!

      # conditions with non date query
      trigger_fields = []
      options[:conditions].each do |e|
        source_field_name = e[:query_field]
        operator_name     = e[:operator_name]
        query_string      = e[:query_string]
        source_field = source_table.db_field_descriptions.find_by_display_name(source_field_name)
        raise "wrong query field display name: '#{source_field_name}', check with DbFieldDescription" unless source_field

        tf = source_field.field_descriptions.first
        raise "can not find field description corresponding to the db_field_description: '#{source_field.display_name}'" unless tf

        operator_item = self.comparison_operator(tf, operator_name)
        raise "wrong operator name: '#{operator_name}' for field '#{tf.target_field}', check with TextListItem" unless operator_item

        # TODO: needs to add code to handle date field queries
        #trigger_field = tf
        trigger_field = source_field
        master_code = nil
        # if there is a list with text and code
        if source_field.list_code_column
          # this source field is a field of some type of classes, e.g. problem classes "|1|30|26|"
          if source_field.field_type == "Set - String"
            # find the code matched to the class term (which is the query string)
            text_attr, code_attr = source_field.fields_saved[0], source_field.list_code_column
            class_type = source_field.list_identifier
            text_list = TextList.find_by_list_name(class_type)
            rec = text_list.text_list_items.send("find_by_#{text_attr}", query_string)
            raise "can not find this class term '#{query_string}'" unless rec
            master_code = rec.send(code_attr)
            master_value = query_string
          else
            master_code, master_value = RuleFetchCondition.find_matching_field(tf, query_string, 1)
          end

          if master_value == query_string
            #            trigger_field = tf.form.field_descriptions.find_by_target_field(tf.target_field + "_C")
            trigger_field = source_table.db_field_descriptions.find_by_data_column(trigger_field.data_column + "_C")
            raise "can not find a code field '#{tf.target_field + "_C"}' corresponding to the field :'#{tf.target_field}'" unless trigger_field
          else
            # The input query string doesn't find any match from the list
            master_code = nil
            #raise "try to search from master table to find '#{query_string}', but found the wrong one '#{master_value}'"
          end
        end

        rfc = RuleFetchCondition.new(
          :rule_fetch_id => rf.id,
          :condition_type => "Q",
          :source_field => source_field_name,
          :source_field_C => source_field.id,
          :non_date_condition_value => query_string,
          :non_date_condition_value_C => master_code,
          :operator_1 => operator_item.display_value,
          :operator_1_C => operator_item.id
        )
        rfc.save!
        trigger_fields << trigger_field
      end
      r.db_field_descriptions = trigger_fields
    end
    r.save
    r
  end

  def self.fetch_rule_options(rule_name, source_table_name, count = false)
    { :rule_name => rule_name,
      :source_table_name => source_table_name,
      :count => count,
      :conditions => []
    }
  end

  def self.find_matching_field(fd, terms, limit)
    table_name = fd.getParam('search_table')
    if(table_name.blank?)
      nil
    elsif fd.getParam("prefetch") == "true" || fd.getParam("prefetch") == "1"
      # run prefetch
      self.prefetch_autocompleter_params(fd, terms)
    else
      # run master table
      self.get_matching_field_vals(fd, terms, limit)
    end
  end

  ### Used by self.find_matching_field only
  def self.public_tables
    @@public_tables ||= Set.new(['gopher_terms', 'rxnorm3_drugs', 'icd9_codes',
        'list_details', 'drug_name_routes', 'drug_strength_forms', 'allergy_types',
        'text_lists', 'vaccines', 'predefined_fields','answer_lists',
        'regex_validators','loinc_items', 'loinc_units', 'field_descriptions',
        'rxterms_ingredients', 'drug_classes', 'db_table_descriptions',
        'db_field_descriptions', 'forms'])
  end

  def self.get_matching_field_vals(fd, terms, limit)
    # Add a wildcard to the end of the last term.  However, Ferret won't use
    # the query analyzer in parsing terms that end in a wild card, so we need
    # to parse that last term away from the rest of the string by adding a
    # space before it.  For example, 'one/two' => 'one/ two*'
    new_terms = terms.sub(/([[:alnum:]\-\.]+)\z/, ' \1*')

    table_name = fd.getParam('search_table')

    if !(self.public_tables.member?(table_name) || table_name.index('user ') == 0)
      raise "Search of table #{table_name} not allowed."
    end

    tableClass = table_name.singularize.camelize.constantize

    list_name= fd.getParam('list_name')
    highlighting = fd.getParam('highlighting')
    if (highlighting.nil?)
      highlighting = false
    end

    search_cond = fd.getParam('conditions')
    if (!search_cond.nil?)
      # search_cond should contain a bit of FQL for restricting the search
      # results
      new_terms = '('+new_terms + ') AND ' + search_cond
    end

    search_options = {:limit=>limit}
    order = fd.getParam('order')
    search_options[:sort] = order if order

    # Return the result of find_storage_by_contents, plus the "highlighting"
    # variable.
    res = tableClass.find_storage_by_contents(list_name, new_terms,
      fd.fields_searched, fd.list_code_column.to_sym,
      fd.fields_returned, fd.fields_displayed,
      highlighting, search_options) << highlighting
    res ?  [res[1][0], res[3][0][0]] : nil # e.g. format is: [code, value]
  end # get_matching_field_vals


  def self.prefetch_autocompleter_params(fd, terms)
    raise "This is not a prefetch field" unless %w(true 1).include? fd.getParam("prefetch")
    some_field = fd
    # Get the data for the field:
    #
    # List fields can now contain lists of user data, which must be obtained
    # after the form is built (because the form is cached) via an AJAX call.
    # Such lists are indicated by the search_table parameter starting with
    # the string "user ".
    search_table = some_field.getParam('search_table')
    if search_table.nil?
      col_names = nil
    else
      is_user_data = search_table.index('user ') == 0

      # Prefetched list fields may be dynamically loaded during runtime.
      # Check to see if this is the case.
      is_dynamically_loaded = search_table == 'dynamically_loaded'

      list_data = nil
      if (!is_user_data)
        # Get the table name, convert it to its class name, & get the data
        if (!is_dynamically_loaded)
          table_class = search_table.singularize.camelize.constantize
        end

        # Get the column names to be returned for the list items.
        col_names = some_field.getParam('fields_displayed')

        # Get the list name, which is either in the list_id parameter
        # or the list_name parameter.  This applies only to tables
        # that are accessed via text_lists (list_name) or answer_lists
        # (list_id).  For tables that are accessed directly, list_name
        # and list_id need not be specified.  Exception to this
        # is the forms table, where the list name needs to indicate
        # form type ('form' or 'panel').
        # If list_name is not specified for a text_lists list, no
        # values will be prefetched.  (Assume that the values will
        # be loaded during run time by some other field).
        if (!is_dynamically_loaded)
          list_name = some_field.getParam('list_id')
          list_name = some_field.getParam('list_name') if list_name.nil?
          if table_class.respond_to?('get_list_items')
            list_data = table_class.get_list_items(
              list_name,
              nil,
              some_field.getParam('order'),
              some_field.getParam('conditions'))
          end
        end
      end
    end # if we have a search table

    found_rec = list_data.select{|e| e.send(col_names[0]) == terms }[0]
    found_rec ? [found_rec.code, found_rec.send(col_names[0])] : nil
  end # prefetch_autocompleter_params
  ####################################################
  ##### end of fetch rule creation code without UI
  ####################################################


end # RuleFetchCondition
