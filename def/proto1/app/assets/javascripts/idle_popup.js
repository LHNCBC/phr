/** 
 * idle_popup.js -> javascript to handle interactions within the pop-up page.
 * 
 * This script is called from within the pop-up html.  This script sets up
 * a warning timer that counts down. There are two links: Clicking OK will reset
 * the session. Clicking Cancel will logoff the user. In both cases
 * the window is closed after the action.
 *
 * $Id: idle_popup.js,v 1.5 2011/08/23 13:53:51 mujusu Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/idle_popup.js,v $
 * $Author: mujusu $
 * 
 * $Log: idle_popup.js,v $
 * Revision 1.5  2011/08/23 13:53:51  mujusu
 * idle popup and session expiry management changes
 *
 * Revision 1.4  2010/08/03 15:49:35  lmericle
 * converted window.open calls to openPopup calls
 *
 * Revision 1.3  2009/09/30 16:13:35  abangalore
 *
 * 
 * License:  This file should be considered to be under the terms of some
 * non-viral open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 * 
 **/
var HOW_LONG = 115; //how long to keep window open for (seconds)
/**
 * Start the warning timer on window pop-up
 **/
function onPageOpen() {
  //close page after howLong elapsed
  var a = setTimeout("self.close()", HOW_LONG * 1000);
  //run tick func every second
  var b = setInterval("tick()", 1000);
}

/**
 * Tick down the timer by 1 second and display countdown
 * in pop-up window
 **/
function tick() {
  //subtract one second
  HOW_LONG -= 1;
  var timeValue = "";
  var timeLeft = HOW_LONG //- second;
  if (timeLeft >= 60) {
    timeValue = (timeLeft - (timeLeft % 60)) / 60 + " minute and ";
  }
  //append number of seconds
  timeValue += (HOW_LONG % 60) + " seconds";
  //show message
  document.getElementById('fsWarningMessage').innerHTML = "There has been no server activity for " +
                                  "an extended period of time.<BR>Your " +
                                  "session will time out in " + timeValue + ".";
}

/**
 * display on clicking OK. Refresh session and close
 **/
function stillHere() {
  //resets timer on parent page and closes this window
  Def.getWindowOpener().refreshSession();
  window.close();
}

/**
 * display on cancel. Close session and go away
 **/
function goAway() {
  //logout on parent page and close this window
  Def.getWindowOpener().closeSession();
  window.close();
}