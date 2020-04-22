Recaptcha.configure do |config|
  config.site_key = RECAPTCHA_SITE_KEY
  config.secret_key = RECAPTCHA_SECRET_KEY

  if ENV['proxy_host'].nil?
    host = port = nil
  else
    host, port = ENV['proxy_host'].split(/:/)
  end
  config.proxy = "#{host}:#{port}" if host
end

Recaptcha.configuration.skip_verify_env.delete('test')

module Recaptcha::Adapters
  module ViewMethods
    def recaptcha_icon(name)
      html = %Q(<img src="https://www.gstatic.com/recaptcha/api2/#{name}.png" alt="#{name}" height="15" width="15">)
      html.respond_to?('html_safe') ? html.html_safe : html
    end
  end
end
