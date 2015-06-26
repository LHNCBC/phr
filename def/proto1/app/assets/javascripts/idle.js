/** 
 * idle.js -> javascript functions to handle timeout notifications
 * to the user.
 *
 * This script sets a timer on the browser. if there is no activity
 * for a while, a pop-up box is launched with a warning. A warning
 * timer will start counting down in the pop-up, indicating the time
 * left before the session expires. There are two buttons on
 * the pop-up box: OK and cancel. Clicking on OK will reset the session
 * on the server and Cancel will log the user off. If the user fails to
 * click on either button before the warning timer expires, the pop-up box
 * automatically logs off the user and closes itself.
 * An alert box is displayed indicating to the user that the session was
 * timed out.
 *
 * This script also monitors for user activity:mouseove, keypress,click
 * It it detects any of the above events, after waiting for a brief period
 * makes a call to the server and resets the session.
 *
 * $Id: idle.js,v 1.34 2011/08/25 20:52:11 mujusu Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/idle.js,v $
 * $Author: mujusu $
 *
 * $Log: idle.js,v $
 * Revision 1.34  2011/08/25 20:52:11  mujusu
 * fixed popup close/hanging issues with multiple tab windows open
 *
 * Revision 1.33  2011/08/23 13:53:51  mujusu
 * idle popup and session expiry management changes
 *
 * Revision 1.32  2011/06/07 20:09:04  mujusu
 * moified extend_session to extend only when session ending
 *
 * Revision 1.31  2011/05/18 14:15:34  mujusu
 * fixes for validation and QA related issues at account creation time
 *
 * Revision 1.30  2011/04/27 20:17:34  mujusu
 * fixed incorrect times
 *
 * Revision 1.29  2011/04/26 21:55:20  mujusu
 * detect the browser close and close popups along with it
 *
 * Revision 1.28  2011/04/25 14:45:07  mujusu
 * session timeout now via cookies, not sever calls
 *
 * Revision 1.27  2011/04/12 14:53:53  lmericle
 * added doAutosave checking on call to autosave checking for updates in closeSession
 *
 * Revision 1.26  2011/03/23 22:17:49  mujusu
 * added case for reset_account_sdecurity
 *
 * Revision 1.25  2011/03/15 18:14:23  lmericle
 * changes from review comments and to accommodate separate autosave timer
 *
 * Revision 1.24  2011/02/28 17:59:00  plynch
 * Changed some things that used to be post AJAX requests to get requests
 * because POST was not needed, and no longer worked because the window
 * authentication token was not being sent.
 *
 * Revision 1.23  2011/02/25 19:21:23  mujusu
 * added comments, fixed browser close popup issue,
 *
 * Revision 1.22  2011/02/15 17:37:41  lmericle
 * separated out autosave code to separate file; changes to how autosave is done
 *
 * Revision 1.21  2011/01/10 23:17:31  wangye
 * added session timeout for popup window (reminder, printableview)
 *
 * Revision 1.20  2011/01/04 19:17:49  mujusu
 *
 * ut should not show browser close confirm popup
 *
 * Revision 1.19  2010/11/10 17:04:27  mujusu
 * new recovery forms added in no session check
 *
 * Revision 1.18  2010/11/05 23:14:49  plynch
 * removed a debugged statement I accidentally left in
 *
 * Revision 1.17  2010/11/05 22:52:17  plynch
 * Initial version of suggestion list
 *
 * Revision 1.16  2010/09/14 14:16:08  lmericle
 * removed obsolete code in rules.js, per code review
 *
 * Revision 1.15  2010/09/09 21:32:13  mujusu
 * bug fix
 *
 * Revision 1.14  2010/09/07 20:40:57  mujusu
 * changes for compression error
 *
 * Revision 1.13  2010/09/07 19:51:24  mujusu
 * reset_security pages added
 *
 * Revision 1.12  2010/08/03 15:49:35  lmericle
 * converted window.open calls to openPopup calls
 *
 * Revision 1.11  2010/07/07 18:19:00  abangalore
 * .
 *
 * Revision 1.10  2010/06/14 15:24:48  abangalore
 * .
 *
 * Revision 1.9  2010/05/26 19:34:28  abangalore
 * handles sessipm extensopn with more than one instance.
 *
 * Revision 1.8  2010/04/26 17:49:02  abangalore
 * code to handle autosave.
 *
 * Revision 1.7  2010/03/12 15:45:07  abangalore
 * *** empty log message ***
 *
 * Revision 1.6  2010/02/22 20:27:58  plynch
 * Removed an unnecessary call to the DataModel (to get rid of that dependency.)
 *
 * Revision 1.5  2010/01/04 20:00:37  abangalore
 * .
 *
 * Revision 1.4  2009/11/23 19:43:09  abangalore
 * Modified files to support IE8 and IE7. Currently the site only works on IE8 and not on IE7 or lower versions.
 *
 * Revision 1.3  2009/09/30 16:13:27  abangalore
 * .
 *
 *
 * License:  This file should be considered to be under the terms of some
 * non-viral open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 *
 **/
// 3300 secs corresponds to 55 minutes.
// This is 5 minutes less than the 60 min set for the
// session on the server side.

Def.Idle = {
  HOW_LONG: 119, //how long to keep window open for (seconds)
  howLongleft_ : 0,
  IDLE_TIME :  3300*1000, //3300 * 1000; // 55 min in millisecs
  timeOut_ : null ,
  WARNING_TIME : 300 * 1000, //5 min in millisecs
  CHECK_SESSION_TIME : 60 * 1000, // 1 minute in millisecs
  WAIT_TIME : 120 * 1000, // 2 minutes in millisecond
  warningTimer_ : null,
  //popWin_ : null,
  //firstTime_ : true,
  //save_ : false,
  sessStatus_ : "inactive",
  tick_ : "" ,
  SESSION_COOKIE : "session_active" ,
  LAST_EXTEND_TIME_COOKIE : "last_extend_time" ,
  ACTIVE : "Active" ,
  INACTIVE : "Inactive" ,
  LOGOFF : "logoff" ,
  warningDialog_ : null ,
  WARNING_TIMER_MSG : "There has been no server activity for an "+
  "extended period of time.<BR>Your session will time out in " ,
  CLOSED : false ,  // avoids multiple executions of closeSession function


  /**
   * Initializes the events on which to reset the timer and
   * reset the session. This is called only for the
   * URLs that need authentication
   **/
  initEvents: function() {
    var urlPath = window.location.pathname;
    if (["/", "/accounts/answer", "/accounts/forgot_id",
        "/accounts/forgot_id_step2", "/accounts/new", "/accounts/login",
        "/accounts/forgot_password", "/accounts/change_password",
        "/accounts/contact_support", "/accounts/get_reset_link",
        "/accounts/logout", "/accounts/two_factor",
        "/accounts/reset_account_security"].indexOf(urlPath) == -1) {
      Event.observe(document.body, 'mousemove', Def.Idle.resetIdle, true);
      Event.observe(document.body, 'click', Def.Idle.resetIdle, true);
      Event.observe(document.body, 'keypress', Def.Idle.resetIdle, true);
      Def.Idle.initSession() ;
      Def.Idle.setIdle();
    }
  }, // end initEvents


  /**
   * Make ajax call to server to refresh session and
   * reset the timers
   **/
  extendSession: function(extend_time) {
    Def.Idle.sessStatus_ = readCookie(Def.Idle.SESSION_COOKIE) ;
    if (Def.Idle.sessStatus_ != Def.Idle.LOGOFF) {
      createCookie(Def.Idle.SESSION_COOKIE,Def.Idle.ACTIVE,1) ;
      new Ajax.Request('/application/extend_session?extend_by='+extend_time, {
        method: 'get',
        asynchronous: true
      });
      clearInterval(Def.Idle.tick_);
      Def.Idle.setIdle(extend_time);  
    }
  }, // end extendSession


  /**
   * Resets the server session
   */
  refreshSession: function() {
    Def.Idle.extendSession(Def.Idle.IDLE_TIME);
  },


  /**
   * Initialize the session cookie, set status to active at start
   */
  initSession: function() {
    var cookie = readCookie(Def.Idle.SESSION_COOKIE);
    if (cookie == null || cookie == "" || cookie == Def.Idle.INACTIVE || 
      cookie == Def.Idle.LOGOFF){
      createCookie(Def.Idle.SESSION_COOKIE,Def.Idle.ACTIVE,1)
    }
    Def.Idle.checkSession() ;
    var lastExtendTime =  (new Date()).getTime() ;
    createCookie(Def.Idle.LAST_EXTEND_TIME_COOKIE,lastExtendTime,1)
  },


  /**
   * Close the server session and redirect to login page.
   **/
  closeSession: function() {
    Def.Idle.sessStatus_ = readCookie(Def.Idle.SESSION_COOKIE) ;
    // Only run this if it hasn't already been run.  There's something that
    // causes this to run more than one, but I have not been able to find
    // out what that is.  lm, 9/26/12.
    if (Def.Idle.CLOSED == false) {
      Def.Idle.CLOSED = true ;

      if (Def.DataModel.initialized_ && Def.DataModel.doAutosave_)
        Def.AutoSave.checkForUpdates() ;
      
      // close all popups
      while (Def.CURRENT_POPUPS_ARR.length > 0){
        popup = Def.CURRENT_POPUPS_ARR.shift() ;
        if (popup){
          popup.close() ;
        }
      }
        
      if (Def.Idle.sessStatus_ != Def.Idle.LOGOFF){
        createCookie(Def.Idle.SESSION_COOKIE,Def.Idle.LOGOFF,1) ;
        reloading = true ;
      }
    
    // If this is a popup, just close the window. Parent window would read the 
    // LOGOFF status cookie and call logoff method preventing duplicate calls.
      if (Def.getWindowOpener())     {
        window.close() ;
      }
      else // top window calls the logoff method.
      {                
        new Ajax.Request('/login/timeout_logoff', {
          method: 'get',
          asynchronous: true,
          onComplete: function() {
            Def.reload_ = true ;
            Def.clicked_ = true ;
            document.location.href = '/accounts/login'
          }
        });
      }
    } // end if this hasn't already been run
  },  // end closeSession


  /**
   * This function checks the state of the session every minute.
   * It detects that the session has been logged off then it logs off as well.
   */
  checkSession: function() {
    Def.Idle.sessStatus_ = readCookie(Def.Idle.SESSION_COOKIE)
    if (Def.Idle.sessStatus_ != null &&
      (Def.Idle.sessStatus_ == Def.Idle.ACTIVE || 
        Def.Idle.sessStatus_ == Def.Idle.INACTIVE)){
      setTimeout("Def.Idle.checkSession()", Def.Idle.CHECK_SESSION_TIME);
    }
    else
    {
      Def.Idle.closeSession() ;
    }
  }, // end checkSession


  /**
   * If an activity is detected reset timer
   **/
  resetIdle: function() {
    var lastActive = new Date().toISOString();
    var lastExtendTime =  new Date().getTime() ;
    createCookie(Def.Idle.LAST_EXTEND_TIME_COOKIE,lastExtendTime,1) ;
    Def.Idle.sessStatus_ = readCookie(Def.Idle.SESSION_COOKIE) ;
    Def.UsageMonitor.add('last_active', lastActive);
    if (Def.Idle.sessStatus_ != Def.Idle.LOGOFF && (!Def.Idle.warningDialog_ || 
        !Def.Idle.warningDialog_.dialogOpen_))
      createCookie(Def.Idle.SESSION_COOKIE,Def.Idle.ACTIVE,1) ;
  },


  /**
   * Set timer
   **/
  setIdle: function(diff) {
    clearTimeout(Def.Idle.timeOut_);
    clearTimeout(Def.Idle.warningTimer_);
    if (diff){
      Def.Idle.timeOut_ = setTimeout("Def.Idle.closeSession()", diff);
      Def.Idle.warningTimer_ = setTimeout("Def.Idle.popupCheck()", 
        (diff - Def.Idle.WARNING_TIME));
    }
    else
    {
      Def.Idle.timeOut_ = setTimeout("Def.Idle.closeSession()", Def.Idle.IDLE_TIME);
      Def.Idle.warningTimer_ = setTimeout("Def.Idle.popupCheck()", 
        (Def.Idle.IDLE_TIME - Def.Idle.WARNING_TIME));
    }
  },


  /**
   * If there is no activity for 42 minutes then set session state to
   * inactive, wait for 10 minutes and see if another page or browser
   * has reset the session to active.
   */
  setInactive: function(){  
    createCookie(Def.Idle.SESSION_COOKIE,Def.Idle.INACTIVE,1) ;
    setTimeout("Def.Idle.checkTime()", Def.Idle.WAIT_TIME);
  },


  /**
   * This function checks if the session state has been
   * changed to active
   */
  checkTime: function(){
    if (readCookie(Def.Idle.SESSION_COOKIE) == Def.Idle.ACTIVE) {
      Def.Idle.resetIdle();
    }
  },


  /**
   * If user activity since start or last session extension, determine the 
   * remaining session time and extend session  by that time. Otherwise
   * call showWarning to open a pop-up window with timer counting down. 
   **/
  popupCheck: function() {
    var lastExtendTime = readCookie(Def.Idle.LAST_EXTEND_TIME_COOKIE) ;
    var diff =Def.Idle.IDLE_TIME-((new Date()).getTime()-lastExtendTime);
    if (diff > Def.Idle.WARNING_TIME)
    {
      Def.Idle.extendSession(diff) ;
      return ;
    } else {
      Def.Idle.showWarning() ;
    }
  },


  /**
   * Open a popup message with timeout warning
   */
  showWarning: function() {
    // Get or construct the warning dialog
    if (!Def.Idle.warningDialog_) {
      Def.Idle.warningDialog_ =new Def.ModalPopupDialog({
        width: 300,
        stack: true,
        buttons: {
          "Extend Session": function() {
            clearInterval(Def.Idle.tick_);
            Def.Idle.refreshSession();
            Def.Idle.warningDialog_.buttonClicked_ = true ;
            Def.Idle.warningDialog_.hide() ;
          },
          Logout: function() {
            Def.Idle.warningDialog_.buttonClicked_ = true ;
            Def.Idle.closeSession();
            Def.Idle.warningDialog_.hide() ;
          }
        },
        beforeClose: function(event, ui) {
          // prevents popup closure by clicking on x
          if (!Def.Idle.warningDialog_.buttonClicked_) return false ;
        },
        open: function() {
          Def.Idle.warningDialog_.dialogOpen_ = true ;
        },
        close: function() {
          Def.Idle.warningDialog_.dialogOpen_ = false ;
        }
      });

      Def.Idle.warningDialog_.setContent(
        '<div id="fsWarningMessage" style="margin-bottom: 1em"></div>');
    }
 
    // clear out old values if present/reset
    Def.Idle.warningDialog_.buttonClicked_ = false ;
    Def.Idle.warningMessage(Def.Idle.WARNING_TIMER_MSG+" 2 minutes and 0 seconds") ;
    Def.Idle.warningDialog_.setTitle('Your session is about to expire!');
    if(window.top == window.self) {
      Def.Idle.warningDialog_.show();
    }
    Def.Idle.setInactive() ;
    Def.Idle.warningTimeouts() ;
  }, // end showWarning


  warningMessage: function(msg){
    $('fsWarningMessage').innerHTML = msg ;
  },


  /**
   * Start the warning timer on window pop-up
   **/
  warningTimeouts: function() {
    Def.Idle.howLongleft_ = Def.Idle.HOW_LONG ;
    Def.Idle.tick_ = setInterval("Def.Idle.tick()", 1000);
  },


  /**
   * Tick down the timer by 1 second and display countdown
   * in pop-up window
   **/
  tick: function() {
    Def.Idle.sessStatus_ = readCookie(Def.Idle.SESSION_COOKIE) ;
    if (Def.Idle.warningDialog_ && Def.Idle.warningDialog_.dialogOpen_ &&
      Def.Idle.sessStatus_ != null && Def.Idle.sessStatus_ == Def.Idle.ACTIVE){
      Def.Idle.warningDialog_.dialogOpen_ = false ;
      Def.Idle.refreshSession();
      Def.Idle.warningDialog_.hide() ;
      clearInterval(Def.Idle.tick_);
      Def.Idle.setIdle() ;
    }
    else if (Def.Idle.sessStatus_ != null && 
      Def.Idle.sessStatus_ == Def.Idle.LOGOFF){
      Def.Idle.closeSession() ;
        }
    else{
      //subtract one second
      Def.Idle.howLongleft_ -= 1;
      if (Def.Idle.howLongleft_ < 1){
        Def.Idle.warningMessage("Session Timed Out. Closing browser window....") ;
        Def.Idle.closeSession() ;
      }
      else {
        var timeValue = "";
        if (Def.Idle.howLongleft_ >= 60) {
          timeValue += (Def.Idle.howLongleft_ - 
            (Def.Idle.howLongleft_ % 60))/60+" minute and ";
        }
        //append number of seconds
        timeValue += (Def.Idle.howLongleft_ % 60) +  " seconds";
        //show message
        Def.Idle.warningMessage(Def.Idle.WARNING_TIMER_MSG+timeValue) ;
      }
    }
  } // end tick
} 
