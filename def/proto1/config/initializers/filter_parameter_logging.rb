# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
#if PUBLIC_SYSTEM || true # Remove the "|| true" if you want to see the parameters
if PUBLIC_SYSTEM || !HOSTS_WITHOUT_LOG_FILTER.include?(HOST_NAME)
  # Disable logging of parameters on the public machines
  Rails.application.config.filter_parameters << lambda do |k , v|
    if v.duplicable?    
      def v.inspect
        "[FILTERED]"
      end
    end
  end
end
