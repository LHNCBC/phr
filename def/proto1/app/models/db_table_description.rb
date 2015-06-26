class DbTableDescription < ActiveRecord::Base
  extend HasShortList

  has_many :db_field_descriptions, :dependent=>:destroy
  has_many :reminder_options
  has_many :date_reminders
  has_many :rule_fetches, :class_name =>"RuleFetch" ,
    :foreign_key => "source_table_C"

  validates_uniqueness_of :data_table
  validates_presence_of :data_table

  @@table_name_to_record = nil
  @@id_to_record = nil

  cache_recs_for_fields 'id', 'data_table', :preload=>true

  # Declares the model classes for the user data tables.
  def self.define_user_data_models
    ActiveRecord::Base.send(:include, PhrDataSanitizer)
    DbTableDescription.all.each do |dtd|
      class_name = dtd.data_table.singularize.camelize
      if (!self.class_exists?(class_name))
        class_def =<<DEF
          class ::#{class_name} < ActiveRecord::Base
            include UserData
            extend UserData::ClassMethods
          end
DEF
        eval(class_def)
      end
      class_name.constantize.sanitize_user_data

      # Create model classes for user historic data tables
      if !dtd.data_table.match(/^obsolete/)
        hist_class_name = ('hist_' + dtd.data_table).singularize.camelize
        if (!self.class_exists?(hist_class_name))
          hist_class_def =<<DEF
          class ::#{hist_class_name} < ActiveRecord::Base
          end
DEF
          eval(hist_class_def)
        end
      end
    end
  end


  # Returns all current data tables
  def self.current_data_tables
    DbTableDescription.all.select{|e| !e.data_table.match(/\Aobsolete_/)}
  end


  # Returns all current historical data tables
  def self.current_hist_table_names
    DbTableDescription.all.select{|e| !e.data_table.match(/\Aobsolete_/)}.map{|d| 'hist_' + d.data_table}
  end


  # Check if the class has been defined elsewhere in the system. Usually model
  # classes are defined in app/models
  #
  # Parameters:
  # * class_name - a table's model class name
  #
  # Returns:
  # * TRUE/FALSE
  #
  def self.class_exists?(class_name)
    rtn = false
    begin
      if Kernel.const_get(class_name).class == Class
        rtn = true
      end
    rescue
      # class does not exist
    ensure
      return rtn
    end
  end


  # Returns the model class for the data table corresponding to this
  # DbTableDescription.
  def model_class
    return data_table.singularize.camelize.constantize
  end


  # Creates a multi-record DbTableDescription for a table that can have more
  # that one record per profile.  Such tables require a record_id column,
  # so in addition to returning the DbTableDescription instance, this also
  # creates and returns the DbFieldDescription for the record_id column.
  #
  # Parameters:
  # * data_table - the name for the data table (e.g. 'phr_notes')
  # * description - a short description that can appear in a list
  def self.create_multi_rec_table(data_table, description)
    db_t = create!(:data_table=>data_table, :description=>description)
    db_rec_id = db_t.add_record_id_field
    return db_t, db_rec_id
  end


  # Issues the SQL command to create in the database the table described by this
  # DbTableDescription.
  def create_db_table
    # Note-- this implementation here is not complete.  We can just add what
    # we need as we come across the different cases.
    # Current use cases:
    # Migration 1316_add_notes.rb (number may change)
    has_record_id = !db_field_descriptions.where(data_column: 'record_id').empty?
    ActiveRecord::Migration.create_table data_table do |t|
      t.column :profile_id, :integer
      t.column :record_id, :integer if has_record_id
      t.column :latest, :boolean
      db_field_descriptions.each do |db_fd|
        if db_fd.data_column != 'record_id'
          opts = {}
          opts[:limit] = db_fd.data_size if db_fd.data_size
          case db_fd.field_type
          when 'ST - string data'
            t.column db_fd.data_column, :string, opts
          when 'Integer'
            # For integers, the data_size refers to the base-ten stringth length
            # because (I think) it gets used to limit size of form field input
            # Currently, if there is a limit, it is 20, and in that case
            # the database limit is 8.  Also, it seems that even if we specify
            # a limit of 8 here, the resulting database type is BIGINT(20).
            opts[:limit] = 8 if opts[:limit] == 20
            t.column db_fd.data_column, :integer, opts
          else
            raise "create_db_table does not yet support field_type #{db_fd.field_type}"
          end
        end
      end
      t.column :version_date, :datetime
      t.column :deleted_at, :datetime, :default=>nil
    end
  end


  # Creates and returns a DbFieldDescription (and associates it with this
  # DbTableDescription) for a field that stores string data.
  #
  # Parameters:
  # * data_column - the value for the data_column field (the column name in the
  #   table)
  # * display_name - a display name for this field
  # * field_vals - a hash of other, optional field values for the
  #   DbFieldDescription record.
  def add_string_field(data_column, display_name, field_vals={})
    attrs = {"required"=>false, :data_column=>data_column,
      "virtual"=>false, "is_major_item"=>false, :display_name=>display_name,
      "max_responses"=>0, "item_table_has_unique_codes"=>false,
      "html_parse_level"=>0, "db_table_description_id"=>self.id,
      "omit_from_field_lists"=>true, "display_name"=>"Description/Comment",
      "predefined_field_id"=>1, "field_type"=>"ST - string data"
    }.merge!(field_vals)
    dbf = DbFieldDescription.create!(attrs)
    self.db_field_descriptions << dbf
    dbf.save!
    return dbf
  end


  # Creates and returns a DbFieldDescription (and associates it with this
  # DbTableDescription) for a field that stores integer data.
  #
  # Parameters:
  # * data_column - the value for the data_column field (the column name in the
  #   table)
  # * display_name - a display name for this field
  # * field_vals - a hash of other, optional field values for the
  #   DbFieldDescription record.
  def add_integer_field(data_column, display_name, field_vals={})
    attrs = {:data_column=>data_column, :display_name=>display_name,
      "data_column"=>"test_date_ET", "data_size"=>20, "max_responses"=>0,
      "html_parse_level"=>0, "db_table_description_id"=>self.id,
      "field_type"=>"Integer", "predefined_field_id"=>39
    }.merge!(field_vals)
    dbf = DbFieldDescription.create!(attrs)
    self.db_field_descriptions << dbf
    dbf.save!
    return dbf
  end


  # Creates the three needed DbFieldDescriptions for a date field (and
  # associates them with this DbTableDescription.
  #
  # Parameters:
  # * data_column - the value for the data_column field (the column name in the
  #   table)
  # * display_name - a display name for this field
  # * field_vals - a hash of other, optional field values for the
  #   DbFieldDescription record.
  #
  # Returns:  A DbFieldDescription for the user-readable date field,
  # a DbFieldDescription for the epoch-time field, and a DbFieldDescription
  # for the HL7 version of the date field.
  def add_date_field(data_column, display_name, field_vals={})
    user_field = add_string_field(data_column, display_name, field_vals)
    et_field = add_integer_field(data_column+'_ET', display_name + ' (ET)',
      field_vals.merge({:data_size=>8}))
    hl7_field = add_string_field(data_column+'_HL7', display_name+' (HL7)',
      field_vals)
    return [user_field, et_field, hl7_field]
  end


  # Creates and returns a record_id field for this DbTableDescription.
  # record_id fields are only needed for tables that can have more than one
  # record per profile (which is most tables).
  def add_record_id_field
    dbf = DbFieldDescription.create!("data_size"=>20, "data_column"=>"record_id",
      "virtual"=>false, "is_major_item"=>false, "max_responses"=>0,
      "item_table_has_unique_codes"=>false, "html_parse_level"=>0,
      "omit_from_field_lists"=>true, "display_name"=>"record id",
      "predefined_field_id"=>39, "field_type"=>"Integer",
      :db_table_description_id=>self.id)
    self.db_field_descriptions << dbf
    return dbf
  end


  # Creates and returns a DbFieldDescription (and associates it with this
  # DbTableDescription) for a field that has a list from the text_lists table
  # and which does not have a list or a controlling field.
  #
  # Parameters:
  # * data_column - the value for the data_column field (the column name in the
  #   table)
  # * display_name - a display name for this field
  # * list_identifier - the list_name of the from the text_lists record for
  #   this list.
  # * field_vals - a hash of other, optional field values for the
  #   DbFieldDescription record.
  def add_text_list_field(data_column, display_name, list_identifier,
                         field_vals={})
    list_field_vals = {"list_master_table"=>"text_lists",
      "current_item_for_field"=>"get_list_items", "match_list_value"=>false,
      "item_master_table"=>"text_list_items",
      "fields_saved"=>['item_text'], :list_identifier=>list_identifier,
      "list_code_column"=>"code"}.merge(field_vals)

    add_string_field(data_column, display_name, list_field_vals)
  end


  # DEPRECATED.  CHANGED TO get_major_field_names when fetch rule form
  #              redesigned.  Remove this when old edit_phr_fetch_rule
  #              form removed.
  # Returns the list of non-date major_item fields for the current table.  The
  # return values will be instances of db_field_descriptions.
  #
  # Parameters:  none
  # Returns:  the db_field_description objects for fields flagged as major
  #           items for the current table.
  #
  def get_major_item_id_field_names
    return get_major_field_names
  end # get_major_item_id_field_names


  # Returns the list of major_item fields for the current table.  The
  # return values will be instances of db_field_descriptions.
  #
  # Parameters:  none
  # Returns:  the db_field_description objects for fields flagged as major
  #           items for the current table.
  #
  def get_major_field_names
    conditions = 'AND is_major_item is true'
    return db_field_descriptions[0].get_field_display_names(id, conditions)
  end # get_major_field_names


  #
  # DEPRECATED.  CHANGED TO get_other_field_names when fetch rule form
  #              redesigned.  Remove this when old edit_phr_fetch_rule
  #              form removed.
  # Returns the list of non-date fields for the current table that are not
  # flagged as major items AND are not dependent on a specific major item.
  # The return values will be instances of db_field_descriptions.
  #
  # Parameters:  none
  # Returns:  the db_field_description objects for fields NOT flagged as major
  #           items for the current table.
  #
  def get_dependent_item_field_names
    return get_other_field_names
  end # get_dependent_item_field_names


  # Returns the list of fields for the current table that are not
  # flagged as major items AND are not dependent on a specific major item.
  # The return values will be instances of db_field_descriptions.
  #
  # Parameters:  none
  # Returns:  the db_field_description objects for fields NOT flagged as major
  #           items for the current table.
  #
  def get_other_field_names
    conditions = "AND is_major_item is false AND major_item_ids is null"
    return db_field_descriptions[0].get_field_display_names(id, conditions)
  end # get_dependent_item_field_names


  # DEPRECATED.  Date and non-date fields now in same section.  Remove
  #              when when old edit_phr_fetch_rule form is removed.
  # Returns the list of date fields for the current table.  The return values
  # will be instances of db_field_descriptions.
  #
  # Parameters:  none
  # Returns:  the db_field_description objects for date fields for the current
  #           table.
  #
  def get_date_field_names
    return db_field_descriptions[0].get_date_field_display_names(id)
  end # get_date_field_names


end # db_table_description
