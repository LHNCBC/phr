class ShareInvitation < ActiveRecord::Base
  belongs_to :profile
  serialize :data, JSON
  validates_uniqueness_of :accept_key
  
  
  # Initializes a new ShareInvitation object.
  #
  # Parameters:
  # * attributes - which is a hash containing the values for the
  #   share_invitation row to be created.  Must be specified with the same
  #   keys as the column names used in the table; is automatically created
  #   from that by the base class.  Must include values for all non-null
  #   columns; may include others.
  #
  # Returns:
  # * nothing
  #
    def initialize(attributes)
    # Create and store the row in the database table
    super
    # associate it with the profile object
    prof_obj = Profile.find_by_id(attributes[:profile_id])
    prof_obj.share_invitations.concat(self)
    # Figure the space used and update the user object.  We track this to
    # protect against a disk-filling denial-of-service attack.
    prof_obj.owner.accumulate_data_length(ShareInvitation.get_row_length(self))

  end # initialize


  # This checks to see if a user has any pending shared access invitations.
  # It is called when the PHR Home page is being created/recreated.
  #
  # Parameters:
  # * user_email the email address for the user
  #
  # Returns:
  # * boolean indicating whether or not the user has any pending invitations
  def self.has_pending_share_invitations?(user_email)
    return where('target_email = ? AND date_responded is ' +
                 'NULL AND expiration_date > ?', user_email,
                 1.day.ago).count > 0
  end


  # Grants access to a user who has accepted this share invitation.  Takes care
  # of updating the invitation to show the acceptance and calling the
  # ProfilesUser method to set the access in the profiles_users table.
  #
  # This assumes that the user object passed to this method is valid for
  # the current invitation, that the invitation has not already been accepted
  # or decline or has expired or any of that.  All validity checking should
  # be done before this is called.
  #
  # Parameters:
  # * user_obj the user object for the user who is the one accepting
  #   this invitation.
  #
  # Returns:
  # * nothing
  def grant_access(user_obj)
    self.target_user_id = user_obj.id
    self.date_responded = Time.now
    self.response = 'accepted'
    self.save!
    ProfilesUser.add_access(user_obj.id, profile_id, access_level)
  end # grant_access


  # Updates this invitation that has been declined by a user.
  #
  # This assumes that the user object passed to this method is valid for
  # the current invitation, that the invitation has not already been accepted
  # or declined or has expired or any of that.  All validity checking should
  # be done before this is called.
  #
  # Parameters:
  # * user_obj the user object for the user who is the one declining
  #   this invitation.
  #
  # Returns:
  # * nothing
  def decline_access(user_obj)
    self.target_user_id = user_obj.id
    self.date_responded = Time.now
    self.response = 'declined'
    self.save!
  end

end # share_invitation
