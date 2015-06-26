class SystemError < ActiveRecord::Base

  # Records the server error associated with the given exception
  # object (if it is of interest), and notifies PHR staff if necessary.
  #
  # Parameters
  # * exception - an exception that was raised while processing some request
  # * request - the request object for the request that caused the error
  # * session - the user's session object
  def self.record_server_error(exception, request, session)
    # Skip InvalidAuthentifyToken errors, which are from session timeouts.
    # Also skip RoutingErrors, which can be triggered by scanners.  We used
    # to report RoutingErrors that had a referrer from our site, but some
    # scanners fake that too.  The downside is that we won't get a report of
    # real broken links.
    if exception.class != ActionController::InvalidAuthenticityToken &&
       exception.class != ActionController::RoutingError &&
       exception.class != AbstractController::ActionNotFound

      error_report = exception.backtrace.unshift(
         "#{exception.class.name}:  #{exception.message}").join("\n")
      record_error(error_report, request, session, false)
    end
  end


  # Records the given exception thrown in a browser and notifies PHR staff if
  # necessary.
  #
  # Parameters
  # * error_report - a string containing the stack trace and message of an
  #   exception that was raised in a user's browser.
  # * request - the request object for the error report request
  # * session - the user's session object
  def self.record_browser_error(exception, request, session)
    record_error(exception, request, session, true)
  end


  private

  # A hash of remote IP addresses to email addresses to which error reports
  # should be sent.
  @@ip_to_email_ = YAML.load(File.read("#{Rails.root}/config/error_email.yml"))
  
  
  # Records the given error (unless we have recently had a report from the
  # same IP address).
  #
  # Parameters:
  # * error_report - an error report, e.g. a string containing the stack trace
  #   and message of an exception.
  # * request - the request object for the error report request
  # * session - the user's session object
  # * is_browser_error - true if this error happened in a browser, and false
  #   otherwise (i.e. false if it happened on the server).
  def self.record_error(error_report, request, session, is_browser_error)
    # Log the error, if this is not a "public" system where there might
    # be PII data.
    if Rails.env == 'development' && !PUBLIC_SYSTEM
      logger.debug '------- ERROR REPORT -------'
      logger.debug error_report
    end
    remote_ip = request.remote_ip
    err_rep = SystemError.where(remote_ip: remote_ip).order('last_email_time DESC').first
    if (err_rep.nil? || Time.now - err_rep.last_email_time > 1.hour)
      url = request.fullpath[0..254] # truncated URL so it fits the field
      user_id = session[:user_id]
      # See if this exception has already been reported.
      err_rep = SystemError.where(url: url, exception: error_report).first
      email_needed = true
      if err_rep
        # Update the count, when, and user_id fields
        # Also update the remote_ip, so that value is always the latest.
        err_rep.remote_ip = remote_ip
        err_rep.user_id = user_id
        err_rep.count += 1
        # If it has been more than one day since the last email about this
        # message send another one (otherwise don't).
        if (Time.now - err_rep.last_email_time) > 1.day
          err_rep.last_email_time = Time.now
        else
          email_needed = false
        end
        err_rep.save!
      else
        # A new error.
        SystemError.create!(:user_id=>user_id,
         :url=>url, :remote_ip=>remote_ip,
         :exception=>error_report, :last_email_time=>Time.now,
         :referrer=>request.env['HTTP_REFERER'],
         :user_agent=>request.env['HTTP_USER_AGENT'],
         :is_browser_error=>is_browser_error)
      end

      if email_needed
        machine_name = `hostname`.chomp
        # Be careful not to include error messages or exception messages
        # in the email, because those might contain PII data.  The idea
        # is to give the recipient just enough information to find the full
        # report.
        
        # Figure out who to send the email to.
        email_addr = PHR_SUPPORT_EMAIL
        if Rails.env != 'development'
          remote_ip = `hostname -i`.chomp if remote_ip=='127.0.0.1'
          if @@ip_to_email_.member?(remote_ip)
            # Note that the value may be nil, meaning we suppress the email
            # (e.g. for a scanner's IP addresss).
            email_addr = @@ip_to_email_[remote_ip]
          else
            email_addr = @@ip_to_email_['default']
          end
        end

        if (email_addr) # may be nil, per note above
          DefMailer.deliver_message(email_addr, 'PHR System Error',
            "A system error has occurred on #{request.protocol}#{request.host}"+
              " (#{machine_name}).  Check the system_errors table for details.")
        end
      end
    end
  end # record_error
end
