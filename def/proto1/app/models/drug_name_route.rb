# Records of this class support the name & route field of the drug
# table on FFAR forms.  For updating these tables, use RxtermsUpdater.
class DrugNameRoute < ActiveRecord::Base
  extend HasChangingCodes
  has_many :drug_strength_forms, -> {where 'suppress != true'; order 'text, id'}

  # Note:  We used to have " :dependent=>:delete_all," in the has_many.
  # However, because the :conditions clause is present, only the DSFs with
  # suppress=false were deleted.

  has_many :drug_strength_forms_all, # all including suppressed ones
    :class_name=>'DrugStrengthForm'

  extend HasSearchableLists
  set_up_searchable_list(:code, [:text, :synonyms, :suppress], [:frequency])


  # Returns a list of the "text" fields of the DrugStrengthForm instances
  # associated with this record.  The returned data structure is a two-element
  # array, the first element of which is the data for the list items and the
  # second element of which is the array of codes for the list items.
  # Parameters:
  # * conditions -  (optional) a condition, a list of conditions, or a hashmap
  #   of conditions to be added to the normal matching statement for rows
  #   to be included in the results from the list named by the name parameter.
  def strength_form_list(cond=nil)
    list_items = []
    codes = []

    dsf_recs = DrugStrengthForm.where(drug_name_route_id: id, suppress: false).
      order('text, id')
    if cond
      case cond
      when Array
        cond.each {|c| dsf_recs = dsf_recs.where(c)}
      when String, Hash
        dsf_recs = dsf_recs.where(cond)
      end
    end

    dsf_recs.each do |df|
      list_items << df.text
      codes << df.rxcui
    end
    return [list_items, codes]
  end


  # Returns the data for the strength and form table selection list for this
  # drug.  The returned data structure is a two-element array, the first
  # element of which is the data for the list items and the second element
  # of which is the array of codes for the list items.  The first array is
  # actually an array of array, with the inner array containing the form and
  # strength values for that list item.
  def strength_form_array
    list_items = []
    codes = []
    drug_strength_forms.each { |df|
      list_items << [df.form, df.strength]
      codes << df.rxcui
    }
    return [list_items, codes]
  end


  # Returns an array of instances of RxtermsIngredient for the ingredients of
  # this drug, in the same order as listed in the ingredient_rxcuis field.
  def ingredients
    if !@ingredients
      @ingredients = []
      PredefinedField.parse_set_value(ingredient_rxcuis).each do |rxcui|
        @ingredients << RxtermsIngredient.find_by_ing_rxcui(rxcui)
      end
    end
    return @ingredients
  end


  # Returns a '|' delimited list of ingredient names for this drug  Names
  # are returned in the same order as the codes in ingredient_rxcuis.
  def ingredient_names
    if !@ingredient_names
      @ingredient_names =
        PredefinedField.make_set_value(ingredients.collect {|ing| ing.name},
                                       false)
    end
    return @ingredient_names
  end


  # Returns a '|' delimited list of drug class names for this drug.  Names
  # are returned in the same order as the codes in drug_class_codes.
  def drug_class_names
    if !@drug_class_names
      names = []
      class_codes = PredefinedField.parse_set_value(drug_class_codes)
      Classification.where(class_code: class_codes).each do |drug_class|
        if drug_class.class_type.class_code == "drug"
          names << drug_class.class_name
        end
      end
      @drug_class_names = PredefinedField.make_set_value(names, false)
    end
    return @drug_class_names
  end


  # Returns a '|' delimited list of drug class names for this drug.  Names
  # are returned in the same order as the codes in route_codes.
  def route_names
    # Note:  Though we could use find_all_by to get all these names in one
    # request, we need to make sure the names are returned in the same
    # order as the codes in route_codes, and there is no reliable way of
    # making sure that happens other than getting them one at a time.
    # If this becomes a performance issue, we will need to precompute this
    # value and store it, as a part of the data update (just as we do
    # for route_codes).
    if !@route_names
      names = []
      PredefinedField.parse_set_value(route_codes).each do |code|
        names << DrugRoute.find_by_code(code).name
      end
      @route_names = PredefinedField.make_set_value(names)
    end
    return @route_names
  end


  # Returns the patient version of the route for the route field of the drug
  # entry form.
  def patient_route
    cm = ClinicalMap.find_by_lookup_field(route)
    return cm.nil? ? nil : cm.patient_text
  end


  # Returns the clinician version of the route for the route field of the drug
  # entry form.
  def clinician_route
    cm = ClinicalMap.find_by_lookup_field(route)
    return cm.nil? ? nil : cm.clinician_text
  end


  # Returns data for information links about this drug.
  #
  # Parameters:
  # * drug_name - the selected drug
  #
  # Returns:
  # An array of length 2 arrays.  Each entry is URL and page title for an
  # MplusDrug page related to this drug.
  # Returns array size zero if no matches meet query conditions.
  def info_link_data
    rtn = []
    # Get the drug strength forms, including the old, suppressed ones,
    # because our map is old and uses old RxCUIs.
    rxcuis = drug_strength_forms_all.collect {|dsf| dsf.rxcui}
    # fetch unique related M+ links for rxcuis
    recs = RxnormToMplusDrug.select('distinct urlid,  mplus_page_title').
       where(:rxcui=>rxcuis).order(:mplus_page_title).load
    if recs.length > 0
      recs.collect {|rec| rtn << [rec.mplus_drug_url() , rec.mplus_page_title]}
    end
    rtn
  end


  # Returns a count of the number of times the drug was prescribed,
  # based on a data set from RxHub.  If the count is not found, the
  # return value is 0.1.
  def frequency
    # Use the count for the drug's display name (the "text" field).
    # We will find this count in the rxhub_frequencies table via the
    # DrugNameRoute's rxcuis.  This could be precomputed, but should only be
    # needed once per RxTerms update (when the Ferret index for this table
    # is rebuilt), so for now we are doing the searching here.
    dnr_cuis = Set.new
    # In finding the RxCUIS for the drug, we need to include the
    # old, suppressed ones, because the RxhubFrequency is not updated
    # (at least not as often as the RxTerms data).
    drug_strength_forms_all.each {|df| dnr_cuis << df.rxcui}
    rx_freq = UnitedHealthFrequency.where(:rxcui=>dnr_cuis.to_a).first

    rx_freq ? rx_freq.display_name_count : 0.1
  end


  # Override Ferret's to_doc method, to assign a boost value to the document.
  def to_doc
    doc = super
    doc.boost = frequency
    return doc
  end

  private

  # See active_record_extensions.rb's find_record.  The override here
  # handles the case where the found drug record has an old code by returning
  # the newer one in its place (if a newer one is found).
  #
  # Parameters:
  # * input_fields - a hash from field names (column names) for this table
  #   to values.  Together the entries in input_fields should specify a
  #   particular record in the table.
  def self.find_record(input_fields)
    rtn = super(input_fields)
    if rtn and rtn.code_is_old
      newer = find_current_for_code(rtn.code)
      rtn = newer if newer
    end
    return rtn
  end

end # drug_name_route.rb

