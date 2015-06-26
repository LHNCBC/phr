require 'test_helper'
class AnswerListTest < ActiveSupport::TestCase
  fixtures :answer_lists, :list_answers, :answers

  def test_get_list_options
    # Try getting a list by id
    list = AnswerList.get_list_items('-2')
    assert_equal(1, list.size, 'race list size')
    assert_equal('None', list[0].answer_text)

    # Try getting a list using an order
    list = AnswerList.get_list_items('-1', nil,
      ['answer_text', 'id'], nil)
    assert_equal(3, list.size, 'order')
    assert_equal('Female', list[0].answer_text, 'order')

    # Try getting a list using just one field for an order
    list = AnswerList.get_list_items('-1', nil,
      ['answer_text'], nil)
    assert_equal(3, list.size, 'order2')
    assert_equal('Female', list[0].answer_text, 'order2')

    # Try getting a list using a condition
    list = AnswerList.get_list_items('-1', nil, nil, 'list_answers.id=-3')
    assert_equal(1, list.size, 'condition')
    assert_equal('Female', list[0].answer_text, 'condition')
  end
end
