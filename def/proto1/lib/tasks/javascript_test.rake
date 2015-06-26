require 'javascript_test/javascript_test/javascript_test'

desc "Run tests for JavaScripts"
task 'test:javascripts' => :environment do
  # Copy javascripts/assets form app and vendor directories into test/javascript directory
  dest = Rails.root.join "test/javascript/assets"
  FileUtils.remove_dir(dest)  if ( File.exist?(dest) || File.symlink?(dest) )
  FileUtils.mkdir(dest)
  %w(app vendor).each do |dir|
    src = Rails.root.join "#{dir}/assets/javascripts"
    Dir.glob("#{src}/*").each do |src_f|
      dest_f = dest.join dest, File.basename(src_f)
      if File.exists?(src_f) && !File.exists?(dest_f)
        File.symlink(src_f, dest_f)
        #FileUtils.copy_entry(src, dest,false, false, true)
      end
    end
  end
  # Create soft links for assets in lib/javascript_test/assets 
  %w(css js).each do |ext|
    d = dest.to_s + "/unittest.#{ext}"
    s = Rails.root.join "lib/javascript_test/assets/unittest.#{ext}"
    File.symlink(s, d)
  end
  
  JavaScriptTest::Runner.new do |t| 
    rails_root = Rails.root.to_s    
    t.mount("/", rails_root)
    t.mount("/test", rails_root+'/test')
    #t.mount('/test/javascript/assets', rails_root+'/lib/javascript_test/assets')
    
    if ENV['name']
      t.run(ENV['name'])
    else
      Dir.glob('test/javascript/*_test.html').each do |js|
        t.run(File.basename(js,'.html').gsub(/_test/,''))
      end
    end
    #t.browser(:safari)
    t.browser(:firefox)
    #t.browser(:ie)
    #t.browser(:konqueror)
  end
  
  FileUtils.remove_dir(dest)
end
