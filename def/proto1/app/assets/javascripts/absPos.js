/**
 * absPos.js -> javascript functions to determine absolute screen position
 *
 * $Id: absPos.js,v 1.15 2008/06/19 16:45:03 smuju Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/absPos.js,v $
 * $Author: smuju $
 *
 * $Log: absPos.js,v $
 * Revision 1.15  2008/06/19 16:45:03  smuju
 * fixed bug related to calendar popup position
 *
 * Revision 1.14  2007/11/29 14:26:02  lmericle
 * navigation updates
 *
 * Revision 1.13  2007/09/19 19:25:13  smuju
 * added special check for IE7. Should look at doing per browser.
 *
 * Revision 1.12  2007/05/14 21:25:15  plynch
 * Changes to allow the search result count to be repositioned along with the
 * search result box (a.k.a the auto-completion list box.)
 *
 * Revision 1.11  2007/05/08 00:08:58  plynch
 * Got rid of the extra horizontal scrollbar.
 *
 * Revision 1.10  2007/05/07 22:27:19  plynch
 * check in of changes to use Dojo split-panel
 *
 * Revision 1.9  2007/04/25 15:09:04  lmericle
 * changes to fix single entry box so that it doesn't fall off the page - and for autocompletion lists in repeating tables - so it doesn't disappear when a new
 * line is added to the table!
 *
 * Revision 1.8  2007/04/19 19:14:36  lmericle
 * changes to indicate a required field
 *
 * Revision 1.7  2007/04/13 16:09:29  lmericle
 * changes to position answer lists correctly as they change size
 *
 * Revision 1.6  2007/04/11 18:07:30  lmericle
 * and again
 *
 * Revision 1.5  2007/04/11 17:59:51  lmericle
 * more list placement tweaks
 *
 * Revision 1.4  2007/04/11 17:36:41  lmericle
 * updated to fix box at bottom
 *
 * Revision 1.3  2007/04/11 12:27:11  lmericle
 * changes for answer list box positioning
 *
 * Revision 1.2  2007/03/30 21:48:41  lmericle
 * added
 *
 * Revision 1.1  2007/03/30 15:14:26  lmericle
 * added
 *
 *
 */

/* These functions get an absolute screen position to use in
 * positioning popup windows.  (You could probably use them 
 * for other things too - but for now that's what they're used for.
 *
 * These functions were included in the bioethics site home page with the
 * Post-it note script from javascriptkit.com.  Visit JavaScript Kit
 * (http://javascriptkit.com) for script.  Note - Credit must stay intact 
 * for use.  Also, it's a good site.  Placement of the functions, etc., 
 * has been modified for this site, and the functions are used for 
 * objects other than postit notes. 
 *
 * Prerequisites:  none
 */


function getAbsX(elt) {
  return parseInt(elt.x) ? elt.x : getAbsPos(elt, "Left") ;
}

function getAbsY(elt) {
  return parseInt(elt.y) ? elt.y : getAbsPos(elt, "Top") ;
}

function getAbsPos(elt, which) {
  iPos = 0 ;
  while (elt != null) {
    iPos += elt["offset" + which] ;
    elt = elt.offsetParent ;
  }
  return iPos ;
}
  /*
  * for elements which are in side a psotopn:relatice div. This helps 
  * find absolute position for it correctly by looking at parent elements
  */
function findPosition(obj) {
  var curleft = curtop = 0;
  if(obj.offsetParent)
      while(1) 
      {
        curleft += obj.offsetLeft;
        curtop += obj.offsetTop;
        if(!obj.offsetParent)
          break;
        obj = obj.offsetParent;
      }
   else {
     if(obj.x) {
       curleft += obj.x;
     }
     if(obj.y) {
       curtop += obj.y;
     }
   }        
	return [curleft,curtop];
}

/** 
 * The following function was obtained from the pages of
 * http://www.howtocreate.co.uk.  
 */
function getScrollXY() {
  var scrOfX = 0, scrOfY = 0;
  var browser=navigator.appName;
  var b_version=navigator.appVersion;
  var version=parseFloat(b_version);
  if( typeof( window.pageYOffset ) == 'number' ) {
    //Netscape compliant
    scrOfY = window.pageYOffset;
    scrOfX = window.pageXOffset;
  } else if( document.body && 
            ( document.body.scrollLeft || document.body.scrollTop ) ) {
    //DOM compliant
    scrOfY = document.body.scrollTop;
    scrOfX = document.body.scrollLeft;
  } else if( document.documentElement && 
            ( document.documentElement.scrollLeft ||
              document.documentElement.scrollTop ) ) {
    //IE6 standards compliant mode
    scrOfY = document.documentElement.scrollTop;
    scrOfX = document.documentElement.scrollLeft;
  }
 else if ((browser=="Microsoft Internet Explorer") & (version>=4))
 {
    //IE7 
    scrOfY = document.documentElement.scrollTop;
    scrOfX = document.documentElement.scrollLeft;
 }
  return [ scrOfX, scrOfY ];
}

function curWindowHeight() {
  curHgt = 0 ;
  var browser=navigator.appName;
  var b_version=navigator.appVersion;
  var version=parseFloat(b_version);
  if( typeof( window.pageYOffset ) == 'number' ) {
    //Netscape compliant
    curHgt = window.innerHeight;
  } else if( document.body && 
            ( document.body.scrollLeft || document.body.scrollTop ) ) {
    //DOM compliant
    curHgt = document.body.offsetHeight;
  } else if( document.documentElement && 
            ( document.documentElement.scrollLeft ||
              document.documentElement.scrollTop ) ) {
    //IE6 standards compliant mode
    curHgt = document.documentElement.offsetHeight;
  }
 else if ((browser=="Microsoft Internet Explorer") & (version>=4))
 {
   // for IE7
   curHgt = document.documentElement.offsetHeight;
} 
  return curHgt ;
}

