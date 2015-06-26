plugins_path = File.join(Rails.root, "lib/rails2plugins")
#plugins_path = File.expand_path("../../../lib/rails2plugins",__FILE__)
plugin_entries = Dir.entries(plugins_path)
#puts plugin_entries.inspect
plugin_entries.each do |ent|
  #puts "EACH ENTRY: #{ent}"
  init_path = File.join(plugins_path, ent, "init.rb")
  #puts "INITIAL PATH: #{init_path.to_s}"
  if File.exist?(init_path)
    #puts "this path exists: #{init_path.to_s}"
    require init_path 
  end
end
