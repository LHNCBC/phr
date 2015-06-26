# Rake tasks for checking the database.
namespace :def do

  desc "Checks the database for inconsistencies."
  task :check_db => :environment do
    # Check for phr records that do not have a profile record.
    # Actually, don't.  This is normal.  It happens when a profile is deleted.
    #  w = 'profile_id not in (select id from profiles)'
    #  c = Phr.where(w).count
    #  if c > 0
    #    puts "Found #{c} phr records that do not have a profile record.\n"+
    #      "  Try:  select * from phrs where #{w};"
    #  end

    # Check for profiles that do not have a phr record.
    w = 'id not in (select profile_id from hist_phrs) and id not in (select profile_id from phrs)'
    c = Profile.where(w).count
    if c > 0
      puts "Found #{c} profiles that do not have a phr record.\n"+
        "  Try:  select * from profiles where #{w};"
    end
  end
end
