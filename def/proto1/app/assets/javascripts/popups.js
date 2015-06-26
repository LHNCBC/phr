/*
 * popups.js -> javascript functions to open specific popup windows
 *
 * taken from the bioethics project; modified as needed
 *
 * $Id: popups.js,v 1.58 2011/08/23 13:53:51 mujusu Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/popups.js,v $
 * $Author: mujusu $
 *
 * $Log: popups.js,v $
 * Revision 1.58  2011/08/23 13:53:51  mujusu
 * idle popup and session expiry management changes
 *
 * Revision 1.57  2011/08/17 18:17:42  lmericle
 * change to blinder implementation (added activeBlinder class) and fixes for info button and reminder popups
 *
 * Revision 1.56  2011/08/10 20:06:09  lmericle
 * added code for modal popups, major restructuring
 *
 * Revision 1.55  2011/08/05 18:17:11  plynch
 * External URLs should not have "from=popup" appended to them
 *
 * Revision 1.54  2011/04/26 22:05:07  mujusu
 * close when closing main window
 *
 * Revision 1.53  2011/04/12 16:06:52  lmericle
 * removed old Def.Logger calls
 *
 * Revision 1.52  2011/04/07 23:13:33  mujusu
 * bug fix
 *
 * Revision 1.51  2011/02/08 21:24:10  plynch
 * popups.js:  Added an option for specifying CSS files to be used with
 * the popup (which then I did not need, but it seems useful.)
 * printableView:  Simplified.  Now it just toggles which CSS files are in
 * use on the main page.
 *
 * Revision 1.50  2011/01/13 21:01:38  plynch
 * Corrected a comment
 *
 * Revision 1.49  2011/01/10 21:54:04  taof
 * bugfix: hitting the print screen button will close popup window
 *
 * Revision 1.48  2011/01/07 20:42:46  plynch
 * code-review changes
 *
 * Revision 1.47  2010/12/20 20:10:56  plynch
 * Update to the gopher terms table (based on work by Julia Xu to map the terms to Snomed codes)
 * plus updates the the tests.
 *
 * Revision 1.46  2010/12/14 19:44:51  taof
 * bugfix: popup window always load the cached javascript files even if it's been outdated
 *
 * Revision 1.45  2010/12/13 20:32:55  plynch
 * Corrected a comment.
 *
 * Revision 1.44  2010/12/08 21:15:07  plynch
 * Changed the drug warnings to use the dojo popups, which I made draggable
 * again.  Also changed the autocompletion lists so that if the field
 * matches exactly (other than case) an item in the list, that item will
 * get selected on a "tab".
 *
 * Revision 1.43  2010/12/04 00:02:05  plynch
 * Post-review changes for the fix to prevent caching of client-side generated popups, and fixed a problem with the resizeToFit function, which was not working right when the content was too long for the screen.
 *
 * Revision 1.42  2010/12/02 18:29:41  wangye
 * bug fixes on printable view page
 *
 * Revision 1.41  2010/11/29 22:42:06  plynch
 * Fixed the list suggestion popup so it closes if you click on the background
 * or hit a key.  Also, in application_phr.js I added a change so that all
 * prototype event listeners will log exceptions.
 *
 * Revision 1.40  2010/11/24 00:24:46  taof
 * remove javascript: from popups.js and cleanup code
 *
 * Revision 1.39  2010/11/10 21:43:56  plynch
 * Changed the code so that popups whose content is specified directly (rather
 * than by URL) are not cached.
 *
 * Revision 1.38  2010/11/03 22:56:00  taof
 * add show more or less feature to reminder messages
 *
 * Revision 1.37  2010/09/07 22:17:18  taof
 * clicking URL in reminder text won't popup a new window
 *
 * Revision 1.36  2010/08/03 15:46:39  lmericle
 * fixed openPopup to accept null anchor parameter
 *
 * Revision 1.35  2010/01/19 19:12:28  taof
 * bugfix: hit in the main window will close popup window
 *
 * Revision 1.34  2009/12/22 22:22:43  plynch
 * Changed splitFullFieldID so that its return value is cached, updated
 * the code to be aware of that, and moved the function into idCache.js.
 *
 * Revision 1.33  2009/11/04 17:09:46  lmericle
 * added openDataHelp function
 *
 * Revision 1.32  2009/09/22 14:45:36  taof
 * reminder popup cannot be closed with key/combination keys
 *
 * Revision 1.31  2009/06/08 16:43:06  wangye
 * resized popup windows
 *
 * Revision 1.30  2009/04/28 21:16:28  lmericle
 * added closeWindow function
 *
 * Revision 1.29  2009/04/28 17:03:49  plynch
 * Changes for fixing the info button.
 *
 * Revision 1.28  2009/04/21 20:56:26  lmericle
 * added noAutoClose parameter to openPopups
 *
 * Revision 1.27  2009/04/21 14:59:47  lmericle
 * modified openPopups to accomodate height specification in windowOpts parameter
 *
 * Revision 1.26  2009/04/15 15:42:05  plynch
 * Changes for the new clinical trials search page.
 *
 * Revision 1.25  2009/04/08 17:15:19  taof
 * Hit spacebar cannot close reminder popup (continued)
 *
 * Revision 1.24  2009/04/08 11:21:50  lmericle
 * fixed popups to always come to top when requested
 *
 * Revision 1.23  2009/03/16 22:43:22  lmericle
 * modified to require specification of help file to be at beginning of help_text field in database
 *
 * Revision 1.22  2009/03/16 19:37:19  lmericle
 * changes to allow help text to come from the database OR from external files.
 *
 * Revision 1.21  2009/02/03 22:15:03  plynch
 * Changes related to fixing HTML encoding in error messages and static_text.
 *
 * Revision 1.20  2009/01/09 16:15:20  taof
 * allow user to close popup window by hitting any keys expect for some special keys
 *
 * Revision 1.19  2009/01/07 22:56:33  plynch
 * Changes to fix issues with the gopher data and the medical problem
 * info button.
 *
 * Revision 1.18  2008/12/15 23:40:25  plynch
 * The code that was opening the popup window was opening it with a URL of
 * "new".  This caused a request to be sent back to the server for the page
 * "new" (relative to the current URL).  I replaced it with '', which causes
 * the request to not be sent.
 *
 * Revision 1.17  2008/11/06 20:43:55  smuju
 * popus can decrease in size also. so chech delta < 0 also
 *
 * Revision 1.16  2008/11/06 20:30:58  taof
 * allow user to close popup windows by hitting any keys expect for some specified keys
 *
 * Revision 1.15  2008/05/29 19:06:07  plynch
 * Added info links to the allergy and immunization tables.
 *
 * Revision 1.14  2008/02/13 01:10:59  smuju
 * focus
 *
 * Revision 1.13  2008/02/12 22:06:57  lmericle
 * changed console statements to def.logger calls; splitAutoComp updates to TablePrefetch class
 *
 * Revision 1.12  2008/02/12 21:56:32  smuju
 * added access key for popup closing
 *
 * Revision 1.11  2008/02/11 23:04:53  plynch
 * Addition of a rule for colonoscopy, support for links in reminder texts,
 * and a fix for the medline plus link for the problems field.
 *
 * Revision 1.10  2008/02/05 17:58:25  plynch
 * Changes for the addition of the mammogram rule.
 *
 * Revision 1.9  2008/01/15 20:54:16  lmericle
 * changes for data loading
 *
 * Revision 1.8  2007/10/03 15:20:48  lmericle
 * updates for form builder conditions
 *
 * Revision 1.7  2007/09/19 18:37:39  plynch
 * Changes to simplify the regex validation code and to fix the error message
 * display.
 *
 * Revision 1.6  2007/08/28 15:24:02  plynch
 * Changed the title of the help window to be not specific to the OASIS form.
 *
 * Revision 1.5  2007/08/20 17:40:04  fun
 * improve robustness of medlineplus drug popup window
 *
 * Revision 1.4  2007/04/11 21:14:33  lmericle
 * remove alert
 *
 * Revision 1.3  2007/04/11 21:13:25  lmericle
 * tweak tweak tweak
 *
 * Revision 1.2  2007/04/11 20:49:47  lmericle
 * changes to position help box to the right
 *
 * Revision 1.1  2007/04/11 20:14:56  lmericle
 * changes for upgraded help box
 *
 *
 */

/**
 * The openPopup function is the main function here.  Specialized popup window
 * openers are defined before openPopup.  All of those simply set up the
 * characteristics for a particular type of window and then call openPopup.
 * No functions should create popups directly.  All popup creation should go
 * through the openPopup function.
 */

// The following lines are needed for popups because they do not include
// application_phr.js file.
if (typeof Def == 'undefined') {
  Def = {};
}

/** Values we set, with no way for the calling function to specify them **/
/**
 * Help window title
 */
HELP_TITLE = 'Form Input Help' ;

/**
 * Left position clearance, used to nudge the box over
 */
LEFT_CLEARANCE = 200 ;

/**
 * Right position clearance, when window will go all the way to the right
 */
RIGHT_CLEARANCE = 30 ;

///**
// * Default window name (HIGHLY IMAGINATIVE)
// */
//DEFAULT_WINDOW_NAME = 'popup' ;



/** Data structure used to gather and then specify the popup window options
 *  Defaults are provided for each, but are overridden by what is specified
 *  in the windowOpts parameter of the openPopup function - if the parameter
 *  IS specified.
 *
 *  We use the window.open parameter names here because current calls to
 *  the openPopup function specify parameters using those names.  If the
 *  popup is created using the showModalDialog option, the appropriate
 *  parameters are matched to the parameter names used by that function.
 *  So it is important to use the window.open parameter names when
 *  providing an options string to the openPopup method.
 *
 *  The following window.open parameters are not used here (and will be
 *  ignored if specified in the windowOpts parameter):  channelmode,
 *  directories, and fullscreen.  In addition, the replace parameter is
 *  not specified.  (See the window.open documentation that is available
 *  online for an explanation of those options and that parameter).
 *
 *  The following showModalDialog parameters are not used here (and will be
 *  ignored if specified in the windowOpts parameter):  dialogHide, edge,
 *  unadorned.  (See the showModalDialog documentation that is available
 *  online for an explanation of those options).
 */

Def.PopupWindowOpts = {

/**
 *  The top position of a popup window, in pixels
 */
top : '40' ,

/**
 *  The left side position of the window, in pixels.  If the user
 *  doesn't specify this, it's figured based on the location of the
 *  anchor, screen width, etc.  We RECOMMEND that this option NOT be
 *  specified.  Just specify an anchor and let the calculations figure
 *  the left most position.   But there's always someone who has to have
 *  it their way ...
 */
left : null ,

/**
 * Default popup window height
 */
height : window.screen.height * 0.7,

/**
 * Default popup window width
 */
width : window.screen.width * 0.7,

/**
 * Default resizable option
 */
resizable : 'yes' ,

/**
 * Default scroll option
 */
scrollbars : 'yes' ,

/**
 * Default status bar option
 */
status : 'no' ,

/**
 * Default menu bar option.  This option is not used by showModalDialog.
 */
menubar : 'yes' ,

/**
 * Default location option.  This option is not used by showModalDialog.
 */
location : 'no' ,

/**
 * Default toolbar option.  This option is not used by showModalDialog.
 */
toolbar : 'no'};


Def.Popups = {
  /**
   *  Help window height (before resizing)
   */
  helpWinHeight_: 100,
  
  /**
   *  Help window width
   */
  helpWinWidth_: Def.PopupWindowOpts.width > 700 ? 700 : Def.PopupWindowOpts,
  
  /* Flag used to avoid running restoreDisplay until the page unloads.
   * Firefox, and maybe other browsers, seems to unload a page before it
   * loads it, which causes us problems.
   */
  popupLoaded_ : false ,

  /* Wrappers for the functions used to specify the corresponding functions
   * as event observers for a modal popup.  These are concerned with
   * restoring the display after a modal popup is unloaded
   */
  restoreDisplayWrapper_ : null ,
  setLoadedFlagWrapper_ : null ,

 /**
  * Counter to track how many times the loaded status of a modal popup
  * has been checked.  Used only for modal popups; set in openPopups, checked
  * in checkPopupLoaded.
  */
  openChecks_ : 0 ,

  /**
   * Limit for the number of checks performed on a modal popup's loaded status.
   */
  MAX_OPEN_CHECKS : 20 ,

  /**
   * Holds a reference to a modal popup being loaded.  Set in openPopup when
   * the popup is created; checked in checkPopupLoaded to see if the popup
   * was closed prematurely.
   */
  popupWindow_ : null ,

  /**
   *  Resizes a popup window to fit its content.  As of Firefox 7, windows not
   *  opened by window.open cannot be resized.
   */
  resizeToFit: function(popupWindow) {
    var minDelta = popupWindow.document.body.scrollHeight - popupWindow.innerHeight + 40;
    if (minDelta + popupWindow.outerheight > screen.availHeight)
      minDelta = screen.availHeight - popupWindow.outerheight ;
    if (minDelta != 0)
      popupWindow.resizeBy(0, minDelta);
  },

  /**
   *  Opens a modeless help window.  This uses the default HELP_TITLE,
   *  all default window options, the default window name, and specifies
   *  the help_popup.css file as an extra CSS file.
   *  
   * @param anchor an element in the current window on which to base the
   *  popup window's position
   * @param helpTextOrURL the text or URL for the help text.
   */
  openHelp: function(anchor, helpTextOrURL) {

    openPopup(anchor, helpTextOrURL, HELP_TITLE, Def.Popups.helpWinSpec_,
              "HELP");
  }
};

Def.Popups.helpWinSpec_ = 'width='+Def.Popups.helpWinWidth_+',height='+
                          Def.Popups.helpWinHeight_ + ',location=no,toolbar=yes';


/**
 *  Opens a modeless popup for a general purpose Info button (which links to an
 *  external site, typically).  This specifies a custom size for the box, no
 *  title for the window and no extra CSS.
 *
 * @param infoButtonID the id of the HTML DOM button/image element that was
 *  clicked.
 * @param urlTargetField the target field name containing the URL to be
 *  displayed.
 * @param anchorFldTarget the target field name for the field to which this
 *  should be anchored.  Trying to anchor it to the urlTargetField doesn't
 *  work; probably because the url is hidden.  Normally this should be whatever
 *  the button is next to, e.g., allergy_name for the allergy_info button.
 */
function showInfoPage(infoButtonID, urlTargetField, anchorFldTarget) {

  // Split the button ID into parts ('fe', target_field, suffix).
  var idParts = Def.IDCache.splitFullFieldID(infoButtonID);
  var urlField = selectField(idParts[0], urlTargetField, idParts[2], 0);
  var anchorFld = selectField(idParts[0], anchorFldTarget, idParts[2], 0) ;
  if (urlField) {
    var windowOpts = 'width=1000,height=680,resizable=yes,scrollbars=yes,status=yes';

    var url = Def.getFieldVal(urlField);
    if (urlField && url) {
      // Add the event to the usage reporting data
      Def.UsageMonitor.add('info_button_opened', {"info_url":url});
      // Cache the url for help when doing automated testing
      Def.lastInfoURL_ = url;
      // Also store the window reference for testing
      Def.lastPopupWindow_ =
        openPopup(anchorFld, url, null, windowOpts, 'info_page');
    }
  }
} // end showInfoPage


/**
 * Opens a popup window.
 *  
 * @param anchor an element in the current window on which to base the
 *  popup window's position or null if positioning has already been done
 *  and is contained in the windowOpts parameter.
 * @param textOrURL the HTML for the body of the popup (other than the title
 *  and the close button) -OR- the full or partial URL for the page to be
 *  loaded to the popup.  Note:  The caller is responsible for ensuring the
 *  safety of any HTML passed in.
 * @param title the title of the popup window if text, rather than a URL, is
 *  being supplied.
 * @param windowOpts optional, options settings for the window.  See the
 *  documentation for the Def.PopupWindowOpts object (above).
 * @param windowName optional, a name to be used for the window object.  If
 *  not supplied or there exists a popup with same windowName, then IE9/11 will 
 *  throw 'Permission Denied' exception (not applicable to windowName which is
 *  an empty string). 
 * @param noAutoClose optional, a boolean that, if true, indicates the popup
 *  window should not automatically close when (almost) any key is pressed.
 *  Default used is false.
 * @param makeModal optional, boolean flag indicating whether or not the
 *  popup should be created as a "modal" box; i.e. where the user cannot
 *  access the window from which the box was requested.  Default is false.
 * @return a reference to the new window object IF the showModalDialog call
 *  was NOT used to create the popup.  If showModalDialog was used, this will
 *  return whatever the popup window returns when it is closed - which is
 *  nothing for all modal popups we've currently implemented.  Since the
 *  showModalDialog function cannot be used for all browsers, it would not
 *  be a good idea to count on this return for a modal popup.
 */
function openPopup(anchor, textOrURL, title, windowOpts,
                   windowName, noAutoClose, makeModal) {

  try {
    // Create a window options hash for this popup based on whatever's in
    // windowOpts, or the defaults where no value was specified
    var theseWindowOpts = parseOpts(windowOpts) ;

//    // If we didn't get a window name, use our own highly imaginative one
//    if (windowName == undefined || windowName == null) 
//      windowName = DEFAULT_WINDOW_NAME ;

    // Set makeModal to false if it was not specified
    if (makeModal === undefined || makeModal === null)
      makeModal = false ;

    // Figure positioning for the window if it wasn't specified (and we
    // hope it wasn't, because these calculations seem to work well).
    // Get the left position from current window, then add the leftmost
    // position of the anchor field to it - if we have an anchor field
    if (theseWindowOpts['left'] === null) {
      if (window.screenX !== null)
        var leftPos = window.screenX ;
      else
        leftPos = window.screenLeft ;
      if (anchor) {
        leftPos += getAbsX(anchor) ;

        // Increase the left position by the anchor width, if we have an anchor,
        // and 200 LEFT_CLEARANCE).  Don't know why this particular number, but
        // it works.
        if (anchor.width) {
          leftPos += anchor.width ;
        }
        else if (anchor.offsetWidth) {
          leftPos += anchor.offsetWidth ;
        }
        leftPos += LEFT_CLEARANCE ;

        // If the window won't fit on the screen drop it back to where it will
        // fit. Otherwise go with the left position we have.
        var winWidth = parseInt(theseWindowOpts['width']) ;
        if ((leftPos + winWidth) > screen.width) {
          leftPos = screen.width - (winWidth + RIGHT_CLEARANCE) ;
        }
      } // end if an anchor was specified
      theseWindowOpts['left'] = leftPos.toString() ;
    } // end if we're calculating the left most position

    // Create the options string from what the calling function passed in 
    // plus defaults for any values not specified.
    var optsString = '' ;
    for (var opt in theseWindowOpts) {
      optsString += opt + '=' + theseWindowOpts[opt] + ',' ;
    }
    optsString = optsString.substr(0, optsString.length - 1) ;

    // Figure out whether or not we're going to pass along an URL that will
    // provide the content of the box, and the type of URL, and whether or
    // not we need to add a parameter (used by the test panel data forms) to
    // the URL.
    var relativeURL = textOrURL.indexOf('/') == 0;
    var externalURL = !relativeURL && (textOrURL.indexOf('http') == 0 ||
                                       textOrURL.indexOf('about') == 0);
    // Adding from=popup to about:blank will make the blank popup window look
    // like an error page. This only happens to IE (e.g. IE 11). It seems to be
    // unnecessary to append from=popup to url of about:blank page, because the  
    // only use case (see openPopup in popupMplusDrugs.js) is to open a blank 
    // window then load the content from another url - Frank
    //  if (relativeURL || (externalURL && textOrURL.indexOf('http') != 0)) {
    if (relativeURL) {
      textOrURL += textOrURL.indexOf('?') < 0 ? "?" : "&";
      textOrURL += 'from=popup' ;
      // If textOrURL is a link to a shtml file, then we should set flag to 
      // distinguish the main shtml page from its sub pages
      if (/\.shtml\?/.test(textOrURL)) {
        textOrURL += '&go_back=false' ;
      }
    }
    
    // If we don't have an URL, call createPopupWithText to create the popup
    // from the textOrURL passed in
    if (!externalURL && !relativeURL) {
       var popup = createPopupWithText(optsString, title, textOrURL, windowName,
                                       theseWindowOpts['top']) ;

      // If we didn't use an external URL, and the noAutoClose parameter was not
      // passed in as true, set the closeWindowOnKeyUp to be run when the user
      // presses a key on the popup
      if (!externalURL && (noAutoClose == undefined ||
                           noAutoClose == null || noAutoClose == false)) {
        Event.observe(popup, 'keyup', this.closeWindowOnKeyUp.bind(popup));
      }
      // Put the popup on the list so that it can be closed if necessary
      Def.CURRENT_POPUPS_ARR.push(popup) ;
//      popup.focus();
    }
    else {

      // Per Lee, a truly modal should meet these requirements:
      // 1) user cannot access underlying form;
      // 2) Modal box stays on top.
      // we can do #1, but not #2 - which is why we put a notice up.
      if (makeModal) {
        var theBlinder = $('blinder') ;
        theBlinder.addClassName('activeBlinder') ;
        var modalNotice = $('modalNotice') ;
        modalNotice.style.display = 'block' ;
        var popupTitleField = $('fe_modal_popup_name') ;
        Def.setFieldVal(popupTitleField, title, false) ;

        // Initialize the values used to monitor a modal popup's loaded status.
        Def.Popups.openChecks_ = 0;
        Def.Popups.popupLoaded_ = false ;
        Def.Popups.popupWindow_ = null ;

        // Call checkPopupLoaded to get the monitoring started
        checkPopupLoaded() ;
      } // end if makeModal

      popup = window.open(textOrURL, windowName, optsString) ;
      if (makeModal)
        Def.Popups.popupWindow_ = popup ;

      // Comment out the success check below.  Right now a problem
      // with IE 10 when displaying MedlinePlus windows causes this to
      // throw an error, even though we do get a popup object back.  This
      // also causes a brief error display to the user - but then the
      // requested info is displayed.   Very frustrating.  7/24/13 lm.
//      if (!popup)
//        throw("Failed to create the popup window "+ windowName);

      // Put the popup on the list so that it can be closed if necessary
      Def.CURRENT_POPUPS_ARR.push(popup) ;
      if (makeModal) {
        this.restoreDisplayWrapper_ = this.restoreDisplay.bind(this) ;
        this.setLoadedFlagWrapper_ = this.setLoadedFlag.bind(this) ;
        Event.observe(popup, 'load', this.setLoadedFlagWrapper_) ;
        Event.observe(popup, 'unload', this.restoreDisplayWrapper_) ;
      }
    } // end if we have an URL
  }
  catch(e) {
    Def.reportError(e);
    throw(e);
  }
  popup.focus();
  return popup ;
} // end openPopup


/**
 * This sets a flag indicating that the modal popup generated by openPopup
 * has loaded.  It is needed because Firefox, and maybe other browsers,
 * seems to "unload" the popup before it creates and loads it.  This causes
 * problems for the restoreDisplay function, so I just gave up and set
 * a flag here.
 */
function setLoadedFlag() {
  Def.Popups.popupLoaded_ = true ;
}

/**
 *  This function restores the current display to an accessible state
 *  after a modal popup that it opened closes.  This is called out as
 *  a separate function so that it can be bound to the unload event on
 *  a modal popup that is displayed in IE.
 */
function restoreDisplay() {
  if (!Def.forceLogout_) {
    if (Def.Popups.popupLoaded_ == true) {
      var theBlinder = $('blinder') ;
      var modalNotice = $('modalNotice') ;
      var popupTitleField = $('fe_modal_popup_name') ;
      if (popupTitleField.innerHTML.indexOf("Add Trackers") > -1 ||
          popupTitleField.innerHTML.indexOf("Edit Result Timeline") > -1)
        TestPanel.testEditingPopupUnloadListener(true, null);
      theBlinder.removeClassName('activeBlinder') ;
      modalNotice.style.display = 'none' ;
      Def.setFieldVal(popupTitleField, '', false) ;
      Def.Popups.popupLoaded_ = false ;
    }
  }
  else if (window.opener)
    window.close() ;  
} // end restoreDisplay


/**
* Close the popup window when the user hits any keys except:
* 1) Ctrl or Alt
* 2) Character C or V when the Ctrl key is being held
* 3) Tab
* 4) PrintScreen
*
* @param e the event object
*/
function closeWindowOnKeyUp(e){
  var evt = e || window.event;
  var keycode = evt.which;
  if (keycode == 0)
    keycode = evt.keyCode;

  var notClose =
    // Ctrl or Alt was captured
    (keycode == 17 || keycode == 18) ||
    // Character C or V was captured while Ctrl key was detected,
    ((keycode == 67 || keycode == 86 || keycode==99 || keycode==118) &&
     evt.ctrlKey) ||
    // Tab was captured
    (keycode == 9) ||
    // PrintScreen was captured
    (keycode == 44);
  if (!notClose) {
    if (this.hide)
      this.hide(); // dojo popups
    else
      this.close();
  }
} // end closeWindowOnKeyUp


/**
 *  Closes the window.  Used for the close button that's added to windows
 *  created with the createPopupWithText function (see below).
 */
function closeWindow() {
  if (Def.formTitle_ == null)
    Def.formTitle_ = document.title ;
  close();
}


/**
 * Creates a window options hash based on window options passed in and the
 * Def.PopupWindowOpts object.  Any options not specified in the windowOpts
 * string will use the defaults in Def.PopupWin (except the 'left' setting for
 * the window, which will be computed).  If an option is specified in the string
 * that is not included in the object, it will be discarded.  So if you need to
 * specify something that's not in the object, add it to the object with a
 * default.
 *
 * @param windowOpts a string containing the options specified by the calling
 *  function, in the form optionName=optionValue,optionName=optionValue, etc.
 *  See the Def.PopupWindowOptions for a more detailed description.
 * @returns new window options object
 */
function parseOpts(windowOpts) {
  var optsHash = Def.deepClone(Def.PopupWindowOpts) ;
  if (windowOpts) {
    var optsArray = windowOpts.split(',') ;
    for (var i=0, l = optsArray.length; i < l; i++) {
      var opt = optsArray[i].split('=');
      if (optsHash[opt[0]])
        optsHash[opt[0]] = opt[1].toString() ;
    }
  }
  return optsHash ;
} // end parseOpts


/**
 * Resizes the input popup window to fit its content
 * @param popup a popup window
 **/
// This function overwrites the original function to include a fix for an 
// openning issue in the chromium project. The original function has been renamed
// to resizeToFit_woChromeFix. When the open issue was resolved, this function 
// should be replaced by the original one and the function named 
// resizeToFit_withChromeFix served as a temporary fix should be removed too. 
// (Please don't forget to do the same thing for help_header.shtml file as it 
// has a copy of  these functions for resizing) - Frank
function resizeToFit(popup) {
  if (!popup)
    popup = window;
  var h= popup.document.documentElement.offsetHeight;
  // If the browser is IE, documentElement.offsetHeight will be too big. We need
  // to compute the value using top/bottom margins and the body.offsetHeight.
  var b = popup.document.body;
  if (b.topMargin)
    // Added 20 to make it work with IE 9 and IE 11.
    h = b.offsetHeight + parseInt(b.topMargin) + parseInt(b.bottomMargin) + 20;
  var newWindowOuterHeight =  h + popup.outerHeight - popup.innerHeight;
  var maxHeight = popup.screen.availHeight - popup.screenY;
  if (newWindowOuterHeight > maxHeight)
    newWindowOuterHeight = maxHeight;
  // call the window resizeTo function if needed
  if (newWindowOuterHeight != 0) 
    popup.resizeTo(popup.outerWidth, newWindowOuterHeight);
};


/**
 * Creates a popup window with the title and text specified.  The text is
 * assumed to be html that is to be written to an already created window.
 * This puts a standard header and footer on the window and, if any
 * extra css files are specified, adds them.
 *
 * @param optsString a string containing window options specified by the
 *  calling function
 * @param title title to be displayed for the window
 * @param text text to be displayed in the window or a JSON string containing 
 *  both text and script. The script is in HTML format and can be executed on 
 *  the client side. 
 * @param windowName optional, a name to be used for the window object.  If
 *  not supplied or there exists a popup with same windowName, then IE9/11 will 
 *  throw 'Permission Denied' exception (not applicable to windowName of an empty
 *  string). 
 * @param topOpt the "top" window option specified.  We need a separate
 *  copy of just that to include in the resizeToFit function created in
 *  the header.  This is a string value.
 */
function createPopupWithText(optsString, title, text, windowName, topOpt) {
  // Try to re-use the existing popup which has the exact same window
  // name as the one we are creating. That way we can avoid the access denial 
  // error on IE 11 browser.
  var popup = null;
  for(var i=0,max = Def.CURRENT_POPUPS_ARR.length; i< max;i++){
    var curWin = Def.CURRENT_POPUPS_ARR[i];
    if(!curWin.closed && curWin.window.name === windowName)
      popup = curWin;
  }
  if (!popup) {
    popup = window.open('about:blank', windowName, optsString) ;
  }
  var pd = popup.document ;
  pd.open();
  // Different from Chrome and Firefox (latest versions in Jan 2012), IE 9 will
  // block the second call of document.write(content) in an opened popup window
  // if the website has a security certificate error and the content to be 
  // written to the popup window may trigger the loading of some external
  // resources (e.g. an external JavaScript link or an img src file etc).
  //   
  // To prevent the text/asset files of the popup from getting cached (on disk)
  // we are creating a page template and then filling in the content after
  // the page gets its load event.  (At least on Firefox, the originally
  // written page gets cached rather than the modified one.)
  // Note:  This assignment needs to be after the first pd.write statement
  // because if the popup window was already open, the write clears
  // the assignment.  Subsequent writes appear to be okay.
  var pdHtml=('<!DOCTYPE html>' +
           '\n<html lang="en"><head><title>' + title + '</title>' +
           '<meta http-equiv="X-UA-Compatible" content="IE=edge" />' +
           '<meta http-equiv="Content-type" content="text/html; charset=UTF-8" />' +
           '<script>window._token = "' + window._token + '";</script>' +
           '<link rel="stylesheet" type="text/css" ' +
           'href="https://fonts.googleapis.com/css?family=Ubuntu:regular,bold&subset=Latin" ' +
           'media="all"/>');

  if (Def.Asset.pageAssets_) {
    var asset = Def.Asset.pageAssets_['popup'];
    if (asset)
     pdHtml+= asset;
  }

  try {
    // If the text is a JSON string, then parse it to get the real text 
    // and the script assets. The script contains profile id information
    var textOpts = text.evalJSON();    
    text = textOpts["text"];
    pdHtml += textOpts["script"]; 
  } catch(e) {
    // If the text is not a JSON string, then text.evalJSON() will throw
    // exception. Neglect the exception and continue 
  }

  pdHtml+=("\n</head>\n");
  // 1) setTimeout interval increased from 1 to 5 because Chrome(v 16.0)  
  // sometimes returns a window.outerHeight which is smaller than the real value;
  // 2) When 'img' or 'a' tag aligned to the right, they are no longer included 
  // in the body element(e.g. inpsect the body element using firebug to see the  
  // close button isn't hightlighted as a part of the body). Using 'p' tag to 
  // wrap and align the close button can fix the problem
  var onloadHandler =["HtmlTruncator.truncate({})",
    "Def.formName_ = \"" + title + "\"",
    "setTimeout(function(){resizeToFit();},1)"];

  if (Def.inTestMode_ == false) {
    onloadHandler.push("Def.UsageMonitor.setTimer()") ;
  }

  // I moved the event handlers to here on the page.  Previously the
  // observers were being registered from the showAllMessages function
  // in the messageManager.  The problem was that the events, although
  // observing the focus events on the Health Reminders window, were
  // being recorded in the calling window.  When that is the PHR Home page,
  // there is no profile_id available (because multiple profiles are
  // listed on the page).  We need the profile ids for the health reminders.
  var focusHandlers = 'onfocus="Def.UsageMonitor.add(' +
                      "'focus_on', {'form_name':'" + title + "'," +
                                   "'form_title':'" + title + "'});" + '"  ' +
                      'onblur="Def.UsageMonitor.add(' +
                      "'focus_off', {'form_name':'" + title + "'," +
                                    "'form_title':'" + title + "'});" + '"'
  var buttonHtml = '<p align="right"><button id="close_button" \n\
class="rounded" onclick="self.closeWindow()" type="button">\n\
<span>Close</span></button></p>';
  onloadHandler = onloadHandler.join(";");
  pdHtml+=("<body onload='" + onloadHandler + "' " + focusHandlers +
           ' id=\"helpBody\"><h2>' + title + "</h2>\n<div id='content'>" +
           text + "</div>" + "</br></br>" + buttonHtml + "</body></html>");
  pd.write(pdHtml);
  pd.close() ;
  return popup ;
} // end createPopupWithText


  /**
   * This function checks the status of a modal popup window every second.
   *
   * If the window has completed loading, the checking is
   * terminated.
   *
   * If the window has been closed before loading completes,
   * this causes the blinder to be removed from the calling window and
   * then terminates.
   *
   * Otherwise the popup is still loading.  If the maximum number of checks
   * have not been reached, this resets itself to check in another second.
   * If the maximum number of checks HAVE been reached, this assumes something
   * is locked up and removes the blinder from the calling window, then
   * terminates.
   **/
  function checkPopupLoaded() {
 
    if (Def.Popups.popupLoaded_ == false) {
      if (Def.Popups.openChecks_ > Def.Popups.MAX_OPEN_CHECKS ||
          (Def.Popups.popupWindow_ != null && Def.Popups.popupWindow_.closed)) {
        setLoadedFlag();
        restoreDisplay();
      } // end if the popup's gone or we've checked long enough
      else {
        Def.Popups.openChecks_ += 1;
        setTimeout("checkPopupLoaded()", 1000) ;
      } // end if the popup is still loading
    } // end if the popup hasn't finished loading
  } // end checkPopupLoaded
