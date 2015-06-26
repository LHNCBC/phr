# A class for generating caches of ActiveRecord objects.  All are accessible
# through this class, so we can keep track of how much stuff is cached.
class ActiveRecordCacheMgr
  # The hashmap that holds all generated caches
  CACHE_LABEL_TO_CACHE = {}

  # Creates an ActiveRecord cache, which acts like a hashmap.  The cache
  # is stored in this class under the label that is passed in.
  #
  # Parameters:
  # * cache_label - a unique string to identify this cache
  # * p - (optional) a Proc object to use in loading a value it if is not
  #   found in the cache.  (In other words, if my_cache[key] would return nil,
  #   p.call(key) will be called to get the value, and the value will be
  #   loaded into the cache and return instead of the nil.
  def self.create_cache(cache_label, p=nil)
    cache = {}
    CACHE_LABEL_TO_CACHE[cache_label] = cache
    return p ? Cache.new(cache, p) : cache
  end


  # Makes some methods available to model classes for caching some types of
  # calls that access the database.
  class ::ActiveRecord::Base
    # Caches find_by_[field] calls for the specified fields, and overrides
    # find() so that if find(:all) is called, those caches are populated.
    # If :id is one of the fields cached, then find(id) will use the id cache
    # (as well as find_by_id).  This method results in faster accesses (about 13
    # times faster in my test) than if you use cache_find_calls, and about 387
    # times faster than the regular ActiveRecord calls.  You can use both this
    # method and cache_find_calls in the same model class if you call the
    # latter after this method, in which case the find_for_[field] calls set up
    # by this method are almost as fast, and all find calls are faster (the
    # second time) than if you weren't using the cache.
    # The (unnamed) arguments here should be a list of fields (as strings)
    # whose values are unique across records (e.g. 'id' or 'data_table').  The
    # last argument can be a hash which can contain ":preload=>true" to preload
    # all records.
    def self.cache_recs_for_fields(*args)
      if USE_AR_CACHE
        preload = false
        if args.last.is_a?(Hash)
          options = args.pop
          preload = options[:preload]
        end

        self.class_eval <<-END_DECL_0
          # Declare these here so they are defined on the model class and not
          # on ActiveRecord::Base.
          @@ar_cached_fields = args
          @@field_to_cache = {} # Holds the caches for each field in args
          @@all_records = nil # holds an array of all records from find(:all)
        END_DECL_0


        self.class_eval <<-END_DECL4
          # For debugging, this allows you to see the contents of the cache.
          def self.inspect_cache
            puts "@@ar_cached_fields = \#{@@ar_cached_fields.inspect}"
            puts "@@field_to_cache = \#{@@field_to_cache.inspect}"
            puts "@@all_records = \#{@@all_records.inspect}"
          end
        END_DECL4

        fields_include_id = false
        args.each do |field|
          # Declare the cache and the method to use it.
          code1 = <<-END_DECL
            @@#{field}_to_#{self.name} =
              ActiveRecordCacheMgr.create_cache('#{field}_to_#{self.name}',
                Proc.new {|field_val| self.where(#{field}: field_val).first})

            @@field_to_cache[field] = @@#{field}_to_#{self.name}

            # Returns the cached or found value
            def self.find_by_#{field}(*args)
              # If there is more than one argument, don't try to use this
              # cache.
              if args.length == 1
                return @@#{field}_to_#{self.name}[args[0]]
              else
                # We need to use the rails method, which might not be defined
                # yet, and if it isn't, it will overwrite this method, at
                # which point the cache will stop working.
                method_name = 'find_by_#{field}_without_cache'
                if !self.respond_to?(method_name)
                  class <<self # set up an alias on a class method
                    alias_method :find_by_#{field}_with_cache, :find_by_#{field}
                  end
                  rtn = super(*args) # redefines find_by_#{field}
                  class <<self  # put the method back
                    alias_method :find_by_#{field}_without_cache, :find_by_#{field}
                    alias_method :find_by_#{field}, :find_by_#{field}_with_cache
                  end
                else
                  rtn = find_by_#{field}_without_cache(*args)
                end
                return rtn
              end
            end
          END_DECL
          self.class_eval(code1)

          fields_include_id = true if field == 'id'
        end

        # Override find to provide support for find(:all) and maybe find(id)
        if fields_include_id
          else_code_for_find_id = "else\n"+
                    "arg_zero = Integer(arg_zero) if !arg_zero.is_a?(Fixnum)\n"+
                    "rtn = @@id_to_#{self.name}[arg_zero]"
        else
          else_code_for_find_id = ''
        end

        code3 = <<-END_DECL3
          def self.find(*args)
            n = "\n"
            rtn = nil
            if args.size==1
              arg_zero = args[0]
              if arg_zero == :all
                if !@@all_records
                  @@all_records = super(:all)
                  @@all_records.each do |rec|
                    @@ar_cached_fields.each do |field|
                      @@field_to_cache[field][rec.send(field)] = rec
                    end
                  end
                end
                rtn = @@all_records
              #{else_code_for_find_id}
              end
            end
            rtn = super(*args) if !rtn
            return rtn
          end

          # Returns true if the class is caching based on the ID field.
          def self.has_cache_by_id
            return #{fields_include_id}
          end
        END_DECL3
        self.class_eval(code3)
        self.all if preload

      end # If we're using the caching mechanism
    end # def cache_recs_for_fields


    # Overrides belongs_to take advantage of the cache where possible.
    def self.cache_associations
      if USE_AR_CACHE
        class_eval <<-END_DECL6
          def self.belongs_to(other_class_symbol, options={})
            other_class = other_class_symbol.to_s.classify.constantize
            # Only change the relation method if the other class is cached
            if defined? other_class.has_cache_by_id &&
                        other_class.has_cache_by_id
              id_attr = options[:foreign_key] || "\#{other_class_symbol}_id"
              class_eval <<-END_DECL5
                def \#{other_class_symbol}
                  if !defined? @\#{other_class_symbol}
                    @\#{other_class_symbol} = # store the reference
                                          \#{other_class.name}.find(\#{id_attr})
                  end
                  return @\#{other_class_symbol}
                end
              END_DECL5
            else
              super(other_class_symbol, options) # call the Rails "belongs_to"
            end
          end
        END_DECL6
      end
    end

  end


  private

  # An internal cache that provides a hash-map like access but tries to
  # self-load missing items using its Proc instance.
  class Cache
    # Initializes the cache
    #
    # Parameters:
    # * store - a hashmap to hold the cached data
    # * p - A proc object which will be used to load the cache when items
    #   are missing
    def initialize(store, p)
      @p=p
      @store=store
    end


    # Returns the value for the given key.  If the value is not found
    # in the cache, an attempt will be made to get it using the Proc.
    def [](key)
      if !::USE_AR_CACHE
        rtn = @p.call(key)
      else
        if (rtn = @store[key])==nil
          rtn = @p.call(key)
          @store[key] = rtn
        end
      end
      return rtn
    end

    # Stores a key-value pair into cache.  This is used if it is desirable
    # to pre-load the cache with a subset of possibly needed items to
    # reduce the number of SQL calls that might be generated by the []
    # accessor.
    def []=(key,value)
      @store[key] = value
    end
  end
end
