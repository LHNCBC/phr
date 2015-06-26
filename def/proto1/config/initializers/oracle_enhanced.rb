#
# Necessary extensions and bug fixes for Oracle Apdater
#
require 'active_support/test_case'

if DatabaseMethod.isOracle
  module ActiveSupport
    class TestCase
      def setup_sequence
        table_names = fixture_table_names
        # added for updating Oracle sequences
        DatabaseMethod.updateSequence(table_names)
      end
      setup :setup_fixtures, :setup_sequence
    end
  end
end

#
# patched for Oracle Enhanced Adapter
#
# indexes return all column names in lower cases.
# for Oracle, if the column name has a mix of upper and lower case letters,
# the column name should be wrapped by ""
#
# To test, run:
#   ActiveRecord::Base.connection.indexes('obr_orders')
if DatabaseMethod.isOracle
  module ActiveRecord
    module ConnectionAdapters
      class OracleEnhancedAdapter
        # set the default start value to 1, instead of 10000
        @@default_sequence_start_value =1

        def indexes(table_name, name = nil) #:nodoc:
          #puts "in the modified code of indexes"
          (owner, table_name) = @connection.describe(table_name)
          result = select_all(<<-SQL, name)
                SELECT lower(i.index_name) as index_name, i.uniqueness, c.column_name as column_name
                  FROM all_indexes i, all_ind_columns c
                 WHERE i.table_name = '#{table_name}'
                   AND i.owner = '#{owner}'
                   AND i.table_owner = '#{owner}'
                   AND c.index_name = i.index_name
                   AND c.index_owner = i.owner
                   AND NOT EXISTS (SELECT uc.index_name FROM all_constraints uc WHERE uc.index_name = i.index_name AND uc.owner = i.owner AND uc.constraint_type = 'P')
                  ORDER BY i.index_name, c.column_position
              SQL

          current_index = nil
          indexes = []

          result.each do |row|
            if current_index != row['index_name']
              indexes << IndexDefinition.new(table_name.downcase, row['index_name'], row['uniqueness'] == "UNIQUE", [])
              current_index = row['index_name']
            end
            column_name = row['column_name']
            if DatabaseMethod.has_uppercase_code(column_name)
              column_name = column_name
            else
              column_name = column_name.downcase
            end
            indexes.last.columns << column_name
          end

          indexes
        end

        # a patch in function create_table for sequence parameters
        def create_table(name, options = {}, &block) #:nodoc:
          create_sequence = options[:id] != false
          column_comments = {}
          super(name, options) do |t|
            # store that primary key was defined in create_table block
            unless create_sequence
              class <<t
                attr_accessor :create_sequence
                def primary_key(*args)
                  self.create_sequence = true
                  super(*args)
                end
              end
            end

            # store column comments
            class <<t
              attr_accessor :column_comments
              def column(name, type, options = {})
                if options[:comment]
                  self.column_comments ||= {}
                  self.column_comments[name] = options[:comment]
                end
                super(name, type, options)
              end
            end

            result = block.call(t)
            create_sequence = create_sequence || t.create_sequence
            column_comments = t.column_comments if t.column_comments
          end

          seq_name = options[:sequence_name] || quote_table_name("#{name}_seq")
          seq_start_value = options[:sequence_start_value] || default_sequence_start_value
          # execute "CREATE SEQUENCE #{seq_name} START WITH #{seq_start_value}" if create_sequence
          execute "CREATE SEQUENCE #{seq_name} START WITH #{seq_start_value} NOCACHE ORDER" if create_sequence

          add_table_comment name, options[:comment]
          column_comments.each do |column_name, comment|
            add_comment name, column_name, comment
          end
        end
      end
    end
  end
end
