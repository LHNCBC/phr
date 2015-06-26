ENV['RAILS_ENV'] = "test"
require File.expand_path("../../config/environment", __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  
  # Returns a field_description record by searching to see if any record matches
  # to options, if failed then create a new record use options
  # This method will be removed after we enabled the stubs of mocha - Frank
  def field_descriptions_has_record_with(options)
    options = { 
      :form_id=> 7, 
      :target_field=>"drug_use_status", 
      :predefined_field_id=>1, 
      :control_type=>""}.merge(options)
    FieldDescription.send("find_or_create_by_#{options.keys.join('_and_')}",
      *options.values)
  end
  
  def setup_association_for(form_id, rule_set_name)
    rs = RuleSet.find_by_name(rule_set_name)
    f = Form.find(form_id)
    f.rule_sets << rs unless f.rule_set_ids.include?(rs.id)
  end

  # Found the following method on 
  # http://www.oreillynet.com/onlamp/blog/2007/07/assert_raise_on_ruby_dont_just.html
  # It helps to test the raise type and the exact error message -Frank
  def assert_raise_message(types, matcher, message = nil, &block)
    args = [types].flatten + [message]
    exception = assert_raise(*args, &block)
    assert_match matcher, exception.message, message
  end

  # Added so that we can log info from test files.  Found on
  # codesnippets.joyent.com, in the midst of other info.  lm, 12/3/08
  def logger
    Rails.logger
  end
  
  
  # The method assert_blank was deprecated in Rails 4
  # Creates a same name method to avoid refactorying due to the deprecation
  def assert_blank(obj, message = nil)
    assert(obj.blank?, message)    
  end
  
  private
  # Creates a test user account with one profile, and returns the user object.
  #
  # Parameters:
  # * (optional) attrs - a hash of attributes for the user
  def create_test_user(attrs = {})
    u = User.create!({:name=>'PHR_Test2', :email=>'one2@two.three.four',
      :password=>'A password', :password_confirmation=>'A password',
      :pin=>'1234', :birth_date=>'1990/2/3'}.merge(attrs))
    # since on the webpage, fixed question shows before self question, therefore
    # we defined qtype list as [1, 0] 
    [1, 0].each do |qt|
      ['1', '2'].each do |q|
        qa = QuestionAnswer.new(:qtype=>qt, :question=>q+qt.to_s)
        u.question_answers << qa
        qa.answer = '1' # needs the user's salt, so we have to assign it first
        qa.save!
      end
    end
    profile = Profile.create!(:id_shown=>Time.now.to_f.to_s)
    u.profiles << profile

    # activate this new user
    error, flash = EmailVerification.match_token(u, u.email_verifications[0].token)
    assert_nil error
    return u
  end
end


class ActionController::TestCase
  self.use_transactional_fixtures = true
end