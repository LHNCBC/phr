/**
 * fields_table.js -> javascript functions to handle fields table processing
 *                    on the client side
 *
 * The functions in this file handle client-side changes to horizontal
 * tables of fields.  Specifically, they handle the insertion and deletion
 * of lines in a table.
 *
 * Note that a "line" in a field table may actually consist of multiple
 * rows - a main row and any number of embedded rows.  Table operations
 * must therefore operate on a line as a whole, with all of its embedded
 * rows, if any.
 *
 * $Id: fields_table.js,v 1.82 2011/04/12 16:06:52 lmericle Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/fields_table.js,v $
 * $Author: lmericle $
 *
 * $Log: fields_table.js,v $
 * Revision 1.82  2011/04/12 16:06:52  lmericle
 * removed old Def.Logger calls
 *
 * Revision 1.81  2011/02/15 17:37:08  lmericle
 * added documentation for missing return
 *
 * Revision 1.80  2010/11/30 20:28:15  plynch
 * The resize table field method no longer repositions the field's list
 * if the keystroke was an arrow key (used to navigate in the list).
 *
 * Revision 1.79  2010/10/12 20:09:53  plynch
 * The field resizing code now repositions the list if needed.
 *
 * Revision 1.78  2010/08/27 22:14:16  plynch
 * Made more fields wrapping fields, changed the alignment of the wrapping fields in the row, and fixed a bug in navigation.js.
 *
 * Revision 1.77  2010/08/26 22:23:11  wangye
 * check if panel group exists
 *
 * Revision 1.76  2010/08/26 19:12:13  plynch
 * Changes to allow text fields to wrap, plus a couple of method renamings.
 *
 * Revision 1.75  2010/06/18 20:37:21  plynch
 * Renamed methods in data_model.js to remove Taffy from its API.
 *
 * Revision 1.74  2010/06/01 17:20:06  lmericle
 * added code to insert row id number; removed obsolete logging messages
 *
 * Revision 1.73  2010/05/27 20:40:29  plynch
 * controlled_edit_table.js & data_model.js:  no significant change
 * Added functions for setting the visibility of table rows (and revised hide_row
 * in rules.js to use one of the new functions).
 *
 * Revision 1.72  2010/05/21 14:00:59  mujusu
 * rtemoved toggleTooltip
 *
 * Revision 1.71  2010/04/27 18:00:33  plynch
 * Fixed a problem (from an earlier fix).  Now when a row is added, only
 * the fields in the new row are assigned new field observers.
 * Also re-fixed the earlier problem with the More button not
 * working for the second new panel.
 *
 * Revision 1.70  2010/03/25 16:15:19  wangye
 * bug fix on test panel that js function of buttons and date fields do not work on newly added test panels
 *
 * Revision 1.69  2010/03/12 17:17:46  lmericle
 * removed autoNumberOrLabel
 *
 * Revision 1.68  2010/03/12 15:45:07  abangalore
 * *** empty log message ***
 *
 * Revision 1.67  2010/02/12 18:25:34  taof
 * add autocompleter to label/order fields in new reminder/value forms
 *
 * Revision 1.66  2010/01/15 21:26:58  mujusu
 * updated calendar id
 *
 * Revision 1.65  2009/11/23 19:43:09  abangalore
 * Modified files to support IE8 and IE7. Currently the site only works on IE8 and not on IE7 or lower versions.
 *
 * Revision 1.64  2009/11/02 20:46:41  plynch
 * missing var statement
 *
 * Revision 1.63  2009/09/10 18:24:32  plynch
 * Moved the calendar initialization code out of the page and into the
 * form-specific generated JS file.
 *
 * Revision 1.62  2009/08/26 23:06:24  plynch
 * Modified fields_table.js to to handle the set up of combo fields.
 * (In combo_fields.js, I moved some constants to make the exist only on the
 * class, rather than on each instance.)
 *
 * Revision 1.61  2009/07/14 19:49:40  wangye
 * update for taffydb/data model
 *
 * Revision 1.60  2009/06/11 15:24:37  lmericle
 * fixed conditions in skipBlankLine and repeatingLine to use Def.getFieldVal instead of field.value (which doesn't handle tooltips correctly)
 *
 * Revision 1.59  2009/05/29 17:26:50  lmericle
 * fixed problem in skipBlankLine where blank fields were not recognized (tooltip thing)
 *
 * Revision 1.58  2009/05/18 16:35:43  mujusu
 * now tooltip is a value. should be treated as blank
 *
 * Revision 1.57  2009/05/15 23:27:02  lmericle
 * replaced check for rules using class with check using Def.Rules.hasRules
 *
 * Revision 1.56  2009/04/22 22:34:21  plynch
 * Fixes for the controlled edit table to initialize listeners on fields for
 * rows that are made editable.
 *
 * Revision 1.55  2009/04/03 22:16:09  plynch
 * Edit and Cancel edit work for controlled edit tables.
 *
 * Revision 1.54  2009/04/02 17:49:46  plynch
 * More changes for the controlled edit table.  The edit command now partially works.
 *
 * Revision 1.53  2009/03/30 21:07:39  plynch
 * Changes to disable saved rows (part of controlled edit table changes.)
 *
 * Revision 1.52  2009/03/26 18:46:40  taof
 * Remove @data_hash from page, using Ajax request to load @data_hash dynamically
 *
 * Revision 1.51  2009/03/24 20:31:13  plynch
 * Changes to start using templates for the generation of repeating line tables.
 *
 * Revision 1.50  2009/03/20 13:38:20  lmericle
 * changes related to conversion of navigation.js functions to Def.Navigation class object
 *
 * Revision 1.49  2009/03/19 20:50:22  plynch
 * Changes for the beginning of the controlled edit table.
 *
 * Revision 1.48  2009/03/16 23:00:32  plynch
 * Gave the fields table stuff a namespace.
 *
 * Revision 1.47  2009/03/06 21:15:49  lmericle
 * implemented navSeqsHash to speed up navigation loading; changes related to that
 *
 * Revision 1.46  2009/02/24 19:28:51  taof
 * validation.js refactoring to meet user stories
 *
 * Revision 1.45  2009/02/18 18:01:27  lmericle
 * modified way building rows to improve performance
 *
 * Revision 1.44  2009/02/12 23:33:27  lmericle
 * changes to speed up addTableLine.  Not done yet
 *
 * Revision 1.43  2009/01/30 22:30:36  wangye
 * bug fixes for new test panels
 *
 * Revision 1.42  2009/01/21 20:22:29  taof
 * Bugfix: js function hasClassName was wrongly overwritten
 *
 * Revision 1.41  2009/01/15 18:09:27  taof
 * required field validation: 1) replace onblur event with onchange; 2) replace console.log with our Def.Logger; 3) fixbug: validation handler shouldnot be registered to the newly added repeating line which has no required field in it
 *
 * Revision 1.40  2009/01/14 22:03:32  taof
 * after click submit button, user should be able to dynamically update error msgs
 *
 * Revision 1.39  2008/11/19 20:55:20  lmericle
 * updates to fix problems with integrating new lines into navigation flow
 *
 * Revision 1.38  2008/11/18 18:00:31  lmericle
 * modified calls to update navigation when new line is added to use updated navigation scheme
 *
 * Revision 1.37  2008/11/13 21:24:47  lmericle
 * fixed bug in figuring when have hit maxRows in a table, per Sumeet.  (Thanks Sumeet!)
 *
 * Revision 1.36  2008/10/29 21:03:22  lmericle
 * fixed code appending new lines; was inadvertently changed to the wrong object
 *
 * Revision 1.35  2008/10/24 21:34:31  wangye
 * bug fixes for IE7 and performance tune-up
 *
 * Revision 1.34  2008/10/23 19:25:09  lmericle
 * Various changes to try to speed up addTableLine
 *
 * Revision 1.33  2008/10/16 20:42:19  lmericle
 * grouped tasks that run through row elements into processRowElements function; other tweaks
 *
 * Revision 1.32  2008/10/09 19:53:55  lmericle
 * removed obsolete functions
 *
 * Revision 1.31  2008/10/07 14:56:41  plynch
 * Changes for clearing data_req_output fields if the value doesn't match the list.
 *
 * Revision 1.30  2008/09/04 18:04:28  lmericle
 * commented out lines referencing obsolete dependencies code
 *
 * Revision 1.29  2008/08/12 20:41:40  plynch
 * Fixed a bug in skipBlankLine.
 *
 * Revision 1.28  2008/08/04 23:49:46  plynch
 * fields_table.js - corrected some bugs in skipBlankLine
 * navigation.js - fixed a bug in moveToNextFormElem
 * (related to task 707)
 *
 * Revision 1.27  2008/07/18 20:53:55  yango
 * modify the max_responses feature when the value is not 1 or 0
 *
 * Revision 1.26  2008/07/16 14:56:50  smuju
 * initialize only the new row for tooltip
 *
 * Revision 1.25  2008/07/01 22:05:47  smuju
 * fixed repeatline to copy calendar setup script for all cal buttons to work
 *
 * Revision 1.24  2008/05/22 21:54:28  plynch
 * Changes to allow the prefetched lists to show up when getting focus even
 * when there is a value already in the list.
 *
 * Revision 1.23  2008/05/21 21:27:10  wangye
 * rename lgEditBox to LargeEditBox
 *
 * Revision 1.22  2008/05/01 14:49:52  lmericle
 * updates to set up nav keys and run rules once after all data loaded
 *
 * Revision 1.21  2008/04/24 19:45:23  plynch
 * Added a cache of base ID strings to actual field IDs, to speed up
 * the run time of the rules.
 *
 * Revision 1.20  2008/04/23 18:56:51  plynch
 * Merge of changes from Caroline Wright's work to create the FillInBlanks
 * autocompleter.
 *
 * Revision 1.19  2008/04/23 16:01:02  lmericle
 * added code to run rules after line(s) added to horizontal table
 *
 * Revision 1.18  2008/03/28 16:13:39  lmericle
 * fixes for editable and default values
 *
 * Revision 1.17  2008/03/10 18:24:43  wangye
 * set up listener for large edit box when adding a new line
 *
 * Revision 1.16  2008/03/05 21:17:37  lmericle
 * fields_table.js - type
 * rules.js - fixed hide code to correctly hide fields that are not displayed within a horizontal table.
 *
 * Revision 1.15  2008/03/05 16:50:38  smuju
 * bug fix
 *
 * Revision 1.14  2008/03/04 21:18:32  smuju
 * added className variable as .contructor not returning name after prototype update
 *
 * Revision 1.13  2008/02/28 14:57:30  lmericle
 * changes to move from first field of last blank line in a horizontal table to next accessible field outside the table
 *
 * Revision 1.12  2008/02/13 01:07:13  perryka
 * fix prefetch duplicator
 *
 * Revision 1.11  2008/02/07 19:30:52  lmericle
 * fix bug in autocompleter fix
 *
 * Revision 1.10  2008/02/07 16:53:26  lmericle
 * fixed autocompleter generation code to account for all current types of autocompleters (and streamlined)
 *
 * Revision 1.9  2008/01/24 22:33:49  smuju
 * reinint tip
 *
 * Revision 1.8  2008/01/23 19:27:42  plynch
 * initial changes to add "rules".
 *
 * Revision 1.7  2008/01/23 00:26:54  smuju
 * fixed repeatline for calendar field
 *
 * Revision 1.6  2008/01/15 20:54:16  lmericle
 * changes for data loading
 *
 * Revision 1.5  2008/01/09 23:09:06  lmericle
 * typo
 *
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Bascially,
 * you can use the code as long as you give NLM credit.
 */

Def.FieldsTable = {
  /**
   *  This function is called to handle the insertion of a line in
   *  a table.  The line added is copied from the model line(s) in the
   *  table, and added immediately after the line indicated by the
   *  rowid input parameter.
   *
   *  Fields in the inserted line may be set to be inaccessible (disabled
   *  set to true; visibility set to hidden).  Any fields that should NOT
   *  be made inaccessible are named in the accessible_fields input
   *  parameter.  This feature is used when adding condition lines for
   *  a single expression, where only some of the fields in the line are
   *  actually used for the second and subsequent conditions listed.
   *
   * @param tableField an existing field in the table that is used to
   *                   find the table
   * @param rowid the id of the line that the new line is to immediately
   *              follow in the table
   * @param accessible_fields fields on the line to be added that should
   *                          remain accessible after the addition.  Any
   *                          fields not in the list will be set to disabled
   *                          and the visibility set to hidden
   *
   * @returns the number used to create the unique id for the new row and
   *          its fields
   */
  insertLine: function(tableField, rowid, accessible_fields) {

    // Get the table that the tableField lives in
    var row = tableField.parentNode;
    while (row.className == undefined || row.className != 'repeatingLine')
      row = row.parentNode;
    var table = row.parentNode;

    // invoke addTableLine to actually insert the line in the table
    var row_num = this.addTableLine(table, rowid) ;
    var row_suffix = row_num.toString() ;

    // set any fields not in the accessible_fields array to be disabled
    // and the actual input field hidden.

    var new_row = this.find_row_by_id(table, row_num) ;
    for (var i=0, il=new_row.cells.length; i < il; i++) {
      var next_field = this.inputElement(new_row.cells[i]) ;
      var next_id = next_field.id ;
      var is_accessible = false ;
      for (var a = 0, al=accessible_fields.length;
        a < al && is_accessible == false; a++) {
        is_accessible = (next_id == accessible_fields[a] + row_suffix) ;
      }
      if (is_accessible == false) {
        next_field.disabled = true ;
        next_field.style.visibility = "hidden";
      }
    }
    return row_num ;

  }, // insertLine


  /**
   *  This function works its way through the rows of a table and
   *  obtains the first one with the specified rowid.  Note that rowids
   *  are not necessarily in sequential order, and also that more than
   *  one row may have the same id - when a group of rows make up one
   *  "line".
   *
   *  Because this function is entirely internal - i.e., not influenced
   *  by user inputs, if the row is not found, a javascript alert is
   *  displayed.  We may or may not want to look at changing this later,
   *  but for now it signals a development error.  11/29/07  lm
   *
   * @param table the table in which to search for the row
   * @param rowid the id of the line to be found
   *
   * @returns the first row in the table with the specified row id
   */
  find_row_by_id: function(table, rowid) {

    var ret_row = null ;

    for (var r = 0, rl = table.rows.length; (r < rl && ret_row == null); r++) {
      if (table.rows[r].getAttribute('rowid') == rowid) {
        ret_row = table.rows[r] ;
      }
    }
    if (ret_row == null) {
      alert("something's off - can't find row to add after") ;
    }
    return ret_row ;
  },


  /**
   *  This gets called when focus leaves a field that is part of a
   *  repeating line of fields.&nbsp; It causes a line to be added at the
   *  end of the table.&nbsp; Field attributes of the model line in the
   *  table are duplicated in the line added, including onblur event handlers
   *  and autocompleters, as appropriate.
   *
   *  The line is not added if a maximum repeat number is passed in and the
   *  table has reached that number of lines.
   *
   * @param field a reference to the HTML field from which the onblur event
   *              occurred.
   * @param repNum the maximum number of times the field may be repeated, if
   *               specified.  0 = infinite
   */
  repeatingLine: function(field, repNum) {
    // Check to see if the content of this field is empty.  The user might
    // have entered the field and typed a backspace, or (maybe) a tab or
    // return.  We don't add a row if the last one's blank.
    var fieldVal = Def.getFieldVal(field) ;
    if (fieldVal != null && fieldVal != '') {

      // Find this field's repeatingLine row element (class=repeatingLine)
      //   and the table that it's in.
      var row = field.parentNode;
      while (!row.hasClassName('repeatingLine')) {
        row = row.parentNode;
      }

      var table = row.parentNode;
      while (table.tagName != 'TABLE')
        table = table.parentNode ;

      // if there are no more repeating lines in the table, we can add one.
      // Well - maybe.  Gotta check to see if there's a limit on the number
      // of lines we can add.  If maxRows = 0, there's no limit.  If only
      // one row is allowed, the code to call this doesn't get attached to
      // the fields in the row, so we don't have to worry about it.  We
      // just need to check if maxRows is > 1.
      if (this.inLastTableRow(table, row)) {

        var maxRows = parseInt(repNum) ;
        var mayAdd = maxRows == 0 ;
        if (mayAdd != true) {
          var curReptLines = 0 ;
          var totRows = table.rows.length ;
          // start checking after the header and model rows
          for (var r = 2; r < totRows; ++r) {
            if (table.rows[r].hasClassName('repeatingLine'))
              curReptLines++ ;
          }
          mayAdd = curReptLines < maxRows ;
        }
        if (mayAdd){
          // update the taffydb first
          Def.DataModel.updateMappingAndDB(field, table);
          // add the a new line
          this.addTableLine(table);
        }
      } // end if we're in the last row
    } // if the field's not empty

  }, // end function repeatingLine


  /**
   *  This is called to skip over (if appropriate) the blank line at the end of
   *  table when tabbing through fields.  The blank line is skipped if the focus
   *  is in the first visible field and if none of the visible fields have
   *  values.
   * @param field the current field (e.g. the field with focus)
   * @return true if the focus was moved.
   */
  skipBlankLine: function(field) {
    var moved = false ;

    // if the field's not blank, neither is the row/line
    var fieldVal = Def.getFieldVal(field) ;
    if (Def.Navigation.inTable(field) &&
        (fieldVal == null || fieldVal == '')) {

      // Only proceed if this is in the last row of the table
      // Note:  We could use field.up('tr.repeatingLine'), instead of the
      // loop below, but that takes 10ms longer.
      var row = field;
      while (row.nodeType == Node.ELEMENT_NODE && // stop at document node
             row.tagName != 'TR' &&
             !row.hasClassName('repeatingLine')) {
        row = row.parentNode;
      }
      var table = row;

      while (table.tagName != 'TABLE') {
        table = table.parentNode ;
      }

      // If the table is a dateField table, set the row to the row
      // containing it (the first parent will be the cell (TD) and the
      // next parent will be the row) and set the table to the one
      // that contains the row.
      if (table.hasClassName('dateField')) {
        row = table.parentNode.parentNode ;
        table = table.up('table') ;
      }

      if (row.nodeType == Node.ELEMENT_NODE &&
          this.inLastTableRow(table, row)) {

        // only proceed if we're in the first visible input node of the row
        var inputs = row.select('input', 'textarea') ;
        var r = 0 ;
        var firstVisible = false ;
        for (var rl= inputs.length; r < rl && !firstVisible; ++r) {
          firstVisible = !inputs[r].hasClassName("hidden_field");
        }
        if (firstVisible)
          firstVisible = (inputs[r-1].id == field.id) ;

        // only skip the line if all non-hidden input fields are empty
        if (firstVisible) {
          var isEmpty = true ;
          for (rl=inputs.length; r < rl && isEmpty; ++r) {
            if ("textcheckboxradio".indexOf(inputs[r].type) > -1 &&
                !inputs[r].hasClassName("hidden_field"))
              isEmpty = (inputs[r].value == null || inputs[r].value == '' ||
                         inputs[r].value == inputs[r].tipValue) ;
          }
          if (isEmpty) {
            Def.Navigation.moveBeyondTable(row) ;
            moved = true ;
          }
        } // end if we're in the first visible input field
      } // end if we're in the last row of the table
    } // end if the field is blank
    return moved ;

  }, // end skipBlankLine


  /** This function checks to see whether or not there are any
   *  rows in the table with same class name as the row passed
   *  in.  The assumption is that the row passed in has a classname
   *  of "repeatingLine" and that, if it's the last row, the only
   *  rows that may follow it (at its level) are embedded rows
   *  (i.e., not "repeatingLine" rows).
   *
   * @param table the table containing the row to check
   * @param row the row to check
   * @returns boolean indicating whether or not the row is the
   *          last of its class in the table at its level
   */
  inLastTableRow: function(table, row) {

    // See if there are any lines following this one which are not embedded
    // rows.  If so, we're not on the last line of the
    // table.  (Embedded rows are considered part of the line in
    // which they're embedded).

    // skip test if it is in a Loinc Test Panel
    var group = table.up('.fieldGroup');
    if (group && group.hasClassName('panelTest')) {
      return false;
    } //end of Loinc Test Panel skip

    var totRows = table.rows.length ;
    var inLast = true ;
    for (var r = row.rowIndex + 1; r < totRows && inLast; ++r)
      inLast = checkClassName(table.rows[r], 'embeddedRow');

    return inLast ;
  }, // end inLastTableRow


  /**
   *  This function will add a line to a table immediately following a
   *  specified line.  If no "add_after" line is specified, the
   *  line is added at the end of the table.
   *
   *  Field attributes are copied from the model row(s) in the table,
   *  including onblur event handlers and autocompleters.
   *
   * @param table the table that is to receive the new line
   * @param addAfter (optional) the rowid of the line that the new line should
   *                  immediately follow.&nbps;  If the line is to be added as
   *                  the first non-header line in the table, this should be
   *                  specified as 0.&nbsp; If not specified the line is
   *                  appended to the end of the table.
   * @param numToAdd (optional) the number of lines to be added.  Default is 1.
   * @param loading  (optional) a flag indicating whether or not we are calling
   *                 this from the data loading process.  If so, we omit certain
   *                 field setting operations (setting up navigation, event
   *                 handlers, etc), assuming those will be taken care of after
   *                 all the data is loaded.   Default is false.
   *
   * @returns nothing
   */
  addTableLine: function(table, addAfter, numToAdd, loading) {
    if (numToAdd == null)
      numToAdd = 1 ;
    if (loading == null)
      loading = false ;

    // Find the non-header/model lines in the table.  There should
    // be one repeating line row and 0 or more embedded rows, all
    // with rowid = 0.
    var modelRows = this.findModelRows(table);

    // Make sure we have both the table and the tbody objects, and get
    // the next rowid from the table.  Use the next available number for
    // the id - which does not necessarily indicate display order,
    // just the order in which the rows were created.  It's just a
    // way to have a unique id for each row and field within it.
    //interim = new Date().getTime() ;
    var tbody = table ;
    if (table.tagName == 'TBODY') {
      table = table.parentNode ;
    }
    else {
      tbody = table.down('tbody') ;
    }
    var nextId = parseInt(table.getAttribute('nextid')) ;
    table.setAttribute('nextid', (nextId + numToAdd).toString()) ;

    var allAdded = this.createRowSets(modelRows, numToAdd, nextId);
    var totAdded = allAdded.length;

    // Now figure out where the row(s) should be inserted and do that
    // They need to be inserted into the form before we run some of
    // the functions invoked by processRowElements
    //interim = new Date().getTime() ;
    var after_num = 0 ;
    if (addAfter == null) {
      after_num = table.rows.length ;
    }
    else {
      var rl = table.rows.length ;
      for (var r = 0; r < rl; ++r) {
        if (table.rows[r].getAttribute('rowid') == addAfter) {
          while ((r < rl ) &&
                 (table.rows[r].getAttribute('rowid') == addAfter)) {
            r += 1 ;
          }
          after_num = r ;
          r = rl ;
        } // end if we are/aren't at the end of the table
      } // end if we've found the row with an id that matches add_after
    } // end do for the table rows

    // Hold onto the row that we're adding after.  We'll need it when
    // we insert the new row(s) into the navigation (if we do that here).
    var prevRow = table.rows[after_num - 1] ;

    // Append or insert the rows to the tbody, which is actually the
    // immediate parent of the rows.  If we append or insert them
    // to the table itself, they don't get in the rows array, which
    // basically messes up everything.
    // I would have used the table.insertRow method, but that only
    // inserts an empty row, which you then have to use insertCell
    // to fill - can't just assign the new row to it.  :<
    //interim = new Date().getTime();

    var a;
    if (after_num == table.rows.length) {
      for (a = 0; a < totAdded; ++a)
        if (!window.testvar)
        tbody.appendChild(allAdded[a]);
    }
    else {
      for (a = 0; a < totAdded; ++a)
        tbody.insertBefore(allAdded[a], table.rows[after_num]);
    } // end if we're appending or inserting

    if (!window.testvar) {
      Def.IDCache.addToCache(tbody);

      // Call setUpRowFieldsJS for each row we're creating.
      //interim = new Date().getTime() ;
      var rowsPerAdd = modelRows.length;
      var m;
      for (a = 0, m = 0; a < totAdded; ++a) {
        this.setUpRowFieldsJS(allAdded[a], modelRows[m]) ;
        m += 1;
        if (m == rowsPerAdd) m = 0 ;
      }
      // Only do tasks that run through everything on the page if we're
      // NOT loading data.
      // Assume that any data loading process will take care of this.
      // Note that doNavKeys will also set up listeners on input text fields
      // for the large edit box.

      if (loading == false) {

        // Add the navigation pointers to the input elements added in the
        // new repeating line row and any associated embedded rows.
        this.addToNavigation(allAdded, prevRow) ;

        // Run through the new row(s) one more time to check for and run
        // any rules present for the new input elements.  I would rather
        // do this as the autocompleters are added, to save another cruise
        // through the row(s), but I'm afraid to run the rules until ALL
        // the new input elements have been created and fully settled.
       // var func_toggleTipMessages = toggleTipMessages;
        for (a = 0; a < totAdded; ++a) {
          for (var i = 0, il = allAdded[a].cells.length; i < il; i++) {
            this.checkRules(allAdded[a].cells[i]) ;
          //  func_toggleTipMessages(allAdded[a].cells[i]) ;
            //this.autoNumberOrLabel(allAdded[a].cells[i]);
          } // end do for each cell in the row
        } // end do for each added row

        var validation =
          Def.Validation.RequiredField.Functions;
        for (a = 0; a < totAdded; ++a) {
          var newInputs = this.getTextInputs(allAdded[a]);
          validation.enableValidationOnNewLine(newInputs);
        }
      } // end if we're NOT loading data
    } // end if !window.testvar
  }, // end addTableLine


 /**
   *  This function will append a "No data" line to the specified table.
   *  This is used for tables being displayed for read-only access that
   *  do not have any data.
   *
   * @param table the table that is to receive the new line
   * @param groupID - The group form ID for the table, e.g., fe_notes_0_tbl.
   *  Used to find the name displayed for the table.  The name is used in the
   *  text of the line that is appended to the empty table.
   *
   * @returns nothing
   */
  addNoDataLine: function(table, groupID) {
    var nameFldParts = Def.IDCache.splitFullFieldID(groupID) ;
    var tableNameFld = $(nameFldParts[0] + nameFldParts[1] + '_lbl_0');
    var tableName = tableNameFld.innerHTML ;
    var colsToSpan = table.getElementsByTagName('col').length;
    var line = new Element('tr', {'class' : 'saved_row'}) ;
    var cell = new Element('td', {'class': 'noDataCell',
                                  'colSpan' : colsToSpan}).update('No <i>' +
                         tableName + '</i> data has been entered for this PHR');
    line.appendChild(cell);
    var tbody = table.down('tbody') ;
    tbody.appendChild(line);
  } , // end addNoDataLine

  
  /**
   *  This function creates one new "row".  Specifically, it creates
   *  the main row plus any embedded rows that go with it, and updates
   *  the row suffixes for all field ids within each row.
   *
   * @param strippedRows the model row(s) where each cell in the row
   *  has been stripped of its innerHTML.
   * @param rowHTML the innerHTML stripped from the cells in the rows
   * @param rowID the numeric row ID to be assigned to the new rows (they all
   *   get the same ID), in string format
   * @param modelSuffix the beginning of the suffix to be replaced for each
   *   field in the row.  This is the part up to, but not including, the point
   *   where the rowID is to be inserted.
   * @param modReg the regular expression to be used for replacing the suffix
   *   in the model row fields with the suffix for this set of rows
   *
   * @returns an array containing the new row(s)
   */
  createOneRowSet: function(strippedRows, rowHTML, rowID, modelSuffix, modReg) {

    var newRows = new Array() ;
    var newCt = strippedRows.length ;
    var newReg = modelSuffix + rowID + '$1' ;

    // For each row to be created, clone the stripped row, then
    // work through it cell by cell, setting the cell's innerHTML to
    // the innerHTML from the stripped row - updated with the correct
    // suffix numbers.
    for (var mr = 0; mr < newCt; ++mr) {
      var rowNode = strippedRows[mr].cloneNode(true) ;

      // if browser is IE and version < 8 the cell values are
      // not exposed bys using the cloneNode function until the
      // row is attached to a table.
      if (BrowserDetect.IEoldVersion) {
        var doc2 = document.createDocumentFragment();
        var otable = doc2.createElement("<TABLE>");
        var tbody = doc2.createElement("<TBODY>");
        tbody.appendChild(rowNode);
        otable.appendChild(tbody);
        rowNode = otable.tBodies[0].rows[0];
      }
      var cellCt = rowHTML[mr].length ;
      var foundRowId = false ;
      for (var c = 0; c < cellCt; c++) {
        rowNode.cells[c].innerHTML = rowHTML[mr][c].replace(modReg, newReg) ;
        if (foundRowId == false) {
          var div = rowNode.cells[c].getElementsByTagName('div')[0] ;
          if (div && div.id && div.id.indexOf('_row_id_') > 0)  {
            Def.setFieldVal(div, rowID, false) ;
            foundRowId = true ;
          }
        }
      }
      rowNode.setAttribute('rowid', rowID) ;
      newRows.push(rowNode) ;
    }
    return newRows ;

  }, // createOneRowSet


  /**
   *  Creates several row sets.
   * @param modelRows the model rows from which the new row sets should be built
   * @param numSets the number of row sets to build
   * @param nextId the starting row id for the row sets to be built.  (The
   *  caller should take care of updating the table's nextid attribute as
   *  needed.)
   *  @returns added rows
   */
  createRowSets:  function(modelRows, numSets, nextId) {
    // Set up the regular expression used in replacing the model
    // suffix with the new suffix for the cells in the rows being
    // added.
    //interim = new Date().getTime() ;
    var modelSuffix = modelRows[0].getAttribute('suffix') ;
    var lastUnder = modelSuffix.lastIndexOf('_') ;
    var modReg = new RegExp(modelSuffix + '((_\\d+)*)', 'g') ;
    modelSuffix = modelSuffix.substr(0, lastUnder + 1) ;

    // Now create as many rows (or row sets) as requested.
    // Create a strippedRows array - which contains clones of
    // the model rows with the innerHTML stripped out of each
    // cell.  The innerHTML is transferred to the rowHTML array.
    // It turns out to be quicker to clone a stripped row,
    // do the suffix replacements on the separate innerHTML,
    // and the set the cell's innerHTML to the updated version
    // than to update the cell's innerHTML directly.  Weird but true.
    // -- we could just strip the innerHTML out of the model rows,
    // but we need the model rows with the innerHTML when we set
    // up the autocompleters.
    //interim = new Date().getTime() ;
    var rowsPerAdd = modelRows.length ;
    var totAdded = numSets * rowsPerAdd ;
    var allAdded = new Array(totAdded) ;
    var strippedRows = new Array(rowsPerAdd) ;
    var rowHTML = new Array(rowsPerAdd) ;

    // Clone each model row, remove attributes that are not needed
    // on the repeating lines (or need to be assigned their own values)
    // and strip the innerHTML from the cloned rows, transferring
    // it to the rowHTML array.
    var a = 0 ;
    for (var h = 0; h < rowsPerAdd; h++) {
      strippedRows[h] = modelRows[h].cloneNode(true) ;

      // if browser is IE and version < 8 the cell values are
      // not exposed by using the cloneNode function until the
      // row is attached to a table.
      if (BrowserDetect.IEoldVersion){
        var doc2 = document.createDocumentFragment();
        var otable = doc2.createElement("<TABLE>");
        var tbody = doc2.createElement("<TBODY>");
        tbody.appendChild(strippedRows[h]);
        otable.appendChild(tbody);
        strippedRows[h] = otable.tBodies[0].rows[0];
      }
      strippedRows[h].removeAttribute('style', 0) ;
      strippedRows[h].removeAttribute('suffix', 0) ;
      var rowCells = strippedRows[h].cells.length ;

      rowHTML[h] = new Array(rowCells) ;
      for (var c = 0; c < rowCells; c++) {
        rowHTML[h][c] = strippedRows[h].cells[c].innerHTML ;
        strippedRows[h].cells[c].innerHTML = '' ;
      }
    }

    // Now create one set of rows for the number of row sets to be
    // added.
    for (var r = 0; r < numSets; r++) {
      var newRows = this.createOneRowSet(strippedRows, rowHTML,
        (nextId + r).toString(), modelSuffix, modReg) ;
      // This is weird.  Adding each row separately is quicker
      // than concatenating the whole set to the allAdded array.
      // Must be because concatenation creates a new object.
      // lm. 2/17/09.
      for (var n = 0; n < rowsPerAdd; ++n, ++a) {
        allAdded[a] = newRows[n] ;
      }
    }
    return allAdded;
  },


  /**
   *  Finds and returns the model rows for the given fields table.
   * @param table the table DOM element.
   */
  findModelRows: function(table) {
    var modelRows = new Array() ;
    var ri = 0 ;
    while (table.rows[ri].getAttribute('rowid') == null)
      ri += 1 ;
    var row = table.rows[ri];
    var numRows = table.rows.length;
    while (ri < numRows && row.getAttribute('rowid') == 0) {
      modelRows.push(row) ;
      ri += 1 ;
      row = table.rows[ri];
    }
    return modelRows;
  },


  /**
   *  This function creates any JavaScript objects (e.g. autocompleter
   *  instances) needed by input fields in the given
   *  newElement DOM element.  It relies on modelElement (which should have
   *  any needed objects already defined) for knowledge about
   *  which input elements need what.
   *
   * @param newRow the row (possibly) containing input fields that might
   *  need some JavaScript objects
   * @param modelRow the model row containing needed inputs fields to be
   *  examined to see what is needed.
   */
  setUpRowFieldsJS: function(newRow, modelRow) {
    var modelInputs = this.getTextInputs(modelRow);
    var newInputs = this.getTextInputs(newRow);
    for (var i = 0, max = modelInputs.length; i < max; ++i) {
      this.setUpFieldJS(newInputs[i], modelInputs[i]);
    }
    // Help IE recognize textarea's HTML5 maxlength attribute.  For IE, when the
    // page loads, we also load maxlength.js which defines setformfieldsize.
    // After that finishes loading it sets things up for the whole page, so
    // here we just handle new lines after that point.
    if (BrowserDetect.IE && (typeof setformfieldsize != "undefined"))
      setformfieldsize($J(newRow).find('textarea[maxlength]'));
  },


  /**
   *  Returns the input fields and textareas contained within a given DOM
   *  element.
   * @param elem the DOM element whose input fields and textareas are needed
   */
  getTextInputs: function(elem) {
    return elem.select('input, textarea');
  },


  /**
   *  This function creates field specific JavaScript objects (e.g.
   *  autocompleters). It relies on the model input element for
   *  knowledge about what is needed.
   *
   * @param newInput the input field that might need some JavaScript objects
   * @param modelInput the model input field to be examined to see what
   *  is needed
   */
  setUpFieldJS: function(newInput, modelInput) {
    // Only go further if the cell we're copying has an autocompleter
    // AND if one for the new cell hasn't already been created.
    var modelAutocomp = modelInput.autocomp;
    if ((modelAutocomp !== undefined)  && (newInput.autocomp == undefined))
      modelAutocomp.dupForField(newInput.id);

    // Set up the combo field, if it is one.
    if (modelInput.comboField)
      new Def.ComboField(newInput.id);

     // Use Datepicker from JQuery. -Ajay 04/04/2013
      if (modelInput.hasClassName('hasDatepicker') &&
          !modelInput.hasClassName('hidden_field')) {
      // Not sure how newInput is already wrapped with datepicker object, but
      // it is not triggering calendar panel.

      var opts = $J(modelInput).datepicker("option", "all"); // Supposed to work as
                                                         // per documentation?
      var cur_value = newInput.value;

      // Remove associated class and img element and wrap newInput again with
      // datepicker object. -Ajay 04/05/2013
      $J("#"+newInput.id+" + .ui-datepicker-trigger").remove();
      newInput.removeClassName('hasDatepicker');

      $J(newInput).datepicker(opts);
      newInput.next().addClassName('sprite_icons-calendar');

      newInput.value = cur_value;
    }
  }, // setUpFieldJS


  /**
   *  This function checks a table cell for an input element and, if
   *  it has one, checks the input element to see if it has rules.
   *  If it does, it runs the rules for the input element.
   *
   * @new_cell the cell to check for rules
   */
  checkRules: function(new_cell) {

    var newInput = this.inputElement(new_cell) ;
    //if (newInput != null && newInput.hasClassName('has_rules'))
    if (newInput != null && Def.Rules.hasRules(newInput))
      Def.Rules.runRules(newInput);
  }, // checkRules


  /**
   *  This function adds a new row, with any embedded rows, to
   *  the navigation for the form.
   *
   * @param newRows the new rows added to the table
   * @param prevRow the row that the new rows were added after
   *
   */
  addToNavigation: function(newRows, prevRow) {

    // Get the element that immediately precedes the new row
    // Use it to figure the starting element number in the
    // document.forms.elements array - which will be the number
    // where the new fields were added.
    var pElems = prevRow.select('input, a, button, textarea');

    // It might be that prevRow did not contain any input elements!  In this
    // case try the row before that one.
    var gotPElems = pElems.length>0;
    while (!gotPElems && prevRow.previousSibling) {
      prevRow = prevRow.previousSibling;
      if (prevRow.nodeType == Node.ELEMENT_NODE) {
        pElems = prevRow.select('input, a, button, textarea');
        gotPElems = pElems.length>0;
      }
    }

    // Proceed assuming there was at least one input element in the row.
    // Find the last element in the row.  The select statement above will
    // return the elements ordered first by tagname, and then by type, so
    // we will have fewer elements to check if we start from the end and work
    // backwards (because there are typically more "inputs").
    var maxSequenceNum = -1;
    var prevEleSeqInfo = null;
    var navSeqsHash = Def.Navigation.navSeqsHash_;
    var foundInput = false; // We only have to check the last input tag
    for (var i=pElems.length-1; i>=0 && !foundInput; --i) {
      var elem = pElems[i];
      if (elem.id) {
        var elemSeqInfo = navSeqsHash[elem.id];
        var seqNum = elemSeqInfo[1];
        if (maxSequenceNum<seqNum) {
          maxSequenceNum = seqNum;
          prevEleSeqInfo = elemSeqInfo;
        }
        if (elem.tagName == 'INPUT')
          foundInput = true;
      }
    }

    // Pass the new sequence number and the form number to doNavyKeys
    // Pass in "true" for the third parameter so that field initialization
    // (e.g. setting up field observers) only happens for the new row.
    Def.Navigation.doNavKeys(prevEleSeqInfo[0], prevEleSeqInfo[1] + 1, true,
      true);
  }, // end addToNavigation


  /**
   *  This function obtains the input element that is in the cell of
   *  a horizontal table.  Since input elements can have various tag
   *  names, and we need to keep finding them in the repeatingLine
   *  function, we use this separate helper function.
   *
   * @param theCell the cell that contains the element we want
   *
   * @returns the element in the cell that accepts, in some way or another
   *          input
   */
  inputElement: function(theCell) {
    var ele = theCell.getElementsByTagName('input')[0] ;
    if (ele == null) {
      ele = theCell.getElementsByTagName('textarea')[0] ;
      if (ele == null) {
        ele = theCell.getElementsByTagName('a')[0] ;
        if (ele == null) {
          ele = theCell.getElementsByTagName('img')[0] ;
        }
      }
    }
    if (ele)
      ele = $(ele) ;
    return ele ;
  }, // end inputElement


  /**
   *  For a fields table associated with a data model table, shows or hides the rows
   *  in the fields table whose data in the data model meet specified
   *  conditions.
   * @param dataTable the name of the data model table for the fields table
   *  whose rows' visibility states are to be updated.
   * @param show if true, rows that meet the conditions are shown, or if
   *  false, rows that meet the conditions are hidden.  If there are no
   *  conditions (conditions is null) all the rows are shown or hidden.
   * @param conditions a hash of data column name/value pairs which must
   *  be present in a row for it to be shown or hidden (accordinng to the
   *  "show" parameter).  This may be null.
   */
  setTableRowVisibility: function(dataTable, show, conditions) {
    var dataModel = Def.DataModel;
    var numRows = dataModel.getRecCount(dataTable);
    var col = null;
    for (var i=1; i<=numRows; ++i) {
      var match = true;
      var row = dataModel.getModelRecord(dataTable, i);
      if (conditions) {
        for (col in conditions) {
          if (row[col] != conditions[col]) {
            match = false;
            break;
          }
        }
      }
      if (!col) {
        // Get a column from the data model
        for (col in row) {break}
      }
      var fieldInRow = dataModel.getFormField(dataTable, col, i);
      var visible = show ? match : !match;
      this.setFieldRowVisibility(fieldInRow, visible, true);
    }
  },


  /**
   *  Sets the visiblity of the table row containing the given field.
   * @param field a DOM element, assumed to be inside a TD tag.
   * @param visible whether the row should be visible
   * @param a flag indicating if the row class needs to be checked
   */
  setFieldRowVisibility: function(field, visible, checkRowClass) {
    var row = field.up(1); //input==>td==>tr
    //some fields may have span or other layer between input and tr
    while (row.tagName.toLowerCase() != 'tr') {
      row= row.up(0);
    }
    if (row && (!checkRowClass || row.hasClassName('saved_row'))) {
      Def.setTableRowVisibility(row, visible);
      if (visible) {
        row.addClassName('show_me');
      }
      else {
        row.removeClassName('show_me');
      }
    }
  },


  /**
   *  Recaculates the needed height for a table field whose text can wrap
   *  to multiple lines, and adjusts the height of the field accordingly.
   *  This gets called on keydown events as the user types.
   * @param event the keydown event
   */
  resizeTableFieldHeight: function(event) {
    var field = event.target;
    // Don't do anything if the key was a control key or is a control+character
    if (field.hasClassName('wrap') && event.keyCode!=17 && !event.ctrlKey) {
      field.style.height = '1px'; /* so scrollHeight gets reset to the minimum */
      // scrollHeight returns different values in FF, IE9 and Chrome.
      // For example if a textarea has 1px on top and bottom border,
      // 4 px on top and bottom padding and its total height is 24px (which means
      // the content height is 14 px) as we curently have for many fields on the
      // PHR form, here's the scrollHeight value from these browsers:
      //             scrollHeight       clientHeight (fixed)
      // FF12.0     : 15                 14
      // Chrome19.0 : 23                 22
      // IE9        : 21                 22
      // Safari should be same as Chrome.
      // scrollHeight does not return a correct value is a known bug on FF.
      // see here: https://bugzilla.mozilla.org/show_bug.cgi?id=576976
      // work around for FF

      // Browser behavior is still different, but the following is a reasonable
      // compromise on height.  (Chrome also has a field position
      // issue, though.)
      field.style.height = field.scrollHeight + 2 + 'px';

      // If the field had an active autocompletion list showing, reposition it.
      if (field.autocomp && field.autocomp.active) {
        field.autocomp.posAnsList();
      }
    }
  }


  /**
   * This function automatically updates the existing autocomp list of the input
   * field through updating the row id information of the autocomp list
   * When input field is a label field, then the value of the label field
   * (e.g. "A1") should consist of label type (e.g. "A") and row number (e.g. 1).
   *
   * @param cell - a table cell which has an input field in it
   *
   **/
  /* REMOVING THIS -- Using current row number is not safe for data that is
   *                  stored.  Labels can be stored, and so are not guaranteed
   *                  to always be shown on the same row.
   *                  Use the set_autoincrement_value rule instead.
   *
  autoNumberOrLabel: function(cell){
    var inputField = this.inputElement(cell);
    if(inputField != null &&
      (inputField.hasClassName("autoLabel") || inputField.hasClassName("autoNumber"))){
      var idParts = Def.IDCache.splitFullFieldID(inputField.id);
      var rowNum = idParts[2].split("_").last();
      var valueList = inputField.hasClassName("autoNumber") ? [rowNum] :
        [ inputField.autocomp.itemCodes_[0].replace((new RegExp("\\d+$")), rowNum) ];
      var codeList = valueList;
      inputField.autocomp.setList(valueList, codeList);
    }
  }
  */
}; // Def.FieldsTable

