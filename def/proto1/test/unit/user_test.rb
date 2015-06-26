require 'test_helper'
require 'set'

class UserTest < ActiveSupport::TestCase
  fixtures :db_table_descriptions
  fixtures :users
  fixtures :two_factors
  fixtures :autosave_tmps
  fixtures :question_answers
  fixtures :user_preferences
  fixtures :profiles_users
  fixtures :profiles
  fixtures :date_reminders
  fixtures :obr_orders
  fixtures :obx_observations
  fixtures :phrs
  fixtures :phr_allergies
  fixtures :phr_conditions
  fixtures :phr_doctor_questions
  fixtures :phr_drugs
  fixtures :phr_immunizations
  fixtures :phr_medical_contacts
  fixtures :phr_surgical_histories
  fixtures :reminder_options
  
  
  def test_typed_data_records
    # Define the user data table model classes
    DbTableDescription.define_user_data_models
    
    u = users(:PHR_Test)
    # Test that we can get the phrs that belong to this user.
    phrs = u.typed_data_records('phrs')
    assert_equal(2, phrs.size)
    id_set = Set.new
    id_set << -20
    id_set << -2
    assert(id_set.member?(phrs[0].id))
    assert(id_set.member?(phrs[1].id))
    assert(phrs[0].id != phrs[1].id)
    
    # Test that we can get a paricular Phr
    phrs = u.typed_data_records('phrs', :pseudonym=>'father')
    assert_equal(1, phrs.size)
    assert_equal(-2, phrs[0].id)
    
    # Test the id_shown method that gets added to the table class.
    assert_equal('1234567', phrs[0].id_shown)    
  end


  def test_add_account
    # need to fill this in
  end # test_add_account


  # This tests the get_attribute_errors method with the following conditions:
  # a.  one error should be returned;
  # b.  two errors should be returned; and
  # c.  no errors should be returned.
  #
  # For the cases where errors should be returned, it checks for the correct
  # error.
  #
  def test_get_attribute_errors
    page_errors = []
    user_obj = User.new(:pin=>'1234')
    user_obj.name = ''
    user_obj.save

    # test for one error on one attribute
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :name)
    assert_equal(1, page_errors.size)
    assert_equal(User.missing_userid_msg, page_errors[0])

    # test for two errors on one attribute
    user_obj.errors.clear
    page_errors.clear
    user_obj.valid?
    second_err = 'a second error on the name attribute'
    user_obj.errors.add(:name, second_err)
    page_errors = user_obj.get_attribute_errors(page_errors, :name)
    assert_equal(2, page_errors.size)
    assert_equal(User.missing_userid_msg, page_errors[0])
    assert_equal(second_err, page_errors[1])

    # test for zero errors on one attribute
    user_obj.name = 'AvalidName'
    user_obj.errors.clear
    page_errors.clear
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :name)
    assert_equal(0, page_errors.size)

  end # test_get_attribute_errors


  # This tests the validity checks that are done on object validation - both
  # when the object is saved & when the valid? method is invoked on the object.
  #
  def test_auto_validations
    page_errors = []
    # make sure we don't get errors on a valid user
    valid_user = create_test_user
    assert_equal(0, valid_user.errors.size)
    # test for a missing name
    user_obj = User.new(:pin=>'1234')
    user_obj.name = ''
    user_obj.save
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :name)
    assert_equal(1, page_errors.size)
    assert_equal(User.missing_userid_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # test for a duplicate name and invalid password

    user_obj.name = valid_user.name
    user_obj.password = user_obj.password_confirmation = 'nope'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :name)
    assert_equal(1, page_errors.size)
    assert_equal(User.duplicate_userid_msg, page_errors[0])
    page_errors.clear
    page_errors = user_obj.get_attribute_errors(page_errors, :password)
    assert_equal(1, page_errors.size)
    assert_equal(User.invalid_password_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # test for invalid name formats:
    # 1.  contains invalid characters (blanks are invalid)
    user_obj.name = 'I am invalid'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :name)
    assert_equal(1, page_errors.size)
    assert_equal(User.invalid_userid_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # 2.  too short (6 character minimum)
    user_obj.name = 'X2345'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :name)
    assert_equal(1, page_errors.size)
    assert_equal(User.invalid_userid_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # 2.  too long (32 character maximum)
    user_obj.name = 'X23456789012345678901234567890123'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :name)
    assert_equal(1, page_errors.size)
    assert_equal(User.invalid_userid_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # 3.  doesn't start with a letter
    user_obj.name = '12345678901234567890123456789012'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :name)
    assert_equal(1, page_errors.size)
    assert_equal(User.invalid_userid_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # test for invalid password formats:
    # 1.  too short (8 character minimum)
    user_obj.password = user_obj.password_confirmation = 'X234567'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :password)
    assert_equal(1, page_errors.size)
    assert_equal(User.invalid_password_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # 2.  doesn't start with a letter
    user_obj.password = user_obj.password_confirmation = '12345678'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :password)
    assert_equal(1, page_errors.size)
    assert_equal(User.invalid_password_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # 3.  only has lower case letters and numbers
    user_obj.password = user_obj.password_confirmation = 'adkdkdkdkw1223'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :password)
    assert_equal(1, page_errors.size)
    assert_equal(User.invalid_password_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # 4.  only has upper case letters and special characters
    user_obj.password = user_obj.password_confirmation = 'X(*&^#V)!(*^^#%'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :password)
    assert_equal(1, page_errors.size)
    assert_equal(User.invalid_password_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # Test for a duplicate email
    valid_user.email = 'ab@cd.ef'
    valid_user.save!
    user_obj.email = valid_user.email
    user_obj.valid?
    assert(valid_user.errors[:email].empty?)
    assert(!user_obj.errors[:email].empty?)
  end # test_auto_validations


  # This tests password validity checking.  Specifically, it tests the following
  # cases:
  # a.  missing the first password entry;
  # b.  missing the second/confirmation password entry;
  # c.  differing first and second/confirmation password entries; and
  # d.  matching and correct first and second/confirmation password entries.
  #
  def test_password_input_checks
    user_obj = User.new(:name => 'valid_name', :pin=>'1234')
    page_errors = []
    user_obj.password = ''
    user_obj.password_confirmation = 'not_blank2'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :password)
    assert_equal(1, page_errors.size)
    assert_equal(User.need_both_passwords_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    user_obj.password = 'not_blank1'
    user_obj.password_confirmation = ''
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :password)
    assert_equal(1, page_errors.size)
    assert_equal(User.need_both_passwords_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    user_obj.password = 'not_blank1'
    user_obj.password_confirmation = 'Something2'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :password)
    assert_equal(1, page_errors.size)
    assert_equal(User.passwords_must_match_msg, page_errors[0])
    user_obj.errors.clear
    page_errors.clear

    # make sure that no errors are returned when the input is correct
    user_obj.password = user_obj.password_confirmation = 'not_blank1'
    user_obj.valid?
    page_errors = user_obj.get_attribute_errors(page_errors, :password)
    assert_equal(0, page_errors.size)

  end # test_password_input_checks


  # This tests security settings update.  Specifically, it tests the following
  # cases:
  # a. Create an initial user object and add questions/answers 
  # b. Update password only. 
  # c. update questions only
  # d. update both question and answers.
  def test_update_security
    @page_errors = []
    
    # Create an initial user object and add questions/answers 
    user = create_test_user
    user.valid?    
    assert_equal(0, user.errors.size)

    fq1 = 'What city was your father born in?'
    fq2 = 'What is the last name of your favorite singer?'
    sq1 = "SQ1"
    sq2 = "SQ2"
    qa_attrs = {
      QuestionAnswer::FIXED_QUESTION => [[fq1 ,"1"], [ fq2,"2"]],
      QuestionAnswer::USER_QUESTION => [[sq1 ,'3' ],[sq2 ,'4']]
    }   
    user.update_security_question(qa_attrs, @page_errors)  
    assert_equal(0, @page_errors.size)
    @page_errors.clear

    # The order in which the questions are retrieved would be the same as they were created. 
    # This is the operating assumption in matching question_answer array with appropriate
    # question and answer.
    assert_equal(User.encrypted_password(user.password, user.salt),user.hashed_password)
    user_qa = user.question_answers
    assert_equal(user_qa[0].question, fq1)
    assert_equal(user_qa[0].answer, user_qa[0].encrypted_answer('1'))
    assert_equal(user_qa[1].question, fq2)
    assert_equal(user_qa[1].answer, user_qa[1].encrypted_answer('2'))
    assert_equal(user_qa[2].question, sq1)
    assert_equal(user_qa[2].answer, user_qa[2].encrypted_answer('3'))
    assert_equal(user_qa[3].question, sq2)
    assert_equal(user_qa[3].answer, user_qa[3].encrypted_answer('4'))
    
    # Update password only. 
    passwd_only = {
      :password =>'Password_2', 
      :password_confirmation => 'Password_2' ,
      :question_answers =>{
        QuestionAnswer::FIXED_QUESTION => [["#{fq1}_mod",''],["#{fq2}_mod",'']],
        QuestionAnswer::USER_QUESTION =>  [["#{sq1}_mod",''],["#{sq2}_mod",'']]
      }
    }
    user.update_profile_to_db(passwd_only, @page_errors)
    assert_equal(0, @page_errors.size)    
    assert_equal(User.encrypted_password('Password_2',user.salt),user.hashed_password) 
    user_qa = user.question_answers
    assert_equal(user_qa[0].question, fq1)
    
    @page_errors.clear
     
    # update questions only
    fq1+="_mod"
    fq2+="_mod"
    sq1+="_mod"
    sq2+="_mod"
    questions_only = {
      :question_answers =>{
        QuestionAnswer::FIXED_QUESTION => [[fq1,'21'],[fq2,'22']],
        QuestionAnswer::USER_QUESTION =>  [[sq1,'23'],[sq2,'24']]
      }
    }
    user.update_profile_to_db(questions_only, @page_errors)
    assert_equal(0, @page_errors.size)
    @page_errors.clear
    
    # The order in which the questions are retrieved would be the same as they were created. 
    # This is the operating assumption in matching question_answer array with appropriate
    # quesiton and answer.
    assert_equal(User.encrypted_password('Password_2',user.salt),user.hashed_password) 
    user_qa = user.question_answers.reload
    assert_equal(user_qa[0].question, fq1)
    assert_equal(user_qa[0].answer, user_qa[0].encrypted_answer('21'))
    assert_equal(user_qa[1].question, fq2)
    assert_equal(user_qa[1].answer, user_qa[1].encrypted_answer('22'))
    assert_equal(user_qa[2].question, sq1)
    assert_equal(user_qa[2].answer, user_qa[2].encrypted_answer('23'))
    assert_equal(user_qa[3].question, sq2)
    assert_equal(user_qa[3].answer, user_qa[3].encrypted_answer('24'))
      
    # update both question and passwords.
    fq1+="_mod"
    fq2+="_mod"
    sq1+="_mod"
    sq2+="_mod"
    questions_only = {
      :password =>'Password_3', :password_confirmation => 'Password_3' ,
      :question_answers =>{
      QuestionAnswer::FIXED_QUESTION => [[fq1,'31'],[fq2,'32']],
      QuestionAnswer::USER_QUESTION =>  [[sq1,'33'],[sq2,'34']]}
    }    
    user.update_profile_to_db(questions_only, @page_errors)
    assert_equal(0, @page_errors.size)
    @page_errors.clear
    
    assert_equal(User.encrypted_password('Password_3',user.salt),user.hashed_password) 
    user_qa = user.question_answers.reload
    assert_equal(user_qa[0].question, fq1)
    assert_equal(user_qa[0].answer,user_qa[0].encrypted_answer('31'))
    assert_equal(user_qa[1].question, fq2)
    assert_equal(user_qa[1].answer,user_qa[1].encrypted_answer('32'))
    assert_equal(user_qa[2].question,sq1)
    assert_equal(user_qa[2].answer,user_qa[2].encrypted_answer('33'))
    assert_equal(user_qa[3].question,sq2)
    assert_equal(user_qa[3].answer,user_qa[3].encrypted_answer('34'))

    fq2 = 'What city was your father born in?'
    sq2 ="SQ23"
    questions_only = {
      :password =>'Password_4', :password_confirmation => 'Password_4' ,
      :question_answers =>{
        QuestionAnswer::FIXED_QUESTION => [[fq1,''],[fq2,'32']],
        QuestionAnswer::USER_QUESTION => [[sq1,''],[sq2,'35']]}
    }     
    user.update_profile_to_db(questions_only, @page_errors)
    assert_equal(0, @page_errors.size)
    @page_errors.clear
     
    assert_equal(User.encrypted_password('Password_4',user.salt),user.hashed_password) 
    user_qa = user.question_answers.reload
    assert_equal(user_qa[0].question, fq1)
    assert_equal(user_qa[0].answer,user_qa[1].encrypted_answer('31'))
    assert_equal(user_qa[1].question, fq2)
    assert_equal(user_qa[1].answer,user_qa[0].encrypted_answer('32'))
    assert_equal(user_qa[2].question, sq1)
    assert_equal(user_qa[2].answer,user_qa[3].encrypted_answer('33'))
    assert_equal(user_qa[3].question, sq2)
    assert_equal(user_qa[3].answer,user_qa[2].encrypted_answer('35'))
    
    # When update both fixed/self-defined questions, validation should not fail
    # when the first new question is the same as the second existing question
    user = User.find_by_id(user)
    fqas = user.question_answers.select{|e| e.qtype = QuestionAnswer::FIXED_QUESTION}
    second_quest = fqas[1].question
    # when only one question needs to be updated, then uniqueness validation 
    # works smoothly
    data_hash = {:question_answers =>{
      QuestionAnswer::FIXED_QUESTION => 
        [[second_quest,'1'],["#{second_quest}_mod",'']]
      }}     
    user.update_profile_to_db(data_hash, @page_errors)
    assert_equal(1, @page_errors.size)
    @page_errors.clear
    # when both questions need to be updated, a workaround needs to be added to 
    # avoid the unnecessary uniqueness validation failure 
    data_hash = {:question_answers =>{
      QuestionAnswer::FIXED_QUESTION => 
        [[second_quest,'1'],["#{second_quest}_mod",'1']]
      }}     
    user.update_profile_to_db(data_hash, @page_errors)
    assert_equal(0, @page_errors.size)
    
  end # test_password_input_checks


  # This tests the validity checking on security questions - predefined and
  # self-created. It includes checks for:
  # a.  no (nil) questions or answers supplied;
  # b.  blank questions and answers supplied;
  # c.  some, but not all, questions and some, but not all, answers supplied;
  # d.  repetitious questions/answers supplied; and
  # e.  correct specification of questions and answers.
  def test_questions_input_checks

    the_errs = User.questions_input_checks(nil, nil, nil, nil,
      nil, nil)
    assert(the_errs.include?(User.need_both_predef_questions_msg))
    assert(the_errs.include?(User.need_both_predef_answers_msg))
    assert(the_errs.include?(User.need_self_question_msg))
    assert(the_errs.include?(User.need_self_answer_msg))
    
    the_errs = User.questions_input_checks('', '', '', '', '', '')
    assert(the_errs.include?(User.need_both_predef_questions_msg))
    assert(the_errs.include?(User.need_both_predef_answers_msg))
    assert(the_errs.include?(User.need_self_question_msg))
    assert(the_errs.include?(User.need_self_answer_msg))

    the_errs = User.questions_input_checks('pdq1', 'pda1', nil, nil,
      nil, nil)
    assert(the_errs.include?(User.need_both_predef_questions_msg))
    assert(the_errs.include?(User.need_both_predef_answers_msg))
    assert(the_errs.include?(User.need_self_question_msg))
    assert(the_errs.include?(User.need_self_answer_msg))

    the_errs = User.questions_input_checks('pdq1', 'PA1', 'pdq1', 'PA2',
      'sq1', 'sa1')
    assert(the_errs.include?(User.predef_questions_must_not_match_msg))
   
    the_errs = User.questions_input_checks('pdq1', 'pdq1', 'pda1', 'pda1',
      'sq1', 'sa1')
    assert_equal(0, the_errs.size)
    
  end # test_questions_input_checks

  # Commented out 6/19/2014, per conversation with Paul.  We no longer use
  # temporary accounts, haven't used them in years, and don't expect to use
  # them in the future.   lm
#  # This is the first of 4 tests for the remove_expired_accounts method.
#  # This one tests to make sure that:
#  # 1.  a temporary account is deleted when it has:
#  #     a. an expiration before the current date; and
#  #     b. a created on date less than 6 months ago.
#  # 2.  a standard account is not deleted even though it has qualifying
#  #     expiration date and creation date values.
#  #
#  # There are 4 different tests to force reload of the fixture data for
#  # each test.
#  #
#  def test_remove_expired_accounts_1
#    ta = users(:temporary_account)
#    ta.expiration_date = 1.day.ago
#    ta.created_on = 5.months.ago
#    ta.save!
#
#    st = users(:standard_account)
#    st.expiration_date = 1.day.ago
#    st.created_on = 7.months.ago
#    st.save!
#
#    run_remove_expired_accounts_test(true, ta.id, st.id)
#  end
#
#
#  # This is the second of 4 tests for the remove_expired_accounts method.
#  # This one tests to make sure that:
#  # 1.  a temporary account is NOT deleted when it has:
#  #     a. an expiration after the current date; and
#  #     b. a created on date less than 6 months ago.
#  # 2.  a standard account is not deleted even though it has qualifying
#  #     expiration date and creation date values.
#  #
#  # There are 4 different tests to force reload of the fixture data for
#  # each test.
#  #
#  def test_remove_expired_accounts_2
#    ta = users(:temporary_account)
#    ta.expiration_date = 1.day.from_now
#    ta.created_on = 5.months.ago
#    ta.save!
#
#    st = users(:standard_account)
#    st.expiration_date = 1.day.ago
#    st.created_on = 7.months.ago
#    st.save!
#
#    run_remove_expired_accounts_test(false, ta.id, st.id)
#  end
#
#
#  # This is the third of 4 tests for the remove_expired_accounts method.
#  # This one tests to make sure that:
#  # 1.  a temporary account is deleted when it has:
#  #     a. an expiration after the current date; and
#  #     b. a created on date more than 6 months ago.
#  # 2.  a standard account is not deleted even though it has qualifying
#  #     expiration date and creation date values.
#  #
#  # There are 4 different tests to force reload of the fixture data for
#  # each test.
#  #
#  def test_remove_expired_accounts_3
#    ta = users(:temporary_account)
#    ta.expiration_date = 1.day.from_now
#    ta.created_on = 7.months.ago
#    ta.save!
#
#    st = users(:standard_account)
#    st.expiration_date = 1.day.ago
#    st.created_on = 7.months.ago
#    st.save!
#
#    run_remove_expired_accounts_test(true, ta.id, st.id)
#  end
#
#
#  # This actually runs the test for the remove_expired_accounts method.
#  # Expected results are based on the should_remove parameter passed in.
#  #
#  # Parameters:
#  # * should_remove - boolean indicating whether or not the temporary
#  #   account should be removed by the remove_expired_accounts method.
#  # * ta_id - id of the temporary account user object
#  # * st_id - id of the standard account user object
#  #
#  def run_remove_expired_accounts_test(should_remove, ta_id, st_id)
#    User.remove_expired_accounts
#
#    if (should_remove)
#      assert_equal(0, User.where({name: 'temp_account'}).length,
#        'expected temp_account to be deleted from users table')
#
#      User.user_id_tables.each do |table_name|
#        table_class = table_name.singularize.camelize.constantize
#        assert_equal(0, table_class.where({user_id: ta_id}).length,
#          'expected temp_account to be deleted from ' +
#            table_name + ' table')
#      end
#      assert_equal(0, ProfilesUser.where({user_id: ta_id}).length,
#        'expected temp_account to be deleted in profiles_users table')
#    else
#      assert_not_equal(0, User.where({name: 'temp_account'}).length,
#        'expected temp_account to exist in users table')
#
#      User.user_id_tables.each do |table_name|
#        table_class = table_name.singularize.camelize.constantize
#        assert_not_equal(0, table_class.where({user_id: ta_id}).length,
#          'expected temp_account to exist in ' +
#            table_name + ' table')
#      end
#      assert_not_equal(0, ProfilesUser.where({user_id: ta_id}).length,
#        'expected temp_account to exist in profiles_users table')
#    end
#
#    # Standard accounts don't expire
#    assert_equal(1, User.where({name: 'standard_account'}).length,
#      'expected standard_account to exist in users table')
#
#    User.user_id_tables.each do |table_name|
#      table_class = table_name.singularize.camelize.constantize
#      assert_not_equal(0, table_class.where({user_id: st_id}).length,
#        'expected standard_account to exist in ' +
#          table_name + ' table')
#    end
#    assert_not_equal(0, ProfilesUser.where({user_id: st_id}).length,
#      'expected standard_account to exist in profiles_users ' +
#        'table')
#  end # run_remove_expired_accounts_test
#

  def test_accumulate_data_length
    
    # create a valid user object
    valid_user = users(:PHR_Test)
    assert_equal(0, valid_user.errors.size)
    
    valid_user.accumulate_data_length(500)
    assert_equal(500, valid_user.total_data_size)
    assert_equal(500, valid_user.daily_data_size)
    assert_not_nil(valid_user.daily_size_date)
    
    valid_user.accumulate_data_length(-600)
    assert_equal(-100, valid_user.total_data_size)
    assert_equal(-100, valid_user.daily_data_size)
    
    valid_user.daily_size_date = DateTime.new - 100
    valid_user.accumulate_data_length(1400)
    assert_equal(1300, valid_user.total_data_size)
    assert_equal(1400, valid_user.daily_data_size)
    
    valid_user.daily_size_date = DateTime.new - 150
    valid_user.accumulate_data_length(-175)
    assert_equal(1125, valid_user.total_data_size)
    assert_equal(0, valid_user.daily_data_size)
    
  end # test_accumulate_data_length 
  
  def test_check_data_overflow
    
    # create a valid user object
    valid_user = users(:PHR_Test)
    assert_equal(0, valid_user.errors.size)   
    
    # test a daily size that is just over the limit
    begin
      valid_user.accumulate_data_length(User::DAILY_DATA_SIZE_LIMIT + 1)
      valid_user.check_data_overflow
      assert_equal('should not have gotten here', valid_user.name)
    rescue DataOverflowError
      assert_equal(true, valid_user.limit_lock)
    end
    
    # test a total size that is WAY over the limit   
    valid_user.limit_lock = false
    begin
      valid_user.accumulate_data_length(User::TOTAL_DATA_SIZE_LIMIT + 1)
      valid_user.check_data_overflow
      assert_equal('should not have gotten here', valid_user.name)
    rescue DataOverflowError
      assert_equal(true, valid_user.limit_lock)
    end   
    
    # test a total size that is just over the limit      
    valid_user.limit_lock = false
    valid_user.daily_data_size = 0
    valid_user.total_data_size = 0
    begin
      valid_user.accumulate_data_length(User::TOTAL_DATA_SIZE_LIMIT + 1)
      valid_user.check_data_overflow
      assert_equal('should not have gotten here', valid_user.name)
    rescue DataOverflowError
      assert_equal(true, valid_user.limit_lock)
    end  
    
    # test a total size that is under the limit - but over the daily limit
    valid_user.limit_lock = false
    valid_user.daily_data_size = 0
    valid_user.total_data_size = 0
    begin
      valid_user.accumulate_data_length(User::TOTAL_DATA_SIZE_LIMIT - 1)
      valid_user.check_data_overflow
      assert_equal('should not have gotten here', valid_user.name)
    rescue DataOverflowError
      assert_equal(true, valid_user.limit_lock)      
    end    

    # test a daily size that is under the limit 
    valid_user.limit_lock = false
    valid_user.daily_data_size = 0
    valid_user.total_data_size = 0
    begin
      valid_user.accumulate_data_length(User::DAILY_DATA_SIZE_LIMIT - 1)
      valid_user.check_data_overflow
      assert_equal(false, valid_user.limit_lock)
    rescue DataOverflowError
      assert_equal('should not have gotten here', valid_user.name)     
    end           
  
    # test a daily size that is at the limit   
    valid_user.daily_data_size = 0
    valid_user.total_data_size = 0
    begin
      valid_user.accumulate_data_length(User::DAILY_DATA_SIZE_LIMIT)
      valid_user.check_data_overflow
      assert_equal(false, valid_user.limit_lock)
    rescue DataOverflowError
      assert_equal('should not have gotten here', valid_user.name)     
    end            
  end # test_check_data_overflow


#  def test_birth_date
#    u = User.create!(:name=>'Adam123', :birth_date=>'2004/3/2', :pin=>'1234')
#    assert(u.valid?)
#
#    assert_equal('2004 Mar 2', u.birth_date)
#    assert_equal('20040302', u.birth_date_HL7)
#    assert_equal('1078203600000', u.birth_date_ET)
#    # Make sure it got stored that way
#    u = User.find_by_name('Adam123')
#    assert_equal('2004 Mar 2', u.birth_date)
#    assert_equal('20040302', u.birth_date_HL7)
#    assert_equal('1078203600000', u.birth_date_ET)
#  end


  def test_email
    # Check that a blank email address is okay - but it's NOT!
    u = User.new
    u.valid?
    assert_equal "can't be blank", u.errors[:email][0]

    # Check the confirmation validation
    u = User.new(:email=>'one@two.three', :email_confirmation=>'two@three.four')
    u.valid?
    assert_equal User.email_addresses_must_match_msg, u.errors[:email_confirmation][0]

    # Check that an email address must be in a valid format
    u = User.new(:email=>'hi')
    u.valid?
    assert_equal EMAIL_ERROR_MESSAGE,  u.errors[:email][0]
  end


  def test_random_question
    u = create_test_user
    # Make sure we keep getting the same random question
    q = u.random_question
    q2 = u.random_question
    q3 = u.random_question
    assert_equal q.id, q2.id
    assert_equal q.id, q3.id

    # Check that we get a new random question if we answered this one.
    # We might randomly pick the same question, so keep trying (up to 1000 times)
    # before we conclude the test is failing.
    new_question = false
    (1..1000).each do
      u.answered = 1
      u.save!
      q2 = u.random_question
      new_question = q.id != q2.id
      break if new_question
    end
    assert new_question
  end


  def test_random_question_pair
    u = create_test_user
    # Make sure we keep getting the same random question pair
    q = u.random_question_pair
    q2 = u.random_question_pair
    q3 = u.random_question_pair
    assert_equal q, q2
    assert_equal q, q3

    # Check that one is fixed and one is user-defined.
    assert_equal 1, q[0].qtype
    assert_equal 0, q[1].qtype
  end
  
  
  def test_update_email
    t = create_test_user
    # avoid duplicated name/email errors
    new_u = create_test_user({:email => "aa@aa.aa", 
        :name => "#{t.name}#{Time.now.to_i}"})

    # when the input email is not unique
    page_errors=[]
    attrs = {:email => t.email }
    update_status = new_u.update_profile_to_db(attrs, page_errors)
    assert_equal update_status, -1
    assert page_errors.size > 0
    new_u= User.find_by_id(new_u)
    
    # when the input email does not match the input confirmation email
    page_errors=[]
    attrs = {:email => new_u.email, :email_confirmation => new_u.email+"#{Time.now.to_i}" }
    update_status = new_u.update_profile_to_db(attrs, page_errors)
    assert_equal update_status, -1
    assert page_errors.size > 0
    new_u= User.find_by_id(new_u)

    # when the input email data is correct
    page_errors=[]
    attrs = {:email => new_u.email, :email_confirmation => new_u.email }
    update_status = new_u.update_profile_to_db(attrs, page_errors)
    assert_equal update_status, 1
    assert page_errors.empty?
  end
end
