# A base class for user data tables where the primary field comes from a
# text list (e.g. phr_allergies), but written as a module, so we don't have to
# create a table for the base class.
module TextListUserData
  include UserData
  module ClassMethods # Intended to be class methods on the class that extends this
    include UserData::ClassMethods

    # Performs "base class" initialization of this module.  Should be called
    # by the sub-class.
    def init_text_list_user_data
      # Set up methods for accessing and working this model's lists (in basic
      # mode).
      model_lists.each do |ar|
        init_nonsearch_list ar[0],
          Proc.new{TextList.find_by_list_name(ar[1]).text_list_items},
          :code, :item_text
      end
    end

    # Should be defined by the sub-class.
    # Returns the ID of the TextList for the primary field for this record.
    def primary_list_id
      raise NotImplementedError
    end

    # Should be overridden by the sub-class as needed.
    # Returns the array of field names of the date fields to be validated.
    def date_fields
      []
    end

    # Should be defined by the sub-class.
    # Returns the column name of the field holding the primary list for the record.
    def primary_field
      raise NotImplementedError
    end

    # Should be defined by the sub-class.
    # Returns the lists this class will use.  Each element will get passed to
    # init_nonsearch_list.
    def model_lists
      raise NotImplementedError
    end
  end


  # When validating, convert the dates to HL7 and epoch time.
  def validate_text_list_user_data
    cl = self.class
    pf = cl.primary_field
    validate_cwe_field(pf)

    # Set blank codes to nil
    pf_C = cl.code_field(pf)
    if (send("#{pf_C}_changed?") || send("#{pf}_changed?")) && send(pf_C).blank?
      self.send(pf_C+'=', nil)
    end

    if send(pf).blank?
      errors.add(pf, 'must not be blank')
    end

    date_fields = cl.date_fields
    date_reqs = cl.date_requirements(date_fields, 'phr')
    date_fields.each {|f| validate_date(f, date_reqs[f])}
  end


  # Returns an info URL for the record.
  def info_link
    rtn = nil
    cl = self.class
    code = send(cl.code_field(cl.primary_field))
    if code
      master_record = TextListItem.find_by_text_list_id_and_code(
        cl.primary_list_id, code)
      if master_record
        rtn = master_record.info_link
      end
    end
    return rtn
  end

end
