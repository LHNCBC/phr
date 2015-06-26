// License:  This file should be considered to be under the terms of some
// "non-viral" open source license, which we will specify soon.  Basically,
// you can use the code as long as you give NLM credit.

var Def = {  // Namespace for DEF classes
  /**
   *  The element containing the form HTML (i.e. not the split list area.)
   */
  formArea_: null ,

  /**
   * Flag letting the client side know whether or not we're in test mode.
   * Set in show.rhtml.erb; currently used to block confirmCancel popup
   * displayed when a form is closed when we're testing, since it's not clear
   * how to get to that to answer it.
   */
  inTestMode_: false ,

  /**
   * Current access level, relevant when a user is accessing one profile,
   * which is how most, but not all, of the forms are used.  (The PHR Home
   * page shows multiple profiles, so this is not applicable on that page,
   * and we could add other pages where it would not be applicable).
   * Set in show.rhtml.erb
   */
   accessLevel_: null ,

   /**
    * Access level constants; set in show.rhtml.erb
    * NO_PROFILE_ACTIVE is used when there is not a specific profile that is
    * active.  This is provided to distinguish between a case where the
    * access level has not been set (= null) and where it has.
    */
   NO_PROFILE_ACTIVE: null,
   OWNER_ACCESS: null,
   READ_WRITE_ACCESS: null,
   READ_ONLY_ACCESS: null,

  /**
   * Name of the current form.  Set in show.rhtml.erb; used by various stuff
   */
  formName_: null ,

  /**
   * The data structure that we use to store various data related to the form
   * that is not actually part of the form.  For example, the group_header_list
   * used by the form builder forms is stored in this.
   */
  data_: {} ,

  // This tells javascript that browser close is not causing the unload event.
  reload_: false ,

  // This tells if user clicked the browser.
  clicked_: false,

  documentKeyEventWrapper_: null ,

  /**
   * The hash that contains the event observer functions that need to be set up
   * for each input field as it is either loaded onto the form or created on
   * the fly, such as fields created when a new line is added to a horizontal
   * fields table.  Contents are as follows:
   *
   * The key for each fieldObservers_ element is the target field name.
   *
   * The value for each fieldObservers_ element is an event hash.
   *
   * The key for each event hash element is the event type (load, click, etc.)
   *
   * The value for each event hash element is an array of function calls.  Each
   * element in the array should be a function call that should be executed to
   * set up a function to be called for an event.  Specifically, it should
   * follow the format
   *
   *   function(event){function_name(function_parameters);}
   *
   * where function_name is the name of the function to be set up and
   * function_parameters are the parameters to be passed, which may include
   * the event object and may also include the form field object ('this').
   *
   * The exception to this is functions to be run on load events.  Those
   * should be specified as
   *
   *   function(theField){function_name(function_parameters);}
   *
   * The difference for those is because those functions will actually be run
   * during the event observer setup process - since it is carried out on
   * page load.
   */
  fieldObservers_: {} ,

  /**
   * The tag names allowed by partialHtmlEncode with htmlParseLevel=1, as
   * a regular expression.
   */
  LEVEL1_TAGS_RE: /&lt;(\/?)(br|center|i|b|u|p)&gt;/ig,


  /**
   * The prefix for field IDs.
   */
  FIELD_ID_PREFIX: 'fe_',

  /**
   * List of active due dates which need to be reminded
   **/
  tableDueDateFields_: {},

  /**
   * Reference to the last popup window displayed.
   */
  lastPopupWindow_: null ,

  /**
   * List of currently open popups.
   */
  CURRENT_POPUPS_ARR: [],

  /**
   * logout URL
   */
  LOGOUT_URL: '/accounts/logout' ,

  /**
   * "Save" button(s) with changed labels.  These are the buttons whose labels
   * are changed by the setWaitState function, and that will need to be reset
   * by the endWaitState function.
   */
  CURRENT_SAVE_BUTTONS: [] ,

  /**
   * A confirmation dialog that is displayed when the user clicks the Close
   * button on a form that has pending changes.  The dialog is built the
   * first time it is displayed, and then is available for subsequent
   * display as needed.
   */
  confirmCloseDialog_: null ,

  /**
   * The message to be displayed in the confirmCloseDialog_
   */
  CONFIRM_CLOSE_MSG: "You have unsaved changes on this page.<BR>" +
                     "Should those changes be saved before the page is closed?",

  /**
   * Flag indicating whether or not a logout is being programmatically forced,
   * e.g., for a data overflow error
   */
  forceLogout_: false ,

  /**
   * Flag indicating whether or not the current form requires the PHR-specific
   * navigation setup to be delayed until after the form is fully built.
   * Defined in the forms table.
   */
  delay_navsetup_: false ,


  /**
   * List of IDs of form fields with attached message manager objects. The idShown_ values of those message managers
   * need to be updated after finishing setting up the data model
   */
  messageFieldIds_: [],

  /**
   * find an element's screen position left-top point, margin/border/padding
   * included.
   * @param obj a dom element
   */
  findScreenPosition: function(obj) {
    var curleft = curtop = 0;
    while (obj != null ) {
      curleft += parseInt(obj.offsetLeft);
      curtop += parseInt(obj.offsetTop);
      obj = obj.offsetParent;
    }
    return [curleft,curtop];
  },


  /**
   * find an element's position relative to an ancestor left-top point,
   * margin/border/padding included.
   * @param obj a dom element
   * @param ancID an ancestor's id
   */
  findRelativePosition : function(obj, ancID) {
    var curleft = curtop = 0;
    while (obj != null && obj.id != ancID ) {
      curleft += parseInt(obj.offsetLeft);
      curtop += parseInt(obj.offsetTop);
      obj = obj.offsetParent;
    }
    return [curleft,curtop];
  },


  /**
   *get a style property of an element
   *@param ele a dom element
   *@param prop a style property
   */
  getStyle : function(ele, prop) {
    //If the property exists in style[], then it's been set recently and
    //is current.
    if (ele.style[prop]) {
      return ele.style[prop];
    }
    //Otherwise, try to use IE's method
    else if (ele.currentStyle) {
      return ele.currentStyle[prop];
    }
    //Otherwise, try W3C's method
    else if (document.defaultView && document.defaultView.getComputedStyle) {
      //It uses the traditional 'text-align' style of rule writing
      //instead of 'text'Align'
      prop = prop.replace(/([A-Z])/g,"-$1");
      prop = prop.toLowerCase();

      //Get the style object and get the value of the property
      var s = document.defaultView.getComputedStyle(ele,"");
      return s && s.getPropertyValue(prop);

    }
    //Otherwise, we don't know
    else {
      return null;
    }
  },


  /**
   *  Returns the trimmed value of a field (which might not be an input element)
   *  as a string. If the value is same as tooltip, then return empty string as
   *  tooltip is not real value.
   * @param field the DOM field element
   */
  getFieldVal: function(field) {
    var fieldVal;
    // if value == tooltip
    if((field.getAttribute("novalue") === "true")
        && (field.value === field.tipValue)){
       return '';
    }
    if (field.value === undefined)
      fieldVal = htmlDecode(field.innerHTML.trim());
    else
      fieldVal = field.value.trim();
    return fieldVal;
  },


  /**
   *  Sets a value of a field (which might not be an input element).
   *  This does NOT make any changes if the field already contains the
   *  new value.
   *
   * @param field the DOM field element.
   * @param val the new value; We assume it should only be a string, a number,
   *  a boolean value or null. By evaluating with typeof() function, we got
   *  the following list of strings indicating their types: "string", "number",
   *  "boolean" and "object";
   * @param runChangeEventObservers (default true) whether the change
   *  event observers for the field (which includes the update for the data
   *  model and the running of rules) should be run after the value is set.
   */
  setFieldVal: function(field, val, runChangeEventObservers) {

    if (runChangeEventObservers === undefined)
      runChangeEventObservers = true ;

    var changed = false;
    var dataType = typeof val;
    var fieldVal = Def.getFieldVal(field);
    if (field.value === undefined) {
      // When we compare field value with another value, we are actually comparing
      // them in string format. Therefore, we need to make sure the variable var
      // is a string before comparing it with the field value which is also a
      // string returned by Def.getFieldVal
      switch(dataType){
        case "string":
          // Assume a DOM element.
          // Only encode strings.
          var htmlParseLevel = field.getAttribute('htmlParseLevel');
          val = Def.partialHtmlEncode(val, htmlParseLevel);
          break;
        // When val is null, convert it to empty string so that we can compare
        // it with the existing field value in the type of string
        case "object":
          val = "";
          break;
        case "boolean":
          val = val + "";
          break;
        default:
        // do nothing with numbers
      }

      if (fieldVal != val) {
        field.innerHTML = val;
        changed = true ;
      }
    }
    else {
       switch(dataType){
        // When val is null, convert it to empty string so that we can compare
        // it with the existing field value in the type of string
        case "object":
          val = "";
          break;
        case "boolean":
          val = val + "";
          break;
        default:
        // do nothing with numbers and srtrings
      }

      if (fieldVal != val) {
        field.value = val;
        changed = true ;
      }
      if (field.tipValue !== undefined)
        Def.onBlurTip(field) ;
    }
    if (runChangeEventObservers && changed) {
      Def.FieldEvents.runChangeEventObservers(field);
    }
  }, // end setFieldVal


  /**
   *  Sets the values of several fields, and then after the values are all
   *  set, runs the fields' change event observers (which includes the update
   *  for the data model and the running of rules).
   * @param fields an array of DOM field elements
   * @param vals an array of new values for the elements in "fields"
   */
  setFieldVals: function(fields, vals) {
    for (var i=0, max=vals.length; i<max; ++i) {
      var f = fields[i]
      this.setFieldVal(f, vals[i], false) ;
      // Update the data model, before we run the other change event observers.
      Def.DataModel.updateModelForField(f);
    }
    // Now run the change event observers.  Unfortunately, this
    // will update the data model again.
    Def.FieldEvents.runChangeEventObservers(fields);
  },


  /**
   *  Redirects to a search result page from ClinicalTrials.gov.  Only
   *  studies that are recruiting are returned.
   * @param condition the name of a medical condition
   * @param state the two-letter abbreviation of a U.S. state.
   * @param age the clinical trials age group code.  (0 = birth to 17, 1=18 to
   *  65, and 2 = over 65).
   */
  clinTrialsSearch: function(condition, state, age) {
    var url = 'http://clinicaltrials.gov/search?cond='+
      encodeURIComponent(condition) +'&recr=Open&age=' +age;
    if (state.trim() != '' && state.trim != 'All States')
       url += '&state1=NA%3AUS%3A'+state;
    document.location = url;
  },


  /**
   *  Populates the fields of a form in another window using rules and values
   *  from this one.  In the future, the functionality of this method may be
   *  expanded by adding additional parameters for specifying what data should
   *  be transferred (e.g. field to field, which we don't currently need).
   * @param otherFormWindow the window reference for the window containing the
   *  form that will receive the data.
   * @param ruleToField a map from names of rules on this form to target field
   *  names of fields on the other form.  The field will get the rule value.
   *  If the field is a code field (target field name ending in "_C") and
   *  there is an associated non-code field that has an autocompleter, an
   *  attempt will be made to set that field's value to the list value that
   *  goes with the code.
   * @param fieldToList a map from target field names of fields on this form to
   *  target field names of fields on the other form that have autocompleters.
   *  For these fields, the data for instances of the fields (which might be
   *  in a repeating line table) will be collected and given to the
   *  autocompleters on the other form as their lists.  If there is just one
   *  data value, the field value on the other form will also be set.  Also,
   *  if the field on this form has an associated code field, the data for those
   *  codes values will also be given to the autocompleters as the codes for
   *  the list values.
   */
  fillInForm: function(otherFormWindow, ruleToField, fieldToList) {
    var idCache = Def.IDCache;
    for (var ruleName in ruleToField) {
      try {
        var ruleVal = Def.Rules.Cache.getRuleVal(ruleName);
        var targetFieldName = ruleToField[ruleName];
        var field = otherFormWindow.selectField(Def.FIELD_ID_PREFIX,
          targetFieldName, '', 0);
        if (field) {
          var setValue = false;
          if (targetFieldName.search(/_C$/) > 1) {
            // See if there is another field for which this is the code field.
            var nonCodeTFName =
              targetFieldName.substring(0, targetFieldName.length-2);
            // Look for the field with the same suffix.
            var idParts = idCache.splitFullFieldID(field.id);
            var nonCodeFieldID = make_form_field_id(nonCodeTFName, idParts[2]);
            var nonCodeField = otherFormWindow.$(nonCodeFieldID);
            if (nonCodeField && nonCodeField.autocomp) {
              // We have found an autocompleter for which this we have the code.
              nonCodeField.autocomp.selectByCode(ruleVal);
              setValue = true;
            }
          }

          if (!setValue) {
            // Then the value was probably not for a autocompleter's code field.
            // Just set the value.
            Def.setFieldVal(field, ruleVal);
          }
        }
      }
      catch (e) {} // continue to next rule
    }

    for (var thisWindowFieldName in fieldToList) {
      var otherWindowFieldName = fieldToList[thisWindowFieldName];
      var otherWindowField = otherFormWindow.selectField(
        Def.FIELD_ID_PREFIX, otherWindowFieldName, '', 0);
      if (otherWindowField && otherWindowField.autocomp &&
          otherWindowField.autocomp.setListAndField) {
        var fieldData = Def.getFieldValsAndCodes(thisWindowFieldName);
        otherWindowField.autocomp.setListAndField(fieldData[0], fieldData[1]);
      }
    }
  },


  /**
   *  Returns the (DOM) code field for the given field, or null if there isn't
   *  one.
   * @param field the (DOM) field for which the code field is needed
   */
  getFieldsCodeField: function(field) {
    var idParts = Def.IDCache.splitFullFieldID(field.id);
    return $(idParts[0] + idParts[1] + '_C' + idParts[2]);
  },


  /**
   *  Returns the DOM element for the score field corresponding to the given
   *  field, or null if there isn't one.
   * @param field the (DOM) field for which the score field is needed
   */
  getFieldsScoreField: function(field) {
    var idCache = Def.IDCache;
    var idParts = idCache.splitFullFieldID(field.id);
    var idPartsTG = idCache.splitFullFieldID(idParts[1]).clone();
    idPartsTG[1] = "test_score";
    return $(idParts[0] + idPartsTG.join("") + idParts[2]);
  },


  /**
   *  Returns an array of two elements, the first of which is an array
   *  of field values for the given target field name, and the second
   *  is an array of corresponding code values if there is a code field
   *  for the specified field.  If there is no code field , the
   *  return value is null.  Blank values are left out of the first array,
   *  and code fields for blank field values are also skipped.
   * @param fieldName the target field name of the field for which values
   *  are needed.
   */
  getFieldValsAndCodes: function(fieldName) {
    // The code here is similar to Def.getFieldVals, but a little different
    // because of the need to find corresponding codes.
    var fields = findFields(Def.FIELD_ID_PREFIX, fieldName, '');
    var fieldVals = new Array();
    var codeVals = null;
    var idCache = Def.IDCache;

    for (var i=0, max=fields.length; i<max; ++i) {
      var codeField;
      var idParts;
      if (i==0) {
        // See if we have code fields
        idParts = idCache.splitFullFieldID(fields[0].id);
        codeField = $(make_form_field_id(idParts[1]+'_C', idParts[2]));
         if (codeField) {
          codeVals = new Array();
        }
      }

      var val = Def.getFieldVal(fields[i]);
      if (val != null) {
        val = val.trim();
        if (val != "") {
          fieldVals.push(val);
          if (codeVals) {
            if (i != 0) {  // if ==0, we already have codeField
              idParts = idCache.splitFullFieldID(fields[i].id);
              codeField = $(make_form_field_id(idParts[1]+'_C', idParts[2]));
            }
            codeVals.push(Def.getFieldVal(codeField));
          }
        }
      }
    }
    return [fieldVals, codeVals];
  },

  focusInlineEdit: function(ele) {
    if (ele.init_value == undefined) {
      ele.init_value = ele.value;
    }
  },

  enterInlineEdit: function(ele) {
    ele.removeAttribute('readonly');
    ele.removeClassName('readonly_field');
  },

  leaveInlineEdit: function(ele) {
    var init_value = ele.init_value;
    var new_value = ele.value;
    if (init_value == new_value) {
      ele.setAttribute('readonly','readonly');
      ele.addClassName('readonly_field');
    }
  },


  /*
   * Runs the onblur event function for tooltip fields.
   * Adds attribute noValue which tells if the value is tooltip or real value
   * @param ele Element with tooltip
   */
  onBlurTip: function(ele) {
    if (ele.hasClassName("invalid") || ele.tipValue == null) {
      return ;
    }
    if (ele.value.trim() == "") {
	    ele.value	= ele.tipValue;
	    ele.style.color	= "gray";
      ele.setAttribute("noValue", true);
    }
    else if(ele.value.trim() == ele.tipValue.trim()) {
      ele.style.color	= "gray" ;
      ele.setAttribute("noValue", true);
    }
    else {
      ele.style.color	= "" ;
      ele.setAttribute("noValue", false);
    }
  }, // onBlurTip

  /*
   * Sets up the onfocus event function for tooltip fields.
   * if tooltip displayed, clear the value
   * @param ele Element with tooltip
   */
  onFocusTip: function(ele) {
    if (ele.hasClassName("invalid") && (ele.value != ele.tipValue )) {
      return ;
    }
    if (ele.value == ele.tipValue ) {
      ele.value	= "";
      ele.style.color	= "";
      if (ele.autocomp != null) {
        ele.autocomp.uneditedValue = "" ;
      }
    }
  }, // onFocusTip


/*
 * Sets up the element style/attributes on initial load of the page.
 * Esesntially, tooltip value is greyed out. Actual value is default color.
 * Also sets noValue attribute appropriately.
 * @param ele Element with tooltip
 **/
  onTipSetup: function(ele) {

  /*
   * Sets up the element style/attributes on initial load of the page.
   * Esesntially, tooltip value is greyed out. Actual value is default color.
   * Also sets noValue attribute appropriately.
   */
    ele.style.opacity = "1.0" ;
    ele.tipValue = ele.getAttribute("tipValue")

    if (ele.value == '' || (ele.value	== ele.tipValue)) {
      ele.value	= ele.tipValue;
      ele.style.color	= "gray";
      ele.setAttribute("noValue", true);
     }
     else {
       ele.style.color	= "" ;
       ele.setAttribute("noValue", false);
     }
  }, // onTipSetup


  /**
   * Sets up the element style/attributes on initial load of the page or
   * field.  Sets the value of the tooltip and runs the onBlurTip function.
   * @param ele Element with tooltip
   * @param newValue new value for the tooltip
   */
  resetTip: function(ele, newValue) {
    // otherwise, it errs out in some cases
    if (ele.tipValue != null)  {
      ele.tipValue = newValue ;
      //ele.value = "" ;
      Def.onBlurTip(ele) ;
    }
  } , // resetTip


  /**
   * Rebuilds the hash map from IDs of unique value field to the original values
   * of those fields. The field values are taken at the time when the form was
   * intially loaded. The map is stored in variable Def.uniqueFieldIdToValueMap_
   *
   * Use CASE: When editing an existing phr profile record, we need to make
   * sure we can enter the original value into the field without getting an
   * unique value validation error on that field
   **/
  updateUniqueValueValidationData: function(){
    var rtn = {};
    var uniqueFieldsHash = Def.Validation.Base.UniqueValuesByField_;

    var tableData = Def.DataModel.data_table_;
    for(var tableName in tableData){
      var records = tableData[tableName];
      var uniqueValueFields = [];
      for(var i=0,max=records.length; i<max;i++){
        // builds the unique value field list
        if (uniqueValueFields.length == 0){
          for(var column in records[0]) {
            if (uniqueFieldsHash[column])
              uniqueValueFields.push(column);
          }
        }

        var record = records[i];
        var position = i+1;
        for(var j=0, jmax=uniqueValueFields.length; j<jmax;j++) {
          column = uniqueValueFields[j];
          var field = Def.DataModel.getFormField(tableName, column, position);
          rtn[field.id] = record[column];
        }
      }
    }
    Def.Validation.Base.DefaultValueByField_ = rtn;
  },


  /**
   * Removes (recursively) all child nodes from an element - if the element
   * has any children.  Does NOT remove the 'fromNode' passed in.
   *
   * @param fromNode the element whose children are to be removed
   **/
   removeAllChildNodes: function(fromNode) {
     for (var c = fromNode.childNodes.length - 1; c >= 0; c--) {
       Def.removeAllChildNodes(fromNode.childNodes[c]) ;
       fromNode.removeChild(fromNode.childNodes[c]) ;
     }
   }, // removeAllChildNodes


   /**
    *  Displays a notice in the "notification" div on the form.  If there
    *  isn't a notification div, it uses an alert box.
    * @param msg the message to be shown
    */
   showNotice: function(msg) {
     var noteDiv = $('notification');
     if (!noteDiv)
       window.alert(msg);
     else {
       noteDiv.style.display = ''; // Might start out as 'none' on page load
       // The cool fade in/out effect on the message box does not work for
       // IE.  It fades in and then POOF! it's gone.
       if (BrowserDetect.IE) {
         noteDiv.innerText = msg;
         noteDiv.style.opacity = 1 ;
       }
       else {
         noteDiv.textContent = msg;
         noteDiv.style.opacity = 0;
         new Effect.Opacity(noteDiv, {to: 1.0,  from: 0.0});
       }
     }
   },


   /**
    *  Hides the notices in the notfication div.
    * @param removeSpace true if the the space the notice contains should be
    *  removed (default false).
    */
   hideNotice: function(removeSpace) {
     var noteDiv = $('notification');
     if (noteDiv.style.opacity !== '0' && noteDiv.style.display != 'none') {
       // Don't generally set display to 'none', because that makes the rest of the page
       // jump upwards, and if there is a list active it gets detached (visually)
       // from its field.
       if (noteDiv) {
         if (removeSpace)
           noteDiv.style.display = 'none';
         else {
           if (BrowserDetect.IE)
             noteDiv.style.opacity = 0 ;
           else
             new Effect.Opacity(noteDiv, {from: 1.0,  to: 0.0});
         }
       }
     }
   },


   /**
    *  Returns true if the notice area is hidden.
    */
   noticeIsHidden: function () {
     var noteDiv = $('notification');
     return noteDiv.style.display == 'none' || noteDiv.style.opacity === '0';
   },


   /**
    *  Displays a notice in the "page_errors" div on the form.  If there
    *  isn't a page_errors div, it uses an alert box.
    * @param msg the message to be shown
    * @param html true if we should allow HTML in the message (default false)
    */
   showError: function(msg, html) {
     if (html == undefined)
       html = false;
     var noteDiv = $('page_errors');
     if (!noteDiv)
       window.alert(msg);
     else {
       if (html)
         noteDiv.innerHTML = msg;
       else {
         if (BrowserDetect.IE)
           noteDiv.innerText = msg;
         else
           noteDiv.textContent = msg;
       }
       noteDiv.style.display = '';
       noteDiv.scrollIntoView();
       // If the top nav bar is present, we need to scroll up enough so
       // the message is below that.
       if ($('fe_form_header_0_expcol')) {
         window.document.documentElement.scrollTop -=
           $('fe_form_header_0_expcol').offsetHeight;
       }
     }
   },


  /**
   * This function adds a div of the same size as a captcha. Essentially, it
   * prevents page/section resize when page unloads.
   */
  addBackground: function(){

    recaptcha_div = $('recaptcha_area') ;
    w = recaptcha_div.offsetWidth ;
    h = recaptcha_div.offsetHeight ;
    if ($('back_ground') == null){
      var backG= document.createElement('div');
      backG.id = 'back_ground'
      var atts= {
        padding: '0',
        zIndex: '-1',
        display: 'block',
        position: 'relative',
        width: w+'px',
        height: h+'px',
        top: '-152px',
        left: '0px'
      }

      for(var p in atts){
        backG.style[p]= atts[p];
      }

      rec_parent = recaptcha_div.parentNode.parentNode ;
      rec_parent.appendChild(backG);
      rec_parent.style.height = 152+'px'
    }
  },


  /**
   *  Reports a JavaScript error to the server.
   * @param e the exception that was caught
   */
  reportError: function(e) {
    var stackLines = printStackTrace({'e': e, 'guess': true});
    if (e.name && e.message)
      stackLines.unshift(e.name + ': ' + e.message);
    var exString = stackLines.join("\n")
    Def.Logger.logMessage([exString]);
    Def.Logger.logException(e); // TBD- should we do this too?  instead?
    // Log the message on the server
    var params = {message: exString};
    if (window._token) // Add the authencity_token for CSRF security check
      params.authenticity_token = window._token || '';
    new Ajax.Request('/error/new', {parameters: params});
  }
};


/**
 *  Adds a function to the String class for trimming white space.  This was
 *  copied from:  http://www.codingforums.com/showthread.php?p=178098
 */
String.prototype.trim=function(){
  return this.replace(/^\s*|\s*$/g,'');
};


/**
 *  Returns the form field ID for the given target field name.  This also
 *  exists in form_helper.rb.  Please use this function to make an id, rather
 *  than doing it yourself, so that if we change our naming conventions we
 *  have fewer areas of the code to change.
 *
 *  And if you change this, please make the corresponding changes in the
 *  form_helper.rb file.
 *
 * @param field_name the target field name
 * @param suffix an optional suffix to append to the ID (may be null)
 *
 * @returns the form field ID
 */
function make_form_field_id(field_name, suffix) {
  var rtn = Def.FIELD_ID_PREFIX + field_name;
  if (suffix != null)
    rtn += suffix;
  return rtn;
}


/**
 *  Returns the form field name for the given target field name.  This also
 *  exists in form_helper.rb.  Please use this function to make a name, rather
 *  than doing it yourself, so that if we change our naming conventions we
 *  have fewer areas of the code to change.
 *
 *  And if you change this, please make the corresponding changes in the
 *  form_helper.rb file.
 *
 * @param field_name the target field name
 * @param suffix an optional suffix to append to the ID (may be null)
 *
 * @returns the form field name
 */
function make_form_field_name(field_name, suffix) {
  var rtn = Def.FIELD_ID_PREFIX + field_name;
  if (suffix != null)
    rtn += suffix;
  return rtn;
}



/**
 *  Returns the base field ID of a field ID, by which is meant the field ID
 *  with the ending underscore and number parts left off.
 */
function getBaseFieldID(fieldID) {
  var re = RegExp('(_\\d+)*$');
  return fieldID.replace(re, '');
}


/**
 *  Returns the result of regexp.exec() if the string matches, and null if it
 *  does not.
 * @param str the string to match
 * @param re the regular expression, also given as a string.
 * @return the result of regexp.exec(), which is an array consisted of:
 *       the index of the start of the match,
 *       the orginal string,
 *       the matched subpatterns (possibly multiple elements)
 */
function matchesRegex(str, re) {
  var regex = new RegExp(re);
  var rtn = regex.exec(str);
  return rtn;
}


/**
 * Destroy the jQuery tooltip instance for the input field
 *
 * @param field the input field
 */
function removeTooltip(field) {
  if (hasTooltip(field)) {
    $J(field).tooltip("destroy");
  }

}


/**
 * Return true if the field has a tooltip and vice versa
 *
 * @param field the input field
 */
function hasTooltip(field) {
  return $J(field).is(":data('ui-tooltip')");
}


/**
 * Add a tooltip for the input field based on the input parameters
 *
 * @param field the input field
 * @param message the tooltip message
 * @param openOrClose a string (either "open" or "close" ) indicating the state
 * of the tooltip
 * @param options a hash of jQuery tooltip options (see jQuery ui tooltip API
 * documentation for details)
 *
 */
function addTooltip(field, message, openOrClose, options){
  if (message.blank()){
    throw "ErrorMessageIsEmpty: "+
    "Please specify tooltip error message for field "+ field.id;
  }
  if (openOrClose == null || openOrClose == undefined) {
    openOrClose = "open";
  }
  else if (["open", "close"].indexOf(openOrClose) == -1) {
    throw "MissingTooltipStatus: Please specify if the tooltip needes to be "+
      "opened or closed";
  }
  // jq_options is the tooltip options
  var jq_options = {};
  if (options != null && options != undefined) {
    jq_options = options;
  }
  // Update the tooltip content
  $J.extend(jq_options,{content: message, items: "#"+field.id})
  // If there is no tooltip, setup tooltip position etc.
  if (!hasTooltip(field))
    $J.extend(jq_options, {
      position: {
        my: "left bottom-20",
        at: "left top",
        collision: "flipfit",
        using: function( position, feedback ) {
          $J( this ).css( position );
          $J( "<div>" )
          .addClass( "arrow" )
          .addClass( feedback.vertical )
          .addClass( feedback.horizontal )
          .appendTo( this );
        }
      }});

    // The default tooltip position is on top of the field. If the field has class "tooltip_on_bottom", then we need to
    // re-position the tooltip accordingly
    if (field.hasClassName('tooltip_on_bottom')) {
        jq_options.position.my = "left top+20";
        jq_options.position.at = "left bottom";
    }

  $J(field).tooltip(jq_options)
  // By default we should open the tooltip immediately. But for invalid required
  // field, we want the tooltip remain hidden until user mouseover to the invalid
  // field
  if (openOrClose == "open")
    $J(field).tooltip(openOrClose);
}


/**
 * Return true if the tooltip for the input field is visible. Mainly used for
 * testing purpose
 *
 * @param field the input field
 */
function hasVisibleTooltip(field){
  if (typeof field === "string"){
    field = $(field);
  }
  return $J(field).is(":data('ui-tooltip-open')");
}


/**
 * Returns the content of the tooltip for the input field. Mainly used for
 * testing purpose
 *
 * @param field the input field
 */
function getTooltipContent(field){
  if (typeof field === "string"){
    field = $(field);
  }
  return $J(field).tooltip("option").content;
}


/**
 * Sets display characteristics for input field to reflect no specified error
 * found on the input field. For example, an phone number field could be a
 * required field and it's phone number format also needs to be validated. This
 * function only ensures that any error display (including the tooltip message)
 * related to the specified type of error will be cleared.
 *
 * @param field the input field
 * @param errTxt the message for the specified error (It can be in HTML, see
 * comments of displayError function for details).
 */
function displayCorrect( field, errTxt ) {
//  if (Def.Validation.tooltip.remove(field,errTxt)){
//    field.style.border = '';
//    setInvalidIndicators(field, false);
//  }
  setInvalidIndicators(field, false);
  // remove the tooltip of invalid error message for this field if exists
  Def.Validation.tooltip.remove(field,errTxt);
}


/**
 *  Sets display characteristics for input field to reflect an error in input value.
 * @param field the field Element DOM object
 * @param errTxt a string to describe the error. Newline characters will get
 *  translated to <br> tags.  It used to be just a text string, not HTML. Now it
 *  can be HTML if doHtmlEncode parameter value is false
 * @param doHtmlEncode a flag indicating whether we need to do html encoding or
 * not. By default, we always do html encoding.
 */
function displayError(field, errTxt, doHtmlEncode,width) {
  field = $(field);
  setInvalidIndicators(field, true);
  Def.FieldAlarms.setOffAlarm(field);
  //show an tooltip for invalid error message
  Def.Validation.tooltip.add(errTxt, field, doHtmlEncode,width);
}


/**
 * This method was taken from an article on firing javascript events.  See
 * http://jehiah.cz/archive/firing-javascript-events-properly.  This is used
 * by the onSelect function in calendar-setup.js to fire an onchange event.
 * Using obj.onchange() quit working when the event call was moved from being
 * defined within the form field to an event observer.
 *
 * @param element the form element on which the event is to be called
 * @param event the name of the event, such as 'change'
 *
 * @return - For IE, true if event fired successfully; false if it was
 *  cancelled.  For Firefox + others, false if it was not cancelled; true
 *  if it was.
 *
 *  Obviously this is a rather ambiguous return, but there are no current
 *  instances in our code where the return is being used - no use case.
 *  If a use case comes up, perhaps the person implementing the user case
 *  could change the return values that were copied from the site referenced
 *  above.
*/
function appFireEvent(element, event) {
  var evt ;
  var rtn;
  // dispatch for IE
  // IE9 deprecated event methods (e.g createEventObject, fireEvent etc) and
  // started to support the same methods as for Firefox etc. (see
  // http://msdn.microsoft.com/en-us/library/ff986080%28v=VS.85%29.aspx)
  if (document.createEventObject && !BrowserDetect.IE9 && !BrowserDetect.IE10){
    evt = document.createEventObject();
    // returns true if the event fired successfully; false if it was cancelled
    rtn = element.fireEvent('on'+event,evt) ;
  }
  // dispatch for firefox + others
  else {
    if (event == 'click') {
      evt = document.createEvent("MouseEvents");
      evt.initMouseEvent('click', true, true, window,
                          0, 0, 0, 0, 0, false, false, false, false, 0, null);
      rtn = !element.dispatchEvent(evt);
    }
    else {
      evt = document.createEvent("HTMLEvents");
      evt.initEvent(event, true, true) ; // event type, bubbling, cancellable
      // returns true if no other handler called preventDefault
      rtn = !element.dispatchEvent(evt);
    }
  }

  return rtn;
} // appFireEvent


/**
 * Adds or removes two invalid indicators for a field. The first indicator is a
 * field attribute called "invalid". Another indicator is a class name called
 * "invalid" which is used to outline the invalid field.
 * @param field - the input field
 * @param isInvalid - true when the input field is invalid and vice versa
 */
function setInvalidIndicators(field, isInvalid){
  if(isInvalid){
    if(field.getAttribute("invalid") != "true"){
      field.setAttribute("invalid", true);
      field.addClassName("invalid");
    }
  }
  else{
    if(field.getAttribute("invalid") == "true"){
      field.setAttribute("invalid", false);
      field.removeClassName("invalid");
    }
  }
}


/**
 *  Checks to see if a value falls within the minimum & maximum ranges
 *  specified for the field.  Either range is optional, although at least
 *  one should be specified (or why are we bothering?).
 *
 *  If the value is out of range, an error is displayed by the
 *  displayError function.  The error states that the value MUST
 *  conform to the range, which is why this is the "absolute" range
 *  checker.
 *
 *  Currently this assumes that the field's field type is either numeric
 *  or a date type.  If range checking is expanded to other types, this
 *  needs to be updated.
 *
 * @param field the field whose value is to be validated
 * @param fieldName Name of the field whose value is to be validated
 * @param min the field's minimum range value
 * @param max the field's maximum range value
 */
function absoluteRangeCheck(field, fieldName, min, max) {

  if (Def.getFieldVal(field).trim().length > 0) {
    var min_comp_str, max_comp_str;
    var str = field.value;
    if (field.field_type == 'NM - numeric' ||
      field.field_type == 'NM+ - numeric with units') {
      str = parseFloat(str) ;
      min_comp_str = 'be no less than ' ;
      max_comp_str = 'be no greater than ' ;
    }
    else {
      min_comp_str = 'not be before ' ;
      max_comp_str = 'not be after ' ;
    }

    if ((str != null && str.length > 0) &&
      ((min != null && min > str) || (max != null && max < str))) {

      var errText = 'The value specified must ' ;
      if (min == null && max != null)
        errText += max_comp_str + str.toString() ;
      else if (min != null && max == null)
        errText += min_comp_str + str.toString() ;
      else // assume a date
        errText += ' be between ' + min.toString() + ' and ' + max.toString() ;

      displayError(field, errText) ;
      setTimeout(function() {field.focus();}, 1);
    }
  } // end if the field has a value
} // absoluteRangeCheck





/**
 * Sets the input field in error mode with error message display. It then
 * refocuses the cursor back to the field.
 *  @param field input field
 *  @param fieldName Name/Label of the date field
 *  @param errorMsg appropriate eror message to display
 *  @param width optional field width of tooltip box
 **/
function setError(field, fieldName, errorMsg, width) {
  displayError( field , errorMsg,false,width );
  setTimeout(function() {
    field.focus();
  }, 100);
}

/**
 *  Returns an HTML-encoded version of the given string.  Quotation marks,
 *  apostrophes, and ampersands are escaped.  (For things going into attribute
 *  values, this is better than prototype's escapeHTML, because it encodes
 *  double and single quote characters.)
 */
function htmlEncode(str) {
  str = str.replace(/&/g, '&amp;');
  str = str.replace(/\"/g, '&quot;');
  str = str.replace(/</g, '&lt;');
  str = str.replace(/>/g, '&gt;');
  return str.replace(/\'/g, '&#39;');
}


/**
 *  Does the opposite of HTML-decode.
 */
function htmlDecode(str) {
  str = str.replace(/&#39;/g, '\'');
  str = str.replace(/&quot;/g, '\"');
  str = str.replace(/&lt;/g, '<');
  str = str.replace(/&gt;/g, '>');
  return str.replace(/&amp;/g, '&');
}


/**
 *  Returns a partially encoded HTML string, according to the htmlParseLevel
 *  parameter.  This lets some HTML tags get through unencoded.
 * @param str the string to be encoded
 * @param htmlParseLevel Controls what gets encoded.  A value of "0" (a string,
 *  because the current use case makes that convenient) means everything is
 *  encoded (equivalent to calling htmlEncode()), and a value "1" means
 *  a few tags are allowed for formatting purposes.  If this parameter is null
 *  or undefined, a value of "0" will be taken as the default.
 */
Def.partialHtmlEncode = function(str, htmlParseLevel) {
  var rtn = htmlEncode(str);
  if (htmlParseLevel == "1") {
    // Decode certain tags
    rtn = rtn.replace(this.LEVEL1_TAGS_RE, '<$1$2>');
  }
  return rtn;
}


/**
 *  Add a new method for shaking a field.  This is based on code copied from the
 *  Scriptaculous web site, but for some reason isn't yet in the library.
 */
Effect.Shake = function(element,valx) {
  element.shakeCanceled = false;
  element = $(element);
  valx = $(valx);
  var nvalx = $(valx * (-1));
  var oldStyle = {
    top: element.getStyle('top'),
    left: element.getStyle('left')
  };

  function reset() { // resets the element to its original state
    element.undoPositioned();
    element.setStyle(oldStyle);
    valx = 0;
    nvalx = 0;
  }

  // Set up the parameters for the move effects, in reverse order so we
  // can chain them.
  var moveArgs4 = {
    x: nvalx,
    y: 0,
    duration: 0.05,
    afterFinishInternal: function(effect) {
      reset();
    }
  }

  var moveArgs3 = {
    x:  (valx*2),
    y: 0,
    duration: 0.1,
    afterFinishInternal: function(effect) {
      if (!element.canceled) {
        new Effect.Move(effect.element, moveArgs4);
      }
      else {
        reset();
      }
    }
  }

  var moveArgs2 = {
    x: (nvalx * 2),
    y: 0,
    duration: 0.1,
    afterFinishInternal: function(effect) {
      if (!element.canceled) {
        new Effect.Move(effect.element, moveArgs3);
      }
      else {
        reset();
      }
    }
  }

  var moveArgs1 = {
    x: (valx),
    y: 0,
    duration: 0.05,
    afterFinishInternal: function(effect) {
      if (!element.canceled) {
        new Effect.Move(effect.element, moveArgs2);
      }
      else {
        reset();
      }
    }
  }

  if (!element.shakeCanceled) {
    return new Effect.Move(element, moveArgs1);
  }
}


/**
 * Function that determines whether or not to show a notice explaining
 * the "required field" icon.  Should be invoked on page load.
 */
function setUpReqInfoNotice() {
  var iCount = 0 ;
  for (var i = 0, il=document.images.length; i < il; i++) {
    if (document.images[i].className.indexOf('requiredImg') >= 0) {
      if (++iCount > 1) {
        i = document.images.length;
        infoNoticeElements = $$('[class="reqNotice"]');
        for (var n = 0, nl =infoNoticeElements.size(); n < nl; n++) {
          if (Def.formName_ != 'phr_home' ||
              infoNoticeElements[n].id != 'reqInfo') {
            infoNoticeElements[n].style.display = "block" ;
          }
        }
      }
    }
  }
}


/**
 * lastStar indicates which form input object last received focus
 */
var lastStar ;

/**
 * This function will hide any current search/questions list IF
 * the field currently registering its focus is not the same that
 * previously had focus.  This is used to keep a list displayed
 * until the user moves to another input field.  If the user has
 * a list displayed and clicks on a non-input area of the form,
 * or requests help on a field, the list remains displayed.
 */
function hideTheList(obj) {
  if (lastStar != null && lastStar != obj) {
    searchDiv = document.getElementById('searchResults') ;
    searchDiv.style.visibility = 'hidden' ;
  }
  lastStar = obj;
}

/**
 * This function expands (makes visible) or collapses (makes invisible)
 * one section.
 * It is to be invoked by expColAll() and expColSection().
 *
 * @param section the section element to be expanded or collapsed
 * @param action should be 'expand' or 'collapse'
 */
function switchExpCol(section, action) {

  var buttonDiv = $(section.id+'_button');
  var image = buttonDiv.down('img');

  // to hide the group
  if (action == 'collapse' ) {
    var newText = 'Show';
    var newStatus = 'group_collapsed';
    var oldStatus = 'group_expanded';
    var newImageClass = 'sprite_icons-expcol_group_collapsed';
    var oldImageClass = 'sprite_icons-expcol_group_expanded';
    section.style.display = "none";
  }
  // to show the group
  else {
    newText = 'Hide';
    newStatus = 'group_expanded';
    oldStatus = 'group_collapsed';
    newImageClass = 'sprite_icons-expcol_group_expanded';
    oldImageClass = 'sprite_icons-expcol_group_collapsed';
    section.style.display = "block";
  }
  // Set the class on both the collapsed div and the containing div (for the
  // sake of the print style sheet).
  image.removeClassName(oldImageClass);
  buttonDiv.removeClassName(oldStatus);
  Element.removeClassName(section.parentNode, oldStatus);
  image.addClassName(newImageClass);
  buttonDiv.addClassName(newStatus);
  Element.addClassName(section.parentNode, newStatus);
  buttonDiv.firstChild.textContent = newText ;
}  //switchExpCol


// get the actual height/width of the current base font size.
// this creates a div temporarily to get height/width before
// removing it.
function emSize(pa){
  pa= pa || document.body;
  var who= document.createElement('div');
  var atts= {
    fontSize:'1em',
    padding:'0',
    position:'absolute',
    lineHeight:'1',
    visibility:'hidden'
  };
  for(var p in atts){
    who.style[p]= atts[p];
  }
  who.appendChild(document.createTextNode('M'));
  pa.appendChild(who);
  var fs= [who.offsetWidth,who.offsetHeight];
  pa.removeChild(who);
  return fs;
}


/**
 * This function expands (makes visible) or collapses (makes invisible)
 * a section, and updates the arrow that controls it as appropriate
 * to the action.
 * @param sectionId the section element to be expanded or collapsed
 */
function expColSection(sectionId) {
  // Get the expand/collapse sections within this section
  var section = $(sectionId);
  var sections = section.select('.expand_collapse');
  //var sections = section.getElementsByClassName('expand_collapse');
  sections.push(section);

  var buttonDiv = $(section.id+'_button');
  var action = 'expand';
  if (buttonDiv.hasClassName('group_expanded')) {
    action = 'collapse';
  }

  for (var i=0, max=sections.length; i<max; ++i) {
    switchExpCol(sections[i], action)
  }
} // expColSection


/**
 * This function expands (makes visible) or collapses (makes invisible)
 * all sections.
 * @param action should be 'expand' or 'collapse'
 * @param rootNode the node to be expanded
 */
function expColAll(action, rootNode) {
  if (!rootNode)
    rootNode = document;
  // Get the expand/collapse sections.
  var sections = rootNode.getElementsByClassName('expand_collapse');
  for (var i=0, max=sections.length; i<max; ++i) {
    switchExpCol(sections[i], action);
  }
} //expColAll



/**
 *  Returns a column of values from a table (as an Array), given the column's
 *  base field name (i.e., the HTML id attribute of the first field of the first
 *  row.  Fields in the column are assumed to have IDs in the form baseID_n,
 *  where n is a row number greater than 1, or to have the base ID itself.
 *  Values that are empty or just whitespace are not returned.  Values are
 *  returned with whitespace trimmed off the edges.
 */
function getColumnVals(baseFieldID) {
  var rtn = new Array();
  var field = $(baseFieldID);

  // The code for repeating fields is currently in transition from having
  // the first field's ID be baseFieldID, to having the first field's ID
  // be baseFieldID + '_1'.  For now, we need to support both.
  if (field==undefined || field==null) {
    field = $(baseFieldID+'_1');
  }

  var row = 1;
  while (field != null) {
    var val = field.value;
    if (val != null) {
      val = val.trim();
      if (val != "")
        rtn.push(val);
    }
    ++row;
    field = $(baseFieldID + '_' +row);
  }
  return rtn;
}



/**
 *  DEPRECATED-- This method will go away after js_expressions.js is removed.
 *  See rules.js' Def.getFieldVals instead.
 *  Returns an array of values of fields whose ID begins with the given base
 *  ID, regardless of how many nesting level postfixes the field's ID is away
 *  from the base ID.  For example, if you pass in someField_1 you will get
 *  values for otherField_1_0_0_1, otherField_1_0_0_2, and also (if it exists,
 *  though it probably would not in our system) otherField_1_0_0_2_0_1.
 *  Effectively, this is the same as getColumnVals, except that you don't have
 *  to know as much of the base ID.  Note though that if the base ID is too
 *  short, you might get more than one set of column vals (e.g. if the field is
 *  in a repeated table that is nested within a repeated table.  Values
 *  are returned with whitespace trimmed off the edges, and empty values
 *  are left out.
 */
function getFieldVals(baseFieldID) {
  var fields = $$('input[id^='+baseFieldID+']');
  var rtn = new Array();
  for (var i=0, max=fields.length; i<max; ++i) {
    var val = fields[i].value;
    if (val != null) {
      val = val.trim();
      if (val != "")
        rtn.push(val);
    }
  }
  return rtn;
}


/**
 *  Returns the nearest ancestor of the given html element that has the
 *  specified tag name, or null if there isn't one.  For table elements,
 *  only ancestors that have an ID are returned .  Similarly, for TR tags,
 *  the TR that has a class name of  "repeatingLine" is returned.
 *  (This exception is for dealing with the drugs table, which has a nested
 *  table in the first field.)
 *
 *  I added the optional blankIdOk parameter so that I COULD get an element
 *  in a date field table, which is a nested table.
 *
 *  @param element the element whose ancestor we want to find
 *  @param tagName the tagName for the ancestor we want to find
 *  @param blankIdOk an optional flag used to indicate whether or not an
 *   element with a blank ID may be returned.  Defaults to false.
 *
 *  @returns the ancestor element or null if it was not found
 */
function getAncestor(element, tagName, blankIdOk) {
  if (blankIdOk === undefined)
    blankIdOk = false ;
  var rtn = null;
  while (rtn == null && element.parentNode != undefined) {
    element = element.parentNode;
    if (element.tagName == tagName) {
      if (tagName == 'TABLE') {
        if (element.id != '' || blankIdOk)
          rtn = element;
      }
      else if (tagName == 'TR') {
        if ($(element).hasClassName('repeatingLine') ||
          $(element).hasClassName('embeddedRow'))
          rtn = element;
      }
      else {
        rtn = element;
      }
    }
  }
  return rtn;
}


/**
 *  Confirms that the user wants to cancel their changes on the current
 *  page, and if they do, the URL of the page to which the browser is
 *  to be directed.
 * @param nextStep indicates the next step to be taken if the user confirms
 *  the cancel.  This should be EITHER: the URL of the page to go; OR the
 *  name of a clean up function to be performed (or the function itself), if
 *  any.  Clean up functions are used when no movement to another page is
 *  required, but some data on the current page needs to be reset to empty
 *  and/or hidden.  This can also be 'return' which means that no page cleanup
 *  or movement is initiated by this function.
 * @param newPage optional flag indicating whether or not the nextStep is
 *  to be movement to a new page.  Default is true.
 */
Def.confirmCancel = function(nextStep, newPage) {

  if (newPage == undefined)
    newPage = true;

  // If we're in test mode, assume we want to cancel.  Otherwise ask.
  if (Def.inTestMode_ == true) {
    var answer = true ;
  }
  else {
    // If we're using the data model, ask about changes
    //if (Def.DataModel && Def.DataModel.data_table_)  {
    if (Def.DataModel)  {
      Def.DataModel.save_in_progress_ = true ;
      if (Def.DataModel.dataUpdated_ ||
          Def.DataModel.recovered_fields_ != null) {
        answer = window.confirm('Are you sure you wish to discard your ' +
                                'changes on this page?\nPress OK to ' +
                                'discard the changes; Cancel to cancel the ' +
                                'request (retaining the changes).')
      }
      else {
        answer = true ;
      }
    }
    else {
      // If we're not using the data model, just ask about canceling.
      answer = window.confirm('Are you sure you wish to discard your input '+
          'on this page?\n'+
          '\nPress OK to discard, or Cancel to remain on the page.');
    }
  } // end if we're not in test mode

  if (!answer) {
    if (Def.DataModel.initialized_ && Def.DataModel.doAutosave_)
      Def.DataModel.save_in_progress_ = false ;
  }
  else {
    if (Def.DataModel.initialized_) {
      if (Def.DataModel.doAutosave_) {
        // Roll back the changes saved in the autosave data table
        new Ajax.Request('/form/rollback_auto_save_data', {
          method: 'post',
          parameters: {
            authenticity_token: window._token,
            profile_id: Def.DataModel.id_shown_ ,
            form_name: Def.DataModel.form_name_ ,
            do_close: (newPage != null || nextStep == 'closeWindow()')
          },
          asynchronous: false
        });
        var windowOpener = Def.getWindowOpener();
        if (Def.DataModel.form_name_ == 'panel_edit' && windowOpener) {
          windowOpener.Def.DataModel.subFormUnsavedChanges_ = false ;
        }
        if (newPage == false)
          Def.AutoSave.resetData(Def.DataModel.data_table_, false) ;
        Def.DataModel.pendingAutosave_ = false ;
        Def.DataModel.save_in_progress_ = false ;
      } // end if we're on a form that does autosaving
      Def.setDataUpdatedState(false) ;
    } // end if we're on a form that uses the data model

    // Now move to the next page or perform the next step
    if (newPage)
      document.location = nextStep;
    else if (nextStep !== undefined) {
      if (typeof nextStep == 'function')
        nextStep.call(this);
      else if (nextStep != 'return')
        eval(nextStep); // end if user confirmed the cancel
    }
  }
  // If we got this far, return the answer
  return answer ;
}  // confirmCancel


/**
 *  Confirms that the user wants to close the page they're on.  If there
 *  are pending changes on the page, this calls showconfirmClose to show
 *  a message asking about saving any changes, and performing the choice
 *  the user makes.
 *
 * @paran button the button that initiated this call
 * @param nextStep indicates the next step to be taken if the user confirms
 *  the cancel.  This should be EITHER: the URL of the page to go; OR the
 *  name of a clean up function to be performed (or the function itself), if
 *  any.  Clean up functions are used when no movement to another page is
 *  required, but some data on the current page needs to be reset to empty
 *  and/or hidden.  This can also be 'return' which means that no page cleanup
 *  or movement is initiated by this function.
 * @param newPage optional flag indicating whether or not the nextStep is
 *  to be movement to a new page.  Default is true.
 */
Def.confirmClose = function(button, nextStep, newPage) {

  if (newPage == undefined)
    newPage = true;

  // If we're not in test mode, we're using the data model, the user has more
  // than read access to the current profile (if applicable), and there are
  // unsaved changes, call showConfirmClose to ask the user whether or not to
  // save before closing.   Otherwise just call doCloseNoSave to close up.
  // (If we're in test mode, we assume we want to close.)  DOES NOT HANDLE
  // PENDING CHANGES FOR FORMS NOT USING THE DATA MODEL.  ???
  if (Def.inTestMode_ === false && Def.DataModel &&
      Def.accessLevel_ != Def.NO_PROFILE_ACTIVE &&
      Def.accessLevel_ < Def.READ_ONLY_ACCESS &&
      (Def.DataModel.dataUpdated_ === true ||
       Def.DataModel.recovered_fields_ !== null)) {
    Def.DataModel.save_in_progress_ = true ;
    Def.showConfirmClose(button, nextStep, newPage);
  }
  else {
    Def.doCloseNoSave(nextStep, newPage) ;
  }

  return true ;
}  // confirmClose


/**
 *  This function performs a form close for the current form.  If there
 *  are pending changes on the form, the user has chosen to discard them,
 *  and this does just that.
 *
 * @param nextStep indicates the next step to be taken if the user confirms
 *  the cancel.  This should be EITHER: the URL of the page to go; OR the
 *  name of a clean up function to be performed (or the function itself), if
 *  any.  Clean up functions are used when no movement to another page is
 *  required, but some data on the current page needs to be reset to empty
 *  and/or hidden.  This can also be 'return' which means that no page cleanup
 *  or movement is initiated by this function.
 * @param newPage optional flag indicating whether or not the nextStep is
 *  to be movement to a new page.  Default is true.
 */
Def.doCloseNoSave = function(nextStep, newPage) {

  // If the form uses the data model and autosaves, do rollback actions
  // necessary to discard the changes.
  if (Def.DataModel.initialized_ && Def.accessLevel_ != Def.NO_PROFILE_ACTIVE &&
      Def.accessLevel_ < Def.READ_ONLY_ACCESS) {
    if (Def.DataModel.doAutosave_) {
      // Roll back the changes saved in the autosave data table
      new Ajax.Request('/form/rollback_auto_save_data', {
        method: 'post',
        parameters: {
          authenticity_token: window._token,
          profile_id: Def.DataModel.id_shown_ ,
          form_name: Def.DataModel.form_name_ ,
          do_close: true
        },
        asynchronous: false
      });
      var windowOpener = Def.getWindowOpener();
      if (Def.DataModel.form_name_ == 'panel_edit' && windowOpener) {
        windowOpener.Def.DataModel.subFormUnsavedChanges_ = false ;
      }
      Def.DataModel.pendingAutosave_ = false ;
      Def.DataModel.save_in_progress_ = false ;
    } // end if we're on a form that does autosaving
    Def.setDataUpdatedState(false) ;
    Def.DataModel.save_in_progress_ = false ;
  } // end if we're on a form that uses the data model

  // Now move to the next page or perform the next step
  if (newPage)
    document.location = nextStep;
  else if (nextStep !== undefined) {
    if (typeof nextStep == 'function')
      nextStep.call(this);
    else if (nextStep != 'return')
      eval(nextStep); // end if user confirmed the cancel
  }
}  // doCloseNoSave


/**
 * This function opens a popup dialog with the confirm close message.
 *
 * If the user indicates that pending changes should be saved, this calls
 * doSave.  If the user indicates that pending changes should be discarded,
 * this calls doCloseNoSave.
 *
 * @paran closeButton the button that initiated this call.  Passed through
 *  to doSave if the user opts to save pending changes.
 * @param nextStep indicates the next step to be taken if the user confirms
 *  the cancel.  This should be EITHER: the URL of the page to go; OR the
 *  name of a clean up function to be performed (or the function itself), if
 *  any.  Clean up functions are used when no movement to another page is
 *  required, but some data on the current page needs to be reset to empty
 *  and/or hidden.  This can also be 'return' which means that no page cleanup
 *  or movement is initiated by this function.  Passed through to doCloseNoSave
 *  if the user opts to discard pending changes.
 * @param newPage optional flag indicating whether or not the nextStep is
 *  to be movement to a new page.  Default is true. Passed through to
 *  doCloseNoSave if the user opts to discard pending changes.
 */
Def.showConfirmClose = function(closeButton, nextStep, newPage) {


  // Get or construct the dialog
  if (!Def.confirmCloseDialog_) {
    Def.confirmCloseDialog_ = new Def.ModalPopupDialog({
      width: 600,
      stack: true,
      buttons: {
        "Save & Close": function() {
          Def.confirmCloseDialog_.buttonClicked_ = true ;
          Def.confirmCloseDialog_.hide() ;
          Def.doSave(closeButton, false) ;
        },
        "Close without Saving": function() {
          Def.confirmCloseDialog_.buttonClicked_ = true ;
          Def.confirmCloseDialog_.hide() ;
          Def.doCloseNoSave(nextStep, newPage) ;
        }
      },
      beforeClose: function(event, ui) {
        // prevents popup closure by clicking on x
        if (!Def.confirmCloseDialog_.buttonClicked_) return false ;
      },
      open: function() {
        Def.confirmCloseDialog_.dialogOpen_ = true ;
      },
      close: function() {
        Def.confirmCloseDialog_.dialogOpen_ = false ;
      }
    });

    Def.confirmCloseDialog_.setContent(
        '<div id="fsWarningMessage" style="margin-bottom: 1em"></div>');
  }

  // clear out old values if present/reset
  Def.confirmCloseDialog_.buttonClicked_ = false ;
  Def.confirmCloseDialog_.setContent(Def.CONFIRM_CLOSE_MSG) ;
  Def.confirmCloseDialog_.setTitle('Save Pending Changes?');
  if (window.top == window.self) {
    Def.confirmCloseDialog_.show();
  }
} // end showConfirmClose


/**
 *  Confirms that the user wants to delete a certain record, and returns
 *  true if they do.
 * @param stopEvent the event to be stopped if the answer is no/false
 */
Def.confirmDelete = function(stopEvent) {
  var answer =  window.confirm('Are you sure you wish to delete this item?' +
                               '\nPress OK to delete; Cancel to cancel the ' +
                               'deletion.')
  if (!answer && stopEvent != undefined && stopEvent != null) {
    Event.stop(stopEvent) ;
  }
  return answer;
}


/**
 *  This method sets a form to a 'wait' state.  A form in a wait state
 *  has its cursor set to a 'wait' cursor, all input fields blocked by
 *  the 'blinder' div, and the 'savingNotice' message displayed.  Buttons with
 *  labels that include the term 'Save' or 'Close' have those terms
 *  changed to 'Saving' and 'Closing' respectively.
 *
 * @param useSavingNotice optional flag indicating whether or not the
 *  'Saving' notice should be displayed.
 * @param save_button optional, invoking button object, if available
 */
Def.setWaitState = function(useSavingNotice, save_button) {

  // Set the cursor to a wait icon
  document.body.style.cursor = "wait" ;

  // Change the label for the invoking save button, or all save buttons IF
  // we're using the "saving" notice.
  if (useSavingNotice) {
    if (!save_button)
      Def.CURRENT_SAVE_BUTTONS =
                       $A($('main_form').getElementsByClassName('save_button'));
    else
      Def.CURRENT_SAVE_BUTTONS = [save_button] ;
    var blen = Def.CURRENT_SAVE_BUTTONS.length ;
    for (var b = 0; b < blen; b++) {
      if (Def.CURRENT_SAVE_BUTTONS[b].innerHTML.indexOf('Save') > -1)
        Def.CURRENT_SAVE_BUTTONS[b].innerHTML =
                   Def.CURRENT_SAVE_BUTTONS[b].innerHTML.replace('Save', 'Saving') ;
      if (Def.CURRENT_SAVE_BUTTONS[b].innerHTML.indexOf('Close') > -1)
        Def.CURRENT_SAVE_BUTTONS[b].innerHTML =
                 Def.CURRENT_SAVE_BUTTONS[b].innerHTML.replace('Close', 'Closing') ;
    }
  }
  // Show the Saving notice and bring the blinder forward
  if (useSavingNotice) {
    var savingNotice = $('savingNotice');
    savingNotice.style.display = 'block' ;
  }

  $('blinder').addClassName('activeBlinder') ;
}


/**
 *  This method shows a 'laoding... plase wait' msg in the center of the window.
 *  Input fields are not blocked.
 *  It could be used by any oprations that might last too long and users have
 *  to wait.
 */
Def.showLoadingMsg = function() {
  // Set the cursor to a wait icon
  document.body.style.cursor = "wait" ;
  var loadingMsg = $('loading_msg');
  loadingMsg.style.display = 'block';
  loadingMsg.style.zIndex = 2;
}


/**
 *  This method hide the 'laoding... plase wait' msg that was previously
 *  displayed by Def.showLoadingMsg
 */
Def.hideLoadingMsg = function() {
  // Set the cursor to a wait icon
  document.body.style.cursor = "auto" ;
  var loadingMsg = $('loading_msg');
  loadingMsg.style.display = 'none';
}

/**
 *  This method resets a form from a 'wait' state back to its normal state.
 *  A form in a wait state has its cursor set to a 'wait' cursor, all input
 *  fields disabled by the blinder division, save/close button labels modified,
 *  and the 'savingNotice' message displayed.
 *
 *  This method undoes all those settings, to restore the form to its normal
 *  state.
 * @param haveSavingNotice optional flag indicating whether or not there is
 *  a 'Saving' notice to be removed.  Default is true - there is a 'Saving'
 *  notice to be taken down.
 */
Def.endWaitState = function(haveSavingNotice) {

  // Set the cursor back to what it was
  document.body.style.cursor = "auto" ;

  if (haveSavingNotice == undefined || haveSavingNotice == null)
    haveSavingNotice = true ;

  // Restore the normal text to any save buttons that were changed
  if (Def.CURRENT_SAVE_BUTTONS.length == 0)
    Def.CURRENT_SAVE_BUTTONS = $A($('main_form').getElementsByClassName('save_button'));
  var blen = Def.CURRENT_SAVE_BUTTONS.length ;
  for (var b = 0; b < blen; b++) {
    //buttons[b].removeAttribute("disabled") ;
    if (Def.CURRENT_SAVE_BUTTONS[b].innerHTML.indexOf('Saving') > -1)
      Def.CURRENT_SAVE_BUTTONS[b].innerHTML =
                   Def.CURRENT_SAVE_BUTTONS[b].innerHTML.replace('Saving', 'Save') ;
    if (Def.CURRENT_SAVE_BUTTONS[b].innerHTML.indexOf('Closing') > -1)
      Def.CURRENT_SAVE_BUTTONS[b].innerHTML =
                 Def.CURRENT_SAVE_BUTTONS[b].innerHTML.replace('Closing', 'Close') ;
  }
  // Hide the Saving notice and drop the blinder back
  if (haveSavingNotice)
    $('savingNotice').style.display = 'none' ;

  $('blinder').removeClassName('activeBlinder') ;
}

/**
 *  This method resets Def.DataModel.dataUpdated_ and enables
 *  or disables the save buttons on the current form if the new state
 *  passed in is a change from the current state.
 *
 *  If the state is reset to true, any save buttons on the form (with a
 *  class of 'save_button') are enabled.  If the state is reset to false,
 *  any save buttons are the form are disabled.
 *
 * @param new_state boolean that indicates whether or not there are current
 *  unsaved updates on the form.
 */
Def.setDataUpdatedState = function(new_state) {
  if (Def.DataModel.dataUpdated_ != new_state) {
    Def.DataModel.dataUpdated_ = new_state ;
    if ($('main_form')) {
      var buttons = $A($('main_form').getElementsByClassName('save_button'));
      if (buttons) {
        var blen = buttons.length ;
        for (var b = 0; b < blen; b++) {
          buttons[b].disabled = !new_state ;
        }
      } // if we have save buttons on the form
    } // if we have a main form (the javascript tests don't)
  } // if this is a change to the current state
} // setDataUpdatedState


/**
 *  This method implements a save request that may or may not cause movement
 *  to another form.  It removes focus from the button used to initiate
 *  the call.  It submits the form contents via an ajax call, and includes
 *  handlers for both a successful and failed return from the server.
 *
 *  Movement to another form is only performed if errors are not signaled
 *  for the current form.
 *
 *  If the form has an element named 'saved_notice', it displays
 *  that notice and makes sure that the notice is in sight on successful
 *  completion.
 *
 *  For cases where we do not move to another form, if the hideSectionId
 *  parameter is specified, the html section whose id is specified will be
 *  hidden on successful completion.
 *
 * @param button the input element that initiated the save request.
 * @param noClose a true/false flag indicating whether to close the form
 *  on successful completion.  Optional; default is false.
 * @param action_conditions data needed, when noClose is false, to determine
 *  what form is to be displayed next.  Optional.
 * @param cleanupFunc a string that represents the invocation of a function
 *  to be run on successful completion, after everything is done but the
 *  optional form close.  The string will be invoked via an eval.  Optional.
 * @param validationErrorFunc a function, or a string that represents the
 *  invocation of a function, to be run if the onSave method returns with
 *  validation errors or to be passed to onFailedSave.  If a string is passed,
 *  it will be invoked via an eval.  A function is preferred. Optional.
 */
Def.doSave = function(button, noClose, action_conditions, cleanupFunc,
                      validationErrorFunc) {

  // Set the buttons and cursor to their wait states
  Def.setWaitState(true, button) ;
  if (Def.DataModel.initialized_) {
    Def.DataModel.save_in_progress_ = true ;
  }

  if (noClose === undefined)
    noClose = false ;
  if (cleanupFunc === undefined)
    cleanupFunc = null ;
  if (validationErrorFunc === undefined)
    validationErrorFunc = null ;

  // This tells javascript that browser close is not causing the unload event.
  // reloading defined in form.rhtml javascript
  Def.reload_ = true ;

  // Invoke the onSave function that will run the validations on the input
  // fields as well as any necessary tooltip handling.  If an error is
  // found (and onSave returns false), don't go any further in this function.
  // The validation code should have taken care of displaying the appropriate
  // error messages, and so we don't need to go back to the server at this
  // point.
  if (!onSave(button)) {
    setTipFields() ;
    Def.endWaitState() ;
    if (validationErrorFunc != null) {
      Def.Logger.logMessage(
                 ['in doSave, validation error, calling validationErrorFunc']) ;
      if (typeof validationErrorFunc === 'function')
        validationErrorFunc.call(this);
      else
        eval(validationErrorFunc) ;
    }
  }
  else {

    // For pages that include the recaptcha widget - where the user is
    // presented with a picture of two mutated words and asked to type
    // the words into a box - the recaptcha software REPLACES the widget
    // division with new form elements when the box is reloaded.
    //
    // The box may be reloaded either by a button on the box itself, when
    // the user wishes to have a different set of words to look at, or
    // when the user's input is submitted and the box is reloaded
    // automatically.
    //
    // In either case, when we get to this point we may or may not have
    // a new widget division created by the recaptcha software.  We want to
    // make sure that the ID cache points to the correct versions of the
    // fields so that when the $ function is used, it points to the right
    // ones.
    //
    // See http://bitbucket.org/mml/ruby-recaptcha/wiki/Home for more
    // info on the recaptcha widget and software.
    if ($('recaptcha_widget_div'))
      Def.IDCache.addToCache(oldDollar('recaptcha_widget_div')) ;

    // Send the post request to the server as an Ajax request.  This prevents
    // the server from automatically looking for the next page to display.
    // Set the request to be synchronous so that the user is blocked from
    // making any other changes or instigating any other events until the
    // save is complete.

    // For user data forms, such as the PHR form and Profile Management
    // form, which includes the registration data, use the taffyDB as the
    // source of the data to be saved.
    if (Def.DataModel.initialized_) {
      // get the current url, needed to find the next url after save
      var url = document.URL;

      if (action_conditions === undefined || action_conditions === null) {
        action_conditions = {} ;
        var idParts = Def.IDCache.splitFullFieldID(button.id);
        var btn_target_field = idParts[1];
        action_conditions[btn_target_field] = "1";
      }
      var messageMap = Def.reminderButtonID_ && $(Def.reminderButtonID_).messageManager.messageMap_ ;
      new Ajax.Request('/form/do_ajax_save', {
        method: 'post',
        parameters: {
          data_table: Object.toJSON(Def.DataModel.data_table_),
          authenticity_token: window._token,
          profile_id: Def.DataModel.id_shown_,
          form_name: Def.DataModel.form_name_,
          no_close: noClose,
          act_url: url,
          act_condition: Object.toJSON(action_conditions),
          message_map: Object.toJSON(messageMap)
        },
        onSuccess: onSuccessfulSave,
        onFailure: function(response) {
          Def.onFailedSave(response, false, validationErrorFunc) ;
        },
        asynchronous: true
      });
    }
    // For all other forms, i.e. those that do not save data from the taffyDB
    else {
      $('main_form').request({
        onSuccess: onSuccessfulSave,
        onFailure: function(response) {
          Def.onFailedSave(response, false, validationErrorFunc) ;
        },
        asynchronous: true
      }) ;
    }
    // Show tooltips again
    setTipFields() ;

    // Remove the focus from the save key
    if (button) {
      button.blur() ;

      // Turn off the display of required field validation error message box when
      // PHR form was saved via "save" button. This will make it behave same as
      // user reloads the page after clicking the "save and close" button.
      if (button.id == "fe_save")
        Def.Validation.RequiredField.Functions.showErrMsgs_ = false;
    }
  } // if onSave returned true - validateInputCtls did not find invalid fields

  // Ajax onSuccess handler
  // 5/1/12 - periodically we have problems with this, where the save will
  // be successful but something will blow up in here.  We don't have a lot of
  // luck tracking it down, so I've added some section numbers (debugSection).
  // Now if a system error is recorded we'll at least have an idea of where to
  // look.  Hopefully we can narrow it down from there.   lm.
  function onSuccessfulSave(response) {
    var doCleanup = true ;
    var debugSection = 0 ;
    try {
      // for user forms with taffydb initialized
      if (Def.DataModel.initialized_) {
        debugSection = 1 ;
        Def.DataModel.recovered_fields_ = null ;
        if (Def.DataModel.doAutosave_) {
          Def.DataModel.pendingAutosave_ = false ;
          var windowOpener = Def.getWindowOpener();
          if (Def.DataModel.form_name_ == 'panel_edit' && windowOpener)
            windowOpener.Def.DataModel.subFormUnsavedChanges_ = false ;
        }
        debugSection = 2 ;
        var respHash = eval('(' + response.responseText + ')');
        // not to update record_id or other fields on flow sheet form
        if (Def.DataModel.form_name_ != 'panel_view') {
          debugSection = 3 ;
          // update the added records
          var recordsAdded = respHash['data']['added'];
          for(var j=0, len=recordsAdded.length; j< len; j++) {
            var table_name = recordsAdded[j][0];
            var position = recordsAdded[j][1];
            var record_id = recordsAdded[j][2];
            if (position !=null && position >=0 && table_name != null &&
                record_id !=null && record_id > 0) {
              // update record_id in data_table_ and the hidden fields of the
              // related rows on the form
              // turn off autosave for updating the record_id, which is already
              // saved in the server end.
              Def.DataModel.doAutosave_ = false;
              Def.DataModel.updateOneRecord(table_name, position,
                  {'record_id': record_id}, true);
              // turn the autosave back on
              Def.DataModel.doAutosave_ = true;
            }
          }
          // no controlled edit table on panel_edit page
          if (Def.DataModel.form_name_ != 'panel_edit') {
            debugSection = 4 ;
            Def.FieldsTable.ControlledEditTable.postSaveUpdate(respHash['data']);
            // update deleted/empty rows: remove rows in data_table and update
            // mapping tables
            //var recordsDeleted = respHash['data']['deleted'];
            //var recordsEmpty = respHash['data']['empty'];
            debugSection = 4.1;
            var recordsToRemove = respHash['data']['to_remove'];
            debugSection = 4.2;
            Def.DataModel.removeRecordsAndUpdateMappings(recordsToRemove);
          } // end if form is not panel_edit

          // update the due date reminder count on phr form
          if (Def.DataModel.form_name_ == 'phr') {
            Def.PHR.setDueDateReminderCount();
          }

          // This is taken care of in the TestPanel.afterSaveCleanup function
          // for the panel_view form.
          if (noClose) {
            debugSection = 5 ;
            Def.AutoSave.resetData(Def.DataModel.data_table_, false) ;
          }
        } // end if form is not panel_view

        // Flag set to true when data changed and again when record_id updated.
        // Set it to false now to prevent data not saved warning popup before
        // browser closes (or even otherwise if just saving).
        //Def.DataModel.dataUpdated_ = false ;
        debugSection = 6 ;
        Def.setDataUpdatedState(false) ;
        // Remove any 'recovered' item flagging and block display of the
        // accompanying message if it's there
        var recFlds = $$('.recovered') ;
        if (recFlds) {
          for (var rf = 0, rtot = recFlds.length; rf < rtot; rf++)
            recFlds[rf].removeClassName('recovered') ;
          Def.hideNotice(true);
        } // end if we have recovered fields
        Def.DataModel.save_in_progress_ = false ;
      } // end if the DataModel has been initialized

      // for all other forms - ones that don't use the data model
      else {
        if (!noClose) {
            respHash = response.responseText.evalJSON() ;
          }
      }  // end if the taffydb is/isn't used with the current form

      // show the saved notice
      var notice = $('saved_notice') ;
      if (notice != null) {
        notice.style.display = 'block' ;
        notice.style.visibility = 'visible' ;
        notice.scrollIntoView(false) ;
      }
      // Execute the cleanup function if one is specified.
      if (cleanupFunc != null) {
        if (typeof cleanupFunc === 'function')
          cleanupFunc.call(this);
        else
          eval(cleanupFunc) ;
      }
      if (respHash['unique'] !=  null ){
        var unique = "Def.Validation.Base.UniqueValuesByField_ = " +
                      respHash['unique'] ;
        eval(unique) ;
        Def.updateUniqueValueValidationData();
      }

      // Close whatever needs to be closed - if anything
      if (!noClose) {
        if (respHash['target'] != null) {
          doCleanup = false ;

          // For the life of me I can't figure out how to bring down
          // the saving notice and get the loading notice up in a timely
          // manner.  The green message line says that the changes have been
          // saved but the Saving block still displays for a long time.  So,
          // I decided to just outfox it and change the notice in the Saving
          // block.  It gets rewritten when the next page loads .. so it
          // doesn't need to be cleaned up.  And it doesn't leave me or the
          // user wondering if the Save process has just wandered off.
          // 12/12/13 lm.
          var snotice = $('savingNotice') ;
          var lnotice = $('loading_msg') ;
          snotice.innerHTML = lnotice.innerHTML ;

          // Now move to the next page - which will be visible to
          // the user after awhile.
          window.location = respHash['target'] ;
        }
        else if (respHash['javascript']) {
          var js = respHash['javascript'] ;
          if (js)
            eval(js) ;
        }
        // no target found, should be a popup window
        else {
          closeWindow();
        }
      }
    }
    catch (e) {
      e.message += ' -- occurred in section ' + debugSection ;
      Def.Logger.logException(e);
      Def.reportError(e);
      Def.showSaveFailedMsg();
      if (doCleanup)
        Def.endWaitState();
      throw e;  // rethrow
    }
    if (doCleanup)
      Def.endWaitState() ;
  } // end onSuccessfulSave


}; // end doSave


/**
 * Ajax save onFailure handler.  This had been defined within the Def.doSave
 * function (as onSuccessfulSave is still defined). I am pulling it out to
 * the Def level because I also need to use it for usage report save failures.
 * @param response response from the server, should contain the error message
 * @param fromUsage boolean flag indicating whether or not this failure was
 *  from a call to store usage stats.  If true, setting error messages, etc.,
 *  is bypassed.  (The user doesn't even know this happens.  They don't need
 *  to be interrupted with a problem from it).  Optional, default is false.
 * @param errorFunc a function, or a string that represents the
 *  invocation of a function, to be run after the error reporting is taken
 *  care of.  Passed from doSave, using the validationErrorFunc parameter.
 *  If a string is passed, it will be invoked via an eval.  A function is
 *  preferred. Optional.
 */
Def.onFailedSave = function(response, fromUsage, errorFunc) {

  if (fromUsage === undefined) {
    fromUsage = false ;
  }
  if (errorFunc === undefined) {
    errorFunc = null ;
  }
  var doLogout = false ;
  var from_overflow = false ;
  var evaled_resp = response.responseText.evalJSON() ;
  var js = evaled_resp['javascript'] ;
  if (js)
    eval(js) ;

  var msg = null ;
  if (evaled_resp['exception'] && evaled_resp['do_logout']) {
    doLogout = true ;
    msg = evaled_resp['exception_msg'] ;
    from_overflow = evaled_resp['exception_type'] &&
                    evaled_resp['exception_type'] == 'data_overflow' ;
  }
  if (!fromUsage) {
    if (evaled_resp['errors']) {
      var respArray = evaled_resp['errors'] ;
      if (respArray.length > 0) {
        msg = 'The following problems were found:<ul>' ;
        for (var e = 0, max = respArray.length; e < max; e++) {
          if (respArray[e] == '</ul>') {
            msg += respArray[e] ;
          }
          else {
            msg += '<li>' + respArray[e] + '</li>' ;
          }
        }
        msg += '</ul>'
      }
    }
    if (msg)
      Def.showError(msg, true) ;
    else
      Def.showSaveFailedMsg() ;
    if (Def.DataModel.initialized_)
      Def.DataModel.save_in_progress_ = false ;
    Def.endWaitState() ;
  } // end if not from a usage error

  if (doLogout) {
    Def.showError(msg + '  Your session is being ended now.', true);
    // Set the forceLogout_ flag so that we don't ask the user if they
    // really want to leave
    Def.forceLogout_ = true ;
    // If this occurred from a popup window - for example, from the
    // Add Tests & Measures window, we need to close the popup and
    // logout from its parent window.
    if (window.opener != null) {
      var curPopup = window ;

      // Set the Def.forceLogout_ flag for all ancestor windows
      // and push the popups on the array of popups to close
      var toClose = [] ;
      while (curPopup.opener != null) {
        toClose.push(curPopup) ;
        curPopup = curPopup.opener ;
        curPopup.Def.forceLogout_ = true ;
      }
      // Force logout from the non-popup ancestor
      if (from_overflow)
        curPopup.location = Def.LOGOUT_URL + '?end_type=after_overflow' ;
      else
        curPopup.location = Def.LOGOUT_URL ;

      // Close the popups, doing this one last
      for (var p=toClose.length - 1; p >= 0; p--)
        toClose[p].close() ;
    }
    else
      if (from_overflow)
        window.location = Def.LOGOUT_URL + '?end_type=after_overflow' ;
      else
        window.location = Def.LOGOUT_URL ;
  }
  else if (errorFunc) {
    if (typeof errorFunc === 'function')
      errorFunc.call(this);
    else
      eval(errorFunc) ;
  }
} // end onFailedSave


/**
 *  Shows a "save failed" message for the case when the problem is
 *  with the system (i.e., an exception was thrown). This had been defined
 *  within Def.doSave (as onSuccessfulSave is stilled defined).  I am pulling
 *  it out to the Def level because it's called by Def.onFailedSave, which I
 *  need to use it for usage report save failures also.  This message is not
 *  actually used for usage report save failures.
 */
Def.showSaveFailedMsg = function() {
  Def.showError('An error with our system occurred while saving.'+
    ' Your data might not be completely saved.  We are sorry for the '+
    'inconvenience, and we will investigate the problem as soon as '+
    'possible.');
}


/**
 *  This method hides an element named 'saved_notice' if one exists
 *  on the form.  This is meant to be called after the notice is
 *  displayed and the user presses a key on the form.
 *
 */
Def.hideSaveNotice = function() {
  var notice = $('saved_notice') ;
  if (notice != null)
    notice.style.visibility = 'hidden' ;
}


/**
 *  Sets the document location (e.g. after pressing a cancel button), or
 *  closes the window if this is a popup and closeIfPopup is true.
 * @param theLocation the new (possibly relative URL for the window)
 * @param closeIfPopup (optional, default=false) If true, then if the window
 *  is a popup it will be closed (instead of going to the given location).
 */
Def.setDocumentLocation = function(theLocation, closeIfPopup) {
  document.location = theLocation ;
  if (closeIfPopup && Def.getWindowOpener()) {
    window.close();
  }
}


/**
 * This function will increment a string value.  It is assumed that the
 * value passed in is a string.  The string is incremented in one of two ways:
 * 1) as a single entity, similar to adding 1 to a number (oneEntity = true); or
 * 2) treating each character as a separate entity (oneEntity = false).
 *
 * Character increments are implemented as follows
 * '0' -> '8' - set to the next digit; incrementing stops if oneEntity is true;
 * '9' -> set to '0' and incrementing continues;
 * 'a' -> 'y' - set to the next lowercase letter; incrementing stops if
 *              oneEntity is true;
 * 'z' -> set to 'z' and incrementing continues;
 * 'A' -> 'Y' - set to the next uppercase letter; incrementing stops if
 *              oneEntity is true;
 * 'Z' -> set to 'A' and incrementing continues;
 * any other characters -> no change; incrementing continues.
 *
 * Incrementing always starts with the last character in the string.  If
 * the value is to be treated as a single entity, (oneEntity = true) the last
 * character is incremented and the process stops - unless the increment causes
 * a "carry".  In that case the character immediately preceding the one just
 * incremented is also incremented.  The "carry" can ripple through all
 * characters in the string, but is not implemented beyond the first character.
 *
 * So, 'a4X' would be incremented to 'a4Y'.  'Tz' would be incremented to 'Ua'.
 * '96Z' would be incremented to '97A'.  '9Z' would be incremented to '0A'.
 *
 * If the value is not to be treated as a single entity, each character in
 * the string is incremented, as noted above, but no "carry" operation is
 * performed.
 *
 * So, 'a4X' would be incremented to 'b5Y'.  'Tz' would be incremented to 'Ua'.
 * '96Z' would be incremented to '07A'.  '9Z' would be incremented to '0A'.
 *
 *
 *
 * @param theString the string to be incremented
 * @param oneEntity flag indicating how to increment the value; default is
 *  true - treat it as one entity (as opposed to incrementing each character
 *  separately)
 * @returns the incremented string
 */
function incrementString(theString, oneEntity) {
  if (oneEntity == undefined)
    oneEntity = true ;
  var revStr = '' ;
  var doMore = true ;
  for (var i = theString.length - 1; i >= 0; i--) {
    var curASCII = theString.charCodeAt(i);
    var newASCII = 0 ;
    if (doMore && ((curASCII >= 48 && curASCII <= 57) ||   // 0 -> 9 (characters)
                   (curASCII >= 65 && curASCII <= 90) ||   // A -> Z
                   (curASCII >= 97 && curASCII <= 122))) { // a -> z
      switch (curASCII) {
      case 57:
        newASCII = 48 ;
        break ;
      case 90:
      case 122:
        newASCII = curASCII - 25 ;
        break ;
      default:
        newASCII = curASCII + 1 ;
        if (oneEntity == true) {
          doMore = false ;
        }
      } // end switch
    }
    else {
      newASCII = curASCII ;
    } // if is/isn't a letter or a digit

    revStr += String.fromCharCode(newASCII) ;
  } // end do for each character in the string
  var newStr = '' ;
  for (i = theString.length - 1; i >= 0; i--)
    newStr += revStr[i] ;
  return newStr ;
} // end incrementString


/**
 * Wrapper for client side validation and tooltip clearance before saving
 * Returns true if non visible input textboxes is invalid
 *
 * @param field the field that caused this function to be invoked
 * @param stopEvent optional, if passed is the event object on which to issue
 *  a stop if invalid fields are found
 */
function onSave(field, stopEvent){
  // If there is invalid non-required fields, then return false
  if ($H(Def.Validation.Base.invalidFields_).size() > 0 ) {
    if (stopEvent)
      Event.stop(stopEvent);
    return false;
  }
  else {
    clearFields() ; // clear remaining tooltips on form fields
    // make sure required field validation was passed
    var ret =  validateInputCtls(field, stopEvent);
    return ret ;
  }
}

/*
 * Clears the toolTips from the fields so that they are not saved.
 * There is an attribute on the field called noValue that is set to false
 * if the value is changed in the field.
 */
function clearFields(){
  for (var fdName in Def.tipFields_) {
    var fields = Def.IDCache.findByIDStart('fe_'+fdName,'_');
    var fields2 = Def.IDCache.findByID('fe_'+fdName);

    fields.concat(fields2) ;
    if (fields.length > 0) {
     for (var i=0;i<fields.length;i=i+1) {
        if (fields[i].getAttribute("novalue") != "false"  &&
          fields[i].value != undefined){
          fields[i].value="" ;
        }
      }
    }
  }
}

/*
 * Sets the toolTips from the fields so that they put back after ajax save
 * There is an attribute on the field called tipValue that has the tooltip
 * value.
 */
function setTipFields(){
  for (var fdName in Def.tipFields_) {
    var fields = Def.IDCache.findByIDStart('fe_'+fdName,'_');
    var fields2 = Def.IDCache.findByID('fe_'+fdName);
    fields.concat(fields2) ;
    if (fields.length > 0) {
      for (var i=0;i<fields.length;i=i+1) {
        if (fields[i].value == ""){
          fields[i].value= fields[i].tipValue ;
          Def.onTipSetup(fields[i]) ;
        }
      }
    }
  }
}

/**
 * Client side validation
 * Trigged by onclick event of button "save" or "save && close"
 * Returns true if non visible input textboxes is invalid
 *
 * @param field the field that caused this function to be invoked
 * @param stopEvent optional, if passed is the event object on which to issue
 *  a stop if invalid fields are found
 */
function validateInputCtls(field, stopEvent){
  var valid = Def.Validation.RequiredField.Functions.validateAll(field);
  if (!valid) {
    var errMsg = "Some input(s) of the form may be invalid";
    Def.Logger.logMessage([errMsg]);
//    alert(errMsg);
    if (stopEvent != undefined && stopEvent != null) {
      Event.stop(stopEvent) ;
    }
  }
  return valid;
}


/**
 *  Determines whether or not an element is an available input field, which is
 *  focusable for naviation.
 *  It is NOT available if:
 *   1) it is disabled;
 *   2) its type is "hidden";
 *   3) it has a tag name of "TH" (it's a header cell in a table,
 *      which can happen when we're moving up and down in a table);
 *   4) it has a class name of "readonly_field";
 *   5) it has a class name of "noNav";
 *   6) it has a style.visibility attribute of 'hidden'; or
 *   7) it OR any of its ancestors has a style.display attribute of 'none'.
 *  Remark: This function was moved out from navigation.js on 1/5/09 - Frank
 *  This function is mainly for key navigation. It does not check computed
 *  style of an element. see isElementVisibile for computed style check.
 *
 * @param elem the element to be tested for availability
 * @param check_collapse (optional) flag indicating whether or not to
 *        omit checking for collapsed divisions.  Defaults to false
 * @return true if the element is hidden or disabled, i.e. NOT available
 *         false if the element is not hidden or disabled, i.e. IS available
 */
function isHiddenOrDisabled(elem, check_collapse) {
  var rtn = false;
  var elemFld = $(elem) ;
  if (check_collapse == undefined)
    check_collapse = false ;
  var hideClasses = ['readonly_field', 'hidden_field', 'noNav',
                     'static_text', 'removed'] ;
  //elemFld.hasClassName('readonly_field') ||
  //elemFld.hasClassName('hidden_field') ||
  //elemFld.hasClassName('noNav') ||
  if (elem.disabled ||
    elem.type == 'hidden' ||
    elem.tagName == 'TH' ||
    checkClassName(elemFld, hideClasses) ||
    (checkClassName(elemFld, ['rowEditText']) && !checkClassName(elemFld, ['cet_edit'])) ||
    elemFld.style.display == 'none' ||
    elemFld.style.visibility == 'hidden' ) {
    rtn = true;
  }
  // If it's not hidden or disabled itself, check to see if an ancestor
  // has display set to "none".  This will affect all descendants of the
  // ancestor.  The other conditions checked at the element level do not
  // affect descendants (disabled, type=hidden, or visibility).
  // [Update:  I don't know about Firefox 2, but on Firefox 3, visibility
  // *does* affect the child nodes, so we need to check that too.]
  // Oh - and the 'removed' class on a parent row ALSO makes child nodes
  // hidden.
  else {
    var climber = elem ;
    while (climber.parentNode != null && !rtn) {
      // for validations
      if (check_collapse) {
        // skip checking for the hidden vertical rows in test panels which could
        // be re-displayed by clicking the "More" button
        // and skip the fields in a collapsed group
        if (!checkClassName(climber, 'test_optional') &&
            !checkClassName(climber, 'expand_collapse') &&
            (climber.style.display == 'none' ||
             climber.style.visibility == 'hidden' ||
             (climber.tagName == 'DIV' && checkClassName(climber,'hidden_field'))
            )) {
          rtn = true;
        }
      }
      // for key navigations, hidden is hidden
      else {
        if (climber.style.display == 'none' ||
            climber.style.visibility == 'hidden' ||
            (climber.tagName == 'DIV' &&
             checkClassName(climber,'hidden_field')) ||
            checkClassName(climber, 'removed')
           ) {
          rtn = true;
        }
      }
      climber = climber.parentNode;
    }
  }
  return rtn;

} // isHiddenOrDisabled

/**
 * Determines if an element is visible, by checking computed style, not static
 * styles, which might be misleading if it's change in CSS files
 *
 * @param elem the element to be tested for visibility
 * @return true if the element is hidden (display:none or visibility:hidden in
 *         computed style).
 *         false if the element is visible
 */
function isElementVisible(elem) {

  if (elem == document) return true;
  if (!elem) return false;
  if (!elem.parentNode) return false;

  if (elem.style && (elem.style.display == 'none' ||
    elem.style.visibility == 'hidden') ) {
    return false;
  }
  //Try the computed style in a standard way
  else if (window.getComputedStyle) {
    var style = window.getComputedStyle(elem, "");
    if (style.display == 'none') return false;
    if (style.visibility == 'hidden') return false;
  }
  //Or get the computed style using IE's silly proprietary way
  else {
    style = elem.currentStyle;
    if (style) {
      if (style['display'] == 'none') return false;
      if (style['visibility'] == 'hidden') return false;
    }
  }
  return isElementVisible(elem.parentNode);
}

/**
 *  Returns the value of the given HTML field object.  If the field is a radio
 *  button or checkbox, the boolean value of the "checked" attribute is
 *  returned.  Otherwise, if the field's value is numeric, it is parsed as a
 *  float and returned, or if it is not numeric, the value is (maybe)
 *  lower-cased and returned as a string.
 *
 * @param field the field to be parsed
 * @param keepCase true if the field's value should not be lowercased.
 *
 *
 * This function was moved from rules.js since valiation.js also needs it -Frank
 */
function parseFieldVal(field, keepCase) {

  var fieldVal;
  var boolVal = false ;
  if (field.type != null) {
    var type = field.type.toLowerCase();
    if (type=='radio' || type=='checkbox') {
      fieldVal = field.checked;
      boolVal = true ;
    }
  }
  if ((boolVal == false && field.value != null)
    || field.hasClassName("static_text")) {
    //fieldVal = field.value.trim();
    fieldVal = Def.getFieldVal(field);
    if (!keepCase)
      fieldVal = fieldVal.toLowerCase();
    if (/^-?[0-9]*\.?[0-9]+$/.exec(fieldVal))
      fieldVal = parseFloat(fieldVal);
  }
  return fieldVal;
}


/**
 * Scrolls into view the field on top of the screen and sets focus on that field
 * @param fieldOrFieldID -  ID of the field or field itself which will be
 * focused on
 * @param topDivs a list of DIVs on the top of the page. They could also be
 * the ids or class names of the DIVs.
 */
function jumpTo(fieldOrFieldID, topDivs){
  var field = (typeof fieldOrFieldID == "string") ? $(fieldOrFieldID) : fieldOrFieldID;
  field.scrollIntoView();

  // Checks if there is a page header starting from the lowest one (e.g. error
  // message box, form header etc)
  var hdr = null;
  for(var i=0,max=topDivs.length;i<max;i++){
    if (typeof topDivs[i] == "string"){
      hdr = $(topDivs[i]);
      if (!hdr)
        hdr = $$("."+topDivs[i])[0];
    }
    if (hdr) break;
  }
  // Because page header may cover the field, we need to scroll field back
  var scrollBack = hdr ? (hdr.offsetTop + hdr.offsetHeight) : 0;

  // The offsetParent of hdr is BODY
  // Since the offsetParent of the field is not BODY, we need to sum the
  // offsetTop until offsetParent is BODY too.
  var curField = field;
  var fieldY = curField.offsetTop;
  while(curField.offsetParent.tagName != "BODY"){
    curField = curField.offsetParent;
    fieldY +=curField.offsetTop;
  }
  // Try to get the current Y coordinate
  var currentFieldY = fieldY - window.pageYOffset;
  // Scrolls back only when the field is in the scroll back zone
  scrollBack = scrollBack - currentFieldY;

  if (scrollBack > 0){
    window.scrollBy(0, 0-scrollBack);
  }
  field.focus();
}


/**
 * Loads the data onto the form, adds needed blank rows, sets up the navigation
 * keys, run the rules, sets up document key events and loads required field
 * validators.
 * @param dataHash - data for the form
 */
function dataLoaderAndDependentSetups(dataHash){

  if(dataHash)
    Def.DataLoader.loadData(dataHash, null);
  var start = new Date().getTime();
  Def.FieldsTable.ControlledEditTable.hideBlankRows();
  Def.Logger.logMessage(['hid blank rows in ', new Date().getTime() - start])

  start = new Date().getTime();
  if (!Def.delay_navsetup_)
    Def.Navigation.setUpNavKeys();
  Def.Logger.logMessage(['did nav keys in ',
    (new Date().getTime() - start), 'ms']) ;

  start = new Date().getTime() ;
  Def.Rules.runFormRules();
  //setUpDocumentKeyEventListener();
    this.documentKeyEventWrapper_ =
                         this.Def.Navigation.handleDocumentKeyEvent.bind(this) ;
  if (typeof window.event != 'undefined') { // IE
    Event.observe(document, 'keydown', this.documentKeyEventWrapper_) ;

  }
  else {
    Event.observe(document, 'keypress', this.documentKeyEventWrapper_) ;
  }
  Def.Logger.logMessage(['ran rules in ',
    (new Date().getTime() - start), 'ms']);


  start = new Date().getTime() ;
  Def.Validation.RequiredField.Functions.loadValidator();
  Def.Logger.logMessage(['ran loadValidator in ',
    start, 'ms'], true, true);
}


/**
 *  Converts an array into an English list, e.g. ['one, 'two'].toEnglish() =
 *  'one and two', and ['one', 'two', 'three'].toEnglish() =
 *  'one, two, and three'.  The values will be html encoded with htmlEncode().
 */
Array.prototype.toEnglish = function() {
  var rtn;
  var numElements = this.length;
  if (numElements == 0)
    rtn = '';
  else {
    if (typeof this[0] == 'string') {
      // HTML encode the elements if they are string (but not if they are
      // numbers)
      for (var i=0; i<=lastIndex; ++i)
        this[i] = htmlEncode(this[i]);
    }
    if (numElements == 1)
      rtn = this[0];
    else if (numElements == 2)
      rtn = this[0] + ' and ' + this[1];
    else {
      var lastIndex = numElements-1;
      rtn = this.slice(0, lastIndex).join(', ') + ', and ' + this[lastIndex];
    }
  }
  return rtn;
}

Array.prototype.clean = function(deleteValue) {
  for (var i = 0; i < this.length; i++) {
    if (this[i] == deleteValue) {
      this.splice(i, 1);
      i--;
    }
  }
  return this;
};

/**
 *  Parses a field value from a set field type
 *  (see PredefinedField.make_set_value), and returns the array.  If there
 *  are no values, an empty array will be returned.
 */
Def.parseSetValue = function(setVal) {
  var rtn = [];
  if (setVal && setVal.length > 2) {
    setVal = setVal.substring(1, setVal.length-1);
    rtn = setVal.split(Def.SET_VAL_DELIM);
  }
  return rtn;
}


/**
 *  Hides or shows a table row.  This assumes the row has not been hidden
 *  by some mechanism other than this method.
 * @param row - the table row
 * @param show - if true, the table row will be made visible; otherwise
 *  it will be hidden.
 */
Def.setTableRowVisibility = function(row, show) {
  row.style.display = show ? '' : 'none';
}


// Override Event.observe to provide error handling.
Event.originalObserve = Event.observe
Event.observe = function(element, eventName, handler, useCapture) {
  var newHandler = function(event) {
    try {
      handler.call(element, event);
    }
    catch(e) {
      Def.reportError(e);
      // Re-throw
      throw e;
    }
  }
  newHandler.handler = handler; // for debugging
  Event.originalObserve(element, eventName, newHandler, useCapture);
} // end Event.observe


/**
 *  Performs a deep clone on the object.
 * @param obj the object to be cloned.  This should be either a hash or
 *  an array.
 */
Def.deepClone = function(obj) {
  if (Object.isArray(obj))
    var rtn = jQuery.extend(true, [], obj);
  else
    rtn = jQuery.extend(true, {}, obj);
  return rtn;
}


/**
 * Submits a non-autosaved form if required field validation was passed.
 * Otherwise restores the form (ie. restores all the cleared tips).
 * If the window is in a popup, the submit request is sent via XHR, and any
 * response back is assumed to be an error message.
 *
 * @param submitButton the submit button
 * @param closeIfPopup if true, and the validation passes, and this window
 *  was opened by another window, then after the form is submitted the
 *  window will be closed. (Default = false)
 * @param messageIfPopup A message to display after the popup closes (if it
 *  is a popup).  This may be omitted, in which case no message will be shown.
 **/
Def.submitForm = function(submitButton, closeIfPopup, messageIfPopup){
  if(!onSave(submitButton)){
    setTipFields() ;
  }
  else{
    var windowOpener = Def.getWindowOpener();
    var form = submitButton.form;
    if (closeIfPopup && windowOpener) {
      // In this case (where we are closing the page) we can't just do
      // form.submit(), though that seems to work in IE and I think used to
      // work in Firefox.  form.submit() does not wait for anything before
      // it returns, so there is a race condition afterward between the
      // request getting off to the server and the window being closed.
      // If the window closes first, the server never gets the request.
      // So instead of doing that, we'll do a synchronous Ajax post.
      var errors = null;
      new Ajax.Request(form.action, {method: form.method,
          asynchronous: false, parameters: form.serialize(true),
          onSuccess: function(response) {
            errors = response.responseText;}} );
      if (errors != null && errors != '')
        Def.showNotice(errors);
      else {
        if (messageIfPopup)
          windowOpener.Def.showNotice(messageIfPopup);
        window.close();
      }
    }
    else // just do a normal form submission
      form.submit();
  }
}

/**
* Returns the label name of a field (including fields of test panel) using label
* information stored in a hash object or taffy_db object on the client side.
* The label name is the first element of the returned array.  The second element
* contains the labels of the field groups containing the field.
*
* @param field the field to get the label name from
**/
Def.getLabelName = function(field){
  field = $(field);
  var rtn = "";
  var fieldName = null ;
  var parenthesisPart = "" ;
  if(TestPanel.inTestPanel(field)){
    // Gets label data from taffy_db
    var labelParts = TestPanel.getLabelName(field).split("/");
    fieldName = labelParts[1];
    parenthesisPart += " (" + labelParts[0]  + ")" ;
  }
  else{
    if (Def.dataFieldlabelNames_) {
      var idParts = Def.IDCache.splitFullFieldID(field.id);
      // Gets label data from a hash
      labelParts = Def.dataFieldlabelNames_[idParts[1]];
      fieldName = labelParts[0][0];
      // If there are more than 1 row, then specify the row number
      var rowContent = "";
      if( findFields(Def.FIELD_ID_PREFIX, idParts[1],'').length > 1 ) {
        var rowNum = idParts[2].split("_").last();
        rowContent += " Row " + rowNum;
      }
      parenthesisPart += " (" + labelParts[1] + rowContent + ")" ;
    }
  }
  return [fieldName, parenthesisPart];
}


/**
 * Returns the main window object which created the popup window passed in as a
 * parameter. This global method should work on the latest versions of all major
 * browsers including IE, Firefox, Chrome and Safari. The popup window could be
 * created by either window.showModalDialog or  window.open functions.
 * -Frank 02/02/2012
 * @param popup the pop up window created by window's open or showModalDialog
 * functions
 **/
Def.getWindowOpener= function(popup){
  if (!popup)
    popup = window;
  return popup.opener || (popup.dialogArguments && popup.dialogArguments[1]);
}


/**
 * Needed when using JavaScript to create asset related HTML code
 */
Def.Asset = {
  /**
   * Equivalent to Rails.application.config.assets.prefix
   * This value will be replaced by the Rails equivalent in
   * application_helper.rb#generate_form_js
   */
  prefix_: '/assets'
}


/**
 * The relative path of the blank image. It is used for building image tags using
 * JavaScript code on client side. In order to make it working in production mode,
 * the path has to be suffixed with a digest(search blankImage in show.rhtml.erb
 * for details).
 */
Def.blankImage_ = window.blankImage;


/**
 * The page view mode. It could be either "standard" or "basic". When in basic
 * mode, the Javascript code will be executed at server side. When in standard
 * mode, the Javascript codes will be executed at client side (i.e. on the
 * browser).
 */
Def.page_view = "default";


/**
 * Update the number displayed on the button with the new count number.
 *
 * @param button the button used for displaying a count number
 * @param count the new display number to be displayed on the button
 */
Def.updateMessageCount=function(button, count) {
  // if the button exists
  if (button) {
    // if there are reminders
    if (count > 0) {
      // update the number
      if (button.next(0) && button.next(0).hasClassName('super')) {
        button.next(0).innerHTML = '[' + count + ']';
      }
      // add a div element to contain the number
      else {
        button.insert(
        {
          after: '<div class=super>[' + count + ']</div>'
        });
      }
    // no reminders
    } else {
      // remove the div
      if (button.next(0) && button.next(0).hasClassName('super')) {
        button.next(0).remove();
      }
    }
  } // end of if the button exists
}


// Show the number of rows as specified in the max_responses attribute of any
// DOM which has a class name "showMaxResponses"
Def.showMaxResponsesRows = function(){
  var hdrs = document.getElementsByClassName("showMaxResponses");
  for (var i=0, max = hdrs.length; i<max; i++) {
    var maxResponses = parseInt(hdrs[i].readAttribute('max_responses'));
    if (isNaN(maxResponses))
      maxResponses = 0 ;
    var table = hdrs[i].down("table");
    var numExistingRows = parseInt(table.readAttribute('nextid')) - 1;
    var numToAdd = maxResponses - numExistingRows;
    if (numToAdd > 0){
      for (i=0; i< numToAdd ; i++)
        Def.FieldsTable.addTableLine(table);
    }
  }
}
