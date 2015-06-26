/**
 * reset_account_security.js -> javascript function specific to the 
 * reset_account_security form. 
 *   
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 */ 

/**
 * Send Ajax Request to reset link. Also forward to login page
 */
Def.resetLink = function() {
  new Ajax.Request('/login/expire_reset_key', {
    method: 'get',
    parameters: {  },
    asynchronous: false
  });
  document.location = "/";
}