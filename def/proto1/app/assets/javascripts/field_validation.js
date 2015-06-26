/**
 * field_validation.js -> The form field validation objects and methods together
 * with base validation methods
 */

Def.vrFuncs = Def.Validation.RequiredField.Functions;

/**
 * Run all the validations associated to the input field. All the associated
 * validations are defined in Def.fieldValidations_, e.g.
 *   fieldValidators={
 *     'sec_eamil': [['email'],['conformation','email']]
 *     ...
 *   }
 *
 * Parameters:
 * @param ele the input field
 */
Def.runValidations = function(ele) {
  // clear validation marks for non-required-field validators
  //Def.refreshErrorDisplay(ele, [true]);
  // clear invalid marks for this field if it is a required field. If it is on a
  // normal line, then clear marks for all the required fields on that same line
  //Def.vrFuncs.resetRequiredFieldValidationByField(ele);

  // run pre-defined validations and stop the process when an invalid field
  // was detected. Each validation supposed to update the following
  // properties :
  //    1) ele.invalid: a boolean value
  //    2) ele.errorMessage: an error message for the invalid field
  var target = Def.IDCache.splitFullFieldID(ele.id)[1];
  var validations = Def.fieldValidations_[target] || [];
  for(var i=0,max=validations.length;i<max;i++) {
    var validatorParts = validations[i].clone();
    var func_name = validatorParts.shift();
    var args = validatorParts;
    args.unshift(ele);
    // From a function name (e.g. date_range), we can get the actually
    // callable function (e.g. Def.Validation.checkDateRange) through the following
    // codes (e.g. date_range ==> date-range ==> Def.Validation.checkDateRange)
    var func_call_name=("check-" + func_name.replace("_","-")).camelize();
    var func_call = Def.Validation[func_call_name];
//    var s1 = new Date();
    func_call.apply(this, args);
//    Def.Logger.logMessage(["Validation >>>", " The '", func_name,
//      "' validation for '", target, "' field was ",
//      (ele.invalid ?  "FAILED" : "PASSED"), " in ", (new Date() - s1 ), " ms" ]);
    if (ele.invalid)
      break;
  }
}


/**
 * If a field was marked as 'invalid' field after validation and user tries to
 * leave the field without correcting the wrong value, system will re-focus the
 * invalid field to give user a chance for correction. If the user tries to
 * leave the field without making any correction, then the field will be cleared
 * and the invalid indicators plus error messages will be removed from the field
 *
 * @param field an input field
 * @param event the blur event
 */
Def.onBlurAfterValidation=function(ele, event) {
  // only process invalid condition
  if (ele.invalid) {
    var currentVal = Def.getFieldVal(ele);
    // The field has to be non required field which always be valid when its
    // value was empty
    if (!currentVal.blank()) {
      // determine if correction is needed or not
      var changed = !ele.previousValue || (ele.previousValue != currentVal);
      if (changed) {
        // Navigation system will move the focus to next DOM element after
        // this function call, therefore we need to set a delay in order to bring
        // the focus back to the invalid field
        setTimeout(function() {
          ele.focus();
        }, 100);
        ele.previousValue = currentVal;
      }
      else{
        // Clear the field and run the validation codes (included in the change
        // listeners) will pass all the non-required field validations and make
        // the field invalid again if it is a required field. Nevertheless, the
        // focus will be advanced to the next field.
        Def.setFieldVal(ele,'',true);
        ele.previousValue = null;
      }
    }
  }
}


/**
 * Refresh input field error displays including error messages and red outline
 * etc. Also sets both invalid and errorMessage properties for the field
 *
 * @param field the field to be validated
 * @param validationResult an array containing validation results where first
 *  element is a boolean indicating valid status of the field, the second element
 *  is the error message if the field is invalid
 * @param displayOptions a combination of jQuery tooltip widget options and the
 *  PHR specific options listed as follows:
 *  1. html: a flag indicating the need for html encoding
 *  2. alarm: a flag indicating whether we need to set off alarm
 *  3. highlight: a flag indicating whether we need to highlight the invalid
 *  field or not
 *  4. open: a flag indicating whether we need to keep the tooltip in the open
 *  status or not
 *
 *  As of now, there are two use cases for displayOptions parameter. One case is
 *  in function Def.vPasswordCheck of field_valdiation.js and another in method
 *  set_validator of form_helper.rb
 */
Def.refreshErrorDisplay= function(field, validationResult, displayOptions){
  field = $(field);
  var valid = validationResult[0];
  var errorMessage = validationResult[1];

  if(valid){
    if (Def.Validation.Base.invalidFields_[field.id])
      delete Def.Validation.Base.invalidFields_[field.id];
    field.errorMessage = null;
    field.invalid = false;
    field.removeClassName("invalid");
    removeTooltip(field);
  }
  else{
    if (Def.Validation.Base.invalidFields_[field.id] === undefined)
      Def.Validation.Base.invalidFields_[field.id] = true;
    field.errorMessage = errorMessage;
    field.invalid = true;

    var options =
      {"html": false, "alarm" : true, "highlight" : true, "open" : true};
    if (displayOptions)
      $J.extend(options, displayOptions);

    // consume and delete options which are not required by jQuery tooltip
    var html = options.html;
    delete options.html;
    if (html === true)
      errorMessage = htmlEncode(errorMessage);

    var alarm = options.alarm;
    delete options.alarm;
    if (alarm === true)
      Def.FieldAlarms.setOffAlarm(field);

    var highlight = options.highlight;
    delete options.highlight;
    if (highlight === true) {
      field.addClassName("invalid");
    }
    var open=options.open;
    delete options.open;
    var openOrClose = open === true ? "open" : "close";

    addTooltip(field, errorMessage, openOrClose, options);
  }
} // end of Def.refreshErrorDisplay


/**
 * Resets validations for both non-required and required fields
 */
Def.resetFieldValidations= function() {
  // reset non-required field validations
  var list = $H(Def.Validation.Base.invalidFields_).keys();
  for(var i= 0, max=list.length; i< max; i++) {
    var ele = $(list[i]);
    Def.refreshErrorDisplay(ele,[true],null);
  }

  // reset required field validations
  Def.vrFuncs.resetReqFldValidation();
}


/**
 * Adds field validation listeners into Def.fieldObservers_ based on the
 * field validation definitions from input parameter
 *
 * @param fieldValidations a hash from target field to field validation
 * specifications
 */
Def.loadFieldValidations = function(fieldValidations) {
  if (!fieldValidations)
    fieldValidations = Def.fieldValidations_;

  for (var targetField in fieldValidations) {
    var vrules = fieldValidations[targetField];
    var count = vrules.length;
    // If field validations are specified, then add the listener
    if (count > 0) {
      var fld_observers = Def.fieldObservers_[targetField],
          onChangeFunc = function(event){Def.runValidations(this);};
      if (!fld_observers) {
        Def.fieldObservers_[targetField] = {"change":[onChangeFunc]};
      }
      else if (!fld_observers["change"]) {
        fld_observers["change"] = [onChangeFunc];
      }
      else {
        fld_observers["change"].unshift(onChangeFunc);
      }
      // If the field validation fails, the onblur listener will force user to
      // go back to the invalid field. This isn't applicable to the following
      // two types of validations: required, xss.
      if (vrules.first()[0] === "xss") {
        count -=1;
      }
      if (vrules.last()[0] === "required") {
        count -=1;
      }
      if (count > 0) {
        var onBlurFunc = function(event) {Def.onBlurAfterValidation(this);};
        if (fld_observers["blur"]) {
          fld_observers["blur"].unshift(onBlurFunc);
        }
        else {
          fld_observers["blur"] = [onBlurFunc];
        }
      }
    }
  }
}


/**
 * Matches password format on keyup event and displays the matching result in a
 * tooltip message box
 *
 * @param field the password field
 * @param event the keyup event
 */
Def.passwordCheckOnkeyup = function(field, event) {
  var c = Def.Navigation.getKeyCode(event);
  // Skips tab and return keys
  if(c!=9 && c!=13) {
    Def.Validation.checkPassword(field, {
      "alarm":false,
      "highlight":false
    });
  }
}


/**
 * Remove one entry from the list of unique field values. This function is
 * useful for updating the list of unique field values if a unique field is in a
 * deleted record (e.g. the pseudonym field in a deleted profile record).
 *
 * @param targetField the unique field name. It is the second element of the
 * array returned by Def.IDCache.splitFullFieldID(field_id) function
 * @param value an outdated unique field value which needs to be removed
 */
Def.removeUniqueFieldValue =  function(targetField, value){
  var list = Def.Validation.Base.UniqueValuesByField_[targetField];
  //remove the value from the list
  var index = list.indexOf(value);
  if (index > -1) {
    list.splice(index, 1);
    // update the unique field values list accordingly
    Def.Validation.Base.UniqueValuesByField_[targetField]= list;
    Def.updateUniqueValueValidationData();
  }
}


/**
 * Includes all the field validation functions which dependent on form fields
 */
var fieldValidationFunctions={

  /**
  * Check to see if the current field has the exact same value as the specified
  * field. It is used for checking typos in email field and/or password field.
  *
  * @param confFld the current field
  * @param mainTarget the name of the specified field
  */
  checkConfirmation : function(confFld, mainTarget) {
    var idParts = Def.IDCache.splitFullFieldID(confFld.id);
    var mainFld = findFields(idParts[0], mainTarget, idParts[2])[0];
    var mainVal = Def.getFieldVal(mainFld) ;
    var confirmVal = Def.getFieldVal(confFld) ;

    var vResult = Def.Validation.Base.validateConfirmation(mainTarget, mainVal, confirmVal);
    Def.refreshErrorDisplay(confFld, vResult);
  },


  /**
   * Check the password to make sure it meets the system requirements.
   *
   * @param field the password field
   * @displayOptions the options for displaying error message of invalid password
   * field
   */
  checkPassword : function(field, displayOptions) {
    var password = Def.getFieldVal(field);
    var vResult = Def.Validation.Base.validatePassword(password);
    Def.refreshErrorDisplay(field, vResult, displayOptions);
  },


  /**
   *  Checks to see if a value falls within the minimum & maximum ranges
   *  specified for the field.  Either range is optional, although at least
   *  one should be specified (or why are we bothering?).
   *
   *  If the value is out of range, an error is displayed by the
   *  Def.refreshErrorDisplay function.  The error states that the value MUST
   *  conform to the range, which is why this is the "absolute" range
   *  checker.
   *
   *  Currently this assumes that the field's field type is
   *  a date type.
   *  this allows for relative date ranges with the format T+-D,M,Y
   *
   * @param field the field whose value is to be validated
   * @param fieldName Name of the field whose value is to be validated
   * @param min the field's minimum range value
   * @param max the field's maximum range value
   * @param min_msg the error message when min range check was failed
   * @param max_msg the error message when max range check was failed
   */
  checkDateRange : function(field, fieldName, min, max, min_msg, max_msg) {

    var str = Def.getFieldVal(field);
    // If the field is blank, skip range checking
    var vResult = [true, null];
    if (str.length > 0) {
      var re = new RegExp('([0-9a-zA-Z]*)[ \\-_.,/]*([0-9a-zA-Z]*)'+
        '[ .\\_,/-]*([0-9a-zA-Z]*)')
      var regexLen = re.exec(str).clean("").length;
      if (regexLen == 4) {
        var dt = Date.parseDayString(str) ;
      }
      else if (regexLen == 3) {
        dt = Date.parseMonthString(str) ;
      }
      else {
        dt = Date.parse(str) ;
      }
      if (dt == null)
        throw("Found unknown date format in date field " + field.id + ".");

      var specificError = '' ;
      if (min.length > 0) {
        min = Date.parse(min) ;
        if (min != null && dt.compareTo(min) < 0) {
          if (min_msg != '') {
            specificError = min_msg ;
          }
          else {
            specificError = Def.Validation.Base.getMinDateErrMsg(min,fieldName) ;
            if (specificError == '') {
              specificError = 'The value specified must not be before ' +
              min.toLocaleFormat("%A, %B, %e, %Y") ;
            }
          }
        }
      }
      if (specificError.length == 0 && max.length > 0) {
        max = Date.parse(max) ;
        if (max != null && dt.compareTo(max) > 0) {
          if (max_msg != '') {
            specificError = max_msg ;
          }
          else {
            specificError = Def.Validation.Base.getMaxDateErrMsg(max,fieldName) ;
            if (specificError == '') {
              specificError = 'The value specified cannot be after ' +
              max.toLocaleFormat("%A, %B, %e, %Y") ;
            }
          }
        }
      }
      if ( specificError.length > 0)
        vResult = [false, specificError];
    }
    Def.refreshErrorDisplay(field, vResult);

  }, // end Def.Validation.checkDateRange


  /**
   *  Uses a regular expression to validate a field.  If the field is valid,
   *  it "normalizes" the content using a format string.  If the field is not
   *  valid, an error message is displayed.
   *
   *  @param field the field to be validated
   *  @param code The code of a regex validator record which includes the following
   *  properties:
   *  1.  regex - a regular expression the field must match
   *  2.  Description - the field's label
   *  3.  normalized_format - the normalized format of the field.  This should
   *   contain strings like #{$1}, and those strings will be replaced by
   *   $1, $2, etc. as set by the regular expression object during matching.
   *  4.  error_message - the error message to display if the field is not valid
   */
  checkRegex : function(field, code) {
    var regOpt = Def.REGEX_[code];
    var str = Def.getFieldVal(field);
    var vResult = Def.Validation.Base.validateRegex(str, regOpt.regex,
      regOpt.error_message, regOpt.normalized_format);
    // assign the normalized value to the field if the input format is correct
    if (vResult[0])
      Def.setFieldVal(field, vResult[2]);
    Def.refreshErrorDisplay(field, vResult);
  },


  /**
  * This function checks, validates and displays the date in appropriate echoback
  * format. This also populates the epoch time as well as hl7 date fields with
  * equivalent date values.
  *
  *  @param dateField date Field where the value is entered and the output is set
  *  NO - removed param hiddenField Field with EpochTime value
  *  NO - removed param hiddenHL7Field field with HL7 date value
  *  @param dateFormat date format with optional field in []. ex. CCYY/[MM]/[DD]
  *  @param et_point epoch time calculation point.
  *  field.
  **/
  checkDate : function(dateField, dateFormat, et_point) {
    var dateEchoFmtD = "yyyy MMM dd", dateEchoFmtM = "yyyy MMM", dateEchoFmtY = "yyyy";
    // make errorMessage
    //var errorMessage = Def.Validation.Base.getDateFieldErrMsg(dateFormat);
    var errorMessage = Def.Validation.Base.getDateFieldErrMsgByField(dateField);

    Def.DateField.makeDateFormat(dateField, dateFormat,
      dateEchoFmtD,
      dateEchoFmtM,
      dateEchoFmtY,
      '',//displayName
      errorMessage,
      et_point);
  },


  /**
   * Validates and formats after interpretation of entered timeField value. Set
   * the reformatted value back in. Also update the epoch date and hl7 date fields
   * accordingly if they exist.
   *
   * @param timeField the time field
   *
  **/
  checkTime : function(timeField) {
    // Now parse the input value and populate the field based on formats
    // selected above. Also populate HL7 as well as EpochTime fields
    var valid = true;
    // no validation required if the time field is empty.
    if (Def.getFieldVal(timeField) != '') {
      var str = Def.Validation.Base.parseNoColonTimeFormat(Def.getFieldVal(timeField));
      if (str != "") {
        // added "2010/01/01" to make sure the time string 'str' won't be wronly
        // treated as a date string, e.g. Date.parse('12')
        var time = Date.parse("2010/01/01 " + str);
        if (time) {
          Def.setFieldVal(timeField, time.toString("h:mm tt"))  ;
          if (timeField.getAttribute("timeonly") != "true") {
            // update Epoch time and HL7 date.
            var idParts = Def.IDCache.splitFullFieldID(timeField.id) ;
            var fieldval = idParts[1].replace('_time','') ;
            var dateField = $(idParts[0] + fieldval + idParts[2]);
            var epochField = $(idParts[0] + fieldval + '_ET' + idParts[2]);
            var hl7Field = $(idParts[0] + fieldval + '_HL7' + idParts[2]);
            var dateVal=Def.getFieldVal(dateField);
            var epochVal =Def.getFieldVal(epochField);
            if (dateVal != '' && epochVal != '') {
              var epochTimeVal = Date.getTimeEpochTime(epochVal, time);
              Def.setFieldVal(epochField, epochTimeVal);
              var hl7TimeVal = Date.getHl7Date(dateVal)+''+time.toString("HHmm");
              Def.setFieldVal(hl7Field, hl7TimeVal) ;
            }
          }
        }
        else {
          valid = false;
        }
      }
      else {
        // Empty string means unparsable. -Ajay 08/27/2013
        valid = false;
      }

    }

    var msg = valid ? null : Def.Validation.Base.ErrorMessages_.time;
    Def.refreshErrorDisplay(timeField, [valid, msg]);
  }, // end of checkTime


  /**
   * Perform the required field validation for both non-normal-line and normal-line
   * fields
   *
   * @params inputField the input field
   * @params fieldType defined the type of required fields where
   *   1) "common" stands for the input field is required
   *   2) "normalline" means the input field is on a same line with its siblings.
   *      The line should contain at least one required field and those required
   *      field(s) must not be empty if any of its sibling field(s) was filled.
   */
  checkRequired : function(inputField, fieldType) {
    switch (fieldType) {
      case "common":
        Def.vrFuncs.validateCommonField(inputField);
        break;
      case "normalLine":
        Def.vrFuncs.validateNormalLine(inputField);
        break;
      default:
        throw("Unknown validation type for required field: " + fieldType + ".");
        break;
    }
  },


  /**
   * Validate and sanitize the input as needed to fend off potential cross site
   * scripting attacks
   *
   * @param inputField the input field
   */
  checkXss : function(inputField) {
    Def.Validation.Xss.validateFieldValue(inputField);
    inputField.invalid = false;
  },


  /**
   * Returns true if the value of the input element does not exist in the
   * unique value list(see Def.Validation.Base.UniqueValuesByField_.). Else returns false and
   * show an error message
   * @param ele - input field
   * @param fieldToValuesMap - a hash map from name of unique fields to lists of
   * stored field values of those fields
   * @param idToValueMap - a hash map from IDs of unique value field to the
   * values of those fields when the form was initially loaded or refreshed (
   * e.g. last saved)
   **/
  checkUniqueness : function(ele, fieldToValuesMap, idToValueMap) {
    if (fieldToValuesMap == undefined)
      fieldToValuesMap = Def.Validation.Base.UniqueValuesByField_;

    if (idToValueMap == undefined)
      idToValueMap = Def.Validation.Base.DefaultValueByField_;

    var valid = true, errMsg = null;

    var input_value = Def.getFieldVal(ele);
    if (input_value && input_value != "") {
      var target_field = Def.IDCache.splitFullFieldID(ele.id)[1]
      var uniqList = fieldToValuesMap[target_field];
      var exceptionalValue = idToValueMap && idToValueMap[ele.id];
      if (exceptionalValue != input_value) {
        if (uniqList && uniqList.indexOf(input_value) > -1)
          valid = false;
        errMsg = Def.Validation.Base.ErrorMessages_.uniqueness;
      }
    }

    Def.refreshErrorDisplay(ele, [valid, errMsg]);
    return valid;
  }  // end checkUniqueness

};
Object.extend(Def.Validation, fieldValidationFunctions);


/**
 * General validation functions, variables. It was created in order to
 * distinguish it from the form field specific validations defined in
 * Def.Validation
 */
Def.Validation.Base = {

  /**
   * Keep track of all the invalid non-requried fields
   * It should be moved into the valiation.js file during the next validation code
   * refactoring (see ticket#4089) -Frank
   */
  invalidFields_ : {},


  /**
   * A hash containing default error messages used by the validation system
   */
  ErrorMessages_ :{
    uniqueness: "Please enter a unique value.",
    time: 'Cannot interpret time.'
  },


  /**
  * Check to see if the two separate values are the same and return the valid
  * status and error message in an array
  *
  * @param fieldName type of the fields to be checked
  * @param masterVal the value entered in the master field
  * @param confirmationVal the value entered in the confirmation field
  */
  validateConfirmation : function(fieldName, masterVal,
    confirmationVal) {
    //var mainTargetDisplayName = Def.dataFieldlabelNames_[mainTarget][0][0];
    //var msg = "Entered " + mainTargetDisplayName.toLowerCase() + " does not match.";
    var msg = Def.Validation.Base.getConfirmationErrMsg(fieldName);
    masterVal = masterVal.strip();
    confirmationVal = confirmationVal.strip();

    var valid = ( confirmationVal == "" || masterVal == confirmationVal );
    return [valid, msg];
  },


  /**
  * Check the input password value and returns an password validation status
  * and error message in an array
  *
  * @param password the password need to be validated
  */
  validatePassword: function(password) {

    var valid=true;
    var validConditions = [];
    if (!password.blank()) {
      var list = [/[A-Z]/g, /[a-z]/g, /[0-9]/g, /[^a-zA-Z0-9]/g];
      for (var i=0, max = list.length; i<max; i++) {
        if (list[i].test(password)) {
          validConditions.push( ["capital","letter","number","special"][i]);
        }
      }

      if ( password.length >= 8 && password.length <= 32 ) {
        valid = validConditions.length >=3;
        validConditions.push("length");
      }
      else{
        valid = false;
      }
    }

    return [valid, Def.Validation.Base.getPasswordErrorMessage(validConditions)];
  },


  /**
   *  Match the string against the regular expression. If they matched, then
   *  normalizes the string with the fieldFormat if provided. Returns the validation
   *  status, error message and normalized string in an array
   *
   *  @param str a string
   *  @param re a regular expression
   *  @param errorMsg an error message used when the input string does not match
   *  regular expression
   *  @param fieldFormat a format for normalizing the matched string
   */
  validateRegex: function(str, re, errorMsg, fieldFormat) {

    var regexResults = matchesRegex(str, re);

    var valid = !(str != "" && regexResults == null);
    if (valid) {
      errorMsg = null;
      // adjust the field value based on the format
      if (regexResults != null && fieldFormat) {
        for (var i=1; i<regexResults.length; ++i) {
          var subVal = regexResults[i]==undefined ? '' : regexResults[i];
          var placeHolder = '#{$'+i+'}';
          fieldFormat = fieldFormat.replace(placeHolder, subVal);
        }
        str = fieldFormat;
      }
    }
    return [valid, errorMsg, str];
  }, // validateRegex


  /**
   * Return the error message for invalid confirmation field
   *
   * @param displayName the display name of the confirmation field
   **/
  getConfirmationErrMsg: function(displayName) {
    return "These " + displayName + " fields do not match. Try again?";
  },


  /**
  * Returns an error message in html format which has all the valid formats being
  * highlighted with green color and invalid formats being highlighted with red
  * color
  *
  * @param validConditions list of requirements which has been satisfied
  */
  getPasswordErrorMessage: function(validConditions) {

    var vRules ={
      'length':"8 characters",
      'letter':"one lowercase letter",
      'capital':"one capital letter",
      'number':"one number",
      'special':"one special character"
    };

    var vMsgs={};
    for(var vtype in vRules) {
      var vCSS = validConditions.indexOf(vtype) > -1 ? "valid_pwd" : "invalid_pwd";
      vMsgs[vtype] = '<li id="'+vtype+'" class="'+vCSS+'">At least <strong>'+
      vRules[vtype]+'</strong></li>';
    }

    var msg = '<div id="pswd_info">'+
    '<h4>Your password must meet the length requirement</h4>'+
    '<ul>'+   vMsgs["length"] +   '</ul>'+
    '<h4>and three of the following requirements:</h4>'+
    '<ul>'+  vMsgs["letter"] + vMsgs["capital"] + vMsgs["number"] +
    vMsgs["special"] + '</ul></div>';

    return msg;
  },


  /**
   *  Generate appropriate error message based on the  minimum relative date.
   *  This would work for relative date validation which is the only type of date
   *  range validation in PHR right now. Beed to be be used in right context, not
   *  for all types of date ranges.
   *
   *  @param min  Minimum date of the date range.
   *  @param fieldName Name/Label of the date field
   *  @return errMsg appropriate eror message returned
   */
  getMinDateErrMsg: function(min,fieldName) {

    var errMsg = '' ;
    var oneDay=1000*60*60*24 ;
    var today = new Date() ;
    var diffSec = today.getTime()-min.getTime() ;
    //Calculate difference btw the two dates, and convert to days
    var dayDiff = Math.floor(diffSec/(oneDay)) ;
    var weekDiff =Math.floor(diffSec/(7*oneDay)) ;
    var yearDiff =Math.floor(diffSec/(365.25*oneDay)) ;
    // Use floor because ceil gives a extra year because of fraction year.

    if (dayDiff == 0) {
      errMsg = ' earlier than today is considered invalid.'
    }
    else if (dayDiff < 7) {
      errMsg = ' earlier than '+dayDiff.toString() +' days is considered invalid.'
    }
    else if (dayDiff < 365) {
      errMsg = ' earlier than '+weekDiff.toString() +' weeks is considered invalid.'
    }
    else{
      errMsg = ' earlier than '+yearDiff+' years is considered invalid.'
    }

    return fieldName + errMsg ;
  },


  /**
   *  Generate appropriate error message based on the  maximum relative date.
   *  This would work for relative date validation which is the only type of date
   *  range validation in PHR right now. Beed to be be used in right context, not
   *  for all types of date ranges.
   *
   *  @param max  Maximum date of the date range.
   *  @param fieldName Name/Label of the date field
   *  @return errMsg appropriate eror message returned
   */
  getMaxDateErrMsg: function(max,fieldName) {

    var errMsg = '' ;
    var one_day=1000*60*60*24 ;
    var today = new Date() ;
    //Calculate difference btw the two dates, and convert to days
    var dayDiff = Math.ceil((max.getTime()-today.getTime())/(one_day))
    var weekDiff =dayDiff/7 ;
    var yearDiff = dayDiff/365 ;

    if (dayDiff == 0) {
      errMsg = ' in future considered invalid.'
    }
    else if (dayDiff < 7) {
      errMsg = ' after '+dayDiff.toString() +' days considered invalid.'
    }
    else if (dayDiff < 365) {
      errMsg = ' after '+weekDiff.toString() +' weeks considered invalid.'
    }
    else{
      errMsg = ' after '+yearDiff+' years considered invalid.'
    }
    return fieldName+errMsg ;
  },


  /**
   * Returns the error message for an invalid date field
   *
   * @param dateFormat the format required for the date field
   **/
  getDateFieldErrMsg: function(dateFormat) {
    // convert characters inside [ ] into lowercases
    var reg = /\[.*\]/;
    dateFormat = dateFormat.replace(reg, function(x) {
      return x.toLowerCase();
    });
    // remove [ ] from the dateFormat
    reg = /[\[\]]/g;
    dateFormat = dateFormat.replace(reg, '');
    // html coding
    dateFormat = htmlEncode(dateFormat);
    return "Enter a valid date, preferably in the " +  dateFormat + " format.";
  },


  /**
   * Returns the error message for an invalid date field
   *
   * @param dateField the invalid date field
   **/
  getDateFieldErrMsgByField: function(dateField) {
    return "Invalid date. " + dateField.title;
  },


    /**
   * Parses a non-colon time input and returns a correctly formatted time string
   * if the input has a valid time format. If it has a colon, the input is returned as
   * it is. If the input is unparsable, returns empty string.
   *
   * This is intended to be used by checkTime function. See checkTime for its usage.
   *
   * @params timeString a time string
   *
   */
  parseNoColonTimeFormat: function(timeString) {
      // Bypass parsing if it contains colon. -Ajay 08/27/2013
    if (timeString != '' && !timeString.match(/:/)) {
      var tRegx = /^(\d{1,4})\s*(AM|PM|A|P)?$/ig;
      var timeRx = tRegx.exec(timeString) ;
      var validHrMin = false;
      var timeMin = "";
      if (timeRx && timeRx[1]) {
        var timeStr = timeRx[1] ;
        if(timeStr.length <= 2) {
          //var timeStr = timeRx[1] ;
          var timeHrs = timeStr;
          timeMin = "00";
          if ( parseInt(timeHrs, 10) < 25) {
            validHrMin = true;
          }
        }
        else if(timeStr.length <= 4) {
          timeHrs = timeStr.slice(0,-2) ;
          timeMin = timeStr.slice(-2) ;
          if(parseInt(timeHrs, 10) < 25) {
            if (parseInt(timeMin, 10) < 60) {
              validHrMin= true;
            }
          }
        }
      }

      if (validHrMin) {
        timeString = timeHrs + ":" + timeMin ;
        if (timeRx[2] && timeRx[2].length > 0) {
          timeString += timeRx[2];
        }
      }
      else {
        // Return empty string if unparsable.
        return '';
      }
    }
    return timeString;
  }
}
