module ActionController
  class LogSubscriber < ActiveSupport::LogSubscriber
    def process_action(event)
      payload   = event.payload
      additions = ActionController::Base.log_process_action(payload)

      message = "Completed in %.0fms" % event.duration
      message << " (#{additions.join(", ")})" unless additions.blank?

      #      params  = payload[:params].except(*INTERNAL_PARAMS)
      params  = payload[:params].except(*[])
      message << "  RequestUrl: #{payload[:path]}" unless params.empty?
      
      info(message)
    end
  end
end     
