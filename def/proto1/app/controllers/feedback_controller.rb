# A class for managing feedback from the user.  This
# handles both the "PHR support" and "feedback" forms.
class FeedbackController < ApplicationController
  helper FormHelper

  # Displays a form for entering feedback
  def new
    render_requested_form
  end


  # Handles newly received feedback.  For XHR requests, any errors will be returned.
  def create
    @page_errors = []
    form_params = params[:fe]
    # Require at least one piece of useful information
    if !form_params[:contact_comment_1].blank? ||
        !form_params[:most_liked_1].blank? ||
        !form_params[:least_liked_1].blank?

      fields_for_email = [:con_name, :con_email, :con_phone,
        :feedback_type, :issue_page_url, :most_liked,
        :least_liked, :contact_comment]
      template_data = {}
      fields_for_email.each do |fn|
        template_data[fn] = form_params[fn.to_s+'_1']
      end
      if !NO_EMAIL_IPS.member?(request.remote_ip)
        # Send the email in a new thread so the response does not need to wait
        # for the email to be sent.
        Thread.new do
          DefMailer.contact_support(PHR_SUPPORT_EMAIL, template_data,
            request.host).deliver_now
        end
      end
      if request.xhr?
        render :plain=>'' # i.e. no errors
      else
        flash[:notice] = "Thank you for your feedback."
        is_contact_form = params[:type]=='contact_us'
        if is_contact_form
          redirect_to '/'
        else
          redirect_to default_html_mode? ? profiles_path : phr_records_path
        end
      end
    else
      @page_errors << 'You forgot to enter your comments.'
      if request.xhr?
        render :plain=>@page_errors.join('  ')
      else
        render_requested_form
      end
    end
  end


  private

  # Renders either the contact or feedback form
  def render_requested_form
    if params[:type]=='contact_us'
      render_contact_form
    else
      render_feedback_form
    end
  end


  # Renders the contact us form
  def render_contact_form
    @action_url = Rails.application.routes.url_helpers.contact_us_path
    form_name = 'contact_support'
    if non_default_html_mode?
      load_basic_vars(form_name)
      render :template=>'basic/feedback/contact_us', :layout=>'basic'
    else
      render_form(form_name)
    end
  end


  # Renders the feedback form
  def render_feedback_form
    @action_url = '/feedback'
    @action_url += '?from=popup' if params['from'] == 'popup'
    form_name = 'feedback'
    if non_default_html_mode?
      load_basic_vars(form_name)
      @page_url = request.referrer
      render :template=>'basic/feedback/feedback', :layout=>'basic'
    else
      @data_hash= {'contact_grp'=>{'issue_page_url'=>request.referrer}}
      render_form(form_name)
    end
  end


  # Loads variables needed for the basic HTML views.
  #
  # Parameters:
  # * form_name - the name of the form
  def load_basic_vars(form_name)
    @fds = {} # hash from names to field descriptions
    form = Form.find_by_form_name(form_name)
    form.field_descriptions.each {|fd| @fds[fd.target_field] = fd}
    @page_title = form.form_title
  end

end
