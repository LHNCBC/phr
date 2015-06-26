# When the config.cache_classes is true, the JavaScript assets will be cached by
# the asset pipeline system in the following places:
# (see line 113 and below of sprockets#railtie.rb for details)
# 
# 1) Rails.application.assets
# 2) The instance methods assets_environment and assets_manifest of 
#    ActionView::Base
# 3) The assets mounted as Rack server to server HTTP requests 
# 
# When the form specific JavaScript is re-generated, we have to manually refresh  
# the cached assets. 
# 
# Since the benefit of using cache for assets is very limited especially when 
# the browser also caches them, it's better to turn off that cache. In order 
# to do so, we override the assets method so that it will always return the 
# non-cached assets even when the attribute @asssets has been cached(see line#113 
# of sprockets#railtie.rb). 
module Rails
  class Application
    # Return non-cached assets disregarding the cache_classes setting
    def assets_with_cache_filtered
      rtn = assets_without_cache_filtered
      @assets_not_indexed ||= rtn
    end
    alias_method_chain :assets, :cache_filtered

#    # Refresh the cached assets if applicable
#    def refresh_cached_assets
#      if assets.is_a? Sprockets::Index
#        @assets= @assets_not_indexed.index
#      end
#    end
    
    # Return the manifest used in non-debug mode
    # Parameter:
    # * need_compile a flag indicating whether the manifest will be used for 
    # compiling assets
    def asset_manifest(need_compile=false)
      if (need_compile)
        manifest_path = File.join(Rails.public_path, config.assets.prefix)
        Sprockets::Manifest.new(assets, manifest_path)
      else
        ActionView::Base.new.assets_manifest
      end
    end
  end
end


## The javascript_include_tag method sometimes returns staled links. The 
## work-around is to clear the cache and index to make sure the returned asset 
## always up-to-date
#module Sprockets
#  class Environment < Base 
#    def find_asset_with_nocache(*args)
#      expire_index!
#      self.cache = nil
#      find_asset_without_nocache(*args)
#    end
#    alias_method_chain :find_asset, :nocache
#  end
#end
