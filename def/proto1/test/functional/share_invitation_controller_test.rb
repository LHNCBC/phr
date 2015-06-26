require 'test_helper'

class ShareInvitationControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :profiles
  fixtures :profiles_users
  fixtures :phrs
  fixtures :share_invitations


  def setup
    @controller = ShareInvitationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'forms', 'db_table_descriptions', 'db_field_descriptions',
        'text_lists', 'text_list_items'])
    @cur_ip = '127.11.11.11'
  end


  # This tests share invitation requests that come in from the client.
  # It tests to make sure the appropriate error returns are working, and
  # that a share_invitation record gets created, although it doesn't test
  # the content of the record.  That's done in the unit test for the model
  # class that actually creates the record.
  #
  # The requests sent are ajax requests.  This does not try to test whether
  # or not non-ajax requests are rejected, because that is handled by the
  # xhr_and_exception filter in the ApplicationController - and that
  # should be tested elsewhere.
  #
  def test_create
 
    the_user = users(:temporary_account_3)
    the_profile = profiles(:standard_profile_3)
    prof_user = ProfilesUser.find_by_profile_id(the_profile.id)

    # Test posting with empty parameters.
    xhr :post, :create, {}, {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(500, @response.status)
    assert(JSON.parse(@response.body)["runtime_error"].include?(
           ShareInvitationController::NO_INVITE_DATA_RESP),
           'NO_INVITE_DATA_RESPONSE not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')
  
    # Test posting with just an id_shown parameter
    xhr :post, :create, {:id_shown=>the_profile.id_shown},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(500, @response.status)
    assert(JSON.parse(@response.body)["runtime_error"].include?(
           ShareInvitationController::NO_INVITE_DATA_RESP),
           'NO_INVITE_DATA_RESPONSE not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')

    invite_data = {"target_email" => "hello@kitty.com",
                   "target_name" => "Horatio",
                   "issuer_name" => "Horace",
                   "personalized_msg" => "This is personal"}

    # Test posting with no id_shown parameter
    xhr :post, :create, {:invite_data=>invite_data.to_json},
                        {:user_id =>the_user.id, :cur_ip => @cur_ip}
    assert_equal(500, @response.status)
    assert(JSON.parse(@response.body)["runtime_error"].include?(
           ShareInvitationController::NO_ID_SHOWN_RESP),
           'NO_ID_SHOWN_RESPONSE not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')

    # Test posting with no target_email parameter
    invite_data.delete("target_email")
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(500, @response.status)
    assert(JSON.parse(@response.body)["runtime_error"].include?(
           ShareInvitationController::NO_EMAIL_RESP),
           'NO_EMAIL_RESPONSE not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')

    # Test posting with no target_name parameter
    invite_data.delete("target_name")
    invite_data["target_email"] = "hello@kitty.com"
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(500, @response.status)
    assert(JSON.parse(@response.body)["runtime_error"].include?(
           ShareInvitationController::NO_TARGET_NAME_RESP),
           'NO_TARGET_NAME_RESPONSE not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')

    # Test posting with no issuer_name parameter
    invite_data.delete("issuer_name")
    invite_data["target_name"] = "Horatio"
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(500, @response.status)
    assert(JSON.parse(@response.body)["runtime_error"].include?(
           ShareInvitationController::NO_ISSUER_NAME_RESP),
           'NO_ISSUER_NAME_RESPONSE not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')
 
    # Test posting with no personalized_msg parameter
    invite_data.delete("personalized_msg")
    invite_data["issuer_name"] = "Horace"
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(500, @response.status)
    assert(JSON.parse(@response.body)["runtime_error"].include?(
           ShareInvitationController::NO_MSG_RESP),
           'NO_MSG_RESPONSE not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')
    invite_data["personalized_msg"] = "This is personal"

    # Test posting with an invalid id_shown parameter
    xhr :post, :create, {:id_shown=>'xxxxxxxxxxxxxx',
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(500, @response.status)
    assert(JSON.parse(@response.body)["security_error"].include?(
           ShareInvitationController::INVALID_ID_SHOWN_RESP),
           'INVALID_ID_SHOWN_RESPONSE not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')

    # Test for non-owner access for the issuing user - change the access
    # level for our user
    non_owner_user = users(:standard_account_2)
    owner_user = the_user
    the_user = non_owner_user
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(500, @response.status)
    assert(JSON.parse(@response.body)["security_error"].include?(
           ShareInvitationController::INVALID_ID_SHOWN_RESP),
           'INVALID_ID_SHOWN_RESP not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')       
    the_user = owner_user

   invite_data["target_email"] = "iam11@anemail.com"
    # test for request for target user who already has access
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(200, @response.status)
    assert(@response.body.include?(
           ShareInvitationController::ALREADY_HAS_ACCESS_RESP),
            'ALREADY_HAS_ACCESS_RESP not returned')

    # test for request for duplicate request
    # first for someone without an account - put in one invite
    invite_data["target_email"] = "hello@kitty.com"
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(200, @response.status)
    assert_equal(@response.body, "null")

    # now try to duplicate it
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    assert_equal(200, @response.status)
    resp = ShareInvitationController::PENDING_INVITE_RESP % {someone: "hello@kitty.com"}
    assert(@response.body.include?(resp),
            'PENDING_INVITE_RESP not returned')

    # hm - let's check the invite that we did manage to create.
    # no need to check details here - we'll check them later.  Just want
    # to make sure the row got created.
    invite = ShareInvitation.where(target_email: "hello@kitty.com")
    assert_equal(1, invite.length)

    # create another valid invitation and check that it was actually sent
    # this in effect tests send_invitation at the functional level.
    # content of the email is tested in the defMailer unit test
    invite_data["target_email"] = "hello@doggy.com"
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      xhr :post, :create, {:id_shown=>the_profile.id_shown,
                           :invite_data=>invite_data.to_json},
                          {:user_id => the_user.id, :cur_ip => @cur_ip}
    end
    invite_email = ActionMailer::Base.deliveries.last
    assert_equal 'Invitation to Share Personal Health Record (PHR) Information',
                 invite_email.subject
    assert_equal invite_data["target_email"], invite_email.to[0]

  end # test_create


 # This tests invitation acceptances that come in from the client.
 # It tests rejecting invalid acceptances (invalid parameters, invitation
 # expired, and invitation already accepted) and valid invitations for
 # users who already have an account and those who do not.
  def test_accept_invitation

    the_user = users(:phr_home_user)
    the_profile = profiles(:phr_home_active_profile_3)

    # Create an invitation for someone without an account
    invite_data = {"target_email" => "hello@kitty.com",
                   "target_name" => "Horatio",
                   "issuer_name" => "Horace",
                   "personalized_msg" => "This is personal"}
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}

    invite1 = ShareInvitation.where(target_email: "hello@kitty.com").take

    # Use this to test for an invalid invitation.
    # First use invalid values for both parameters
    post :accept_invitation, {:email => 'h@k.com', :invite_data => 'xyz'},
                             {:user_id => nil, :cur_ip => @cur_ip}
    assert_template :reject_accept
    assert_template layout: 'layouts/nonform'

    # Next use invalid accept_key value
    post :accept_invitation, {:email => invite1.target_email,
                              :invite_data => 'xyz'},
                             {:user_id => nil, :cur_ip => @cur_ip}
    assert_template :reject_accept
    assert_template layout: 'layouts/nonform'

    # Now use an invalid email
    post :accept_invitation, {:email => 'h@k.com',
                              :invite_data => invite1.accept_key},
                             {:user_id => nil, :cur_ip => @cur_ip}
    assert_template :reject_accept
    assert_template layout: 'layouts/nonform'

    # Now test a valid accept message for a user who does not have an account
    post :accept_invitation, {:email => invite1.target_email,
                              :invite_data => invite1.accept_key},
                             {:user_id => nil, :cur_ip => @cur_ip}
    assert_template 'form/show.rhtml'
    assert_template layout: 'form.rhtml'

    # Now create one for someone with an account
    target_user = users(:phr_home_user2)
    invite_data = {"target_email" => target_user.email,
                   "target_name" => "Romeo",
                   "issuer_name" => "Horace",
                   "personalized_msg" => "second access invitation"}
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    invite2 = ShareInvitation.where(target_email: target_user.email).take

    # accept that invitation
    post :accept_invitation, {:email => invite2.target_email,
                              :invite_data => invite2.accept_key},
                             {:user_id => nil, :cur_ip => @cur_ip}
    assert_template :current_user_acceptance
    assert_template layout: 'layouts/nonform'

    # Make sure the invitation was updated
    invite2 = ShareInvitation.where(target_email: target_user.email).take
    assert_not_nil(invite2.date_responded)

    # Try to accept it again
    post :accept_invitation, {:email=>invite2.target_email,
                              :invite_data => invite2.accept_key},
                             {:user_id => nil, :cur_ip => @cur_ip}
    assert_template :previously_responded
    assert_template layout: 'layouts/nonform'

    # Create one more invitation, reset the expiration date on it so
    # that it will be expired, then try to accept it.
    invite_data = {"target_email" => "abc@def.org",
                   "target_name" => "Rowena",
                   "issuer_name" => "Horace",
                   "personalized_msg" => "third access invitation"}
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    invite3 = ShareInvitation.where(target_email: invite_data["target_email"]).take
    invite3.expiration_date = 3.months.ago
    invite3.save!
    post :accept_invitation, {:email=>invite3.target_email,
                              :invite_data => invite3.accept_key},
                             {:user_id => nil, :cur_ip => @cur_ip}
    assert_template :invite_expire
    assert_template layout: 'layouts/nonform'
    
  end # test_accept_invitation


 # This tests invitation declines that come in from the client.
  #def test_access_declined
    # access_declined is actually tested in test_update_invitations
  #end # test_access_declined

  
  # This tests the implement_access method
  def test_implement_access

    the_user = users(:phr_home_user)
    the_profile = profiles(:phr_home_active_profile_1)

    # Create an invitation for someone without an account
    invite_data = {"target_email" => "iamunknown@email.com",
                   "target_name" => "Horatio",
                   "issuer_name" => "Horace",
                   "personalized_msg" => "This is personal"}
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}

    # First call implement_access with neither an invite nor an invite_key
    exception = assert_raises(NoMethodError) {
      ShareInvitationController.implement_access(the_user, nil, nil)
    }
    prof_msg = "undefined method `grant_access' for nil:NilClass"
    assert_equal(prof_msg, exception.message[0, prof_msg.length])
    # Make sure the invitation was NOT updated
    invite1 = ShareInvitation.where(target_email: invite_data["target_email"]).take
    assert_nil(invite1.date_responded)

    usalt = "NaCl" # unless defined?(SALT)
    hpw = User.encrypted_password("A password", usalt)
    iam = User.create(:name => 'unknown_user',
                      :salt => usalt,
                      :admin => 0,
                      :hashed_password => hpw,
                      :pin => '1234',
                      :email => 'iamunknown@email.com')
    # Now call implement_access.  Give it a user that we don't user anywhere
    # else, to simulate this being called after the target user has created
    # an account.  This type of user will have the invite key to pass in, but
    # not the invite object.
    ShareInvitationController.implement_access(iam, nil,
                                               invite1.accept_key)

    # Check to make sure that the accept date was updated
    invite1 = ShareInvitation.where(target_email: "iamunknown@email.com").take
    assert_not_nil(invite1.date_responded)

    # Create an invitation for someone with an account
    target_user = users(:phr_home_user2)
    invite_data = {"target_email" => target_user.email,
                   "target_name" => "Horatio",
                   "issuer_name" => "Emily",
                   "personalized_msg" => "This is also personal"}
    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    invite2 = ShareInvitation.where(target_email: invite_data["target_email"]).take
    # Now call implement_access.  This type of user will have the invitation
    # to pass in, but not the invite_key.
    ShareInvitationController.implement_access(target_user, invite2, nil)
    # Check to make sure that the accept date was updated
    invite2 = ShareInvitation.where(target_email: invite_data["target_email"]).take
    assert_not_nil(invite2.date_responded)

  end # test_implement_access


  # This tests the send_invitation method
  #def test_send_invitation
    # testing of send_invitation is included test_create
  #end # test_send_invitation


  # This tests the get_pending_share_invitations method that is used
  # to populate the pending_invitations list
  def test_get_pending_share_invitations

    # Create an invitation
    target = users(:phr_home_user3)
    the_user = users(:phr_home_user2)
    the_profile = profiles(:phr_home_active_profile_5)
    invite_data = {"target_email" => target.email,
                   "target_name" => "Aloysius",
                   "issuer_name" => "Grace",
                   "personalized_msg" => "This is also SO personal"}

    xhr :post, :create, {:id_shown=>the_profile.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}

    xhr :get, :get_pending_share_invitations, {}, {:user_id => target.id,
                                                   :cur_ip => @cur_ip}
    assert_template partial: "form/_pending_invites_field.rhtml"
    assert(@response.body.include?("You have received an invitation"))
    assert(@response.body.include?(the_profile.phr.pseudonym))

  end # test_get_pending_share_invitations


  # This tests the update_invitations action, which is called when the
  # user makes accept/decline/defer decisions on the pending_invitations list.
  def test_update_invitations

    # create three invitations
    target = users(:phr_home_user3)
    the_user = users(:phr_home_user)
    profile1 = profiles(:phr_home_active_profile_1)
    profile2 = profiles(:phr_home_active_profile_2)
    profile3 = profiles(:phr_home_active_profile_3)
    invite_data = {"target_email" => target.email,
                   "target_name" => "Aloysius",
                   "issuer_name" => "Grace",
                   "personalized_msg" => "This is also SO personal"}

    xhr :post, :create, {:id_shown=>profile1.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    xhr :post, :create, {:id_shown=>profile2.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}
    xhr :post, :create, {:id_shown=>profile3.id_shown,
                         :invite_data=>invite_data.to_json},
                        {:user_id => the_user.id, :cur_ip => @cur_ip}

    # accept one, decline one, and leave one alone
    invite_actions = {}
    invite_actions[-40] = 'accept'
    invite_actions[-41] = 'decline'

    # switch the user, since it's now the person who received the invites
    owner = the_user
    the_user = target
    xhr :post, :update_invitations, {:invite_actions=>invite_actions.to_json},
                                    {:user_id => the_user.id, :cur_ip => @cur_ip}

    invites = ShareInvitation.where(issuing_user_id: owner.id,
                                    target_user_id: target.id)
    assert_equal(3, invites.size)
    have_accept = false
    have_decline = false
    have_defer = false
    num_invites = 0

    invites.each do |invite|
      if invite.profile_id === -40
        assert_equal('accepted', invite.response)
        have_accept = true
      elsif invite.profile_id === -41
        assert_equal('declined', invite.response)
        have_decline = true
      else
        assert_nil(invite.response)
        have_defer = true
      end
      num_invites += 1
    end
    assert(have_accept)
    assert(have_decline)
    assert(have_defer)
    assert(3, num_invites)

    # now try to accept the one that was declined
    invite_actions[-41] = 'accept'
    invite_actions.delete(-40)
    xhr :post, :update_invitations, {:invite_actions=>invite_actions.to_json},
                                    {:user_id => the_user.id, :cur_ip => @cur_ip}

    assert(JSON.parse(@response.body)["runtime_error"].include?(
           ShareInvitationController::INVALID_INVITE_ACTION_RESP),
           'INVALID_INVITE_ACTION_RESPONSE not returned')
    assert(JSON.parse(@response.body)["exception_msg"].include?(
           ShareInvitationController::RUNTIME_ERR_USER_RESP),
           'User Error response not returned')
  end # test_update_invitations


 # This tests the send_invitation_accepted method
  def test_send_invitation_accepted
    invite = share_invitations(:invite_1)
    sender = users(:phr_home_user)
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      ShareInvitationController.send_invitation_accepted(invite)
    end
    invite_email = ActionMailer::Base.deliveries.last
    assert_equal 'Your Invitation was Accepted', invite_email.subject
    assert_equal sender.email, invite_email.to[0]

    # email content tested in the defMailer unit tests
  end # test_send_invitation_accepted


 # This tests the send_invitation_declined method
  def test_send_invitation_declined
    invite = share_invitations(:invite_1)
    sender = users(:phr_home_user)
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      ShareInvitationController.send_invitation_declined(invite)
    end
    invite_email = ActionMailer::Base.deliveries.last
    assert_equal 'Your Invitation was Declined', invite_email.subject
    assert_equal sender.email, invite_email.to[0]

    # email content tested in the defMailer unit tests

  end # test_send_invitation_declined

end # share_invitation_controller_test