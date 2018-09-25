class LoincPanel < ActiveRecord::Base
  cache_associations

  has_many :sub_fields, -> { order "sequence_num" }, class_name: "LoincPanel", foreign_key: :p_id

  belongs_to :loinc_item
#          :foreign_key => 'loinc_num',
#          :primary_key => 'loinc_num'
#         :finder_sql => 'select i.* from loinc_items i ' +
#             'where i.loinc_num = \'#{loinc_num}\''
  delegate :display_name, :to => :loinc_item
  validates_presence_of :loinc_item_id
  validates_presence_of :loinc_num

  # get sub fields by checking the excluded_in_phr flag
  # deprecated, used only in loinc_preparation.rb
  def subFields_old
    #LoincPanel.where(p_id: id).order('sequence')
    subfields = sub_fields
    # do not use subfield.delete(..), which deletes records in database
    rtn = []
    subfields.each do |field|
      if !field.loinc_item.is_excluded? &&
            field.observation_required_in_phr !='X'
        rtn << field
      end
    end
    return rtn
  end

  # get sub fields by checking the included_in_phr flag
  def subFields(check_use_flag = true)
    # do not use subfield.delete(..), which deletes records in database
    rtn = []
    if !check_use_flag
      rtn += sub_fields
    else
      # Relying on the caller to have already included loinc_item in the sub
      # fields. If you put in .includes here, it does a new search for
      # subfields. For an example of a caller doing that include of
      # loinc_items, see panel_data.rb.
      #sub_fields.includes(:loinc_item).each do |field|
      sub_fields.each do |field|
        if field.loinc_item.is_included?
          rtn << field
        end
      end
    end
    return rtn
  end

  # get loinc_nums of all the test fields defined in the panel
  def obx_field_loinc_nums
    rtn = []
    fields = subFields
    fields.each do |field|
      if field.id != field.p_id
        if field.has_sub_fields?
          rtn += field.obx_field_loinc_nums
        else
          rtn << field.loinc_num
        end
      end
    end
    return rtn
  end


  def is_top_level?
    # if it is a panel and it is top level
    if !loinc_item.nil? && loinc_item.is_panel? && p_id == id
      return true
    end
    return false
  end

  def has_sub_fields?
    subfields = subFields
    if !subfields.nil? && subfields.length > 0
      return true
    end
    return false
  end

  # possible value for observation_required_in_phr
  # 'R'   -- required
  # 'O'   -- optional
  # 'C'   -- conditional
  # 'X'   -- excluded
  # ''    -- treated as required
  # nil   -- treated as required
  def required_in_panel?
    rtn = false
    if observation_required_in_phr.nil? ||
          !observation_required_in_phr.nil? &&
          observation_required_in_phr != 'O'

      rtn = true
    end
    return rtn
  end

  def get_last_result(profile_id=nil)
    rtn = nil
    if !profile_id.nil?
      results = ObxObservation.where('loinc_num=? AND profile_id=? AND obx5_value IS NOT NULL',
          loinc_num, profile_id).order('test_date_ET DESC')
      if !results.nil? && results.length >0
        rtn = results[0]
      end
    end
    return rtn
  end

  def root
    id == p_id ? self : LoincPanel.find(p_id).root
  end

  def parent
    id == p_id ? self : LoincPanel.find(p_id)
  end

  # get the loinc_nums of all the tests within this panel
  # excluding sub panels loinc_num
  def get_all_test_loinc_nums(check_use_flag = true)
    loinc_nums = []
    loinc_panel_records = []

    self.get_all_sub_fields(loinc_panel_records, check_use_flag)
    loinc_panel_records.each do |record|
      if (record.loinc_item.is_test?)
        loinc_nums << record.loinc_num
      end
    end

    return loinc_nums
  end

  # get all the fields for the panel, including
  # the all the sub panels and tests
  def get_all_sub_fields(loinc_panel_records = [], check_use_flag = true)

    fields = self.subFields(check_use_flag)

    fields.each do |field|
      loinc_panel_records << field
      if field.id != field.p_id
        field.get_all_sub_fields(loinc_panel_records, check_use_flag)
      end
    end
  end

  # Returns the LoincPanel records for the panel LOINC numbers, in the order
  # the LOINC numbers are listed.
  #
  # Parameters:
  # * loinc_nums - The array of panel (except single test panels) LOINC numbers
  #               for which the LoincPanel records are needed.
  def self.find_panels_in_order(loinc_nums)
    loinc_num_to_rec = {}
    LoincPanel.where('loinc_num in (?) and id=p_id', loinc_nums).each {|lp|
      loinc_num_to_rec[lp.loinc_num] = lp
    }
    rtn = []
    loinc_nums.each {|ln| rtn << loinc_num_to_rec[ln]}
    return rtn
  end
end

