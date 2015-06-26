# For some reason, without redefining the log_process_action, the following patch will break.
class << ActionController::Base
  def log_process_action(payload)
    super
  end
end


# In Rails 4, the request completion log message is missing the request path which made
# it hard to measure the performance of PHR page loading. The original process_action method
# was patched with an extra line before the 'info(message)' to include the request path. -Frank
module ActionController
  class LogSubscriber < ActiveSupport::LogSubscriber

    def process_action(event)
      return unless logger.info?

      payload = event.payload
      additions = ActionController::Base.log_process_action(payload)

      status = payload[:status]
      if status.nil? && payload[:exception].present?
        exception_class_name = payload[:exception].first
        status = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception_class_name)
      end
      message = "Completed #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]} in #{event.duration.round}ms"
      message << " (#{additions.join(" | ")})" unless additions.blank?
      message << " [ #{payload[:path]} ]" if payload[:path]

      info(message)
    end
  end
end