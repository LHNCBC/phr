class ListAnswer < ActiveRecord::Base
  cache_associations
  belongs_to :answer
  belongs_to :answer_list
  validates_presence_of :code

  # Returns the text of the answer.
  def answer_text
    return answer.answer_text
  end
end
