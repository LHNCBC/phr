/**
 *  A special-purpose replacement of ConflictChecker for the drugs table.
 */
Def.FieldsTable.ControlledEditTable.DrugConflictChecker = Class.create({
  /**
   *  Constructor.
   */
  initialize: function() {
    // A hashmap from data model row indices to other row indices containing drugs that
    // conflict.
    this.drugIndexToConflicts_ = {};

    // A reference to the class
    this.dccClass_ = Def.FieldsTable.ControlledEditTable.DrugConflictChecker;
  },


  /**
   *  A check that is run when the user enters a new drug name.  If a potential
   *  problem is detected, a pop-up with a warning message will be displayed.
   * @param field the field that changed, triggering the need for a check.
   */
  newDrugEntryCheck: function(field) {
    // If field.autocomp.matchStatus_ is false, run the check right away.
    // Otherwise, we need to wait not only for the record data requester to finish,
    // but for the event notifications for RDR assignment to finish so that the data
    // model is updated.  These event notifications are also asynchronous -- the
    // RDR notifyObservers call returns before they are run.  However, in
    // def_autocomp.js, there is an observer set up (see the call to
    // observerRDRAssignment) which will call postRDRAssignmentCheck() on the
    // conflict checker after the fields are updated.  (That call only happens
    // if there were fields updated, which is why when matchStatus_ is false,
    // we have to do the warning here.)
    this.warnIfDrugConflicts(field, 'just entered', true);
  },


  /**
   *  Called when a record data requester has populated fields in the table.
   *  This checks to see if there are conflicts.
   * @param field the field that changed, triggering the need for a check.
   */
  postRDRAssignmentCheck: function(field) {
    this.warnIfDrugConflicts(field, 'just entered', true);
  },


  /**
   *  A check that is run when the user changes the status of a record.
   *  If a potential
   *  problem is detected, a pop-up with a warning message will be displayed.
   * @param field the field that changed, triggering the need for a check.
   *  This would either be the same as checkField or displayField (except that
   *  this parameter is the DOM node, while the other two are target field
   *  names.)
   * @param codeField the field for the code corresponding to "field" (if such
   *  a thing exists).
   */
  drugMadeActiveCheck: function(field, codeField) {
    var rowNum = Def.DataModel.getModelLocation(field.id)[2];
    var val =
      Def.DataModel.getModelFieldValue('phr_drugs', 'drug_use_status_C', rowNum);
    // This will run for unsaved records too, because the user should see the
    // status warning icons update if they change the status, and they should
    // get the warning message again if they change the status from active
    // to stopped to active again.
    // However, we want to stop this running if we are here for a row in which
    // the user has just entered a new conflicting drug.  In that case,
    // newDrugEntryCheck will have run and the warning dialog will already be
    // up.  So, if the dialog is up, skip this check.
    if (!Def.FieldsTable.ControlledEditTable.ConflictChecker.dialogIsOpen())
      this.warnIfDrugConflicts(field, 'made active', true);
  },


  /**
   *  Shows the warning dialog when the user clicks on the warning icon
   *  next to a drug.
   * @param iconID The ID of the warning icon field
   */
  drugWarningIconClicked: function(iconID) {
    var idParts = Def.IDCache.splitFullFieldID(iconID);
    var nameField = $(idParts[0] + 'name_and_route' + idParts[2]);
    this.warnIfDrugConflicts(nameField, 'have');
  },


  /**
   *  Warns the user via a pop-up if any potential conflicts are detected between
   *  the row containing "field" and other rows in the drugs table.
   * @param field the field that changed, triggering the need for a check.
   * @param actionDesc a string like 'just entered' or 'made active' which
   *  describes what the user did (and can be inserted into a sentence like
   *  "the drug which you [just entered] is the same as...."
   * @param updateWarningIcons (false by default) if true the record warning
   *  icons will be updated after the conflicts are found.
   */
  warnIfDrugConflicts: function(field, actionDesc, updateWarningIcons) {
    var rowNum = Def.DataModel.getModelLocation(field.id)[2];
    var rowIndex = rowNum - 1;
    var drugRows = Def.DataModel.data_table_['phr_drugs'];
    var rowData = drugRows[rowIndex];
    // Note:  This logic has been ported to the server side (for the basic HTML
    // mode), so if you change something here, you will likely also need to
    // revise phr_drugs/_dup_warnings.html.erb.
    var conflictData = this.drugConflictCheck(drugRows, rowIndex);
    if (conflictData) {
      var nameRouteDuplicates = conflictData[0];
      var drugRouteDuplicates = conflictData[1];
      var equivalentRouteMatches = conflictData[2];
      var sharedIngredientMatches = conflictData[3];
      var msg = '';
      if (nameRouteDuplicates.length > 0) {
        // Determine whether this drug's ingredients contain one of the special
        // ingredients that require a different message.
        var ingredientCodes = Def.parseSetValue(rowData['drug_ingredients_C']);
        var numIngredients = ingredientCodes.length;
        var hasSpecial = false;
        for (var i=0; i<numIngredients && !hasSpecial; ++i) {
          if (Def.DUP_DRUG_SPECIAL_INGREDIENTS[ingredientCodes[i]])
            hasSpecial = true;
        }
        if (hasSpecial) {
          msg = this.generateDrugNameRouteSpecialDupMsg(nameRouteDuplicates,
            drugRows, rowNum, actionDesc);
        }
        else {
          msg = this.generateDrugNameRouteDupMsg(nameRouteDuplicates,
            drugRows, rowNum, actionDesc);
        }
      }
      if (drugRouteDuplicates.length > 0) {
        msg += this.generateDrugEquivRouteDupMsg(drugRouteDuplicates,
            drugRows, rowNum, actionDesc);
      }
      if (equivalentRouteMatches.length > 0) {
        msg += this.generateDrugEquivRouteEquivMsg(equivalentRouteMatches,
            drugRows, rowNum, actionDesc);
      }
      var max;
      for (i=0, max=sharedIngredientMatches.length; i<max; ++i) {
        var match = sharedIngredientMatches[i];
        msg += this.generateDrugSharedIngredMsg(match[0], match[1], drugRows,
          rowNum, actionDesc);
      }
      if (msg) {
        Def.FieldsTable.ControlledEditTable.ConflictChecker.showWarning(
          field, msg, "Drug Warnings");
      }
    }
    if (updateWarningIcons)
      this.updateDrugWarningIconState();
  },


  /**
   *  Updates the visibilty of the drug warning icons, based on the conflict checking
   *  previously done.
   */
  updateDrugWarningIconState: function() {
    for (var i=0, len=Def.DataModel.data_table_.phr_drugs.length; i<len; ++i) {
      var conflictsForI = this.drugIndexToConflicts_[i];
      var hasConflicts = false;
      for (var j in conflictsForI) {
        hasConflicts = true;
        break;
      }
      // Find the prefix and (especially) the suffix for the warning icon via the
      // name_and_route field.
      var nameAndRouteID = Def.DataModel.getFormFieldId('phr_drugs', 'name_and_route', i+1);
      var idParts = Def.IDCache.splitFullFieldID(nameAndRouteID);
      var warningIcon = $(idParts[0] + 'warnings' + idParts[2]);
      warningIcon.style.visibility = hasConflicts ? 'visible' : ''; // hidden by class
    }
  },


  /**
   *  Given a row number into the data models rows, return the corresponding
   *  row number shown in the form table rows.
   */
  formRowFromModelRow: function(modelRow) {
    var nrField = Def.DataModel.getFormField('phr_drugs', 'name_and_route', modelRow);
    var suffix = Def.IDCache.splitFullFieldID(nrField.id)[2];
    return $(Def.FIELD_ID_PREFIX + 'drugs_row_id'+suffix).textContent;
  },


  /**
   *  Generates a message about duplicate drug entries (exact same name and route)
   *  for the case where the drug has a special ingredient for which multiple
   *  prescriptions might sometimes be given.
   * @param nameRouteDuplicates an array of drug row
   *  indices whose name and route is exactly the same as the rowIndex entry
   * @param drugRows the data model's data for thr phr_drugs table
   * @param rowNum the row number in drugRows of the drug which is the subject
   *  of the warning.
   * @param actionDesc a string like 'just entered' or 'made active' which
   *  describes what the user did (and can be inserted into a sentence like
   *  "the drug which you [just entered] is the same as...."
   * @return the warning message
   */
  generateDrugNameRouteSpecialDupMsg: function(nameRouteDuplicates, drugRows, rowNum, actionDesc) {
    var msg = '<p><b>Warning: Duplicate active medications</b><br>';
    var templates = this.dccClass_.DrugWarningTemplates;
    if (!templates.drugNameRouteSpecialDupMsgSingle_) {
      // Note:  If you change these messages, you should also update the
      // equivalent messages in phr_drugs/_dup_warnings.html.erb.
      templates.drugNameRouteSpecialDupMsgSingle_ = new Template(
        'The medication you #{actionDesc} in row #{rowNum}'+
        ' is the same as the other entry for "#{conflictDrug}" '+
        '(row #{conflictRow}).  Unless the prescribing doctor told you to '+
        'take both medications at the same time (e.g. different doses on'+
        ' different days of the week), you should either mark one as ' +
        ' "Stopped", or delete or clear one (after making sure the correct ' +
        'information for this drug is entered in the remaining row).  '+
        'If you are not sure if one or both of these '+
        'prescriptions should be taken, please call your physician.'
      );
      templates.drugNameRouteSpecialDupMsgMultiple_ = new Template(
        'The medication you #{actionDesc} in row #{rowNum}'+
        ' is the same as the other entries for "#{rowDrug}" (rows '+
        '#{conflictRows}).  Unless the prescribing doctor told you to '+
        'take these medications at the same time (e.g. different doses on'+
        ' different days of the week), you should either mark all but one as ' +
        ' "Stopped", or delete or clear them (after making sure the correct ' +
        'information for this drug is entered in the remaining row).  ' +
        'If you are not sure if one or all of these '+
        'prescriptions should be taken, please call your physician.'
      );
    }
    msg += this.generateDrugWarningMsg(templates.drugNameRouteSpecialDupMsgSingle_,
       templates.drugNameRouteSpecialDupMsgMultiple_,
       nameRouteDuplicates, drugRows, rowNum, actionDesc);
    return msg;
  },


  /**
   *  Generates a message about duplicate drug entries (exact same name and route)
   *  for the case where the drug does NOT has a special ingredient for which
   *  multiple prescriptions might sometimes be given.
   * @param nameRouteDuplicates an array of drug row
   *  indices whose name and route is exactly the same as the rowIndex entry
   * @param drugRows the data model's data for thr phr_drugs table
   * @param rowNum the row number in drugRows of the drug which is the subject
   *  of the warning.
   * @param actionDesc a string like 'just entered' or 'made active' which
   *  describes what the user did (and can be inserted into a sentence like
   *  "the drug which you [just entered] is the same as...."
   * @return the warning message
   */
  generateDrugNameRouteDupMsg: function(nameRouteDuplicates, drugRows, rowNum, actionDesc) {
    var msg = '<p><b>Warning: Duplicate active medications</b><br>';
    var templates = this.dccClass_.DrugWarningTemplates;
    if (!templates.drugNameRouteDupMsgSingle_) {
      // Note:  If you change these messages, you should also update the
      // equivalent messages in phr_drugs/_dup_warnings.html.erb.
      var single = 'The medication you #{actionDesc} in row #{rowNum} is the '+
        'same as the other entry for "#{conflictDrug}" (row #{conflictRow}).  '+
        'You should either mark one as "Stopped", or delete or clear one '
      var any = '(after making sure the correct information for this drug is '+
        'entered in the remaining row).  If you are not sure which of these '+
        'prescriptions should be taken, please call your physician.'
      single += any;
      var multi = 'The medication you #{actionDesc} in row #{rowNum} is the '+
        'same as the other entries for "#{rowDrug}" (rows #{conflictRows}).  '+
        'You should either mark all but one as "Stopped", or delete or clear '+
        'them ' + any;
      templates.drugNameRouteDupMsgSingle_ = new Template(single);
      templates.drugNameRouteDupMsgMultiple_ = new Template(multi);
    }
    msg += this.generateDrugWarningMsg(templates.drugNameRouteDupMsgSingle_,
      templates.drugNameRouteDupMsgMultiple_,
      nameRouteDuplicates, drugRows, rowNum, actionDesc);
    return msg;
  },


  /**
   *  Generates a message about drugs that are equivalent to the entered/revised
   *  drug and whose route is an exact match.
   * @param drugRouteDuplicates an array of drug row
   *  indices for drugs that are equivalent to the entered/revised
   *  drug and whose route is an exact match.
   * @param drugRows the data model's data for thr phr_drugs table
   * @param rowNum the row number in drugRows of the drug which is the subject
   *  of the warning.
   * @param actionDesc a string like 'just entered' or 'made active' which
   *  describes what the user did (and can be inserted into a sentence like
   *  "the drug which you [just entered] is the same as...."
   * @return the warning message
   */
  generateDrugEquivRouteDupMsg: function(drugRouteDuplicates, drugRows, rowNum, actionDesc) {
    var msg = '<p><b>Warning: Duplicate active medications, different name</b><br>';
    var templates = this.dccClass_.DrugWarningTemplates;
    if (!templates.drugEquivRouteDupMsgSingle_) {
      // Note:  If you change these messages, you should also update the
      // equivalent messages in phr_drugs/_dup_warnings.html.erb.
      var single = 'The medication you #{actionDesc} in row #{rowNum} is the '+
        'same as the entry for "#{conflictDrug}" (row #{conflictRow}), only '+
        'with a different generic or brand name.' +
        'You should either mark one as "Stopped", or delete or clear one '
      var any = '(after making sure the correct information for this drug is '+
        'entered in the remaining row).  If you are not sure which of these '+
        'prescriptions should be taken, please call your physician.'
      single += any;
      var multi = 'The medication you #{actionDesc} in row #{rowNum} is the '+
        'same as the entries for #{conflictRowsAndDrugs}, only with a '+
        'different generic or brand name.  '+
        'You should either mark all but one as "Stopped", or delete or clear '+
        'them ' + any;
      templates.drugEquivRouteDupMsgSingle_ = new Template(single);
      templates.drugEquivRouteDupMsgMultiple_ = new Template(multi);
    }
    msg += this.generateDrugWarningMsg(templates.drugEquivRouteDupMsgSingle_,
      templates.drugEquivRouteDupMsgMultiple_,
      drugRouteDuplicates, drugRows, rowNum, actionDesc);
    return msg;
  },


  /**
   *  Generates a message about drugs that are equivalent to the entered/revised
   *  drug but which differ in the form modifier (e.g. XR) and/or the route
   *  (though some effort is made to make sure the route is not completely
   *  unrelated, e.g. a topical route if the changed row is systemic).
   * @param drugRouteEquivalents an array of drug row
   *  indices whose drugs equivalent to the entered/revised
   *  drug but which differ in the form modifier (e.g. XR) and/or the route
   * @param drugRows the data model's data for thr phr_drugs table
   * @param rowNum the row number in drugRows of the drug which is the subject
   *  of the warning.
   * @param actionDesc a string like 'just entered' or 'made active' which
   *  describes what the user did (and can be inserted into a sentence like
   *  "the drug which you [just entered] is the same as...."
   * @return the warning message
   */
  generateDrugEquivRouteEquivMsg: function(drugRouteEquivalents, drugRows, rowNum, actionDesc) {
    var msg = '<p><b>Warning: Duplicate active medications, different form or route</b><br>';
    var templates = this.dccClass_.DrugWarningTemplates;
    if (!templates.drugEquivRouteEquivMsgSingle_) {
      // Note:  If you change these messages, you should also update the
      // equivalent messages in phr_drugs/_dup_warnings.html.erb.
      var single = 'The medication you #{actionDesc} in row #{rowNum} is the same drug as '+
        'the entry "#{conflictDrug}" (row #{conflictRow})';
      var drugDiff = ', only with a '+
        'different form (e.g. regular versus extended release) and/or route '+
        '(e.g. injectable versus oral).  ';
      var end = '(after making sure the correct information for this drug is '+
        'entered in the remaining row). If you are not sure which of these '+
        'prescriptions should be taken, please call your physician.'
      single = single + drugDiff +
        'You should either mark one as "Stopped", or delete or clear one ' +
        end;
      var multi = 'The medication you #{actionDesc} in row #{rowNum} is the '+
        'same drug as the entries for #{conflictRowsAndDrugs}' + drugDiff +
        'You should either mark all but one as "Stopped", or delete or clear '+
        'them ' + end;
      templates.drugEquivRouteEquivMsgSingle_ = new Template(single);
      templates.drugEquivRouteEquivMsgMultiple_ = new Template(multi);
    }
    msg += this.generateDrugWarningMsg(templates.drugEquivRouteEquivMsgSingle_,
      templates.drugEquivRouteEquivMsgMultiple_,
      drugRouteEquivalents, drugRows, rowNum, actionDesc);
    return msg;
  },


  /**
   *  Generates a message about one drug that has one or more shared ingredients
   *  with the entered/revised drug.
   * @param sharedIngredDrugIndex the index of the drug that shared the ingredient
   * @param sharedIngreds an array of shared ingredients (names)
   * @param drugRows the data model's data for thr phr_drugs table
   * @param rowNum the row number in drugRows of the drug which is the subject
   *  of the warning.
   * @param actionDesc a string like 'just entered' or 'made active' which
   *  describes what the user did (and can be inserted into a sentence like
   *  "the drug which you [just entered] is the same as...."
   * @return the warning message
   */
  generateDrugSharedIngredMsg: function(sharedIngredDrugIndex, sharedIngreds, drugRows, rowNum, actionDesc) {
    var msg = '<p><b>Warning: Duplicate ingredients in different active medications</b><br>';
    var templates = this.dccClass_.DrugWarningTemplates;
    if (!templates.drugSharedIngredMsg_) {
      // Note:  If you change these messages, you should also update the
      // equivalent messages in phr_drugs/_dup_warnings.html.erb.
      templates.drugSharedIngredMsg_ = new Template(
        'The medication you #{actionDesc} in row #{rowNum} has the same active '+
        '#{sharedIngredStr} as the entry "#{conflictDrug}" (row '+
        '#{conflictRow}).'+
        '  Two different medications with the same active ingredient usually '+
        'should not be taken at the same time. If you are not sure if one or '+
        'both of these medications should be taken, please call your physician.'
      );
    }
    if (sharedIngreds.length > 1)
      var sharedIngredStr = 'ingredients ' + sharedIngreds.toEnglish();
    else
      sharedIngredStr = 'ingredient ' + htmlEncode(sharedIngreds[0]);

    var conflictRow = sharedIngredDrugIndex + 1;
    msg += templates.drugSharedIngredMsg_.evaluate({'rowNum': rowNum,
      'sharedIngredStr': sharedIngredStr,
      'conflictDrug': drugRows[sharedIngredDrugIndex]['name_and_route'],
      'conflictRow': conflictRow, 'actionDesc': actionDesc});

    return msg;
  },


  /**
   *  Uses templates (in the format supported by Prototype) to generate a drug
   *  warning message.  The templates may contain variable names supplied by
   *  this method (see the parameter descriptions).
   * @param oneConflictMsg a message template (a Prototype Template) for use when
   *  there is one
   *  conflict to be described.  This may use the following variables, supplied
   *  by this method: rowNum, conflictRow (the row of the conflicting drug),
   *  conflictDrug (the name of the conflicting drug), and actionDesc.
   * @param multipleConflictsMsg a template for use when there are many drugs
   *  in conflict with the entered/revised drug.  This may use the following
   *  variables, supplied by this method:  rowNum, rowDrug (the drug name in
   *  rowNum), conflictRows (a string that
   *  is a list of the conflicting row numbers), conflictRowsAndDrugs (a
   *  string that is a list of the conflicting drug names and row numbers), and
   *  actionDesc.
   * @param conflictIndices an array of drug row
   *  indices whose name and route is exactly the same as the rowIndex entry
   * @param drugRows the data model's data for thr phr_drugs table
   * @param rowNum the row number in drugRows of the drug which is the subject
   *  of the warning.
   * @param actionDesc a string like 'just entered' or 'made active' which
   *  describes what the user did (and can be inserted into a sentence like
   *  "the drug which you [just entered] is the same as...."
   */
  generateDrugWarningMsg: function(oneConflictMsg, multipleConflictMsg, conflictIndices, drugRows,
      rowNum, actionDesc) {
    var msg;

    var numConflicts = conflictIndices.length;
    var formRowNum = this.formRowFromModelRow(rowNum);
    if (numConflicts == 1) {
      var conflictIndex = conflictIndices[0];
      var conflictRow = this.formRowFromModelRow(conflictIndex + 1);
      var conflictDrug = drugRows[conflictIndex]['name_and_route'];
      msg = oneConflictMsg.evaluate({'rowNum': formRowNum,
        'conflictRow': conflictRow, 'conflictDrug': htmlEncode(conflictDrug),
        'actionDesc': actionDesc});
    }
    else { // more than one duplicate drug
      var conflictRowsAndDrugsArray = [];
      var conflictRowArray = [];
      var rowDrug = drugRows[rowNum-1]['name_and_route'];
      for (var i=0; i<numConflicts; ++i) {
        conflictIndex = conflictIndices[i];
        conflictRow = this.formRowFromModelRow(conflictIndex + 1);
        conflictDrug = htmlEncode(drugRows[conflictIndex]['name_and_route']);
        conflictRowsAndDrugsArray.push(conflictDrug + ' (row '
          +conflictRow+ ')');
        conflictRowArray.push(conflictRow);
      }
      var conflictRowsAndDrugs = conflictRowsAndDrugsArray.toEnglish();
      var conflictRows = conflictRowArray.toEnglish();
      msg = multipleConflictMsg.evaluate({'rowNum': formRowNum,
        'rowDrug': htmlEncode(rowDrug),
        'conflictRows': conflictRows,
        'conflictRowsAndDrugs': conflictRowsAndDrugs, 'actionDesc':
        actionDesc});
    }
    return msg;
  },


  /**
   *  Adds a drug row index to our internal record of conflicts.
   * @param drugIndex1 a row index of a drug
   * @param drugIndex2 another drug with which the drug at row index drugIndex1
   *  has conflicts.
   */
  addDrugConflict: function(drugIndex1, drugIndex2) {
    var d1Conflicts = this.drugIndexToConflicts_[drugIndex1];
    if (!d1Conflicts) {
      d1Conflicts = {}; // A hash for easy removal later
      this.drugIndexToConflicts_[drugIndex1] = d1Conflicts;
    }
    d1Conflicts[drugIndex2] = 1;
    var d2Conflicts = this.drugIndexToConflicts_[drugIndex2];
    if (!d2Conflicts) {
      d2Conflicts = {}
      this.drugIndexToConflicts_[drugIndex2] = d2Conflicts;
    }
    d2Conflicts[drugIndex1] = 1;
  },


  /**
   *  Removes a record of a conflict (if previously present) between two drugs.
   * @param drugIndex1 a row index of a drug
   * @param drugIndex2 another drug with which the drug at row index drugIndex1
   *  does not conflict.
   */
  removeDrugConflict: function(drugIndex1, drugIndex2) {
    var d1Conflicts = this.drugIndexToConflicts_[drugIndex1];
    if (d1Conflicts)
      delete d1Conflicts[drugIndex2];
    var d2Conflicts = this.drugIndexToConflicts_[drugIndex2];
    if (d2Conflicts)
      delete d2Conflicts[drugIndex1];
  },


  /**
   *  Clears all conflicts with the given row ID (which has just been cleared).
   * @param rowID the ID of the row that was cleared.
   */
  removeConflictsWithRow: function(rowID) {
    // Delete any record of a conflict that other rows have with this one
    // Assume index = rowID - 1 (which it should be)
    var rowIndex = rowID - 1;
    var iToC = this.drugIndexToConflicts_;
    var otherIndices = Object.keys(iToC);
    for (var i=0, len=otherIndices.length; i<len; ++i) {
      var otherRowConflicts = iToC[otherIndices[i]];
      delete otherRowConflicts[rowIndex];
    }
    delete iToC[rowIndex];
  },


  /**
   *  Finds all the conflicts for the active drugs and updates the warning icons.
   */
  findAllDrugConflicts: function() {
    this.drugIndexToConflicts_ = {}; // clear any old data
    var drugRows = Def.DataModel.data_table_['phr_drugs'];

    // For read-only access, the data table does not include an entry for
    // tables with no data.
    if (drugRows !== undefined) {
      for (var i=0, len=drugRows.length; i<len; ++i) {
        this.drugConflictCheck(drugRows, i, true);
      }
      this.updateDrugWarningIconState();
    }
  },


  /**
   *  Called when internally stored state might be invalid (e.g. after a save
   *  where rows were deleted).
   */
  recalculate: function() {
    this.findAllDrugConflicts();
  },


  /**
   *  Checks for conflicts between the row at rowIndex and other rows in
   *  the drugs table, and returns data structures with information about the
   *  conflicts.
   * @param drugRows the data model's data for thr phr_drugs table
   * @param rowIndex the index in drugRows of the row that was changed/added
   * @param startFromRowIndex if true, this will only look for conflicts with
   *  rows at a higher index than rowIndex.  The default is false.
   * @return An array consisting of the following:  1) an array of drug row
   *  indices whose name and route is exactly the same as the rowIndex entry;
   *  2) an array of drug row indices for each drug entry whose route is the same
   *  and whose drug name is equivalent; 3) an array of drug row indices for each
   *  drug which in an equivalent drug but with not exactly the same route
   *  (but which might conflict due to the route having some similarity); and
   *  4) an array of arrays, one for each drug (not in the earlier cases) that
   *  shares an ingredient with the drug being checked (each array is the index
   *  of that drug record and an array of ingredient names that are shared).
   *  In all cases only active drugs are considered.
   *  If there is nothing to warn about (or if the drug row being checked is not
   *  active) the return value is null.
   */
  drugConflictCheck: function(drugRows, rowIndex, startFromRowIndex) {
    // Note:  The logic here has been ported to phr_drug.rb's dup_check, so if
    // you change it here you should also update it there.
    var rowData = drugRows[rowIndex];
    var rtn = null;
    // If the drug name is blank, or if it is inactive, remove all conflict data
    // for the row.
    if (rowData['name_and_route'].trim() === '' ||
        rowData['drug_use_status_C'] === 'DRG-I') {
      this.removeConflictsWithRow(rowIndex+1);
    }
    else { // the record is active
      var numRows = drugRows.length;
      var nameRouteDuplicates = [];
      var drugRouteDuplicates = []; // full ingredient match and route match
      var equivalentRouteMatches = [];
      var sharedIngredientMatches = [];
      var routeCodeRegex = null;
      var ingredientTexts = null;
      var ingredientCodes = null;
      var haveWarning = false;
      var rowFormMod = this.dccClass_.getDrugFormModifier(rowData);
      var startIndex = startFromRowIndex ? rowIndex + 1 : 0;

      for (var i=startIndex; i<numRows; ++i) {
        var conflictAtI = false;
        if (i != rowIndex) { // don't compare the row with itself
          // Only consider active drugs
          var checkRowData = drugRows[i];
          if (checkRowData['drug_use_status_C'] != 'DRG-I') {
            // Check for duplicate name and route entries
            if (checkRowData['name_and_route'] == rowData['name_and_route']) {
              nameRouteDuplicates.push(i);
              conflictAtI = true;
            }
            else if (rowData['drug_ingredients_C']) {  // otherwise no further checks
              // Check for an complete match on ingredients and route
              if (checkRowData['drug_ingredients_C'] == rowData['drug_ingredients_C']) {
                var checkRowFormMod = this.dccClass_.getDrugFormModifier(checkRowData);
                if (checkRowData['drug_routes_C'] == rowData['drug_routes_C'] &&
                    rowFormMod == checkRowFormMod) {
                  drugRouteDuplicates.push(i);
                  conflictAtI = true;
                }
                else {
                  // Check for a complete match on ingredients and an
                  // equivalent route.
                  if (!routeCodeRegex)
                    routeCodeRegex = this.dccClass_.buildRouteCodeRegex(rowData['drug_routes_C']);
                  if (routeCodeRegex.test(checkRowData['drug_routes_C'])) {
                    equivalentRouteMatches.push(i);
                    conflictAtI = true;
                  }
                }
              }
              else {
                // See if there is a shared ingredient with this drug
                if (!ingredientCodes) {
                  ingredientCodes = Def.parseSetValue(rowData['drug_ingredients_C']);
                  ingredientTexts = Def.parseSetValue(rowData['drug_ingredients']);
                }
                var checkCodes = Def.parseSetValue(checkRowData['drug_ingredients_C']);
                var checkCodeSet = {};
                for (var j=0, max=checkCodes.length; j<max; ++j)
                  checkCodeSet[checkCodes[j]] = 1;
                var matchedIngredients = []
                for (j=0, max=ingredientCodes.length; j<max; ++j) {
                  if (checkCodeSet[ingredientCodes[j]])
                    matchedIngredients.push(ingredientTexts[j]);
                }
                if (matchedIngredients.length > 0) {
                  sharedIngredientMatches.push([i, matchedIngredients]);
                  conflictAtI = true;
                }
              }
            }
          }
          if (conflictAtI) {
            this.addDrugConflict(rowIndex, i);
            if (!haveWarning)
              haveWarning = true;
          }
          else {
            this.removeDrugConflict(rowIndex, i);
          }
        }
        if (haveWarning) {
          rtn = [nameRouteDuplicates, drugRouteDuplicates, equivalentRouteMatches,
            sharedIngredientMatches];
        }
      } // for each row
    }
    return rtn;
  },


});

// Add class-level variables and methods.

Object.extend(Def.FieldsTable.ControlledEditTable.DrugConflictChecker, {
  /**
   *  The ingredient codes for the special drugs which should get a slightly
   *  different warning message when there is a duplicate entry.  To add a new
   *  code, add ", 'newcode': 1" to the list.
   */
  // Def.DUP_DRUG_SPECIAL_INGREDIENTS // now pulled in from the server side
  // See PhrDrug.MULTI_DOSE_INGREDIENTS

  /**
   *  A namespace for templates for drug conflict warnings.
   */
  DrugWarningTemplates: {},

  /**
   *  Returns the form modifier of a drug as it appears in the drug's name
   *  and route string.  The form modifier is something like "XR", or "EC".
   * @param rowData the data model's data for the drug entry
   * @return the form modifier, or the empty string if there isn't one.
   */
  getDrugFormModifier: function(rowData) {
    // Note:  This has been ported to phr_drug.rb, so if you change this,
    // change that one too.
    var regexRtn = this.FORM_MODIFIER_REGEX.exec(rowData['name_and_route']);
    return regexRtn && regexRtn.length>1? regexRtn[1] : '';
  },
  // A regular expression used by getDrugFormModifier for retreiving the
  // form modifier from the drug's name and route string.
  // Note:  This has been ported to phr_drug.rb, so if you change this,
  // change that one too.
  FORM_MODIFIER_REGEX: / (XR|EC|\d\d\/\d\d|U\d+) \(/,


  /**
   *  Builds a regular expression for checking whether another drug's route
   *  is equivalent (in the sense of posing a potential conflict) with the
   *  given route codes (from the 'drug_routes_C' column).
   * @param routeCodes the route codes of the drug for which potential conflicts
   *  are being sought.  This should be the value from the drug's drug_routes_C
   *  column.
   */
  buildRouteCodeRegex: function(routeCodes) {
    // Note:  This has been ported to phr_drug.rb, so if you change this,
    // change that one too.

    // Build a list of routes to be considered.
    var routeCodeArray = Def.parseSetValue(routeCodes);
    // If the routeCodeArray contains the mixed route, make sure it also
    // contains systemic, and vice versa, because if something is mixed it
    // it may be systemic, and want to warn about matches.
    // Also, add the delimiter character around each code to aid in
    // comparisons.
    var hasMixed = false;
    var hasSystemic = false;
    for (var i=0, max=routeCodeArray.length; i<max; ++i) {
      var routeCode = routeCodeArray[i];
      if (routeCode == 'RC1')
        hasSystemic = true;
      if (routeCode == 'RC3')
        hasMixed = true;
    }
    if (hasMixed && !hasSystemic)
      routeCodeArray.push('RC1');
    else if (hasSystemic && !hasMixed)
      routeCodeArray.push('RC3');

    if (!Def.ESCAPED_SET_VAL_DELIM)
      Def.appSpecificInit();

    return RegExp(Def.ESCAPED_SET_VAL_DELIM +
      routeCodeArray.join(Def.ESCAPED_SET_VAL_DELIM + '|' +
                          Def.ESCAPED_SET_VAL_DELIM) +
      Def.ESCAPED_SET_VAL_DELIM);
  }
});
