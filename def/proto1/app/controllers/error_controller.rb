# A controller for error reports from the browser
class ErrorController < ApplicationController
  # Handles an error report from the browser.
  def new
    SystemError.record_browser_error(params[:message], request, session)
    render :text=>'' # We don't need to report anything back.
  end
end
