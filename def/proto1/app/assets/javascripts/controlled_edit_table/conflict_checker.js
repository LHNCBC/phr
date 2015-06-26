/**
 *   A module for checking for conflicts between rows of a controlled edit
 *   table, and warning the user as needed.  This is the default conflict
 *   checker.  It does not have any table-speficic state, so it is not defined
 *   as a class.
 */
Def.FieldsTable.ControlledEditTable.ConflictChecker = {
  /**
   *  A dialog for showing warnings.
   */
  warningDialog_: null,

  /**
   *  Returns true if the warning dialog is open.
   */
  dialogIsOpen: function() {
    return this.warningDialog_ && this.warningDialog_.isOpen();
  },


  /**
   *  Warns the user if the given field has duplicates within its table.
   * @param field the DOM field that changed, triggering the need for a check.
   * @param codeField the field for the code corresponding to "field" (if such
   *  a thing exists).  If this is not null, this is the field that will be
   *  checked for duplicates.
   */
  warnAboutDuplicates: function(field, codeField) {
    var dupVal = this.checkForDuplicates(field, codeField);
    if (dupVal) {
      // This message is also in basic/_dup_warnings_section.html.erb.  If you
      // change this, also update the message there.
      var msg = 'You have more than one record for ' + htmlEncode(dupVal) +
        '.\nThat is allowed, but these tables are really intended to be '+
        '\nprofiles rather than histories.';
      this.showWarning(field, msg, 'Duplicate Record Warning');
    }
  },


  /**
   *  Opens a pop-up for showing a warning message about conflicts.
   * @param anchor a field on the window to use as a basis for positioning
   *  the pop-up.
   * @param text the text of the message
   * @param title the title for the window
   */
  showWarning: function(anchor, text, title) {
    // Get or construct the warning dialog
    if (!this.warningDialog_) {
      this.warningDialog_ = new Def.NoticeDialog({
        width: 300
      });
    }
    this.warningDialog_.setTitle(title);
    this.warningDialog_.setContent(text);
    this.warningDialog_.show();
    Def.FieldsTable.ControlledEditTable.notifyObservers(anchor, 'DUPLICATE', {data: title + "\n" + text});
  },


  /**
   *  Checks whether the given field has duplicates within its table.
   * @param field the DOM field that changed, triggering the need for a check.
   * @param codeField the field for the code corresponding to "field" (if such
   *  a thing exists).  If this is not null, this is the field that will be
   *  checked for duplicates.
   * @param extraCond Extra conditions (a hash in the taffy DB condition format)
   *  on a record's fields for it to be considered in the check for duplicates.
   * @return the value of field if there is a duplicate, or null if there
   *  is not.
   */
  checkForDuplicates: function(field, codeField, extraCond) {
    var taffyLoc = Def.DataModel.getModelLocation(field.id);
    var field_tf = taffyLoc[1];
    var conditions = extraCond ? Object.clone(extraCond) : {};
    var checkFieldVal = '';
    // Use the code field if there is one and if it has a value
    if (codeField) {
        checkFieldVal =
          Def.DataModel.getModelFieldValue(taffyLoc[0], codeField, taffyLoc[2]);
      if (checkFieldVal !== '')
        conditions[codeField] = checkFieldVal;
    }
    if (checkFieldVal === '' || checkFieldVal === null) {
      conditions[field_tf] =
        Def.DataModel.getModelFieldValue(taffyLoc[0], field_tf, taffyLoc[2]);
    }

    var likeRecords = Def.DataModel.searchRecord(taffyLoc[0],
      [{'conditions': conditions}]);

    return likeRecords.size() > 1 ? likeRecords[0][field_tf] : null;
  },


  /**
   *  Clears all conflicts with the given row ID (which has just been cleared).
   * @param rowID the ID of the row that was cleared.
   */
  removeConflictsWithRow: function(rowID) {
    // For most tables, we don't indicate row conflicts, so there is nothing
    // to do for this default checker.
  },


  /**
   *  Called when internally stored state might be invalid (e.g. after a save
   *  where rows were deleted).
   */
  recalculate: function() {
    // This default checker does not store state, so there is nothing to do.
  },


  /**
   *  Called when a record data requester has populated fields in the table.
   *  This checks to see if there are conflicts.
   * @param field the field that changed, triggering the need for a check.
   */
  postRDRAssignmentCheck: function(field) {
    // The default checker does not know what should be done if there is a
  }

};
