require 'set'

namespace :def do
  # This task takes care of changes to data tables and files needed to customize
  # the application for a particular installation location.  Specify which
  # installation using the format "rake def:installation name=
  desc 'Switches between installation configurations; specify which '+
    'installation as a parameter in the format "name=[installation name]".'
  task :installation => :environment do
    inst_name = ENV['name']
    if !inst_name
      raise 'Specify the installation name as a parameter in format '+
        '"name=[installation name]".'
      exit
    end

    # Perform data table changes
    InstallationChange.change_installation(inst_name)
  end
  

  desc 'Lists available configuration names, as found in the '+
    'installation_changes table.  These names may be passed to the '+
    'installation task.'
  task :installation_list => :environment do
    put_default = false
    default_inst_str = InstallationChange::INSTALLATION_NAME_DEFAULT
    InstallationChange.select('installation').distinct.each do |r|
      puts r.installation
      put_default = true if r.installation==default_inst_str
    end
    puts default_inst_str if !put_default
  end


end
