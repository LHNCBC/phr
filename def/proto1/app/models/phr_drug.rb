# This is an application specific model class.  Avoid putting general framework
# code here.
class PhrDrug  < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods
  
  belongs_to :drug_name_route, :foreign_key=>:name_and_route_C,
    :primary_key=>:code
  belongs_to :profile

  # Set up methods for accessing and working this model's lists
  # Status list
  init_nonsearch_list :drug_use_status,
    Proc.new{TextList.find_by_list_name('Drug Use Status').text_list_items},
    :code, :item_text
  # "Why Stopped" list
  init_nonsearch_list :why_stopped,
    Proc.new{TextList.find_by_list_name('why_stopped').text_list_items},
    :code, :item_text

  # A list of the fields that are dates
  DATE_FIELDS = ['drug_start', 'stopped_date', 'expire_date']

  # A list of codes of ingredients for drugs which are sometimes prescribed
  # simulateneously at different dose levels.
  MULTI_DOSE_INGREDIENTS = Set.new(['11289',  # Warfarin
                                    '10582',  # Thyroxine
                                    '42351',  # Lithium Carbonate
                                    '52105'])  # lithium citrate


  # When validating, convert the dates to HL7 and epoch time.
  def validate
    validate_cne_field(:drug_use_status)
    validate_cwe_field(:why_stopped)
    
    # Validate the drug name and code
    if name_and_route_C_changed?
      drug_info = DrugNameRoute.find_by_code(name_and_route_C)
      self.name_and_route = drug_info.text
    elsif name_and_route_changed?
      drug_info = DrugNameRoute.find_by_text(name_and_route)
      self.name_and_route_C = drug_info.code if (drug_info)
    elsif !name_and_route_C.blank? # load it anyway for future use
      drug_info = DrugNameRoute.find_by_code(name_and_route_C)
    end
    if name_and_route.blank?
      errors.add(:name_and_route, 'must not be blank')
    end

    # Validate the strength
    if drug_strength_form_C_changed?
      if drug_strength_form_C.blank?
        self.drug_strength_form = '' unless drug_strength_form_changed?
      else
        # In this case we should have drug_info.  We are not trying to validate
        # for all possible uses of this object.  The validation is primarily for
        # users of the web application.
        # Include the suppressed (retired) strengths in this lookup.  We have
        # a code, which changed, and regardless of whether it is old, the
        # text is needed.
        sf_info = drug_info.drug_strength_forms_all.find_by_rxcui(drug_strength_form_C)
        self.drug_strength_form = sf_info.text
      end
    end

    date_reqs = self.class.date_requirements(DATE_FIELDS, 'phr')
    DATE_FIELDS.each {|f| validate_date(f, date_reqs[f])}
  end


  # Returns the long version (based on concatenated RxNorm codes, and other
  # things) for the drug record.  There is a one to one correspondence between
  # name_and_route_C (the code we use in the application) and this code, which
  # was originally intended for internal purposes.  However, Dr. McDonald wants
  # it to be a part of the exported data because it contains RxNorm codes,
  # whereas name_and_route_C is a code we made up.
  def long_code
    code_rec = DrugNameRouteCode.find_by_code(name_and_route_C)
    return code_rec.nil? ? nil : code_rec.long_code
  end


  # Returns the codes of the drug classes for this drug, concatenated with |,
  # like |12|20|, or nil if there are no codes available.
  def drug_classes_C
    drug_name_route ? drug_name_route.drug_class_codes : nil
  end


  # Returns the class names of the drug's classes, concatenated with |,
  # like |a|b|, or nil if there are no classes available.
  def drug_classes
    drug_name_route ? drug_name_route.drug_class_names : nil
  end


  # Returns the codes of the ingredients, concatenated with |, like |12|20|,
  # or nil if the ingredient codes are not available.
  def drug_ingredients_C
    drug_name_route ? drug_name_route.ingredient_rxcuis : nil
  end


  # Returns the names of the ingredients, concatenated with |, like |a|b|,
  # or nil if the ingredients are not known.
  def drug_ingredients
    drug_name_route ? drug_name_route.ingredient_names : nil
  end

  # Returns the route codes for this drug, concatenated with |, like |12|20|,
  # or nil if the route codes are not available.
  def drug_routes_C
    drug_name_route ? drug_name_route.route_codes : nil
  end

  # Returns the names of the drug's routes, concatenated with |, like |a|b|,
  # or nil if the routes are not known.
  def drug_routes
    drug_name_route ? drug_name_route.route_names : nil
  end


  # Returns information for links about this drug.  If one link is found,
  # that will be the return value otherwise the return value will be an array
  # where each element is a two-element array consisting of a URL and a label
  # for the URL.
  def info_link
    data = drug_name_route.info_link_data if drug_name_route
    if !data ||data.size == 0
      data = 'http://search.nlm.nih.gov/medlineplus/query?' +
             'MAX=500&SERVER1=server1&SERVER2=server2&' +
             'DISAMBIGUATION=true&FUNCTION=search&PARAMETER=' +
             URI.escape(name_and_route)
    end
    return data
  end



  # Returns the form modifier of a drug as it appears in the drug's name
  # and route string.  The form modifier is something like "XR", or "EC".
  # [Ported from appSpecific.js]
  #
  # Parameters:
  # * rowData - the data model's data for the drug entry
  #
  # Returns: the form modifier, or the empty string if there isn't one.
 def get_drug_form_modifier
    # [Ported from appSpecific.js, so if you change this, change that one too.]
   name_and_route =~ / (XR|EC|\d\d\/\d\d|U\d+) \(/
   return $1 && $1.length>1? $1 : ''
 end


  # Checks whether this record, if saved, would possibly conflict with
  # other near-duplicate records.  [Ported from appSpecific.js]
  #
  # Returns:  nil if no warnings are needed, or an array of arrays of data
  # about exact duplicates, complete ingredient-route duplicates,
  # ingredient & equivalent route duplicates, and shared ingredient matches.
  def dup_check
    # Note:  The logic here has been ported from appSpecific.js'
    # drugConflictCheck, so if you change it here you should also update it
    # there.
    rtn = nil
    # Make sure this record (that changed) is not inactive.  If it is, we
    # don't show warnings.
    if drug_use_status_C != 'DRG-I'
      name_route_duplicates = []
      drug_route_duplicates = []  # full ingredient match and route match
      equivalent_route_matches = []
      shared_ingredient_matches = []
      route_code_regex = nil
      ingredient_texts = nil
      ingredient_codes = nil
      have_warning = false
      row_form_mod = get_drug_form_modifier
      route_code_regex = nil
      drugs = profile.phr_drugs
      drugs = drugs.where(["id != ?", id]) if id
      drugs.each do |drug|
        # Only consider active drugs
        if drug.drug_use_status_C != 'DRG-I'
          # Check for duplicate name and route entries
          if drug.name_and_route == name_and_route
            name_route_duplicates << drug.name_and_route
            have_warning = true
          elsif drug_ingredients_C  # otherwise no further checks
            # Check for an complete match on ingredients and route
            if drug.drug_ingredients_C == drug_ingredients_C
              if drug.drug_routes_C == drug_routes_C &&
                                     row_form_mod == drug.get_drug_form_modifier
                drug_route_duplicates << drug.name_and_route
                have_warning = true
              else
                # Check for a complete match on ingredients and an
                # equivalent route.
                if !route_code_regex
                  route_code_regex =
                    self.class.build_route_code_regex(drug_routes_C)
                end
                if drug.drug_routes_C =~ route_code_regex
                  equivalent_route_matches << drug.name_and_route
                  have_warning = true
                end
              end
            else
              # See if there is a shared ingredient with this drug
              if !ingredient_codes
                ingredient_codes = PredefinedField.parse_set_value(drug_ingredients_C)
                ingredient_texts = PredefinedField.parse_set_value(drug_ingredients)
              end
              check_codes = PredefinedField.parse_set_value(drug.drug_ingredients_C)
              check_code_set = Set.new(check_codes)
              matched_ingredients = []
              ingredient_codes.each_with_index do |ing_code, j|
                if check_code_set.member?(ing_code)
                  matched_ingredients << ingredient_texts[j]
                end
              end
              if matched_ingredients.length > 0
                shared_ingredient_matches << [drug.name_and_route, matched_ingredients]
                have_warning = true
              end
            end
          end
        end

        if have_warning
          rtn = [name_route_duplicates, drug_route_duplicates,
                 equivalent_route_matches, shared_ingredient_matches]
        end
      end # for each other drug
    end # if this drug is not inactive
    return rtn
  end


  # Returns true if this drug contains one of the MULTI_DOSE_INGREDIENTS.
  def has_multi_dose_ing
    rtn = false
    ing_codes = drug_ingredients_C
    if ing_codes
      PredefinedField.parse_set_value(ing_codes).each do |code|
        rtn = MULTI_DOSE_INGREDIENTS.member?(code)
        break if rtn
      end
    end
    return rtn
  end


  # Builds a regular expression for checking whether another drug's route
  # is equivalent (in the sense of posing a potential conflict) with the
  # given route codes (from the 'drug_routes_C' column).
  #
  # Parameters:
  # * route_codes - the route codes of the drug for which potential conflicts
  #   are being sought.  This should be the value from the drug's drug_routes_C
  #   column.
  def self.build_route_code_regex(route_codes)
    # [Ported from appSpecific.js, so if you change this, change that one too.]
    # Build a list of routes to be considered.
    route_code_array = PredefinedField.parse_set_value(route_codes)
    # If the route_code_array contains the mixed route, make sure it also
    # contains systemic, and vice versa, because if something is mixed it
    # it may be systemic, and want to warn about matches.
    # Also, add the delimiter character around each code to aid in
    # comparisons.
    has_mixed = false
    has_systemic = false
    route_code_array.each do |route_code|
      has_systemic = true if route_code == 'RC1'
      has_mixed = true if route_code == 'RC3'
    end
    if has_mixed && !has_systemic
      route_code_array << 'RC1'
    elsif has_systemic && !has_mixed
      route_code_array << 'RC3'
    end

    # Build something that will match a route code in route_code_array
    # surrounded by SET_VAL_DELIM.
    escaped_set_val_delim = SET_VAL_DELIM.gsub('|', '\\|')
    return Regexp.new(escaped_set_val_delim +
      route_code_array.join(escaped_set_val_delim + '|' +
                            escaped_set_val_delim) +
      escaped_set_val_delim)
  end

end
