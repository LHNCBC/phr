require 'test_helper'

class PhrConditionTest < ActiveSupport::TestCase
  
  fixtures :users
  fixtures :profiles
  fixtures :profiles_users
  fixtures :text_lists, :text_list_items
  fixtures :db_table_descriptions, :db_field_descriptions, :field_descriptions


  def test_dup_check
    user = create_test_user
    PhrCondition.delete_all
    GopherTerm.delete_all
    GopherTerm.create!(:key_id=>'8815', :primary_name=>'Meningitis - fungal')
    GopherTerm.create!(:key_id=>'8321',
      :primary_name=>'Coma - hyperosmolar nonketotic (HONK)')
    PhrCondition.create!(:latest=>1, :profile_id=>user.profiles.first.id,
      :present=>'Active', :present_C=>'A',
      :problem=>'Meningitis - fungal', :problem_C=>'8815')
    cond = PhrCondition.create!(:latest=>1, :profile_id=>user.profiles.first.id,
      :present=>'Active', :present_C=>'A',
      :problem=>'Coma - hyperosmolar nonketotic (HONK)', :problem_C=>'8321')

    # Try checking a non-duplicate
    assert_nil cond.dup_check

    # Try creating a new duplicate
    cond = PhrCondition.new(:latest=>1, :profile_id=>user.profiles.first.id,
      :present=>'Active', :present_C=>'A',
      :problem=>'Meningitis - fungal', :problem_C=>'8815')
    assert_equal('Meningitis - fungal', cond.dup_check)

    # Try creating something that isn't a duplicate
    cond = PhrCondition.new(:latest=>1, :profile_id=>user.profiles.first.id,
      :present=>'Active', :present_C=>'A',
      :problem=>'something', :problem_C=>'12')
    assert_nil cond.dup_check

    # Try creating something with a different problem name but which is a
    # duplicate based on its code value.
    cond = PhrCondition.new(:latest=>1, :profile_id=>user.profiles.first.id,
      :present=>'Active', :present_C=>'A',
      :problem=>'Fungal Meningitis', :problem_C=>'8815')
    assert_equal('Fungal Meningitis', cond.dup_check)

    # Try checking a saved record that is a duplicate
    cond = PhrCondition.create!(:latest=>1, :profile_id=>user.profiles.first.id,
      :present=>'Active', :present_C=>'A',
      :problem=>'Meningitis - fungal', :problem_C=>'8815')
    assert_equal('Meningitis - fungal', cond.dup_check)

    # Create something that doesn't have a code and isn't a duplicate.
    cond = PhrCondition.new(:latest=>1, :profile_id=>user.profiles.first.id,
      :present=>'Active', :present_C=>'A',
      :problem=>'Pain')
    assert_nil cond.dup_check

    # Save it and try a duplicate.
    cond.save!
    cond = PhrCondition.new(:latest=>1, :profile_id=>user.profiles.first.id,
      :present=>'Active', :present_C=>'A',
      :problem=>'Pain')
    assert_equal('Pain', cond.dup_check)
  end


  def test_phr_data_sanitizer
    PhrCondition.sanitize_user_data
    ra = PhrCondition.new(:problem=>'cannot remember', :present_C=>'A')
    ra.save!

    # Test prob_desc field of PhrCondition model
    # prob_desc will escape html tag by inserting a space after > sign for a
    # normally XSS safe tag <b>
    remaining_text = "remaining_text"
    bold_text = "<b>bold_text</b>"
    ra.prob_desc = bold_text + remaining_text
    ra.save!
    assert_equal ra.prob_desc, "< b>bold_text< /b>" + remaining_text
    # prob_desc will escape html tag by inserting a space after > sign for
    # dangerous script tag
    script_text = "<script>script_text</script>"
    ra.prob_desc = script_text + remaining_text
    ra.save!
    assert_equal ra.prob_desc, "< script>script_text< /script>" +  remaining_text
    # prob_desc will escape html tag by inserting a space after > sign for
    # unknown tag
    ra.prob_desc = "<blar>" + remaining_text + "</blar>"
    ra.save!
    assert_equal ra.prob_desc, "< blar>" + remaining_text + "< /blar>"
    # prob_desc field allow less than sign (< sign followed by a space) and less
    # than or equal sign as operators
    unknown_tag =
      # There has to be a space after less than sign
    "a< 1 and k > 1.1 and b < 2 and k > 2.1"+
      # There is no space required after less than or equal sign
    " and c<=3 and k > 3.1 and d <=4 and k > 4.1"
    ra.prob_desc = unknown_tag
    ra.save!
    assert_equal ra.prob_desc, unknown_tag
  end
  
  def test_get_row_length
    valid_user = users(:PHR_Test)
    valid_profile = profiles(:phr_test_phr1)
    
    cond_values = {"profile_id" => valid_profile.id ,
                   "record_id" => 1 ,
                   "latest" => true ,
                   "problem" => 'Blindness' ,
                   "problem_C" => '2190' ,
                   "prob_desc" => "'I see' said the blind man as he " +
                                  'picked up his hammer and saw.' ,
                   "present" => 'Active' ,
                   "present_C" => 'DRG-A' ,
                   "when_started" => '1970 Dec 1' ,
                   "when_started_HL7" => '1970/12/01' ,
                   "when_started_ET" => 18875599872 ,
                   "cond_stop" => nil ,
                   "cond_stop_HL7" => nil ,
                   "cond_stop_ET" => nil }
    
    tinyint_fields = ['latest']
    tinyint_size = 1    
    int_fields = ['id', 'profile_id', 'record_id']
    int_size = 4    
    bigint_fields = ['when_started_ET','cond_stop_ET']
    bigint_size = 8
    datetime_fields = ['version_date', 'deleted_at']
    datetime_size = 8
    varchar_fields = ['problem', 'problem_C', 'prob_desc',
                      'present', 'present_C', 'when_started',
                      'when_started_HL7', 'cond_stop', 'cond_stop_HL7']
    
    expected_size = int_size * int_fields.length
    expected_size += tinyint_size * tinyint_fields.length
    expected_size += bigint_size * bigint_fields.length
    expected_size += datetime_size * datetime_fields.length
    fixed_size = expected_size
    varchar_fields.each do |field_name|
      field_value = cond_values[field_name]
      expected_size += field_value.nil? ? 2 : field_value.length + 2     
    end    
    assert_equal(expected_size, PhrCondition.get_row_length(cond_values))
    
    cond_values2 = {"profile_id" => valid_profile.id ,
                    "record_id" => 2 ,
                    "latest" => false ,
                    "problem" => 'Unrestrained Optimism' ,
                    "problem_C" => 'Yes!' ,
                    "prob_desc" => "Wheeeeee! " ,
                    "present" => 'Inactive' ,
                    "present_C" => 'DRG-I' ,
                    "when_started" => '1960 Dec 1' ,
                    "when_started_HL7" => '1960/12/01' ,
                    "when_started_ET" => 18875599872 ,
                    "cond_stop" => '2012 Jan 1' ,
                    "cond_stop_HL7" => '2012/01/01' ,
                    "cond_stop_ET" => 1234567890100
                    }   
                  
    expected_size = fixed_size
    varchar_fields.each do |field_name|
      field_value = cond_values2[field_name]
      expected_size += field_value.nil? ? 2 : field_value.length + 2     
    end  
    assert_equal(expected_size, PhrCondition.get_row_length(cond_values2))    
  end
  
  def test_mass_insert_length
    valid_user = users(:PHR_Test)
    valid_profile = profiles(:phr_test_phr1)  
   
    cond_values = {"profile_id" => valid_profile.id ,
                   "record_id" => 1 ,
                   "latest" => true ,
                   "problem" => 'Blindness' ,
                   "problem_C" => '2190' ,
                   "prob_desc" => "'I see' said the blind man as he " +
                                  'picked up his hammer and saw.' ,
                   "present" => 'Active' ,
                   "present_C" => 'DRG-A' ,
                   "when_started" => '1970 Dec 1' ,
                   "when_started_HL7" => '1970/12/01' ,
                   "when_started_ET" => 18875599872 ,
                   "cond_stop" => nil ,
                   "cond_stop_HL7" => nil ,
                   "cond_stop_ET" => nil
                   }   
    cond_values2 = {"profile_id" => valid_profile.id ,
                    "record_id" => 2 ,
                    "latest" => true ,
                    "problem" => 'Unrestrained Optimism' ,
                    "problem_C" => 'Yes!' ,
                    "prob_desc" => "Wheeeeee! " ,
                    "present" => 'Active' ,
                    "present_C" => 'DRG-A' ,
                    "when_started" => '1960 Dec 1' ,
                    "when_started_HL7" => '1960/12/01' ,
                    "when_started_ET" => 18875599872 ,
                    "cond_stop" => nil ,
                    "cond_stop_HL7" => nil ,
                    "cond_stop_ET" => nil
                   }   
    cond_values3 = {"profile_id" => valid_profile.id ,
                    "record_id" => 2 ,
                    "latest" => false ,
                    "problem" => 'Unrestrained Optimism' ,
                    "problem_C" => 'Yes!' ,
                    "prob_desc" => "Wheeeeee! " ,
                    "present" => 'Inactive' ,
                    "present_C" => 'DRG-I' ,
                    "when_started" => '1960 Dec 1' ,
                    "when_started_HL7" => '1960/12/01' ,
                    "when_started_ET" => 18875599872 ,
                    "cond_stop" => '2012 Jan 1' ,
                    "cond_stop_HL7" => '2012/01/01' ,
                    "cond_stop_ET" => nil
                    }   
                  
    inserts = []
    inserts << cond_values
    inserts << cond_values2
    inserts << cond_values3
   
    tinyint_fields = ['latest']
    tinyint_size = 1    
    int_fields = ['id', 'profile_id', 'record_id']
    int_size = 4    
    bigint_fields = ['when_started_ET','cond_stop_ET']
    bigint_size = 8
    datetime_fields = ['version_date', 'deleted_at']
    datetime_size = 8
    varchar_fields = ['problem', 'problem_C', 'prob_desc',
                      'present', 'present_C', 'when_started',
                      'when_started_HL7', 'cond_stop', 'cond_stop_HL7']   
   
    expected_size = int_size * int_fields.length
    expected_size += tinyint_size * tinyint_fields.length
    expected_size += bigint_size * bigint_fields.length
    expected_size += datetime_size * datetime_fields.length
   
    expected_size = expected_size * 3
    varchar_fields.each do |field_name|
      inserts.each do |cur_cond|
        field_value = cur_cond[field_name]
        expected_size += field_value.nil? ? 2 : field_value.length + 2 
      end
    end    
    assert_equal(expected_size, PhrCondition.get_mass_insert_length(inserts))  
 end  
end
