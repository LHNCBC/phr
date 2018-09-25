// We need these to allow the editing portion of the controlled edit
// table to be run.  Normally these are set by other code in which this
// runs.
Def.accessLevel_ = 1 ;
Def.READ_ONLY_ACCESS = 3 ;
Def.FORM_READ_ONLY_EDITABILITY = 'READ_ONLY' ;
Def.formEditability = Def.FORM_READ_ONLY_EDITABILITY ;

Def.FieldsTable.ControlledEditTable.ceTableData_ = {
  getrows_test: {
    is_editable_field: [false, true, true, false, false, false, false],
    controlled_edit_menu: [['selectByFieldCode', 'present_C',
      {'I': ['Make Active', 'MA']}, ['Make Inactive', 'MI']]],
    controlled_edit_actions: {
      'MA': ['setListFieldByCode', 'present', 'A'],
      'MI': ['setListFieldByCode', 'present', 'I']}}
};
Def.FieldsTable.ControlledEditTable.DELETED_MARKER='delete ';
Def.Rules.fieldRules_ = {};
new Def.FieldsTable.ControlledEditTable('fe_getrows_test_0',
                                        'problems_header_id');
var fe_present_0_autoComp =
  new Def.Autocompleter.Prefetch('fe_present_0', ["Active", "Inactive"],
                                 {'codes': ["A", "I"]});

new Test.Unit.Runner({

  // replace this with your real tests

  setup: function() {
    Def.Navigation.formNavInitialized_ = true;
  },

  teardown: function() {

  },


  /**
   *  Tests checkForDuplicates.
   */
  testCheckForDuplicates: function() { with(this) {
    var dataModel = {'drugs': [{'drug': 'aspirin', 'drug_C': 1},
                           {'drug': 'propranalol', 'drug_C': 2},
                           {'drug': 'propranalol', 'drug_C': 2},
                           {'drug': 'amoxicillin', 'drug_C': 3},
                           {'drug': 'amox.', 'drug_C': 3},
                           {'drug': 'caffeine', 'drug_C': 4},
                           {'drug': 'caffeine', 'drug_C': 5}  ]};
    var mappingTable = {'drug_1': ['drugs', 'drug', 1],
                    'drug_C_1': ['drugs', 'drug_C', 1],
                    'drug_2': ['drugs', 'drug', 2],
                    'drug_C_2': ['drugs', 'drug_C', 2],
                    'drug_3': ['drugs', 'drug', 3],
                    'drug_C_3': ['drugs', 'drug_C', 3],
                    'drug_4': ['drugs', 'drug', 3],
                    'drug_C_4': ['drugs', 'drug_C', 3],
                    'drug_5': ['drugs', 'drug', 3],
                    'drug_C_5': ['drugs', 'drug_C', 3],
                    'drug_6': ['drugs', 'drug', 3],
                    'drug_C_6': ['drugs', 'drug_C', 3],
                    'drug_7': ['drugs', 'drug', 4],
                    'drug_C_7': ['drugs', 'drug_C', 4] };
    var modelTable = {'drugs': {'drug': ['Drug Name', 100],
                            'drug_C': ['Drug Code', 110]}};
    var table2Group = [];
    Def.DataModel.addNewDataModel(dataModel, mappingTable, modelTable,
      table2Group);

    // Test a field that does not have a duplicate
    var dupVal =
      Def.FieldsTable.ControlledEditTable.ConflictChecker.checkForDuplicates($('drug_1'),
        'drug_C')
    assertNull(dupVal, 'drug_1 does not have a duplicate');
    // Test a field that does have a duplicate
    var dupVal =
      Def.FieldsTable.ControlledEditTable.ConflictChecker.checkForDuplicates($('drug_2'),
        'drug_C')
    assertEqual('propranalol', dupVal, 'drug_2 (propranolol) is duplicated');
    // Test a field that has a duplicate, but don't use the code field.
    // Also use the second value of the duplicate pair.
    var dupVal =
      Def.FieldsTable.ControlledEditTable.ConflictChecker.checkForDuplicates($('drug_3'),
        null)
    assertEqual('propranalol', dupVal, 'drug_3 (propranolol) is duplicated '+
        'even without the code value');
    // Test a field that has a duplicate but whose display name has changed
    var dupVal =
      Def.FieldsTable.ControlledEditTable.ConflictChecker.checkForDuplicates($('drug_4'),
        'drug_C')
    assertEqual('propranalol', dupVal, 'drug_4 (amoxicillin) is duplicated '+
        'according to the code value');
    // Test that if we are checking the code value, if the code values differ
    // it does not matter if the display names are the same.  (Hopefully there
    // is not a real case of this.)
    var dupVal =
      Def.FieldsTable.ControlledEditTable.ConflictChecker.checkForDuplicates($('drug_6'),
        'drug_C')
    assertEqual('propranalol', dupVal, 'drug_6 is NOT duplicated '+
        'according to the code value');
  }},


  /**
   *  Tests selectByFieldCode.
   */
  testSelectByFieldCode: function() { with(this) {
    var nodeRow = $('selectByFieldCodeTest');
    var cet = $('fe_getrows_test_0').ce_table;
    cet.initMenuLocation(nodeRow);
    var nodeRowID = nodeRow.readAttribute('rowid');
    // Try a value not in the hashmap
    Def.setFieldVal($('fe_status_4'), 'A1');
    var rtn = Def.FieldsTable.ControlledEditTable.selectByFieldCode(cet,
      'status', {'B2': 'val2', 'C3': 'val3'}, 'val1');
    assertEqual('val1', rtn);
    // Now try a value that is in the hashmap
    Def.setFieldVal($('fe_status_4'), 'C3');
    rtn = Def.FieldsTable.ControlledEditTable.selectByFieldCode(cet, 'status',
      {'B2': 'val2', 'C3': 'val3'}, 'val1');
    assertEqual('val3', rtn);
  }},


  /**
   *  Tests findFieldInRowSet.
   */
  testFindFieldInRowSet: function() { with(this) {
    // There are two cases to check-- finding a field in the first row,
    // and finding a field in an embedded row.
    // There are two types of rows to pass in-- the first row of a row
    // set, and an embedded row.  So, we have four cases.
    var nodeRow = $('testFindFieldInRowSet');
    var cet = $('fe_getrows_test_0').ce_table;
    cet.initMenuLocation(nodeRow);
    var nodeRowID = nodeRow.readAttribute('rowid');
    var field = Def.FieldsTable.ControlledEditTable.findFieldInRowSet(
      cet.menuRowSet_, 'problem');
    assertEqual('fe_problem_5', field.id, 'test from first row');
    field = Def.FieldsTable.ControlledEditTable.findFieldInRowSet(
      cet.menuRowSet_, 'embeddedRowField');
    assertEqual('fe_embeddedRowField_5', field.id, 'test from first row');

    nodeRow = $('testFindFieldInRowSet2');
    cet.initMenuLocation(nodeRow);
    field = Def.FieldsTable.ControlledEditTable.findFieldInRowSet(
      cet.menuRowSet_, 'problem');
    assertEqual('fe_problem_5', field.id);
    field = Def.FieldsTable.ControlledEditTable.findFieldInRowSet(
      cet.menuRowSet_, 'embeddedRowField');
    assertEqual('fe_embeddedRowField_5', field.id);
  }},


  /**
   *  Tests setListFieldByCode.
   */
  testSetListFieldByCode: function() { with(this) {
    var nodeRow = $('testSetListFieldByCode');
    var nodeRowID = nodeRow.readAttribute('rowid');
    var cet = $('fe_getrows_test_0').ce_table;
    cet.setUpContextMenu($('fe_present_6'));
    // Make the code think that a table command has been run, so it
    // doesn't change the field contents.
    var oneRowsData = cet.rowData_[nodeRowID];
    oneRowsData['table_command_run'] = true;

    Def.FieldsTable.ControlledEditTable.setListFieldByCode(cet, 'Set List',
      'present', 'I');
    assertEqual('Inactive', $('fe_present_6').value);
    // Can't check the code value because it is set asynchronously
    // assertEqual('I', $('fe_present_C_6').value);
    // Also check the data model values
    // Can't check the data model because it is updated asynchronously
    // assertEqual('Inactive',
    //  Def.DataModel.getModelFieldValue('phr_problems', 'present', 6));
    // assertEqual('I',
    //  Def.DataModel.getModelFieldValue('phr_problems', 'present_C', 6));
  }},


  /**
   *  Tests clearRow.
   */
  testClearRow: function() { with(this) {
    assertEqual('original problem', $('fe_problem_8').value, 'field value');
    // Also check the data model
    assertEqual('original problem',
      Def.DataModel.getModelFieldValue('phr_problems', 'problem', 8));
    var cet = $('fe_getrows_test_0').ce_table;
    cet.setUpContextMenu($('fe_present_8'));
    cet.clearRow();
    assertEqual('', $('fe_problem_8').value);
    // Also check the data model
    assertEqual('',
      Def.DataModel.getModelFieldValue('phr_problems', 'problem', 8));
  }},


  /**
   *  One of several methods that test the set up of the context menu and the
   *  effects of various.  This one checks the initial state of the menu
   *  before any menu commands are issued.
   */
  testMenuAndFieldStates_Initial: function() { with(this) {
    TestHelpers.checkMenuAndRowForInitialUneditableState(this);
  }},


  /**
   *  One of several methods that test the set up of the context menu and the
   *  effects of various.  This one tries choosing "Revise" and then "Undo".
   */
  testMenuAndFieldStates_ReviseUndo: function() { with(this) {
    var cet = $('fe_getrows_test_0').ce_table;
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'pre check');

    // Run the edit command, followed by "undo".
    assert(!$('fe_problem_7').up('td').hasClassName('cet_edit')); // initially not there
    cet.editRow();
    TestHelpers.checkProblemRecFieldStates(this, cet,
      [false, true, false, false, false]);
    TestHelpers.checkRowSevenFieldValues(this,
      ['3000', 'original problem', 'original problem code', 'Active', 'A']);
    // Check the cet_edit class on the TD cell.
    assert($('fe_problem_7').up('td').hasClassName('cet_edit'));
    // Change the problem
    Def.setFieldVal($('fe_problem_7'), 'new problem');
    Def.setFieldVal($('fe_problem_C_7'), 'new problem code');
    // Make sure the taffy db was updated
    assertEqual('new problem',
      Def.DataModel.getModelFieldValue('phr_problems', 'problem', 7));
    cet.setUpContextMenu($('fe_problem_7'));
    TestHelpers.checkTableMenu(this, cet,
      [TestHelpers.undoLabel_ + ' ' +TestHelpers.editLabel_,
       TestHelpers.editLabel_,
       TestHelpers.deleteLabel_, TestHelpers.makeInactiveLabel_],
      [false, true, false, false]);
    // Undo
    cet.undoLatestCommand();
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'post check');
    // Check the cet_edit class on the TD cell-- it should be gone now.
    assert(!$('fe_problem_7').up('td').hasClassName('cet_edit'));
  }},


  /**
   *  One of several methods that test the set up of the context menu and the
   *  effects of various.  This one tries choosing "Make Inactive" and then
   *  "Undo".
   */
  testMenuAndFieldStates_MakeInactiveUndo: function() { with(this) {
    var cet = $('fe_getrows_test_0').ce_table;
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'pre check');

    // Run the "make inactive" command, followed by undo
    cet.cetClass_.setListFieldByCode(cet, TestHelpers.makeInactiveLabel_,
      'present', 'I');
    // Wait for data model changes to happen (asynchronously)
    wait(1, function() {
      TestHelpers.checkMenuAndRowForMakeInactiveState(this);

      // Undo
      cet.undoLatestCommand();
      TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'post check');
    });
  }},


  /**
   *  One of several methods that test the set up of the context menu and the
   *  effects of various.  This one tries choosing "Delete" and then
   *  "Undo".
   */
  testMenuAndFieldStates_DeleteUndo: function() { with(this) {
    var cet = $('fe_getrows_test_0').ce_table;
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'pre check');

    // Run the Delete command, followed by undo.
    cet.deleteRow();
    TestHelpers.checkProblemRecFieldStates(this, cet,
      [false, false, false, false, false]);
    TestHelpers.checkRowSevenFieldValues(this,
      ['delete 3000', 'original problem', 'original problem code',
       'Active', 'A'], 'after delete');
    cet.setUpContextMenu($('fe_problem_7'));
    var undoDelete = TestHelpers.undoLabel_ + ' ' + TestHelpers.deleteLabel_;
    TestHelpers.checkTableMenu(this, cet,
      [undoDelete, TestHelpers.editLabel_,
       TestHelpers.deleteLabel_],
      [false, true, true]);
    assert(cet.menuRowSet_[0].hasClassName('deleted'));
    // Undo
    cet.undoLatestCommand();
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'post check');
  }},


  /**
   *  One of several methods that test the set up of the context menu and the
   *  effects of various.  This one tries choosing "Make Inactive", "Revise",
   *  "Undo", and "Undo.
   */
  testMenuAndFieldStates_MakeInactiveReviseUndo: function() { with(this) {

    var cet = $('fe_getrows_test_0').ce_table;
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'pre check');

    // Run the "make inactive" command.  Another test checks for its effect.
    cet.cetClass_.setListFieldByCode(cet, TestHelpers.makeInactiveLabel_,
      'present', 'I');
    // Wait for the asynchronous data model update
    wait(1, function() {
      // Run the revise command.
      // Change the problem field to a blank value.  We had a bug where if the
      // old value was blank, the blank value would not be restored on undo.
      Def.setFieldVal($('fe_problem_7'), '');
      cet.editRow();
      TestHelpers.checkProblemRecFieldStates(this, cet,
        [false, true, false, false, false]);
      TestHelpers.checkRowSevenFieldValues(this,
        ['3000', '', 'original problem code', 'Inactive', 'I'], 'after editRow');
      // Change the problem.
      Def.setFieldVal($('fe_problem_7'), 'new problem');
      Def.setFieldVal($('fe_problem_C_7'), 'new problem code');
      cet.setUpContextMenu($('fe_problem_7'));
      TestHelpers.checkTableMenu(this, cet,
        [TestHelpers.undoLabel_ + ' ' +TestHelpers.editLabel_,
         TestHelpers.editLabel_,
         TestHelpers.deleteLabel_, TestHelpers.makeActiveLabel_],
        [false, true, false, false]);
      // Undo
      cet.undoLatestCommand();
      assertEqual('', Def.getFieldVal($('fe_problem_7')));
      // Also check the read only value displayed to the user
      assertEqual('', $('fe_problem_7').readOnlyNode.innerHTML);
      // Now restore fe_problem_7 to the value it would have been if we weren't
      // testing for the bug with blank values.
      Def.setFieldVal($('fe_problem_7'), 'original problem');
      $('fe_problem_7').readOnlyNode.innerHTML = 'original problem';
      TestHelpers.checkMenuAndRowForMakeInactiveState(this);

      // Undo one last time (to undo everything)
      cet.undoLatestCommand();
      TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'post check');
    });
  }},


  /**
   *  One of several methods that test the set up of the context menu and the
   *  effects of various.  This one tries choosing "Make Inactive", "Delete",
   *  "Undo", and "Undo.
   */
  testMenuAndFieldStates_MakeInactiveDeleteUndo: function() { with(this) {
    var cet = $('fe_getrows_test_0').ce_table;
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'pre check');

    // Run the "make inactive" command.  Another test checks for its effect.
    cet.cetClass_.setListFieldByCode(cet, TestHelpers.makeInactiveLabel_,
      'present', 'I');
    // Wait for the asynchronous data model update
    wait(1, function() {
      // Run the delete command.
      cet.deleteRow();
      TestHelpers.checkProblemRecFieldStates(this, cet,
        [false, false, false, false, false]);
      TestHelpers.checkRowSevenFieldValues(this,
        ['delete 3000', 'original problem', 'original problem code', 'Inactive',
         'I'], 'after deleteRow');
      cet.setUpContextMenu($('fe_problem_7'));
      TestHelpers.checkTableMenu(this, cet,
        [TestHelpers.undoLabel_ + ' ' +TestHelpers.deleteLabel_,
         TestHelpers.editLabel_,
         TestHelpers.deleteLabel_],
        [false, true, true]);
      // Undo
      cet.undoLatestCommand();
      TestHelpers.checkMenuAndRowForMakeInactiveState(this);

      // Undo one last time (to undo everything)
      cet.undoLatestCommand();
      TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'post check');
    });
  }},


  /**
   *  One of several methods that test the set up of the context menu and the
   *  effects of various.  This one tries choosing "Revise", "Delete",
   *  "Undo", and "Undo.
   */
  testMenuAndFieldStates_ReviseDeleteUndo: function() { with(this) {
    var cet = $('fe_getrows_test_0').ce_table;
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'pre check');

    // Run the revise command.  Another test checks for its effect.
    cet.editRow();
    // Change the problem
    Def.setFieldVal($('fe_problem_7'), 'new problem');
    Def.setFieldVal($('fe_problem_C_7'), 'new problem code');

    // Run the delete command.
    cet.deleteRow();
    TestHelpers.checkProblemRecFieldStates(this, cet,
      [false, false, false, false, false]);
    TestHelpers.checkRowSevenFieldValues(this,
      ['delete 3000', 'new problem', 'new problem code', 'Active',
       'A'], 'after delete');
    cet.setUpContextMenu($('fe_problem_7'));
    TestHelpers.checkTableMenu(this, cet,
      [TestHelpers.undoLabel_ + ' ' +TestHelpers.deleteLabel_,
       TestHelpers.editLabel_,
       TestHelpers.deleteLabel_],
      [false, true, true]);
    // Undo
    cet.undoLatestCommand();
    // Confirm we are back at the edit state-- with the changes
    TestHelpers.checkProblemRecFieldStates(this, cet,
      [false, true, false, false, false]);
    TestHelpers.checkRowSevenFieldValues(this,
      ['3000', 'new problem', 'new problem code', 'Active', 'A'],
      'after first undo');
    cet.setUpContextMenu($('fe_problem_7'));
    TestHelpers.checkTableMenu(this, cet,
      [TestHelpers.undoLabel_ + ' ' +TestHelpers.editLabel_,
       TestHelpers.editLabel_,
       TestHelpers.deleteLabel_, TestHelpers.makeInactiveLabel_],
      [false, true, false, false]);

    // Undo one last time (to undo everything)
    cet.undoLatestCommand();
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'post check');
  }},


  /**
   *  One of several methods that test the set up of the context menu and the
   *  effects of various.  This one tries choosing "Revise", "Make Inactive",
   *  "Undo", and "Undo.
   */
  testMenuAndFieldStates_ReviseMakeInactiveUndo: function() { with(this) {
    var cet = $('fe_getrows_test_0').ce_table;
    TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'pre check');

    // Run the revise command.  Another test checks for its effect.
    cet.editRow();
    // Change the problem
    Def.setFieldVal($('fe_problem_7'), 'new problem');
    Def.setFieldVal($('fe_problem_C_7'), 'new problem code');

    // Run the "make inactive" command.  Another test checks for its effect.
    cet.cetClass_.setListFieldByCode(cet, TestHelpers.makeInactiveLabel_,
      'present', 'I');
    // Wait for the asynchronous data model update
    wait(1, function() {
      TestHelpers.checkProblemRecFieldStates(this, cet,
        [false, true, false, false, false]);
      TestHelpers.checkRowSevenFieldValues(this,
        ['3000', 'new problem', 'new problem code', 'Inactive',
         'I'], 'after make inactive');
      cet.setUpContextMenu($('fe_problem_7'));
      TestHelpers.checkTableMenu(this, cet,
        [TestHelpers.undoLabel_ + ' ' +TestHelpers.makeInactiveLabel_,
         TestHelpers.editLabel_,
         TestHelpers.deleteLabel_, TestHelpers.makeActiveLabel_],
        [false, true, false, false]);
      // Undo
      cet.undoLatestCommand();
      // Confirm we are back at the edit state-- with the changes
      TestHelpers.checkProblemRecFieldStates(this, cet,
        [false, true, false, false, false]);
      TestHelpers.checkRowSevenFieldValues(this,
        ['3000', 'new problem', 'new problem code', 'Active', 'A'],
        'after undo');
      cet.setUpContextMenu($('fe_problem_7'));
      TestHelpers.checkTableMenu(this, cet,
        [TestHelpers.undoLabel_ + ' ' +TestHelpers.editLabel_,
         TestHelpers.editLabel_,
         TestHelpers.deleteLabel_, TestHelpers.makeInactiveLabel_],
        [false, true, false, false]);

      // Undo one last time (to undo everything)
      cet.undoLatestCommand();
      TestHelpers.checkMenuAndRowForInitialUneditableState(this, 'post check');
    });
  }},


 /**
   *  Tests getFieldContainerForHiding.
   */
  testGetFieldContainerForHiding: function() { with(this) {
    // Test a date field
    var nodeRow = $('testSetListFieldByCode');
    var nodeRowID = nodeRow.readAttribute('rowid');
    var cet = $('fe_getrows_test_0').ce_table;
    var fieldCon =
      cet.getFieldContainerForHiding($('getFieldContainerForHiding1'));
    assertEqual('getFieldContainerForHiding2', fieldCon.id);
    // Test something that isn't a date field
    fieldCon = cet.getFieldContainerForHiding($('moreResults'));
    assertEqual('moreResults', fieldCon.id);
  }},


  testGetRowSetForRow: function() { with(this) {
    var cetClass = Def.FieldsTable.ControlledEditTable;
    var rows = cetClass.getRowSetForRow(
      $('test1'), 1);
    assertEqual(3, rows.length);
    for (var i=0, max=rows.length; i<max; ++i) {
      assertEqual("1", Element.readAttribute(rows[i], 'rowId'), "row "+i);
    }

    rows = cetClass.getRowSetForRow($('test2'), 2);
    assertEqual(3, rows.length);
    for (var i=0, max=rows.length; i<max; ++i) {
      assertEqual("2", Element.readAttribute(rows[i], 'rowId'), "row "+i);
    }
  }},


  testGetRowCells: function() { with(this) {
    var cetClass = Def.FieldsTable.ControlledEditTable;
    var rows = cetClass.getRowSetForRow($('test1'), 1);
    var tds = cetClass.getRowCells(rows);
    assertEqual(4, tds.length);
    assertEqual('fe_problems_header_id_1', tds[0].down().id);
    assertEqual('fe_problem_1', tds[1].down().id);
    assertEqual('first row embedded row 1', tds[2].innerHTML);
    assertEqual('first row embedded row 2', tds[3].innerHTML);
  }},

  // The following tests are for the controlled edit table routines defined
  // in appSpecific.js.
 /**
  *  Tests drugConflictCheck in appSpecific.js
  */
 testDrugConflictCheck: function() {with(this) {
   // Check a duplicate drug entry
   // Note:  The tests here have been ported to phr_drug_test.rb
   // test_dup_check.  If you update this, update that one too.
   var drugRows = [
       {"drug_routes":"|Oral-pill|Systemic|",
        "name_and_route":"Warfarin (Oral-pill)", "drug_classes_C":"|19|",
        "drug_ingredients":"|Warfarin|", "drug_routes_C":"|R11|RC1|",
        "name_and_route_C":"13423", "drug_ingredients_C":"|11289|",
        "drug_classes":"|Coumadins|"},
       {"drug_routes":"|Oral-pill|Systemic|",
        "name_and_route":"AUGMENTIN (Oral-pill)",
        "drug_ingredients":"|Clavulanate|Amoxicillin|",
        "drug_routes_C":"|R11|RC1|", "name_and_route_C":"9375",
        "drug_ingredients_C":"|48203|723|"},
       {"drug_routes":"|Oral-pill|Systemic|",
        "name_and_route":"Amoxicillin/Clavulanate (Oral-pill)",
        "drug_ingredients":"|Clavulanate|Amoxicillin|",
        "drug_routes_C":"|R11|RC1|", "name_and_route_C":"4843",
        "drug_ingredients_C":"|48203|723|"},
       {"drug_routes":"|Oral-liquid|Systemic|",
        "name_and_route":"Amoxicillin/Clavulanate (Oral-liquid)",
        "drug_ingredients":"|Clavulanate|Amoxicillin|",
        "drug_routes_C":"|R9|RC1|", "name_and_route_C":"2878",
        "drug_ingredients_C":"|48203|723|"},
       {"drug_routes":"|Injectable|Systemic|",
        "name_and_route":"Clavulanate/Ticarcillin (Injectable)",
        "drug_ingredients":"|Ticarcillin|Clavulanate|",
        "drug_routes_C":"|R3|RC1|", "name_and_route_C":"9682",
        "drug_ingredients_C":"|10591|48203|"},
       {"drug_routes":"|Oral-liquid|Systemic|",
        "name_and_route":"Amoxicillin (Oral-liquid)",
        "drug_ingredients":"|Amoxicillin|",
        "drug_routes_C":"|R9|RC1|", "name_and_route_C":"12370",
        "drug_ingredients_C":"|723|"},
       {"drug_routes":"|Oral-liquid|Systemic|",
        "name_and_route":"Amoxicillin/Clavulante/Chocoloate (Oral-liquid)",
        "drug_ingredients":"|Clavulanate|Amoxicillin|Chocolate",
        "drug_routes_C":"|R9|RC1|", "name_and_route_C":"X1",
        "drug_ingredients_C":"|48203|723|1234567"},
       {"drug_routes":"",
        "name_and_route":"Something not in the list",
        "drug_ingredients":"",
        "drug_routes_C":"", "name_and_route_C":"",
        "drug_ingredients_C":""},
       {"drug_routes":"|Oral-pill|Systemic|",
        "name_and_route":"AUGMENTIN XR (Oral-pill)",
        "drug_ingredients":"|Clavulanate|Amoxicillin|",
        "drug_routes_C":"|R11|RC1|", "name_and_route_C":"X2",
        "drug_ingredients_C":"|48203|723|"},
    ];

   var newRowIndex = 9;
   drugRows[newRowIndex] = Object.clone(drugRows[1]); // duplicate AUGMENTIN pill
   var conflictChecker = new Def.FieldsTable.ControlledEditTable.DrugConflictChecker();
   rtn = conflictChecker.drugConflictCheck(drugRows, newRowIndex);
   assertEqual(4, rtn.length,
     "drugConflictCheck should return an array of length 4")
   assertEqual(1, rtn[0].length, "There should be one duplicate drug");
   assertEqual(1, rtn[0][0], "The duplicate drug should be at index 1");
   assertEqual(1, rtn[1].length,
     "There should be 1 equivalent drugs with the same route");
   assertEqual(2, rtn[1][0],
     "The equivalent drug with the same route should be at index 2");
   assertEqual(2, rtn[2].length,
     "There should be 2 equivalent drugs with a similar route");
   assertEqual(3, rtn[2][0],
     "One equivalent drug with a similar route should be at index 3");
   assertEqual(8, rtn[2][1],
     "The second equivalent drug (with the XR form) should be at index 8");
   assertEqual(3, rtn[3].length, "There should be 3 shared ingredient drugs");
   assertEqual(4, rtn[3][0][0],
     "The first shared ingredient drug should be at index 4");
   assertEnumEqual(['Clavulanate'], rtn[3][0][1],
     "The first shared ingredient drug's shared ingredient should be "+
     "Clavulanate");
   assertEqual(5, rtn[3][1][0],
     "The second shared ingredient drug should be at index 5");
   assertEnumEqual(['Amoxicillin'], rtn[3][1][1],
     "The second shared ingredient drug's shared ingredient should be "+
     "Amoxicillin");
   assertEqual(6, rtn[3][2][0],
     "The third shared ingredient drug should be at index 6");
   assertEnumEqual(['Clavulanate', 'Amoxicillin'], rtn[3][2][1],
     "The third shared ingredient drug's shared ingredients should be "+
     "Clavulanate and Amoxicillin");

   // Test that the matches are not reported if the entered drug is inactive
   drugRows[newRowIndex]['drug_use_status_C'] = 'DRG-I';
   rtn = conflictChecker.drugConflictCheck(drugRows, newRowIndex);
   assertNull(rtn, 'Nothing should be returned for a new but inactive drug');

   // Test that the matches are not reported if the other drugs are inactive
   drugRows[newRowIndex]['drug_use_status_C'] = ''; // so it will be treated as active
   for (var i=0; i<newRowIndex; ++i) {
     drugRows[i]['drug_use_status_C'] = 'DRG-I';
   }
   rtn = conflictChecker.drugConflictCheck(drugRows, newRowIndex);
   assertNull(rtn, 'Nothing should be returned if the other drugs are inactive');

   // Now make one active again
   drugRows[6]['drug_use_status_C'] = '';
   rtn = conflictChecker.drugConflictCheck(drugRows, newRowIndex);
   assertEqual(4, rtn.length,
     "drugConflictCheck should again return an array of length 4");
   assertEqual(0, rtn[0].length, '0 duplicates');
   assertEqual(0, rtn[1].length, '0 equivalent, same route drugs');
   assertEqual(0, rtn[2].length, '0 equilvalent, similar route drugs');
   assertEqual(1, rtn[3].length, '1 shared ingredient drug');

   // Test what happens when drugs are present that are not in the list.
   drugRows = [
       {"drug_routes":"",
        "name_and_route":"Something not in the list",
        "drug_ingredients":"",
        "drug_routes_C":"", "name_and_route_C":"",
        "drug_ingredients_C":""},
       {"drug_routes":"",
        "name_and_route":"A different something not in the list",
        "drug_ingredients":"",
        "drug_routes_C":"", "name_and_route_C":"",
        "drug_ingredients_C":""},
       {"drug_routes":"",
        "name_and_route":"Something not in the list",
        "drug_ingredients":"",
        "drug_routes_C":"", "name_and_route_C":"",
        "drug_ingredients_C":""},
   ];
   rtn = conflictChecker.drugConflictCheck(drugRows, 2);
   assertEqual(4, rtn.length, "non list drugConflictCheck should return an "+
     "array of length 4");
   assertEqual(1, rtn[0].length, "non list drugConflictCheck: 1 duplicate");
   assertEqual(0, rtn[1].length, 'non list: 0 equivalent, same route drugs');
   assertEqual(0, rtn[2].length, 'non list: 0 equilvalent, similar route drugs');
   assertEqual(0, rtn[3].length, 'non list: 0 shared ingredient drug');
 }},


 /**
  *  Tests the getDrugFormModifier function.
  */
 testGetDrugFormModifier: function() {with(this) {
   var conflictCheckerCls = Def.FieldsTable.ControlledEditTable.DrugConflictChecker;
   assertEqual('', conflictCheckerCls.getDrugFormModifier({}));
   assertEqual('', conflictCheckerCls.getDrugFormModifier(
     {'name_and_route': 'AUGMENTIN (Oral-pill)'}));
   assertEqual('XR', conflictCheckerCls.getDrugFormModifier(
     {'name_and_route': 'AUGMENTIN XR (Oral-pill)'}));
   assertEqual('', conflictCheckerCls.getDrugFormModifier(
     {'name_and_route': 'AUGMENTIN A (Oral-pill)'}));
   assertEqual('EC', conflictCheckerCls.getDrugFormModifier(
     {'name_and_route': 'AUGMENTIN EC (Oral-pill)'}));
   assertEqual('20/80', conflictCheckerCls.getDrugFormModifier(
     {'name_and_route': 'AUGMENTIN 20/80 (Oral-pill)'}));
   assertEqual('U500', conflictCheckerCls.getDrugFormModifier(
     {'name_and_route': 'AUGMENTIN U500 (Oral-pill)'}));
 }}

}, "testlog");

TestHelpers = {
  /**
   *  The text of the edit menu item.
   */
  editLabel_: 'Revise',

  /**
   *  The text of the delete menu item.
   */
  deleteLabel_: 'Delete',

  /**
   *  The text of the undo menu item.
   */
  undoLabel_:  'Undo',

  /**
   *  The text of the Make Inactive menu item.
   */
  makeInactiveLabel_: 'Make Inactive',

  /**
   *  The text of the Make Active menu item.
   */
  makeActiveLabel_: 'Make Active',


  /**
   *  A helper method for testtMenuAndFieldStates() that checks that the
   *  fields in the current menu row have the given editable states.
   * @param tr the TestRunner instance
   * @param cet the controlled edit table instance
   * @param expectedEditableStates an array of booleans, one for each
   *  cell in the non-embedded rows (because we're not testing the embedded
   *  rows here) which is true if the fields in the cell should be in the
   *  editable state.
   */
  checkProblemRecFieldStates: function(tr, cet, expectedEditableStates) {
    var rowCells = cet.cetClass_.getRowCells(cet.menuRowSet_);
    for (var c=0, max=expectedEditableStates; c<max; ++c) {
      var cellFields = cet.getFieldsFromElement(rowCells[c]);
      if (cellFields.length>0) {
        tr.assertEqual(expectedEditableStates[c],
          !cet.isFieldReadOnly(cellFields[0]));
      }
    }
  },


  /**
   *  Checks that row seven of the problem table is in its initial state.
   * @param tr the TestRunner instance
   * @param cet the controlled edit table instance
   * @param msg a message string to use in the assertions when they fail
   */
  assertRowSevenInInitialState: function(tr, cet, msg) {
    // Check that the fields are not editable.
    TestHelpers.checkProblemRecFieldStates(tr, cet,
      [false, false, false, false, false]);
    // Check the field values and tag names
    TestHelpers.checkRowSevenFieldValues(tr,
      ['3000', 'original problem', 'original problem code', 'Active', 'A'],
      msg);
    var fields = ['fe_problems_header_id_7', 'fe_problem_7', 'fe_problem_C_7',
     'fe_present_7', 'fe_present_C_7'];
    for (var i=0, max=fields.length; i<max; ++i)
      tr.assertEqual('DIV', $(fields[i]).tagName, msg);
  },


  /**
   *  Checks the values of the fields in row seven of the problem table.
   * @param tr the TestRunner instance
   * @param vals the values of the fields
   * @param msg a message to use with assertions that fail
   */
  checkRowSevenFieldValues: function(tr, vals, msg) {
    if (!msg)
      msg = 'checkRowSevenFieldValues'

    var formFieldMsg = msg + ' (form field)';
    tr.assertEqual(vals[0], Def.getFieldVal($('fe_problems_header_id_7')),
      formFieldMsg);
    tr.assertEqual(vals[1], Def.getFieldVal($('fe_problem_7')), formFieldMsg);
    tr.assertEqual(vals[2], Def.getFieldVal($('fe_problem_C_7')), formFieldMsg);
    tr.assertEqual(vals[3], Def.getFieldVal($('fe_present_7')), formFieldMsg);
    tr.assertEqual(vals[4], Def.getFieldVal($('fe_present_C_7')), formFieldMsg);

    var dataModelMsg = msg + ' (data model)';
    // Also check the data model
    tr.assertEqual(vals[0],
      Def.DataModel.getModelFieldValue('phr_problems', 'problems_header_id', 7),
      dataModelMsg);
    tr.assertEqual(vals[1],
      Def.DataModel.getModelFieldValue('phr_problems', 'problem', 7),
      dataModelMsg);
    tr.assertEqual(vals[2],
      Def.DataModel.getModelFieldValue('phr_problems', 'problem_C', 7),
      dataModelMsg);
    tr.assertEqual(vals[3],
      Def.DataModel.getModelFieldValue('phr_problems', 'present', 7),
      dataModelMsg);
    tr.assertEqual(vals[4],
      Def.DataModel.getModelFieldValue('phr_problems', 'present_C', 7),
      dataModelMsg);
  },


  /**
   *  Checks that a menu is in the given state.
   * @param tr the TestRunner instance
   * @param cet the table whose menu is being checked
   * @param labels the labels on the menu (not counting the dividers)
   * @param disabled an array of booleans, with "true" meaning the menu item
   *  at the same index in "labels" is disabled.
   */
  checkTableMenu: function(tr, cet, labels, disabled) {
    var menu = cet.contextMenu_[0]; // jQuery keeps things in arrays
    var items = Element.childElements(menu);
    var numVisItems = labels.length > 3 ? 6 : 4; // includes separators
    // Get the visible menu items.
    var visMenuItems = [];
    for (var i=0, max=items.length; i<max; ++i) {
      var item = items[i];
      if (item.style.display != 'none' &&
          !$(item).hasClassName('separator'))
        visMenuItems.push(item);
    }
    tr.assertEqual(labels.length, visMenuItems.length, 'in checkTableMenu');
    tr.assertEqual(labels[0], visMenuItems[0].innerHTML, 'in checkTableMenu');
    tr.assertEqual(disabled[0], visMenuItems[0].hasClassName('disabled'),
      'in checkTableMenu');
    tr.assertEqual(labels[1], visMenuItems[1].innerHTML, 'in checkTableMenu');
    tr.assertEqual(disabled[1], visMenuItems[1].hasClassName('disabled'),
      'in checkTableMenu');
    tr.assertEqual(labels[2], visMenuItems[2].innerHTML, 'in checkTableMenu');
    tr.assertEqual(disabled[2], visMenuItems[2].hasClassName('disabled'),
      'in checkTableMenu');
    if (labels.length > 3) {
      tr.assertEqual(labels[3], visMenuItems[3].innerHTML, 'in checkTableMenu');
      tr.assertEqual(disabled[3], visMenuItems[3].hasClassName('disabled'),
        'in checkTableMenu');
    }
  },


  /**
   *  Checks that the menu and row fields are in the initial unmodified state.
   * @param tr the TestRunner instance
   * @param msg A message to use with assertions when they fail
   */
  checkMenuAndRowForInitialUneditableState: function(tr, msg) {
    if (!msg)
      msg = 'checkMenuAndRowForInitialUneditableState'
    var cet = $('fe_getrows_test_0').ce_table;

    // Test the intial, uneditable state.
    cet.setUpContextMenu($('fe_problem_7'));
    TestHelpers.checkTableMenu(tr, cet,
      [TestHelpers.undoLabel_, TestHelpers.editLabel_,
       TestHelpers.deleteLabel_, TestHelpers.makeInactiveLabel_],
      [true, false, false, false]);
    TestHelpers.assertRowSevenInInitialState(tr, cet, msg);

    tr.assert(!cet.menuRowSet_[0].hasClassName('deleted'));
  },


  /**
   *  Checks that the menu and row fields are state they should be in if the
   *  only change that was done was to make the problem inactive.
   * @param tr the TestRunner instance
   */
  checkMenuAndRowForMakeInactiveState: function(tr) {
     var cet = $('fe_getrows_test_0').ce_table;

    // Test the intial, uneditable state.
    cet.setUpContextMenu($('fe_problem_7'));
    TestHelpers.checkTableMenu(tr, cet,
      [TestHelpers.undoLabel_+ ' ' + TestHelpers.makeInactiveLabel_,
       TestHelpers.editLabel_,
       TestHelpers.deleteLabel_, TestHelpers.makeActiveLabel_],
      [false, false, false, false]);
    TestHelpers.checkProblemRecFieldStates(tr, cet,
      [false, false, false, false, false]);
    TestHelpers.checkRowSevenFieldValues(tr,
      ['3000', 'original problem', 'original problem code', 'Inactive', 'I'],
      'checkMenuAndRowForMakeInactiveState');

    tr.assert(!cet.menuRowSet_[0].hasClassName('deleted'));
  },


  /**
   *  Sets up the form's data model.
   * @param dataModel A hash from table names to arrays of hashes of table
   *  row data.
   */
  initDataModel: function(dataModel) {
    var mappingTable = {};
    // Generate the mappingTable based on dataModel
    for (var tableName in dataModel) {
      var tableData = dataModel[tableName]
      var numRows = tableData.length;
      for (var i=1; i<=numRows; ++i) {
        var rowData = tableData[i-1];
        for (var fieldName in rowData) {
          mappingTable['fe_'+fieldName+'_'+i] = [tableName, fieldName, i];
        }
      }
    }

    var modelTable = {};
    var table2Group = [];
    var formInfo=['test_form_name', 'test_id_show'];
    Def.DataModel.initDataModel(dataModel, mappingTable, modelTable,
      table2Group, formInfo, null, false);
  }
}

Def.SET_VAL_DELIM = '|'; // normally set from environment.rb


// Create the data model for the problems table
var testData = [
  {problems_header_id: "3000",
   problem: "Sleepy"
  },
  {problems_header_id: "24",
   problem: ""
  },
  {problems_header_id: "Niacin (Oral-pill)",
   problem: "5005"
  },
  {problems_header_id: "",
   status: "A1"
  },
  {problems_header_id: "",
   problem: "",
   embeddedRowField_C: "",
   embeddedRowField: "model row embedded row 1"
  },
  {problems_header_id: "",
   problem: "",
   problem_C: "",
   present: "",
   present_C: ""
  },
  {problems_header_id: "3000",
   problem: "original problem",
   problem_C: "original problem code",
   present: "Active",
   present_C: "A"
  },
  {problems_header_id: "3000",
   problem: "original problem",
   problem_C: "original problem code",
   present: "Active",
   present_C: "A"
  }
];


TestHelpers.initDataModel({'phr_problems': testData});
Def.DataModel.setupModelListener();

// Set up field observers for updating the data model
Def.fieldObservers_ = {};
var obsFields = ['problems_header_id', 'problem', 'problem_C',
     'present', 'present_C'];
for (var i=0, max=obsFields.length; i<max; ++i) {
  var fieldName = obsFields[i];
  Def.fieldObservers_[fieldName] = {};
  Def.fieldObservers_[fieldName]['change'] =
    [function(event){
       Def.DataModel.formFieldUpdateHandler(event);
    }];
//  Def.Navigation.setUpFieldListeners($('fe_'+fieldName+'_0'));
}
Def.Navigation.doNavKeys(0,0,true,true,true);
