/**
 *
 * validation.js -> The required field validation object and methods
 *
 */
if (!Def)
  Def = {};

if (!Def.Validation)
   Def.Validation = {};

/**
 * Definition of some words used in required field validation:
 *
 *  normal-line: a line when it is empty, any required field on it is valid
 *  abnormal-line: none of the required fields on this line can be left blank
 *  repeating-line: either normal line or abnormal line
 *  common-required-field: required field which is not on normal-line
 **/
Def.Validation.RequiredField = {};

Def.Validation.RequiredField.Functions = {
    /**
     * Returns true when we need to debug validtion js code
     **/
    debugStatus_: true,

    /**
     * List of all required field ids on the form
     */
    reqFldIds_: [],

    /**
     * A data hash from field ID to a boolean. When the boolean value is true,
     * the corresponding field is an invalid required and vice versa
     */
    reqErrHash_: {},

    /**
     * A flag indicating whether or not we need to show the floating error
     * messages
     */
    showErrMsgs_: false,

    /**
     * When the page first gets loaded, observes all the required fields and
     * the TR rows of normal-lines. CAN ONLY CALL THIS ONCE!!!!
     **/
    loadValidator: function() {
      var start = new Date().getTime();

      // Refreshes real required field id list on the page
      // Checked with PHR form, there is no required field of tag div. Do not
      // remember any other required field which has tag DIV. The related line
      // of code was commented out - Frank
      var reqFlds = $('main_form').getElementsBySelector(
        'div.required:not(.hidden_field)',
        'input.required:not(.hidden_field)',
        'textarea.required:not(.hidden_field)');
      var idList = [];
      for(var i=0, max = reqFlds.length; i< max ; i++) {
        // filter all the header fields whose suffix end with 0 except for test
        // panel fields
        var suffix =  Def.IDCache.splitFullFieldID(reqFlds[i].id)[2];
        if (suffix.split("_").last() != "0")
          idList.push(reqFlds[i].id);
      }
      this.reqFldIds_ = idList;


      Def.Logger.logMessage(['Load required field validations in ', start],
        this.debugStatus_, true);
    },//end of loadValidator()


    /**
     * Resets the required field validation system so that all the messages
     * and/or highlights related to invalid required fields are cleared
     **/
    resetReqFldValidation: function() {
      // Remove error marks on error fields stored in this.reqErrHash_
      // 1) Reset field properties (i.e. invalid and errorMessage).
      //    Also update this.reqErrHash_.
      var rlist = $H(this.reqErrHash_).keys();
      for(var i= 0, max=rlist.length; i< max; i++) {
        var cur = $(rlist[i]);
        this.removeError(cur);
      }
      // 2) Reset outline, tooltip and floating error div.
      this.showErrMsgs_ = false;
      Def.Validation.RequiredField.ErrDisplay.showErrs(true);
    },  // end of resetReqFldValidation


//    /**
//     * Resets the common or normal-line required field validation status based
//     * on the input field.
//     * This function is used by Def.runValidations function.
//     *
//     * @param field the field to be used to determine which type of required field
//     * validation needs to be reset
//     **/
//    resetRequiredFieldValidationByField: function(field) {
//      if (this.isNormalLine(field)) {
//        //find all the required field on that line
//        var requiredFields = this.findLineFields(field)[1];
//      }
//      else {
//        if (this.isRequired(field))
//          requiredFields = [field];
//      }
//
//      if (requiredFields) {
//        for(var i=0, max=requiredFields.length; i<max; i++)
//          delete this.reqErrHash_[requiredFields[i].id];
//        this.showErrMsgs_ = false;
//        Def.Validation.RequiredField.ErrDisplay.showErrs(true);
//      }
//    }, // end of resetReqFldValidationForSingleField


    /**
     *  Registers validation handler
     *  When input line is normal-line, register corresponding handlers to
     *  required fields and its TR row
     *  When input line is abnormal-line, only register required field with
     *  corresponding handler
     *
     *  @param newRepLine newly added repeating-line
     **/
    enableValidationOnNewLine: function(newRepLine) {
      if (document.loaded) {
        var reqFldList = this.findLineFields(newRepLine)[1];

        if (reqFldList.length > 0) {
          // refresh the required fields list - CHANGE TO INSERTION
          // saving: from 20 ms to 5 ms
          this.insertNewReqFlds(reqFldList);
        }
      }
    }, //end of enableValidationOnNewLine()


    /**
     * Returns true if all the required fields are valid, vice versa.
     * Display error messages and outlines all invalid fields if any
     * Assume all the required fields are known
     *
     * @param field button being clicked - Doesn't seem to be used, so
     *  I am passing a null value for this from the PHR Home page, edit/enter
     *  demographics data box.  10/1/13 lm.
     * @param showErrMsgs a flag indicates whether to show the error message
     **/
    validateAll: function(field, showErrMsgs) {
      if (showErrMsgs == undefined || showErrMsgs == null) {
        showErrMsgs = true;
      }
      this.showErrMsgs_ = showErrMsgs;
      var start = new Date().getTime();
      this.reqErrHash_ = {};
      this.updateErrHash();
      Def.Logger.logMessage(["update err hash finished in ", start],
        this.debugStatus_, true);


      var rtn = Def.Validation.RequiredField.ErrDisplay.showErrs(true);
      Def.Logger.logMessage(["Required field validation finished in " ,start],
        this.debugStatus_, true);
      return !rtn;
    }, // end of function: validateAll()


     /**
     * Validates all required fields on a normal-line or a test panel and refresh
     * corresponding outlines and error messages on the page (Also used in
     * fields_group_helper.rb)
     *
     * @param field a trigger field on a normal line
     **/
    validateNormalLine: function(field) {
      var start = new Date().getTime();
      // skip this function before submit button was clicked
      this.updateErrHashForFields(field, {});
      Def.Validation.RequiredField.ErrDisplay.showErrs(false, field);
      Def.Logger.logMessage(["Validate normal line finished in ", start],
          this.debugStatus_, true);
    },// end of validateNormalLine()


    /**
     * Validates common-required-field and refresh the corresponding error
     * message and outline on the page (Also used in form_helper.rb)
     *
     * @param field a common-required-field which triggers the validation
     **/
    validateCommonField: function(field) {
      var start = new Date().getTime();
      // Skip this function before click the submit button
      this.updateErrHashForCommonField(field);
      Def.Validation.RequiredField.ErrDisplay.showErrs(false, field);
      Def.Logger.logMessage(["Validate common field finished in ", start],
        this.debugStatus_, true);
    },//end of validateCommonField()


    /**
     * Validates all the required fields and updates the data hash containing
     * requird field errors accordingly.
     **/
    updateErrHash: function() {
      var idList = this.reqFldIds_;
      var errHash = this.reqErrHash_;
      var processedReqFlds={};

      for(var i = 0, max = idList.length; i< max; i++) {
        var currId = idList[i];
        var currFld = $(currId);

        if (processedReqFlds[currId]==null) {
          if (this.isNormalLine(currFld)) {
            // Avoid unnecessary validation which may set the validation_enabled
            // status to true for required fields on the new line of each section
            // (e.g. the last line of the drug section). Also see comments in
            // function updateErrHashForFields (searching by "Use cases").
            if (!this.onLastLine(currFld))
              this.updateErrHashForFields(currFld, processedReqFlds, true);
          }
          else{
            this.updateErrHashForCommonField(currFld);
          }
        }
      }
    }, // end of function: updateErrHash()


   /**
     * Validates a normal line or test panel and updates data hash containing
     * the required field errors accordingly. Marks all the processed required
     * field in the processedReqFlds hash.
     *
     * @param currFld a field on a normal line
     * @param processedReqFlds a hash map from required field id to a flag
     * which indicates whether the required field has been processed or not
     * @param all a flag indicating whether we should validate all the required
     * fields or just the fields whose validation_enabled status are true
     **/
    updateErrHashForFields: function(currFld, processedReqFlds, all) {
      var twoLists = this.findLineFields(currFld);
      var isLineEmpty = this.isLineEmpty(twoLists[2]);
      var inTestPanel = twoLists[3].length > 0 ;

      // When the currFld is in test panel
      if (inTestPanel) {
        var noTestValue = this.isLineEmpty(twoLists[3]);
        isLineEmpty = isLineEmpty && noTestValue;
      }

      var rList = twoLists[1];
      for(var i=0, max=rList.length;i<max;i++) {
        var rFld = rList[i];
        if (processedReqFlds[rFld.id] == null) {
          if (!rFld.validation_enabled && (all==true || currFld.id == rFld.id))
            rFld.validation_enabled = true;
          // Only validate the sibling required fields if they've been validated.
          // Use cases:
          // 1) When we type in a drug name and run validation, the required
          // drug status field shouldn't be marked as invalid if we haven't had
          // a chance to enter the status value.
          // 2) In "Questions to Ask Doctor" section where the first entry is a
          // date field. When we run the validation on that field, the sibling
          // required "Question" field shouldn't be marked as invalid before we
          // had a chance to enter our question.
          if (rFld.validation_enabled)
            isLineEmpty ? this.removeError(rFld) :
                          this.updateErrHashForCommonField(rFld);
          processedReqFlds[rFld.id] = 1;
        }
      }
    },//updateErrHashForFields()


    /**
     * Validates the input common field (ie. a required field always needs to
     * have a value in order to keep it valid) and updates data hash containing
     * all required field errors accordingly.
     *
     * @param currFld a common field
     */
    updateErrHashForCommonField: function(currFld) {
      // for a deleted field (through controlled_edit_table) will be marked as
      // a disabled field, therefore will be treated as non-required field
      this.isBlankField(currFld) && isHiddenOrDisabled(currFld, true) == false ?
        this.addError(currFld) : this.removeError(currFld);
    }, // updateErrHashForCommonField()


    /**
     * Sets the hash value of the input field to TRUE in reqErrHash_ if its
     * current hash value is FALSE
     *
     * Parameters:
     * @params currFld the invalid required field
     */
    addError: function(currFld) {
      if (this.reqErrHash_[currFld.id] === undefined) {
        this.reqErrHash_[currFld.id] = true;
      }
      currFld.invalid = true;
      currFld.errorMessage =
        Def.Validation.RequiredField.ErrDisplay.getTooltipErrMsg(currFld);
    }, //addError()


    /**
     * Sets the hash value of the input field to FALSE in reqErrHash_
     * if its current hash value is TRUE
     *
     * Parameters:
     * @params currFld the valid required field
     */
    removeError: function(currFld) {
      if (this.reqErrHash_[currFld.id] !== undefined) {
        delete this.reqErrHash_[currFld.id];
      }
      currFld.invalid = false;
      currFld.errorMessage = null;
    }, //removeError()


    /**
     * Returns true if all the input line fields are empty, vice versa
     * @param lineFields all visible input fields on a line
     **/
    isLineEmpty: function(lineFields) {
      var empty = true;
      for(var i=0, max = lineFields.length; i< max && empty ; i++) {
        if (!this.isBlankField(lineFields[i]))
          empty = false;
      }
      return empty;
    },//end of idLineEmpty()


    /**
     * Insert required field ids into the this.reqFldIds_ list so that
     * this.reqFldIds_ will have all required field ids and they will be in
     * the same order as it appears in the DOM
     *
     * @param reqFlds required fields on the newly added repeating line
     **/
    insertNewReqFlds: function(reqFlds) {
      var start = new Date().getTime();

      // get last required field id (preLastReqId) of the line above the new line
      var lastReqFldId = reqFlds.last().id;
      var idParts = lastReqFldId.split("_");
      idParts[idParts.length -1] -= 1
      //      var preSeq = idParts.pop() -1;
      //      idParts.push(preSeq);
      var preLastReqFldId = idParts.join("_");

      var index = this.reqFldIds_.indexOf(preLastReqFldId);
      // if the new required fields are in the new test panel
      // then append to this.reqFldIds_ with the required field ids of new line
      if (index == -1) {
        for(var i=0, max=reqFlds.length; i< max; i++) {
          this.reqFldIds_.push(reqFlds[i].id);
        }
      }
      else{
        // find the index of preLastReqId in this.reqFldIds_
        // insert the require field ids of new line at index point
        var reqFldIdsTemp = this.reqFldIds_.clone();
        //      var index = reqFldIdsTemp.indexOf(preLastReqFldId);
        this.reqFldIds_ = reqFldIdsTemp.splice(0, index + 1);
        for(i=0, max=reqFlds.length; i< max; i++) {
          this.reqFldIds_.push(reqFlds[i].id);
        }
        this.reqFldIds_ = this.reqFldIds_.concat(reqFldIdsTemp);
      }

      Def.Logger.logMessage([" insertNewReqFlds in: ", start],
        this.debugStatus_, true);
    },//end of insertNewReqFlds()


    /**
     * Finds all the fields sitting on the same line as the input obj and
     * returns two lists of fields (not required fields and required fields) in
     * an array
     *
     * @params obj an input field or all input fields on a normal-line
     **/
    findLineFields: function(obj) {
      var slist = [], rlist = [], vlist = [], eblist =[];
      var fields = [], ebIndex = null, i, max, tmp;
      if (obj.length != undefined) {
        for(i = 0, max = obj.length; i< max; i++) {
          if (!checkClassName(obj[i], 'hidden_field'))
            fields.push(obj[i]);
        }
      }
      else{
        if (Def.DataModel.initialized_)
          tmp = this.findLineFieldsCandidatesByDataModel(obj);
        else
          tmp = this.findLineFieldsCandidatesByForm(obj);

        fields = tmp[0];
        ebIndex = tmp[1];
      }

      for(i = 0, max = fields.length; i< max; i++) {
        var currFld = fields[i];
        tmp = this.isRequired(currFld) ? rlist : slist;
        tmp.push(currFld);
        vlist.push(currFld);
        // get list of vertical input fields
        if (i > ebIndex -1) eblist.push(currFld);
      }
      return [slist, rlist, vlist, eblist];
    },// end of findLineFields()


    /**
     * Returns all line fields of a normal line which contains the specified
     * input field. Also works for test panel where horizontal line fields are
     * treated as normal line fields and vertical fields are treated as extra
     * fields on the horizontal line.
     * This function searches for fields by data model.
     *
     * @param obj an input field of a normal line
     **/
    findLineFieldsCandidatesByDataModel: function(obj) {
      var returnFields = [];
      var lineFieldCount = 0;
      var affectedObrFields = ['test_date','test_date_time','test_place','summary','due_date'];
      var affectedObxField = 'obx5_value';
      var defModel = Def.DataModel;
      var dbLocation = defModel.getModelLocation(obj.id);
      // ignore the fields in the hidden rows that are the first rows in the tables.
      if (dbLocation) {
        // if obj is an obr field
        if (dbLocation[0] == defModel.OBR_TABLE || dbLocation[0] == defModel.OBX_TABLE ) {
          if (dbLocation[0] == defModel.OBR_TABLE)
            var obrNum = defModel.getModelFieldValue(defModel.OBR_TABLE,'_id_', dbLocation[2]);
          else
            obrNum = defModel.getModelFieldValue(defModel.OBX_TABLE,'_p_id_', dbLocation[2]);

          // find the obr fields
          for(var k= 0, kl=affectedObrFields.length; k<kl; k++) {
            var field = defModel.getFormField(defModel.OBR_TABLE, affectedObrFields[k], obrNum+1);
            returnFields.push(field);
          }
          // find the obx fields
          var taffy = defModel.taffy_db_[defModel.OBX_TABLE];
          var obxFields = [];
          var obxNums = taffy.find({_p_id_:obrNum});
          // get obx fields (obx5_value only)
          for(var j=0, lj=obxNums.length; j<lj; j++) {
            var field = defModel.getFormField(defModel.OBX_TABLE, affectedObxField, obxNums[j]+1);
            obxFields.push(field);
          }
          lineFieldCount = returnFields.length;
          returnFields = returnFields.concat(obxFields);
        }
        // obj is not a test panel field
        else {
          // find all the line fields
          var lineFields = defModel.getAllFormFieldsAtRowPosition(dbLocation[0], dbLocation[2]);
          for (var i=0, ilen= lineFields.length; i < ilen; i++) {
            if (!checkClassName(lineFields[i], "hidden_field"))
              returnFields.push(lineFields[i]);
          }
          lineFieldCount = returnFields.length;
        }
      }


      return [returnFields, lineFieldCount]
    },// end of findLineFieldsCandidatesByDataModel()


    /**
     * Returns all line fields of a normal line which contains the specified
     * input field. Also works for test panel where horizontal line fields are
     * treated as normal line fields and vertical fields are treated as extra
     * fields on the horizontal line.
     * This function searches for fields by DOM.
     *
     * @param obj an input field of a normal line
     **/
    findLineFieldsCandidatesByForm: function(obj) {
      var nlRow = getAncestor(obj, "TR");
      var ebRow = null;

      // if obj is a horizontal field in a test panel, try to find the
      // embedded row next to it
      var nlRowNext = nlRow.next();
      if ( nlRowNext && checkClassName(nlRowNext, "embeddedRow")) {
        ebRow = nlRowNext;
      }
      // if obj is vertical field in a test panel, try to find the embedded
      // row containing the obj and the repeatingLine above/next to the
      // embedded row
      else if (!nlRowNext || !checkClassName(nlRowNext, "embeddedRow")) {
        var eb_tmp = getAncestor(nlRow, "TR");
        if (eb_tmp && checkClassName(eb_tmp, "embeddedRow")) {
          var eb_previous = eb_tmp.previous();
          if (eb_previous && checkClassName(eb_previous, "repeatingLine")) {
            nlRow = eb_previous;
            ebRow = eb_tmp;
          }
        }
      }

      // find all candidate fields on repeating line(i.e. nlRow) and embedded
      // row (i.e. ebRow)
      var rlSelector = nlRow.getElementsBySelector.bind(nlRow);
      var rtn = rlSelector("input:not(.hidden_field), textarea:not(.hidden_field)");
      var ebCount = rtn.length;
      if (ebRow) {
        var rlErSelector = ebRow.getElementsBySelector.bind(ebRow);
        var flist = rlErSelector("input:not(.hidden_field), textarea:not(.hidden_field)");
        for (var i=0, max= flist.length; i< max; i++) {
          var cur = flist[i];
  //          if (cur.getAttribute("readonly") != "readonly"
  //            && !checkClassName(cur, "panel_header")) {
          if (!checkClassName(cur, "panel_header") &&
              cur.id.indexOf("test_value") > 0) {
            rtn.push(cur);
          }
        }
      }
      return [rtn, ebCount];
    },// end of findLineFieldsCandidatesByForm()


    /**
     * Returns true if the field is blank or vice versa
     *
     * @params field the field needs to be checked
     **/
    isBlankField: function(field) {
      var fldVal = parseFieldVal(field), rtn = false;
      if ( fldVal == null || fldVal === "") rtn = true;
      // If the checkbox is not checked, return true and vise versa
      // See sign on page, check box of id 'fe_agree_chbox_1'
      if (field.type =="checkbox")
        rtn = !field.checked;
      return rtn;
    },// end of isBlankField()


    /**
     * Defines an abnormal-line field is a field sitting under the "signup_quest"
     * Node. Returns false if the field is on an abnormal-line and returns true if the
     * field is on a normal line
     *
     * @param field a field on a line
     **/
    isNormalLine: function(field) {
      var rtn = this.onRepeatingLine(field) ? true : false;

      // assume the field must be on a repeating-line
      var targetFieldName= "signup_quest";
      var p= field;
      // If we found the targetFieldName in field's parents, then return false
      var idCache = Def.IDCache;
      while( rtn && (p = p.parentNode) && (p != document) ) {
        if (p.id && idCache.splitFullFieldID(p.id)[1] == targetFieldName) {
          rtn = false;
        }
      }
      return rtn;
    },// end of isNormalLine()


    /**
     * Checks to see if there is a field in the same column on the line below
     * the current line
     * @param field a field on a normal line
     */
    onLastLine: function(field){
      var idParts = field.id.split("_");
      idParts[idParts.length-1] = parseInt(idParts.last()) + 1;
      return $(idParts.join("_")) ? false : true;
    },


    /**
     * Returns true if the field is on a repeating line and vice versa
     *
     * @param field an input field
     **/
    onRepeatingLine: function(field) {
      return getAncestor(field, "TR") != null;
    },//end of onRepeatingLine()


    /**
     * Checks both horizontal and vertical fields in a test panel to see if there
     * is any field inside the row with className "test_optional"
     *
     * @param field one of the input field in a test panel
     **/
    hasSiblingTestOptionalField: function(field) {
      var rtn = false;
      if (this.isNormalLine(field)) {
        var processed_rows = [];
        var fields = this.findLineFields(field)[2];
        for(var i=0, max= fields.length; i< max && !rtn; i++) {
          var row = getAncestor(fields[i],"TR");
          if (row && processed_rows.indexOf(row) < 0) {
            processed_rows.push(row);
            if (checkClassName(row, "test_optional")) rtn = true;
          }
        }
      }
      return rtn;
    },//end of hasSiblingTestOptionalField()


    /**
     * Returns true when the input field is a required field and vice versa
     *
     * @param field input field
     **/
    isRequired: function(field) {
      return field.hasClassName("required");
    },


    /**
     * Unregisters the input field from the validation system after it was
     * removed from DOM tree (see removeRecordsAndUpdateMappings function in
     * data_model.js for details)
     **/
    unregisterField: function(field) {
      var field_id = $(field).id;
      delete this.reqErrHash_[field_id];
      var index = this.reqFldIds_.indexOf(field_id);
      if (index > -1)
        this.reqFldIds_.splice(index, 1);
    }
}// end of Functions


Def.Validation.RequiredField.ErrDisplay = {

  errDivClassName_:"errReqDiv",

  errOutlineClassName_:"errReqOutline",

  errMsgInParenthesisClassName_: "errMsgInParen",

  /**
   * DOM Element containing the floating error messages
   */
  errMsgDiv_:null,

  /**
   * ClassName for a link used for closing the floating error div
   */
  closingLinkClassName_: 'closingLink',


  errOutlineFields_:[],

  reqFuncs: Def.Validation.RequiredField.Functions,

  messages: {
    "tpNormalLine": "Please enter a value or clear this panel.",
    "normalLine"  : "Please enter a value or clear the entire row.",
    "otherReq"    : "This field must not be left blank."
  },

  headerBarDiv_: $("fe_form_header_0_expcol"), // form header bar

  /**
   * Returns true if there is any invalid required field and vice versa.
   * Displays error messages in a floating DIV and outline the invalid required
   * fields if any.
   *
   * @param showAll a flag indicating whether we will display all or single
   * error message in the floating error div
   * @param alarmField a required input field. When it is invalid, an alarm
   * with few shakes and a "bonk" sound should be set off
   **/
  showErrs: function(showAll, alarmField) {
    // Removes all required-field error messages
    this.removeFloatingErrMsg();
    this.removeOutlines();

    var errList = this.getErrList();
    if (errList.length > 0 ) {
      // find the alarm field
      if (alarmField!=null) {
        alarmField = $(alarmField);
        var alarmOn = true;
      }

      //alarmField = alarmField != null ? $(alarmField) : errList[0];
      var displayErrIndex = errList.indexOf(alarmField);
      if (displayErrIndex == -1) {
        alarmOn = false;
        displayErrIndex = 0;
      }

      var errFieldNames = [];
      for(var i = 0, max = errList.length; i< max; i++) {
        var errField = errList[i];
        // outline each invalid required field and add tooltip listener to field
        this.outlineErrField(errField);
        // If invalid field in collapsed folder, expend the folder to show the
        // invalid field
        if (isHiddenOrDisabled(errField)) this.expandToShowField(errField.id);
        // show hidden vertical input fields in test panel
        if ( this.reqFuncs.hasSiblingTestOptionalField(errField))
          this.showTestOptionalFields(errField.id);
        // collect error messages for the floating error div
        if (this.reqFuncs.showErrMsgs_ == true)
          errFieldNames.push(this.makeClickableAndBold(errField, showAll));
      }

      // show errors message(s)
      var len = errFieldNames.length;
      if (len > 0) {
        var divHtml = len > 1 ? "These fields" : "This field";
        divHtml += " must not be blank: <ul><li>" + errFieldNames.join("</li><li>");
        divHtml +=  "</li></ul>";
        this.addFloatingErrMsg(divHtml);
      }

      // Set off alarm if needed
      if (alarmOn)
        Def.FieldAlarms.setOffAlarm(alarmField);

      return true;
    } else {
      // The display of yellow error message box should be turned off after all
      // of the required fields were filled out. Save button needs to be clicked
      // in order to make the yellow error message box appear again for any
      // subsequent invalid required field
      this.reqFuncs.showErrMsgs_ = false;

      return false;
    }
  },//end of showErrs()


  /**
   * Closes the floating div of error messages
   */
  closeFloating: function() {
    this.reqFuncs.showErrMsgs_ = false;
    this.removeFloatingErrMsg();
  },//closeFloating


  /**
   * Returns an ordered list of ids of invalid required fields using updated
   * this.reqFldIds_ and an invalid required fields hash
   **/
  getErrList: function(needId) {
    var errHash = this.reqFuncs.reqErrHash_;
    var idList = this.reqFuncs.reqFldIds_;
    var errList=[];

    for(var i= 0, max= idList.length;  i<max; i++) {
      if (errHash[idList[i]] == true) {
        var e = needId ? idList[i] : $(idList[i]);
        errList.push(e);
      }
    }
    return errList;
  },//end of getErrList()


  /**
   * Removes the floating error message div.
   **/
  removeFloatingErrMsg:function() {
    //clear the floating error message
    var errMsgDiv = $('validation_errors');
    errMsgDiv.addClassName('screen_reader_only');
  }, //removeFloatingErrMsg()


  /**
   *  Returns true if the validation error messages are showing.
   */
  messagesVisible: function() {
    return !$('validation_errors').hasClassName('screen_reader_only');
  },


  removeOutlines:function() {
    //clear all the outlines
    var list = this.errOutlineFields_;
    var errClass = this.errOutlineClassName_;
    for(var i = 0, max = list.length; i < max; i++) {
      var curr = list[i];
      if (curr.hasClassName(errClass)) {
        curr.removeClassName(errClass);
        removeTooltip(curr);
      }
      // If the input field is contained in a td element, then we should be able to
      // find in td element the same class which helps to make the invisible part of
      // the outline visible
      var tdElement = getAncestor(curr, "TD");
      if (tdElement && tdElement.hasClassName(errClass))
        tdElement.removeClassName(errClass);
    }
    this.errOutlineFields_ = [];
  },//end of removeOutlines()


  /**
   * Adds a floating error message div with htmlTxt to the form and returns that
   * error message div
   *
   * @param htmlTxt the innerHTML of floating error message div
   **/
  addFloatingErrMsg: function(htmlTxt) {
    var errMsgContent = $('validation_alert');
    errMsgContent.innerHTML = htmlTxt;

    // Check if there is a top nav bar (i.e. a  bar for settings, logout links )
    var errMsgDiv = $('validation_errors'); // contains validation_alert
    var hh = 0;
    if (this.headerBarDiv_)
       hh += this.headerBarDiv_.offsetTop + this.headerBarDiv_.offsetHeight
    errMsgDiv.style.top= hh + "px";

    errMsgDiv.removeClassName('screen_reader_only');
    return errMsgDiv
  },// end of AddFloatingErrMsg()


  /**
   * Returns an required field error message for building a tooltip
   * @param field the field for generating error message
   **/
  getTooltipErrMsg: function(field) {
    // Per Dr. McDonald, if no test result for when done date, then invalid
    // the when done date
    var errorMsg;

    var tpNormalLineMsg  = this.messages["tpNormalLine"];
    var normalLineMsg = this.messages["normalLine"];
    var otherReqMsg   = this.messages["otherReq"];
    errorMsg = this.reqFuncs.isNormalLine(field) ?
      (TestPanel.inTestPanel(field) ? tpNormalLineMsg : normalLineMsg) : otherReqMsg;
    return errorMsg;
  },// end of getTooltipErrMsg()

  /**
   * Returns a clickable labelName in HTML which will take user to a field with
   * specified id
   *
   * @param field the field user will be taken to after click the link returned
   * by this function
   * @param showAll a flag indicating whether or not the floating div which
   * has link(s) made by this function will show all or single error message
   **/
  makeClickableAndBold: function(field, showAll) {
    var labelNameParts = Def.getLabelName(field);
    var fieldName = labelNameParts[0];
    var parenthesisPart = labelNameParts[1];

   var rtn = [];
    rtn.push( "<a href='#label' onclick='");
    if (showAll)
      rtn.push("Def.Validation.RequiredField.ErrDisplay.showErrs(false);");
//      rtn.push("Def.Validation.RequiredField.ErrDisplay.showErrs(false,\"" +
//               field.id + "\");");
    var listOfTopDivs = [this.errDivClassName_];
    if (this.headerBarDiv_)
      listOfTopDivs.push(this.headerBarDiv_.id);
    listOfTopDivs = listOfTopDivs.join("\",\"")
    rtn.push("jumpTo(\"" +field.id + "\",[\""+ listOfTopDivs + "\"]);'>" );
    rtn.push( fieldName + "</a>");
    rtn.push("<span class='"+ this.errMsgInParenthesisClassName_ + "'>");
    rtn.push(parenthesisPart + "</span>");
    return rtn.join("");
  },// end of makeClickableAndBold()


  /**
   * Outlines the field using CSS, shakes the field, and plays a sound
   * @param field the input field
   **/
  outlineErrField: function(field) {
    if (this.errOutlineFields_.indexOf(field) == -1)
      this.errOutlineFields_.push(field);
    var className = this.errOutlineClassName_;

    if (!checkClassName(field, className)) {
      field.addClassName(className);
    }

    // If the INPUT field is contained in a TD, the right part of its outline
    // will be hidden. Solution: add 4px of padding-right style to the TD using
    // the same className
    var tdElement = getAncestor(field,"TD");
    if (tdElement && !tdElement.hasClassName(className))
        tdElement.addClassName(className);

    // Create tooltip for invalid required fields
    addTooltip(field, field.errorMessage, "close");

    // also outline the tipMessage since it will be needed when the field is
    // covered with the tipMessage
    var tipMsg = field.next();
    if (tipMsg &&
      (tipMsg.tagName == "SPAN") &&
      checkClassName(tipMsg, "tipMessage")  &&
      !checkClassName(tipMsg, className) ) {
      tipMsg.addClassName(className);
    }
  },// end of outlineErrField()

  /**
   * Searchs along parentNodes to find elements which has className
   * "expand_collapse" and expands it
   *
   * @param fieldID ID of the field to start searching with
   */
  expandToShowField: function(fieldID) {
    var curNode = $(fieldID);
    curNode = curNode.parentNode || curNode;
    var expNode = null;
    // Stop searching when we hit document
    while(curNode.parentNode != null) {
      if (checkClassName(curNode, "expand_collapse")) {
          expNode = curNode;
      }
      curNode = curNode.parentNode;
    }
    if (expNode)
      expColAll("expand", curNode);
  },

  /**
   * Shows all the vertical fields in a test panel
   *
   * @param horizontalFieldID an ID of horizontal input field in test panel
   **/
  showTestOptionalFields: function(horizontalFieldID) {
    var rl = getAncestor($(horizontalFieldID),"TR");
    var button = rl.parentNode.select("button.show_more")[0];
    if (button) {
      appFireEvent(button, 'click');
      Def.Logger.logMessage(["firing onclick event on button ", button.id]);
    }
  }
}// end of Def.Validation.RequiredField.ErrDisplay


/**
 * Observer will validate both normal line and common required fields, then
 * update error messages accordingly
 **/
Def.Validation.ObserveHandlers ={
  /**
   * An observer handler for validate common-required-fields
   **/
  commonReqFldValidator: function() {
    Def.Validation.RequiredField.Functions.validateCommonField(this);
  },// end of commonReqFldValidator()


  /**
   * An observer handler for validating normal-line required fields.
   **/
  normalLineReqFldValidator: function() {
    Def.Validation.RequiredField.Functions.validateNormalLine(this);
  } //end of normalLineReqFldValidator()
}// end of Def.Validation.ObserveHandlers


Def.Validation.Xss = {

  /**
   * An jQuery dialog containning warning message for any data field which has
   * HTML tag
   */
  dialog_: null,

  /**
   * Returns true if there is no HTML found in the field value and vice versa
   * @params field a data input field
   **/
  validateFieldValue: function(field) {
    // Escapes any HTML tags found in the field value by making sure there is a
    // space or "=" right after each less-than sign.
    // The sanitized field value will be stored in variable named "rtn"
    var xssFound = false;
    var rtn = Def.getFieldVal($(field));
    var regex = /(<|%3C|&(lt|#(0*60|x0*3c));?|\\(x|u00)3c)([^\s+])/i;
    rtn = rtn.gsub(regex, function(match) {
      if (match && match[5] != "=") {
        xssFound = true;
        return match[1]+" "+match[5];
      }
    });

    if (xssFound) {
      // Updates the field value with the sanitized version
      Def.setFieldVal($(field), rtn, false);

      var fieldName = Def.getLabelName(field)[0];
      var title= "HTML is not allowed in the \""+ fieldName+ "\" field";
      var msg =
        "In order to prevent hackers from inserting malicious code in your data,\
         all potential HTML tags, which start with a '<', have been modified by\
         adding a space after the less-than sign (<).  To avoid this warning,\
         please make sure there is a space after any less-than sign if you need\
         to use it. Thank you."
      var msg = "<small>" + msg + "</small>"
      this.showWarning(title, msg);
    }
    return !xssFound;
  },

  // Uses a modal popup to remind users of any HTML tag found in the data they
  // entered
  showWarning: function(title, msg) {
      var warningDialog = this.dialog_ || new Def.NoticeDialog({
        width: 700
      });
      warningDialog.setTitle(title);
      warningDialog.setContent(msg);
      warningDialog.show();
      this.dialog_ = warningDialog;
      return warningDialog;
  }
}
