#!/proj/def/bin/ruby
# Methods to look for data problems in the autosave_tmps table.
#

require 'rubygems'
require 'mysql2'
require 'yaml'
require 'erb'
require 'fileutils'
require 'json'

# script description and usage info
def show_help
  puts <<END_HELP
autosave_tmp_cleanups.rb:  Looks for problem data in the autosave_tmps table
and lists the data.

Three groups of problem data are addressed by this script. Here are the groups
and how to run this script for each group:

1.  Rows with null values in the profile_id and/or form_name fields: Enter 1
 
2.  Rows that contain duplicated data in the base record column, e.g. drugs
    that are listed twice even though the user only entered them once: Enter 2

3.  Instances where there are multiple base records for the same
    profile_id and form_name values, e.g. multiple base records for
    profile_id = 2 AND form_name = X:  Enter 3

To specify more than one option, separate each with one space, e.g. 1 2 3

END_HELP
end

if ARGV.length == 0 || ARGV[0] == '-h'
  show_help
  exit
end



def set_up_db_stuff
  # Read the database connection information from the database.yml file
  db_config_file = File.dirname(__FILE__) + '/../config/database.yml'
  db_config = YAML.load(ERB.new(File.read(db_config_file)).result)['development']

  # Connect to the database
  @conn = Mysql2::Client.new(:host=>db_config['host'],
                             :username=>db_config['username'],
                             :database=>db_config['database'],
                             :password=>db_config['password'])
end

def process_nulls()
  nulls_list = @conn.query('select * from autosave_tmps where profile_id is ' +
                           'NULL or form_name is NULL')
  if nulls_list.count == 0
    puts "No rows with null profile_ids or form_names were found; " +
         "no further processing done."
  else
    puts nulls_list.count.to_s + ' rows were found with null values.'
    puts ''
    nulls_list.each do |nl|
      puts nl["id"].to_s + ' profile_id = ' + nl["profile_id"].to_s +
           '; user_id = ' + nl["user_id"].to_s + '; form_name = ' +
           nl["form_name"].to_s + '; created_at = ' +
           nl["created_at"].strftime("%d-%m-%Y %H:%M:%S") + '; updated_at = ' +
           nl["updated_at"].strftime("%d-%m-%Y %H:%M:%S") + '; base_rec = ' +
           nl["base_rec"].to_s
    end # do for each null row
  end # if any rows with null profile_ids or form_names were found
end # process_nulls


def process_dup_data()

  # get counts from data tables, base rec
  all_base = @conn.query('select * from autosave_tmps where base_rec = true ' +
                         'AND profile_id IS NOT NULL AND form_name IS NOT NULL')
  if all_base.size == 0
    puts "There are no autosave base records in this database.  No further " +
         "processing done (what would we do?)."
  else
    dup_data_list = []
    table_dump = {}
    all_base.each do |brec|
      table_dump[brec["id"]] = {}
      brec["diffs"] = {}
      recorded_row = false
      data_tbl = JSON.parse(brec["data_table"])
      data_tbl.each do |table_name, rec_array|

        if table_name[0..1] != 'ob'
          # get the count for the base record
          rec_array.each do |rec|
            if rec["record_id"] == ""
              rec_array.delete(rec)
              break
            end
          end # checking for the blank row
          rec_count = rec_array.size
          # compare to the table count
          table_recs = @conn.query('select * from ' + table_name + ' where ' +
                                   'profile_id ' + 
            (brec["profile_id"].nil? ? 'IS NULL ' : ' = ' + brec["profile_id"].to_s)  +
                                   ' and latest = true')
          if table_recs.size != rec_count
            brec["diffs"][table_name] = "base record count for this " +
                            "table = " + rec_count.to_s + "; db count = " +
                            table_recs.size.to_s + "; base_rec data_table:"
            if !recorded_row
              dup_data_list << brec
              recorded_row = true
            end
            table_dump[brec["id"]][table_name] = rec_array
          end
        end # if this is not a obr or obx table
      end # do for each data_table in the row
    end # do for each row
    if dup_data_list.size == 0
      puts "No rows with duplicated data were found; no further processing done."
    else
      puts dup_data_list.count.to_s + ' rows were found with duplicated data.'
      puts ''
      dup_data_list.each do |dp|
        puts dp["id"].to_s + ' profile_id = ' + dp["profile_id"].to_s +
             '; user_id = ' + dp["user_id"].to_s + '; form_name = ' +
             dp["form_name"].to_s + '; created_at = ' +
             dp["created_at"].strftime("%d-%m-%Y %H:%M:%S") + '; updated_at = ' +
             dp["updated_at"].strftime("%d-%m-%Y %H:%M:%S") + '; base_rec = ' +
             dp["base_rec"].to_s
        table_dump[dp["id"]].each_pair do |table_name, rec_array|
          puts ''
          puts table_name + ':  ' + dp["diffs"][table_name]
          rec_array.each do |rec|
            puts rec.to_json
          end
        end
        puts '---------------------'
        puts ''
      end # do for each base record
    end # if records with duplicated data were found
  end # if base records were found
end # process_dup_data


def process_dup_base_recs()
  dup_base_groups = @conn.query('SELECT profile_id, form_name, count(base_rec), ' +
                                'created_at from autosave_tmps where base_rec ' +
                                ' = true group by profile_id, form_name having ' +
                                'count(base_rec) > 1 and profile_id is NOT NULL')
  if dup_base_groups.size == 0
    puts "No duplicate base records found; no further processing done."
  else
    puts 'Row(s) found with duplicated base records.'
    puts ''

    dups_count = 0
    dup_base_groups.each do |db|
      one_set = @conn.query('SELECT * from autosave_tmps where ' +
                            'profile_id = "' + db["profile_id"].to_s +
                            '" and form_name = "' + db["form_name"] +
                            '" and base_rec = true order by updated_at')
      one_set.each do |os|
        puts os["id"].to_s + ' profile_id = ' + os["profile_id"].to_s +
             '; user_id = ' + os["user_id"].to_s + '; form_name = ' +
             os["form_name"].to_s + '; created_at = ' +
             os["created_at"].strftime("%d-%m-%Y %H:%M:%S") +
             '; updated_at = ' +
             os["updated_at"].strftime("%d-%m-%Y %H:%M:%S") + '; base_rec = ' +
             os["base_rec"].to_s
        dups_count += 1
      end # do for the detail rows
      puts ''
    end # do for each row
    puts ''
    puts dups_count.to_s + ' rows found with duplicated base records.'
  end # if any duplicate base records were found
end # process_dup_base_recs

set_up_db_stuff

ARGV.each do |arg|
  if arg.length != 1 || !['1', '2', '3'].include?(arg[0])
     puts 'Invalid argument - ' + arg + ' - not processed'
  else
    case arg[0]
    when '1'
      process_nulls()
    when '2'
      process_dup_data()
    when '3'
      process_dup_base_recs()
    end
  end
end
