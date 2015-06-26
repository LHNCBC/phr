class JavascriptTestGenerator < Rails::Generator::NamedBase  

  def manifest
    record do |m|
      m.directory File.join("test","javascript")      
      m.template 'javascript_test.html', File.join('test/javascript', "#{name}_test.html")
    end
  end
end