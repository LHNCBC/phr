/**
 * cookie_handle.js--> This class provides a set of methods to set, get and delete cookies
 * in javascript.
 * 
 * This javascript was downloaded from 
 * http://www.developertutorials.com/tutorials/javascript/custom-javascript-functions-060822/page9.html
 *
 * $Id: cookie_handler.js,v 1.1 2009/11/23 20:07:30 abangalore Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/cookie_handler.js,v $
 * $Author: abangalore $
 *
 * $Log: cookie_handler.js,v $
 * Revision 1.1  2009/11/23 20:07:30  abangalore
 * This file provides a set of functions to handle cookies.
 *
 *
 * License:  This file should be considered to be under the terms of some
 * non-viral open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 *
 **/
var CookieHandler = {
  // return cookie value for a cookie name
  getCookie: function(name) {
    var start = document.cookie.indexOf( name + "=" );
	var len = start + name.length + 1;
	if ( ( !start ) && ( name != document.cookie.substring( 0, name.length ) ) ) {
		return null;
	}
	if ( start == -1 ) return null;
	var end = document.cookie.indexOf( ';', len );
	if ( end == -1 ) end = document.cookie.length;
	return unescape( document.cookie.substring( len, end ) );

  },
  // set a cookie. Optionally set expiry time, path, domain and secure.
  setCookie: function(name, value, expires, path, domain, secure) {
  var today = new Date();
	today.setTime( today.getTime() );
	if ( expires ) {
		expires = expires * 1000 * 60 * 60 * 24;
	}
	var expires_date = new Date( today.getTime() + (expires) );
	document.cookie = name+'='+escape( value ) +
		( ( expires ) ? ';expires='+expires_date.toGMTString() : '' ) + //expires.toGMTString()
		( ( path ) ? ';path=' + path : '' ) +
		( ( domain ) ? ';domain=' + domain : '' ) +
		( ( secure ) ? ';secure' : '' );

  },
  // delete cookie with name
  deleteCookie: function(name, path, domain) {
   if ( getCookie( name ) ) document.cookie = name + '=' +
			( ( path ) ? ';path=' + path : '') +
			( ( domain ) ? ';domain=' + domain : '' ) +
			';expires=Thu, 01-Jan-1970 00:00:01 GMT';

  }
  
};


