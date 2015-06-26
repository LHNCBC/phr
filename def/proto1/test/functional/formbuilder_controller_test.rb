require 'test_helper'
require 'formbuilder_controller'

# Re-raise errors caught by the controller.
class FormbuilderController; def rescue_action(e) raise e end; end

class FormbuilderControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :two_factors
 
  # label_width has been removed from the forms table. it is added here only 
  # for passing the test.
  class ::Form
    attr_accessor :label_width
  end
  
  def setup
    @controller = FormbuilderController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL     
  end # setup 

  
  # This method tests the new_form controller method.  It requests a
  # a new form as an admin user, and checks to make sure the response
  # signalled success.
  # 
  # Then it requests a new form as a non-admin user, and checks to make
  # sure the response indicated a redirection - which would be to a 
  # page requesting admin login.
  #   
  def test_new_form
  
    # hm - we need some tables for this
    copyDevelopmentTables(['forms', 'form_builder_maps', 'predefined_fields'])  
    
    # confirm that we can get a new form page if we're an admin user
    get :new_form, {:form_name=>'FormBuilder'}, {:user_id=>users(:phr_admin).id}
    assert_response(:success, @response.body.to_s)
    
    # confirm that we can't get a new form page if we're not an admin user
    get :new_form, {:form_name=>'FormBuilder'}, {:user_id=>users(:PHR_Test).id}
    assert_response(302, @response.body.to_s)
    
  end # test_new_form
  
  
  # This method tests the edit_form controller method.  It copies the forms
  # and field_descriptions tables, as well as several related tables, from 
  # the development database to the test database to be able to use them 
  # without having to repopulate them here. 
  #
  # This calls edit_form, specifying the FormBuilder form as the one to be 
  # edited. It checks the response to make sure that successful completion
  # was signalled.  It then calls edit_form with a non-existent form name
  # and checks to be sure the proper error message is returned.
  #
  def test_edit_form
  
    copyDevelopmentTables(['forms', 'field_descriptions', 'form_builder_maps',
                           'predefined_fields', 'list_details', 
                           'text_lists', 'text_list_items', 'regex_validators'])
                           
    # get the form - specifying a form name that should be in all the
    # databases
    get :edit_form, {:form_name=>'FormBuilder'},
                    {:user_id=>users(:phr_admin).id}
    assert_response(:success, @response.body.to_s)
    #assert_equal(true, @controller.@edit_action)
    #assert_redirected_to('/forms')           
    
    # now try for a form that should not exist
    get :edit_form, {:form_name=>'NotThere'},
                    {:user_id=>users(:phr_admin).id}
    assert((@response.body.include?"With searching comes loss&lt\;br&gt\;" +
                                   "and the presence of absence.&lt\;br&gt\;" +
                                   "Form NotThere not found.&lt\;br&gt\;"), 
           "Form not found error message missing")
           
    # now try for a missing form name
    # There is no longer a matching route for this case
    #assert_raise(ActionController::RoutingError) do
    assert_raise(ActionController::UrlGenerationError) do
      get :edit_form, {:form_name=>nil},
                    {:user_id=>users(:phr_admin).id}
    end
           
    # now try the PHR form
    get :edit_form, {:form_name=>'PHR'},
                    {:user_id=>users(:phr_admin).id}
    assert_response(:success, @response.body.to_s)
    #assert_equal(true, @controller.@edit_action)
    #assert_redirected_to('/forms')
    assert((@response.body.include?'<div id=fbFieldsMap'),
            "fbFieldsMap missing")
    
     
    # get a short form and test data_hash for the right values.
    
  end # test_edit_form
  
  def test_phr_form_edit_and_save
  
    copyDevelopmentTables(['forms', 'field_descriptions', 'form_builder_maps',
                           'predefined_fields', 'list_details', 
                           'text_lists', 'text_list_items', 'regex_validators'])
                             
    get :edit_form, {:form_name=>'PHR'},
                    {:user_id=>users(:phr_admin).id}
    assert_response(:success, @response.body.to_s)  
  
  
    # update some values
    # store the form
    # check stored form
  
  
  end # test_phr_form_edit_and_save

  
  # This method tests the save_form controller method.  It sets up a
  # form fields object, populated with data at the form level and data
  # for one check box.  It copies several related tables from the development
  # database to the test database to be able to use them without having
  # to repopulate them here.
  #
  # This calls save_form and then checks to make sure that the form and field
  # description rows were saved.  It then updates the form fields object to
  # change one field for each, as well as provide some data related to 
  # updating, and calls save_form again.  This time it checks to see if the 
  # form fields were updated properly.
  #
  # Detailed checking of the saved data is performed in multiple other
  # test methods, and so we don't bother with that here.
  #
  def test_save_form
  
    copyDevelopmentTables(['forms', 'field_descriptions',
                           'form_builder_maps', 'predefined_fields',
                           'list_details', 'text_lists', 'text_list_items',
                           'regex_validators'])
                           
    # build an abbreviated form object
    fe_mast = {"form_description"=>"Form to test creation and update",
               "form_name"=>"AutoTest",
               "form_title"=>"Monday's test form",
               "form_type"=>"form",
               "id"=>""}
    #           "label_width"=>"8"} # label_width has been romoved
    fe_mast = make_empty_field_def(fe_mast, 0)
    fe_mast = make_empty_field_def(fe_mast, 1)
    
    fe_mast["control_type_1"] ="check_box"
    fe_mast["ctd_edit_1_1_1"] = "Always editable"
    fe_mast["ctd_edit_C_1_1_1"] = "1"
    fe_mast["ctd_first_1_1_1"] = "CheckBox"
    fe_mast["ctd_stored_no_1_1_1"] = "no"		
    fe_mast["ctd_stored_yes_1_1_1"] = "yes"		
    fe_mast["ctd_tooltip_1_1_1"] = "a tooltip for a check box"
    fe_mast["d_check_box_default_value_1_1_1"] = "yes"	
    fe_mast["display_name_1"] = "a check box"
    fe_mast["display_order_1"] = "1"
    fe_mast["field_type_1"] = "Check Box"
    fe_mast["supported_ft_1"] = "true"
    fe_mast["max_responses_1_1_1"] = ""
    fe_mast["predefined_field_id_1"] = "27"
    fe_mast["required_1_1_1"] = "No"
    fe_mast["target_field_1"] = "a_check_box"
    fe_mast["save_and_close"] = '1'
            
    # Right now we're expecting the user to be redirected when the 
    # form is saved successfully.  Change this if that changes.
    logger.info 'in test_save_form immediately before post'
    post :save_form, {:fe=>fe_mast.clone}, {:user_id=>users(:phr_admin).id}
    assert_response(302, @response.body.to_s)
    logger.info 'in test_save_form after post'
        
    fm = Form.where(form_name: 'AutoTest').take
    assert_not_nil(fm, 'Checking for form creation in test_save_form')
    
    cb = FieldDescription.where(form_id: fm.id,
                                target_field: 'a_check_box').take
    assert_not_nil(cb, 
                   'Checking for check box field creation in test_save_form')
                   
    # fill in the row id numbers and change one form field for the 
    # form and field_description rows, then run as an update
    
    fe_mast["form_title"] = "Monday's Autotest test form"
    fe_mast["id"] = fm.id.to_s
    fe_mast["display_name_1"] = "a check box name"
    fe_mast["field_id_1"] = cb.id.to_s
    
    post :save_form, {:fe=>fe_mast.clone, :form_name=>'AutoTest'},
                     {:user_id=>users(:phr_admin).id}
    assert_response(302, @response.body.to_s)

    fm = Form.where(form_name: 'AutoTest').take
    assert_not_nil(fm, 'Checking for form creation in test_save_form')
    assert_equal("Monday's Autotest test form", fm.form_title,
                 'Checking updated form_title in test_save_form')
                 
    cb = FieldDescription.where(form_id: fm.id,
                                target_field: 'a_check_box').take
    assert_not_nil(cb, 
                   'Checking for check box field creation in test_save_form')
    assert_equal('a check box name', cb.display_name, 
                 'Checking updated display_name in test_save_form')
                         
  end # test_save_form

  
  # This method tests the controller's load_field_def method
  def test_load_field_def
    # haven't done this one yet
    
    # Test load for each field type in the test form, including
    # the unsupported type(s)
    
  end # test_load_field_def

  # This method tests the controller's load_ctd_field method
  def test_load_ctd_field
  
    copyDevelopmentTables(['forms', 'field_descriptions',
                           'form_builder_maps', 'predefined_fields',
                           'list_details', 'text_lists', 'text_list_items',
                           'regex_validators'])
     
    fm = Form.where(form_name: 'fb_test_form').take

    # Test load of regular parameters that are there. Include tests for
    # a string, a hash, an array, a number and a boolean parameter
    
    # Test for a straightforward string value    
    targ_field = 'ctd_first'
    fld_data = FieldDescription.where(form_id: fm.id,
                                      display_name: 'Check Box').take
    check_one_ctd_field_load(targ_field, fld_data)
    
    # Test for a hash value.  Oops - don't have any of those that
    # match up to an existing form field.  If we get some, do this then.
    
    # Test for an array value
    targ_field = 'ctd_fields_searched'
    fld_data = FieldDescription.where(form_id: fm.id,
                                      display_name: 'CNE search field').take
    check_one_ctd_field_load(targ_field, fld_data)
    
    # Test for a number
    targ_field = 'ctd_disp_min'
    fld_data = FieldDescription.where(form_id: fm.id, 
                                      display_name: 'Numeric field').take
    check_one_ctd_field_load(targ_field, fld_data)
    
    # Test for a boolean parameter
    targ_field = 'ctd_show_unit'
    fld_data = FieldDescription.where(form_id: fm.id, 
                                      display_name: 'Numeric field').take
    check_one_ctd_field_load(targ_field, fld_data)
    
    # Test load of a regular parameter that's not there
    targ_field = 'ctd_place'
    fld_data = FieldDescription.where(form_id: fm.id, 
                                      display_name: 'Check Box').take
    check_one_ctd_field_load(targ_field, fld_data)
    
    # Test load of the search table parameter -- THIS IS DIFFERENT
    targ_field = 'ctd_search_tbl_name'
    fld_data = FieldDescription.where(form_id: fm.id, 
                                      display_name: 'CWE text field').take
    #check_one_ctd_field_load(targ_field, fld_data, 'search_table')
    
    # Test load of the edit parameter -- THIS IS DIFFERENT
    targ_field = 'ctd_edit'
    fld_data = FieldDescription.where(form_id: fm.id, 
                                      display_name: 'CNE search field').take
    #check_one_ctd_field_load(targ_field, fld_data)
        
    # Test load of the class parameters
    targ_field = 'ctd_class_no_group_hdr'
    fld_data = FieldDescription.where(form_id: fm.id, 
                                      display_name: 'Group header field').take
    check_one_ctd_field_load(targ_field, fld_data, 'class')
    
    targ_field = 'ctd_class_hidden'
    fld_data = FieldDescription.where(form_id: fm.id, 
                                      display_name: 'CWE text field code').take
    check_one_ctd_field_load(targ_field, fld_data, 'class')
    
    # Test load of a parameter that uses a list to translate the value
    
  end # test_load_ctd_field

  
  # This method tests the controller's store_form_data method.
  # It sets up a form object with the form part of the specifications,
  # acquires the forms table information, and then checks to see if
  # the form data was stored correctly.  It then sets up changes to the
  # form data and makes sure THAT is also stored correctly.
  #
  def test_store_form_data
  
    # Set up the form object
    fe_mast = {"form_description"=>"Form to test creation and update",
               "form_name"=>"Monday",
               "form_title"=>"Monday's test form",
               "form_type"=>"form",
               "id"=>"",
               "label_width"=>"8"}
    fe = fe_mast.clone
 
    copyDevelopmentTables(['forms', 'field_descriptions',
                           'text_lists', 'text_list_items'])
                           
    # Get default values for the form builder form.
    fb_fields, fb_defs = get_fb_fields
    cur_form = nil
          
    form_tbl_cols = Form.columns
    form_tbl_row  = Hash.new
    ror_types = Hash.new
    form_tbl_cols.each do |fc|
      form_tbl_row[fc.name] = fc.default
      if !fb_defs[fc.name].nil?
        form_tbl_row[fc.name] = fb_defs[fc.name]
      end
      ror_types[fc.name] = fc.type
    end        
          
    form_id = @controller.store_form_data(fe, form_tbl_row, ror_types, 
                                          cur_form, fb_fields)
    
    # Make sure the form was stored and check its values
    cur_form = check_form_data(form_id, 'Form to test creation and update')
    
    # Now reset the form object, change a couple of things, and then run
    # it again.
    
    fe = fe_mast
    fe["form_description"] = 'Updated form'
    fe["id"] = form_id
    
    form_id = @controller.store_form_data(fe, form_tbl_row, ror_types, 
                                          cur_form, fb_fields)    
    cur_form = check_form_data(form_id, 'Updated form')
    
  end # test_store_form_data

  # This method tests the controller's store_field_descriptions method.
  # Specifically it sets up the form object with specifications for
  # two fields, acquires the table information for the field_descriptions
  # table by copying the form and field_descriptions tables from the 
  # development database, and then checks to see if the two field 
  # descriptions were stored as expected.  It then sets up changes to
  # the form field descriptions and tests that they were stored correctly.
  #
  def test_store_field_descriptions

    fe = make_field_defs_object  

    # Call set_up_fd_objects to get the field_descriptions and 
    # form builder form definition data structures.
    fb_fields, fb_defs, fd_tbl_row, ror_types = set_up_fd_objects(150) 

    # Copy over various reference tables.
    copyDevelopmentTables(['predefined_fields', 'list_details',
                           'form_builder_maps', 'text_lists',
                           'text_list_items'])  
       
    # Invoke @controller.store_field_descriptions with a nil value for
    # cur_fields, which holds the current field descriptions from the
    # database when we're updating a current form.
    @controller.store_field_descriptions(fe, fd_tbl_row, ror_types, 
                                         nil, fb_fields)
    
    # Check for 3 fields in field descriptions with made-up form id 
    flds = FieldDescription.where(form_id: 150).to_a
    assert_equal(3,flds.length, 
                 'Checking number of field_description rows created')
      
    # Make sure the check box matches what we're expecting it to contain.
    cb_id = check_cb_row('a check box')
    cne_id = check_cne_row('Harriet')
    cne_code_id = check_cne_code_row
    
    # Now test with an update to existing form fields.  Use the flds
    # object for the cur_fields parameter, and make a couple of changes
    # to the check box and cne form fields.  For the cne code field, 
    # fill in the fields that are populated when it's (programmatically)
    # created, and then add blank fields for a 4th (visible) row.
    # Note that we need to get a new form object, because fields were
    # removed from the previous object as it was processed.
    
    fe = make_field_defs_object
    
    fe["field_id_1"] = cb_id
    fe["display_name_1"] = 'updated check box'
    fe["display_order_1"] = '5'
    
    fe["field_id_2"] = cne_id
    fe["d_text_field_default_value_2_1_1"] ='Hazel'
    fe["display_order_2"] = '30'
    
    fe["field_id_3"] = cne_code_id
    fe["display_order_3"] = '31'
    fe["display_name_3"] = 'a cne field code'
    fe["target_field_3"] = 'a_cne_field_C'
    fe["control_type_3"] = 'text_field'
    fe["control_type_detail_3"] = 'class=>(hidden_field)'
    fe["field_type_3"] = 'ST - string data'
    fe["predefined_field_id_3"] =
        PredefinedField.where(field_type: 'ST - string data').take.id
    fe["required_3_1_1"] = 'NO'
    
    fe = make_empty_field_def(fe, 4)  
        
    @controller.store_field_descriptions(fe, fd_tbl_row, ror_types, 
                                         flds, fb_fields)
    
    # Check for 3 fields in field descriptions with made-up form id 
    flds = FieldDescription.where(form_id: 150).to_a
    assert_equal(3,flds.length, 
                 'Checking number of field_description rows created')
      
    # Make sure the check box matches what we're expecting it to contain.
    cb_id = check_cb_row('updated check box')
    cne_id = check_cne_row('Hazel')
    cne_code_id = check_cne_code_row
    
  end # test_store_field_descriptions

  
  # This method tests the controller's get_field_data method AND 
  # get_one_data_row methods.  
  # 
  # Testing for get_extra_form_data consists of making sure that the only 
  # row(s) returned are for actual field definitions.
  #
  # Testing for get_one_data_row consists of making sure that the data
  # returned for the field definition includes elements for all fields
  # in the field_descriptions table row, whether or not data was specified
  # - or even solicited - for the field and that any necessary data 
  # conversions (e.g. for boolean fields) are performed.
  #
  # Testing here includes of building the appropriate input objects,
  # including data from the form and field_descriptions tables - which 
  # are copied from the development database.
  #
  def test_get_field_data
  
    # Build the form object.  This was taken from a dump of a form object
    # for a form with one check_box field defined.  I don't know that it's
    # really worth adding form fields for other field type definitions, but
    # go ahead if you want.  Just seems like overkill at this point, since 
    # all form fields are returned for each field definition, whether or not
    # they were actually displayed.
   
    fe = {"target_field_0"=>"",
          "ctd_tooltip_1_1_1"=>"a tooltip for a check box",
          "d_check_box_default_value_1_1_1"=>"no",
          "ctd_abs_min_1_1_1"=>"",
          "ctd_orientation_2_1_1"=>"",
          "ctd_show_unit_2_1_1"=>"",
          "required_1_1_1"=>"No",
          "target_field_1"=>"a_check_box",
          "regex_validator_id_2_1_1"=>"",
          "regex_validator_id_0_1_1"=>"",
          "ctd_disp_max_1_1_1"=>"",
          "help_text_1_1_1"=>"",
          "ctd_rows_0_1_1_1"=>"",
          "target_field_2"=>"",
          "label_width"=>"8",
          "d_static_text_default_value_0_1_1"=>"",
          "ctd_labels_1_1_1"=>"",
          "max_responses_1_1_1"=>"",
          "ctd_stored_yes_0_1_1"=>"yes",
          "control_type_0"=>"",
          "predefined_field_id_0"=>"",
          "ctd_show_range_0_1_1"=>"",
          "ctd_search_tbl_name_1_1_1"=>"",
          "ctd_class_no_group_hdr_1_1_1"=>"",
          "ctd_display_size_0_1_1"=>"",
          "ctd_open_0_1_1"=>"",
          "regex_validator_1_1_1"=>"",
          "ctd_cols_0_1_1_1"=>"",
          "control_type_1"=>"check_box",
          "predefined_field_id_1"=>"27",
          "control_type_2"=>"",
          "ctd_fields_displayed_1_1_1"=>"",
          "ctd_list_details_id_2_1_1"=>"",
          "predefined_field_id_2"=>"",
          "ctd_first_2_1_1"=>"FieldLabel",
          "field_description_id_0"=>"",
          "ctd_calendar_2_1_1"=>"",
          "field_description_id_1"=>"",
          "d_text_field_default_value_1_1_1"=>"",
          "field_id_0"=>"",
          "d_text_area_default_value_0_1_1"=>"",
          "ctd_abs_max_1_1_1"=>"",
          "form_type"=>"form",
          "ctd_date_format_1_1_1"=>"",
          "form_name"=>"Monday",
          "field_description_id_2"=>"",
          "form_description"=>"Form to test creation and update",
          "field_id_1"=>"1393",
          "units_of_measure_1_1_1"=>"",
          "group_header_name_1_1_1"=>"",
          "field_id_2"=>"",
          "d_static_text_default_value_2_1_1"=>"",
          "ctd_stored_yes_2_1_1"=>"yes",
          "ctd_edit_1_1_1"=>"Always editable",
          "ctd_show_range_2_1_1"=>"",
          "ctd_open_2_1_1"=>"",
          "ctd_display_size_2_1_1"=>"",
          "ctd_disp_min_0_1_1"=>"",
          "ctd_edit_C_1_1_1"=>"1",
          "ctd_orientation_1_1_1"=>"",
          "control_type_detail_0"=>"",
          "ctd_tooltip_0_1_1"=>"",
          "d_check_box_default_value_0_1_1"=>"no",
          "ctd_disp_max_0_1_1"=>"",
          "help_text_0_1_1"=>"",
          "display_name_0"=>"",
          "ctd_show_unit_1_1_1"=>"",
          "group_header_id_1_1_1"=>"",
          "control_type_detail_1"=>"stored_no=>no,stored_yes=>yes,edit=>1," +
                                   "first=>CheckBox," +
                                   "tooltip=>a tooltip for a check box",
          "ctd_rows_2_1_1_1"=>"",
          "d_text_area_default_value_2_1_1"=>"",
          "form_title"=>"Monday's test form",
          "display_name_1"=>"a check box",
          "control_type_detail_2"=>"",
          "ctd_stored_no_1_1_1"=>"no",
          "ctd_order_0_1_1"=>"",
          "ctd_fields_searched_1_1_1"=>"",
          "ctd_cols_2_1_1_1"=>"",
          "display_name_2"=>"",
          "ctd_id_type_0_1_1"=>"",
          "ctd_search_tbl_name_0_1_1"=>"",
          "instructions_2_1_1"=>"",
          "d_calendar_default_value_1_1_1"=>"",
          "instructions_0_1_1"=>"",
          "ctd_abs_min_0_1_1"=>"",
          "ctd_disp_min_2_1_1"=>"",
          "help_text_2_1_1"=>"",
          "ctd_disp_max_2_1_1"=>"",
          "d_text_field_default_value_0_1_1"=>"",
          "ctd_tooltip_2_1_1"=>"",
          "d_check_box_default_value_2_1_1"=>"no",
          "required_0_1_1"=>"",
          "regex_validator_id_1_1_1"=>"",
          "ctd_abs_max_0_1_1"=>"",
          "ctd_date_format_0_1_1"=>"",
          "ctd_order_2_1_1"=>"",
          "id"=>"57",
          "units_of_measure_0_1_1"=>"",
          "group_header_name_0_1_1"=>"",
          "ctd_show_range_1_1_1"=>"",
          "ctd_labels_0_1_1"=>"",
          "ctd_stored_yes_1_1_1"=>"yes",
          "ctd_id_type_2_1_1"=>"",
          "max_responses_0_1_1"=>"",
          "ctd_class_no_group_hdr_0_1_1"=>"",
          "ctd_edit_C_0_1_1"=>"1",
          "regex_validator_0_1_1"=>"",
          "ctd_display_size_1_1_1"=>"",
          "ctd_search_tbl_name_2_1_1"=>"",
          "ctd_fields_displayed_0_1_1"=>"",
          "field_type_0"=>"",
          "ctd_first_1_1_1"=>"CheckBox",
          "ctd_list_details_id_1_1_1"=>"",
          "ctd_calendar_1_1_1"=>"",
          "field_type_1"=>"Check Box",
          "group_header_id_0_1_1"=>"",
          "ctd_abs_min_2_1_1"=>"",
          "ctd_rows_1_1_1_1"=>"",
          "ctd_stored_no_0_1_1"=>"no",
          "field_type_2"=>"",
          "ctd_abs_max_2_1_1"=>"",
          "d_text_field_default_value_2_1_1"=>"",
          "required_2_1_1"=>"",
          "ctd_fields_searched_0_1_1"=>"",
          "units_of_measure_2_1_1"=>"",
          "ctd_date_format_2_1_1"=>"",
          "group_header_name_2_1_1"=>"",
          "d_static_text_default_value_1_1_1"=>"",
          "ctd_cols_1_1_1_1"=>"",
          "ctd_labels_2_1_1"=>"",
          "max_responses_2_1_1"=>"",
          "d_calendar_default_value_0_1_1"=>"",
          "ctd_edit_0_1_1"=>"Always editable",
          "ctd_open_1_1_1"=>"",
          "regex_validator_2_1_1"=>"",
          "ctd_edit_C_2_1_1"=>"1",
          "ctd_class_no_group_hdr_2_1_1"=>"",
          "ctd_disp_min_1_1_1"=>"",
          "ctd_orientation_0_1_1"=>"",
          "ctd_fields_displayed_2_1_1"=>"",
          "group_header_id_2_1_1"=>"",
          "display_order_0"=>"",
          "ctd_order_1_1_1"=>"",
          "d_text_area_default_value_1_1_1"=>"",
          "ctd_show_unit_0_1_1"=>"",
          "display_order_1"=>"1",
          "ctd_stored_no_2_1_1"=>"no",
          "ctd_fields_searched_2_1_1"=>"",
          "display_order_2"=>"",
          "ctd_id_type_1_1_1"=>"",
          "instructions_1_1_1"=>"",
          "ctd_calendar_0_1_1"=>"",
          "d_calendar_default_value_2_1_1"=>"",
          "ctd_edit_2_1_1"=>"Always editable",
          "ctd_list_details_id_0_1_1"=>"",
          "ctd_first_0_1_1"=>"FieldLabel"} 
          
    # Call set_up_fd_objects to get the form builder field_descriptions 
    # data structures used to acquire and parse the data.
    fb_fields, fb_defs, fd_tbl_row, ror_types = set_up_fd_objects(150)
  
    # Copy the development text list tables into the test database.  Need
    # these for reference in parsing the data.
    copyDevelopmentTables(['text_lists', 'text_list_items'])      
        
    # Now we can call get_field_data
    logger.info 'in test_get_field_info, about to call get_field_data'
    all_fd_rows, fd_tbl_row = @controller.get_field_data(fe, fd_tbl_row, 
                                                         ror_types, fb_fields)
    logger.info 'in test_get_field_info, just returned from get_field_data'
    all_fd_rows.each_index do |x|
      logger.info 'all_fd_rows, have row with index = ' + x.to_s
    end
    
    # We should get 1 element back - for suffix #1, which is the actual
    # form field defined for the form.  The data for suffix #2, which is the 
    # empty definition following the one "real" one, is dropped here.
    assert_equal(1, all_fd_rows.length, 'Checking for number of rows returned' +
                                        ' in all_fd_rows array.')
    
    # Now check the contents of the row.  It should contain one element 
    # for each field in a field_descriptions table row that applies to 
    # the field type.  Of those, it should include:
    # 1. fields that were returned with data - with the data returned -
    #    with boolean values translated from strings to booleans;
    # 2. fields that were not returned with data - with values of nil; and
    # Fields that are NOT accessible for the field type are removed so that
    # empty or default values are not stored in the table for them.
    expected = [
      {"form_id"=>150,
       "required"=>false,
       "target_field"=>"a_check_box",
       "max_responses"=>0,
       "control_type"=>"check_box",
       "predefined_field_id"=>"27",
       "control_type_detail"=>"stored_no=>no,stored_yes=>yes,edit=>1," +
                              "first=>CheckBox," +
                              "tooltip=>a tooltip for a check box",
       "display_name"=>"a check box",
       "field_type"=>"Check Box",
       "display_order"=>"1",
       "id"=>"1393",
       "units_of_measure"=>nil,
       "group_header_id"=>nil,
       "regex_validator_id"=>nil, 
       "instructions"=>nil ,
       "help_text"=>nil}
    ]
    assert_equal(expected, all_fd_rows, 'Checking row array returned.')    
    
  end # test_get_field_data


  # This method tests the controller's get_extra_form_data method.  
  # A dump of a form object is used for the form object input to be
  # tested, with form fields removed that should be removed by the 
  # controller's get_field_data method.
  #
  # Tests consist of making sure that the correct number of "extra"
  # hash elements are returned and that they contain the expected values.
  #
  def test_get_extra_form_data
  
    # Build the form object.  This was taken from a dump of a form object
    # for a form with one check_box field defined - same one as used by 
    # test_get_field_data.  
    # 
    # All the elements for form objects that correspond to columns in the
    # field_descriptions table have been removed, as this is the case when 
    # the controller runs normally. The exception is all form fields with a
    # suffix beginning with '_0' - which are fields for the model line in a
    # horizontal table.  We never show the model line to the user and
    # the fields can never be filled in.  They should be removed during
    # processing by get_extra_form_data (ALL for suffix = 0).
    fe = {
      "target_field_0"=>"",
      "regex_validator_id_0_1_1"=>"",      
      "ctd_tooltip_1_1_1"=>"a tooltip for a check box",
      "d_check_box_default_value_1_1_1"=>"no",
      "ctd_abs_min_1_1_1"=>"",
      "ctd_orientation_2_1_1"=>"",
      "ctd_show_unit_2_1_1"=>"",
      "ctd_disp_max_1_1_1"=>"",
      "ctd_rows_0_1_1_1"=>"",
      "d_static_text_default_value_0_1_1"=>"",
      "ctd_labels_1_1_1"=>"",
      "ctd_stored_yes_0_1_1"=>"yes",
      "control_type_0"=>"",
      "predefined_field_id_0"=>"",      
      "ctd_show_range_0_1_1"=>"",
      "ctd_search_tbl_name_1_1_1"=>"",
      "ctd_class_no_group_hdr_1_1_1"=>"",
      "ctd_display_size_0_1_1"=>"",
      "ctd_open_0_1_1"=>"",
      "regex_validator_1_1_1"=>"",
      "ctd_cols_0_1_1_1"=>"",
      "ctd_fields_displayed_1_1_1"=>"",
      "ctd_list_details_id_2_1_1"=>"",
      "ctd_first_2_1_1"=>"FieldLabel",
      "ctd_calendar_2_1_1"=>"",
      "d_text_field_default_value_1_1_1"=>"",
      "d_text_area_default_value_0_1_1"=>"",
      "ctd_abs_max_1_1_1"=>"",
      "ctd_date_format_1_1_1"=>"",
      "group_header_name_1_1_1"=>"",  
      "d_static_text_default_value_2_1_1"=>"",  
      "ctd_stored_yes_2_1_1"=>"yes",
      "ctd_edit_1_1_1"=>"Always editable",
      "ctd_show_range_2_1_1"=>"",
      "ctd_open_2_1_1"=>"",
      "ctd_display_size_2_1_1"=>"",
      "ctd_disp_min_0_1_1"=>"",
      "ctd_edit_C_1_1_1"=>"1",
      "ctd_orientation_1_1_1"=>"",
      "ctd_tooltip_0_1_1"=>"",
      "d_check_box_default_value_0_1_1"=>"no",
      "ctd_disp_max_0_1_1"=>"",
      "ctd_show_unit_1_1_1"=>"",
      "ctd_rows_2_1_1_1"=>"",
      "d_text_area_default_value_2_1_1"=>"",
      "ctd_stored_no_1_1_1"=>"no",
      "ctd_order_0_1_1"=>"",
      "ctd_fields_searched_1_1_1"=>"",
      "ctd_cols_2_1_1_1"=>"",
      "ctd_id_type_0_1_1"=>"",
      "ctd_search_tbl_name_0_1_1"=>"",
      "d_calendar_default_value_1_1_1"=>"",
      "ctd_abs_min_0_1_1"=>"",
      "ctd_disp_min_2_1_1"=>"",
      "ctd_disp_max_2_1_1"=>"",
      "field_id_0"=>"",      
      "d_text_field_default_value_0_1_1"=>"",
      "ctd_tooltip_2_1_1"=>"",
      "d_check_box_default_value_2_1_1"=>"no",
      "ctd_abs_max_0_1_1"=>"",
      "ctd_date_format_0_1_1"=>"",
      "ctd_order_2_1_1"=>"",
      "group_header_name_0_1_1"=>"",
      "ctd_show_range_1_1_1"=>"",
      "ctd_labels_0_1_1"=>"",
      "ctd_stored_yes_1_1_1"=>"yes",
      "ctd_id_type_2_1_1"=>"",
      "ctd_class_no_group_hdr_0_1_1"=>"",
      "ctd_edit_C_0_1_1"=>"1",
      "group_header_id_0_1_1"=>"",      
      "regex_validator_0_1_1"=>"",
      "ctd_display_size_1_1_1"=>"",
      "ctd_search_tbl_name_2_1_1"=>"",
      "field_description_id_0"=>"",      
      "ctd_fields_displayed_0_1_1"=>"",
      "control_type_detail_0"=>"",
      "help_text_0_1_1"=>"",      
      "ctd_first_1_1_1"=>"CheckBox",
      "ctd_list_details_id_1_1_1"=>"",
      "ctd_calendar_1_1_1"=>"",
      "field_type_0"=>"",      
      "ctd_abs_min_2_1_1"=>"",
      "ctd_rows_1_1_1_1"=>"",
      "ctd_stored_no_0_1_1"=>"no",
      "ctd_abs_max_2_1_1"=>"",
      "d_text_field_default_value_2_1_1"=>"",
      "ctd_fields_searched_0_1_1"=>"",
      "ctd_date_format_2_1_1"=>"",
      "group_header_name_2_1_1"=>"",
      "d_static_text_default_value_1_1_1"=>"",
      "ctd_cols_1_1_1_1"=>"",
      "regex_validator_0_1_1"=>"",      
      "ctd_labels_2_1_1"=>"",
      "d_calendar_default_value_0_1_1"=>"",
      "ctd_edit_0_1_1"=>"Always editable",
      "ctd_open_1_1_1"=>"",
      "regex_validator_2_1_1"=>"",
      "display_name_0"=>"",
      "instructions_0_1_1"=>"",
      "required_0_1_1"=>"",      
      "ctd_edit_C_2_1_1"=>"1",
      "ctd_class_no_group_hdr_2_1_1"=>"",
      "ctd_disp_min_1_1_1"=>"",
      "ctd_orientation_0_1_1"=>"",
      "ctd_fields_displayed_2_1_1"=>"",
      "units_of_measure_0_1_1"=>"",
      "group_header_name_0_1_1"=>"",
      "max_responses_0_1_1"=>"",      
      "ctd_order_1_1_1"=>"",
      "d_text_area_default_value_1_1_1"=>"",
      "ctd_show_unit_0_1_1"=>"",
      "ctd_stored_no_2_1_1"=>"no",
      "ctd_fields_searched_2_1_1"=>"",
      "ctd_id_type_1_1_1"=>"",
      "ctd_calendar_0_1_1"=>"",
      "d_calendar_default_value_2_1_1"=>"",
      "ctd_edit_2_1_1"=>"Always editable",
      "ctd_list_details_id_0_1_1"=>"",
      "display_order_0"=>"",       
      "ctd_first_0_1_1"=>"FieldLabel"}

    copyDevelopmentTables(['forms', 'field_descriptions',
                           'text_lists', 'text_list_items'])
    fb_fields, fb_defs = get_fb_fields

    # submit the object to get_extra_form_data
    extra = @controller.get_extra_form_data(fe, fb_fields)
    
    # fe should now have no key/value pairs.  Make sure that's true
    assert_equal(0, fe.length, 'Checking fe length after extra data removed')
    
    # check extra to see that it contains what it should, and doesn't
    # contain what it shouldn't
    
    expected = { 
1=>
  {"ctd_fields_searched"=>"",
   "ctd_disp_max"=>"",
   "ctd_calendar"=>"",
   "ctd_edit"=>"always editable",
   "ctd_abs_max"=>"",
   "ctd_open"=>"",
   "ctd_fields_displayed"=>"",
   "d_text_area_default_value"=>"",
   "d_static_text_default_value"=>"",
   "ctd_search_tbl_name"=>"",
   "ctd_stored_yes"=>"yes",
   "ctd_display_size"=>"",
   "d_text_field_default_value"=>"",
   "ctd_list_details_id"=>"",
   "ctd_class_no_group_hdr"=>"",
   "ctd_disp_min"=>"",
   "ctd_abs_min"=>"",
   "ctd_tooltip"=>"a tooltip for a check box",
   "ctd_order"=>"",
   "d_check_box_default_value"=>"no",
   "d_calendar_default_value"=>"",
   "regex_validator"=>"",
   "ctd_labels"=>"",
   "ctd_orientation"=>"",
   "ctd_show_range"=>"",
   "ctd_id_type"=>"",
   "ctd_first"=>"CheckBox",
   "ctd_edit_C"=>"1",
   "ctd_show_unit"=>"",
   "ctd_stored_no"=>"no",
   "ctd_cols"=>"",
   "ctd_rows"=>"",
   "group_header_name"=>"",
   "ctd_date_format"=>""},
 2=>
  {"ctd_disp_max"=>"",
   "ctd_calendar"=>"",
   "ctd_fields_searched"=>"",
   "ctd_open"=>"",
   "d_text_area_default_value"=>"",
   "ctd_edit"=>"always editable",
   "ctd_abs_max"=>"",
   "ctd_fields_displayed"=>"",
   "ctd_display_size"=>"",
   "d_static_text_default_value"=>"",
   "ctd_stored_yes"=>"yes",
   "ctd_search_tbl_name"=>"",
   "d_text_field_default_value"=>"",
   "ctd_class_no_group_hdr"=>"",
   "ctd_list_details_id"=>"",
   "ctd_tooltip"=>"",
   "ctd_abs_min"=>"",
   "ctd_disp_min"=>"",
   "d_check_box_default_value"=>"no",
   "regex_validator"=>"",
   "ctd_labels"=>"",
   "ctd_order"=>"",
   "ctd_orientation"=>"",
   "d_calendar_default_value"=>"",
   "ctd_id_type"=>"",
   "ctd_show_range"=>"",
   "ctd_first"=>"FieldLabel",
   "ctd_stored_no"=>"no",
   "ctd_edit_C"=>"1",
   "ctd_show_unit"=>"",
   "ctd_rows"=>"",
   "ctd_cols"=>"",
   "group_header_name"=>"",
   "ctd_date_format"=>""}
      }
    assert_equal(expected, extra, 'Checking values returned in extra')       
    
  end # test_get_extra_form_data
  

  # Tests the check_for_user_entry method.  Tests the following cases:<ol>
  # <li>a row that is an update to an existing field definition;</li>
  # <li>a row with no field_type specified;</li>
  # <li>a row that contains only a field_type and default data; and</li>
  # <li>a row that contains user-entered data.</li></ol>
  # 
  # This method calls set_up_fd_objects to use the current form builder
  # definitions to drive the test.  The intent is that the test will remain
  # valid as changes are made to the form builder definition. It's worth a try.
  #
  def test_check_for_user_entry
  
    # Set up the table description objects for the field_descriptions 
    # table.  We don't actually use the ror_types hash fb_fields array or
    # fb_defs array in this method, but they come with the package.
    fb_fields, fb_defs, fd_tbl_row, ror_types = set_up_fd_objects(150)    
    
    row = Hash.new
    extra = Hash.new
        
    # Test an update to an existing definition
    
    this_field_def = ['1', '2', '3']
    have_data = @controller.check_for_user_entry(this_field_def, row, 
                                                 extra, fd_tbl_row)
    assert_equal(true, have_data, 'for update to existing record')
    
    # Test row with field_type missing
    this_field_def = nil
    have_data = @controller.check_for_user_entry(this_field_def, row, 
                                                 extra, fd_tbl_row)
    assert_equal(false, have_data, 'for new record with empty field_type')
         
    # Test when only have a field type and default data
    fd_tbl_row.each do |key, value|
      if !value.nil?
        if key[0,4] == 'ctd_' || key[0,2] == 'd_'
          extra[key] = value
        else
          row[key] = value
        end
      end
    end
    row['field_type'] = 'something'
    have_data = @controller.check_for_user_entry(this_field_def, row, 
                                                 extra, fd_tbl_row)
    assert_equal(false, have_data, 'for new record with only default values')
    
    # Test when actually have data
    row['something else'] = 'a value'
    have_data = @controller.check_for_user_entry(this_field_def, row, 
                                                 extra, fd_tbl_row)
    assert_equal(true, have_data, 'for new record with data')
     
  end # test_check_for_user_entry

  
  # Tests the do_excludes method.  Tests every field named in the
  # form_builder_maps table against every field type currently 
  # processed by the form builder.
  # 
  # This method copies the predefined_fields and form_builder_maps tables
  # from the current development database and uses them to drive the test.
  # The intent is that as more field types are added to the form builder,
  # the additions to predefined_fields and form_builder_maps will cause 
  # the new types to be tested.
  # 
  # It's worth a try.
  #
  def test_do_excludes
  
    # Copy the predefined_fields table from the development database,
    # so we can use what's currently defined.
    copyDevelopmentTables(['predefined_fields', 'form_builder_maps'])
    
    # create a master hash for the row and extra hashes that contains
    # dummy data for each field in the map table
    
    m_row = Hash.new
    m_extra = Hash.new
    
    FormBuilderMap.find_each do |mp|
      if mp.field_name[0,4] == 'ctd_' || mp.field_name[0,2] == 'd_'
        m_extra[mp.field_name] = 'extra data'
      else
        m_row[mp.field_name] = 'row data'
      end
    end
    
    # Now get an exclusions hash
    exclusions = FormBuilderMap.get_exclusions_hash(true)
    
    # Process each field type used by the form builder
    
    fb_field_types = PredefinedField.where(form_builder: true).to_a
    fb_field_types.each do |ft|
      row = m_row.clone
      extra = m_extra.clone
      row['field_type'] = ft.field_type
      row['target_field'] = 'a_' + ft.fb_map_field
      row, extra = @controller.do_excludes(exclusions, row, extra)
      
      # check each field in the map table to see if it should or 
      # shouldn't be kept for the current field type.  Then check
      # to see if it was or wasn't.
      
      FormBuilderMap.find_each do |mp|
        keep = mp.send(ft.fb_map_field.downcase.to_sym)
        msg = ft.field_type + ':  ' + mp.field_name
        if mp.field_name[0,4] == 'ctd_' || mp.field_name[0,2] == 'd_'
          if keep
            assert_not_nil(extra[mp.field_name], msg)
          else
            assert_nil(extra[mp.field_name], msg)
          end
        else
          if keep
            assert_not_nil(row[mp.field_name], msg)
          else
            assert_nil(row[mp.field_name], msg)
          end
        end # end if appears in extra or row
      end # end do for each field in the map table
    end # end do for each field type handled by the form builder
  
  end # test_do_excludes

  
  # Tests the create_extra_calendar_fields method.  Tests for:<ol>
  # <li>creation of 2 new fields;</li>
  # <li>correct values in the attributes that are modified from
  #     the list field; and</li>
  # <li>retention of non-list related fields in the copied fields.</li>
  # </ol>
  #  
  def test_create_extra_calendar_fields
  
    # Set up the row containing data for the date field.  At this
    # point it would not have any "extra" fields or anything in
    # control_type_detail.
    
    row = Hash.new
    row['display_order'] = 50
    row['display_name'] = 'A date field'
    row['target_field'] = 'date_field'
    row['control_type'] = 'calendar'
    row['help_text'] = 'some help text'
    row['field_type'] = 'DTM - date/time'
    row['required'] = true
    
    all_fd_rows = Array.new
    all_fd_rows << row
    
    # check the extra field created to see if it exists
    # and has the right attributes
    all_fd_rows = @controller.create_extra_calendar_fields(row, all_fd_rows)
    
    assert(3 == all_fd_rows.length)
    new_row1 = all_fd_rows[1]
    new_row2 = all_fd_rows[2]
    
    assert_equal(row['display_order'], new_row1['display_order'])
    assert_equal(row['display_name'] + ' epoch value', new_row1['display_name'])
    assert_equal(row['target_field'] + '_ET', new_row1['target_field'])
    assert_equal('text_field', new_row1['control_type'])
    assert_equal('class=>(hidden_field)', new_row1['control_type_detail'])
    assert_nil(new_row1['help_text'])
    assert_equal('NM - numeric', new_row1['field_type'])
    assert_equal(false, new_row1['required'])
   
    assert_equal(row['display_order'], new_row2['display_order'])
    assert_equal(row['display_name'] + ' HL7 value', new_row2['display_name'])
    assert_equal(row['target_field'] + '_HL7', new_row2['target_field'])
    assert_equal('text_field', new_row2['control_type'])
    assert_equal('class=>(hidden_field)', new_row2['control_type_detail'])
    assert_nil(new_row2['help_text'])
    assert_equal('DT - date', new_row2['field_type'])
    assert_equal(false, new_row2['required'])
   
  end # test_create_extra_calendar_fields
  
  
  # Tests the create_extra_list_field method.  Tests for:<ol>
  # <li>creation of a new field;</li>
  # <li>correct values in the attributes that are modified from
  #     the list field; and</li>
  # <li>retention of non-list related fields in the copied field.</li>
  # </ol>
  #
  def test_create_extra_list_field
  
    # Copy the predefined_fields table from the development database,
    # so we can use what's currently defined.
    copyDevelopmentTables(['predefined_fields'])
    
    # Set up the row containing data for the list field.  At this
    # point it would not have any "extra" fields or anything in
    # control_type_detail.
    
    row = Hash.new
    row['display_order'] = 50
    row['display_name'] = 'A list field'
    row['target_field'] = 'list_field'
    row['control_type'] = 'text_field'
    row['help_text'] = 'some help text'
    row['field_type'] = 'CNE - coded with no exceptions'
    row['required'] = false
    
    all_fd_rows = Array.new
    all_fd_rows << row
    
    # check the extra field created to see if it exists
    # and has the right attributes
    all_fd_rows = @controller.create_extra_list_field(row, all_fd_rows)
    
    assert(2 == all_fd_rows.length)
    new_row = all_fd_rows[1]
    
    assert_equal(row['display_order'], new_row['display_order'])
    assert_equal(row['display_name'] + ' code', new_row['display_name'])
    assert_equal(row['target_field'] + '_C', new_row['target_field'])
    assert_equal('text_field', new_row['control_type'])
    assert_equal('class=>(hidden_field)', new_row['control_type_detail'])
    assert_nil(new_row['help_text'])
    assert_equal('ST - string data', new_row['field_type'])
    assert_equal(false, new_row['required'])
    
  end # test_create_extra_list_field

  
  # Tests the process_list_field method.  Tests for:<ol>
  # <li>prefetched and search list fields;</li>
  # <li>new and updated list fields;</li>
  # <li>various combinations of list parameter specifications;</li>
  # <li>preservation of any data in the control_type_detail element of
  #     a row hash when process_list_field is invoked; and</li>
  # <li>preservation of non-list parameter specifications in the extra hash
  #     at the conclusion of process_list_field.</li>
  # </ol>
  #
  # The various test elements are group into five different test setups,
  # which are run from five different methods.
  #
  def test_process_list_field
    # update sequence only
    copyDevelopmentTables([])
    
    # Tests for a prefetched list.  Includes tests for a new list field
    # spec as well as an update to an existing one, with and without
    # additional parameters in control_type_detail, and for both the
    # CNE and CWE list types.  Test 1 is for an answer_list list field
    # and test 2 updates an answer_list list field to a text_list list field.
    
    proc_list_fld_test1
    proc_list_fld_test2

    # Tests for a search lists:
    # Tests include new and updated list fields, both CNE and CWE list types,
    # prefetched and search lists, answer_lists and text_lists, other list
    # sources, and various combinations of specifications.
    
    proc_list_fld_test3
    proc_list_fld_test4
    proc_list_fld_test5
    
  end # test_process_list_field
  
  
  # Tests the process_extra_fields method.  Tests for each field type,
  # since the extra parameters vary by field type.
  # The things that we need to make sure are working are:<ol>
  #
  # <li>if the control_type_detail element of the row hash already has
  #     data in it, that data is preserved when process_extra_fields is
  #     called;</li>
  # <li>all parameters in the extra hash are accounted for;</li>
  # <li>parameters in the extra hash that should not be transferred to
  #     the control_type_detail element are not;</li>
  # <li>default values are written correctly; and</li>
  # <li>field types are written correctly.</li></ol>
  #
  # The method loads the data specific to a field type into a simulated
  # "extra" hash and calls other (private) methods to actually test the
  # process_extra_fields method and test the outcomes.   
  #
  # As new field_types are implemented in the form builder, data for them
  # should be added to this method.
  #  
  def test_process_extra_fields

    # Test parameters used for checkboxes (display-only and input capable)
    extra = Hash.new   
    extra['ctd_stored_yes'] = 'keep'
    extra['ctd_stored_no'] = 'delete'
    extra['d_check_box_default_value'] = 'keep'    
    extra['ctd_place'] = 'in_hdr'
    extra['ctd_first'] = 'FieldLabel'
    extra['ctd_class_hidden'] = 'hidden_field'
    extra['ctd_edit'] = '3'
    test_extras('Check Box', 'check_box', extra, 'd_check_box_default_value')
        
    # Test parameters used for list fields (CNE and CWE)
    
    # Load the list-specific parameters to the preload hash, which will
    # be preloaded into the control_type_detail parameter before 
    # process_extra_fields is called.
    preload = Hash['search_table'=>'table_name', 
                   'fields_displayed'=>'(field_one,field_two,field_three)' ,
                   'fields_searched'=>'(field_two,field_three)', 
                   'order'=>'(field_three)', 'auto'=>'1',
                   'data_req_output'=>'{code=>test_list_id}',
                   'match_list_value'=>'true']
    extra = extra.clear                               
    extra['d_text_field_default_value'] = 'a default selection' 
    extra['ctd_edit'] = 'Always editable'
    extra['ctd_edit_C'] = '2'
    extra['ctd_display_size'] = '30'     
    test_extras('CWE - coded with exceptions', 'search_field', extra, 
                'd_text_field_default_value', preload)
        
    # Test parameters used for coded fields (CX)
    extra = extra.clear    
    extra['ctd_id_type'] = 'social security number'
    extra['d_text_field_default_value'] = 'a default coded value' 
    extra['ctd_edit'] = 'Not editable'
    extra['ctd_edit_C'] = '1'
    extra['ctd_display_size'] = '15'  
    extra['regex_validator'] = 'a regex validator name'
    test_extras('CX - extended composite ID with check digit', 'text_field',
                extra, 'd_text_field_default_value')  
                
    # Test parameters used for date fields (DT & DTM)
    extra = extra.clear    
    extra['ctd_abs_min'] = '6/15/08'
    extra['ctd_abs_max'] = '8/15/08'
    extra['ctd_date_format'] = 'MMYYDD'
    extra['ctd_calendar'] = 'no'
    extra['d_calendar_default_value'] = '20080813'
    extra['ctd_edit'] = 'Always editable'
    extra['ctd_edit_C'] = '2'
    test_extras('DTM - date/time)', 'calendar', extra, 
                'd_calendar_default_value')
    
               
    # Test parameters used for group headers
    extra = extra.clear     
    extra['ctd_orientation'] = 'horizontal'
    extra['ctd_labels'] = 'label'
    extra['ctd_open'] = '0'
    extra['ctd_class_no_group_hdr'] = 'NO'
    test_extras('Group Header', 'group_hdr', extra)
    
    # Test parameter (!) used for display_only fields
    extra = extra.clear      
    extra['d_static_text_default_value'] = 'Here\'s some static text to be ' +
          'displayed on a form.  We store it in the default value field, ' +
          'the field is there and it\s not used in the traditional way for ' +
          'display-only fields.'
    test_extras('Label/Display Only', 'static_text', extra, 
                'd_static_text_default_value')
    
    # Test parameters used for numeric fields (NM & NM+)
    extra = extra.clear      
    extra['regex_validator'] = 'a regex validator name'    
    extra['ctd_abs_min'] = 5
    extra['ctd_abs_max'] = 10
    extra['ctd_disp_min'] = 6
    extra['ctd_disp_max'] = 8
    extra['ctd_show_range'] = 'yes'
    extra['ctd_show_unit'] = 'no' 
    extra['d_text_field_default_value'] = '123.4'
    extra['ctd_edit'] = 'Always editable'
    extra['ctd_edit_C'] = '2'
    extra['ctd_display_size'] = '10'      
    test_extras('NM+ - numeric with units', 'text_field', extra, 
                'd_text_field_default_value')
                
    # Test parameters used for string fields (ST)
    extra = extra.clear
    extra['regex_validator'] = 'a regex validator name'
    extra['d_text_field_default_value'] = 'a default value for a text field.'
    extra['ctd_edit'] = 'Always editable'
    extra['ctd_edit_C'] = '2'
    extra['ctd_display_size'] = '30'
    test_extras('ST - string data', 'text_field', extra, 
                'd_text_field_default_value')    
    
    # Test parameters used for text fields (TX)
    extra = extra.clear
    extra['d_text_area_default_value'] = 'lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  ' +
          'lots of text.  lots of text.  lots of text.  lots of text.  '
    extra['ctd_edit'] = 'New records only'
    extra['ctd_edit_C'] = '3'
    extra['ctd_rows'] = 4
    extra['ctd_cols'] = 80
    extra['ctd_class_hidden'] = 'hidden_field'
    test_extras('TX - text data', 'text_area', extra, 
                'd_text_area_default_value')
    
    # ADD OTHER FIELD TYPES HERE as they are implemented

  end # test_process_extra_fields
  
  
  # Tests the to_formatted_s method to make sure it handles various
  # input types correctly.  Not particularly complex, but it's important
  # to be sure it's working.
  #
  def test_to_formatted_s
  
    avar = 'a variable'
    
    str = @controller.to_formatted_s('This is a simple string' + 
                      " that includes " + avar + ' embedded in it.') 
    assert_equal(str,
          'This is a simple string that includes a variable embedded in it.')
     
    ary = Array['This is an array', 'that includes', avar, 'embedded in it.']
    assert_equal('This is an array that includes a variable embedded in it.',
          @controller.to_formatted_s(ary, false, ' '))
          
    hsh = {'This is a'=>'hash', 'that includes'=>avar, 'embedded'=>'in it.'}
    assert_equal('{This is a=>hash,that includes=>a variable,embedded=>in it.}',
                 @controller.to_formatted_s(hsh))
                 
    int = 123456789
    assert_equal('123456789', @controller.to_formatted_s(int))
    
    flt = 12345.789
    assert_equal('12345.789', @controller.to_formatted_s(flt))
    
    bool = false
    assert_equal('false', @controller.to_formatted_s(bool))
    
  end # test_to_formatted_s
    

  private #############  Private Methods ##########################
  
  # This method verifies the acquistion of one control type detail (ctd)
  # parameter from a field definition object.
  #
  # Parameters:
  # * targ_field - the name of the form field to receive the data
  # * fd_object - the field definition object that contains the 
  #   ctd parameter to be acquired
  # * param_name - name of the parameter as it appears in the 
  #   control type detail column of the field definition object.  
  #   Specify ONLY if it differs from targ_field with the ctd_
  #   stripped from the front.
  #
  # Returns: nothing
  #
  def check_one_ctd_field_load(targ_field, fd_object, param_name=nil)
    
    grp_hash = Hash.new
    # Clone the controls_hash, because the load_ctd_field method deletes things
    # from the hash it is passed.
    these_params = fd_object.controls_hash.clone
    if param_name.nil?
      param_name = targ_field[4..-1]
    end
    grp_hash, these_params = @controller.load_ctd_field(targ_field, grp_hash,
                                                        these_params)
                                                        
    # Test to see that the right value got transferred to the group hash
    check_params = fd_object.controls_hash

    if (param_name == 'search_table')
      if !check_params['search_table'].nil? &&
       check_params['search_table'] == 'text_lists'
        if !check_params['match_list_value'].nil? &&
           check_params['match_list_value'] == 'true'
          check_params[param_name] = 
            @controller.get_text_list_val(fd_object, check_params[param_name])
        else
          list_val = get_text_list_val(fd_object, check_params[param_name])
          if !list_val.nil?
            check_params[param_name] = list_val
          end
        end # if the value must come from the list or may vary
      end # if this parameter comes from a text_list
    end # if we're looking for the search table stuff
    
    if param_name == 'class' && targ_field == 'ctd_class_no_group_hdr'
      if !check_params['class'].nil? &&
         check_params['class'].include?('no_group_hdr')
        check_params['class'] = 'NO'
      else
        check_params['class'] = 'YES'
      end
    end # if we're looking for the no_group_hdr class parameter

    if !check_params[param_name].nil? && 
       !check_params[param_name].instance_of?(String)
      check_params[param_name] =
            @controller.to_formatted_s(check_params[param_name], false, ', ')
    end # if the parameter needs to be converted to a string
    assert_equal(check_params[param_name], grp_hash[targ_field],
                 'Checking load of ctd parameter to target_field ' + targ_field)
                 
    # Test to see that it got removed from the input parameters hash
    check_params.delete(param_name)
    assert_equal(check_params, these_params, 
                 'Checking removal of parameter ' + param_name + 
                 'from input parameters hash')
  end # check_one_ctd_field_load
     
  
  # This method verifies that a form table row was saved, and with the
  # data we expected.  It is called by the test_store_form_data method.
  #
  # Parameters:
  # * id - the form id
  # * description - the value specified for the form_description.  This
  #                  value is changed between the test for the new row
  #                  and the test for the updated row.
  #
  # Returns:  the forms table row
  #
  def check_form_data(id, description)
  
    # make sure it's there
    fm = Form.find_by_id(id) 
    assert_not_nil(fm, 'Checking that the form was saved')
    
    # make sure that the fields contain what we expect them to contain
    
    assert_equal(description, fm.form_description, 'form_description')
    assert_equal('Monday', fm.form_name, 'form_name')
    assert_equal('Monday\'s test form', fm.form_title, 'form_title')
    assert_equal('form', fm.form_type, 'form_type')
# label_width has been removed
#    assert_equal(8, fm.label_width, 'label_width')
    
    return fm
  end # check_form_data

  
  # This method sets up the fd_tbl_row and ror_types hashes for tests that
  # involve the field_descriptions table.  Specifically, this is needed when
  # storing data to the field_descriptions table.
  #
  # This includes copying the forms and field_descriptions tables from the
  # current development database to the test database, and getting the 
  # field_descriptions table definition, which is written to the 
  # fd_tbl_row and ror_types hashes.
  #
  # Parameters:  
  # * form_id - an id to be set as the current form id
  #
  # Returns:  fd_tbl_row, ror_types
  #
  def set_up_fd_objects(form_id)
  
    # Copy the forms and field_descriptions tables from the development
    # database, so we can use what's currently defined.
    copyDevelopmentTables(['forms', 'field_descriptions'])  
  
    # get the default values defined by the form builder form definition
    # for the field_descriptions columns
    fb_fields, fb_defs = get_fb_fields

    form_tbl_cols = Form.columns
    form_tbl_row  = Hash.new
    ror_types = Hash.new
    form_tbl_cols.each do |fc|
      form_tbl_row[fc.name] = fc.default
      if !fb_defs[fc.name].nil?
        form_tbl_row[fc.name] = fb_defs[fc.name]
      end
      ror_types[fc.name] = fc.type
    end        
    
    # Get the columns defined for the field_descriptions table and 
    # write the defaults defined in the table description to the 
    # columns
    fd_tbl_cols = FieldDescription.columns
    fd_tbl_row = Hash.new
    fd_tbl_cols.each do |tc|
      fd_tbl_row[tc.name] = tc.default
      
      # then if the form defines others, override what came from the table
      # description with what's specific to the form
      if !fb_defs[tc.name].nil?
        fd_tbl_row[tc.name] = fb_defs[tc.name]
      end  

      # get the ruby on rails data type for the field      
      ror_types[tc.name] = tc.type
    end # do for each column in the field_descriptions table
    fd_tbl_row['form_id'] = form_id
    
    return fb_fields, fb_defs, fd_tbl_row, ror_types
    
  end # set_up_fd_objects
  
  
  # This method gets the field definitions for the FormBuilder form
  # and returns a hash of the fields.  It also returns a separate hash
  # of default values for the fields that have them.
  # 
  # Parameters:  none  #
  # Returns:  fb_fields hash and fb_defs hash
  #
  def get_fb_fields
  
    fb_form = Form.where(form_name: 'FormBuilder').take
    fb_vals = FieldDescription.where(form_id: fb_form.id).to_a
    fb_defs = Hash.new
    fb_fields = Hash.new
    fb_vals.each do |fv|
      fb_fields[fv.target_field] = fv
      if (!fv.default_value.nil?)
        fb_defs[fv.target_field] = fv.default_value
      end
    end
    return fb_fields, fb_defs                  
  end # get_fb_fields
  
  
  # This method populates a form object with 4 field definitions:<ol>
  # <li>a check box definition;</li>
  # <li>a cne list field definition;</li>
  # <li>a blank field definition to correspond to the blank line
  #     that is written for a horizontal table whenever the last
  #     existing line is populated; and</li>
  # <li>a blank field description (suffix = 0) that corresponds
  #     to the model row of a horizontal table (and is never 
  #     populated.</li></ol>
  #
  # This is a separate method because it's needed more than once
  # and, although it's in theory one line of code, it's LONG. 
  # This was taken from a dump of a form object from a form.  Fields
  # related to the form part of the definition have been removed.  
  #
  # Parameters: none
  # Returns: the form object
  #
  def make_field_defs_object
  
    fe = {"target_field_0"=>"",
          "supported_ft_1"=>"true" , 
          "ctd_tooltip_1_1_1"=>"a tooltip for a check box",
          "d_check_box_default_value_1_1_1"=>"yes",
          "ctd_abs_min_1_1_1"=>"",
          "ctd_orientation_2_1_1"=>"",
          "ctd_show_unit_2_1_1"=>"",
          "required_1_1_1"=>"No",
          "target_field_1"=>"a_check_box",
          "d_text_area_default_value_3_1_1"=>"",
          "regex_validator_id_2_1_1"=>"",
          "regex_validator_id_0_1_1"=>"",
          "ctd_disp_max_3_1_1"=>"",
          "ctd_disp_max_1_1_1"=>"",
          "help_text_1_1_1"=>"help text for a <em>check box</em>",
          "ctd_rows_0_1_1_1"=>"",
          "target_field_2"=>"a_cne_field",
          "ctd_order_3_1_1"=>"",
          "d_static_text_default_value_0_1_1"=>"",
          "ctd_labels_1_1_1"=>"",
          "max_responses_1_1_1"=>"",
          "ctd_id_type_3_1_1"=>"",
          "ctd_stored_yes_0_1_1"=>"yes",
          "control_type_0"=>"",
          "predefined_field_id_0"=>"",
          "ctd_show_range_0_1_1"=>"",
          "ctd_search_tbl_name_1_1_1"=>"",
          "target_field_3"=>"",
          "ctd_class_no_group_hdr_1_1_1"=>"",
          "ctd_display_size_0_1_1"=>"",
          "ctd_open_0_1_1"=>"",
          "regex_validator_1_1_1"=>"",
          "ctd_cols_0_1_1_1"=>"",
          "control_type_1"=>"check_box",
          "predefined_field_id_1"=>"27",
          "instructions_3_1_1"=>"",
          "control_type_2"=>"search_field",
          "list_code_column_0_1_1"=>'',
          "list_code_column_1_1_1"=>'',
          "list_code_column_2_1_1"=>'id',
          "supported_ft_2"=>"true" ,
          "ctd_fields_displayed_1_1_1"=>"",
          "ctd_list_details_id_2_1_1"=>"425",
          "predefined_field_id_2"=>"18",
          "ctd_rows_3_1_1_1"=>"",
          "ctd_first_2_1_1"=>"FieldLabel",
          "control_type_3"=>"",
          "field_description_id_0"=>"",
          "predefined_field_id_3"=>"",
          "ctd_abs_min_3_1_1"=>"",
          "ctd_calendar_2_1_1"=>"",
          "required_3_1_1"=>"",
          "d_check_box_default_value_3_1_1"=>"no",
          "field_description_id_1"=>"",
          "d_text_field_default_value_1_1_1"=>"",
          "help_text_3_1_1"=>"",
          "field_id_0"=>"",
          "d_text_area_default_value_0_1_1"=>"",
          "ctd_tooltip_3_1_1"=>"",
          "ctd_abs_max_1_1_1"=>"",
          "ctd_date_format_1_1_1"=>"",
          "field_description_id_2"=>"",
          "field_id_1"=>"",
          "units_of_measure_1_1_1"=>"",
          "group_header_name_1_1_1"=>"",
          "field_description_id_3"=>"",
          "ctd_cols_3_1_1_1"=>"",
          "field_id_2"=>"",
          "d_static_text_default_value_2_1_1"=>"",
          "max_responses_3_1_1"=>"",
          "ctd_stored_yes_2_1_1"=>"yes",
          "ctd_class_no_group_hdr_3_1_1"=>"",
          "field_id_3"=>"",
          "ctd_edit_1_1_1"=>"Always editable",
          "ctd_labels_3_1_1"=>"",
          "ctd_show_range_2_1_1"=>"",
          "ctd_open_2_1_1"=>"",
          "regex_validator_3_1_1"=>"",
          "ctd_display_size_2_1_1"=>"18",
          "ctd_fields_displayed_3_1_1"=>"",
          "ctd_search_tbl_name_3_1_1"=>"",
          "ctd_disp_min_0_1_1"=>"",
          "ctd_edit_C_1_1_1"=>"1",
          "ctd_orientation_1_1_1"=>"",
          "control_type_detail_0"=>"",
          "ctd_tooltip_0_1_1"=>"",
          "d_check_box_default_value_0_1_1"=>"no",
          "ctd_disp_max_0_1_1"=>"",
          "help_text_0_1_1"=>"",
          "display_name_0"=>"",
          "ctd_show_unit_1_1_1"=>"",
          "group_header_id_1_1_1"=>"",
          "control_type_detail_1"=>"stored_no=>no,stored_yes=>yes,edit=>1," +
                                   "first=>CheckBox," +
                                   "tooltip=>a tooltip for a check box",
          "ctd_rows_2_1_1_1"=>"",
          "d_text_area_default_value_2_1_1"=>"",
          "display_name_1"=>"a check box",
          "control_type_detail_2"=>"",
          "ctd_stored_no_1_1_1"=>"no",
          "d_text_field_default_value_3_1_1"=>"",
          "ctd_order_0_1_1"=>"",
          "ctd_abs_max_3_1_1"=>"",
          "group_header_name_3_1_1"=>"",
          "ctd_fields_searched_1_1_1"=>"",
          "ctd_cols_2_1_1_1"=>"",
          "display_name_2"=>"a cne field",
          "control_type_detail_3"=>"",
          "ctd_date_format_3_1_1"=>"",
          "units_of_measure_3_1_1"=>"",
          "ctd_id_type_0_1_1"=>"",
          "display_name_3"=>"",
          "ctd_search_tbl_name_0_1_1"=>"",
          "instructions_0_1_1"=>"",
          "d_calendar_default_value_1_1_1"=>"",
          "instructions_2_1_1"=>"",
          "ctd_edit_3_1_1"=>"Always editable",
          "ctd_edit_C_3_1_1"=>"1",
          "ctd_abs_min_0_1_1"=>"",
          "ctd_disp_min_2_1_1"=>"",
          "ctd_orientation_3_1_1"=>"",
          "regex_validator_id_1_1_1"=>"",
          "required_0_1_1"=>"",
          "d_text_field_default_value_0_1_1"=>"",
          "ctd_disp_max_2_1_1"=>"",
          "d_check_box_default_value_2_1_1"=>"no",
          "help_text_2_1_1"=>"help text for a <strong>cne field</strong>",
          "ctd_tooltip_2_1_1"=>"a tool tip for a cne field",
          "group_header_id_3_1_1"=>"", 
          "ctd_date_format_0_1_1"=>"",
          "ctd_abs_max_0_1_1"=>"",
          "ctd_order_2_1_1"=>"term_icd9_code only",
          "ctd_show_unit_3_1_1"=>"",
          "group_header_name_0_1_1"=>"",
          "units_of_measure_0_1_1"=>"",
          "ctd_stored_no_3_1_1"=>"no",
          "ctd_fields_searched_3_1_1"=>"",
          "ctd_class_no_group_hdr_0_1_1"=>"",
          "max_responses_0_1_1"=>"",
          "ctd_stored_yes_1_1_1"=>"yes",
          "ctd_labels_0_1_1"=>"",
          "ctd_show_range_1_1_1"=>"",
          "ctd_id_type_2_1_1"=>"",
          "ctd_fields_displayed_0_1_1"=>"",
          "ctd_display_size_1_1_1"=>"",
          "regex_validator_0_1_1"=>"",
          "ctd_edit_C_0_1_1"=>"1",
          "ctd_search_tbl_name_2_1_1"=>"Problems,Gopher",
          "d_calendar_default_value_3_1_1"=>"",
          "field_type_0"=>"",
          "ctd_first_1_1_1"=>"CheckBox",
          "ctd_list_details_id_1_1_1"=>"",
          "ctd_calendar_1_1_1"=>"",
          "field_type_1"=>"Check Box",
          "group_header_id_0_1_1"=>"",
          "ctd_abs_min_2_1_1"=>"",
          "ctd_rows_1_1_1_1"=>"",
          "ctd_stored_no_0_1_1"=>"no",
          "field_type_2"=>"CNE - coded with no exceptions",
          "ctd_abs_max_2_1_1"=>"",
          "d_text_field_default_value_2_1_1"=>"Harriet",
          "required_2_1_1"=>"YES",
          "regex_validator_id_3_1_1"=>"",
          "ctd_fields_searched_0_1_1"=>"",
          "units_of_measure_2_1_1"=>"",
          "ctd_date_format_2_1_1"=>"",
          "group_header_name_2_1_1"=>"",
          "field_type_3"=>"",
          "d_static_text_default_value_1_1_1"=>"",
          "ctd_cols_1_1_1_1"=>"",
          "ctd_labels_2_1_1"=>"",
          "max_responses_2_1_1"=>"",
          "ctd_stored_yes_3_1_1"=>"yes",
          "d_static_text_default_value_3_1_1"=>"",
          "d_calendar_default_value_0_1_1"=>"",
          "ctd_edit_0_1_1"=>"Always editable",
          "ctd_open_1_1_1"=>"",
          "regex_validator_2_1_1"=>"",
          "ctd_edit_C_2_1_1"=>"1",
          "ctd_class_no_group_hdr_2_1_1"=>"",
          "ctd_show_range_3_1_1"=>"",
          "ctd_disp_min_1_1_1"=>"",
          "ctd_orientation_0_1_1"=>"",
          "ctd_fields_displayed_2_1_1"=>"BOTH",
          "ctd_list_details_id_3_1_1"=>"",
          "ctd_display_size_3_1_1"=>"",
          "group_header_id_2_1_1"=>"",
          "ctd_calendar_3_1_1"=>"",
          "ctd_first_3_1_1"=>"FieldLabel",
          "display_order_0"=>"",
          "ctd_order_1_1_1"=>"",
          "d_text_area_default_value_1_1_1"=>"",
          "ctd_show_unit_0_1_1"=>"",
          "display_order_1"=>"1",
          "ctd_stored_no_2_1_1"=>"no",
          "ctd_fields_searched_2_1_1"=>"primary_name,synonyms & word_synonyms",
          "display_order_2"=>"6",
          "ctd_id_type_1_1_1"=>"",
          "instructions_1_1_1"=>"",
          "ctd_calendar_0_1_1"=>"",
          "d_calendar_default_value_2_1_1"=>"",
          "ctd_edit_2_1_1"=>"Always editable",
          "display_order_3"=>"",
          "ctd_list_details_id_0_1_1"=>"",
          "ctd_first_0_1_1"=>"FieldLabel",
          "ctd_disp_min_3_1_1"=>"",
          "ctd_open_3_1_1"=>""}  
    return fe
  end # make_field_defs_object
  
  
  # This method verifies that a check box field_description row was
  # saved and with the data we expected.  It is called by the 
  # test_store_field_descriptions method.
  #
  # Parameters:
  # * display_name - the value specified for the display_name.  This
  #                  value is changed between the test for the new
  #                  row and the test for the updated row
  #
  # Returns:  the id of the field_descriptions row found for the
  #           check box 
  #
  def check_cb_row(display_name)
  
    # make sure it's there
    cb = FieldDescription.where(form_id: 150, target_field: 'a_check_box').take
    assert_not_nil(cb, 'Checking that check box row was created.')
    
    pdf = PredefinedField.where(field_type: 'Check Box').take
    
    # make sure that the fields, other than the control_type_detail field
    # all contain what we expect them to contain
    
    assert_equal('check_box', cb.control_type, 'check box control_type')
    assert_equal('yes', cb.default_value, 'check box default_value')
    assert_equal(display_name, cb.display_name, 'check box display_name')
    assert_equal(nil, cb.group_header_id, 'check box group_header_id')
    assert_equal('help text for a <em>check box</em>',
                 cb.help_text, 'check box help_text')
    assert_equal(nil, cb.instructions, 'check box instructions')
    assert_equal(0, cb.max_responses, 'check box max_responses')
    assert_equal(pdf.id, cb.predefined_field_id, 
                'check box predefined_field_id')
    assert_equal(nil, cb.regex_validator_id, 'check box regex_validator_id')
    assert_equal(false, cb.required, 'check box required')
    assert_equal(nil, cb.units_of_measure, 'check box units_of_measure')
    
    # check to make sure the control_type_detail parameters that apply to the
    # check box type are there if the user specified them
    assert((cb.control_type_detail.include? "stored_no=>no"),
           'check box control_type_detail stored_no parameter')
    assert((cb.control_type_detail.include? "stored_yes=>yes"),
           'check box control_type_detail stored_yes parameter')    
    assert((cb.control_type_detail.include? "edit=>1"),
           'check box control_type_detail edit parameter')    
    assert((cb.control_type_detail.include? "first=>CheckBox"),
           'check box control_type_detail first parameter')           
    assert((cb.control_type_detail.include? "tooltip=>a tooltip for a " +
            "check box"), 'check box control_type_detail tooltip parameter')

    # Check to make sure the control_type_detail parameters that don't
    # apply to the check box type, or that weren't specified, aren't there
    
    assert(!(cb.control_type_detail.include? "abs_max"),
           'check box control_type_detail abs_max parameter')
    assert(!(cb.control_type_detail.include? "abs_min"),
           'check box control_type_detail abs_min parameter')
    assert(!(cb.control_type_detail.include? "calendar"),
           'check box control_type_detail calendar parameter')
    assert(!(cb.control_type_detail.include? "class"),
           'check box control_type_detail class parameter')
    assert(!(cb.control_type_detail.include? "cols"),
           'check box control_type_detail cols parameter')
    assert(!(cb.control_type_detail.include? "date_format"),
           'check box control_type_detail date_format parameter')
    assert(!(cb.control_type_detail.include? "disp_max"),
           'check box control_type_detail disp_max parameter')
    assert(!(cb.control_type_detail.include? "disp_min"),
           'check box control_type_detail disp_min parameter')
    assert(!(cb.control_type_detail.include? "display_size"),
           'check box control_type_detail display_size parameter')
    assert(!(cb.control_type_detail.include? "edit_C"),
           'check box control_type_detail edit_C parameter')
    assert(!(cb.control_type_detail.include? "fields_displayed"),
           'check box control_type_detail fields_displayed parameter')
    assert(!(cb.control_type_detail.include? "fields_searched"),
           'check box control_type_detail fields_searched parameter')
    assert(!(cb.control_type_detail.include? "id_type"),
           'check box control_type_detail id_type parameter')
    assert(!(cb.control_type_detail.include? "labels"),
           'check box control_type_detail labels parameter')
    assert(!(cb.control_type_detail.include? "list_details_id"),
           'check box control_type_detail list_details_id parameter')
    assert(!(cb.control_type_detail.include? "open"),
           'check box control_type_detail open parameter')
    assert(!(cb.control_type_detail.include? "order"),
           'check box control_type_detail order parameter')
    assert(!(cb.control_type_detail.include? "orientation"),
           'check box control_type_detail orientation parameter')
    assert(!(cb.control_type_detail.include? "rows"),
           'check box control_type_detail rows parameter')
    assert(!(cb.control_type_detail.include? "search_table"),
           'check box control_type_detail search_table parameter')
    assert(!(cb.control_type_detail.include? "show_range"),
           'check box control_type_detail show_range parameter')
    assert(!(cb.control_type_detail.include? "show_unit"),
           'check box control_type_detail show_unit parameter')
    return cb.id
  end # check_cb_row
  
  
  # This method verifies that a CNE field_description row was
  # saved and with the data we expected.  It is called by the 
  # test_store_field_descriptions method.
  #
  # Parameters:
  # * default_value - the value specified for the default_value.  This
  #                   value is changed between the test for the new
  #                   row and the test for the updated row  
  #
  # Returns:  the id of the field_descriptions row found for the
  #           CNE field 
  #
  def check_cne_row(default_value)
  
    # make sure it's there
    cne = FieldDescription.where(form_id: 150, target_field: 'a_cne_field').take
    assert_not_nil(cne, 'Checking that cne row was created.')
    
    pdf = PredefinedField.where(field_type: 'CNE - coded with no exceptions').take
    
    # make sure that the fields, other than the control_type_detail field
    # all contain what we expect them to contain
    
    assert_equal('search_field', cne.control_type, 'cne control_type')
    assert_equal(default_value, cne.default_value, 'cne default_value')
    assert_equal('a cne field', cne.display_name, 'cne display_name')
    assert_equal(nil, cne.group_header_id, 'cne group_header_id')
    assert_equal('help text for a <strong>cne field</strong>',
                 cne.help_text, 'cne help_text')
    assert_equal(nil, cne.instructions, 'cne instructions')
    assert_equal(0, cne.max_responses, 'cne max_responses')
    assert_equal(pdf.id, cne.predefined_field_id, 
                'cne predefined_field_id')
    assert_equal(nil, cne.regex_validator_id, 'cne regex_validator_id')
    assert_equal(true, cne.required, 'cne required')
    assert_equal(nil, cne.units_of_measure, 'cne units_of_measure')
    
    # check to make sure the control_type_detail parameters that apply to the
    # cne type are there if the user specified them.  NOTE that the values
    # for the list parameters are verified by later tests.  Here we're just
    # making sure the parameters are there.
    
    assert((cne.control_type_detail.include? "auto=>1"),
           'cne control_type_detail auto parameter')
    assert((cne.control_type_detail.include? "display_size=>18"),
           'cne control_type_detail display_size parameter')           
    assert((cne.control_type_detail.include? "edit=>1"),
           'cne control_type_detail edit parameter')    
    assert((cne.control_type_detail.include? "fields_displayed") ,
           'cne control_type_detail fields_displayed parameter')
    assert((cne.control_type_detail.include? "fields_returned"),
           'cne control_type_detail fields_returned parameter')
    assert((cne.control_type_detail.include? "fields_searched"),
           'cne control_type_detail fields_searched parameter')
    assert((cne.control_type_detail.include? "match_list_value=>true"),
           'cne control_type_detail match_list_value parameter')
    assert((cne.control_type_detail.include? "order=>(term_icd9_code)"),
           'cne control_type_detail order parameter')
    assert((cne.control_type_detail.include? "search_table=>gopher_terms"),
           'cne control_type_detail search_table parameter')           
    assert((cne.control_type_detail.include? "tooltip=>a tool tip for a cne"),
           'cne control_type_detail tooltip parameter')
    assert((cne.control_type_detail.include? "list_details_id"),
           'cne control_type_detail list_details_id parameter')
           
    # check to make sure the control_type_detail parameters that don't
    # apply to the cne type, or that weren't specified, aren't there
    assert(!(cne.control_type_detail.include? "abs_max"),
           'cne control_type_detail abs_max parameter')
    assert(!(cne.control_type_detail.include? "abs_min"),
           'cne control_type_detail abs_min parameter')
    assert(!(cne.control_type_detail.include? "calendar"),
           'cne control_type_detail calendar parameter')
    assert(!(cne.control_type_detail.include? "class"),
           'cne control_type_detail class parameter')
    assert(!(cne.control_type_detail.include? "cols"),
           'cne control_type_detail cols parameter')
    assert(!(cne.control_type_detail.include? "date_format"),
           'cne control_type_detail date_format parameter')
    assert(!(cne.control_type_detail.include? "disp_max"),
           'cne control_type_detail disp_max parameter')
    assert(!(cne.control_type_detail.include? "disp_min"),
           'cne control_type_detail disp_min parameter')
    assert(!(cne.control_type_detail.include? "edit_C"),
           'cne control_type_detail edit_C parameter')
    assert(!(cne.control_type_detail.include? "first"),
           'cne control_type_detail first parameter')                    
    assert(!(cne.control_type_detail.include? "id_type"),
           'cne control_type_detail id_type parameter')
    assert(!(cne.control_type_detail.include? "labels"),
           'cne control_type_detail labels parameter')
    assert(!(cne.control_type_detail.include? "open"),
           'cne control_type_detail open parameter')
    assert(!(cne.control_type_detail.include? "orientation"),
           'cne control_type_detail orientation parameter')
    assert(!(cne.control_type_detail.include? "rows"),
           'cne control_type_detail rows parameter')
    assert(!(cne.control_type_detail.include? "show_range"),
           'cne control_type_detail show_range parameter')
    assert(!(cne.control_type_detail.include? "show_unit"),
           'cne control_type_detail show_unit parameter')
    assert(!(cne.control_type_detail.include? "stored_no"),
           'cne control_type_detail stored_no parameter')
    assert(!(cne.control_type_detail.include? "stored_yes"),
           'cne control_type_detail stored_yes parameter')   
    return cne.id
  end # check_cne_row
  
  
  # This method verifies that a CNE code field_description row was
  # saved and with the data we expected.  It is called by the 
  # test_store_field_descriptions method.
  #
  # Returns:  the id of the field_descriptions row found for the
  #           CNE code field
  #  
  def check_cne_code_row
  
    # make sure it's there
    cd = FieldDescription.where(form_id: 150, target_field: 'a_cne_field_C').take
    assert_not_nil(cd, 'Checking that cne code row was created.')
    
    pdf = PredefinedField.where(field_type: 'ST - string data').take
    
    # make sure that the fields, including the control_type_detail field
    # all contain what we expect them to contain.  
    
    assert_equal('text_field', cd.control_type, 'cne code control_type')
    assert_equal(nil, cd.default_value, 'cne code default_value')
    assert_equal('a cne field code', cd.display_name, 'cne code display_name')
    assert_equal(nil, cd.group_header_id, 'cne code group_header_id')
    assert_equal(nil, cd.help_text, 'cne code help_text')
    assert_equal(nil, cd.instructions, 'cne code instructions')
    assert_equal(0, cd.max_responses, 'cne code max_responses')
    assert_equal(pdf.id, cd.predefined_field_id, 
                'cne code predefined_field_id')
    assert_equal(nil, cd.regex_validator_id, 'cne code regex_validator_id')
    assert_equal(false, cd.required, 'cne code NOT required')
    assert_equal(nil, cd.units_of_measure, 'cne code units_of_measure')
    
    assert_equal('class=>(hidden_field)', cd.control_type_detail, 
                 'cne code control_type_detail')
    return cd.id
  end # check_cne_code_row
  
  
  # This method creates an empty set of field definition form fields.
  # It's really separate just to isolate it as a task.
  #
  # Parameters:
  # * fe - the form object to which the form field objects are to be added
  # * num - the suffix number to be used
  #
  # Returns: the updated form field object
  #
  def make_empty_field_def(fe, num)
  
    fe["control_type_" + num.to_s] = ""
    fe["supported_ft_" + num.to_s] = "true"
    fe["control_type_detail_" + num.to_s] = ""		
    fe["ctd_abs_max_" + num.to_s + "_1_1"] = ""		
    fe["ctd_abs_min_" + num.to_s + "_1_1"] = ""		
    fe["ctd_calendar_" + num.to_s + "_1_1"] = ""	
    fe["ctd_class_no_group_hdr_" + num.to_s + "_1_1"] = ""		
    fe["ctd_cols_" + num.to_s + "_1_1_1"] = ""		
    fe["ctd_date_format_" + num.to_s + "_1_1"] = ""		
    fe["ctd_disp_max_" + num.to_s + "_1_1"] = ""		
    fe["ctd_disp_min_" + num.to_s + "_1_1"] = ""		
    fe["ctd_display_size_" + num.to_s + "_1_1"] = ""		
    fe["ctd_edit_" + num.to_s + "_1_1"] = "Always editable"		
    fe["ctd_edit_C_" + num.to_s + "_1_1"] = "1"
    fe["ctd_fields_displayed_" + num.to_s + "_1_1"] = ""
    fe["ctd_fields_searched_" + num.to_s + "_1_1"] = ""
    fe["ctd_first_" + num.to_s + "_1_1"] = "FieldLabel"
    fe["ctd_id_type_" + num.to_s + "_1_1"] = ""
    fe["ctd_labels_" + num.to_s + "_1_1"] = ""
    fe["ctd_list_details_id_" + num.to_s + "_1_1"] = ""
    fe["ctd_open_" + num.to_s + "_1_1"] = ""
    fe["ctd_order_" + num.to_s + "_1_1"] = ""
    fe["ctd_orientation_" + num.to_s + "_1_1"] = ""
    fe["ctd_rows_" + num.to_s + "_1_1_1"] = ""
    fe["ctd_search_tbl_name_" + num.to_s + "_1_1"] = ""
    fe["ctd_show_range_" + num.to_s + "_1_1"] = ""
    fe["ctd_show_unit_" + num.to_s + "_1_1"] = ""
    fe["ctd_stored_no_" + num.to_s + "_1_1"] = "no"
    fe["ctd_stored_yes_" + num.to_s + "_1_1"] = "yes"
    fe["ctd_tooltip_" + num.to_s + "_1_1"] = ""
    fe["d_calendar_default_value_" + num.to_s + "_1_1"] = ""
    fe["d_check_box_default_value_" + num.to_s + "_1_1"] = "no"
    fe["d_static_text_default_value_" + num.to_s + "_1_1"] = ""
    fe["d_text_area_default_value_" + num.to_s + "_1_1"] = ""
    fe["d_text_field_default_value_" + num.to_s + "_1_1"] = ""
    fe["display_name_" + num.to_s] = ""
    fe["display_order_" + num.to_s] = ""
    fe["field_description_id_" + num.to_s] = ""
    fe["field_id_" + num.to_s] = ""
    fe["field_type_" + num.to_s] = ""
    fe["group_header_id_" + num.to_s + "_1_1"] = ""
    fe["group_header_name_" + num.to_s + "_1_1"] = ""
    fe["help_text_" + num.to_s + "_1_1"] = ""
    fe["instructions_" + num.to_s + "_1_1"] = ""
    fe["max_responses_" + num.to_s + "_1_1"] = ""
    fe["predefined_field_id_" + num.to_s] = ""
    fe["regex_validator_" + num.to_s + "_1_1"] = ""
    fe["regex_validator_id_" + num.to_s + "_1_1"] = ""
    fe["required_" + num.to_s + "_1_1"] = ""
    fe["target_field_" + num.to_s] = ""
    fe["units_of_measure_" + num.to_s + "_1_1"] = ""

    return fe
  end # make_empty_field_def
  
  # This method executes one test case for the process_list_fields
  # method.  Items being tested here are:<ol>
  # 
  # <li>entering a new prefetched list field;</li>
  # <li>one parameter already loaded to control_type_detail;</li>
  # <li>addition of the match_list_value parameter for CNE field type; and</li>
  # <li>other parameters in the extra hash.
  # 
  # Parameters:  none
  # Returns: nothing
  #
  def proc_list_fld_test1
  
    # create the list for this test
    t1_id = ListDetail.create!(
      :display_name => 'HIV-SSC - HIV-Signs and Symptoms Checklist' ,
      :control_type_template => 'search_table=>answer_lists,list_id=>396,' +
                                'prefetch=>true,' +
                                'fields_displayed=>(answer_text),auto=>1,' +
                                'data_req_output=>{answer_id=>_C}' ,
      :id_column => 'answer_text' ,
      :text_column => 'answer_text' ,
      :hl7_id => 99494 ,
      :id_header => nil ,
      :text_header => nil )
      
    # load the row hash
    row = Hash.new
    row['field_type'] = 'CNE - coded with no exceptions'
    row['target_field'] = 'new_prefetched'
    row['control_type_detail'] = 'existing_param=>test_value'
      
    # load the extra hash
    extra = Hash.new
    extra['other_param1'] = 'other parameter 1'
    extra['other_param2'] = ['other', 'parameter', '2']
    extra['ctd_search_tbl_name'] = 'HIV-SSC - HIV-Signs and Symptoms ' +
                                     'Checklist'
    extra['ctd_list_details_id'] = t1_id

    # load the ctd hash with the expected contents of the
    # the control_type_detail string
    ctd = Hash.new
    ctd['existing_param'] = 'test_value'
    ctd['search_table'] = 'answer_lists'
    ctd['list_id'] = '396'
    ctd['prefetch'] = 'true'
    ctd['fields_displayed'] = '(answer_text)'
    ctd['auto'] = '1'
    ctd['data_req_output'] = '{answer_id=>new_prefetched_C}'
    ctd['match_list_value'] = 'true'
    ctd['list_details_id'] = t1_id

    # and test        
    test_list_field(row, extra, ctd)
    
  end # proc_list_fld_test1
  

  # This method executes one test case for the process_list_fields
  # method.  Items being tested here are:<ol>
  # 
  # <li>updating an existing prefetched list field;</li>
  # <li>moving from an answer_list to a text_list;</li>
  # <li>control_type_detail contains list field specifications from before the
  #     update as well as other parameters;</li>
  # <li>omission of the match_list_value parameter for CWE field type; and</li>
  # <li>other parameters in the extra hash.
  # 
  # Parameters:  none
  # Returns: nothing
  #
  def proc_list_fld_test2
  
    # create the list for this test
    t2_id = ListDetail.create(
      :display_name => 'ICD9 diseases with synonyms' ,
      :control_type_template => 'extra_parameter=>one,' +
                                'search_table=>text_lists,prefetch=>true,' +
                                'list_name=>ICD9 with Synonyms,auto=>1,' + 
                                'data_req_output=>{code=>_C},' +
                                'another_param=>two',
      :id_column => 'item_text' ,
      :text_column => 'item_text' ,
      :hl7_id => 99409 ,
      :id_header => nil,
      :text_header => nil)
      
    # load the row hash
    row = Hash.new
    row['field_type'] = 'CWE - coded with exceptions'
    row['target_field'] = 'existing_prefetched'
    row['control_type_detail'] = 'extra_parameter=>one,' +
                                 'search_table=>answer_lists,list_id=>396,' +
                                 'prefetch=>yadda,' +
                                 'fields_displayed=>(answer_text),auto=>x,' +
                                 'data_req_output=>{answer_id=>' +
                                 'existing_prefetched_C},another_param=>two'
    # load the extra hash
    extra = Hash.new
    extra['other_param1'] = {'other'=>'parameter', 'is'=>'1'}
    extra['other_param2'] = ['other', 'parameter', '2']
    extra['ctd_search_tbl_name'] = 'ICD9 diseases with synonyms'
    extra['ctd_list_details_id'] = t2_id

    # load the ctd hash with the expected contents of the 
    # control_type_detail string
    ctd = Hash.new
    ctd['extra_parameter'] = 'one'
    ctd['another_param'] = 'two'
    ctd['search_table'] = 'text_lists'
    ctd['list_name'] = 'ICD9 with Synonyms'
    ctd['prefetch'] = 'true'
    ctd['auto'] = '1'
    ctd['data_req_output'] = '{code=>existing_prefetched_C}'
    ctd['list_details_id'] = t2_id
    
    # create a dummy field_def object so that the code will recognize this
    # as an update to an existing field definition
    field_def = ['existing def']
    test_list_field(row, extra, ctd, field_def)      
      
  end # proc_list_fld_test2
  

  # This method executes one test case for the process_list_fields
  # method.  Items being tested here are:<ol>
  # 
  # <li>entering a new search list field;</li>
  # <li>one parameter already loaded to control_type_detail;</li>
  # <li>2 fields in the list to be displayed;</li>
  # <li>one field chosen for fields_displayed;</li>
  # <li>addition of the match_list_value parameter for CNE field type; and</li>
  # <li>other parameters in the extra hash.
  # 
  # Parameters:  none
  # Returns: nothing
  #
  def proc_list_fld_test3
  
    # create the list for this test
    t3_id = ListDetail.create(
      :display_name => 'ICD9 without procedures' ,
      :control_type_template => 'search_table=>icd9_codes,' +
                                'conditions=>is_procedure:false,' +
                                'fields_displayed=>(code,description),' +
                                'fields_searched=>(code,description),' +
                                'fields_returned=>(code),auto=>1,' +
                                'data_req_output=>{code=>_C},' +
                                'just_another=>gratuitous_parameter',
      :id_column => 'code' ,
      :text_column => 'description' ,
      :hl7_id => 99705 ,
      :id_header => 'Code' ,
      :text_header => 'Description' )
      
    # load the row hash
    row = Hash.new
    row['field_type'] = 'CNE - coded with no exceptions'
    row['target_field'] = 'new_search'
      
    # load the extra hash
    extra = Hash.new
    extra['other_param1'] = 'other parameter 1'
    extra['other_param2'] = ['other', 'parameter', '2']
    extra['ctd_search_tbl_name'] = 'ICD9 without procedures'
    extra['ctd_list_details_id'] = t3_id
    extra['ctd_fields_displayed'] = 'description only' 
    extra['ctd_order'] = ''
    #extra['ctd_fields_searched'] = '' <- make sure no error if missing.

    # load the ctd hash with the expected contents of the
    # the control_type_detail string
    ctd = Hash.new
    ctd['just_another'] = 'gratuitous_parameter'
    ctd['search_table'] = 'icd9_codes'
    ctd['conditions'] = 'is_procedure:false'
    ctd['fields_displayed'] = '(description)'
    ctd['fields_searched'] = '(description)'
    ctd['fields_returned'] = '(code)'
    ctd['order'] = '(description)'
    ctd['auto'] = '1'
    ctd['data_req_output'] = '{code=>new_search_C}'
    ctd['match_list_value'] = 'true'
    ctd['list_details_id'] = t3_id
    
    # and test        
    test_list_field(row, extra, ctd)
    
  end # proc_list_fld_test3
  

  # This method executes one test case for the process_list_fields
  # method.  Items being tested here are:<ol>
  # 
  # <li>updating an existing search list field;</li>
  # <li>control_type_detail contains list field specifications from before the
  #     update as well as other parameters;</li>
  # <li>2 fields in the list to be displayed;</li>
  # <li>both fields chosen for fields_displayed;</li>
  # <li>omission of the match_list_value parameter for CWE field type; and</li>
  # <li>other parameters in the extra hash.
  # 
   # 
  # Parameters:  none
  # Returns: nothing
  #
  def proc_list_fld_test4
  
    # create the list for this test
    t4_id = ListDetail.create(
      :display_name => 'ICD9 Procedures' ,
      :control_type_template => 'search_table=>icd9_codes,' +
                                'conditions=>is_procedure:true,' +
                                'fields_displayed=>(code,description),' +
                                'fields_searched=>(code,description),' +
                                'fields_returned=>(code),auto=>1,' +
                                'data_req_output=>{code=>_C},' +
                                'just_another=>gratuitous_parameter',
      :id_column => 'code' ,
      :text_column => 'description' ,
      :hl7_id => 99703 ,
      :id_header => 'Code',
      :text_header => 'Description' )
      
    # load the row hash
    row = Hash.new
    row['field_type'] = 'CWE - coded with exceptions'
    row['target_field'] = 'existing_search'
    row['control_type_detail'] = 'extra_parameter=>one,' +
                                 'search_table=>blahicd9_codes,' +
                                 'conditions=>is_procedure:true,' +
                                 'fields_displayed=>(blah,description),' +
                                 'fields_searched=>(blah,description),' +
                                 'fields_returned=>(blah),auto=>1,' +
                                 'data_req_output=>{blah=>existing_search_C},' +
                                 'just_another=>gratuitous_parameter'
    # load the extra hash
    extra = Hash.new
    extra['other_param1'] = {'other'=>'parameter', 'is'=>'1'}
    extra['other_param2'] = ['other', 'parameter', '2']
    extra['ctd_search_tbl_name'] = 'ICD9 Procedures'
    extra['ctd_list_details_id'] = t4_id
    extra['ctd_fields_displayed'] = 'BOTH'
    extra['ctd_order'] = 'description'
    extra['ctd_fields_searched'] = 'BOTH'

    # load the ctd hash with the expected contents of the
    # the control_type_detail string
    ctd = Hash.new
    ctd['just_another'] = 'gratuitous_parameter'
    ctd['extra_parameter'] = 'one'
    ctd['search_table'] = 'icd9_codes'
    ctd['conditions'] = 'is_procedure:true'
    ctd['fields_displayed'] = '(code,description)'
    ctd['fields_searched'] = '(code,description)'
    ctd['fields_returned'] = '(code)'
    ctd['order'] = '(description)'
    ctd['auto'] = '1'
    ctd['data_req_output'] = '{code=>existing_search_C}'
    ctd['list_details_id'] = t4_id
    
    # create a dummy field_def object so that the code will recognize this
    # as an update to an existing field definition
    field_def = ['existing def']
    test_list_field(row, extra, ctd, field_def)      
      
  end # proc_list_fld_test4
  

  # This method executes one test case for the process_list_fields
  # method.  Items being tested here are:<ol>
  # 
  # <li>updating an existing search list field;</li>
  # <li>control_type_detail contains list field specifications from before the
  #     update as well as other parameters;</li>
  # <li>4 fields in the list to be searched;</li>
  # <li>BOTH fields chosen for fields_displayed;</li>
  # <li>addition of the match_list_value parameter for CNE field type; and</li>
  # <li>other parameters in the extra hash.
  # 
  # Parameters:  none
  # Returns: nothing
  #
  def proc_list_fld_test5
  
    # create the list for this test
    t5_id = ListDetail.create(
      :display_name => 'Problems, Gopher' ,
      :control_type_template => 'search_table=>gopher_terms,' +
                                'fields_displayed=>(primary_name,' +
                                'term_icd9_code),fields_searched=>' +
                                '(term_icd9_code,primary_name,synonyms,' +
                                'word_synonyms),fields_returned=>' +
                                '(term_icd9_code),auto=>1,' +
                                'data_req_output=>{key_id=>_C}',
                                
      :id_column => 'term_icd9_code' ,
      :text_column => 'primary_name,synonyms,word_synonyms' ,
      :hl7_id => 99702 ,
      :id_header => 'ICD9 Code',
      :text_header => 'Problem' )
      
    # load the row hash
    row = Hash.new
    row['field_type'] = 'CNE - coded with no exceptions'
    row['target_field'] = 'four_field_search'
    row['control_type_detail'] = 'extra_parameter=>one,' +
                                 'search_table=>blahicd9_codes,' +
                                 'conditions=>is_procedure:true,' +
                                 'fields_displayed=>(blah,description),' +
                                 'fields_searched=>(blah,description),' +
                                 'fields_returned=>(blah),auto=>1,' +
                                 'data_req_output=>{blah=>existing_search_C},' +
                                 'just_another=>gratuitous_parameter'
    # load the extra hash
    extra = Hash.new
    extra['other_param1'] = {'other'=>'parameter', 'is'=>'1'}
    extra['other_param2'] = ['other', 'parameter', '2']
    extra['ctd_search_tbl_name'] = 'Problems, Gopher'
    extra['ctd_list_details_id'] = t5_id
    extra['ctd_fields_displayed'] = 'BOTH'
    extra['ctd_order'] = 'term_icd9_code'
    extra['ctd_fields_searched'] = 'primary_name, synonyms & word_synonyms'

    # load the ctd hash with the expected contents of the
    # the control_type_detail string
    ctd = Hash.new
    ctd['just_another'] = 'gratuitous_parameter'
    ctd['extra_parameter'] = 'one'
    ctd['search_table'] = 'gopher_terms'
    ctd['fields_displayed'] = '(primary_name,term_icd9_code)'
    ctd['fields_searched'] = '(primary_name,synonyms,word_synonyms)'
    ctd['fields_returned'] = '(term_icd9_code)'
    ctd['order'] = '(term_icd9_code)'
    ctd['auto'] = '1'
    ctd['data_req_output'] = '{key_id=>four_field_search_C}'
    ctd['match_list_value'] = 'true'
    ctd['list_details_id'] = t5_id
    
    # create a dummy field_def object so that the code will recognize this
    # as an update to an existing field definition
    field_def = ['existing def']
    test_list_field(row, extra, ctd, field_def)      
      
  end # proc_list_fld_test5
  
      
      
  # This method accepts data for one list field spec and invokes the 
  # process_list_field method on it.  It then checks to see if the
  # data was processed correctly.
  # 
  # This method checks the following things:<ol>
  # <li>that the row hash ends up with the correct number of elements
  #     - which depends on whether or not the control_type_detail
  #       element already existed in the hash when the process_list_field
  #       method was called;</li>
  # <li>that the control_type_detail element in the row hash contains
  #     the expected parameters;</li>
  # <li>that the control_type_detail element in the row hash does not
  #     contain anything else; and</li>
  # <li>that all list-related elements have been removed from the "extra"
  #     hash.
  #
  # This method is called by the test_process_list_field method for each
  # combination of variables we're testing (prefetched versus search lists,
  # multiple versus single list values, etc).
  # 
  # Parameters:
  # * row - hash containing the list-related parameters we want
  #         test
  # * extra - the hash containing the "extra" list-related parameters
  #           we want to test
  # * ctd - hash containing the values we expect to see in the
  #         control_type_detail element of the row 
  # * field_def - simulated field_descriptions row for an existing
  #               list field that is to be updated for the test;
  #               default is nil.  Actually, a dummy array is passed
  #               in, since the process_list_field only checks for a
  #               nil value.  It does nothing with the contents.
  #
  # Returns:  nothing (but an error is thrown for failed assertions)
  #
  def test_list_field(row, extra, ctd, field_def=nil)
    
    expected_row_length = row.length
    if row['control_type_detail'].nil?
      expected_row_length += 1
    end
    
    row, extra = @controller.process_list_field(row, extra, field_def)
       
    # Make sure we have the correct number of parameters in the row hash
    row_msg = 'row parameters are:  '
    row.each do |key, value|
      row_msg += 'row[' + key + '] = ' + 
                 @controller.to_formatted_s(value) + '   '
    end 
    assert_equal(expected_row_length, row.length, row_msg)
    
    # Make sure the control_type_detail element of the row
    # hash contains the elements we're expecting - and only those
    # elements
   
    ctd.each do |key, value|
      row = check_ctd(key, value, row)
    end  # ctd.each
    
    # Make sure there's nothing left in the control_type_detail parameter
    # - that we've checked everything and there are no surprises lurking.
    row['control_type_detail'] = row['control_type_detail'].gsub(',', '')
    assert_equal(0, row['control_type_detail'].length, 
                    'row[control_type_detail] = ' + row['control_type_detail'])
    
    # Make sure that all the list-related parameters have been removed from
    # the extra hash
    assert(extra['ctd_search_tbl_name'].nil?)
    assert(extra['ctd_list_details_id'].nil?)
    assert(extra['ctd_fields_displayed'].nil?)
    assert(extra['ctd_order'].nil?)
    assert(extra['ctd_fields_searched'].nil?)  
                    
  end # test_list_field
  
  
  # This method accepts data for one field type and invokes the 
  # process_extra_fields method on it.  It then checks to see if the
  # data was processed correctly.  If data was specified for preloading
  # to the control_type_detail parameter, it takes care of that too.
  #
  # This method preloads any data specified for preload, and invokes
  # the process_extra_fields method.  On return it checks the default 
  # value and field type transfers, and sets up the data to make sure
  # that any parameters that should have been discarded have been.
  # It then invokes check_ctd to check what actually got loaded to the
  # control_type_detail parameter (and to make sure what was already
  # there wasn't discarded).
  # 
  # Parameters:
  # * field_type - the field type being tested
  # * control_type - control_type for the field type being tested
  # * extra - the hash containing the "extra" parameters for the
  #           field type being tested
  # * default_name - the name of the default parameter for the field
  #                  type being tested, if any
  # * preload - a hash of values that could have been preloaded to the
  #             control_type_detail parameter by the time the 
  #             process_extra_fields method is called
  #
  # Returns:  nothing (but an error is thrown for failed assertions)
  #
  def test_extras(field_type, control_type, extra, 
                  default_name=nil, preload=nil)
    
    row = Hash['field_type'=>field_type, 'control_type'=>control_type]
   
    if !preload.nil?
      row['control_type_detail'] = @controller.to_formatted_s(preload, false)
      @controller.log_this('preload written to row[control_type_detail] = ' +
                            row['control_type_detail'])
    end
      
    row = @controller.process_extra_fields(extra, row)
    
    # Make sure the right default value got written
    if !default_name.nil?
      assert_equal(extra[default_name], row['default_value'])
    end
    
    # Make sure we have the correct number of parameters in the row hash
    row_msg = 'row parameters are:  '
    row.each do |key, value|
      row_msg += 'row[' + key + '] = ' + 
                 @controller.to_formatted_s(value) + '   '
    end 
    if !default_name.nil?
      assert_equal(4, row.length, row_msg)
    else
      assert_equal(3, row.length, row_msg)
    end
    
    # Make sure all the extra fields got written to the control type
    # details parameter.  
    # - If a default value was specified, delete it so that we don't 
    # look for it here.    
    # - If some values were preloaded to that parameter,
    # add them to the extra hash here so that they get checked.
    # - If extra includes any of the parameters that we just drop, 
    #   delete them so that we're not looking for them.  (They shouldn't
    #   be there).
    
    if !default_name.nil?
      extra.delete(default_name)
    end
    if !preload.nil?
      extra = extra.merge(preload)
    end
    if !extra['regex_validator'].nil?
      extra.delete('regex_validator')
    end
    if !extra['group_header_name'].nil?
      extra.delete('group_header_name')
    end
    extra.each do |key, value|
      if key[0,4] == 'ctd_'
        key = key[4, (key.length - 4)]
      end
      if key == 'class_no_group_hdr'
        if value == 'NO'
          key = 'class'
          value = '(no_group_hdr)'
          row = check_ctd(key, value, row)
        end  # (we don't store anything for YES)     
      elsif key[0, 5] == 'class'
        key = 'class'
        value = '(' + value + ')'
        row = check_ctd(key, value, row)
      else
        row = check_ctd(key, value, row)
      end
    end  # extra.each
    
    # Make sure there's nothing left in the control_type_detail parameter
    # - that we've checked everything and there are no surprises lurking.
    row['control_type_detail'] = row['control_type_detail'].gsub(',', '')
    assert_equal(0, row['control_type_detail'].length, 
                    'row[control_type_detail] = ' + row['control_type_detail'])        
  end # test_extras
    

  # This method checks a single parameter to see if it appears in
  # the control_type_detail elemment of a row hash passed in.  If it finds
  # it, it removes it from the control_type_detail element string.  If it
  # doesn't find it the assertion fails and an error is thrown for the test.
  #
  # Parameters:
  # * param - the name of the parameter to be checked
  # * value - the value that the parameter should have
  # * row - the hash containing the control_type_detail element
  #
  # Returns:  the row hash with the parameter and its value removed
  #           OR, if the assertion fails, an error is thrown
  #
  def check_ctd(param, value, row)
    expected = param + '=>' + @controller.to_formatted_s(value)
    assert_equal(expected, row['control_type_detail'].slice!(expected))
    return row
  end # check_ctd
  
    
  # STOLEN from Paul's rule_controller_test.  I stole this and modified
  # it to copy one or more specified tables from the current development
  # database to the test database.  This is useful for tests where you
  # want to use the current contents of a reference table - e.g. the
  # predefined_fields table for test_do_excludes.
  #
  # Parameters:
  # * tables - an array of one or more tables to be copied
  #
  # Returns:  nothing
  #
  def copyDevelopmentTables(tables)
    #tables = ['forms', 'field_descriptions', 'rules', 'rules_forms',
    # 'rule_actions', 'rule_cases', 'rule_dependencies',
    # 'rule_field_dependencies', 'text_lists', 'text_list_items']
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

  
end # formbuilder_controller_test
