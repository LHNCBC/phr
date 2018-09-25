require 'test_helper'

class DataControllerUpdateTest < ActionDispatch::IntegrationTest
  fixtures :users
  fixtures :two_factors

  # Tests the update method
  def test_update
    DatabaseMethod.copy_development_tables_to_test(
      ['action_params', 'forms', 'field_descriptions', 'rules', 'rules_forms',
       'rule_actions', 'rule_cases', 'rule_fetches', 'rule_fetch_conditions',
       'rule_dependencies', 'rule_field_dependencies',
       'text_lists', 'text_list_items', 'rule_action_descriptions',
       'regex_validators', 'db_table_descriptions', 'db_field_descriptions',
       'predefined_fields', 'comparison_operators', 'comparison_operators_predefined_fields'])
  
    https! # Set the request to be SSL

    # Make sure the user is redirected if they are not logged in
    post '/data/update'
    assert_redirected_to('/accounts/login')

    # Make sure the user is redirected to the login page if they are not
    # an admin user.
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:PHR_Test).name,
                            :password_1_1=>'A password'}}
    post '/data/update'
    assert_redirected_to('/accounts/login')

    post '/accounts/logout'

    # Make sure the user can't update a table they aren't allowed to.
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
                            :password_1_1=>'A password'}}
    post '/data/update',
      params: {:update_file=>fixture_file_upload("#{Rails.root}/test/fixtures/data_update_test1.txt")}
    assert_redirected_to('/data')
    follow_redirect!
    assert_equal('Updates of table "forms" are not permitted.',
      flash[:error])

    # Make sure the format parameter does not cause a problem
    get '/data/export/text_list_items.csv?text_list_id=137'
    assert_response :success
  end

end
