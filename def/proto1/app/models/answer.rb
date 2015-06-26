class Answer < ActiveRecord::Base
  has_many :list_answer

  cache_recs_for_fields 'id'
end
