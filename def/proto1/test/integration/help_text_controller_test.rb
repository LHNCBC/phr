require 'test_helper'

class HelpTextControllerUpdateTest < ActionDispatch::IntegrationTest
  fixtures :users
  fixtures :two_factors

  # The file name for the test help file
  TEST_FILE_NAME = 'An_Integration_Test1.html'

  # The pathname of the shared test help tile
  SHARED_HELP_PN = "#{Rails.root}/public/help/#{TEST_FILE_NAME}"

#  # The pathname of the suburban test help file
#  SUBURBAN_HELP_PN =
#    "#{Rails.root}/public/help/installation/suburban/#{TEST_FILE_NAME}"

  # The pathname of the default mode test help file
#  DEFAULT_HELP_PN =
#    "#{Rails.root}/public/help/installation/default/#{TEST_FILE_NAME}"
  DEFAULT_HELP_PN = SHARED_HELP_PN

  # The location of the real VCS lock file
  REAL_VCS_LOCK = Vcs::VCS_COMMIT_LOCK

  # The data for the installation mode text_list
  @@inst_mode_list = nil

  # The data for the text_list_items that are in the installation mode text_list.
  @@inst_mode_list_items = []

  # Loads the class variables
  def self.init_class
    dbconfig = DatabaseMethod.getConfig
    ActiveRecord::Base.establish_connection(dbconfig['development'])
    tl = TextList.find_by_list_name('help_text_installation_modes')
    @@inst_mode_list = tl.attributes
    tl.text_list_items.each {|tli| @@inst_mode_list_items << tli.attributes}
    ActiveRecord::Base.establish_connection(:test)
  end

  init_class


  def setup
    Vcs.const_set(:VCS_COMMIT_LOCK, '/tmp/test_vcs_lock')
    RestartManager.const_set(:RESTART_FILE, '/tmp/test_restart_file')
    cleanup_vcs_lock
    RestartManager.release_restart_lock
    https! # Set the request to be SSL

    cleanup_test_files
    system("#{HelpText::GIT_COMMAND} branch help_text_test; #{HelpText::GIT_COMMAND} checkout help_text_test")

    # Copy the needed text list from the development database
    TextList.where(@@inst_mode_list).destroy_all
    tl = TextList.create!(@@inst_mode_list)
    TextListItem.disable_ferret
    @@inst_mode_list_items.each do |tli|
      tl.text_list_items << TextListItem.new(tli)
    end
    TextListItem.enable_ferret
    
    # Login
    DatabaseMethod.copy_development_tables_to_test(
      ['forms', 'field_descriptions','db_table_descriptions', 'db_field_descriptions'])
  end

  
  def teardown
    cleanup_vcs_lock
    RestartManager.release_restart_lock
    restart_signal = RestartManager::RESTART_FILE
    File.delete(restart_signal) if File.exists?(restart_signal)

    # Switch to the previous branch
    system("#{HelpText::GIT_COMMAND} checkout -; #{HelpText::GIT_COMMAND} branch -D help_text_test")
    Vcs.const_set(:VCS_COMMIT_LOCK, REAL_VCS_LOCK)
  end


  # Cleans up any test help files that were left around.
  def cleanup_test_files
    if File.exists?(DEFAULT_HELP_PN)
      system("rm -f #{DEFAULT_HELP_PN}")
    end
  end


  # Cleans up the VCS lock if it was left around
  def cleanup_vcs_lock
    begin
    Vcs.release_vcs_lock
    rescue # will raise an exception if we didn't have the lock; that's okay
    end
  end


  def test_login
    # Make sure the user is redirected to the login page if they are not
    # an admin user.
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:PHR_Test).name,
                            :password_1_1=>'A password'}}
    post '/help_text'
    assert_redirected_to('/accounts/login')
  end


  def test_new_shared_file
    # Login
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
                            :password_1_1=>'A password'}}

    # Move from the help_text management page to the new help text page.
    post '/help_text', params: {:fe=>{:mode_C=>'1'}, :new=>1}
    assert_redirected_to('/help_text/new')
    follow_redirect!

    # Check handling of problems with the file name.
    # Blank file name
    post '/help_text/new', params: {:fe=>{:help_html=>'Test1', :mode_C=>'1'}}
    assert_response(:success)
    assert(flash[:error])

    # Check file names with bad characters
    post '/help_text/new', params: {:fe=>{:file_name=>'/a',
      :help_html=>'Test1', :mode_C=>'1'}}
    assert_response(:success)
    assert(flash[:error])
    post '/help_text/new', params: {:fe=>{:file_name=>'..',
      :help_html=>'Test1', :mode_C=>'1'}}
    assert_response(:success)
    assert(flash[:error])

    # Check a file name of an existing file
    post '/help_text/new', params: {:fe=>{:file_name=>'general.shtml',
      :help_html=>'Test1', :mode_C=>'1'}}
    assert_response(:success)
    assert(flash[:error])

    # Create a help file
    post '/help_text/new', params: {:fe=>{:file_name=>TEST_FILE_NAME,
      :help_html=>'Test1', :mode_C=>'1'}}
    assert_redirected_to('/help_text')
    follow_redirect!
    assert(flash[:error].nil?)
    assert(flash[:notice])
    pn = "#{Rails.root}/public/help/#{TEST_FILE_NAME}"
    assert(File.exists?(pn))
    assert_equal('Test1', File.read(pn))

  end


#  def test_new_suburban_file
#    # Login
#    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
#
#   post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
#                            :password_1_1=>'A password'}}
#                        
#    # Create a Suburban-specific help file
#   post '/help_text/new', params: {:fe=>{:file_name=>TEST_FILE_NAME,
#      :help_html=>'Test1', :mode_C=>'3'}}
#    assert_redirected_to('/help_text')
#    follow_redirect!
#    assert(flash[:error].nil?)
#    assert(flash[:notice])
#    # Two files should have been created and checked in (for both installation
#    # modes).  Also, the new file should have been installed into the shared
#    # help directory.
#    [DEFAULT_HELP_PN, SUBURBAN_HELP_PN, SHARED_HELP_PN].each do |pn|
#      assert(File.exists?(pn), pn)
#      assert_equal('Test1', File.read(pn), pn)
#    end
#  end

  def test_edit_shared_file
    # Login
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
                            :password_1_1=>'A password'}}

    # Create a help file
    original_text = 'Test1'
    post '/help_text/new', params: {:save=>1, :fe=>{:file_name=>TEST_FILE_NAME,
      :help_html=>original_text, :mode_C=>'1'}}
    follow_redirect!
    assert(File.exists?(SHARED_HELP_PN))

    # Find it.
    ht = HelpText.find_by_mode_and_file_name('1', TEST_FILE_NAME)

    # Post an edit, but with a wrong file name
    revised_text = 'Revised Text'
    post "/help_text/edit/#{ht.code}", params: {:fe=>{:file_name=>'other name',
      :help_html=>revised_text}}
    assert_response :success
    assert(flash[:error])
    assert(flash[:notice].nil?)
    assert_equal(original_text, File.read(SHARED_HELP_PN))

#    # Post an edit, but with a wrong code
#   post "/help_text/edit/2_1", params: {:fe=>{:file_name=>TEST_FILE_NAME,
#      :help_html=>revised_text}}
#    assert_response :success
#    assert(flash[:error])
#    assert(flash[:notice].nil?)
#    assert_equal(original_text, File.read(SHARED_HELP_PN))

    #post an edit with the right file name and code
    post "/help_text/edit/#{ht.code}", params: {:fe=>{:file_name=>TEST_FILE_NAME,
      :help_html=>revised_text}}
    assert_redirected_to('/help_text')
    follow_redirect!
    assert(flash[:error].nil?)
    assert(flash[:notice])
    assert_equal(revised_text, File.read(SHARED_HELP_PN))
  end

#  def test_edit_suburban_file
#    # Login
#    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
#   post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
#                            :password_1_1=>'A password'}}
#
#    # Test an edit while in the default mode
#    pre_test_inst_mode = InstallationChange.installation_name
#    if pre_test_inst_mode != 'default'
#      # Put the system into the default mode.  When we create the help
#      # file, it should not get copied into the shared help directory.
#      system("rake def:installation name=default")
#    end
#
#    # Create a help file
#    original_text = 'Test1'
#   post '/help_text/new', params: {:save=>1, :fe=>{:file_name=>TEST_FILE_NAME,
#      :help_html=>original_text, :mode_C=>'3'}}
#    follow_redirect!
#    assert(File.exists?(SUBURBAN_HELP_PN))
#
#    # Find it.
#    ht = HelpText.find_by_mode_and_file_name('3', TEST_FILE_NAME)
#
#    # Post an edit
#    revised_text = 'Revised Text'
#    post "/help_text/edit/#{ht.code}", params: {:fe=>{:file_name=>TEST_FILE_NAME,
#      :help_html=>revised_text}}
#    assert_redirected_to('/help_text')
#    follow_redirect!
#    assert(flash[:error].nil?)
#    assert(flash[:notice])
#    assert_equal(revised_text, File.read(SUBURBAN_HELP_PN))
#    # Make sure the default mode's file is still the original text.
#    assert_equal(original_text, File.read(DEFAULT_HELP_PN))
#    # Make sure the installed file is still the original text
#    assert_equal(original_text, File.read(SHARED_HELP_PN))
#    # Now put the system into suburban mode and try again.
#    system("rake def:installation name=suburban") || raise('rake failed')
#    revised_text = 'Newly Revised Text'
#   post "/help_text/edit/#{ht.code}", params: {:fe=>{:file_name=>TEST_FILE_NAME,
#      :help_html=>revised_text}}
#    assert_redirected_to('/help_text')
#    follow_redirect!
#    assert(flash[:error].nil?)
#    assert(flash[:notice])
#    assert_equal(revised_text, File.read(SUBURBAN_HELP_PN))
#    # Make sure the default mode's file is still the original text.
#    assert_equal(original_text, File.read(DEFAULT_HELP_PN))
#    # Make sure the installed file has the revised text
#    assert_equal(revised_text, File.read(SHARED_HELP_PN))
#
#    # If we were not in suburban mode originally, go back to the default mode
#    if pre_test_inst_mode != 'suburban'
#      # Put the system into the default mode.  When we create the help
#      # file, it should not get copied into the shared help directory.
#      system("rake def:installation name=default")
#    end
#  end


  def test_delete_shared_file
 
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
                            :password_1_1=>'A password'}}

    # Create a help file
    post '/help_text/new', params: {:fe=>{:file_name=>TEST_FILE_NAME,
      :help_html=>'Test1', :mode_C=>'1'}}
    follow_redirect!
    assert(File.exists?(SHARED_HELP_PN))

    # Test deleting the file, but without a file selected
    ht = HelpText.find_by_mode_and_file_name('1', TEST_FILE_NAME)
    ht_code = ht.code
    post '/help_text', params: {:delete=>1, :fe=>{:one=>:two}}
    assert_response(:error)

    # Test deleting the file, but use a blank file name
    post '/help_text', params: {:delete=>1, :fe=>{:file_name_C=>ht_code}}
    assert_response(:success)
    assert(flash[:error])

    # Test deleting the file, but with a missing file code
    file_name_and_mode = "#{TEST_FILE_NAME} (#{ht.get_inst_mode_label})"
    post '/help_text', params: {:delete=>1, :fe=>{:file_name=>file_name_and_mode}}
    assert_response(:error)

    # Test deleting the file, but use the wrong file name
    post '/help_text', params: {:delete=>1,
      :fe=>{:file_name_C=>ht_code, :file_name=>'other_name'}}
    assert_response(:success)
    assert(flash[:error])

    # Delete the help file
    post '/help_text', params: {:delete=>1,
      :fe=>{:file_name_C=>ht_code, :file_name=>file_name_and_mode}}
    assert_response(:success)
    assert(flash[:error].nil?)
    assert(flash[:notice])
    assert(!File.exists?(SHARED_HELP_PN))
  end

#  def test_delete_suburban_file
#    # Login
#    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
#   post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
#                            :password_1_1=>'A password'}}
#    
#    # Create a help file
#    original_text = 'Test1'
#   post '/help_text/new', params: {:save=>1, :fe=>{:file_name=>TEST_FILE_NAME,
#      :help_html=>original_text, :mode_C=>'3'}}
#    follow_redirect!
#    assert(File.exists?(SUBURBAN_HELP_PN))
#    assert(File.exists?(DEFAULT_HELP_PN))
#    assert(File.exists?(SHARED_HELP_PN))
#
#    # Delete it
#    ht = HelpText.find_by_mode_and_file_name('3', TEST_FILE_NAME)
#    file_name_and_mode = "#{TEST_FILE_NAME} (#{ht.get_inst_mode_label})"
#   post '/help_text', params: {:delete=>1,
#      :fe=>{:file_name_C=>ht.code, :file_name=>file_name_and_mode}}
#    assert_response(:success)
#    assert(flash[:error].nil?)
#    assert(flash[:notice])
#    # I am undecided as to whether the other mode's installation specific file
#    # should also be deleted; for now we leave it alone and let the user delete
#    # that one separately.
#    assert(!File.exists?(SUBURBAN_HELP_PN))
#    assert(File.exists?(DEFAULT_HELP_PN))
#    assert(!File.exists?(SHARED_HELP_PN))
#
#    # Now also delete the other installation specific file, to make sure
#    # that works.
#    ht = HelpText.find_by_mode_and_file_name('2', TEST_FILE_NAME)
#    file_name_and_mode = "#{TEST_FILE_NAME} (#{ht.get_inst_mode_label})"
#   post '/help_text', params: {:delete=>1,
#      :fe=>{:file_name_C=>ht.code, :file_name=>file_name_and_mode}}
#    assert_response(:success)
#    assert(flash[:error].nil?)
#    assert(flash[:notice])
#    assert(!File.exists?(DEFAULT_HELP_PN))
#  end

  def test_new_with_vcs_lock
    # Login
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
                            :password_1_1=>'A password'}}
    # Re-create the file, but check the behavior when the VCS lock is in place
    assert(Vcs.lock_if_available)
    post '/help_text/new', params: {:fe=>{:file_name=>TEST_FILE_NAME,
      :help_html=>'Test2', :mode_C=>'1'}}
    assert_redirected_to('/help_text')
    follow_redirect!
    assert(flash[:error].nil?)
    assert(flash[:notice])
    assert(!File.exists?(SHARED_HELP_PN)) # The files should not exist yet.
    Vcs.release_vcs_lock
    sleep(Vcs::LOCK_CHECK_INTERVAL + 2) # Wait for the file to be written
    assert(File.exists?(SHARED_HELP_PN), SHARED_HELP_PN)
    assert_equal('Test2', File.read(SHARED_HELP_PN), SHARED_HELP_PN)
  end


  def test_new_with_restart_lock
    # Login
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
                            :password_1_1=>'A password'}}
    # Re-create the file, but check the behavior when the restart lock is in place
    assert(RestartManager.lock_if_available)
    post '/help_text/new', params: {:fe=>{:file_name=>TEST_FILE_NAME,
      :help_html=>'Test2', :mode_C=>'1'}}
    assert_redirected_to('/help_text')
    follow_redirect!
    assert(flash[:error].nil?)
    assert(flash[:notice])
    assert(!File.exists?(SHARED_HELP_PN)) # The file should not exist yet.
    RestartManager.release_restart_lock
    sleep(Vcs::LOCK_CHECK_INTERVAL + 2) # Wait for the file to be written
    assert(File.exists?(SHARED_HELP_PN), SHARED_HELP_PN)
    assert_equal('Test2', File.read(SHARED_HELP_PN), SHARED_HELP_PN)
  end


  def test_new_with_restart_requested
    assert(!File.exists?(SHARED_HELP_PN)) # The file should not exist yet.
    # Login
    cookies['phr_user'] = '3f0df575eda55d1b0bf59d23613d7a6e02723bc8a8dabe709876e3a1ca0afb81'
    post '/accounts/login', params: {:fe=>{:user_name_1_1=>users(:phr_admin).name,
                            :password_1_1=>'A password'}}
    # Test what happens if the user tries to save a new file when a restart
    # has been been requested
    RestartManager.request_restart
    restart_signal = RestartManager::RESTART_FILE
    assert(File.exists?(restart_signal))
    post '/help_text/new', params: {:fe=>{:file_name=>TEST_FILE_NAME,
      :help_html=>'Test2', :mode_C=>'1'}}
    assert_response :success
    assert(flash[:error]) # should say the user should try later
    assert(flash[:notice].nil?)
    assert(File.exists?(restart_signal))
    assert(!File.exists?(SHARED_HELP_PN)) # The file should still not exist yet.
    File.delete(restart_signal)
  end


  # Tests for a particular error that happened with the save code, in which
  # if an exception was thrown during the save, the system left the VCS and
  # restart locks in place.  This could be a unit test, except that it needs to
  # be run on a side branch like the other methods here.
  def test_save_error
    # Force a save error, by redefining the save_and_check_in method.
    HelpText.class_eval do
      alias_method :old_save, :save_and_check_in
      def save_and_check_in(email=nil)
        raise 'save error'
      end
    end

    # Preconditions - Make sure the locks aren't present
    assert !RestartManager.is_locked?
    vcs_lock_file = Vcs.get_vcs_lock_file_path
    assert !File.exists?(vcs_lock_file)
    err = nil
    begin
      ht = HelpText.create('file_name', 'help_html', 'mode_code')
    rescue RuntimeError => e
      err = e
    end

    # Assert we did not catch an exception.  (The one we created should have
    # been caught inside HelpText.)
    assert err.nil?
    # Assert that the locks are gone.
    assert !RestartManager.is_locked?
    assert !File.exists?(vcs_lock_file)

    # Put the HelpText class back as it was.
    HelpText.class_eval <<-END_EVAL2
      alias_method :save_and_check_in, :old_save
    END_EVAL2
  end

end
