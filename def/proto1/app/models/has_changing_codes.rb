# This is a module for list table whose codes might change.
# It is assumed that the table has a "code_is_old" column (boolean)
# and an "old_codes" column with prior codes surrounded and delimited by |.

module HasChangingCodes
  # Returns the instance that has the given code and whose code_id_old column
  # is false.
  #
  # Paramaters:
  # * code - the ingredient RxCUI for which the current instance is needed.
  def find_current_for_code(code)
    return where(code_is_old: false).where("old_codes like '%|#{code}|%'").take
  end
end
