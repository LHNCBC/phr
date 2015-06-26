// $Log: fieldOps.js,v $
// Revision 1.36  2010/12/22 17:37:34  taof
// remove obsoleted js function for fetching latested records
//
// Revision 1.35  2010/12/22 16:48:34  wangye
// fixed a conflict of jQuery and prototype when both are minimized into one file.
//
// Revision 1.34  2010/12/21 19:45:32  taof
// code review#219 changes
//
// Revision 1.33  2010/10/26 19:58:27  taof
// only show when done field when panel is empty
//
// Revision 1.32  2009/12/22 22:22:43  plynch
// Changed splitFullFieldID so that its return value is cached, updated
// the code to be aware of that, and moved the function into idCache.js.
//
// Revision 1.31  2009/09/28 20:50:26  taof
// *** empty log message ***
//
// Revision 1.30  2009/08/24 21:57:40  taof
// FieldOps#latest_from_form performance issue
//
// Revision 1.29  2009/06/16 20:34:05  taof
// add bmi rule
//
// Revision 1.28  2009/06/09 21:30:15  taof
// add new reminder rules for tests including pap, mamm, abdominal and colon cancer etc
//
// Revision 1.27  2009/05/29 17:26:17  lmericle
// fixed call to latest_from_table
//
// Revision 1.26  2009/05/27 14:38:41  taof
// create flu shot rule and modified loinc related latest rules
//
// Revision 1.25  2009/04/22 22:34:21  plynch
// Fixes for the controlled edit table to initialize listeners on fields for
// rows that are made editable.
//
// Revision 1.24  2009/03/30 21:07:39  plynch
// Changes to disable saved rows (part of controlled edit table changes.)
//
// Revision 1.23  2009/03/20 22:10:59  wangye
// js performance improvement
//
// Revision 1.22  2009/03/11 17:05:14  taof
// restore broken rules: latest_chol etc
//
// Revision 1.21  2009/03/05 21:41:25  taof
// restore broken test panel rules and fix bug in FieldOps#latest_loincFn()
//
// Revision 1.20  2009/03/05 15:53:11  taof
// rebuild latest_sysbp rule based on new test panel
//
// Revision 1.19  2009/02/27 23:01:00  smuju
// adedd method field_length
//
// Revision 1.18  2009/02/27 20:14:41  taof
// modify rule parser to work with new test panel
//
// Revision 1.17  2008/12/09 23:57:26  taof
// codingStd: fix wrong indentation in fieldOps.js, rules.js
//
// Revision 1.16  2008/12/09 22:44:03  taof
// bugfix: FieldOps.js#select_fields has a dead loop
//
// Revision 1.15  2008/12/09 20:35:14  taof
// build new functions for creating active_statin_drug rule
//
// Revision 1.14  2008/12/05 17:55:29  taof
// hide info buttons for blank drug/problem rows
//
// Revision 1.13  2008/11/04 00:19:01  taof
// data migration to fix problem with framingham risk rule and bug fix on null dateList in fieldOps.js
//
// Revision 1.12  2008/10/28 20:04:32  taof
// implemented new rule: latest_from_form(fieldID, dateField)
//
// Revision 1.11  2008/10/24 21:34:31  wangye
// bug fixes for IE7 and performance tune-up
//
// Revision 1.10  2008/10/23 21:09:41  taof
// implement js functions for blood pressure rule supports
//
// Revision 1.9  2008/04/24 19:45:23  plynch
// Added a cache of base ID strings to actual field IDs, to speed up
// the run time of the rules.
//
// Revision 1.8  2008/04/15 20:34:20  plynch
// Changes to add has_list as a function for the FieldOps class.
//
// Revision 1.7  2008/02/11 23:04:53  plynch
// Addition of a rule for colonoscopy, support for links in reminder texts,
// and a fix for the medline plus link for the problems field.
//
// Revision 1.6  2008/02/07 20:16:26  plynch
// Changes for new rules.
//
// Revision 1.5  2008/02/05 17:58:25  plynch
// Changes for the addition of the mammogram rule.
//
// Revision 1.4  2008/02/01 17:09:39  plynch
// Changes to allow actions to be run even when the controlling rule does not
// have a value.  Also, the FieldOps.column_max function now supports the DT
// data type.
//
// Revision 1.3  2008/01/30 20:41:49  plynch
// Changes to support the framingham risk equation.
//
// Revision 1.2  2008/01/24 23:47:11  plynch
// Changes and fixes to the rules.  With these changes, the remaining PHR
// "dependencies" fields (in field_descriptions) have been migrated to "rules".
//
// Revision 1.1  2007/11/28 03:28:13  plynch
// Changes for the reminder messages.
//

/**
 *  A class for operations in rules on field values.
 *  Operations that can't be expressed in simple JavaScript should be defined
 *  here.  The user of the Form Builder will be able to make use of these
 *  functions.
 */
Def.FieldOps = {};
// Extend Def.FieldOps, not Def.FieldOps.prototype, because we are using
// Def.FieldOps more as a namespace than a class.
Object.extend(Def.FieldOps, {
  /**
   *  Returns the maximum value of a column of fields, and throws a
   *  Def.Rules.Exceptions.NoVal exception if there are no values.
   *  In the case of a date field,
   *  the time returned is the "epoch time" -- the number of milliseconds
   *  since 1970.
   * @param the id of a field in the column
   * @param dataType the HL7 data type of the column.  Supported types are 'NM'
   *  (numeric) and 'DT' (date).
   */
  column_max: function(fieldID, dataType) {

    // The base field ID of the field (shared by the field IDs of the other
    // fields in the column) should be the field_id minus its last
    // digit.
    var baseColID = Def.trimSuffix(fieldID);

    var fieldVals = Def.getFieldVals(baseColID);

    var rtn = Number.NEGATIVE_INFINITY;
    for (var i=0, max=fieldVals.length; i<max; ++i) {
      var next = Number.NaN;
      if (dataType =='NM')
        next = parseFloat(fieldVals[i]);
      else if (dataType == 'DT') {
        next = Def.DateUtils.getEpochTime(fieldVals[i]);
      }
      if (!isNaN(next) && rtn < next)
        rtn = next;
    }

    if (rtn == Number.NEGATIVE_INFINITY) {
      throw new Def.Rules.Exceptions.NoVal('No value for '+baseColID+
        '_* fields.');
    }
    return rtn;
  },


  /**
   *  Returns true if a column has no non-blank entries.
   * @param fieldID the id of a field in the column
   * @param dataType the HL7 data type of the column.  Not used.
   */
  column_blank: function(fieldID, dataType) {
    // The base field ID of the field (shared by the field IDs of the other
    // fields in the column) should be the field_id minus its last
    // suffix part.
    var baseColID = Def.trimSuffix(fieldID);

    var fieldVals = Def.getFieldVals(baseColID);
    return fieldVals.length==0;
  },


  /**
   *  Returns true if the values in the field column containing the field
   *  with the given ID matches the given string in a case-insensitive manner.
   *  Values in the column will be trimmed before comparison.
   * @param fieldID the id of a field in the column
   * @param dataType the data type of the field fieldID (not used)
   * @param strVal the string value to look for in the column.
   */
  column_contains: function(fieldID, dataType, strVal) {
    // The base field ID of the field (shared by the field IDs of the other
    // fields in the column) should be the field_id minus its last
    // suffix part.
    var baseColID = Def.trimSuffix(fieldID);

    var fieldVals = Def.getFieldVals(baseColID);
    var rtn = false;
    strVal = strVal.trim();
    for (var i=0, max = fieldVals.length; i<max && !rtn; ++i)
      rtn = (fieldVals[i]==strVal);
    return rtn;
  },


  /**
   *  Returns the latest value of a column of values, based on the date in the
   *  specified date column.  The parsed field value of the latest field that
   *  has a value will
   *  be returned.  If there is no value, an exception is thrown.
   * @param fieldID the id of a field in the column
   * @param dataType the data type of the field fieldID (not used)
   * @param dateField the target field name of the date column, which should be
   *  in the same table.  This routine expects there to be one date field for
   *  each fieldName field, with the same suffix (the same row).
   */
  latest_from_table: function(fieldID, dataType, dateField, conditionStr) {
    var cond = conditionStr ? Def.FieldOps.getQueryHash(conditionStr) : null;
    // Remove the last part suffix from the fieldID.  We want to find
    // all fields in the same column.
    fieldID = Def.trimSuffix(fieldID);
    // Now get the fields in the column.
    var idCache = Def.IDCache;
    var fieldIDParts = idCache.splitFullFieldID(fieldID);
    var fieldList =
    findFields(fieldIDParts[0], fieldIDParts[1], fieldIDParts[2]);

    var numFields = fieldList.length;
    var latestDate = Number.NEGATIVE_INFINITY;
    var latestValue = null;     
    for (var i=0; i<numFields; ++i) {
      var f = fieldList[i];
      fieldIDParts = idCache.splitFullFieldID(f.id);
      //var d = selectField(fieldIDParts[0], dateField, fieldIDParts[2], 0);
      var d = selectField(fieldIDParts[0], dateField + "_ET", fieldIDParts[2], 0);
      var match = cond ? this.matchCondition(cond, fieldIDParts): true;
      if (match && d) {
        //var dTime = Def.DateUtils.getEpochTime(Def.getFieldVal(d));
        var dTime = Def.getFieldVal(d);
        if (dTime > latestDate) {
          var fieldVal = parseFieldVal(f, true);
          // Don't count rows that don't have a value, even if they have a date
          if (fieldVal) {
            latestDate = dTime;
            latestValue = fieldVal;
          }
        }
      }
    } // for each fieldName field

    if (latestValue == null || latestValue == '') {
      // The user entered no data, so we can't return a value.  Throw an
      // exception, because rules depend on this function returning a value.
      throw 'No value in table for field '+fieldID+'*';
    }
    return latestValue;
  },


  /**
   * Returns the latest value from a column field based on the specified date
   * field and and query conditions
   *
   * @param fieldID
   * @param dataType
   * @param dateField
   * @param conditionStr
   **/
  latest_with_conditions: function(fieldID, dataType, dateField, conditionStr) {
    var rtn;
    try{
      rtn = Def.FieldOps.latest_from_table(fieldID, dataType,
        dateField, conditionStr);
    }
    catch(e){
      rtn = "";
    }
    return rtn;
  },


  /**
  * A row with field_a, field_b,  field_c and field_d
  * field_a value should be value_a or value_b
  * field_b value should be 1 or 2 or 3
  * field_c value should be some_value
  * field_d valud should be 12
  *
  * @param conditions
  * @param fieldIDParts 
  */
  matchCondition: function(conditions, fieldIDParts){
    // check each condition
    for( var f in conditions){
      // get the actual field value
      var s = selectField(fieldIDParts[0], f, fieldIDParts[2], 0);
      s = s && Def.getFieldVal(s).toLowerCase();
      // get the expected field value or field value list
      var cur = conditions[f];

      // match the field value to the conditions
      var rtn = true;
      if(s == null || s==undefined){
        rtn = false;
      }
      else if( typeof cur == "object" && cur.splice()){
        rtn = cur.indexOf(s) > -1;
      }
      else if(typeof cur == "string"){
        rtn = cur == s;
      }
      else{
        throw "unknow condition:" + cur.inspect();
      }

      // returns false if no matching
      if(!rtn) return rtn;
    }
    
    return true;
  },

  /**
   * Converts a string of query criteria into a hash mapping from field name(s)
   * to field value(s)
   * Examples:
   * input:
   * "field_a in ('value_a','value_b') AND field_b in (1,2,3) AND
   * field_c = 'some_value' AND field_d = 12 "
   * output:
   * {"field_a":['value-a', 'value_b'], "field_b": [1,2,3],
   * "field_c": 'some_value', "field_d": 12}
   *
   * @param conditionStr - a string with all query criteria
   */
  getQueryHash: function(conditionStr){
    var rtn={};
    var conditionList = conditionStr.split(" and ");
    for(var i=0, max=conditionList.length; i< max; i++){
      var cur = conditionList[i];
      if( cur.indexOf(" in ") > -1){
        var h = cur.strip().split(/\s*in\s*/);
        var temp = h[1].strip().replace(/(^\(\s*'?)|('?\s*\)$)/g,"");
        rtn[h[0]] = temp.strip().split(/'?\s*,\s*'?/);
      }
      else if(cur.indexOf("=") > -1){
        var h = cur.strip().split(/\s*=\s*/);
        rtn[h[0]] = h[1].replace(/'/g,"").strip();
      }
      else{
        throw "can not parse the unknown condition string: " + cur.inspect();
      }
    }
    return rtn;
  },


  /**
   *  Returns true if the given field has a prefetched autocompleter and
   *  the autocompleter has a non-empty list.
   * @param fieldID the id of the field whose list is being checked
   * @param dataType the HL7 data type of the field.  Not used.
   */
  has_list: function(fieldID, dataType) {
    // Be careful about using undefined values (which reported causes an error
    // in IE.
    var rtn = false;
    var field = $(fieldID);
    if (typeof field.autocomp != 'undefined') {
      var autocomp = field.autocomp;
      rtn = autocomp.options.array && autocomp.options.array.length;
    }
    return rtn;
  },

  /**
   * Find the latest value of a specified type of fields based on the date value
   * of the corresponding dateField.
   * The specified type of fields should have both the same suffix and target
   * field as the ones in the input fieldID.
   *
   * @param fieldID - the field ID.
   * @param dataType - the data type of the field fieldID (not used).
   * @param dateField - the target field name of a date field which has the
   * same suffix as the input fieldID.
   */
  latest_from_form: function(fieldID, dataType, dateField) {
    var latestValue = null;
    var idParts = Def.IDCache.splitFullFieldID(fieldID);
    var dateFieldList = findFields(idParts[0], dateField, '');
    if(dateFieldList.length > 0)
      latestValue=this.findLatestField(idParts[1], dateFieldList);
    if (latestValue == null || latestValue == '') {
      throw 'No value in form for field '+ fieldID +'*';
    }
    return latestValue;
  },


  /**
   * Find latest value of a specified type of fields based on the input
   * dateList.
   * The specified type of fields should have the same target field as the input
   * fieldName. The prefix and suffix should match to any element in the
   * dateList.
   *
   *
   * @param fieldName - target field of in the field ID.
   * @param dateList - list of date fields
   */
  findLatestField: function(fieldName, dateList){
    var latestDate = Number.NEGATIVE_INFINITY;
    var latestValue= null;
    var num = dateList.length;
    for(var i = 0; i< num; i++ ){
      var dateField = dateList[i];
      var dateFieldValue = Def.getFieldVal(dateList[i]);
      if(dateFieldValue){
        var dateValue = Def.DateUtils.getEpochTime(dateFieldValue);
        if(dateValue > latestDate){
          var idParts = Def.IDCache.splitFullFieldID(dateField.id);
          // find the matching field
          var selectedField = selectField(idParts[0],
            fieldName, idParts[2], 0);
          var fieldValue = parseFieldVal(selectedField, true);
          if(fieldValue){
            latestValue = fieldValue;
            latestDate = dateValue;
          }
        }
      }
    }
    return latestValue;
  },

  /**
   *  Check if the field is blank
   *
   *  @param fieldID - id of the input field
   */
  field_blank: function(fieldID){
    var rtn=  Def.getFieldVal($(fieldID)) === "";
    return rtn;
  },

  /**
   *  Checks if the field is hidden - display = 'none' or visibility = 'hidden'.
   *
   *  This uses one of 2 ways (depending on which one is available for the
   *  current platform) to find out the current style, which includes any
   *  CSS setting for the visibility.  Just checking the style.display and
   *  style.visibility properties don't work for styles set through CSS.
   *
   *  @param fieldID - id of the field or document element to be checked
   */
  is_hidden: function(fieldID){
    var fld = $(fieldID) ;
    if (fld.currentStyle) {
      var displayStyle = fld.currentStyle['display'] ;
      var visibilityStyle = fld.currentStyle['visibility'] ;
    }
    else {
      displayStyle = document.defaultView.getComputedStyle(
                                         fld,null).getPropertyValue('display') ;
      visibilityStyle = document.defaultView.getComputedStyle(
                                      fld,null).getPropertyValue('visibility') ;
    }
    return displayStyle == 'none' || visibilityStyle == 'hidden'
  },
  

  /**
   *  return field_length
   *
   *  @param fieldID - id of the input field
   */
  field_length: function(fieldID){
    return Def.getFieldVal($(fieldID)).length;
  },

  /**
   *  Returns a list of fields in the field column of a table by looking for
   *  input string value in that column. If candidate rows are provided, then
   *  we should shrink our searching space from the table into the candidate
   *  rows. If the strVal is blank, then skip looking for input string value.
   *
   * @param fieldID the id of a field in the column
   * @param dataType the data type of the field fieldID (not used)
   * @param strVal the string value to look for in the column.
   * @param candidateRows the list of candidateRows to look for the fields.
   */
  select_fields: function(fieldID, dataType, strVal, candidateRows){
    var fields = [];
    // When there is no candidateRows, find all the rows based on fieldID
    var idCache = Def.IDCache;
    if(candidateRows == null || candidateRows == undefined ){
      var idParts = idCache.splitFullFieldID(fieldID);
      fields = findFields(idParts[0],idParts[1],'');
    //fields = $$('input[id^='+ Def.trimSuffix(fieldID) + ']');
    }else{
      // Get the fields from specified field column and candidateRows
      var field_name = idCache.splitFullFieldID(fieldID)[1];
      var max = candidateRows.length;
      for(var i=0; i< max; ++i){
        var idparts= idCache.splitFullFieldID(candidateRows[i].id).clone();
        idparts[1] = field_name;
        fields.push($(idparts.join("")));
      }
    }

    // When string value input is blank, return the list of fields
    if(strVal == null || strVal.trim() == "") {
      return fields;
    }

    // Iterator through list of fields to look for string value
    var max = fields.length;
    for(var i=0; i< max; i++){
      var f = fields.shift();
      var fVal = Def.getFieldVal(f);
      if(f != null && fVal != null){
        var class_list = fVal.strip().toLowerCase().split(/\s*,\s*/);
        if(class_list.member(strVal.trim().toLowerCase())){
          fields.push(f);
        }
      }
    }
    return fields;
  },


  /**
   * Returns the value of a loinc field
   *
   * @param prefix - prefix of the trigger field
   * @param suffix - suffix of the trigger field
   * @param loincNum - the loinc number matches to the field for
   * retrieving value
   * @param valueField - target field of the loinc field for retrieving value
   **/
  getVal_loincFn: function(prefix, suffix, loincNum, valueField){
    var loincTargetField = valueField + ":" + loincNum;
    var field = findFields(prefix, loincTargetField, suffix)[0];
    return field && Def.getFieldVal(field);
  },

  /**
   * Merge string of column names and string of column values into one string
   * of query condition
   * @param prefix - not used here
   * @param suffix - not used here
   * @param str1 - a string of column target fields delimited by '|'
   * @param str2 - a string of column values delimited by '|'
   * Example, providing input strings "field_a|field_b|field_c" and
   * " ('a1','a3')  | '34' |'asdfsda'  ", it will return a new string like
   * "field_a|field_b|field_c";  var str2 = " ('a1','a3')  | '34' |'asdfsda'  ";
   **/
  column_conditions: function(prefix, suffix, str1, str2){
    var rtn = [];
    var tmp = "";
    var fieldList = str1.split("|");
    var condList = str2.split("|");
    for(var i = 0, max= fieldList.length; i< max; i++){
      var cur1 = fieldList[i].strip();
      var cur2 = condList[i].strip();
      tmp += cur1;
      tmp += cur2.match(/^\(.*\)$/) ? " in " : " = ";
      tmp += cur2;
      rtn.push(tmp);
      tmp = "";
    }
    return rtn.join(" and ");
  },


  /**
 * inputs are the whenDone and dueDate fields
 * outputs true if there is any duedate found
 *
 * and the duedate trigger fields shuold be attached to the trigger duedate field
 * @param prefix - prefix of the trigger field
 * @param suffix - suffix of the trigger field
 * @param str1 - a string of column target fields delimited by '|'
 * @param str2 - number of days away from the due date. It is used to setup
 *  reminder when it is close to due date
 **/
  is_test_due: function(prefix, suffix, str1, str2){
    // find all the duedate fields for building reminders
    // attach them onto the current duedate field (with input prefix and suffix)
    // return true if there is any duedate fields found or vice verse

    // Default: need to setup reminder within 5 days of the due date
    if(str2 == undefined) str2 = "5";

    var fieldList = str1.split("|");
    var dueDate = fieldList[0];
    var whenDone = fieldList[1];

    // find the all latest whenDone date fields
    var whenDoneFields = findFields(prefix, whenDone);
    var latestVal = Number.NEGATIVE_INFINITY;
    var latestFields = [];
    for(var i=0, max=whenDoneFields.length;i< max; i++){
      var cur = whenDoneFields[i];
      var curVal = Def.DateUtils.getEpochTime(Def.getFieldVal(cur));
      if(curVal || curVal >= latestVal){
        if(curVal > latestVal){
          latestVal = curVal;
          latestFields =[cur];
        }
        else{
          latestFields.push(cur);
        }
      }
    }

    // find all the active due date using latest whenDone fields
    var reminderDueDates = [];
    var reminderDueDate;
    var idParts;
    for(var i=0, max=latestFields.length;i< max; i++){
      reminderDueDate = this.findSibling(latestFields[i], dueDate);
      var dueDateVal= Def.getFieldVal(reminderDueDate);
      if(dueDateVal && dueDateVal.strip() != ""){
        var fn = Def.Rules.RuleFunctions;
        var diff = (fn.to_date(dueDateVal) - fn.dateOfToday())/fn.millisPerDay_;
        if(diff <= parseInt(str2) && diff >= 0)
          reminderDueDates.push(reminderDueDate);
      }
    }

    var rtn = reminderDueDates.length > 0;
    if(rtn){
      Def.tableDueDateFields_[dueDate] = reminderDueDates;
      Def.tableDueDateFields_[whenDone] = reminderDueDates;
    }

    return rtn;
  },

  /**
   * Finds sibling field in a table row
   * @param souceField - source field
   * @param targetField - the target sibling field
   **/
  findSibling: function(sourceField, targetField){
    var idParts = Def.IDCache.splitFullFieldID(sourceField.id).clone();
    idParts[1] = targetField;
    return $(idParts.join(""));
  }

//};
});
