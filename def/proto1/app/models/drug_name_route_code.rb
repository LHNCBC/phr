class DrugNameRouteCode < ActiveRecord::Base

  # The last value returned by next_code
  @@last_next_code = nil

  # Returns the next available unused code.  This assumes that only the caller
  # is actively inserting new records; the database is only checked once.
  def self.next_code
    if !@@last_next_code
      @@last_next_code = self.maximum(:code) || 0
    end
    @@last_next_code = @@last_next_code + 1
    return @@last_next_code
  end

end
