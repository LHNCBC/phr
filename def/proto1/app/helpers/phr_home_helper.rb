# A helper for the PHR Home controller.
# This methods in this helper produce the html for the profile-specific
# components of the phr home page.


module PhrHomeHelper
  
 
  # This method returns the html for the profile icon shown on the main
  # line of an active profile listing as well as the line for a removed
  # profile listing.  At the moment we are showing just a generic
  # profile icon.  The plan is to allow the user to choose icons for the
  # profiles and to show those icons.
  #
  # Parameters:
  # * profile the profile object for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * rem_row boolean indicating whether or not this is for a "removed"
  #   profile line.  Since this html component, i.e., the profile icon,
  #   is used for both active and inactive profiles, we prepend "rem_" to
  #   the id for components that are used in the inactive section.
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the profile icon
  #
  def profile_icon(profile, row_s, rem_row=false, prefix='')
    # change the icon to the user's icon when we implement that

    # The profile icon is clickable in the active profiles section, and
    # not clickable in the removed profiles section.  So, in the active
    # profiles section we want it to have a button, so it can be included
    # in the navigable elements of the form, and we want to assign an
    # onclick function to it.
    if !rem_row
       btn_tag_attrs = {:id => prefix + 'profile_icon_btn_' + row_s,
                       :class => "profile_icon_btn" ,
                       :type => "button",
                       :title => PhrHomeController::FORM_TOOLTIPS["name"],
                       :onclick => 'Def.PHRHome.toggleLinksSections("' +
                                   row_s + '", "' + prefix + '");'}
      img_tag_attrs = {:id => prefix + 'profile_icon_image_' + row_s,
                       :class => "inline_image sprite_icons-person_blue" ,
                       :alt => "Personal Icon"}

      ret = content_tag('button',
                        image_tag('blank.gif', img_tag_attrs),
                        btn_tag_attrs)

    # In the removed phrs section we just need the image
    else
      img_tag_attrs = {:id => 'rem_profile_icon_' + row_s,
                       :class => "inline_image sprite_icons-person_blue" ,
                       :alt => "Personal Icon"} 
      ret = image_tag('blank.gif', img_tag_attrs)
    end
    return ret
  end # profile_icon


  # This method returns the html for the wedgie icon (orange arrowhead and line)
  # shown on the main line of an active profile listing.
  #
  # Parameters:
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the wedgie icon
  #
  def wedgie_icon(row_s, prefix='')
    # The wegie icon is clickable so we want it to have a button.  That allows
    # it to be included in the navigable elements of the form.  We assign an
    # onclick function to the button rather than the image.

    btn_tag_attrs = {:id => prefix + 'wedgie_btn_' + row_s,
                     :class => "wedgie_icon_btn" ,
                     :type => "button",
                     :title => PhrHomeController::FORM_TOOLTIPS["name"],
                     :onclick => 'Def.PHRHome.toggleLinksSections("' +
                                 row_s + '", "' + prefix + '");'}
    img_tag_attrs = {:id => prefix + "wedgie_" + row_s ,
                     :class => "wedgie_image sprite_icons-phr-show-all-orange" ,
                     :alt => "Section open/close icon"}
    return content_tag('button',
                       image_tag('blank.gif', img_tag_attrs),
                       btn_tag_attrs)
  end # wedgie_icon


  # This method returns the html for the name and age component shown on the
  # main line of an active profile listing as well as the line for a removed
  # profile.  At one point we included the gender in the listing, but then
  # decided to take it out.  I've left it in the title in case we switch back
  # to using it.  :0
  #
  # Parameters:
  # * profile the profile object for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * rem_row boolean indicating whether or not this is for a "removed"
  #   profile line.  Since this html component is used for both active
  #   and removed profiles, we prepend "rem_" to the id for components
  #   that are used in both sections.
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the name and age component
  #
  def name_age_gender(profile, row_s, rem_row=false, prefix='')

    # Like the profile icon, the name functions differently in the active
    # listings and the removed listings.  The fun part here is that we split
    # the name/age string into two parts, one of which (the name) is clickable
    # in the active listings, while neither are active in the removed listings.
    # what fun!
    link_id = prefix + "name_link_" + row_s
    nlabel_id = prefix + "name_string_" + row_s
    alabel_id = prefix + "age_string_" + row_s

    label_parts = profile.phr.name_age_gender_label(true, false)
#    label_parts = label.split(',')
    # if there are 3 elements in the newLabels array, the name included
    # a comma.  Combine the first and second elements, and move the
    # other 2 to the second and third elements
#    if label_parts.length === 3
#      label_parts[0] += ',' + label_parts[1];
#      label_parts[1] = label_parts[2];
#    end
    label_parts[1] = ', ' + label_parts[1]

    # If this is for the active listings, the name portion becomes a button.
    if !rem_row
      tag_attrs = {:id => link_id,
                   :class => "name_button" ,
                   :display => "inline-block"}
      nlabel_attrs = {:id => nlabel_id ,
                      :class => 'name_string' ,
                      :type => 'button',
                      :title => PhrHomeController::FORM_TOOLTIPS["name"],
                      :onclick => 'Def.PHRHome.toggleLinksSections("' +
                                   row_s + '", "' + prefix + '");'}
      alabel_attrs = {:id => alabel_id ,
                      :class => 'name_age_string'}
      ret = content_tag('span',
                       content_tag('button', label_parts[0], nlabel_attrs) +
                       content_tag('span', label_parts[1], alabel_attrs),
                       tag_attrs)

    # Otherwise this is for the removed listings, no button needed.
    else
      tag_attrs = {:id => "rem_" + link_id,
                   :class => "name_button" ,
                   :display => "inline-block"}
      nlabel_attrs = {:id => "rem_" + nlabel_id ,
                      :class => 'rem_name_string'}
      alabel_attrs = {:id => "rem_" + alabel_id ,
                      :class => 'rem_name_age_string'}
      ret = content_tag('span',
                         content_tag('span', label_parts[0], nlabel_attrs) +
                         content_tag('span', label_parts[1], alabel_attrs),
                         tag_attrs)
    end
    return ret
  end # name_age_gender


  # This method returns the html for the last updated component shown on the
  # main line of a profile listing.  It uses the how_long_ago method in the
  # ApplicationHelper to figure and format the string.
  #
  # Parameters:
  # * profile the profile object for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created.
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the last updated component
  #
  def last_updated(profile, row_s, prefix='')
    ret_str = how_long_ago(profile.last_updated_at)
    tag_attrs = {:id => prefix + 'last_updated_' + row_s,
                 :class => "updated_string"}
    return content_tag('span', ret_str, tag_attrs)
  end # last_updated


  # This method returns the html for the health reminders envelope component
  # shown on the main line of a profile listing.  This returns html for the
  # blank gif.  When the health reminders data is updated on the form
  # which happens at page load, this will be changed as appropriate (to
  # a closed red envelope to indicate that at least one of the reminders has
  # not been read, or to a blank if there are no reminders).
  #
  # Parameters:
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the health reminders envelope component
  #
  def envelope_icon(row_s, prefix='')

    # Set the onclick handler to the message manager function used by the
    # health reminders link.
    eb_tag_attrs = {:id => prefix + "envelope_button_" + row_s,
                    :class => "envelope_button" ,
                    :type => "button",
                    :title => PhrHomeController::FORM_TOOLTIPS["health_rem"],
                    :onclick => "$('health_reminders_link_" + row_s +
                                "').messageManager_.showAllMessages" +
                                                      "(\'Health Reminders\');"}

    ei_tag_attrs = {:id => prefix + "envelope_icon_" + row_s,
                    :class => "inline_image envelope_icon",
                    :alt => "envelope icon to indicate health reminders"}
    return content_tag('button',
                       image_tag("blank.gif", ei_tag_attrs),
                       eb_tag_attrs)
  end # envelope_icon


  # This method returns the html for the health reminders component shown on the
  # main line of a profile listing.  This returns just generic link information.
  # When the health reminders data is updated on the form, which happens at page
  # load time, this will be changed as appropriate to indicate how many health
  # reminders there are for the user, if any, and how many are unread (if any).
  #
  # Parameters:
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the health reminders link component
  #
  def health_reminders_link(row_s, prefix='')

    hr_label = PhrHomeController::FORM_LABELS["reminders_checking"]

    # The onclick handler is assigned to the link by the message manager
    # when it attaches itself to the link.
    hr_tag_attrs = {:id => prefix + "health_reminders_link_" + row_s,
                    :class => "disabled_reminders" ,
                    :type => "button",
                    :title => PhrHomeController::FORM_TOOLTIPS["health_rem"],
                    :verticalAlign => "middle"}
    hr_label_attrs = {:id => prefix + "health_reminders_text_" + row_s,
                      :class => 'focus_text',
                      :display => "inline-block"}
    return content_tag('button',
                        content_tag('span', hr_label, hr_label_attrs),
                        hr_tag_attrs)
  end # health_reminders_link


  # This method returns the html for the calendar icon component shown on the
  # main line of a profile listing.  If the user has no due date reminders, the
  # calendar icon is not displayed.  Otherwise the calendar is enabled and
  # includes the tooltip.
  #
  # Parameters:
  # * profile the profile object for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the calendar icon component
  #
  def calendar_icon(profile, row_s, prefix='')
    due_date_reminders = DateReminder.get_reminder_count(profile.id)
    if due_date_reminders == 0
      title = ''
    else
      title = PhrHomeController::FORM_TOOLTIPS["date_rem"]
    end
    cb_tag_attrs = {:id => prefix + "calendar_button_" + row_s,
                    :class => "calendar_button" ,
                    :type => "button",
                    :verticalAlign => "middle",
                    :title => title,
                    :onclick => 'Def.DateReminders.openDateReminderWindow("' +
                                 profile.id_shown + '");'}
    ci_tag_attrs = {:id => prefix + "calendar_icon_" + row_s,
                    :class => "inline_image sprite_icons-calendar",
                    :title => "",
                    :alt => ""}

    if due_date_reminders == 0
      cb_tag_attrs[:disabled] = true
      ci_tag_attrs[:class] = "inline_image"
    end

    return content_tag('button',
                       image_tag('blank.gif', ci_tag_attrs),
                       cb_tag_attrs)
  end # calendar_icon


  # This method returns the html for the date reminders link component shown on
  # the main line of a profile listing.  If the user has no due date reminders,
  # the link is disabled and no tooltip is shown for it (because the tooltip
  # tells the user to click on it for due date reminders).  Otherwise the link is
  # enabled and includes the tooltip.
  #
  # Parameters:
  # * profile the profile object for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the date reminders link component
  #
  def date_reminders_link(profile, row_s, prefix='')

    due_date_reminders = DateReminder.get_reminder_count(profile.id)
    if due_date_reminders > 0
      classnames = "text_button reminders_text"
      title = PhrHomeController::FORM_TOOLTIPS["date_rem"]
    else
      classnames = "disabled_reminders"
      title = ''
    end
    dd_tag_attrs = {:id => prefix + "date_reminders_link_" + row_s,
                    :class => classnames ,
                    :type => "button",
                    :title => title,
                    :onclick => 'Def.DateReminders.openDateReminderWindow("' +
                                 profile.id_shown + '");'}

    if due_date_reminders == 0
      dd_label = 'No date reminders'
      dd_tag_attrs[:disabled] = true
    else
      dd_label = due_date_reminders.to_s + ' date reminder'
      if due_date_reminders > 1
        dd_label += 's'
      end
    end
    dd_label_attrs = {:id => prefix + "date_reminders_text_" + row_s,
                      :class => 'focus_text',
                      :display => "inline-block"}
    return content_tag('button',
                        content_tag('span', dd_label, dd_label_attrs),
                        dd_tag_attrs)

  end # date_reminders_link


  # This method returns the html for the health summary link component shown on
  # the first links line of a profile listing.  The link is to the client-side
  # function that will show the main PHR (details) page for the current profile.
  #
  # Parameters:
  # * id_shown the id_shown value for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  # Returns:
  # * the html for the health summary (details) link component
  #
  def detail_link(id_shown, row_s, prefix='')
    label = PhrHomeController::FORM_LABELS["main_form"]
    label_attrs = {:id => prefix + 'show_phr_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => prefix + "show_phr_form_" + row_s,
                 :class => ["task_button", "detail_link", "wide_btn"],
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["health_summary"],
                 :onclick => "Def.PHRHome.showHealthSummary('" +
                              id_shown + "');"}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end # detail_link


  # This method returns the html for the import link/button component shown on
  # the first links line of a profile listing.  The link will invoke the
  # import task when it is complete. 
  #
  # Parameters:
  # * id_shown the id_shown value for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the import link/button component
  #
  def import_link(id_shown, row_s)
    label = PhrHomeController::FORM_LABELS["import"]
    label_attrs = {:id => 'import_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => "import_phr_" + row_s,
                 :class => "task_button",
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["import"],
                 :onclick => "Def.PHRHome.handleImportRequest('" +
                             id_shown + "');"}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end # import_link


  # This method returns the html for the share access link/button component shown
  # on the first links line of a profile listing.  The link will invoke the
  # share invite task when it is complete.
  #
  # Parameters:
  # * id_shown the id_shown value for the profile to be shared
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the share invite link/button component
  #
  def share_invite_link(id_shown, row_s)
    label = PhrHomeController::FORM_LABELS["share_invite"]
    label_attrs = {:id => 'share_invite_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => "share_invite_" + row_s,
                 :class => ["task_button", "wide_btn"],
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["share_invite"],
                 :onclick => "Def.PHRHome.handleShareInviteRequest('" +
                             id_shown + "', '" + row_s + "');"}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end


  # This method returns the html for the tests link component shown on
  # the second links line of a profile listing.  The link is to the
  # client-side function that will show the panel_view form (aka
  # "flowsheet", "view & edit results timeline", etc.).
  #
  # Parameters:
  # * id_shown the id_shown value for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the tests link component
  #
  def tests_link(id_shown, row_s, prefix='')
    label = PhrHomeController::FORM_LABELS["tests"]
    label_attrs = {:id => prefix + 'trackers_tests_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => prefix + "show_tests_" + row_s,
                 :class => ["task_button", "wide_btn"],
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["tests"],
                 :onclick => "Def.PHRHome.showTestsAndTrackers('" +
                              id_shown + "');"}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end # tests_link


  # This method returns the html for the export link/button component shown on
  # the second links line of a profile listing.  The link invokes the
  # client-side Def.PHRHome methods that handle an export request.
  #
  # Parameters:
  # * profile the profile object for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #
  # Returns:
  # * the html for the export link/button component
  #
  def export_link(profile, row_s, prefix='')
    phr = profile.phr
    label = PhrHomeController::FORM_LABELS["export"]
    label_attrs = {:id => prefix + 'export_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => prefix + "export_phr_" + row_s,
                 :class => "task_button",
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["export"] ,
                 :onclick => 'Def.PHRHome.handleExportRequest("' +
                             profile.id_shown + '", "' + phr.pseudonym +
                             '");'}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end # export_link


  # This method returns the html for the list of others with access component
  # shown on the second links line of a profile listing.  The link will cause
  # the access list to be displayed.
  #
  # Parameters:
  # * id_shown the id_shown value for the profile to be shared
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the share invite link/button component
  #
  def share_list_link(profile, row_s)
    have_others = profile.users.length > 1
    if have_others
      label = PhrHomeController::FORM_LABELS["share_list"]
    else
      label = PhrHomeController::FORM_LABELS["share_list2"]
    end
    label_attrs = {:id => 'share_list_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => "share_list_" + row_s,
                 :class => ["task_button", "wide_btn"],
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["share_list"],
                 :onclick => "Def.PHRHome.handleShareListRequest('" +
                             profile.id_shown + "', '" + row_s + "');"}
    if !have_others
      tag_attrs[:disabled] = true
    end

    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end


  # This method returns the html for the demographics link component shown on
  # the third links line of a profile listing.  The link invokes the
  # client-side Def.PHRHome methods that handle a request to update the
  # demographic data for a profile.
  #
  # Parameters:
  # * profile the profile object for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  # * prefix string prefixed to html component names for "other" profile
  #   listings.  Will be an empty string for active profiles.
  #   
  # Returns:
  # * the html for the demographis link component
  #
  def demographics_link(profile, row_s, prefix='')
    phr = profile.phr
    readonly = @user.access_level(profile.id) == ProfilesUser::READ_ONLY_ACCESS
    label = PhrHomeController::FORM_LABELS["demographics"]
    label_attrs = {:id => prefix + 'basics_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => prefix + "edit_demographics_" + row_s,
                 :class => ["task_button", "wide_btn"],
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["demographics"] ,
                 :onclick => 'Def.PHRHome.editDemographics("' +
                             profile.id_shown + '", "' + phr.pseudonym +
                             '", "' + row_s + '", "' + readonly.to_s + '");'}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end # demographics_link


  # This method returns the html for the remove link/button component shown on
  # the third links line of a profile listing.  The link invokes the
  # client-side Def.PHRHome methods that handle a remove request.
  #
  # Parameters:
  # * id_shown the id_shown value for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the remove link/button component
  #
  def remove_link(id_shown, row_s)
    label = PhrHomeController::FORM_LABELS["remove"]
    label_attrs = {:id => 'remove_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => "remove_profile_" + row_s,
                 :class => "task_button" ,
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["remove"],
                 :onclick => 'Def.PHRHome.removeProfile("' +
                             id_shown + '", "' + row_s + '");'}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end # remove_link


  # This method returns the html for the restore link/button component shown
  # for a removed profile listing.  The link invokes the client-side
  # Def.PHRHome methods that handle a restore request.
  #
  # Parameters:
  # * id_shown the id_shown value for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the restore link/button component
  #
  def restore_link(id_shown, row_s)
    label = PhrHomeController::FORM_LABELS["restore"]
    label_attrs = {:id => 'restore_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => "restore_profile_" + row_s,
                 :class => "task_button",
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["restore"],
                 :onclick => 'Def.PHRHome.restoreProfile("' +
                             id_shown + '", "' + row_s + '");'}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end # restore_link


  # This method returns the html for the delete link/button component shown
  # for a removed profile listing.  The link invokes the client-side
  # Def.PHRHome methods that handle a delete request.
  #
  # Parameters:
  # * id_shown the id_shown value for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the delete link/button component
  #
  def delete_link(id_shown, row_s)
    label = PhrHomeController::FORM_LABELS["delete"]
    label_attrs = {:id => 'delete_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => "delete_profile_" + row_s,
                 :class => "task_button" ,
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["delete"],
                 :onclick => 'Def.PHRHome.deleteProfile("' +
                             id_shown + '", "' + row_s + '");'}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end # delete_link


  # This method returns the html for the owner link/button component shown
  # for an other profile listing.
  #
  # Parameters:
  # * profile the profile object for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the owner link/button component
  #
  def owner_link(profile, row_s)
    owner_name = profile.owner.name
    label_attrs = {:id => 'owner_label_' + row_s,
                   :class => 'owner_string'}

    return content_tag('span', owner_name, label_attrs)
  end # owner_link


  # This method returns the html for access level information provided
  # for an other profile listing
  #
  # Parameters:
  # * profile the profile object for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the owner link/button component
  #
  def access_level_text(profile, row_s)
    level = "You have " + @user.access_level_text(profile.id) + 
            " access to this PHR"
    label_attrs = {:id => 'access_level_label_' + row_s,
                   :class => 'access_level_string'}

    return content_tag('span', level, label_attrs)
  end # access_level_text


  # This method returns the html for the remove access link/button component
  # shown for an "other" profile listing.  The link invokes the client-side
  # Def.PHRHome methods that handle a remove access request for a phr that the
  # current user has access to, but is not the owner of.
  #
  # Parameters:
  # * id_shown the id_shown value for the profile being listed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the delete link/button component
  #
  def remove_my_access_link(id_shown, row_s)
    label = PhrHomeController::FORM_LABELS["remove_my_access"]
    label_attrs = {:id => 'remove_my_access_label_' + row_s,
                   :class => 'task_button_label'}
    tag_attrs = {:id => "remove_my_access_" + row_s,
                 :class => ["task_button", "very_wide_btn"],
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["remove_my_access"],
                 :onclick => 'Def.PHRHome.removeMyAccess("' +
                             id_shown + '", "' + row_s + '");'}
    return content_tag('button',
                       content_tag('span', label, label_attrs), tag_attrs)
  end # remove_my_access_link


  # This method returns the html for the remove access link on the list of
  # other people who have access to a phr.  This link invokes the client-side
  # Def.PHRHome methods that handle the request.
  #
  # Parameters:
  # * id_shown the id_shown value for the profile with the access to be removed
  # * accessor_id the id of the user object for the user whose access is to be
  #   removed
  # * row_s the string representation of the row number to be assigned
  #   to the id(s) created for the html components created
  #
  # Returns:
  # * the html for the link component
  #
  def remove_this_access_link(id_shown, accessor_id, row_s)
    label = PhrHomeController::FORM_LABELS["remove_this_access"]
    label_attrs = {:id => 'remove_this_access_label_' + row_s,
                   :class => 'remove_this_access_label'}
    tag_attrs = {:id => "remove_this_access_" + row_s,
                 :class => "remove_this_access_button",
                 :type => "button",
                 :title => PhrHomeController::FORM_TOOLTIPS["remove_this_access"],
                 :onclick => 'Def.PHRHome.removeThisAccess("' +
                             id_shown + '", "' + row_s +
                             '", "' + accessor_id.to_s + '");'}
    return content_tag('button',
                        content_tag('span', label, label_attrs),
                        tag_attrs)
  end # remove_this_access_link



end # PhrHomeHelper
