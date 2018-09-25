# This is a utility class for updating the RxTerms data in our database.
# It will update the drug_name_routes and drug_strength_forms tables.
# This version of the update does not attempt to preserve DrugNameRoute id
# values, and so is a lot simpler.  If in the future we need a code for the
# DrugNameRoute objects, talk with Kin Wah Fung, the creator of RxTerms.
# He doesn't think they are needed.  For the PHR, probably a temporary
# code that is the ID will work just fine.  The temporary code will only
# be valid until the next update, but we mainly use that code for AJAX
# calls for additional data, so a temporary code is sufficient.
#
# There is one top-level method (update_tables); the rest are public only to
# facilitate testing.
#
# Note:  Some method comments refer to "dnr" as an abbreviation for 
# DrugNameRoute, and to "dsf" as an abbreviation for "DrugStrengthForm".
#require 'ar-extensions'
#require 'ar-extensions/adapters/mysql'
#require 'ar-extensions/import/mysql'
require 'activerecord-import'

class RxtermsUpdater
 
  def initialize
    # A map from "name and route" strings to hashes of attributes for
    # DrugNameRoute objects
    @name_to_dnr = {}
    
    # A map from "name and route" strings to lists of hashes of attributes for
    # DSFs (from the update data, not the database).
    @name_to_dsfs = {}
    
    # A map of dnrs to representative generic RxCUI field values.
    @name_to_generic_rxcui = {}

    # A map of RXCUIs to DrugNameRoute objects
    @rxcui_to_dnr = {}

    # A map rom "name and route" strings to sets of synonyms.  The synonyms
    # might only really apply to specific strengths of the drug, but for now
    # we are just collecting and applying them all at the name and route level.
    @name_to_synonyms = {}

    # A map from route names to the route code.
    @route_to_code = {}
    DrugRoute.where('retired != true').each {
      |dr| @route_to_code[dr.name] = dr.code}

    # A map from drug RxCUIs to brand RxCUIs.
    @drug_rxcui_to_brand_rxcui = nil

    # A map from long DNR codes to sets of corresponding display names.
    # This is used as a check on the uniqueness of the codes; the sets should
    # each contain just one element.
    @long_dnr_code_to_dnr_name = {}

    # A map of existing long DNR codes to the shorter codes.
    @long_dnr_code_to_code = {}
    DrugNameRouteCode.all.each {|dnrc|
      @long_dnr_code_to_code[dnrc.long_code] = dnrc.code}

    # A hash set of RxCUIs that are branded packs
    @is_branded_pack = Set.new
  end

  # Initialize some constants to hold the column indices of the fields
  # in the RxTerms file.
  RXCUI_COL = 0
  GENERIC_RXCUI_COL = 1
  TTY_COL = 2
  FULL_GENERIC_NAME_COL = 5
  DISPLAY_NAME_COL = 7
  ROUTE_COL = 8
  FORM_COL = 9
  STRENGTH_COL = 10
  SUPPRESS_COL = 11
  SYNONYM_COL = 12
  IS_RETIRED_COL = 13

  # Performs an update of the data in this table and in the assocated
  # drug_strength_forms table.
  #
  # Parameters:
  # * data_file - the pathname for the file containing the data.  This should
  #   contain all of the old data, plus maybe some new records.  It should be
  #   in the RxTerms format (currently produced by Kin Wah Fung).  Here
  #   are Kin Wah's notes (modified) on the meaning of the data fields:
  #   1. RXCUI
  #   1. GENERIC_RXCUI
  #   1. TTY
  #   1. FULL_NAME – full name from rxnorm
  #   1. RXN_DOSE_FORM – original dose form in rxnorm
  #   1. FULL_GENERIC_NAME – full name excluding brand name part (if present)
  #   1. BRAND_NAME – brand name (all upper case)
  #   1. DISPLAY_NAME – this is either a. generic ingredient list + route
  #      (for tty=SCD) or b. BRAND_NAME + route (for tty=SBD)
  #   1. ROUTE – the route that we parsed out, this is used in the generation of
  #      the DISPLAY_NAME
  #   1. NEW_DOSE_FORM – the dose form that we used for our table
  #   1. STRENGTH – strength information (concatenated if there are multiple
  #      ingredients)
  #   1. SUPPRESS_FOR – if this = ‘C’ (short for CMS), the whole row should be
  #      suppressed for the CMS use case.  Note that if one row for a drug
  #      name/route is suppressed, there might be others that are not.
  #   1. DISPLAY_NAME_SYNONYM – synonyms, separated by semicolons
  #   1. IS_RETIRED – ‘TRUE’ if the rxcui is present in the previous version
  #      (based on rxnorm 200707) and not in the latest generated version. These
  #      rows should generally be suppressed. They exist only as historical
  #      information.
  # * ingredient_file - the pathname for a file containing the ingredient data.
  #   This should be in a format similar to the RxTerms file, but with the
  #   following fields:
  #   1. RXCUI - the RXCUI of a drug from the RxTerms file
  #   1. INGREDIENT - the name of an ingredient in the drug
  #   1. ING_RXCUI - the RXCUI for the ingredient
  # * brand_name_file - the pathname for a file containing a table mapping
  #   drug RxCUIs (the first column) to brand name RxCUIs (the second column).
  def update_tables(data_file, ingredient_file, brand_name_file)
    
    # Turn off ferret indexing for DrugNameRoute.  We'll do it later.
    update_start = Time.new
    DrugNameRoute.disable_ferret

    load_start = Time.new
    puts 'Loading data'
    @name_to_dnr = {}

    rxcui_to_rxterms_ing = load_ingredients(ingredient_file)

    load_brand_name_data(brand_name_file)

    File.open(data_file) do |file|
      first_line = true
      file.each_line do |line|
        if (first_line)
          first_line = false # skip first line (the headers)
        else        
          fields = get_rxterm_fields(line)
          process_line(fields)
        end # not first line of file
      end # each line of file
    end # open file
    
    puts "Finished loading data in #{Time.new-load_start} seconds."
    
    post_update_processing(@name_to_dnr, @name_to_dsfs)
    
    assign_route_codes

    compute_dnr_ingredients(rxcui_to_rxterms_ing)

    save_updates

    assign_generic_dnrs # needs to be done after the data is saved

    self.class.update_drug_classes # Also needs to be done after the data is saved

    # Now turn indexing back on and rebuild the DrugNameRoute index.
    start=Time.new
    puts 'Rebuilding DrugNameRoute index'
    DrugNameRoute.enable_ferret
    DrugNameRoute.rebuild_index
    puts "Finished rebuilding the index in #{Time.new-start} seconds."
    puts "Total update time:  #{Time.new-update_start} seconds"
  end


  # Updates the drug class data stored in the drug_name_routes table based on
  # the ingredient RxCUIs stored in the drug_name_routes table and the
  # current RxtermsIngredient classes stored in the data_classes and
  # classifications tables.
  #
  # Note:  This method will be quite slow unless USE_AR_CACHE is set to true.
  # You can achieve that by running script/console like this:
  # ( setenv USE_AR_CACHE true ; script/console )
  def self.update_drug_classes
    start = Time.new
    # Build a set of routes that should be assigned classes if possible.
    # Per Kin Wah Fung, these are routes of type "Systemic" or "Mixed".
    routes_for_classes = Set.new
    systemic = DrugRoute.find_by_code('RC1')
    mixed = DrugRoute.find_by_code('RC3')
    DrugRoute.where('retired != true').each do |dr|
      parent = dr.parent
      route_okay = false
      while (!route_okay && parent)
        if parent == systemic || parent == mixed
          route_okay = true
          routes_for_classes << dr.name
        else
          parent = parent.parent
        end
      end
    end

    # Pre-load the RxtermsIngredients and the classes.
    ing_rxcui_to_classes = {}
    RxtermsIngredient.all.each do |rxi|
      ing_rxcui_to_classes[rxi.ing_rxcui] = rxi.classification_codes_array
    end

    DrugNameRoute.all.each do |dnr|
      if routes_for_classes.member?(dnr.route)
        ing_rxcuis = PredefinedField.parse_set_value(dnr.ingredient_rxcuis)
        codes = Set.new
        # For each RxtermsIngredient for this drug, get its classes
        ing_rxcuis.each do |ing_rxcui|
          codes.merge(ing_rxcui_to_classes[ing_rxcui])
        end
        new_classes = PredefinedField.make_set_value(codes.to_a.sort)
        if dnr.drug_class_codes != new_classes
          dnr.drug_class_codes = new_classes
          dnr.save!
        end
      end
    end
    puts "Finished updating drug classes in #{Time.new-start} seconds."
  end

  
  # Processes the data from line of the RxTerms file, creates
  # dnr (if not already there) and the dsf.
  #
  # Parameters
  # * rxcui- the RxCUI, as an integer, for this record
  # * dsf - the DrugStrengthForm (if already existing) corresponding to the
  #   RxCUI
  # * fields - the fields parsed from the data line of the RxTerms file.
  def process_line(fields)
    process_dnr_fields(fields)
    process_dsf_fields(fields)
  end
  
  
  # Breaks up a line of RxTerms data into fields, which it returns as an
  # array.  Returned empty fields may be either an empty string or nil, so
  # use blank? to check that.
  # 
  # Parameters:
  # * line - the  line of data from the RxTerms data file, including
  #   any line ending characters
  def get_rxterm_fields(line)
    rtn = line.chomp.split('|');
    rtn[IS_RETIRED_COL] = nil if rtn.length <= IS_RETIRED_COL
    return rtn
    # The following version was slower:
    # return line.chomp.split('|', -1) # -1 means return trailing empty fields
  end
  
  
  # Processes the fields needed for a DrugNameRoute record, and stores (or
  # updates) the data in @name_to_dnr.
  #
  # Parameters:
  # * fields - the array of fields from an RxTerms record
  def process_dnr_fields(fields)
    name_route = fields[DISPLAY_NAME_COL]
    dnr_hash = @name_to_dnr[name_route]

    if !dnr_hash
      # Create it.
      route = fields[ROUTE_COL]
      synonyms = fields[SYNONYM_COL]
      is_brand = fields[TTY_COL] != 'SCD' && fields[TTY_COL] != 'GPCK'
      dnr_hash = {'text'=>name_route, 'route'=>route,
                       'synonyms'=>synonyms, 'is_brand'=>is_brand,
                       'drug_class_codes'=>nil, 'ingredient_rxcuis'=>nil
                       }
      @name_to_dnr[name_route] = dnr_hash
      synonym_set = Set.new
      synonym_set.merge(synonyms.split(/; /)) if synonyms
      @name_to_synonyms[name_route] = synonym_set
    else
      # See if there are new synonyms
      synonyms = fields[SYNONYM_COL]
      if synonyms && synonyms != dnr_hash['synonyms']
        synonym_set = @name_to_synonyms[name_route]
        count = synonym_set.size
        synonym_set.merge(synonyms.split(/; /))
        if synonym_set.size > count
          dnr_hash['synonyms'] = synonym_set.to_a.sort.join('; ')
        end
      end
    end
  end
  
  
  # Processes the fields needed for a dsf record, and
  # caches the data in @name_to_dsfs.
  #
  # Parameters:
  # * fields - the array of fields from an RxTerms record
  def process_dsf_fields(fields)
    # Add/update the strength form information
    strength = fields[STRENGTH_COL]
    form = fields[FORM_COL]
    rxcui = fields[RXCUI_COL].to_i
    @is_branded_pack << rxcui if fields[TTY_COL] == 'BPCK'
    amount_list = get_amount_list(fields[ROUTE_COL], form)
    retired = !fields[IS_RETIRED_COL].blank?
    suppress = !fields[SUPPRESS_COL].blank?
    dsf_attrs = {'strength'=>strength, 'form'=>form,
      'amount_list_name'=>amount_list, 'rxcui'=>rxcui,
      'suppress'=>(retired || suppress)}
    name = fields[DISPLAY_NAME_COL]
    dsfs = @name_to_dsfs[name]
    if !dsfs
      dsfs = []
      @name_to_dsfs[name] = dsfs
    end
    dsfs << dsf_attrs

    # Store the generic RXCUI, but prefer the value from a non-suppressed record
    if !@name_to_generic_rxcui[name] || !suppress
      generic_rxcui = fields[GENERIC_RXCUI_COL]
      @name_to_generic_rxcui[name] = generic_rxcui.to_i if !generic_rxcui.blank?
    end
  end
  
  
  # Assigns generic DrugNameRoutes to brand name DrugNameRoutes
  # This needs to be done after the data is saved, because it stores the id
  # of the generic DrugNameRoute.
  def assign_generic_dnrs
    start = Time.new
    puts 'Assigning generic drug name routes'

    # Make a hash of RxCUIs to DNR ids
    rxcui_to_dnr_id = {}
    DrugStrengthForm.all.each {
      |dsf| rxcui_to_dnr_id[dsf.rxcui] = dsf.drug_name_route_id}
    DrugNameRoute.all.each do |nr|
      # Set the generic DrugNameRoute, if there is one.
      generic_rxcui = @name_to_generic_rxcui[nr.text]
      if generic_rxcui
        generic_dnr_id = rxcui_to_dnr_id[generic_rxcui]
        if generic_dnr_id && nr.generic_id != generic_dnr_id
          nr.generic_id = generic_dnr_id
          nr.save!
        end
      end
    end
    puts 'Finished assigning generic drug name routes in '+
         "#{Time.new-start} seconds."
  end


  # This method performs processing on the drug table data that must
  # be done after all of the lines of a data file have been read in and
  # processed.  (In other words, this is processing that cannot be done
  # on a line by line basis as the data is read in.)  In particular, this
  # method:
  # * left-pads the strength fields so that they sort correctly
  # * sets the value of the suppress field for the drug_name_route records
  #   (which are suppressed if all of their drug_strength_forms are suppressed).
  #
  # Parameters:
  # * name_to_dnr - a map from dnr name+route values to dnrs
  # * name_to_dsfs - a map from name+route values to dsf lists.
  def post_update_processing(name_to_dnr, name_to_dsfs)
    # Now pad the strength fields so that the numbers sort correctly
    start = Time.new
    puts 'Post-update processing'
    name_to_dnr.values.each do |nr|
      # Get the dsfs for the dnr.
      dsf_list = name_to_dsfs[nr['text']]
      pad_strength_fields(dsf_list)
      
      # Sort the DSFs by RxCui, and suppress duplicate "text" attribute values.
      # In this way, the unsuppressed DSF of a pair of duplicates will always
      # be the one with the lower RxCUI (which should be the older one).
      # But, if a DSF is already suppressed, don't let it affect duplicates.
      # (I'm not sure now why there would be duplicates for a particular drug.
      # I can't think of a case where there would be; it might be safe to
      # remove this check.)
      dsf_list.sort! {|x,y| x['rxcui'] <=> y['rxcui']}
      dsf_texts = Set.new
      # Also, keep track of whether at least one dsf is not suppressed.
      all_suppressed = true
      dsf_list.each do |sf|
        if !sf['suppress']
          if dsf_texts.member?(sf['text'])
            sf['suppress'] = true
          else
            dsf_texts << sf['text']
          end
        end
        all_suppressed = sf['suppress'] if all_suppressed
      end
      
      nr['suppress'] = all_suppressed
    end

    puts "Finished post-update processing in #{Time.new-start} seconds."
  end


  # Pads the strength fields with spaces on the left so that when presented
  # together, the strength values will line up right adjusted.  We also create
  # the "text" attribute (the combination of the strength and form strings)
  # in this method.
  #
  # Parameters
  # * dsf_list - a list of hashes of attributes for DrugStrengthForm objects
  def pad_strength_fields(dsf_list)
    max_strength_digits = get_max_strength_digits(dsf_list)

    # Now add the padding to the fields.
    dsf_list.each do |sf|
      if (max_strength_digits != 0)
        str_val = sf['strength']
        str_num = get_strength_number(str_val)
        num_digits = str_num.length
        sf['strength'] = ' ' * (max_strength_digits - num_digits) +
            str_val.strip  # trim the string in case we've padded before
      end
      # Create the "text" field
      sf['text'] = sf['strength'] + ' ' + sf['form']
    end
  end


  # For the given list of DrugStrengthForms (dsfs), computes and returns the
  # maximum number of digits in the strength value.  If the strength field
  # for the first dsf is the string "Mixed", it is assumed that all items
  # in the list have that value.  (In that case, the return value is zero.)
  #
  # Parameters:
  # * dsf_list - the list of hashes of attributes for DrugStrengthForm objects
  #   whose strength values are to be examined
  def get_max_strength_digits(dsf_list)
    rtn = 0
    first_strength = dsf_list[0]['strength']
    # Newer mixed-strength drugs now say "mixed" instead of "Mixed".
    if (first_strength != 'mixed' && first_strength != 'Mixed')
      dsf_list.each do |sf|
        str_num = get_strength_number(sf['strength'])
        if (str_num.nil?)
          raise "Bad strength data for rxcui #{sf['rxcui']}"
        end
        num_digits = str_num.length
        rtn = num_digits if num_digits > rtn
      end
    end
    return rtn
  end
  
  
  # Returns the numeric part of the given strength string.  The number is
  # expected to be at the beginning of the string, but may be preceeded
  # by whitespace.
  #
  # Parameters:
  # * strength_val - string containing the strength number and units
  #
  # Returns the strength number (as a string), or nil if the string doesn't 
  # match the expected format.
  def get_strength_number(strength_val)
    strength_val =~ /\A\s*([\d,]+)/
    return $1
  end
  
  
  # Returns the name of the text_list containing the amount list for the given
  # route and dose_form combination
  # This list is not actually used anymore, but we still compute it for now.
  def get_amount_list(route, dose_form)
    if (dose_form =~ /\bTabs\z/)
      list_name = 'Tabs_Dose_Type'
    elsif (dose_form =~ /\bCaps\z/)
      list_name = 'Caps_Dose_Type'
    elsif (dose_form == 'Inhal' || route == 'Inhalant')
      list_name = 'Inhalant_Dose_Type'
    elsif (route == 'Nasal')
      if (dose_form == 'Spray')
        list_name = 'Nasal_Spray_Dose_Type'
      elsif (dose_form == 'Sol')
        list_name = 'Nasal_Sol_Dose_Type'
      end
    elsif (route == 'Injectable')
      list_name = ''
    elsif (route == 'Rectal' && dose_form == 'Suppository')
      list_name = 'Rectal_Dose_Type'
    elsif (route == 'Otic')
      if (dose_form == 'Cream')
        list_name = 'Otics_Cream_Dose_Type'
      elsif (dose_form == 'Sol')
        list_name = 'Otics_Dose_Type'
      end
    elsif (route == 'Ophthalmic')
      if (dose_form == 'Ointment')
        list_name = 'Opthalmic_Oint_Dose_Type'
      elsif (dose_form == 'Sol')
        list_name = 'Opthalmic_Dose_Type'
      end
    elsif (dose_form == 'Sol' || dose_form == 'Syrup' || dose_form == 'Susp')
      list_name = 'Solution_Dose_Type'
    else
      list_name = 'Dose'
    end
  end


  # Loads the data from the ingredient file into the database, and returns
  # a hash from drug RXCUIs to sets of attributes of RxtermsIngredient instances.
  #
  # Parameters:
  # * ingredient_file - the pathname for a file containing the ingredient data.
  #
  # Returns: a hash from non-suppressed drug RXCUIs to sets of attributes of
  # RxtermsIngredient instances.
  def load_ingredients(ingredient_file)
    start = Time.new
    puts 'Loading RxTerms Ingredient data'
    # A hash from drug rxcui to sets of RxtermsIngredient attributes
    rxcui_to_rxing = {}
    # An array of attribute arrays for RxtermsIngredients to be created/updated
    new_rxing_values = []
    # A hash from ingredient RxCUIs to hashes of RxtermsIngredient attributes
    ing_rxcui_to_rxterms_ing = {}
    File.open(ingredient_file) do |file|
      first_line = true
      file.each_line do |line|
        if (first_line)
          first_line = false # skip first line (the headers)
        else
          rxcui, name, ing_rxcui = line.chomp!.split(/\|/)
          drug_ingredients = rxcui_to_rxing[rxcui]
          if !drug_ingredients
            drug_ingredients = Set.new
            rxcui_to_rxing[rxcui] = drug_ingredients
          end
          rxterms_ing = ing_rxcui_to_rxterms_ing[ing_rxcui]
          if !rxterms_ing
            rxterms_ing = {'name'=>name,
              'ing_rxcui'=>ing_rxcui}
            ing_rxcui_to_rxterms_ing[ing_rxcui] = rxterms_ing
            new_rxing_values << [name, ing_rxcui]
          end
          drug_ingredients << rxterms_ing
        end # not first line of file
      end # each line of file
    end # open file

    # Load old data
    old_code_to_rxi = {}
    old_name_to_rxi = {}
    RxtermsIngredient.all.each do |rxi|
      old_code_to_rxi[rxi.ing_rxcui]= rxi
      # Prefer current instances
      if !old_name_to_rxi[rxi.name] || !rxi.code_is_old
        old_name_to_rxi[rxi.name] = rxi
      end
    end

    # Make old data as not in the list the user sees
    RxtermsIngredient.connection.execute(
      'update rxterms_ingredients set in_current_list=false')

    # Merge the new data with the old, building the import data list and
    # some lists of warnings.
    import_data_hashes = []
    new_rxing_values.each do |rxi_data|
      new_name, new_rxcui = rxi_data
      old_rxi = old_code_to_rxi[new_rxcui]
      if old_rxi
        attr_vals = nil
        if old_rxi.code_is_old
          # This would be the case if the code change from A in release 1
          # to B in release 2 and back to A in release 3.
          # Find the latest record for this code, and make it not the latest
          latest_old_rxi =
            RxtermsIngredient.find_current_for_code(old_rxi.ing_rxcui)
          latest_old_attr_vals = latest_old_rxi.attributes
          latest_old_attr_vals['in_current_list'] = false
          latest_old_attr_vals['code_is_old'] = true
          import_data_hashes << latest_old_attr_vals
          # Update old_rxi
          attr_vals = {'code_is_old'=>false, 'in_current_list'=>true,
            'old_codes'=>latest_old_attr_vals['old_codes'] +
              latest_old_attr_vals['ing_rxcui'] + '|'}
          cur_rxcui = latest_old_attr_vals['ing_rxcui']
          puts "Warning:  Ingredient RxCUI #{cur_rxcui} changed back to "+
            "#{new_rxcui}"
        end
        if new_name != old_rxi.name
          puts "Warning:  For Ingredient RxCUI #{new_rxcui}, the name changed "+
            "from #{old_rxi.name} to #{new_name}"
          # Update the record
          attr_vals = {} if !attr_vals
          attr_vals.merge!({'name'=>new_name})
        end
        # We always need to update the record to set in_current_list back to
        # true, because we set them all to false (above) to handle obsolete
        # records that don't show up in the next update file.
        attr_vals = {} if !attr_vals
        attr_vals.merge!({'in_current_list'=>true})
        attr_vals = old_rxi.attributes.merge(attr_vals)
        import_data_hashes << attr_vals
       else # we couldn't find by the code; try finding by the name
        old_rxi = old_name_to_rxi[new_name]
        old_codes = ''
        if (old_rxi)
          if (old_rxi.code_is_old)
            # In this case both the name and the code have changed, but the name
            # in this last release has changed back to something it used to be.
            # Find the latest record for this code, and make it not the latest
            latest_old_rxi =
              RxtermsIngredient.find_current_for_code(old_rxi.ing_rxcui)
            attr_vals = latest_old_rxi.attributes
            attr_vals['in_current_list'] = false
            attr_vals['code_is_old'] = true
            import_data_hashes << attr_vals
            cur_rxcui = attr_vals['ing_rxcui']
            puts "Warning:  Ingredient RxCUI #{cur_rxcui} changed to "+
              "#{new_rxcui} and the name changed back to an older name, "+
              new_name
          else # the code is not old
            # In this case, the code has changed.
            attr_vals = old_rxi.attributes
            attr_vals['in_current_list'] = false
            attr_vals['code_is_old'] = true
            import_data_hashes << attr_vals
            cur_rxcui = attr_vals['ing_rxcui']
            puts "Warning:  Ingredient RxCUI #{cur_rxcui} changed to "+
              "#{new_rxcui}"
          end
          # Make the old_codes attribute for the replacement record
          old_codes =  # (Note:  attr_vals['old_codes'] might be '')
            attr_vals['old_codes'].chop + '|' + attr_vals['ing_rxcui'] + '|'
        end
        # In all three cases in this branch, we want to make a new record;
        # however, the old_codes list will by non-empty in two cases.
        import_data_hashes << {'name'=>new_name, 'ing_rxcui'=>new_rxcui,
          'in_current_list'=>true, 'code_is_old'=>false, 'old_codes'=>old_codes}
      end
    end

    # Now make rows of data for the import.
    import_data_rows = []
    import_cols =
      ['id', 'name', 'ing_rxcui', 'in_current_list', 'code_is_old', 'old_codes']
    import_data_hashes.each do |h|
      import_data_rows << h.values_at(*import_cols)
    end

    if import_data_rows.size > 0 # true if there are any ingredients
      # In the line below, the clone is necessary because import adds timestamp
      # columns to the import_cols array.
      result = RxtermsIngredient.import(import_cols, import_data_rows,
        {:validate=>false, :on_duplicate_key_update=>import_cols.clone})
      raise 'Error- RxtermsIngredient import' if result.failed_instances.size>0
    end

    puts "Finished loading RxTerms ingredients in #{Time.new-start} seconds."
    return rxcui_to_rxing
  end


  # Sets up the links between drug_name_routes and drug_classes.  This is
  # computable from the links between drug_classes and ingredient_names, but
  # we go ahead and set up these links in advance to save some database time.
  #
  # Because it is convenient, this method also calls compute_dnr_codes to assign
  # the DNR codes.  That means assign_route_codes must already have been called
  # prior to this method.
  #
  # Parameters:
  # * rxcui_to_rxterms_ing - a hash from drug RXCUIs to sets of attributes of
  #   RxtermsIngredient instances.
  def compute_dnr_ingredients(rxcui_to_rxterms_ing)
    start = Time.new
    puts 'Computing drug ingredients'
    new_dnr_code_data = []
    @name_to_dnr.values.each do |dnr|
      # Find an rxcui for the dnr that is not suppressed, if we can.
      # Sometimes, different RxCUIs for the same display name have different
      # brand name codes (because we remove strength values).  For the sake
      # of stability, pick the one with the lowest rxcui.
      dsf = nil
      dsfs = @name_to_dsfs[dnr['text']]
      dsfs.each do |d|
        if !d['suppress']
          dsf = d if !dsf || dsf['rxcui'] > d['rxcui']
        end
      end

      dsf = dsfs[0] if ! dsf

      dnr_rxcui = dsf['rxcui'].to_s
      ingredients = rxcui_to_rxterms_ing[dnr_rxcui]
      if ingredients
        ing_rxcuis = ingredients.collect {|ing| ing['ing_rxcui']}
        dnr['ingredient_rxcuis'] = PredefinedField.make_set_value(ing_rxcuis)
      end

      # Compute the dnr code (which we can do now that we have assigned
      # ingredient codes).
      code_data = compute_dnr_code(dnr, dsf)
      new_dnr_code_data << code_data if code_data # else code is not new
    end # for each dnr

    # Make sure the assigned codes were unique.  (This check is also done
    # at the database-level, but we can print out better errors here.)
    @long_dnr_code_to_dnr_name.each do |long_code, names|
      if (names.size > 1)
        raise "Error:  #{long_code} is being used for the names " +
          names.to_a.join(', ')
      end
    end

    # Update the DrugNameRouteCodes table
    if new_dnr_code_data.size > 0
      DrugNameRouteCode.import(['code', 'long_code'], new_dnr_code_data,
        {:validate=>false})
    end

    puts "Finished computing drug ingredients in #{Time.new-start} seconds."
  end


  # Computes and stores a code for the DNR, if possible.  The dnr should
  # already have had route codes and ingredient codes assigned.
  #
  # Parameters
  # dnr - a hash of attributes for a DNR
  # dsf - a hash of attributes for a non-suppressed DSF.
  #
  # Returns:  nil, unless the code is new, in which case an array containing the
  # code and the long code will be returned so that the drug_name_route_codes
  # table can be updated in a batch import later.
  def compute_dnr_code(dnr, dsf)
    rtn = nil
    if (!dnr['suppress'])
      route_code = @route_to_code[dnr['route']]
      full_code = nil
      rxcui = dsf['rxcui']
      if dnr['is_brand']
        if (@is_branded_pack.member?(rxcui))
          # There is just one rxcui for these branded packs, but there is no
          # brand code, so we use the rxcui.
          brand_code = rxcui.to_s
        else
          brand_code = @drug_rxcui_to_brand_rxcui[rxcui]
        end
        raise 'Missing brand code for ' + dsf['rxcui'].to_s if !brand_code
        ingred_codes = '|' + brand_code
      else
        ingred_codes = dnr['ingredient_rxcuis']
        ingred_codes = ingred_codes.chop if ingred_codes
      end

      if (ingred_codes)
        # Some drug names contain 'XR' or 'EC' before the route string.  Others
        # (insulins) contain 50/50 or U500.  However, they ingredients are the
        # same as the forms without XR/EC or different numbers, so we need
        # to pull that string out and add it to the code.
        name = dnr['text']
        if name =~ / (XR|EC|\d\d\/\d\d|U\d+) \(/
          extra = $1
        else
          extra = ''
        end

        full_code = "#{route_code}|#{extra}#{ingred_codes}"
        
        # Keep track of which names are getting which ones.  There should
        # be a one-to-one correspondence, but we will check that later.
        names = @long_dnr_code_to_dnr_name[full_code]
        if !names
          names = Set.new
          @long_dnr_code_to_dnr_name[full_code] = names
        end
        names << name

        # See if we have defined this code before
        code = @long_dnr_code_to_code[full_code]
        if !code
          code = DrugNameRouteCode.next_code
          rtn = [code, full_code]
        end
        # Set the code, but as a string, which is how we store it in
        # DrugNameRoute.  (In DrugNameRouteCode, it is an integer, so we
        # can easily increment it to get the next one available).
        dnr['code'] = code.to_s
      end
    end
    return rtn
  end


  # Uses the route field in DrugNameRoute to compute route codes and stores
  # them in the new route codes field.
  def assign_route_codes
    start = Time.new
    puts 'Computing route codes'
    route_name_to_codes = {}
    @name_to_dnr.values.each do |dnr|
      route_name = dnr['route']
      code_str = route_name_to_codes[route_name]
      if !code_str
        drug_route = DrugRoute.where('retired != true').where(:name=>route_name).first
        codes = []
        while (drug_route)
          codes << drug_route.code
          drug_route = drug_route.parent
        end
        if !codes.empty?
          code_str = PredefinedField.make_set_value(codes)
          route_name_to_codes[route_name] = code_str
        else
          raise "Could not find an entry in drug_routes for the route \"#{route_name}\""
        end
      end
      dnr['route_codes'] = code_str if code_str
    end
    puts "Finished computing route codes in #{Time.new-start} seconds."
  end


  # Reads the brand name file and initializes @drug_rxcui_to_brand_rxcui with a
  # map of drug rxcuis to brand name
  def load_brand_name_data(brand_name_file)
    puts 'Loading brand name data'
    start = Time.new
    @drug_rxcui_to_brand_rxcui = {}
    File.open(brand_name_file) do |file|
      first_line = true
      file.each_line do |line|
        if (first_line)
          first_line = false # skip first line (the headers)
          if (line.chomp != 'RXCUI|BN_RXCUI')
            raise 'The first line of the brand name file should be ' +
              "RXCUI|BN_RXCUI but was '#{line}'."
          end
        else
          drug_rxcui, brand_rxcui = line.chomp!.split(/\|/)
          @drug_rxcui_to_brand_rxcui[drug_rxcui.to_i] = brand_rxcui
        end # not first line of file
      end # each line of file
    end # open file
    puts "Finished loading brand data in #{Time.new-start} seconds."
  end


  # Saves the updated information to the database.
  def save_updates
    puts 'Saving data'
    start = Time.new
    # Suppress everything in the drug_name_routes table, which we won't
    # completely delete.
    DrugNameRoute.update_all(:suppress=>1)
    # Same for the DrugStrengthForm table
    DrugStrengthForm.update_all(:suppress=>1)

    # Load the existing data in and build hashes so we can find IDs.
    name_to_dnr_obj = {}
    code_to_dnr_obj = {}
    DrugNameRoute.all.each do |dnr|
      dnr_id = dnr.id
      # Prefer non-old instances
      if !name_to_dnr_obj[dnr.text] || !dnr.code_is_old
        name_to_dnr_obj[dnr.text] = dnr
      end
      code = dnr.code
      code_to_dnr_obj[code] = dnr if code
    end

    # Determine the list of IDs for the records we're updating.  Also separate
    # the DNR data into 1) the ones that were there before and will be updated;
    # and 2) the ones that are really new and we need to insert
    # Be careful not to change dnr_hash after it has been added to
    # a set, because then the hash value might change and the set gets
    # confused.
    new_dnr_data = []
    updated_dnr_data = []
    dsf_data = [] # dsfs with values for drug_name_route_id
    # This section parallels the update procedure in load_ingredients.
    # Unfortunately, it is not sufficiently similar for a common method.
    @name_to_dnr.each do |name, dnr_hash|
      # For suppressed (which can mean retired) data we don't bother to update
      # the data table.  (If it wasn't suppressed before, the record was
      # suppressed by the global update above.)
      next if dnr_hash['suppress']
      
      new_code = dnr_hash['code']
      old_dnr = code_to_dnr_obj[new_code]
      if old_dnr
        attr_vals = old_dnr.attributes.merge!(dnr_hash)
        if old_dnr.code_is_old
          # Find latest, and update it (making it old)
          latest_old_attr_vals = mark_latest_dnr_old(new_code, updated_dnr_data)
          # Update old_dnr
          attr_vals.merge!({'code_is_old'=>false,
            'old_codes'=>latest_old_attr_vals['old_codes'] +
              latest_old_attr_vals['code'] + '|'})
          # Code reversion warning
          current_code = latest_old_attr_vals['code']
          puts "Warning:  DNR code #{current_code} changed back to #{new_code}"
        end
        if name != old_dnr.text
          puts "Warning:  For DNR code #{old_dnr.code} the name changed from "+
            "#{old_dnr.text} to #{name}"
        end
        # The record is not suppressed, so we need to update it to set
        # suppress back to false, because we set them all to true above.
        add_dnr_to_update(attr_vals, updated_dnr_data, dsf_data)
      else # We didn't find the DNR by code
        old_dnr = name_to_dnr_obj[name]
        old_codes = ''
        make_new_dnr = true
        if old_dnr
          if old_dnr.code_is_old
            # Find the latest, and update it (making it old)
            attr_vals =
              mark_latest_dnr_old(old_dnr.code, updated_dnr_data)
            # Name and code change warning
            puts "Warning:  Drug code #{attr_vals['code']} changed to "+
              "#{new_code} and the name changed back to an older name, #{name}"
          elsif old_dnr.code == nil
            # Just update the existing entry.
            make_new_dnr = false
            attr_vals = old_dnr.attributes.merge!(dnr_hash)
            add_dnr_to_update(attr_vals, updated_dnr_data, dsf_data)
          else
            # Update old_dnr to make it old
            attr_vals = mark_dnr_old(old_dnr, updated_dnr_data)
            # Code change warning
            puts "Warning:  Drug code #{attr_vals['code']} changed to "+
              new_code.to_s
          end
          # Make the old_codes attribute for the replacement record
          old_codes =  # (Note:  attr_vals['old_codes'] might be '')
            "#{attr_vals['old_codes'].chop}|#{attr_vals['code']}|"
        # else- Make new DNR, DSFs
        end
        if make_new_dnr
          # Make new DNR & DSFs;
          # however, the old_codes list will by non-empty in two cases.
          # (We will make the DSFs later when we know the DNR id).
          new_dnr_data << dnr_hash.merge({'old_codes'=>old_codes,
            'code_is_old'=>false})
        end
      end
    end

    puts "   Updating #{updated_dnr_data.size} DrugNameRoute records"
    if updated_dnr_data.size > 0
      # Update the existing records by dropping and re-inserting them.  It should
      # be much faster than individual updates.
      dnr_cols = DrugNameRoute.column_names
      dnr_rows = []
      updated_dnr_data.each {|h| dnr_rows << h.values_at(*dnr_cols)}
      rtn = DrugNameRoute.import(dnr_cols, dnr_rows,
        {:validate=>false, :on_duplicate_key_update=>dnr_cols})
      raise 'Some DNRs failed in the import' if rtn.failed_instances.size > 0
    end

    # Now insert the new records.  We need to learn the IDs created for each of
    # these, so we have to do these one at a time.
    puts "   Inserting #{new_dnr_data.size} DrugNameRoute records"
    new_dnr_data.each do |dnr|
      dnr_obj = DrugNameRoute.create!(dnr)
      dnr_obj_id = dnr_obj.id
      @name_to_dsfs[dnr['text']].each do |dsf|
        dsf['drug_name_route_id'] = dnr_obj_id
        dsf_data << dsf
      end
    end

    # Also update the DSF data
    puts "   Updating/inserting #{dsf_data.size} DrugStrengthForm records"
    dsf_col_names = DrugStrengthForm.column_names
    # Make a map from DSF rxcuis to DSF ids for the existing records
    rxcui_to_dsf_id = {}
    DrugStrengthForm.all.each {|dsf| rxcui_to_dsf_id[dsf.rxcui] = dsf.id}
    # Add the IDs to the drug strength form data
    dsf_values = []
    dsf_data.each do |dsf|
      dsf['id'] = rxcui_to_dsf_id[dsf['rxcui']]
      vals = dsf.values_at(*dsf_col_names)
      dsf_values << vals
    end
    rtn = DrugStrengthForm.import(dsf_col_names, dsf_values,
      {:validate=>false, :on_duplicate_key_update=>dsf_col_names})
    raise 'Some DSFs failed in the import' if rtn.failed_instances.size > 0

    puts "Finished saving data in #{Time.new-start} seconds."
  end


  # Updated by save_updates to add the data for a DNR and its DSFs to the
  # update lists.
  #
  # Parameters:
  # * attr_vals - the new attribute value for the DNR, including its ID.
  # * updated_dnr_data - an array of hashes of DNR attributes to be updated.
  #   This parameter will be updated by this method.
  # * dsf_data - an array of hashes of DSF data (with the drug_name_route_id
  #   assigned)
  #   This parameter will be updated by this method.
  def add_dnr_to_update(attr_vals, updated_dnr_data, dsf_data)
    old_dnr_id = attr_vals['id']
    updated_dnr_data << attr_vals

    # Add the DSFs to the update array
    dnr_dsf_data = @name_to_dsfs[attr_vals['text']]
    dnr_dsf_data.each do |dsf|
      dsf['drug_name_route_id'] = old_dnr_id
      dsf_data << dsf
    end
  end


  # Used by save_updates to find the current DrugNameRoute for the given
  # (obsolete) code and mark it as old.
  #
  # Parameters:
  # * obs_code - the obsolete code
  # * updated_dnr_data - an array of updated attributes for DrugNameRoute
  #   objects.  This will get the updated data for the DrugNameRoute this
  #   method finds.
  #
  # Returns:  the revised attributes for the DrugNameRoute that is found
  def mark_latest_dnr_old(obs_code, updated_dnr_data)
    latest_old_dnr = DrugNameRoute.find_current_for_code(obs_code)
    return mark_dnr_old(latest_old_dnr, updated_dnr_data)
  end


  # Used by save_updates to mark the given DrugNameRoute as old.
  #
  # Parameters:
  # * dnr - the old DrugNameRoute
  # * updated_dnr_data - an array of updated attributes for DrugNameRoute
  #   objects.  This will get the updated data for the given DrugNameRoute
  #
  # Returns:  the revised attributes for the DrugNameRoute
  def mark_dnr_old(dnr, updated_dnr_data)
    attr_vals = dnr.attributes
    attr_vals['suppress'] = true
    attr_vals['code_is_old'] = true
    updated_dnr_data << attr_vals
    return attr_vals
  end

end
