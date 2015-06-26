require 'test_helper'
class ServersideValidationTest < ActiveSupport::TestCase
  TABLES = %w(db_table_descriptions db_field_descriptions regex_validators
    text_lists text_list_items gopher_terms drug_name_routes drug_strength_forms
    field_descriptions)

# We decided not to use serverside validations, and later added validations
# on the model classes themselves, so this test won't work, but we are
# keeping it just in case.

#  def setup
#    DatabaseMethod.copy_development_tables_to_test(TABLES, false)
#
#    # For some reason all data table models are missing, reload them again
#    DbTableDescription.define_user_data_models
#
#    # Sets up validations for testing purpose
#    validation_config =[
#      ["required", nil, {"phr_drugs" => ["name_and_route", "drug_use_status"]}],
#      ["size", {:maximum=>8}, {"phr_medical_contacts"=>["name"]}],
#      ["phone", nil, {"phr_medical_contacts"=>["phone"]}],
#      ["email", nil, {"phr_medical_contacts"=>["email"]}],
#      ["date", nil,  { "phr_drugs"=>["drug_start"]}],
#      ["time", nil, {"obr_orders"=>["test_date_time"]}],
#      ["unique", {:scope => :profile_id},
#        {"phr_medical_contacts"=>["name", "email"]}],
#      ["selectable", {:with_exception => true},
#        {"phr_drugs"=>["name_and_route", "drug_strength_form"],
#         "phr_conditions"=> ["problem"]}],
#      ["selectable", nil , {"phr_drugs"=>["drug_use_status"]}]]
#    ServersideValidation.load_validations(validation_config)
#  end
#
#  def test_server_side_validations
#    # Test required fields: name_and_route and drug_use_status of phr_drugs
#    d = PhrDrug.new
#    #case 1: required field can be empty if the record is blank
#    assert d.valid?
#    d.record_id = 1
#    d.valid?
#    #case 2: required field in a non empty record has to be filled
#    assert_equal d.errors.on(:name_and_route),"can't be blank"
#    assert_equal d.errors.on(:drug_use_status),"can't be blank"
#
#    # Test limited size field: name of phr_medical_contacts
#    c = PhrMedicalContact.new
#    #case 1: field value could be nil
#    assert c.valid?
#    c.name = "12345678"
#    #case 2: field size within the limit (which is 8)
#    assert c.valid?
#    c.name +="9"
#    #case 3: field size over the limit (which is 8)
#    assert !c.valid?
#    assert_equal c.errors.on(:name), "is too long (maximum is 8 characters)"
#
#    # Test phone field: phone of phr_medical_contacts
#    error_msg =
#      RegexValidator.find_by_description("Phone number (US or international)").error_message
#    c = PhrMedicalContact.new
#    c.valid?
#    #case 1: when phone number is nil, it is valid
#    assert_nil c.errors.on(:phone)
#    #case 2: when phone number only has digits and the number of digits is in
#    #the range of 7-10, it is valid
#    c.phone = "1234567"
#    c.valid?
#    assert_nil c.errors.on(:phone)
#    c.phone = "12345678901"
#    c.valid?
#    assert_equal c.errors.on(:phone), error_msg
#    c.phone = "1234567890"
#    c.valid?
#    assert_nil c.errors.on(:phone)
#    #case 3: when phone number is in the correct format
#    c.phone = "00 000 000 0000"
#    c.valid?
#    assert_nil c.errors.on(:phone)
#    c.phone = "0 000 000 0000"
#    c.valid?
#    assert_equal c.errors.on(:phone), error_msg
#
#    # Test email field: email field of phr_medical_contacts table
#    error_msg = RegexValidator.find_by_description("E-Mail Address").error_message
#    c = PhrMedicalContact.new
#    assert c.valid?
#    c.email = "fas_d1.f@mail.nih.gov" # valid email address
#    assert c.valid?
#    c.email = "asdf-asdf@mail.nih.gov" # invalid email address: space not allowed
#    assert !c.valid?
#    assert_equal c.errors.on(:email), error_msg
#    c.email = "asdfasdf@mail" # invalid email address: wrong dns
#    assert !c.valid?
#    assert_equal c.errors.on(:email), error_msg
#    c.email = "asdfasdf@mail.com.com.com.com" # valid dns of email address
#    assert c.valid?
#
#    # Test date field: drug_start field of phr_drugs table
#    date_format_error_msg = RegexValidator.find_by_description("Date").error_message
#    not_match_error_msg =
#      DbFieldValidationMethods::ERROR_MESSAGES[:date_formats_not_match]
#    t = PhrDrug.new
#    # case 1: date field could be blank when its related HL7 and ET are both blank
#    t.valid?
#    assert_nil t.errors.on(:drug_start)
#    # case 2: date field can not be blank when HL7 field is not blank
#    t.drug_start_HL7 = "20010101"
#    t.valid?
#    assert_equal t.errors.on(:drug_start), not_match_error_msg
#    #case 3: Valid date field reflects the same date as its corresponding HL7
#    #and ET fields
#    t.drug_start = "2001/01/01"
#    t.drug_start_ET = Time.parse(t.drug_start).to_i * 1000
#    t.valid?
#    assert_nil t.errors.on(:drug_start)
#    #case 4: date field value is invalid when it has wrong format
#    t.drug_start = "01/01/2001"
#    t.valid?
#    assert_equal t.errors.on(:drug_start), date_format_error_msg
#    #case 5: date field is invalid if its HL7 field has a different date
#    t.drug_start = "2001 01 01"
#    t.drug_start_HL7 = "19990909"
#    t.valid?
#    assert_equal t.errors.on(:drug_start), not_match_error_msg
#    #case 6: date field is invalid if its ET field has a different date
#    t.drug_start_HL7 = "20010101"
#    t.drug_start_ET = ""
#    t.valid?
#    assert_equal t.errors.on(:drug_start), not_match_error_msg
#
#    # Test time field: test_date_time field of obr_orders table
#    rec = ObrOrder.new
#    rv = RegexValidator.find_by_description("Time")
#    error_message = rv.error_message
#    #case 1: empty time field should be valid
#    rec.valid?
#    assert_nil rec.errors.on(:test_date_time)
#    #case 2: time field should follow correct format
#    rec.test_date_time = "8:33 AM"
#    rec.valid?
#    assert_nil rec.errors.on(:test_date_time)
#    rec.test_date_time = "08:33 AM"
#    rec.valid?
#    assert_nil rec.errors.on(:test_date_time)
#    rec.test_date_time = "18:33"
#    rec.valid?
#    assert_nil rec.errors.on(:test_date_time)
#    #case 3: time field with wrong format will result in getting an error message
#    rec.test_date_time = "28:33"
#    rec.valid?
#    assert_equal rec.errors.on(:test_date_time), error_message
#
#    # Test unique value field: email field of phr_medical_contacts table
#    rec = PhrMedicalContact.new
#    #case 1: unique value fields can be empty
#    rec.valid?
#    assert_nil rec.errors.on(:email)
#    #case 2: unique value field cannot have duplicated value based on its scope
#    rec.profile_id = 1
#    rec.email = "abc@msn.com"
#    rec.save!
#    rec1 = PhrMedicalContact.new
#    rec1.profile_id = 1
#    rec1.email = "abc@msn.com"
#    a = rec1.valid?
#    assert_equal rec1.errors.on(:email), "has already been taken"
#    rec1.profile_id = 2
#    rec1.save
#    assert_nil rec.errors.on(:email)
#
#    # Test CNE/CWE fields:
#    # drug_use_status, name_and_route of phr_drugs table and
#    # problem field of phr_conditions table
#    error_message = "is invalid. " +
#        DbFieldValidationMethods::ERROR_MESSAGES[:name_code_not_match]
#    rec = PhrDrug.new
#    # For CWE and CNE
#    # case 1: blank drug record is valid
#    assert rec.valid?
#    # For CNE only
#    # name and code field should match
#    # case 1: invalid when name has value and code is blank
#    rec.drug_use_status = "no-match drug_status"
#    rec.valid?
#    assert_equal rec.errors.on(:drug_use_status), error_message
#    # case 2: invalid when name and code are not blank, but they do not match
#    rec.drug_use_status_C = "DRG-A"
#    rec.valid?
#    assert_equal rec.errors.on(:drug_use_status), error_message
#    # case 3: valid when name and code are not blank, and they match
#    rec.drug_use_status = "Active"
#    rec.valid?
#    assert_nil rec.errors.on(:drug_use_status)
#    # For CWE only
#    # code field has to be blank or match name field
#    # case 1: invalid when code field is blank
#    rec.name_and_route ="no-match drug"
#    rec.valid?
#    assert_nil rec.errors.on(:name_and_route)
#    # case 2: invalid when code field does not match name field
#    rec.name_and_route_C = "8407"
#    rec.valid?
#    assert_equal rec.errors.on(:name_and_route), error_message
#    # case 3: valid when code field matches name field
#    rec.name_and_route ="BALAGAN (Otic)"
#    rec.valid?
#    assert_nil rec.errors.on(:name_and_route)
#
#    # Test CWE field problem on phr_conditions table
#    rec = PhrCondition.new
#    rec.problem_C = "3335"
#    rec.valid?
#    assert_equal rec.errors.on(:problem), error_message
#    rec.problem ="no-match-problem"
#    rec.valid?
#    assert_equal rec.errors.on(:problem), error_message
#    rec.problem ="Ascites"
#    rec.valid?
#    assert_nil rec.errors.on(:problem)
#
#    # Test a validate phr_drug
#    d_attrs = {"stopped_date_HL7"=>"20100528", "record_id"=>4,
#  "expire_date_HL7"=>"20100529", "expire_date_ET"=>1275105600000,
#  "why_stopped"=>"Don't know", "stopped_date"=>"20100528",
#  "name_and_route_C"=>"331","drug_use_status"=>"Stopped",
#  "name_and_route"=>"J-TAN (Oral-liquid)", "drug_start_ET"=>1274846400000,
#  "expire_date"=>"20100529", "drug_strength_form"=>"4 mg/5ml Susp",
#  "drug_start_HL7"=>"20100526",  "drug_use_status_C"=>"DRG-I",
#  "why_stopped_C"=>"STP-1",
#  "stopped_date_ET"=>1275019200000, "drug_start"=>"20100526", "latest"=>true,
#  "instructions"=>"yyy gggggggggggg",
#  "drug_strength_form_C"=>"645741", "profile_id"=>3484}
#    rec = PhrDrug.new(d_attrs)
#    assert rec.valid?, rec.errors.full_messages
#  end
#
#  def teardown
#    DbFieldDescription.update_all(:validation_opts => nil)
#  end

end

