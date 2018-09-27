# Patching for acts_as_ferret gem to fix deprecated Relation#all method
# See [gem_path]/gems/acts_as_ferret-0.5.4/lib/acts_as_ferret/class_methods.rb line 74
module ActsAsFerret
  module ClassMethods
    def records_for_rebuild(batch_size = 1000)
      transaction do
        if use_fast_batches?
          offset = 0
          while (rows = where(["#{table_name}.id > ?", offset]).limit(batch_size).load).any?
            offset = rows.last.id
            yield rows, offset
          end
        else
          order = "#{primary_key} ASC" # fixes #212
          0.step(self.count, batch_size) do |offset|
            yield scoped.limit(batch_size).offset(offset).order(order).load, offset
          end
        end
      end
    end
  end
end

