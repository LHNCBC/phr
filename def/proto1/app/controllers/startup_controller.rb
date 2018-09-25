# A controller that handles the request (sent by Passenger) to initialize
# the rails process when the rails process is first started.
require 'net/https'
class StartupController < ApplicationController
  before_action :localhost_only

  # A before filter to only allow accesses to this controller from the machine
  # itself.
  def localhost_only
    # Require that the URL being accessed have 127.0.0.1 (localhost) as the
    # host, which means that the requester is also on the local system.
    if request.host != '127.0.0.1'
      logger.info "Rejecting request, because host was #{request.host}"
      render :file=>File.join(Rails.root, 'public', 'errors', '403.txt'),
        :status=>:forbidden
    end
  end

  def load_resources
    # The simplest way to load things is to exercise the system.  Log in,
    # and visit some pages.
    http_success_code = '200'
    resp_codes_okay = access_url('/') == http_success_code &&
                      access_url('/form/test/phr') == http_success_code
    raise 'Error accessing startup URLs' if !resp_codes_okay
    render :plain=>'Loaded.'
  end


  private

  # Access a URL on the local system.
  #
  # Parameters:
  # *  url - a relative URL in the system (but with an absolute path,
  #    e.g. "/login")
  #
  # Returns the response code.
  def access_url(url)
    # The following is based on a comment by MAIK SCHMIDT on the page at:
    # http://olabini.com/blog/2008/08/ruby-https-web-calls/

    https = Net::HTTP.new('127.0.0.1', request.env['SERVER_PORT'])
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    resp_code = nil
    https.start do |http|
      request = Net::HTTP::Get.new(url)
      request.basic_auth('phr_demo', 'phr#2496')
      response = https.request(request)
      resp_code = response.code
    end
    return resp_code
  end
end
