# Contains drug prescription frequency information which is used to rank
# search results from the drug_name_routes table.
# This is like RxhubFrequency, but the data is from a different source
# and the set of data is larger.
class UnitedHealthFrequency < ActiveRecord::Base

  # Imports data from a CSV file, which is assumed to have a header row,
  # and to have the following columns:
  # * RXCUI
  # * A prescription count for the RXCUI
  # * The TTY of the RXCUI (e.g. SBD, SCD, etc.)
  # * The full name of the drug (including the strength)
  # * The generic RXCUI for the equivalent generic drug.  (This will be blank
  # * if the drug itself is the generic).
  # Callers will likely want to call delete_all before running this method.
  #
  # Parameters:
  # * file - the full pathname to the data file for the import.
  def self.import_csv(file)
    freq_data = File.open(file).readlines.join
    rxcui_col = 0
    rxcui_count_col = 1
    tty_col = 2
    full_name_col = 3
    generic_rxcui_col = 4
    display_name_to_count = {}
    rxcui_to_display_name = {}
    header_row = true
    import_data = []
    import_cols = [:rxcui, :generic_rxcui,:rxcui_count,:display_name_count,:tty,
      :full_name]
    require 'csv'
    CSV.parse(freq_data).each do |line|
      if header_row
        header_row = false # skip the first row
      else
        rxcui = Integer(line[rxcui_col])
        dsf = DrugStrengthForm.find_by_rxcui(rxcui)
        # Skip this row if we don't have data for it in RxTerms.
        if dsf
          dnr = dsf.drug_name_route
          rxcui_to_display_name[rxcui] = dnr.text
          display_name_count = display_name_to_count[dnr.text]
          display_name_count = 0 if display_name_count.nil?
          rxcui_count = Integer(line[rxcui_count_col])
          display_name_to_count[dnr.text] = display_name_count + rxcui_count
          generic_rxcui = line[generic_rxcui_col].blank? ? nil :
                                                Integer(line[generic_rxcui_col])
          row = [rxcui, generic_rxcui, rxcui_count, nil, line[tty_col],
                                                            line[full_name_col]]
          import_data << row
        end
      end
    end

    # Now set the display name counts values in the rows
    import_data.each do |row|
      rxcui = row[0]
      display_name = rxcui_to_display_name[rxcui]
      display_name_count = display_name_to_count[display_name]
      row[3] = display_name_count
    end

    result = UnitedHealthFrequency.import(import_cols, import_data,
        {:validate=>false})
    raise 'Error on import' if result.failed_instances.size>0
  end
end
