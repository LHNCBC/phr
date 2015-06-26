/*
 * phr_popups.js -> javascript functions to support PHR Help popups
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 *
 */

Def.HelpPopups = {

/**
 * This function sets the "Go Back" link based on whether there is another
 * help popup to go back to.
 */
  updateBackLinkDisplay: function() {

    // hide the back link if it is the starting help page
    var url = document.location.href;
    var visible = /go_back=false/.test(url) ? "hidden" : "visible";
    document.getElementById("backLink").style.visibility = visible;
  }, // end updateBackLinkDisplay


/**
 * The next three functions handle reizing the popup window to fit the
 * text that we stuff into it.  They are something like what is used in
 * popups.js but need to be slightly different because of the way these
 * help popups are constructed.  Frank says that once HTML5 is widely used
 * these can be consolidated with what's in popups.js.   4/24/14 lm
 *
 * @param popup the popup window
 */
  resizeToFit: function(popup) {
    if (navigator.userAgent.toLowerCase().indexOf('chrome') > -1){
      this.resizeToFit_withChromeFix(popup);
    } else {
      this.resizeToFit_woChromeFix(popup);
    }
  } ,

  resizeToFit_withChromeFix: function(popup) {
    var ih = popup.innerHeight;
    var oh = popup.outerHeight;
    if (ih > oh) {
      setTimeout(function(){ Def.HelpPopups.resizeToFit_withChromeFix(popup)},100);
    }
    else {
      setTimeout(function(){ Def.HelpPopups.resizeToFit_woChromeFix(popup)},100);
    }
  } ,


  resizeToFit_woChromeFix: function(popup) {
    if (!popup)
      popup = window;
    var h = popup.document.documentElement.offsetHeight;
    var b = popup.document.body;
    if (b.topMargin)
      h = b.offsetHeight + parseInt(b.topMargin) + parseInt(b.bottomMargin);
    var newWindowOuterHeight =  h + popup.outerHeight - popup.innerHeight;
    var maxHeight = popup.screen.availHeight - popup.screenY;
    if (newWindowOuterHeight > maxHeight)
      newWindowOuterHeight = maxHeight;
    if (newWindowOuterHeight != 0)
      popup.resizeTo(popup.outerWidth, newWindowOuterHeight);
  } ,

/**
 * This function performs setups that are needed to record usage statistics
 * for the help popups.  This includes issuing the form_opened event and
 * setting up event handlers for the focus events.  The form_closed event is
 * handled by the browser_close code.
 *
 * @returns {undefined}
 */
  setUpUsageStats: function() {

    window._token = window.opener._token ;
    var popup = window;

    // Find the window that called the first help popup, and point
    // Def.UsageMonitor to the usage monitor on that window, so that all
    // usage events go there.  This lessens the amount of traffic going
    // back to the server, because the events will only be sent back on the
    // original window's schedule (once every xx seconds) instead of each
    // time a help popup closes.
    var parentWindow = window.opener ;
    while (parentWindow.opener) {
      parentWindow = parentWindow.opener ;
    }
    Def.UsageMonitor = parentWindow.Def.UsageMonitor;
    Def.DataModel = parentWindow.Def.DataModel;
    Def.formName_ = "help" ;
    Def.formTitle_ = document.getElementsByTagName("h1")[0].innerHTML ;
    var usage_params = {"form_name":Def.formName_,
                        "form_title":Def.formTitle_}
    Def.UsageMonitor.add('form_opened', usage_params) ;
    Event.observe(popup, 'focus', Def.UsageMonitor.add.bind(Def.UsageMonitor,
                         'focus_on', usage_params)) ;
    Event.observe(popup, 'blur', Def.UsageMonitor.add.bind(Def.UsageMonitor,
                         'focus_off', usage_params)) ;
  } , // end setUpUsageStats

}  // end Def.HelpPopups

Event.observe(window, "load", function() {
  Def.HelpPopups.updateBackLinkDisplay();
  Def.HelpPopups.resizeToFit(window);
  Def.HelpPopups.setUpUsageStats();
});

