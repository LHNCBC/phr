#--
# $Log: form_cache_expiration_test.rb,v $
# Revision 1.40  2011/08/19 00:07:45  plynch
# Changed the paths for the page fragment cache so that it does not depend
# on the hostname with which the website was accessed, so the PassengerPreStart
# URL can start things using 127.0.0.1, and produce usable page fragments.
#
# Revision 1.39  2011/08/08 17:39:47  mujusu
# used 64 char SHA256 generated token
#
# Revision 1.38  2011/06/17 17:20:11  wangye
# remove deleted and empty records in the data model and update mapping tables after a successful save
#
# Revision 1.37  2010/10/29 15:14:11  lmericle
# changes to mirror switch in method for saving registration data - from full page submit to ajax update
#
# Revision 1.36  2010/09/14 23:37:41  taof
# change field name from age to age_group
#
# Revision 1.35  2010/08/25 22:20:58  taof
# add validation to avoid rule name conflict with target_field
#
# Revision 1.34  2010/07/19 20:58:16  mujusu
# added two_factor fixture
#
# Revision 1.33  2010/07/15 18:27:22  mujusu
# added phr_user cookie
#
# Revision 1.32  2010/06/07 18:14:22  taof
# block rule deletion when it's used by others
#
# Revision 1.31  2010/05/11 21:43:07  plynch
# Changes to remove the duplicate sections/tables that now exist as panels,
# plus updates to the tests.
#
# Revision 1.30  2010/04/23 19:01:27  taof
# newly created reminder rule does not show up on phr form until a restart of the server
#
# Revision 1.29  2010/04/21 22:10:08  plynch
# Changed the rule name field on the value rule form to have a target_field
# of rule_name.
#
# Revision 1.28  2010/04/19 08:28:16  taof
# fix bugs in new reminder rule creating/reading/updating/deleting
#
# Revision 1.27  2010/04/06 18:11:37  mujusu
# another cache file created now
#
# Revision 1.26  2010/03/30 22:42:05  plynch
# Changes for the help management pages.
#
# Revision 1.25  2010/03/26 21:56:46  taof
# After a rule changing, user can get updated rules on the form by reload the formcsv
#
# Revision 1.24  2010/03/24 17:30:53  mujusu
# added gender etc
#
# Revision 1.23  2010/03/24 15:24:50  taof
# clear fragment cache when data rule gets updated
#
# Revision 1.22  2010/02/22 17:22:20  lmericle
# modified confirm_phr_cache_cleared function to check explicit location for cached files rather than depending on environment variable that can be changed
#
# Revision 1.21  2010/02/05 22:54:27  taof
# new reminder rule and new value rule forms
#
# Revision 1.20  2010/01/07 19:54:34  lmericle
# added rule_action_descriptions to tables copied from database
#
# Revision 1.19  2009/10/29 23:14:17  taof
# create new fetch rules (rule_type='fetch') to replace old rules
#
# Revision 1.18  2009/10/09 15:34:44  mujusu
# updates since profiles/new disabled
#
# Revision 1.17  2009/08/25 14:42:56  lmericle
# added fetch rule tables to those being copied to test databases
#
# Revision 1.16  2009/08/10 21:32:43  plynch
# Changes needed by the fetch rule page.
#
# Revision 1.15  2009/08/08 00:06:13  wangye
# changes after the save code rewriting
#
# Revision 1.14  2009/07/31 19:27:40  plynch
# Changed routes from /app/phr to /profiles
#
# Revision 1.13  2009/07/24 22:08:40  plynch
# Changed the user data model classes so that they are automatically declared,
# so we don't need those empty model class files.
#
# Revision 1.12  2009/05/11 15:39:37  taof
# bugfix: expire form cache
#
# Revision 1.11  2009/04/14 20:14:14  mujusu
# now 5 files created for cache
#
# Revision 1.10  2009/03/10 17:44:50  mujusu
# RAILS 2.2.2 related change
#
# Revision 1.9  2009/01/27 22:25:54  plynch
# Changes related to moving the ATR tests to the test database.
#
# Revision 1.8  2009/01/27 21:49:43  smuju
# updated test since forms cached in different dir structure
#
# Revision 1.7  2008/09/15 15:50:21  plynch
# Changes made for supporting the phr_index page.
#
# Revision 1.6  2008/08/29 21:39:44  plynch
# Turned caching back on, and added caching of the form layout.
#
# Revision 1.5  2008/08/19 20:29:07  plynch
# Changes to move us over to HTTPS.
#
# Revision 1.4  2008/07/21 14:44:27  wangye
# fixed oracle compatibility bugs
#
# Revision 1.3  2008/07/16 22:57:51  yango
# change the login page test fields
#
# Revision 1.2  2008/07/09 17:04:16  plynch
# Routing changes for the form builder, simplification of what happens
# after a login, and the addition of the beginning of a file for field events.
#
# Revision 1.1  2008/06/04 17:46:47  plynch
# Added code for clearing a form's cache files when the form's rules change.
#
#++


require 'test_helper'

# Tests that the cache files for forms get expired when they should.
class FormCacheExpirationTest < ActionDispatch::IntegrationTest
  fixtures :users
  fixtures :two_factors
  #fixtures :action_params
  #fixtures :db_table_descriptions

 
  # Tests that the cache for a form is expired when its rules are changed
  # via the rule controller.
  def test_expiration_by_rule_change
    tables =
      ['action_params','forms', 'field_descriptions', 'rules', 'rules_forms',
       'rule_actions', 'rule_cases', 'rule_fetches', 'rule_fetch_conditions',
       'rule_dependencies', 'rule_field_dependencies',
       'text_lists', 'text_list_items', 'rule_action_descriptions',
       'regex_validators', 'db_table_descriptions', 'db_field_descriptions',
       'predefined_fields', 'comparison_operators', 
       'comparison_operators_predefined_fields', 'rule_labels',
       'loinc_panels', 'loinc_items'
       ]
    DatabaseMethod.copy_development_tables_to_test(tables)
    
    # Define the user data table model classes (after the db_table_descriptions
    # table is copied above).
    DbTableDescription.define_user_data_models

    # Turn on caching.
    ActionController::Base.perform_caching = true
    
    https! # Set the request to be SSL

    # Now try editing a rule on the PHR form.
    # Note:  In integration tests you don't get to specify the session data
    # along with a put command, and for some reason, it does not seem possible
    # to put things like
    # the user_id into the session hash directly.  Instead, we have to
    # post to the login page.
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'

    # The controller instance is needed for reading/expiring fragment
    @controller= ApplicationController.new
    # Clear out any existing cached files
    clear_phr_cache
    confirm_phr_cache_cleared

    post '/accounts/login', {:fe=>{:user_name_1_1=>users(:phr_admin).name,
                            :password_1_1=>'A password'}}

    make_phr_cache_files

    rule = Rule.find_by_name('hide_colon_header')
    action_id = rule.rule_actions[0].id.to_s
    put '/forms/PHR/rules/8;edit',
     {:fe=>{:rule_expression=>'age < 50 +2', :rule_name=>'hide_colon_header',
            :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
            :affected_field_1=>'immunizations', :rule_actions_id_1=>action_id}}

    assert_redirected_to('/forms/PHR/rules')
    confirm_phr_cache_cleared

    # Create a new rule and confirm that the cache is cleared.
    make_phr_cache_files
    post '/forms/PHR/rules/new',
      :fe=>{:rule_expression=>'age < 50 +12', :rule_name=>'my_test_rule',
            :rule_action_name_1=>'hide', :rule_action_parameters_1=>'',
            :affected_field_1=>'immunizations'}
    assert_redirected_to('/forms/PHR/rules')
    confirm_phr_cache_cleared

    # Delete a rule and confirm that the cache was cleared.
    make_phr_cache_files
    post '/forms/PHR/rules', :fe=>{:delete_general_rule_4=>4}
    assert_equal flash[:notice],
      "Cannot delete rule not_pregnant because it is used by other rules."
    # make sure this rule is no longer used by any other rules
    Rule.find_by_id(4).used_by_rules = []
    Rule.find_by_id(4).used_by_rules.reload

    post '/forms/PHR/rules', :fe=>{:delete_general_rule_4=>4}
    assert_response(:success)
    assert_nil flash[:notice]
    assert_nil(Rule.find_by_id(4))
    
    confirm_phr_cache_cleared


    ##################################################################
    # Test data rule creating, editing and deleting
    ##################################################################
    data_hash = {
      "rule_name"=>"new_value_rule_tt",
      "exclusion_criteria"=>"",

      "fetch_rules_used_id_1"=>"",
      "fetch_rule_label_1"=>"A1",
      "fetch_rule_name_1"=>"demographic_info",
      "fetch_rule_property_1"=>"Gender",

      "value_rule_label_1"=>"B1",
      "value_rules_used_id_1"=>"",
      "value_rule_name_1"=>"",

      "rule_case_id_1"=>"",
      "case_order_1"=>"",
      "case_expression_1"=>"true",
      "computed_value_1"=>"A1"
    }

  
#
#    # Create a new value rule and confirm that the cache is not cleared.
#    make_phr_cache_files
#    post '/value_rules/new', :fe=> data_hash
#    assert_redirected_to(:controller => 'rules')
#    # don't need to clear phr cache
#    #confirm_phr_cache_cleared
#    confirm_phr_cache_exists
#
#    new_rule = Rule.find_by_name("new_value_rule_tt")
#    data_hash["rule_case_id_1"] =  new_rule.rule_cases.first.id.to_s
#
#    # Edit a data rule and confirm that the cache is cleared.
#    put "/value_rules/#{new_rule.id};edit", :fe => data_hash
#    assert_redirected_to(:controller => 'rules')
#    confirm_phr_cache_cleared
#
#    # Test cache version of a rule and its associated fields on a form
#    # The cache version should be auto-incremented everytime when a rule gets saved
#    assert new_rule.forms.size > 0
#    test_form = new_rule.forms.first
#    actual = ClassCacheVersion.latest_version(RuleAndFieldDataCache, test_form)
#    put "/value_rules/#{new_rule.id};edit", :fe => data_hash
#    expected = ClassCacheVersion.latest_version(RuleAndFieldDataCache, test_form)
#    assert actual != expected
#
#    # Delete a data rule and confirm that the cache was cleared.
#    make_phr_cache_files
#    post '/rules',:delete => true,
#      :fe=> {'rule_name_C'=> new_rule.id,'rule_type_C' =>  "RT2"}
#    assert_redirected_to(:controller => 'rules')
#    assert_nil(Rule.find_by_id(new_rule.id))
#    confirm_phr_cache_cleared

    # Turn off caching.
    ActionController::Base.perform_caching = false
    # Clears the obsoleted caches
    system("rake tmp:cache:clear")
  end


  private
    # Generates cache files of the PHR form for testing.  This also contains
    # assertions that the cache files are created.  For testing case
    # insentivity, the cache files will be created for a form name
    # of 'pHr'.
    # Updated 10/2010 to work with combination of phr management & registration
    # pages.  Registration page no longer exists; management data saved to
    # server via an ajax call rather than a page submission.  lm.
    def make_phr_cache_files
      params = {}
      params[:profile_id] = ""
      params[:data_table] = {:phrs=>[{:race_or_ethnicity_C=>'',
                                      :birth_date_ET=>'',
                                      :pseudonym=>'test',
                                      :birth_date_HL7=>'',
                                      :birth_date=>'1945 Jan 02',
                                      :gender=>'Male',
                                      :gender_C=>'M',
                                      :race_or_ethnicity=>''}]}.to_json
      params[:form_name] = "phr_index"
      params[:no_close] = "false"
      params[:act_url] = "https://localhost/profiles"
      params[:act_condition] = {:save=>"1", :action_C_1=>"1"}.to_json
      params[:message_map] = nil

#      post '/profiles' , {:fe=>{:pseudonym_1=>'test', :save=>1, :action_C_1=>1,
#              :gender=>'Male', :birth_date=>'1945 Jan 02'}}
      xml_http_request :post, '/form/do_ajax_save', params
#      assert_response(:redirect)
#      @response.redirected_to =~ %r{/profiles/([[:alnum:]]+);edit}
      assert_response(:success)
      @response.body =~ %r{/profiles/([[:alnum:]]+);edit}
      assert_not_nil($1)
      id = $1
      get '/profiles/'+id+';edit'
      assert_response(:success)
      # Confirm the presence of the cache files
      confirm_phr_cache_exists
    end

    # Clears all teh phr caches
    def clear_phr_cache
      %w(part1 part2 part3 layout_part1 layout_part2 layout_part3).each do |cache_name|
        @controller.expire_fragment(Regexp.new("test/#{cache_name}phr"))
      end
    end

    # Checks that the cache files created by make_phr_cache_files
    # are gone.
    def confirm_phr_cache_cleared
      # Confirm that the cache files are gone
      %w(part1 part2 part3 layout_part1 layout_part2 layout_part3).each do |cache_name|
        # The cache method in cache_helper.rb has been patched so that digest will be skipped in fragment cache
        # see cache_helper_ext.rb for details
        assert_nil @controller.read_fragment("test/#{cache_name}phr")
      end
    end

    def confirm_phr_cache_exists
      %w(part1 part2 part3 layout_part1 layout_part2 layout_part3).each do |cache_name|
        # The cache method in cache_helper.rb has been patched so that digest will be skipped in fragment cache
        # see cache_helper_ext.rb for details
        assert_not_nil @controller.read_fragment("test/#{cache_name}phr")
      end
    end

end
