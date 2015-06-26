# A class for use in slowing down rapid accesses from web crawlers.
require 'lrucache'

class Brake
  # The maximum number of seconds to slow down a request.  Do not make this
  # too large, because if a multi-threaded scanner hits us with a sufficient
  # number of threads, all the rails processes will be busy sleeping for this
  # list length of time (meaning real users won't be able to access the site
  # for this length of time).
  MAX_SLEEP = 5

  # The initial number of seconds to slow down a request.
  INITIAL_SLEEP = 0.5

  # The multiplier by which to increase the number of seconds by which a request
  # is slowed down.
  SLEEP_MULITIPLIER = 3

  # The amount of time in seconds since the last penalized request before the
  # penalty is cleared.
  RESET_TIME = 5.minutes

  # The minimum amount of time between requests for which we do not impose
  # a penalty (in seconds).
  MIN_REQ_INTERVAL = 1


  # A class instance variable to hold information about recent IP addresses.
  @ip_to_time_and_slow_factor = LRUCache.new(:max_size=>10000) # class instance variable

  # A method intended to be used as a before_filter to slow down
  # requests from IPs that are sending us too many requests (e.g. web crawlers
  # and scanners).  This is meant to be used in conjunction with the
  # store_response_info method (which is a after_filter).
  #
  # Parameters:
  # * request - the request object
  def self.slow_scanners(request)
    # For now, log the process ID handling the request, so we can get a better
    # understanding of the behavior of scanners.  Long term, we probably do not
    # want to do this for every request.
    logger.info "Brake:  Request handled by process #{Process.pid}"
    # Ignore requests where were redirected from another request.  (This
    # flag is set in store_response_info, below.)
    if request.session[:was_redirect]
      request.session.delete(:was_redirect) # reset the flag
    else
      # Completely ignore AJAX requests, at least for now.  Sometimes PHR pages
      # send AJAX requests within a second (even just on page load) and we don't
      # want to penalize normal users.  Of course, it might be that some scanners
      # will send us AJAX requests.  If that is an issue, we'll revise this.
      # Also don't run this in the test mode.
      if (!request.xhr? && ENV['RAILS_ENV'] != 'test')
        delay = get_delay_time(request.ip)
        if delay != 0
          logger.info "Brake:  delaying #{request.method} request for "+
            "#{request.fullpath} from #{request.ip} by #{delay}s."
          sleep(delay)
        end
      end
    end
  end


  # Another part of slowing down the scanners.  We need to check the response
  # type; if it is redirect we do not want to slow the next request.  This is
  # meant to be called as an after_filter, and used in conjuction with
  # slow_scanners (a before_filter).
  #
  # Paramaters:
  # * response - the response object from the controller
  # * session - the session object from the controller
  def self.store_response_info(response, session)
    session[:was_redirect] = response.status == 302
  end


  # Returns the delay in seconds for the given IP address for the current
  # request.  This method is not intended to be called directly; use
  # slow_scanners instead.  It is a public method just to be testable.
  # This method does not sleep, but expects the caller will sleep for the
  # return value.
  #
  # Parameters:
  # * ip - the IP address of the request
  def self.get_delay_time(ip)
    rtn = 0
    time = Time.now
    data = @ip_to_time_and_slow_factor[ip]

    if !data
      @ip_to_time_and_slow_factor[ip] = [time, 0]
    else
      last_req_time, delay, last_penalty_time = data
      if last_penalty_time && (time - delay - RESET_TIME > last_penalty_time)
        # Then there has been five minutes since the end of their last
        # delayed request (and after the delay).  Reset it to normal.
        @ip_to_time_and_slow_factor[ip] = [time, 0]
      else
        # No penalty for a request that follows the previous request
        # by at least 1s.
        if time - last_req_time < MIN_REQ_INTERVAL
          if delay != MAX_SLEEP
            delay = delay!=0 ? delay * SLEEP_MULITIPLIER : INITIAL_SLEEP
            delay = MAX_SLEEP if delay > MAX_SLEEP
          end
          rtn = delay
          # Update "time" so that if they return immediately they are still
          # penalized.
          time += delay
          @ip_to_time_and_slow_factor[ip] = [time, delay, time]
        else
          @ip_to_time_and_slow_factor[ip][0] = time # update last request time
        end
      end
    end
    return rtn
  end
end
