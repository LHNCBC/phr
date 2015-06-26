module ModifyTables

  # This method performs phrase substitutions and record deletions on the given
  # table.
  # Parameters:
  # * table_name - the name of the table to modify
  # * column_name - the name of the column to be modified (and to check as to
  #   whether the record should be deleted.
  # * delete_list - entries whose column name contains one of the phrases in
  #   this list will be deleted.  Note:  The comparison is case-sensitive.
  #   This can be nil, in which case the remaining arguments are ignored, and
  #   the method loads data from the files: 
  #   /proj/def/proto1/config/substitute_in_union_bn_2007AA.txt and
  #   /proj/def/proto1/config/exclude_in_union_bn_2007AA.txt (for deletions).
  # * subst_keys - a list of phrases to be substituted (case-insenstive).  The
  #   substitions are performed in the order of the items in this list.
  # * subst_map a map from the items in subst_keys to replacement strings
  def modify_table_entries(table_name, column_name, del_list_file_name, 
                           sub_list_file_name, delete_list=nil, subst_keys=nil, 
                           subst_map=nil)    
    if (delete_list==nil)
      get_phrases(del_list_file_name, sub_list_file_name)
    else
      # Set up the data members that get_phrases sets up
      @phrases_delete = '(' + delete_list.join('|') + ')'
      @phrases_sub = subst_keys
      @sub_phrase_counter = subst_keys.length
      @sub_hash = subst_map
    end

    @table_class = table_name.singularize.camelize.constantize
    dg = @table_class.find_all
    dg.each do |o|
      current_entry = o.send(column_name)
      no_phrase_match = make_substitutions(current_entry, del_list_file_name)
      if (no_phrase_match.nil? && !del_list_file_name.nil?) 
      #Delete entries containing delete phrases
        o.destroy
      else
        if @changed
          o.send(column_name+'=', no_phrase_match)
          o.save
        end  #end if
      end #end if/else
    end #end do |o|
  end #end modify_table_entries

  #Reads the files containing the phrases to be substituted and deleted and
  #stores this information
  def get_phrases(del_list_file_name, sub_list_file_name)
    del_phrase_counter = 0
    
    @phrases_delete = nil
    
    if(!del_list_file_name.nil?)
      #Get the phrases of entries to be deleted from the list and put these 
      #phrases into the array phrases_delete
      File.open(del_list_file_name.to_s) do |file|
        file.each_line do |line|
          if (!@phrases_delete.nil?)
            @phrases_delete = @phrases_delete.chomp
            @phrases_delete = @phrases_delete + line
            @phrases_delete = @phrases_delete.chomp
            @phrases_delete = @phrases_delete + '|'
          else
            @phrases_delete = '('
            @phrases_delete = @phrases_delete + line
            @phrases_delete = @phrases_delete.chomp
            @phrases_delete = @phrases_delete + '|'
          end  #end if/else
        end  # end do line
        #get rid of the last |
        @phrases_delete = @phrases_delete.chop
        @phrases_delete = @phrases_delete + ')'
      end  # end do file
    end #end if not nil
    @sub_hash = Hash.new
    
    @sub_phrase_counter = 0
    
    @phrases_sub = Array.new
    
    if(!sub_list_file_name.nil?)
      File.open(sub_list_file_name.to_s) do |file|
        
        file.each_line do |line|
                  
          #VERY IMPORTANT Note about rxnorm_substitute_phrases.txt:
          #To add a phrase and it's replacement, type the phrase followed by the 
          #character | followed by its replacement in 
          #rxnorm_substitute_phrases.txt
          
          parts = line.split('|')
          #store parts[0] in a_string so white space can be chomped
          a_string = parts[0]
          a_string = a_string.chomp(" ")
          @phrases_sub[@sub_phrase_counter] = a_string
          @sub_phrase_counter += 1
          #store parts[1] in a_string1 so white space can be chomped
          a_string1 = parts[1]
          a_string1 = a_string1.chomp.lstrip
          @sub_hash[a_string] = a_string1
        end  #end do line
      end  # end do file
    end #end if not nil
  end #end get_phrases
  
  #Makes substitutions and deletions and returns the resulting string
  def make_substitutions(current_entry, del_list_file_name)
    phrase_match = current_entry.match(/\b#{@phrases_delete}\b/i)
    if (!phrase_match.nil? && !del_list_file_name.nil?)  
      return nil
    else
      another_counter = 0
      #Make substitutions of phrases
      changed = false
      while another_counter < @sub_phrase_counter
        current_phrase_sub = @phrases_sub[another_counter]
        term_match = current_entry.match(/\b#{current_phrase_sub}\b/)

        if (!term_match.nil?)
          copy = @sub_hash[current_phrase_sub]
          current_entry = current_entry.gsub(/#{current_phrase_sub}/, copy)
          @changed = true
        end  #end if
        another_counter += 1
      end  #end while
      return current_entry
    end  #end if/else
  end #end make_substitutions
end