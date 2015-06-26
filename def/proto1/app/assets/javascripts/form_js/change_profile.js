/**
 * change_profile.js -> javascript class that contains functions specific to the
 *              change_profile form.
 * Members of this class should be specific to the change_profile.js form.
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 */ 

/**
 * Set up an event observer to run loadChoices when the form is loaded
 */
Def.ChangeProfile = {
  
  originalQuestions_ : {} ,
  fquest1_ : null,
  fansw1_ : null ,
  fquest2_ : null ,
  fansw2_ : null ,
  squest1_ : null ,
  sansw1_ : null ,

  passBox_ : '<p>Enter your password to confirm account deletion. Once the account is'+
            ' deleted the associated profiles and data cannot be recovered.</p>'+
          '<form> <label for="name" style="float:left; width: 30%">Password: </label>'+
		      '<input type="password" name="delete_password" id="delete_password" '+
          'class="text" style="width: 65%"/></form><p id="warning_msg"></p>',
  /*
   * Called when one of the email addresses is updated. Makes the fields required
   * or not depending on if one of the emails is entered. This function is called
   * when form is validated.
   */
  onQuestionChange : function(ele) {
    var qaHash = {} ;
    qaHash[Def.ChangeProfile.fquest1_.id] = Def.ChangeProfile.fansw1_ ;
    qaHash[Def.ChangeProfile.fquest2_.id] = Def.ChangeProfile.fansw2_ ;
    qaHash[Def.ChangeProfile.squest1_.id] = Def.ChangeProfile.sansw1_ ;
    
    var label = {"cp_fixansw":[["Enter Fixed Question Answer"],"Change Security Questions"],
      "cp_selfansw":[["Enter Self-Defined Question Answer"],"Change Security Questions"]};
    Def.dataFieldlabelNames_ = $J.extend(label,Def.dataFieldlabelNames_) ;
    
    if (ele.value == Def.ChangeProfile.originalQuestions_[ele.id]){
      qaHash[ele.id].removeClassName("required") ;
      Def.Validation.RequiredField.Functions.unregisterField(qaHash[ele.id]) ;
    }
    else {
      qaHash[ele.id].addClassName("required") ;
      // Prevent duplicate entries.
      var index = Def.Validation.RequiredField.Functions.reqFldIds_.indexOf(qaHash[ele.id].id);      
      if(index == -1){
        Def.Validation.RequiredField.Functions.insertNewReqFlds([qaHash[ele.id]]) ;
      }
    }  
  },
  
  /*
   * Called on form load to load original questions
   */
  originalQuestion : function() {
    Def.ChangeProfile.fquest1_ = $('fe_cp_fixquest_1_1') ;
    Def.ChangeProfile.fansw1_ = $('fe_cp_fixansw_1_1') ;
    Def.ChangeProfile.fquest2_ = $('fe_cp_fixquest_1_2') ;
    Def.ChangeProfile.fansw2_ = $('fe_cp_fixansw_1_2')  ;
    Def.ChangeProfile.squest1_ = $('fe_cp_selfquest_1_1') ;
    Def.ChangeProfile.sansw1_ = $('fe_cp_selfansw_1_1')  ;
    Def.ChangeProfile.originalQuestions_[Def.ChangeProfile.fquest1_.id] = 
      Def.getFieldVal(Def.ChangeProfile.fquest1_) ;
    Def.ChangeProfile.originalQuestions_[Def.ChangeProfile.fquest2_.id] = 
      Def.getFieldVal(Def.ChangeProfile.fquest2_) ;
    Def.ChangeProfile.originalQuestions_[Def.ChangeProfile.squest1_.id] = 
      Def.getFieldVal(Def.ChangeProfile.squest1_) ;
  },
  
  /**
   * Open a popup message with password input field. User enters password which
   * is verified on server side before account is deleted.
   */
  showPasswordBox: function() {
    // Get or construct the warning dialog
    if (!Def.ChangeProfile.warningDialog_) {
      Def.ChangeProfile.warningDialog_ =new Def.ModalPopupDialog({
        width: 400,
        stack: true,
        buttons: {
          "Delete Account": function() {
            Def.ChangeProfile.deleteAccount();
            Def.ChangeProfile.warningDialog_.buttonClicked_ = true ;
            Def.ChangeProfile.warningDialog_.hide() ;
          },
          Cancel: function() {
            Def.ChangeProfile.warningDialog_.buttonClicked_ = true ;
            Def.ChangeProfile.warningDialog_.hide() ;
            // clean up the fields
            $('warning_msg').innerHTML = '';
            $('delete_password').value = '';  
          }
        },
        beforeClose: function(event, ui) {
          // prevents popup closure by clicking on x
          if (!Def.ChangeProfile.warningDialog_.buttonClicked_) return false ;
        },
        open: function() {
          Def.ChangeProfile.warningDialog_.dialogOpen_ = true ;
        },
        close: function() {
          Def.ChangeProfile.warningDialog_.dialogOpen_ = false ;
          Def.ChangeProfile.warningDialog_.hide() ;
        }
      });

      Def.ChangeProfile.warningDialog_.setContent(
        '<div id="confirm_passwd" style="margin-bottom: 1em"> '+
           Def.ChangeProfile.passBox_+'</div>');
    }
 
    // clear out old values if present/reset
    Def.ChangeProfile.warningDialog_.buttonClicked_ = false ;
    Def.ChangeProfile.warningDialog_.setTitle('Enter your password');
    if(window.top == window.self) {
      Def.ChangeProfile.warningDialog_.show();
    }
    Def.Idle.setInactive() ;
  }, // end showPasswordBox

  
  
  warningMessage: function(msg){
    $('confirm_passwd').innerHTML = msg ;
  },
  
  
  /**
   * Make an Ajax call to the server to delete the user account. 
   * 
   **/
  deleteAccount: function() {
    createCookie(Def.Idle.SESSION_COOKIE,Def.Idle.ACTIVE,1) ;
    var params = { };
    if (window._token) // Add the authenticity_token for CSRF security check
      params.authenticity_token = window._token || '';
    params.password = $('delete_password').value ;
    params['_method'] = 'delete'
    new Ajax.Request('/accounts/delete_account', {
      method: 'post',
      parameters: params ,
      asynchronous: true,
      onSuccess: function(response) {
        // if successful, close windows and logout user
        resp = response.responseText ;
        if (resp == 'Valid') {
          var windowOpener = Def.getWindowOpener();
          if (windowOpener) {
            Def.forceLogout = true ;
            windowOpener.Def.showNotice('Account deleted. You are logged out.');
            windowOpener.location = Def.LOGOUT_URL
            window.close();
          }
        }
        //if unsuccessful/incorrect passwd, show error message to user for retry.
        else {
          resp = response.responseText ;
          $('warning_msg').innerHTML = '<span style="color:red">'+resp+'</span>';
          // clean up the password field
          $('delete_password').value = '';
          Def.ChangeProfile.warningDialog_.show();
        }
      },
      // if errors, hide popup box and show error on window.
      onFailure: function(response) {
        resp = response.responseText ;
        Def.showError('Error deleting account.');
      }
    });
  } // end deleteAccount
} // end Def.Signup