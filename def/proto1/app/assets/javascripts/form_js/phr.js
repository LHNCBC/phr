/**
 * phr.js -> javascript class that contains functions specific to the
 *           phr form
 *
 * Members of this class should be specific to the PHR main form.  For
 * example, the openClinTrialsParamWindow function is specific to the
 * Research Studies button on that form.
 *
 * $Id: phr.js,v 1.12 2011/08/03 18:01:13 plynch Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/form/phr.js,v $
 * $Author: plynch $
 *
 * $Log: phr.js,v $
 * Revision 1.12  2011/08/03 18:01:13  plynch
 * Changes to remove dojo from all but the panel_view and panel_edit pages.
 *
 * Revision 1.11  2010/09/14 23:37:41  taof
 * change field name from age to age_group
 *
 * Revision 1.10  2010/05/27 22:34:48  plynch
 * Removed the event observer on fe_inactive_drugs.  That is now put in place through
 * the control type detail.
 *
 * Revision 1.9  2010/05/27 20:42:03  plynch
 * Added code to hide inactive drug rows after the data loads into the form.
 *
 * Revision 1.8  2009/10/19 21:27:55  plynch
 * Changes to add drug class and ingredient names to the form.
 *
 * Revision 1.7  2009/06/15 19:51:35  lmericle
 * removed obsolete (commented out) code
 *
 * Revision 1.6  2009/06/12 20:09:12  lmericle
 * added reference to studiesWindow_
 *
 * Revision 1.5  2009/06/02 15:26:26  lmericle
 * added ct_search.js; modified phr.js in way ct_search window brought up and parameters passed
 *
 * Revision 1.4  2009/05/13 20:51:30  lmericle
 * commented out some in-progress changes
 *
 * Revision 1.3  2009/04/28 21:33:58  lmericle
 * removed openCtWindow
 *
 * Revision 1.2  2009/04/21 21:13:16  lmericle
 * added methods related to onclick events (not yet invoked)
 *
 * Revision 1.1  2009/04/21 14:59:57  lmericle
 * added
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Bascially,
 * you can use the code as long as you give NLM credit.
 */


Def.PHR = {

  /**
   * Reference to the research studies window popped up when the user
   * presses the Research Studies button.  If the window's NOT open, the
   * reference is null.
   */
  studiesWindow_: null ,

  /**
   *  Opens the ct_search window, which is used to get parameters for a
   *  search of the clinical trials database.  Assumes this is invoked by
   *  an onclick of the Research Studies button (or a button).
   *
   * @return false (return for button)
   */
  openClinTrialsParamWindow: function() {

    // Clear the hidden fields on the PHR form that are used to retain
    // the user's choices on the clinical trials search parameters window.
    // We only hold onto them to be able to redisplay the choices if and
    // when the user returns to the parameters window from the clinical
    // trials window.  When the user invokes the window from the Research
    // Studies button on the main PHR form, we want to be sure there are
    // no old values hanging around.
    Def.setFieldVal($('fe_ctsearch_problem', '')) ;
    Def.setFieldVal($('fe_ctsearch_state', '')) ;
    Def.setFieldVal($('fe_ctsearch_age_code', '')) ;

    // Build the window options, and the url from any applicable values
    // on the PHR form, andn open the window.
     var windowOpts = "width=900,height=600,resizable=yes,scrollbars=yes," +
                     "toolbar=yes,location=yes" ;
    try {
      try {
        var ageParam = Def.Rules.Cache.getRuleVal('ct_age_code') ;
      }
      catch(e) {
        if (e.message == 'No cached value for rule ct_age_code')
          ageParam = '' ;
      }
      var probList = Def.getFieldValsAndCodes('problem') ;
//      var nwUrl = '/profiles/'+Def.DataModel.id_shown_+'/research_studies?age_group_c=' + ageParam.toString() +
//                  "&probItems=" + encodeURIComponent(probList[0].join("+")) +
//                  "&probCodes=" + probList[1].join(",") ;
      var nwUrl = '/profiles/'+Def.DataModel.id_shown_+'/ct_search?age_group_c=' + ageParam.toString() +
                  "&probItems=" + encodeURIComponent(probList[0].join("+")) +
                  "&probCodes=" + probList[1].join(",") ;

      // hold onto window object for testing
      Def.PHR.studiesWindow_ =
                          openPopup(this, nwUrl, null, windowOpts, null, true) ;
    }
    catch(e) {
      Def.Logger.logMessage([e]) ;
    }
    return false;
  }, // end openClinTrialsParamWindow


  /**
   *  Called after the data has loaded to hide the inactive drug
   *  rows.  (Perhaps one day soon it will hide inactive condition rows too.)
   */
  setInactiveDataRowVisibility: function() {
    var drugInactiveVis = $('fe_inactive_drugs').checked;
    if (drugInactiveVis)
      Def.FieldsTable.setTableRowVisibility('phr_drugs', true, null); //show all
    else {
      Def.FieldsTable.setTableRowVisibility('phr_drugs', false,
       {'drug_use_status_C': 'DRG-I'}); // hides matching rows
    }

    this.setStripeCssClass();
  },


  /**
   * Set a class for CSS settings of stripes on the Drugs table
   */
  setStripeCssClass: function() {
    var drugTable= $('fe_drugs_0_tbl');
    var visibleRows = drugTable.select('tr.saved_row.show_me');
    for (var i=0, ilen=visibleRows.length; i<ilen; i++) {
      if (i % 2 == 0) {
        visibleRows[i].removeClassName('odd_row');
        visibleRows[i].addClassName('even_row');
      }
      else {
        visibleRows[i].removeClassName('even_row');
        visibleRows[i].addClassName('odd_row');
      }
    }
  },


  /**
   * Get the total numbers of the unopened health reminders and unhidden
   * due date reminders
   */
  setDueDateReminderCount: function() {

    // make an ajax call
    new Ajax.Request('/form/get_reminder_count', {
      method: 'get',
      parameters: {
        authenticity_token: window._token,
        p_id: Def.DataModel.id_shown_
      },
      onSuccess: function(t) {
        try {
          // the 1st one is health reminders number, and the 2nd is due date
          // the process of the health reminders is done on client side for now.
          var msg_numbers = eval('(' + t.responseText + ')');
          // find the two reminder buttons and attach a div after each button
          var date_reminder_button = $('fe_date_reminder_1_1');
          var date_reminder_num = msg_numbers[1];
          Def.updateMessageCount(date_reminder_button, date_reminder_num);
        } // end of try
        catch (e) {
          Def.Logger.logException(e);
        }
      },
      asynchronous: true
    });

  },


  /**
   * Get the latest reviewed status of health reminders from server
   * and update the related variable on client side. Also refresh the
   * display of the count of unreviewed reminders
   **/
  updateHealthReminderReviewStatus: function(){
    var url = "/form/get_reviewed_reminders";
    new Ajax.Request(url, {
      method: 'get',
      parameters: {
        authenticity_token: window._token,
        profile_id: Def.DataModel.id_shown_
      },
      onSuccess: successAction,
      onFailure: failureAction,
      asynch: false
    });


    // update reviewed status
    function successAction(response){
      var anchor = $(Def.reminderButtonID_);
      var mm = anchor.messageManager;
      mm.reviewedMessageKeys_ = eval('(' + response.responseText + ')');
      // verify the review status records in case of user data was updated not
      // through PHR form
      // update the unreviewed reminder number display on PHR form
      mm.updateReviewedMessageInfo();
      mm.refreshNumberOfUnreviewedMessages();
    }

    // show error msg when failed to get the reviewed reminders from server
    function failureAction(){
      Def.showError("We were unable to retrieve the list of previously viewed "+
        "Health Reminders.  You may still view your Health Reminders, but"+
        " we will not be able to indicate which ones you've already read.");
    }
  }

}; // end Def.PHR


/**
 *  Handles the print button.
 */
Def.print = function() {
  // Build the print instruction dialog if it hasn't already been built.
  if (!this.printDialog_) {
    this.printDialog_ = new Def.ModalPopupDialog({
        width: 500, stack: true,
        buttons: [{
          text: "Print" ,
          class: "rounded",
          click: function() {
            this.printDialog_.hide();
            window.print();
          }.bind(this)}, {
          text: "Cancel",
          class: "rounded" ,
          click: function() {
            this.printDialog_.hide();
          }.bind(this)}]
        });

    // The title and text of the dialog are on the page as
    // hidden static text fields.
    var titleField = $('fe_phr_print_dialog_title');
    if (titleField)
      var titleText = titleField.textContent;
    if (!titleText) // should always be present, but....
      titleText = 'Print Help';
    this.printDialog_.setTitle(titleText);
    var messageField = $('fe_phr_print_dialog_text');
    if (messageField) {
      this.printDialog_.setContent(
        '<div id="confirmDeleteText" style="margin-bottom: 1em">' +
        messageField.textContent + '</div>');
    }
  } // end if the dialog has not already been built

  this.printDialog_.show();
};



// Set up a call to hideInactiveDataRows after the data has been loaded.
jQuery.connect(Def.DataModel, 'setup', Def.PHR, 'setInactiveDataRowVisibility');
// set classes for stripes on tests - if they're on the form
if (Def.accessLevel_ < Def.READ_ONLY_ACCESS) {
  jQuery.connect(Def.DataModel, 'setup', TestPanel, 'setStripeCssClass');
  // Add a left-click helper on the panel container element
  jQuery.connect(Def.DataModel, 'setup', TestPanel,'addLeftClickHelper');
}
// get the total numbers of the unopened/unhidden reminder messages
jQuery.connect(Def.DataModel, 'setup', Def.PHR,'setDueDateReminderCount');
// extend the message manger object on the health reminder button
jQuery.connect(window, 'onload', Def.PHR, 'updateHealthReminderReviewStatus');
// Update the drug warning icon state after the data has loaded
jQuery.connect(window, 'onload', $('fe_drugs_0').ce_table.conflictChecker_,
  'findAllDrugConflicts');

/**
 *  Handles clicks on the drug warning icon.  This is here because
 *  it needs to call $('fe_drugs_0'), but the fields_table code
 *  changes the suffix on each row.
 * @param iconID the ID of DOM element of the icon
 */
Def.drugWarningIconClicked = function(iconID) {
  $('fe_drugs_0').ce_table.conflictChecker_.drugWarningIconClicked(iconID);
};

/**
 * The ID of the health reminder button
 **/
Def.reminderButtonID_ = "fe_reminders_1_1";


/* Initialization for the saved panel section */
// Get the ID from the page URL
var loc = (new RegExp(/profiles\/(.*);edit/)).exec(document.location.pathname)[1];
$J('#saved_panels').dataTable({"bJQueryUI": true, "bProcessing": true,
  "sAjaxSource": '/phr_records/'+loc+'/phr_panels.json',
  "aoColumnDefs": [
      { "sType": "date", "aTargets": [ 0 ] }
    ]});
// Originally, I used the following code to get the id_shown from the data
// model.  However, if you wait until the data model is set up, the navigation
// code also runs, and then gets confused by the JQuery DataTables addition
// of two new input fields on the form.
/*$J(document).ready(function() {
  // Wait for the data model to be loaded (for id_shown_)
  var setup = function() {
    if (Def.DataModel.id_shown_) {
      $J('#saved_panels').dataTable({"bJQueryUI": true, "bProcessing": true,
        "sAjaxSource": '/phr_records/'+Def.DataModel.id_shown_+'/phr_panels.json'});
    }
    else
      setTimeout(setup, 50);
  };
  setup();
} );*/
