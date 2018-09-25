# A class handles data operations for test panels

class PanelData < FormData

  TEST_VALUE_COL_NAME = 'obx5_value'
  #
  # initialization
  # * user_obj the object of current user
  #
  def initialize(user_obj)

    # call FormData's initializer
    super('loinc_panel_temp')

    @user_obj = user_obj

  end

  # For TaffyDB implementation on client side
  #
  # get a data db and 2 mapping tables for taffydb, edit existing record
  #
  # Parameters:
  # * processing_item - a loinc_panel record of a panel group field
  #                       or a loinc_item record if it is a single test
  # * obr_index - optional, a panel sequence index
  # * obx_index - optional, a test sequence index
  # * panel_grp_sn - the sequence number of the test panel group
  # * panel_sn - the sequence number of the test panel in the group
  # * suffix_prefix - prefix to the field suffix in the panel template
  # * profile_id - optional, a profile's id
  # * obr_record_id - optional, an obr record id
  # * is_single_test - optional, if it is a single individual test
  #
  # Returns:
  # * [data_table, taffy_mapping, taffy_model]
  #
  # - +data_table+ - data hash that in the same format of the tables in
  #   database used for the creation of a taffydb.
  # - +taffy_mapping+ - a mapping table between fields on a form and records
  #   in a taffydb, for lookups from form fields to taffydb
  #   records and from taffydb record to form fields.
  # - +taffy_model+ - a database model record for inserting new empty records
  #   in taffydb when a new row is created in a form table.
  #
  def get_one_panel_taffy_db_data(processing_item, obr_index=0, obx_index=0,
        panel_grp_sn='', panel_sn =0, suffix_prefix='', profile_id = nil,
        obr_record_id = nil, is_single_test = false)

    if !@has_data_table
      return nil
    end

    if is_single_test
      data_table, obr_rec_num, obx_rec_num =
          get_one_single_test_panel_data_table(processing_item, obr_index,
          profile_id, obr_record_id)
    else
      data_table, obr_rec_num, obx_rec_num = get_one_panel_data_table(
          processing_item, obr_index, profile_id, obr_record_id)
    end
    # calculate the mapping table and model table
    taffy_mapping = get_one_panel_taffy_db_mapping(data_table, obr_index,
        obx_index, panel_grp_sn, panel_sn, suffix_prefix)

    # calculate the table to group mapping
    panel_table_2_group= get_one_panel_taffy_db_table_to_group_mapping(
        data_table, obr_index, obx_index, panel_grp_sn, panel_sn, suffix_prefix)
    # get model table
    taffy_model = {}   # model row for inserting a new taffy record
    @table_definition.each do |key, value|
      model_row = {}
      value.keys.each do |col_name|
        model_row[col_name] = @column_2_field_mapping[key + '|' + col_name]
      end
      taffy_model[key]=model_row
    end
    # obx table needs two additional column
    taffy_model[OBX_TABLE][PARENT_TABLE_COL] = OBR_TABLE
    taffy_model[OBX_TABLE][FOREIGN_KEY_COL] = ''

    # increase the record index
    obr_index += obr_rec_num
    obx_index += obx_rec_num

    return [[data_table, taffy_mapping, taffy_model, panel_table_2_group],
        obr_index, obx_index]
  end


   #
  # Get the taffydb data for any test panels defined in the form
  # Note: the test panel is displayed in 2 steps
  #       1) display a test panel template
  #       2) use data loader to load the actual tests
  #
  # Parameters:
  # * form - a Form record, or a name of a form
  # * profile_id - id of a profile record
  # * data_table - data_table merged from data in autosave_tmps
  #
  # Return: taffydb data that includes test panel templates,
  #     following the same group structure on the form
  #
  # This is for display test panels of a new form, not for displaying existing
  #    test panel records, which is not done yet
  #
  # Assumption for embedding test panels in other forms:
  #      One form could only include ONE test panel placeholder due to the
  #      limitation on displayField function.
  #      Although the this methods also handles multiple test panel placeholders
  #      privided they are in different groups. (Any group could only have One
  #      test panel placeholder)
  #
  def get_panel_group_taffydb_data(form, profile_id=nil, data_table=nil)
    form = Form.find_by_form_name(form) if form.class == String
    from_autosave = data_table.nil? ? false : true

    # loinc_panel needs to be changed to 'test_panel' when everything is done
    panel_fields = FieldDescription.find_all_by_control_type_and_form_id(
        'loinc_panel', form.id)

    data_hash = {}
    panel_grp_sn = 1
    obr_index = 0
    obx_index = 0
    suffix_prefix =''

    panel_group_taffy_db_data = Array.new
    panel_fields.each do |panel_field|
      # get data hash
      panel_data_hash = get_panel_data_hash(panel_field, panel_grp_sn,
          profile_id)
      # get the upper level groups and calculate the suffix_prefix
      if !panel_data_hash.nil? && !panel_data_hash.empty?
        p_field = panel_field.parent_field
        while !p_field.nil?
          hash = {}
          if p_field.max_responses==0 &&
              p_field.getParam('orientation')=='horizontal'
            array = []
            array << panel_data_hash
            hash[p_field.target_field]= array
          else
            hash[p_field.target_field]= panel_data_hash
          end
          panel_data_hash = hash
          p_field = p_field.parent_field
          suffix_prefix = suffix_prefix + '_1'
        end
        data_hash.merge!(panel_data_hash)
      end
      # get taffy db data
      one_panel_group_taffy_db_data, obr_index, obx_index =
          get_panel_taffy_db_data(panel_field,obr_index, obx_index,
          panel_grp_sn, suffix_prefix, profile_id, data_table)

      # merger the entire panel group's taffy db data
      if panel_group_taffy_db_data.empty?
        panel_group_taffy_db_data = one_panel_group_taffy_db_data
      elsif !one_panel_group_taffy_db_data.empty?
        # merge data table
        if !from_autosave
          panel_group_taffy_db_data[0].each do |table_name, records|
            panel_group_taffy_db_data[0][table_name] =
                records.concat(one_panel_group_taffy_db_data[0][table_name])
          end
        end
        # merge mapping
        panel_group_taffy_db_data[1] =
            panel_group_taffy_db_data[1].merge(one_panel_group_taffy_db_data[1])
        # model class is the same, no need to merge

        # merge table_2_group mapping
        # for obr table
        table_2_group = panel_group_taffy_db_data[3][OBR_TABLE]
        one_panel_group_taffy_db_data[3][OBR_TABLE].each do |grp_id, rec_num|
          if !table_2_group[grp_id].blank?
            table_2_group[grp_id] = table_2_group[grp_id] + rec_num
          else
            table_2_group[grp_id] = rec_num
          end
        end
        # for obx table
        table_2_group = panel_group_taffy_db_data[3][OBX_TABLE]
        one_panel_group_taffy_db_data[3][OBX_TABLE].each do |grp_id, rec_num|
          if !table_2_group[grp_id].blank?
            table_2_group[grp_id] = table_2_group[grp_id] + rec_num
          else
            table_2_group[grp_id] = rec_num
          end
        end

      end
      panel_grp_sn +=1
      suffix_prefix = ''
    end

    if from_autosave
      panel_group_taffy_db_data[0] = data_table
    end
    return panel_group_taffy_db_data
  end


  # Returns two arrays, one of list_names and the other of corresponding codes
  # for the "where done" field for a particular user.
  #
  # Parameters:
  # * user - the user object.  The user's previously used values will be
  #   included in the returned list.
  def self.get_merged_where_done_list(user)
    items = TextList.get_list_items('test_where_done').clone
    list_names = []
    list_codes = []
    items.each do |item|
      list_names << item.item_text
      list_codes << item.code
    end

    users_wheredone_list = user.typed_data_records('obr_orders',{},
      {:select=>'distinct(test_place)'})
    if !users_wheredone_list.nil? && users_wheredone_list.length >0
      users_wheredone_list.each do |record|
        item = record.test_place
        if !item.blank? && !list_names.include?(item)
          list_names << item
          list_codes << ''
        end
      end
    end
    return list_names, list_codes
  end


  private


  #
  # Check if a data record has all the required fields for obr_orders and obx_observations tables
  # Override the method in FormData
  # If the required field in obr_orders table, the 'When Done' is empty, no error message is returned.
  #
  # Parameters:
  # * table_name - a database table name
  # * record_data - a hash map that contains a data record of the table
  #
  # Returns:
  # * True/False
  #
  def has_required_data?(table_name, record_data)
    has_required = true

    # the When Done field is required only if at least one of the tests have a test value.
    # for now, we'll not return error messages but the obr record itself won't be saved
    table_def = @table_definition[table_name]
    if !table_def.nil?
      table_def.each do |column_name, col_def|
        # if it's a required field and its value is empty
        if col_def[2] && record_data[column_name].blank?
          has_required = false
          key = "#{table_name}|#{column_name}"
          # create an error message if it is the obx_orders table
          # (only the obr_orders and obx_observations tables are handled here)
          if table_name != OBR_TABLE
            if @column_2_field_mapping[key] &&
                @column_2_field_mapping[key][0] &&
                @field_name_mapping[@column_2_field_mapping[key][0]]
              field_name = @field_name_mapping[@column_2_field_mapping[key][0]][0]
            else
              field_name = column_name
            end
            @feedback['errors'] << "'#{field_name}' must not be left blank."
          end
          break
        end # end of if it's a required field and its value is empty
      end # end of each field
    end # end of the table

    return has_required

  end


  #
  # pre-process user data, over ride the method in FormData
  #
  # Parameters:
  # * data_table - user's data table
  #
  # Returns:
  # * in data_table object
  #
  def preprocess_data_table(data_table)
    # trim the string value
    trim_data(data_table)
    # record empty rows in the data table, except the last one
    # note obr/obx records are never empty (loinc_num has value)
    record_empty_rows(data_table)
    # keep a copy of the original data_table for the use in autosave
    # as the new base record, which needs to have the empty obx records
    orig_data_table = Marshal::load(Marshal.dump(data_table))
    # remove all obx records that have no test values,
    #filter_empty_obx_records(data_table)
    return orig_data_table
  end


  # not used. empty records are handled while being saved.
  # remove obx records that have no test values
  # Parameters:
  # * data_table - user's data table
  #
  # Returns:
  # * in data_table object
  #
  def  filter_empty_obx_records(data_table)
    # don't delete empty obr record here, otherwise the order of the
    # obr records will change. empty obr records will not be saved by
    # the save code since the required test_date is empty.

    # check obx records
    obx_records = data_table[OBX_TABLE]
    i = obx_records.length
    while i > 0
      if obx_records[i-1]['obx5_value'].blank?
        obx_records.delete_at(i-1)
      end
      i -= 1
    end
  end


  # not used
  # keep one empty obx records if all obx records for one panel are empty
  def  filter_empty_obx_records_keep_one(data_table)
    obr_records = data_table[OBR_TABLE]
    obx_records = data_table[OBX_TABLE]

    obr_records.each do | obr_record |
      # don't delete empty obr record here, otherwise the order of the
      # obr records will change
      obr_id = obr_record["_id_"]
      # check obx records
      obx_empty, obx_non_empty = check_obx_records(obr_id, obx_records)
      # if all of the obx records are empty, delete all of them except the first
      # empty obx record
      if obx_non_empty.empty?
        length = obx_empty.length
        obx_empty.reverse.each do |idx|
          length -= 1
          if length > 0
            obx_records.delete_at(idx)
          end
        end
      # otherwise delete the empty obx records, keep the ones that are not empty
      else
        obx_empty.reverse.each do |idx|
          obx_records.delete_at(idx)
        end
      end
    end
  end

  # check the obx records
  # Parameters:
  # * obr_id -- the id(index) of an obr record
  # * obx_records - the entire obx records
  #
  # Returns:
  # * obx_empty_records - an array of the index of the empty obx records
  #                     of the obr record
  # * obx_records_count - the total number of obx records of the obr
  #                     record
  #
  def check_obx_records(obr_id, obx_records)
    obx_empty_records = []
    obx_non_empty_records = []
    idx = 0
    obx_records.each do | obx_record |
      if obx_record['_p_id_'] == obr_id
        if obx_record['obx5_value'].blank?
          obx_empty_records << idx
        else
          obx_non_empty_records << idx
        end
      end
      idx += 1
    end

    return obx_empty_records, obx_non_empty_records
  end


  #
  # create a mapping table to taffy db of a new panel
  #
  # Parameters:
  # * data_table - a hashmap that contains data following the actual table
  #                structure
  # * obr_index - the max record index in obr table, which will be used by
  #               this obr record set, (only one obr record)
  # * obx_index - the max record index in obx table, starting which will be
  #               used by this obx record set. (multiple obx records)
  # * panle_grp_sn - the serial number of the panel template that this test
  #                  panel that belongs to the form
  # * suffix_prefix - the prefix of the field id suffix, depending on the form's
  #                   structure that the panel template belongs to.
  #                   for example, if the panel template is within another
  #                   group, the suffix is "_1".
  #
  # Returns:
  # * taffy_mapping - a mapping hash between test panels' fields and data
  #                   location in taffy db
  #
  def get_one_panel_taffy_db_mapping(data_table, obr_index=0, obx_index=0,
      panel_grp_sn='', panel_sn = 0, suffix_prefix='')

    obr_index = 0 if obr_index.nil?
    obx_index = 0 if obx_index.nil?
    panel_grp_sn = '' if panel_grp_sn.nil?
    panel_sn = 0 if panel_grp_sn.nil?
    suffix_prefix = '' if suffix_prefix.nil?

    # group_definition of the test panel template form is used
    # and it's fixed structure is depended on by the code in this function
    group_def = @group_definition

    taffy_mapping = Hash.new

    obr_mapping_template = Hash.new
    obx_mapping_template = Hash.new

    # parse test panels group definition to get a mapping template
    group_def.each do | key, values|
      case values
      when Array # temp group
        values[0].each do |target_fd, value|
          case value
          when nil  # obr field level 1
            obr_mapping_template[target_fd] = "_0"
          when Hash # obr field level 2
            value.each do |t_fd,val|
              case val
              when nil
                obr_mapping_template[t_fd] = "_0_1"
              when Array ## obx field, level 3
                val[0].each do |fd,v|
                  case v
                  when nil
                    obx_mapping_template[fd] = "_0_1_0"
                  end
                end #end of columns for a test record, tp_loinc_panel_temp_test
              end
            end
          end # end of tp_loinc_panel_temp groug
        end
      end # end of tp_loinc_panel_temp_grp group
    end

    # get obr record number
    obr_rec_num = data_table[OBR_TABLE].length

    # create mapping for obr table
    obr_mapping_template.each do |target_field, suffix_pattern |
      # replace the "_0" with the current obr_index or the current obx_index
      # and insert the panel_grp_sn
      if target_field.match(/\Atp_/)

        column_name = get_column_name_by_target_field(target_field)
        if !column_name.blank?
          # insert panel_grp_sn after "tp" in target_field
          modified_target = target_field
          if !panel_grp_sn.blank?
            modified_target  = target_field[0,2] + panel_grp_sn.to_s +
                target_field[2..-1]
          end
          i = 0
          while (i < obr_rec_num)
            suffix = suffix_pattern.gsub(/\A_0/, '_'+ (panel_sn + i + 1).to_s)
            ele_id = FORM_OBJ_NAME + "_" + modified_target + suffix_prefix +
                suffix
            taffy_mapping[ele_id] = [OBR_TABLE,column_name, obr_index +i +1]
            i += 1
          end
        end # end of !column_name.blank?
      end # end of if test panel field
    end # end of fields for obr

    # get obx record number for each obr_record
    obx_rec_nums = Hash.new
    obx_data = data_table[OBX_TABLE]
    obx_data.each do |obx_record|
      p_index = obx_record[FOREIGN_KEY_COL]
      obx_rec_nums[p_index] = obx_rec_nums[p_index].nil? ? 1:
          obx_rec_nums[p_index] + 1
    end

    # create mapping for obx table
    obx_rec_nums.each do |obr_num, obx_num|
      obx_mapping_template.each do |target_field, suffix_pattern |
        if target_field.match(/\Atp_/)
          column_name = get_column_name_by_target_field(target_field)
          if !column_name.blank?
            # insert panel_grp_sn after "tp" in target_field
            modified_target = target_field
            if !panel_grp_sn.blank?
              modified_target  = target_field[0,2] + panel_grp_sn.to_s +
                  target_field[2..-1]
            end
            j = 0
            while (j < obx_num)
              suffix = suffix_pattern.gsub(/\A_0/, '_'+ (panel_sn + 1).to_s)
              suffix = suffix.gsub(/_0\z/, '_' + (j + 1).to_s)
              ele_id = FORM_OBJ_NAME + "_" + modified_target + suffix_prefix +
                  suffix
              taffy_mapping[ele_id] = [OBX_TABLE,column_name, obx_index + j + 1]
              j += 1
            end
          end # end of column_name is not blank
        end # end of if test panel field
      end # end of fields for obx

    end
    return taffy_mapping
  end

 #
  # create a table to group mapping table of a new panel
  #
  # Parameters:
  # * data_table - a hashmap that contains data following the actual table
  #                structure
  # * obr_index - the max record index in obr table, which will be used by
  #               this obr record set, (only one obr record)
  # * obx_index - the max record index in obx table, starting which will be
  #               used by this obx record set. (multiple obx records)
  # * panle_grp_sn - the serial number of the panel template that this test
  #                  panel that belongs to the form
  # * suffix_prefix - the prefix of the field id suffix, depending on the form's
  #                   structure that the panel template belongs to.
  #                   for example, if the panel template is within another
  #                   group, the suffix is "_1".
  #
  # Returns:
  # * panel_table_2_group - a mapping hash between test panels' data tables to
  #                         group header ids on the form
  #
  def get_one_panel_taffy_db_table_to_group_mapping(data_table, obr_index=0,
      obx_index=0, panel_grp_sn='', panel_sn = 0, suffix_prefix='')

    obr_index = 0 if obr_index.nil?
    obx_index = 0 if obx_index.nil?
    panel_grp_sn = '' if panel_grp_sn.nil?
    panel_sn = 0 if panel_grp_sn.nil?
    suffix_prefix = '' if suffix_prefix.nil?
    panel_table_2_group = Hash.new

    obr_grp= 'tp_loinc_panel_temp_grp'
    obx_grp= 'tp_loinc_panel_temp_test'

    # obr table to group mapping
    # get obr record number
    obr_rec_num = data_table[OBR_TABLE].length
    modified_obr_grp  = obr_grp[0,2] + panel_grp_sn.to_s +
        obr_grp[2..-1]
    suffix = '_0'
    obr_grp_id = FORM_OBJ_NAME + "_" + modified_obr_grp + suffix_prefix +
        suffix
    panel_table_2_group[OBR_TABLE] = {obr_grp_id=>obr_rec_num}


    # get obx record number for the obr_record
    obx_rec_num = data_table[OBX_TABLE].length

    # obx table to group mapping
    modified_obx_grp  = obx_grp[0,2] + panel_grp_sn.to_s +
        obx_grp[2..-1]
    suffix = '_0_1_0'
    suffix = suffix.gsub(/\A_0/, '_' + (panel_sn + 1).to_s)
    obx_grp_id = FORM_OBJ_NAME + "_" + modified_obx_grp + suffix_prefix +
                  suffix
    panel_table_2_group[OBX_TABLE] = {obx_grp_id=>obx_rec_num}

    return panel_table_2_group
  end


  #
  # Convert a panel_data_hash (not regular data_hash) to data_table hashmap
  # based on the actual data table structure
  #
  # Parameters:
  # * panel_data_hash - a panel_data_hash data from a form.
  #                     panel_data_hash is created from form_params by
  #                     convert_params_to_panel_records() in
  #                     application_controller
  #
  # Returns:
  # * data_table - a hash map that contains data following the actual table
  #                structure
  #
  # +panel_data_hash+ examples:
  # {'1'=>{'_1_1'=>{"0"=>{"tp_invisible_field_panel_loinc_num"=>"",
  #                       "tp_invisible_field_panel_name"=>"",
  #                       "tp_loinc_panel_temp_grp_id"=>"",
  #                       "tp_panel_testdate"=>"",
  #                       "tp_panel_testdate_ET"=>"",
  #                       "tp_panel_testdate_HL7"=>"",
  #                       "tp_panel_testplace"=>"",...},
  #                 "1"=>{'tp_test_name'=>'BP Systolic',
  #                       'tp_test_value'=>'100', ...},
  #                 "2"=>{'tp_test_name'=>'BP Diastolic',
  #                       'tp_test_value'=>'110', ...},
  #                 ... ## other tests within one panel
  #                },
  #        '_1_2'=>{"0"=>{... ...},
  #                 "1"=>{...},
  #                 "2"=>{...},
  #                 ...
  #                }
  #         ... ## other panels within one template group
  #       },
  #  '2'=>{...}, ...  ## other template group
  def convert_to_data_table(panel_data_hash)
    # uses
    # @table_definition
    # @field_2_column_mapping
    data_table = Hash.new
    obr_index = 0
    obx_index =0
    panel_data_hash.each do |group_sn, group|
      # key group_sn is the panel template group sequence num
      group.each do |rec_sn, records|
        # rec_sn is record sequence num
        # records is a data set that includes 1 obr record and many obx records
        # that belong to it

        # OBR record
        obr_record = records["0"]
        p_table_name = nil
        obr_record.each do |field, value|
          table_name = get_table_name_by_target_field(field)
          column_name = get_column_name_by_target_field(field)
          if !is_column_virtual?(table_name,column_name)
            # create the data structure if no table structure
            if data_table[table_name].nil?
              data_table[table_name] = Array.new
            end
            # insert a new row structure
            if data_table[table_name][obr_index].nil?
              data_table[table_name] << Hash.new
            end
            # insert the data
            data_table[table_name][obr_index][column_name] = value
          end
          # insert the primary key value
          data_table[table_name][obr_index][PRIMARY_KEY_COL] = obr_index
          p_table_name = table_name
        end

        records.each do |index, record|
          # index is the record index, 0 means obr record, otherwise obx record
          # record is an obr or an obx record
          # OBX record
          if index.to_i >0
            record.each do |field, value|
              table_name = get_table_name_by_target_field(field)
              column_name = get_column_name_by_target_field(field)
              if !is_column_virtual?(table_name,column_name)
                # create the data structure if no table structure
                if data_table[table_name].nil?
                  data_table[table_name] = Array.new
                end
                # insert a new row structure
                if data_table[table_name][obx_index].nil?
                  data_table[table_name] << Hash.new
                end
                # insert the data
                data_table[table_name][obx_index][column_name] = value
                # insert two additional columns
                if !data_table[table_name][obx_index].nil? &&
                    data_table[table_name][obx_index][PARENT_TABLE_COL].nil?
                  data_table[table_name][obx_index][PARENT_TABLE_COL] =
                      p_table_name
                  data_table[table_name][obx_index][FOREIGN_KEY_COL] =
                      obr_index
                end
              end
              # insert the primary key value
              data_table[table_name][obx_index][PRIMARY_KEY_COL] = obx_index
            end # end of each of OBX record field/value
            obx_index +=1
          end # end of OBX record
        end # end of records
        obr_index += 1
      end # end of each panel temp group
    end # end of all panel temp groups
    return data_table
  end


  public


  # Update the test values in a data_table where answer lists are missing
  # from merged autosaved data
  # Parameters:
  # * data_table recovered data_table from autosave_tmps where answer lists
  # for tests who have incremental changes are missing
  def reset_answer_lists(data_table)
    if !data_table.nil?
      obx_table = data_table[OBX_TABLE]
      # when there's test panel data
      if !obx_table.nil?
        obx_table.each do |obx_record|
          # when an answer list might be missing
          if obx_record['obx5_value'].class != Array
            loinc_num = obx_record['loinc_num']
            loinc_item = LoincItem.find_by_loinc_num(loinc_num)
            # when it should have an answer list
            if !loinc_item.answerlist_id.blank?
              answer_list = loinc_item.answers_and_codes
              if !answer_list.nil?
                # add the answer list
                obx_record['obx5_value'] = [obx_record['obx5_value'],
                    answer_list[0], answer_list[1]]
              end
            end
          end
        end
      end
    end
  end


  #
  # get a panel's definition and data of a profile, for timeline view
  #
  # Parameters:
  # * loinc_num - a loinc_num of a top level panel loinc item
  # * profile_id - a profile's id
  # * start_date - a epoch value of date that represents the 'from' limit
  #                of the test date in the search result
  # * end_date - a epoch value of date that represents the 'to' limit of
  #              the test date in the search result
  # * end_date_str - the string value of the end date. It could be in the format
  #   of 'yyyy', 'yyyy Mon', or 'yyyy Mon dd'
  # * group_by_code - a code that indicates different group types of the
  #                   search result
  # * date_range_code - a code that indicates a different date range
  # * include_all - a code that indicates if all data from other panels for the same
  #                 tests in this panel should be included
  #
  # Returns: an array of
  # * timeline_def - an array that defines each test/subpanel in a panel
  # * timeline_data - an array that contains user data each test/subpanel
  #                   in a panel
  # * date_columns - an ARRAY of date and time for each obr record.
  #                 sorted by test_date_ET
  #   [ {id=>[year, month_day, time, et, [classes]]}.
  #     ...
  #   ]
  # * panel_info - a hash of panel information about common units and no_data
  #
  #
  def get_panel_timeline_data_def(loinc_num, profile_id, start_date=nil,
      end_date=nil, end_date_str=nil, group_by_code=nil, date_range_code=nil,
      include_all=nil)
    timeline_def = self.class.get_panel_timeline_def(loinc_num)
    timeline_data, grid_dates, first_cols =
        get_panel_timeline_data(timeline_def,loinc_num, profile_id,
        start_date, end_date, end_date_str, group_by_code, date_range_code,
        include_all)

    # add the 'first' classes for the first column in each group
    first_cols.each do |grp_id, col_id|
      grid_dates[col_id][4] << 'first'
    end

    # do it again after inserting new data
    # sorted by test_date_ET
    # [ {id=>[year, month_day, time, et, [classes]]}.
    #   ...
    # ]
    date_columns =[]
    sorted_array = grid_dates.sort {|a,b| a[1][3] <=> b[1][3] }
    sorted_array.each do |rec|
      date_columns << {rec[0]=>rec[1]}
    end
    # most recent date first
    date_columns.reverse!

    # create a hash for panel info about common units and no_data
    panel_info = {}
    info_array = []
    i=4
    while i< timeline_def.length
      test_info = {}
      test_info['commUnits'] = timeline_def[i]['units']
      test_info['chartData'] = timeline_def[i]['chart_data']
      test_info['loincNum'] = timeline_def[i]['loinc_num']
      test_info['testName'] = timeline_def[i]['name']
      test_info['numOfRecords'] = timeline_def[i]['numOfRecords'] =
          grid_dates.length
      info_array << test_info
      i+=1
    end
    panel_info[timeline_def[0]['loinc_num']] = info_array

    return [timeline_def, timeline_data, date_columns, panel_info]
  end

  #
  # get a panel's definition and data of a profile, for timeline view
  #
  # Parameters:
  # * loinc_nums - a array of loinc_nums of top level panel loinc items
  # * profile_id - a profile's id
  # * start_date - a epoch value of date that represents the 'from' limit
  #                of the test date in the search result
  # * end_date - a epoch value of date that represents the 'to' limit of
  #              the test date in the search result
  # * end_date_str - the string value of the end date. It could be in the format
  #   of 'yyyy', 'yyyy Mon', or 'yyyy Mon dd'
  # * group_by_code - a code that indicates different group types of the search
  #                   result
  # * date_range_code - a code that indicates a different date range
  # * include_all - a code that indicates if all data from other panels for the same
  #                 tests in this panel should be included
  #
  # Returns: an array of
  # * timeline_def - an array that defines each test/subpanel in the panels
  # * timeline_data - an array that contains user data each test/subpanel
  #                   in the panels
  # * date_columns - an ARRAY of date and time for each obr record.
  #                 sorted by test_date_ET
  #   [ {id=>[year, month_day, time, et, [classes]]}.
  #     ...
  #   ]
  #
  def get_panel_timeline_data_def_in_one_grid(loinc_nums, profile_id,
      start_date=nil, end_date=nil, end_date_str=nil, group_by_code=nil,
      date_range_code=nil, include_all=nil)
    add_separator = true
    timeline_def = []
    timeline_data = []
    timeline_dates = {}
    first_columns = {}
    i = 0
    separator_num = loinc_nums.length - 1
    loinc_nums.each do |loinc_num|
      one_timeline_def = self.class.get_panel_timeline_def(loinc_num)
      timeline_def.concat(one_timeline_def)
      grid_data, grid_dates, first_cols= get_panel_timeline_data(
          one_timeline_def,loinc_num, profile_id, start_date, end_date,
          end_date_str, group_by_code, date_range_code, include_all)
      # first panel's data
      if timeline_data.empty? && timeline_dates.empty?
        timeline_data = grid_data
        timeline_dates = grid_dates
        first_columns = first_cols
      # subsequent panel's data
      else
        timeline_data.concat(grid_data)

        # for each group there's only on column has the 'sum' class, whose id
        # also starts with "sum_"
        # keep the last 'sum' and remove others
        if timeline_dates.empty?
          timeline_dates = grid_dates
        elsif !grid_dates.empty?
          common_keys = timeline_dates.keys & grid_dates.keys
          common_keys.each do |key|
            et1 = timeline_dates[key][3]
            et2 = grid_dates[key][3]
            # get the earlier col, the order is reversed later
            if et1 < et2
              grid_dates.delete(key)
            else
              timeline_dates.delete(key)
            end
          end
          timeline_dates.merge!(grid_dates)
        end

        # for each group there's only on column has the 'first' class
        # keep the real 'first' and remove others
        if first_columns.empty?
          first_columns = first_cols
        elsif !first_cols.empty?
          common_keys = first_columns.keys & first_cols.keys
          common_keys.each do |grp_id|

            et1 = timeline_dates[first_columns[grp_id]][3]
            et2 = timeline_dates[first_cols[grp_id]][3]
            # get the latest col, the order is reversed later
            if et1 > et2
              first_cols.delete(grp_id)
            else
              first_columns.delete(grp_id)
            end
          end
          first_columns.merge!(first_cols)
        end
      end

      # add an empty row between different panels
      if add_separator && i< separator_num
        timeline_def << {'panel_separator' => true}
        timeline_data << {}
      end
      i +=1
    end

    # add the 'first' classes for the first column in each group
    first_columns.each do |grp_id, col_id|
      timeline_dates[col_id][4] << 'first'
    end

    # get the sorted date column header
    date_columns =[]
    sorted_array = timeline_dates.sort {|a,b| a[1][3] <=> b[1][3] }
    sorted_array.each do |rec|
      date_columns << {rec[0]=>rec[1]}
    end

    # most recent date first
    date_columns.reverse!

    return [timeline_def, timeline_data, date_columns]

  end


  #
  # get a panel's definition, for timeline view
  #
  # Parameters:
  # * loinc_num - a loinc_num of a top level panel loinc item
  #
  # Returns:
  # * panel_timeline_def - an array of hashmaps for each test/subpanel
  #                        in a panel
  #   the keys of hashmap:
  #   loinc_num, name, disp_level, required, is_test,
  #   and panel_separator (added later in get_panel_timeline_data_def)
  #
  def self.get_panel_timeline_def(loinc_num)
    panel_timeline_def = []
    loinc_item = LoincItem.find_by_loinc_num(loinc_num)
    if !loinc_item.nil?
      # a top level panel item
      if loinc_item.is_panel? && loinc_item.has_top_level_panel?
        get_panel_timeline_top_level_panel_def(panel_timeline_def, loinc_num)
      # a test
      elsif loinc_item.is_test?
        get_panel_timeline_single_test_panel_def(panel_timeline_def, loinc_num)
      # ignore sub panel items
      #elsif loinc_item.is_panel?
      end
    end
    return panel_timeline_def
  end


  private


  #
  # get a panel's data of a profile, for the timeline view
  #
  # Parameters:
  # * timeline_def - a panel's definition
  # * p_loinc_num - a loinc_num of a top level panel LOINC item
  # * profile_id - a profile's id
  # * start_date - a epoch value of date that represents the 'from' limit
  #                of the test date in the search result
  # * end_date - a epoch value of date that represents the 'to' limit of
  #              the test date in the search result
  # * end_date_str - the string value of the end date. It could be in the format
  #   of 'yyyy', 'yyyy Mon', or 'yyyy Mon dd'
  # * group_by_code - a code that indicates different group types of the search
  #                   result
  # * date_range_code - a code that indicates a different date range
  # * include_all - a code that indicates if all data from other panels for the same
  #                 tests in this panel should be included
  #
  # Returns: an array of
  # * panel_timeline_data - an ARRAY of hash maps for each test/subpanel
  #                        in a panel, the structure of the hashmap:
  #   [{id=>[display_value, abnormal_flag, units, normal_high,
  #          normal_low, test_date, value, test_time, test_date_ET],
  #     id=>[display_value, abnormal_flag, units, normal_high,
  #          normal_low, test_date, value, test_time, test_date_ET],
  #        ...
  #    }
  #    ...
  #   ]
  # * timeline_date_columns - a HASH of obr id to date info. used to create a
  #                           sorted date column array for combined view
  #   {id=>[year, month_day, time, et, [classes]].
  #    ...
  #   }
  # * first_cols - a HASH of group_id to column_id to indicate the 'first' column
  #               in the group
  #
  def get_panel_timeline_data(timeline_def, p_loinc_num, profile_id,
      start_date=nil, end_date=nil, end_date_str=nil, group_by_code=nil,
      date_range_code=nil, include_all=nil)

    panel_timeline_data = []
    date_columns = []
    first_cols = {}

    records, obr_records = get_panel_timeline_records(p_loinc_num, profile_id,
      start_date, end_date, end_date_str, date_range_code, include_all)

    # if there are any records
    if records.length >0

      # re-organize records into the format of
      #   {loinc_num => {record_id=>[display_value, abnormal_flag, units,
      #                       normal_high, normal_low, test_date, value,
      #                       test_time, test_date_ET, has_data, p_loinc_num],
      #                  record_id=>[display_value, abnormal_flag, units,
      #                       normal_high, normal_low, test_date, value,
      #                       test_time, test_date_ET, has_data, p_loinc_num],
      #                  ...
      #                 }
      temp_array = Array.new(records.length)
      # process each record in the result set
      records.each_with_index do |record, record_index|
        record_attrs = record.attributes
        obx5_value = record_attrs['obx5_value']
        if obx5_value.blank?
          has_data = false
        else
          has_data = true
        end
        # calculate the abnormal flag value
        abnormal_flag=''
        test_normal_high = record_attrs['test_normal_high']
        test_normal_low = record_attrs['test_normal_low']
        if has_data
          if !test_normal_high.blank? &&
              obx5_value.to_f > test_normal_high.to_f
            abnormal_flag ='*H'
          elsif !record.test_normal_low.blank? &&
              obx5_value.to_f < test_normal_low.to_f
            abnormal_flag ='*L'
          end
        end
        # empty value is replaced with '-'
        display_value = has_data ? obx5_value : '-'
        # create a temporary array
        temp_array[record_index] = [record_attrs['loinc_num'], {record_attrs['record_id'].to_s=>
            [display_value,abnormal_flag,record_attrs['obx6_1_unit'],
            test_normal_high,test_normal_low,
            record_attrs['test_date'],obx5_value,record_attrs['test_date_time'],
            record_attrs['test_date_ET'], has_data, record_attrs['p_loinc_num'],
            record_attrs['panel_name']]}]
      end

      # convert the temporary array to a temporary hash
      temp_hash = {}
      loinc_num = temp_array[0][0]
      test_hash = {}
      temp_array.each do |record|
        if loinc_num == record[0]
          if test_hash.empty?
            test_hash[loinc_num] = record[1]
          else
            test_hash[loinc_num].merge!(record[1])
          end
        else
          temp_hash.merge!(test_hash)
          test_hash = {}
          loinc_num=record[0]
          test_hash[loinc_num] = record[1]
        end
      end
      # last one
      temp_hash.merge!(test_hash)

      # add the summary, where_done and due_date into the hash
      # with a pseudo loinc_num as a key
      obr_info1 = {}
      obr_info2 = {}
      obr_info3 = {}
      # obr_records is returned from get_panel_timeline_records
      obr_records.each do |obr_record|
        # 12 fields
        obr_info1[obr_record.record_id.to_s] = [obr_record.summary,'','','','',
            '','','',obr_record.test_date_ET,!obr_record.summary.blank?,
            obr_record.loinc_num,obr_record.panel_name]
        obr_info2[obr_record.record_id.to_s] = [obr_record.test_place,'','','',
            '','','','',obr_record.test_date_ET,!obr_record.test_place.blank?,
            obr_record.loinc_num,obr_record.panel_name]
        obr_info3[obr_record.record_id.to_s] = [obr_record.due_date,'','','',
            '','','','',obr_record.test_date_ET,!obr_record.due_date.blank?,
            obr_record.loinc_num,obr_record.panel_name]
      end
      temp_hash[p_loinc_num + '_summary'] = obr_info1
      temp_hash[p_loinc_num + '_test_place'] = obr_info2
      temp_hash[p_loinc_num + '_due_date'] = obr_info3

      # calculate the most used units for each test/loinc_num
      most_used_units_hash = Hash.new
      temp_hash.each do |loinc_num, date_records|
        units_hash = Hash.new
        date_records.each do | obr_id, record|
          units = record[2]
          if !units.blank?
            if !units_hash[units].nil?
              units_hash[units] += 1
            else
              units_hash[units] = 1
            end
          end
        end
        if !units_hash.empty?
          sorted_units = units_hash.sort { |a,b| a[1] <=> b[1] }
          most_used_units = sorted_units[sorted_units.length-1][0]
          most_used_units_hash[loinc_num] = most_used_units
        end
      end

      # create the data table from the temporary hash
      # update timeline_def to add the most used units and a flag indicating
      # whether there's data for the test
      timeline_def.each do |record_def|
        loinc_num = record_def['loinc_num']
        if temp_hash[loinc_num].nil?
          panel_timeline_data << {}
          if record_def['is_test']
            record_def['no_data'] = true
            record_def['chart_data'] = {}
          end
        else
          test_records = temp_hash[loinc_num]
          # update timeline_data units
          has_data = false
          # data for chart
          chart_data = []
          test_records.each do |obr_id, test_record|
            # element in test_record are in the following order, as in the temp
            # array created above:
            # [display_value,abnormal_flag,record.obx6_1_unit,
            # record.test_normal_high,record.test_normal_low,
            # record.test_date,record.obx5_value,record.test_date_time,
            # record.test_date_ET, has_data, record.p_loinc_num,
            # record.panel_name]
            # if the units is the mostly used units, remove the units value
            if !test_record[2].blank? &&
                !most_used_units_hash[loinc_num].blank? &&
                test_record[2] == most_used_units_hash[loinc_num]
              test_record[2] = nil
            end
            # check if there's data in any columns
            if test_record[9]
              has_data = true
            end
            # get the chart data if it's a numeric value or a time field
            if record_def['data_type'] != 'CWE' &&
                record_def['data_type'] != 'CNE'
              # if it is a time field
              if record_def['data_type'] == 'TS'
                # value and date_et
                chart_data << [Util.time_to_int(test_record[6]), test_record[8],
                    test_record[3], test_record[4], obr_id]
              # if it is a numeric value
              elsif Util.numeric?(test_record[6])
                # value and date_et
                chart_data << [test_record[6].to_f, test_record[8],
                    test_record[3], test_record[4], obr_id]
              # if it's a nil, '', or other non-numeric strings
              # keep a placeholder of possible editing on the client side
              else
                chart_data << [nil, test_record[8],
                    test_record[3], test_record[4], obr_id]
              end
            end
          end
          panel_timeline_data << test_records
          record_def['no_data'] = !has_data
          if record_def['is_test']
            record_def['units'] = most_used_units_hash[loinc_num]
            # get the chart data if it's a numeric value
            # and has data and is not panel info row
            if record_def['data_type'] != 'CWE' &&
                record_def['data_type'] != 'CNE' &&
                !record_def['no_data'] && !record_def['panel_info'] &&
                !chart_data.empty?
              # sort chart_data
              chart_data_sorted = chart_data.sort {|a,b| (a[1] <=> b[1]) }
              # get the values and dates
              chart_values = []
              orders = []
              chart_data_sorted.each do |data|
                if data[0].nil?
                  chart_values << nil
                else
                  chart_values << data[1].to_s + ":" + data[0].to_s
                end
                orders << data[4]
              end
              # get the normal range
              norm_high = chart_data_sorted.last[2]
              norm_low = chart_data_sorted.last[3]
              record_def['chart_data'] = {'values' => chart_values,
                  'normal_range' => {'max' => norm_high, 'min' => norm_low},
                  'type' => record_def['data_type'],
                  'orders' => orders
              }
            end
          end
        end
      end
    # no records found
    else
      timeline_def.each do |record_def|
        panel_timeline_data << {}
        if record_def['disp_level'] >1 && record_def['is_test']
          record_def['no_data'] = true
        end
      end

    end

    # get the data table's column header information, which is the date
    # {record_id=>[year, month_day, time, et, [classes]].
    #  ...
    # }
    timeline_date_columns = {}
    panel_timeline_data.each do |test|
      if !test.nil? and !test.empty?
        test.keys.each do |id|
          date_et = test[id][8]
          p_loinc_num = test[id][10]
          p_panel_name =test[id][11]
          if !date_et.blank?
            begin
              time = Time.at((date_et/1000).to_i)
            rescue RangeError
              # With the 32-bit ruby, the supported date range is limited,
              # and a date like 1850/1/1 causes the above line to blow up.
              # We are moving to a 64-bit version; for now just skip this
              # result so that the flowsheet isn't broken.
            end
            if time
              year = time.year.to_s
              month_day = time.strftime("%d %b")
              #ymd = time.strftime("%Y%m%d")
              #hour_second = time.strftime("%I:%M %p")

              # if there's grouped columns
              # class will be added later if there's grouped columns
              if !group_by_code.blank? && group_by_code != '1'
                #              timeline_date_columns[id]=[year,month_day,test[id][7],date_et]
                timeline_date_columns[id]=[year,month_day,test[id][7],date_et,
                  [id],p_loinc_num, p_panel_name]
              else
                #              timeline_date_columns[id]=[year,month_day,test[id][7],date_et,[ymd]]
                timeline_date_columns[id]=[year,month_day,test[id][7],date_et,
                  [id],p_loinc_num, p_panel_name]
              end
            end
          end
        end
      end
    end

    # sorted by test_date_ET, lastest first
    # [ {record_id=>[year, month_day, time, et, [classes]]}.
    #   ...
    # ]
    date_columns =[]
    sorted_array = timeline_date_columns.sort {|a,b| b[1][3] <=> a[1][3] }
    sorted_array.each do |rec|
      date_columns << {rec[0]=>rec[1]}
    end

    # add additional date columns for the group by record
    if !group_by_code.blank? && group_by_code != '1'
      summary_columns = {}
      group_value = ''
      group_ymd = nil
      date_columns.each do | date_column|
        id = date_column.keys[0]
        date_info = date_column.values[0]

        date_et = date_info[3]
        if !date_et.blank?
          time = Time.at((date_et/1000).to_i)
          current_ymd = time.strftime("%Y%m%d")
          current_ym = time.strftime("%YM%m")
          current_yw = time.strftime("%YW%U")
          month_day = time.strftime("%d %b")
          day = time.day.to_s
          week = time.strftime("%U")
          month = time.strftime("%B")
          year = time.year.to_s

          # set the ymd value if this is the 1st record
          if group_ymd.nil?
            group_ymd=current_ymd
          end

          # make the grouped column data record
          case group_by_code
          when '2' # day
            current_group_value = current_ymd
            group_class = 'g_' + current_group_value
            summary_column = [year,month_day,'',date_et, ['sum',group_class]]
          when '3' # week
            current_group_value = current_yw
            group_class = 'g_' + current_group_value
            summary_column = [year,'Week ' + week.to_i.to_s,'',date_et,
                ['sum',group_class]]
          when '4' # month
            current_group_value = current_ym
            group_class = 'g_' + current_group_value
            summary_column = [year,month,'',date_et, ['sum',group_class]]
          when '5' # year
            current_group_value = year
            group_class = 'g_' + current_group_value
            summary_column = [year,'','',date_et, ['sum',group_class]]
          end

          # if this starts a new group, add the additional summary column
          if group_value != current_group_value
            sum_col_id = 'sum_' + current_group_value
            summary_columns[sum_col_id] = summary_column

            # add summary data.
            # for now it copies data from the 1st record in the group
            panel_timeline_data.each do |data_row|
              if !data_row.empty?
                sum_data_rec = data_row[id.to_s]
                data_row[sum_col_id] = sum_data_rec
              end
            end
            group_ymd=current_ymd
            # it is the first column after the order is reversed
            first_cols[current_group_value] = id
          end
          group_value = current_group_value

          # update the existing date columns to add classes
          # only when there's a grouped column
          timeline_date_columns[id][4] << 'rec'
          timeline_date_columns[id][4] << group_class
        end
      end
      # add the new date columns
      timeline_date_columns.merge!(summary_columns)
    end

    return panel_timeline_data, timeline_date_columns, first_cols

  end


  #
  # get a panel's data records, for the timeline view
  # called by get_panel_timeline_data
  #
  # Parameters:
  # * p_loinc_num - a loinc_num of a top level panel LOINC item
  # * profile_id - a profile's id
  # * start_date - a epoch value of date that represents the 'from' limit
  #                of the test date in the search result
  # * end_date - a epoch value of date that represents the 'to' limit of
  #              the test date in the search result
  # * end_date_str - the string value of the end date. It could be in the format
  #   of 'yyyy', 'yyyy Mon', or 'yyyy Mon dd'
  # * date_range_code - a code that indicates a different date range
  # * include_all - a code that indicates if all data from other panels for the same
  #                 tests in this panel should be included
  #
  # Returns:
  # * records - an array of combined records
  # * obr_records - an array of obr records
  #
  def get_panel_timeline_records(p_loinc_num, profile_id,
      start_date=nil, end_date=nil, end_date_str=nil, date_range_code=nil,
      include_all=nil)

    select_string = "SELECT DISTINCT a.test_date_ET, a.test_date, b.obx5_value, " +
        "b.obx6_1_unit, b.test_normal_high, b.test_normal_low, b.loinc_num, " +
        "a.test_date_time, a.record_id, a.loinc_num p_loinc_num, a.panel_name "+
        "FROM obr_orders a LEFT JOIN obx_observations b ON a.id=b.obr_order_id "
    # include data in all the panels
    if include_all
      loinc_item = LoincItem.find_by_loinc_num(p_loinc_num)
      if loinc_item.is_test?
        str_loinc_nums = "('#{p_loinc_num}')"
      else
        panel_item = LoincPanel.where("p_id=id AND loinc_num=?", p_loinc_num).first

        test_loinc_nums = panel_item.get_all_test_loinc_nums
        loinc_nums_w_quote = []
        test_loinc_nums.map {|loinc_num| loinc_nums_w_quote << "'#{loinc_num}'"}
        str_loinc_nums = "(#{loinc_nums_w_quote.join(',')})"
      end

      condition_string = "WHERE a.profile_id=" +
          "#{profile_id} AND b.loinc_num IN #{str_loinc_nums}"

    # just the data in this panel
    else
      condition_string = "WHERE a.profile_id=" +
        "#{profile_id} AND a.loinc_num='#{p_loinc_num}' "
    end

    now = Time.now
    start_of_today = Time.local(now.year,now.month,now.day,0,0,0).to_i * 1000
    ms_in_a_day = 24 * 60 * 60 *1000
    # limit by date
    if !date_range_code.blank?
      case date_range_code
      # all
      when '1'
        time_then = nil
      # 7 days
      when '2'
        time_then = start_of_today - ms_in_a_day * 7
      # 30 days
      when '3'
        time_then = start_of_today - ms_in_a_day * 30
      # 60 days
      when '4'
        time_then = start_of_today - ms_in_a_day * 60
      # 180 days
      when '5'
        time_then = start_of_today - ms_in_a_day * 180
      # 1 year
      when '6'
        time_then =  Time.local(now.year-1,now.month,now.day,0,0,0).to_i * 1000
      # Customize
      when '7'
        time_then = nil

        if !start_date.blank?
          time = Time.at((start_date/1000).to_i)
          start_time = Time.local(time.year,time.month,time.day,0,0,0).to_i * 1000
          date_condition = "AND a.test_date_ET >= #{start_time} "
        else
          date_condition = ""
        end
        if !end_date.blank?
          time = Time.at((end_date/1000).to_i)
          # check the end date format
          str_length = end_date_str.length
          end_time = nil
          # if it's a 'yyyy'
          if str_length == 4
            end_time = Time.local(time.year,1,1,0,0,0).next_year.to_i * 1000
          # if it's a 'yyyy Mon'
          elsif str_length == 8
            end_time = Time.local(time.year,time.month,1,0,0,0).next_month.to_i * 1000
          # if it's a 'yyyy Mon dd' or 'yyyy Mon d'
          elsif str_length == 11 || str_length == 10
            end_time = Time.local(time.year,time.month,time.day,0,0,0).tomorrow.to_i * 1000
          end
          date_condition += "AND a.test_date_ET < #{end_time} " unless end_time.nil?
        end
      # 2 years
      when '8'
        time_then =  Time.local(now.year-2,now.month,now.day,0,0,0).to_i * 1000
      # 3 years
      when '9'
        time_then =  Time.local(now.year-3,now.month,now.day,0,0,0).to_i * 1000
      # 5 years
      when '10'
        time_then =  Time.local(now.year-5,now.month,now.day,0,0,0).to_i * 1000
      # 10 years
      when '11'
        time_then =  Time.local(now.year-10,now.month,now.day,0,0,0).to_i * 1000
      end
      date_condition = "AND a.test_date_ET >= #{time_then} " unless time_then.nil?
      condition_string += date_condition unless date_condition.nil?
    end
    # order by loinc_num and time
    order_string = "ORDER BY b.loinc_num, a.test_date_ET"
    records = ObrOrder.find_by_sql(select_string + condition_string +
        order_string)

    # obr records
    obr_query_string = "SELECT a.* FROM obr_orders a " +
        "WHERE a.profile_id=#{profile_id} AND a.loinc_num='#{p_loinc_num}' "
    obr_query_string += date_condition unless date_condition.nil?
    obr_records = ObrOrder.find_by_sql(obr_query_string)
    return records, obr_records
  end


  #
  # get a top level panel definition, for timeline view.
  #   called by get_panel_timeline_def
  #
  # Parameters:
  # * panel_timeline_def - an array of hash maps for each test/subpanel
  #                        in a panel
  # * loinc_num - the loinc number of the top level panel item
  #
  # Returns: None
  #   values are returned in the input parameters of panel_timeline_def and
  #   display_level
  #
  def self.get_panel_timeline_top_level_panel_def(panel_timeline_def, loinc_num)
    display_level = 1
    panel_item = LoincPanel.where(loinc_num: loinc_num).where("id=p_id").first
    if !panel_item.nil?
      panel_def_row = Hash.new
      panel_def_row['loinc_num'] = panel_item.loinc_num
      panel_def_row['name'] = panel_item.display_name
      panel_def_row['disp_level'] = display_level
      panel_def_row['is_test'] = false
      panel_def_row['required'] = panel_item.required_in_panel?
      panel_timeline_def << panel_def_row
      # add additional rows for comment, where done and due date
      # comment
      panel_timeline_def << {
        'loinc_num'=> panel_item.loinc_num + '_summary',
        'name' => 'Comment',
        'disp_level' => 2,
        'is_test' => true,
        'panel_info' =>true,
        'required' => panel_item.required_in_panel?
      }
      # where done
      panel_timeline_def << {
        'loinc_num'=> panel_item.loinc_num + '_test_place',
        'name' => 'Where done',
        'disp_level' => 2,
        'is_test' => true,
        'panel_info' =>true,
        'required' => panel_item.required_in_panel?
      }
      # due date
      panel_timeline_def << {
        'loinc_num'=> panel_item.loinc_num + '_due_date',
        'name' => 'Due Date',
        'disp_level' => 2,
        'is_test' => true,
        'panel_info' =>true,
        'required' => panel_item.required_in_panel?
      }

      display_level +=1
      # For each of of the sub_items below, we check its sub fields by calling
      # has_sub_fields?, so we might as well include them.  Also,
      # get_panel_timeline_sub_def is recursive, so we include more than one
      # level of subpanels.  You can include as many levels as you like, but
      # this number works well for the Daisy Duck flowsheet.
      sub_items = panel_item.sub_fields.includes(:loinc_item,
        :sub_fields=>[:loinc_item,
        :sub_fields=>[:loinc_item, :sub_fields=>:loinc_item]])
      sub_items.each do |sub_item|
        if sub_item.loinc_item.included_in_phr? and sub_item.id != sub_item.p_id
          panel_def_row = Hash.new
          panel_def_row['loinc_num'] = sub_item.loinc_num
          panel_def_row['name'] = sub_item.display_name
          panel_def_row['disp_level'] = display_level
          panel_def_row['required'] = sub_item.required_in_panel?

          if sub_item.has_sub_fields?
            panel_def_row['is_test'] = false
            panel_def_row['panel_info'] = false
            panel_timeline_def << panel_def_row
            get_panel_timeline_sub_def(panel_timeline_def, sub_item,
              display_level)
          else
            panel_def_row['is_test'] = true
            panel_def_row['panel_info'] = false
            panel_def_row['data_type'] = sub_item.loinc_item.data_type
            panel_timeline_def << panel_def_row
          end
        end
      end
    end

  end


   #
  # get a single test panel definition, for timeline view.
  #   called by get_panel_timeline_def
  #
  # Parameters:
  # * panel_timeline_def - an array of hash maps for each test/subpanel
  #                        in a panel
  # * loinc_num - the loinc number of a test loinc item
  #
  # Returns: None
  #   values are returned in the input parameters of panel_timeline_def and
  #   display_level
  #
  def self.get_panel_timeline_single_test_panel_def(panel_timeline_def, loinc_num)
    loinc_item = LoincItem.find_by_loinc_num(loinc_num)

    if !loinc_item.nil?
      # the panel row
      panel_timeline_def << {
        'loinc_num'=> loinc_item.loinc_num,
        'name' => loinc_item.display_name,
        'disp_level' => 1,
        'is_test' => false,
        'panel_info' => false,
        'required' => true
      }
      # add additional rows for comment, where done and due date
      # comment
      panel_timeline_def << {
        'loinc_num'=> loinc_item.loinc_num + '_summary',
        'name' => 'Comment',
        'disp_level' => 2,
        'is_test' => true,
        'panel_info' =>true,
        'required' => true
      }
      # where done
      panel_timeline_def << {
        'loinc_num'=> loinc_item.loinc_num + '_test_place',
        'name' => 'Where done',
        'disp_level' => 2,
        'is_test' => true,
        'panel_info' =>true,
        'required' => true
      }
      # due date
      panel_timeline_def << {
        'loinc_num'=> loinc_item.loinc_num + '_due_date',
        'name' => 'Due Date',
        'disp_level' => 2,
        'is_test' => true,
        'panel_info' =>true,
        'required' => true
      }

      # the test
      panel_timeline_def << {
        'loinc_num'=> loinc_item.loinc_num,
        'name' => loinc_item.display_name,
        'disp_level' => 2,
        'is_test' => true,
        'panel_info' => false,
        'required' => true,
        'data_type' => loinc_item.data_type
      }
    end
  end


  #
  # get a panel sub item definition, for timeline view.
  #   called by get_panel_timeline_def and itself
  #
  # Parameters:
  # * panel_timeline_def - an array of hash maps for each test/subpanel
  #                        in a panel
  # * panel_item - a LoincPanel object of a sub item of a panel
  # * display_level - the structural level of the panel item in a panel
  #
  # Returns: None
  #   values are returned in the input parameters of panel_timeline_def and
  #   display_level
  #
  def self.get_panel_timeline_sub_def(panel_timeline_def, panel_item, display_level)
    display_level += 1
    sub_items = panel_item.subFields
    sub_items.each do |sub_item|
      panel_def_row = Hash.new
      panel_def_row['loinc_num'] = sub_item.loinc_num
      panel_def_row['name'] = sub_item.display_name
      panel_def_row['disp_level'] = display_level
      panel_def_row['required'] = sub_item.required_in_panel?
      if sub_item.has_sub_fields?
        is_test = false
        panel_def_row['is_test'] = is_test
        panel_timeline_def << panel_def_row
        get_panel_timeline_sub_def(panel_timeline_def, sub_item,
          display_level)
      else
        is_test = true
        panel_def_row['is_test'] = is_test
        panel_def_row['data_type'] = sub_item.loinc_item.data_type
        panel_timeline_def << panel_def_row
      end
    end
  end


  #
  # get a panel's subitems data, for timeline view.
  #   called by get_panel_timeline_data and itself
  #
  # Parameters:
  # * panel_timeline_data - an array of hashmaps for each test/subpanel
  #                        in a panel
  # * panel_item - a LoincPanel object of a subitem of a panel
  # * profile_id - a profile's id
  #
  # Returns: None
  #   values are returned in the input parameters of panel_timeline_sub_data
  #
  def get_panel_timeline_sub_data(panel_timeline_data, panel_item, profile_id)
    sub_items = panel_item.subFields
    sub_items.each do |sub_item|
      if sub_item.id != sub_item.p_id
        if sub_item.has_sub_fields?
          panel_timeline_data << {}
          get_panel_timeline_sub_data(panel_timeline_data, sub_item, profile_id)
        else
          obrRecords = ObrOrder.where("profile_id=? and loinc_num=? and latest=?",
                  profile_id, sub_item.loinc_num, true).order('test_date_ET')
          obrobx_data ={}
          obrRecords.each do |obr_record|
            obxRecords = ObxObservation.where("obr_order_id=? and profile_id=? and latest=?",
                  obr_record.id, profile_id, true)
            obx_data ={}
            obxRecords.each do |obx_record|
              obx_data[obx_record.loinc_num] = [obx_record.obx5_value,
                  obx_record.obx6_1_unit, obx_record.obx7_reference_ranges]
            end
            obrobx_data[obr_record.test_date] = obx_data
          end
          panel_timeline_data << obrobx_data
        end
      end
    end

  end


  #
  # get data_table for displaying a NEW empty test panel
  #
  # Parameters:
  # * loinc_item - a loinc_item record for the test
  # * obr_index - optional, a panel sequence index
  # * profile_id - optional, a profile's id
  # * obr_record_id - optional, an obr record id
  #
  #
  # Returns:
  # * [data_table, obr_rec_num, obx_rec_num]
  #
  def get_one_single_test_panel_data_table(loinc_item, obr_index=0,
      profile_id=nil, obr_record_id=nil)

    # get the data into an hash if the obr_record_id is not nil
    if (obr_record_id)
      saved_obr = ObrOrder.where("profile_id=? AND record_id=? AND latest=?",
          profile_id.to_i, obr_record_id.to_i, true).first
      saved_obr_data = saved_obr.attributes unless saved_obr.nil?
      saved_obx = ObxObservation.where(
          "profile_id=? AND obr_order_id=? AND latest =?",
          profile_id.to_i, saved_obr.id, true).first
      saved_obx_data = saved_obx.attributes unless saved_obx.nil?
    end

    obr_table_data = Array.new
    obx_table_data = Array.new

    obr_rec_num = 0
    obx_rec_num = 0

    obr_table_def = @table_definition[OBR_TABLE]
    obx_table_def = @table_definition[OBX_TABLE]

    # obr_orders records
    obr_record = Hash.new
    obr_table_def.each do |col, col_def|
      case col
      when 'loinc_num'
        obr_record[col] = loinc_item.loinc_num
      when 'panel_name'
        obr_record[col] = loinc_item.display_name
      when 'test_place'
        if saved_obr_data.nil? || saved_obr_data[col].nil?
          current_value = ''
        else
          current_value = saved_obr_data[col]
        end
        obr_record[col] = get_merged_where_done_list(current_value)
      else
        obr_record[col] = saved_obr_data[col] unless saved_obr_data.nil?
      end
    end
    # set the single test flag
    obr_record['single_test'] = 1

    obr_record[PRIMARY_KEY_COL] = obr_index
    obr_table_data << obr_record
    obr_rec_num +=1

    # obx_observations records
    obx_record = Hash.new
    # create the default key/value
    obx_table_def.keys.each do | key|
      obx_record[key] = ''
    end
    # get last value, test date
    last_result = get_latest_result_for_single_test(loinc_item.loinc_num,
        profile_id)
    # get answer list
    answer_list = loinc_item.answers_and_codes
    # get unit and ranges and ranges
    units, codes, resultset = loinc_item.units_and_codes_and_ranges
    # add all fields under the top level panel, including sub panels
    # and normal tests
    # loinc num
    obx_record['loinc_num'] = loinc_item.loinc_num
    # display name
    obx_record['obx3_2_obs_ident'] = loinc_item.display_name
    # value
    if !saved_obx_data.nil? && !saved_obx_data.empty?
      obx5_value = saved_obx_data['obx5_value']
      obx5_code = saved_obx_data['obx5_1_value_if_coded']
      obx_record_id = saved_obx_data['record_id']
      value_real = saved_obx_data['value_real']
      obx_test_date = saved_obx_data['test_date']
      obx_test_date_et = saved_obx_data['test_date_ET']
      obx_test_date_hl7 = saved_obx_data['test_date_HL7']
    else
      obx5_value = ''
      obx5_code =''
      obx_record_id =''
      value_real = ''
      obx_test_date = ''
      obx_test_date_et = ''
      obx_test_date_hl7 = ''
    end
    obx_record['obx5_1_value_if_coded'] = obx5_code
    obx_record['record_id'] = obx_record_id
    obx_record['value_real'] = value_real
    if !answer_list.nil?
      obx_record['obx5_value'] = [obx5_value,answer_list[0], answer_list[1]]
    else
      obx_record['obx5_value'] = obx5_value
    end
    obx_record['test_date'] = obx_test_date
    obx_record['test_date_ET'] = obx_test_date_et
    obx_record['test_date_HL7'] = obx_test_date_hl7

    # last result
    if !last_result.nil?
      obx_record['last_value'] = last_result.obx5_value + " " + last_result.obx6_1_unit
      obx_record['last_date'] = last_result.test_date
      obx_record['last_date_ET'] = last_result.test_date_ET
      obx_record['last_date_HL7'] = last_result.test_date_HL7
      # new last value-date
      obx_record['lastvalue_date'] = last_result.obx5_value + " " + last_result.obx6_1_unit + "  " +
          mod_test_date_by_et(last_result.test_date_ET,last_result.test_date)
    end
    # unit and ranges and ranges
    if !units.nil?
      if !saved_obx_data.nil? && !saved_obx_data.empty?
        obx_record['obx6_1_unit'] =
            [saved_obx_data['obx6_1_unit'], units, codes]
        obx_record['unit_code'] = saved_obx_data['unit_code']
      else
        obx_record['obx6_1_unit'] = [units[0], units, codes]
        obx_record['unit_code'] = codes[0]
      end
      obx_record['test_normal_high'] = resultset[0].norm_high
      obx_record['test_normal_low'] = resultset[0].norm_low
      obx_record['test_danger_high'] = resultset[0].danger_high
      obx_record['test_danger_low'] = resultset[0].danger_low
      obx_record['obx7_reference_ranges'] = resultset[0].norm_range
    end
    obx_record['obx2_value_type'] = loinc_item.data_type
    obx_record['required_in_panel'] = true

    # add two additional columns
    #   PARENT_TABLE_COL = '_p_table_'
    #   FOREIGN_KEY_COL = '_p_id_'
    obx_record[PARENT_TABLE_COL] = OBR_TABLE
    obx_record[FOREIGN_KEY_COL] = obr_index

    # add 2 columns for display control
    obx_record['is_panel_hdr'] = false
    obx_record['disp_level'] = 1
    obx_table_data << obx_record
    obx_rec_num +=1

    # return values
    data_table = {OBR_TABLE=>obr_table_data, OBX_TABLE=>obx_table_data}
    return [data_table, obr_rec_num, obx_rec_num]
  end


  #
  # get data_table for displaying a NEW empty test panel
  #
  # Parameters:
  # * panel_item - a loinc_panel record object of a panel group field
  # * obr_index - optional, a panel sequence index
  # * profile_id - optional, a profile's id
  # * obr_record_id - optional, an obr record id
  #
  # Returns:
  # * [data_table, obr_rec_num, obx_rec_num]
  #
  def get_one_panel_data_table(loinc_panel_item, obr_index=0,
                               profile_id=nil, obr_record_id=nil)
    # get the data into an hash if the obr_record_id is not nil
    if (obr_record_id)
      saved_obr = ObrOrder.where(
          "profile_id=? AND record_id=? AND latest=?",
          profile_id.to_i, obr_record_id.to_i, true).first
      saved_obr_data = saved_obr.attributes unless saved_obr.nil?
      saved_obx = ObxObservation.where(
          "profile_id=? AND obr_order_id=? AND latest =?",
          profile_id.to_i, saved_obr.id, true)
      saved_obx_data = Hash.new
      saved_obx.each do |obx|
        saved_obx_data[obx.loinc_num] = obx.attributes
      end
    end
    obr_table_data = Array.new
    obx_table_data = Array.new

    obr_rec_num = 0
    obx_rec_num = 0

    obr_table_def = @table_definition[OBR_TABLE]
    obx_table_def = @table_definition[OBX_TABLE]

    # get the where done list

    disp_level = 1
    sub_items = loinc_panel_item.subFields()
    prefetch_latest_result_for_one_panel(loinc_panel_item, profile_id)
    sub_items.each do |sub_item|
      # the top level group header, should have one
      if sub_item.id == sub_item.p_id
        obr_record = Hash.new
        obr_table_def.each do |col, col_def|
          case col
          when 'loinc_num'
            obr_record[col] = sub_item.loinc_num
          when 'panel_name'
            obr_record[col] = sub_item.loinc_item.display_name
          when 'test_place'
            current_value = saved_obr_data.nil? ? '' : saved_obr_data[col]
            obr_record[col] = get_merged_where_done_list(current_value)
          else
            obr_record[col] = saved_obr_data.nil? ? '' : saved_obr_data[col]
          end
        end
        obr_record[PRIMARY_KEY_COL] = obr_index
        obr_table_data << obr_record
        obr_rec_num +=1
      else
        obx_record = Hash.new
        # create the default key/value
        obx_table_def.keys.each do | key|
          obx_record[key] = ''
        end
        # get last value, test date
        last_result = get_latest_result_from_prefetch(sub_item.loinc_num,
            profile_id)
#        last_result = get_latest_result(sub_item.loinc_num, profile_id)
        # get answer list
        answer_list = sub_item.loinc_item.answers_and_codes
        # get unit and ranges and ranges
        units, codes, resultset = sub_item.loinc_item.units_and_codes_and_ranges
        # add all fields under the top level panel, including sub panels
        # and normal tests
        # loinc num
        obx_record['loinc_num'] = sub_item.loinc_num
        # display name
        obx_record['obx3_2_obs_ident'] = sub_item.loinc_item.display_name
        # value
        if !saved_obx_data.nil? && !saved_obx_data.empty? &&
            !saved_obx_data[sub_item.loinc_num].nil?
          obx5_value = saved_obx_data[sub_item.loinc_num]['obx5_value']
          obx5_code = saved_obx_data[sub_item.loinc_num]['obx5_1_value_if_coded']
          obx_record_id = saved_obx_data[sub_item.loinc_num]['record_id']
          value_real = saved_obx_data[sub_item.loinc_num]['value_real']
          obx_test_date = saved_obx_data[sub_item.loinc_num]['test_date']
          obx_test_date_et = saved_obx_data[sub_item.loinc_num]['test_date_ET']
          obx_test_date_hl7 = saved_obx_data[sub_item.loinc_num]['test_date_HL7']
        else
          obx5_value = ''
          obx5_code =''
          obx_record_id =''
          value_real = ''
          obx_test_date = ''
          obx_test_date_et = ''
          obx_test_date_hl7 = ''
        end
        obx_record['obx5_1_value_if_coded'] = obx5_code
        obx_record['record_id'] = obx_record_id
        obx_record['value_real'] = value_real
        obx_record['test_date'] = obx_test_date
        obx_record['test_date_ET'] = obx_test_date_et
        obx_record['test_date_HL7'] = obx_test_date_hl7
        if !answer_list.nil?
          obx_record['obx5_value'] = [obx5_value,answer_list[0], answer_list[1]]
        else
          obx_record['obx5_value'] = obx5_value
        end
        # last result
        if !last_result.nil?
          obx_record['last_value'] = last_result.obx5_value + " " + last_result.obx6_1_unit
          obx_record['last_date'] = last_result.test_date
          obx_record['last_date_ET'] = last_result.test_date_ET
          obx_record['last_date_HL7'] = last_result.test_date_HL7
          # new last value-date
          obx_record['lastvalue_date'] = last_result.obx5_value + " " + last_result.obx6_1_unit + "  " +
              mod_test_date_by_et(last_result.test_date_ET,last_result.test_date)
        end
        # unit and ranges and ranges
        if !units.nil?
          if !saved_obx_data.nil? && !saved_obx_data.empty? &&
            !saved_obx_data[sub_item.loinc_num].nil?
            obx_record['obx6_1_unit'] =
                [saved_obx_data[sub_item.loinc_num]['obx6_1_unit'], units, codes]
            obx_record['unit_code'] = saved_obx_data[sub_item.loinc_num]['unit_code']
          else
            obx_record['obx6_1_unit'] = [units[0], units, codes]
            obx_record['unit_code'] = codes[0]
          end
          obx_record['test_normal_high'] = resultset[0].norm_high
          obx_record['test_normal_low'] = resultset[0].norm_low
          obx_record['test_danger_high'] = resultset[0].danger_high
          obx_record['test_danger_low'] = resultset[0].danger_low
          obx_record['obx7_reference_ranges'] = resultset[0].norm_range
        end
        obx_record['obx2_value_type'] = sub_item.loinc_item.data_type
        obx_record['required_in_panel'] = sub_item.required_in_panel?

        # add two additional columns
        #   PARENT_TABLE_COL = '_p_table_'
        #   FOREIGN_KEY_COL = '_p_id_'
        obx_record[PARENT_TABLE_COL] = OBR_TABLE
        obx_record[FOREIGN_KEY_COL] = obr_index

        if sub_item.has_sub_fields?
          # add 2 columns for display control
          obx_record['is_panel_hdr'] = true
          obx_record['disp_level'] = disp_level
          obx_table_data << obx_record
          obx_rec_num +=1
          # process the sub panel
          sub_panel_data, sub_obx_rec_num = process_one_sub_panel_data_table(
              sub_item, obr_index, profile_id, saved_obx_data, disp_level)
          obx_table_data = obx_table_data.concat(sub_panel_data)
          obx_rec_num += sub_obx_rec_num
        else
          # add 2 columns for display control
          obx_record['is_panel_hdr'] = false
          obx_record['disp_level'] = disp_level
          obx_table_data << obx_record
          obx_rec_num +=1
        end
      end
    end

    data_table = {OBR_TABLE=>obr_table_data, OBX_TABLE=>obx_table_data}
    return [data_table, obr_rec_num, obx_rec_num]
  end


  # get the where done list for one user
  # * current_value the current test_place value
  def get_merged_where_done_list(current_value)
    # the default list
    list_names, list_codes = self.class.get_merged_where_done_list(@user_obj)

    if !current_value.blank? && !list_names.include?(current_value)
      list_names << current_value
    end

    # options
    opts = {
      'matchListValue'=>false,
      'suggestionMode'=>0,
      'autoFill'=>true,
      'keepList'=>false
    }
    return [current_value, list_names, list_codes, opts]
  end


  #
  #
  # get data_table for one sub panel information
  #
  # Parameters:
  # * loinc_panel_item - a loinc_panel record object of a panel group field
  # * obr_index - a panel sequence index
  # * profile_id - a profile's id
  # * disp_level - current display level of the panel
  # * saved_obx_data - saved obx data record
  #
  # Returns:
  # * [obx_table_data, obx_rec_num]
  #
  def process_one_sub_panel_data_table(loinc_panel_item, obr_index, profile_id,
      saved_obx_data, disp_level = 1)
    obx_table_data = Array.new
    obx_table_def = @table_definition[OBX_TABLE]

    obx_rec_num = 0

    if !loinc_panel_item.nil?
      sub_items = loinc_panel_item.subFields()
      disp_level += 1 unless disp_level >= 5
      if !sub_items.nil?
        sub_items.each do |sub_item|
          obx_record = Hash.new
          # create the default key/value
          obx_table_def.keys.each do | key|
            obx_record[key] = ''
          end
          # get last value, test date
          last_result = get_latest_result_from_prefetch(sub_item.loinc_num,
              profile_id)
#          last_result = get_latest_result(sub_item.loinc_num, profile_id)
          # get answer list
          answer_list = sub_item.loinc_item.answers_and_codes
          # get unit and ranges and ranges
          units,codes,resultset = sub_item.loinc_item.units_and_codes_and_ranges
          # add all fields under the top level panel, including sub panels
          # and normal tests
          # loinc num
          obx_record['loinc_num'] = sub_item.loinc_num
          # display name
          obx_record['obx3_2_obs_ident'] = sub_item.loinc_item.display_name
          # value
          if !saved_obx_data.nil? && !saved_obx_data.empty? &&
              !saved_obx_data[sub_item.loinc_num].nil?
            obx5_value = saved_obx_data[sub_item.loinc_num]['obx5_value']
            obx5_code = saved_obx_data[sub_item.loinc_num]['obx5_1_value_if_coded']
            obx_record_id = saved_obx_data[sub_item.loinc_num]['record_id']
            value_real = saved_obx_data[sub_item.loinc_num]['value_real']
            obx_test_date = saved_obx_data[sub_item.loinc_num]['test_date']
            obx_test_date_et = saved_obx_data[sub_item.loinc_num]['test_date_ET']
            obx_test_date_hl7 = saved_obx_data[sub_item.loinc_num]['test_date_HL7']
          else
            obx5_value = ''
            obx5_code =''
            obx_record_id =''
            value_real = ''
            obx_test_date = ''
            obx_test_date_et = ''
            obx_test_date_hl7 = ''
          end
          obx_record['obx5_1_value_if_coded'] = obx5_code
          obx_record['record_id'] = obx_record_id
          obx_record['value_real'] = value_real
          obx_record['test_date'] = obx_test_date
          obx_record['test_date_ET'] = obx_test_date_et
          obx_record['test_date_HL7'] = obx_test_date_hl7
          if !answer_list.nil?
            obx_record['obx5_value'] = [obx5_value,answer_list[0], answer_list[1]]
          else
            obx_record['obx5_value'] = obx5_value
          end
          # last result
          if !last_result.nil?
            obx_record['last_value'] = last_result.obx5_value + " " + last_result.obx6_1_unit
            obx_record['last_date'] = last_result.test_date
            obx_record['last_date_ET'] = last_result.test_date_ET
            obx_record['last_date_HL7'] = last_result.test_date_HL7
            # new last value-date
            obx_record['lastvalue_date'] = last_result.obx5_value + " " + last_result.obx6_1_unit + "  " +
                mod_test_date_by_et(last_result.test_date_ET,
                last_result.test_date)
          end
          # unit and ranges
          if !units.nil?
            if !saved_obx_data.nil? && !saved_obx_data.empty? &&
              !saved_obx_data[sub_item.loinc_num].nil?
              obx_record['obx6_1_unit'] =
                  [saved_obx_data[sub_item.loinc_num]['obx6_1_unit'], units, codes]
              obx_record['unit_code'] = saved_obx_data[sub_item.loinc_num]['unit_code']
            else
              obx_record['obx6_1_unit'] = [units[0], units, codes]
              obx_record['unit_code'] = codes[0]
            end
            obx_record['test_normal_high'] = resultset[0].norm_high
            obx_record['test_normal_low'] = resultset[0].norm_low
            obx_record['test_danger_high'] = resultset[0].danger_high
            obx_record['test_danger_low'] = resultset[0].danger_low
            obx_record['obx7_reference_ranges'] = resultset[0].norm_range
          end
          obx_record['obx2_value_type'] = sub_item.loinc_item.data_type
          obx_record['required_in_panel'] = sub_item.required_in_panel?

          # add two additional columns
          #   PARENT_TABLE_COL = '_p_table_'
          #   FOREIGN_KEY_COL = '_p_id_'
          obx_record[PARENT_TABLE_COL] = OBR_TABLE
          obx_record[FOREIGN_KEY_COL] = obr_index

          if sub_item.has_sub_fields?
            # add 2 columns for display control
            obx_record['is_panel_hdr'] = true
            obx_record['disp_level'] = disp_level
            obx_table_data << obx_record
            obx_rec_num +=1
            # process the sub panel
            sub_panel_data, sub_obx_rec_num = process_one_sub_panel_data_table(
                sub_item, obr_index, profile_id, saved_obx_data, disp_level)
            obx_table_data = obx_table_data.concat(sub_panel_data)
            obx_rec_num += sub_obx_rec_num
        else
            # add 2 columns for display control
            obx_record['is_panel_hdr'] = false
            obx_record['disp_level'] = disp_level
            obx_table_data << obx_record
            obx_rec_num +=1
          end
        end # end sub_items.each
      end # end if !sub_items.nil?
    end # end !panel_item.nil?

    return [obx_table_data, obx_rec_num]

  end


  # pre-fetch the latest results of all the tests defined in a panel
  #
  # Parameters:
  # * panel_field - a panel header record object in loinc_panels
  # * profile_id - an id of a profile
  # Returns:
  # * @last_result - a hash that keeps the last results for this panel (and profile)
  def prefetch_latest_result_for_one_panel(panel_field, profile_id)
    @prefetched_last_result = {}

    if !profile_id.blank?
      loinc_nums = panel_field.obx_field_loinc_nums

      query_str ="select a.* from obx_observations a, " +
          " latest_obx_records b where a.id=b.last_obx_id and " +
          " b.loinc_num in (?) and " + " b.profile_id=? and a.obx5_value IS NOT NULL"
      results = ObxObservation.find_by_sql([query_str, loinc_nums, profile_id])

      results.each do |result|
        @prefetched_last_result[profile_id.to_s + '#' + result.loinc_num] = result
      end
    end
  end


  # get the latest result of one test from pre-fetched data
  #
  # Parameters:
  # * loinc_num - a test's LOINC number
  # * profile_id - an id of a profile
  # Returns:
  # * @last_result - a hash that keeps the last results for this panel (and profile)
  def get_latest_result_from_prefetch(loinc_num, profile_id)

    rtn = nil
    if !profile_id.blank?
      if !@prefetched_last_result.nil? && !@prefetched_last_result.empty?
        rtn = @prefetched_last_result[profile_id.to_s + '#' + loinc_num]
      end
    end
    return rtn
  end


  #
  # get the latest test result for one loinc test
  #
  # Parameters:
  # * loinc_num - a LOINC test's loinc_num
  # * profile_id - an id of a profile
  #
  # Returns:
  # * rtn - a hash map that contains the last test data, in the format of
  #   obx record
  #
  def get_latest_result_for_single_test(loinc_num, profile_id)
    # Initialize (but don't store) an Obx to use its method for getting the
    # latest record.
    tmp_obx = ObxObservation.new(:loinc_num=>loinc_num, :profile_id=>profile_id)
    tmp_obx.get_latest_obx_observation
  end


  #
  # get latest test result
  # old method, to be removed
  #
  # Parameters:
  # * loinc_num - a LOINC test's loinc_num
  # * profile_id - an id of a profile. search within all profiles if it is nil
  #
  # Returns:
  # * rtn - a hash map that contains the last test data, in the format of
  #   obx record
  #
  def get_latest_result(loinc_num, profile_id=nil)
    rtn = nil
    if !profile_id.nil?
      if DatabaseMethod.isMySQL
        query_str ="select a.*, b.test_date_ET from obx_observations a, " +
            " obr_orders b where a.obr_order_id=b.id and a.loinc_num=? and " +
            " a.profile_id=?  and a.obx5_value IS NOT NULL " +
            " order by b.test_date_ET DESC, a.updated_at DESC limit 1"
      else
        query_str ="select a.*, b.test_date_ET from obx_observations a, " +
            " obr_orders b where a.obr_order_id=b.id and a.loinc_num=? and " +
            " a.profile_id=?  and a.obx5_value IS NOT NULL and rownum <=1" +
            " order by b.test_date_ET DESC, a.updated_at DESC"
      end
      results = ObxObservation.find_by_sql([query_str, loinc_num, profile_id])

      if !results.nil? && results.length >0
        rtn = results[0]
      end
    end
    return rtn
  end


  #
  # create a more readable display format of the test date from it's ET value
  #
  # Parameters:
  # * test_date_et - the ET value of a test date
  # * test_date - the steing value of a test date
  #
  # Returns:
  # * rtn - a string of test date in a readable format
  #
  def mod_test_date_by_et(test_date_et,test_date)
    ObxObservation.formatted_test_age(test_date_et, test_date)
  end


  # For TaffyDB implementation on client side
  # get taffy db data from a data_table that is from the autosave_tmps table
  #
  # For TaffyDB implementation on client side
  #
  # get a data db and 2 mapping tables for taffydb, edit existing record
  #
  # Parameters:
  # * panel_field - a FieldDescription object of 'loinc_panel'
  # * obr_index - index of obr record
  # * obx_index - index of obx record
  # * pnale_grp_sn - sequence number of panel groups on a form
  # * suffix_prefix - prefix to panel fields id's suffix
  # * profile_id - id of a profile record
  # * data_table - data_table merged from data in autosave_tmps
  #
  # Returns:
  # * [data_table, taffy_mapping, taffy_model]
  #
  # - +data_table+ - data hash that in the same format of the tables in
  #   database used for the creation of a taffydb.
  # - +taffy_mapping+ - a mapping table between fields on a form and records
  #   in a taffydb, for lookups from form fields to taffydb
  #   records and from taffydb record to form fields.
  # - +taffy_model+ - a database model record for inserting new empty records
  #   in taffydb when a new row is created in a form table.
  #
  def get_panel_taffy_db_data(panel_field, obr_index=0,obx_index=0,
        panel_grp_sn='', suffix_prefix='', profile_id = nil, data_table=nil)

    if !@has_data_table
      return nil
    end

    from_autosave = data_table.nil? ? false : true

    panel_sn = 0
    panel_taffy_db_data = []
    if panel_field.control_type=='test_panel' ||
          panel_field.control_type=='loinc_panel'
      loinc_nums = panel_field.getParam('loinc_num')
      # if there are no loinc_nums associated with the field
      if loinc_nums.blank?
         # try to find loinc_nums in the data_table retrieved from autosave_tmps
         if from_autosave && !data_table[OBR_TABLE].nil?
           loinc_nums = data_table[OBR_TABLE].map {|x| x['loinc_num']}
         end
      end
      if !loinc_nums.blank?
        process_items = {}
        panel_loinc_nums = []
        LoincItem.find_in_order(loinc_nums).each do |loinc_item|
          if !loinc_item.nil?
            if loinc_item.is_test?
              process_items[loinc_item.loinc_num] = [loinc_item, true ]
            elsif loinc_item.has_top_level_panel?
              panel_loinc_nums << loinc_item.loinc_num
            end
          end
        end
        if !panel_loinc_nums.empty?
          LoincPanel.find_panels_in_order(panel_loinc_nums).each do |panel_item|
            if !panel_item.nil?
              process_items[panel_item.loinc_num] = [panel_item, false ]
            end
          end
        end
        loinc_nums.each do |loinc_num|
          process_item, single_test = process_items[loinc_num]
          # just incase the loinc_num does not exist
          # such as in the integration tests the loinc_items table is empty
          if !process_item.nil?
            one_panel_taffy_db_data, obr_index, obx_index =
                get_one_panel_taffy_db_data(process_item, obr_index,
                obx_index, panel_grp_sn, panel_sn, suffix_prefix, profile_id,
                nil, single_test)

            # merger panel's taffy db data
            if panel_taffy_db_data.empty?
              panel_taffy_db_data = one_panel_taffy_db_data
            else
              # merge data table
              if !from_autosave
                panel_taffy_db_data[0].each do |table_name, records|
                  panel_taffy_db_data[0][table_name] =
                      records.concat(one_panel_taffy_db_data[0][table_name])
                end
              end
              # merge mapping
              panel_taffy_db_data[1] =
                  panel_taffy_db_data[1].merge(one_panel_taffy_db_data[1])
              # model class is the same, no need to merge

              # merge table_2_group
              # for obr table
              table_2_group = panel_taffy_db_data[3][OBR_TABLE]
              one_panel_taffy_db_data[3][OBR_TABLE].each do |grp_id, rec_num|
                if !table_2_group[grp_id].blank?
                  table_2_group[grp_id] = table_2_group[grp_id] + rec_num
                else
                  table_2_group[grp_id] = rec_num
                end
              end
              # for obx table
              table_2_group = panel_taffy_db_data[3][OBX_TABLE]
              one_panel_taffy_db_data[3][OBX_TABLE].each do |grp_id, rec_num|
                if !table_2_group[grp_id].blank?
                  table_2_group[grp_id] = table_2_group[grp_id] + rec_num
                else
                  table_2_group[grp_id] = rec_num
                end
              end
            end
            panel_sn += 1
          end
        end
      end
    end
    # data_table is from autosave_tmps
    if from_autosave
      panel_taffy_db_data[0] = data_table
    end
    return [panel_taffy_db_data,obr_index, obx_index]

  end


  #
  # Only for fields whose control_type is 'test_panel' or 'loinc_panel'
  # Get the Panel definitions from Loinc tables based on the loinc_num
  # specfied in the control_type_details parameter "loinc_num"
  # Return a data_hash like structure, which will be insert into the form's
  # data_hash structure.
  # The top level keys of this returning data_hash are the target_fields of the
  # top level groups in the panel template, which is 'tp_loinc_panel_temp_grp'
  #
  # Parameters:
  # * panel_field - a field_description record object of the panel group field
  # * panel_grp_sn - a sequence number of the current panel group
  # * profile_id - a profile's id
  #
  # Returns:
  # * data_hash - a data_hash hash map that is used to load data into a form
  #
  def get_panel_data_hash(panel_field, panel_grp_sn = '', profile_id=nil)
    panel_grp_sn = panel_grp_sn.to_s
    panel_grp_key = 'tp'+panel_grp_sn+'_loinc_panel_temp_grp'
    data_hash = {}
    panel_data_array = []
    if panel_field.control_type=='test_panel' ||
          panel_field.control_type=='loinc_panel'
      loinc_nums = panel_field.getParam('loinc_num')
      if !loinc_nums.blank?
        LoincPanel.find_panels_in_order(loinc_nums).each do |panel_item|
          if !panel_item.nil?
            one_panel_data_hash= get_one_panel_data_hash(panel_item,
                panel_grp_sn, profile_id)
            one_panel_data = one_panel_data_hash[panel_grp_key]
            panel_data_array = panel_data_array.concat(one_panel_data)
          end
        end
        data_hash[panel_grp_key] = panel_data_array
      end
    end
    return data_hash
  end


  #
  # Get the Panel definitions from Loinc tables based on the loinc_num
  # specfied in the control_type_details parameter "loinc_num"
  # Return a data_hash like structure, which will be insert into the form's
  # data_hash structure.
  # The top level keys of this returning data_hash are the target_fields of the
  # top level groups in the panel template, which is 'tp_loinc_panel_temp_grp'
  #
  # Parameters:
  # * panel_item - a loinc_panel record object of the panel group field
  # * panel_grp_sn - a sequence number of the current panel group
  # * profile_id - a profile's id
  #
  # Returns:
  # * data_hash - a data_hash hash map that is used to load data into a form
  #
  def get_one_panel_data_hash(panel_item, panel_grp_sn = '', profile_id = nil)
    panel_grp_sn = panel_grp_sn.to_s
    disp_level = 0
    one_panel_data = []
    sub_items = panel_item.subFields()
    disp_level += 1 unless disp_level >= 5
    prefetch_latest_result_for_one_panel(panel_item, profile_id)
    sub_items.each do |sub_item|
      # do not include the top level panel info, which is displayed in
      # the top level group header
      if sub_item.id != sub_item.p_id
        # add all fields under the top level panel, including sub panels
        # and normal tests
        one_panel_test = {}
        last_result = get_latest_result_from_prefetch(sub_item.loinc_num,
            profile_id)
#        last_result = get_latest_result(sub_item.loinc_num, profile_id)
        one_panel_test['tp'+panel_grp_sn+'_loinc_panel_temp_test_id'] =''
        #one_panel_test['tp'+panel_grp_sn+'_test_loinc_num_display'] =
        #    sub_item.loinc_num
        one_panel_test['tp'+panel_grp_sn+'_test_name'] =
            sub_item.loinc_item.display_name
        # answer list
        list = sub_item.loinc_item.answers_and_codes
        if list.nil?
          one_panel_test['tp'+panel_grp_sn+'_test_value'] = ""
        else
          one_panel_test['tp'+panel_grp_sn+'_test_value'] =["",list[0], list[1]]
        end
        if !last_result.nil?
          one_panel_test['tp'+panel_grp_sn+'_test_last_value'] =
              last_result.obx5_value +  " " + last_result.obx6_1_unit
          one_panel_test['tp'+panel_grp_sn+'_test_lastdate'] =
              last_result.test_date
          one_panel_test['tp'+panel_grp_sn+'_test_lastdate_ET'] =
              last_result.test_date_ET
          one_panel_test['tp'+panel_grp_sn+'_test_lastdate_HL7'] =
              last_result.test_date_HL7
          # new last value-date
          one_panel_test['tp'+panel_grp_sn+'_test_lastvalue_date'] =
              last_result.obx5_value + " " + last_result.obx6_1_unit + "  " +
              mod_test_date_by_et(last_result.test_date_ET,
              last_result.test_date)
        else
          one_panel_test['tp'+panel_grp_sn+'_test_last_value'] = ''
          one_panel_test['tp'+panel_grp_sn+'_test_lastdate'] = ''
          one_panel_test['tp'+panel_grp_sn+'_test_lastdate_ET'] = ''
          one_panel_test['tp'+panel_grp_sn+'_test_lastdate_HL7'] = ''
          # new last value-date
          one_panel_test['tp'+panel_grp_sn+'_test_lastvalue_date'] = ''
        end
        # unit and ranges and ranges
        units, codes, resultset = sub_item.loinc_item.units_and_codes_and_ranges
        if units.nil?
          one_panel_test['tp'+panel_grp_sn+'_test_unit'] = ""
          one_panel_test['tp'+panel_grp_sn+'_test_unit_C'] = ""
          one_panel_test['tp'+panel_grp_sn+'_test_normal_high'] =""
          one_panel_test['tp'+panel_grp_sn+'_test_normal_low'] =""
          one_panel_test['tp'+panel_grp_sn+'_test_danger_high'] =""
          one_panel_test['tp'+panel_grp_sn+'_test_danger_low'] =""
          one_panel_test['tp'+panel_grp_sn+'_test_range'] = ""
        else
          one_panel_test['tp'+panel_grp_sn+'_test_unit'] =
              [units[0], units, codes]
          one_panel_test['tp'+panel_grp_sn+'_test_unit_C'] = codes[0]
          one_panel_test['tp'+panel_grp_sn+'_test_normal_high'] =
              resultset[0].norm_high
          one_panel_test['tp'+panel_grp_sn+'_test_normal_low'] =
              resultset[0].norm_low
          one_panel_test['tp'+panel_grp_sn+'_test_danger_high'] =
              resultset[0].danger_high
          one_panel_test['tp'+panel_grp_sn+'_test_danger_low'] =
              resultset[0].danger_low
          one_panel_test['tp'+panel_grp_sn+'_test_range'] =
              resultset[0].norm_range
        end
        one_panel_test['tp'+panel_grp_sn+'_test_loinc_num'] = sub_item.loinc_num
        one_panel_test['tp'+panel_grp_sn+'_test_value_C'] =''
        one_panel_test['tp'+panel_grp_sn+'_test_score'] =''
        one_panel_test['tp'+panel_grp_sn+'_test_data_type'] =
            sub_item.loinc_item.data_type
        one_panel_test['tp'+panel_grp_sn+'_test_code_system'] =''
        one_panel_test['tp'+panel_grp_sn+'_test_required_in_panel'] =
            sub_item.required_in_panel?

        one_panel_data << one_panel_test

        if sub_item.has_sub_fields?
          # add 2 columns for display control
          one_panel_test['tp'+panel_grp_sn+'_test_is_panel_hdr'] = true
          one_panel_test['tp'+panel_grp_sn+'_test_disp_level'] = disp_level
          # process the sub panel
          sub_panel_data = process_one_panel_tests(sub_item, panel_grp_sn,
              profile_id, disp_level)
          one_panel_data = one_panel_data.concat(sub_panel_data)
        else
          # add 2 columns for display control
          one_panel_test['tp'+panel_grp_sn+'_test_is_panel_hdr'] = false
          one_panel_test['tp'+panel_grp_sn+'_test_disp_level'] = disp_level
        end
      end
    end
    one_panel_hash = {}
    one_panel_hash['tp'+panel_grp_sn+'_loinc_panel_temp_test']=one_panel_data
    one_panel_hash['tp'+panel_grp_sn+'_panel_testdate'] = ''
    one_panel_hash['tp'+panel_grp_sn+'_panel_testdate_ET'] = ''
    one_panel_hash['tp'+panel_grp_sn+'_panel_testdate_HL7'] = ''
    # the where one location list is prefetched by displayField, stored in the
    # hidden model row. not to replace it by adding a key of
    # 'tp'+panel_grp_sn+'_panel_testplace'
    # one_panel_hash['tp'+panel_grp_sn+'_panel_testplace']
    one_panel_hash['tp'+panel_grp_sn+'_panel_duedate'] = ''
    one_panel_hash['tp'+panel_grp_sn+'_panel_duedate_ET'] = ''
    one_panel_hash['tp'+panel_grp_sn+'_panel_duedate_HL7'] = ''

    # add one more level of group
    one_panel_grp_hash= {}
    one_panel_grp_hash['tp'+panel_grp_sn+'_loinc_panel_temp'] = one_panel_hash
    # add invisible fields
    one_panel_grp_hash['tp'+panel_grp_sn+'_invisible_field_panel_name']=
        panel_item.loinc_item.display_name
    one_panel_grp_hash['tp'+panel_grp_sn+'_invisible_field_panel_loinc_num']=
        panel_item.loinc_num
    panel_data = []
    panel_data << one_panel_grp_hash
    data_hash = {}
    data_hash['tp'+panel_grp_sn+'_loinc_panel_temp_grp'] = panel_data
    return data_hash
  end


  #
  # get one sub panel information
  def process_one_panel_tests(panel_item, panel_grp_sn, profile_id,disp_level=1)
    one_panel_data = []
    if !panel_item.nil?
      sub_items = panel_item.subFields()
      disp_level += 1 unless disp_level >= 5
      if !sub_items.nil?
        sub_items.each do |sub_item|
          # add all fields under the top level panel, including sub panels
          # and normal tests
          one_panel_test = {}
          last_result = get_latest_result_from_prefetch(sub_item.loinc_num,
              profile_id)
#          last_result = get_latest_result(sub_item.loinc_num, profile_id)
          one_panel_test['tp'+panel_grp_sn+'_loinc_panel_temp_test_id'] =''
          one_panel_test['tp'+panel_grp_sn+'_test_name'] =
              sub_item.loinc_item.display_name
          # answer list
          list = sub_item.loinc_item.answers_and_codes
          if list.nil?
            one_panel_test['tp'+panel_grp_sn+'_test_value'] = ""
          else
            one_panel_test['tp'+panel_grp_sn+'_test_value'] = ["",list[0],
                list[1]]
          end
          if !last_result.nil?
            one_panel_test['tp'+panel_grp_sn+'_test_last_value'] =
                last_result.obx5_value + " " + last_result.obx6_1_unit
            one_panel_test['tp'+panel_grp_sn+'_test_lastdate'] =
                last_result.test_date
            one_panel_test['tp'+panel_grp_sn+'_test_lastdate_ET'] =
                last_result.test_date_ET
            one_panel_test['tp'+panel_grp_sn+'_test_lastdate_HL7'] =
                last_result.test_date_HL7
            # new last value-date
            one_panel_test['tp'+panel_grp_sn+'_test_lastvalue_date'] =
                last_result.obx5_value + " " + last_result.obx6_1_unit + "  " +
                mod_test_date_by_et(last_result.test_date_ET,
                last_result.test_date)
          else
            one_panel_test['tp'+panel_grp_sn+'_test_last_value'] = ''
            one_panel_test['tp'+panel_grp_sn+'_test_lastdate'] = ''
            one_panel_test['tp'+panel_grp_sn+'_test_lastdate_ET'] = ''
            one_panel_test['tp'+panel_grp_sn+'_test_lastdate_HL7'] = ''
            # new last value-date
            one_panel_test['tp'+panel_grp_sn+'_test_lastvalue_date'] = ''
          end
          # unit and ranges and ranges
          units,codes,resultset = sub_item.loinc_item.units_and_codes_and_ranges
          if units.nil?
            one_panel_test['tp'+panel_grp_sn+'_test_unit'] = ""
            one_panel_test['tp'+panel_grp_sn+'_test_unit_C'] = ""
            one_panel_test['tp'+panel_grp_sn+'_test_normal_high'] =""
            one_panel_test['tp'+panel_grp_sn+'_test_normal_low'] =""
            one_panel_test['tp'+panel_grp_sn+'_test_danger_high'] =""
            one_panel_test['tp'+panel_grp_sn+'_test_danger_low'] =""
            one_panel_test['tp'+panel_grp_sn+'_test_range'] = ""
          else
            one_panel_test['tp'+panel_grp_sn+'_test_unit'] =
                [units[0], units, codes]
            one_panel_test['tp'+panel_grp_sn+'_test_unit_C'] = codes[0]
            one_panel_test['tp'+panel_grp_sn+'_test_normal_high'] =
                resultset[0].norm_high
            one_panel_test['tp'+panel_grp_sn+'_test_normal_low'] =
                resultset[0].norm_low
            one_panel_test['tp'+panel_grp_sn+'_test_danger_high'] =
                resultset[0].danger_high
            one_panel_test['tp'+panel_grp_sn+'_test_danger_low'] =
                resultset[0].danger_low
            one_panel_test['tp'+panel_grp_sn+'_test_range'] =
                resultset[0].norm_range
          end
          one_panel_test['tp'+panel_grp_sn+'_test_loinc_num'] =
              sub_item.loinc_num
          one_panel_test['tp'+panel_grp_sn+'_test_value_C'] =''
          one_panel_test['tp'+panel_grp_sn+'_test_score'] =''
          one_panel_test['tp'+panel_grp_sn+'_test_data_type'] =
              sub_item.loinc_item.data_type
          one_panel_test['tp'+panel_grp_sn+'_test_code_system'] =''
          one_panel_test['tp'+panel_grp_sn+'_test_required_in_panel'] =
              sub_item.required_in_panel?

          one_panel_data << one_panel_test
          if sub_item.has_sub_fields?
            one_panel_test['tp'+panel_grp_sn+'_test_is_panel_hdr'] = true
            one_panel_test['tp'+panel_grp_sn+'_test_disp_level'] = disp_level
            # process sub panels
            sub_panel_data = process_one_panel_tests(sub_item, panel_grp_sn,
                profile_id, disp_level)
            one_panel_data = one_panel_data.concat(sub_panel_data)
          else
            one_panel_test['tp'+panel_grp_sn+'_test_is_panel_hdr'] = false
            one_panel_test['tp'+panel_grp_sn+'_test_disp_level'] = disp_level
          end
        end
      end
    end
    return one_panel_data
  end

end # panel_data


