require 'test_helper'

class DefMailerTest < ActionMailer::TestCase


  def test_share_invitation
    msg = "Hello target_name,
    Here's the invite"
    accept_key = '123jko'
    link_text = 'Yes, I accept the invitation'
    host = 'hostname'

    email = DefMailer.share_invitation("invitee@email.com", msg, accept_key,
            link_text, host).deliver
    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ['donotreply@mail.nih.gov'], email.from
    assert_equal ['invitee@email.com'], email.to
    assert_equal 'Invitation to Share Personal Health Record (PHR) Information',
                 email.subject

    # I did not use a fixture, and read_fixture, to test the body of the
    # email, because the html in the email made it too difficult to match
    # correctly.
    e_body = email.body.to_s
    msg_index = e_body.index(msg)
    assert msg_index > 15
    expect_url = 'share_invitation/accept_invitation?' +
                 'email=invitee%40email.com&amp;invite_data=' + accept_key
    url_index = e_body.index(expect_url)
    assert url_index > msg_index
    assert e_body.index(link_text) > url_index
  end


 def test_invitation_accepted
    msg_frag = "will be able to view the PHR"
    issuer_email = "Issuer email"
    issuer_name = "Invitation Issuer"
    target_name = "Invitee name"
    target_email = "Invitee email"
    prof_name = "Georgia's"
    prof_name_html = "Georgia&#39;s"
    from_lines = 'from me to you'
    host = 'hostname'

    email = DefMailer.invitation_accepted(issuer_email, issuer_name,
            target_name, target_email, prof_name, from_lines).deliver
    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ['donotreply@mail.nih.gov'], email.from
    assert_equal issuer_email, email.to
    assert_equal 'Your Invitation was Accepted', email.subject

    # I did not use a fixture, and read_fixture, to test the body of the
    # email, because the html in the email made it too difficult to match
    # correctly.
    e_body = email.body.to_s
    issuer_name_index = e_body.index(issuer_name)
    assert issuer_name_index > 5
    target_name1_index = e_body.index(target_name)
    assert target_name1_index > issuer_name_index
    target_email_index = e_body.index(target_email)
    assert target_email_index > target_name1_index
    prof_name1_index = e_body.index(prof_name_html)
    assert prof_name1_index > target_email_index
    target_name2_index = e_body.index(target_name, prof_name1_index)
    assert target_name2_index > prof_name1_index
    msg_frag_index = e_body.index(msg_frag)
    assert msg_frag_index > target_name2_index
    prof_name2_index = e_body.index(prof_name_html, msg_frag_index)
    assert prof_name2_index > msg_frag_index
    assert e_body.index(from_lines) > prof_name2_index
  end


  def test_invitation_declined
    msg_frag = "has declined your invitation"
    issuer_email = "Issuer email"
    issuer_name = "Invitation Issuer"
    target_name = "Invitee name"
    target_email = "Invitee email"
    prof_name = "Georgia's"
    prof_name_html = "Georgia&#39;s"
    from_lines = 'from me to you'
    host = 'hostname'

    email = DefMailer.invitation_declined(issuer_email, issuer_name,
            target_name, target_email, prof_name, from_lines).deliver
    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ['donotreply@mail.nih.gov'], email.from
    assert_equal issuer_email, email.to
    assert_equal 'Your Invitation was Declined', email.subject

    # I did not use a fixture, and read_fixture, to test the body of the
    # email, because the html in the email made it too difficult to match
    # correctly.
    e_body = email.body.to_s
    issuer_name_index = e_body.index(issuer_name)
    assert issuer_name_index > 5
    target_name1_index = e_body.index(target_name)
    assert target_name1_index > issuer_name_index
    target_email1_index = e_body.index(target_email)
    assert target_email1_index > target_name1_index
    msg_frag_index = e_body.index(msg_frag)
    assert msg_frag_index > target_email1_index
    prof_name_index = e_body.index(prof_name_html)
    assert prof_name_index > msg_frag_index
    target_name2_index = e_body.index(target_name, prof_name_index)
    assert target_name2_index > prof_name_index
    target_email2_index = e_body.index(target_email, target_name2_index)
    assert target_email2_index > target_name2_index
    assert e_body.index(from_lines) > target_name2_index
  end

end
