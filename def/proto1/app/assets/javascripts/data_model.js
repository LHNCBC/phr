/**
 * data_model.js -> The TaffyDB object and methods
 *
 * This implements the client-side TaffyDB object.
 *
 * $Id: data_model.js,v 1.60 2011/08/22 21:22:45 lmericle Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/data_model.js,v $
 * $Author: lmericle $
 *
 * $Log: data_model.js,v $
 * Revision 1.60  2011/08/22 21:22:45  lmericle
 * misc fixes for panel_edit close problem
 *
 * Revision 1.59  2011/08/18 13:19:59  lmericle
 * fix to include blanked out fields in recovered fields display
 *
 * Revision 1.58  2011/08/17 18:15:38  lmericle
 * changes related to problem with "removed rows" in controlled edit tables - task #2492
 *
 * Revision 1.57  2011/08/10 20:05:47  lmericle
 * added recovered field flag to dataLoader call to apply styles to test panel fields
 *
 * Revision 1.56  2011/08/03 18:01:13  plynch
 * Changes to remove dojo from all but the panel_view and panel_edit pages.
 *
 * Revision 1.55  2011/08/03 17:17:26  mujusu
 * javascript confirmation popup fixes
 *
 * Revision 1.54  2011/07/18 20:24:30  wangye
 * various bugs fiexed and comments corrected
 *
 * Revision 1.53  2011/07/15 20:09:27  wangye
 * add some timing printouts
 *
 * Revision 1.52  2011/07/14 19:00:33  lmericle
 * autosave changes for test panel data
 *
 * Revision 1.51  2011/06/28 11:49:57  taof
 * bugfix: got required field validation error on drug row after it was removed from dom tree
 *
 * Revision 1.50  2011/06/22 23:32:04  plynch
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
 * Revision 1.49  2011/06/17 17:20:11  wangye
 * remove deleted and empty records in the data model and update mapping tables after a successful save
 *
 * Revision 1.48  2011/04/05 14:19:04  lmericle
 * changes from code review
 *
 * Revision 1.47  2011/03/29 19:08:26  lmericle
 * added code to condition autosave functions on autosaves flag in forms table; commented out some unneeded code
 *
 * Revision 1.46  2011/03/15 18:13:27  lmericle
 * modified loading to accomodate switch from record id to row number identification of recovered fields
 *
 * Revision 1.45  2011/03/04 21:54:20  taof
 * bugfix: obr/obx test_date syncronizing did not trigger auto saving
 *
 * Revision 1.44  2011/02/16 16:07:16  lmericle
 * fixed stray text problem in data_model.txt that caused problems in autosave.js as a side-effect
 *
 * Revision 1.43  2011/02/15 17:36:33  lmericle
 * changes related to autosave data changes (no longer storing mapping tables for autosave data) and inclusion of recovered data on data load
 *
 *
 * License:  This file should be considered to be under the terms of some
 * non-viral open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 *
 **/

Def.DataModel = {

  // constant variable for test panel's storage data table names
  OBR_TABLE : 'obr_orders',
  OBX_TABLE : 'obx_observations',
  KEY_DELIMITER : '|',
  // field id ==> taffy db
  mapping_table_id_ : null,
  // taffy db ==> field id
  mapping_table_db_ : null,
  model_table_ : null,
  taffy_db_ : null,
  form_name_: null,
  id_shown_: null,

  //used in autosave
  doAutosave_: true ,
  // flag indicating that there are changes waiting to be autosaved
  pendingAutosave_: false,
  // tp_update_: false, -- not used, 1/19/12, lm
  autosave_data_table_: [],
  // autosave_tp_data_table_: null, -- not used, 1/19/12, lm
  // flag indicating that a save operation is currently being performed; 
  // used to block autosave from being done while saving.
  save_in_progress_: false ,
  // flag used for test panels to indicating changes on one popup called from
  // the other
  subFormUnsavedChanges_: false,
  //total_autosave_data_size_: 0 ,
  // used for displaying popup if changes made, autosaved or not.
  dataUpdated_: false,
  // A mapping of data table names to group ids and the number of rows the group
  // table needs.
  table_2_group_ : null,
  
  // the data store of the taffy db.
  // changes in taffy db reflect here too.
  data_table_ : null,
  // not implemented yet. how to clone an object easily?
  taffy_db_orig_ : null,
  data_table_orig_: null,

  // a flag to avoid a loop of updating between fields on the form and
  // records in the taffy db
  in_updating_ : false,
  // a flag to indicate if the data model is initialized
  initialized_ : false,

  // to extend taffy object with new object properties
  extended_func_ :  {
    table_name_: null,
    setTableName: function(table_name) {
      this.table_name_ = table_name;
    },
    getTableName: function() {
      return this.table_name_;
    },

    update_position_: null,
    setUpdatePosition: function(position) {
      this.update_position_ = position;
    },

    getUpdatePosition: function() {
      return this.update_position_;
    },

    // Form rules can be triggered by form fields which were grouped by their
    // tables. Data rule can be triggered by data fields which were grouped by
    // their tables and observations. This function will return a concated
    // string of table name and loinc number, e.g. "obx_observations|2345-8"
    // Note: see related method named generate_group_name in rule_date.rb -Frank
    getGroupName: function(){
      var tableName = this.table_name_;
      var rtn = [tableName];

      //check sub grouping
      var subGroup = "loinc_num";
      var rec = Def.DataModel.taffy_db_[tableName].get(this.update_position_ - 1)[0];
      var columnNames = $H(rec).keys();
      if(columnNames.indexOf(subGroup) > -1)
        rtn.push(rec[subGroup]);

      return rtn.join(Def.Rules.defaultDelimiter_);

    }

  },


  /**
   * initialize the data in data model
   *
   * @param data_table data table that contains the data
   * @param mapping_table_id mapping table for a lookup from field id 
   *  to taffy db record
   * @param model_table model table for taffy db
   * @param table_2_group a mapping of data table names to group ids and the
   *  number of rows the group table needs.
   * @param form_info an array of form_name and profile_id
   * @param recoveredFields a hash of recovered data from unsaved changes.
   * @param doAutosave a flag to indicated whether or not to execute actions
   *  related to the autosave function.
   * 
   * examples:
   *   data_table = {table_1:[{name:'test one',birth_day: '2000/01/11'}],
   *                 table_2:[{test_name:'n1',test_value:'v1'},
   *                          {test_name:'n2',test_value:'v2'},
   *                          {test_name:'n3',test_value:'v1'}]
   *                };
   *   mapping_table_id = {fe_name_1:['table_1','name',1],
   *                       fe_birth_day_1:['table_1','birth_day',1],
   *                       fe_test_name_1:['table_2','test_name',1],
   *                       fe_test_value_1:['table_2','test_value',1],
   *                       fe_test_name_2:['table_2','test_name',2],
   *                       fe_test_value_2:['table_2','test_value',2],
   *                       fe_test_name_3:['table_2','test_name',3],
   *                       fe_test_value_3:['table_2','test_value',3]
   *                       ...
   *                      };
   *   model_table = {table_1:{'name':'','birth_day': ''},
   *                  table_2:{'test_name':'','test_value':''}
   *                  ...
   *                 };
   *
   *   table_2_group = [ ["phr_problems_headers",[["fe_problems_header_0", 4]]],
   *                     ["phr_surgical_histories",[["fe_surgical_history_0", 1]]],
   *                     ["phr_sigmoidoscopies",[["fe_sigmoidoscopy_0", 1]]],
   *                     ...
   *                   ]
   *
   *   recoveredFields = { tableName : [ {row# : {fieldName : value}},
   *                                      row# : {fieldName : value}} ] ,
   *                       tableName : [ {row# : {fieldName : value}}] }
   *
   */
  initDataModel: function(data_table, 
                          mapping_table_id,
                          model_table,
                          table_2_group,
                          form_info,
                          recoveredFields,
                          doAutosave) {

    if (doAutosave == undefined || doAutosave == null) {
      doAutosave = true ;
    }

    var start = new Date().getTime();
    if (form_info != null) {
      Def.DataModel.form_name_ = form_info[0];
      Def.DataModel.id_shown_ = form_info[1];
    }
    Def.DataModel.mapping_table_id_ = mapping_table_id
    Def.DataModel.model_table_ = model_table;
    Def.DataModel.data_table_ = data_table;
    //Def.DataModel.total_autosave_data_size_ = Object.toJSON(data_table).length ; 
    Def.DataModel.table_2_group_ = table_2_group;
    Def.DataModel.recovered_fields_ = recoveredFields;
    
    // Sets up taffy_db which is needed in order to run searchRecord function
    this.setupTaffyDb(data_table);
    
    // Set the beginning state of the dataUpdated_ flag and the save buttons
    if (recoveredFields)
      Def.setDataUpdatedState(true) ;
    else {
      // set the dataUpdated_ flag to true just so that a change will be
      // kicked off in the setDataUpdatedState function.
      Def.DataModel.dataUpdated_ = true ;
      Def.setDataUpdatedState(false) ;
    }
    // create the db to id mapping
    var mapping_table_db = {};
    for (var field_id in Def.DataModel.mapping_table_id_) {
      var db_loc = Def.DataModel.mapping_table_id_[field_id];
      var db_key = db_loc[0] + Def.DataModel.KEY_DELIMITER +
      db_loc[1] + Def.DataModel.KEY_DELIMITER +
      db_loc[2];
      mapping_table_db[db_key] = field_id;
    }
    Def.DataModel.mapping_table_db_ = mapping_table_db;

    Def.DataModel.doAutosave_ = doAutosave ;

    Def.Logger.logMessage(['data model initialized in ',
      (new Date().getTime() - start), 'ms']);

    if (Def.DataModel.data_table_ != undefined &&
      Def.DataModel.data_table_ != null) {
      Def.DataModel.initialized_ = true;
      if (doAutosave) {
        Def.AutoSave.setTimer();
      }
    }
  }, // end initDataModel
  
  
  /**
   * Sets up taffy_db inside Def.DataModel so that it can be used by 
   * searchRecord function. 
   * 
   * @param data_table data table that contains data (see initDataModel for 
   *   details)
   */
  setupTaffyDb: function(data_table){
    // create a set of taffy db
    var taffy_db = {};
    for (var table_name in data_table) {
      var data = data_table[table_name];
      var taffy = new TAFFY(data);
      Object.extend(taffy, Def.DataModel.extended_func_);
      taffy.setTableName(table_name);
      taffy_db[table_name] = taffy;
    }

    this.taffy_db_ = taffy_db;
  },


  /**
   * Sets the doAutosave_ flag
   * @param setting boolean setting for the flag
   */
  setAutosave: function(setting) {
    if (Def.DataModel.doAutosave_ != setting) {
      if (setting == true)
        Def.AutoSave.setTimer();
      else
        Def.AutoSave.stopTimer() ;
    }
    Def.DataModel.doAutosave_ = setting ;
  } ,


  /**
   * add test panel's data, mapping and model_table to an already initialized
   * data model
   *
   * @param data_table - data table that contains the data
   * @param mapping_table - mapping table for a lookup from field id to taffy db record
   * @param model_table - model table for taffy db
   * @param table_2_group - a table name to group id mapping
   */
  addNewDataModel: function(data_table, mapping_table, model_table,
    table_2_group) {

    if (Def.DataModel.initialized_ == false) {
      Def.DataModel.initDataModel(data_table, mapping_table, model_table,
        table_2_group);
    }
    else {
      var start = new Date().getTime();

      // create the db to id mapping
      var mapping_table_db = {};
      for (var field_id in mapping_table) {
        var db_loc = mapping_table[field_id];
        var db_key = db_loc[0] + Def.DataModel.KEY_DELIMITER +
        db_loc[1] + Def.DataModel.KEY_DELIMITER +
        db_loc[2];
        mapping_table_db[db_key] = field_id;
      }
      // merge mapping_table_db_
      Object.extend(Def.DataModel.mapping_table_db_, mapping_table_db);

      // merge mapping_table_id
      Object.extend(Def.DataModel.mapping_table_id_, mapping_table);
      
      // if there are already obr/obx tables in Def.DataModel
      // do nothing on model_table_
      // and merge data_table_ by copying the data record one by one
      if (Def.DataModel.model_table_[Def.DataModel.OBR_TABLE] != null &&
        Def.DataModel.model_table_[Def.DataModel.OBR_TABLE] != undefined &&
        Def.DataModel.model_table_[Def.DataModel.OBX_TABLE] != null &&
        Def.DataModel.model_table_[Def.DataModel.OBX_TABLE] != undefined  ) {
        for (var table_name in data_table) {
          var new_data_records = data_table[table_name];
          var existing_data_records = Def.DataModel.data_table_[table_name];
          Def.DataModel.data_table_[table_name] =
          existing_data_records.concat(new_data_records);
        }
      }
      // otherwise, merge model_table_, and data_table_
      else {
        // merge model_table
        Object.extend(Def.DataModel.model_table_, model_table);
        // merge data_table_,
        Object.extend(Def.DataModel.data_table_, data_table);
      }

      // create a set of taffy db
      var taffy_db = {};
      for (table_name in Def.DataModel.data_table_) {
        var data = Def.DataModel.data_table_[table_name];
        var taffy = new TAFFY(data);
        Object.extend(taffy, Def.DataModel.extended_func_);
        taffy.setTableName(table_name);
        taffy_db[table_name] = taffy;
      }

      // merge the sets of taffy db
      Def.DataModel.taffy_db_ = taffy_db;

      // We will want table_2_group's data in case we restore from an autosave.
      // Merge it into table_2_group_.
      var startT2G = new Date().getTime();
      var previousTable2Group = this.table_2_group_;
      var prevNumEntries = previousTable2Group.length;
      if (prevNumEntries > 0) {
        for (var i=0, max=table_2_group.length; i<max; ++i) {
          var newEntry = table_2_group[i];
          var tableName = newEntry[0];
          var found = false;
          for (var j=0; j<prevNumEntries; ++j) {
            if (previousTable2Group[j][0] == tableName) {
              found = true;
              break;
            }
          }
          if (found) {
            previousTable2Group[j][1] =
            previousTable2Group[j][1].concat(newEntry[1]);
          }
          else {
            previousTable2Group.push(newEntry);
          }
        } // end of loop of new table_2_group
      } // end if existing table_2_group has values
      else {
        this.table_2_group_ = table_2_group;
      }
      Def.Logger.logMessage(['Merged table_2_group in ',
        (new Date().getTime() - startT2G), 'ms']);

      Def.Logger.logMessage(['new data model added in ',
        (new Date().getTime() - start), 'ms']);

      if (Def.DataModel.data_table_ != undefined &&
        Def.DataModel.data_table_ != null) {
        Def.DataModel.initialized_ = true;
      }
    } // end if the data model has been initialized
  }, // end addNewDataModel


  /**
   *  Returns the number rows (records) in the given data table.
   * @param table the name of the data table
   */
  getRecCount: function(table) {
    var count = 0;
    if (Def.DataModel.initialized_ ) {
      var taffy = Def.DataModel.taffy_db_[table];
      if (taffy != null) {
        count = taffy.getLength();
      }
    }
    return count;
  },

  /**
   * It is called when a new empty row is created in a table on the form.
   * It inserts a model reord in a corresponding table in the taffy db
   *
   * NOT USED. see updateMappingAndDB
   */
  formRowInsertHandler: function(e) {
    if (Def.DataModel.initialized_ ) {
      var field = e.target;
      var db_location = Def.DataModel.mapping_table_id_[field.id];
      Def.DataModel.in_updating_ = true;
      Def.DataModel.insertOneModelRecord(db_location[0]);
      Def.DataModel.in_updating_ = false;
    }
  },

  /**
   * OnChange event handler for every input field on the form
   * It updates the corresponding record in the taffy db.
   * Also stores updates from autosave.
   * @param e is the onchange event
   */
  formFieldUpdateHandler: function(e) {
    Def.Logger.logMessage(["taffy: ", e.target.id, " on change"]);
    try {
      this.updateModelForField(e.target);
    }
    catch(e) {
      Def.Logger.logException(e);
      Def.reportError(e);
      throw e;
    }
  },


  /**
   *  Updates the data model with the value of the form field AND adds the
   *  update to the autosave data table.
   * @param field the field connected to the data model
   */
  updateModelForField: function(field) {
 
    if (Def.DataModel.initialized_) {
      var value = Def.getFieldVal(field);
      var db_location = Def.DataModel.mapping_table_id_[field.id];
      if (db_location && db_location[0]) {
        var tableName = db_location[0]
        var rowNum = db_location[2]
        var new_field = {};
        new_field[db_location[1]] = value;
        //        Def.DataModel.in_updating_ = true;
        Def.DataModel.updateOneRecord(tableName, rowNum, new_field);
        if (Def.DataModel.doAutosave_)
          Def.DataModel.pendingAutosave_ = true ;
      //Def.DataModel.dataUpdated_ = true;
        
        
      //        // add to auto save records
      //        if (Def.DataModel.doAutosave_) {
      //          Def.DataModel.pendingAutosave_ = true;
      //          // Create a 2 element hash that contains the row number as the first
      //          // element and the changed field's name and new value as the second.
      //          var autosave_record = {} ;
      //          autosave_record["row_num"] = rowNum ;
      //          autosave_record[db_location[1]] = value;
      //
      //          // Add the hash to the autosave_data_table_ array for the table that
      //          // contains the field.
      //          var autosave_rec = {};
      //          autosave_rec[tableName] = autosave_record;
      //          Def.DataModel.autosave_data_table_.push(autosave_rec) ;
      //        } // end if we are executing autosave actions
      
      } // end if we got a db_location from mapping_table_id_
    } // end if the model has been initialized
  }, // end updateModelForField


  /**
   *  Updates the autosave table with an entry indicating that a row has
   *  been 'removed' (added and then blanked out).
   * @param field a field in the removed row.  It doesn't really matter
   *  what field, just that it's in the removed row.
   */
  markFieldRowAsRemoved: function(field) {
    if (Def.DataModel.initialized_) {
      var db_location = Def.DataModel.mapping_table_id_[field.id];
      if (db_location && db_location[0]) {
        //var rowNum = db_location[2]
        if (Def.DataModel.doAutosave_) {
          Def.DataModel.pendingAutosave_ = true;
          Def.AutoSave.addUpdate(db_location[0], db_location[2], 
                                 db_location[1], 'Removed')

        }  // end if we got a db_location from mapping_table_id_
      } // end if we are executing autosave actions
    } // end if the model has been initialized
  }, // end markFieldRowAsRemoved


  /**
   * It is called when a row is deleted in a table on the form.
   * It does not remove a reord in a corresponding table in the taffy db.
   * Instead it update value of the 'id' column to be "delete [id]", as it is
   * in the new design of how to delete a row in the table on the form.
   *
   * Not used
   */
  formRowRemoveHandler: function(table, position) {
    if (Def.DataModel.initialized_) {
      var taffy = Def.DataModel.taffy_db_[table];
      var record = taffy.get(position-1);
      Def.DataModel.in_updating_ = true;
      for(var key in record) {
        if (key.match(/_id$/)) {
          record[key] = "delete " + record[key];
          break;
        }
      }
      Def.DataModel.in_updating_= false;

    }

  },


  /**
   * set up Taffy DB listener
   */
  setupModelListener: function() {
    if (Def.DataModel.initialized_ ) {

      var start = new Date().getTime();

      for (var key in Def.DataModel.taffy_db_) {
        var taffy = Def.DataModel.taffy_db_[key];
        taffy.onInsert = Def.DataModel.taffyInsertHandler;
        taffy.onUpdate = Def.DataModel.taffyUpdateHandler;
        taffy.onRemove = Def.DataModel.taffyRemoveHandler;
        taffy.afterUpdate = Def.DataModel.taffyAfterUpdateHandler;
      }

      Def.Logger.logMessage(['data model event listener set up in ',
        (new Date().getTime() - start), 'ms']);
    }

  },

  
  /**
   * reset all fields value on the form with the corresponding data in taffy db
   */
  resetFormFieldValues: function() {
    if (Def.DataModel.initialized_ ) {

      var start = new Date().getTime();

      for (var field_id in Def.DataModel.mapping_table_id_) {
        var value = Def.DataModel.getModelFieldValueById(field_id);
        $(field_id).value = value;
      }

      Def.Logger.logMessage(['form fields reset in ',
        (new Date().getTime() - start), 'ms']);
    }

  },


  /**
   * Clean all the data for one table, including taffydb, data and mapping
   * @param table the data table name, if table_name is not provided
   *        then all the data is deleted
   */
  cleanUpData: function(table) {
    // all data
    if(table == null || table == undefined) {
      Def.DataModel.mapping_table_id_ = null;
      Def.DataModel.model_table_ = null;
      Def.DataModel.data_table_ = null;
      Def.DataModel.table_2_group_ = null;
      Def.DataModel.mapping_table_db_ = null;
      Def.DataModel.taffy_db_ = null;
      Def.DataModel.initialized_ = false;
    }
    // one table only
    else {
      delete Def.DataModel.taffy_db_[table];
      delete Def.DataModel.data_table_[table];
      delete Def.DataModel.model_table_[table];
      // table_2_group_
      for(var i=0, len=Def.DataModel.table_2_group_.length; i<len; i++) {
        if (Def.DataModel.table_2_group_[i][0] == table) {
          Def.DataModel.table_2_group_.splice(i);
          break;
        }
      }
      // mapping_table_db_
      for(var key in Def.DataModel.mapping_table_db_) {
        if (key.indexOf(table + '|') == 0) {
          delete Def.DataModel.mapping_table_db_[key];
        }
      }
      // mapping_table_id_
      for(var id in Def.DataModel.mapping_table_id_) {
        var location = Def.DataModel.mapping_table_id_[id];
        if (location[0] == table) {
          delete Def.DataModel.mapping_table_id_[id];
        }
      }
    } // end of one table
  },
  

  /**
    * Event handler for Taffy update
    *
    * @param new_record - a taffy db record after the update
    * @param record - a taffy db record before the update
    */
  taffyUpdateHandler: function(new_record, record) {
    if (Def.DataModel.initialized_ ) {

      // avoid a loop of updating
      // update the field on the form only if it is not resulted from
      // the update of the field on the form
      Def.Logger.logMessage(["taffy event: Update"]);
      TestPanel.sync_observation_date(new_record, this);
      if (!Def.DataModel.in_updating_) {
        // 'this' is a TAFFY object
        var table_name = this.getTableName();
        var update_position = this.getUpdatePosition();
        Def.Logger.logMessage(["   update position: ", update_position])

        for (var column in new_record) {
          var value = new_record[column];
          var field = Def.DataModel.getFormField(table_name, column, update_position);
          // The following call should maybe be Def.setFieldVal, but right now
          // that causes an endless loop for the rules acceptance test.
          Def.setFieldVal(field, value);
        //field.value = value;
          
        }
      }
    }
  },


  /**
    * Event handler for Taffy after updating
    *
    * @param new_record - a taffy db record after the update
    *  this is actually a field name/value pair.  This MUST be a 
    *  single key/value hash or the autosave stuff will blow up.
    * @param record - a taffy db record before the update
    *  this is actually a hash of all the "before" field values
    */
  taffyAfterUpdateHandler: function(new_record, record) {
    if (Def.DataModel.initialized_ ) {
      var groupName = this.getGroupName();
      for (var column in new_record) {
        Def.Rules.updateDataTableRules(groupName, column);
      }
      // enable the save button
      Def.setDataUpdatedState(true) ;
            
      // add to auto save records
      if (Def.DataModel.doAutosave_) {
        Def.DataModel.pendingAutosave_ = true; 
        
        var tableName = this.getTableName();
        var rowNum = this.getUpdatePosition();       
 
        // Assumes that the new_record hash contains just one
        // field name/value pair.
        var rec_hash = $H(new_record) ;
        Def.AutoSave.addUpdate(tableName, 
                               rowNum, 
                               rec_hash.keys()[0],
                               rec_hash.values()[0]) ;
                               
//        // Create a 2 element hash that contains the row number as the first
//        // element and the changed field's name and new value as the second.
//        var autosave_record = new_record;
//        autosave_record["row_num"] = rowNum ;
//
//        // Add the hash to the autosave_data_table_ array for the table that
//        // contains the field.
//        var autosave_rec = {};
//        autosave_rec[tableName] = autosave_record;
//        Def.DataModel.autosave_data_table_.push(autosave_rec) ;
      } // end if we are executing autosave actions      
    }
  },


  /**
    * Event handler for Taffy delete
    *
    * @param record - a taffy db record to be removed
    */
  taffyRemoveHandler: function(record) {
    if (Def.DataModel.initialized_ ) {
      // while it is not a removal due to changes in the field on the form
      Def.Logger.logMessage(["taffy event: Remove"]);
      if (!Def.DataModel.in_updating_) {
        var table_name = this.getTableName();
        var delete_position = this.getUpdatePosition();
        Def.Logger.logMessage(["   delete position: ", delete_position])

      }
    }
  },
  /**
    * Event handler for Taffy insert
    *
    * @param new_record - a taffy db record to be inserted
    */
  taffyInsertHandler: function(new_record) {
    if (Def.DataModel.initialized_ ) {
      // while it is not a insertation due to changes in the field on the form
      Def.Logger.logMessage(["taffy event: Insert"]);
      if (!Def.DataModel.in_updating_) {
        var table_name = this.getTableName();
        var insert_position = this.getUpdatePosition();
        Def.Logger.logMessage(["   insert position: ", insert_position])

      }
    }
  },


  /**
   * Insert a row at the end of the taffy table
   *
   * @param table - table name in taffy db
   * @param record - a record
   * @param update_form - a flag indicating if the field on the form needs to
   *                       be updated too, default is false
   *
   */
  insertOneRecord: function(table, record, update_form) {
    if (Def.DataModel.initialized_ ) {
      if (update_form == undefined || update_form == null) {
        update_form = false;
      }

      var taffy = Def.DataModel.taffy_db_[table];
      var length = taffy.getLength();
      taffy.setUpdatePosition(length + 1);
      if (update_form) {
        taffy.insert(record);
      }
      else {
        Def.DataModel.in_updating_ = true;
        taffy.insert(record);
        Def.DataModel.in_updating_ = false;
      }
    }
  },

  /**
   * Insert a model(empty) row at the end of the taffy table
   *
   * @param table - table name in taffy db
   * @param update_form - a flag indicating if the field on the form needs to
   *                       be updated too, default is false
   */
  insertOneRecord_Model: function(table, update_form) {
    if (Def.DataModel.initialized_ ) {
      if (update_form == undefined || update_form == null) {
        update_form = false;
      }
      var taffy = Def.DataModel.taffy_db_[table];
      var record = Def.DataModel.getEmptyModelRecord(table);
      var new_record = {};
      for (var col in record) {
        new_record[col] = "";
      }
      var length = taffy.getLength();
      taffy.setUpdatePosition(length + 1);
      if (update_form) {
        taffy.insert(new_record);
      }
      else {
        Def.DataModel.in_updating_ = true;
        taffy.insert(new_record);
        Def.DataModel.in_updating_ = false;
      }

    }
  },

  /**
   * remove a record at specified position in a table
   *
   * @param table - table name in taffy db
   * @param position - record index in the table
   * @param update_form - a flag indicating if the field on the form needs to
   *                       be updated too, default is false
   */
  removeOneRecord: function(table, position, update_form) {
    if (Def.DataModel.initialized_ ) {
      if (update_form == undefined || update_form == null) {
        update_form = false;
      }
      var taffy = Def.DataModel.taffy_db_[table];
      taffy.setUpdatePosition(position);
      if (update_form) {
        taffy.remove(position-1);
      }
      else {
        Def.DataModel.in_updating_ = true;
        taffy.remove(position-1);
        Def.DataModel.in_updating_ = false;
      }
    }
  },


  /**
   * Removes user data and updates related mapping infomation
   *
   * @param recordsToRemove - a hash that contains user table name and record
   *                       positions in the tables of the records to be removed
   *                       in the following format:
   *  [ [table_name, position, record_id],
   *    [table_name, position, record_id],
   *    ...
   *  ]
   *  where the position starts from 1, and the record_id is not used in this
   *  function. Records are first ordered by table_name, then by position in a
   *  REVERSE order, starting from the largest number.
   */
  removeRecordsAndUpdateMappings: function(recordsToRemove) {

    if (Def.DataModel.initialized_ ) {
      for (var i=0, len=recordsToRemove.length; i<len; i++) {
        var table = recordsToRemove[i][0];
        var position = recordsToRemove[i][1];
        var taffy = Def.DataModel.taffy_db_[table];

        // get record number
        var recordNum = Def.DataModel.getRecCount(table);

        // remove records
        taffy.setUpdatePosition(position);
        Def.DataModel.in_updating_ = true;
        taffy.remove(position-1);
        Def.DataModel.in_updating_ = false;

        // delete mapping records in mapping_table_db_ and
        // mapping_table_id_
        var model_record = Def.DataModel.model_table_[table];
        for (var col in model_record) {
          var db_key = table + Def.DataModel.KEY_DELIMITER +
          col + Def.DataModel.KEY_DELIMITER + position;
          var field_id = Def.DataModel.mapping_table_db_[db_key];
          Def.Validation.RequiredField.Functions.unregisterField(field_id);
          delete Def.DataModel.mapping_table_id_[field_id];
          delete Def.DataModel.mapping_table_db_[db_key];
        }

        // update the mappings for the records who are behind the delelted
        // record by moving them forward one space in position
        // (the shifting could probably be optimized)
        for (var j=position; j<recordNum; j++) {
          for (col in model_record) {
            db_key = table + Def.DataModel.KEY_DELIMITER +
            col + Def.DataModel.KEY_DELIMITER + (j+1);

            var new_db_key = table + Def.DataModel.KEY_DELIMITER +
            col + Def.DataModel.KEY_DELIMITER + j;
            var new_db_location = [table, col, j];

            field_id = Def.DataModel.mapping_table_db_[db_key];
            // shift up in mapping_table_db_
            delete Def.DataModel.mapping_table_db_[db_key];
            Def.DataModel.mapping_table_db_[new_db_key] = field_id;
            // shift up in mapping_table_id_
            delete Def.DataModel.mapping_table_id_[field_id];
            Def.DataModel.mapping_table_id_[field_id] = new_db_location;
          }
        }          
      } // each record to be removed
    } // has data model
  },


  /**
   * replace a record at a specified position
   *  1) values of the same keys in the existing record and the new records
   *  are replaced
   *  2) values of keys that are in the exsitng record but not in the new
   *  records are *REMOVED*
   *  3) values of keys that are not in the existing record but in the new
   *  record are inserted
   *  4) default value from model record are added
   * @param table - table name in taffy db
   * @param position - record index in the table
   * @param new_record - new record to update the record at the specified
   *     position in the table. if new_record is not provided, the record will
   *     be replaced with an empty record from model table
   * @param update_form - a flag indicating if the field on the form needs to
   *                       be updated too, default is false
   */
  updateOneRecord_Replace: function(table, position, new_record, update_form) {
    if (Def.DataModel.initialized_ ) {
      if (update_form == undefined || update_form == null) {
        update_form = false;
      }
      if (new_record == undefined || new_record == null) {
        new_record = {};
      }

      var taffy = Def.DataModel.taffy_db_[table];
      // remove existing fields
      var old_record = taffy.get(position-1)[0];
      for (var k in old_record) {
        delete old_record[k];
      }
      var record = {}
      
      // create an empty record based on model table record
      var model_record = Def.DataModel.model_table_[table];
      for (var key in model_record) {
        record[key]='';
      }
      
      for (key in new_record) {
        record[key]=new_record[key];
      }
      taffy.setUpdatePosition(position);
      if (update_form) {
        taffy.update(record, position-1);
      }
      else {
        Def.DataModel.in_updating_ = true;
        taffy.update(record, position-1);
        Def.DataModel.in_updating_ = false;
      }

    }

  },

  /**
   * update a record at a specified poistion
   *  1) values of the same keys in the existing record and the new record
   *  are replaced with the new value in the new record
   *  2) values of keys that are in the existng record but not in the new
   *  records are *KEPT*
   *  3) values of keys that are not in the existing record but in the new
   *  record are inserted
   * @param table - table name in taffy db
   * @param position - record index in the table
   * @param new_record - new record to update the record at the specified
   *                     position in the table
   * @param update_form - a flag indicating if the field on the form needs to
   *                      be updated too. The default is false.
   */
  updateOneRecord: function(table, position, new_record, update_form) {
    if (Def.DataModel.initialized_ ) {
      if (update_form == undefined || update_form == null) {
        update_form = false;
      }
      var taffy = Def.DataModel.taffy_db_[table];
      taffy.setUpdatePosition(position);
      if (update_form) {
        taffy.update(new_record, position - 1);
      }
      else {
        Def.DataModel.in_updating_ = true;
        taffy.update(new_record, position - 1);
        Def.DataModel.in_updating_ = false;
      }
    } // end if the data model is initialized
  }, // end updateOneRecord


  /**
   * update a few field of a record at a specified poistion
   *  1) values of the same keys in the existing record and the new records
   *  are replaced
   *  2) values of keys that are in the exsitng record but not in the new
   *  records are *KEPT*
   *  3) values of keys that are not in the existing record but in the new
   *  record are inserted
   * It is functionally same as the updateOneRecord()
   * 
   * @param table - table name in taffy db
   * @param position - record index in the table
   * @param new_record - a record to update the record at the specified
   *                     position in the table
   * @param update_form - a flag indicating if the field on the form needs to
   *                       be updated too, default is false
   *
   * Not Used so far
   */
  updateOneRecord_Merge: function(table, position, new_record, update_form) {
    Def.DataModel.updateOneRecord(table, position, new_record, update_form);
  },

  /**
   * update a field's value in taffy db
   *
   * @param field_id - a form field's id
   * @param value - the new value of the field
   * @param update_form - a flag indicating if the field on the form needs to
   *                       be updated too, default is false
   *
   * Called by Def.setFieldVal()
   */
  updateOneField: function(field_id, value, update_form) {
    if (Def.DataModel.initialized_ ) {
      Def.Logger.logMessage(["taffy: ", field_id, " : ", value, " changed by setFieldVal"]);
      var db_location = Def.DataModel.mapping_table_id_[field_id];
      if (db_location != null) {
        var new_field = {};
        new_field[db_location[1]] = value;
        Def.DataModel.updateOneRecord(db_location[0],db_location[2],new_field, update_form);
      }
    }
  },


  /**
   *  Updates the data model values for an hash of form fields.
   * @param fieldData a hash of field IDs to new field values
   */
  updateFields: function(fieldData) {
    for (var fieldID in fieldData)
      this.updateOneField(fieldID, fieldData[fieldID]);
  },


  /**
   *  Clears the data model values (setting them to the empty string) for the
   *  given list of form fields.
   * @param fieldList the array of DOM field objects
   */
  clearFieldListVals: function(fieldList) {
    for (var i=0, max=fieldList.length; i<max; ++i) {
      var field = fieldList[i];
      this.updateOneField(field.id, '');
    }
  },
  

  /**
   * return a model record with empty value for a table
   *
   * @param table - table name in taffy db
   * @return record - a model record of the table
   */
  getEmptyModelRecord: function(table) {
    var record = {};
    var model_record = Def.DataModel.model_table_[table];
    for( var key in model_record) {
      record[key] = '';
    }
    return record;
  },


  /* this function should probably not be used for test panels, where
   * the mapping should be created on server side when a new test panel is
   * pulled
   *
   */
  
  /**
   * called by repeatingline to update mapping table and insert a new empty
   * row in corresponding taffy db when a new empty row is added to a form table
   *
   * @param field - the field that belongs to the form table and where
   *                the onBlur event occurs
   * @param form_table - the table element on the form where a new row is added
   */
  updateMappingAndDB: function(field, form_table) {
    Def.Logger.logMessage(["updating mapping and db. field: ", field.id]);
    if (Def.DataModel.initialized_ ) {

      // find the suffix for the new fields
      var modelRows = Def.FieldsTable.findModelRows(form_table);
      var modelSuffix = modelRows[0].getAttribute('suffix') ;
      var nextId = parseInt(form_table.getAttribute('nextid')) ;
      var nextSuffix = modelSuffix.replace(/_0/, "_" +nextId) ;

      // add an empty record to corresponding taffy db, the template record is
      // from the model table
      var db_location = Def.DataModel.mapping_table_id_[field.id];
      // for some forms other than phr, db_location might be null
      //      if (db_location == null) {
      //        return;
      //      }
      if (db_location != null) {
        Def.DataModel.insertOneRecord_Model(db_location[0], false);

        // update mapping tables by insert the entries of the new fields
        var model_record = Def.DataModel.model_table_[db_location[0]];
        var field_ids = [];
        var columns = [];
        //      if (Def.DataModel.doAutosave_) {
        //        var autosave_record= {};
        //        var autosave_val = []
        //      }
        for (var col in model_record) {
          // These don't seem to be used for anything.  3/28/11 lm
          //        autosave_val = [];
          //        autosave_val[0] = db_location[0];
          //        autosave_val[1] = col;
          //        autosave_val[2] = nextId;
          //
          //        autosave_record[Def.FIELD_ID_PREFIX + col + nextSuffix] = autosave_val ;

          // one column could be mapped to multiple target fields
          var target_fields = model_record[col];
          for(var i=0, len=target_fields.length; i<len; i++) {
            field_ids.push(Def.FIELD_ID_PREFIX + target_fields[i] + nextSuffix);
            columns.push(col);
          }
        }
        var position = this.getRecCount(db_location[0]);
        Def.DataModel.insertOneMappingRecord(field_ids, db_location[0],
          columns, position) ;
      } // end if we have a db_location
    } // end if the data model has been initialized
  }, // end updateMappingAndDB

  /**
   * Insert a mapping record for a form field. Called when a new
   * field is added to the form
   *
   * Called by insertOneMappingRecord
   */
  insertOneMappingField: function(field_id, table, column, position) {
    if (Def.DataModel.initialized_ ) {
      if (Def.DataModel.mapping_table_id_[field_id] == null ||
        Def.DataModel.mapping_table_id_[field_id] == undefined ) {
        Def.DataModel.mapping_table_id_[field_id] = [table, column, position];
        var db_key = table + Def.DataModel.KEY_DELIMITER + column +
        Def.DataModel.KEY_DELIMITER + position;
        Def.DataModel.mapping_table_db_[db_key] = field_id;
      }
      else {
        Def.Logger.logMessage(["taffy: ", field_id, " already exists in mapping table"]);
      }
    }
  },

  /**
   * Insert mapping records for all fields in a table row.
   * 
   * Called when a new row is added to the table on the form
   */
  insertOneMappingRecord: function(field_ids, table, columns, position) {
    if (Def.DataModel.initialized_ ) {
      for (var i=0, il=field_ids.length; i< il; i++) {
        Def.DataModel.insertOneMappingField(field_ids[i],table, columns[i], position);
      }
    }
  },

  /**
   * Remove a mapping for a field
   */
  removeOneMappingField: function(field_id) {
    if (Def.DataModel.initialized_ ) {
      var db_loc = this.mapping_table_id_[field_id];
      delete this.mapping_table_db_[db_loc[0] + Def.DataModel.KEY_DELIMITER +
      db_loc[1] + Def.DataModel.KEY_DELIMITER +
      db_loc[2]];
      delete this.mapping_table_id_[field_id];
    }
  },

  /**
   * Remove mapping records for all fields in a record
   */
  removeOneMappingRecord: function(field_ids) {
    if (Def.DataModel.initialized_ ) {
      for (var field_id in field_ids) {
        this.removeOneMappingField(field_id);
      }
    }
  },

  /**
   * find a field on form based on the triple of [table,column,position]
   *
   * @param table - taffy db table name
   * @param column - a column (field) name
   * @param position - row number in the table
   * @return field - the field on form
   */
  getFormField: function(table, column, position) {
    if (Def.DataModel.initialized_ ) {
      var db_key = table + Def.DataModel.KEY_DELIMITER +
      column + Def.DataModel.KEY_DELIMITER +
      position;
      var field_id = Def.DataModel.mapping_table_db_[db_key];
      return $(field_id);
    }
  },


/**
   * find a field ID on form based on the triple of [table,column,position]
   *
   * @param table - taffy db table name
   * @param column - a column (field) name
   * @param position - row number in the table
   * @return field_id - the ID of the field on form
   */
  getFormFieldId: function(table, column, position) {
    if (Def.DataModel.initialized_ ) {
      var db_key = table + Def.DataModel.KEY_DELIMITER +
          column + Def.DataModel.KEY_DELIMITER +
          position;
      var field_id = Def.DataModel.mapping_table_db_[db_key];
      return field_id;
    }
  },
  

  /**
   *  Returns one field in a row, given the position number in the data table.
   * @param table a data table name (e.g. phr_conditions)
   * @param position the position in the table (starting at 1 for the first row)
   */
  getFormFieldAtRowPosition: function(table, position) {
    var field = null;
    for (var col in this.model_table_[table]) {
      field = this.getFormField(table, col, position);
      if (field) break;
    }
    return field;
  },
  
  
  /**
   *  Returns all fields in a row, given the position number in the data table.
   * @param table a data table name (e.g. phr_conditions)
   * @param position the position in the table (starting at 1 for the first row)
   */
  getAllFormFieldsAtRowPosition: function(table, position) {
    var fields = [];
    for (var col in this.model_table_[table]) {
      var field = this.getFormField(table, col, position);
      if (field) {
        fields.push(field);
      }
    }
      
    return fields;
  },
  
  /**
   * find a taffy location of [table,column,position] for a field on form
   *
   * @param field_id - id of a field on form
   * @return taffy_location - [table,column,position]
   */
  getModelLocation: function(field_id) {
    if (Def.DataModel.initialized_ ) {

      var taffy_location = Def.DataModel.mapping_table_id_[field_id]
      return taffy_location;
    }
  },
  

  /**
   * return value of a column at a specified row in a speficied table
   *
   * @param table - taffy db table name
   * @param column - a cloumn (field) name
   * @param position - row number in the table
   * @return value - the value of the specified field
   */
  getModelFieldValue: function(table, column, position) {
    if (Def.DataModel.initialized_ ) {
      var taffy = Def.DataModel.taffy_db_[table];
      var record = taffy.get(position-1)[0];
      return record[column];
    }
  },
  /**
   * return value of a column at a specified row in a speficied table
   *
   * @param field_id - id of a field on form
   * @return value - the value of the specified field
   */
  getModelFieldValueById: function(field_id) {
    if (Def.DataModel.initialized_ ) {
      var taffy_location = Def.DataModel.mapping_table_id_[field_id];

      var taffy = Def.DataModel.taffy_db_[taffy_location[0]];
      var record = taffy.get(taffy_location[2]-1)[0];
      return record[taffy_location[1]];
    }
  },
  /**
   * return a record at a specified row in a speficied table
   *
   * @param table - taffy db table name
   * @param position - row number in the table
   * @return record - a hash that contains the value of the record
   *
   */
  getModelRecord: function(table, position) {
    if (Def.DataModel.initialized_ ) {
      var taffy = Def.DataModel.taffy_db_[table];
      var record = taffy.get(position-1)[0];
      return record;
    }
  },

  /**
   *
   * @param table_name - taffy db table name
   * @param options - an array of hash of search options.
   *              get the first search result from the first opt,
   *              run second search with the second opt againt the first result,
   *              and so on.
   *  keys in option:
   *     order - an array of {column: "desc"|"asc"}, or column to sort the
   *             result set. the default order is "asc"
   *             example: ["age",
   *                      {"name":"desc"}]
   *     limit - specifies how many records to be included in the result set
   *             example: 1
   *     conditions - taffydb supported search options
   *                  example: {state:["WA","MT","ID"],
   *                            age:{greaterthan:22}}
   * @param count - to return the record num in the LAST result set.
   *                default is false.
   *
   *
   * @return result - an array of records that meet the search conditons, or
   *                  the size of the result set
   */
  searchRecord: function(table_name, options, count) {
    var ret = null;
    var invalidOption = 0;
    if (Def.DataModel.initialized_ ) {
      var taffy = Def.DataModel.taffy_db_[table_name];
      if (taffy) {
        /*
        // if options["recency"] is true
        // merge obx_observation with it's obx_observaion_in_recency
        // do the same query again
        if(option["recency"]){
          var recency_taffy = Def.DataModel.taffy_db_[table_name+ "_recency"];
          taffy = new TAFFY(taffy.get().concat(recency_taffy.get()));
        }// needs to build and load obx_observation_in_recency taffy db
        */
        // TODO::needs to be merged into Def.DataModel.data_tables_.obx_observations per Paul
        if(table_name == "obx_observations"){
          var prefetched_taffy = Def.DataModel.taffy_db_[table_name+ "_prefetched"];
          if (prefetched_taffy != undefined && prefetched_taffy != null) {
            taffy = new TAFFY(taffy.get().concat(prefetched_taffy.get()));
          }
        }// needs to build and load obx_observation_in_recency taffy db

        for(var j=0, length=options.length; j<length; j++) {
          // get the result
          var option = options[j];
          var conditions = option["conditions"];
          var limit = option["limit"];
          var order = option["order"];
          // reset local variables
          var result_idx =null;
          var result = null;
          var new_data = null;
          var limited_result = null;
          var new_taffy = null;
          // has conditions
          if (conditions != undefined && conditions != null) {
            result_idx = taffy.find(conditions);
            result = taffy.get(result_idx);
            // make a copy
            new_data = Def.deepClone(result);
            new_taffy = new TAFFY(new_data);
            // sort the db, if there's an 'order'
            if (order != undefined && order != null) {
              new_taffy.orderBy(order)
            }
            // get the first few records, if there's a 'limit'
            if (limit != undefined && limit != null) {
              var rec_range = [];
              var i=0;
              var rec_num = new_taffy.getLength();
              while (i < limit && i < rec_num) {
                rec_range.push(i);
                i++;
              }
              limited_result = new_taffy.get(rec_range);
            }
            // create a new taffy db, assign it to the variable of taffy
            if (limited_result != [undefined] && limited_result != undefined  &&
              limited_result != [null] && limited_result != null) {
              taffy = new TAFFY(limited_result);
            }
            else {
              taffy = new_taffy;
            }
          }
          // no conditions
          else {
            // no limit and no order, abort serach, return null
            if ((order == undefined || order == null) &&
              (limit == undefined || limit == null) ) {
              invalidOption +=1;
              continue;
            }
            // has limit and/or order
            else {
              result = taffy.get();
              // make a copy
              new_data = Def.deepClone(result);
              // create a new taffy db
              new_taffy = new TAFFY(new_data);
              // sort the db, if there's an 'order''
              if (order != undefined && order != null) {
                new_taffy.orderBy(order)
              }
              // get the first few records, if there's a 'limit'
              if (limit != undefined && limit != null) {
                var rec_range = [];
                var i=0;
                var rec_num = new_taffy.getLength();
                while (i < limit && i < rec_num) {
                  rec_range.push(i);
                  i++;
                }
                limited_result = new_taffy.get(rec_range);
              }
              // create a new taffy db, assign it to the variable of taffy
              if (limited_result != [undefined] && limited_result != undefined  &&
                limited_result != [null] && limited_result != null) {
                taffy = new TAFFY(limited_result);
              }
              else {
                taffy = new_taffy;
              }
            }
          }
        }
      }
      // if get a search result set
      if (taffy != null) {
        if (count == undefined || count == null) {
          count = false;
        }
        // get result set size if count is supplied
        if (count) {
          ret = taffy.getLength();
        }
        // otherwise return the data array of the result set
        else {
          ret = taffy.get();
        }
      }
      // if search does not complete
      else {
        ret = null;
      }
    }
    if (options.length === invalidOption) {
      return null;
    }
    else {
      return ret;
    }
    
  },

  /**
   * check if the keys in mapping_table_id_ are valid element ids on the form
   *
   */
  checkElementIDs: function() {
    var all_valid = true;
    for (var ele_id in Def.DataModel.mapping_table_id_) {
      var dom_element = $(ele_id);
      var db_loc = Def.DataModel.mapping_table_id_[ele_id];
      if (dom_element == null || dom_element == undefined) {
        Def.Logger.logMessage(["invalid element id: ", ele_id, 
          "\n      table: " + db_loc[0],
          "\n     column: " + db_loc[1],
          "\n    rec num: " + db_loc[2]]);
        all_valid = false;
      }
      else {
    //Def.Logger.logMessage(["  valid element id: ", ele_id]);
    }
    }
    if (all_valid) {
      Def.Logger.logMessage(["  all element ids are valid."]);
    }
  },

  /**
   * set up the data model and load data into the form
   * @param form_data form data returned from server
   * @param create_table_row a flag indicating if new empty rows need to be
   *    created, default value is true. It's false only when it is used in
   *    the 'edit in place' function on flowsheet.
   * @param recoveredData an object used to indicate which fields, if any,
   *    are "recovered data", that is, data from the autosave_tmps table that
   *    hasn't been saved yet.  The object is an array of 2 hashes.  The first
   *    is a hash, keyed by table name, indicating which rows are unsaved
   *    additions.  The second is the recovered data from the autosave_tmp
   *    table.
   * @param doAutosave flag to indicate whether or not to execute actions
   *    related to the autosave function.  Default is true.  Passed through
   *    to initDataModel.
   */
  setup: function(form_data, create_table_row, recoveredData, doAutosave) {

    if (create_table_row == undefined || create_table_row == null) {
      create_table_row = true;
    }
    if (recoveredData == undefined) {
      recoveredData = [null, null] ;
    }
    var start = new Date().getTime();
    if (form_data != null) {
      this.initDataModel(form_data[0], form_data[1], form_data[2], form_data[3],
                         form_data[4], recoveredData[1], doAutosave);
      this.setupModelListener();
      var table2GroupHash = {} ;
      if (create_table_row) {
        var start2 = new Date().getTime();
        // add the rows, passing in the added_rows hash from the recovered data
        table2GroupHash = this.addFormTableRows(Def.DataModel.table_2_group_, 
                                                true,
                                                recoveredData[0]);
        Def.Logger.logMessage(['(1) add form table rows in ',
                               (new Date().getTime() -start2), 'ms']);
      }
      var start3 = new Date().getTime();
      //this.loadFormData(form_data[1], table2GroupHash, recoveredData[0]);
      this.loadFormData(Def.DataModel.mapping_table_id_, table2GroupHash);

      // set up styles if there's recovered data, passing in the added_rows
      // part of the recovered data
      if (Def.DataModel.recovered_fields_) {
        this.setRecoveredStyles(table2GroupHash, recoveredData[0]);
      }      
      
      Def.Logger.logMessage(['(2) loaded data in ',
                             (new Date().getTime() -start3), 'ms']);
      $('content').style.display = 'block' ;
    }
    Def.Logger.logMessage(['(1+2) data model setup in ',
                           (new Date().getTime() -start), 'ms']);

  }, // setup


  /**
   *  Append data into the current data model and load data into the form.
   * @param form_data form data returned from serer
   * @param create_table_row a flag indicating if new empty rows need to be
   *    created, default value is true. it's false only when it is used in
   *    the 'edit in place' function on flowsheet.
   */
  append: function(form_data, create_table_row) {
    if (create_table_row == undefined || create_table_row == null) {
      create_table_row = true;
    }
    var start = new Date().getTime();
    if (form_data != null) {
      this.addNewDataModel(form_data[0], form_data[1], form_data[2],
        form_data[3]);
      // load data into form
      this.setupModelListener();
      
      if(create_table_row) {
        var discard = this.addFormTableRows(form_data[3], false);
      }
      this.loadFormData(form_data[1]);
    }
    Def.Logger.logMessage(['loaded data in ',
      (new Date().getTime() -start), 'ms']);

  },

  /**
   *  Adds the form table rows that are needed to accomodate the data.
   * @param table_2_group a mapping of data table names to group ids and the
   *  number of rows the group table needs.  (See the comments on initDataModel
   *  for details.)
   * @param loading a flag indicating whether or not we are calling this from
   *  from the data loading process.  If so, we omit certain field setting
   *  operations (setting up navigation, event handlers, etc), assuming those
   *  will be taken care of after all the data is loaded.  In addition, we
   *  populate a table2GroupHash and return it to be used in subsequent loading
   *  operations (see loadFormData).
   * @param addedRows an optional hash that indicates which rows have been
   *  added to a table.  This is used only when loading recovered data, where
   *  we need to know which rows were added during the course of the updates
   *  that are being restored
   * @returns table2GroupHash a hash that provides table header field names
   *  via a hash that uses the table name as a key.  Only created when loading
   *  data (loading parameter is true).  Otherwise an empty hash is returned.
   */
  addFormTableRows: function(table_2_group, loading, addedRows) {

    if (addedRows === undefined)
      addedRows = null ;
    var fieldsTable = Def.FieldsTable; // no significant improvement in speed
    var table2GroupHash = {} ;   
    
    // process each table on the form
    for (var i=0, max=table_2_group.length; i<max; ++i) {
      var tableName = table_2_group[i][0]; 
      var tableData = table_2_group[i][1]; // [[group header id, row count]]
      if (loading)
        table2GroupHash[tableName] = tableData[0] ;
      
      // process each group, where tables with nested tables will have
      // multiple groups (e.g. test data)
      for (var j=0, maxJ = tableData.length; j<maxJ; ++j) {
        var groupData = tableData[j]; // [group header id, row count]
        var fieldGroupID = groupData[0];
        var fieldGroup = $(fieldGroupID);

        // Don't add any rows to tables that won't appear on the form.
        // For example, the tests section is omitted from the form when the
        // user only has read access to the profile.
        if (fieldGroup !== null) {
          var tableID = fieldGroupID + '_tbl';
          var tableElem = $(tableID);
          var isCETable = fieldGroup.ce_table != null;
          // Figure out how many rows to actually add.  There are two cases:
          // 1) the table is empty, except perhaps for a blank row
          // 2) there is existing data already in the table (e.g. when a new
          //    test panel is added to the form or we are loading recovered data.
          // Assumption-- since we are loading data, we do not need to be
          // concerned with whether we are running up against the maximum number
          // of responses for the table.  Assume that a table can contain the
          // needed number of additional rows (but maybe not another blank row).
          var table = fieldGroup.down('table');
          // numExistingRows (below) may include a blank row (which we can use).
          var numExistingRows = parseInt(table.readAttribute('nextid')) - 1;
          var maxResponses = this.getMaxResponses(fieldGroup);
          var isTestPanel = (fieldGroupID.substr(0,5) == 'fe_tp');
          if (isTestPanel) {
            // When a test panel/section is blank, max_repsonses is 0.  In this
            // case only is there a blank row.
            var numExistingBlank = maxResponses==0 ? 1 : 0;
          }
          else
            numExistingBlank = numExistingRows > 0 ? 1 : 0;
          var numNewDataRows = groupData[1]; //Number of rows of data being loaded
          var newTotalNumDataRows =
                              numExistingRows - numExistingBlank + numNewDataRows;
          if (isTestPanel) {
            // For test panels, we never want to show a new row, so we set
            // the maximum number of rows to be the actual number of rows.
            maxResponses = newTotalNumDataRows;
            fieldGroup.setAttribute('max_responses', maxResponses);
          }
          var addBlankRow = !isTestPanel && 
                      Def.formEditability_ !== Def.FORM_READ_ONLY_EDITABILITY &&
                      (maxResponses == 0 || newTotalNumDataRows < maxResponses);
          var numDataRowsToAdd = numNewDataRows - numExistingBlank;

          if (isCETable) {
            if (addedRows && addedRows[tableName]) {
              var tableAdds = addedRows[tableName].length ;
              numDataRowsToAdd -= tableAdds ;
            }
            else
              tableAdds = 0 ;
            if (numDataRowsToAdd > 0)
              fieldGroup.ce_table.createReadOnlyRows(tableElem, numDataRowsToAdd);
            if (addBlankRow || tableAdds > 0)
              fieldsTable.addTableLine(tableElem, null, 1 + tableAdds, loading);
            if (numNewDataRows === 0 && 
                Def.formEditability_ === Def.FORM_READ_ONLY_EDITABILITY)
              fieldsTable.addNoDataLine(tableElem, fieldGroupID)
          }
          else {
            var editableRows = numDataRowsToAdd + addBlankRow;
            if (editableRows > 0) {
              fieldsTable.addTableLine(tableElem, null, editableRows, loading);
            }
          }
        } // end if the table does exist on the form.
      }
    }
    return table2GroupHash ;
  }, // end addFormTableRows


  /**
   *  Returns the maximum number of rows for the given horizontal field group.
   * @param fieldGroup the DOM element of a horizontal field group.
   */
  getMaxResponses: function(fieldGroup) {
    // The max_responses from the group header is a string that needs
    // to be converted to an integer.  Default is 0 if it's not there.
    var maxResponses = 0 ;
    if (fieldGroup.readAttribute) {
      maxResponses = parseInt(fieldGroup.readAttribute('max_responses'));
      if (isNaN(maxResponses))
        maxResponses = 0 ;
    }
    return maxResponses;
  },


  /**
   *  Change the table's max_responses value based on the actual length of the
   *  panel array or test array
   * @param fdName the field's target_field
   * @param group_hdr the DOM object of the group header
   * @param maxResponses the existing value of max_responses
   * @param numDataRows the number of data rows
   * @return maxResponses the new value of max_responses
   */
  setTestPanelMaxResponses: function(fdName,group_hdr,maxResponses,
    numDataRows) {
    var index = fdName.indexOf('_');
    var str_field = fdName.substr(index);
    if (str_field == '_loinc_panel_temp_grp' ||
      str_field == '_loinc_panel_temp_test') {
      maxResponses = numDataRows;
      group_hdr.setAttribute('max_responses', maxResponses);
    }
    return maxResponses;
  },


  /**
   * refresh values in form fields from the data in taffydb
   */
  refreshFormData: function() {
    this.loadFormData(this.mapping_table_id_);
  },


  /**
   *  Set up styles for the recovered data by going through the recovered data 
   *  when the form is being loaded.
   *  
   * @param table2GroupHash optional hash that provides top-level field names
   *  for tables.  Used to determine whether or not a particular table is a
   *  controlled edit table.
   * @param addedRows is an optional parameter that is used to determine whether
   *  or not a recovered row was being added by the user.
   */
  setRecoveredStyles: function(table2GroupHash, addedRows) {
    if (addedRows === undefined)
      addedRows = null ;
    var editedRows = {} ;
    var deletedRows = {} ;
    var panelDeleted = {};

    //if there's recovered data
    if (this.recovered_fields_) {
      // for each user table in the recovered data
      for (var tableName in this.recovered_fields_) {
        var recovered_table_data = this.recovered_fields_[tableName];
        // for each row in the user table
        for (var rowNo in recovered_table_data) {
          var rowNum = parseInt(rowNo);
          var recovered_columns = recovered_table_data[rowNum];
          // for each column in the row
          for (var i=0, ilen=recovered_columns.length; i<ilen; i++) {
            var columnName = recovered_columns[i];
            var fieldValue = this.data_table_[tableName][rowNum-1][columnName];
            var fieldID = this.getFormFieldId(tableName,columnName,rowNum);
            var formField = $(fieldID);
            // if formField exists on the page 
            if (formField != null) {
              // for recovered test panel records on panel_edit form
              if (this.form_name_ == 'panel_edit') {
                // if the panel is being edited
                formField.addClassName('recovered'); 
                // make the row visible in case the test is opional and therefor
                // hidden at the moment
                var elemRow = $(formField.parentNode);
                while (elemRow.tagName != 'TR') 
                  elemRow = $(elemRow.parentNode) ;
                if (elemRow.hasClassName('test_optional'))
                  elemRow.addClassName('containsRecovered') ;            

                // if the panel is being deleted, keep the obr record row num 
                // and set the sytle later 
                if (tableName == this.OBR_TABLE && 
                    typeof fieldValue == 'string' &&
                    fieldValue.substr(0,6) == 'delete') {
                  panelDeleted[rowNum]=fieldValue.substr(7);
                }                  
              }
              // for all other forms (PHR only for now)
              else {
                // For fields in an added row, make sure the row gets the
                // 'recovered' class so that the whole row gets outlined.
                // Also add the 'no_hide' class so that the row is not hidden
                // on the form (say, if it's a stopped drug and only the active
                // ones are being shown
                if (addedRows != null && addedRows[tableName] != null &&
                    addedRows[tableName].indexOf(rowNum) >= 0) {
                  var tr = getAncestor(formField, 'TR') ;
                  if (tr) {
                    tr.addClassName('recovered') ;
                    tr.addClassName('no_hide') ;
                  }
                  else {
                    formField.addClassName('recovered') ;
                  }
                }
                else {
                  var fieldGroupID = table2GroupHash[tableName][0] ;
                  // make sure there's something in for the
                  // row in the deletedRows hash; and add the recovered class to
                  // the row.  And the no_hide class - see above.
                  if (typeof fieldValue == 'string' &&
                      fieldValue.substr(0,6) == 'delete') {
                    if (deletedRows[fieldGroupID] == null)
                      deletedRows[fieldGroupID] = {} ;
                    if (deletedRows[fieldGroupID][rowNum] == null)
                      deletedRows[fieldGroupID][rowNum] = fieldID ;
                    tr = getAncestor(formField, 'TR') ;
                    tr.addClassName('recovered') ;
                    tr.addClassName('no_hide') ;
                  }
                  // For an edited field in an existing row, add the recovered 
                  // class to either the form field or, if it's in a controlled
                  // edit table, to the containing cell, and make sure that 
                  // there is something in the editRows hash for the field's 
                  // row.  If the field is in a row also add 'no_hide' to the 
                  // containing row so that the row can't get hidden by 
                  // something else - see above.
                  else {
                    var tbl = getAncestor(formField, 'TABLE', true);
                    if (tbl && tbl.hasClassName('dateField'))
                      var td = getAncestor(tbl, 'TD') ;
                    else
                      td = getAncestor(formField, 'TD');
                    if (td)
                      td.addClassName('recovered') ;
                    else 
                      formField.addClassName('recovered');
                    tr = getAncestor(formField, 'TR') ;
                    if (tr)
                      tr.addClassName('no_hide') ;

                    if (editedRows[fieldGroupID] == null)
                      editedRows[fieldGroupID] = {};
                    if (editedRows[fieldGroupID][rowNum] == null)
                      editedRows[fieldGroupID][rowNum] = fieldID;
                  } // end if the row was/was not deleted
                } // end if row was/was not added     
                // if this a field in the embeded test panel group
                // make the row visible in case the test is optional and 
                // therefore hidden at the moment
                if (fieldID.substr(0,5) == 'fe_tp') {            
                  elemRow = $(formField.parentNode);
                  while (elemRow.tagName != 'TR') 
                    elemRow = $(elemRow.parentNode) ;
                  if (elemRow.hasClassName('test_optional'))
                    elemRow.addClassName('containsRecovered') ;                          
                }
              } // end if the form is panel_edit or phr          
            } // end if formField valid  
          } // end of each column
        } // end of each row
      } // end of each user table      

      // If we're working with recovered fields we'll have a table2GroupHash,
      // and we need to set any controlled edit rows with recovered data.
      if (table2GroupHash)
        this.setRecoveredCEData(editedRows, deletedRows) ;

      // set the sytles for deleted test panel records
      // for each test panel record
      for (var obrNum in panelDeleted) {
        //var obrRecordId = panelDeleted[rowNum];
        var obrFields = this.getAllFormFieldsAtRowPosition(this.OBR_TABLE, 
            obrNum);
        var taffy = this.taffy_db_[this.OBX_TABLE];
        var obxNums = taffy.find({_p_id_:obrNum-1});
        var obxFields = [];
        // get obx fields
        for(var k=0, lk=obxNums.length; k<lk; k++) {
          var fields = this.getAllFormFieldsAtRowPosition(this.OBX_TABLE, 
              obxNums[k]+1);
          obxFields = obxFields.concat(fields);
        }

        // for obr fields, marked as deleted
        for(var j=0,l=obrFields.length; j<l; j++){
          formField = $(obrFields[j]);
          if(formField) {
            // remove the calendar button if it is a date field
            tbl = getAncestor(formField, 'TABLE', true);
            if (tbl && tbl.hasClassName('dateField')) {
              var img = tbl.down('img.ffar_calendar');
              if (img) img.style.display = 'none';
            }
            formField.disabled = true;
            formField.style.color = 'black';
            formField.addClassName('deleted');
            // mark the containing td as 'deleted'so it background could be set
            formField.up('td').addClassName('deleted');
          } // end if formField exists
        } // end obr fields

        // for obx fields, only test_value is marked as deleted
        for(j=0,l=obxFields.length; j<l; j++){
          formField = $(obxFields[j]);
          if(formField) {
            formField.disabled = true;
            formField.style.color = 'black';
            if(formField.id.match(/test_value/)) {
              formField.addClassName('deleted');
              // mark the containing td as 'deleted'so it background 
              // could be set
              formField.up('td').addClassName('deleted');            
            }
          } // end of if formField exists
        } // end of obx fields
      } // end of setting styles for deleted test panels
    } // end of if it has recovered data
  },


  /**
   *  Loads the data on the form based on the given data model.  This assumes
   *  that table lines have been added to accomodate the data.
   * @param mapping_table_id (See the description in the initDataModel method
   *  comment.)
   * @param table2GroupHash optional hash that provides top-level field names
   *  for tables.  Used to determine whether or not a particular table is a
   *  controlled edit table.
   */
  loadFormData: function(mapping_table_id, table2GroupHash) {

    if (table2GroupHash === undefined)
      table2GroupHash = null ;
    for (var fieldID in mapping_table_id) {
      var fieldDataLoc = mapping_table_id[fieldID];
      var tableName = fieldDataLoc[0];
      if (tableName !== null) { // as it happens to be for drug_id on rxterms_demo
        var columnName = fieldDataLoc[1];
        var rowNum = fieldDataLoc[2];      
        var fieldValue = this.data_table_[tableName][rowNum-1][columnName];

        // Care is needed in the test below, because false == ''
        if (fieldValue != null &&
          (typeof fieldValue != 'string' || fieldValue != '')) {
          var formField = $(fieldID);
          // if formField exists on the page -- is it possible not to???
          if (formField != null) {

            if (typeof fieldValue != 'object') {
              Def.setFieldVal(formField, fieldValue, false);
            }
            else {
              // The object should be an array.  Decide what to do with it.
              if (fieldValue.length > 1 && typeof fieldValue[1] != 'string') {
                // This is an array of data for a prefetched autocompleter field.
                var listItems = fieldValue[1];
                var listCodes = fieldValue[2];
                var acOpts = fieldValue[3];
                fieldValue = fieldValue[0];
                Def.setFieldVal(formField, fieldValue, false);
                // create an autocomp object if it does not exist on the formField
                // used by edit in place on flowsheet page
                if (formField.autocomp == null) {
                  var opts = {};
                  opts['matchListValue']=true;
                  opts['suggestionMode']=0;
                  opts['autoFill']=true;
                  if (acOpts) {
                    if (acOpts['matchListValue'])
                      opts['matchListValue']=acOpts['matchListValue'];
                    if (acOpts['suggestionMode'])
                      opts['suggestionMode']=acOpts['suggestionMode'];
                    if (acOpts['autoFill'])
                      opts['autoFill']=acOpts['autoFill'];
                  }
                  new Def.Autocompleter.Prefetch(fieldID, [], opts);
                  formField.autocomp.setList(listItems, listCodes);
                }
                else {
                  if (!acOpts ||  !acOpts['keepList'])
                    formField.autocomp.setList(listItems, listCodes);
                }

                // should also remove the list part in the data_table_
                this.data_table_[tableName][rowNum-1][columnName] = fieldValue;
              }
            }
            // Add special handling for test panels try to speed up by avoiding
            // unnecessary regular expression comparison
            // execution time saved by 50%
            if (fieldID.substr(0,5) == 'fe_tp') {
              var idParts = Def.IDCache.splitFullFieldID(fieldID);
              Def.DataLoader.setTestPanelStyle(idParts[1], formField, idParts[2],
                fieldValue);
            }
          } // end if formField valid
        } // end if fieldValue valid
      } // if there is a table name
    } // end each field id
  } , // end loadFormData


  /**
   *  Sets up any controlled edit table lines that have received recovered data.
   *  Unlike previously saved data that is loaded into the controlled edit
   *  tables, unsaved data needs to be presented in the condition in which it
   *  was entered.  Specifically, added lines need to be fully editable;
   *  edited lines need to be in the revision state (not read-only) and
   *  deleted lines need to show in the deleted state.
   *
   *  This calls methods in the Def.FieldsTable.ControlledEditTable class to
   *  set the rows as appropriate.
   *
   * @param editedRows hash that has one entry for every row that has an edited
   *  field in it.  Does not include added or deleted rows.
   * @param deletedRows hash that has one entry for every deleted row.
   */
  setRecoveredCEData: function(editedRows, deletedRows) {
    for (var fgID in editedRows) {
      var ceTable = $(fgID).ce_table ;
      if (ceTable) {
        var eRows = editedRows[fgID] ;
        for (var rowNum in eRows) {
          ceTable.initMenuLocation(eRows[rowNum], false) ;
          ceTable.editRow(false) ;
        } // end do for each row number
      } // end if a controlled edit table was found for this group
    } // end do for each group in the editedRows hash
    for (fgID in deletedRows) {
      ceTable = $(fgID).ce_table ;
      if (ceTable) {
        var dRows = deletedRows[fgID] ;
        for (rowNum in dRows) {
          ceTable.initMenuLocation(dRows[rowNum], false) ;
          ceTable.editRow(false) ;
          ceTable.deleteRow(false) ;
        } // end do for each row number
      } // end if a controlled edit table was found for this group
    } // end do for each group in the deletedRows hash
  } // end setRecoveredCEData


}; // end Def.DataModel
