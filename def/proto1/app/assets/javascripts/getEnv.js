/*
 * getEnv.js -> javascript to acquire environment info and set
 *              corresponding global variables, includes utility function
 * taken from the bioethics project; modified as needed
 *
 * $Id: getEnv.js,v 1.3 2008/10/24 21:34:31 wangye Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/getEnv.js,v $
 * $Author: wangye $
 *
 * $Log: getEnv.js,v $
 * Revision 1.3  2008/10/24 21:34:31  wangye
 * bug fixes for IE7 and performance tune-up
 *
 * Revision 1.2  2007/04/24 17:17:23  lmericle
 * updates to suppress "required field" icon if no required fields
 *
 * Revision 1.1  2007/04/11 20:14:56  lmericle
 * changes for upgraded help box
 *
 *
 */

/* This script determines, to the extent needed by the other scripts,
 * the current environment - specifically, the browser type, etc.
 * It should be included before all other scripts.
 *
 * The getById function is also included here, as it is used by most 
 * of the rest of the scripts.  It's written to accomodate the various
 * (old) methods of obtaining an object by an ID, as well as the newer
 * method.
 *
 * Prerequisites:  none
 */

/* these are used to condition statements by browser - as needed */

var ns4 = document.layers && !document.getElementById ;
var ie4 = document.all ;
var ns6 = document.getElementById && !document.all ;

/* this flag is used to determine whether or not to display site 
 * help popups - set to true only on user request
 */
/*  not used yet
var siteHelp = false ;
*/
/* this gets an element by ID.  We use it often, and each time 
 * we need to condition on browser type - so it's a general 
 * utility method
 */

function getById(objID) {
  var theObj = null ;
  if (ns4) {
    theObj = document.layers[objID] ;
  }
  else if (ie4) {
    theObj = document.all[objID] ;
    if ((theObj) && (theObj.length) && (theObj.length > 0)) {
      for (var i = 0; i < theObj.length; i++) {
        if (theObj[i].id == objID) {
          holdi = i ;
          i = theObj.length ;         
          theObj = theObj[holdi] ;
        }
      }
    }
  }
  else {
    theObj = document.getElementById(objID) ;
  }
  return theObj ;
}

/**
 * The following function is pretty much the standard for getting
 * elements by class name.  It was written by Dustin Diaz, and 
 * copyrighted under the Creative Commons Licensing.
 *
 * searchClass:: the name of the class for which you want elements
 * node::        optional - used to limit the search to one branch of
 *               the DOM.  document is used if nothing is supplied.
 * tag::         optional - another way to limit the search.  An
 *               asterisk (*) is used if nothing's specified to 
 *               indicate any tag
 *
 * returns an array of elements with the specified class
 */
function getElementsByClass(searchClass,node,tag) {
	var classElements = new Array();
	if ( node == null )
		node = document;
	if ( tag == null )
		tag = '*';
	var els = node.getElementsByTagName(tag);
	var elsLen = els.length;
	var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
	for (var i = 0, j = 0; i < elsLen; i++) {
		if ( pattern.test(els[i].className) ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}
