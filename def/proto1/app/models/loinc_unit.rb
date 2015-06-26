class LoincUnit < ActiveRecord::Base
  belongs_to :loinc_item

  # Provides the normal high range defined for the current loinc_unit.  Two
  # arrays are returned for display by a prefetch autocompleter.
  #
  # Returns:  an array containing two elements:
  #  * an array containing the range value; and
  #  * an array containing the corresponding id.
  #
  def normal_high_range
    return [[norm_high], [id]]
  end


  # Provides the normal low range defined for the current loinc_unit.  Two
  # arrays are returned for display by a prefetch autocompleter.
  #
  # Returns:  an array containing two elements:
  #  * an array containing the range value; and
  #  * an array containing the corresponding id.
  #
  def normal_low_range
    return [[norm_low], [id]]
  end


  # Provides the critical high range defined for the current loinc_unit.  Two
  # arrays are returned for display by a prefetch autocompleter.
  #
  # Returns:  an array containing two elements:
  #  * an array containing the range value; and
  #  * an array containing the corresponding id.
  #
  def critical_high_range
    return [[danger_high], [id]]
  end


  # Provides the critical low range defined for the current loinc_unit.  Two
  # arrays are returned for display by a prefetch autocompleter.
  #
  # Returns:  an array containing two elements:
  #  * an array containing the range value; and
  #  * an array containing the corresponding id.
  #
  def critical_low_range
    return [[danger_low], [id]]
  end


  # Returns the unit string along with the normal range field as one string.
  def unit_with_range
    norm_range ? "#{unit} (range: #{norm_range})" : unit
  end
end
