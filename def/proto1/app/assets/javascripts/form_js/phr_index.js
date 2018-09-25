/*
 * phr_index.js -> javascript functions to support the PHR Management form.
 *
 * Note - this started out as account_management.js, but then we decided to
 * separate form-specific javascript out and put it in form-specific js files.
 *
 * $Id: phr_index.js,v 1.33 2011/08/10 20:07:48 lmericle Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/form/phr_index.js,v $
 * $Author: lmericle $
 *
 * $Log: phr_index.js,v $
 * Revision 1.33  2011/08/10 20:07:48  lmericle
 * minor cosmetic
 *
 * Revision 1.32  2011/07/25 17:00:07  mujusu
 * cursor style bug fix
 *
 * Revision 1.31  2011/07/21 15:58:08  mujusu
 * bug fixes
 *
 * Revision 1.30  2011/07/14 19:00:33  lmericle
 * autosave changes for test panel data
 *
 * Revision 1.29  2011/07/06 19:45:54  taof
 * changes based on code review #351 feedback
 *
 * Revision 1.28  2011/07/05 19:34:10  taof
 * code review #349 updated
 *
 * Revision 1.27  2011/06/17 15:16:31  taof
 * changes based on code review for ie9 bugfix
 *
 * Revision 1.26  2011/06/16 12:57:21  taof
 * IE9 cross browser bug fixing
 *
 * Revision 1.25  2011/04/12 16:07:02  lmericle
 * removed old Def.Logger calls
 *
 * Revision 1.24  2011/04/12 14:54:56  lmericle
 * type fix
 *
 * Revision 1.23  2011/03/29 19:09:38  lmericle
 * added and then commented out code to handle autosave functions for phr_index form
 *
 * Revision 1.22  2011/03/18 23:34:30  plynch
 * Improved the export message.
 *
 * Revision 1.21  2011/03/17 13:17:44  lmericle
 * modified to call edit_profile_with_form instead of get_registration_data
 *
 * Revision 1.20  2011/03/15 18:17:12  lmericle
 * added render_to parameter to call to get_registration_data
 *
 * Revision 1.19  2011/02/15 17:38:51  lmericle
 * commented out autosave initialization
 *
 * Revision 1.18  2011/01/26 21:51:23  plynch
 * The export now puts a message into the notification div to let the user
 * know what to expect after Go is clicked.
 *
 * Revision 1.17  2011/01/18 19:14:47  plynch
 * Changed the text of some messages.
 *
 * Revision 1.16  2010/12/21 16:24:33  wangye
 * bug fix on the validations of the file export fields
 *
 * Revision 1.15  2010/12/10 22:59:28  wangye
 * fixes on the export funtion
 *
 * Revision 1.14  2010/11/30 21:02:43  lmericle
 * modified handling of error option in doAction
 *
 * Revision 1.13  2010/11/17 14:35:59  lmericle
 * updated calls to Def.setFieldVal
 *
 * Revision 1.12  2010/11/09 15:27:00  lmericle
 * fixes from code review for PHR Management & Registration pages merge
 *
 * Revision 1.11  2010/10/29 15:18:33  lmericle
 * major rewrite for combination of management and registration pages; switch from full page submits to ajax calls
 *
 * Revision 1.10  2010/08/13 16:21:14  lmericle
 * modified doAction to reflect changes to page and handle create new action
 *
 * Revision 1.9  2010/03/25 15:18:09  mujusu
 * archive action . do notheing when no actions elected
 *
 * Revision 1.8  2010/03/03 18:51:17  mujusu
 *
 * Cvascript for admin actionVS: ----------------------------------------------------------------------
 *
 * Revision 1.7  2010/01/12 21:46:16  mujusu
 * dont clear arhive action fld
 *
 * Revision 1.6  2010/01/12 21:12:57  mujusu
 * added confirmProfiledelete
 *
 * Revision 1.5  2010/01/05 22:53:54  mujusu
 * added archive option
 *
 * Revision 1.4  2009/09/24 17:55:51  mujusu
 * new case of registration edit to handle
 *
 * Revision 1.3  2009/07/31 19:27:35  plynch
 * Changed routes from /app/phr to /profiles
 *
 * Revision 1.2  2009/06/30 15:35:55  plynch
 * A fix for the action list on the phr_index form.
 *
 * Revision 1.1  2009/05/14 15:39:36  lmericle
 * moved account_management.js to form/phr_index.js to follow (new) convention regarding form-specific javascript; updated phr_index do_action button that refereces the function in the file.
 *
 *
 */

Def.PHRManagement = {

  /**
   * An alert box that can be reused for this page
   * - and looks a LOT better than the Firefox alert box (YUCK)
   */
  warningDialog_: null ,

  /**
   *  Invokes an action specified on the phr management form in response to a
   *  GO-button-click event. For actions triggered by other type of buttons (ie. 
   *  action code 1 and 5), check the control_type_details of these buttons in 
   *  field_descriptions table. 
   *  
   * @param actionCodeFld the field containing that action's code
   * @param idFld the field containing the id of the phr form on which to
   *  take the action
   * @param event the submit event to be stopped if the action is handled
   *  in a different way (i.e., not through submitting the form)
   */
  doAction: function(actionCodeFld, idFld, event) {

    var action_code = $(actionCodeFld).value;
    var id = $(idFld).value;
    var doStop = true ;
    switch (action_code) {

//      // register/create New PHR
//      case "1" :
//        This is handled by the checkTask function, which is invoked
//        by change event observers on the task and record name input fields.
        
      // edit profile
      case "2" :
        Def.setWaitState(false) ;
        Def.setDocumentLocation("/profiles/" + id + ";edit") ;
        break;

      // export the form
      case "3":
        Def.showNotice('Your export should begin downloading in a few '+
            'seconds.  (If you have lots of data, it might take half a minute.'+
            '  Please be patient, and do not press the "Go" button while the '+
            'browser is still working.)  After you have saved it, you may '+
            'choose another task or export format.');
        doStop = false;
        break;

      // view flowsheet
      case "4":
        Def.setWaitState(false);
        Def.setDocumentLocation("/profiles/" + id + "/panels") ;
        break;

//      // edit PHR Registration
//      case "5" :
//        This is handled by the checkTask function, which is invoked
//        by change event observers on the task and record name input fields.

      // Archive profile
      case "6":
        Def.setWaitState(false);
        Def.PHRManagement.doArchiveAction(actionCodeFld, event) ;
        Def.endWaitState(false);
        break;

      // Invalid option
      default:
        //THROW AN ERROR!!!!!!
        break;
    }

    if (doStop) {
      Event.stop(event) ;
    }
  }, // end doAction


/**
   *  Determines whether or not the getRegistrationData method should be
   *  called.  It is called on a change event for both the PHR Task field
   *  and the PHR Record Name field.  The getRegistrationData method is
   *  called if:
   *  1.  the Task is either the edit or the create phr registration task; and
   *  2.  if it's the edit task, there is a valid value in the phr record name
   *  field.
   */
  checkTask:  function() {
    Def.resetFieldValidations();
    Def.hideNotice();
    var actionCode = $('fe_action_C_1').value ;
    var id = $('fe_record_name_C_1').value ;
    if (actionCode == '1' ||
        (actionCode == '5' && id.length > 0 &&
         Def.PHRManagement.checkForUnsavedChanges(id) == false)) {

      this.registrationEditCleanup(false);
      if (actionCode == "5")
        this.getRegistrationData();
    } // end if this is a registration add or update request and
      //        we don't have unsaved changes
  } , 


  checkForUnsavedChanges: function(id) {
    var ret = false ;
    new Ajax.Request('/form/has_autosave_data', {
      method: 'get',
      parameters: {
        authenticity_token: window._token,
        profile_id:  id ,
        render_to: 'json'
      },
      asynchronous: false ,
      onSuccess: function(transport) {
        var formNames = JSON.parse(transport.responseText);
        if (formNames.length > 0) {
          var msg = "<center>You have pending changes that have not been saved " +
                    "or cancelled.<br><br>These changes are from your last " +
                    "update of ";
          var id = $('fe_record_name_C_1').value ;
          var pseudo = $('fe_record_name_1').value ;

          if (formNames.indexOf('phr') >= 0) {
            msg += "the health record " ;
//            Def.setFieldVal($('fe_action_1'), 'Review/Edit PHR', false) ;
//            Def.setFieldVal($('fe_action_C_1'), '2', true) ;
            Def.setFieldVals([$('fe_action_1'), $('fe_action_C_1')],
                             ['Review/Edit PHR', '2']) ;
            if (formNames.length > 1)
              msg += "and test data " ;
          }
          else {
            msg += "test data " ;
//            Def.setFieldVal($('fe_action_1'), 'View Flowsheet', false) ;
//            Def.setFieldVal($('fe_action_C_1'), '4', true) ;
            Def.setFieldVals([$('fe_action_1'), $('fe_action_C_1')],
                             ['View Flowsheet', '4']) ;
          }
          msg += "for <i>" + $('fe_record_name_1').value + ".</i><br><br>" +
                 "These changes must be completed (saved or cancelled) before " +
                 "changes are made to any other data.<br><br>Please click on the " +
                 "<b>x</b> in the top right corner of this box and then, when " +
                 "this small box is gone, click on the <b>Go</b> button to " +
                 "select the " ;
          if (formNames.indexOf('phr') >= 0)
            msg += "<b>Review/Edit PHR</b> " ;
          else
            msg += "<b>View Flowsheet</b> " ;
          msg += "task to take care of these changes.";
          if (formNames.length > 1)
            msg += "<br><br>While you are on the main health record page, please " +
                   "also click on the <b>Add Trackers & Test Results</b> button\nabove " +
                   "the <b>Save & Close</b> button at the top of the page\n" +
                   "to take care of the changes to the test data." ;
          Def.PHRManagement.showWarning(msg, 'Oops') ;
          $('fe_record_name_C_1').value = id ;
          $('fe_record_name_1').value = pseudo ;
          ret = true ;
          Def.Logger.logMessage(['at the end of checkForUnsavedChanges']) ;
        } // end if there are unsaved changes
      }, // end onSuccess
      onFailure: function(transport) {
        ret = true ;
        alert('Error ' + transport.status + ' -- ' + transport.statusText) ;
      }
    }) ; // end request
    return ret ;
  } , // end checkForUnsavedChanges


  /**
    * Handles the Ajax call to the server to get registration data to be
    * updated, and provides the handlers for a successful return and a failed
    * return.
    */
  getRegistrationData: function() {

    Def.setWaitState(false) ;
    
    // construct ajax request
    new Ajax.Request('/form/edit_profile_with_form', {
      method: 'get',
      parameters: {
        authenticity_token: window._token,
        form_name: 'phr_index' ,
        id:  $('fe_record_name_C_1').value ,
        render_to: 'json'
      },
      asynchronous: true ,
      onSuccess: function(transport) {
        var formData = JSON.parse(transport.responseText);
        if (formData && formData.length > 0) {
          Def.DataModel.setup(formData, false, null, false) ;
          Def.Rules.runFormRules();
          // update data used for validation of unique value fields
          Def.updateUniqueValueValidationData();
          // add these lines back in if we ever put autosave on this form.
//          Def.AutoSave.resetData(Def.DataModel.data_table_,
//                                 Def.DataModel.recovered_fields != null) ;          
          Def.endWaitState(false);
        }
      }, 
      on404: function(transport) {
        Def.endWaitState(false) ;
        alert('Error:  registration data not found!') ;
      } ,
      on500: function(transport) {
        Def.endWaitState(false);
        if (transport == 'do_logout') {
          window.location = Def.LOGOUT_URL ;
        }
        else {
          alert('Error ' + transport.status + ' -- ' + transport.statusText) ;
        }
      }, 
      onFailure: function(transport) {
        Def.endWaitState(false) ;
        alert('Error ' + transport.status + ' -- ' + transport.statusText) ;
      }    
    }) ; // end request
  } , // end getRegistrationData
  
  
  /**
   *  Clears out registration data in the demographics section. Also clears out 
   *  the action and record-name fields if needed.
   *  This is used both before the demographics section is displayed and when it 
   *  is closed by either the save or cancel buttons.
   *  @param clearAction flag indicating whether or not to clear the value
   *   of the action field.  Default is true.  This also causes the record
   *   name list to be refreshed when set to true (which it is by the save
   *   and cancel buttons on the demographics section).
   */
  registrationEditCleanup:  function(clearAction) {

    if (clearAction == undefined || clearAction == null)
      clearAction = true ;

// SEE NOTE BELOW
//    if (clearAction) {
//      var clearTempId = Def.getFieldVal($('fe_record_name_C_1'));
//      if (parseInt(clearTempId) > -1)
//        clearTempId = null ;
//    }
    if (!clearAction) { 
      this.clearRegistrationData();
    }
    else {
      $('fe_demographics_1_0').style.display = 'none' ;
      if ($('fe_action_code_1') != '1') {
        this.clearRegistrationData();
        Def.setFieldVal($('fe_action_1'), '', false) ;
        Def.setFieldVal($('fe_action_C_1'), '', false) ;
        refresh_fe_record_name_1_list() ;
      }
    }
// NOT CURRENTLY USED.  This was implemented to work with the autosave data,
// but then Paul decided it wasn't worth bothering with.  Leaving in so that
// it doesn't have to be redone if he changes his mind.
//    if (clearTempId > null) {
//      if (parseInt(clearTempId) < 0) {
//        new Ajax.Request('/form/clear_temp_profile_id', {
//          method: 'get',
//          parameters: {
//            authenticity_token: window._token,
//            temp_id: clearTempId ,
//            form_name: 'phr_index'
//          },
//          asynchronous: true ,
//          onSuccess: function(transport) {
//            var ranOK = JSON.parse(transport.responseText) ;
//            if (!ranOK) {
//              alert('Error on clear_temp_profile_id, check server log') ;
//              Def.endWaitState(false);
//            }
//          },
//          onFailure: function(transport) {
//            Def.endWaitState(false) ;
//            alert('Error ' + transport.status + ' -- ' + transport.statusText) ;
//          } ,
//          on404: function(transport) {
//            Def.endWaitState(false) ;
//            alert('Error:  clear temp profile id returned not found!') ;
//          }
//        }) ; // end request
//      }
//    }  // end if we have a clearTempId to check

  } , // registrationEditCleanup
  
  
  
  /**
   *  Clears out the fields in the demographics section and the taffyDb records
   *  related to those fields
   */
  clearRegistrationData: function(){
    var sectionHdr = $('fe_demographics_1_0');
    var sectionInputs = sectionHdr.select('input');
    // clearnup form fields
    for (var e = 0, max=sectionInputs.length; e < max; e++) {
      Def.setFieldVal(sectionInputs[e], '', false) ;
    }
    // clean up profile information
    Def.DataModel.id_shown_ = null;
    // clean up field values in phrs table
    Def.DataModel.updateOneRecord_Replace("phrs", 1, {}, false);
    // update data used for validation of unique value fields
    Def.Validation.Base.DefaultValueByField_ = {};
  },


  /**
    * Sets up the call to Def.doSave.  There's too much stuff to put this
    * all in the field_description for the save button.
    */
  saveRegistrationData:  function(button) {
    var action_conditions = {} ;
    action_conditions['save'] = $('fe_save_1_1').value ;
    action_conditions['action_C_1'] = $('fe_action_C_1').value ;
    var profile_id = $('fe_record_name_C_1').value;
    if (profile_id < 0) {
      Def.setFieldVal($('fe_record_name_C_1'), '', false) ;
    }
    if (action_conditions['action_C_1'] == "")
      action_conditions['action_C_1'] = '1' ;
    if (action_conditions['action_C_1'] == '1')
      Def.doSave(button, false, action_conditions,
                 function(){Def.PHRManagement.registrationEditCleanup(true);}) ;
    else
     Def.doSave(button, true, action_conditions,
               function(){Def.PHRManagement.registrationEditCleanup(true);}) ;
  } ,


  /**
    * Handles the Ajax call to the server to get registration data to be
    * updated, and provides the handlers for a successful return and a failed
    * return.
    */
  doArchiveAction: function(actionCodeFld, event) {

    Event.stop(event) ;
    document.body.style.cursor = 'wait' ;
    
    var action_code = Def.getFieldVal($(actionCodeFld));
    var id = Def.getFieldVal($('fe_archived_profile_C_1')) ;
    var doOK = true ;
    var successMessage = null;
    switch (action_code) {

      // archive the profile
      case "6":
        id = $('fe_record_name_C_1').value ;
        var prof_name = Def.getFieldVal($('fe_record_name_1')) ;
        var url_method = '/form/archive_profile';
        if ($('fe_arch_profiles_link').parentElement.style.display != 'none')
          successMessage = 'The PHR for ' + prof_name + ' has been ' +
            'archived.  Click the blue "Archived PHRs" link below to ' +
            'manage your archived PHRs.';
        else
          successMessage = 'The PHR for ' + prof_name + ' has been ' +
            'archived.  Use the "Archived PHRs" section below to ' +
            'manage your archived PHRs.' ;
        break ;

      // delete the profile
      case "1":
        var answer =
        window.confirm('Are you sure you wish to permanently delete the PHR?' +
          '\nPress OK to delete the PHR, or cancel to cancel the ' +
          'request (retaining the PHR).');
        if (!answer){
          doOK = false ;
        }
        else {
          url_method = '/form/delete_profile';
          successMessage = 'PHR deleted.';
        }
        break;

      // unarchive the profile
      case "2":
        url_method = '/form/unarchive_profile';
        prof_name = Def.getFieldVal($('fe_archived_profile_1'));
        successMessage = 'The PHR for ' + prof_name + ' has been ' +
          'unarchived.  It should now appear in the "PHR Record Name" list.' ;
        break;

      // invalid - what now?
      default:
        doOK = false ;
        break;

    }
    if (doOK) {
    
      // construct ajax request
      new Ajax.Request(url_method, {
        method: 'post',
        parameters: {
          authenticity_token: window._token ,
          form_name: 'phr_index' ,
          profile_id: id
        },
        asynchronous: true ,
        onSuccess: function(transport) {
          Def.setFieldVal($('fe_arch_action_1'), '', false, false) ;
          Def.setFieldVal($('fe_arch_action_C_1'), '', false, false) ;
          refresh_fe_record_name_1_list() ;
          refresh_fe_archived_profile_1_list() ;
          Def.endWaitState(false) ;
          if (successMessage)
            Def.showNotice(successMessage);
        },
        onFailure: function(transport) {
          Def.endWaitState(false) ;
          alert('Error ' + transport.status + ' -- ' + transport.statusText) ;
        } ,
        on404: function(transport) {
          Def.endWaitState(false) ;
          alert('Error:  Either the registration data was not found or ' +
                'there was some programmatic error.  Sorry.') ;
        }
      }) ; // end request
    } // end if doOK
  }, // end doArchiveAction


  /** Displays an alert box for this page.  Does NOT use the standard
   *  alert box, which is not customizable and is UGLY in Firefox.
   *
   * @param text the text of the message
   * @param title the title for the window
   */
   showWarning: function(text, title) {
    // Get or construct the warning dialog
    var theAlert = this.warningDialog_;
    if (!theAlert) {
      theAlert = this.warningDialog_ = new Def.ModalPopupDialog({
         width: 600,
         height: 320,
         position: 'center'
      });
    }
    theAlert.setContent(text);
    theAlert.setTitle(title);
    theAlert.show();
    return theAlert ;
  }
};  // end Def.PHRManagement

