class GopherTermSynonym < ActiveRecord::Base
  has_paper_trail
  belongs_to :gopher_term

  # Returns the class whose ferret index includes data from this one.
  # (Used by the data controller).
  def self.ferret_class
    GopherTerm
  end
end
