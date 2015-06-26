/** 
 * autosave.js -> The AutoSave object and methods
 *
 * This object and its methods implement the client-side processing for the
 * autosave feature, which is available only for certain forms that are used
 * to enter and update user data.
 *
 * These were broken out from the idle.js file to separate the two different
 * functionalities.
 *
 * $Id: autosave.js,v 1.10 2011/08/17 18:19:37 lmericle Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/autosave.js,v $
 * $Author: lmericle $
 *
 * $Log: autosave.js,v $
 * Revision 1.10  2011/08/17 18:19:37  lmericle
 * minor changes from code reviews, formatting, typos
 *
 * Revision 1.9  2011/08/10 20:04:23  lmericle
 * added comments for 2 functions
 *
 * Revision 1.8  2011/07/14 19:00:33  lmericle
 * autosave changes for test panel data
 *
 * Revision 1.7  2011/07/05 19:34:10  taof
 * code review #349 updated
 *
 * Revision 1.6  2011/06/22 23:32:04  plynch
 * Fixes for issue 2456:
 * application_phr.js - blank rows are now hidden when the form loads
 * added a method for checking whether autosaves are needed (for the acceptance
 * tests)
 * controlled_edit_table: blank rows are now hidden until a save occurs;
 *  when a save occurs blank/deleted rows are removed;
 *  rows are not renumbered when a save occurs (though I temporarily left
 *  a method for that there.)
 * data_model - added getFormFieldAtRowPosition
 *
 * Revision 1.5  2011/04/05 14:19:04  lmericle
 * changes from code review
 *
 * Revision 1.4  2011/03/15 18:11:46  lmericle
 * created separate timer for autosave functions, set to 20 seconds
 *
 * Revision 1.2  2011/02/16 16:07:16  lmericle
 * fixed stray text problem in data_model.txt that caused problems in autosave.js as a side-effect
 *
 * Revision 1.1  2011/02/15 17:34:08  lmericle
 * added
 *
 *
 * License:  This file should be considered to be under the terms of some
 * non-viral open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 *
 **/

Def.AutoSave = {
  
  /**
   *  The interval at which to save any changes that have not been saved or
   *  autosaved.
   */
  CHECK_AUTOSAVE_TIME : 10 * 1000 , // 10 seconds in milliseconds
  
  /**
   * The timeout object used to trigger the (next) check
   */
  checkTime_ : '' ,
  
  /**
   * Flag indicating whether or not an autosave request is currently
   * running on the server
   */
  running_ : false ,
  
  /**
   * Hash that contains a copy of the Def.DataModel.data_table_ before
   * any changes are made.  Used to determine if a user has basically rolled
   * back a change by changing it back to its original value.  
   */
  origData_ : {} ,
   
  /**
   * Sparse hash that contains changes to fields in the data model's
   * data table.  This only contains entries for fields that have
   * been changed.  Note that where the origData_ hash has an array
   * for each table, the changedData_ hash is all hashes so that we
   * store no empty hashes or arrays.  (REWORD)
   */
  changedData_ : {} ,
   
  /**
   * This sets the original data hash to the data table passed in IF the form 
   * being loaded (or updated) does not include recovered data.  If the form 
   * does include recovered data, the base data and latest changed data hashes 
   * are retrieved from the database so that they will match the original and
   * changed states of the form.
   * 
   * This should be called when a form is loaded.  It also needs to be called
   * when a save or rollback is being executed without a form close, because
   * the original data hash needs to be re-written and the changed data hash 
   * needs to be cleared. 
   * 
   * @param dataTable the original data for the form
   * @param getFromDb flag indicating whether or not the data should be 
   *  retrieved from the database.  This will be true if a form has recovered
   *  data.
   * @param getChanges an optional parameter that indicates whether or not
   *  to get the change hash as well as the base data.  The default is true; 
   *  false is used when we are adding loinc panels to test panel forms
   *  (panel_edit & panel_view).  
   */
  resetData: function(dataTable, getFromDb, getChanges) {
    if (!getFromDb) {
      Def.AutoSave.origData_ = Def.deepClone(dataTable) ; 
      Def.AutoSave.changedData_ = {} ;
    }
    else {
      if (getChanges === undefined)
        getChanges = true ;
      // get the hashes from the database
      new Ajax.Request('/form/get_autosave_data', {
        method: 'get',
        parameters: {
          authenticity_token: window._token,
          profile_id: Def.DataModel.id_shown_ , 
          form_name: Def.DataModel.form_name_ ,
          get_changes: getChanges
        },
        asynchronous: false ,
        onSuccess: function(response) {
          var evaled_resp = response.responseText.evalJSON() ;
          if (typeof evaled_resp[0] == "string") {
            Def.AutoSave.origData_ = evaled_resp[0].evalJSON() ;
          }
          else {
            Def.AutoSave.origData_ = evaled_resp[0] ;        
          }
          if (getChanges) {
            if (evaled_resp[1] != null && typeof evaled_resp[1] == "string")
              Def.AutoSave.changedData_ = evaled_resp[1].evalJSON() ;
            else
              Def.AutoSave.changedData_ = evaled_resp[1] ;
          }
        } ,
        onFailure: function(response) {
          if (response == 'do_logout') {
            window.location = Def.LOGOUT_URL ;
          }
          else {
            alert('Error ' + response.status + ' -- ' + response.statusText) ;
          }     
        } 
      });      
    } // end if the form doesn't/does have recovered data on it
  } , // end resetData
  
  
  /**
   * Processes an update provided by the data model (Def.DataModel).
   * 
   * This ASSUMES that the origData_ hash contains a hash for each table
   * on the form and a field entry for each field in existing rows, whether
   * or not it has data in it.  (This is the way the data_table_ in the
   * data model is structured).
   * 
   * The types of updates this function will receive are:
   * 
   * 1.  Updates to existing data (i.e., data that existed when the form
   *     was loaded).  These will include:
   *     a.  updated values for a field in an existing row;
   *     b.  a delete instruction for a row (where the field name will be
   *         'record_id' and the value will be the id number preceded by
   *         the word 'delete'); and
   *     c.  an undelete instruction for a row (where the field name will,
   *         again, be 'record_id' and the value will be the id number 
   *         WITHOUT 'delete' preceding it).
   * 
   *  2.  Updates to rows that don't exist in the original data.  These
   *      will include:
   *      a.  a field value for a row that doesn't exist either in the 
   *          original data or the changed data hash;
   *      b.  a field value for a row that exists in just the changed data 
   *          hash; and
   *      c.  a 'Removed' flag for a row that was added and subsequently
   *          deleted.
   *          
   *  Updates to existing data are compared to the corresponding value in the
   *  original data.  If they differ, the new value is added to the changed
   *  data hash, adding whatever parent objects are necessary.  If they match,
   *  the field is removed from the changed data hash, as are any parent objects
   *  that are left empty after the field is removed.  For delete and undelete
   *  instructions, alteration of the record id will correctly flag the row's
   *  status for later processing.
   *  
   *  Updates to new data are simply added to the changed data hash, creating
   *  any parent objects necessary.  The one exception to this is a blank 
   *  record id specification for a row that's been flagged as 'Removed'.  
   *  Removed rows are entirely blanked out, and so a blank field value will
   *  be passed to this function for every field in the row.  The 'Removed'
   *  flag, which is written to the record id field, is passed by a separate 
   *  function in the Data Model and may be received before the blank field 
   *  value for the record id is received.  We ignore this case to avoid
   *  'unflagging' the row.
   *  
   *  Note that although deleted rows can be undeleted, removed rows cannot.  
   *  So removed row numbers are not reused. 
   * 
   * @param tableName the name of the table containing the change
   * @param rowNum the row number in the table
   * @param fieldName the field in the row
   * @param value the new value
   */
  addUpdate: function(tableName, rowNum, fieldName, value) {
 
    var rowIdx = rowNum - 1 ;
    if (Def.AutoSave.changedData_[tableName] == null)
      Def.AutoSave.changedData_[tableName] = {} ;
    var changedTable = Def.AutoSave.changedData_[tableName] ;

    // Process a field for a new row i.e., one that does not exist in the
    // original data.  Assume that the origData_ hash will be there and
    // that the user can't add new tables to to form.
    if (Def.AutoSave.origData_[tableName][rowIdx] == null) {
      
      // If any parents of the field specified are missing in the changed
      // data hash, supply them now.    
      if (changedTable[rowNum] == null)
        changedTable[rowNum] = {} ;
      
      // Make sure that this is not a record id specification for a row
      // already flagged as removed (see the update types description in
      // the function description above).      
      if (changedTable[rowNum]['record_id'] != 'Removed')
        changedTable[rowNum][fieldName] = value ;
    }  
    
    // Else process a field for a row that exists in the original data. 
    else {
      
      // If this is a change from the original value, write it to the 
      // changedData_ hash, creating whatever parents are missing.
      var origValue = Def.AutoSave.origData_[tableName][rowIdx][fieldName] ;
      if (typeof origValue == 'object' && origValue != null)
        origValue = origValue[0];

      // make sure to check for the case of a field that starts out null
      // and that is sent from the form with an empty string.  We consider
      // null == "" in that case.
      if ((origValue != value) && !(origValue == null && value == "")) {
        if (changedTable[rowNum] == null)
          changedTable[rowNum] = {} ;
        changedTable[rowNum][fieldName] = value ;
      }
      
      // Else the user is reverting the value back to the original.  Remove
      // the field from the changedData_ hash and any empty parents the 
      // removal creates.  Keep this sparse.     
      else {
        if (changedTable[rowNum] != null) {
          if (changedTable[rowNum][fieldName] != null)
            if (tableName == 'obx_observations')
              var obr_row = Def.AutoSave.origData_[tableName][rowIdx]['_p_id_'] ;
            delete changedTable[rowNum][fieldName] ;
          if ($H(changedTable[rowNum]).keys().length < 1)
            delete changedTable[rowNum] ;
        }
        if ($H(changedTable).keys().length < 1) {
          delete Def.AutoSave.changedData_[tableName] ;
          if (tableName == 'obx_observations')
            delete Def.AutoSave.origData_['obr_orders'][obr_row];
          // IF WE'VE GOTTEN THIS FAR, CHECK FORM NAME.  IF IT'S 
          // OBX, AND WE HAVE NOTHING FOR IT, WE NEED TO TAKE OUT THE
          // OBR ALSO.  RIGHT? -- JUST FROM THE CHANGE HASH
          // link obx _p_id to obr _id_  _p_id_ and _id_ are in
          // orig data.  Use _p_id_ in orig obx to remove change hash obr
        }
      }
    } // end if the field does not/does exist in the original data
    
   //Def.AutoSave.changedData_[tableName] = changedTable ;
  } , // end addUpdate
  
  
  /**
   *  Checks to see if there are pending updates and, if there are, saves
   *  them to the autosave_tmps table.
   */
  checkForUpdates: function() {
    
    if (!Def.DataModel.save_in_progress_ ) {
    
      // if the data_table has been changed
      if (Def.DataModel.pendingAutosave_) {
        Def.DataModel.pendingAutosave_ = false;
        Def.AutoSave.running_ = true;
        new Ajax.Request('/form/auto_save', {
          method: 'post',
          parameters: {
            authenticity_token: window._token,
            profile_id: Def.DataModel.id_shown_ , 
            form_name: Def.DataModel.form_name_ ,
            data_tbl: Object.toJSON(Def.AutoSave.changedData_)
          },
          asynchronous: true,
          onSuccess: function(response) {
            Def.AutoSave.running_ = false ;
            var windowOpener = Def.getWindowOpener();
            if (Def.DataModel.form_name_ == 'panel_edit' && windowOpener)
            windowOpener.Def.DataModel.subFormUnsavedChanges_ = true ;        
          } , 
          onFailure: function(response) {
            Def.AutoSave.running_ = false ;
            var evaled_resp = response.responseText.evalJSON() ;
            if (evaled_resp == 'do_logout')
              window.location = Def.LOGOUT_URL ;
            else {
              var msg = 'The autosave function ran into a problem:<br> ' +
                        Object.toJSON(evaled_resp()) ;
              Def.showError(msg, true) ;        
            }
          }
        });
      } // end if we're saving
    } // end if we're not in the middle of a save
    Def.AutoSave.setTimer() ;
  },  // end checkForUpdates

      
  /**
   * Sets the timer to invoke the checkForUpdates function at the
   * CHECK_AUTOSAVE_TIME interval.  Clears the timeout first if it's
   * not already cleared
   */
  setTimer: function() {

    if (Def.AutoSave.checkTime_ != '')
      window.clearTimeout(Def.AutoSave.checkTime_) ;
    Def.AutoSave.checkTime_ = 
                             window.setTimeout("Def.AutoSave.checkForUpdates()",
                                               this.CHECK_AUTOSAVE_TIME) ;
  } , // end setTimer


  /**
   * Clears the timer if it's not already cleared
   */
  stopTimer: function() {

    if (Def.AutoSave.checkTime_ != '')
      window.clearTimeout(Def.AutoSave.checkTime_) ;

  } , // end stopTimer
  

 /**
   *  Returns true if an autosave needs to be performed.  This seems to
   *  be used only in the acceptance tests - at least right now.  10/14/11 lm
   */
  autoSaveNeeded: function () {
    return !Def.AutoSave.running_ && Def.DataModel.pendingAutosave_ &&
           !Def.DataModel.save_in_progress_ ;
  } 
   
} ; // end Def.AutoSave

