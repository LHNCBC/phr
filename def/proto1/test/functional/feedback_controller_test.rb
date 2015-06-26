require 'test_helper'

class FeedbackControllerTest < ActionController::TestCase

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL

    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items'])
  end


  def test_new
    page_views = ['basic', 'default']
    page_views.each do |page_view|
      # Feedback form
      session_data = {:cur_ip=>'127.0.0.1'}
      get :new, {}, session_data
      assert_response :success, page_view
      assert @response.body.index('action="'+feedback_path)
      assert !@response.body.index('action="'+contact_us_path)

      # Contact form
      get :new, {:type=>'contact_us'}, session_data
      assert_response :success, page_view
      assert @response.body.index('action="'+contact_us_path)
      assert !@response.body.index('action="'+feedback_path)
    end
  end


  def test_create
    # Multiple cases to test:
    # basic mode/standard mode
    # feedback/contact form
    # errors/good submission

    page_views = ['basic', 'default']
    page_views.each do |page_view|
      # Form blank.
      session_data = {:cur_ip=>'127.0.0.1', :page_view=>page_view}
      form_types = ['contact_us', nil]
      form_types.each do |type|
        form = type ? 'contact' : 'feedback'
        form_data = {:fe=>{:contact_comment_1=>''}, :type=>type}
        # Use Ajax only for the standard mode's feedback page
        if page_view == 'default' && type == 'feedback'
          xhr :post, :create, form_data, session_data
        else
          post :create, form_data, session_data
        end
        err_msg = "#{page_view}, #{form}"
        assert_response :success, err_msg
        assert error_message_present, err_msg
      end

      # Feedback form, comment not blank.
      [:contact_comment_1, :most_liked_1, :least_liked_1].each do |field|
        form_data = {:fe=>{field=>'feedback_controller_test.rb, test_create'}}
        if page_view == 'default'
          xhr :post, :create, form_data, session_data
          assert @response.body=''
        else
          post :create, form_data, session_data
          err_msg = "#{page_view}, #{field}"
          assert_redirected_to phr_records_path, err_msg
          assert !error_message_present, err_msg
        end
      end

      # Contact form, comment not blank.  This form does not use Ajax in the standard mode,
      # because it is not in a popup.
      form_data = {:fe=>{:contact_comment_1=>'feedback_controller_test.rb, test_create'},
        :type=>'contact_us'}
      post :create, form_data, session_data
      assert !error_message_present, page_view
      assert_redirected_to '/'
    end
  end


  # Returns true if an response contains an error message.
  def error_message_present
    !@response.body.index('forgot').nil?
  end
end
