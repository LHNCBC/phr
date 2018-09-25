class AutosaveTmp < ActiveRecord::Base

  belongs_to :profiles

  TEST_PANEL_FORMS = ['panel_edit', 'panel_view']


  # This method determines if there is a change record in the autosave_tmps
  #  table for the user/profile/form name specified.
  # Parameters:
  # * profile_id - profile id
  # * form_name - form name - optional.  If not specified, this will check
  #   all autosave_tmps data for the given profile.
  # * named_form_only - flag indicating whether or not to check for the
  #   form name in the form_name parameter only.  This is currently used
  #   to prevent a form name in TEST_PANEL_FORMS from triggering a search
  #   for all form names in that array.
  #
  # Returns:
  # * if form_name is specified returns a boolean indicating whether or not
  #   there is change data for the specified form name - or for the test panel
  #   forms if the form_name was a test panel and named_form_only was not
  #   passed in as true; or
  #   if form_name is not specified returns an array that contains the
  #   names of the forms for which change data exists.  The array will be
  #   empty if there is no change data for the profile.
  #
  def self.have_change_data(profile,
                            form_name,
                            named_form_only = false)
    have_changes = false
    profile_id = profile.id

    if !form_name.nil?
      # assume that the user_id is found and that the profile_id and form_name
      # parameters are valid.  This is being called from other code that should
      # have already validated those, so I am letting it blow up here if they
      # are not valid.
      form_name = form_name.downcase
      if !named_form_only && TEST_PANEL_FORMS.include?(form_name)
        form_name = TEST_PANEL_FORMS.clone

        # Check to see if we have a base record with leftover data for the
        # flowsheet (panel_view form) - that is, a base record with a non-empty
        # data_table column and no change record.  This can happen when
        # a user asks to edit a panel but doesn't actually make any edits, and
        # then leaves the form via the X button or some other method.   If the
        # data in the base record is left there and there are unsaved changes
        # for the panel_edit form (Add Tests & Measures), it skews the display
        # of the recovered data.  So fix it here.
        pv_recs = AutosaveTmp.where(profile_id: profile_id,
                                    form_name: 'panel_view').to_a

        # if there's only one record for the form, it should be a base
        # record with an empty data table.  Make sure it is.  If it's a
        # change record with no base record, remove the record (invalid state).
        if !pv_recs.nil? && pv_recs.size == 1
          accumulate_len = 0
          br = pv_recs[0]
          if br.base_rec
            if !br.data_table.nil? &&
               !(ActiveSupport::JSON.decode(br.data_table).empty?)
              accumulate_len -= br.data_table.length
              br.data_table = Hash.new.to_json
              br.save!
            end
          else
            accumulate_len -= AutosaveTmp.get_row_length(br)
            br.destroy!
          end
          user_obj = profile.owner
          user_obj.accumulate_data_length(accumulate_len)
        end # if we have just one record/row
      end # if this is a test panel form
      change_rec = AutosaveTmp.where(profile_id: profile_id,
                                     form_name: form_name,
                                     base_rec: false).to_a

      # we have changes if we have a change record that has
      # data in the data table.  If we have more than one change record
      # there is a problem and we're returning false because we don't
      # want to use the current autosave data.  This should also cause
      # some kind of error notification, to be added when the error
      # checking is pulled out to be run separately.
      have_changes = !change_rec.nil? && change_rec.size == 1 &&
                      change_rec[0].data_table != '{}'

    # Else no form name was specified.  We're checking to see if there are
    # any pending changes at all
    else
      change_rec = AutosaveTmp.where(profile_id: profile_id,
                                     base_rec: false).to_a
      have_changes = []
      change_rec.each do |cr|
        if cr.data_table != '{}'
          have_changes << cr.form_name.downcase
        end
      end
    end # if a form name was/wasn't specified

    return have_changes

  end # have_change_data


  # This method checks to see if the base record is missing for a particular
  # profile_id/form_name combination
  # Parameters:
  # * profile_id - profile id
  # * form_name - form name
  #
  def self.missing_base(profile_id, form_name)

    form_name = form_name.downcase
    missings = AutosaveTmp.where("profile_id = ? AND form_name = ? " +
                                 "AND base_rec = true", profile_id, form_name);1
    return missings.size == 0
  end # missing_base


  # Resets the base record in the autosave_tmp table for the given
  # profile_id and the given form.  Resetting means updating the data_table
  # column with the data_tbl_str passed in and deleting any change row for
  # the profile/form.
  #
  # The current setting of access_level is checked to make sure the current user
  # has at least write access for the profile before any resetting is done.
  # Although it should be checked before this is called, we check again for
  # safety.
  #
  # NOTE that because this stores data to the database, the
  # check_for_data_overflow method in the application controller should be
  # called by whatever calls this on return from this method.
  #
  # Parameters:
  # * profile - the profile object
  # * form_name - name of form
  # * access_level - access level current user has to the profile
  # * data_tbl_str - the data "glob" that we store in the autosave_tmp table
  # * do_close - flag indicating whether or not we're closing the form.  If we
  #   are, this resets the data_table for the test panel data forms to empty
  #   on the base record, because that's the way the forms start out (no data).
  # * add_to_base - a flag indicating whether or not the data_tbl_str is to
  #   replace what's in the current base record (if any) or be added to it.
  #
  def self.set_autosave_base(profile,
                             form_name,
                             access_level,
                             data_tbl_str,
                             do_close,
                             add_to_base)

    if access_level >= ProfilesUser::READ_ONLY_ACCESS
      err_msg = "set_autosave_base was called for profile with id = " +
                profile.id + " but the current user only has " +
                ProfilesUser::ACCESS_TEXT[access_level] + " access for the " +
                "profile."
      logger.debug err_msg
      raise SecurityError, err_msg
    else
      form_name = form_name.downcase

      # if this request is for the flowsheet (form name = panel_view), see
      # if the data table being passed in contains the demographic data.  For
      # some reason that data is passed in the first time this is called, but
      # if we leave it here it messes up subsequent processing.  It's not
      # updated by this form, so we don't need it here.
      if form_name == 'panel_view'
        # Seems to be a Rails 3 bug
        # encode(nil) ==> 'null'; decode('null') ==> unexpected token 'null'
        data_tbl_hash = ActiveSupport::JSON.decode(data_tbl_str) if data_tbl_str !='null'
        data_tbl_str = nil
        if !data_tbl_hash.nil?
          if data_tbl_hash.include? 'phrs'
            data_tbl_hash.delete('phrs')
          end
          if !data_tbl_hash.empty?
            data_tbl_str = data_tbl_hash.to_json
          end
        end
      end
      if !data_tbl_str.nil?
        # get the current autosave_tmp rows for this profile and form
        form_name = form_name.downcase
        if do_close && TEST_PANEL_FORMS.include?(form_name)
          search_form_name = TEST_PANEL_FORMS.clone
        else
          search_form_name = form_name
        end
        existing = AutosaveTmp.where(profile_id: profile.id,
                                     form_name: search_form_name).
                               order('base_rec desc, updated_at').to_a

        # Because the data retrieved is sorted by the base_rec column,
        # the base record (base_rec = true) will be the first in the
        # array.  Change records (base_rec = false) will follow the base record.
        base_records = []
        accumulate_len = 0
        if existing.empty?
          base_row = AutosaveTmp.new
          base_row.profile_id = profile.id
          base_row.form_name = form_name
          base_row.base_rec = true
          base_row.data_table = String.new
          accumulate_len += AutosaveTmp.get_row_length(base_row)
          base_records << base_row
        else
          while !existing.empty? && existing[0]['base_rec']
            base_records << existing.delete_at(0)
          end
        end

        # If we're adding data to the base (from one of the test panel forms,
        # which adds base data as the user requests it), add the data table
        # string to the current base record.  In this case we can assume
        # that we only have one base record
        if add_to_base
          bef_len = base_records[0].data_table.length
          data_tbl_str = AutosaveTmp.add_base_data(data_tbl_str,
                                                   base_records[0].data_table)
          accumulate_len += data_tbl_str.length - bef_len

        # If we're NOT adding data to the base, set the data table string to
        # null if this is for a test panel form.  Both of those start out
        # empty.
        elsif TEST_PANEL_FORMS.include?(form_name)
          accumulate_len =- data_tbl_str.length
          data_tbl_str = Hash.new.to_json
        end

        base_records.each do |br|
          if br.form_name == form_name
            accumulate_len += data_tbl_str.length - br.data_table.length
            br.data_table = data_tbl_str
            br.save!
          end
        end

        # Now clear out the change rows IF this wasn't an add_to_base request.
        # This will remove any existing "merged" row as well as all changes.
        if !add_to_base && !existing.empty?
          existing.each do |old_row|
            accumulate_len -= AutosaveTmp.get_row_length(old_row)
            old_row.destroy
          end
        end
        profile.owner.accumulate_data_length(accumulate_len)
      end # if the data table string is not nil
    end # if the current user has at least write access to the profile
  end # set_autosave_base


  # Adds data to the supplied data table from a base record. This does no
  # checking for duplicate data between what's already in the base record's
  # data table and what's being added.
  #
  # This was created because the panel_edit form builds up its base data
  # as the user adds panels to create.  This does not have to be limited
  # to that use case.  That's just what brought it up.
  #
  # It is assumed that whatever calls this takes care of calling accumulate_
  # data_length on @user for this data.
  #
  # Parameters:
  # * data_tbl_str - the data "glob" that we store in the autosave_tmp table
  # * base_data - data table to receive the additional data
  # Returns:
  # * the string representing the merged data
  #
  def self.add_base_data(data_tbl_str, base_data)
    if data_tbl_str.class == Hash
      data_tbl_object = data_tbl_str
    else
      raw = ActiveSupport::JSON.decode(data_tbl_str)
      if raw.class == String
        data_tbl_object = JSON.parse(raw)
      else
        data_tbl_object = raw
      end
    end
    if base_data.class == Hash
      base_data_object = base_data
    elsif !base_data.nil? && !base_data.empty?
      raw = ActiveSupport::JSON.decode(base_data)
      if raw.class == String
        base_data_object = JSON.parse(raw)
      else
        base_data_object = raw
      end
    end
    if base_data_object.nil? || base_data_object.empty?
      base_data_object = data_tbl_object
    else
      data_tbl_object.each do |table_name, recs_array|
        if base_data_object[table_name].nil?
          base_data_object[table_name] = recs_array
        else
          base_data_object[table_name].concat(recs_array)
        end
      end
    end
    return base_data_object.to_json
  end # add_base_data


  # This method stores change data in the autosave table.  If there is
  # an existing change record, the data table is simply replaced with
  # the one passed in.  If there is no existing change record one is created.
  #
  # The current setting of access_level is checked to make sure the current user
  # has at least write access for the profile before any resetting is done.
  # Although it should be checked before this is called, we check again for
  # safety.
  #
  # NOTE that because this stores data to the database, the
  # check_for_data_overflow method in the application controller should be
  # called by whatever calls this on return from this method.
  #
  # Parameters
  # * profile - the profile object
  # * form_name - form name
  # * access_level - access level of the current user for the profile
  # * data_tbl_str - changed data table in string form
  #
  def self.save_change_rec(profile,
                           form_name,
                           access_level,
                           data_tbl_str)

    if access_level >= ProfilesUser::READ_ONLY_ACCESS
      err_msg = "The autosave save_change_rec method was called for profile " +
                "with id = " + profile.id + " but the current user only has " +
                ProfilesUser::ACCESS_TEXT[access_level] +
                " access for the profile."
      logger.debug err_msg
      raise SecurityError, err_msg
    else
      form_name = form_name.downcase
      # Make sure we have a base record for this profile/form.  If we don't
      # we have a problem.   The base record should be returned first
      existing = AutosaveTmp.where(profile_id: profile.id,
                                   form_name: form_name).
                             order("base_rec desc").to_a

      if (existing.size == 0 || !existing[0].base_rec)
        err_msg = 'Autosave change specified but no base record was found.\n' +
                  'profile_id = ' + profile.id.to_s + '; form_name = ' +
                  form_name.to_s + '\n' +
                  'Autosave WILL NOT WORK for this profile until this is fixed.'
        logger.debug err_msg
        raise err_msg
      end
      logger.debug 'existing rows found'
      # check to see if we have a change record.  If not, create one.
      if existing[1].nil?
        existing[1]= AutosaveTmp.new
        existing[1].profile_id = profile.id
        existing[1].form_name = form_name
        existing[1].base_rec = false
        bef_len = 0
      elsif existing[1].base_rec
        err_msg = 'Autosave change specified but multiple base records ' +
                  '(' + existing.length.to_s + ') were found.\n' +
                  'profile_id = ' + profile.id.to_s + '; form_name = ' +
                  form_name.to_s + '\n' +
                  'Autosave WILL NOT WORK for this profile until this is fixed.'
        logger.debug err_msg
        raise err_msg
      else
        bef_len = AutosaveTmp.get_row_length(existing[1])
      end
      existing[1].data_table =
                             AutosaveTmp.convert_from_browser_json(data_tbl_str)
      existing[1].save!
      profile.owner.accumulate_data_length(
                              AutosaveTmp.get_row_length(existing[1]) - bef_len)
    end # if the current user has at least write access to the profile
  end # save_change_rec


  # This method merges a change record into the base record for a
  # profile/form and returns the merged data.  If something goes wrong
  # during the process, the change record is discarded, to avoid repeatedly
  # telling the user that something went wrong, etc.
  #
  # NOTE that although there may be a change to the owner user's data size
  # count, the change will only be a decrement.  No overflow checking is
  # needed in this case.
  #
  # Parameters
  # * profile_id - profile id
  # * form_name - the name of the form
  # Returns:
  # * base_hash - the base data hash with the change data merged into it
  # * recovered_data - an array that contains two hash objects:
  #   1) added_rows - a hash that contains one entry for each table with
  #   added rows.  The entry consists of an array of row numbers for the rows
  #   that were added.
  #   2) recovered_fields - a hash that contains one entry for each table with
  #   added rows.  The entry is a hash that contains one entry for every row
  #   that was changed or added, and the entry for that is an array of the
  #   names of the fields that were changed.
  #
  def self.merge_changes(profile, form_name)

    form_name = form_name.downcase
    begin
      #  Get all autosave records for this profile/form
      form_recs = AutosaveTmp.where(profile_id: profile.id,
                                    form_name: form_name).
                              order("base_rec desc, updated_at").to_a
      if form_recs.nil? || form_recs.empty?
        err_msg = 'No autosave records found for profile_id ' +
                  profile.id.to_s  + '; form_name = ' +
                  form_name + '\nThis occurred in a call to ' +
                  'AutosaveTmp.merge_changes.\n' +
                  'Something has gone wrong; this should not have been called.'
        logger.debug err_msg
        raise err_msg
      else
        # get the base record
        base_record = form_recs.delete_at(0)
        if !base_record.base_rec
          base_record = nil
        end
        if base_record.nil?
          err_msg = 'No base record found for profile_id ' + profile.id.to_s +
                    '; form_name = ' + form_name + '\nThis occurred in a ' +
                    'call to AutosaveTmp.merge_changes.\nAutosave WILL NOT ' +
                    'WORK for this profile until this is fixed.'
          logger.debug err_msg
          raise err_msg
        elsif form_recs.nil? || form_recs.length == 0
          err_msg = 'No autosave changes found for profile_id ' +
                    profile.id.to_s  + '; form_name = ' + form_name +
                    '\nThis occurred in a call to ' +
                    'AutosaveTmp.merge_changes.\nSomething has gone wrong; ' +
                    'this should not have been called.'
          logger.debug err_msg
          raise err_msg
        end # if we're missing the base or change record
      end # if we found any autosave records

      # if we got this far without being bumped, call merge_change_hash
      ret = AutosaveTmp.merge_change_hash(base_record.data_table,
                                          form_recs[0].data_table)

    # If something went wrong, dump the change data.  The message the user
    # gets tells them that we've abandoned it, so go ahead and do just that.
    rescue Exception => e
      AutosaveTmp.clear_change_recs(profile, form_name)
      raise e
    end # begin/rescue
    return ret
  end # merge_changes


  # This method retrieves change records from the autosave_tmps table for
  # one or both of the test panel forms and merges them with the base records.
  # If something goes wrong during the process, the change records for both
  # forms are discarded, to avoid repeatedly telling the user that something
  # went wrong, etc.
  #
  # NOTE that because this MIGHT store data to the database (if we are missing
  # a base record for any of the test panels), the check_for_data_overflow
  # method in the application controller should be called by whatever calls
  # this on return from this method.
  #
  # Parameters
  # * profile - the profile object
  #
  # Returns
  # * data table hash with the merged data
  # * recovered fields array
  #
  def self.merge_tp_changes(profile)
    begin
      # We are assuming that this version of the merge changes method
      # is ONLY called for test panel forms.
      forms_recs = AutosaveTmp.where(profile_id: profile.id,
                                     form_name: TEST_PANEL_FORMS).
                               order("base_rec desc, " +
                                     "form_name desc, updated_at").to_a
      if forms_recs.nil? || forms_recs.empty?
        err_msg = 'No autosave records found for profile_id ' + profile.id.to_s +
                  '; form_name in ' + TEST_PANEL_FORMS.to_json +
                  '\nThis occurred in a call to AutosaveTmp.merge_tp_changes.\n' +
                  'Something has gone wrong; this should not have been called.'
        logger.debug err_msg
        raise err_msg
      else
        # find the base record(s)
        base_records = []
        while !forms_recs.empty? && forms_recs[0].base_rec
          base_records << forms_recs.delete_at(0)
        end
        # handle a case of no base records
        if base_records.length == 0
          err_msg = 'No base record found for profile_id ' + profile.id.to_s  +
                    '; form_name in ' + TEST_PANEL_FORMS.to_json +
                    '\nThis occurred in a call to ' +
                    'AutosaveTmp.merge_tp_changes.\nAutosave WILL NOT WORK ' +
                    'for this profile until this is fixed.'
          logger.debug err_msg
          raise err_msg
        # and a case of too many base records
        elsif base_records.length > TEST_PANEL_FORMS.length
          err_msg = 'TOO MANY (' + base_records.length.to_s + ') base ' +
                    'records were found for profile_id ' + profile.id.to_s  +
                    '; form_name in '  + TEST_PANEL_FORMS.to_json +
                    '\nThis occurred in a call to AutosaveTmp.merge_tp_changes.\n' +
                    'Autosave WILL NOT WORK for this profile until this is fixed.'
        # and a case of no change record
        elsif forms_recs.length == 0
          err_msg = 'No autosave change record was found for profile_id ' +
                    profile.id.to_s  + '; form_name in ' +
                    TEST_PANEL_FORMS.to_json + '\nThis occurred in a call to ' +
                    'AutosaveTmp.merge_tp_changes.\n' +
                    'Something has gone wrong; this should not have been called.'
          logger.debug err_msg
          raise err_msg

        # and a case of too many change records - there should only be one
        elsif forms_recs.length > 1
          err_msg = 'TOO MANY (' + forms_recs.length.to_s + ') change records '
                    'were found for profile_id ' + profile.id.to_s  +
                    '; form_name in ' + TEST_PANEL_FORMS.to_json +
                    '\nThis occurred in a call to AutosaveTmp.merge_tp_changes.\n' +
                    'Something has gone wrong; this should not have been called.'
          logger.debug err_msg
          raise err_msg
        # else process what we have
        else

          # Check to see if we're missing one of the base records we should
          # have.  In theory this shouldn't happen.  Theory is nice; checking
          # is better.  If we are missing one, insert an empty.
          if base_records.length < TEST_PANEL_FORMS.length
            need_base = TEST_PANEL_FORMS.clone
            base_records.each do |br|
              need_base.delete(br.form_name.downcase)
            end
            need_base.each do |nb|
              newb = AutosaveTmp.create!(:profile_id => profile.id ,
                                         :form_name => nb ,
                                         :data_table => Hash.new.to_json ,
                                         :base_rec => true)
              profile.owner.accumulate_data_length(AutosaveTmp.get_row_length(newb))
              base_records << newb
            end
          end # if we're missing a base record

          # Merge the base records,
          base_data_str = AutosaveTmp.merge_base_tp_records(base_records)

          # Now check to see if we got an empty string back.  If we did, it
          # means both base records were empty BUT there is a change record
          # for one of the test panels.  Throw an error.  It's happened.  I
          # don't know how, but it has.
          if (base_data_str == "{}")
            err_msg = 'An autosave change record was found for profile_id ' +
                      profile.id.to_s  + '; form_name in ' +
                      TEST_PANEL_FORMS.to_json + '\nBUT base records for the ' +
                      'forms were all empty.\nThis occurred in a call to ' +
                      'AutosaveTmp.merge_tp_changes.\nSomething has gone wrong.'
            logger.debug err_msg
            raise err_msg
          end
        end # if we have a valid number of base and change rows
      end # if we found the base record

      # if we got this far without being bumped, call merge_change_hash
      ret = AutosaveTmp.merge_change_hash(base_data_str,
                                          forms_recs[0].data_table)

    # If something went wrong, dump the change data.  The message the user
    # gets tells them that we've abandoned it, so go ahead and do just that.
    rescue Exception => e
      AutosaveTmp.clear_change_recs(profile, TEST_PANEL_FORMS)
      raise e
    end # begin/rescue
    return ret
  end # merge_tp_changes


  # This method rolls back, as far as the autosave_tmps table is concerned,
  # the user's current changes.  This is called when the user chooses to
  # cancel changes on the page.
  #
  # Rolling back the changes is accomplished by deleting the change record
  # for the current user/profile/form, leaving just the base record that
  # was there when the form was loaded.  For test panel forms the data table
  # in the base record is cleared.
  #
  # The current setting of access_level is checked to make sure the current user
  # has at least write access for the profile before any resetting is done.
  # Although it should be checked before this is called, we check again for
  # safety.
  #
  # NOTE that although this affects the amount of data stored in the database
  # for the current user, this method only REMOVES data.  So there is NO NEED
  # to call the check_for_data_overflow method in the application controller
  # from whatever calls this on return from this method.
  #
  # Parameters
  # * profile - the profile object
  # * form_name - form name
  # * access_level - the level of access the current user has for the profile
  # * showing_unsaved - used to include all test panels if one is specified
  #   and unsaved changes were being displayed
  # * closing_window - used to determine whether or not to clear out the
  #   data tables on test panel forms - yes if we're closing the form.
  #
  def self.rollback_autosave_changes(profile,
                                     form_name,
                                     access_level,
                                     showing_unsaved,
                                     closing_window)

    if access_level >= ProfilesUser::READ_ONLY_ACCESS
      err_msg = "rollback_autosave_changes was called for profile with id = " +
                profile.id + " but the current user only has " +
                ProfilesUser::ACCESS_TEXT[access_level] +
                " access for the profile."
      logger.debug err_msg
      raise SecurityError, err_msg
    else
      form_name = form_name.downcase
      if TEST_PANEL_FORMS.include?(form_name) && showing_unsaved
        search_form_name = TEST_PANEL_FORMS.clone
      else
        search_form_name = form_name
      end
      autosave_recs = AutosaveTmp.where(profile_id: profile.id,
                                        form_name: search_form_name).
                                    order('base_rec desc').to_a

      accumulate_len = 0
      while !autosave_recs.empty? && autosave_recs[0].base_rec
        base_rec = autosave_recs.delete_at(0)
        if closing_window && TEST_PANEL_FORMS.include?(form_name)
          accumulate_len -= base_rec.data_table.length
          base_rec.data_table = Hash.new.to_json
          base_rec.save!
        end
      end
      autosave_recs.each do |rec|
        accumulate_len -= AutosaveTmp.get_row_length(rec)
        rec.destroy
      end # do for each change record, if any
      profile.owner.accumulate_data_length(accumulate_len)
    end # if the user has write access to the profile
  end # rollback_autosave_changes


  # This method gets the data hashes for the base record and change record for
  # the specified form and profile.
  #
  # Parameters
  # * profile_id - profile id
  # * form_name - form name
  # * get_changes - flag to indicate whether or not the change has is to
  #   be included in te returned data.
  def self.get_autosave_data_tables(profile,
                                    form_name,
                                    get_changes)

    form_name = form_name.downcase
    if TEST_PANEL_FORMS.include?(form_name)
      search_form_name = TEST_PANEL_FORMS.clone
      test_form = true
      form_name_string = ' in ' + search_form_name.to_json
    else
      search_form_name = form_name
      test_form = false
      form_name_string = ' = ' + search_form_name
    end
    forms_recs = AutosaveTmp.where(profile_id: profile.id,
                                   form_name: search_form_name).
                               order('base_rec desc').to_a

    if forms_recs.empty?
      err_msg = 'No autosave records found for profile_id ' + profile.id.to_s  +
                '; form_name ' + form_name_string +
                '.\nThis occurred in a call to ' +
                'AutosaveTmp.get_autosave_data_tables.\n' +
                'Something has gone wrong; this should not have been called.'
      logger.debug err_msg
      raise err_msg
    else
      base_records = []
      while !forms_recs.empty? && forms_recs[0].base_rec
        base_records << forms_recs.delete_at(0)
      end
      # handle a case of no base records
      if base_records.length == 0
        err_msg = 'No base record found for profile_id ' + profile.id.to_s  +
                  '; form_name ' + form_name_string +
                  '.\nThis occurred in a call to ' +
                  'AutosaveTmp.get_autosave_data_tables.\n' +
                  'Autosave WILL NOT WORK for this profile until this is fixed.'
        logger.debug err_msg
        raise err_msg
      # and a case of too many base records
      elsif (test_form && base_records.length > TEST_PANEL_FORMS.length) ||
            (!test_form && base_records.length > 1)
        err_msg = 'TOO MANY (' + base_records.length.to_s + ') base ' +
                  'records were found for profile_id ' + profile.id.to_s  +
                  '; form_name ' + form_name_string +
                  '.\nThis occurred in a call to ' +
                  'AutosaveTmp.get_autosave_data_tables.\n' +
                  'Autosave WILL NOT WORK for this profile until this is fixed.'
      # and a case of no change record - this is not actually an error.
      # at startup, if there are no unsaved changes, there shouldn't be
      # a change record.

      # and a case of too many change records - there should only be one
      elsif forms_recs.length > 1
        err_msg = 'TOO MANY (' + forms_recs.length.to_s + ') change records '
                  'were found for profile_id ' + profile.id.to_s  +
                  '; form_name ' + form_name_string +
                  '.\nThis occurred in a call to ' +
                  'AutosaveTmp.get_autosave_data_tables.\n' +
                  'Something has gone wrong; this should not have been called.'
        logger.debug err_msg
        raise err_msg
      # else process what we have
      else
        # Check to see if we're missing one of the base records we should
        # have.  In theory this shouldn't happen.  Theory is nice; checking
        # is better.  If we are missing one, insert an empty.
        if (test_form && base_records.length < TEST_PANEL_FORMS.length)
          need_base = TEST_PANEL_FORMS.clone
          base_records.each do |br|
            need_base.delete(br.form_name.downcase)
          end
          need_base.each do |nb|
            newb = AutosaveTmp.create!(:profile_id => profile.id ,
                                       :form_name => nb ,
                                       :data_table => Hash.new.to_json ,
                                       :base_rec => true)
            profile.owner.accumulate_data_length(AutosaveTmp.get_row_length(newb))
            base_records << newb
          end
        end # if we're missing a base record

        # If this is for a test panel form, merge the base records
        if test_form
          base_data_str = AutosaveTmp.merge_base_tp_records(base_records)

          # Now check to see if we got an empty string back.  If we did, it
          # means both base records were empty BUT there is a change record
          # for one of the test panels.  Throw an error.  It's happened.  I
          # don't know how, but it has.
          if (base_data_str == "{}")
            err_msg = 'An autosave change record was found for profile_id ' +
                      profile.id.to_s  + '; form_name ' + form_name_string +
                      '.\nBUT base records for the forms were all empty.\n' +
                      'This occurred in a call to ' +
                      'AutosaveTmp.merge_tp_changes.\nSomething has gone wrong.'
            logger.debug err_msg
            raise err_msg
          end
          base_records[0].data_table  = base_data_str
        end # if we have a valid number of base and change rows
      end # if we found the base record
    end # if we found the user id

    # Set the change record return buffer based on whether or not we're
    # returning one.
    if get_changes && !forms_recs.empty? && !forms_recs[0].nil?
      change_rec = JSON.parse(forms_recs[0].data_table)
    else
      change_rec = nil
    end
    return [base_records[0].data_table, change_rec]
  end # get_autosave_data_tables


  # Converts a string received from the browser in json format that includes
  # quotes, escape characters, and extra spaces, to a json string without those.
  # If the input string is nil or blank, the same thing is returned.
  # Parameters:
  # * the_string the string to be converted
  # Returns:  the converted string
  #
  def self.convert_from_browser_json(the_string)

   if the_string.nil? || the_string.strip().size == 0
     converted_json = the_string
   else
      # use decode here to get quotes and escape characters out of the string:
      # "[{\"obx_observations\": {\"record_id\": 13 ... becomes
      # [{"obx_observations": {"record_id": 13 ...
      raw = ActiveSupport::JSON.decode(the_string)

      # but we also want to close up the extra spaces. to_json on an object
      # will do that, so we turn the string into an array with hash elements,
      # and then use to_json on it to turn it BACK into a string without all
      # the spaces.  i.e. [{"obx_observations":{"record_id":13 ...
      if raw.class == String
        the_object = JSON.parse(raw)
        converted_json = the_object.to_json
      else
        converted_json = raw.to_json
      end
    end
    return converted_json
  end


  # This merges the change data into the base data.  Each set of data is stored
  # in the autosave_tmps table as a string that represents a hash.  The base
  # data hash contains entries for all user data displayed on the form when
  # the form was loaded.  The change data hash contains entries only for fields
  # that were changed and rows that were added or deleted.  The format of each
  # mirrors the data_table_ in the Def.DataModel created when a form is loaded:
  #
  #  {table_name:[{table_column_name : value,
  #                table_column_name : value,
  #                ...},
  #               {table_column_name : value,
  #                table_column_name : value,
  #                ...}],
  #   table_name:[{table_column_name : value,
  #                table_column_name : value,
  #                ...},
  #               {table_column_name : value,
  #                table_column_name : value,
  #                ...}],
  #   ...}
  #
  # Each table-level array contains one entry for every data row in the table
  # in the base data.  Each data row entry in the base data MUST contain an
  # entry for every field in the row, or this will blow up.
  #
  # The change data is a sparse hash and only contains data for changes,
  # additions and deletions.
  #
  # Parameters:
  # * base_data - the base record for this profile in the autosave_tmps table
  # * change_data - the corresponding change data record
  #
  # Returns:
  # * base_hash - the base data hash with the change data merged into it
  # * recovered_data - an array that contains two hash objects:
  #   1) added_rows - a hash that contains one entry for each table with
  #   added rows.  The entry consists of an array of row numbers for the rows
  #   that were added.
  #   2) recovered_fields - a hash that contains one entry for each table with
  #   added rows.  The entry is a hash that contains one entry for every row
  #   that was changed or added, and the entry for that is an array of the
  #   names of the fields that were changed.
  # * is_test_data - optional flag that indicates whether or not we're merging
  #   data for test panel forms.  Default is false.  Used to determine whether
  #   or not blank rows at the end of tables should be preserved.
  #
  def self.merge_change_hash(base_data, change_data)

    base_hash = JSON.parse(base_data)
    change_hash = JSON.parse(change_data)

    recovered_data = []
    recovered_fields = {}
    added_rows = {}

    # Process the change_hash against the base_hash
    # ASSUMPTION:  All rows in the base_hash include all fields for the
    #              row.  This will not be true for the change hash
    #              (unless all fields were changed), but must be true for
    #              the base_hash.
    change_hash.each do |table_name, rows_hash|

      is_test_data = ['obr_orders', 'obx_observations'].include?(table_name)
      rows_hash = rows_hash.sort_by{|e| e[0]}
      last_row_idx = base_hash[table_name].length - 1
      removed_ct = 0
      rows_hash.each do |char_row_num, one_row_hash|
        row_num = char_row_num.to_i

        # bypass removed rows
        if (!one_row_hash['record_id'].nil? &&
            one_row_hash['record_id'] == 'Removed')
          removed_ct += 1
        else
          row_idx = row_num - 1 - removed_ct
          if removed_ct > 0
            row_num = row_idx + 1
            # char_row_num = row_num.to_s
          end
          row_changed = false
          one_row_hash.each do |field_name, value|
            # Process a change for an existing (in the base_hash) row
            # by writing the field from the change hash to the base
            # hash.  This will take care of updated, deleted, and
            # undeleted records (by the way the change hash is built).
            #
            # Note that test panel forms do NOT have an extra row at the
            # end of tables, and when a test panel is added, it's added to
            # the base record in the database and on the client Def.AutoSave
            # original data hash.  So we don't have added rows for that data.
            field_changed = false
            cur_row = base_hash[table_name][row_idx]
            if !cur_row.nil? && (is_test_data || last_row_idx > row_idx)
              if cur_row[field_name] != value
                cur_row[field_name] = value
                row_changed = true
                field_changed = true
              end
            # Process a row that was added during the update session
            else
              # move the empty row at the end of the group to the new
              # end, and insert the new row where it wants to be.
              row_changed = true
              field_changed = true
              base_hash[table_name][row_idx + 1] =
                                       Hash[base_hash[table_name][last_row_idx]]

              last_row_idx = row_idx + 1
              #base_hash[table_name][row_idx] = {}
              base_hash[table_name][row_idx][field_name] = value
              added_rows[table_name] = [] if added_rows[table_name].nil?
              #last_row_idx += 1
              added_rows[table_name] << row_num
            end

            # add the field to the recovered_fields hash
            if field_changed
              if recovered_fields[table_name].nil?
                recovered_fields[table_name] = {}
              end
              if recovered_fields[table_name][row_num].nil?
                recovered_fields[table_name][row_num] = []
              end
              recovered_fields[table_name][row_num] << field_name
            end
          end # do for each field in the row hash
          # if the row ended up with no changes, delete it from the recovered
          # fields array.  Same with the table.
          if !row_changed && !recovered_fields.nil?
            rec_table = recovered_fields[table_name]
            if !rec_table.nil?
              if rec_table[row_num].empty?
                rec_table.delete(row_num)
              end
              if rec_table.empty?
                recovered_fields.delete(table_name)
              end
            end # end if we recorded anything for this table
          end # if there were no real changes for this row
        end # if this is not a removed row
      end # do for each row hash in the change hash
    end # do for each table in the change hash

    # send back the added rows and recovered fields
    if added_rows.empty? && recovered_fields.empty?
      recovered_data = nil
    else
      recovered_data << added_rows
      recovered_data << recovered_fields
    end
    return base_hash, recovered_data
  end  # merge_change_hash


  # Merges multiple base records for test panel forms
  # Parameters:
  # * base_records an array containing the records to be merged
  # Returns:
  # * base_data_sring a string representing the data table containing the
  #   merged data tables of each record in the base_records array
  #
  def self.merge_base_tp_records(base_records)

    base_data_string = base_records[0].data_table
    base_records.delete_at(0)
    base_data = ActiveSupport::JSON.decode(base_data_string)

    base_records.each do |next_base|
      next_dt = ActiveSupport::JSON.decode(next_base.data_table)
      if !next_dt.empty?
        next_dt['obr_orders'].each do |row_hash|
          if base_data['obr_orders'].nil?
            base_data['obr_orders'] = []
          end
          base_data['obr_orders'] << row_hash
        end
        next_dt['obx_observations'].each do |row_hash|
          if base_data['obx_observations'].nil?
            base_data['obx_observations'] = []
          end
          base_data['obx_observations'] << row_hash
        end
      end # if the next base record is not empty
    end # do for each subsequent base record

    return base_data.to_json
  end # merge_base_tp_records


 # This method deletes the change records for the specified profile/form(s)
 # and deducts the freed up space from the owner user's data size count.
 # This was created for the merge_changes and merge_tp_changes methods, to
 # get rid of pending changes that somehow cause an exception to be thrown.
 # In those cases we let the user know that something went wrong with the
 # recovery of their unsaved changes, and that those changes are lost.  So
 # here's where we lose them.
 #
 # Parameters:
 # * profile - the profile object
 # * form_name - the name of the form (or forms in the case of test panel
 #   forms) whose change data we're dumping.
 #
 # Returns: nothing
 #
 def self.clear_change_recs(profile, form_name)

   change_recs = AutosaveTmp.where(profile_id: profile.id,
                                   form_name: form_name,
                                   base_rec: false).to_a
   accumulate_len = 0
   change_recs.each do |chg|
     accumulate_len -= AutosaveTmp.get_row_length(chg)
     chg.destroy
   end
   profile.owner.accumulate_data_length(accumulate_len)

 end # clear_change_recs

end # autosave_tmp

