require 'test_helper'

class TextValidatorTest < ActiveSupport::TestCase

  def test_validators
    copyDevelopmentTables(['regex_validators'])
    
    check_phone_validator
    check_integer_validator
    check_social_security_validator
    check_zip_code_validator
    check_bounded_number_validator
    check_medicare_validator
    check_upin_validator
    check_medicaid_validator
    check_dea_validator
    check_npi_validator
    check_date_validator
    check_email_validator

  end
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_phone_validator
    rv = RegexValidator.find_by_description(
                           'Phone number (US or international)')
                           
    assert_equal('01-022-033-4444', check_match(rv, '01-022-033-4444'))
    assert_equal('01-022 033 4444', check_match(rv, '01-022 033 4444'))
    assert_equal('01 (022) 033-4444', check_match(rv, '01 (022) 033-4444'))
    assert_equal('01 022 033 4444', check_match(rv, '01 022 033 4444'))
    assert_equal('123 4567', check_match(rv, '123 4567'))
    assert_equal('123-4567 x5', check_match(rv, '123-4567 x5'))
    assert_equal(rv.error_message, check_match(rv, '01 022 (033) 4444'))
    assert_equal('01 022 033 4444 X544', 
                 check_match(rv, '01 022 033 4444 X544'))
    assert_equal(rv.error_message, check_match(rv, '+ 22 333 4444 52'))
    assert_equal('+1 (22) 555 2838 x544', 
                 check_match(rv, '+1 (22) 555 2838 x544'))
    assert_equal('+(022) 5455 000.2238 ext 5', 
                 check_match(rv, '+(022) 5455 000.2238 ext 5'))
    assert_equal(rv.error_message, check_match(rv, '+1F 003 2233 Af2'))
    assert_equal(rv.error_message, check_match(rv, nil))
    
  end # check_phone_validator
  
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #  
  def check_integer_validator
    rv = RegexValidator.find_by_description('Integer')
    
    assert_equal('01', check_match(rv, '01'))
    assert_equal(rv.error_message, check_match(rv, '01-022'))
    assert_equal(rv.error_message, check_match(rv, '01.033-4444'))
    assert_equal('0', check_match(rv, ' 0'))
    assert_equal(rv.error_message, check_match(rv, '0.1'))  
    assert_equal(rv.error_message, check_match(rv, nil))  
    
  end # check_integer_validator
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #  
  def check_social_security_validator
    rv = RegexValidator.find_by_description('Social Security Number')
     
    assert_equal('123-45-6789', check_match(rv, '123456789'))
    assert_equal('123-45-6789', 
                 check_match(rv, '                        123-45-6789'))
    assert_equal(rv.error_message, check_match(rv, '1234X6789'))    
    assert_equal(rv.error_message, check_match(rv, '123.45.6789'))
    assert_equal(rv.error_message, check_match(rv, nil))
    
  end # check_social_security_validator
  
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_zip_code_validator
    rv = RegexValidator.find_by_description(
                                'U.S. Zip Code or Canadian Postal Code')    

    assert_equal('12345', check_match(rv, '12345'))
    assert_equal('12345-6789', check_match(rv, '12345-6789'))
    assert_equal('12345-6789', check_match(rv, '   12345-6789'))    
    assert_equal(rv.error_message, check_match(rv, '123456789'))
    assert_equal(rv.error_message, check_match(rv, '1234'))    
    assert_equal(rv.error_message, check_match(rv, '1234-6789'))    
    assert_equal(rv.error_message, check_match(rv, '12345-789'))
    assert_equal(rv.error_message, check_match(rv, '12345-A789'))    
    assert_equal(rv.error_message, check_match(rv, '1234A-6789'))
    
    assert_equal('A1A 1A1', check_match(rv, 'A1A 1A1')) 
    assert_equal('A1A 1A1', check_match(rv, '   A1A 1A1'))       
    assert_equal('a1a 1a1', check_match(rv, 'a1a 1a1'))    
    assert_equal('b1A 1b1', check_match(rv, 'b1A 1b1'))     
    assert_equal(rv.error_message, check_match(rv, 'a1a-1a1'))    
    assert_equal(rv.error_message, check_match(rv, 'a1a1a1'))     
    assert_equal(rv.error_message, check_match(rv, 'a1a aa1')) 
    assert_equal(rv.error_message, check_match(rv, 'aab 1a1')) 
    assert_equal(rv.error_message, check_match(rv, 'a1 1a1'))
    assert_equal(rv.error_message, check_match(rv, 'a1a a1')) 
    assert_equal(rv.error_message, check_match(rv, nil)) 
    
  end # check_zip_code_validator
  
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_bounded_number_validator
    rv = RegexValidator.find_by_description('Bounded Number')    

    assert_equal('12345', check_match(rv, '12345')) 
    assert_equal('12.34', check_match(rv, '12.34'))
    assert_equal('>12.34', check_match(rv, '   >12.34'))
    assert_equal('<12.34', check_match(rv, '<12.34  '))
    assert_equal('>12.34', check_match(rv, '>      12.34'))    
    assert_equal('-1234', check_match(rv, '-1234'))
    assert_equal(rv.error_message, check_match(rv, '<>12.34'))
    assert_equal(rv.error_message, check_match(rv, '(12.34)'))
    assert_equal(rv.error_message, check_match(rv, '12   34'))    
    assert_equal(rv.error_message, check_match(rv, '12.34.44'))        
    assert_equal(rv.error_message, check_match(rv, '12\34'))
    assert_equal(rv.error_message, check_match(rv, '12F34'))       
    assert_equal(rv.error_message, check_match(rv, '1234H'))    
    assert_equal(rv.error_message, check_match(rv, nil))    
    
  end # check_bounded_number_validator
  
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_medicare_validator
    rv = RegexValidator.find_by_description('Medicare')    

    assert_equal('123-45-6789A', check_match(rv, '123456789-A'))
    assert_equal('123-45-6789A', 
                 check_match(rv, '                123-45-6789A'))
    assert_equal(rv.error_message, check_match(rv, '1234X6789A'))    
    assert_equal(rv.error_message, check_match(rv, '123.45.6789-A'))
    assert_equal(rv.error_message, check_match(rv, '123456789AA'))
    assert_equal(rv.error_message, check_match(rv, nil))
    
  end # check_medicare_validator
  
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_upin_validator
    rv = RegexValidator.find_by_description('Upin')    

    assert_equal('123456', check_match(rv, '123456'))
    assert_equal('123456', check_match(rv, '  123456')) 
    assert_equal('123456', check_match(rv, '123456  '))    
    assert_equal('aBcDef', check_match(rv, 'aBcDef'))
    assert_equal(rv.error_message, check_match(rv, '1234567'))
    assert_equal(rv.error_message, check_match(rv, '12345'))
    assert_equal(rv.error_message, check_match(rv, 'abC ddf')) 
    assert_equal(rv.error_message, check_match(rv, '123(#6')) 
    assert_equal(rv.error_message, check_match(rv, nil)) 
    
  end # check_upin_validator
  
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_medicaid_validator
    rv = RegexValidator.find_by_description('Medicaid')    

    assert_equal('0-123-45-6789', check_match(rv, '0123456789'))
    assert_equal('0-123-45-6789', 
                 check_match(rv, '                0-123-45-6789'))
    assert_equal(rv.error_message, check_match(rv, '01234X6789'))    
    assert_equal(rv.error_message, check_match(rv, '0.123.45.6789'))
    assert_equal(rv.error_message, check_match(rv, '01234567890'))
    assert_equal(rv.error_message, check_match(rv, nil))
    
  end # check_medicaid_validator
  
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_dea_validator
    rv = RegexValidator.find_by_description('DEA#')    

    assert_equal('zA1234561', check_match(rv, 'zA1234561'))
    assert_equal('AA1234561', 
                 check_match(rv, '                AA1234561'))
    assert_equal(rv.error_message, check_match(rv, '1A123456A')) 
    assert_equal(rv.error_message, check_match(rv, 'AA12345678'))      
    assert_equal(rv.error_message, check_match(rv, 'AA.123456.A'))
    assert_equal(rv.error_message, check_match(rv, '22ABCDEFX'))
    assert_equal(rv.error_message, check_match(rv, nil))
    
  end # check_dea_validator
  
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_npi_validator
    rv = RegexValidator.find_by_description('NPI')    

    assert_equal('1234567890', check_match(rv, '1234567890'))
    assert_equal('1234567890', 
                 check_match(rv, '                1234567890'))
    assert_equal(rv.error_message, check_match(rv, '1234X678901'))  
    assert_equal(rv.error_message, check_match(rv, '1234X6789A'))      
    assert_equal(rv.error_message, check_match(rv, '123.45.6789-A'))
    assert_equal(rv.error_message, check_match(rv, '123456789AA'))
    assert_equal(rv.error_message, check_match(rv, nil))
    
  end # check_npi_validator
  
     
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_date_validator
    rv = RegexValidator.find_by_description('Date')    

    assert_equal('1934/12/28', check_match(rv, '19341228'))
    assert_equal('1934/12/28', 
                 check_match(rv, '                19341228'))
    assert_equal('1934/12/28', check_match(rv, '1934-12-28'))
    assert_equal('1934/12/28', check_match(rv, '1934 12 28'))

    assert_equal(rv.error_message, check_match(rv, '12/28/1934'))    
    assert_equal(rv.error_message, check_match(rv, '28/12/1934'))
    assert_equal(rv.error_message, check_match(rv, '19341238'))
    assert_equal(rv.error_message, check_match(rv, '19341428'))
    assert_equal(rv.error_message, check_match(rv, '18341228'))
    assert_equal(rv.error_message, check_match(rv, '1934122'))
    assert_equal(rv.error_message, check_match(rv, '193412'))    
    assert_equal(rv.error_message, check_match(rv, nil))
    
  end # check_date_validator
  
  
  
  # This method submits various valid and invalid values
  # to the check_match method and verifies that the response 
  # is as expected for the validator being tested.
  #
  def check_email_validator
    rv = RegexValidator.find_by_description('E-Mail Address')    

    assert_equal('harry@test.com', check_match(rv, 'harry@test.com'))
    assert_equal('harry@test.com', 
                 check_match(rv, '                harry@test.com'))
    assert_equal('Ma.S.Smith@test.com', check_match(rv, 'Ma.S.Smith@test.com'))
    assert_equal('Ma.S.Smith@this.test.com', 
                 check_match(rv, 'Ma.S.Smith@this.test.com'))

    assert_equal(rv.error_message, check_match(rv, 'ha$test.com'))    
    assert_equal(rv.error_message, check_match(rv, 'haATtest.com'))
    assert_equal(rv.error_message, check_match(rv, 'ha@test'))
    assert_equal(rv.error_message, check_match(rv, '@test.com'))
    assert_equal(rv.error_message, check_match(rv, 'ha@'))
    assert_equal(rv.error_message, check_match(rv, nil))
    
  end # check_email_validator
  
            
  # This method tests a string against a regex validator and
  # returns either: the normalized version of the input string 
  # (formatted as specified in the normalized_format column of
  # the regex_validators row for the validator being tested); or
  # the error_message specified by the regex_validators row.
  #
  # Parameters: 
  # * re_rec the regex_validators table row for the validator
  #   to be tested
  # * val the value to be tested against the validator
  #
  # Returns: either the input as formatted by the validator's 
  #          normalized string or the validator-specific error message
  #  
  def check_match(re_rec, val)
    re = Regexp.new(re_rec.regex)
    res = re.match(val)
    if res.nil?
      ret = re_rec.error_message
    else
      ret = re_rec.normalized_format
      while ret.include?('#{$')
        s_pos = ret.index('#{$')
        e_pos = ret.index('}')
        d_val = ret[(s_pos + 3)..(e_pos - 1)].to_i
        ret = ret.sub('#{$' + d_val.to_s + '}', res[d_val].to_s)
      end
    end
    return ret
  end
  
  def copyDevelopmentTables(tables)
    table_names = tables.class == Array ? tables.join(','): tables
    puts 'Copying tables:  ' + table_names
    dev_db = DatabaseMethod.getDatabaseName('development')
    verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    start = Time.now.to_f
    tables.each do |t|
      ActiveRecord::Migration.execute("delete from #{t}")
      ActiveRecord::Migration.execute("insert into #{t} select * "+
        "from #{dev_db}.#{t}")
    end
    # update sequence on Oracle
    table_names = ['forms', 'field_descriptions', 'rules',
                   'rule_actions', 'rule_cases',
                   'text_lists', 'text_list_items', 'list_details']
    DatabaseMethod.updateSequence(table_names)
    
    puts "Copied tables in #{Time.now.to_f - start} seconds."
    ActiveRecord::Migration.verbose = verbose
  end 
  
end
