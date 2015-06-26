/**
 * signup.js -> javascript class that contains functions specific to the
 *              signup form
 *
 * Members of this class should be specific to the signup form.
 *
 * $Id: signup.js,v 1.5 2011/01/04 19:16:50 mujusu Exp $ Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/form/signup.js,v $
 * $Author: mujusu $
 *
 * $Log: signup.js,v $
 * Revision 1.5  2011/01/04 19:16:50  mujusu
 * added onclick
 *
 * Revision 1.4  2010/09/29 16:56:11  mujusu
 * post code review changes based on feedback
 *
 * Revision 1.3  2010/09/23 21:10:38  mujusu
 * updates to terms and conditions box on signup page
 *
 * Revision 1.2  2010/07/15 18:28:26  mujusu
 * flash cookie support
 *
 * Revision 1.1  2010/06/29 19:41:41  lmericle
 * added
 *
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 */

/**
 * Set up an event observer to run loadChoices when the form is loaded
 */
Def.Signup = {
//   userNameErrorMsg_ : 'Please specify between 6 and 32 characters (letters, '+
//     'numbers, and/or underscores) starting with '+
//     'a letter. Click the help icon on the right for detailed requirements.' ,
   
   userName_ : 'undefined',

  /**
   * Popup dialog box used to let the user know something.  Added for use
   * with forced signup for non-user share invitation acceptance.
   *
   */
   infoDialog_: null ,
  /**
   *  If the email fields exist on the form, passes the value of the
   *  experimental field (true or false) to the hide function to hide
   *  (if experimental is true) or show (if experimental is false) the
   *  email group and its fields.  This is specified in the field_descriptions
   *  row for the experimental field for the onchange event.
   *  THIS SHOULD NOT RUN because we've removed the account type group
   *  from the form, at least for now.  8/2012 lm
   */
//  toggleFields: function() {
//
//    if (Def.IDCache.findByIDStart('fe_email_grp').length > 0) {
//      var exp_val = Def.IDCache.findByIDStart('fe_experimental')[0].checked ;
//      Def.Rules.Actions.hide(exp_val, null, null,
//                             Def.IDCache.findByIDStart('fe_email_grp')[0]) ;
//    }
//  },

  /*
   * This function synchs the browser persistenet cookie as well as
   * flash LSO to have the same value.
   */
  checkCookie: function() {
    flash_ready() ;
    var cookie =  readCookie('phr_user') ;
    var flash_cookie = CB_Cookie.get('phr_user') ;
    if (cookie == null || cookie == ''){
      if (flash_cookie != null && flash_cookie != '')
      {
        createCookie('phr_user',flash_cookie,365) ;
      }
    }
    else if(cookie != null && cookie != '' && CB_Cookie.is_able())
    {
      CB_Cookie.set('phr_user',cookie) ;
    }    
       
  },

  /*
   * Called on page load to set up the appropriate listeners for the instructions
   * scrollbar. Sets up appropriate function for onscroll event.
   *
   * If there is data to be loaded into the page, as there will be when the
   * user's email is being preset, load that also and prevent the user from
   * changing it.  This will also show a dialog that explains the process
   * to the new user.
   */
  setupPage: function() {
    // var agreement = $('fe_instructions2_1');
    var checkbox = $('fe_agree_chbox_1');
    checkbox.checked=false;
    checkbox.disabled=false;
   //  agreement.onscroll = Def.Signup.handleScroll;
   if (Def.pageLoadData_) {
     var email_val = Def.pageLoadData_["email_val"];
     var email_fld = $('fe_email_1');
     Def.setFieldVal(email_fld, email_val, false);
     email_fld.setAttribute('readonly', 'readonly') ;
     email_fld.addClassName('readonly_field');
     var sec_email = $('fe_sec_email_1') ;
     Def.setFieldVal(sec_email, email_val, false);
     sec_email.addClassName('hidden_field');
     sec_email.parentNode.addClassName('hidden_field') ;
     var instr2 = $('fe_supplied_email_instr_1') ;
     instr2.removeClassName('hidden_field');
     instr2.parentNode.removeClassName('hidden_field') ;
     Def.setFieldVal($('fe_invite_key'), Def.pageLoadData_["invite_key"], false);
     if (Def.pageLoadData_["msg"]) {
       Def.Signup.showInfo(Def.pageLoadData_["msg"], Def.pageLoadData_["msg_title"]);
     }
   }
  },
  
  /*
   * Checks when the scroll bar has scrolled the entire window.
   * Enables the agree checkbox when instructions fully scrolled.
   */
  handleScroll: function() {
    var agreement = $('fe_instructions2_1');
    var visibleHeight = agreement.clientHeight;
    var scrollableHeight = agreement.scrollHeight;
    var position = agreement.scrollTop;
    if (position + visibleHeight == scrollableHeight) {
      $('fe_agree_chbox_1').disabled=false;
    }
  },

  /*
   * Called when submit button clicked. certain validations performed..
   */
  onClick : function(e) {  
    
    var agreement = $('fe_instructions2_1');
    var visibleHeight = agreement.clientHeight;
    var scrollableHeight = agreement.scrollHeight;
    var position = agreement.scrollTop;
    if (!(position + visibleHeight == scrollableHeight)) {
      $('fe_agree_chbox_1').checked=false ;
      Event.stop(e) ;
      alert(" Please fully scroll through and read the legalese first.") ;
    }    
  } ,


  /** Displays an alert box for this page.
   *
   * @param text the text of the message
   * @param title the title for the window
   */
   showInfo: function(text, title) {
    // Get or construct the warning dialog
    var theAlert = this.infoDialog_;
    if (!theAlert) {
      theAlert = this.infoDialog_ = new Def.ModalPopupDialog({
         width: 600,
         height: 450,
         position: 'center',
         buttons: [{
           text: "OK",
           class: "rounded" ,
           click: function() {
             this.infoDialog_.hide();
          }.bind(this)}]
      });
    }
    theAlert.setContent(text);
    theAlert.setTitle(title);
    theAlert.show();
    return theAlert ;
  }
}// end Def.Signup

Event.observe('main_form','submit',Def.Signup.checkCookie) ;
Event.observe(window,'load',Def.Signup.setupPage ) ;
