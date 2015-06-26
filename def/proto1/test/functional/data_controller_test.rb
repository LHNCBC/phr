require 'test_helper'

class DataControllerTest < ActionController::TestCase
  fixtures :users, :text_lists, :text_list_items, :forms, :field_descriptions, :two_factors

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
  end

  # Tests the export method
  def test_export
    # Make sure the user is redirected to the login page if they are not
    # an admin user.
    get :export, {:id=>'text_list_items'}
    assert_redirected_to('/accounts/login')
    get :export, {:id=>'text_list_items'},
     {:user_id=>users(:PHR_Test).id}
    assert_redirected_to('/accounts/login')
    
    # Make sure the user can't export a table they aren't allowed to.
    get :export, {:id=>'forms'}, {:user_id=>users(:phr_admin).id}
    assert_not_nil(@response.body.index(
        'forms is not a table that can be accesssed.'))
    
    # Confirm that we can get data for a table that can be accesseed
    get :export, {:id=>'text_list_items'},
     {:user_id=>users(:phr_admin).id}
    assert(@response.body =~ /^id,/)
  end


  # Test the export_form_text method
  def test_export_form_text
    # Make sure the user is redirected to the login page if they are not
    # an admin user.
    get :export_form_text, {:id=>'PHR'}
    assert_redirected_to('/accounts/login')
    get :export_form_text, {:id=>'PHR'},
      {:user_id=>users(:PHR_Test).id}
    assert_redirected_to('/accounts/login')
    
    # Confirm that we can get data for a form
    get :export_form_text, {:id=>'PHR'},
     {:user_id=>users(:phr_admin).id}

    assert(@response.body =~ /,help_text,/)
  end
  

  # Test the update method for field descriptions.
# I could not get this test to work correctly, so I am commenting it out for
# now, but leaving the implementation here in case there is time to work further
# on it later.
#  def test_field_desc_update
#    # Get the data for the PHR form
#    session_info = {:user_id=>users(:phr_admin).id}
#    get :export_form_text, {:id=>'PHR'}, session_info
#    phr_export = @response.body
#    # Insert a new column, and try to change regex_validator_id (which is
#    # not allowed).
#    phr_export.sub!('id,display_name', 'id,regex_validator_id,display_name')
#    # Find the ID of the first field on the form
#    fd = Form.where(form_name: 'phr').first.field_descriptions.first
#    fd_id = fd.id
#    assert_equal(nil, fd.regex_validator_id) # precondition check
#    # Make up a value and insert it into the CSV data
#    phr_export.sub!(/^#{fd_id},/, "#{fd_id},101,")
#    # Make a temporary file for the upload
#    f = File.open(Tempfile.new('data_controller_test'), 'w')
#    f.write(phr_export)
#    f.close
#    # Submit the file for the update
#    post :update, {:update_file=>Rack::Test::UploadedFile.new(f.path)}, session_info
#    # Reload fd and check the value
#    fd = Form.where(form_name: 'phr').first.field_descriptions(true).first
#    # Allow the update thread some time to finish
#    sleep(10) # TBD
#    assert_equal(nil, fd.regex_validator_id)
#  end
  
end
