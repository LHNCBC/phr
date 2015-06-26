class PageTimerController < ApplicationController
  before_filter :only_allow_local_ips

  # A before filter to only allow access from local IPs.
  def only_allow_local_ips
    redirect_to '/' if request.remote_ip !~ /^130\.14/
  end


  # The relative URL of the profile being timed.
  TIMED_PAGE = '/profiles/772695c5ee;edit' # also see PageLoadTime#@@page_url

  # Opens a page that times the loading of the PHR page.
  def time_phr
    render :template => 'page_timer/time_phr',:formats => [:rhtml], :handlers =>[:erb]
  end
  
  # Saves a new load time record
  def save_load_time
    @page_url = params[:url]
    @user_agent = request.env['HTTP_USER_AGENT']
    @remote_ip = request.remote_ip

    load_times = PageLoadTime.get_load_times
    #logger.info ("<<<<<<<<<<<  PageTimerController#save_load_time: "+ load_times.inspect)

    if PageLoadTime.create(:url=>@page_url, :remote_ip=>@remote_ip,
     :user_agent=>@user_agent,
     :when_recorded=>Time.new, :load_time=>params[:load_time].to_i,
     :apache_time=>load_times["apache_time"], 
     :rails_time=>load_times["rails_time"], 
     :view_time=>load_times["view_time"],
     :db_time=>load_times["db_time"], :rails_mode=>Rails.env)
      render :text => "Load time saved!", :status => 200
    else
      render :text => "Saving load time failed.", :status => 400
    end


    # Do some data analysis, and send the results back
    if false # This code will be replace by JQuery Flot, but not now.
    require 'rsruby'
    r = RSRuby.instance
    user_load_time_recs =
      PageLoadTime.find_all_by_url_and_user_agent_and_remote_ip(
        @page_url, @user_agent, @remote_ip)
    @user_load_time_hist = '/userLoadTimeHist.png'
    @user_load_time_data_count, @user_load_time_mean, @user_load_time_SE =
      load_time_stats(r, user_load_time_recs, @user_load_time_hist,
                      'Data for your browser')

    # Now drop the user_agent from the search
    ip_load_time_recs =
      PageLoadTime.find_all_by_url_and_remote_ip(@page_url, @remote_ip)
    @ip_load_time_hist = '/ipLoadTimeHist.png'
    @ip_load_time_data_count, @ip_load_time_mean, @ip_load_time_SE =
      load_time_stats(r, ip_load_time_recs, @ip_load_time_hist,
            'Data for your machine')
    
    # Now drop the remote IP from the search
    load_time_recs = PageLoadTime.find_all_by_url(@page_url)
    @load_time_hist = '/loadTimeHist.png'
    @load_time_data_count, @load_time_mean, @load_time_SE =
      load_time_stats(r, load_time_recs, @load_time_hist,
            'All accesses to this website')
    end
  end # save_load_time
  
  def page_load_time_chart
    @page_url = PageLoadTime.get_page_url
    @chart_data_array = PageLoadTime.get_chart_data
    @unique_ips = PageLoadTime.unique_ips
    @unique_modes = PageLoadTime.unique_modes
    @unique_agents = PageLoadTime.unique_agents
    render :layout => "page_timer.rhtml"
  end

  # get the load time data for the Plot charts
  def get_chart_data
    # Is this an XmlHttpRequest request?
    if (!request.xhr?)
      # Go to the "Access Denied" page
      render(:file=>"#{Rails.root}/public/403.html", :status=>403)
    else

      # get parameters
      opt = JSON.parse(get_param(:opt))
      modes = opt['modes']
      ips = opt['ips']
      agents = opt['agents']
      
      chart_data_array = PageLoadTime.get_chart_data(modes, ips, agents)

      render(:text => chart_data_array.to_json)
    end
  end
  
  private
  
  
  # Generates statistics for the given load time data
  #
  # Parameters
  # * r - the R instance
  # * file_path - a file path relative to the public directory for the image
  #   file that will be saved.  The images will be png's.
  # * load_times - the PageLoadTime records to generate statistics for
  # * title - the title for the histogram
  def load_time_stats(r, load_times, file_path, title)
    mean = nil
    sd = nil
    if (load_times.size > 1)
      times = []
      load_times.each {|t| times << t.load_time}
      make_hist(r, times, file_path, title)
      mean = r.mean(times).round
      sd = r.sd(times).round
    end
    return load_times.size, mean, sd
  end

  
  # Plots a histogram of the given data
  #
  # Parameters
  # * r - the R instance
  # * data - the set of data to plot
  # * file_path - a file path relative to the public directory for the image
  #   file that will be saved.  The images will be png's.
  # * title - the title for the histogram
  def make_hist(r, data, file_path, title)
    r.bitmap('public' + file_path, type='png256', height=4,
      width=4, res=72, 14)
    r.hist(data, :main=>title, :xlab=>'Value')
    r.dev_off.call
  end
  
end
