class RuleFetch < ActiveRecord::Base
  cache_associations
  belongs_to :rule
  belongs_to :db_table_description, :foreign_key => :source_table_C
  has_many :rule_fetch_conditions, :dependent=>:delete_all
  cache_recs_for_fields 'rule_id'
  serialize :executable_fetch_query_js, JSON
  serialize :executable_fetch_query_ar, JSON

  MAJOR_QUALIFIER = 'M'
  OTHER_QUALIFIER = 'O'
  DATA_SOURCE_NAMES = %w(taffy_db active_record)

  @@eq_op = nil
  @@is_op = nil

  def init_ops
    @@eq_op = ComparisonOperator.where(display_value: 'equal (=)').first
    @@is_op = ComparisonOperator.where(display_value: 'is').first
  end

  # Returns boolean indicating whether or not the current fetch rule
  # has any conditions
  #
  # Parameters: none
  # Returns: boolean
  #
  def has_conditions
    return !rule_fetch_conditions.nil? && rule_fetch_conditions.size > 0
  end


  # Returns all qualifier conditions for the current fetch rule
  #
  # Parameters: none
  # Returns: array of qualifier conditions
  #
  def major_qualifiers
    return rule_fetch_conditions.where(condition_type: MAJOR_QUALIFIER).load
  end


  # Returns all comparison conditions for the current fetch rule
  #
  # Parameters: none
  # Returns: array of comparison conditions
  #
  def other_qualifiers
    return rule_fetch_conditions.where(condition_type: OTHER_QUALIFIER).load
  end


  # This is a utility method that searches a hash for a key.  This is useful
  # for a hash, such as the hash used to return the fetch rule form data, that
  # has multiple levels in a combination of arrays and hashes.  Rather than
  # having to code to the specific level, this will go find the key in the
  # hash.
  #
  # I would like to turn this into a utility method that is accessible to all
  # the ruby code, but have not had any luck with it yet.  So here it is.
  #
  # Parameters:
  # * key_name - name of the key whose value is to be returned
  # * the_hash - the hash object to be searched
  # Returns:
  #  the value for the specified key, if found, or null if not found
  #
  def search_hash(key_name, the_hash)
    rtn = the_hash[key_name]
    if rtn.nil?
      the_hash.each_value do |val|
        if rtn.nil?
          if val.instance_of?(Array)
            val.each do |array_elem|
              if rtn.nil?
                rtn = search_hash(key_name, array_elem)
              end
            end
          elsif val.instance_of?(Hash)
            rtn = search_hash(key_name, val)
          end
        end
      end
    end
    return rtn
  end # search_hash

  # This takes care of adding or updating a fetch rule, including the
  # conditions, if any, specified for the rule.
  #
  # Parameters:
  # * rule - the Rule object to which this fetch rule is, or is to be, attached.
  # * form_data - data from the edit fetch rule form
  # * updating - boolean indicating whether we are updating or adding
  # Returns:
  #  the new or updated fetch rule
  #
  def self.add_update_fetch_rule(rule, form_data, updating)
    logger.debug 'form_data on entry to add_update_fetch_rule = ' +
                 form_data.to_json

    # ref_fields is used to accumulate the ids of field_description
    # objects referenced by the conditions of this rule
    ref_fields = Set.new

   if (updating)
      fetch = rule.rule_fetch
    else
      fetch = RuleFetch.new
    end
    # Get the fetch rule data that stored in the rule_fetch object
    # and either update the existing fetch rule or create a new one
    from_form = fetch.get_main_fetch_data(form_data)
    if (!updating)
      from_form[:rule_id] = rule.id
    end
    fetch.update_attributes!(from_form)

    # There are four types of condition data.  Get each type and
    # then pass it on to update_add_conditions to add or update
    # as appropriate.  Note that the user can add new conditions,
    # update existing conditions, and delete existing conditions
    # -- where a condition is considered deleted if there is no
    # source_field value for the condition.
    # -- nope - not currently.  just major attribute and other
    # attribute.  Haven't changed the field names yet.  2/24/10 lm.
    major_quals = fetch.get_major_qualifier_data(form_data)
    if (!major_quals.nil?)
      ref_fields = RuleFetchCondition.update_add_conditions(major_quals,
                                                            fetch.id,
                                                            ref_fields)
    end # if we have any non_date qualifiers

    non_date_quals = fetch.get_non_date_qualifiers_data(form_data)
    if (!non_date_quals.nil?)
      ref_fields = RuleFetchCondition.update_add_conditions(non_date_quals,
                                                            fetch.id,
                                                            ref_fields)
    end # if we have any non_date qualifiers

    # we've removed the date/non-date distinction (but not yet renamed all fields)
#    date_quals = fetch.get_date_qualifiers_data(form_data)
#    if (!date_quals.nil?)
#      ref_fields = RuleFetchCondition.update_add_conditions(date_quals,
#                                                            fetch.id,
#                                                            ref_fields)
#    end # if we have any date qualifiers

    # we've removed the comparison sections
#    non_date_comps = fetch.get_non_date_comps_data(form_data)
#    if (!non_date_comps.nil?)
#      ref_fields = RuleFetchCondition.update_add_conditions(non_date_comps,
#                                                            fetch.id,
#                                                            ref_fields)
#    end # if we have any non_date comparisons
#
#    date_comps = fetch.get_date_comps_data(form_data)
#    if !(date_comps.nil?)
#      ref_fields = RuleFetchCondition.update_add_conditions(date_comps,
#                                                            fetch.id,
#                                                            ref_fields)
#    end # if we have any date comparisons

    # Now update the field associations using the ref_fields array
    # updated by the update_add_conditions method.  Then we're done.
    rule.save! # this will make sure rule is valid after making changes
    #rule.update_associations(true, ref_fields)
    return fetch
  end # add_update_fetch_rule

  # This extracts the main fetch rule data from the form_data hash passed in.
  # This is the data that's actually stored to the rule_fetch table.
  #
  # Parameters:
  # * form_data - the hash of data returned from the form
  # Returns:
  #  a hash containing the rule_fetch table column names as keys and the
  #  corresponding data from the form_data hash (where form field names don't
  #  necessarily match column table names).
  #
  def get_main_fetch_data(form_data)

    return {:source_table => search_hash('source_table', form_data) ,
            :source_table_C => search_hash('source_table_C', form_data) }
#            :comparison_basis => search_hash('comparison_basis', form_data) ,
#            :comparison_basis_C => search_hash('comparison_basis_C', form_data)}
  end # get_main_fetch_data


  # This extracts the major qualifier data from the form_data hash passed in.
  # This is the data that's stored for the major qualifier conditions.
  # Right now only one major qualifier condition may be specified.
  #
  # Parameters:
  # * form_data - the hash of data returned from the form
  # Returns:
  #  an array containing one hash for each condition specified, where the
  #  rule_fetch_conditions table column names are the keys and the
  #  corresponding data values from the form_data hash (where form field names
  #  don't necessarily match column table names) are the values.
  #
  def get_major_qualifier_data(form_data)
    if @@eq_op.nil?
      init_ops
    end
    quals = []
    major_quals = search_hash('major_qualifier_group', form_data)
    if (!major_quals.nil?)
      major_quals.each do |mjq|
        if mjq['major_qualifier_value'] == 'First/oldest date' ||
           mjq['major_qualifier_value'] == 'Last/most recent date'
          this_op = mjq['major_qualifier_value']
          this_op_C = mjq['major_qualifier_value_C']
          this_val = nil
          this_val_C = nil
        else
          db_field = DbFieldDescription.find(mjq['major_qualifier_name_C'])
          if (db_field.field_type == 'Set - String')
            this_op = @@is_op.display_value
            this_op_C = @@is_op.id
          else
            this_op = @@eq_op.display_value
            this_op_C = @@eq_op.id
          end
          this_val = mjq['major_qualifier_value']
          this_val_C = mjq['major_qualifier_value_C']
        end
        quals << {:condition_id => mjq['major_qualifier_group_id'],
                  :condition_type => MAJOR_QUALIFIER ,
                  :source_field => mjq['major_qualifier_name'] ,
                  :source_field_C => mjq['major_qualifier_name_C'] ,
                  :operator_1 => this_op ,
                  :operator_1_C => this_op_C ,
                  :non_date_condition_value => this_val ,
                  :non_date_condition_value_C => this_val_C }
      end
    end
    return quals
  end # get_major_qualifier_data



  # This extracts the non-date qualifier data from the form_data hash passed in.
  # This is the data that's stored for a the non-date qualifier conditions,
  # where multiple conditions may be specified.
  #
  # Parameters:
  # * form_data - the hash of data returned from the form
  # Returns:
  #  an array containing one hash for each condition specified, where the
  #  rule_fetch_conditions table column names are the keys and the
  #  corresponding data values from the form_data hash (where form field names
  #  don't necessarily match column table names) are the values.
  #
  def get_non_date_qualifiers_data(form_data)
    if @@eq_op.nil?
      init_ops
    end
    quals = []
    non_date_quals = search_hash('non_date_fetch_qualifiers_group', form_data)
    if (!non_date_quals.nil?)
      non_date_quals.each do |ndq|
        if ndq['qualifier_value'] == 'First/oldest date' ||
           ndq['qualifier_value'] == 'Last/most recent date'
          this_op = ndq['qualifier_value']
          this_op_C = ndq['qualifier_value_C']
          this_val = nil
          this_val_C = nil
        else
          db_field = DbFieldDescription.find(ndq['non_date_qualifier_name_C'])
          if (db_field.field_type == 'Set - String')
            this_op = @@is_op.display_value
            this_op_C = @@is_op.id
          else
            this_op = @@eq_op.display_value
            this_op_C = @@eq_op.id
          end
          this_val = ndq['qualifier_value']
          this_val_C = ndq['qualifier_value_C']
        end
        quals << {:condition_id => ndq['non_date_fetch_qualifiers_group_id'],
                  :condition_type => OTHER_QUALIFIER ,
                  :source_field => ndq['non_date_qualifier_name'] ,
                  :source_field_C => ndq['non_date_qualifier_name_C'] ,
                  :operator_1 => this_op ,
                  :operator_1_C => this_op_C ,
                  :non_date_condition_value => this_val ,
                  :non_date_condition_value_C => this_val_C }
      end
    end
    return quals
  end # get_non_date_qualifiers_data


  # This extracts the date qualifier data from the form_data hash passed in.
  # This is the data that's stored for a the date qualifier conditions,
  # where multiple conditions may be specified.
  #
  # Parameters:
  # * form_data - the hash of data returned from the form
  # Returns:
  #  an array containing one hash for each condition specified, where the
  #  rule_fetch_conditions table column names are the keys and the
  #  corresponding data values from the form_data hash (where form field names
  #  don't necessarily match column table names) are the values.
  #
#  def get_date_qualifiers_data(form_data)
#    quals = []
#    date_quals = search_hash('date_fetch_qualifiers_group', form_data)
#    if (!date_quals.nil?)
#      date_quals.each do |dq|
#        quals << {:condition_id => dq['date_fetch_qualifiers_id'] ,
#                  :condition_type => 'Q' ,
#                  :source_field => dq['date_qualifier_name'] ,
#                  :source_field_C => dq['date_qualifier_name_C'] ,
#                  :operator_1 => dq['qualifier_recency'] ,
#                  :operator_1_C => dq['qualifier_recency_C'] ,
#                  :operator_2 => dq['qualifier_recency_qualifier'] ,
#                  :operator_2_C => dq['qualifier_recency_qualifier_C'] ,
#                  :condition_date => dq['qualifier_recency_date'] ,
#                  :condition_date_ET => dq['qualifier_recency_date_ET'] ,
#                  :condition_date_HL7 => dq['qualifier_recency_date_HL7']}
#      end
#    end
#    return quals
#  end # get_date_qualifiers_data


  # This extracts the non-date comparison data from the form_data hash passed
  # in.  This is the data that's stored for a the non-date qualifier conditions,
  # where multiple conditions may be specified.
  #
  # Parameters:
  # * form_data - the hash of data returned from the form
  # Returns:
  #  an array containing one hash for each condition specified, where the
  #  rule_fetch_conditions table column names are the keys and the
  #  corresponding data values from the form_data hash (where form field names
  #  don't necessarily match column table names) are the values.
  #
#  def get_non_date_comps_data(form_data)
#    comps = []
#    non_date_comps = search_hash('non_date_comp_qualifiers_group', form_data)
#    if (!non_date_comps.nil?)
#      non_date_comps.each do |ndc|
#        comps << {:condition_id => ndc['non_date_comp_qualifiers_id'],
#                  :condition_type => 'C' ,
#                  :source_field => ndc['non_date_comparison_data'] ,
#                  :source_field_C => ndc['non_date_comparison_data_C'] ,
#                  :operator_1 => ndc['comparison_operator'] ,
#                  :operator_1_C => ndc['comparison_operator_C'] ,
#                  :non_date_condition_value => ndc['comparison_value'],
#                  :non_date_condition_value_C => ndc['comparison_value_C']}
#      end
#    end
#    return comps
#  end # get_non_date_comps_data


  # This extracts the date comparison data from the form_data hash passed in.
  # This is the data that's stored for a the non-date qualifier conditions,
  # where multiple conditions may be specified.
  #
  # Parameters:
  # * form_data - the hash of data returned from the form
  # Returns:
  #  an array containing one hash for each condition specified, where the
  #  rule_fetch_conditions table column names are the keys and the
  #  corresponding data values from the form_data hash (where form field names
  #  don't necessarily match column table names) are the values.
  #
#  def get_date_comps_data(form_data)
#    comps = []
#    date_comps = search_hash('date_comp_qualifiers_group', form_data)
#    if !(date_comps.nil?)
#      date_comps.each do |dc|
#        comps << {:condition_id => dc['date_comp_qualifiers_id'] ,
#                  :condition_type => 'C' ,
#                  :source_field => dc['date_comparison_data'] ,
#                  :source_field_C => dc['date_comparison_data_C'] ,
#                  :operator_1 => dc['comparison_recency'] ,
#                  :operator_1_C => dc['comparison_recency_C'] ,
#                  :operator_2 => dc['comparison_recency_qualifier'] ,
#                  :operator_2_C => dc['comparison_recency_qualifier_C'] ,
#                  :condition_date => dc['comparison_recency_date'],
#                  :condition_date_ET => dc['comparison_recency_date_ET'],
#                  :condition_date_HL7 => dc['comparison_recency_date_HL7']}
#      end
#    end
#    return comps
#  end # get_date_comps_data


  # Performs validations on a fetch rule before it is saved or updated.
  #
  # Problems are documented via messages written to the errors object that
  # is automatically created for the class.
  validate :validate_instance
  def validate_instance
    if rule_id.nil?
      errors.add(:rule_id, 'must not be nil')
    else
      base_rule = Rule.find_by_id(rule_id)
      if base_rule.nil?
        errors.add(:rule_id, 'must be the id of an existing rule')
      end
    end
    check_required_column('source_table')
    check_required_column('source_table_C')
#    if (!comparison_basis.nil?)
#      check_required_column('comparison_basis_C')
#    end

  end #validate


  # Checks to see if this rule includes a comparison basis values.  This
  # is actually called by the validation code in the RuleFetchCondition
  # class, when the conditions are being validated.  It is only called
  # when validating comparison conditions.
  #
  # Parameters:  none
  # Returns:  a message if the comparison basis is blank, or nil if it's not
  #
#  def check_comparison_basis
#    msg = nil
#    if (comparison_basis.blank?)
#      msg = 'Comparison Basis must be specified with Comparison Criteria'
#    end
#    return msg
#  end

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


  # Runs fetch rules whose source table is obx_observations table and returns
  # the fetched record. Obx_observations table is the only table which has all
  # candidate columns required by fetch rules. Other tables like phr_drugs are
  # missing some query-able columns (e.g. drug_class column)
  #
  # Parameters:
  # * profile_id a profile ID
  def prefetch_obx_observations_at_serverside(profile_id)
    rtn = []
    if profile_id
      query = executable_fetch_query_ar
      query_table = query[0]
      if "obx_observations" == query_table
        ar_hash = {}
        query_table_class = query_table.classify.constantize
        query_hash = query[1].first

        cond_hash = query_hash['conditions']
        if cond_hash
          cond_head, cond_main = [], []
          cond_hash.each do |k, v|
            query_field = k
            query_op, query_str = v.to_a[0]

            query_value = query_str.blank? ? "is null" : "#{query_op} ?"
            if query_str.blank?
              query_op = query_op == "=" ? "is" : "is not"
              cond_head << "#{query_field} #{query_op} null"
            else
              cond_head << "#{query_field} #{query_op} ?"
              cond_main << query_str
            end
          end
          cond_head << "profile_id = ? "
          cond_main << profile_id
          cond_main.unshift(cond_head.join(" AND "))
          ar_hash[:conditions] = cond_main
        end

        order_hash = query_hash[:order]
        ar_hash[:order] = order_hash.to_a.map{|e| e.join(" ")}.join(",") if order_hash
        limit_value = query_hash[:limit]
        ar_hash[:limit] = limit_value if limit_value

        rtn = query_table_class.where(ar_hash[:conditions])
        rtn = rtn.order(ar_hash[:order]) if ar_hash[:order]
        rtn = rtn.limit(ar_hash[:limit]) if ar_hash[:limit]
      end
    end
    rtn[0]
  end # run_fetch_rule_at_serverside



end # RuleFetch
