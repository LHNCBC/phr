# Two instance methods of classified model for retrieving list of class names or
# class codes concatenated in a string. These two methods are currently used in
# current_value_for_field field of db_field_descriptions table
# 
# (see value of field problem_classes or problem_classes_C on PHR form)
module HasClassification
  
  # Returns list of classes names for this classified record
  def classification_names
    # If we're caching ActiveRecord objects, we might as well cache the class
    # values too.
    if USE_AR_CACHE
      if !@classification_names
        @classification_names = retrieve_classification_names_codes
      end
      rtn = @classification_names
    else
      rtn = retrieve_classification_names_codes
    end
    return rtn
  end


  # Returns list of classes codes for this classified record
  def classification_codes
    # If we're caching ActiveRecord objects, we might as well cache the class
    # values too.
    if USE_AR_CACHE
      if !@classification_codes
        @classification_codes = retrieve_classification_names_codes(true)
      end
      rtn = @classification_codes
    else
      rtn = retrieve_classification_names_codes(true)
    end
    return rtn
  end


  # Returns list of classes codes for this classified record as an array.
  def classification_codes_array
    retrieve_classification_names_codes_array(true)
  end

  
  def code_value
    self.send(self.class::DEFAULT_CODE_COLUMN)
  end


  private
  # Returns list of classes names/codes based on input parameter
  # Per Paul, we assume for any class item list, if it has been classified using
  # one attribute, then it cannot be classified using other attributes 
  # 
  # Parameters:
  # * retrieve_code - specify whether to get list of code or value
  def retrieve_classification_names_codes(retrieve_code = false)
    PredefinedField.make_set_value(
      retrieve_classification_names_codes_array(retrieve_code))
  end


  # Returns list of classes names/codes based on input parameter
  # Per Paul, we assume for any class item list, if it has been classified using
  # one attribute, then it cannot be classified using other attributes
  #
  # Parameters:
  # * retrieve_code - specify whether to get list of code or value
  def retrieve_classification_names_codes_array(retrieve_code = false)
    class_item_table = self.class.table_name
    searching_column = "item_master_table" 
    
    # handle the case when list items (e.g. immunizations) are stored in text_list
    if class_item_table == "text_list_items"   
      searching_column = "list_identifier"
      class_item_table = text_list.list_name
    end
    
    # Select all classes by table_name and code value of current record
    class_list = Classification.where( ["ld.#{searching_column} like ? and dc.item_code like ?",
        class_item_table, self.send("code_value")]).select("c.class_code, c.class_name").
     joins( "c left join `list_descriptions` ld " +
        " on c.list_description_id = ld.id " +
        " left join `data_classes` dc on c.id = dc.classification_id")
    rtn_list_type = retrieve_code ? "class_code" : "class_name"
    rtn_list = class_list.map{|e| e.send(rtn_list_type)}
  end
end
