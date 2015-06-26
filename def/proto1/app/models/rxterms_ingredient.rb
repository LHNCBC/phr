class RxtermsIngredient < ActiveRecord::Base
  extend HasSearchableLists
  extend HasChangingCodes
  include HasClassification
  set_up_searchable_list(:ing_rxcui, [:name])
  
  DEFAULT_CODE_COLUMN = "ing_rxcui"
end
