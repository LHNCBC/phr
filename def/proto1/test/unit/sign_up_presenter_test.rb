require 'test_helper'
require File.dirname(__FILE__) + '/presenter_test_base'

class SignUpPresenterTest < ActiveSupport::TestCase
  include PresenterTestBase

  # Tests the DataRec structure
  def test_data
    sp = SignUpPresenter.new({:some_field=>5})
    assert_equal(5, sp.data.some_field)
    assert_nil(sp.data.not_there)
    sp.data.new_var = 2
    assert_equal(2, sp.data.new_var)
  end

  # Tests process_form_params
  def test_process_form_params
    sp = SignUpPresenter.new # no parameters
    user, errors = sp.process_form_params
    assert user.errors[:email].size > 0
    assert errors.size > 0

    # Make sure we can also pass in nil without things blowing up.
    sp = SignUpPresenter.new(nil)

    form_params = {:agree_chbox_1=>'1', :user_name_1=>'pl_temp1',
      :password_1=>'abcABC123', :confirm_password_1=>'abcABC123',
      :su_fix_quest_1_1=>'one',
      :su_fixansw_1_1=>'1', :su_fix_quest_1_2=>'two', :su_fixansw_1_2=>'2',
      :su_selfquest_1_1=>'1', :su_selfansw_1_1=>'1', :su_selfquest_1_2=>'2',
      :su_selfansw_1_2=>'1', :dob_1=>'1993/2/3', :pin_1=>'1234',
      :admin=>'1', :admin_1=>'1', :email_1=>'one@two.three',
      :sec_email_1=>'one@two.three'}
    sp = SignUpPresenter.new(form_params)
    user, errors = sp.process_form_params
    assert_not_nil user.name

    # Make sure we get the right number of errors on a duplicate user name,
    # and that we also get an error for a duplicate email address.
    user2 = create_test_user(:email=>form_params[:email_1])
    form_params[:user_name_1] = user2.name
    sp = SignUpPresenter.new(form_params)
    user, errors = sp.process_form_params
    assert user.errors[:name].size > 0
    assert user.errors[:email].size > 0
  end
end
