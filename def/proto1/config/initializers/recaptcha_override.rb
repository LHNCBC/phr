# This is here to fix a bug in rack-recaptcha 0.6.4 gem. After gem is updated
# with fixed code, this should be removed
require 'rack/recaptcha'
class Rack::Recaptcha
  def verify(ip, challenge, response)
    params = {
      'privatekey' => Rack::Recaptcha.private_key,
      'remoteip'   => ip,
      'challenge'  => challenge,
      'response'   => response
    }
    
    uri  = URI.parse(VERIFY_URL)
    
    if self.class.proxy_host && self.class.proxy_port
      http = Net::HTTP.Proxy(self.class.proxy_host,
        self.class.proxy_port,
        self.class.proxy_user,
        self.class.proxy_password).start(uri.host, uri.port)
    else
      http = Net::HTTP.start(uri.host, uri.port)
    end
    
    request           = Net::HTTP::Post.new(uri.path)
    request.form_data = params
    response          = http.request(request)
    
    response.body.split("\n")
  end
end
