# This is a general purpose utility class to make utility methods available
# to code in the controller and helper classes as well as model classes.
#
# Please don't just dump everything in here - just stuff that really needs
# to be here.
#
# ALSO, please keep methods in alphabetical order by method name so that we
# can find them.  If some should be kept together, name them in such a way
# that it will happen.  thanks.
#
class Util
 
  def search_hash(key_name, the_hash)
    logger.info 'just entered search_hash, key_name = ' + key_name
    rtn = the_hash[key_name]
    if rtn.nil?
      the_hash.each_value do |val|
        if rtn.nil?
          if val.instance_of?(Array)
            val.each do |array_elem|
              if rtn.nil?
                rtn = search_hash(key_name, array_elem)
              end
            end
          elsif val.instance_of?(Hash)
            rtn = search_hash(key_name, val)
          end
        end
      end
    end
    logger.info 'returning ' + rtn.to_json
    return rtn
  end # search_hash

  # takes a full form field id and splits it into its 3 parts:
  #  prefix
  #  target_field value
  #  suffix
  # Modeled on the same function in rules.js.  6/26/08 lm.
  #
  # Parameters:
  # * form_field_id - the ID to be split
  # * has_prefix - a flag indicating whether or not the field
  #   has a prefix.  Default is true.  This is used when splitting
  #   data returned by the form, where the prefix is omitted.
  #
  # Returns: A 3 element array; elements in the order listed above
  #
  def self.split_full_field_id(form_field_id, has_prefix=true)

    suffix = form_field_id[/(_\d+)+\z/]
    if suffix.nil?
      suffix = ''
    end
    if has_prefix
      prefix = form_field_id[/\A[^_]+_/]
      if prefix.nil?
        prefix = ''
      end
      field_name =
        form_field_id[prefix.length..(form_field_id.length - suffix.length - 1)]
    else
      field_name = form_field_id[0,(form_field_id.length - suffix.length)]
      prefix = ''
    end
    return [prefix, field_name, suffix]
  end


  # Prints out the system call and then runs it.  Returns the return value of the
  # system call.
  def self.echo_system(cmd)
    puts cmd
    rtn = system(cmd)
    puts '(Completed)' if rtn
    return rtn
  end


  # Returns true if the string can be parsed as an Integer without raising
  # an exception and does not have extra leading zeroes.  The goal
  # is to have the parsed number look the same when printed as the unparsed
  # number.
  #
  # Parameters:
  # * str the string to be checked
  def self.integer?(str)
    # See http://railsforum.com/viewtopic.php?id=19081
    # I don't want leading zeroes, because 000034 looks like a code rather
    # than a numeric value, and I don't want to just show "34" after it is
    # parsed.
    return str.match(/\A(0|[+-]?[1-9]\d*)\Z/) != nil
  end

  # Returns true if the string can be parsed as a Float without raising
  # an exception, does not have extra leading zeroes, and !integer?.  The goal
  # is to have the parsed number look the same when printed as the unparsed
  # number.
  #
  # Parameters:
  # * str the string to be checked
  def self.float?(str)
    # See http://railsforum.com/viewtopic.php?id=19081
    # I don't want leading zeroes, because 000034 looks like a code rather
    # than a numeric value, and I don't want to just show "34" after it is
    # parsed.
    return str.match(/\A[+-]?(\d?|[1-9]\d+)\.\d+\Z/) != nil
  end

  # Returns true if the string can be parsed as a number, float or integer
  # Parameters:
  # * str the string to be checked
  def self.numeric?(str)
    Float(str)
    true
  rescue
    false
  end


  # return an epoch value of the time string on the day of
  # Jan 1, 1970
  # Parameters:
  # * str the string of the time in the following supported format:
  #       '9:00AM', '9:00 AM'
  #       '9:00 am', '9:00 am'
  #       '13:00', '9:00'
  # 
  def self.time_to_int(str)
    et = nil
    # validate string

#    if !str.blank? && str.match(/\A(\d{0,2}):?(\d{0,2}\s*)([aApP][mM])*\Z/)
    if !str.blank? && str.match(/\A(0?[1-9]|1[012])(:([0-5]\d))?\s*([aApP][mM])?\Z/)
      h = $1.to_i
      m = $3.nil? ? 0 : $3.to_i
      ampm = $4
      if !ampm.nil?
        if h != 12 && ampm.match(/\A[pP][mM]\Z/)
          h += 12
        elsif h == 12 && ampm.match(/\A[aA][mM]\Z/)
          h -= 12
        end
      end

      et = Time.utc(1970,1,1,h,m,0).to_i * 1000
    end
    return et
  end



  # Export a profile's data in all user tables into a YAML file
  #
  # Parameters:
  # * profile_id a profile's id
  # * file_name the data file name
  #
  def self.export_a_profile_yml(profile_id, file_name=nil)
    if !profile_id.nil?

      if file_name.blank?
        file_name = Rails.root.to_s + '/all_data_for_profile_'+profile_id.to_s + '.yml'
      elsif !file_name.match(/\A\//)
        file_name = Rails.root.to_s + '/' + file_name
      end
      other_data = {}
      data_tables = DbTableDescription.where(["data_table not like ?", "obsolete%"])
      data_tables.each do |data_table|
        # bypass the newly added 'users' table
        if data_table.data_table != 'users'
          
          if (data_table.data_table != 'obr_orders' && data_table.data_table != 'obx_observations')
            tableClass = data_table.data_table.singularize.camelcase.constantize
            records = tableClass.where(["profile_id =?", profile_id])
            data_array = []
            records.each do |record|
              # ignore the 'id' column
              columns = record.attributes
              columns.delete('id')
              data_array << columns
            end
            other_data[data_table.data_table] = data_array
          end

        end
      end

      # obr/obx
      panel_data =[]
      obr_records = ObrOrder.where(["profile_id=?", profile_id])
      obr_records.each do |obr_record|
        obr_order_id = obr_record.id
        # ignore the 'id' column
        obr_columns = obr_record.attributes
        obr_columns.delete('id')
        #find associated obx records
        obx_data_array =[]
        obx_records = ObxObservation.where(["profile_id=? and obr_order_id=?", profile_id, obr_order_id])
        obx_records.each do |obx_record|
          # ignore the 'id' column
          columns = obx_record.attributes
          columns.delete('id')
          obx_data_array << columns
        end
        panel_data << {'obr'=>obr_columns, 'obx'=> obx_data_array}
      end
      all_data = {'panel'=> panel_data, 'other'=>other_data}      
      File.open(file_name, 'w') {|f| YAML.dump(all_data, f)}
    end
  end


  # Import a profile's data from a YAML into user tables
  #
  # Parameters:
  # * profile_id a profile's id
  # * file_name the data file name
  # * replace_profile_id a flag indicates whether the profile_id value
  #                      needs to be replaced with the targeted profile_id value
  # * use_file_cache - (default false) Whether the contents of file_name should
  #   be reused if the file has been read before by this process.
  def self.import_a_profile_yml(profile_id, file_name=nil,
                                replace_profile_id=false, use_file_cache=false)
    if !profile_id.nil?
      if file_name.blank?
        file_name = Rails.root.to_s + '/all_data_for_profile_'+profile_id.to_s + '.yml'
      elsif !file_name.match(/\A\//)
        file_name = Rails.root.to_s + '/' + file_name
      end
      
      if File.readable?(file_name)
        Profile.transaction do
          @profile_data_cache ||= {}
          all_data = use_file_cache ? @profile_data_cache[file_name] : nil
          if !all_data
            all_data = YAML.load_file(file_name)
            @profile_data_cache[file_name] = all_data
          end
          # other
          other_data = all_data['other']
          other_data.each do |data_table, rows|
            tableClass = data_table.singularize.camelcase.constantize
            rows.each do |row|
              if replace_profile_id
                row['profile_id'] = profile_id
              end
              rec_obj = tableClass.new(row)
              rec_obj.save(:validate => false)
            end
          end
          #panel
          panel_data = all_data['panel']
          panel_data.each do |panel_record|
            obr= panel_record['obr']
            obx_data_array = panel_record['obx']
            # create obr record
            if replace_profile_id
              obr['profile_id'] = profile_id
            end
            obr_obj = ObrOrder.new(obr)
            obr_obj.save(:validate => false)
            #create obx records
            obx_data_array.each do |obx|
              obx['obr_order_id'] = obr_obj.id
              if replace_profile_id
                obx['profile_id'] = profile_id
              end
              obx_obj = ObxObservation.new(obx)
              obx_obj.save(:validate => false)
            end
          end
        end
      else
        puts "File: #{file_name} does not exist or is not readable"
      end
    end
  end

  
  # Create demo accounts for demo systems
  #
  # Parameters:
  # * num_of_accounts the number of the demo accounts to be created
  # * file_name an array of the names of the data files
  #             created by export_a_profile_data
  #   Ajay 06/11/2014: Added an option to create question answers
  #   for load testing.
  # * add_question_answers - Option to add question answers for the user.
  # * id_prefix - A prefix to user_id to help identify the batch. Ajay 07/16/2014

  def self.create_demo_accounts(num_of_accounts = DEMO_ACCOUNT_INCREMENTAL,
      file_names = DEMO_SAMPLE_DATA_FILES, add_question_answers = false,
      id_prefix = "Demo")

    1.upto(num_of_accounts) do |i|
      # create a user account
      # may only need a record in the users table. (no question/answers)
      time_str = Time.now.to_i.to_s
      user = User.new
      user.name = "#{id_prefix}_#{time_str}_#{i}"
      user.password = "I'm a demo account, no #{i}"
      user.password_confirmation = user.password
      user.email = "D#{time_str}_#{i}@nowhere.org"
      user.email_confirmation = user.email
      user.account_type = DEMO_ACCOUNT_TYPE
      user.admin = false
      user.save!

      # Fixed question answers to all the accounts. Intended for load testing.
      # -Ajay 06/11/2014
      if(add_question_answers)
        user.add_question(QuestionAnswer::FIXED_QUESTION, 'a', '1')
        user.add_question(QuestionAnswer::FIXED_QUESTION, 'b', '1')
        user.add_question(QuestionAnswer::USER_QUESTION, 'c', '1')
      end


      file_names.each do |f_name|
        # create a profile for each file
        profile = Profile.create!
        profile_id = profile.id
        # import the profile data, and replace the profile_id with the newly
        # created profile's id
        self.import_a_profile_yml(profile_id, f_name, true, true)
        # create association records in profile_users table now that the profile
        # has data.
        user.profiles << profile
      end # end of files
    end # end of accounts
  end


  # Delete a profile's data in user tables, but keep the profile itself
  def self.delete_a_profile_data(profile_id)
    if !profile_id.nil?
      data_tables = DbTableDescription.where(["data_table not like ?", "obsolete%"])
      Profile.transaction do
        data_tables.each do |data_table|
          # bypass the newly added 'users' table
          if data_table.data_table != 'users'
            tableClass = data_table.data_table.singularize.camelcase.constantize
            tableClass.destroy_all(["profile_id = ?", profile_id])
            histTableClass = 'hist_'+data_table.data_table
            histTableClass = histTableClass.singularize.camelcase.constantize
            histTableClass.destroy_all(["profile_id = ?", profile_id])
          end
        end
      end
    end
  end

  
  # Should create a new method in this class that update virtual fields
  # It's a combination of the update_all_virtual_fields method in form_data.rb
  # and migration 1119.
  # Do it when the everyone has run migration 1119

  
end # Utilities


# Extensions

class Array
  # Converts the array to an english phrase with proper commas and "and".
  def to_english
    if size == 0
      rtn = '';
    elsif size == 1
      rtn = self[0]
    elsif size == 2
      rtn = self[0] + ' and ' + self[1];
    else
      last_index = size-1;
      rtn = slice(0, last_index).join(', ') + ', and ' + self[last_index];
    end
    return rtn;
  end
end
