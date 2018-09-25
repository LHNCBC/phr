/* 
 * Javascripts related to the Due Date Reminders
 */
Def.DateReminders = {
  /**
   * function to open a date reminder window, called by the due dates button on
   * PHR form
   *
   */
  openDateReminderWindow: function(id_shown) {
    if (id_shown === undefined || id_shown === null)
      id_shown = Def.DataModel.id_shown_;

    var strURL = "/profiles/" + id_shown + "/reminders"
    var winProp = "menubar=yes,location=no,resizable=yes,scrollbars=yes," +
                  "status=no,width=800,height=600";
    var popup = openPopup(null, strURL, null, winProp, 'date_reminder', true);
  },


  /**
   * function to open a window to show and/or change cutoff days for each 
   * category
   *
   */
  openCutoffDaysWindow: function() {
    var id_shown = Def.DataModel.id_shown_;

    var strURL = "/profiles/" + id_shown + "/reminder_options"
    var winProp = "menubar=yes,location=no,resizable=yes,scrollbars=yes," +
                  "status=no,width=640,height=480";
    var popup = openPopup(null, strURL, null, winProp, 'reminder_cutoff', true);
  },


  /**
   * show previous hidden reminder record
   *
   */
  showHiddenReminders: function() {
    var table = $('fe_date_reminders_0_tbl');
    var eleTRs = table.select('tr.repeatingLine');
    var showall = $('fe_rmd_show').checked;
    for(var i=1, len = eleTRs.length; i< len; i++) {
      // if it is not the last empty row
      if (!eleTRs[i].hasClassName('last_empty_row')) {
        // show all
        if (showall) {
          eleTRs[i].style.display = '';
        }
        // hide the hidden rows
        else {
          var eleHide = eleTRs[i].select('input[type="checkbox"]')[0];
          if (eleHide.checked) {
            eleTRs[i].style.display = 'none';
          }
        }
      }
    }    
    // add stripes
    this.setStripeCssClass();
  },


  /**
   * update a reminder record to make it hidden or unhidden
   *
   * @param ele - a checkbox HTML element
   *
   */
  updateAReminder: function(ele) {
    var to_hide = ele.checked;
    var showall = $('fe_rmd_show').checked;
    var eleTR = ele.parentNode.parentNode;
    var hmv_value = 0;
    // it was shown, (changed to hide)
    if (to_hide) {
      hmv_value = 1;
      // if 'show all' is not checked,
      if (!showall) {
        // hide this row
        eleTR.style.display = 'none';
      }
    }

    // update the hide_me field in taffy db
    // by updating the 'hide_me_value' form field ('fe_hide_me_value_1')
    var ids = Def.IDCache.splitFullFieldID(ele.id);
    var hmv_id = ids[0] + 'hide_me_value' + ids[2];
    Def.setFieldVal($(hmv_id), hmv_value);

    // create a simple updated data_table
    var location =Def.DataModel.getModelLocation(hmv_id);
    var record = Def.DataModel.getModelRecord(location[0],location[2]);
    var data_table = {};
    data_table[location[0]] = [record];

    // $('content').style.cursor = 'wait';
    
    // update db
    // make an ajax call to update the date_reminders table
    new Ajax.Request('/form/update_a_reminder', {
      method: 'post',
      parameters: {
        data_table: Object.toJSON(data_table),
        authenticity_token: window._token,
        profile_id: Def.DataModel.id_shown_,
        form_name: Def.DataModel.form_name_
      },
      onSuccess: function(t) {
        //var htmlText = response.responseText;
        //$('content').style.cursor = 'auto';
      },
      onFailure: function(t) {
        // set the cursor to auto
        //$('content').style.cursor = 'auto';
        alert('Error ' + t.status + ' -- ' + t.statusText);
      },
      on404: function(t) {
        // set the cursor to auto
        //$('content').style.cursor = 'auto';
        alert('Error:   reminder not found!');
      },
      asynchronous: true
    });
  },


  /**
   * Customize the appearance of the Reminders tabel once the page is loaded
   * 1) hide the empty row at the bottom
   * 2) hide the hidden rows
   * 3) add class for "past due" reminders
   *
   */
  customizeReminderTable: function() {
    // Find the last row and delete it - IF this is being displayed for
    // read-only access.  The last empty rows are not generated for read-only
    // access (or else they're deleted before we get here).
    if (Def.formEditability_ !== Def.FORM_READ_ONLY_EDITABILITY) {
      var table = $('fe_date_reminders_0_tbl');
      var lastRow = table.rows[table.rows.length-1];
      // hide it
      lastRow.style.display = 'none';
      // add an identifier class
      lastRow.addClassName('last_empty_row');
    }
    // Else the user has read-only access to the phr. Hide the
    // group header instructions about the hide box and set a style
    // for the access_notice div
    else {
      $('fe_date_reminders_ins_0').addClassName('hidden_field');
      $('fe_access_notice_1').parentNode.setStyle({clear: 'none'}) ;
    }
    var records = Def.DataModel.data_table_['date_reminders'];
    if (records !== undefined) {
      for (var i=0, len = records.length; i<len; i++ ) {
        // hide previous hidden rows
        if (records[i]['hide_me']==1) {
          var formEle = Def.DataModel.getFormField('date_reminders','hide_me',i+1);
          var trEle = formEle.parentNode.parentNode;
          var ids = Def.IDCache.splitFullFieldID(formEle.id);
          // get the check box element, set the checked flag
          var checkbox_id = ids[0] + 'hide_me' + ids[2];
          $(checkbox_id).checked = true;
          // hide the row
          trEle.style.display = 'none';
        }
        if (records[i]['reminder_status'].match(/past due$/)) {
          formEle = Def.DataModel.getFormField('date_reminders','reminder_status',i+1);
          tdEle = formEle.parentNode;
          tdEle.addClassName('past_due');
        }
      }
    }
    
    // set the stripes
    this.setStripeCssClass();
  },


  /**
   * hide the last empty row in the option table
   *
   */
  hideTheLastRow: function() {
    // find the last row
    var table = $('fe_reminder_options_0_tbl');
    var lastRow = table.rows[table.rows.length-1];
    lastRow.style.display = 'none';
  },

  /** 
   * Set a class for CSS settings of stripes on the Drugs table
   */
  setStripeCssClass: function() {
    var reminderTable= $('fe_date_reminders_0_tbl');
    var allRows = reminderTable.select('tr.repeatingLine');
    var sn = 0;
    for (var i=0, ilen=allRows.length; i<ilen; i++) {
      if (allRows[i].style.display == '') {
        sn++;
        if (sn % 2 == 0) {
          allRows[i].removeClassName('odd_row');        
          allRows[i].addClassName('even_row');
        }
        else {
          allRows[i].removeClassName('even_row');        
          allRows[i].addClassName('odd_row');
        }
      }
    }
  }

}

