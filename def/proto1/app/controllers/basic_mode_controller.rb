# This is a base class for the controllers that support the "basic mode"
# (where there is only minimal JS, CSS, and graphics).
class BasicModeController < ApplicationController
  
  # The form object name for fields constructed based on a field description.
  FD_FORM_OBJ_NAME = 'phr'

  # The standard notice for a successful save.
  CHANGES_SAVED = 'Your changes have been saved.'

  protected
  
  # Loads the user's PHR record based on the :phr_record_id parameter (or the
  # given id, if provided) into the variable @phr_record.  This method takes
  # care of redirecting the user if they do not have permission to access the
  # profile.  Calling code should check @phr_record.nil? to determine whether a
  # redirection has occurred.
  #
  # Parameters:
  # * profile_id - (optional) the ID of the profile to load.  If not specified,
  #   params[:phr_record_id] will be used.
  def load_phr_record(profile_id=nil)
    profile_id = params[:phr_record_id] if !profile_id
    @phr_record = nil
    begin
      @access_level, @phr_record = get_profile("load_phr_record, basic mode",
                                               ProfilesUser::READ_ONLY_ACCESS,
                                               profile_id)
      @profile = @phr_record
    rescue SecurityError=>e
      flash[:error] = e.to_s
      redirect_to phr_records_path
    end
  end


  # Updates the given record with the params.  We don't just use
  # update(params) because of the security issue with mass assigns.
  #
  # Parameters:
  # * rec - the record to be updated
  # * update_fields - a list of fields in rec that we allow to be updated.  These
  #   are the base field names; field+_C.
  # * db_to_form_field - a map from database field names to field names used
  #   on the form.  This is optional; if not provided it will be assumed that
  #   the the same names are used for both.
  def update_record_with_params(rec, update_fields, db_to_form_field=nil)
    form_params = params[FD_FORM_OBJ_NAME]
    # CWE lists have "alt" text fields for non-coded items.  Allow the user
    # to change either the alt field or the code field without changing the
    # other; if both change give the alt field priority (so the user doesn't
    # lose what they typed.)

    # We also allow mutiple lists to target the same field if each list field
    # name ends in _C1, _C2, etc.-- which is why code_vals contains sets.
    # Whatever changes, accept that value, even if the old value was not
    # cleared.  If everything is blank, the user is clearing the field.
    alt_vals = {}
    code_vals = {}
    form_params.each do |k, v|
      if k=~/\A(.+)_C\Z/
        code_vals[$1] = Set.new([v])
      elsif k =~ /\Aalt_(.+)\Z/
        alt_vals[$1] = v
      elsif k =~ /\A(.+)_C\d+\Z/
        vals_for_param = code_vals[$1] ||= Set.new
        vals_for_param << v
      end
    end

    update_fields.each do |db_f|
      f = db_to_form_field ? db_to_form_field[db_f] : db_f
      if code_vals.member?(f) || alt_vals.member?(f) # a prefetched list field
        code_field = rec.class.send('code_field', db_f)
        new_alt_val = alt_vals[f]
        if !rec.respond_to?(code_field)
          # Then this is a list that doesn't use codes.  (We currently have
          # just one such case-- "where done" in the test panels).
          rec.update_field_with_vals(db_f,
            form_params[f], new_alt_val)
        else
          codes_for_field = code_vals[f]
          cur_val = rec.send(db_f) || '' # for comparison with the form parameter
          cur_code_val = rec.send(code_field) || ''

          if codes_for_field
            codes_for_field.delete('') if codes_for_field.size > 1
            codes_for_field.delete(cur_code_val) if codes_for_field.size > 1
            # At this point there would normally just be one item in codes_for_field,
            # but there could be more than one if multiple lists were from the same
            # field and more than one list was used.
            new_code_val = codes_for_field.first
          end

          if (!new_alt_val.blank? || new_code_val.blank?) && new_alt_val != cur_val
            new_val = new_alt_val
            rec.send(code_field+'=', '') # clear the code for the non-coded item
            rec.send(db_f+'=', new_alt_val)
          elsif !(new_code_val.blank? && cur_code_val.blank?) # not both blank
            # new_code_val might be the empty string, and it might be nil.
            # The above "if" clause prevents our switching from one to the other,
            # thereby signaling a semantically empty change.
            rec.send(code_field+'=', new_code_val)
          end
        end
      else
        # This is just a regular field.  Don't assign empty strings if the
        # old value was nil.
        new_val = form_params[f]
        cur_val = rec.send(db_f)
        rec.send(db_f+'=', new_val) if new_val and (!cur_val.nil? || new_val!='')
      end
    end
  end


  # Handles the saving of a record in one of our user data tables.  This
  # includes updating the user's data storage count, which is why the method is
  # here rather that at the model level.
  #
  # Parameters:
  # * rec - the record to be saved.
  # Returns:
  # * the result of "save" on the record.
  def save_record(rec)

    if rec.new_record?
      rec.latest = 1
      # Set the record ID.  For some reason, one of our tables currently
      # does not have record_ids.  (The plan is for those to go away though--
      # see task 3041.)
      if rec.respond_to?('record_id')
        rec.record_id = rec.class.next_record_id(@phr_record.id)
      end

    # existing record needs to be moved into a hist_* table
    else
      # We need to save a duplicate containing the old attributes.
      # We could use clone, but when we move to Rails 3 that would break.
      # If the record hasn't changed, don't bother.
      if rec.changed?
        # get the hist table class
        table_name = rec.class.name.tableize
        hist_table_name = 'hist_' + table_name
        hist_table_class = hist_table_name.classify.constantize

        # prepare the date for hist table
        columns_values = rec.attributes
        # id value is in orig_id
        columns_values.merge!({'orig_id'=>columns_values.delete('id')})
        hist_rec = hist_table_class.new(columns_values)
        rec.changes.each {|field, vals| hist_rec[field] = vals[0]}
        hist_rec.latest = false
      else
        no_changes = true
      end
    end

    if !no_changes
      rec.version_date = Time.now
      rtn = rec.save
      if rtn
        @user.accumulate_data_length(rec.class.get_row_length(rec))
        hist_rec.save(:validate => false) if hist_rec # false = don't validate
      end
    end
    return no_changes || rtn
  end


  # Handles the deletion of a record from of the user data tables.  This
  # could be in a model base class, but save_record needs to be at the controller
  # level, so it made sense for this to be here as well.
  # The deleted records are moved into a hist_* table.
  #
  # Parameters:
  # * rec - the record to be deleted.
  def delete_record(rec)

    # get the hist table class
    table_name = rec.class.name.tableize
    hist_table_name = 'hist_' + table_name
    hist_table_class = hist_table_name.classify.constantize

    # prepare the date for hist table
    rec.latest = false
    rec.deleted_at = Time.now
    columns_values = rec.attributes
    columns_values.merge!({'orig_id'=>columns_values.delete('id')})

    # insert a copy of data in the hist table
    hist_table_class.new(columns_values).save(:validate => false)
    # delete the record in the normal user data table
    rec.delete

  end

end
