// Autocompleter settings for their use in the PHR project.

// Override lookupKey to return the target field name rather than
// the field's ID.
Def.Observable.lookupKey = function(field) {
  return Def.IDCache.splitFullFieldID(field.id)[1];
};
Def.FieldsTable.ControlledEditTable.lookupKey = Def.Observable.lookupKey;
Def.Autocompleter.Event.lookupKey = Def.Observable.lookupKey;

// *** Set up of the autocompleters. ***
// Custom code for getting/setting element values (needed because of our
// tooltip code)
Def.Autocompleter.setOptions({getFieldVal: Def.getFieldVal,
  setFieldVal: Def.setFieldVal, //screenReaderLog: Def.ScreenReaderLog.add,
  getFieldLookupKey: Def.Observable.lookupKey,

  findRelatedFields: function(field, otherFieldLookupKey) {
    var idParts = Def.IDCache.splitFullFieldID(field.id);
    return findFields(idParts[0], otherFieldLookupKey, idParts[2]);
  },

  getFieldLabel: function(fieldID) {
    return Def.getLabelName(fieldID)[0];
  }

});

Def.Autocompleter.Event.observeRDRClearing(function(updatedFields) {
  // Before running the change event observers, update the data model.
  // Some change event observers now run on the data model, so it must
  // be completely up to date.
  Def.DataModel.clearFieldListVals(updatedFields);
  Def.FieldEvents.runChangeEventObservers(updatedFields);
});


Def.Autocompleter.Event.observeRDRAssignment(function(data) {
  Def.FieldEvents.runChangeEventObservers(data.updatedFields);
  var listField = data.listField;
  var listFieldGrp = listField.up('div.fieldGroup');
  if (listFieldGrp) {
    var ceTable = listFieldGrp.ce_table;  // The controlled edit table instance
    if (ceTable)
      ceTable.conflictChecker_.postRDRAssignmentCheck(listField);
  }
});


// Set up an observer to update the code fields for lists whenever a list
// field changes.
Def.Autocompleter.Event.observeListSelections(null, function(data) {
  var fieldID = data.field_id;
  var field = $(fieldID);
  var codeField = Def.getFieldsCodeField(field);
  var codeVal = data.item_code;
  if (codeVal === undefined)
    codeVal = '';
  if (codeField) {
    Def.setFieldVal(codeField, codeVal, false);
    Event.simulate(codeField, 'change');
  }

  // Also update the score field, if there is one.  The score is the code,
  // in this case.
  var scoreField = Def.getFieldsScoreField(field);
  if (scoreField) {
    Def.setFieldVal(scoreField, codeVal, false);
    Event.simulate(scoreField, 'change');
  }

  // If the list item was clicked, move to the next field
  // Also resize the table row if we're in a table.
  if (data.input_method === 'clicked') {
    // Adjust the field height to fit the newly selected item.  (We also do this
    // in a keyup listener on the field.)
    if (field.hasClassName('wrap')) // a field that can wrap text
      Def.FieldsTable.resizeTableFieldHeight({target: field});

    // Move to the next element, but allow rules to finish running first
    Def.Navigation.moveToNextFormElem(field); // contains a timeout
  }
});


Def.Autocompleter.Event.observeListAssignments(null, function(data) {
  // Run rules because the list has changed (and some rules check whether a
  // field has a list)
  var fieldID = data.field_id;
  var field = $(fieldID);
  Def.Rules.runRules(field);
});
