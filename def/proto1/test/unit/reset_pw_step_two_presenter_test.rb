require 'test_helper'
require File.dirname(File.expand_path(__FILE__)) + '/presenter_test_base'

class ResetPwStepTwoPresenterTest < ActiveSupport::TestCase
  include PresenterTestBase

  def test_questions
    u = create_test_user
    p = ResetPwStepTwoPresenter.for_user(nil, u)
    # Check the questions for the right qustion type.  The question is
    # either a 1 or a 2 (as a string) followed by the question type.
    fixed_questions = Set.new
    user_questions = Set.new
    ['1', '2'].each do |qbase|
      fixed_questions.add(qbase + QuestionAnswer::FIXED_QUESTION.to_s)
      user_questions.add(qbase + QuestionAnswer::USER_QUESTION.to_s)
    end

    assert(fixed_questions.member?(p.fixed_question))
    assert(user_questions.member?(p.user_question))
    assert_not_equal(p.fixed_question, p.user_question)
  end
end
