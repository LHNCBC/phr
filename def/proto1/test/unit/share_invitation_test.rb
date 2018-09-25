require 'test_helper'

class ShareInvitationTest < ActiveSupport::TestCase

  fixtures :users
  fixtures :profiles
  fixtures :profiles_users
  fixtures :usage_stats # Added an empty fixture to meet the assumptions of the following tests
  DUMMY_IP = '123.4.5.6'

  # Tests the creation of a share_invitation row.
  #
  def test_new

    mysql_error_start = "Mysql2::Error: "
    a_user = users(:temporary_account_3)
    invite_attributes = {}
    # test with ALL parameters null - fails on missing profile
    exception = assert_raises(NoMethodError) {
      ShareInvitation.new(invite_attributes)
    }
    assert_equal("undefined method `share_invitations' for nil:NilClass",
                 exception.message)
    all_invite = ShareInvitation.where('issuing_user_id is NULL').to_a
    assert_equal(0, all_invite.size)

    # test with just a user specified - also fails on missing profile
    invite_attributes[:issuing_user_id] = a_user.id
    exception = assert_raises(NoMethodError) {
      ShareInvitation.new(invite_attributes)
    }
    assert_equal("undefined method `share_invitations' for nil:NilClass",
                 exception.message)
    all_invite = ShareInvitation.where(issuing_user_id: -10).to_a
    assert_equal(0, all_invite.size)

    # Populate the attributes hash and then test removing each value that
    # is required, one at a time.  Testing to make sure row cannot be created
    # with missing required attribute.
    
    invite_attributes[:profile_id] = -34
    invite_attributes[:target_name] = 'Horatio'
    invite_attributes[:target_user_id] = -12
    invite_attributes[:target_email] = 'anemail@address.com'
    invite_attributes[:date_issued] = DateTime.now
    invite_attributes[:expiration_date] = 30.days.from_now
    invite_attributes[:access_level] = ProfilesUser::READ_ONLY_ACCESS
    invite_attributes[:accept_key] = 'rqopiu34'

    exception = assert_raises(ActiveRecord::StatementInvalid) {
      ShareInvitation.new(invite_attributes)
    }
    fld_msg = mysql_error_start +
              "Field 'issuer_name' doesn't have a default value: INSERT"
    assert_equal(fld_msg, exception.message[0, fld_msg.length])
    all_invite = ShareInvitation.where(issuing_user_id: -10).to_a
    assert_equal(0, all_invite.size)

    invite_attributes[:issuer_name] = 'Horace'
    invite_attributes.delete(:target_name)

    exception = assert_raises(ActiveRecord::StatementInvalid) {
      ShareInvitation.new(invite_attributes)
    }
    fld_msg = mysql_error_start +
              "Field 'target_name' doesn't have a default value: INSERT"
    assert_equal(fld_msg, exception.message[0, fld_msg.length])
    all_invite = ShareInvitation.where(issuing_user_id: -10).to_a
    assert_equal(0, all_invite.size)

    invite_attributes[:target_name] = 'Horatio'
    invite_attributes.delete(:target_email)

    exception = assert_raises(ActiveRecord::StatementInvalid) {
      ShareInvitation.new(invite_attributes)
    }
    fld_msg = mysql_error_start +
              "Field 'target_email' doesn't have a default value: INSERT"
    assert_equal(fld_msg, exception.message[0, fld_msg.length])
    all_invite = ShareInvitation.where(issuing_user_id: -10).to_a
    assert_equal(0, all_invite.size)

    invite_attributes[:target_email] = 'anemail@address.com'
    invite_attributes.delete(:date_issued)

    exception = assert_raises(ActiveRecord::StatementInvalid) {
      ShareInvitation.new(invite_attributes)
    }
    fld_msg = mysql_error_start +
              "Field 'date_issued' doesn't have a default value: INSERT"
    assert_equal(fld_msg, exception.message[0, fld_msg.length])
    all_invite = ShareInvitation.where(issuing_user_id: -10).to_a
    assert_equal(0, all_invite.size)

    invite_attributes[:date_issued] = DateTime.now
    invite_attributes.delete(:expiration_date)

    exception = assert_raises(ActiveRecord::StatementInvalid) {
      ShareInvitation.new(invite_attributes)
    }
    fld_msg = mysql_error_start +
              "Field 'expiration_date' doesn't have a default value: INSERT"
    assert_equal(fld_msg, exception.message[0, fld_msg.length])
    all_invite = ShareInvitation.where(issuing_user_id: -10).to_a
    assert_equal(0, all_invite.size)
 
    invite_attributes[:expiration_date] = 30.days.from_now
    invite_attributes.delete(:accept_key)

    exception = assert_raises(ActiveRecord::StatementInvalid) {
      ShareInvitation.new(invite_attributes)
    }
    fld_msg = mysql_error_start +
              "Field 'accept_key' doesn't have a default value: INSERT"
    assert_equal(fld_msg, exception.message[0, fld_msg.length])
    all_invite = ShareInvitation.where(issuing_user_id: -10).to_a
    assert_equal(0, all_invite.size)
   
    invite_attributes[:accept_key] = 'rqopiu34'

    # test with all parameters specified
    assert_nothing_raised {
      ShareInvitation.new(invite_attributes)
    }
    all_invite = ShareInvitation.where(issuing_user_id: -10).to_a
    assert_equal(1, all_invite.size)
    the_invite = all_invite[0]
    assert_equal(a_user.id, the_invite.issuing_user_id)
    assert_equal(-34, the_invite.profile_id)
    assert_equal(invite_attributes[:issuer_name], the_invite.issuer_name)
    assert_equal(invite_attributes[:target_name], the_invite.target_name)
    assert_equal(invite_attributes[:target_email], the_invite.target_email)
    # The time portion of the date/time comes back as localtime, but it must
    # be specifically requested for the date created here.
    assert_equal((invite_attributes[:expiration_date].localtime).to_formatted_s(:db),
                 the_invite.expiration_date.to_formatted_s(:db))
    assert_equal(ProfilesUser::READ_ONLY_ACCESS, the_invite.access_level)
    assert_equal(-12, the_invite.target_user_id)
    assert_not_nil(the_invite.date_issued)
    assert_nil(the_invite.date_responded)
    assert_nil(the_invite.response)
    assert_not_nil(the_invite.created_at)
    assert_equal(invite_attributes[:accept_key], the_invite.accept_key)
  end # test_new


  # This tests the has_pending_invitations? method
  def test_has_pending_invitations?
    # First test for a user that has no pending invitations
    @user = users(:phr_home_user3)
    assert_not(ShareInvitation.has_pending_share_invitations?(@user.email))

    # Then create one and test again
    target = @user
    @user = users(:phr_home_user2)
    @profile = profiles(:phr_home_active_profile_5)
    invite_attributes = {}
    invite_attributes[:profile_id] = @profile.id
    invite_attributes[:issuing_user_id] = @user.id
    invite_attributes[:issuer_name] = "Grace"
    invite_attributes[:target_name] = "Aloysius"
    invite_attributes[:target_email] = target.email
    invite_attributes[:date_issued] = DateTime.now
    invite_attributes[:expiration_date] = 30.days.from_now
    invite_attributes[:access_level] = ProfilesUser::READ_ONLY_ACCESS
    invite_attributes[:accept_key] = '40209-fdvknpqeof9781;3mrk'

    ShareInvitation.new(invite_attributes)
    assert(ShareInvitation.has_pending_share_invitations?(target.email))

    # Now test when the invitation has expired
    invite = ShareInvitation.where(
                                accept_key: invite_attributes[:accept_key]).take
    invite.expiration_date = 1.day.ago
    invite.save!
    assert_not(ShareInvitation.has_pending_share_invitations?(target.email))

    # Now test when the invitation has been accepted
    invite = ShareInvitation.where(
                                accept_key: invite_attributes[:accept_key]).take
    invite.expiration_date = 1.day.from_now
    invite.date_responded = Time.now
    invite.save!
    assert_not(ShareInvitation.has_pending_share_invitations?(target.email))

  end # test_has_pending_invitations?


  # Tests the method called to grant access to a profile.  Does not test
  # error conditions because the grant_access method does no checking.  It
  # assumes the error checking has been done before it is called.
  #
  # This tests to make sure the invitation is updated with the acceptance and
  # that the user does have access to the profile as an "other_profile"
  #
  def test_grant_access

    # Create the invitation to be accepted
    owner_user = users(:temporary_account_3)
    target_user = users(:standard_account_3)

    invite_attributes = {}
    invite_attributes[:profile_id] = -34
    invite_attributes[:issuing_user_id] = owner_user.id
    invite_attributes[:issuer_name] = 'Horace'
    invite_attributes[:target_name] = 'Horatio'
    invite_attributes[:target_user_id] = target_user.id
    invite_attributes[:target_email] = 'anemail@address.com'
    invite_attributes[:date_issued] = DateTime.now
    invite_attributes[:expiration_date] = DateTime.now
    invite_attributes[:access_level] = ProfilesUser::READ_ONLY_ACCESS
    invite_attributes[:accept_key] = 'rqopiu34'

    ShareInvitation.new(invite_attributes)

    # Now grant access to the target user
    invite = ShareInvitation.where(
                                accept_key: invite_attributes[:accept_key]).take
    invite.grant_access(target_user)

    # Get the invitation again and check it for the acceptance
    invite = ShareInvitation.where(
                                accept_key: invite_attributes[:accept_key]).take

    assert_equal(target_user.id, invite.target_user_id)
    assert_not_nil(invite.date_responded)
    assert_equal('accepted', invite.response)

    # check to see if the user has access
    target_user = User.find_by_id(target_user.id)
    profile = Profile.find_by_id(invite.profile_id)
    profs = target_user.other_profiles
    assert(profs.include?(profile))

  end # test_grant_access


  # Tests the method called to decline access to a profile.  Does not test
  # error conditions because the grant_access method does no checking.  It
  # assumes the error checking has been done before it is called.
  #
  # This tests to make sure the invitation is updated with the refusal and
  # that the user does NOT have access to the profile as an "other_profile"
  #
  def test_decline_access

    # Create the invitation to be accepted
    owner_user = users(:temporary_account_3)
    target_user = users(:standard_account_3)
 
   invite_attributes = {}
    invite_attributes[:profile_id] = -34
    invite_attributes[:issuing_user_id] = owner_user.id
    invite_attributes[:issuer_name] = 'Horace'
    invite_attributes[:target_name] = 'Horatio'
    invite_attributes[:target_user_id] = target_user.id
    invite_attributes[:target_email] = 'anemail@address.com'
    invite_attributes[:date_issued] = DateTime.now
    invite_attributes[:expiration_date] = DateTime.now
    invite_attributes[:access_level] = ProfilesUser::READ_ONLY_ACCESS
    invite_attributes[:accept_key] = 'rqopiu34'

    ShareInvitation.new(invite_attributes)

    # Now decline access for the target user
    invite = ShareInvitation.where(
                                accept_key: invite_attributes[:accept_key]).take
    invite.decline_access(target_user)

    # Get the invitation again and check it for the decline
    invite = ShareInvitation.where(
                                accept_key: invite_attributes[:accept_key]).take

    assert_equal(target_user.id, invite.target_user_id)
    assert_not_nil(invite.date_responded)
    assert_equal('declined', invite.response)

    # check to make sure the user does not have access
    target_user = User.find_by_id(target_user.id)
    profile = Profile.find_by_id(invite.profile_id)
    profs = target_user.other_profiles
    assert_not(profs.include?(profile))
  end # test_decline_access

end # share_invitation_test
