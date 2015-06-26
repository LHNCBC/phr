/**
 * browser_close.js-> Detects browser close event when user logged in.
 * Shows a popup prompting user to logout before closing the browser.
 * This also runs when user tries to navigate away from the logged in
 * page without using the application buttons but browser navigation.
 *
 * $Log: browser_close.js,v $
 * Revision 1.15  2011/08/15 15:09:53  mujusu
 * bug fix. did not popup atall on phr/panel pages
 *
 * Revision 1.14  2011/08/10 20:04:39  lmericle
 * updated close message
 *
 * Revision 1.13  2011/08/03 17:19:56  mujusu
 * javascript poup box fixes
 *
 * Revision 1.12  2011/07/26 18:10:55  mujusu
 * fixes popup issue
 *
 * Revision 1.11  2011/07/25 20:05:31  mujusu
 * popup on session logout fixed
 *
 * Revision 1.10  2011/07/15 16:56:58  taof
 * bugfix: browser_close.js
 *
 * Revision 1.9  2011/07/14 13:42:08  taof
 * replace addEventListener with Event.observer in browser_close.js
 *
 * Revision 1.8  2011/06/30 15:20:03  taof
 * bugfix: get popup when navigating to flowsheet from phr_index page
 *
 * Revision 1.7  2011/06/29 13:50:54  taof
 * bugfix: event.fireEvent() not working with IE9
 *
 * Revision 1.6  2011/05/18 18:19:46  mujusu
 * fix bug caousing logout when popup closed
 *
 * Revision 1.5  2011/05/02 19:59:05  mujusu
 * cleanup
 *
 * Revision 1.4  2011/04/26 21:55:20  mujusu
 * detect the browser close and close popups along with it
 *
 * Revision 1.3  2011/02/28 18:44:40  mujusu
 * fix to prevent popup on cancel
 *
 * Revision 1.2  2011/02/25 19:21:23  mujusu
 * added comments, fixed browser close popup issue,
 *
 * 
 * License:  This file should be considered to be under the terms of some
 * non-viral open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 *
 **/


  // This event fires before the browser DOM unloads. This is an indirect way
  // to detect if the browser received a close request, since there is no event
  // that is automatically fired when the browser's  'X' or back buttons are
  // pressed.
  Event.observe(window, 'beforeunload', function (e) {

    // Figure out if this came from the logout link at the top of the page.
    // (This used to check for the account settings link also, but that now
    // causes a popup to be displayed rather than closing the window).

    // If Firefox, the original target is the link text
    if (BrowserDetect.Firefox) {
      oriTarget = e.explicitOriginalTarget ;
      targetTagName = oriTarget.tagName;
      if (targetTagName === undefined && oriTarget.parentNode)
        targetID = oriTarget.parentNode && oriTarget.parentNode.id;
    }
    // Else it's the active element (IE, Chrome, Safari)
    else {
      var oriTarget = document.activeElement;
      var targetTagName = oriTarget.tagName;
      var targetID = oriTarget.id ;
    }

    // If the trigger is from one of the buttons, specified fields or the page 
    // to be unloaded is a popup, then we should let it go
    var closePopupPage = document.location.href.indexOf("from=popup") != -1;
    // user session being logged out.
    var loggingOut = readCookie(Def.Idle.SESSION_COOKIE) == Def.Idle.LOGOFF ;

    // Return without a message for the following cases, letting the window
    // close without comment
    if ((Def.forceLogout_ == true) ||         // e.g., data overflow error
        (!Def.DataModel) ||                   // no data model
        (Def.formName_ === "help") ||         // help popup
        (targetTagName == "BUTTON") ||        // not sure if this works
        (targetTagName == "HTML") ||          // don't know what this is for
        ("/phr_home" == location.pathname) || // on the phr management page
        (targetID == 'fe_logout') ||          // from logout link
        (loggingOut) ||                       // from a timeout logoff
        (!Def.DataModel.dataUpdated_ &&       // no pending changes AND
         (["BODY","#document" ].include(oriTarget.nodeName) ||      // see above
          closePopupPage))) {                            // from a popup window
        Def.UsageMonitor.add('form_closed', {"form_name":Def.formName_,
                                             "form_title":Def.formTitle_}) ;
        Def.UsageMonitor.sendReport() ;
      return;
    }
    // If we got this far, set up a message asking the user to log out before
    // closing the browser.  This message will not actually be displayed in
    // Firefox, which has decided to display it's OWN message if something is
    // returned, but will be displayed in other browsers.
    var message = 'Please log out from the PHR application before closing '+
                  'the browser.  Otherwise you risk unauthorized access ' +
                  'to your account.  Thanks.' ;
    var e = e || window.event;
    // For IE and Firefox (FF Bug: FF4+, system message will be displayed in popup)
    // Otherwise, return message which will show in a popup asking user to confirm
    // continue or return to the page for user to logout.
    if (e) {
      e.returnValue = message;
    }
    // For Safari
    return message;
  });

  // When window closes, close all popups
  Event.observe(window, 'unload', function (e) {
    // if just closing popup. keep session active
    var windowOpener = Def.getWindowOpener(this);
    if (windowOpener && !windowOpener.closed)
      return ;
    createCookie(Def.Idle.SESSION_COOKIE,Def.Idle.LOGOFF,1) ;
    //reloading=true prevents the browser close/unload popup from blocking logout.
    reloading = true ;
    while (Def.CURRENT_POPUPS_ARR.length > 0) {
      popup = Def.CURRENT_POPUPS_ARR.shift() ;
      popup.close() ;
    }
  });