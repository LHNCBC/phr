/**
 * browser_detect.js-> Detects browser type, browser version and OS. It also
 * checks to see if the browser is IE8 if it is running in compatibility mode
 * Function showInfo displays alert messages for IE users.
 *
 * This javascript was downloaded from http://www.quirksmode.org/js/detect.html.
 *
 * A new function was added to check for Compatibility mode in case of IE8.
 * Another function called checkBrowserSupport was added to display a message to the user if
 * the browser is IE and IE < IE8 and if the browser is IE8 and running in compatibility mode.
 *
 *
 * This script uses the navigator.appVersion, navigator.userAgent
 * and navigator.platform to to determine the type, version and OS.
 *
 * $Id: browser_detect.js,v 1.6 2011/08/03 17:17:26 mujusu Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/browser_detect.js,v $
 * $Author: mujusu $
 *
 * $Log: browser_detect.js,v $
 * Revision 1.6  2011/08/03 17:17:26  mujusu
 * javascript confirmation popup fixes
 *
 * Revision 1.5  2011/08/02 14:38:25  taof
 * minor bugfix in browser_detect.js
 *
 * Revision 1.4  2011/06/30 15:20:03  taof
 * bugfix: get popup when navigating to flowsheet from phr_index page
 *
 * Revision 1.3  2011/06/29 13:50:54  taof
 * bugfix: event.fireEvent() not working with IE9
 *
 * Revision 1.2  2010/03/12 15:45:07  abangalore
 * *** empty log message ***
 *
 * Revision 1.1  2009/11/23 20:08:24  abangalore
 * Detects browers and versions.
 *
 *
 * License:  This file should be considered to be under the terms of some
 * non-viral open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 *
 **/
var BrowserDetect = {
  init: function() {
    this.browser = this.searchString(this.dataBrowser) || 
                   navigator.appCodeName ||
                   "An unknown browser";
    this.IE = this.browser == 'Explorer';
    this.Chrome = this.browser == 'Chrome' ;
    this.Safari = this.browser == 'Safari' ;
    this.Firefox = this.browser == 'Firefox' ;
    
    this.version = this.searchVersion(navigator.userAgent) ||
                   this.searchVersion(navigator.appVersion) || 
                   "an unknown version";
    this.OS = this.searchString(this.dataOS) || "an unknown OS";
    this.compatibilityMode = this.checkForCompatibilityMode(navigator.userAgent);
    this.IE7 = this.checkIEVersion(7);
    this.IEoldVersion = this.isIEoldVersion();
    this.IE8compatibilityMode = this.checkIECompatibility(8);
    this.IE8 = this.checkIEVersion(8);
    this.IE9compatibilityMode = this.checkIECompatibility(9);
    this.IE9 = this.checkIEVersion(9);
    this.IE10compatibilityMode = this.checkIECompatibility(10);
    this.IE10 = this.checkIEVersion(10);
  },
   
  //checks to see if browser is IE8
  checkIEVersion: function(versionNumber) {
    return this.IE && (parseInt(this.version) == versionNumber) && !this.compatibilityMode;
  },
  
  //checks to see if broweser is IE8 running in compatibility mode
  checkIECompatibility: function(versionNumber) {
    return this.IE && (parseInt(this.version) == versionNumber) && this.compatibilityMode;
  },
  
  //cheks to see if version of IE is supported
  isIEoldVersion: function() {
    return this.IE && parseInt(this.version) < 9;
  },
  
  searchString: function(data) {
    for (var i = 0; i < data.length; i++) {
      var dataString = data[i].string;
      var dataProp = data[i].prop;
      this.versionSearchString = data[i].versionSearch || data[i].identity;
      if (dataString) {
        if (dataString.indexOf(data[i].subString) != -1) 
          return data[i].identity;
      }
      else 
      if (dataProp)
        return data[i].identity;
    }
  },
  
  searchVersion: function(dataString) {
    var index = dataString.indexOf(this.versionSearchString);
    if (index == -1) 
      return;
    return parseFloat(dataString.substring(index + this.versionSearchString.length + 1));
  },
  
  // This function only works if the Browser is IE.
  // Only IE8 browsers have the "Trident/4.0" value in the user agent string.
  checkForCompatibilityMode: function(dataString) {
    return this.IE && this.version == "7" && dataString.indexOf("Trident/4.0") != -1;
  },
  
  //This function displays a message if the browser is IE and is < IE8.
  checkBrowserSupport: function() {
      
    if (CookieHandler.getCookie("browser_support") == null) {
        
      if (this.IEoldVersion) {
        alert("You seem to be using a version of Internet Explorer that is less than 9.\n Currently we only support Internet Explorer 9.");
        document.location.href = "/login/browser_support";
      }
        
    }
  },
  
  
  dataBrowser: [{
    string: navigator.userAgent,
    subString: "Chrome",
    identity: "Chrome"
  }, {
    string: navigator.userAgent,
    subString: "OmniWeb",
    versionSearch: "OmniWeb/",
    identity: "OmniWeb"
  }, {
    string: navigator.vendor,
    subString: "Apple",
    identity: "Safari",
    versionSearch: "Version"
  }, {
    prop: window.opera,
    identity: "Opera"
  }, {
    string: navigator.vendor,
    subString: "iCab",
    identity: "iCab"
  }, {
    string: navigator.vendor,
    subString: "KDE",
    identity: "Konqueror"
  }, {
    string: navigator.userAgent,
    subString: "Firefox",
    identity: "Firefox"
  }, {
    string: navigator.vendor,
    subString: "Camino",
    identity: "Camino"
  }, { // for newer Netscapes (6+)
    string: navigator.userAgent,
    subString: "Netscape",
    identity: "Netscape"
  }, {
    string: navigator.userAgent,
    subString: "MSIE",
    identity: "Explorer",
    versionSearch: "MSIE"
  }, {
    string: navigator.userAgent,
    subString: "Gecko",
    identity: "Mozilla",
    versionSearch: "rv"
  }, { // for older Netscapes (4-)
    string: navigator.userAgent,
    subString: "Mozilla",
    identity: "Netscape",
    versionSearch: "Mozilla"
  }],
  dataOS: [{
    string: navigator.platform,
    subString: "Win",
    identity: "Windows"
  }, {
    string: navigator.platform,
    subString: "Mac",
    identity: "Mac"
  }, {
    string: navigator.userAgent,
    subString: "iPhone",
    identity: "iPhone/iPod"
  }, {
    string: navigator.platform,
    subString: "Linux",
    identity: "Linux"
  }]

};
BrowserDetect.init();
