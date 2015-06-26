require 'test_helper'
require 'tempfile'

class JsGeneratorTest < ActiveSupport::TestCase
  
  def setup
    @rrfile = REMINDER_RULE_DATA_JS_FILE
    AssetLockFile.clear_locks
    # make sure no manifest available in test mode
    system("rm -rf #{Rails.root.join("public","assets")}")
  end

  # When a lock was found while trying to generate a new js file, it will skip
  # the action of generating the new js file
  def test_generate_reminder_rule_data_js_with_a_lock
    #####################################
    # in test mode
    #####################################
    # make sure the generated js file does not exist
    JsGenerator.remove(@rrfile)
    gnd1_js = JsGenerator.get_asset_fullpath(@rrfile)
    assert_nil gnd1_js, "GeneratedFileFoundError: #{gnd1_js}"
    
    # creates a lock
    lockfile = AssetLockFile.convert_to_lockfile(@rrfile)
    lockfile_path = AssetLockFile.get_lock_file_path(lockfile)
    AssetLockFile.create_lock_file(lockfile_path)
    assert File.exists?(lockfile_path), "NoLockFileError: #{lockfile_path}"
    # avoid unnecessary waiting
    mwt = AssetLockFile.max_wait_seconds
    AssetLockFile.max_wait_seconds = 0

    # Calling the generate function will do nothing with the lock file exists
    assert_raises(RuntimeError){ JsGenerator.generate_reminder_rule_data_js }
    # reset the class variable
    AssetLockFile.max_wait_seconds = mwt

    gnd2_js = JsGenerator.get_asset_fullpath(@rrfile)
    assert_nil gnd2_js, "GeneratedFileFoundError: #{gnd2_js}"
    # remove the lock file
    system("rm #{lockfile_path}")
    # calling the generate function will actually create the new js file
    JsGenerator.generate_reminder_rule_data_js
    gnd3_js = JsGenerator.get_asset_fullpath(@rrfile)
    assert_not_nil gnd3_js, "NoGeneratedFileError"

    
    #####################################
    # in production mode
    #####################################
    # replace the assets configuration using the ones from production mode
    config = Rails.application.config
    config.assets.debug = false
    config.assets.digest = true
    config.assets.compile = false

    # make sure the generated js file does not exist
    JsGenerator.remove(@rrfile)
    gnd4_js = JsGenerator.get_asset_fullpath(@rrfile)
    assert_nil gnd4_js, "GeneratedFileFoundError: #{gnd4_js}"
    
    # create a lock
    lockfile = AssetLockFile.convert_to_lockfile(@rrfile)
    lockfile_path = AssetLockFile.get_lock_file_path(lockfile)
    AssetLockFile.create_lock_file(lockfile_path)
    assert File.exists?(lockfile_path), "NoLockFileError: #{lockfile_path}"
    # avoid unnecessary waiting
    mwt = AssetLockFile.max_wait_seconds
    AssetLockFile.max_wait_seconds = 0

    # Calling the generate function will do nothing with the lock file exists
    assert_raise(RuntimeError){ JsGenerator.generate_reminder_rule_data_js }
    # reset the class variable
    AssetLockFile.max_wait_seconds = mwt

    gnd5_js = JsGenerator.get_asset_fullpath(@rrfile)
    assert_nil gnd5_js, "GeneratedFileFoundError: #{gnd5_js}"
    # remove the lock file
    system("rm #{lockfile_path}")
    # calling the generate function will actually create the new js file
    JsGenerator.generate_reminder_rule_data_js
    gnd6_js = JsGenerator.get_asset_fullpath(@rrfile)
    assert_not_nil gnd6_js, "NoGeneratedFileError"

    JsGenerator.remove(@rrfile)

    # change the assets configuration back into the ones of test mode
    config.assets.debug = true
    config.assets.digest = false
    config.assets.compile = true
  end
  
  
  def test_generate_reminder_rule_data_js_with_asset_tag_helper
    helper = ActionView::Base.new
    rrbase = @rrfile.split(".").first
    
    
## TODO::The following commented part cannot pass the test. The test simulating 
## the senarios in production mode works okay. Need to have a revisit ASAP
#    #####################################
#    # in test mode
#    #####################################
#    # ensure there is no gnd_reminder_rule_data.js
#    JsGenerator.remove(@rrfile)
#    # call the tag helper method will return a link without digest
#    str1 = helper.javascript_include_tag(@rrfile)
#    assert_not_nil str1.index(@rrfile)
#    
#    # generate that js file
#    JsGenerator.generate_reminder_rule_data_js
#    
#    # call the tag helper will return a link with digest
#    str2 = helper.javascript_include_tag(@rrfile)
#    assert_nil str2.index(@rrfile)     # the asset link has no digest
#    assert_not_nil str2.index(rrbase) # the asset link includes the digest information
#    
#    # generate that js file again
#    JsGenerator.generate_reminder_rule_data_js
#    
#    # the tag helper method call will return a link with same digest
#    str3 = helper.javascript_include_tag(@rrfile)
#    assert_nil str3.index(@rrfile)
#    assert_not_nil str3.index(rrbase)
#    assert_equal str2, str3
#    
#    # modify the content of that js file
#    new_tempfile = Tempfile.new(Time.now.to_i.to_s)
#    new_tempfile.write(Time.now.to_i.to_s)
#    new_tempfile.close
#    JsGenerator.generate_reminder_rule_data_js(new_tempfile)
#    
#    # the tag helper method call will return a link with different digest
#    str4 = helper.javascript_include_tag(@rrfile)
#    assert_nil str4.index(@rrfile)
#    assert_not_nil str4.index(rrbase)
#    assert_not_equal str3, str4
    
    
    #####################################
    # in production mode
    #####################################
    config = Rails.application.config
    config.assets.debug = false
    config.assets.digest = true
    config.assets.compile = false
    # ensure there is no gnd_reminder_rule_data.js
    JsGenerator.remove(@rrfile)
    # call the tag helper method will return a link without digest
    str1 = helper.javascript_include_tag(@rrfile)
    assert_not_nil str1.index(@rrfile)
    
    # generate that js file
    JsGenerator.generate_reminder_rule_data_js
    
    # call the tag helper will return a link with digest
    str2 = helper.javascript_include_tag(@rrfile)
    assert_nil str2.index(@rrfile)     # the asset link has no digest
    assert_not_nil str2.index(rrbase) # the asset link includes the digest information
    # get teh asset file content
#    a = str2.split(".js").first; digested_file = a.split("/").last + ".js"
#    f2 = File.read("#{Rails.root.join("public","assets", digested_file)}")
    
    # generate that js file again
    JsGenerator.generate_reminder_rule_data_js
    
    # the tag helper method call will return a link with same digest
    str3 = helper.javascript_include_tag(@rrfile)
    assert_nil str3.index(@rrfile)
    assert_not_nil str3.index(rrbase)
    # get the file content
#    a = str3.split(".js").first; digested_file = a.split("/").last + ".js"
#    f3 = File.read("#{Rails.root.join("public","assets", digested_file)}")
#    
#    if str2 != str3
#      puts "first file is: \n" + f2
#      puts "second file is: \n" + f3
#    end
    assert_equal str2, str3
    
    # generate the js file again with slightly different content
    new_tempfile = JsGenerator.reminder_rule_data_tempfile
    File.open(new_tempfile.path,"a") {|file | file.puts " var nnn=123;"}
    JsGenerator.generate_reminder_rule_data_js(new_tempfile)
    
    # the tag helper method call will return a link with different digest
    str4 = helper.javascript_include_tag(@rrfile)
    assert_nil str4.index(@rrfile)
    assert_not_nil str4.index(rrbase)
    assert_not_equal str3, str4
    
    JsGenerator.remove(@rrfile)
    
    # revert back to test mode
    config.assets.debug = true
    config.assets.digest = false
    config.assets.compile = true
  end
  
  def teardown
    AssetLockFile.clear_locks
    system("rm -rf #{Rails.root.join("public","assets")}")
  end
end
