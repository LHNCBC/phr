/*
 * phr_home.js -> javascript functions to support the PHR Home page
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 *
 */ 

/**
 * This function updates the health reminders counts that are displayed for
 * active profiles.  It is defined outside of the Def.PHRHome class because
 * it can be defined for multiple classes.  It is called by the
 * Def.completeMessageManager function in the messageManager javascript code
 * for whatever class is requesting manager creation.
 *
 * This updates the counts (total reminders as well as how many are new), the
 * text, and the envelope icon as appropriate for a single profile.
 *
 * @param messageMgr the message manager object for the link being updated
 * @returns nothing
 */
Def.refreshCountButton = function(messageMgr) {

  var healthReminderLink = messageMgr.control_ ;
  var linkID = healthReminderLink.id;
  if (linkID.substr(0,2) === 'o_')
    var prefix = 'o_' ;
  else
    prefix = '';

  var profNum = linkID.substr(linkID.lastIndexOf('_') + 1) ;
 
  // Get the counts from the message manager attached to this link.
  var totalCount = messageMgr.getMessageCount() ;
  var newCount = messageMgr.getUnreviewedMessageCount() ;
  var textNode = $(prefix + "health_reminders_text_" + profNum) ;
  var envIcon = $(prefix + 'envelope_icon_' + profNum) ;
  var envButton = $(prefix +'envelope_button_' + profNum) ;

  if (totalCount === 0) {
    var newText = 'No health reminders';
    envIcon.removeClassName("sprite_icons-env_red_whole") ;
    envIcon.removeClassName("sprite_icons-env_blue_outline") ;
    healthReminderLink.disabled = true ;
    healthReminderLink.title = '' ;
    healthReminderLink.addClassName('disabled_reminders') ;
    healthReminderLink.removeClassName('text_button') ;
    envButton.disabled = true;
    envButton.title = '' ;
  }
  else {
    if (totalCount === 1)
      newText = '1 health reminder';
    else
      newText = totalCount + ' health reminders' ;
    if (newCount > 0) {
      newText += ' (' + newCount + ' unread)' ;
      envIcon.addClassName("sprite_icons-env_red_whole") ;
      envIcon.removeClassName("sprite_icons-env_blue_outline") ;
    }
    else {
      envIcon.addClassName("sprite_icons-env_blue_outline") ;
      envIcon.removeClassName("sprite_icons-env_red_whole") ;
    }
    healthReminderLink.disabled = false ;
    healthReminderLink.title = Def.PHRHome.FORM_TOOLTIPS["health_rem"] ;
    healthReminderLink.removeClassName('disabled_reminders') ;
    healthReminderLink.addClassName('text_button') ;
    envButton.disabled = false ;
    envButton.title = Def.PHRHome.FORM_TOOLTIPS["health_rem"] ;
  }
  textNode.innerHTML = newText ;
}  // end refreshCountButton


/**
 * This controls the new PHR Home page
 *
 */
Def.PHRHome = {

  /**
   * The name on file for the current user
   */
  userName_ : '',

  /**
   * An array containing the id_shown values for the user's active profiles.
   * This is initialized on page load (see index.html.erb)
   * key = profile id_shown, val = row num (index + 1)
   */
  idsShown_ : {} ,

  /**
   * Flag indicating whether or not the page is being displayed for 
   * the first time after the user logs in; used to determine whether or
   * not to show pending invitations if there are any
   */
  loggingIn_ : false ,

  /**
   * The id shown value for the current profile - which is whatever profile
   * the user has requested to use for a task.  Used when a dialog is displayed
   * for confirmation or parameters needed before processing a request.
   */
  currentIdShown_ : null ,

  /**
   * The string version of the row number suffix for the current phr being
   * processed.  Used when a dialog is displayed for confirmation or parameters
   * needed before processing a request.
   */
  currentRowSNum_ : '' ,

  /**
   * The number (string version) of the active link rows that are currently open,
   * if any.  The link rows are the lines under the main listing line for
   * an active profile.  We only allow one set of those to be open at a time.
   *
   */
  aLinksCurrentlyOpen_ : null ,

  /**
   * Last row number used as a suffix for active profile fields.  Used when
   * we move a new listing to the list of active phrs from a restore request.
   */
  lastRowNum_ : 0 ,

  /**
   * The number of active profiles currently shown.
   */
  activeCount_ : 0 ,

  /**
   * The number of "other" profiles currently shown.
   */
  othersCount_ : 0 ,

  /**
   * The number (string version) of the "others" link rows that are currently open,
   * if any.  The link rows are the lines under the main listing line for
   * an "other" profile.  We only allow one set of those to be open at a time.
   *
   */
  oLinksCurrentlyOpen_ : null ,


  /**
   * Flag indicating whether or not the "Removed PHRs" link is displayed.
   * More efficient than getting and checking the form element each time.
   */
  //remProfsToggleShown_ : true ,

  /**
   * Label text for the task labels, e.g., "Health Summary", that are set up on
   * the server side.  The values are passed to the loadPage function by the
   * server on page load.  Allows us to keep the labels consistent between the
   * client and the server.  Do NOT define any here.  Define them in the
   * PhrHomeController.
   */
  FORM_LABELS : {} ,

  /**
   * Tooltip text for the tooltips that are set up on the server side.
   * The values are passed to the loadPage function by the server on page load.
   * Allows us to keep the tooltips consistent.  Do NOT define any here.
   * Define them in the PhrHomeController.
   */
  FORM_TOOLTIPS : {} ,

  /**
   * Title specified for the health reminders box.  This really should
   * match what's used when the box is displayed from the PHR form.  Need
   * to make this a constant all can access
   */
  HEALTH_REMINDERS_TITLE: "Health Reminders" ,
 
  /**
   * The JQuery dialog box that is used for entry and update of the demographics
   * data for a single profile
   */
  demographicsDialog_: null,

  /**
   * The parent of the demographics dialog box.  We use this to modify the
   * z-index of the box when we want it either behind or in front of the
   * blinders (ours and the jquery blinder).
   */
  demoDialogParent_: null,

  /**
   * Flag indicating whether or not a change to or entry of a field of
   * demographics data could affect the reminder rules counts.  We use
   * this to restrict refiguring the count to only those times when they
   * might change.   The value is set true by the setAffectsRemdiners method,
   * and set false when the changes are saved and when the dialog box is
   * displayed (to avoid a lingering setting).
   */
  affectsReminders_ : false ,


  /**
   * Title of the demographics dialog box when we're adding a new person.
   */
  DEMOGRAPHICS_DIALOG_NEW_TITLE: 'Add New Person',

  /**
   * Title of the demographics dialog box when we're updating an existing phr.
   */
  DEMOGRAPHICS_DIALOG_UPDATE_TITLE: 'Update Demographics',

 /**
   * Title of the demographics dialog box when we're viewing an existing phr
   * (for a user with readonly access to the phr).
   */
  DEMOGRAPHICS_DIALOG_VIEW_TITLE: 'View Demographics',

 /**
   * Text displayed on the demographics dialog for users with readonly
   * access to the phr.  Passed to the loadPage function by the server on
   * page load.
   */
  READ_ONLY_NOTICE: '' ,

  /**
   * The JQuery dialog box that is used to explain the Download/export
   * process when the user selects "Download".
   */
  exportDialog_: null,

  /**
   * Title for the export dialog box.  This is what shows in the top left
   * of the window, looks like part of the frame.
   */
  EXPORT_DIALOG_TITLE: 'Download NAME Health Record',

  /**
   * Text for the export dialog box
   */
  EXPORT_DIALOG_WARNING_IMAGE: '<image id="warning_image" '+
                               'class="sprite_icons-warning_shield inline_image" src=' +
                                        Def.blankImage_ + '>'
                                  ,
  EXPORT_DIALOG_WARNING: 'To ensure your privacy, avoid downloading personal ' +
                         "information if you are using a public computer." ,

  EXPORT_DIALOG_MAIN_LINE: 'Click the <b>Download</b> button to download ' +
    '<span id="possessive_pseudonym">name</span> health information to a ' +
    'file on your computer.' ,

  EXPORT_DIALOG_TEXT: '<ul><li>The file name will start with ' +
  '<span id="phr_pseudonym"></span>, followed by the date and time it was ' +
  'generated.<ul><li>i.e., <span id="export_filename"></span></li></ul></li>' +
  '<li>Your internet browser will download the file ' +
  'from the PHR server to your computer.</li>' +
  '<li>The file will include data from the <b><span id="main_form_name">name' +
  '</span></b> and <b><span id="test_form_name">name</span></b>; it will not ' +
  'include documents you have uploaded (imported).</li>' +
  '<li>You can use most spreadsheet programs to view the information and to ' +
  'print a copy for your records or for your health care provider.</li></ul>',

  /* NOT USED at the moment.  Right now they can just get an excel file.
  EXPORT_HELP_ME_CHOOSE_LINK: 'Help me choose' ,
  */

  /**
   * Radio button label for the default export file format.  NOT USED
   * at the moment/
  EXPORT_DEFAULT_FORMAT_LABEL: 'Excel Spreadsheet' ,
  */
 
  /**
   * The current format chosen for an export file.  Starts out with the
   * default. Make sure to change this if the default format changes.
   */
  exportFormat_: '2' ,

  /**
   * The filename constructed for the current export request.
   */
  exportFileName_: null ,

  /**
   * Notice that appears at the top of the page (in green) after the user
   * has specified a file type for a requested export.
   */
  EXPORT_NOTICE: 'Your download should begin in a few seconds.  (If you have ' +
                 'lots of data, it might take half a minute.  ' +
                 'Please be patient, and do not press the "Go" button while ' +
                 'the browser is still working.)' ,

  /**
   * The JQuery dialog box that is used to confirm a delete phr request.  The
   * first time a phr delete is requested the dialog is created.  After that
   * the same dialog is reused.
   */
  confirmDeletePhrDialog_: null ,

  /**
   * Title for the confirm phr delete dialog box
   */
  DELETE_PHR_DIALOG_TITLE: 'DELETE PHR',

  /**
   * Text for the delete phr confirmation dialog box
   */
  DELETE_PHR_DIALOG_TEXT:
                      '<div id="deleteConfMessage" style="margin-bottom: 1em">' +
                      '<b>Are you sure you want to permanently delete the ' +
                      'record for <span id="confDeleteName"></span>?</b>' +
                      "<br><br>Once it's deleted you will not be able to get " +
                      'it back.<br><br></div>' ,

  /**
   * The JQuery dialog box that is used to confirm a remove access request.  The
   * first time an access remove is requested the dialog is created.  After that
   * the same dialog is reused.
   */
  confirmRemoveAccessDialog_: null ,

  /**
   * Title for the confirm access remove dialog box
   */
  REMOVE_ACCESS_DIALOG_TITLE: 'Remove Aaccess',

  /**
   * Text for the remove access confirmation dialog box when the access
   * to be removed is for the current user
   */
  REMOVE_MY_ACCESS_TEXT:
                      '<div id="deleteConfMessage" style="margin-bottom: 1em">' +
                      '<b>Are you sure you want to remove your access to ' +
                      "PNAME's PHR data?</b>" +
                      "<br><br>Once the access is removed you will have to " +
                      'get a new invitation for the access if you want it ' +
                      'back.<br><br></div>' ,

  /**
   * Text for the remove access confirmation dialog box when the access
   * to be removed is for a user who currently has access to a phr that
   * is owned by the current user
   */
  REMOVE_THIS_ACCESS_TEXT:
                      '<div id="deleteConfMessage" style="margin-bottom: 1em">' +
                      "<b>Are you sure you want to remove ONAME's access to " +
                      "PNAME's PHR data?</b>" +
                      "<br><br>Once the access is removed you will have to " +
                      'issue a new invitation for the access if you want  ' +
                      'ONAME to have it again.<br><br></div>' ,

  /**
   * The idShown value for a phr whose access is about to be removed from
   * a user.  Temporarily stored here while user responds to the confirm
   * remove dialog.   Used by doRemoveAccess if the remove is confirmed.
   */
  accessIdShown_: null ,

  /**
   * The id value for a user whose access to a phr is about to be removed.
   * Temporarily stored here while user responds to the confirm remove dialog.
   * Used by doRemoveAccess if the remove is confirmed.
   */
  accessUserId_: null,

  /**
   * The row number (as a string) of the access row to be removed - from
   * either the "others" section or the confirmRemoveAccess dialog.
   */
  accessRow_ : '' ,

  /**
   * Flag indicating whether a request to remove access is for the
   * current user (remove MY access) or for someone who can access a
   * phr belonging to the current user (remove THIS access).
   */
  myAccessRemoved_ : false ,

  /**
   * Title for the warning box displayed when a user has no profiles.  The
   * showWarning function is used to display the warning box.
   */
  NO_PROFILES_TITLE: "Create a PHR Record" ,

 /**
   * Text for the warning box displayed when a user has no profiles.
   */
  NO_ACTIVE_PROFILES_MSG: 'You have no PHR Records.  Please click on ' +
                          'the "Add New Person" button to create a new one.',

  /**
   * The JQuery dialog box that is used to gather the information to be used
   * to issue a share invitation.
   */
  shareInviteDialog_: null ,

  /**
   * Title for the share invitation box.  This is what shows in the top left
   * of the window, looks like part of the frame.
   */
  SHARE_INVITE_DIALOG_TITLE: 'Invite Another Person to Share Access',

  /**
   * Name for the PHR System.  This changes based on the current
   * installation and is defined in the installation-specific configuration
   * files (currently config/installation/default/installation_config.rb and
   * config/installation/alternate/installation_config.rb).  Used in the
   * text of the shared access invitation.
   */
  PHR_SYSTEM_NAME: '' ,

 /**
   * "From" line(s) for the shared access invitation.  This changes based on
   * the current installation and is defined in the installation-specific
   * configuration files
   * (currently config/installation/default/installation_config.rb and
   * config/installation/alternate/installation_config.rb).  Used in the
   * text of the shared access invitation.
   */
  SHARE_INVITE_FROM_LINES: '' ,

  /**
   * The message displayed to the user on a successful return from
   * create (a share invitation).  <name> is replaced with the invitee's
   * name before the message is posted.
   */

   SHARE_INVITE_SUCCESS:  'The invitation to <name> has been sent.',

  /**
   * Message to user on a create (a share invitation) failure that is not
   * one of the recognized failures.
   */
   SHARE_INVITE_FAILURE: 'Something has gone wrong, and the invitation ' +
                         'could not be sent.  Please use the ' +
                         '<a href="javascript:void()" ' +
                         "onclick=\"openPopup(this, '/feedback/new', " +
                         "'Feedback', 'width=900px,height=900px', " +
                         "'feedback', true); return false;\">Feedback</a>" +
                         ' form to let us about this.  Thank you.' ,

  /**
    * The JQuery dialog box that is used to list pending invitations for the
    * current user.
    */
   pendingInvitationsDialog_: null ,

  /**
    * Title for the pending invitations box.  This is what shows in the top left
    * of the window, looks like part of the frame.
    */
   PENDING_INVITATIONS_DIALOG_TITLE: 'Pending Invitations',

  /**
    * The JQuery dialog box that is used to list others with access to
    * the current phr.
    */
   accessListDialog_: null ,

  /**
    * Title for the access list box.  This is what shows in the top left
    * of the window, looks like part of the frame.
    */
   ACCESS_LIST_DIALOG_TITLE: "Access List for PNAME's PHR",


  /**
   *  Warning dialog box used by showWarning for alert-type messages
   */
  warningDialog_ : null ,
          
  /**
   * Warning/message box title for most error messages
   */
  ERROR_MSG_BOX_TITLE: "We're sorry" ,

  /**
   * Link to the Feedback form that can be included in error messages
   */
  FEEDBACK_FORM_LINK: '<a href="javascript:void()" ' +
                      "onclick=\"openPopup(this, '/feedback/new', " +
                      "'Feedback', 'width=900px,height=900px', " +
                      "feedback', true); return false;\">Feedback</a>",

  /**
   * Message displayed for the Import function -- until it's implemented.
   */
  IMPORT_FUNCTION_MSG: 'We are working on making the import function ' +
                       'available to you in the near future.  Honest.  ' +
                       'You can use the <a href="javascript:void()" ' +
                       "onclick=\"openPopup(this, '/feedback/new', " +
                       "'Feedback', 'width=900px,height=900px', " +
                       "'feedback', true); return false;\">Feedback</a>" +
                       ' form to let us know you want us to send you an ' +
                       'email when the function is ready.',

  /**
   * Message displayed for the Share Invite function -- until it's implemented.
   */
  SHARE_INVITE_FUNCTION_MSG: 'We are working on making the share access function ' +
                       'available to you in the near future.  Honest.  ' +
                       'You can use the <a href="javascript:void()" ' +
                       "onclick=\"openPopup(this, '/feedback/new', " +
                       "'Feedback', 'width=900px,height=900px', " +
                       "'feedback', true); return false;\">Feedback</a>" +
                       ' form to let us know you want us to send you an ' +
                       'email when the function is ready.',

  /**
   * Message displayed for the Share Invite function -- until it's implemented.
   */
  SHARE_LIST_FUNCTION_MSG: 'We are working on making the share list function ' +
                       'available to you in the near future.  Honest.  ' +
                       'You can use the <a href="javascript:void()" ' +
                       "onclick=\"openPopup(this, '/feedback/new', " +
                       "'Feedback', 'width=900px,height=900px', " +
                       "'feedback', true); return false;\">Feedback</a>" +
                       ' form to let us know you want us to send you an ' +
                       'email when the function is ready.',

  /**
   * Message displayed for the Remove Access function -- until it's implemented.
   */
  REMOVE_ACCESS_FUNCTION_MSG: 'We are working on making the remove access function ' +
                       'available to you in the near future.  Honest.  ' +
                       'You can use the <a href="javascript:void()" ' +
                       "onclick=\"openPopup(this, '/feedback/new', " +
                       "'Feedback', 'width=900px,height=900px', " +
                       "'feedback', true); return false;\">Feedback</a>" +
                       ' form to let us know you want us to send you an ' +
                       'email when the function is ready.',

  /**
   * Message displayed for the Show Pending Invitations function -- until it's
   * implemented.
   */
  SHOW_PENDING_FUNCTION_MSG: 'We are working on making the show pending invitations function ' +
                       'available to you in the near future.  Honest.  ' +
                       'You can use the <a href="javascript:void()" ' +
                       "onclick=\"openPopup(this, '/feedback/new', " +
                       "'Feedback', 'width=900px,height=900px', " +
                       "'feedback', true); return false;\">Feedback</a>" +
                       ' form to let us know you want us to send you an ' +
                       'email when the function is ready.',
  /**
   * This function performs start-up specific tasks when the page loads.
   * Specifically, it:
   *   * gets the populated active phr listings from the server and inserts
   *     them into the page;
   *   * hides the "Inactive PHRs" section at the bottom of the active phrs list
   *     if there are no inactive phrs for the current user;
   *   * stores the form labels and tooltips passed from server;
   *   * calls the message manager code that creates message managers for
   *     each health reminders link and fills in the correct counts for each; and
   *   * performs initializations where necessary.
   *
   * The call for this is set up on the server as the page is created.
   *
   * @param constants an array containing constants defined on the server
   *  [0] contains a hash to populate FORM_LABELS
   *  [1] contains a hash to populate FORM_TOOLTIPS
   *  [2] contains a string to assign to PHR_SYSTEM_NAME
   *  [3] contains a string to assign to SHARE_INVITE_FROM_LINES
   * @returns nothing
   */
  loadPage: function() {

	  // removed toggle taken out 3/4/14 - but may resurrect, so leave this for
    // awhile
   	//if (removed_count === 0) {
    //  $('fe_removed_profiles_toggle').style = "display: none;";
    //  Def.PHRHome.remProfsToggleShown_ = false ;
    //}

    this.FORM_LABELS = Def.pageLoadData_[0] ;
    this.FORM_TOOLTIPS = Def.pageLoadData_[1] ;
    this.PHR_SYSTEM_NAME = Def.pageLoadData_[2] ;
    this.SHARE_INVITE_FROM_LINES = Def.pageLoadData_[3];
    this.READ_ONLY_NOTICE = Def.pageLoadData_[4];
    this.loggingIn_ = Def.pageLoadData_[5];

    new Ajax.Request('/phr_home/get_initial_listings', {
      method: 'get' ,
      parameters: {
        authenticity_token: window._token ,
      } ,
      asynchronous: false,
      onFailure: function(response) {
        if (response.status === 500) {
          Def.showError(response.responseText)
        }
        else {
          this.showWarning(response.responseText, "We're sorry") ;
        }
      }.bind(this) ,
      onSuccess: function(response) {
        var resp = JSON.parse(response.responseText) ;
        this.userName_ = resp['user_name'] ;

        var profIdsForRems = {};
        var actRet = resp['active'] ;
        this.activeCount_ = actRet["count"] ;
        this.lastRowNum_ = this.activeCount_ ;
        this.idsShown_ = actRet["ids"]
        if (this.activeCount_ > 0) {
          profIdsForRems = this.drawInitialSection(actRet["listings"],
                                                   this.idsShown_,
                                                   'topSection',
                                                   'health_reminders_link_') ;
        } // end if we have active profiles

        var remRet = resp['removed'] ;
        if (remRet["count"] > 0) {
          this.drawRemovedSection(true, remRet);
          //$('fe_removed_profiles_toggle').style = "display: none;";
          //Def.PHRHome.remProfsToggleShown_ = false ;
        }

        // If we have other profiles, add that section now
        var otherRet = resp['other'] ;
        this.othersCount_ = otherRet["count"] ;
        if (this.othersCount_ > 0) {

          var remInfo = this.drawInitialSection(otherRet["listings"],
                                                otherRet["ids"],
                                                'otherTopSection',
                                                'o_health_reminders_link_') ;
          for (var othId in remInfo) {
            profIdsForRems[othId] = remInfo[othId] ;
          }
          expColSection('fe_other_profiles_0_expcol') ;
          $('fe_other_profiles_0').setStyle({display: 'block'}) ;
        } // end if we have other profiles

        // If we have active or other profiles, go get the health reminders
        if (this.activeCount_ > 0 || this.othersCount_ > 0) {
           Def.attachMessageManagers(profIdsForRems);
        }

        // If there are no active profiles, hide the section
        if (this.activeCount_ === 0) {
          $('profiles_list').style = "display: none;";
        }

        // If there are no profiles (active, removed or other), ask the user
        // to add a new one
        if (this.activeCount_ === 0 && remRet["count"] === 0 &&
            this.othersCount_ === 0) {
          $('profiles_list').style = "display: none;";
          this.showWarning(this.NO_ACTIVE_PROFILES_MSG, this.NO_PROFILES_TITLE);
        }

        // Call the navigation code to set up the form elements for navigation
        // in our system.  Because much of the form is built from views instead
        // of field descriptions, the form elements are not being set up in
        // the normal processing flow.
        Def.Navigation.setUpNavKeys();

        // If there are no pending invitations, hide the button for them
        if (resp['has_pending_invites'] === false) {
          $('fe_other_invitations').style = "display: none;";
        }
        // Otherwise, if the user is logging in and there are pending
        // invitations, show the pending invitations list
        else {
          if (this.loggingIn_)
            this.showPendingInvitations();
        }
      }.bind(this) // end onSuccess
    }); // end Ajax call to get the active profiles
  } , // end loadPage


  /**      Functions that directly respond to requests from the form        **\
  /**
   * This function controls the opening and closing of the "links" section for
   * each active phr.  The links section is displayed under the main listing
   * line for the phr, and provides links to the rest of the PHR system and
   * the functions available from this page.
   *
   * If the links section is closed when this is called, this opens it.
   * Conversely, if the section is open when this is called, this closes it.
   * This also resets the tooltip that is shown for the links that can be
   * used to invoke this, based on whether the section will be opened or closed.
   *
   * If another links section is open (other than the one this was called for)
   * this takes care of closing that section before opening the specified one.
   *
   * @param row_s the number (as a string) used as a suffix for the form
   *  fields displayed for the current phr
   * @param prefix a prefix for the form field names.  The same names are
   *  used for both the active phrs and the other phrs, with an 'o_' prefixed
   *  to the field names in the other phrs section.
   * @returns nothing
   */
  toggleLinksSections: function(row_s, prefix) {
    if (prefix === undefined)
      prefix = '';
    
    // Figure out what to open.  If the toggle is for a set of links that
    // are currently open, don't try to open them again.  The user is asking
    // to close them.
    if ((prefix === '' && this.aLinksCurrentlyOpen_ !== row_s) ||
        (prefix === 'o_' && this.oLinksCurrentlyOpen_ !== row_s)) {
      var openLinks = row_s;
      var openPrefix = prefix ;
    }
    else {
      openLinks = null ;  
    }

    // Now find out what links, if any, need to be closed
    if (this.aLinksCurrentlyOpen_ !== null) {
      var closeLinks = this.aLinksCurrentlyOpen_ ;
      var closePrefix = '' ;
      this.aLinksCurrentlyOpen_ = null ;
    }
    else if (this.oLinksCurrentlyOpen_ !== null) {
      closeLinks = this.oLinksCurrentlyOpen_ ;
      closePrefix = 'o_' ;
      this.oLinksCurrentlyOpen_ == null ;
    }
    else {
      closeLinks = null;
    }

    if (closeLinks !== null)
      this.toggleOneLinksSection(closeLinks, closePrefix, 'none',
                                 'sprite_icons-phr-show-all-orange',
                                 'sprite_icons-phr-hide-all-orange',
                                 this.FORM_TOOLTIPS['name']) ;
    if (openLinks !== null) 
      this.toggleOneLinksSection(openLinks, openPrefix, 'table-row',
                                 'sprite_icons-phr-hide-all-orange',
                                 'sprite_icons-phr-show-all-orange',
                                 this.FORM_TOOLTIPS['wedgie_up']) ;
    if (prefix === '')
      this.aLinksCurrentlyOpen_ = openLinks ;
    else
      this.oLinksCurrentlyOpen_ = openLinks ;
    
  } , // end toggleLinksSections


  /**
   * This function changes the following items for one links section (the
   * three links lines shown below the main phr line for an active phr):
   * the visibility of the lines (visible or collapsed); which "wedgie" icon is
   * displayed (up or down); which class name to apply to the wedgie icon (up
   * or down); and the title/tooltip that is shown for the 3 elements on the
   * main phr line that control opening and closing the links section.
   * Those elements are the profile icon, the wedgie icon, and the phr name link.
   *
   * @param row_s the number (as a string) used as a suffix for the form
   *  fields displayed for the current phr
   * @param prefix a prefix for the form field names.  The same names are
   *  used for both the active phrs and the other phrs, with an 'o_' prefixed
   *  to the field names in the other phrs section.
   * @param visibility the visibility attribute to be assigned to the lines
   *  ('visible' or 'collapsed') - actually the display attribute - 'none' or
   *  'table-row'
   * @param addClass the class to be added to the wedgie icon (controls which
   *  image is used for the icon)
   * @param removeClass the class to be added to the wedgie icon (controls
   *  which image is used for the icon)
   * @param title the title/toolbar text that is to be assigned to the three
   *  main profile line elements that control the visibility of the link lines
   * @returns nothing
   */
  toggleOneLinksSection: function(row_s, prefix, visibility, addClass,
                                  removeClass, title) {
    var linkLines = document.getElementsByClassName(prefix + "links_line_" + row_s);
    for (var i = 0, ll = linkLines.length; i < ll; ++i) {
      linkLines[i].style.display = visibility;
    }
    var wedgieImg = $(prefix + 'wedgie_' + row_s) ;
    if (wedgieImg) {
      wedgieImg.removeClassName(removeClass) ;
      wedgieImg.addClassName(addClass) ;
    }
    $(prefix + 'wedgie_btn_' + row_s).title = title ;
    $(prefix + 'profile_icon_btn_' + row_s).title = title;
    $(prefix + 'name_string_' + row_s).title = title ;
 
  } , // end toggleOneLinksSection


  /**
   * This function displays/redisplays the populated Removed PHRs section.
   * If the Removed PHRs link is displayed when this is called, it is hidden.
   * An ajax call to the server gets the listings for each removed phr for
   * the current user, and the IDCache is updated with the new listings.
   *
   * If no removed phrs exist for the user when this is called, the
   * Removed PHRs section is hidden.
   *
   * This is called by the loadPage function, the Removed PHRs link and by the
   * remove and restore functions.
   *
   * @param startClosed flag indicating that the inactive phrs, if any, should
   *  not actually be shown - just the header.  Used by the loadPage method
   *  to start the section out closed even though there are inactive phrs.
   *  This is per Clem's request at the 6/3/14 meeting
   * @param removedData the data (inactive phr listings) for the section.  This
   *  is used by loadPage, because all the phr listings are acquired at once
   *  for the initial page load.  It's not used; defaulted to false, for the
   *  other calls.
   * @returns nothing
   */
  drawRemovedSection: function(startClosed, removedData) {

    if (startClosed === undefined)
      startClosed = false ;

    document.getElementById('main_form').style.cursor = "wait" ;

    if (removedData === undefined) {
      new Ajax.Request('/phr_home/get_removed_listings', {
        method: 'get' ,
        parameters: {
          authenticity_token: window._token ,
          form_name: 'phr_home'
        } ,
        asynchronous: false,
        onFailure: function(response) {
          this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
        }.bind(this),
        onSuccess: function(response) {
          var resp = JSON.parse(response.responseText) ;
          haveRemoveds(resp['removed'])
        }
      }); // end request
    }
    else {
      haveRemoveds(removedData)
    }
    function haveRemoveds(remData) {
      // Make sure the Removed PHRs toggle link is NOT showing.  If we
      // have archived profiles, the link will be replaced with the
      // Removed PHRs section (if it hasn't been replaced already).  If
      // we don't have any archived profiles, we also don't want the link.
      // Toggle REMOVED 3/4/14 - but it may come back, so leave this in
      //var toggle = $('fe_removed_profiles_toggle') ;
      //if (isElementVisible(toggle)) {
      //  toggle.setStyle({display: "none"}) ;
      //  Def.PHRHome.remProfsToggleShown_ = false ;
      //}

      // If there are archived profiles, load up the section.  
      if (remData["count"] > 0) {
        // Rewrite the removed section with what we got back and update
        // the id cache.
        $('fe_removed_profiles_0_expcol').innerHTML =
                      '<div class="field">' + remData["listings"] + '</div>' ;
        Def.IDCache.addToCache($('fe_removed_profiles_0_expcol'));

        // If startClosed is false, make sure the listings are displayed.
        // Otherwise leave the list closed
        if (startClosed === false) {
          if ($('fe_removed_profiles_0_expcol').style.display == 'none')
            expColSection('fe_removed_profiles_0_expcol') ;
        }
        // But do make sure the header is showing if there are any removed
        // phrs
        $('fe_removed_profiles_0').setStyle({display: 'block'}) ;
      }
      // Otherwise there are no more archived profiles.  Make sure the
      // section is NOT showing.
      else {
        if ($('fe_removed_profiles_0_expcol').style.display == 'block') {
          expColSection('fe_removed_profiles_0_expcol') ;
          $('fe_removed_profiles_0').setStyle({display: 'none'}) ;
        }
      }
    } // end haveRemoveds
    
    document.getElementById('main_form').style.cursor = "auto" ;
  } , // end drawRemovedSection


  /**
   * This function handles a request to add a new person by displaying
   * the demographics edit box.
   *
   * @returns nothing
   */
  addNew: function() {
    this.currentIdShown_ = null ;
    Def.DataModel.id_shown_ = null ;
    Def.DataModel.initialized_ = true ;
    this.displayEditBox('0', this.DEMOGRAPHICS_DIALOG_NEW_TITLE, 'false') ;
  } , // end addNew


  /**
   * This function handles a request to edit a person's demographic information
   * by displaying the demographics edit box.
   *
   * A check is made, before the edit box is displayed, to see if there are
   * any unsaved changes for the profile.  Specifically, these would be
   * unsaved autosave data from the main phr form or the test panel forms.
   * If unsaved data is found a message is displayed asking the user to clear
   * up the unsaved changes before editing the demographic data (and the
   * edit request is terminated).
   *
   * @param idShown the id shown for the phr to be edited
   * @param pseudonym the pseudonym of the phr to be edited
   * @param row_s the number (as a string) used as a suffix for the form
   *  fields displayed for the current phr
   * @param readonly flag indicating whether or not the user is restricted
   *  to read-only access to the phr; passed as a string
   * @returns nothing
   */
  editDemographics: function(idShown, pseudonym, row_s, readonly) {
    if (this.checkForUnsavedChanges(idShown, pseudonym) == false) {
      if (this.getDemographicsData(idShown, pseudonym)) {
        this.currentIdShown_ = idShown ;
        if (readonly == 'true')
          this.displayEditBox(row_s, this.DEMOGRAPHICS_DIALOG_VIEW_TITLE,
                              readonly);
        else
          this.displayEditBox(row_s, this.DEMOGRAPHICS_DIALOG_UPDATE_TITLE,
                              readonly);
      }
    }
  } , // editDemographics


 /**
  * This function displays the "Loading ... Please Wait" message block and
  * then loads the main PHR details page (by resetting the document location).
  * I added the display of the loading message because, if this (or the link)
  * just sets the document location, it takes awhile for the form to come up -
  * and the user is left wondering what the heck is going on.
  * 
  * @param idShown the idShown for the current profile
  * @returns none
  */
  showHealthSummary: function(idShown) {
    $('loading_msg').setStyle({display: 'block'}) ;
    Def.setDocumentLocation('/profiles/' + idShown + ';edit') ;
  } ,


  /**
   * This function handles an import request by ... doing nothing right now
   * except putting up an alert letting the user know that they chose
   * the option (and that nothing will happen).
   *
   * @param idShown the id shown for the phr for which data is to be imported
   * @returns nothing
   */
  handleImportRequest: function(idShown) {
   this.showWarning(this.IMPORT_FUNCTION_MSG, this.ERROR_MSG_BOX_TITLE) ;
  } , // handleImportRequest


 /**
   * This function handles a request to share access to the current PHR
   * by ... doing nothing right now except putting up an alert letting the
   * user know that they chose the option (and that nothing will happen).
   *
   * @param idShown the id shown for the phr to be shared
   * @param rowS the string version of the row number for the profile
   *  to be shared
   * @returns nothing
   */
  handleShareInviteRequest: function(idShown, rowS) {
   this.currentIdShown_ = idShown ;
   this.currentRowSNum_ = rowS ;
    // Build the share invitation dialog if necessary.  Use the
    // options hash format for the button specifications, so that the
    // buttons will get IDs.  They need IDs to be included in the navigation.
    if (!this.shareInviteDialog_) {
      this.shareInviteDialog_ = new Def.ModalPopupDialog({
        width: 800,
        stack: true,
        appendTo: '#main_form' ,
        buttons: [{
          text: Def.PHRHome.FORM_LABELS["share_invite_btn"] ,
          id: "shareInviteBtn" ,
          class: "rounded" ,
          click: function() {
            this.launchShareInvitation() ;
          }.bind(this)} , {
          text: "Cancel",
          id: "shareCancelBtn",
          class: "rounded" ,
          click: function() {
            this.clearShareInvite() ;
            this.shareInviteDialog_.buttonClicked_ = true ;
            this.shareInviteDialog_.dialogOpen = false ;
            this.shareInviteDialog_.hide();
          }.bind(this)}]
      }) ;

      var inviteBox = $('fe_share_invitation_1_0');
       // add the "required" text to the box
      var imgSrc = Def.blankImage_ ;
      var rimg = new Element('img', {class: 'requiredImg sprite_icons-phr-required',
                                     src: imgSrc,
                                     alt: 'required field'})
      rimg.addClassName('requiredImgLabel');
      var txt = new Element('span', {class: 'requiredText',
                                     style: 'vertical-align:middle;' +
                                            'line-height: 10px'}).update(' indicates required information');
      var req = new Element('div', {class:'reqNotice', id:'reqInfo',
                                    style:'display: block;'});
      req.appendChild(rimg);
      req.appendChild(txt);
      var prevBtn = $('fe_invite_preview_btn_1_1') ;
      $('fe_share_invitation_1_0_expcol').insertBefore(req, prevBtn) ;

      // Set the title of the box just once, here, because it doesn't change.
      // The username, system name, and from lines don't change either, so
      // set them here.
      this.shareInviteDialog_.setTitle(this.SHARE_INVITE_DIALOG_TITLE);
      $('issuer_id').innerHTML = Def.PHRHome.userName_ ;
      $('phr_system_name').innerHTML = Def.PHRHome.PHR_SYSTEM_NAME ;
      $('from_lines').innerHTML = Def.PHRHome.SHARE_INVITE_FROM_LINES ;

      // Set the content of the box here.  We'll update the changable parts
      // below, since they change each time.
      this.shareInviteDialog_.setContent(inviteBox);
      inviteBox.removeClassName('hidden_field') ;
      // Disable the dummy "accept" button shown on the invitation
      $('fe_dummy_accept_btn_1_1_1').disabled = true ;
      Def.Navigation.doNavKeys(0,
                               Def.Navigation.navSeqsHash_['fe_email_1_1'][1],
                               true, true, false) ;      
    } // end if the dialog hasn't already been created

    // Fill in the profile name where it appears in the text.  We have to
    // wait on the other values until the user fills in the fields.
    var possessive = $('name_string_' + rowS).innerHTML + "'s";
    $('hdr_prof_name').innerHTML = possessive;
    $('msg_prof').innerHTML = possessive;

    // Figure the expiration date
    var expDate = new Date();
    expDate.setDate(expDate.getDate() + 30);
    var expDate = $J.datepicker.formatDate("DD, MM d, yy", expDate);
    $('expire_date').innerHTML = expDate ;

    // Show the box
    this.shareInviteDialog_.buttonClicked_ = false ;
    this.shareInviteDialog_.show();

  } , // handleShareInviteRequest


 /**
   * This function is called for a change event from the fe_target_name_1_1
   * field.  The event handler is set in the field descriptions for that field.
   * This updates the text in the sample invitation email that uses the
   * contents of the target_name field.
   *
   * @param none
   * @returns nothing
   */
  inviteeNameUpdated: function() {
    var targetName = Def.getFieldVal($('fe_target_name_1_1')) ;
    $('target_name').innerHTML = targetName;
  } ,


/**
   * This function is called for a change event from the fe_issuer_name_1_1
   * field.  The event handler is set in the field descriptions for that field.
   * This updates the text in the sample invitation email that uses the
   * contents of the issuer_name field.
   *
   * @param none
   * @returns nothing
   */
  issuerNameUpdated: function() {
    var issuerName = Def.getFieldVal($('fe_issuer_name_1_1')) ;
    $('issuer_name').innerHTML = issuerName ;
    $('issuer_name2').innerHTML = issuerName ;
  } ,
          

 /* This function displays the "Loading ... Please Wait" message block and
  * then loads the main PHR details page (by resetting the document location).
  * I added the display of the loading message because, if this (or the link)
  * just sets the document location, it takes awhile for the form to come up -
  * and the user is left wondering what the heck is going on.
  *
  * @param idShown the idShown for the current profile
  * @returns none
  */
  showTestsAndTrackers: function(idShown) {
    $('loading_msg').setStyle({display: 'block'}) ;
    Def.setDocumentLocation('profiles/' + idShown + '/panels') ;
  } ,


  /**
   * This function handles an export request displaying the exportDialog_
   * box.  If this is the first export request, the dialog box is constructed
   * here.
   *
   * @param idShown the id shown for the phr for which data is to be imported
   * @param pseudonym the pseudonym for the phr
   * @returns nothing
   */
  handleExportRequest: function(idShown, pseudonym) {

    this.currentIdShown_ = idShown ;
    // Build the export options dialog if necessary.  Use the
    // options hash format for the button specifications, so that the
    // buttons will get IDs.  They need IDs to be included in the navigation.
    if (!this.exportDialog_) {
      this.exportDialog_ = new Def.ModalPopupDialog({
        width: 800,
        stack: true,
        appendTo: '#main_form' ,
        buttons: [{
          text: this.FORM_LABELS["export"] ,
          id: "exportExportBtn" ,
          class: "rounded" ,
          click: function() {
            this.launchExport() ;
          }.bind(this)} , {
          text: "Cancel",
          id: "exportCancelBtn",
          class: "rounded" ,
          click: function() {
            this.exportDialog_.buttonClicked_ = true ;
            this.exportDialog_.dialogOpen = false ;
            this.exportDialog_.hide();
          }.bind(this)}]
      }) ;

      // Set the content of the dialog - first the text elements
      this.exportDialog_.setContent(
        '<div id="exportWarning">' + this.EXPORT_DIALOG_WARNING_IMAGE +
                                 ' ' + this.EXPORT_DIALOG_WARNING + '</div>' +
        '<div id="exportContent">' +
          '<div id="exportDialogFirstLine">' + this.EXPORT_DIALOG_MAIN_LINE +
          '</div>' +
          '<div id="exportMessage">' + this.EXPORT_DIALOG_TEXT + '</div>' +
        '</div>');

      $('main_form_name').innerHTML = this.FORM_LABELS["main_form"];
      $('test_form_name').innerHTML = this.FORM_LABELS["tests"]
      // Get the file format radio buttons, append them to the current
      // content, and set the default format button to checked
      // NO RADIO BUTTONS right now (Jan 10, 2014).  Until we have more
      // than one format, we don't need 'em.  per meeting 1/10/14.  lm
//      var radioButtonSet = $('fe_button_set_1') ;
//      $('exportContent').appendChild(radioButtonSet);
//      radioButtonSet.removeClassName('hidden_field') ;
//      var radioLabels = radioButtonSet.getElementsByTagName('label') ;
//      var rlCount = radioLabels.length ;
//      for (var i=0; i < rlCount &&
//           radioLabels[i].innerHTML.indexOf(this.EXPORT_DEFAULT_FORMAT_LABEL) < 0;
//           i++) ;
//      if (i < rlCount ) {
//        radioLabels[i].firstElementChild.checked = true ;
//        radioLabels[i].id = 'defRadioButton' ;
//      }
      // update the navigation sequence data to reflect the fact that the
      // predefined radio buttons were moved into the dialog and that two
      // buttons were added.  Even though we're not showing the radio buttons
      // right now, they're still there, and we can use them as the starting
      // point for the renumbering.
      Def.Navigation.doNavKeys(0,
                               Def.Navigation.navSeqsHash_['fe_button_set_1R_1'][1],
                               true, true, false) ;

      // Create a link to help text that explains the difference in the
      // file formats, and add it to the content after the buttons.
      // NOT RIGHT NOW - only one file format type
//      var helpLink = new Element('span', {'id' : 'export_file_help_link',
//                'onclick' : "Def.Popups.openHelp(this, " +
//                "'/help/export_file_format.shtml'); event." +
//                "stopPropagation();"}).update(this.EXPORT_HELP_ME_CHOOSE_LINK);
//      $('exportContent').appendChild(helpLink) ;
    } // end if the dialog hasn't already been created

    // Set the box title (goes in the blue header along the top).
    // Set it each time the box is displayed since it includes the current
    // phr name
    var possessive = pseudonym + "'s" ;
    var titleName = this.EXPORT_DIALOG_TITLE.replace('NAME',
                                                      possessive)
    this.exportDialog_.setTitle(titleName);
    $('possessive_pseudonym').innerHTML = possessive;
    $('phr_pseudonym').innerHTML = pseudonym;

    this.exportFileName_ = pseudonym;
    while (this.exportFileName_.indexOf(' ') >= 0)
      this.exportFileName_ = this.exportFileName_.replace(' ', '');
    var now = new Date();
    var dtString = '_' + $J.datepicker.formatDate("yyMdd", now) +
                   now.getHours() + now.getMinutes() + now.getSeconds() + '.xls';
    this.exportFileName_ += dtString ;
    $('export_filename').innerHTML = this.exportFileName_ ;
    this.exportDialog_.buttonClicked_ = false ;

    this.exportDialog_.show();

  } , // end handleExportRequest


 /**
   * This function handles a request to show pending access invitations that
   * are waiting for the user to accept or decline them.
   *
   * No parameters needed
   * @returns nothing
   */
  handleShareListRequest: function(idShown, rowS) {

    this.currentIdShown_ = idShown ;
    this.currentRowSNum_ = rowS ;
    // Build the pending invitations dialog if necessary.  Use the
    // options hash format for the button specifications, so that the
    // buttons will get IDs.  They need IDs to be included in the navigation.
    if (!this.accessListDialog_) {
      this.accessListDialog_ = new Def.ModalPopupDialog({
        width: 700,
        stack: true,
        appendTo: '#main_form' ,
        buttons: [{
          text: "Invite Another Person" ,
          id: "inviteAnotherBtn" ,
          class: "rounded" ,
          click: function() {
            this.handleShareInviteRequest(Def.PHRHome.currentIdShown_,
                                          Def.PHRHome.currentRowSNum_ ) ;
            this.accessListDialog_.buttonClicked_ = true ;
            this.accessListDialog_.dialogOpen = false ;
            this.accessListDialog_.hide();
          }.bind(this)} , {
          text: "Close",
          id: "closeAccessListBoxBtn",
          class: "rounded" ,
          click: function() {
            this.accessListDialog_.buttonClicked_ = true ;
            this.accessListDialog_.dialogOpen = false ;
            this.accessListDialog_.hide();
          }.bind(this)}]
      }) ;

      var accessListBox = $('fe_access_list_1_0');

      // Set the content of the box here.  We'll update the changable parts
      // below, since they change each time.
      this.accessListDialog_.setContent(accessListBox);
    } // end if the box has not been created yet

    // Set the title of the box
    var phrName = $('name_string_' + rowS).textContent;
    var titleText = Def.PHRHome.ACCESS_LIST_DIALOG_TITLE ;
    titleText = titleText.replace('PNAME', phrName)
    this.accessListDialog_.setTitle(titleText);
    var titleLine = $('fe_access_list_header_1_1').firstChild.textContent;
    titleLine = titleLine.replace('PNAME', phrName) ;
    $('fe_access_list_header_1_1').firstChild.textContent = titleLine ;

    // Get the access list
    new Ajax.Request('/phr_home/get_access_list', {
      method: 'get' ,
      parameters: {
        authenticity_token: window._token ,
        id_shown: idShown
      } ,
      asynchronous: false,
      onFailure: function(response) {
        this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
      }.bind(this),
      onSuccess: function(response) {
        //var listHTML = JSON.parse(response.responseText) ;
        var listHTML = response.responseText;
        // insert the list after the header text
        var currentBox = $('access_list_box') ;
        currentBox.parentNode.innerHTML = listHTML;
        //currentBox.parentNode.replaceChild(theList, currentBox);
        Def.IDCache.addToCache($('fe_access_list_1_0_expcol')) ;

        // Add the elements to the navigation sequence, starting with
        // the dummy element we need to have something to add after.
        Def.Navigation.doNavKeys(0,
             Def.Navigation.navSeqsHash_['fe_dummy_access_input_fld_1_1'][1],
             true, true, false) ;
        $('fe_access_list_1_0').removeClassName('hidden_field') ;
        // Show the box
        this.accessListDialog_.buttonClicked_ = false ;
        this.accessListDialog_.show();
      }.bind(this) // end onSuccess
    }); // end request

    document.getElementById('main_form').style.cursor = "auto" ;

  } , // handleShareListRequest


  /**
   * This function handles a remove (archive) request.  It issues an ajax call
   * to the server to flag the profile as removed.  It then updates the form as
   * follows:
   * * hides the form rows in the active phrs section for the phr that was
   *   just removed; and
   * * if the Removed PHRs section is not displayed, makes sure that the
   *   Removed PHRs toggle (different from section) is displayed, otherwise,
   *   if the Removed PHRs section is already displayed, redraws it so that
   *   the newly removed profile will be included.
   *
   * @param idShown the id shown for the phr to be removed
   * @param row_s the number (as a string) used as a suffix for the form
   *  fields displayed for the current phr
   * @returns nothing
   */
  removeProfile: function(idShown, row_s) {

    // create success message
    var profName = $('name_string_' + row_s).textContent ;

    // If the table of removed profiles is not currently displayed, set the
    // message to tell the user to use the removed profiles toggle to display
    // the list - and make sure that it's visible.
    // Toggle REMOVED 3/4/14 - but it may come back, so don't take this out
    //if ($('fe_removed_profiles_0').style.display != 'block') {
    //  var successMessage = 'The PHR for ' + profName + ' has been removed.  ' +
    //                       'Click the "Removed PHRs" link below for a list of ' +
    //                       'your removed PHRs.';
    //  if (Def.PHRHome.remProfsToggleShown_ == false) {
    //    $('fe_removed_profiles_toggle').setStyle({display: "block"}) ;
    //    Def.PHRHome.remProfsToggleShown_ = true ;
    //  }
    //}

    // Otherwise refer them to the displayed list of removed profiles.
    //else {
    var successMessage = 'The PHR for ' + profName + ' has been flagged as ' +
                         '"inactive".  See the "Inactive PHRs" section below ' +
                         'for a list of your inactive PHRs.' ;
    //}

    new Ajax.Request('/form/archive_profile', {
      method: 'post' ,
      parameters: {
        authenticity_token: window._token ,
        form_name: 'phr_home' ,
        profile_id: idShown
      } ,
      asynchronous: false,
      onFailure: function(response) {
        this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
      }.bind(this),
      onSuccess: function(response) {
        // make sure the link lines for this profile are collapsed and
        // then collapse the main profile line
        var linkLines = document.getElementsByClassName("links_line_" + row_s);
        if (linkLines[0].style.display === 'table-row') {
          this.toggleLinksSections(row_s) ;
        }
        var mainLine = $('main_profile_line_' + row_s) ;
        mainLine.style.display = "none" ;
        this.activeCount_ -= 1 ;
        Def.showNotice(successMessage);

        // If the removed profiles section is open, redraw it so it will 
        // include the newly removed profile.
        // Otherwise, the link for the section should already be showing
        // - because we checked that when we constructed the success message
        // NO - just redraw the section.  3/4/14 lm
        //if ($('fe_removed_profiles_0_expcol').style.display === 'block')
        this.drawRemovedSection() ;

        // If there are no more active profiles, hide the active section.
        if (this.activeCount_ === 0) {
          $('profiles_list').setStyle({display: 'none'}) ;
          //this.showWarning(this.NO_ACTIVE_PROFILES_MSG, this.NO_PROFILES_TITLE) ;
        }
      }.bind(this) // end onSuccess
    }); // end Ajax request
  } , // end removeProfile


  /**
   * This function handles a request to restore (unarchive) a profile.  It
   * issues an ajax call to the server to flag the profile as restored.  It then
   * updates the form as follows:
   * * if the profile was previously on the active list (was active, then
   *   removed, and now restored) the listing for it is unhidden;
   * * else it issues another ajax call to the server to get the listing for
   *   the profile, finds the correct location for the listing and inserts
   *   it in the active list, and calls the message manager to update the
   *   health reminders link for the profile;
   * * then updates the removed PHRs section by redrawing it if there are
   *   other removed profiles for the user or, if there are no other profiles,
   *   replacing the section with the Removed PHRs toggle.
   *
   * @param idShown the id shown for the phr to be restored
   * @param row_s the number (as a string) used as a suffix for the form
   *  fields displayed for the current phr
   * @returns nothing
   */
  restoreProfile: function(idShown, row_s) {

    // create success message
    var worked = true ;
    var profName = $('rem_name_string_' + row_s).textContent ;
    var successMessage = 'The PHR for ' + profName + ' has been restored.' ;

    new Ajax.Request('/form/unarchive_profile', {
      method: 'post' ,
      parameters: {
        authenticity_token: window._token ,
        form_name: 'phr_home' ,
        profile_id: idShown
      } ,
      asynchronous: false,
      onFailure: function(response) {
        worked = false ;
        this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
      }.bind(this) ,
      onSuccess: function(response) {

        // Increment the active count and, if the increment is set to 1,
        // display the profiles list section, which should previously have
        // been hidden because there were no active profiles
        this.activeCount_ += 1 ;
        if (this.activeCount_ === 1) {
          $('profiles_list').setStyle({display: 'block'}) ;
        }

        // Check to see if this person is already in the active list, just
        // hidden.  This will be true if this person was removed and restored
        // in the same session.  If he/she is, just unhide the main row.
        // (Leave the link lines hidden - the user can open them.
        var active_row = this.idsShown_[idShown] ;
        if (active_row) {
          $('main_profile_line_' + active_row).style.display = "table-row" ;
        }
        // Otherwise get a listing for this person and insert it.
        else {
          var rowNum = ++this.lastRowNum_ ;
          new Ajax.Request('/phr_home/get_one_active_profile_listing', {
            method: 'get' ,
            parameters: {
              authenticity_token: window._token ,
              row_num: rowNum ,
              id_shown: idShown
            } ,
            asynchronous: false,
            onFailure: function(response) {
              worked = false ;
              this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
            }.bind(this) ,
            onSuccess: function(rowResp) {
              this.idsShown_[idShown] = rowNum ;
              this.lastRowNum_ = Object.keys(this.idsShown_).length ;

              // figure out where it goes and insert it - use profName
              // get names from all with class = 'name_string'
              var names = document.getElementsByClassName('name_string') ;
              if (names.length == 0) {
                var header_row = document.getElementById('profile_list_header_row');
                header_row.insertAdjacentHTML('afterend', rowResp.responseText);
              }
              else {
                var bef = 0;
                for ( ; bef < names.length &&
                        names[bef].innerHTML < profName; bef++) ;
                if (bef < names.length) {
                  var befID = names[bef].id ;
                  var befNum = befID.substr(befID.lastIndexOf('_') + 1) ;
                  var befRow = $('main_profile_line_' + befNum) ;
                  befRow.insertAdjacentHTML('beforebegin', rowResp.responseText);
                }
                else {
                  var aftID = names[bef-1].id;
                  var aftNum = aftID.substr(aftID.lastIndexOf('_') + 1) ;
                  var aftRow = $('main_profile_line_' + aftNum) ;
                  // move to the third links row for the profile, since
                  // we want to insert the new stuff after those
                  for (var v=0; v < 3; v++ )
                    aftRow = aftRow.nextElementSibling ;
                  aftRow.insertAdjacentHTML('afterend', rowResp.responseText) ;
                }
              }
              // Get the reminders count
              var rowNumStr = rowNum.toString() ;
              var profile_data = {};
              var hLinkID = 'health_reminders_link_' + rowNumStr;
              profile_data[idShown] = [hLinkID, hLinkID,
                                       this.HEALTH_REMINDERS_TITLE] ;
              Def.attachMessageManagers(profile_data);

              // Update the id cache for the active profiles list
              Def.IDCache.addToCache($('profiles_list'));
            }.bind(this) // end onRowGetSuccess
          }) ; // end ajax request to get the active row data
        } // end if this profile is not currently in the profiles list
      }.bind(this) // end onSuccess for unarchive request
    }); // end Ajax unarchive request

    // If there was no problem with either of the ajax calls, redraw the
    // removed profile section with the unarchived profile removed, and
    // let the user know it worked.   If there was a problem a message has
    // already been displayed.
    if (worked) {
      this.drawRemovedSection() ;
      Def.showNotice(successMessage);
    }
  } ,  // end restoreProfile


  /**
   * This function handles a request to delete a profile by displaying the
   * confirmDelete dialog, which it creates if it has not already been
   * created.
   *
   * @param idShown the id shown for the phr to be restored
   * @param row_s the number (as a string) used as a suffix for the form
   *  fields displayed for the current phr
   * @returns nothing
   */
  deleteProfile: function(profile_id, row_s) {

    this.currentIdShown_ = profile_id ;
    this.currentRowSNum_ = row_s ;
    // build the confirm delete dialog
    var profName = $("rem_name_string_" + row_s).innerHTML ;
    if (!this.confirmDeletePhrDialog_) {
      this.confirmDeletePhrDialog_ = new Def.ModalPopupDialog({
        width: 500,
        stack: true,
        buttons: [{
          text: "Yes, Delete" ,
          id: "confDeleteYesBtn",
          class: "rounded",
          click: function() {
            this.confirmDeletePhrDialog_.buttonClicked_ = true ;
            this.doDeleteProfile() ;
            this.confirmDeletePhrDialog_.hide();
          }.bind(this)}, {
          text: "No, Cancel the request",
          id: "confDeleteNoBtn" ,
          class: "rounded" ,
          click: function() {
            this.confirmDeletePhrDialog_.buttonClicked_ = true ;
            this.confirmDeletePhrDialog_.hide();
          }.bind(this)}]
        }) ;

      this.confirmDeletePhrDialog_.setTitle(this.DELETE_PHR_DIALOG_TITLE);
      this.confirmDeletePhrDialog_.setContent(
        '<div id="confirmDeleteText" style="margin-bottom: 1em">' +
        this.DELETE_PHR_DIALOG_TEXT + '</div>');
    } // end if the dialog has not already been built

    $("confDeleteName").innerHTML = profName ;
    this.confirmDeletePhrDialog_.buttonClicked_ = false ;
    
    this.confirmDeletePhrDialog_.show();
  }, // end deleteProfile


 /**
   * This function handles a request to show pending access invitations that
   * are waiting for the user to accept or decline them.
   *
   * No parameters needed
   * @returns nothing
   */
  showPendingInvitations: function() {

    // Build the pending invitations dialog if necessary.  Use the
    // options hash format for the button specifications, so that the
    // buttons will get IDs.  They need IDs to be included in the navigation.
    if (!this.pendingInvitationsDialog_) {
      this.pendingInvitationsDialog_ = new Def.ModalPopupDialog({
        width: 800,
        stack: true,
        appendTo: '#main_form' ,
        buttons: [{
          text: "OK" ,
          id: "pendingInviteBtn" ,
          class: "rounded" ,
          click: function() {
            this.processPendingInvitations() ;
            this.pendingInvitationsDialog_.buttonClicked_ = true ;
            this.pendingInvitationsDialog_.dialogOpen = false ;
            this.pendingInvitationsDialog_.hide();
          }.bind(this)} , {
          text: "Cancel",
          id: "cancelPendingBoxBtn",
          class: "rounded" ,
          click: function() {
            this.pendingInvitationsDialog_.buttonClicked_ = true ;
            this.pendingInvitationsDialog_.dialogOpen = false ;
            this.pendingInvitationsDialog_.hide();
          }.bind(this)}]
      }) ;

      var pendingListBox = $('fe_pending_invitations_1_0');
      // Set the title of the box just once, here, because it doesn't change.
      // The username, system name, and from lines don't change either, so
      // set them here.
      this.pendingInvitationsDialog_.setTitle(this.PENDING_INVITATIONS_DIALOG_TITLE);

      // Set the content of the box here.  We'll update the changable parts
      // below, since they change each time.
      this.pendingInvitationsDialog_.setContent(pendingListBox);
    }

    // Get the list of pending invitations
    new Ajax.Request('/share_invitation/get_pending_share_invitations', {
      method: 'get' ,
      parameters: {
        authenticity_token: window._token ,
      } ,
      asynchronous: false,
      onFailure: function(response) {
        this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
      }.bind(this),
      onSuccess: function(response) {
        //var listHTML = JSON.parse(response.responseText) ;
        var listHTML = response.responseText;
        // create an element for the listings
        var theList = new Element('div',
                          {'id' : 'pending_invites_box'}).update(listHTML);
        // insert the list after the header text
        var currentBox = $('pending_invites_box') ;
        currentBox.parentNode.replaceChild(theList, currentBox);
        Def.IDCache.addToCache($('fe_pending_invitations_1_0_expcol')) ;

        // Add the elements to the navigation sequence.
        // First find the first element in the forms[0].elements array
        // that precedes the first one from this dialog.  They will be
        // form input elements (buttons, text input, etc) and since this
        // dialog does not start out with any input elements when the
        // form is loaded, there's nothing to start with, so we have a dummy
        // field.
        var i = document.forms[0].element
        Def.Navigation.doNavKeys(0,
             Def.Navigation.navSeqsHash_['fe_dummy_input_fld_1_1'][1],
             true, true, false) ;
        $('fe_pending_invitations_1_0').removeClassName('hidden_field') ;
        // Show the box
        this.pendingInvitationsDialog_.buttonClicked_ = false ;
        this.pendingInvitationsDialog_.show();
      }.bind(this) // end onSuccess
    }); // end request

    document.getElementById('main_form').style.cursor = "auto" ;

  } , // showPendingInvitations


  /**
   * This function handles a request to remove the currrent user's access to a
   * phr owned by another user by putting up a confirmation box to make sure
   * the access should be deleted.  If the deletion is confirmed the
   * confirmDeleteRemoveDialog_ box will call the doRemoveAccess function to
   * perform the actual removal.
   *
   * @param idShown the id shown for the phr for which access is to be removed
   * @param rowS the number (as a string) used as a suffix for the form
   *  fields displayed for the current phr
   * @returns nothing
   */
  removeMyAccess: function(idShown, rowS) {
    this.accessIdShown_ = idShown;
    this.accessUserId_ = null;
    this.accessRow_ = rowS ;
    this.myAccessRemoved_ = true ;

    if (!this.confirmRemoveAccessDialog_)
      this.createRemoveAccessBox();

    var content = Def.PHRHome.REMOVE_MY_ACCESS_TEXT ;
    var phrName = $('o_name_string_' + rowS).textContent ;
    content = content.replace('PNAME', phrName);
    this.confirmRemoveAccessDialog_.setContent(
        '<div id="confirmRemoveAccessText" style="margin-bottom: 1em">' +
        content + '</div>');
    this.confirmRemoveAccessDialog_.buttonClicked_ = false ;
    this.confirmRemoveAccessDialog_.show();
  } , // removeMyAccess


  /**
   * This function handles a request to remove the access to a phr owned by
   * the current user from an other user, as shown in the access list
   * dialog box.  This puts up a confirmation box to make sure
   * the access should be removed.  If the removal is confirmed the
   * confirmRemoveAccessDialog_ box will call the doRemoveAccess function to
   * perform the actual removal.
   *
   * @param idShown the id shown for the phr for which access is to be removed
   * @param rowS the number (as a string) used as a suffix for the form
   *  fields displayed on the access list
   * @param userId the id for the user whose access is to be removed
   * @returns nothing
   */
  removeThisAccess: function(idShown, rowS, userId) {
    this.accessIdShown_ = idShown;
    this.accessUserId_ = userId;
    this.accessRow_ = rowS ;

    if (!this.confirmRemoveAccessDialog_)
      this.createRemoveAccessBox();

    var content = Def.PHRHome.REMOVE_THIS_ACCESS_TEXT ;
    var phrName = $('access_phr_name').textContent ;
    var otherName = $('accessor_name_' + rowS).textContent;
    content = content.replace('PNAME', phrName) ;
    content = content.replace(/ONAME/g, otherName) ;
    this.confirmRemoveAccessDialog_.setContent(
        '<div id="confirmRemoveAccessText" style="margin-bottom: 1em">' +
        content + '</div>');
    this.confirmRemoveAccessDialog_.buttonClicked_ = false ;
    this.confirmRemoveAccessDialog_.show();
  } , // removeThisAccess


  /**
   * This function performs an actual access removal as requested by either
   * the removeMyAccess or removeThisAccess function.  This includes an ajax
   * call to have the access removed on the server as well as updating the
   * form to reflect the removal
   *
   * no parameters, no return
   */
  doRemoveAccess: function() {

    new Ajax.Request('/phr_home/remove_access', {
      method: 'put' ,
      parameters: {
        authenticity_token: window._token ,
        user_id: this.accessUserId_,
        id_shown: this.accessIdShown_
      } ,
      asynchronous: false,
      onFailure: function(response) {
        this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
      }.bind(this),
      onSuccess: function(response) {
        if (this.myAccessRemoved_) {
          // make sure the link lines for this profile are collapsed and
          // then collapse the main profile line
          var linkLines = document.getElementsByClassName("o_links_line_" +
                                                          this.accessRow_);
          if (linkLines[0].style.display === 'table-row') {
            this.toggleLinksSections(this.accessRow_, 'o_') ;
          }
          var mainLine = $('other_profile_line_' + this.accessRow_) ;
          mainLine.style.display = "none" ;
          this.othersCount_ -= 1;
          
          // if there are no more "other" profiles, close the section
          if (this.othersCount_ === 0) {
            expColSection('fe_other_profiles_0_expcol') ;
            $('fe_other_profiles_0').setStyle({display: 'none'}) ;
          }
 
          this.myAccessRemoved_ = false ;
        }
        else {
          var listSize = parseInt($('access_count').innerHTML)
          if (listSize == 1) {
            this.accessListDialog_.hide()
          }
          else {
            $('access_count').innerHTML = String(listSize - 1) ;
            $('access_row_' + this.accessRow_).setStyle({display: 'none'}) ;
          }
        } // end if this is a request to remove someone else's access

        this.confirmRemoveAccessDialog_.hide() ;
        this.accessRow_ = '';

     }.bind(this) // end onSuccess
    }); // end request
  } , // doRemoveAccess


  /**
   * This function creates the confirmRemoveAccessDialog_ box.  It should only
   * be called once, when it is first requested.
   *
   * @param idShown the idShown for the phr from which to remove access
   * @param the id of the user for which access to the phr is to be removed
   *  fields displayed for the current phr
   * @returns nothing
   */
  createRemoveAccessBox: function() {
    this.confirmRemoveAccessDialog_ = new Def.ModalPopupDialog({
      width: 500,
      stack: true,
      buttons: [{
        text: "Yes, Remove" ,
        id: "confRemoveAccessYesBtn",
        class: "rounded",
        click: function() {
          this.confirmRemoveAccessDialog_.buttonClicked_ = true ;
          this.doRemoveAccess() ;
          this.confirmRemoveAccessDialog_.hide();
        }.bind(this)}, {
        text: "No, Cancel the request",
        id: "confRemoveAccessNoBtn" ,
        class: "rounded" ,
        click: function() {
          this.confirmRemoveAccessDialog_.buttonClicked_ = true ;
          this.accessRow_ = '';
          this.myAccessRemoved_ = false ;
          this.confirmRemoveAccessDialog_.hide();
        }.bind(this)}]
      }) ;
    this.confirmRemoveAccessDialog_.setTitle(this.REMOVE_ACCESS_DIALOG_TITLE);
  }, // end createRemoveAccessBox



  /**            Functions not directly called by the form                 **\

  /**
   * This function performs a check for any unsaved changes that may be pending
   * for a phr.  It is called before a user is allowed to edit the demographics
   * data for a phr, to prevent unsaved changes from being overwritten in the
   * autosave tables.
   *
   * @param idShown the id shown for the phr to be checked
   * @param pseudonym name on the phr
   * @returns true if there are pending changes; false if not
   */
  checkForUnsavedChanges: function(idShown, pseudonym) {
    var ret = false ;
    new Ajax.Request('/form/has_autosave_data', {
      method: 'get',
      parameters: {
        authenticity_token: window._token,
        profile_id:  idShown ,
        render_to: 'json'
      },
      asynchronous: false ,
      onSuccess: function(transport) {
        var formNames = JSON.parse(transport.responseText) ;
        if (formNames.length > 0) {
          var msg = "You have pending changes for <i>" + pseudonym +
                    "</i> that have not been saved or cancelled.<br><br>" +
                    "These changes are from your last update of the " ;
          var pendingData = ''
          if (formNames.indexOf('phr') >= 0) {
            pendingData += this.FORM_LABELS['main_form'] + " data" ;
            if (formNames.length > 1)
              pendingData += " and " + this.FORM_LABELS['tests'] + " data" ;
          }
          else {
            pendingData += this.FORM_LABELS['tests'] + " data" ;
          }
          msg += pendingData + " for <i>" + pseudonym + ".</i><br><br>" +
                 "These changes must be completed (saved or cancelled) " +
                 "before changes are made to any other data.<br><br>Please " +
                 "click on the <b>OK</b> button and then, when this small " +
                 "box is gone, update the " + pendingData + "." ;
          this.showWarning(msg, this.ERROR_MSG_BOX_TITLE) ;
          ret = true ;
        } // end if there are unsaved changes
      }.bind(this), // end onSuccess
      onFailure: function(response) {
        ret = true ;
        this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
      }.bind(this)
    }) ; // end request
    return ret ;
  } , // end checkForUnsavedChanges


  /**
   * This function handles the Ajax call to the server to get demographics data
   * to be updated.  It passes the acquired date to the DataModel.setup function,
   * which will populate the form fields. It includes a call to run form rules
   * and to set up validation stuff for unique pseudonyms.
   *
   * Errors in acquiring the data will produce error messages - and logout if
   * appropriate.
   *
   * @param idShown the id shown for the phr to be updated
   * @param pseudonym the pseudonym for the phr to be updated
   * @returns true if the data was successfully acquired; false if not
   */
  getDemographicsData: function(idShown, pseudonym) {

    Def.setWaitState(false) ;
    var ret = false ;
    // construct ajax request
    new Ajax.Request('/form/edit_profile_with_form', {
      method: 'get',
      parameters: {
        authenticity_token: window._token,
        form_name: 'phr_home' ,
        id:  idShown ,
        render_to: 'json'
      },
      asynchronous: false ,
      onSuccess: function(transport) {
        ret = true ;
        var formData = JSON.parse(transport.responseText) ;
        if (formData && formData.length > 0) {
          Def.DataModel.setup(formData, false, null, false) ;
          // Def.Rules.runFormRules() is not needed at the moment because
          // there are no rules defined on the form.  If any are subsequently
          // defined, uncomment this call.
          //Def.Rules.runFormRules();
          // update data used for validation of unique value fields
          Def.updateUniqueValueValidationData();
          Def.endWaitState(false);
        }
      },
      onFailure: function(transport) {
        Def.endWaitState(false);
        if (transport === 'do_logout') {
          window.location = Def.LOGOUT_URL ;
        }
        else {
          this.showWarning(
                  "There was a problem retrieving the demographics " +
                  'information for ' + pseudonym + '.  Please contact us ' +
                  'using the ' + this.FEEDBACK_FORM_LINK + ' page to provide ' +
                  'further information.', this.ERROR_MSG_BOX_TITLE) ;
        }
      }.bind(this) // end onFailure
    }) ; // end request
    return ret ;
  } , // end getDemographicsData

  
  /**
   * This function displays the demographics edit dialog box.  If this is the
   * first request for the dialog it is created here.
   *
   * @param row_s the number (as a string) used as a suffix for the form
   *  fields displayed for the current phr - or '0' for an add request
   * @param title the title to be displayed for the box.  Since this could
   *  be for an add request or for an update request, the title changes from
   *  request to request.
   * @param readonly flag indicating whether or not the user is restricted to
   *  read-only access for the phr; passed as a string
   * @returns nothing
   */
  displayEditBox: function(row_s, title, readonly) {
    // Build the edit dialog if necessary.  Use the options hash format for
    // the button specifications, so that the buttons will get IDs.  They
    // need IDs to be included in the navigation.
    if (!this.demographicsDialog_) {
      this.demographicsDialog_ = new Def.ModalPopupDialog({
        width: 800,
        stack: true,
        title: "edit box" ,
        appendTo: "#main_form" ,
        buttons: [{
          text: "Save",
          id: "editSaveBtn" ,
          class: "rounded save_button" ,
          click: function() {
            this.saveDemographics(Def.getFieldVal($('fe_pseudonym_1_1'))) ;
          }.bind(this)}, {
          text: "Cancel",
          id: "editCancelBtn" ,
          class: "rounded" ,
          click: function() {
            this.demographicsDialog_.buttonClicked_ = true ;
            this.demographicsDialog_.dialogOpen = false ;
            this.demographicsDialog_.hide();
            this.clearDemographics();
            Def.resetFieldValidations();
          }.bind(this)}]
        }) ;

      var demoBox = $('fe_demographics_1_0') ;

      // add the "required" text to the box
      var imgSrc = Def.blankImage_ ;
      var rimg = new Element('img', {class: 'requiredImg sprite_icons-phr-required',
                                     src: imgSrc,
                                     alt: 'required field'})
      rimg.addClassName('requiredImgLabel');
      var txt = new Element('span', {class: 'requiredText'}).update(' indicates required information');
      var req = new Element('div', {class:'reqNotice', id:'reqInfo'});
      req.appendChild(rimg);
      req.appendChild(txt);
      demoBox.appendChild(req);

      var access_notice = new Element('div', {id: 'access_notice'});
      var access_text = new Element('span', {id: 'access_text'});
      access_notice.appendChild(access_text);
      demoBox.appendChild(access_notice);

      //demoBox.innerHTML = demoBox.innerHTML + reqNoticeHtml;
//    // we tried appending the search results division - that displays the
//    // prefetched lists for gender and ethnicity - to the box that contains
//    // the fields, but that makes the ethnicity list initiate scrolling for
//    // that part of the box (the demoBox) part and most of the list to be
//    // obscured by the panel containing the save and cancel buttons.
//    // Leaving it where it normally is allows it to be displayed over the
//    // buttons section and beyond the dialog box if necessary. 
      //var searchDiv = $('searchResults') ;
      //demoBox.appendChild(searchDiv) ;
      this.demographicsDialog_.setContent(demoBox);
      demoBox.removeClassName('hidden_field') ;
      $('fe_demographics_1_0_expcol').setStyle({display: 'block'}) ;
      Def.Navigation.doNavKeys(0,
                               Def.Navigation.navSeqsHash_['fe_pseudonym_1_1'][1],
                               true, true, false) ;
      this.demoDialogParent_ = this.demographicsDialog_.dialog_[0].parentNode;
    }

    this.affectsReminders_ = false ;
    this.currentRowSNum_ = row_s ;
    this.demographicsDialog_.buttonClicked_ = false ;
    this.demographicsDialog_.setTitle(title);

    // Set the input fields editability based on the readonly setting
    var disabled_flag = (readonly == 'true') ;
    $('fe_pseudonym_1_1').disabled = disabled_flag ;
    $('fe_birth_date_1_1').disabled = disabled_flag ;
    $('fe_gender_1_1').disabled = disabled_flag ;
    $('fe_race_or_ethnicity_1_1').disabled = disabled_flag ;


    // If the input fields are not editable, the save button is hidden and
    // the cancel button text is changed to close
    if (disabled_flag) {
      $('editSaveBtn').style.visibility = 'hidden';
      $('editCancelBtn').firstElementChild.innerHTML = 'Close' ;
      $('access_text').textContent = 
        this.READ_ONLY_NOTICE.replace('%{owner};<br>',
                                    $('owner_label_' + row_s).innerHTML + '; ');
    }

    // Else make sure the save button shows and the cancel button text is
    // correct.  NOTE: I also needed to set disabled to false on the save
    // button.   If the demographics box is shown for a phr where the user
    // has only read access, and the save button is hidden, evidently jquery
    // also sets the button to disabled.  Which is fine, but if the button
    // is subsequently shown, it doesn't remove the disabled flag.   Very
    // annoying.  lm, 11/5/14.
    else {
      $('editSaveBtn').style.visibility = 'visible';
      $('editSaveBtn').disabled = false ;
      $('editCancelBtn').firstElementChild.innerHTML = 'Cancel' ;
      $('access_text').textContent = '';
    }

    this.demographicsDialog_.show();
    
  } , // end displayEditBox


  /**
   * This sets the affectsReminders_ flag to true.  It is called by an 
   * onchange event handler that is assigned to demographics fields where
   * changes could affect the health reminders.  Currently that is the
   * birth date and gender fields.   The onchange handler is specified in
   * the field definitions for those fields.
   * 
   * @param none
   * @returns nothing
   */
  setAffectsReminders: function() {
    Def.PHRHome.affectsReminders_ = true;
  } ,


  /**
   * This function responds to a request from the demographics dialog box to
   * save the demographics data currently in the dialog box.  That data is
   * stored in the DataModel as the user enters/updates it, and the data in
   * the DataModel is what is saved to the tables in the database.
   *
   * This calls Def.doSave (in application_phr.js) to do the actual saving.
   * Before that call it sets up the action_conditions hash, which is used to
   * determine what should be displayed to the user on the successful completion
   * of the save.  If the request is for a new phr, the main PHR page will be
   * displayed on successful save.  Otherwise the request is for an update to
   * the demographics data, and the demographics dialog will be removed on
   * successful save, the name string for the phr will be updated, and the user
   * will remain on the phr home page.
   *
   * @param pseudonym name on the phr
   * @returns nothing
   */
  saveDemographics: function(pseudonym) {

    // Move the dialog box behind the blinder so that the user
    // can't change anything while the data is being saved and
    // so that the "saving" message is visible.  This is particularly
    // important when adding a new person, because after the save
    // the user is taken to the main PHR page, which takes some
    // time to load.
    $J(this.demoDialogParent_).css('zIndex', 10);
    var action_conditions = {} ;
    if (this.currentRowSNum_ === '0') {
      action_conditions['save'] = "1";
      Def.doSave($('editSaveBtn'), false, action_conditions, null,
                  function(){Def.PHRHome.demographicsDialogToFront()}) ;
    }
    else {
      Def.doSave($('editSaveBtn'), true, action_conditions,
                 function(){Def.PHRHome.updateNameString(
                                  Def.DataModel.data_table_.phrs[0].pseudonym)},
                 function(){Def.PHRHome.demographicsDialogToFront()}) ;
    }
  } , // end saveDemographics


  /**
   *  This function brings the demographics dialog box to the front.  It
   *  is meant to be called when the user has decided to save either a new
   *  phr or updates to an existing phr, and the save returns validation
   *  errors.   The dialog is moved behind the blinder when the user chooses
   *  to save (see saveDemographics), and so must be moved to the front
   *  so the user can correct the problems.
   * @returns nothing
   */
  demographicsDialogToFront: function() {
    $J(this.demoDialogParent_).css('zIndex', 100);
  },


  /**
   * This function is invoked at the conclusion of a successful save of
   * updated demographics data for an existing phr.  An ajax call is made
   * to the server to reconstruct the name string, which will include any
   * changes made to it, and the new string replaces the old string on the
   * home page.
   *
   * The pseudonym is passed to the server to find the phr for which an updated
   * string is being requested.  On return from the server, the
   * Def.PHRHome.currentRowSNum_ variable is used to determine which rows
   * contain the listing for the phr being updated.
   *
   * The clearDemographics function is called at the conclusion of this one and
   * the wait state indicator (saving notice) is removed.
   *
   * @param pseudonym name on the phr
   * @returns nothing
   */
  updateNameString: function(pseudonym) {

    // It's possible that we got here after the user tried to save something
    // that was rejected with an error message, fixed the message, and then
    // saved it successfully.   If the error message is still up, we want it
    // to go away.
    $('page_errors').style.display = "none";
    new Ajax.Request('/phr_home/get_name_age_gender_updated_labels', {
      method: 'get',
      parameters: {
        authenticity_token: window._token,
        pseudonym:  pseudonym ,
        id_shown: this.currentIdShown_
      },
      asynchronous: false ,
      onFailure: function(response) {
        this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
      }.bind(this),
      onSuccess: function(response) {    	
        this.demographicsDialog_.buttonClicked_ = true ;
        this.demographicsDialog_.dialogOpen = false ;
        this.demographicsDialog_.hide() ;
        this.demographicsDialogToFront();
        var newLabels = response.responseText.evalJSON() ;
        //var  = response.responseText.split(',') ;
        // if there are 4 elements in the newLabels array, the name included
        // a comma.  Combine the first and second elements, and move the
        // other 2 to the second and third elements
//        if (newLabels.length === 4) {
//          newLabels[0] += ',' + newLabels[1];
//          newLabels[1] = newLabels[2];
//          newLabels[2] = newLabels[3];
//        }

        var oldName = $('name_string_' + this.currentRowSNum_) ;
        var oldAge = $('age_string_' + this.currentRowSNum_) ;
        var oldUpdated = $('last_updated_' + this.currentRowSNum_) ;
        // The name string is actually a button - to get it into the
        // navigation flow.  Def.setFieldVal doesn't work correctly
        // for the button.  It sets a value attribute, but we need it
        // to set the textContent attribute. 3/18/14 lm
        oldName.textContent = newLabels[0] ;
        Def.setFieldVal(oldAge, ', ' + newLabels[1], false) ;
        Def.setFieldVal(oldUpdated, newLabels[2], false) ;

        // If the change was to a field that could affect the health
        // reminders, update the health reminders text on the page
        if (this.affectsReminders_) {
          var profile_data = {};
          var hLinkID = 'health_reminders_link_' + this.currentRowSNum_ ;
          profile_data[this.currentIdShown_] = [hLinkID, hLinkID,
                                                this.HEALTH_REMINDERS_TITLE] ;
          Def.attachMessageManagers(profile_data);
          this.affectsReminders_ = false ;
        }
      }.bind(this) // end onSuccess
    }); // end request
    this.clearDemographics() ;
    this.currentIdShown_ = null ;
    Def.endWaitState();
  } , // end updateNameString


  /**
   * This function clears the input field values of the demographics dialog box.
   *
   * @returns nothing
   */
  clearDemographics: function() {
    Def.setFieldVal($('fe_pseudonym_1_1'), '', false);
    Def.setFieldVal($('fe_birth_date_1_1'), '', false) ;
    Def.setFieldVal($('fe_birth_date_ET_1_1'), '', false) ;
    Def.setFieldVal($('fe_birth_date_HL7_1_1'), '', false) ;
    Def.setFieldVal($('fe_gender_1_1'), '', false) ;
    Def.setFieldVal($('fe_gender_C_1_1'), '', false) ;
    Def.setFieldVal($('fe_race_or_ethnicity_1_1'), '', false) ;
    Def.setFieldVal($('fe_race_or_ethnicity_C_1_1'), '', false) ;
    Def.DataModel.id_shown_ = null ;
  } , // end clearDemographics


  /**
   * This function clears the input field values of the share invitation
   * dialog box.
   *
   * @returns nothing
   */
  clearShareInvite: function() {
    Def.setFieldVal($('fe_email_1_1'), '', false);
    Def.setFieldVal($('fe_confirm_target_email_1_1'), '', false) ;
    Def.setFieldVal($('fe_target_name_1_1'), '', false) ;
    Def.setFieldVal($('fe_issuer_name_1_1'), '', false) ;
    Def.setFieldVal($('fe_personalized_msg_1_1_1'), '', false) ;
    var previewBox = $('fe_invitation_box_1_1_0') ;
    previewBox.addClassName('hidden_field') ;
    $('target_name').innerHTML = '';
    $('issuer_name').innerHTML = '' ;
    $('issuer_name2').innerHTML = '';
    $('personalized_msg').innerHTML = '';
  } , // end clearDemographics



  /**
   * This function sets the format that the user chooses for an export/download.
   * BUT - we're not doing that right now, so it's not being used.
   *
   * @returns nothing
   */
  setExportFormat: function(ele) {
    this.exportFormat_ = ele.value ;
  } , // end setExportFormat


  /**
   * This function handles an export request from the export dialog box.
   * It closes the export dialog, shows the EXPORT_NOTICE, sets the location
   * of the document to the URL for the export_one_profile action, and then, if
   * possible, removes the EXPORT_NOTICE.
   *
   * Using an ajax call for this did not work.  The browser generated "where
   * do you want this" dialog did not come up when I tried this with an ajax
   * call, so I left it as is.
   *
   * The file format sent with the export request is the current setting of
   * Def.PHRHome.exportFormat_ .
   *
   * @param none
   * @returns none
   */
  launchExport: function() {
    this.exportDialog_.buttonClicked_ = true ;
    this.exportDialog_.dialogOpen = false ;
    this.exportDialog_.hide() ;
    // display notice to user
    Def.showNotice(this.EXPORT_NOTICE);
    Def.setDocumentLocation('phr_home/export_one_profile/' +
                             this.currentIdShown_ + '/' +
                             this.exportFormat_ + '/' +
                             this.exportFileName_) ;

    window.setTimeout("Def.hideNotice(true)", 5000) ;
    this.currentIdShown_ = null ;
  } ,  // end launchExport


  /**
   *  This function shows the share invitation that will be sent for a share
   *  request.  The invitation can be customized by the user.
   *
   * @returns nothing
   */
  previewInvitation: function() {
    var previewBox = $('fe_invitation_box_1_1_0') ;
    previewBox.removeClassName('hidden_field') ;
    previewBox.setStyle({display: 'block'});
  },


  /**
   * This function handles an share invitation request from the share invite
   * dialog box.  it sends the ajax request to the server to create and send
   * the share invitation, and reports back on how it went (whether or not the
   * invitation was sent successfully).  And cleans up after itself.
   *
   * @param none
   * @returns none
   */
  launchShareInvitation: function() {

    var targetName = Def.getFieldVal($('fe_target_name_1_1'));
    var successMessage = this.SHARE_INVITE_SUCCESS.replace('<name>', targetName);

    var invite_data = {"target_email" : Def.getFieldVal($('fe_email_1_1')),
                       "target_name"  : targetName,
                       "issuer_name"  : Def.getFieldVal($('fe_issuer_name_1_1')),
                       "personalized_msg" :
                                Def.getFieldVal($('fe_personalized_msg_1_1_1'))};
    new Ajax.Request('/share_invitation', {
      method: 'post' ,
      parameters: {
        authenticity_token: window._token ,
        id_shown: this.currentIdShown_ ,
        invite_data: Object.toJSON(invite_data)
      } ,
      asynchronous: false,
      onFailure: function(response) {
        var resp = JSON.parse(response.responseText) ;
        if (resp['exception_msg']) {
          var displayMsg = this.SHARE_INVITE_FAILURE + '<br>' +
                           resp['exception_msg']
          this.showWarning(displayMsg, this.ERROR_MSG_BOX_TITLE) ;
          if (resp['do_logout'] && resp['do_logout'] == true) {
            window.location = Def.LOGOUT_URL ;
          }       
        }
        else {
          this.showWarning(this.SHARE_INVITE_FAILURE, this.ERROR_MSG_BOX_TITLE) ;
        }
      }.bind(this) ,
      onSuccess: function(response) {
        if (response.responseText != "null") {
          msg = "No invitation was sent.<br>" + response.responseText ;
          this.showWarning(msg, this.ERROR_MSG_BOX_TITLE) ;
        }
        else {
          Def.showNotice(successMessage);
        }
      }.bind(this) // end onSuccess for share invitation request
    }); // end request
    Def.setDataUpdatedState(false);
    Def.DataModel.save_in_progress = false ;
    this.clearShareInvite();
    this.shareInviteDialog_.buttonClicked_ = true ;
    this.shareInviteDialog_.dialogOpen = false ;
    this.shareInviteDialog_.hide() ;
    this.currentIdShown_ = null ;
  } ,  // end launchShareInvitation


  /**
   * This function handles a delete request from the delete dialog box.
   * The Def.PHRHome.currentRowSNum_ and Def.PHRHome.currentIdShown_ variables
   * are used to identify the phr to be deleted.  This makes an ajax call to
   * the server to delete the phr, then calls drawRemovedSection and puts up
   * a notice letting the user know that the phr has been deleted.
   *
   * @returns nothing
   */
  doDeleteProfile: function() {

    // create success message
    var profName = $('rem_name_string_' + this.currentRowSNum_ ).textContent ;
    var successMessage = 'The PHR for ' + profName + ' has been deleted.'

    new Ajax.Request('/form/delete_profile', {
      method: 'post' ,
      parameters: {
        authenticity_token: window._token ,
        profile_id: this.currentIdShown_
      } ,
      asynchronous: false,
      onFailure: function(response) {
        this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
      }.bind(this) ,
      onSuccess: function(response) {
        // Redraw the removed profile section with the deleted profile removed,
        // and let the user know the delete worked.   If there was a problem an
        // error will be thrown by the methods called; no need to echo it here.
        //this.drawRemovedSection() ;
        // NO - don't redraw.  Remove the functional buttons for the deleted
        // profile and set the font to strikethrough for the name.  Next time
        // the section is redrawn the profile will disappear.
        var lineEle = $('removed_profile_line_' + this.currentRowSNum_) ;
        var restCell = $('restore_cell_' + this.currentRowSNum_) ;
        var restBtn = $('restore_profile_' + this.currentRowSNum_);
        var spn = new Element('span', {'class':'deleted_text'}).update("DELETED");
        restCell.replaceChild(spn, restBtn);
        restCell.addClassName('has_deleted_text') ;
        var delCell = $('delete_cell_' + this.currentRowSNum_) ;
        lineEle.removeChild(delCell) ;
        // Originally I simply set the text decoration style on the
        // span that contains the name and age strings.  That worked fine for
        // IE and Firefox, but not for Chrome.  It also didn't work to set it
        // separately for the name and age string.  Using a class name and
        // setting it in the css, however, does work.  6/5/14 lm.
        var nameEle = $('rem_name_link_' + this.currentRowSNum_);
        nameEle.addClassName('deleted_name_string') ;
        Def.removeUniqueFieldValue('pseudonym', profName);
        Def.showNotice(successMessage);
      }.bind(this) // end onSuccess for delete request
    }); // end request
    this.currentIdShown_ = null ;
  } ,  // end doDeleteProfile


  /**
   * This function processes a user's input on the pending invitations list.
   * It makes a list of accept and decline requests, ignoring defer requests
   * and any profile lines left blank.  It sends the accept and decline requests
   * to the server for implementation.  On return from the server, if any
   * acceptances were processed the "Others" section is redrawn to include
   * them.  If no pending invitations are left for the user, the Pending
   * Access Invitations button is removed from the "Others" section header.
   *
   * @returns nothing
   */
  processPendingInvitations: function() {
    var numRows = parseInt($('pending_count').innerHTML);
    var inviteActions = {} ;
    for (var i = 1; i <= numRows; i++) {
      var groupName = 'invitation_option_' + i
      var buttonGrp = document.getElementsByName(groupName) ;
      var disposition = null;
      for (var r = 0; r < buttonGrp.length; r++) {
        if (buttonGrp[r].checked)
          disposition = buttonGrp[r].value ;
      }
      if (disposition && disposition !== 'defer') {
        inviteActions[$('profile_id_' + i).innerHTML] = disposition;
      }
    } // end processing each row
    if (Object.keys(inviteActions).length > 0) {
      new Ajax.Request('/share_invitation/update_invitations', {
        method: 'post' ,
        parameters: {
          authenticity_token: window._token ,
          invite_actions: Object.toJSON(inviteActions)
        } ,
        asynchronous: false,
        onFailure: function(response) {
          this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
        }.bind(this) ,
        onSuccess: function(response) {
          // if there were any acceptances, redraw the "others" section
          var resp = JSON.parse(response.responseText) ;
          if (resp['acceptances'] > 0) {
            this.redrawOthersSection();
          }
          if (resp['has_pending'] === false) {
            $('fe_other_invitations').setStyle({display: 'none'}) ;
          }
        }.bind(this)
      }); // end request
    } // end if the user requested any actions
  } , // end processPending Invitations


  /**
   * This function draws and displays the Active and Other PHRs sections.  It
   * is called during page load only.  The html returned for the active and
   * others sections is very similar, so this is used for them both.  This is
   * not used for the removed/inactive phrs section.
   *
   * This does not check to see if the html has any listings; it assumes
   * that the calling function (loadPage) does not call this if there are no
   * listings for the section.
   *
   * This also sets up the health reminder link info to be used to create
   * message managers for the profiles, although it does not issue the call
   * to actually create those.
   *
   * @param sectionText the html for the section returned from the server
   * @param idsList the hash of profile ids to row numbers
   * @param topSectionName the name of the top section division
   * @param remLinkName the name to be used for the health reminders link
   *  created from the section profile ids
   *
   * @returns a two-element array containing the profiles->row numbers hash
   *  and the health reminders links hash (in that order)
   */
  drawInitialSection: function(sectionText, idsShown,
                               topSectionName, remLinkName) {

    var topSectionParent = $(topSectionName).parentNode;
    topSectionParent.innerHTML = sectionText ;
    Def.IDCache.addToCache(topSectionParent) ;

    // Create the hash of ids/links used to set up the health reminders
    var remLinks = {} ;
    for (var profId in idsShown) {
      var linkID = remLinkName + parseInt(idsShown[profId]) ;
      remLinks[profId] = [linkID, linkID, this.HEALTH_REMINDERS_TITLE] ;
    }
    return remLinks ;
  } , // end drawInitialSection


  /**
   * This function redisplays the Other PHRs section.  It is called when
   * the user accepts an access invitation (or invitations) from the pending
   * access invitations list.  This assumes, therefore, that there are
   * other phrs to be displayed.  If a call is added to this where there
   * might not be other phrs to be displayed, this will need to be enhanced
   * to take that into account.
   *
   * @returns nothing
   */
  redrawOthersSection: function() {

    document.getElementById('main_form').style.cursor = "wait" ;

    new Ajax.Request('/phr_home/get_others_listings', {
      method: 'get' ,
      parameters: {
        authenticity_token: window._token ,
        form_name: 'phr_home'
      } ,
      asynchronous: false,
      onFailure: function(response) {
        this.showWarning(response.responseText, this.ERROR_MSG_BOX_TITLE) ;
      }.bind(this),
      onSuccess: function(response) {
        var resp = JSON.parse(response.responseText) ;
        this.othersCount_ = resp["count"]
        var idsForRems = this.drawInitialSection(resp["listings"],
                                                 resp["ids"],
                                                 'otherTopSection',
                                                 'o_health_reminders_link_')

        Def.IDCache.addToCache($('fe_other_profiles_0_expcol'));
        if (this.othersCount_ > 0)
          Def.attachMessageManagers(idsForRems);

        // If the section is closed, open it.  Also make sure the header
        // is showing
        if ($('fe_other_profiles_0_expcol').style.display == 'none') {
          expColSection('fe_other_profiles_0_expcol') ;
          $('fe_other_profiles_0').setStyle({display: 'block'}) ;
        }
      }.bind(this)
    }); // end request
    document.getElementById('main_form').style.cursor = "auto" ;
  } , // end redrawOthersSection


  /**
   * This function displays an alert box for this page.  It does NOT use the
   * standard javascript alert box, which is not customizable and is UGLY in
   * Firefox.
   *
   * @param text the text of the message
   * @param title the title for the window
   * @returns the alert box
   */
  showWarning: function(text, title, height, width) {
 
    // Set the options for the box
    var options = {
      position: 'center',
      buttons: [{
        text: "OK",
        id: "warningOKBtn" ,
        class: "rounded" ,
        click: function() {
          this.warningDialog_.hide() ;
        }.bind(this)
      }]
    }
    if (height !== undefined)
      options['height'] = height ;
    if (width !== undefined)
      options['width'] = width ;

    // Create the box
    this.warningDialog_ = new Def.ModalPopupDialog(options);
    
    this.warningDialog_.setContent(text) ;
    this.warningDialog_.setTitle(title);
    this.warningDialog_.show();

  } , // end showWarning

  /**
   * This function displays an alert box for this page.  It does NOT use the
   * standard javascript alert box, which is not customizable and is UGLY in
   * Firefox.
   *
   * @param text the text of the message
   * @param title the title for the window
   * @returns the alert box
   */
  showConfirmation: function(text, title, height, width) {

    // Set the options for the box
    var options = {
      position: 'center',
      buttons: [{
        text: "OK",
        id: "warningOKBtn" ,
        class: "rounded" ,
        click: function() {
          this.warningDialog_.hide() ;
        }.bind(this)
      }]
    }
    if (height !== undefined)
      options['height'] = height ;
    if (width !== undefined)
      options['width'] = width ;

    // Create the box
    this.warningDialog_ = new Def.ModalPopupDialog(options);

    this.warningDialog_.setContent(text) ;
    this.warningDialog_.setTitle(title);
    this.warningDialog_.show();

  }  // end showWarning


}  // end Def.PHRHome
Event.observe(window,'load',Def.PHRHome.loadPage.bind(Def.PHRHome) ) ;
