class ListDetail < ActiveRecord::Base
  extend HasSearchableLists
  extend HasShortList # not very short...
  set_up_searchable_list(nil, [:display_name])

  # The name of the column in the table that should be matched against
  # the "pattern" argument of HasShortList.get_list_items.
  def self.pattern_col
    'display_name'
  end
  
  # Returns the columns to be listed for the "Display" field on the
  # form builder.  Controls what columns are shown in the list of values
  # the user may choose from.  This is a separate method because the search
  # list can differ from the display list, depending on whether or not there
  # are multiple values in the text_column.
  def get_display_vals
    return get_list_cols_both('display')
  end
  
  # Returns the columns to be listed for the "Allowed Inputs" field on the
  # form builder.  Controls what columns are searched for values the user
  # enters in a search field.  This is a separate method because the search
  # list can differ from the display list, depending on whether or not there
  # are multiple values in the text_column.
  def get_inputs_vals
    return get_list_cols_both('search')
  end
  
  # This returns an array of values to display as list options.  It is
  # assumed that the list options will be presented to a form designer
  # to choose which list fields - the ID, the text, or BOTH, will be 
  # displayed for the list.
  #
  # If the value in the id_column and the text_column of the current 
  # list_details row match, the array returned is empty.
  # If they don't match, the array will contain 3 elements.  The first
  # two will be the return from get_list_cols, and the third will be
  # the word "BOTH"
  #
  def get_list_cols_both(list_type=nil)
    if (self.id_column == self.text_column)
      rtn = []
    else
      rtn = self.get_list_cols(list_type)
      if rtn[1].include? ' & '
        rtn[2] = 'ALL'
      else
        rtn[2] = 'BOTH'
      end
    end
    return rtn  
  end
  
  # This returns an array of values to display as list options.  It is
  # assumed that the list options will be presented to a form designer
  # to choose which list fields - the ID or the text -  will be displayed
  # for the list.
  #
  # If the value in the id_column and the text_column of the current 
  # list_details row match, the array returned is empty.
  # If they don't match, the array will contain 2 elements.  The first
  # will be the field name in id_column followed by the word "only".
  # The second will be the field name in the text_column followed by 
  # the word "only" - UNLESS the value in the text_column contains
  # multiple values.  In that case the second array element will contain
  # each element.
  #  
  def get_list_cols(list_type=nil)
    rtn = []
    if (self.id_column != self.text_column)
      rtn[0] = self.id_column + ' only'
      if (self.text_column.include? ',')
        if (list_type == 'search')
          tx_ary = self.text_column.split(',') 
          tx_ary.each do |ta|
            if ta == tx_ary.first
              rtn[1] = ta
            elsif ta != tx_ary.last
              rtn[1] += ', ' + ta
            else
              rtn[1] += ' & ' + ta
            end
          end # do for each word
        else # not a search list
          rtn[1] = self.text_column[0, self.text_column.index(',')]
        end # if there's more than one word
      else
        rtn[1] = self.text_column + ' only'
      end
    end
    return rtn
  end
  
  # This returns a control type that should be used for the field
  # using the list.
  # 
  # If the control_type_template text contains a prefetch parameter
  # (which should always be true if it's specified), this will return
  # a value of "text_field".  If not it will return "search_field".
  #
  def get_control_type
    if (self.control_type_template.include? "prefetch")
      rtn = 'text_field'
    else
      rtn = 'search_field'
    end
    return rtn
  end
end
