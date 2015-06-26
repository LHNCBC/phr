class ProfilesUser < ActiveRecord::Base
   belongs_to :user
   belongs_to :profile

   NO_PROFILE_ACTIVE = 0
   OWNER_ACCESS = 1
   READ_WRITE_ACCESS = 2
   READ_ONLY_ACCESS = 3

   ACCESS_TEXT = ["Owner", "Read and Write", "Read Only"]
   READ_ONLY_NOTICE = 
         "This PHR is owned by %{owner};<br>you do not have permission to edit it."

  # Adds access to a profile for the specified user at the specified access
  # level
  #
  # Parameters:
  # * user_id id of the user object to receive addess
  # * profile_id id of the profile to which access is being granted
  # * access_level level of access being granted
  # Returns:
  # * nothing
  #
  def self.add_access(user_id, profile_id, access_level)
    ProfilesUser.create!(:user_id => user_id,
                         :profile_id => profile_id,
                         :access_level => access_level)
  end


  # Removes access to a profile for the specified user.
  #
  # Parameters:
  # * user_id id of the user object from which access is being removed
  # * profile_id id of the profile from which access is being removed
  # Returns:
  # * nothing
  #
  def self.remove_access(user_id, profile_id)
#    rem = ProfilesUser.where(user_id: user_id, profile_id: profile_id).take
#    rem.destroy
    user_obj = User.find(user_id)
    user_obj.other_profiles.delete(profile_id)
  end
end
