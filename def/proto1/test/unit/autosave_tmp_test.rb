require 'test_helper'



class AutosaveTmpTest < ActiveSupport::TestCase
  fixtures :autosave_tmps
  fixtures :users
  # use PHR_Test (id = 5), phr_admin (id = 6) temporary_account (id=7)
  fixtures :profiles
  # use phr_test_phr1 (id = 10, id_shown = abc, user_id = 5)
  #     phr_test_prh2 (id = 11, id_shown = 1234567, user_id = 5)
  #     other_user_phr1 (id = 12, id_shown = def123, user_id = 6)
  #     temp_profile_1 (id = 20, id_shown = 7e8rt, user_id = 7)
  fixtures :forms
  # use one (form_name PHR), panel_edit, panel_view
  fixtures :profiles_users
  
  
  # Tests to be sure the correct count is returned when, for the current 
  # user/profile/form:
  # 1) there are no rows;
  # 2) there is only a base row ;
  # 3) there is only a change row (and makes sure it gets deleted); and
  # 4) there is a base row and 0, 1 or 3 change rows.
  # 
  # This also tests to make sure:
  # 5) the method works for non-test-panel forms as well as test-panel-forms; and
  # 6) it clears out the data table for a panel_view base record that
  #    has no incremental data;
  #    
  # In addition the user object's data size (total and daily) are checked in the 
  # appropriate cases to make sure the sizes are incremented/decremented correctly.
  def test_have_change_data
    
    # Test for non-test-panel form 
    # user/profile with no autosave data
    sp1 = profiles(:standard_profile_1)
    assert_equal(false, AutosaveTmp.have_change_data(sp1, 'phr'),
                 'Testing return for user/profile with no autosave data')
    
    # users/profiles with only a base row
    ts1 = profiles(:phr_test_phr1)
    sueb = autosave_tmps(:standard_user_empty_base)
    assert_equal(false, AutosaveTmp.have_change_data(ts1,
                                                     sueb.form_name))
    tp1 = profiles(:temp_profile_1)
    tueb = autosave_tmps(:temp_user_empty_base)
    assert_equal(false, AutosaveTmp.have_change_data(tp1,
                                                     tueb.form_name))                                                 
    
    # user/profile with one change record
    sp2 = profiles(:standard_profile_2)
    supb = autosave_tmps(:standard_user_change_hash)
    assert_equal(true, AutosaveTmp.have_change_data(sp2,
                                                    supb.form_name))
                                                
    # user/profile with multiple change records
    tp4 = profiles(:temp_profile_4)
    tupb = autosave_tmps(:temp_user_multiple_changes)
    assert_equal(false, AutosaveTmp.have_change_data(tp4,
                                                     tupb.form_name))
    # test for specific test-panel issues
    # test for a base record with leftover data for the panel_view form
    tupvpb = autosave_tmps(:temp_user_panel_view_populated_base)
    db_rec = AutosaveTmp.where({:profile_id => tp1.id, :form_name => tupvpb.form_name}).first
    starting_dt_len = db_rec.data_table.length
    user_obj = User.find_by_id(tp1.owner)
    starting_total_size = user_obj.total_data_size
    starting_daily_size = user_obj.daily_data_size
    assert_equal(false, AutosaveTmp.have_change_data(tp1,
                                                     tupvpb.form_name))
    db_rec = AutosaveTmp.where({:profile_id => tp1.id, :form_name => tupvpb.form_name}).first
    assert_equal('{}', db_rec.data_table)
    check_user_obj_size(tp1.owner, starting_daily_size,
                        starting_total_size, starting_dt_len)
    
    # test for non test panel and test panel - with and without named form only
    # test with leftover panel_view change rec
 
  end # test_have_change_data


  # tests to see if returns correct answer for both cases - base missing and
  # not missing,
  def test_missing_base
    # test with missing base
    mb = autosave_tmps(:standard_user_orphan_change_hash)
    assert_equal(true, AutosaveTmp.missing_base(mb.profile_id, 
                                                mb.form_name))
    
    # test with existing base
    hb = autosave_tmps(:standard_user_panel_edit_base)
    assert_equal(false, AutosaveTmp.missing_base(hb.profile_id, 
                                                 hb.form_name))
  end # test_missing_base
  
  
  # For the current user/profile/form:
  # * For the panel_view form, makes sure to remove any phrs table data from
  #   the data_table data stored.
  # * Tests that the base row is set/reset correctly when:
  #   1) there are no rows;
  #   2) there is only a base row;
  #   3) there is only an incremental row (and makes sure it gets deleted)
  #   4) there is a base row and 1 or 3 incremental rows
  #   5) this works for non-test-panel forms as well as test-panel-forms
  #   6) this clears out the data table for a test panel base records 
  #   7) this adds base data to a test panel base record when requested
  # The user object's data size (total and daily) are checked in each of
  # these cases to make sure the sizes are incremented/decremented correctly. 
  # check user totals
  # check invalid parameters
  def test_set_autosave_base
    # test panel forms:
    # test with flowsheet passing in phrs data
    fp = autosave_tmps(:standard_user_panel_view_base)
    fpuser = users(:standard_account)
    fp_profile = profiles(:standard_profile_2)
    starting_daily = fpuser.daily_data_size
    starting_total = fpuser.total_data_size
    tbl_str = '{"phrs":[{"pseudonym":"Hortense","birth_date":"1910 Jun 6",' +
              '"gender":"Female"}]}'
    AutosaveTmp.set_autosave_base(fp_profile,
                                  fp.form_name,
                                  ProfilesUser::READ_WRITE_ACCESS,
                                  tbl_str,
                                  false,
                                  false)
    check_user_obj_size(fpuser.id, starting_daily, starting_total, 0)

    # test with adding to base, do_close true
    # test with adding to base, do_close false
    # test with NOT adding to base, do_close true
    # test with NOT adding to base, do_close false
    assert true
    # test with empty data table string
    # test with data string and:
    #  test for no base or change rec
    #  test for base, no change rec
    #  test with base and change rec
    
    
  end # test_set_autosave_base
  
  def test_add_base_data
    assert true
  end
  
  def test_save_change_rec
    assert true
  end
  
  def test_merge_changes
    # Test the removal of a change record when an exception is raised.
    # Not going to test the other possible errors here, since the error
    # checking is scheduled to be consolidated into a separate method.
    # But the change data removal will remain here.

    # Use a profile where there is a change record but no base record.
    # This should cause an error that should throw an exception,
    # and the change record should be deleted.
    @user = users(:temporary_account_3)
    test_prof = profiles(:standard_profile_3)
    auto_rec = autosave_tmps(:standard_user_change_hash_2)
    
    assert_raise(RuntimeError){
                    AutosaveTmp.merge_changes(test_prof, auto_rec.form_name)}
    chgs = AutosaveTmp.where( {:profile_id => test_prof.id,
                                            :form_name => auto_rec.form_name,
                                            :base_rec => false}).load
    assert_equal(0,chgs.length)
    
  end # test_merge_changes
  
  def test_merge_tp_changes
   # Test the removal of a change record when an exception is raised.
    # Not going to test the other possible errors here, since the error
    # checking is scheduled to be consolidated into a separate method.
    # But the change data removal will remain here.

    # Use a profile where there are change records for the test panel forms
    # but no base records. This should cause an error that should throw an exception,
    # and the change record should be deleted.
    test_prof = profiles(:temp_profile_3)
    auto_rec = autosave_tmps(:temp_user_panel_view_change)

    assert_raise(RuntimeError){
                    AutosaveTmp.merge_changes(test_prof, auto_rec.form_name)}
    chgs = AutosaveTmp.where({:profile_id => test_prof.id,
                                            :form_name => auto_rec.form_name,
                                            :base_rec => false}).load
    assert_equal(0,chgs.length)

  end
  
  def test_rollback_autosave_changes
    assert true
  end
  
  def test_get_autosave_data_tables
    assert true
  end
  
  def test_convert_from_browser_json
    assert true
  end
  
  def test_merge_change_hash
    assert true
  end
  
  def test_merge_base_tp_records
    assert true
  end
  
  def check_user_obj_size(user_id, starting_daily, starting_total, acc_length)
    user_obj = User.find_by_id(user_id)
    assert_equal(starting_total - acc_length, user_obj.total_data_size)
    if (starting_daily - acc_length) > 0
      assert_equal(starting_daily - acc_length, user_obj.daily_data_size)
    else
      assert_equal(0, user_obj.daily_data_size)
    end
  end # check_user_obj_size

end # autosave_tmp_test
