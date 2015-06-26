require 'test_helper'
require File.dirname(__FILE__) + '/presenter_test_base'

class RecoverIdStepTwoPresenterTest < ActiveSupport::TestCase
  include PresenterTestBase

  def test_process_params
    u = create_test_user

    # Test an valid answer to a password
    p = RecoverIdStepTwoPresenter.for_user({
      :email_1=>u.email, :passwd_ans_1_1=>'A password'}, u)
    page_errors = p.process_form_params
    assert page_errors.blank?

    # Test an invalid answer to a password
    p = RecoverIdStepTwoPresenter.for_user({
      :email_1=>u.email, :passwd_ans_1_1=>'wrong'}, u)
    page_errors = p.process_form_params
    assert !page_errors.blank?
    assert_equal 1, page_errors.size

    # Test a valid answer to a question
    p = RecoverIdStepTwoPresenter.for_user({
      :email_1=>u.email, :chall_answ_1_1=>'1'}, u)
    page_errors = p.process_form_params
    assert page_errors.blank?

    # Test a invalid answer to a question
    p = RecoverIdStepTwoPresenter.for_user({
      :email_1=>u.email, :chall_answ_1_1=>'wrong'}, u)
    page_errors = p.process_form_params
    assert !page_errors.blank?

    # Check the handling of the radio buttons.  When present, that should
    # control whether the password or the question is checked.
    p = RecoverIdStepTwoPresenter.for_user({
      :email_1=>u.email, :chall_answ_1_1=>'wrong',
      :passwd_ans_1_1=>'A password', :reset_option_radio_1_1=>'challenge_q'}, u)
    page_errors = p.process_form_params
    assert !page_errors.blank? # Challenge question was used.
    p = RecoverIdStepTwoPresenter.for_user({
      :email_1=>u.email, :chall_answ_1_1=>'wrong',
      :passwd_ans_1_1=>'A password',
      :reset_option_radio_1_1=>'password'}, u)
    page_errors = p.process_form_params
    assert page_errors.blank? # Password was used
  end
end
