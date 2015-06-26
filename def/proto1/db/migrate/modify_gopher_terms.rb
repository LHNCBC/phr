#
# This modules provides functions to modify data in table gopher_terms and
# gopher_term_synonyms for task #360. 
# The functions are based on modfity_tables.rb with modification to serve
# the special requirement of task #360.
#
module ModifyGopherTerms
  #
  # Parse the text file and store the data into hash tables
  #
  def get_phrases(sub_list_file_name)
    # A hash table of the replacement strings, the key is the original strings
    @sub_hash = Hash.new
    # An array of the original strings to be matched in table
    @phrases_sub = Array.new
    # index of above array
    @sub_phrase_counter = 0
    # A hashtable of the additional synonyms
    @additional_synonyms = Hash.new
    
    if(!sub_list_file_name.nil?)
      File.open(sub_list_file_name.to_s) do |file|
        file.each_line do |line|
          parts = line.split('|')
          # store parts[0] in a_string so white space can be chomped
          a_string = parts[0]
          a_string = a_string.chomp(" ")
          @phrases_sub[@sub_phrase_counter] = a_string
          @sub_phrase_counter += 1
          # store parts[1] in a_string1 so white space can be chomped
          a_string1 = parts[1]
          a_string1 = a_string1.chomp.lstrip
          @sub_hash[a_string] = a_string1
          if(!parts[2].nil?)
            a_string2 = parts[2]
            a_string2 = a_string2.chomp.lstrip
            @additional_synonyms[a_string] = a_string2 if(!a_string2.empty?)
          end #end if parts[2]
        end  #end do line
      end  # end do file
    end #end if not nil
  end #end get_phrases

  
  def make_substitutions(current_entry)
    another_counter = 0
    #Make substitutions of phrases
    @changed = false
    @additional_syn = ""
    while another_counter < @sub_phrase_counter
      current_phrase_sub = @phrases_sub[another_counter]
      term_match = current_entry.match(/\b#{current_phrase_sub}\b/i)
      if (!term_match.nil?)
        copy = @sub_hash[current_phrase_sub]
        current_entry = current_entry.gsub(/\b#{current_phrase_sub}\b/i, copy)
        @additional_syn = @additional_synonyms[current_phrase_sub]
        @changed = true
      end  #end if
      another_counter += 1
    end  #end while
    return current_entry
  end #end make_substitutions
  
  def add_word_synonyms(add_word_file)
    get_phrases(add_word_file)
    
    dg = GopherTerm.find_all
    dg.each do |o|
      gopher_name = o.primary_name
      gopher_word = o.word_synonyms
      another_counter = 0
      while another_counter < @sub_phrase_counter
        search_str = @phrases_sub[another_counter]
        matched = gopher_name.match(/\b#{search_str}\b/i)
        if (!matched.nil?)
          new_word = @sub_hash[search_str]
          o.word_synonyms = gopher_word + ";" + new_word
          o.save
          break
        end  #end if
        another_counter += 1
      end  #end while
    end #end do |o|
    
  end
  
  def modify_gopher_entries(sub_list_file_name)
    get_phrases(sub_list_file_name)

    dg = GopherTerm.find_all
    dg.each do |o|
      gopher_name = o.primary_name
      gopher_id = o.id
      replaced_term = make_substitutions(gopher_name)
      if (!replaced_term.nil?)
        #
        # Update primary_name and insert previous primary_name into 
        # gopher_term_synonyms
        #
        if @changed
          o.primary_name = replaced_term
          o.save
          GopherTermSynonym.create(
            :gopher_term_id => gopher_id ,
            :synonym => gopher_name )
          #
          # insert additional gopher term synonym
          #
          if(!@additional_syn.nil? && !@additional_syn.empty?)
            GopherTermSynonym.create(
              :gopher_term_id => gopher_id ,
              :synonym => @additional_syn )
          end 
        end  #end if
      end #end if/else
    end #end do |o|
  end #end modify_gopher_entries
  
  # Reloads the development database from the given database dump file.
  def reload_db(data_file)
    db_config = YAML.load(File.read('config/database.yml'))
    dev_db = db_config['development']['database']
    db_host = db_config['development']['host']
    #
    # db_user = db_config['development']['username']
    # db_pwd = db_config['development']['password']
    #
    # Here is the assumption/requirement:
    # 1. Current user's linux account name is same as his/her mysql account name
    # 2. The mysql password is stored in .my.cnf at hie/her home directory.
    #    We are not supply password on command line for security reasons. 
    #    (see http://dev.mysql.com/doc/refman/5.0/en/password-security.html)
    #    Instead mysql reads the password from .my.cnf file.
    #
    ActiveRecord::Migration.execute('drop database ' + dev_db)
    ActiveRecord::Migration.execute('create database ' + dev_db)
    system('mysql -h ' + db_host + ' '+ dev_db + ' < ' + data_file)
           
    # Reconnect to the database so that the schema version can be updated
    ActiveRecord::Base.establish_connection(:development)
  end

end
