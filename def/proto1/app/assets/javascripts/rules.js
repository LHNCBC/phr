// JavaScript for handling the rules.

Def.Rules = { // Namespace for the rule stuff
  logLevel : null, // when set to "debug", will show log messages in console
                   // we may also add other log levels including info, warn and
                   // error etc as needed
  timeEachRule: null, // Logs the time for running each rule
  nonDOM_ : false, // a flag indicating if rules are running with or without DOM
  defaultDelimiter_ : "|"
};

Def.Rules.Exceptions = {}; // a namespace for exceptions used by the rule code
Object.extend(Def.Rules.Exceptions, {
  NoVal: Class.create() // no value for the rule
});

Object.extend(Def.Rules.Exceptions.NoVal.prototype, {
  /**
   * The constructor.  Takes a message for the exception.
   */
  initialize: function(msg) {
    this.message = msg;
  }
});


// Define the cache.  Note that we just need one of these, so I am defining
// Cache directly, rather than Cache.prototype.
Def.Rules.Cache = {
  ruleVals_: {},  // cached values of rules

  /**
   *  Returns the cached value of the rule, or throws an exception if there
   *  is no value for the rule.
   * @param rule_name the name of the rule for which the value is needed
   */
  getRuleVal: function(rule_name) {
    var rtn = this.ruleVals_[rule_name];
    if (rtn == null) {
      throw new Def.Rules.Exceptions.NoVal('No cached value for rule ' +
        rule_name);
    }
    return rtn;
  },


  /**
   *  Sets the cached value of the rule.
   * @param rule_name the name of the rule for which the value is needed
   * @param value the new value for the rule
   */
  setRuleVal: function(rule_name, value) {
    this.ruleVals_[rule_name] = value;
    // by enabling debug status, user can monitor realtime rule updating
    if(Def.Rules.logLevel == "debug")
      Def.Logger.logMessage(["rule => ", rule_name, "; value => ",
        Object.toJSON(value) ]);
  },


  /**
   *  Removes a rule value from the cache.
   * @param ruleName the name of the rule whose value should be removed.
   */
  removeRuleVal: function(ruleName) {
    this.ruleVals_[ruleName] = null;
  } ,

  /**
   * Displays all current rule values in a special area of a form
   * that should be accessible only to administrative users.
   */
  displayRuleVals: function() {
    // create/recreate the table
    var rulesTableBody = $('rule_values_table_body') ;
    Def.removeAllChildNodes(rulesTableBody) ;
    var rulesHash = $H(this.ruleVals_) ;
    var ruleKeys = rulesHash.keys() ;
    ruleKeys.sort(function(a,b) {
      var aa = String(a).toLowerCase() ;
      var bb = String(b).toLowerCase() ;
      var ret = 0 ;
      if (aa < bb)
        ret = -1 ;
      else
        if (aa > bb)
          ret = 1 ;
      return ret ;
    }) ;
    var keysLength = ruleKeys.length ;
    //for (var ruleName in ruleKeys) {
    for (var r = 0; r < keysLength; r++) {

      var nameCell = document.createElement('td') ;
      nameCell.innerHTML = ruleKeys[r] ;

      var valueCell = document.createElement('td') ;
      var val = this.ruleVals_[ruleKeys[r]] ;
      if (val != null && val != '' && typeof val != "string" &&
          typeof val != "boolean" && typeof val != "number" &&
          val.constructor != Date) {
        try {
          var objVal = '' ;
          for (var key in val) {
            if (val[key] != null && val[key].constructor != Function) {
              if (val[key].constructor == HTMLDivElement)
                objVal += key + ' = ' + Def.getFieldVal(val[key]) ;
              else
                objVal += key + ' = ' + val[key] + '; ';
            }
          }
          val = objVal.substr(0, objVal.length - 2) ;
        }
        catch (e) {
          Def.reportError(e);
        }
      }
      valueCell.innerHTML = val ;

      var rowNode = document.createElement('tr') ;
      rowNode.appendChild(nameCell);
      rowNode.appendChild(valueCell);
      rulesTableBody.appendChild(rowNode) ;
    }
    // If this is the first time we're displaying the table, make sure
    // it's visible and reset the button text
    var valDiv = $('rule_values') ;
    if (valDiv.style.display == "none") {
      valDiv.style.display = "block" ;
      $('rule_values_table_title').scrollIntoView(false) ;
      $('rule_values_button_text').innerHTML = 'Update Current Rule Values' ;
    }
  } // end displayRuleVals


};

var defRules = {
  /**
   *  A queue of message actions (an array of parameters to the add_message
   *  action) waiting to be run.
   */
  messageQueue_: [],

  /**
   * List of actions needs to be processed at the end of a run of rules
   **/
  postProcessedActions_: ['add_message','add_table_messages'],

  /**
   *  A hash of the form rule names for checking whether the rule is a data
   *  rule or not.
   */
  dataRuleHash_: null,

  /**
   * A boolean value indicating whether current process is in the middle of
   * queueing messages
   */
  messageQueueing_ : false,


  /**
   *  Returns true if the given rule name is a data rule.
   * @param ruleName the name of the rule
   */
  isDataRule: function(ruleName) {
    if (!this.dataRuleHash_) {
      var tmpHash = {};
      var dataRuleNames = this.dataRules_;
      for (var i=0, max=dataRuleNames.length; i<max; ++i)
        tmpHash[dataRuleNames[i]] = 1;
      this.dataRuleHash_ = tmpHash;
    }
    return this.dataRuleHash_[ruleName] == 1;
  },


  /**
   * Checks to see if a field has rules.  A field is assumed to have rules if
   * it's in the fieldRules_ hash and the value for it isn't blank
   *
   * @param field the field to be checked
   * @returns boolean
   */
  hasRules: function(field) {
    var has = false ;
    if (field != null)
      has =  this.findRules(field).length > 0;
    return has;
  },


  /**
   * Returns array of rules being triggered by the input triggerField
   *
   * @param triggerField a trigger field
   */
  findRules:function(triggerField){
    var triggerName = Def.IDCache.splitFullFieldID(triggerField.id)[1];
    var  rules = [];
    if(TestPanel.inTestPanel(triggerName)){
      // converts tp1 in triggerName into tp
      var targetField = TestPanel.getRealTargetName(triggerName);
      // finds all rules associated with target field only
      if(this.fieldRules_[targetField])
        rules = this.fieldRules_[targetField].clone();
      // finds all the rules associated with loinc field (ie. a field defined by
      // a combination key of target_field and loinc number)
      var loincRules = TestPanel.findLoincRules(triggerField);
      // assuming rules and loincRules are not referencing each other
      rules = rules.concat(loincRules);
    }
    else{
      if(this.fieldRules_ && this.fieldRules_[triggerName])
        rules = this.fieldRules_[triggerName].clone();
    }
    return rules;
  },


  /**
   *  Runs all of the rules for the form.  This is used when the page loads.
   *  @params formRules all or part of rules used on the current form. The rules
   *  are ordered based on the rule dependencies
   */
  runFormRules: function(formRules) {
    //if (formRules === undefined || formRules.length === undefined)
    if (!formRules)
       formRules = Def.Rules.formRules_;
    // Run each of the rules in formRules_.  For each rule, run the rule and
    // its associated actions (if any) for each instance of the trigger field
    // stored in the ruleTrigger_ map.  If there isn't a trigger field for
    // a rule, use the last trigger field.  (In that case, it really shouldn't
    // matter what the trigger field is, but we pass one in to keep the code
    // from complaining.)
    var start = new Date().getTime();
    if (formRules) {
      if (!this.messageQueueing_){
        this.messageQueueing_ = true;
        var allowProcess = true;
      }

      var numRules = formRules.length;
      var triggerField = null;
      var lastValidTriggerField = null;
//      var lastValidTriggerFieldIDParts = null;
      var lastValidTriggerFieldIDParts = [];
//      var triggerFieldIDParts = null;
      var triggerFieldIDParts = [];
      var func_findFields = findFields;
      var idCache = Def.IDCache;
      for (var i=0; i<numRules; ++i) {
        var ruleName = formRules[i];
        // triggerFieldName may either be a single target field(e.g. problem)
        // or target field joined by loinc number with ":"
        // (e.g. tp_test_value:8480-6)
        var triggerFieldName = Def.Rules.ruleTrigger_[ruleName];
        if (triggerFieldName == null) {
          // Run the rule with the last trigger field.  (See note above.)
          //Def.Rules.runOneRule(ruleName, triggerField, triggerFieldIDParts);
          // Third element in the following array cannot be anything since
          // it may affect finding correct affected field(s) of the rule's associated action(s)
          lastValidTriggerFieldIDParts = ["fe_", lastValidTriggerFieldIDParts[1],""];
          Def.Rules.runOneRule(ruleName, lastValidTriggerField, lastValidTriggerFieldIDParts);
         }
        else {
          var triggers = func_findFields(
            Def.FIELD_ID_PREFIX, triggerFieldName, '');
          var hasLoincNumInTrigger =
          triggerFieldName.indexOf(TestPanel.FIELD_LOINC_NUM_DELIMITER) > -1;
          // some tests are not on the form when it's just loaded
          var numTriggers = triggers.length;
          for (var j=0; j<numTriggers; ++j) {
            triggerField = triggers[j];
            triggerFieldIDParts = idCache.splitFullFieldID(triggerField.id);
            if(hasLoincNumInTrigger ||
              // remove invisible trigger fields
              (!hasLoincNumInTrigger && (triggerFieldIDParts[2].substr(0,2) != '_0'))){
              Def.Rules.runOneRule(ruleName, triggerField, triggerFieldIDParts);
              lastValidTriggerField = triggerField;
              lastValidTriggerFieldIDParts = triggerFieldIDParts;
            }
          } // each trigger field instance
        } // if there is a trigger field name
      } // each rule

      // Now run any pending "add_message" actions in the queue.  We do these
      // afterward because the messages can contain rule values.
      if (allowProcess == true)
        Def.Rules.processMessageQueue();
      var finish = new Date().getTime();
      Def.Logger.logMessage(['ran all rules in ', (finish-start),
                             'ms-- may include IDCache initialization time']);
    } // if there are rules
  }, // runformRules function


  /**
   *  Runs the rules for the given field, and executes associated actions.
   *  If an exception occurs, the running of the rules stops.
   */
  runRules: function(triggerField) {
    //var start = new Date().getTime();
    // Reset the message queue
    //
    // runRules() can be triggered by set_or_clear_value action of a form rule,
    // therefore if runRules() was called in the middle of executing runFormRules(),
    // the messageQueue may contain something and should not be cleared
    //

    var rules = this.findRules(triggerField);

    if (rules != null) {
      // If messageQueueing_ status is not true, sets the messageQueueing_ status
      // to true and generate reminder messages when finishing running all the
      // rules here. If messageQueueing_ is true, then keeping  queueing reminder
      // messages but do not generate reminders.
      if(this.messageQueueing_ != true){
        this.messageQueueing_ = true;
        var allowProcessing   = true;
        //this.messageQueue_    = [];
      }

      // if field_options_apply is one of the rules, make
      // sure it's the first to run
      var max = rules.length ;
      if (max > 1 && rules[0] != 'field_options_apply') {
        var found = false ;
        for (var i = 1; i < max && found == false; ++i) {
          if (rules[i] == 'field_options_apply') {
            found = true ;
            var fld_opts = rules.splice(i, 1).toString() ;
            rules.unshift(fld_opts) ;
          } // end if we found it
        } // end looking for set_fb_fields
      } // end if there's more than one action here

      for (var j=0; j<max; ++j) {
        var id_parts = Def.IDCache.splitFullFieldID(triggerField.id);
        this.runOneRule(rules[j], triggerField, id_parts);
      } // for each rule for field triggerField

      // Now run any pending "add_message" actions in the queue.  We do these
      // afterward because the messages can contain rule values.
      if(allowProcessing == true)
        this.processMessageQueue();
      //var finish = new Date().getTime();
      //Def.Logger.logMessage(["ran rules in ", (finish-start), "ms",
      //                       " for triggerField.id = " + triggerField.id]);
    } // end if there are rules to run
  }, // function runRules


  /**
   * Runs rules which have actions on the fields
   * @param rowFields list of rows with fields
   **/
  runRulesForFields: function(fields) {
    var ruleAndParams = [], rulesProcessed = {};
    // Gets rules (including parameters needed to run each rule)
    for (var i=0, imax=fields.length; i<imax; i++) {
      var affectedIdParts = Def.IDCache.splitFullFieldID(fields[i].id);
      var prefix = affectedIdParts[0];
      var suffix = affectedIdParts[2];
      var affectedFieldRules = Def.Rules.affectedFieldRules_[affectedIdParts[1]];
      if (affectedFieldRules && affectedFieldRules.length > 0) {
        for (var j=0, jmax = affectedFieldRules.length; j<jmax; j++) {
          var params = [ affectedFieldRules[j], prefix, suffix ];
          if (!rulesProcessed[params]) {
            rulesProcessed[params] = 1;
            ruleAndParams.push(params);
          }
        }
      }
    }

    // Run the rules
    if (ruleAndParams.length > 0) {
      for (i=0, imax=ruleAndParams.length; i<imax; i++) {
        var params = ruleAndParams[i];
        var ruleName = params[0];
        var trigger = Def.Rules.ruleTrigger_[ruleName];
        var triggerField = findFields(params[1], trigger, params[2])[0];
        var triggerIdParts = Def.IDCache.splitFullFieldID(triggerField.id);
        Def.Rules.runOneRule(ruleName, triggerField, triggerIdParts);
      }
    }
  },


  /**
   *  Runs the "add message" or "add_table_messages" actions that were queued up
   *  during a run of rules.  After this is over, the queue will be emptied.
   */
  processMessageQueue: function() {
    this.messageQueueing_ = false;
    for (var i=0, max=this.messageQueue_.length; i<max; ++i) {
      var params = this.messageQueue_[i];
      var actionName = params.pop();
      Def.Rules.Actions[actionName](params[0], params[1], params[2], params[3], params[4]);
    }
    if (this.messageQueue_.length > 0)
      this.messageQueue_ = [];
  },


  /**
   *  Runs the specified rule (form or data rule) for the given trigger field
   *  (which in the case of a data rule will be null).
   * @param ruleName the name of the rule to run.
   * @param triggerField the field whose change triggered the run of the rule
   * @param triggerIDParts the parts of the triggerField's ID returned by the
   *  function splitFullFieldID().
   */
  runOneRule: function(ruleName, triggerField, triggerIDParts) {
    var sp = new Date();
    try {
      if (this.isDataRule(ruleName))
        this.runDataRule(ruleName);
      else {
        if (triggerIDParts) {
          var prefix = triggerIDParts[0];
          var suffix = triggerIDParts[2];
        }
        else {
          // When a form rule is triggered by a data rule, there is no trigger
          // field.
          prefix = Def.FIELD_ID_PREFIX;
          suffix = '';
        }

        if (Def.Rules.caseRules_[ruleName]) {
          // Case rules have actions specific to each case, so they are handled
          // differently.  Evaluate the case rule directly; it will take case of
          // running the right actions.
          this['rule_'+ruleName](prefix, suffix);
        }
        else {
          var ruleActions = this.ruleActions_[ruleName];
          this.processRuleActions(ruleName, this['rule_'+ruleName], prefix,
            suffix, triggerField, ruleActions);
        }
      }
    }
    catch (e) {
      // If a rule fails, log the error, but let other rules run.
      Def.reportError(e);
    }
    var tp = new Date(), dp = tp-sp;
    if(Def.Rules.timeEachRule) {
      Def.Logger.logMessage(["The rule: ", ruleName, " runs for ", dp,
        " ms (trigger: ", triggerField && triggerField.id, ")"]);
    }
  },


  /**
   *  Runs all of the actions for a rule's cases.  No matter which case is
   *  selected, the actions for all of the cases must be run, so that
   *  the actions for a previously selected case can "undo" their action
   *  (e.g. for a 'hide' action, show a field that had been hidden).
   *  A part of running the actions involves computing the selected case's
   *  return value, so this function returns that value (which then becomes
   *  the overall value for the rule).
   * @param caseRuleName the name of the case rule
   * @param seqNums the sequence numbers of the cases in the rule
   * @param selectedCase the sequence number of the selected case
   * @param prefix the field ID prefix of the trigger field
   * @param suffix the field ID suffix of the trigger field
   * @param triggerField - not currently used for case rules, but
   *  to preserve consistency over call sequence (since non-case rules
   *  DO use this), a null is passed through for this parameter.
   * @return the value for the selected case
   */
  processCaseActions: function(caseRuleName, seqNums, selectedCase,
                               prefix, suffix, triggerField) {
    var rtn = null;
    var caseFunction = this['ruleCaseVal_'+caseRuleName+'_'+selectedCase];
    for (var i=0, max=seqNums.length; i<max; ++i) {
      var order = seqNums[i];
      if (selectedCase == order) {
        rtn = this.processRuleActions(caseRuleName, caseFunction,
          prefix, suffix, triggerField,
          this.ruleActions_[caseRuleName+'.'+selectedCase]);
      }
      else {
        // Run the non-selected cases' actions with a "false" value (the null).
        // Function evaluateRule() will not return 'false' value for the null.
        // Instead it will raise a NoVal exception
        // this.processRuleActions(caseRuleName, null,
        this.processRuleActions(caseRuleName, (function(){return false;}),
        prefix, suffix, triggerField,
        this.ruleActions_[caseRuleName+'.'+order]);
      }
    }
    return rtn;
  },


  /**
   *  Handles the processing of actions for a rule, and also evaluates the
   *  rule's expression and stores the value in the cache.  If there is more
   *  than one affected field by an action, the expression is evaluated
   *  multiple times, and the last value is stored.
   * @param ruleName the name of the rule to run.
   * @param ruleCall the string containing the JavaScript expression to
   *  be evaluated for the rule.  This can be null, in which case the rule's value
   *  will be null (false).
   * @param prefix the field ID prefix of the trigger field
   * @param suffix the field ID suffix of the trigger field
   * @param triggerField the field object that triggered the rule.  Will be
   *  null for case rules.
   * @param ruleActions an array containing the data needed to run the actions.
   *  This is in the format of the Def.Rules.ruleActions_ variable defined
   *  on returned web pages.  For each action in the array, there is an array
   *  of three elements-- the rule name, the affected field name (or null), and
   *  a hashmap of parameters for the action.  This parameter may be null
   *  if there are no actions for the rule, in which case the method will
   *  just evaluate the ruleCall and return.
   * @return the value of the rule stored in the cache
   */
  processRuleActions: function(ruleName, ruleCall, prefix, suffix,
                               triggerField, ruleActions) {
    if (ruleActions == null) {
      // There are no actions, so go ahead an evaluate the rule and update
      // its cached value.
      this.evaluateRule(ruleName, ruleCall, prefix, suffix, null);
    }
    else {
      // Process each action.
      var max_j = ruleActions.length ;
      if (max_j > 1 && ruleActions[1][0] != 'set_fb_fields') {
        var found = false ;
        for (var i = 1; i < max_j && found == false; ++i) {
          if (ruleActions[i][0] == 'set_fb_fields') {
            found = true ;
            var fb_action = ruleActions.splice(i, 1).toString() ;
            ruleActions.unshift(fb_action) ;
          } // end if we found it
        } // end looking for set_fb_fields
      } // end if there's more than one action here

     // "j" should be defined as a local variable, else it could be treated as a
     // global variable and its value could be changed by codes inside the for loop
     // (i.e. codes sit between { and } )
     for (var j=0; j<max_j; ++j) {
        var actionData = ruleActions[j];
        var actionName = actionData[0];
        var affectedFieldName = actionData[1];
        var actionParams = actionData[2];

        // Get the affected fields.
        var affectedFields = [];
        if (affectedFieldName != null)
          affectedFields = findFields(prefix, affectedFieldName, suffix);
//          affectedFields = window.findFields(prefix, affectedFieldName, suffix);

        /* NOTE - at this point something has happened to the action parameters
         * that makes them inaccessible on the first try.  See the note in
         * update_shared_list that describes the problem.  Before the call
         * to findFields the parameters are immediately accessible.  After
         * the call, they're not.  lm, 1/12/09
         */

        var ruleVal = null;
        if (affectedFields.length == 0) {
          // Evaluate the rule and run the action.
          ruleVal = this.evaluateRule(ruleName, ruleCall, prefix, suffix,
                                      null);

          this.ruleAction(ruleVal, actionName, actionParams, triggerField,
                          null);
        }
        else {
          // Evaluate the rule for each affected field, passing in its index,
          // in case the affected field (or a parallel column) is in the rule.
          // For now, we are only allowing one stored value per rule name.  (It
          // gets really complicated otherwise.)
          var numFields = affectedFields.length;
          for (var affectedFieldIndex=0;
                   affectedFieldIndex<numFields;
                   ++affectedFieldIndex) {
            try {
              ruleVal = this.evaluateRule(ruleName, ruleCall, prefix,
                                          suffix, affectedFieldIndex);
              //var listName = actionParams['listName'] ;  //MAKETHISGOAWAY
              this.ruleAction(ruleVal, actionName, actionParams, triggerField,
                              affectedFields[affectedFieldIndex]);
            }
            catch (e) {
              // If a rule fails for one index, it might not for the next,
              // so log the error and proceed.
              Def.reportError(e);
            }
          } // each affected field
        } // else there are affected fields for this action
      } // each action
    } // else process actions
  }, // processRuleActions function


  /**
   *  Evaluates a rule and returns its value.  If the rule evaluates to null
   *  or NaN, or if it cannot be evaluated because there is no value for
   *  something on which it depends, a NoVal exception will be returned (of
   *  type Def.Rules.Exceptions.NoVal) as an indication that there is no
   *  value for the rule, and any previous value for the rule will be cleared
   *  from the cache.  If some other exception occurs while the rule is being
   *  evaluated, the value will be cleared from the cache, and the exception
   *  will be rethrown.  Otherwise, the cache will be updated
   *  with the new rule value.
   * @param ruleName the name of the rule
   * @param ruleCall the the function to be called to obtain a value for the rule.
   *  This can be null, in which case the returned value will be null (which is
   *  interpreted as false).
   * @param prefix the field ID prefix of the trigger field
   * @param suffix the field ID suffix of the trigger field
   * @param affectedFieldIndex the index of the affectedField in a list
   *  of affectedFields, if there is more than one.
   * @return the value of the rule, or null if the ruleCall is null,
   *  or if the no value could be determined
   *  (e.g. because of missing data), an instance of the NoVal exception.
   */
  evaluateRule: function(ruleName, ruleCall, prefix, suffix,
                         affectedFieldIndex) {

    var ruleVal = null;
    try {
      if (ruleCall)
        ruleVal = ruleCall(prefix, suffix, affectedFieldIndex);
      // added checks to include cases when ruleVal appears to be a hash after
      // running  a fetching rule
      if (ruleVal == null || (ruleVal.length == null && isNaN(ruleVal)
        && Object.toJSON(ruleVal) == "{}")) {
        // No need to remove the value from the cache-- the catch below
        // takes care of that.
        throw new Def.Rules.Exceptions.NoVal(
          'Could not determine value for rule ' +ruleName);
      }
      this.Cache.setRuleVal(ruleName, ruleVal);
    }
    catch (e) {
      this.Cache.removeRuleVal(ruleName);
      if (e instanceof Def.Rules.Exceptions.NoVal)
        ruleVal = e;
      else
        throw e;
    }
    return ruleVal;
  },


  /**
   *  This is called to handle the running of any type of action for a rule.
   *  Exceptions generated by an action are squelched for now.
   * @param ruleVal value of the rule controlling this action
   * @param actionName - the action name
   * @param params a hash map of parameters (if any) needed by the action.
   *  This can be null.
   * @param triggerField the field object that triggered the rule.  Will
   *  be null for case rules.
   * @param affectedField a reference to the HTML field object for the field
   *  affected by this call to ruleAction.  This can be null.
   * @param options a hash map holding the label values so that label variables
   * can be referenced in the action (e.g. "add_messages")
   */
  ruleAction: function(ruleVal, actionName, params, triggerField,
                       affectedField, options) {

    if (this.postProcessedActions_.indexOf(actionName) > -1) {
      // Queue up this action until we are done with the other rules,
      // because messages can contain embedded rule values.
      // The "null" value is a reference to the triggerField.  We aren't
      // using that, so I'm starting to phase it out. - NOPE - put it
      // back in.  lm, 6/2008
      this.messageQueue_.push([ruleVal, params, triggerField,
        affectedField, options, actionName]);
    }
    else {
      try {
        this.Actions[actionName](ruleVal, params, triggerField, affectedField, options);
      }
      catch (e) {
        Def.reportError(e);
      }
    }
  }, // function ruleAction


  /**
   *  Fills in the given message template with sibling field values, rule values
   *  and url links
   *  @param triggerFields - trigger fields used for filling sibling values
   *  @param template - the inputing template
   *  @param options a hash map holding the label values so that label variables
   *  can be referenced in the action (e.g. "add_messages")
   */
  fillMessageTemplate: function(template, triggerFields, options) {
    var rtn =[], message= template;
    if(triggerFields == undefined) triggerFields = [];

    if(options && options['label'])
    message = this.fillMessageTemplateByType("label", message, triggerFields, options);

    // fill template related to sibling field values
    for(var i = 0, max = triggerFields.length;i< max; i++){
      message = this.fillMessageTemplateByType(
                  "sibling", message, triggerFields[i]);
      rtn.push(message);
    }
    if(rtn.length > 0){
      message = rtn.join("</br>");
    }

    // fill template related to rule value
    message = this.fillMessageTemplateByType("rule", message);
    // fill template related to URL link
    message = this.fillMessageTemplateByType("url", message, null, options);
    return message;
  }, // end of fillMessageTemplate


  /**
   *  Fills in the given message template with corresponding value including
   *  sibling field values, rule value, http link for URL.
   *  Supported syntax:
   *  1) Sibling field -  "some message sib:{foo}" where foo is the target field
   *  of a sibling field.
   *  2) Rule - "some message ${someRuleName;*.5}" where the "5"
   *  can be any non-negative number and represents the number of decimal
   *  places to use in the formatting of the value of "someRuleName".
   *  3) URL - "some message http://www.google.com"
   *  @param template_type - type of templates including "sibling", "rule"
   *  and "url"
   *  @param template - inputing template
   *  @param triggerField - the trigger field used for filling in sibling field
   *  value
   *  @param options a hash from string 'label' to an object of class RuleLabels
   *  which can return label value for different labels
   */
  fillMessageTemplateByType: function(template_type, template, triggerField,
                                      options) {
    var message, regexp;
    switch(template_type){
      case "label":
        // placeholder for labels used in data rule is '{}'
        // regexp should be able to separate '{}' from other placeholders like
        // 'sib:{}', '${}' and 'javascript{}'
        regexp = new RegExp('([^(sib\\:|\\$|javascript)])\\{(.*?)\\}', 'g');
        message = template.replace(regexp, function(matched_str, prefix_symbol, paren_val) {
          //return labelCaches[paren_val.strip()];
          var labelName = paren_val.strip();
          var dateValueToStr = true;
          return prefix_symbol + options['label'].getVal(labelName, dateValueToStr);
        });
        break;
      case "sibling":
        // The message might have embedded sibling values.  Look for them and
        // subsitute.
        // placeholder for sibling field value is 'sib:{}'
        regexp = new RegExp('sib\\:\\{(.*?)\\}', 'g');
        message = template.replace(regexp, function(matched_str, paren_val) {
          var fld = Def.FieldOps.findSibling(triggerField, paren_val.strip());
          return Def.getFieldVal(fld);
        });
        break;
      case "rule":
        // The message might have embedded rule values.  Look for them and
        // subsitute.
        // placeholder for form rule is '${}'
        regexp = new RegExp('\\$\\{(.*?)\\}', 'g');
        message = template.replace(regexp, function(matched_str, paren_val) {
          // The paren_val might contain formatting information following
          // a semicolon, e.g. 'rule_val;5.2' meaning pad the string to at
          // least 5 characters and make it have 2 decimal places.  For now,
          // we are going to ignore the padding part.  I'm not sure we'll
          // need it.
          var nameParts = /^([^;]+)(;(\d+|\*)\.(\d+))?$/.exec(paren_val);
          var name = nameParts[1];
          var decimalStr = nameParts[4];
          var nameVal = Def.Rules.Cache.getRuleVal(name);
          if (decimalStr) {
            var numDecPlaces = parseInt(decimalStr);
            nameVal = nameVal.toFixed(numDecPlaces);
          }
          return nameVal;
        });
        break;
      case "url":
        // If the message contains URLs, wrap them in hyperlinks.
        regexp = new RegExp('http://\\S+\\w', 'g');
        message = template.replace(regexp, function(matchStr) {
          // In standard mode, the linked page/document is displayed in popup
          // window; In basic mode, the window for showing page/document cannot
          // be generated using Javascript code. Instead it will be generated by
          // setting the anchor tag's target attribute value to "_blank"
          switch(Def.page_view){
            case "default":
              var urlParts = ['<a href="javascript:void(0)"', ' onclick="'] ;
              if (options && options['affected_field']) {
                var usgString = 'Def.UsageMonitor.add(\'' +
                                 options['affected_field'] + '_url\', ' +
                                 '{\'reminder_url\':\'' + matchStr + '\'}); ';

                urlParts.push(usgString) ;
              }
              var popString = 'otherwin = openPopup(null, \'' + matchStr +
                '\', null, \'resizable=yes,scrollbars=yes,' +
                'width=700,height=550,screenX=10,screenY=50\', ' +
                '\'reminderSubWin\', true); otherwin.focus(); ' +
                'Event.stop(event); ' +
                'return false;\" >';
              urlParts.push(popString) ;
              break;
            case "basic":
              var urlParts = ['<a target="_blank" href="'+matchStr+'" >'] ;
              break;
            default:
              var errorMsg = "The page_view mode is unknown.";
              Def.Logger.logMessage([errorMsg]);
              throw errorMsg;
          };
          urlParts.push(matchStr, '</a>');
          return urlParts.join('');
        });
        break;

      default:
        var errorMsg =
          "Wrong template_type input for Def.Rules.fillMessageTemplateByType()";
        Def.Logger.logMessage([errorMsg]);
        throw errorMsg;
    }
    return message;
  } // end of fillMessageTemplateByType

};
Object.extend(Def.Rules, defRules);



Def.Rules.Actions = { // A namespace for the action methods

  /* NOTE!!!!!!   If you add an action here, you must also add it to the
   * rule_action_descriptions table in the database.  Otherwise you
   * won't be able to use it.
   */

  /**
   *  Handles a "hide" action for the field affected by the action.
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field affected by the action
   */
  hide: function(ruleVal, params, triggerField, affectedField) {
    // If the "field" is div (a group of fields), set display to none to hide
    // it.  Otherwise, just make the field's visibility hidden.
    // The NoVal ruleVal case is handled by not taking any action.  This
    // is because we don't know whether to hide or show.  (Example:  If the
    // user enters gender of "male" but does not enter birth year, the
    // not_impregnable rule should not try to show the question about
    // pregnancy just because it can get an age value.)
    //
    // Note that on fields that are displayed vertically (not in a table)
    // you need to set the display parameter, not the visibility one.
    // Setting visibility to hidden still reserves the space for the
    // field - which we don't want.  We want the space it would normally
    // take up to close up.   lm 3/08
    //
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      // If we are hiding the field, blur the field if it has focus.  (This
      // gives an autocompletion list a chance to close if its field is being
      // hidden.)
      if (ruleVal && affectedField.id && affectedField.id === document.activeElement.id)
        affectedField.blur();

      if (affectedField.tagName == 'DIV' &&
          affectedField.hasClassName('fieldGroup')) { // see comments above
        // This line below used to be 'none' : ''.  However, for a div that
        // was initially hidden via a style sheet, setting the display
        // value to '' had no effect (it remained hidden).
        affectedField.style.display = ruleVal ? 'none' : 'block';
      }
      else if (affectedField.tagName == 'DIV' &&
           affectedField.parentNode.hasClassName('initially_not_displayed')) {
        affectedField.parentNode.style.display = ruleVal ? 'none' : 'block';
        affectedField.style.display = ruleVal ? 'none' : 'block' ;
        //affectedField.parentNode.removeClassName('initially_not_displayed') ;
      }
      else if (affectedField.tagName ==="IMG") {
        affectedField.style.visibility = ruleVal ? 'hidden' : 'visible';
      }
      else if (affectedField.tagName ==="BUTTON") {
        affectedField.style.display = ruleVal ? 'none' : 'block';
      }
      else  {
        // If not a div, look for HTML structure to determine what to do.
        var ancestors = affectedField.ancestors() ;
        var found = false ;
        //  Iterate through parent structure and find appropriate tag(s)
        // to hide/show. This should work across formbuilder/PHR forms
        // with current layouts and is intended to be generic
        for (var c = 0, cl = ancestors.length; c < cl  && !found; ++c) {
          if(ancestors[c].tagName=='TD' &&
            ancestors[c+1].tagName == 'TR' &&
            ancestors[c+1].hasClassName('repeatingLine')) {
            // For table cells in a repeatingLine table, we put the style
            // setting on the first child of the cell.  We assume (in line with
            // what our form generation code does) that the content of the cell
            // is inside one element that is itself inside the TD.
            ancestors[c].firstChild.style.visibility =  ruleVal ? 'hidden' : 'visible';

            // find tooltip in descendent and toggle
            var children = ancestors[c].descendants() ;
            for (var a = 0, al = children.length; a < al && !found; ++a) {
              if(children[a].hasClassName('tipMessage')) {
                children[a].style.visibility = ruleVal ? 'hidden' : 'visible';
              }
            }
            found = true ;
          }
          // if there is a field/div of class field in ancestors, make it
          // invisible.
          if(ancestors[c].hasClassName('field')){
            ancestors[c].style.display = ruleVal ? 'none' : 'block';
            found = true ;
          }
        }
        // If none of the previous, make the field itself invisible.
        if(!found)  {
          affectedField.style.visibility = ruleVal ? 'hidden' : 'visible';
        }

      }
    }
  }, // end hide


  /**
   *  Handles a "show" action for the field affected by the action.
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field affected by the action
   */
  show: function(ruleVal, params, triggerField, affectedField) {
    // Do the opposite of the hide action
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal))
      ruleVal = !ruleVal;
    this.hide(ruleVal, params, triggerField, affectedField);
  },


  /**
   * Handles a "hide_sub_columns" action for the field affected by the action.
   * It has been used by PHR form rule named "show_when_done_field_only" and
   * works okay - Frank.
   *
   * @param ruleVal if true, the loinc row will be shown, if false it will be
   *  hidden, and if NoVal no action will be taken.
   * @param params a hash with a single key named 'column' which maps to a
   *  sub-column target name
   * @param triggerField the HTML DOM field that triggered the action.
   *  Not used by this method.
   * @param affectedField the field containing the sub-columns need to be hide
   */
  hide_sub_columns: function(ruleVal, params, triggerField, affectedField) {
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      //find all the column elements
      var columnFields =
        this.find_sub_columns(affectedField, params['column'])
      // hide/show them one at a time based on ruleVal
      for (var i=0, max=columnFields.length;i<max;i++) {
        this.hide(ruleVal, params, triggerField, columnFields[i]);
      }
    }
  },


  /**
   * Handles a "show_sub_columns" action for the field affected by the action.
   *
   * @param ruleVal if true, the loinc row will be shown, if false it will be
   *  hidden, and if NoVal no action will be taken.
   * @param params a hash with a single key named 'column' which maps to a
   *  sub-column target name
   * @param triggerField the HTML DOM field that triggered the action.
   *  Not used by this method.
   * @param affectedField the field containing the sub-column needs to be showed
   */
  show_sub_columns: function(ruleVal, params, triggerField, affectedField) {
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
     this.hide_sub_columns(!ruleVal, params, triggerField, affectedField);
    }
  },


  /**
   *  Shows error for the field affected by the action.
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field affected by the action
   */
  show_error: function(ruleVal, params, triggerField, affectedField) {

    if (ruleVal) {
      var msg = params['message'] ;
      displayError( affectedField , msg );
      setTimeout(function() {affectedField.focus();}, 1);
    }
    else
      displayCorrect( affectedField, msg );
  },

  /**
   *  This method sets the value of a field on the form with the
   *  value parameter passed into it.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action.  For
   *  this function it should be the value to be placed in the
   *  affected field (specified as value=>whatever) OR
   *  javascript to be executed to provide a value (prefaced by
   *  the string 'javascript{' with a '}' at the end).
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field affected by the action.  For
   *  this function it should be the field to receive the value.
   */
  set_value: function(ruleVal, params, triggerField, affectedField) {

    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal) &&
        ruleVal != undefined &&
        ruleVal != null &&
        (affectedField !=null || affectedField != undefined) &&
        ruleVal != false) {
      //Def.Logger.logMessage(['set_value called for triggerField = ',
      //  triggerField.id, '; affectedField = ',
      //  affectedField.id]);
      var ro = $(affectedField.id).readAttribute('readonly') ;
      if (ro)
        affectedField.removeAttribute('readonly') ;
      var pref = 'javascript{' ;
      var newVal;
      if (params['value'].substr(0,pref.length) == pref)
        newVal = eval(params['value'].substr(pref.length,
                   params['value'].length - (pref.length+1))) ;
      else{
        newVal = params['value'] ;
        if(newVal.strip() == "self")
          newVal = ruleVal;
      }
      Def.setFieldVal(affectedField, newVal);
      if (ro)
        affectedField.setAttribute('readonly', 'readonly') ;
      if(Def.Rules.logLevel == "debug")
        Def.Logger.logMessage(['affectedField value is now ', newVal]);
    }
  }, // end set_value


  /**
   * Sets the value of a field on the form with the value parameter passed in
   * or clears the field based on the value of rule's expression
   *
   * @param ruleVal - the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params - a hashmap of parameters for the action.  For
   *  this function it should be the value to be placed in the
   *  affected field (specified as value=>whatever)
   * @param triggerField - the field that triggered the action.
   *  Not used by this function.
   * @param affectedField - the field affected by the action.  For
   *  this function it should be the field to receive the value.
   **/
  set_or_clear_value: function(ruleVal, params, triggerField, affectedField) {
    var newRuleVal = ruleVal;
    var newParams = params;
    if ((ruleVal instanceof Def.Rules.Exceptions.NoVal) ||
      ruleVal == undefined ||
      ruleVal == null ||
      ruleVal == false ){
      newRuleVal = true;
      newParams = {"value" : ""};
    }
    this.set_value(newRuleVal, newParams, triggerField, affectedField);
  }, // end set_or_clear_value


  /**
   *  This method sets the value of a field on the form with the
   *  the next automatically incremented value for the field.
   *  This is intended for fields in a horizontal table that have multiple
   *  lines.  This looks for a previous version of the field - i.e. the
   *  same field in the previous line, and then sets the affected field
   *  to the next value in the sequence.  So if we had fieldA and a table
   *  had 3 (visible) lines with fieldA in each, if we added another line,
   *  fieldA_4 would get the value from fieldA_3, increment it, and place
   *  it in fieldA_4 when the rule runs.
   *
   *  A prefix, suffix, and beginning value are specified as parameters.
   *  The beginning value determines the series type.
   *
   *  The value is set if the rule evaluates to true.  No action is taken
   *  if the rule value is false or 'NoVal'.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action.  For
   *  this function the parameters are as follows:
   *  * prefix - an optional string that is prepended to each incremented
   *    value, such as {, where { is prepended to the series value after
   *    it is determined;
   *  * beginning value - the first value to be used in the increment
   *    series.  This defines the series.  So if the beginning value is
   *    1, each subsequent value will get the next digit (2, 3, ...).
   *    If the beginning value is A, each subsequent value will get the next
   *    uppercase letter (A, B, ...).  In the case of a finite series (A),
   *    the increment value will loop around to the beginning of the series
   *    when series end is reached; and
   *  * suffix - an optional string that is appended to each incremented
   *    value, such as }, where } is appended to the series value after
   *    it is determined.
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field whose column header is to be set.
   */
  set_autoincrement_value: function(ruleVal,
                                    params,
                                    triggerField,
                                    affectedField) {
    if (ruleVal != undefined && ruleVal != null && ruleVal != false &&
        !(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {

      var fldParts = Def.IDCache.splitFullFieldID(affectedField.id) ;
      if (params['prefix'] != undefined)
        var prefix = params['prefix'] ;
      else
        prefix = '' ;
      var beginningVal = params['beginning_value'] ;
      if (params['suffix'] != undefined)
        var suffix = params['suffix'] ;
      else
        suffix = '' ;
      var lastUscore = fldParts[2].lastIndexOf('_') ;
      if (lastUscore >= 0)
        var intSuffix = parseInt(fldParts[2].substr(lastUscore + 1)) ;
      else
        intSuffix = 0 ;
      if (intSuffix <= 0)
        var newVal = prefix + beginningVal + suffix ;
      else {

        var lastFld = findFields(fldParts[0], fldParts[1],
                                              '_'  + (intSuffix - 1)) ;
        if (lastFld.length > 0) {
          var prevVal = Def.getFieldVal(lastFld[0]) ;
        }
        if (prevVal == null || prevVal.length == 0)
          newVal = prefix + beginningVal + suffix ;
        else {
          newVal = prefix.length > 0? prevVal.substr(prefix.length) : prevVal ;
          newVal = suffix.length > 0?
                    newVal.substr(0, newVal.length - suffix.length) : newVal ;
          if (isNaN(parseInt(newVal)))
            newVal = incrementString(newVal) ;
          else {
            newVal = (parseInt(newVal) + 1) + '';
          } // if value is/is not a number
          newVal = prefix + newVal + suffix ;
        } // if we got a previous value
      } // if the suffix is > 0
      Def.setFieldVal(affectedField, newVal) ;
    } // if rule evaluates to true
  } , // end set_autoincrement_value


  /**
   *  This method sets/resets a tooltip for the affected field.
   *
   *  If the rule value is true, it sets it with the value found
   *  in either the field named in the params parameter, or, if
   *  the params parameter is not specified, with the value in the
   *  triggerField.
   *
   *  If the value of the rule is false, it clears the tooltip.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action.  For
   *  this function it is optional, but if specified should be
   *  the name (without prefix or suffix) of the field containing
   *  the value to be used for the tooltip.
   * @param triggerField the field that triggered the action.
   *  If not params value is specified, the value in this field is
   *  used for the tooltip.
   * @param affectedField the field affected by the action.  For
   *  this function it should be the field whose tooltip is to be set.
   */
  set_tooltip: function(ruleVal, params, triggerField, affectedField) {
    if (ruleVal != undefined && ruleVal != null &&
        !(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      if (params['field']) {
        var field_parts = Def.IDCache.splitFullFieldID(triggerField.id) ;
        var source_field = $(field_parts[0] + params['field'] + field_parts[2]) ;
      }
      else {
        source_field = triggerField ;
      }
      if (ruleVal == false)
        var new_value = "";
      else
        new_value = Def.getFieldVal(source_field) ;
      Def.resetTip(affectedField, new_value) ;
    }
  } , // end set_tooltip


  /**
   *  This method modifies the value of a group header label.
   *
  *  If the rule value is true, it sets the label to the value passed
   *  as the rule action's 'label' parameter.  No action is taken if the
   *  rule value is false or 'NoVal'.
   *
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action.  For
   *  this function there is one parameter whose key is 'label'.
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field affected by the action.  For
   *  this function it should be the group header whose label is to be
   *  set.
   */
  set_group_header_label: function(ruleVal, params,
                                   triggerField, affectedField) {
    if (ruleVal != undefined && ruleVal != null && ruleVal != false &&
        !(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      var fldParts = Def.IDCache.splitFullFieldID(affectedField.id) ;
      var hdrFld = $(fldParts[0] + fldParts[1] + '_lbl' + fldParts[2]) ;
      if (hdrFld)
        Def.setInnerHTMLText(hdrFld, params['label']) ;
    }
  } , // end set_group_header_label


  /**
   *  This method modifies a group header's instructions text.
   *
   *  If the rule value is true, it sets the text to the value passed
   *  as the rule action's 'text' parameter.  No action is taken if the
   *  rule value is false or 'NoVal'.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action.  For
   *  this function there is one parameter whose key is 'text'.
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field affected by the action.  For
   *  this function it should be the group header whose label is to be
   *  set.
   */
  set_group_header_instructions: function(ruleVal, params,
                                          triggerField, affectedField) {
    if (ruleVal != undefined && ruleVal != null && ruleVal != false &&
        !(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      var fldParts = Def.IDCache.splitFullFieldID(affectedField.id) ;
      var insFld = $(fldParts[0] + fldParts[1] + '_ins' + fldParts[2]) ;
      if (insFld)
        Def.setInnerHTMLText(insFld, params['instructions']) ;
    }
  } , // end set_group_header_instructions


  /**
   *  This method modifies a field label.
   *
   *  If the rule value is true, it sets the label to the value passed
   *  as the rule action's 'label' parameter.  No action is taken if the
   *  rule value is false or 'NoVal'.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action.  For
   *  this function there is one parameter whose key is 'text'.
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field whose label is to be set.
   */
  set_field_label: function(ruleVal, params, triggerField, affectedField) {
    if (ruleVal != undefined && ruleVal != null && ruleVal != false &&
        !(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      var fldParts = Def.IDCache.splitFullFieldID(affectedField.id) ;
      var fldLbl = $(fldParts[0] + fldParts[1] + '_lbl' + fldParts[2]) ;
      if (fldLbl)
        Def.setInnerHTMLText(fldLbl, params['label']) ;
    }
  } , // end set_field_label


  /**
   *  This method modifies a column header in a horizontal table.
   *
   *  If the rule value is true, it sets the header to the value passed
   *  as the rule action's 'header' parameter.  No action is taken if the
   *  rule value is false or 'NoVal'.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action.  For
   *  this function there is one parameter whose key is 'header'.
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field whose column header is to be set.
   */
  set_column_header: function(ruleVal, params, triggerField, affectedField) {
    if (ruleVal != undefined && ruleVal != null && ruleVal != false &&
        !(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      var fldParts = Def.IDCache.splitFullFieldID(affectedField.id) ;
      var colHdr = $(fldParts[0] + fldParts[1] + '_hd') ;
      if (colHdr)
        Def.setInnerHTMLText(colHdr, params['header']) ;
    }
  } , // end set_column_header


  /**
   *  This method sets the visibility for definition fields on the
   *  form builder form based on field type.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   *  We only process this is the value is true.
   * @param params a hashmap of parameters for the action.
   *  Not used by this function.
   * @param triggerField the field that triggered the action.
   *  It IS used by this method!
   * @param affectedField the field affected by the action.
   *  This should be the division that contains all the fields
   *  whose visibility we're setting.
   */
  set_fb_fields: function(ruleVal, params, triggerField, affectedField) {

    // First see if the triggerField is a model row.  This only
    // happens on page load, but when it does we don't want this
    // to do ANYTHING.  We never show that anyway, so it's a waste
    // of time.  Also, it makes this not work.
    var idCache = Def.IDCache;
    var trig_parts = idCache.splitFullFieldID(triggerField.id) ;

    if (trig_parts[2] != '_0') {
      if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal) && ruleVal) {

        // This can be invoked by either the supported_ft or field_type
        // form fields.  We want to make sure that the trigger field
        // is field_type.
        if (trig_parts[1] != 'field_type') {
          triggerField = Def.IDCache.findByID(trig_parts[0] +
            'field_type' +
            trig_parts[2]) ;
        }
        // Get the row from the fields map that is for the field type
        // specified in field_type.
        var the_row = fbFieldsMap[Def.getFieldVal(triggerField)] ;

        // If we did not find a row, it means we're at an unsupported
        // field type.  (We shouldn't get to this point, but whatever).
        // Don't bother with the rest.
        if (the_row) {

          // Use the variable fields hash to get the after-suffix for
          // the field.  The after-suffix is that part of the suffix
          // that does not change - and follows what is supplied by
          // the field_type trigger field.  Use that suffix to get
          // the form field directly from the cache rather than having
          // to search around for it.
          for (var fldName in the_row) {
            var target_field = Def.IDCache.findByID(trig_parts[0] +
              fldName +
              trig_parts[2] +
              fbVariableFlds[fldName]) ;
            if (the_row[fldName] == true &&
              !target_field.hasClassName('hidden_field')) {
              this.show(true, null, null, target_field) ;
            }
            else {
              this.show(false, null, null, target_field) ;
            }
          } // end do while we have cells in the row
        } // end if we have a row to process
      } // end if the rule is true

      // Now run show on the containing field (affectedField) whether or
      // not the rule evaluates to true.
      this.show(ruleVal, params, triggerField, affectedField) ;
    } // end if this was not triggered by the model row

  }, // end set_fb_fields


  /**
   *  Handles an "add_message" action for the given affected field.
   *  This adds a message to a message handler on the affected field if
   *  ruleVal is not zero or false, and removes it otherwise.
   * @param ruleVal the value of the rule's expression.  This can be
   *  an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action
   * @param triggerField the HTML DOM field that triggered the action.
   *  Not used by this method.
   * @param affectedField the HTML DOM field affected by the action
   * @param options NOT DOCUMENTED BY WHOEVER ADDED
   */
  add_message: function(ruleVal, params, triggerField, affectedField, options) {
    return this.add_message_general(ruleVal, params, [], affectedField, options);
  }, // end add_message


  /**
   *  Handles an "add_table_messages" action for the given affected field.
   *  This adds a message to a message handler on the affected field if
   *  ruleVal is not zero or false, and removes it otherwise.
   * @param ruleVal - the value of the rule's expression.  This can be
   *  an instance of the NoVal exception to indicate no value.
   * @param params - a hashmap of parameters for the action
   * @param triggerField - the HTML DOM field that triggered the action.
   * @param affectedField - the HTML DOM field affected by the action
   **/
  add_table_messages: function(ruleVal, params, triggerField, affectedField) {
    var idParts = Def.IDCache.splitFullFieldID(triggerField.id);
    var triggerFields = Def.tableDueDateFields_[idParts[1]];

    return this.add_message_general(ruleVal, params, triggerFields, affectedField);
  },// end of add_table_messges


  /**
   *  Handles "add_message" or "add_table_messages" action for the given
   *  affected field.
   *  This adds a message to a message handler on the affected field if
   *  ruleVal is not zero or false, and removes it otherwise.
   * @param ruleVal the value of the rule's expression.  This can be
   *  an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action
   * @param triggerFields the HTML DOM fields that triggered the action.
   * @param affectedField the HTML DOM field affected by the action
   * @param options a hash map holding the label values so that label variables
   * can be referenced in the action (e.g. "add_messages")
   */
  add_message_general: function(ruleVal, params, triggerFields, affectedField, options){

    if (options == null || options === undefined)
      options = {} ;

    // Messages are referenced by a key.  For now, we can use the message
    // itself as the key.  (We could also use the defining field's ID, though
    // in a table that could cause trouble.)
    var key = SHA256(params['message']);
    var message = params['message'];
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal) && ruleVal) {
      var afParts = Def.IDCache.splitFullFieldID(affectedField.id);
      // Add the message to the message manager.
      options['affected_field'] = afParts[1] ;
      message = Def.Rules.fillMessageTemplate(message, triggerFields, options);

      // Set the message
      affectedField.messageManager.addMessage(key, message);
    }
    else {
      // Remove the message.
      affectedField.messageManager.removeMessage(key);
    }
  }, // end of add_message_general


  /**
   *  Handles a "hide_row" action for the given affected field..  When the
   *  ruleVal parameter is true, the nearest table row containing the
   *  field is hidden.
   * @param ruleVal the value of the rule's expression.  This can be
   *  an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action
   * @param triggerField the HTML DOM field that triggered the action.
   *  Not used by this method.
   * @param affectedField the HTML DOM field affected by the action
   */
  hide_row: function(ruleVal, params, triggerField, affectedField) {
    Def.FieldsTable.setFieldRowVisibility(affectedField, !ruleVal);
  },


  /**
   * This function will hide/show the embedded row next to the hidden
   * repeating line. The repeating line should have the affectedField whose value
   * is equal to the loinc number carried by the params
   **/
  hide_loinc_panel: function(ruleVal, params, triggerField, affectedField) {
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      if(affectedField && affectedField.value == params.loinc_number){
        //var row = affectedField.up('tr');
        var row = affectedField.up(1);  //input==>td==>tr
        //some fields may have span or other layers between input and tr
        while (row.tagName.toLowerCase() != 'tr') {
          row= row.up(0);
        }
        if (row) {
          // hide the embedded line next to the repeating line
          row.next().style.display = ruleVal ? 'none' : '';
        }
      }
    }
  },


  /**
   *  This function will show/hide the embedded row next to the hidden
   *  repeating line. It does the opposite of hide_loinc_panel.  The repeating
   *  line should have the affectedField
   *  whose value is equal to the loinc number carried by the params.
   * @param ruleVal if true, the loinc row will be shown, if false it will be
   *  hidden, and if NoVal no action will be taken.
   * @param params a hashmap of parameters for the action
   * @param triggerField the HTML DOM field that triggered the action.
   *  Not used by this method.
   * @param affectedField the HTML DOM field affected by the action
   */
  show_loinc_panel: function(ruleVal, params, triggerField, affectedField) {
    // Do the opposite of the hide_loinc_panel
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal))
      ruleVal = !ruleVal;
    this.hide_loinc_panel(ruleVal, params, triggerField, affectedField);
  },


 /**
   * This function will hide/show the loinc test row which have the
   * affectedField whose value is equal to the loinc number carried by the params
   **/
  hide_loinc_test: function(ruleVal, params, triggerField, affectedField) {
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      if(affectedField && affectedField.value == params.loinc_number){
        var row = affectedField.up('tr');
        if (row) {
          // hide the row which has the affectedField
          row.style.display = ruleVal ? 'none' : '';
        }
      }
    }
  },


  /**
   *  This function will show/hide the loinc test row which have the
   *  affectedField. It does the opposite of hide_loinc_test. The value of the
   *  affectedField should be equal to the loinc number carried by the params
   * @param ruleVal if true, the loinc test row will be shown, if false it will
   *  be hidden, and if NoVal no action will be taken.
   * @param params a hashmap of parameters for the action
   * @param triggerField the HTML DOM field that triggered the action.
   *  Not used by this method.
   * @param affectedField the HTML DOM field affected by the action
   */
  show_loinc_test: function(ruleVal, params, triggerField, affectedField) {
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal))
      ruleVal = !ruleVal;
    this.hide_loinc_test(ruleVal, params, triggerField, affectedField);
  },


  /**
   *  This method sets a field to read_only accessibility.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   *  We only process this if the value is true.
   * @param params a hashmap of parameters for the action.
   *  Not used by this function.
   * @param triggerField the field that triggered the action.
   *  Not used by this function
   * @param affectedField the field affected by the action.
   *  This should be the field to be disabled if the rule is true.
   */
  make_readonly: function(ruleVal, params, triggerField, affectedField) {

    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal) && ruleVal) {

      var ro = affectedField.readAttribute('readonly') ;

      if (!ro || ro != 'readonly')
        affectedField.writeAttribute('readonly', 'readonly') ;

      if (!affectedField.hasClassName('readonly_field'))
        affectedField.addClassName('readonly_field') ;

      if (affectedField.type == 'text') {
        Event.stopObserving(affectedField, 'keypress',
          LargeEditBox.srcKeyEventHandler);
        Event.stopObserving(affectedField, 'click',
                            Def.ClickedTextSelector.onclick);
        Event.stopObserving(affectedField, 'blur',
                            Def.ClickedTextSelector.onblur) ;
      }
    }
  } , // end make_readonly


  /**
   *  This method enables the affected field (e.g. a button field) when rule
   *  evaluation returns true; disables the affected field when rule evaluation
   *  returns false; and does nothing if the rule is a "NoVal" exception.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   *  We only process this if the value is true.
   * @param params not used by this function
   * @param triggerField not used by this function
   * @param affectedField the field (e.g. a button) affected by the action.
   *
   **/
  enable_field: function(ruleVal, params, triggerField, affectedField) {
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal))
      this.disable_field(!ruleVal, params, triggerField, affectedField);
  },


  /**
   *  This method disables the affected field (e.g. a button field) when rule
   *  evaluation returns true; enables the affected field when rule evaluation
   *  returns false; and does nothing if the rule is a "NoVal" exception.
   *
   *  This method was added to allow specification of a more efficient
   *  condition on the PHR Management page to disable/enable a button.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params not used by this function
   * @param triggerField not used by this function
   * @param affectedField the field (e.g. a button) affected by the action.
   *
   **/
  disable_field: function(ruleVal, params, triggerField, affectedField) {
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal))
      affectedField.disabled = ruleVal;
  },


  /**
   * Disables the sub column embedded inside the affectedField
   *
   * @param ruleVal if true, the loinc row will be shown, if false it will be
   *  hidden, and if NoVal no action will be taken.
   * @param params a hash with a single key named 'column' which maps to a
   *  sub-column target name
   * @param triggerField not used by this function.
   * @param affectedField the field containing the sub-columns need to be
   *  disabled
   */
  disable_sub_columns: function(ruleVal, params, triggerField, affectedField) {
    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal)) {
      var columnFields =
        this.find_sub_columns(affectedField, params['column'])
      // hide/show them one at a time based on ruleVal
      for (var i=0, max=columnFields.length;i<max;i++) {
        this.disable_field(ruleVal, params, triggerField, columnFields[i]);
      }
    }
  },


  /**
   * Enables the sub column embedded inside the affectedField
   *
   * @param ruleVal if true, the loinc row will be shown, if false it will be
   *  hidden, and if NoVal no action will be taken.
   * @param params a hash with a single key named 'column' which maps to a
   *  sub-column target name
   * @param triggerField not used by this function.
   * @param affectedField the field containing the sub-columns need to be
   * enabled
   */
  enable_sub_columns: function(ruleVal, params, triggerField, affectedField) {
    disable_sub_columns(!ruleVal, params, triggerField, affectedField);
  },


  /**
   * Finds all the fields on a column embedded in the input field. It is used by
   * the following actions: hide_sub_columns, disable_sub_columns etc.
   *
   * @param inputField the field containing the sub-columns
   * @params columnName target name of the column embedded inside the inputField
   **/
  find_sub_columns: function(inputField, columnName) {

    var idParts = Def.IDCache.splitFullFieldID(inputField.id) ;
    var prefix = idParts[0];
    var targetName = columnName;
    var suffix = Def.trimSuffix(idParts[2]);
    var columnFields = findFields(prefix, targetName, suffix);

    // Hiding/showing test_value column should not affect the test_value
    // field in sub-panel header row.
    // Related bug: when a rule action trying to show test_value column
    // of a test panel which has a sub-panel header, the test_value field
    // in sub-panel header row was wrongly enabled/shown.
    if(TestPanel.inTestPanel(targetName)){
      var tmpList =[];
      var uselessSubpanelFieldHash = TestPanel.uselessSubpanelRowFields;
      var baseTargetName = TestPanel.getBaseTargetName(targetName);
      var skipSubpanelRow = uselessSubpanelFieldHash[baseTargetName] == 1;
      for(var k=0, max=columnFields.length; k< max; k++){
        if (!skipSubpanelRow || !TestPanel.inSubpanelHeaderRow(columnFields[k]))
          tmpList.push(columnFields[k]);
      }
      columnFields = tmpList;
    }
    return columnFields;

  },


  /**
   *  Executes a javascript string if the rule value indicates true.
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   * @param params a hashmap of parameters for the action.  For this
   *  action there should be one parameter, named 'javascript'.
   * @param triggerField the field that triggered the action.
   *  Not used by this function.
   * @param affectedField the field affected by the action.  Not used
   *  by this function.
   */
  execute_javascript: function(ruleVal, params, triggerField, affectedField) {

    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal) && ruleVal) {
      var script = params['javascript'];
      eval(script) ;
    }
  },

  /**
   *  This function checks to see if the value in the specified
   *  triggerField is unique within the context of other fields on the
   *  current form.  Which fields are included in the check are defined
   *  by the params parameter, as described below.
   *
   *  If the triggerField's current value is not unique, the displayError
   *  function is called for the triggerField, with a message explaining the
   *  problem.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   *  We only process this if the value is true.
   * @param params a hashmap of parameters for the action.
   *  In this case there should be one item in the hash, and it
   *  should be named 'fields'.  The value for the item should be
   *  an array with 0 or more form field names, as follows:<ul>
   *  <li>If the array is empty, the value of the trigger field
   *  must be unique within all other fields with the same base field
   *  ID (field id minus the suffix).  This would basically be for
   *  a field in a repeating line table;</li>
   *  <li>If the array contains one element with a value of 'ALL',
   *  the value of the trigger field must be unique with respect to
   *  all fields on the form containing the trigger field; and </li>
   *  <li>If the array contains multiple elements, each should
   *  be a field id of a field (or fields) to check against the trigger
   *  field's value for uniqueness.  The trigger field id is NOT added
   *  automatically to this list, so if there are multiple versions of
   *  the trigger field, be sure to add the id to the array.</li></ul>
   * @param triggerField the field that triggered the action.
   *  This will be the field whose value is to be checked.
   * @param affectedField the field affected by the action.
   *  Not used by this function.
   */
  unique_value: function(ruleVal, params, triggerField, affectedField) {

    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal) && ruleVal) {

      // Get the list of form fields whose values should be checked.
      var fields = params['fields'] ;
      var trigValue = Def.getFieldVal(triggerField);
      var trigID = triggerField.id ;
      var haveMatch = false ;

      // An empty fields array means to check uniqueness just among other
      // fields with the same base id. Load the fields array with the
      // trigger field.
      if (fields == null)
        fields = new Array() ;
      if (fields.length == 0)
        fields.push(trigID) ;

      // If the fields parameter array just contains one element with
      // a value of ALL, we're checking all elements on the form.
      if (fields.length == 1 && fields[0] == 'ALL') {
        // figure out what form we're in
        //var formNum = triggerField.getAttribute('formno') ;
        var formNum = Def.Navigation.navSeqsHash_[trigID][0] ;
        // process all elements in the form
        var theForm = document.forms[formNum] ;
        for (var e = theForm.elements.length - 1;
             haveMatch == false && e >= 0; --e) {
          haveMatch = ($(theForm.elements[e]).value == trigValue) ;
        }
      }
      // A fields array with one or more values (that are not 'ALL')
      // contains the ids of the fields to be checked.
      else {
        var allowedCount = 0 ;
        // Go through each field in the fields list
        for (i = fields.length - 1; haveMatch == false && i >= 0; --i) {
          var fieldVals = Def.getFieldVals(getBaseFieldID(fields[i])) ;
          var matchCount = 0 ;
          if (fields[i] == trigID)
            allowedCount = 1 ;
          else
            allowedCount = 0 ;
          for (var f = fieldVals.length - 1;
               matchCount <= allowedCount && f >= 0; --f) {
            if (fieldVals[f] == trigValue)
              matchCount++ ;
          } // end do for each value of the current base field id
          haveMatch = matchCount > allowedCount ;
        } // end do for each field id
      } // end if we're not trying to match all fields

      // If we have a match, call displayError to complain
      if (haveMatch == true) {
        var msg = trigID + " must have a unique value, but '" + trigValue +
                  "' is already used by another field.";
        displayError(triggerField, msg) ;
      }
      // Otherwise all displayCorrect to make sure that the error
      // is not lingering on the field from a previous input.
      else {
        displayCorrect(triggerField, msg) ;
      }
    } // end if the rule evaluates to true
   } , // end unique_value


  /**
   *  This function updates a shared list, which is a list shared by
   *  multiple list fields.  The update includes propagation of the
   *  updated list to all list fields that use it.
   *
   * @param ruleVal the value of the rule's expression.  This can
   *  be an instance of the NoVal exception to indicate no value.
   *  We only process this if the value is true.
   * @param params a hashmap of parameters for the action, with keys and
   *  expected values as follows:<ul>
   *  <li>listName - the name of the shared list;</li>
   *  <li>keyName - name of the field containing the value used as a key
   *  into the shared list;</li>
   *  <li>valName - name of the field containing the value to be added or
   *  updated for the specified key;</li>
   *  <li>codeName - name of the field containing the code value; and</li>
   *  <li>condition - an optional condition to be evaluated (in addition to
   *  the evaluation of the rule) before the list is updated.  This is
   *  expressed as an array with the following elements:<ul>
   *    <li>the name of the field to be used in the condition;</li>
   *    <li>the operator to be used in the condition; and</li>
   *    <li>the value to be used in the condition.</li></ul></li></ul>
   * @param triggerField the field that triggered the action.
   *  This will be the field whose value is to be checked.
   * @param affectedField the field affected by the action.
   *  Not used by this function.
   */
  update_shared_list: function(ruleVal, params, triggerField, affectedField) {

    if (!(ruleVal instanceof Def.Rules.Exceptions.NoVal) && ruleVal) {

      /* The following line - accessing the parameters directly via
       * the ruleActions_ array - is put in solely to TAP DANCE around
       * a BUG somewhere!!!!!  For some ENTIRELY UNKNOWN reason, the
       * first time the parameters are accessed here, the requested
       * parameter is "undefined".  Subsequent accesses work fine.
       * Notice that we're not USING the params2 variable, just creating
       * it to access the parameters.  Paul and I spent an afternoon
       * trying to debug this and could not come up with a reason
       * why this is happening, although we know it's happening in
       * processRuleActions (see note there).  So until we figure
       * out what the heck is going on, please leave this here.
       * (This extensive note inserted at Paul's request and my
       * pleasure).  lm, 1/12/09
       */
      var params2 = Def.Rules.ruleActions_['possible_gh_change'][0][2] ;
      var listName = params['listName'] ;
      var keyName = params['keyName'] ;
      var valName = params['valName'] ;
      var codeName = params['codeName'];
      var condition = params['condition'] ;

      // Figure out what suffix we're using and use it to build
      // id values for the key and value fields
      var trigFldParts = Def.IDCache.splitFullFieldID(triggerField.id) ;
      var keyVal = Def.getFieldVal(findFields(trigFldParts[0], keyName,
                              trigFldParts[2])[0]);
      var valField = findFields(trigFldParts[0], valName, trigFldParts[2])[0] ;
      var newVal = Def.getFieldVal(valField);
      var codeID = trigFldParts[0] + codeName + trigFldParts[2] ;

      // if the list is empty, create it
      if (Def.data_[listName] == null)
        Def.data_[listName] = {} ;

      // Get the form field for the condition, if we have one.
      if (condition != null) {
        var condField = findFields(trigFldParts[0], condition[0],
                                   trigFldParts[2])[0] ;
      }
      // Process based on whether or not the condition is true
      // - if we have one.  If we don't have one, go with "true".
      if (condition == null ||
          eval('"' + Def.getFieldVal(condField) + '" ' + condition[1] +
               ' "' + condition[2] + '"')) {

        // If the key is already found in the list, check to see if the
        // value has changed.  If so, change it in the list, and call
        // propagateSharedList to propagate the updated list.  That function
        // will also update any affected fields that contain the old value
        // with the new value
        if (Def.data_[listName][keyVal] != null &&
            Def.data_[listName][keyVal] != newVal) {
          var oldVal = Def.data_[listName][keyVal] ;
          Def.data_[listName][keyVal] = newVal ;
          propagateSharedList(listName, affectedField.id,
                              keyVal, codeID, oldVal, newVal) ;
          // If it's in the list but hasn't changed, no more action needed
        }
        // If it's not in the list, add it and feed the list to setList.
        // Since it's new, no affected fields need to be checked for update.
        else {
          Def.data_[listName][keyVal] = newVal ;
          propagateSharedList(listName, affectedField.id, keyVal, codeID) ;
        }
      }
      // Otherwise the condition's not true.  If the key is found in the
      // list we need to remove it from the list and remove it as a value
      // for any fields that currently contain it.  (If the key is not found
      // in the list, we don't need to do anything).
      else if (Def.data_[listName][keyVal] != null) {
        oldVal = Def.data_[listName][keyVal] ;
        delete Def.data_[listName][keyVal] ;
        propagateSharedList(listName, affectedField.id, keyVal, codeID, oldVal, null) ;
      }

    } // end if the rule evaluates to true
  }  // end update_shared_list

  /* NOTE!!!!!!   If you add an action here, you must also add it to the
   * rule_action_descriptions table in the database.  Otherwise you
   * won't be able to use it.
   */

};


Def.Rules.RuleFunctions = { // Namespace for extra functions rules can call
  // Note:  Functions here are generally not camel-case, because they are
  // names that users will see.

  /**
   *  Returns the current time as a number of milliseconds.  (This does not
   *  operate on a field, and perhaps should be moved elsewhere, but it is
   *  part of the functions that can be called by a rule.
   */
  today: function() {
    return new Date().getTime();
  },


  today_by_type: function(dataType){
    var rtn = this.today();
    if( dataType && dataType.toLowerCase() == "string"){
      rtn = new Date().toString().substring(4,15);
    }
    return rtn;
  },

  /**
   * The number of millseconds per year.
   */
  millisPerYear_: 1000*60*60*24*365.24,
    /**
   * The number of millseconds per month.
   */
  millisPerMonth_: 1000*60*60*2*365.24,
    /**
   * The number of millseconds per week.
   */
  millisPerWeek_: 1000*60*60*24*7,
  /**
   * The number of millseconds per day.
   */
  millisPerDay_: 1000*60*60*24,

  /**
   *  Returns the number of years indicated by the given number of milliseconds.
   *  The time returned is fractional, e.g. 2.343
   */
  time_in_years: function(timeInMillis) {
    return timeInMillis/this.millisPerYear_;
  },

  /**
   * Returns the weight in kg
   * @param value - the weight value
   * @param unit - weight unit
   **/
  convert_to_kg:  function(value, unit){
    // input validation: value should not be empty, unit should be a string
    var validInput = true;
    value = parseFloat(value);
    validInput = value && value > 0;
    if(validInput) validInput = typeof unit ==  "string";

    // if inputs are not valid, then throw exception
    if(!validInput){
      throw new Def.Rules.Exceptions.NoVal(
        "wrong input for Def.Rules.RuleFunctions.weight_in_kg()");
    }
    // unit should be in the list of ["kilograms", "pounds"]
    else{
      var rtn;
      switch(unit){
        case "kilograms":rtn = value;
          break;
        case "pounds":rtn = value * 0.4536;
          break;
        default:   //do nothing;
          throw new Def.Rules.Exceptions.NoVal(
            "wrong input for Def.Rules.RuleFunctions.weight_in_kg()");
          break;
      }
      return rtn;
    }
  },

  /**
   * Returns the height in meter
   * @param value - the height value
   * @param unit - height unit
   **/
  convert_to_meter:  function(value, unit){
    // input validation: value should not be empty, unit should be a string
    var validInput = true;
    value = parseFloat(value);
    validInput = value && value > 0;
    if(validInput) validInput = typeof unit ==  "string";

    // if inputs are not valid, then throw exception
    var errMsg = "wrong input for Def.Rules.RuleFunctions.height_in_meter()";
    if(!validInput){
      throw new Def.Rules.Exceptions.NoVal(errMsg);
    }
    // unit should be in the list of ["inches","centimeters","feet","meters"]
    else{
      var rtn;
      switch(unit){
        case "inches":rtn = value * 0.0254;
          break;
        case "centimeters":rtn = value * 0.01;
          break;
        case "feet":rtn = value * 12 * 0.0254;
          break;
        case "meters":rtn = value;
          break;
        default:throw new Def.Rules.Exceptions.NoVal(errMsg);
          break;
      }
      return rtn;
    }
  },

  /**
   * Returns a date object for today with time being set to 00:00:00
   **/
  dateOfToday: function(){
    var t = new Date();
    return new Date(t.toDateString());
  },

  /**
   * Returns elapsed years after the date specified by the input date strings
   * @param yString the date string or year string, e.g. "2000 Jan 23" or "2003"
   * @param mString a string of a month, e.g. "Feb" or "02"
   * @param dString a string of a day, e.g. "18"
   */
  years_elapsed_since: function(yString, mString, dString) {
    if(yString == null || yString == undefined)
      throw "Missing year input for years_elapsed_since() function";
    var sDate = (yString instanceof Date) ? yString :
      (typeof yString == "number" ? (new Date(yString)) : this.to_date(yString, mString, dString));
    if(sDate == null)
      throw "Wrong input for years_elapsed_since() function";
    //return Math.round(((this.today() - sDate.getTime())/this.millisPerYear_)*100)/100;
    return (this.today() - sDate.getTime())/this.millisPerYear_;
  },


  /**
   * Returns the month of the input date as a number
   * @param date - the date for retrieving current month in numeric format
   */
  find_month: function(date){
    if(typeof date  === "string"){
      date = Date.parseDayString(date);
    }
    else if(typeof date === "number"){
      date = new Date(date);
    }

    if(date instanceof Date === false){
      throw "unknow input for find_month();";
    }
    return date.getMonth() + 1;
  },


  /**
   * Returns the year of the input date as a number
   * @param date - the date for retrieving current year in numeric format
   */
  find_year: function(date){
    if(typeof date  === "string"){
      date = Date.parseDayString(date);
    }
    else if(typeof date === "number"){
      date = new Date(date);
    }

    if(date instanceof Date === false){
      throw "unknow input for find_year();";
    }
    return date.getYear() + 1900;
  },


  /**
   * Returns a date object after parsing the input date strings
   * @param yyyy - the date string or year string, e.g. "2000 Jan 23" or 2003
   * @param mm - a string of a month, e.g. "Feb" or "02"
   * @param dd - a string of a day, e.g. "18"
   */
  to_date: function(yyyy, mm, dd){
    var date="";
    var errMsg = "Input error for Def.Rules.RuleFunctions.to_date()";


    if(yyyy == null || yyyy == undefined){
        throw errMsg;
    }
    else{
      yyyy +="";
      if(yyyy.strip() == ""){
        throw errMsg;
      }
      else{
        if(yyyy.length == 4){
           if(!mm) mm = "01";
           if(!dd) dd = "01";
           date = [yyyy, mm, dd].join(" ");
         }
         else{
          if(mm || dd)
            throw "unknow input for to_date();";
          date = yyyy;
         }
      }
    }
    date = Date.parseDayString(date);
    return date;
  },


 /* Tests to see if a field exists on a form.
   * @param field_name name of the field to test for.  If it does
   *  not begin with the Def.FIELD_ID_PREFIX, the prefix is added.  It may
   *  or may not include a suffix.  If a suffix is included it looks
   *  for that particular instance.  If a suffix is not included
   *  it looks for any instance.
   * @return boolean indicating exists/doesn't
   */
  field_exists_on_form: function(field_name) {
    if (field_name.substr(0,Def.FIELD_ID_PREFIX.length) != Def.FIELD_ID_PREFIX)
      field_name = Def.FIELD_ID_PREFIX + field_name ;
    var full = Def.IDCache.splitFullFieldID(field_name) ;
    return (Def.IDCache.findByIDStart(full[0] + full[1], full[2]).length > 0) ;
  } ,


  /**
   * Returns true if the input is blank or an exception
   * @param input - the input for checking its blankness
   */
  is_blank: function(input){
    var rtn = false;
    if (input == undefined || input == null ||
      input instanceof Def.Rules.Exceptions.NoVal){
      rtn = true;
    }
    else if(typeof input == "string" ){
      rtn  = input.strip().length == 0;
    }
    else if(typeof input == "number" ){
      rtn  = false;
    }
    else{
      throw "unknown input for is_blank().";
    }
    return rtn;
  },


  /**
   *  Searches a string for the first occurrence of a specified
   *  substring and returns its position, if found.  If the
   *  specified substring is not found, returns -1.  Basically
   *  implements the indexOf javascript function in a way that the
   *  rules parser can handle.
   *
   * @param str the string to be searched
   * @param substr the substring to be searched for
   * @return the position of the substring or -1 if it is not found
   */
   index_of: function(str, substr) {
     return str.indexOf(substr) ;
   },

  /**
   * Returns the drug_set in hash format
   *
   * @params drugSetName the name of the drug set
   **/
  get_drug_set: function(drugSetName){
    return Def.Rules.hashSets_[drugSetName];
  },

  /**
   * Return the intersect of list and set
   *
   * @params list the list of names (e.g. ["elementA", "elementC"])
   * @params thisSet the hash like set (e.g.  {elementA: 1, elementB: 2}
   *
   **/
  intersect_with_set: function(list, thisSet) {
    var rtn=[];
    for(var i=0, max = list.length; i < max; i++) {
      var listItem = list[i].trim().toLowerCase();
      if (thisSet[listItem] == 1) {
        rtn.push(list[i]);
      }
    }
    return rtn;
  },

  /**
   * Return the value of each field in the fields list
   *
   * @param fields the field list
   **/
  extract_values_from_fields: function(fields){
    var rtn = [];
    for(var i=0, max=fields.length; i< max; i++){
      rtn.push(Def.getFieldVal(fields[i]));
    }
    return rtn;
  },

  // count the occurance of the specified word in a stringr
  count_words:function(string, word_to_count){
    var str = string.toLowerCase();
    var word = word_to_count.toLowerCase();
    var strs = str.split("/");

    var rtn = 0;
    var i = 0;
    while(rtn != null && i != strs.length){
      if(strs[i].strip() == ""){
        rtn = null;
      }
      else if(strs[i].strip() == word.strip()){
        rtn +=1;
      }
      i++;
    }
    return rtn;
  },

  // hand dominance parser for ALSPAC(childen above 42 months)
  alspac_hd_parser: function(string){
    var lc = this.count_words(string, "Left");
    if(lc != null){
      var rc = this.count_words(string, "Right");
      var mc = this.count_words(string, "Either");
    }
    var rtn;

    // if there is any field left empty, then return null
    if( lc == null){
      rtn = null;
    }
    // a) if there are more htan 2 Ls and no Rs it is L
    else if(lc > 2 && rc == 0){
      rtn = "left-handed";
    }
    // c ) if there are more than 2 Rs and No L's it is R
    else if( rc > 2 && lc == 0){
      rtn = "right-handed";
    }
    // d) If there are both R's and L's and and E'sthen it is mixe
    else if( rc == lc){
      rtn = "mixed-handed";
    }
    //  Maybe (did not check) all the rest have not been defined
    else{
      rtn = "not-defined";
    }
    return rtn;
  },

  /**
   *  Returns the sum of scores inputted via a string of scores delimited by
   *  back slash
   *
   *  @param list_string - a string of scores concatinated by back slashes
   */
  sum: function(list_string){
    var rtn = 0;
    var list = list_string.strip().split(/\s*\/\s*/);
    for(var i=0; i< list.length; i++){
      var curr = parseInt(list[i]);
      if(isNaN(curr)){
        throw new Def.Rules.Exceptions.NoVal('There is an empty summation field.');
      }
      rtn += curr;
    }
    return rtn;
  }

};


// The following functions are not namespaced because they were written earlier
// and are used by other JavaScript files than this one, or because they
// might be used elsewhere.
/**
 *  Trims a field suffix to remove the last level's index number.  (For
 *  example, '_0_11' -> '_0'.  Returns the new value.  If there is nothing
 *  to trim, the original value is returned.
 * @param suffix either the full field's ID or just the suffix.
 */
Def.trimSuffix = function(suffix) {
  var re = /(.*)(_\d+)/;
  var matchData = re.exec(suffix);
  return (matchData == null) ? suffix : matchData[1];
};


/**
 *  Calls findFields to find fields close to the given field ID, and then
 *  collects the non-empty values and trims left and right whitespace.  The
 *  return value is an array of the collected values, or an empty array if no
 *  non-empty values were found.
 * @param baseFieldID the base field ID to use in the search for fields.  The
 *  parts of this ID will be passed into findFields.
 */
Def.getFieldVals = function(baseFieldID) {
  var fieldIDParts = Def.IDCache.splitFullFieldID(baseFieldID);
  var fields = findFields(fieldIDParts[0], fieldIDParts[1], fieldIDParts[2]);
  var rtn = new Array();
  for (var i=0, max=fields.length; i<max; ++i) {
    var val = Def.getFieldVal(fields[i]);
    if (val != null) {
      val = val.trim();
      if (val != "")
        rtn.push(val);
    }
  }
  return rtn;
};


/**
 *  Sets the innerHTML text of a DOM element.  This sets the value of the
 *  text node childe of the element passed in, which avoids writing over
 *  any other html that might be there (such as expand/collapse buttons,
 *  help buttons, etc.)
 *
 *  When using this be sure that you are passing in an element that has only
 *  one string of text in it.  For example, on group headers there are a few
 *  spaces before the expand/collapse button, which is followed by the header
 *  label.  If you pass in the element that contains all that, the starting
 *  spaces will be interpreted as the text node to be changed, and the actual
 *  label text will remain.   To get around that I've wrapped the label text
 *  in a span with an id, and that's the element that gets passed in.
 *
 * @param element the field, or DOM object, whose innerHTML text is to be set.
 * @param text the text that is to be substituted for the current text.
 */
Def.setInnerHTMLText = function(element, text) {

  if ($(element)) {
    element.firstChild.nodeValue = text ;
  } // end if the element passed in has an id
};


/**
 *  Tries to find a field or fields close to the given prefix and suffix.
 *  The first attempt is to find a field with exactly the given prefix and
 *  suffix.
 *  <p>
 *  If that fails, it looks for fields at deeper suffix levels that start
 *  with the given suffix.
 *  <p>
 *  If that fails, the suffix is successively shortened (and the
 *  algorithm repeated) until either matches are found or the suffix
 *  cannot be shorted further.
 *  <p>
 *  The return value is a list of fields that were found, or null if none
 *  were found.  Fields that are a part of model rows are not returned.
 *  <p>
 *  Because rules can apply to divs (group header fields) as well as input
 *  fields, this routine will return those as well.
 *
 * @param prefix the field prefix.  If this is null, FIELD_ID_PREFIX is used.
 * @param targetName - for non test panel fields, it is the target_field of a
 * field defined in field_descriptions table;  For test panel fields, it is a
 * target_field concatenated by a loinc number, e.g. tp_test_value:3333-3.
 * @param suffix the field suffix to try.
 * @return an array containing the form field element or elements found
 */
function findFields(prefix, targetName, suffix) {
  if (prefix == null){
    prefix = Def.FIELD_ID_PREFIX;
  }

  // If the field being searched related to a loinc number, split targetName to
  // get target_field and loinc_num
  if(targetName && targetName.indexOf(":")>-1){
    var tpFieldInfo = targetName.split(":");
    targetName = tpFieldInfo[0];
    var targetLoincNum = tpFieldInfo[1];
  }

  // convert "tp_target_field" to "tp1_target_field" so that it matches the one
  // on the form. TODO::all tp1 prefixes of form fields should be converted to
  // tp as the serial number seems to be not needed
  var tp = TestPanel.PREFIX;
  if( targetName && targetName.indexOf(tp +  "_")==0 ){
    // not working with multiple test panel sections in one form in which case
    // we need to also consider tp2, tp3 ...
    targetName = tp + "1" + targetName.substring(tp.length);
  }

  if (suffix == null)
    suffix = '';

  var baseField = prefix+targetName;
  var re = /^(.*)(_\d+)/;
  var rtn = [];
  var done = false;
  // Look for an exact match.  If that fails, look for child elements.
  // If that fails, shorten the suffix one level and start again.
  while (!done) {
    // See if we have an exact match.  Don't look for the element using $,
    // because for a lot cases the exact match doesn't exist, and that will
    // result in a call to getElementByID, which is relatively slow compared
    // to a lookup from the cache.
    var field = Def.IDCache.findByID(baseField+suffix);
    // If searching is done in testPanel, needs to match loinc number
    if(field && targetLoincNum
      && TestPanel.getLoincNum(field) != targetLoincNum){
          field = null;
    }

    if (field != null) {
      rtn = [field];
      done = true;
    }
    else {
      var fields = Def.IDCache.findByIDStart(baseField, suffix+'_');
      if (fields.length > 0) {
        done = true;
        // If searching is done in testPanel, needs to match loinc number
        if(targetLoincNum){
          for(var j=0, max=fields.length; j< max; j++){
            if(TestPanel.getLoincNum(fields[j]) == targetLoincNum)
              rtn.push(fields[j]);
          }
        }
        else {
          rtn = fields;
        }
      }
      else if (suffix.length == 0)
        done = true;
      else {
        // Try shortening the suffix
        var matchData = re.exec(suffix);
        if (matchData == null)
          done = true;
        else
          suffix = matchData[1];
      }
    } // else no exact match
  } // while !done

  return rtn;
}


/**
 *  Selects a field that has close to the given suffix.  This uses findFields
 *  to get a list of fields, and then if there is more than one, it picks
 *  the one given by fieldIndex.  If there is only one, fieldIndex is ignored.
 * @param prefix the field prefix
 * @param targetName the field's target_name value in the FieldDescription.
 * @param suffix the field suffix to try.
 * @param fieldIndex If there is more than one matching field, this index
 *  is used to pick one.
 * @param fromRule optional, conditions what is returned when the field is not found
 * @return the selected field, or null if one wasn't found.
 */
function selectField(prefix, targetName, suffix, fieldIndex, fromRule) {
  if (fromRule === undefined)
    fromRule = false;

  var fields = findFields(prefix, targetName, suffix);
  var rtn = null;
  if (fields.length == 1 || fieldIndex == undefined)
    fieldIndex = 0;
  if (fields.length > fieldIndex)
    rtn = fields[fieldIndex];
  if (rtn === null && fromRule) {
    throw new Def.Rules.Exceptions.NoVal('The field ' +
            targetName + " is missing");
  }
  return rtn;
}


//function parseFieldVal(field, keepCase) was moved into application_phr.js
//because validation.js needs it - Frank

/**
 *  This function propagates a shared list (in Def.data_) to all
 *  autocompleters for a specified base field name.
 *
 *  This assumes that the shared list is a hash that serves as the
 *  value in the Def.data_ hash for the key with the value of the
 *  list name parameter.  i.e. Def.data_[listName].  The keys of the
 *  hash are set to the autocompleter as the codes, and their associated
 *  values are sent as the items.
 *
 *  Autocompleters for all fields that match the fieldID passed in - up to
 *  the last digit of the suffix - are updated with the shared list.  The
 *  last digit of the suffix is started at 1 and incremented until no more
 *  fields are found.
 *
 *  This also updates the contents of the field IF it contained the old
 *  value specified.  The old value is replaced with the new value.  If
 *  that new value happens to be null, that means that the old value was
 *  deleted from the list.  In that case the corresponding code field is
 *  also set to null.  (If the old value simply is changing, the code
 *  field remains the same.)
 *
 * @param listName the name of the list; used as the key to the Def.data_
 *  hash
 * @param fieldID the ID of one instance of the field(s) with autocompleter
 *  lists to be updated
 * @param keyVal the value of the key field that is paired with the affected
 *  field (the field to be updated)
 * @param codeID the id of the form field that contains the code value
 * @param oldVal the old value being either replaced or deleted.  This
 *  should not be specified when a value is being added to the list
 * @param newVal the new value to replace the old value.  Should be null
 *  if the old value is to be deleted.  Should not be specified if a value
 *  is being added to the list.
 */
function propagateSharedList(listName, fieldID, keyVal,
                             codeID, oldVal, newVal) {

  // Build the items and codes arrays that get passed to the setList function
  var items = new Array() ;
  var codes = new Array() ;
  for (var key in Def.data_[listName]) {
    items.push(Def.data_[listName][key]) ;
    codes.push(key) ;
  }
  // get all instances of the affected field
  var idCache = Def.IDCache;
  var idParts = idCache.splitFullFieldID(fieldID) ;
  var fields = idCache.findByIDStart(idParts[0] + idParts[1], '') ;
  // get all instances of the key field

  idParts = idCache.splitFullFieldID(codeID) ;
  var codeVals = Def.IDCache.findByIDStart(idParts[0] + idParts[1], '') ;

  for (var f = 0, max = fields.length; f < max; ++f) {
    if (fields[f].autocomp != null) {
      if (oldVal != undefined &&
          fields[f].value == oldVal &&
          codeVals[f].value == keyVal) {
        fields[f].value = newVal ;
        fields[f].autocomp.setListAndField(items, codes, true) ;
      }
      else {
        fields[f].autocomp.setList(items, codes) ;
      }
    }
  }
} // end propagateSharedList


///************************************************
// * Functions for data rules (begin)
// ************************************************/
var dataRuleFunctions = {
  /**
   * Returns a string by joinning the input array with the constant
   * defaultDelimiter_
   * This is the JavaScript version of a Ruby method named generate_group_name
   * in rule_data.rb
   **/
  generateGroupName: function(inputArray){
    return inputArray.join(this.defaultDelimiter_);
  },


  /**
   * Runs all the rules attached to this trigger column
   * @param tableOrGroupName the kep maps to column name in Def.Rules.dbFieldRules_
   * @param column name of data field which is used to trigger a data rule
   */
  updateDataTableRules: function(tableOrGroupName, column){
    if (Def.Rules.dbFieldRules_) {
      var key = this.generateGroupName([tableOrGroupName, column]);
      var rules = Def.Rules.dbFieldRules_[key];
      if (rules && rules.length > 0)
        this.runFormRules(rules);
    }
  },


  /**
   * Executes the inputting data rule
   * @param ruleName name of the data rule, which must be a data rule and not a
   *  form rule.
   */
  runDataRule: function(ruleName){
    try {
      var errorMessages;
      if(Def.Rules.fetchRules_[ruleName]){
        var fetchRuleQuery = Def.Rules.fetchRules_[ruleName];
        var table_name = fetchRuleQuery[0];
        var options = fetchRuleQuery[1];
        var count = fetchRuleQuery[2];
        var ruleCall = function(){
          var searchRec = Def.DataModel.searchRecord(table_name, options, count);
          if (searchRec)
            return searchRec[0];
          else
            return null;
        };
        this.evaluateRule(ruleName, ruleCall, '', '', null);

        errorMessages = ["<<< running data rule: ",ruleName, "[fetch]: "];
      }
      else  {
        var ruleCall = this['rule_'+ruleName];
        // reminder rule needs the prefix "fe_"
        this.evaluateRule(ruleName, ruleCall, 'fe_', '', null);
        var rule_type = Def.Rules.reminderRules_[ruleName] ? "reminder" : "value";
        errorMessages = ["<<< running data rule: ",ruleName, "[", rule_type,
          "] value=", Def.Rules.Cache.ruleVals_[ruleName]];
      }
      if(Def.Rules.logLevel == "debug")
        Def.Logger.logMessage(errorMessages);
    }
    catch(e) {
      // If a rule fails, log the error, but let other rules run.
      Def.Logger.logException(e);
    }
  },

  /**
   * Runs through all the data rules. If a fetch rule was executed at serverside
   * and the result has been pushed to the browser, then skips running the fetch
   * rule and store the result into Rule.Cache
   */
  runDataRules: function(){
    var dataRules = this.dataRules_;
    for(var i=0, max=dataRules.length; i< max; i++)
      this.runDataRule(dataRules[i]);
  },


 /**
   *  Runs all of the actions for a data rule's cases.  No matter which case is
   *  selected, the actions for all of the cases must be run, so that
   *  the actions for a previously selected case can "undo" their action
   *
   * @param dataRuleName the name of the reminder or value rule
   * @param seqNums the sequence numbers of the cases in the rule
   * @param selectedCase the sequence number of the selected case
   * @param prefix the field ID prefix of the trigger field
   * @param suffix the field ID suffix of the trigger field (not used here)
   * @param triggerField - not currently used for data rules, but
   *  to preserve consistency over call sequence (since non-case rules
   *  DO use this), a null is passed through for this parameter.
   * @param ruleVal the value of the data rule
   * @param options a hash map for storing details of labels used in the data
   * rule so that "add_message" action can reference these labels while building
   * it's messages. e.g. options = {'label':{'A1':'the value for this label'}}
   * @return the value for the selected case
   */
  processDataRuleCaseActions: function(dataRuleName, seqNums, selectedCase,
    prefix, suffix, triggerField, ruleVal, options) {
    for (var i=0, max=seqNums.length; i<max; ++i) {
      var order = seqNums[i];
      if (selectedCase == order) {
        this.processDataRuleActions(dataRuleName, ruleVal,
        prefix, suffix, triggerField,
        this.ruleActions_[dataRuleName+'.'+selectedCase], options);
      }
      else {
        this.processDataRuleActions(dataRuleName, false,
        prefix, suffix, triggerField,
        this.ruleActions_[dataRuleName+'.'+order], options);
      }
    }

  },

  /**
   * Process the data rule action if any
   * @param ruleName name of reminder rule or value rule
   * @param ruleVal the value of the rule
   * @param prefix the field ID prefix of the trigger field
   * @param suffix the field ID suffix of the trigger field (not used here)
   * @param triggerField - not currently used for data rules, but
   *  to preserve consistency over call sequence (since non-case rules
   *  DO use this), a null is passed through for this parameter.
   * @param ruleActions actions attached to the reminder/value rule cases
   * @param options a hash map for storing details of labels used in the data
   * rule so that "add_message" action can reference these labels while building
   * it's messages. e.g. options = {'label':{'A1':'the value for this label'}}
   **/
  processDataRuleActions: function(ruleName, ruleVal, prefix, suffix,
                               triggerField, ruleActions, options) {
    if (ruleActions != null){
      var actionData = ruleActions[0];
      var actionName = actionData[0];
      var affectedFieldName = actionData[1];
      var actionParams = actionData[2];
      // When running reminder rules without DOM, the reminders will be stored
      // in a Def.Rules in a way similar as the reminders button on PHR form
      if (Def.Rules.nonDOM_){
        Def.Rules.messageManager = new Def.MessageManager();
        var affectedFields = [Def.Rules];
      }
      else{
//        var affectedFields = window.findFields(prefix, suffix, affectedFieldName);
        var affectedFields = findFields(prefix, affectedFieldName, suffix);
      }
      for (var i=0,max=affectedFields.length; i< max; i++){
        try {
          this.ruleAction(ruleVal, actionName, actionParams, triggerField,
            affectedFields[i], options);
        }
        catch (e) {
          Def.Logger.logException(e);
        }
      } // each affected field
    } // else process actions
  },

  /**
   * When input is a float number or integer or boolean or date,returns the input
   * When input is a stringified number, parses the string and returns the number.
   * Otherwise, returns the string itself.
   * If the input not belongs to any of the cases above, then returns null.
   *
   * @param inputVal - the input value
   **/
  parseDataRuleVal: function(inputVal){
    var rtn = null;
    if((typeof inputVal == "boolean") || (typeof inputVal == "number") ||
       (inputVal instanceof Date)){
      rtn = inputVal;
    }
    else if(typeof inputVal == "string"){
      rtn = inputVal;
      var rtnLowerCase = inputVal.toLowerCase();
      if((/^-?[0-9]*.?[0-9]+$/).exec(rtnLowerCase))
        rtn = parseFloat(rtnLowerCase);
    }
    return rtn;
  },

  /**
   * Returns value of a rule label
   * @param labelName - name of a rule label
   * @param ruleLabelCache - hash from rule label name to its value
   * @param ruleLabelParams - hash from rule label to parameters of the label.
   * for example: {"B1":["rule-name", "fetch-rule-property-name"]}
   */
  getRuleLabelVal: function(labelName, ruleLabelCache, ruleLabelParams){
    var ruleCache = Def.Rules.Cache;
    var rtn = ruleLabelCache[labelName];

    if(rtn == null || rtn == undefined){
      var params = ruleLabelParams[labelName];
      var ruleName = params[0];
      var property = params[1];

      var labelType = labelName[0];
      if(labelType == "A"){
        if(property == "is_exist"){
          // Don't use getRuleVal() as it will throw exception when rule value is null
          rtn = ruleCache.ruleVals_[ruleName] != null;
          }
        else{
          // if rule value is null, throws an exception
          rtn = ruleCache.getRuleVal(ruleName);
          rtn = rtn && rtn[property];
        }
      }
      else if(labelType == "B"){
        // if rule value is null, throw an exception
        rtn = ruleCache.getRuleVal(ruleName);
      }
      rtn = Def.Rules.parseDataRuleVal(rtn);
      ruleLabelCache[labelName] = rtn;
    }
    return rtn;
  },

  /**
   * Returns a lower cased string when the input is a string. Otherwise, returns
   * the input itself. This function is used for downcasing rule label value
   * when the label appears in rule expression, case rule expression or computed
   * value.
   * @param labelVal The input label value
   */
  toLowerCase: function(labelVal){
    return typeof(labelVal) == "string" ? labelVal.toLowerCase() : labelVal;
  },


  /**
   * Updates the rule system in case of any changes being made to
   * obx_observations data through other popup windows
   * @params profileId a profile ID
   **/
  updateRuleSystemOnObxDataChanges: function(profileId){
    var url_method = "/form/get_prefetched_obx_observations";
    //var profileId = profileId || "e6700154889bacbe" ;
    var profileId = profileId

    Def.setWaitState(false) ;
    new Ajax.Request(url_method, {
      method: 'post',
      parameters: {
        authenticity_token: window._token ,
        profile_id: profileId
      },
      asynchronous: true ,
      onSuccess: actOnSuccess,
      onFailure: function(transport) {
        Def.endWaitState(false) ;
        try {
          throw ('Error ' + transport.status + ' -- ' + transport.statusText) ;
        }
        catch (e) {
          Def.reportError(e);
          Def.showError(
            "The data on your browser may not be in sync with the server. " +
            "Please reload the page.");
        }
      },
      on404: function(transport) {
        Def.endWaitState(false);
        try {
          throw ('Error:   Prefetched obx_observations data was not found') ;
        }
        catch (e) {
          Def.reportError(e);
          Def.showError(
            "The data on your browser may not be in sync with the server. " +
            "Please reload the page.");
        }
      }
    });

    function actOnSuccess(response){
      Def.endWaitState(false) ;
      var prefetched_obx = eval('(' + response.responseText + ')');
      var ruleToValues = prefetched_obx[0];
      var completeRules = prefetched_obx[1];

      // 1) update prefetched_obx_observations for client side data model to
      //    make it up-to-date
      Def.DataModel.data_table_.obx_observations_prefetched =
        $H(ruleToValues).values();

      // 2) update obx fetch rule values
      for(var ruleName in ruleToValues){
        var ruleValue = ruleToValues[ruleName];
        Def.Rules.Cache.setRuleVal(ruleName, ruleValue);
      }

      // 3) run rules which are using the prefetched obx_observation rules
      var associatedRules = [];
      for(var i=0,max=completeRules.length;i<max;i++){
        var rule = completeRules[i];
        if (!ruleToValues[rule])
          associatedRules.push(rule);
      }

      if (associatedRules.length > 0)
        Def.Rules.runFormRules(associatedRules)
    }
  }
};
Object.extend(Def.Rules, dataRuleFunctions);
///************************************************
// * Functions for data rules (end)
// ************************************************/


// This class holds all rule label details for a rule
// and it has a function for retriving an individual label value
var RuleLabels = Class.create({
  initialize: function() {
    //this.parentRuleName = parentRuleName;
    this.getValFunc = Def.Rules.getRuleLabelVal;
    this.cache  = {};
    this.params  = {};
  },

  addLabel: function(labelName,ruleName, propertyName) {
    this.params[labelName] = [ruleName, propertyName];
  },

  /**
   * Retrives individual label value
   * @param labelName - The name of the label
   * @param dateValueToString - a boolean value when it is true, it means
   * the returning label value should be in string format if it is a date
   * and vice versa
   **/
  getVal: function(labelName, dateValueToString){
    var rtn = this.getValFunc(labelName, this.cache, this.params);
    if(dateValueToString){
      var labelProperty = this.params[labelName][1];
      if(rtn && labelProperty && labelProperty.match(/_ET$/)){
        rtn = (new Date(rtn)).toDateString();
        rtn = rtn.substr(rtn.indexOf(" ")+1);
      }
    }
    return rtn;
  }
});


