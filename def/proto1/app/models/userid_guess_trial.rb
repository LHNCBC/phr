class UseridGuessTrial < ActiveRecord::Base
  @@max_trial = 3
  def self.guess_trial(user_name, page_errors)
    max = 1 # hours account to be locked.
    user = UseridGuessTrial.find_by_username(user_name)
   if user
      if user.trial and user.trial < @@max_trial
        user.trial += 1
        user.save!
      elsif user.trial and user.trial == @@max_trial
        if user.updated_at and
            (Time.now.to_i - Time.at(user.updated_at.to_i).to_i > max*3600)
          user.trial = 0
          user.save!
        else
          page_errors << "We are sorry, #{user_name}, but your login attempts have"+
            " exceeded the maximum number allowed.  To protect your account, further "+
            " attempts will not be allowed for one hour."
          return false
        end
      else # password_trial is null
        user.trial = 0
        user.save!
      end
    else
      UseridGuessTrial.create(:username=>user_name,:trial=>0)
    end
    page_errors << "The account ID and password combination is invalid."
    return false
  end
  
end
