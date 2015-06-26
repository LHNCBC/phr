#!/bin/sh
# This scripts facilitates the occasional need to update production system
# FFAR tables without updating the rest of the code.  This only works when
# the tables that need updating have not changed their struture,
# and when the data changes do not otherwise cause problems for the code.
# The script will exit if the source table columns do not match the
# destination table columns.
#
# Procedure:
# 1) Export the data from the baseline system using this script, e.g.:
#       table_update.sh --export proto1_development text_lists text_list_items
#    This will produce two files in /tmp, table_columns and table_data.
# 2) Upload (sftp) the two files to the machine containing the database to
#    be updated.
# 3) Import the data using this script, e.g.:
#       table_update.sh --import proto1_development table_columns table_data
#    If this table columns on the destination machine do not match the table columns
#    that were exported, the script will issue an warning and exit.
#
# Notes:
# 1) The script expects to be run on the machine hosting the database.  If you
#    wish to run from a development system, edit the script to set the host
#    variable to anthem.
# 2) The script must be run as user irvmgr for the import on the staging and
#    production systems.
# 3) If the table you are copying has a Ferret index (under /index/production)
#    you will need to copy that over too.

command=$1
if  [[  ("$command" != "--import" && "$command" != "--export") || $# -lt 3 ]]
then
  echo 'Please read the top of the script for usage instructions.'
  echo 'Exiting.'
  exit
fi

db=$2
shift 2
host=`hostname`
#host='anthem' # uncomment to run this on a development system

# Set the mysql user to the current user.  Otherwise, mysql picks up the sudo user.
mysql_usr='-u '$USER

if [ "$command" == '--export' ]
then
  table_columns='/tmp/table_columns'
  table_data='/tmp/table_data'
  tables=$*
  echo $tables > $table_columns
  for table in $tables
  do  
    mysql $mysql_usr -h $host $db --execute "show columns from $table" >> $table_columns
  done
  mysqldump $mysql_usr -h $host $db $tables > $table_data
else
  # Import
  table_columns=$1
  table_data=$2
  exec 4<$table_columns
  declare -a tables
  read -u 4 -a tables
  read -u 4 header_line
  for table in ${tables[@]}
  do  
    echo Checking $table
    table_info=$header_line
    while read -u 4 line && test "$line" != "$header_line"
    do 
      table_info="${table_info}"$'\n'"${line}"
    done
    # Run the following mysql output through the read command to get the same behavior on trailing whitespace
    # as we did above.
    declare host_table_info=''
    first_line=1
    cmd_out=`mysql $mysql_usr -h $host $db --execute "show columns from $table"`
    while read one_line
    do
      if [ "$first_line" == 1 ]
      then
        host_table_info=$one_line
        first_line=0
      else
        host_table_info="${host_table_info}"$'\n'"${one_line}"
      fi
    done <<< "$cmd_out"

    #echo -e t=$table_info
    #echo "$host_table_info"
    #t=`expr substr "$table_info" 80 80`
    #echo "$t" | od -a # shows all characters in $t, including names of non-printable characters
    if test "$table_info" != "$host_table_info"
    then
      echo The table columns appear to be different for table $table.  Exiting.
      exit
    fi

  done

  # Now import the table data
  echo Dropping and importing table data
  cat $table_data | mysql $mysql_usr -h $host $db
fi
