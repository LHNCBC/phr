/**
 *  controlled_edit_table.js - Contains classes, data structures, and functions
 *  related to the controlled edit table, which is a type of fields table where
 *  editing is restricted.  This could be a sub-class of FieldsTable, but
 *  FieldsTable is not (yet?) a class.  
 */
Def.FieldsTable.ControlledEditTable = Class.create({});
Object.extend(Def.FieldsTable.ControlledEditTable, Def.Observable);

/**
 *  Data and methods common to all instances of ControlledEditTable.
 */
var classMembers = {
  /**
   *  The marker that indicates a record ID is marked for deletion.  This
   *  appears in front of the actual ID.
   */
  DELETED_MARKER: null, // set in form_data.rb

  /**
   *  The menu label for the Revise command.
   */
  MENU_LABEL_REVISE: 'Revise',

  /**
   *  The menu label for the Delete command.
   */
  MENU_LABEL_DELETE: 'Delete',

  /**
   *  The menu label for the Clear Row command.
   */
  MENU_LABEL_CLEAR_ROW: 'Delete',

  /**
   *  A structure needed by controlled-edit tables to determine the behavior
   *  of the context menus.  This structure is data generated along with the
   *  form HTML, and is set elsewhere.  It is a hash of tables' target_field
   *  names to the data needed by each table.  (See the reference to
   *  @ce_table_data in fields_group_helper.rb for more information.)  This is
   *  not held as an instance variable because for a single target_field name
   *  there can be multiple instances (if the table is embedded in another
   *  table).
   */
  ceTableData_: null,

  /**
   * An array of all the controlled edit table instances.
   */
  ceTables_: [],


  /**
   *  Warns the user if the given field has duplicates within its table.
   * @param field the DOM field that changed, triggering the need for a check.
   * @param codeField the field for the code corresponding to "field" (if such
   *  a thing exists).  If this is not null, this is the field that will be
   *  checked for duplicates.
   * @param fieldGroupID the ID of the field group containing this field.
   */
  warnAboutDuplicates: function(field, codeField, fieldGroupID) {
     $(fieldGroupID).ce_table.conflictChecker_.warnAboutDuplicates(field, codeField);
  },


  /**
   *  Registers a callback for when the duplicate warning message appears.
   * @param baseFieldID the central part of the field ID with the prefix
   *  (ending with _) and the suffix (numbers like _1_2_1) removed.  The
   *  idea is that there might be multiple fields (perhaps of an unknown number)
   *  that are related for which the callback should receive notifications.
   * @param callback the function to be called when a duplicate warning message
   *  is displayed.  The function will be called with the following argument:
   *  - duplicate_warning (the text of the warning)
   */
  observeDuplicateWarnings: function(baseFieldID, callback) {
    this.storeCallback(baseFieldID, 'DUPLICATE', callback);
  },


  /**
   *  Called after data loading to add a blank line to any controlled edit
   *  tables that didn't have any saved data.
   */
  addNeededBlankRows: function() {
    for (var i=0, max=this.ceTables_.length; i<max; ++i) {
      var table = this.ceTables_[i];
      if (!table.dataLoaded_) {
        var domTable = $(table.fieldGroupID_).down('table');
        Def.FieldsTable.addTableLine(domTable, null, 1, true);
      }
    }
  },


  /**
   *  Given a hash of codes to values, returns the value whose code matches
   *  the value of the specified field.  If no match is found, the default
   *  is returned.
   * @param cet the ControlledEditTable instance.
   * @param codeField the "target field name" of the field that contains
   *  the code to be matched.
   * @param codeToVals the hashmap of codes to values
   * @param defaultReturn the default value to be returned in case of no match.
   */
  selectByFieldCode: function(cet, codeField, codeToVals, defaultReturn) {
    // Find the field
    var domField = this.findFieldInRowSet(cet.menuRowSet_, codeField);

    var rtn = defaultReturn;
    if (domField) {
      var match = codeToVals[Def.getFieldVal(domField)];
      if (match)
        rtn = match;
    }
    return rtn;
  },


  /**
   *  Sets a list field value and its associated code field.  This is used
   *  as a table-specific command from the context menu.
   * @param cet the ControlledEditTable instance.
   * @param undoLabel the label for the undo menu item for this action (but
   *  without the string "Undo" at the beginning).
   * @param listField the "target field name" of the list field
   * @param code the code to use in selecting the list item.
   */
  setListFieldByCode: function(cet, undoLabel, listField, code) {
    var oneRowsData = cet.rowData_[cet.menuRowID_];
    if (!oneRowsData['state_flags']['saveable']) {
      cet.makeRowSaveable(null);
    }
    var domListField = this.findFieldInRowSet(cet.menuRowSet_, listField);
    var prevFieldVals = {};
    var autocomp = domListField.autocomp;
    if (autocomp) {
      prevFieldVals[domListField.id] = domListField.value;
      var codeField = Def.getFieldsCodeField(domListField);
      if (codeField)
        prevFieldVals[codeField.id] = codeField.value;
      autocomp.selectByCode(code);
      Def.setFieldVal(codeField, code, true); // run change observers
      // We also have to set the text node that the user sees.  (The actual
      // field is hidden to avoid field events.)
      if (domListField.previousSibling)
        domListField.previousSibling.innerHTML = domListField.value;

      cet.saveUndoData(undoLabel, {}, prevFieldVals);
    }
  },


  /**
   *  Does the same thing as setListFieldByCode, but also makes some
   *  fields editable.
   * @param cet the ControlledEditTable instance.
   * @param undoLabel the label for the undo menu item for this action (but
   *  without the string "Undo" at the beginning).
   * @param listField the "target field name" of the list field
   * @param code the code to use in selecting the list item.
   * @param fieldsToOpen the target field names of the fields to make editable
   */
  setListFieldByCodeAndOpenFields: function(cet, undoLabel, listField,
      code, fieldsToOpen) {
    this.setListFieldByCode(cet, undoLabel, listField, code);
    // Get the undo information that setListFieldByCode added -- we will need
    // to update it.
    var oneRowsData = cet.rowData_[cet.menuRowID_];
    var undoStack = oneRowsData['undo_stack'];
    var undoData = null, tdEditStates, fieldVals, fieldIDToCellIndex;
    if (undoStack.length > 1) {
      undoData = undoStack[undoStack.length - 1];
      tdEditStates = undoData[1];
      fieldVals = undoData[2];
      fieldIDToCellIndex = oneRowsData['field_id_to_cell_index'];
    }

    // Now process the extra fields
    for (var i=0, max=fieldsToOpen.length; i<max; ++i) {
      var field = this.findFieldInRowSet(cet.menuRowSet_, fieldsToOpen[i]);
      // Update the undo information for the field, if necessary.
      // It is not necessary if this is the only operation on the "undo stack".
      if (undoData) {
        if (fieldVals[field.id] === undefined)
          fieldVals[field.id] = Def.getFieldVal(field);
        var cellIndex = fieldIDToCellIndex[field.id];
        if (tdEditStates[cellIndex] === undefined)
          tdEditStates[cellIndex] = !cet.isFieldReadOnly(field);
      }
      cet.makeFieldEditable(field);
    }
  },


  /**
   *  Tries to find a field in the specified row set (set of rows sharing the
   *  same row ID.)
   * @param rowSet an array of DOM table rows
   * @param targetFieldName the "target field name" of the field to be found.
   * @return the field, or null if not found
   */
  findFieldInRowSet: function(rowSet, targetFieldName) {
    var domField = null;
    for (var i=0, max=rowSet.length; i<max && !domField; ++i)
      domField = this.findFieldInRow(rowSet[i], targetFieldName);
    return domField;
  },


  /**
   *  Returns an array of the rows of the table with the same row id as the
   *  given row.  This does not assume that the given row is the first
   *  in its row set (the set of rows sharing the rowID).
   * @param row the DOM row node, for the case where one row in the row set
   *  is known.  If this is not known, null can be passed in.
   * @param rowID the rowid attribute of the row node.
   */
  getRowSetForRow: function(row, rowID) {
    var inputRow = row;
    var rtn = [];
    // Get the rows before the current row
    while (row.previousSibling &&
      (row.previousSibling.nodeType !== Node.ELEMENT_NODE ||
       Element.readAttribute(row.previousSibling, 'rowId') == rowID)) {
      row = row.previousSibling;
      if (row.nodeType == Node.ELEMENT_NODE)
        rtn.push(row);
    }
    rtn.reverse();
    rtn.push(inputRow);
    // Get the rows after the current row
    row = inputRow;
    while (row.nextSibling && (row.nextSibling.nodeType !== Node.ELEMENT_NODE ||
           Element.readAttribute(row.nextSibling, 'rowId') == rowID)) {
      row = row.nextSibling;
      if (row.nodeType === Node.ELEMENT_NODE)
        rtn.push(row);
    }
    return rtn;
  },


  /**
   *  Returns the child elements in the given rows (ignoring text nodes).  The
   *  returned array should consist entirely of td or th tags.
   * @param rows the rows whose TD elements are needed.
   */
  getRowCells: function(rows) {
    var rtn = [];
    for (var i=0, max=rows.length; i<max; ++i) {
      var rowTDs = Element.childElements(rows[i]);
      for (var j=0, maxJ=rowTDs.length; j<maxJ; ++j)
        rtn.push(rowTDs[j]);
    }
    return rtn;
  },


  /**
   *  Tries to find a field in the specified table row DOM node.  This is not
   *  intended to be called directly; it is a utility method for
   *  findFieldInRowSet.
   * @param nodeRow the DOM row object
   * @param targetFieldName the "target field name" of the field to be found.
   * @return the field, or null if not found
   */
  findFieldInRow: function(nodeRow, targetFieldName) {
    var fieldIDStart = Def.FIELD_ID_PREFIX + targetFieldName;
    var selectPattern = '[id^='+fieldIDStart+']';
    var domFieldCandidates = nodeRow.select(selectPattern);
    var domField = null;
    var idCache = Def.IDCache;
    if (domFieldCandidates) {
      if (domFieldCandidates.length === 0)
        domField = domFieldCandidates[0];
      else {
        // Find the right one.  There could be more than one, if the target
        // field name is a subset of another field's target field name (as it
        // is in the case of list fields with code fields).
        for (var i=0, max=domFieldCandidates.length; i<max && !domField; ++i) {
          var candidate = domFieldCandidates[i];
          var fieldIDParts = idCache.splitFullFieldID(candidate.id);
          if (fieldIDParts[1] === targetFieldName)
            domField = candidate;
        }
      }
    }

    return domField;
  },


  /**
   *  Updates the state of the controlled edit tables on the form (as needed)
   *  after the user saved the form using Def.doSave (in application_phr.js).
   * @param saveRespData the 'data' attribute of the response doSave gets
   *  back from the server.  This is a hash with keys 'added', 'deleted', and
   *  'updated'.  Each value is an array of arrays, where each subarray contains
   *  a data table name, a record index, and a record ID.
   */
  postSaveUpdate: function(saveRespData) {
    // Organize the response data by table
    var cet;
    try { // if this fails, reload the page
      var tableToUpdates = {};
      var changes = [saveRespData['added'], saveRespData['updated'],
      saveRespData['to_remove']]; // to_remove includes both 'deleted' & 'empty'
      var i, max, entry, tableData, tableName;
      for (var changeType=0; changeType<3; ++changeType) {
        var changeSet = changes[changeType];
        for (i=0, max=changeSet.length; i<max; ++i) {
          entry = changeSet[i];
          tableName = entry[0];
          var dataModelPos = entry[1];
          tableData = tableToUpdates[tableName];
          if (!tableData) {
            tableData = [[],[],[]]; // added, updated, to_remove
            tableToUpdates[tableName] = tableData;
          }
          var changeRows = tableData[changeType];
          var formFieldInRow =
            Def.DataModel.getFormFieldAtRowPosition(tableName, dataModelPos);
          var formRow = formFieldInRow.up('tr.repeatingLine,tr.embeddedRow');
          if (formRow) // won't be defined for table 'phrs' (e.g. phr_index form)
            changeRows.push(parseInt(formRow.readAttribute('rowid'), 10));
        }
      }

      // Now process the change data for each table to make the rows
      // change to a "saved" state.
      var rowIDs;
      var tableToGroup = {};
      var tableToGroupArray = Def.DataModel.table_2_group_;
      for (i=0, max=tableToGroupArray.length; i<max; ++i) {
        entry = tableToGroupArray[i];
        if (entry[1][0]) // on the phr_index this is not defined for "phrs"
          tableToGroup[entry[0]] = entry[1][0][0]; // table_name => group field ID
      }
      var oldFields = []; // arrays of data-carrying fields removed from the form
      var affectedFields = [];  // used for re-running rules which have actions on
      for (tableName in tableToUpdates) {
        tableData = tableToUpdates[tableName];
        var fieldGroupName = tableToGroup[tableName];
        // Get the controlled edit table instance, if there is one for this table.
        if (fieldGroupName) {
          cet = $(fieldGroupName).ce_table;
          if (cet) {
            rowIDs = tableData[1]; // updated
            if (rowIDs.length > 0){
              affectedFields.push(cet.getAffectedFields(rowIDs));
              oldFields.push(cet.putUpdatedRowsIntoSavedState(rowIDs));
            }
            rowIDs = tableData[0]; // new
            if (rowIDs.length > 0){
              affectedFields.push(cet.getAffectedFields(rowIDs));
              oldFields.push(cet.putNewRowsIntoSavedState(rowIDs));
            }
            // Deleted and empty rows are currently handled the same
            rowIDs = tableData[2]; // should already be sorted by the server
            if (rowIDs.length > 0) {
              // The following removes blank and deleted rows
              oldFields.push(cet.cleanUpDeletedRows(tableName, rowIDs));
            }
          }
        }
      }

      // At this point there might still be rows opened for editing but
      // not changed.  (This can also be accomplished by a combination of
      // "Make Active" followed by "Make Inactive"-- no change from the server's
      // point of view, but certain fields are open for editing.) Put them into the
      // saved state.
      var ce_tables = this.ceTables_;
      for (i=0, max=ce_tables.length; i<max; ++i) {
        cet = ce_tables[i];
        var rowData = cet.rowData_;
        rowIDs = [];
        var rowDataKeys = Object.keys(rowData);
        for (var j=0, len=rowDataKeys.length; j<len; ++j) {
          var rowID = rowDataKeys[j];
          // Make sure this is a saved row in an editable state.  The rowID
          // can exist simply because the menu was activated.
          var stateFlags = rowData[rowID].state_flags;
          if (stateFlags && stateFlags.saveable && !stateFlags.deleted)
            rowIDs.push(rowID);
        }
        // The following command does not run change requests, and that is okay
        // because these rows have not really changed.
        if (rowIDs.length > 0)
          oldFields.push(cet.putUpdatedRowsIntoSavedState(rowIDs));
      }

      if (oldFields.length > 0)
        this.disconnectFields(oldFields);
      // Re-runs rules which have actions on the input rows, e.g. has_allergy_url.
      if(affectedFields.length > 0){
        affectedFields = affectedFields.flatten();
        Def.Rules.runRulesForFields(affectedFields);
      }
    }
    catch (e) {
      // For debugging, add saveRespData to the message
      e.message += '; recoveredData[1]=' + Object.toJSON(Def.DataModel.recovered_fields_);
      e.message += '; saveRespData=' + Object.toJSON(saveRespData);
      if (typeof cet !== 'undefined')
        e.message += '; rowData_ = ' + Object.toJSON(cet.rowData_);
      throw e;
    }
  },


  /**
   *  Disconnects the given fields from navigation and listeners as needed.
   * @param fields the fields to be disconnected.  It is assumed that the
   *  field that is first in the navigation sequence is first in this array.
   *  This may also be an array of arrays of fields, in which case the code
   *  assumes that the first field in each sub-array has the earliest
   *  navigation sequence number.
   */
  disconnectFields: function(fields) {
    try {
      var nav = Def.Navigation;
      var navFieldData = null;
      var navSeqsHash = nav.navSeqsHash_;
      var firstField = fields[0];
      if (typeof firstField === 'object' && firstField.constructor === Array) {
        // Per the method comments, fields in this case is an Array of Arrays.
        navFieldData = navSeqsHash[firstField[0].id];
        // Flatten the array, but find first the earliest field.
        for (var i=1, numArrays=fields.length; i<numArrays; ++i) {
          var nfd = navSeqsHash[fields[i][0].id];
          if (navFieldData[1] > nfd[1])
            navFieldData = nfd;
        }
        fields = fields.flatten();
      }
      else {
        navFieldData = navSeqsHash[firstField.id];
      }

      nav.clearNavData(fields);
      nav.doNavKeys(navFieldData[0], navFieldData[1]-1, true);
    }
    catch (e) {
      // For debugging, add fields to the message
      try {
        e.message += '; fields =' + Object.toJSON(fields);
        e.message += '; navFieldData =' + Object.toJSON(navFieldData);
      }
      catch (e2) {
        e2.message += '; blew up in disconnectFields while trying to add fields '+
         'and navFieldData to the message.  Original exception message and stack was:' +
         e.message + "\n" + printStackTrace(e);
        throw e2;
      }
      throw e;
    }
  },


  /**
   *  Hides blank rows in controlled edit tables following a page load.
   *  Blank rows can exist if there is autosaved data.
   */
  hideBlankRows: function() {
    var dataTable = Def.DataModel.data_table_;
    for (var tableName in dataTable) {
      var tableData = dataTable[tableName];
      // Check each row in the data table, but skip the last row, which is
      // usually a new row.  Also, start from the last row and work toward
      // the first.  When we get to a line that has a record ID, we can stop
      // because that is a saved (not autosaved) row, and shouldn't be blank.
      var foundRecordID = false;
      for (var i=tableData.length-2; i>=0 && !foundRecordID; --i){
        var row = tableData[i];
        var recordID = row['record_id'];
        if (recordID !== null && recordID !== '')
          foundRecordID = true;
        else {
          // Check for a blank row
          var blank = true;
          for (var fieldName in row) {
            if (row[fieldName] !== null && row[fieldName] !== '') {
              blank = false;
              break;
            }
          }
          if (blank) {
            var rowField = Def.DataModel.getFormField(tableName, fieldName, i+1);
            var formRow = rowField.up('.repeatingLine, .embeddedRow');
            if (formRow) {
              var nodeRowID = formRow.readAttribute('rowid');
              var rowSet = this.getRowSetForRow(formRow, nodeRowID);
              for (var j=0, numFormRows = rowSet.length; j<numFormRows; ++j) {
                rowSet[j].addClassName('removed');
              }
            }
          }
        }
      }
    }
  }
};
Object.extend(Def.FieldsTable.ControlledEditTable, classMembers);


/**
 *  Data and methods that apply to a particular instance of a
 *  ControlledEditTable.
 */
var instanceMembers = {
  /**
   *  The context menu for this table.
   */
  contextMenu_: null,

  /**
   *  The ID of the field group DOM node for this table.
   */
  fieldGroupID_: null,

  /**
   *  The target field name of the record ID field.
   */
  recordIDTargetField_: null,

  /**
   *  The column index of the column containing the record ID field.
   */
  recordIDColIndex_: null,

  /**
   *  An array of hashes of data about the rows, one hash per row.
   *  Keys:<ul>
   *     <li>undo_stack - a stack of undo data for each undo-able action.
   *       The first entry just contains an array with the label of the menu
   *       item that was chosen.  Subsequent entries also contain an array
   *       of flags, one for each field in the row, which are true if the field
   *       should be editable, and a copy of the state_flags hash for the
   *       time at which the menu item was selected.</li>
   *     <li>fields - Created when a row is made saveable, this is an array
   *      with a sub-array for each field.  Each subarray contains a reference
   *      to the DOM-element for the non-editable display-only version of the
   *      field, and a reference to the editable version of the field.
   *     <li>state_flags - a hash of state flags about the row, with the following
   *       keys and meanings:<ul>
   *       <li>editable - whether the row is in an editable state.  This is true
   *         if the user has selected "Revise" on a saved row, of if the row is
   *         new. This controls whether the "Revise" menu option is enabled or
   *         not.</li>
   *       <li>saved_row - whether the row was previously saved</li>
   *       <li>deleted - whether the row has been deleted</li>
   *       <li>saveable - whether the row's data had been made savable (which
   *         happens when the user selects one of the commands on a saved row).</li>
   *     </ul></li>
   *     <li>row_set_cells - An array of the TD DOM elements in the row set</li>
   *     <li>original_cell_html - An array of HTML strings comprising the inner
   *      HTML of the cells, as they were originally when the page loaded.</li>
   *     <li>field_id_to_cell_index - A hash from field IDs in the row to
   *      the index of the containing TD tag in the array of row cells.</li>
   *  </ul>
   */
  rowData_: null,

  /**
   *  Keeps track of whether createReadOnlyRows has been called, so that we
   *  know whether data was loaded for this table.
   */
  dataLoaded_: false,

  /**
   *  A reference to the ceTableData_ data for this table.
   */
  tableInfo_: null,

  /**
   *  The array of editable model rows for this table.
   */
  editableModelRows_: null,

  /**
   *  The array of editable model row input fields for this table.
   */
  editableModelFields_: null,

  /**
   *  A reference to the class object for access to its functions.
   */
  cetClass_: Def.FieldsTable.ControlledEditTable,

  /**
   *  The row set on which the user has brought up the context menu.
   */
  menuRowSet_: null,

  /**
   *  The row ID of the row set on which the user has brought up the context
   *  menu.
   */
  menuRowID_: null,

  /**
   *  This gets set to true if the menu is in use.  (Sometimes you can bring
   *  up a second menu before a menu command has finished running.)
   */
  menuInUse_: false,

  /**
   *  The menu item for the "undo" command.
   */
  undoMenuItem_: null,

  /**
   *  The menu item for the "revise row" command.
   */
  editMenuItem_: null,

  /**
   *  The menu item for the "delete row" command.
   */
  deleteMenuItem_: null,

  /**
   *  The menu item for the "clear row" command.
   */
  clearMenuItem_: null,

  /**
   *  An array containing arrays of the table specific menu items, with
   *  one sub-array for each mutually exclusive set of menu items.
   */
  tableSpecificMenuItems_: null,

  /**
   *  The separator menu item that appears before the table specific menu
   *  items.
   */
  tableSpecificSeparator_: null,

  /**
   *  The conflict checker used to warn about duplicates.
   */
  conflictChecker_: null,

  /**
   *  Constructor.
   * @param fieldGroupID the ID of the table's field group.
   * @param recordIDTargetField the target field name of the record ID field.
   * @param conflictChecker the conflictChecker to be used
   */
  initialize: function(fieldGroupID, recordIDTargetField, conflictChecker) {
    this.rowData_ = [];
    this.fieldGroupID_ = fieldGroupID;
    this.recordIDTargetField_ = recordIDTargetField;
    if (conflictChecker)
      this.conflictChecker_ = conflictChecker;
    else
      this.conflictChecker_ = Def.FieldsTable.ControlledEditTable.ConflictChecker;

    // Initialize tableInfo_.
    var targetField = Def.IDCache.splitFullFieldID(this.fieldGroupID_)[1];
    this.tableInfo_ =
      this.cetClass_.ceTableData_[targetField];

    if (Def.formEditability_ !== Def.FORM_READ_ONLY_EDITABILITY)
      this.buildContextMenu(fieldGroupID);

    // Store a reference to this table on the field header node.
    $(fieldGroupID).ce_table = this;
    this.cetClass_.ceTables_.push(this);

    Event.observe(fieldGroupID, 'change',
      this.removeRowIfBlank.bindAsEventListener(this));
  },


  /**
   *  Handles the edit menu action.
   * @param allowUndo whether the action can be undone.  (Default = true.)
   *  In the case of autosave recovered data initialization, we don't want
   *  to allow the undo.
   */
  editRow: function(allowUndo) {
    if (allowUndo === undefined)
      allowUndo = true ;
    var stateFlags = this.rowData_[this.menuRowID_]['state_flags'];
    var is_editable_field = this.tableInfo_['is_editable_field'];
    var cetClass = this.cetClass_;
    if (!stateFlags['saveable']) {
      if (allowUndo)
        this.saveUndoData(cetClass.MENU_LABEL_REVISE) ;
      this.makeRowSaveable(is_editable_field);
    }
    else {
      // The table has editable fields (from the table command).  We just
      // need to make them visible, and get rid of the text node values.
      var rowIDTDs = this.cetClass_.getRowCells(this.menuRowSet_);
      var previousEditStates = {};
      var prevFieldVals = {};
      for (var i=0, max=rowIDTDs.length; i<max; ++i) {
        // Find the fields in the cell.
        var rowTD = rowIDTDs[i];
        var cellFields = this.getFieldsFromElement(rowTD);
        for (var f=0, numFields=cellFields.length; f<numFields; ++f) {
          // Because some fields affect other associated fields (e.g. lists
          // and dates, we cache all the values, even if not open for editing.
          var field = cellFields[f];
          prevFieldVals[field.id] = Def.getFieldVal(field);
          if (is_editable_field[i]) {
            // See if the fields in the cell are in the read-only state, and
            // change them to editable if they are.  We toggle the state on
            // a cell-level, so the first field in the cell should be
            // representative (if not the only one).
            if ( this.isFieldReadOnly(cellFields[0])) {
              previousEditStates[i] = false;
              this.makeFieldEditable(field);
            } // if the cell is not already editable
          } // if the cell should be editable
        } // for each field
      } // for each cell

      this.saveUndoData(cetClass.MENU_LABEL_REVISE, previousEditStates,
        prevFieldVals);
    } // else the row was already saveable

    // Update the status of this row.
    stateFlags['editable'] = true;
  },


  /**
   *  Handles the delete menu action (and confirms the action with the user).
   */
  confirmDeleteRow: function() {
    var oneRowsData = this.rowData_[this.menuRowID_];
    var answer = null;
    if (oneRowsData['state_flags']['editable']) {
      answer = window.confirm(
        'Are you sure you wish to discard your changes and'+"\n"+
        ' mark this row for deletion?');
    }
    // else we don't confirm
    if (answer===null || answer) {
      this.deleteRow();
    }
  },


  /**
   *  Marks the current row for deletion (without confirming).
   * @param runChangeObservers optional parameter used to specify whether or
   *  not the change observers should be run after the value of a field is
   *  set.  Default is true; false is used for recovered fields, where we
   *  don't want to duplicate data that's already there.
   */
  deleteRow: function(runChangeObservers) {
    if (runChangeObservers === undefined)
      runChangeObservers = true ;
    var recordIDTD = this.menuRowSet_[0].cells[this.getRecordIDColIndex()];
    var recordIDFieldID = recordIDTD.down('[id]').id;

    var stateFlags = this.rowData_[this.menuRowID_]['state_flags'];
    var previousEditStates = {};
    if (!stateFlags['saveable']) {
      this.makeRowSaveable(null);
    }
    else {
      // Make any input fields appear as uneditable text (except the one
      // which is the record ID.)
      var rowIDTDs = this.cetClass_.getRowCells(this.menuRowSet_);
      for (var i=0, max=rowIDTDs.length; i<max; ++i) {
        var rowTD = rowIDTDs[i];
        var cellFields = this.getFieldsFromElement(rowTD);
        if (cellFields.length > 0 && !this.isFieldReadOnly(cellFields[0])) {
          previousEditStates[i] = true;
          for (var f=0, numFields=cellFields.length; f<numFields; ++f) {
             var field = cellFields[f];
             if (field.id !== recordIDFieldID) {
               this.makeFieldReadOnly(field);
               // after deletion of each field, run the delete event observer
               Def.FieldEvents.runEventObservers([field],"delete");
             }
          }
        }
      } // for each cell
    } // else the row was already saveable

    var recIDField = $(recordIDFieldID);
    var prevFieldVals = {};
    prevFieldVals[recordIDFieldID] = recIDField.value;
    this.saveUndoData(this.cetClass_.MENU_LABEL_DELETE, previousEditStates,
       prevFieldVals);

    Def.setFieldVal(recIDField,
                    this.cetClass_.DELETED_MARKER + recIDField.value,
                    runChangeObservers);
    this.addRowSetClass('deleted');
    stateFlags['deleted'] = true;
  },


  /**
   *  Handles the "Clear Row" menu action (and confirms the cancel with
   *  the user.)
   */
  confirmClearRow: function() {
    var answer = window.confirm('Are you sure you want to erase this row?');
    if (answer) {
      this.clearRow();
    }
  },


  /**
   *  Clears the current row (without confirming).
   */
  clearRow: function() {
    // Find all of the input fields on the form and clear the values.
    var inputs = this.getFields(this.menuRowSet_);
    var fieldVals = [];
    for (var i=0, max=inputs.length; i<max; ++i)
      fieldVals.push('');
    Def.setFieldVals(inputs, fieldVals);
  },


  /**
   *  Called at data loading time to initialize the table with the correct
   *  number of read-only rows needed to hold the saved data records.
   * @param table the table DOM element that is to receive the read-only rows
   * @param numToAdd the number of read-only lines to be added.
   */
  createReadOnlyRows: function(table, numToAdd) {
    var tbody = table.tBodies.item(0);

    // Add the new rows
    var allRowHTML = this.buildReadOnlyRowHTML(table, 1, numToAdd);
    var rowNodes = this.parseRowHTML(allRowHTML);

    for (var i=rowNodes.length; i>0; --i)
      tbody.appendChild(rowNodes.item(0)); // item(0) gets removed each item

    table.writeAttribute('nextid', numToAdd+1);

    Def.IDCache.addToCache(tbody);
    this.dataLoaded_ = true; // (the data is about to be loaded)
  }, // createReadOnlyRows


  // === Functions below this marker are not intended to be called directly ===
  /**
   *  Constructs the HTML for read only table rows (but does not convert
   *  the HTML into DOM elements).
   * @param table the table DOM element that is to receive the read-only rows
   * @param rowIDStart the rowID of the first row (row set) to be constructed
   * @param numRows the number of row sets (groups of rows with the same row ID)
   *  to be constructed
   * @return the HTML for the rows
   */
  buildReadOnlyRowHTML: function(table, rowIDStart, numRows) {
    var modelHTML = this.tableInfo_['read_only_model_row'];
    var modelSuffix = table.getAttribute('suffix') ;
    var lastUnder = modelSuffix.lastIndexOf('_');
    var truncatedSuffix = modelSuffix.substr(0, lastUnder + 1);
    var modelRowSuffix = truncatedSuffix + '1'; //true for controlled edit tables
    var elemIdPat =
      new RegExp('( id="[^\'">]*?)'+modelRowSuffix+'((_\\d+)*)', 'g');
    var replacmentPatternStart = '$1'+truncatedSuffix;
    var rowidPattern = new RegExp(' rowId="\\d+"', 'g');
    // Also create a pattern for matching field ID's in onclick attributes.
    // The onclick attributes will be replaced with Event.observe, but for now
    // they we are still using them.
    var onclickPat = new RegExp('( onclick="[^\\"]*?\\w+)'+ modelRowSuffix+
      '((_\\d+)*)', 'g');
    var onclickRep = '$1'+truncatedSuffix ;

    var allRowHTML, nextRowID, maxRowID;
    if (rowIDStart==1) {
      // The read-only model row has rowID 1 already present
      allRowHTML = modelHTML;
      nextRowID = 2;
      maxRowID = numRows;
    }
    else {
      allRowHTML = '';
      nextRowID = rowIDStart;
      maxRowID = rowIDStart + numRows - 1;
    }

    var rowHTML;
    for (var rowid=nextRowID; rowid<=maxRowID; ++rowid) {
      rowHTML = modelHTML.replace(rowidPattern, ' rowId="'+rowid+'"');
      rowHTML = rowHTML.replace('>1<', '>' + rowid + '<') ;
      rowHTML = rowHTML.replace(onclickPat, onclickRep+rowid+'$2');
      allRowHTML += rowHTML.replace(elemIdPat, replacmentPatternStart+rowid+'$2');
    }
    return allRowHTML;
  },


  /**
   *  Turns a string of table row HTML (the output of buildReadOnlyRowHTML)
   *  into a parsed DOM structure.
   * @param rowHTML the the table row HTML (possibly several rows)
   * @return a NodeList of DOM Nodes for the parsed row nodes
   */
  parseRowHTML: function(rowHTML) {
    // if browser is IE create a DOM document of the HTML and add it to tbody
    var rtnRows = null;
    if (BrowserDetect.IE) {
      // Create a temporary document and a temporary table for IE
      //var doc2 = document.createDocumentFragment();
      //var otable = doc2.createElement("<TABLE>");
      var odiv = document.createElement('DIV');
      var allRowHTML = "<TABLE><TBODY> " + rowHTML + " </TBODY></TABLE>";
      odiv.innerHTML = "<TABLE><TBODY> " + rowHTML + " </TBODY></TABLE>";
      rtnRows = odiv.firstChild.rows;
//      var otable = document.createElement("TABLE");
//      var allRowHTML = "<TBODY> " + rowHTML + " </TBODY>";
//      allRowHTML = allRowHTML.gsub('&#x27;',"'");
//      HTMLtoDOM(allRowHTML, otable);  // loads otable
//      rtnRows = otable.rows;
    }
    else {
      var tempNode = document.createElement('table'); // tbody doesn't work in FF 3.6
      tempNode.innerHTML = rowHTML;
      rtnRows = tempNode.rows;
    }

    return rtnRows;
  },


  /**
   *  Builds the context menu for a controlled-edit table.
   *  All menu items are added, and then we hide the ones we don't want to
   *  appear.  As of Dojo 1.5 (and maybe in 1.4) actually adding and removing
   *  after the menu has been created and shown causes problems, so instead
   *  of that we hide the inapplicable items (in setUpContextMenu).
   * @param fieldGroupID the ID of the table's field group.
   */
  buildContextMenu: function(fieldGroupID) {
    this.menuItemIDToFunction_ = {};

    this.undoMenuItem_ = this.createMenuItem('Undo', 'undoOrConfirmCancelEdit');

    var cetClass =  this.cetClass_;
    this.editMenuItem_ =
      this.createMenuItem(cetClass.MENU_LABEL_REVISE, 'editRow');
    this.deleteMenuItem_ =
      this.createMenuItem(cetClass.MENU_LABEL_DELETE, 'deleteRow');
    this.clearMenuItem_ =
      this.createMenuItem(cetClass.MENU_LABEL_CLEAR_ROW, 'confirmClearRow');

    // Delete and Clear will not both be shown at the same time, so hide
    // one so that the menu positioning will have a valid menu size to work
    // with.  (This is only an issue the first time the menu is opened, and
    // only if the menu has to be placed above the mouse position.)
    this.clearMenuItem_.style.display = 'none';

    var menuItems = [this.undoMenuItem_, this.createMenuSeparator(),
      this.editMenuItem_, this.deleteMenuItem_, this.clearMenuItem_].concat(
      this.createTableSpecificContextMenuOptions());
    var menuID = fieldGroupID + '_' + 'menu';
    this.contextMenu_ = $J('<ul id="'+menuID+
      '" class="jeegoocontext cm_default" style="display: none"></ul>');
   for (var i=0, num=menuItems.length; i<num; ++i)
      this.contextMenu_.append(menuItems[i]);
    $J('body').append(this.contextMenu_[0]);
    var menuOptions = {
      onShow: function(event, context) {
        this.lastHoverID_ = '';
        // For a left click, only show the menu when the action button is clicked
        if (event.type !== 'click' || event.target.hasClassName('cet_action')) {
          if (!this.menuInUse_) {
            this.menuInUse_ = true;
            try {
              this.setUpContextMenu(event.target);
            }
            finally {
              this.menuInUse_ = false;
            }
          }
        }
        else {
          if (event.type === 'click')
            this.helpOnLeftClick(event);
          return false;
        }
      }.bind(this),

      onSelect: function(event, context) {
        var rtn = false; // cancel the default
        var menuItem = event.target;
        if (!Element.hasClassName(menuItem, 'disabled')) {
          var itemFunction = this.menuItemIDToFunction_[event.target.id];
          if (itemFunction) {
            itemFunction();
            this.unhighlightRowSet();
            rtn = true;
          }
        }
        return rtn;
      }.bind(this),

     onHover: function(e, context) {
        // Adds the hovered menu item to the screen reader buffer
        var menuItem = e.target;
        if (this.lastHoverID_ !== menuItem.id) {
          this.lastHoverID_ = menuItem.id;
          var menuText = $J(menuItem).text();
          if (menuItem.hasClassName('disabled'))
            menuText += ' (disabled)';
          Def.ScreenReaderLog.add(menuText);
        }
        return false; // to dicontinue the default handling
      }.bind(this),

      onHide: function() {
        this.unhighlightRowSet();
      }.bind(this),

      event: ['click', 'contextmenu', 'dblclick'],
      keyDelay: 1000
    };
    $J($(fieldGroupID).down('tbody')).jeegoocontext(menuID, menuOptions);
  },


  /**
   *  Initializes the context menu for a controlled-edit table.
   * @param domNode the DOM node that was clicked
   */
  setUpContextMenu: function(domNode) {
    var oneRowsData = this.initMenuLocation(domNode); // sets menuRowID_
    // menuRowID_ should never be null.  If it is, there's not much we can
    // do except not show the menu.
    if (this.menuRowID_) {
      var stateFlags = oneRowsData['state_flags'];

      var undoStack = oneRowsData['undo_stack'];
      if (undoStack && undoStack.length > 0) {
        var topUndoItem = undoStack[undoStack.length-1];
        var label = topUndoItem[0];
        this.undoMenuItem_.removeClassName('disabled');
        this.undoMenuItem_.innerHTML = 'Undo '+label;
      }
      else {
        this.undoMenuItem_.addClassName('disabled');
        this.undoMenuItem_.innerHTML = 'Undo';
      }

      var editEnabled = stateFlags['editable'] ||
        !stateFlags['saved_row'] ||  stateFlags['deleted'];
      var enableFunction = editEnabled ? 'addClassName' : 'removeClassName';
      this.editMenuItem_[enableFunction]('disabled');

      if (stateFlags['deleted']) {
        this.deleteMenuItem_.addClassName('disabled');
        this.deleteMenuItem_.style.display = '';
        this.clearMenuItem_.style.display = 'none';
      }
      else if (stateFlags['saved_row']) {
        this.deleteMenuItem_.removeClassName('disabled');
        this.deleteMenuItem_.style.display = '';
        this.clearMenuItem_.style.display = 'none';
      }
      else {
        this.deleteMenuItem_.style.display = 'none';
        this.clearMenuItem_.style.display = '';
      }
      if (this.tableSpecificMenuItems_ !== null)
        this.setUpTableSpecificContextMenuOptions(stateFlags);
    }
  }, // end setUpContextMenu


  /**
   *  Sets this.menuRowSet_ and this.menuRowID_ for the new location of the
   *  menu.  Also highlights the selected row set.
   * @param domNode the DOM node that was clicked
   * @param setSelected optional flag to indicate whether or not the
   *  "selected_row" class should be applied to the fields in the row.
   *  Default value is true.  False is used when loading in recovered data.
   */
  initMenuLocation: function(domNode, setSelected) {
    if (setSelected === undefined)
      setSelected = true ;
    // Find the row in the table that contains the domNode.  Note that this
    // might not be the first ancestor of domNode that is a repeating line row,
    // because tables can be nested.
    // Note 2:  The domNode might be the row (if the td is hidden)!
    var rows = $(this.fieldGroupID_).down('tbody').childElements();
    var nodeRow = null;
    var nodeRowID = null;
    domNode = $(domNode);
    for (var rowIndex=0, max=rows.length; rowIndex<max && nodeRow === null;
         ++rowIndex) {
      var row = rows[rowIndex];
      if (domNode === row || domNode.descendantOf(row)) {
        nodeRowID = row.readAttribute('rowid');
        nodeRow = row;
      }
    }
    var rowSet = this.cetClass_.getRowSetForRow(nodeRow, nodeRowID);
    this.menuRowSet_ = rowSet;
    this.menuRowID_ = nodeRowID;

    var oneRowsData = this.rowData_[this.menuRowID_];
    if (!oneRowsData) {
      // Initialize it.
      oneRowsData = {};
      var stateFlags = {};
      oneRowsData['state_flags'] = stateFlags;
      var editable = !this.menuRowSet_[0].hasClassName('saved_row');
      stateFlags['editable'] = editable; // whether row is currenly editable
      if (!editable) {
        // then this is a previously saved row, which might be edited.
        stateFlags['saved_row'] = true;
      }
      stateFlags['deleted'] = false;
      this.rowData_[this.menuRowID_] = oneRowsData;
    }

    // Highlight the row set for the menu
    if (setSelected) {
      for (rowIndex=0, max=rowSet.length; rowIndex<max; ++rowIndex)
        rowSet[rowIndex].addClassName('selected_row');
    }
    return oneRowsData ;
  }, // end initMenuLocation


  /**
   *  Creates a menu item for the context menu.
   * @param label the menu item's text the user sees
   * @param functionName the name of the function to call.  (This should be
   *  a function on this instance of ControlledEditTable).  If this is null,
   *  no function will be assigned.
   * @return the menu item created
   */
  createMenuItem: function(label, functionName) {
    var baseItemID = this.fieldGroupID_ + '_' + label.replace(' ', '_');
    var itemID = baseItemID;
    // Allow for mutiple menu items with the same name.
    var labelCount = 1;
    while (this.menuItemIDToFunction_[itemID] !== undefined) {
      labelCount += 1;
      itemID = baseItemID + labelCount;
    }
    if (functionName) {
      this.menuItemIDToFunction_[itemID] =
        function() {
          if (!this.menuInUse_) {
            this.menuInUse_ = true;
            try {
              this[functionName]();
            }
            finally {
              this.menuInUse_ = false;
            }
          }
        }.bind(this);
    }
    return $J('<li id="'+itemID+'">'+label+"</li>")[0];
  },


  /**
   *  Creates a menu separator and returns it.
   */
  createMenuSeparator: function() {
    return $J('<li class="separator"></li>')[0];
  },


  /**
   *  Creates table-specific menu options to the right-click context menu.
   *  As in buildContextMenu, here we add all of the options to the menu,
   *  and later (in setUpTableSpecificContextMenuOptions) we will hide the ones
   *  we don't want.
   * @returns the options created.
   */
  createTableSpecificContextMenuOptions: function() {
    // The following code uses the field group's controlled_edit_menu
    // and controlled_edit_actions fields. 
    var extraMenuOptions = this.tableInfo_['controlled_edit_menu'];
    var rtn = [];
    if (extraMenuOptions) {
      this.tableSpecificSeparator_ = this.createMenuSeparator();
      rtn.push(this.tableSpecificSeparator_);
      this.tableSpecificMenuItems_ = [];
      for (var i=0, max=extraMenuOptions.length; i<max; ++i) {
        // For now, there is only format for the value.  That might change
        // in the future.
        var functionData = extraMenuOptions[i];
        var fieldCodeToMenuItemData = functionData[2];
        var menuItemDatas = [];
        for (var fieldCode in fieldCodeToMenuItemData)
          menuItemDatas.push(fieldCodeToMenuItemData[fieldCode]);
        menuItemDatas.push(functionData[3]); //the default case, not in the hash
        var menuItems = [];
        this.tableSpecificMenuItems_.push(menuItems);
        for (var j=0, maxJ=menuItemDatas.length; j<maxJ; ++j) {
          var menuItemData = menuItemDatas[j];
          var menuItemCode = menuItemData[1];
          var menuLabel = menuItemData[0];
          var menuItem = this.createMenuItem(menuLabel, null);
          this.menuItemIDToFunction_[menuItem.readAttribute('id')] =
               this.makeTableSpecificMenuItemHandler(menuLabel, menuItemCode);
          menuItems.push(menuItem);
          rtn.push(menuItem);
          if (j !== 0) // hide the alternate menu items
            menuItem.style.display = 'none';
        }
      }
    }
    return rtn;
  },


  /**
   *  Returns a menu item handler (function) for a table-specific menu item
   *  whose menu item label and code are as specified.  This is only used
   *  by addTableSpecificContextMenuOptions, but we're doing this
   *  here in a separate function so each copy of the returned function has
   *  its own copy of the parameters.
   * @param menuLabel the label of the menu item
   * @param menuItemCode the action code for the menu item's label
   */
  makeTableSpecificMenuItemHandler: function(menuLabel, menuItemCode) {
    var cet = this.cetClass_;
    return function() {
       if (!this.menuInUse_) {
         this.menuInUse_ = true;
         try {
           var actionData =
             this.tableInfo_['controlled_edit_actions'][menuItemCode];
           var functionArgs =
             [this, menuLabel].concat(actionData.slice(1));
           cet[actionData[0]].apply(cet, functionArgs);
         }
         finally {
           this.menuInUse_ = false;
           this.unhighlightRowSet();
         }
       }
     }.bind(this);
  },


  /**
   *  Sets up the table-specific menu options to the right-click context menu
   *  so that only the ones that should be active are visible.
   * @param stateFlags a hash of state flags for the row.
   */
  setUpTableSpecificContextMenuOptions: function(stateFlags) {
    // For now, I am only going to show table specific menu items if the
    // row is a saved row that is not deleted.  That is because at present all
    // such items are for changing the status field, and if the row is deleted
    // the user cannot change it.  We might need to revisit this
    // later.
    var i, j, menuItems;
    if (stateFlags['saved_row'] && !stateFlags['deleted']) {
      var extraMenuOptions = this.tableInfo_['controlled_edit_menu'];
      if (extraMenuOptions) {
        this.tableSpecificSeparator_.style.display = '';
        for (i=0, max=extraMenuOptions.length; i<max; ++i) {
          // Determine which menu option in the set of mutually exclusive
          // choices should be visible.
          var functionData = extraMenuOptions[i];
          var functionName = functionData[0];
          var cet = this.cetClass_;
          var functionArgs = [this].concat(functionData.slice(1));
          var menuItemData = cet[functionName].apply(cet, functionArgs);
          var visibleMenuLabel = menuItemData[0];
          // Now make this table-specific item visible and the others in the
          // set not visible.
          menuItems = this.tableSpecificMenuItems_[i];
          for (j=0, maxJ=menuItems.length; j<maxJ; ++j) {
            var menuItem = menuItems[j];
            var visible = menuItem.innerHTML == visibleMenuLabel;
            menuItem.style.display = visible ? '' : 'none';
          }
        }
      }
    }
    else {
      // In this case, hide all of the table-specific options.
      for (i=0, max=this.tableSpecificMenuItems_.length; i<max; ++i) {
        menuItems = this.tableSpecificMenuItems_[i];
        for (j=0, maxJ=menuItems.length; j<maxJ; ++j)
          menuItems[j].style.display = 'none';
      }
      this.tableSpecificSeparator_.style.display = 'none';
    }
  },


  /**
   *  Changes the cells of the current row set so that it contains form fields
   *  instead of static text fields.  (Assumes that the row set is currently not
   *  editable.)  Also runs the field initializers.  If the editableCells
   *  array is passed, the indicated fields will not be made read only (which
   *  otherwise will be done by default).
   * @param editableCells an array of booleans, one for each cell in the
   *  row set, that indicates whether the field should be made editable.  If
   *  this is null, no fields will be editable (except that the record ID
   *  field will be made into a real field).
   */
  makeRowSaveable: function(editableCells) {
    var modelRows = this.getEditableModelRows();
    var editableRows =
    Def.FieldsTable.createRowSets(modelRows, 1, parseInt(this.menuRowID_, 10));
    var editableTDs = this.cetClass_.getRowCells(editableRows);
    var rowIDrows = this.menuRowSet_;
    var rowIDTDs = this.cetClass_.getRowCells(rowIDrows);
    var oneRowsData = this.rowData_[this.menuRowID_];
    var originalCellHTML = [];
    oneRowsData['original_cell_html'] = originalCellHTML;
    oneRowsData['row_set_cells'] = rowIDTDs;
    var fieldIDToCellIndex = {};
    oneRowsData['field_id_to_cell_index'] = fieldIDToCellIndex;
    var recIDColIndex = this.getRecordIDColIndex();
    for (var i=0, max=rowIDTDs.length; i<max; ++i) {
      // Although theoretically we just need to change the cells that are
      // editable, for the sake of not complicating the save code we will
      // add editable versions of each cell, but will hide the editable version
      // for the cells the user shouldn't edit.

      // See if the field is a static_text field, and if so get its value
      var rowTD = rowIDTDs[i];
      // For the record_warning TD, iff the first child has style visibility i
      // set on the element, copy that.
      var isWarningCol = rowTD.hasClassName('record_warning');
      if (isWarningCol) {
        var tdChild = Element.down(rowTD);
        var firstChildVis = tdChild ? tdChild.style.visibility : '';
      }

      originalCellHTML.push(rowTD.innerHTML); // in case we need to restore
      var staticFieldList = rowTD.select('div.static_text, div.hidden_field');
      // Determine whether to make the cell read only after we turn it into
      // the editable version from the model row.  Don't mess with the first
      // cell, which is the record id.
      var makeReadOnly = i!=recIDColIndex &&
                        (!editableCells || !editableCells[i]);
      if (!makeReadOnly)
        rowTD.addClassName('cet_edit'); // for CSS

      // Collect the field values for this cell, and store by field ID
      var fieldVals = {};
      var field;
      for (var f=0, maxF=staticFieldList.length; f<maxF; ++f) {
        field = staticFieldList[f];
        fieldVals[field.id] = field.innerHTML;
        fieldIDToCellIndex[field.id] = i; // i = cell index
      }

      // Do our work inside a span node, and then give the span node to
      // rowTD, so that the user doesn't things incrementally appearing
      // and disappearing.
      var cellContents = document.createElement('SPAN');

      // This prototype method takes care of executing any scripts in the
      // html.
      var editableTD = editableTDs[i];
      Element.insert(cellContents, editableTD.innerHTML);
      Def.IDCache.addToCache(cellContents); // update the cache

      if (isWarningCol && firstChildVis != '')
        editableTD.down().style.visibility = firstChildVis;

      // Set field values and make some read only.
      for (var fieldID in fieldVals) {
        field = $(fieldID);
        var fieldVal = fieldVals[fieldID];
        Def.setFieldVal(field, htmlDecode(fieldVal), false);
        // Create the text node
        var textVal = document.createElement('SPAN');
        var readOnlyClass = 'readonly_field_val';
        textVal.setAttribute('class', readOnlyClass);
        textVal.innerHTML = fieldVal;
        var fieldContainer = this.getFieldContainerForHiding(field);
        field.fieldContainer = fieldContainer;
        fieldContainer.parentNode.insertBefore(textVal, fieldContainer);
        field.readOnlyNode = textVal;
        if (makeReadOnly)
          this.makeFieldReadOnly(field);
        else
          this.makeFieldEditable(field);
      }

      rowTD.innerHTML = '';
      rowTD.appendChild(cellContents);
    }
    this.initializeNewFields(rowIDrows);
    oneRowsData['state_flags']['saveable'] = true;
  },


  /**
   *  Returns the column index of the column containing the record id field.
   */
  getRecordIDColIndex: function() {
    if (this.recordIDColIndex_ === null) {
      var firstModelRow = this.getEditableModelRows()[0];

      var tds = firstModelRow.cells;
      var recIDSelector = '[id^=' + Def.FIELD_ID_PREFIX +
        this.recordIDTargetField_ + ']';
      for (var i=0, max=tds.length; i<max && !this.recordIDColIndex_; ++i) {
        var idFields = tds[i].down(recIDSelector);
        if (idFields)
          this.recordIDColIndex_ = i;
      }
    }
    return this.recordIDColIndex_;
  },


  /**
   *  Changes an input field into a read-only version.
   * @param field the editable version of the field (i.e. the actual form field,
   *  as opposed to the read-only display version).
   */
  makeFieldReadOnly: function(field) {
    // Hide the field and show a text node with the field's value.  We can't
    // just set the field's readonly attribute because events are still
    // processed.
    var readOnlyField = field.readOnlyNode;
    var editFieldContainer = field.fieldContainer;
    readOnlyField.innerHTML = Def.getFieldVal(field);
    readOnlyField.style.display = '';
    var editFieldStyle = editFieldContainer.style.display;
    if (editFieldStyle != 'none') {
      editFieldContainer.oldDisplay = editFieldStyle;
      editFieldContainer.style.display = 'none';
    }

    var td = this.findRowEditTextCell(field);
    if (td)
      Element.removeClassName(td, 'cet_edit');
  },


  /**
   *  Changes a field into its editable version.
   * @param field the editable version of the field (i.e. the actual form field,
   *  as opposed to the read-only display version).
   */
  makeFieldEditable: function(field) {
    field.readOnlyNode.style.display = 'none';
    var editFieldContainer = field.fieldContainer;
    // If makeFieldReadOnly has been called, reset the display on the editable
    // version.
    if (editFieldContainer.oldDisplay !== undefined)
      editFieldContainer.style.display = editFieldContainer.oldDisplay;

    // Try to add add "cet_edit" as a CSS class to the containing TD
    var td = this.findRowEditTextCell(field);
    if (td)
      Element.addClassName(td, 'cet_edit');
  },


  /**
   *  Returns the TD.rowEditText that contains the given field.  (This is to
   *  avoid the "up" method in prototype, which is very inefficient.)
   *  It returns null if none is found.  (We look for class rowEditText to
   *  skip past the table around date fields.)
   */
  findRowEditTextCell: function(field) {
    var rtn = null;
    var done = false;
    var checkNode = field;
    while (!done) {
      checkNode = checkNode.parentNode;
      if (checkNode === null) {
        done = true;
      }
      else if (checkNode.tagName == 'TD' &&
          Element.hasClassName(checkNode, 'rowEditText')) {
        rtn = checkNode;
        done = true;
      }
      else if (checkNode.tagName == 'TR' &&
          (Element.hasClassName(checkNode, 'repeatingLine') ||
           Element.hasClassName(checkNode, 'embeddedRow'))) {
        done = true;
      }
    }
    return rtn;
  },


  /**
   *  Returns true if the field is in the read only state.  This assumes that
   *  makeRowSaveable has already been called for the field's row.
   * @param field the editable version of the field (i.e. the actual form field,
   *  as opposed to the read-only display version).
   */
  isFieldReadOnly: function(field) {
    return field.readOnlyNode.style.display != 'none';
  },


  /**
   *  Returns the element containing the given field that should be hidden
   *  when the field needs to be hidden (e.g. when the row is being modified,
   *  but not all fields are available for editing.)  This in most cases
   *  is the field itself.
   * @param field the field whose containing element (for purposes of hiding)
   *  is needed.
   */
  getFieldContainerForHiding: function(field) {
    // If field is a date field, operate on its dateField container.
    // Avoid using prototype's "up" which can be slow.
    var dateTable = field.parentNode;
    for (;dateTable && dateTable.className!='dateField';
         dateTable = dateTable.parentNode);
    if (dateTable !== null)
      field = dateTable;
    return field;
  },


  /**
   *  Returns an array of the (editable) model rows for this table.
   *  This is cached, and subsequent calls return the cached rows.
   */
  getEditableModelRows: function() {
    if (!this.editableModelRows_) {
      this.editableModelRows_ =
        Def.FieldsTable.findModelRows($(this.fieldGroupID_).down('table'));
    }
    return this.editableModelRows_;
  },


  /**
   *  Returns the input fields from the given array of rows when imageTag is not
   *  true. Otherwise, adds image tag fields into the returned.
   *
   * @param rows the rows for which the fields will be found
   * @param imageTag a flag indicating whether the image tag fields should be
   * added into the returned.
   */
  getFields: function(rows, imageTag) {
    var fields = this.getFieldsFromElement(rows[0], imageTag);
    // Most of the time there will be just one row, so this is optimized for
    // that case.  (Note that "concat" returns a new array.)
    for (var i=1, max=rows.length; i<max; ++i)
      fields = fields.concat(
        this.getFieldsFromElement(rows[i], imageTag));
    return fields;
  },


  /**
   *  Returns the data-carrying form fields in the given DOM element when
   *  imageTag is not true. Otherwise, adds image tag fields into the returned.
   *  (It is assumed that the given element is not itself an input field.)
   *
   * @param elem the element to check for form fields.
   * @param imageTag a flag indicating whether the image tag fields should be
   * added into the returned.
   */
  getFieldsFromElement: function(elem, imageTag) {
    return imageTag != true ? $(elem).select('input', 'textarea') :
           $(elem).select('input', 'textarea', 'img');
  },


  /**
   *  Sets up the navigation code and other listeners for the new fields added
   *  by a change to a row (e.g. making it editable).
   * @param rows an array of table rows (probably sharing the same row ID)
   *  containing the new fields
   * @param navIndexData (optional) an array of two indices (the form index
   *  and the field index) that give the location of the first of the new
   *  input elements within the DOM element arrays.
   */
  initializeNewFields: function(rows, navIndexData) {
    if (!this.editableModelFields_)
      this.editableModelFields_ = this.getFields(this.getEditableModelRows());

    // We will use doNavKeys to set up the other field listeners (e.g.
    // navigation).  doNavKeys wants the index of the first field that needs to
    // be set up.
    var formIndex=0;
    var fieldIndex=0;
    if (navIndexData) {
      formIndex = navIndexData[0];
      fieldIndex = navIndexData[1];
    }
    var numRows = rows.length;
    var fields = this.getFields(rows);
    if (fields && fields.length>0) {
      var fieldJSSetUp = Def.FieldsTable.setUpFieldJS;
      var modelFields = this.editableModelFields_;

      var rules = Def.Rules;
      for (var i=0, max=fields.length; i<max; ++i) {
        var f = fields[i];
        var modelField = modelFields[i];
        fieldJSSetUp(f, modelField);
        if (modelField.autocomp) {
          // Initialize the autocompleter's item code, if possible.
          var codeField = Def.getFieldsCodeField(f);
          if (codeField)
            f.autocomp.itemCode_ = Def.getFieldVal(codeField);
        }

        // We need to run the rules too, even though the field value is
        // not changing, so that things that should be shown (e.g. info
        // buttons) get shown if they should be but have class initially_hidden.
        rules.runRules(f);
      }

      if (!navIndexData) {
        formIndex = 0; // works for now
        var elemArray = document.forms[0].elements;
        var firstFieldID = fields[0].id;
        for (fieldIndex=0, max=elemArray.length;
          firstFieldID!=elemArray[fieldIndex].id && fieldIndex<max;++fieldIndex);
        if (fieldIndex==max)
          fieldIndex=0;
      }
    }

    // Even if there were no new fields, we might still need to adjust the
    // navigation data (e.g. restoreRowSet was called).  Don't do this if
    // doNavKeys hasn't been run yet (e.g. in the case of autosave setup).
    if (Def.Navigation.formNavInitialized_)
      Def.Navigation.doNavKeys(formIndex, fieldIndex, true, true);
  },


  /**
   *  Saves data needed to undo a command.
   * @param cmdLabel a label for the command that would be undone.
   * @param tdEditStates a hash from indices into an array of row cells to booleans
   *  indicating whether the cell should be editable when the command is
   *  undone.
   * @param fieldVals a hash from field IDs to field values for fields whose
   *  values should be restored when the command is undone.
   */
  saveUndoData: function(cmdLabel, tdEditStates, fieldVals) {
    var oneRowsData = this.rowData_[this.menuRowID_];
    var undoStack = oneRowsData['undo_stack'];
    if (!undoStack) {
      undoStack = [[cmdLabel]];
      oneRowsData['undo_stack'] = undoStack;
      // For the first change, we do not need further information, because
      // when it is undone the row will be reverted back to an unsaveable state.
    }
    else {
      var undoData = [cmdLabel, tdEditStates, fieldVals,
        Object.clone(oneRowsData['state_flags'])];
      undoStack.push(undoData);
    }
  },


  /**
   *  Undoes the latest command, and asks for confirmation if the change
   *  to be undone means cancelling an edit of a saved row.  This is separate
   *  from undoLatestCommand because that gets tested automatically and
   *  we don't want pop-ups during the test.
   */
  undoOrConfirmCancelEdit: function() {
    var oneRowsData = this.rowData_[this.menuRowID_];
    var undoStack = oneRowsData['undo_stack'];
    var userChangedMind = false;
    if (undoStack && undoStack.length > 0) {
      var topUndoItem = undoStack[undoStack.length-1];
      var label = topUndoItem[0];
      if (label == this.cetClass_.MENU_LABEL_REVISE) {
        var answer = window.confirm('Discard changes to this row?');
        if (!answer)
          userChangedMind = true;
      }
    }
    if (!userChangedMind)
      this.undoLatestCommand();
  },


  /**
   *  Performs an "undo" of the latest command.
   */
  undoLatestCommand: function() {
    var oneRowsData = this.rowData_[this.menuRowID_];
    var undoStack = oneRowsData['undo_stack'];
    var rowSetCells = oneRowsData['row_set_cells'];
    if (undoStack && undoStack.length > 0) {
      // Remove the "deleted" style if present
      var undelete = false;
      if (oneRowsData['state_flags']['deleted']){
        this.removeRowSetClass('deleted');
        undelete = true;
      }

      this.hideActiveAutocompList();
      if (undoStack.length == 1) {
        // In this case, we revert the row back to the uneditable state.
        var oldFields = this.revertRow(this.menuRowID_, this.menuRowSet_)[0];
        // Disconnect the navigation code from the fields we just removed.
        this.cetClass_.disconnectFields(oldFields);
        // Run the change event listeners for the reverted fields.  First,
        // we need to get the data model consistent, or the change event
        // listeners (which may read the data model) might behave incorrectly.
        var changedFields = [];
        var revertedField;
        for (var i=0, max=oldFields.length; i<max; ++i) {
          revertedField = $(oldFields[i].id);
          var revertedVal = Def.getFieldVal(revertedField) ;
          var oldVal = Def.getFieldVal(oldFields[i]) ;
          if (revertedVal != oldVal) {
            Def.DataModel.updateModelForField(revertedField);
            changedFields.push(revertedField);
          }
        }
        for (i=0, max=changedFields.length; i<max; ++i) {
          revertedField = changedFields[i];
          Def.FieldEvents.runChangeEventObservers(revertedField);
          if (undelete)
            Def.FieldEvents.runEventObservers([revertedField],"undelete");
        }
      }
      else {
        // Use the undo data to undo the last command.
        // First, restore cells to their previous editable/non-editable state.
        var undoData = undoStack.pop();
        var cellEditStates = undoData[1];
        var fieldVals = undoData[2];
        var fieldsToUpdate = [];
        var fieldValsForUpdate = [];
        var fieldVal, field;
        for (var cellIndex in cellEditStates) {
          var editable = cellEditStates[cellIndex];
          var cellFields = this.getFieldsFromElement(rowSetCells[cellIndex]);
          // For each cell field, set its editable state to editable
          for (var fieldIndex=0, maxInd=cellFields.length; fieldIndex<maxInd;
               ++fieldIndex) {
            field = cellFields[fieldIndex];
            fieldVal = fieldVals[field.id];
            delete fieldVals[field.id];
            if (fieldVal !== undefined) {
              fieldsToUpdate.push(field);
              fieldValsForUpdate.push(fieldVal);
            }
            if (editable)
              this.makeFieldEditable(field);
            else {
              this.makeFieldReadOnly(field);
              if (fieldVal !== undefined) {
                var readOnlyField = field.readOnlyNode;
                readOnlyField.innerHTML = fieldVal;
              }
            }
            if(undelete)
              Def.FieldEvents.runEventObservers([$(field.id)],"undelete");
          }
        } // for each cell that changed its state

        // Now restore any other field values.
        for (var fieldID in fieldVals) {
          fieldVal = fieldVals[fieldID];
          field = $(fieldID);
          fieldsToUpdate.push(field);
          fieldValsForUpdate.push(fieldVal);
          if (field.readOnlyNode)
            field.readOnlyNode.innerHTML = fieldVal;
        }

        Def.setFieldVals(fieldsToUpdate, fieldValsForUpdate);

        // Now restore the state flags
        oneRowsData['state_flags'] = undoData[3];
      } // if this is not the final undo
    } // if we have undo info
  },


  /**
   *  Hides the currently active autocompletion list, if any.  Also removes
   *  the navigation code's knowledge of focus on the field.
   */
  hideActiveAutocompList: function() {
    // If one of the fields is the currently focused field, and has an
    // autocompleter, make sure the autocompletion list is hidden.
    var nav = Def.Navigation;
    var focusedField = nav.focusedField_;
    if (focusedField) {
      focusedField = $(focusedField);
      // If the field has an autocompleter, hide it.  It might be showing.
      if (focusedField.autocomp)
        focusedField.autocomp.hide();
      // Also clear focusedField_, so we don't later think this is
      // focused.
      nav.focusedField_ = null;
    }
  },


  /**
   *  Removes the highlight from the selected row set.
   */
  unhighlightRowSet: function() {
    this.removeRowSetClass('selected_row');
  },


  /**
   *  Removes the given CSS class from the current row set.
   * @param cssClass the name of the CSS class to remove
   */
  removeRowSetClass: function(cssClass) {
    for (var rowIndex=0, max=this.menuRowSet_.length; rowIndex<max; ++rowIndex)
      this.menuRowSet_[rowIndex].removeClassName(cssClass);
  },


  /**
   *  Adds the given CSS class to the current row set.
   * @param cssClass the name of the CSS class to remove
   */
  addRowSetClass: function(cssClass) {
    for (var rowIndex=0, max=this.menuRowSet_.length; rowIndex<max; ++rowIndex)
      this.menuRowSet_[rowIndex].addClassName(cssClass);
  },


 /**
   *  This is used after a form is saved to make changed rows return to
   *  a saved state.  This removes the editable fields from the row and
   *  replaces them with DIVs.
   * @param rowIDs the row IDs of the rows that were updated.  This array
   *  should contain at least one row ID, and the rowIDs should be in order.
   * @return the fields (DOM elements) that were removed by this method, in the
   *  order they were on the form.
   */
  putUpdatedRowsIntoSavedState: function(rowIDs) {
    var oldFields = [];
    for (var i=0, max=rowIDs.length; i<max; ++i) {
      var rowID = rowIDs[i];
      var rowSet = this.getRowSetForRowID(rowID);
      var fieldData = this.revertRow(rowID, rowSet);
      if (fieldData === null) {
        Def.reportError(new Error('revertRow failed for '+this.fieldGroupID_+
          ' row '+rowID));
      }
      else {
        var rowSetOldFields = fieldData[0];
        var rowSetFieldVals = fieldData[1];
        oldFields.push(rowSetOldFields);
        // Now assign the values in the old fields to the divs that replaced them.
        for (var j=0, num=rowSetOldFields.length; j<num; ++j) {
          var field = rowSetOldFields[j];
          Def.setFieldVal($(field.id), rowSetFieldVals[field.id], false);
        }
      }
    }
    return oldFields.flatten();
  },


 /**
   *  This is used after a form is saved to make new rows change to
   *  a saved state.  This removes the editable fields from the row and
   *  replaces them with DIVs.
   * @param rowIDs the row IDs of the rows that were updated.  This array
   *  should contain at least one row ID, and the IDs should be in order.
   * @return the fields (DOM elements) that were removed by this method, in
   *  the order they were on the form.
   */
  putNewRowsIntoSavedState: function(rowIDs) {
    // We cannot make an assumption that the new rows being saved are together
    // at the bottom of the table, with only the blank row following them.
    // There could be blank rows inbetween, as well.  We also have to do this
    // in a way that does not change the order or number of the rows, because
    // after this method returns we need to removed certain rows.
    var table = $(this.fieldGroupID_).down('table');
    var tbody = table.tBodies.item(0);
    var oldFields = [];
    var j;
    for (var i=0, num=rowIDs.length; i<num; ++i) {
      var rowID = rowIDs[i];
      var rowSet = this.getRowSetForRowID(rowID);
      oldFields.push(this.getFields(rowSet, true));
      var savedRowHTML = this.buildReadOnlyRowHTML(table, rowID, 1);
      var savedRowNodes = this.parseRowHTML(savedRowHTML);
      for (j=0, rowSetSize=rowSet.length; j<rowSetSize; ++j) {
        var row = rowSet[j];
        var savedRowNode = savedRowNodes[0]; // insertBefore removes the item each time
        tbody.insertBefore(savedRowNode, row);
        row.addClassName('saved_row');
        Def.IDCache.addToCache(savedRowNode);
        tbody.removeChild(row);
      }

      // Drop all data about this row.
      delete this.rowData_[rowID];
    }
    oldFields = oldFields.flatten();

    // Now assign the values in oldFields to the divs that replaced them.
    var oldFieldsWithoutImgs = []; // the caller only wants navigable fields returned
    for (j=0, num=oldFields.length; j<num; ++j) {
      var field = oldFields[j];
      if (field.tagName != 'IMG') {
        Def.setFieldVal($(field.id), Def.getFieldVal(field), false);
        oldFieldsWithoutImgs.push(field);
      }
      else {
        // If the img has visiblity set on the element, copy that.
        var vis = field.style.visibility;
        if (vis != '')
          $(field.id).style.visibility = vis;
      }
    }
    return oldFieldsWithoutImgs;
  },


  /**
   * Returns list of form fields which could be affected by form rules. The
   * returning fields are the fields with tag name of input, textarea or img
   *
   * @param rowIDs list of row ids
   **/
  getAffectedFields: function(rowIDs) {
    var fields = [];
    for(var i=0, max= rowIDs.length; i<max; i++){
      var rowID = rowIDs[i];
      var rowSet = this.getRowSetForRowID(rowID);
      fields.push(this.getFields(rowSet, true));
    }
    return fields.flatten();
  },


  /**
   *  This method is used after a form is saved to clean up deleted rows
   *  corresponding to the given row IDs.
   * @param tableName the name of the data table in the data model
   * @param rowIDs the row IDs of the rows that were updated.  This array
   *  should contain at least one row ID, and the row IDs should be in
   *  reverse sorted order.
   * @return the fields (DOM elements) from the deleted rows, or the order
   *  that they were on the form.
   */
  cleanUpDeletedRows: function(tableName, rowIDs) {
    var oldFields = [];
    for(var j=rowIDs.length-1; j>=0; --j) {
      var rowID = rowIDs[j];

      // Delete the rows from the table
      var rowSet = this.getRowSetForRowID(rowID);
      oldFields.push(this.getFields(rowSet));
      for (var i=0, numRows=rowSet.length; i<numRows; ++i) {
        var row = rowSet[i];
        row.parentNode.removeChild(row);
      }
    } // end of loop of deleted records
    // Notify the conflict checker of the deletions but do that in a timeout
    // to give the data model a chance to update.
    setTimeout(function() {this.conflictChecker_.recalculate();}.bind(this), 1);
    return oldFields.flatten();
  },


  /**
   *  Reverts a previously saved row back to its initial state.  This only
   *  affects the controlled edit table structures and the HTML on the form.
   *  It does not handle updating the navigation code or running change event
   *  observers.
   *
   * @param rowID the row ID of the row to be reverted
   * @param rowSet the set of rows with that row ID.  In the case of embedded
   *  rows, a there will be more than one.
   * @return an array of the fields in the row, and a hash from field IDs to
   *  field values.  We used to just use the fields for the value, but in IE 9,
   *  once an element is removed from the page the child nodes are lost, which
   *  for a textarea element means its value is lost.  This can also return
   *  null, which indicates there was nothing to revert for this row; i.e.,
   *  the table thinks the row was not in an editable state, and has no
   *  information about it.  This is an error condition, but it seems that
   *  sometimes the server gives us information that a row was updated
   *  when it wasn't.  The only harm to the user at present is that they
   *  get a warning about their data not being saved, which actually it has been.
   */
  revertRow: function(rowID, rowSet) {
    var rtn = null;
    var oneRowsData = this.rowData_[rowID];
    if (oneRowsData !== undefined) {
      var rowSetCells = oneRowsData['row_set_cells'];
      var oldFields = this.getFields(rowSet);
      var oldFieldVals = {};
      for (var i=0, max=oldFields.length; i<max; ++i) {
        var f = oldFields[i];
        oldFieldVals[f.id] = Def.getFieldVal(f); // getFieldVal handles field hints
      }
      var originalCellHTML = oneRowsData['original_cell_html'];
      for (i=0, max=rowSetCells.length; i<max; ++i) {
        var td = rowSetCells[i];
        td.innerHTML = originalCellHTML[i];
        // If the cell has "cet_edit" on it, remove it.  The intial state does
        // not have that class.
        td.removeClassName('cet_edit');
        Def.IDCache.addToCache(td);
      }

      // Drop all data about this row.  We could save it in case the
      // user edits it again, but that complicates makeRowSaveable.
      delete this.rowData_[rowID];

      rtn = [oldFields, oldFieldVals];
    }
    return rtn;
  },


  /**
   *  Returns the row set (array of rows) for the given row ID.
   * @param rowID the rowID attribute of the rows.
   */
  getRowSetForRowID: function(rowID) {
    var rows = $(this.fieldGroupID_).down('tbody').childElements();
    var rowSet = [];
    var foundAll = false;
    for (var rowIndex=0, numRows=rows.length; rowIndex<numRows && !foundAll;
         ++rowIndex) {
      var row = rows[rowIndex];
      if (rowID == row.readAttribute('rowid')) {
        rowSet.push(row);
      }
      else if (rowSet.length > 0) {
        foundAll = true;
      }
    }
    return rowSet;
  },


  /**
   *  Puts up a dialog box if the user clicks on a saved row, but only
   *  once per page load.
   * @param event the event object
   */
  helpOnLeftClick: function(event) {
    // Only do this once.
    if (!Def.FieldsTable.ControlledEditTable.leftClickHelpShown_) {
      var elem = Event.element(event);
      // Do nothing if the element was an image (which we use as buttons)
      if (elem.tagName != 'IMG') {
        var td = elem;
        if (td.tagName != 'TD')
          td = elem.up('td');
        // Do nothing if the td is for one of the standard button columns.
        // The user might have been trying to click on the button.
        if (td && !td.hasClassName('info_button') && !td.hasClassName('record_warning')) {
          var row = td.up('tr.repeatingLine.saved_row,tr.embeddedRow.saved_row');
          if (row) {
            var rowid = row.readAttribute('rowid');
            // See if this row has had the menu used before.  If it is has, don't show
            // the alert; the user already knows how to get to the menu.
            if (!this.rowData_[this.menuRowID_]) {
              Def.FieldsTable.ControlledEditTable.leftClickHelpShown_ = true;
              var dialog = new Def.NoticeDialog({'title': 'Edit Help'});
              dialog.setContent('To edit a saved row, use right-click or the '+
                'row\'s menu icon to access a menu of edit options.');
              dialog.show();
            }
          }
        }
      }
    }
  },


  /**
   *  An onchange event listener which checks to see if the row is blank
   *  and hides the row if it is.
   * @param event the change event prompting the check
   */
  removeRowIfBlank: function(event) {
    var elem = event.element();
    if (Def.getFieldVal(elem) === '') {
      // Check other field values in the row set.  The row might be
      // of class repeatingLine or embeddedRow.
      var row = elem.up('tr.repeatingLine,tr.embeddedRow');
      // Only do this if the row has not already been removed
      if (row && !row.hasClassName('removed')) {
        var rowID = row.readAttribute('rowID');
        // Don't remove if this is the last row in the table
        var tableRows = row.up('tbody').rows;
        var lastRowID = tableRows.item(tableRows.length-1).readAttribute('rowID');
        if (rowID != lastRowID) {
          var rowSet = this.getRowSetForRowID(rowID);
          var fields = this.getFields(rowSet);
          // If the fields array is empty, the row is probably returning to
          // a previously saved state.  (I can't think of any other cases.)
          // In that case, we definitely do not want to remove the row.
          if (fields.length !== 0) {
            var blank = true;
            for (var i=0, len=fields.length; blank && i<len; ++i) {
              var f = fields[i];
              if (f != elem && Def.getFieldVal(f) !== '')
                blank = false;
            }
            if (blank) {
              for (i=0, len=rowSet.length; i<len; ++i) {
                row = rowSet[i];
                // row.parentNode.removeChild(row);
                // We used to remove the row.  This caused serious problems for
                // the autosave code which relies on row numbers, and might have
                // caused problems for the save code too.
                row.addClassName('removed');
              }
              Def.DataModel.markFieldRowAsRemoved(fields[0]) ;
              // this.cetClass_.disconnectFields(fields);
              // It is no longer necessary to disconnect the fields because
              // the elements are not actually getting removed from the form.
            }
          }
        }
      }
    }
  }
};
Def.FieldsTable.ControlledEditTable.addMethods(instanceMembers);
