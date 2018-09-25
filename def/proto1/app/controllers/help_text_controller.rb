require 'restart_manager'

class HelpTextController < ApplicationController
  before_action :admin_authorize

  def index
    redirected = false
    if request.post?
      if params[:new]
        session[:installation_mode_code] = params[:fe][:mode_C]
        redirect_to('/help_text/new')
        redirected = true
      elsif params[:edit]
        redirect_to("/help_text/edit/#{params[:fe][:file_name_C]}")
        redirected = true
      elsif params[:delete]
        # To make the integration test work, we clear the flash here.
        flash.now[:notice]=flash.now[:error]=nil if Rails.env=='test'
        delete
      end
    end

    if (!redirected)
      @user_name = User.find_by_id(session[:user_id]).name
      @title = 'Help Text Management'

      # Get the installation mode names and codes, and also create a list
      # of files for the modes.
      @mode_names = []
      @mode_codes = []
      TextList.find_by_list_name('help_text_installation_modes'
        ).text_list_items.each do |tli|
        @mode_names << tli.item_text
        @mode_codes << tli.code
      end

      @file_names = []
      @file_name_codes = []
      @mode_codes.each_with_index do |mc, i|
        files_for_mode = HelpText.get_help_for_mode(mc)
        mode_name = @mode_names[i]
        files_for_mode.each do |f|
          @file_names << file_and_mode_label(f.file_name, mode_name)
          @file_name_codes << f.code
        end
      end

      render(:layout=>'nonform')
    end
  end


  # Handles the creation of a new help text
  def new
    user = User.find_by_id(session[:user_id])
    redirected = false
    all_file_names = HelpText.get_all_file_names
    if request.post?
      # Using instance variables for things we'll need for redisplaying
      # the form if there is an error.
      @file_name = params[:fe][:file_name]
      @help_html = params[:fe][:help_html]
      @installation_mode_code = params[:fe][:mode_C]
      if @file_name.blank?
        flash.now[:error] = 'You must enter a file name.'
      elsif @file_name !~ /\A[\w\._]+\z/
        flash.now[:error] = 'The filename can only contain letters, numbers, '+
          'and the period and underscore characters.'
      elsif all_file_names.index(@file_name) # Make sure filename is unique
        flash.now[:error] = 'The file name matches one that already exists.  '+
          'Please enter a unique file name.'
      elsif RestartManager.restart_requested?
        flash.now[:error] = 'A restart of the system has been requested.  '+
          'Please wait one minute before trying again.'
      else
        ht = HelpText.create(@file_name, @help_html, @installation_mode_code,
          user.email)
        msg = ht.error_msg
        if msg && !ht.change_pending?
          flash.now[:error] = msg
        else # success, or the save hasn't happened yet
          if !msg
            if ht.is_shared?
              msg = "Your new help file #{@file_name} has been saved."
            else
              msg = "You new help file #{@file_name} has been saved.  Because "+
                "it was not a shared help file, a copy has been saved for each"+
                " non-shared installation mode."
            end
          end
          flash[:notice] = msg
          redirect_to('/help_text')
          redirected = true
        end
      end
    end

    if !redirected
      if !request.post?
        @installation_mode_code = session[:installation_mode_code]
        @help_html = 'Enter your HTML here, after choosing a file name above.'
      end
      @user_name = user.name
      @title = 'New Help Text'
      @installation_mode = HelpText.get_inst_mode_label(@installation_mode_code)
      @unique_values_by_field = {
        'file_name' => all_file_names
      }
      render(:layout=>'nonform')
    end
  end


  # list all existing help files on one page
  def list
    @common_files, @mode_files = HelpText.list_files
    render(:layout=>nil)
  end


  # Handles the editing of an existing help text
  def edit
    user = User.find_by_id(session[:user_id])
    help = HelpText.find(params[:id])
    redirected = false
    if request.post?
      help.file_text = params[:fe][:help_html]
      posted_file_name = params[:fe][:file_name]
      if (posted_file_name.blank?)
        flash.now[:error] = 'Missing file name.'  # should not normally happen
      elsif posted_file_name != help.file_name
        flash.now[:error] = 'The page you are editing is outdated.  '+
          'Please save your work elsewhere, return to the <a href="/help_text"'+
          '>Help Text Management</a> page, and re-select this file for '+
          'editing.'
      elsif RestartManager.restart_requested?
        flash.now[:error] = 'A restart of the system has been requested.  '+
          'Please wait one minute before trying again.'
      else
        # Save the file
        saved = help.save(user.email)
        if(!saved && !help.change_pending?)
          flash.now[:error] = help.error_msg
        else
          flash[:notice] = saved ?
            "Your changes to file #{help.file_name} have been saved." :
            help.error_msg
          redirect_to('/help_text')
          redirected = true
        end
      end
    end

    if !redirected
      @user_name = user.name
      @title = 'Edit Help Text'
      @code = params[:id]
      @file_name = help.file_name
      @help_html = help.file_text
      @installation_mode = help.get_inst_mode_label
      @help_header =
        HelpText.find_by_mode_and_file_name('1', 'help_header.shtml').file_text
      @help_footer =
        HelpText.find_by_mode_and_file_name('1', 'help_footer.shtml').file_text
      @edit = true
      render(:layout=>'nonform', :action=>'new')
    end
  end

  private

  # Deletes a help file.  This is private, because it is expected to be called
  # by the index method.
  def delete
    raise 'Error-- POST requests only' if !request.post?
    user = User.find_by_id(session[:user_id])
    file_code = params[:fe][:file_name_C]
    help = HelpText.find(file_code)
    posted_file_name = params[:fe][:file_name]
    expected_file_name =
      file_and_mode_label(help.file_name, help.get_inst_mode_label)

    if (posted_file_name.blank? || file_code.blank?)
      flash.now[:error] = 'Missing file name.'  # should not normally happen
    elsif posted_file_name != expected_file_name
      flash.now[:error] = 'The help files have changed, making your page '+
        'outdated.  Please reselect the file you wish to delete and try again.'
    else
      deleted = help.destroy(user.email)
      if (!deleted && !help.change_pending?)
        flash.now[:error] = help.error_msg
      else
        flash.now[:notice] = deleted ?
          flash.now[:notice] = "File #{help.file_name} has been deleted." :
          help.error_msg
      end
    end
  end


  # Returns the form of the help file name shown in the list on the index page.
  #
  # Parameters
  # * file_name - the file name (without the path)
  # * mode_name - the user friendly label for the installation mode
  def file_and_mode_label(file_name, mode_name)
    "#{file_name} (#{mode_name})"
  end
end
