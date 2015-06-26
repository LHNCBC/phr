require File.expand_path("../serverside_validation/db_field_validation_methods", __FILE__)

class ServersideValidation

  # Loads server side db field validations
  # 
  # Parameters:
  # * validation_params_list list of validation_params. Each validation_params
  # has three elements as follows:
  #  [ validation type, validation options/parameters, validation_fields]
  def self.load_validations(validation_params_list=nil)
    if validation_params_list
      DbFieldDescription.update_all(:validation_opts => nil)
      validation_params_list.each do |e|
        save_validation_definitions(e)
      end
    end

    DbTableDescription.current_data_tables.each do |t|
        table_class = t.data_table.classify.constantize
        table_class.send(:belongs_to, :profile)
        table_class.send(:include, DbFieldValidationMethods)
        table_class.send(:load_data_field_validation)
    end
  end

  # Saves definitions of server side db field validations into
  # db_field_descriptions table
  #
  # Parameters:
  # * validation_params an array consists of three elements where first one is a
  # validation type, second one is a validation options/parameters and third
  # one specifies the fields need to be validated
  def self.save_validation_definitions(validation_params)
    v_type, v_opts, table_field_map = validation_params
    table_field_map.each do |table, fields|
      db_table = DbTableDescription.where(data_table: table).first
      db_table.db_field_descriptions.where(data_column: fields).each do |e|
        rtn = e.validation_opts || {}
        rtn[v_type] = v_opts
        e.validation_opts = rtn
        e.save!
      end
    end
  end

  # Returns validation definitions categorized by data_table/data_field and
  # validation type
  def self.show_validation_definitions
    cat_by_db_table = {}
    cat_by_v_type = {}
    DbTableDescription.current_data_tables.each do |t|
      cat_by_db_field = {}
      t.db_field_descriptions.each do |f|
        if f.validation_opts
          # categorized by data field/data table
          cat_by_db_field[f.data_column] = f.validation_opts
          # categorized by validation type
          f.validation_opts.each do |k, v|
            cat_by_v_type[k] ||= []
            cat_by_v_type[k] << [t.data_table, f.data_column, v]
          end
        end
      end
      cat_by_db_table[t.data_table] = cat_by_db_field
    end
    [cat_by_db_table, cat_by_v_type]
  end
end
