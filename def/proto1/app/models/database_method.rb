#
# A module that handles difference of Oracle and MySQL for certain
# database-specific functions.
#
module DatabaseMethod

  # To handle differenct REGEXP functions for different database types
  # Default: mysql
  #
  # Parameters
  # * strColumnName, is a table column name or an expression
  # * strPattern, is the pattern to be matched
  #
  # Returns
  # * a REGEXP string
  def self.createRegexpFuncStr(strColumnName, strPattern)
    if self.isMySQL
      strReturn ="(" + strColumnName + " REGEXP " + strPattern +")"
    elsif self.isOracle
      strReturn ="(REGEXP_INSTR(" + strColumnName + "," + strPattern + ") > 0)"
    else
      logger.debug "Database type unknown. Only MySQL and Oracle are supported." +
          " Please check config/database.yml."
      logger.debug "MySQL style REGEXP functions are used."
      strReturn ="(" + strColumnName + " REGEXP " + strPattern +")"
    end
  end

  # get database config content
  def self.getConfig()
    if !defined? @@db_config
      dbfile = File.dirname(__FILE__) + '/../../config/database.yml'
      @@db_config = YAML.load(ERB.new(File.read(dbfile)).result)
    end
    return @@db_config
  end

  # Get database adapter name in uppercase, based on mode
  #
  # Parameters
  # * strMode - Rails environment mode, optional. Defalut value is 'development'
  #
  # Returns
  # * 'MYSQL' or 'ORACLE'
  def self.getAdapterName(strMode=Rails.env)
    if strMode.nil?
      strMode ="development"
    end
    db_adapter = self.getConfig[strMode]['adapter']
    return db_adapter.upcase
  end

  # check if it is Oracle database, otherwise it is MySQL
  def self.isOracle(strMode=Rails.env)
    adapter_name = self.getAdapterName(strMode)
    return adapter_name ==  'ORACLE' || adapter_name == 'ORACLE_ENHANCED'

  end

  # check if it is MySQL database, otherwise it is Oracle
  def self.isMySQL(strMode=Rails.env)
    return self.getAdapterName(strMode) ==  'MYSQL' ||
     self.getAdapterName(strMode) ==  'MYSQL2'
  end

  # Get database name, for Oracle, it is from 'username'
  #
  # Parameters
  # * strMode - Rails environment mode, optional. Default value is 'development'
  def self.getDatabaseName(strMode=Rails.env)
    if strMode.nil?
      strMode ="development"
    end
    if self.isOracle(strMode)
      db_name = self.getConfig[strMode]['username']
    else
      db_name = self.getConfig[strMode]['database']
    end
    return db_name
  end

  # Get database user name
  #
  # Parameters
  # * strMode - Rails environment mode, optional. Defalut value is 'development'
  def self.getUserName(strMode=Rails.env)
    if strMode.nil?
      strMode ="development"
    end
    db_user = self.getConfig[strMode]['username']
    return db_user
  end

  # Get database host name
  #
  # Parameters
  # * strMode - Rails environment mode, optional. Defalut value is 'development'
  #
  # Returns
  # * TNS name for Oracle, host name for MySQL
  def self.getHost(strMode=Rails.env)
    if strMode.nil?
      strMode ="development"
    end
    if self.isOracle(strMode)
      db_host = self.getConfig[strMode]['database']
    else
      db_host = self.getConfig[strMode]['host']
    end
    return db_host
  end

  # Get database user password
  #
  # Parameters
  # * strMode - Rails environment mode, optional. Default value is 'development'
  def self.getPassword(strMode=Rails.env)
    if strMode.nil?
      strMode ="development"
    end
    db_pwd = self.getConfig[strMode]['password']
    return db_pwd
  end

  # Oracle system table user_tab_columns contains the information of all
  # columns under a user's schema.
  # This model class is created so that we can easily access to this table
  # and check if a 'ID' column exsits in a user's table. If a table has a 'ID'
  # column, a sequence for this 'ID' needs to be updated.
  # This class is solely used by class method updateSequence below
  class UserTabColumn < ActiveRecord::Base
  end

  # update sequece number according the exisitng record number
  # For use with Test Fixture only in test file.
  #
  # When fixture is loaded into a table in Oracle, the related sequence
  # is not updated automatically.
  # Usually, in the fixtures we set the 'id' to 1, 2, etc.
  # Then if a new record is created, the 'id' value is calculated from
  # the sequence, which still has its initial value --1.
  # This causes a "unique constraint ... violated" error
  # on the primary key (the 'id' column)
  # Use a big number, i.e. 1000, on 'id' might avoid this problem.
  #
  # Each test class that BOTH loads fixture data AND create/add new record
  # using codes should include the following codes!
  #
  #   # Correct sequence problem on Oracle when fixures are used
  #   def initialize(test_method_name)
  #     super(test_method_name)
  #     #table_names = [:rules, :rule_actions, :field_descriptions, :forms]
  #     table_names = [:table1, :table2, :tbale3  ]
  #     DatabaseMethod.updateSequence(table_names)
  #   end
  #--
  # Update:
  # Class method fixtures in Test::Unit::TestCase has been extended so that
  # a sequence will be automatically updated whenever a fixutres is used
  # see config/oracle_adapter_extension.rb
  # So the above methods is not necessary any more.
  # Comments are kept here for reference
  #++
  # Parameters
  # * tables_names -- an array of tables name which has sequence
  #                  note: some table does not have sequence, such as
  #                  rule_dependencies, rules_forms
  #
  def self.updateSequence(table_names)
    if self.isOracle # && Rails.env == 'test'
      dbconn = ActiveRecord::Base.connection
      # for each afftected table
      table_names.each do |table_name|
        table_name = table_name.to_s
        # Some joint tables have no model classed defined.
        # These tables should not have a 'ID' column, nor a sequence
        begin
          # constantize fails if no model class exists
          tableClass = table_name.singularize.camelcase.constantize
          # get record number in the table ( created from fixture)
          # if column ID exist
          ## query column name on Oracle database
          ## "select column_name from user_tab_columns where table_name ='#{table_name.upcase}' and column_name = 'ID'"
          id_column = UserTabColumn.where(
            "table_name = ? and column_name = 'ID'", table_name.upcase).take
          if id_column
            count = tableClass.maximum('id')
            count = 0 unless !count.nil?
            # get sequence name
            sequence_name = table_name + '_seq'
            new_start = count + 1
            # recreate the sequence
            #puts "creating sequence #{sequence_name} with #{new_start}"
            dbconn.execute "drop sequence #{sequence_name}"
            dbconn.execute "CREATE SEQUENCE #{sequence_name} START WITH #{new_start} NOCACHE ORDER"
          end
        rescue NameError # rescue no model class error only
          puts "Info: no model class for: " + table_name
        end
      end
    end
  end

  # Reloads the database from the given MySQL database dump file.
  # data_file, dump file that contains DROP TABLE, CREATE TABLE, LOCK TABLES,
  # INSERT and UNLOCK TABLES and etc SQL statement. It does not include DROP
  # or CREATE database statement.
  #
  # It now supports Oracle database. It converts a MySQL dump file into
  # several Oracle SQLPlus files to drop existing objects(tables, indexes and
  # sequences), recreate them, and create a control file and a data file for
  # Oracle SQL Loader to load the data into Oracle database.
  #
  # The destiniation database type/schema/account/password is determinined by
  # the database.yml file in use.
  #
  # Parameters
  # * data_file - database dump file
  # * strMode - Rails environment mode, optional. Defalut value is 'development'
  # * pk_sn - starting sequence number used in primary key names
  #
  # Examples to create dump file of all (or some) tables in one database
  # 1) MySQL:
  #   mysqldump -h <db_host> -u <db_user> -p <db_name> [tables] > data_file.sql
  #   mysqldump -h <db_host> -u <db_user> -p<db_pwd> <db_name> [tables] > data_file.sql
  # 2) Oracle:
  #   N/A
  #
  # Examples to restore dump files
  # 1) MySQL:
  #   mysql -h <db_host> -u <db_user> -p <db_name> < data_file.sql
  #   mysql -h <db_host> -u <db_user> -p<db_pwd> <db_name> < data_file.sql
  # 2) Oracle:
  #   see sqlldr man page
  #
  def self.reloadDatabase(data_file, strMode=Rails.env, pk_sn=1)
    if strMode.nil?
      strMode ="development"
    end
    # check the mysql script file
    if !File.exist?(data_file)
      logger.debug "Error: MySQL dump file #{data_file} does not exist."
      return false
    end
    db_name = self.getDatabaseName(strMode)
    db_user = self.getUserName(strMode)
    db_pwd = self.getPassword(strMode)
    db_host = self.getHost(strMode)
    #
    # Here is the assumption/requirement: --for MySQL only
    # 1. Current user's linux account name is same as his/her mysql account name
    # 2. The mysql password is stored in .my.cnf at hie/her home directory.
    #    We are not supply password on command line for security reasons.
    #    (see http://dev.mysql.com/doc/refman/5.0/en/password-security.html)
    #    Instead mysql reads the password from .my.cnf file.
    #
    # In the latest MySQL version, passwd in the following command is hidden
    # shown as "****" in the output of ps command
    #
    if self.isMySQL
      #
      # Receate database not necessary
      #
      # ActiveRecord::Migration.execute('drop database ' + db_name)
      # ActiveRecord::Migration.execute('create database ' + db_name)
      #
      # Make sure mysql and sqlplus is installed and in the PATH
      #
      # Edit the password to escape special characters (before handing it to
      # the shell).  Create a new string so we don't change the string that
      # was passed in.
      cmd = 'mysql -h ' + db_host + ' -u ' + db_user +
            ' ' + db_name + ' < ' + data_file
      system(cmd)
    elsif self.isOracle
      self.migrateFromMySQL2Oracle(data_file,db_user,db_pwd,db_host,false,pk_sn)
    else
      #
      # should raise error message too
      #
      logger.debug 'Unknown database type. Please check config/database.yml'
    end

    # Reconnect to the database so that the schema version can be updated
    ActiveRecord::Base.establish_connection(strMode)

  end

  #
  # Load a MySQL dump file into an existing Oracle schema
  #
  # Not supposed to be used directly
  #
  def self.migrateFromMySQL2Oracle(mysql_dump_file, ora_uid, ora_password,
      ora_tns, keep_file=false, pk_sn=1)
    file_location = 'tmp/dbmigrate'
    # create destination directory
    file_dir = File.dirname(__FILE__) + '/../../' + file_location + '/'
    if (!File.exists?(file_dir))
      Dir.mkdir(file_dir)
    end
    # go to the file location
    Dir.chdir(file_dir)

    # sqlldr options, fixed. not necessary in dbmigrate.yml
    sqlldr_options = 'DIRECT=TRUE COLUMNARRAYROWS=1000 ERRORS=1000'

    # Convert the MySQL dump scripts to be Oracel-specific scripts
    schema_script, alter_script, control_file, data_file, log_file, bad_file,
        err_file, drop_script =
        self.convert_script(mysql_dump_file,file_dir, pk_sn)

    # delete existing objects
    cmd = "sqlplus #{ora_uid}/#{ora_password}@#{ora_tns} @#{drop_script}"
    system(cmd)

    # rereated tables, sequence and indexes
    cmd = "sqlplus #{ora_uid}/#{ora_password}@#{ora_tns} @#{schema_script}"
    system(cmd)

    # Load the data by executing SQL Loader with control_file and data_file
    # with options:
    # DIRECT=TRUE           : reduce execution time from 44m to 40s.
    #                         need to rebuild index after data is loaded.
    # COLUMNARRAYROWS=1000  : reduce memory requirement. default: 5000
    cmd = "sqlldr #{ora_uid}/#{ora_password}@#{ora_tns} control=#{control_file} log=#{log_file} #{sqlldr_options}"
    system(cmd)
    # Example
    # sqlldr test/p#8080@phrdev control=sqlldr_control_20080910115936.ctl log=sqlldr_log.log DIRECT=TRUE COLUMNARRAYROWS=1000 > sqlldr.out

    # rebuild index
    cmd = "sqlplus #{ora_uid}/#{ora_password}@#{ora_tns} @#{alter_script}"
    system(cmd)

    # change file permissions to 700 or remove these files
    if keep_file
      File.chmod(0700, schema_script)
      File.chmod(0700, alter_script)
      File.chmod(0700, control_file)
      File.chmod(0700, data_file)
      File.chmod(0700, drop_script)
    else
      File.delete(schema_script)
      File.delete(alter_script)
      File.delete(control_file)
      File.delete(data_file)
      File.delete(drop_script)
    end

  end

  # load the entire schema on MySQL or Oracle from dump file of the same
  #   database type
  # * data_file - the name of the dump file.
  #       for mysql it's a file stored on the local machine,
  #       for oracle, it's a file stored on the oracle db server machine
  #          at the location defined by a DIRECTORY
  # * directory - for Oracle, a DIRECTORY variable defined in database system
  #               default is 'DEVEL_DIR'
  #               for mysql, the path where the dump file is located
  # * src_schema - Oracle only. the source schema that the dump file was
  #            created from.
  def self.load_database(data_file, directory=nil, src_schema=nil,
                         str_mode=Rails.env)
    if str_mode.nil?
      str_mode ="development"
    end
    db_name = self.getDatabaseName(str_mode)
    db_user = self.getUserName(str_mode)
    db_pwd = self.getPassword(str_mode)
    db_host = self.getHost(str_mode)
    if self.isMySQL
      if directory.nil?
        directory = File.dirname(__FILE__) + '/../../tmp'
      end
      # check the mysql script file
      if !File.exist?(directory + "/" + data_file)
        raise "Error: MySQL dump file #{directory}/#{data_file} does not exist."
        return false
      end
      self.load_db('mysql', db_host, db_user, db_pwd, data_file, directory,
        db_name, nil)
    else
      directory = 'DEVEL_DIR' if directory.nil?
      src_schema = db_user if src_schema.nil?
      self.load_db('oracle', db_host, db_user, db_pwd, data_file, directory,
        db_name, src_schema)

    end
  end

  # dump the entire schema on MySQL or Oracle, or selected tables
  # Parameters
  # * data_file - the name of the dump file.
  #       for mysql it's a file stored on the local machine,
  #       for oracle, it's a fiel stored on the oracle db server machine
  #          at the location defined by a DIRECTORY
  # * directory - for Oracle, a DIRECTORY variable defined in database system
  #               default is 'DEVEL_DIR'
  #               for mysql, the path where the dump file is located
  # * tables - an array of table names (or nil if all of them should be dumped)
  # * strMode - The environment name (used to select the database from the
  #   database.yml file).
  # * schema_only_tables - tables (within the "tables" parameter) for which
  #   only the schema should be dumped, and not the data.
  def self.dump_database(data_file, directory=nil, tables=nil,
                         str_mode=Rails.env, schema_only_tables=[])

    if str_mode.nil?
      str_mode ="development"
    end
    db_name = self.getDatabaseName(str_mode)
    db_user = self.getUserName(str_mode)
    db_pwd = self.getPassword(str_mode)
    db_host = self.getHost(str_mode)
    if self.isMySQL
      directory = File.dirname(__FILE__) + '/../../tmp' if directory.nil?
      self.dump_db('mysql', db_host, db_user, nil, data_file, directory,
                   db_name, tables, schema_only_tables)
    else
      directory = 'DEVEL_DIR' if directory.nil?
      self.dump_db('oracle', db_host, db_user, db_pwd, data_file, directory,
                   db_name, tables)
    end
  end


  # dump data from (some tables of) a database to a file
  # Parameters
  # * db_type - oracle or mysql
  # * db_host - database server, a tnsname for oracle, hostname for mysql
  # * db_user - user account on database server
  # * db_pwd - user's password (may be nil, in which case no password will be specified)
  # * data_file - the name of the dump file.
  #       for mysql it's a file stored on the local machine,
  #       for oracle, it's a fiel stored on oracle db server machine
  #          at the location defined by a DIRECTORY
  # * directory - for Oracle, a DIRECTORY variable defined in database system
  #               default is 'DEVEL_DIR'
  #               for mysql, the path where the dump file is located
  # * schema - the shema (in oracle) or database (in mysql) to be dumped
  # * tables - Optional, an array of the table names within the schema to be dumped
  #            nil means dump the entire schema
  # * schema_only_tables - tables (within the "tables" parameter) for which
  #            only the schema should be dumped, and not the data.
  # * separate_lines_output - flag indicating whether or not to use a separate
  #                           insert statement for each row, and therefore to
  #                           list each row to be used separately.  Used for
  #                           the data dumps produced for the GitHub version of
  #                           the system, to make cleaning the data more
  #                           intelligible.  Default is false.
  def self.dump_db(db_type, db_host, db_user, db_pwd, data_file, directory,
      schema, tables=nil, schema_only_tables=[], separate_lines_output=false)

    if db_type == 'mysql'
      command = 'mysqldump --lock-tables --skip-triggers '
      # Edit the password to escape special characters (before handing it to
      # the shell).  Create a new string so we don't change the string that
      # was passed in.
      if !db_pwd.nil?
        db_pwd = db_pwd.gsub(/([$`'"\\\(\)>< ])/, '\\\\\\1') # escape $`'"\()>< and space
      end
      parameters = ' -h ' + db_host + ' -u ' + db_user
      parameters += ' -p' + db_pwd if !db_pwd.nil?
      if separate_lines_output
        parameters += ' --extended-insert=FALSE --complete-insert=TRUE '
      end
      parameters += ' ' + schema
      if tables
        tables = tables - schema_only_tables
      else
        tables = ActiveRecord::Base.connection.tables - schema_only_tables
      end
      file_path = File.join(directory, data_file)
      FileUtils.rm(file_path) if File.exists?(file_path)
      file_redir = ' >> ' + file_path
      if !schema_only_tables.blank?
        # Just output the schema for these tables
        so_cmd = command + parameters + ' --no-data ' + schema_only_tables.join(' ') +
           file_redir
        system(so_cmd) || raise('mysqldump of schema tables failed')
      end
      parameters += ' ' + tables.join(' ') + file_redir
      system(command + parameters) || raise('mysqldump failed')
    elsif db_type == 'oracle'
      # for Oracle, db_user == schema, in our setup
      command = 'expdp'
      time_now = Time.now.strftime('%Y%m%d%H%M%S')
      log_file = 'expdp_' + time_now +'.log'
      parameters = '  ' + db_user + '/' + db_pwd + '@' + db_host +
          ' DIRECTORY=' + directory +
          ' LOGFILE=' + log_file +
          ' DUMPFILE=' + data_file +
          ' SCHEMAS=' + schema  +
          ' REUSE_DUMPFILES=y'
      if !tables.nil?
        table_array =[]
        sequence_array = []
        tables.each do | table_name|
          table_array << "\\'" + table_name.upcase + "\\'"
          sequence_array << "\\'" + table_name.upcase + "_SEQ" + "\\'"
        end
        table_list = table_array.join(",")
        sequence_list = sequence_array.join(",")
        parameters += ' INCLUDE=TABLES:\\"IN \\(' + table_list + '\\)'
        parameters += ' INCLUDE=SEQUENCE:\\"IN \\(' + sequence_list + '\\)'
      end
      system(command + parameters)

    else
      raise 'Unknown databse type, dump_db aborted'
    end
  end

  # load data from a dump file to a database
  # Parameters
  # * db_type - oracle or mysql
  # * db_host - database server, a tnsname for oracle, hostname for mysql
  # * db_user - user account on database server
  # * db_pwd - user's password
  # * data_file - the name of the dump file.
  #       for mysql it's a file stored on the local machine,
  #       for oracle, it's a fiel stored on oracle db server machine
  #          at the location defined by a DIRECTORY
  # * direcotry - for Oracle, a DIRECTORY varaible defined in database system
  #               default is 'DEVEL_DIR'
  #               for mysql, the path where the dump file is located
  # * schema - the shema (in oracle) or database (in mysql) where the data is
  #            to be loaded
  # * src_schema - Oracle only. the source shema where the dump file was
  #            created from.
  # * tables - Optional, an array of the table names within the schema to be dumped
  #            nil means dump the entire schema
  def self.load_db(db_type, db_host, db_user, db_pwd, data_file, directory,
      schema, src_schema, tables=nil)
    if db_type == 'mysql'
      command = 'mysql'
      parameters = ' -h ' + db_host + ' -u ' + db_user + ' -p' + db_pwd + ' ' + schema
      parameters += ' < ' + directory + '/'+ data_file
      system(command + parameters)

    elsif db_type == 'oracle'
      # for Oracle, db_user is the new schema, schema is the old one
      command = 'impdp'
      time_now = Time.now.strftime('%Y%m%d%H%M%S')
      log_file = 'impdp_' + time_now +'.log'
      parameters = '  ' + db_user + '/' + db_pwd + '@' + db_host +
          ' DIRECTORY=' + directory +
          ' LOGFILE=' + log_file +
          ' DUMPFILE=' + data_file +
          ' TABLE_EXISTS_ACTION=REPLACE' +   # only replace tables, not sequences
      ' REMAP_SCHEMA=' + src_schema + ':' + schema
      system(command + parameters)
      # call updateSequence since sequence is not replaced by impdp
      # it may cause the seqeunce number different from the dump file
      # another way is to drop sequences before load the dump file, but how do
      # we know which tables are included in the dump file, so that their
      # sequences need to be dropped?
      table_names = ActiveRecord::Base.connection.tables
      self.updateSequence(table_names)
    else
      raise 'Unknown databse type, load_db aborted'
    end
  end

  # Recreate database
  # for MySQL only
  #
  # Parameters
  # * strMode - Rails environment mode, optional. Defalut value is 'development'
  def self.reCreateDatabase(strMode=Rails.env)
    if strMode.nil?
      strMode ="development"
    end
    db_name = self.getDatabaseName(strMode)
    db_user = self.getUserName(strMode)
    db_pwd = self.getPassword(strMode)
    db_host = self.getHost(strMode)
    if self.isMySQL
      #
      # Receate database not necessary
      #
      ActiveRecord::Migration.execute('drop database ' + db_name)
      ActiveRecord::Migration.execute('create database ' + db_name)

      # Reconnect to the database so that the schema version can be updated
      ActiveRecord::Base.establish_connection(strMode)

    end
  end


  # Returns a list of column names for the given table.  The returned list
  # of strings will be quoted as necessary if Oracle is being used.  (This
  # method is also useful for MySQL for cases in which data is being copied
  # between two tables that have the same columns but in a different order.)
  #
  # Parameters:
  # * table_name - the name of the table whose columns are needed
  def self.get_quoted_table_col_names(table_name)
    cols = []

    # Note that (e.g. for join tables) we cannot assume the table class exists.
    oracle = DatabaseMethod.isOracle
    ActiveRecord::Base.connection.columns(table_name).each do |c|
      col_name = c.name
      if oracle and DatabaseMethod.has_uppercase_code(col_name)
        cols << '"' + col_name + '"'
      else
        cols << col_name
      end
    end

    return cols
  end


  # Returns the list of table names that are not safe to copy into the
  # production database during an update, e.g. because they
  # have user data in them.
  def self.get_uncopiable_tables
    uncopiable_tables = Set.new(%w(locks users profiles_users deleted_profiles
      open_id_auth_associations open_id_auth_nonces schema_migrations sessions
      user_preferences question_answers two_factors userid_guess_trials profiles
      autosave_tmps system_errors audits page_load_times latest_obx_records
      usage_stats research_data versions auto_increments share_invitations
      date_reminders health_reminders reviewed_reminders email_verifications
      data_edits
    ))

    DbTableDescription.all.each {|m| uncopiable_tables << m.data_table}
    DbTableDescription.current_hist_table_names.each {|t| uncopiable_tables << t}
    return uncopiable_tables
  end


  # Returns the list of uncopiable tables that currently exist in the
  # database.  The list returned from get_uncopiable_tables includes tables
  # named in the db_table_descriptions table that don't always exist in the
  # database.  Using that list in the data dumps causes them to crash, so
  # we clean that list here.
  def self.get_existing_uncopiable_tables
    tlist = self.get_uncopiable_tables
    elist = ActiveRecord::Base.connection.tables
    tlist = tlist.reject {|t| !elist.member?(t)}
  end

  
  # Returns the list of table names that are safe to copy into the
  # production database during an update.
  def self.get_copiable_tables
    uncopiable_tables = self.get_uncopiable_tables
    tables_to_copy =
      ActiveRecord::Migration.tables.reject{|t| uncopiable_tables.member?(t)}
    return tables_to_copy
  end


  # Copies tables from one database environment to another.  After this is
  # called the database connection will be with the "to_env" database.
  #
  # Parameters:
  # * from_env - the environment name from database.yml that specifies
  #   how to connect to the database from which the data will be read
  # * to_env the environment name from database.yml that specifies
  #   how to connect to the database into which the data will be written
  # * table_names - the list of tables to be copied.  There must be
  #   model classes defined for these tables.
  # * copy_index - whether the Ferret search index should be copied as well
  #   as the data.
  # * conditions - (optional) a hash from table name to a condition string
  #   to add to the select
  #
  # Note: This function only works on the same kind of database. It can not
  #       copy tables between MySQL and Oracle.
  def self.copy_tables(from_env, to_env, table_names, copy_index = true,
      conditions={})
    start = Time.now.to_f
    table_names = [table_names] if table_names.class != Array
    tables = table_names.join(',')
    puts 'Copying tables:  ' + tables
    verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false

    # Don't change databases unless necessary.  It causes a rollback
    # of any open transaction (e.g. in the test code).
    from_db = DatabaseMethod.getDatabaseName(from_env)
    to_db = DatabaseMethod.getDatabaseName(to_env)
    if to_db != ActiveRecord::Base.connection.current_database
      ActiveRecord::Base.establish_connection(to_env)
    end


    tables_with_sequences = []
    to_env_tables = Set.new
    ActiveRecord::Migration.tables.each {|t| to_env_tables << t}

    table_names.each do |copy_t|
      # Skip tables that do not exist in the target database
      if (to_env_tables.member?(copy_t))
        # The class might or might not have a model class (e.g. join tables)
        # so don't try to use ActiveRecord.
        ActiveRecord::Migration.execute("delete from #{copy_t}")

        # Get the list of column names for table t.  We can't just use
        # "insert into #{t} select * ..." because in at least one case,
        # the order of columns is different between the development and test
        # systems.  (Not necessary, but that's the way it is.)
        column_names = self.get_quoted_table_col_names(copy_t)
        col_name_str = column_names.join(',')
        table_cond = conditions[copy_t]
        table_cond = "where #{table_cond}" if table_cond
        ActiveRecord::Migration.execute(
          "insert into #{copy_t} (#{col_name_str}) "+
          "select #{col_name_str} from #{from_db}.#{copy_t} #{table_cond}")

        # Copy the ferret index for the table, if it exists
        if copy_index
          # See if the table class exists
          table_cls = nil
          begin
            table_cls = copy_t.singularize.camelize.constantize
          rescue # just continue -- it means the class isn't defined
          end
          if table_cls and table_cls.respond_to?('disable_ferret')
            self.copy_ferret_index(from_env, to_env, copy_t)
          end
        end

        if column_names.member?('id')
          tables_with_sequences << copy_t
        end
      end
    end

    # Update sequence on Oracle
    DatabaseMethod.updateSequence(tables_with_sequences)

    ActiveRecord::Migration.verbose = verbose
    puts "Copied tables in #{Time.now.to_f - start} seconds."
  end


  # Copies development data tables to the test database, and takes care
  # of updating sequencies on IDs where applicable.  This changes the
  # connection to the test database.
  #
  # Parameters:
  # * table_names - the list of tables to be copied.  There must be
  #   model classes defined for these tables, or no copy will take place
  #   (for the tables without them).
  # * copy_index - whether the Ferret search index should be copied as well
  #   as the data.
  # * conditions - (optional) a hash from table name to a condition string
  #   to add to the select
  def self.copy_development_tables_to_test(table_names, copy_index = true,
      conditions={})
    self.copy_tables('development', 'test', table_names, copy_index, conditions)
  end


  # Returns the path of the ferret index for the given database environment
  # and index name.
  #
  # Parameters:
  # * db_env - the environment name from database.yml
  # * index_name - the name of the index (its directory name)
  def self.get_ferret_index_path(db_env, index_name)
    base_index_path = self.getConfig[db_env]['ferret_index']
    if base_index_path
      index_path = File.join(base_index_path, index_name)
    else
      index_path = File.join(Rails.root, 'index', db_env, index_name)
    end
    return index_path
  end


  # Copies a ferret index from one database environment to another.
  # This method does not do anything to disable ferret before the copy.
  #
  # Parameters:
  # * from_env - the environment name from database.yml that specifies
  #   how to connect to the database whose index will be read
  # * to_env the environment name from database.yml that specifies
  #   how to connect to the database whose index will be overwritten
  # * table_name - the name of the table to be copied
  def self.copy_ferret_index(from_env, to_env, table_name)
    # Copy the ferret index
    index_dir_name = table_name.singularize
    from_index = self.get_ferret_index_path(from_env, index_dir_name)
    to_index = self.get_ferret_index_path(to_env, index_dir_name)
    if (File.exists?(to_index))
      FileUtils.rm_rf(to_index)
    end
    to_index_containing_dir = File.dirname(to_index)
    if !File.exists?(to_index_containing_dir)
      FileUtils.makedirs(to_index_containing_dir)
    end
    FileUtils.cp_r(from_index, to_index)
  end


  # Replaces the table's indexes in test system with indexes in development
  # system
  #
  # Parameters:
  # * table_name - a table name
  # * table_cls - constant corresponding to the table name
  def self.copy_development_ferret_index_to_test(table_name, table_cls)
    # Turn off Ferret indexing
    uses_ferret = table_cls.respond_to?('disable_ferret')

    if uses_ferret
      self.copy_ferret_index('development', 'test', table_name)
    end
  end


  # Deletes all the records in the tables
  #
  # Parameters:
  # * tables - a list of table names
  def self.clear_tables(table_names)
    ActiveRecord::Base.establish_connection('test')
    verbose =  ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    table_names.each do |t|
      ActiveRecord::Migration.execute("delete from #{t}")
    end
    ActiveRecord::Migration.verbose = verbose
  end

  # Copies the entire development database to the test database.
  # After calling this, the connection will be to the test database
  def self.copy_development_db_to_test
    # Recreate the test database, taking care the Rails.env is development;
    # when it is "test" the schema gets created from the test database!
#    system('export Rails.env=development; rake db:test:clone')
    system('export RAILS_ENV=development; rake db:test:clone')
    ActiveRecord::Base.establish_connection('development')
    tables = ActiveRecord::Base.connection.tables
    ActiveRecord::Base.establish_connection('test')
    DatabaseMethod.copy_development_tables_to_test(tables)
  end


  # check if there are some upper case characters in in the string
  def self.has_uppercase_code(column_name)
    rtn = false
    if column_name =~ /_C\z/
      rtn = true
    elsif column_name =~ /_ET\z/
      rtn = true
    elsif column_name =~ /_HL7\z/
      rtn = true
    end
    return rtn
  end


  # Convert a MySQL dump script file into 4 Oracel PL/SQL script files
  # and a SQLLDR control file and a SQLLDR data file
  #
  # Parameters:
  # * mysql_script - mysql dump file
  # * file_dir - directory where the oracle script files are created
  # * pk_sn - starting sequence number used in primary key names
  #
  # Returns:
  # [schema_script,alter_script,control_file,data_file,sqlldr_log_file,
  #    sqlldr_bad_file, sqlldr_err_file,drop_script]

  def self.convert_script(mysql_script, file_dir, pk_sn =1)
    # get current time for file names
    time_now = Time.now.strftime('%Y%m%d%H%M%S')

    # db object removal script
    drop_script = 'oracle_drop_' + time_now + '.sql'
    # db schema recreation
    schema_script = 'oracle_db_' + time_now + '.sql'
    # db schema alteration
    alter_script = 'oracle_alter_' + time_now + '.sql'
    # Oracle SQL Loader data file
    data_file = 'sqlldr_data_' + time_now + '.dat'
    # Oracle SQL Loader control file
    control_file = 'sqlldr_control_' + time_now + '.ctl'

    # sqlldr log file, bad file, and error file
    sqlldr_log_file = 'sqlldr_log_' + time_now + '.log'
    sqlldr_bad_file = 'sqlldr_bad_' + time_now + '.bad'
    sqlldr_err_file = 'sqlldr_err_' + time_now + '.err'

    # Open the Oracle script for writing
    ora_script = File.new(file_dir + schema_script, "w")

    # Open the db alteration script for writing
    # it rebuilds indexes after data is loaded
    ora_alter = File.new(file_dir + alter_script, "w")

    # Open the slqldr data file for writing
    ora_data = File.new(file_dir + data_file, "w")

    # Open the slqldr control file for writing
    ora_control = File.new(file_dir + control_file, "w")

    # generating the drop script
    ora_drop = File.new(file_dir + drop_script, "w")
    ora_drop.puts "SET SCAN OFF;"

    # Add initial commands in Oracle script file
    ora_script.puts "SET SCAN OFF;"

    # Add initial setting for SQL Loader control file
    ora_control.puts "LOAD DATA"
    ora_control.puts "  INFILE #{data_file} \"str X'00'\""
    ora_control.puts "  BADFILE #{sqlldr_bad_file}"
    ora_control.puts "  DISCARDFILE #{sqlldr_err_file}"
    ora_control.puts "  APPEND "
    ora_control.puts ""

    # table name lists
    tablenames = []
    # create index statement
    create_indexes = []
    #primary index name list
    primary_indexes = []

    inCreate = false
    seq_needed = false

    extra_sql = []
    table_name =''
    control_line = nil
    # col lines in sql loader control file
    control_cols = []

    # Convert the SQL commands
    File.open(mysql_script, "r").each do |line|
      # Ignore comments
      # 1. starting with '--'
      # 2. included by '/*' and '*/'
      # Ingore empty lines
      # Ignore DROP TABLE statement
      # Ignore LOCK, UNLOCK statement
      if line =~ /^--/ || line =~ /^\/\*.*\*\/;$/ || line =~ /^\s*$/ ||
            line =~ /^(DROP|LOCK|UNLOCK)/i
        # puts "Ignored: " + line
      else
        # puts "Converted: " + line
        # Remove ``
        line.gsub!(/`/, '')

        control_line = line

        if line =~ /^CREATE\s+TABLE\s+(\S*)\s+\(/i
          table_name = $1
          tablenames.push table_name
          inCreate = true

          # drop existing tables
          ora_drop.puts "DROP TABLE #{table_name} CASCADE CONSTRAINTS;"

          # sqlldr control file
          ora_control.puts "  INTO TABLE #{table_name} WHEN TAB ='#{table_name}'"
          ora_control.puts "  FIELDS TERMINATED BY \",\" OPTIONALLY ENCLOSED BY \"'\""
          ora_control.puts "  ( tab FILLER position(1),"
          control_line = nil
          control_cols = []
        end

        # Within CREATE TABLE statement:
        if inCreate
          # 0.0 found a 'auto_increment'
          if line =~ /auto_increment/
            seq_needed = true
          end
          # 0.1 remove "auto_increment"
          if line !~ /ENGINE.*AUTO_INCREMENT=(.*)\s+DEFAULT\s+CHARSET.*;$/i
            line.gsub!(/auto_increment/i, '')
          end

          # 0.2 remove "default ''"
          if line =~ /NOT\s+NULL\s+default\s+''/
            line.gsub!(/NOT\s+NULL\s+default\s+''/, 'NOT NULL')
          end

          # 0.3 remove column comments;
          if line =~ /\S+\s+COMMENT/i
            line.gsub!(/(\S+\s+)COMMENT.*,/, '\1,')
            line.gsub!(/(\S+\s+)COMMENT.*/, '\1')
          end

          # 1. Do data type translation
          #  MySQL data type ======>   Oracle data type
          #  int(11)                   number(38)
          #  int                       number
          #  tinyint(1)                number(1)
          #  varchar                   varchar2
          #  float                     number
          #  text                      clob
          #  blob                      blob
          #  datetime                  date
          line.gsub!(/(\S+\s+)int\(11\)/i, '\1number(38)')
          line.gsub!(/(\S+\s+)tinyint\(/i, '\1number(')
          line.gsub!(/(\S+\s+)int\(/i, '\1number(')
          line.gsub!(/(\S+\s+)float/i, '\1number')
          line.gsub!(/(\S+\s+)varchar\(/i, '\1varchar2(')
          line.gsub!(/(\S+\s+)text,$/i, '\1clob,')
          line.gsub!(/(\S+\s+)text$/i, '\1clob')
          line.gsub!(/(\S+\s+)datetime/i, '\1date')

          # replace wrap column name with " if it has upper case code
          if line =~ /^\s+(\S*)(.*)/
            column_name = $1
            rest_of_the_line = $2
            if has_uppercase_code(column_name)
              line = '"' + column_name + '"' + rest_of_the_line
            end
          end

          control_line = line unless control_line.nil?

          # 2. Rewrite primary key statement
          #    "PRIMARY KEY  (`id`),"
          # ==> CONSTRAINT primary_#{sn} PRIMARY KEY (id)
          if line =~ /^\s*PRIMARY KEY/i
            line.gsub!(/^\s*PRIMARY\s+KEY\s+(.*)/i,
              "  CONSTRAINT primary_#{pk_sn} PRIMARY KEY \\1")
            primary_indexes.push "primary_#{pk_sn}"
            # add rebuild index command in db alteration script
            ora_alter.puts "alter index primary_#{pk_sn} rebuild;"
            pk_sn += 1
            # remove the ending ',' if there's one (when it's followed by KEY ...)
            line.gsub!(/,$/, '')
            control_line = nil
            # 2.1 Rewrite unique key statement
            #    "UNIQUE KEY `unique_schema_migrations` (`version`)"
            # ==> "CONSTRAINT unique_schema_migrations UNIQUE(version)"
          elsif line =~ /^\s*UNIQUE KEY/i
            line.gsub!(/^\s*UNIQUE\s+KEY\s+(\S+)\s+(\S+)/i,
              "  CONSTRAINT \\1 UNIQUE \\2")
            # remove the ending ',' if there's one (when it's followed by KEY ...)
            line.gsub!(/,$/, '')
            control_line = nil
          else
            # 3. CREATE a INDEX for other KEY
            #    "KEY `index_mplus_drugs_on_urlid_and_name_type` (`urlid`,`name_type`)"
            # ==> CREARE INDEX index_mplus_drugs_on_urlid_and_name_type ON mplus_drugs
            #     (urlid, name_type);
            if line =~ /KEY\s+(\S*)\s+\((\S*)\)/i
              index_name = $1
              column_names = $2
              col_names = column_names.split(',')
              modified_col_names =[]
              col_names.each do | col_name|
                if has_uppercase_code(col_name)
                  modified_col_names << '"' + col_name + '"'
                else
                  modified_col_names << col_name
                end
              end
              modified_column_names = modified_col_names.join(',')

              # index_name should be no more than 30 characters
              index_name = index_name.slice(0..29)
              sql_statement = "CREATE INDEX #{index_name} ON #{table_name} (#{modified_column_names});"
              create_indexes.push(sql_statement)
              # add rebuild index command in db alteration script
              ora_alter.puts "alter index #{index_name} rebuild;"
              line = nil
              control_line = nil
              ##extra_sql.push(sql_statement)
            end
          end

          # 4. Create sequence if in CREATE TABLE statement, id is ended with
          # " `id` int(11) NOT NULL auto_increment, "
          # Check the last line for the start value of the sequence
          # "ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;"
          # check keyword : 'AUTO_INCREMENT=3'
          # ==> CREATE SEQUENCE #{table_name}_SEQ MINIVALUE 3 MAXVALUE 999999999999999999999999
          #     INCREMENT BY 1 NOCYCLE NOCACHE ORDER
          if seq_needed
            if line =~ /ENGINE.*AUTO_INCREMENT=(.*)\s+DEFAULT\s+CHARSET.*/i
              seq_init_value = $1
              sql_statement = "CREATE SEQUENCE #{table_name}_SEQ MINVALUE #{seq_init_value} MAXVALUE 999999999999999999999999 INCREMENT BY 1 NOCYCLE NOCACHE ORDER;"
              extra_sql.push(sql_statement)
              line = ');'
              # drop existing seq
              ora_drop.puts "DROP SEQUENCE #{table_name}_SEQ;"
              control_line = nil
              seq_needed = false
            elsif line =~ /ENGINE.*\s+DEFAULT\s+CHARSET.*/i
              seq_init_value = 1
              sql_statement = "CREATE SEQUENCE #{table_name}_SEQ MINVALUE #{seq_init_value} MAXVALUE 999999999999999999999999 INCREMENT BY 1 NOCYCLE NOCACHE ORDER;"
              extra_sql.push(sql_statement)
              line = ');'
              # drop existing seq
              ora_drop.puts "DROP SEQUENCE #{table_name}_SEQ;"
              control_line = nil
              seq_needed = false
            end
          end

          # 5. Remove "ENGINE=InnoDB DEFAULT CHARSET=utf8;" part
          if line =~ /ENGINE.*DEFAULT\s+CHARSET.*/i
            line = ');'

            control_line = nil
          end

          ora_script.puts line unless line.nil?

          # sqlldr control file
          # get column name, data type and data size
          col_control_line = ''
          col_name = ''
          col_type = ''
          col_size = ''

          if !control_line.nil?
            if control_line =~ /^\s*(\S+)\s+(\S+)\((\S+)\)\s*.*/
              col_name = $1
              col_type = $2
              col_size = $3
              #            if col_type == 'varchar2' && col_size !='255'
              #              col_control_line = "#{col_name} char(#{col_size})"
              #            else
              #              col_control_line = "#{col_name}"
              #            end
              if col_type == 'varchar2' && col_size.to_i > 255
                col_control_line = "#{col_name} char(#{col_size})"
              else
                col_control_line = "#{col_name}"
              end
              #            col_control_line = "#{col_name}"
              # date, clob, blob or number without size specified
            elsif control_line =~ /^\s*(\S+)\s+(\S+),?\s*.*/
              col_name = $1
              col_type = $2
              # remove the tailing ',' if there's one
              col_type.gsub!(/,\z/, '')
              if col_type == 'clob' || col_type == 'blob'
                col_control_line = "#{col_name} char(80000)"
              elsif col_type == 'date'
                col_control_line = "#{col_name} date 'YYYY-MM-DD HH24:MI:SS'"
              else
                col_control_line = "#{col_name}"
              end
            else
              puts "#{control_line} is not parsed correctly in table #{table_name}"
            end
            # add default NULL, except for "NOT NULL"
            if control_line !~ /NOT NULL/i
              # special handling for reserved word 'last' in table 'pets'
              # use "" to avoid reseved word error. Note: it becomes case sensitive
              # "LAST" is the actual column name stored in Oracle db.
              # so is "EXPRESSION", "DATA"
              if col_name =~ /"/
                uppercase_col_name = col_name
              else
                uppercase_col_name = '"' + col_name.upcase + '"'
              end
              col_control_line = col_control_line + " NULLIF (#{uppercase_col_name}='NULL')"
              #            col_control_line = col_control_line + " decode(:#{col_name},'NULL',null)"
            end
            control_cols.push(col_control_line)
          end
          # end of "CREATE TABLE"
          if line =~ /;$/
            # add extra sql statement
            extra_sql.each do |sql|
              ora_script.puts sql
            end
            #          # alter table to nologgin
            #          ora_script.puts "ALTER TABLE #{table_name} NOLOGGING;"

            i=0
            while i< control_cols.length-1
              ora_control.puts "    #{control_cols[i]},"
              i += 1
            end
            # last line , no ","
            ora_control.puts "    #{control_cols[control_cols.length-1]}"
            ora_control.puts "  )"

            inCreate = false
            extra_sql = []
            seq_init_value = 1
            table_name = ''
          end
          # "INSERT INTO" commands
        elsif line =~ /^s*INSERT\s+INTO\s+(\S+)\s+VALUES\s+(.*);$/
          table_name = $1
          value = $2
          # special handling for data in some tables
          # if it's gopher_terms or temp_gopher_terms table
          # replace "\r\n' with ''
          if table_name == 'gopher_terms' || table_name == 'temp_gopher_terms'
            value.gsub!(/\\r\\n/,'')
          end
          # if it's field_descriptions or rules table
          # replace '\n' with newline 10.chr
          # replace '\\t' with 9.chr
          if table_name == 'field_descriptions' || table_name == 'rules'
            value.gsub!(/\\r\\n/,10.chr)  # some has \r\n
            value.gsub!(/\\n/,10.chr)     # \n
            value.gsub!(/\\\\\t/,9.chr)   # \\t
          end

          # general convertion
          # escape single quote (mysql : \', oracle: '')
          value.gsub!(/\\'/, "''")   # \'
          # replace \" with "
          value.gsub!(/\\"/,'"')     # \"
          # repalce \\ with \
          value.gsub!(/\\\\/, '\\')  # \\

          # if it's open_id_associations, open_id_auth_nonces or sessions
          # don't touch '\n'
          value += ","
          in_string= false
          quote_replaced = false
          idx = self.find_unescaped_single_quote(value)
          while (!idx.nil?)
            in_string = !in_string
            if in_string
              idx2 = self.find_unescaped_single_quote(value,idx+1)
              r_idx = value.index(")", idx+1)
              while (!r_idx.nil? && r_idx < idx2)
                value[r_idx]=00.chr
                r_idx = value.index(")",r_idx+1)
                quote_replaced = true
              end
            end
            idx = self.find_unescaped_single_quote(value,idx+1)
          end
          value_list = value.split("),")
          value_list.each do |value_rec|
            value_rec.gsub!(00.chr,")") unless !quote_replaced
            value_rec.gsub!(/\A\(/, '')
            ora_data.write table_name + ',' + value_rec  + 00.chr
          end
          #          ora_data.write table_name + ',' + value  + 00.chr
          line = nil
          # Other SQL than "CREATE TABLE" or "INSERT INTO"
        else
          puts "other sql statements than creat or insert"
          ora_script.puts line unless line.nil?
        end
      end
    end

    #create indexes
    create_indexes.each do |index_creation|
      ora_script.puts index_creation
    end

    #  # alter table to logging
    #  tablenames.each do |table|
    #    ora_script.puts "ALTER TABLE #{table} LOGGING;"
    #  end
    ora_script.puts "disconnect;"
    ora_script.puts "exit;"
    ora_script.close
    ora_alter.puts "disconnect;"
    ora_alter.puts "exit;"
    ora_alter.close
    ora_drop.puts "disconnect;"
    ora_drop.puts "exit;"
    ora_drop.close
    ora_data.close
    ora_control.close

    return [schema_script,alter_script,control_file,data_file,sqlldr_log_file,
      sqlldr_bad_file, sqlldr_err_file,drop_script]
  end

  # find the first unescaped ' in the string
  def self.find_unescaped_single_quote(line, offset=0)
    ret = nil
    idx = line.index("'",offset)
    while (!idx.nil?)
      idx2 = idx -1
      if (idx2 < 0)
        backslash = nil
      else
        backslash = line.slice(idx-1,1)
      end
      if (!backslash.nil? && backslash == "\\")
        idx = line.index("'", idx +1)
      else
        ret = idx
        break
      end
    end
    return ret
  end


  # Resets the auto increment counter on the id column to 1.  This should only
  # be called if the table has been emptied.
  #
  # Parameters:
  # * table_name the name of the table for which the sequence should be reset.
  def self.reset_id_col_auto_increment(table_name)
    table_cls = table_name.singularize.camelize.constantize
    if (self.isMySQL)
      table_cls.connection.execute(
        "ALTER TABLE #{table_name} AUTO_INCREMENT = 0")
    else
      sql_statement = "DROP SEQUENCE #{table_name}_SEQ;"+
        "CREATE SEQUENCE #{table_name}_SEQ MINVALUE 1 MAXVALUE " +
        '999999999999999999999999 INCREMENT BY 1 NOCYCLE NOCACHE ORDER;'
      table_cls.connection.execute(sql_statement)
    end
  end


end
