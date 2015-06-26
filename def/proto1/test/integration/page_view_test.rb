require 'test_helper'

# Tests involving page view checks (e.g. Basic HTML vs. standard mode)
class PageViewTest < ActionDispatch::IntegrationTest
  fixtures :users
  fixtures :two_factors

  def test_login_redirect_on_basic_mode
    # Check that if the user requests a basic HTML view, but are not logged in,
    # they get redirected to a basic HTML page, and likewise for the standard
    # mode.
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions', 'db_field_descriptions'])
    https! # Set the request to be SSL

    get '/phr_records' # a basic mode URL
    assert_redirected_to '/accounts/login'
    follow_redirect!
    assert_not_nil @response.body.index('Current page mode:  Basic HTML') # on the bsaic mode login page
  end
  
  def test_login_redirect_on_standard_mode
    # Check that if the user requests a standard HTML view, but are not logged in,
    # they get redirected to a standard HTML page
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions', 'db_field_descriptions'])
    https! # Set the request to be SSL

    get '/profiles' # a standard mode URL
    assert_redirected_to '/accounts/login'
    follow_redirect!
    assert_nil @response.body.index('Current page mode:  Basic HTML') # not on the basic mode login page
  end

end
