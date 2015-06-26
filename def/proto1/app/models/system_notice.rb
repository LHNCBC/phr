# A class for managing system notices that get shown to the user.
class SystemNotice
  # Note:  These notices are currently just stored on the file system.  It
  # might be that we should move them to the database, but I want to wait
  # until we see what other kinds of information/messages need to be sent
  # periodically to the client.
  # The location of notices (in the file system) that get displayed on pages.
  NOTICE_DIR = "#{Rails.root}/public"
  # The pathname of the notice that appears on the login page
  LOGIN_NOTICE_PATHNAME = "#{NOTICE_DIR}/loginNotice.txt"
  # The pathname of the urgent notice that appears on all pages
  URGENT_NOTICE_PATHNAME = "#{NOTICE_DIR}/urgentNotice.txt"

  # Returns the text of the current login page notice, or nil if there isn't
  # any.
  def self.login_page_notice
    rtn = nil
    if (File.exists?(LOGIN_NOTICE_PATHNAME))
      rtn = File.readlines(LOGIN_NOTICE_PATHNAME).join
    end
    return rtn
  end

  # Returns the text of the current urgent user message, or nil if there isn't
  # one newer than the "since" time.
  #
  # Parameters:
  # * since - the epoch time (in ms) of the oldest message that should be
  #   returned.
  #   (If the message is older than this, it won't be returned.) If this is
  #   nil (the default) then if present the urgent message will be returned
  #   regardless of its age.
  def self.urgent_notice(since=nil)
    rtn = nil
    if (File.exists?(URGENT_NOTICE_PATHNAME) &&
          (!since || (File.mtime(URGENT_NOTICE_PATHNAME).to_i*1000)>=since))
      rtn = File.readlines(URGENT_NOTICE_PATHNAME).join
    end
  end
end
