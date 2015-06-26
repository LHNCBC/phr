# To change this template, choose Tools | Templates
# and open the template in the editor.

class LoincName < ActiveRecord::Base
  validates_uniqueness_of :loinc_num
  validates_presence_of :loinc_num

  extend HasSearchableLists

  def display_name_for_sort
    display_name
  end

  # update names in the loinc names table when there's a change in the loinc 
  # item names in loinc_items table
  def self.update_myself(rebuild_index = false)
    
    # delete existing record
    LoincName.delete_all
    
    loinc_items = LoincItem.find_all_by_is_searchable(true)
    loinc_items.each do |item|
      if item.is_panel?
        type = "Panel"
        code = "P"
      else
        type = "Test"
        code = 'T'
      end
      # create a record,
      LoincName.create!(
        :loinc_num => item.loinc_num,
        :loinc_num_w_type => code + ':' + item.loinc_num,
        :display_name => item.display_name,
        :display_name_w_type => item.display_name + " (#{type})",
        :type_code => code,
        :type_name => type,
        :component => item.component,
        :short_name => item.shortname,
        :long_common_name => item.long_common_name,
        :related_names => item.relatednames2,
        :consumer_name => item.consumer_name
      )
    end
    
    # rebuild ferret index
    if (rebuild_index) 
      self.rebuild_index
    end    
  end
  
 # auto completer
  set_up_searchable_list(:loinc_num,
     [:display_name, :loinc_num, :component, :short_name, :long_common_name,
       :related_names, :type_name, :type_code, :consumer_name, :display_name_w_type],
     [:display_name_for_sort]
     )
end
