# In Rails 4, by default, the cache method will generate a fragment cache suffixed with a digest based on
# the source of template and its dependencies. The advantage of cache digest is that it can expire fragment
# cache automatically in non-production mode. Since we need to expire cache in production, this feature is
# not practical to us. Therefore we will keep using our existing code for cache expiring and disable the
# digest feature.
# (see cache_digest on github or ActionView::Digestor in Rails 4 for details)
module ActionView
  module Helpers
    module CacheHelper
      def cache_with_modification(name = {}, options = nil, &block)
        options ||={}
        options[:skip_digest] = true
        cache_without_modification(name, options, &block)
      end
      alias_method_chain :cache, :modification
    end
  end
end
