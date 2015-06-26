/**
 * login.js -> javascript class that contains functions specific to the
 *                 login form
 * Members of this class should be specific to the login form.
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Bascially,
 * you can use the code as long as you give NLM credit.
 *
 *  $Log: login.js,v $
 *  Revision 1.4  2010/07/15 18:28:27  mujusu
 *  flash cookie support
 *
 *  Revision 1.3  2010/02/22 21:38:45  mujusu
 *  fixed , assign function reference
 *
 *  Revision 1.2  2010/02/22 21:02:17  mujusu
 *  somehow leaves an javascript error with Event.observe
 *
 *  Revision 1.1  2010/02/17 22:59:24  mujusu
 *  logoff when login page displayed
 *
 */


/**
 * Set up an event observer to run when the form is loaded
 */
Def.Login = {
 /**
  *   Close the server session when user goes to login page - no, it
  *   already gets done.  Just initialize the page
  **/
  initializePage: function() {
  
    $('fe_password_1_1').hide();
    $('fe_fake_password_1_1').show();
    $('fe_user_name_lbl_1_1').hide();
    $('fe_password_lbl_1_1').hide();
  },

/*
 * Synch the phr_user cookie value between the flash LSO as well as
 * browser cookie.
 */
  checkCookie: function() {
     flash_ready() ;
     var cookie =  readCookie('phr_user') ;
     if (cookie == null || cookie == ''){
       var flash_cookie = null ;
       if (CB_Cookie.is_able()){
         flash_cookie = CB_Cookie.get('phr_user') ;
       }
       if (flash_cookie != null && flash_cookie != '')
       {
         createCookie('phr_user',flash_cookie,365) ;
       }
     }
     else if(cookie != null && cookie != '' && CB_Cookie.is_able() && CB_Cookie.set)
     {
       CB_Cookie.set('phr_user',cookie) ;
     }
   },

   pwdFocus: function() {
     $('fe_password_1_1').show();
     $('fe_password_1_1').focus();
     $('fe_fake_password_1_1').hide();
   },

   pwdBlur: function() {
     if ($('fe_password_1_1').value == '') {
       $('fe_fake_password_1_1').show();
       $('fe_fake_password_1_1').value = $('fe_fake_password_1_1').getAttribute('tipvalue') ;
       $('fe_password_1_1').hide();
     }
   }
}  // end Def.deleteSession

Event.observe(window,'load',Def.Login.initializePage )
Event.observe('main_form','submit',Def.Login.checkCookie )
Event.observe($('fe_fake_password_1_1'),'focus',Def.Login.pwdFocus )
Event.observe($('fe_password_1_1'),'blur',Def.Login.pwdBlur )
// ]]
