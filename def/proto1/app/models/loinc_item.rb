class LoincItem < ActiveRecord::Base
  has_many :loinc_panels, :dependent=>:destroy
  has_many :loinc_units, :dependent=>:destroy
  belongs_to :answer_list, :foreign_key=>:answerlist_id
#  :foreign_key => 'loinc_num',
#  :primary_key => 'loinc_num'
        #   :finder_sql=> 'select p.* from loinc_panels p ' +
        #     'where p.loinc_num = \'#{loinc_num}\''

  validates_uniqueness_of :loinc_num
  validates_presence_of :loinc_num
  
  extend HasSearchableLists

  cache_recs_for_fields 'id', 'loinc_num'

  # is this loinc item a test panel?
  def is_panel?
    return is_panel
  end

  def has_top_level_panel?
    return is_panel && has_top_level_panel
  end
  
  # check if this loinc item is excluded from phr
  # deprecated, used only in loinc_preparation.rb
  def is_excluded?
    return excluded_from_phr
  end

  # check if this loinc item is included in phr
  def is_included?
    return included_in_phr
  end

  # is this loinc item a test in a test panel?
  def is_test?
    return !is_panel?
  end

  # get the display name
  def display_name
    if !is_panel? && !loinc_class.nil? && loinc_class.match(/SURVEY/)
      relma_display_name
    else
      loinc_display_name
    end
  end

  # get the display name with type
  def display_name_w_type
    if is_panel?
      ret = display_name + " (Panel)"
    else
      ret = display_name + " (Test)"
    end

    return ret
  end
  
# not used, in handle_data_req of FormController,
#  norm_range needs to be a actual column name
# 
#  # redefine norm_range
#  def norm_range
#    range_text = read_attribute(:norm_range)
#    if range_text.blank?
#      high_text = read_attribute(:norm_high)
#      low_text =  read_attribute(:norm_low)
#      if !high_text.blank?
#        if !low_text.blank?
#          range_text = low_text + " - " + high_text
#        else
#          range_text = " - " + high_text
#        end
#      elsif !low_text.blank?
#        range_text = low_text + " - "
#      end
#    end
#    return "range_text"
#  end


  # Provides units and associated ranges for the current loinc_item.
  #
  # Returns:  an array containing three arrays:
  #  * an array of the unit values defined for the current loinc item;
  #  * an array of the corresponding loinc_units ids; and
  #  * an array of the loinc_unit table rows for the current loinc item.
  #
  def units_and_codes_and_ranges
    rtn = nil
    if !loinc_num.blank?
      list = LoincUnit.find(:all, :conditions => ["loinc_num=?",loinc_num],
        :order=>"id ASC")
      if list.nil? || list.length <=0
        rtn = nil
      else
        items = []
        codes = []
        list.each do |rec|
          items << (rec.unit.nil? ? '' : rec.unit)
          codes << rec.id
        end
        rtn = [items, codes, list]
      end
    end
    return rtn
  end


  # get list items and codes from answer list if there's one
  def answers_and_codes
    rtn = nil
    if !answerlist_id.blank?
      list = ListAnswer.find(:all, :conditions => ["answer_list_id=?",answerlist_id],
        :order=>"sequence_num ASC")
      if list.nil? || list.length <=0
        rtn = nil
      else
        items = []
        codes = []
        list.each do |rec|
          items << rec.answer_text
          codes << rec.code
        end
        rtn = [items, codes]
      end
    end
    return rtn
  end


  # pick up a diaplay name ion the follwoing priority
  # 1. phr_display_name
  # 2. long_common_name
  # 3. shortname
  # 4. concatenated LOINC name
  def loinc_display_name
    name = ''
    if !phr_display_name.blank?
      name = phr_display_name
    elsif !long_common_name.blank?
      name = long_common_name
    elsif !shortname.blank?
      name = shortname
    else
      tmp_array = []
      tmp_array << component unless component.blank?
      tmp_array << property unless property.blank?
      tmp_array << time_aspct unless time_aspct.blank?
      tmp_array << loinc_system unless loinc_system.blank?
      tmp_array << scale_typ unless scale_typ.blank?
      tmp_array << method_typ unless method_typ.blank?
      name = tmp_array.join(':')
    end
    return name
  end

  # pick up a diaplay name ion the follwoing priority
  # 1. phr_display_name
  # 2. long_common_name
  # 3. shortname
  # 4. component
  # 5. concatenated LOINC name
  def relma_display_name
    name = ''
    if !phr_display_name.blank?
      name = phr_display_name
    elsif !long_common_name.blank?
      name = long_common_name
    elsif !shortname.blank?
      name = shortname
    elsif !component.blank?
      name = component
    else
      tmp_array = []
      tmp_array << component unless component.blank?
      tmp_array << property unless property.blank?
      tmp_array << time_aspct unless time_aspct.blank?
      tmp_array << loinc_system unless loinc_system.blank?
      tmp_array << scale_typ unless scale_typ.blank?
      tmp_array << method_typ unless method_typ.blank?
      name = tmp_array.join(':')
    end
    return name
  end

# filtered names are not unique. -- 5/22/2012, Ye
# 
#  # rewrite long_common_name
#  # to remove anything with '[' and ']' including the '[' and ']' and/or extra
#  # space around '[' and ']'
#  # For example:
#  # DBG Ab [Presence] in Serum or Plasma
#  # ==>
#  # DBG Ab in Serum or Plasma
#  def long_common_name
#    lc_name = read_attribute(:long_common_name)
#    if !lc_name.nil?
#      lc_name.gsub!(/\s*\[.*\]\s*/, ' ')
#      lc_name.strip!  # e.g. "Ab [Presence]" ==> "Ab "
#    end
#    return lc_name
#  end

  
  # Define a duplicate of the "display_name" model-derived method that will
  # be used for sorting the results when searching.  ("display_name" gets
  # tokenized; this one won't be.
  def display_name_for_sort
    return self.display_name
  end

  # Get the data type of the loinc item
  def data_type
    data_type = hl7_v3_type
    if data_type.blank?
      data_type = datatype
      if data_type.nil?
        data_type = ''
      end
    end
    return data_type
  end
  
  # Returns the records for the LOINC numbers, in the order the LOINC
  # numbers are listed.
  #
  # Parameters:
  # * loinc_nums - The array of LOINC numbers
  #               
  def self.find_in_order(loinc_nums)
    loinc_num_to_rec = {}
    LoincItem.find(:all,
          :conditions=>["loinc_num in (?)", loinc_nums]).each {|lp|
      loinc_num_to_rec[lp.loinc_num] = lp
    }
    rtn = []
    loinc_nums.each {|ln| rtn << loinc_num_to_rec[ln]}
    return rtn
  end
  
  # autocompleter
  set_up_searchable_list(:loinc_num,
     [:display_name, :shortname, :long_common_name,
       :relatednames2, :component, :loinc_num, :is_panel, :has_top_level_panel,
       :excluded_from_phr, :included_in_phr],
     [:display_name_for_sort]
     )
end
