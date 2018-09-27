module Ruport
  module Reportable
    module SingletonMethods

      # Override original method to fix the error caused by the deprecated ActiveRecord finder
      def report_table(number = :all, options = {})
        only = options.delete(:only)
        except = options.delete(:except)
        methods = options.delete(:methods)
        includes = options.delete(:include)
        filters = options.delete(:filters)
        transforms = options.delete(:transforms)
        # patch_001: remove order out of the where clause
        order = options.delete(:order)
        # patch_001 end
        record_class = options.delete(:record_class) || Ruport::Data::Record
        self.aar_columns = []

        unless options.delete(:eager_loading) == false
          # patch_002: fix error caused by {include: nil}
          options[:include] = get_include_for_find(includes) if includes
          # patch_002 end
        end

        # patch_003: convert 'find' to 'where' clause and adjust the order
        sql = where(options)
        sql = sql.order(order) if order
        data = [number === :all ? sql.all : sql.take(number)].flatten
        # patch_003 end
        data = data.map {|r| r.reportable_data(:include => includes,
                                               :only => only,
                                               :except => except,
                                               :methods => methods)}.flatten

        table = Ruport::Data::Table.new(:data => data,
                                        :column_names => aar_columns,
                                        :record_class => record_class,
                                        :filters => filters,
                                        :transforms => transforms)
      end
    end
  end
end
