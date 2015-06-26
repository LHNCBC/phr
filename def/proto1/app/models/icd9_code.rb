class Icd9Code < ActiveRecord::Base
  extend HasSearchableLists
  # Set up the index.  We include :text_list_id so that we can distinguish
  # between the lists during a search.
  set_up_searchable_list(:code, [:description, :is_procedure])

end
