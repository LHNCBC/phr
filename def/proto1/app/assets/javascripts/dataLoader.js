/**
 * dataLoader.js -> javascript functions to control loading of the
 *                  stored data into a form
 *
 *
 *
 * $Id: dataLoader.js,v 1.57 2011/08/17 18:19:37 lmericle Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/dataLoader.js,v $
 * $Author: lmericle $
 *
 * $Log: dataLoader.js,v $
 * Revision 1.57  2011/08/17 18:19:37  lmericle
 * minor changes from code reviews, formatting, typos
 *
 * Revision 1.56  2011/08/10 20:05:11  lmericle
 * added code to display recovered date in test fields that are normally not initially displayed
 *
 * Revision 1.55  2011/07/26 18:22:06  wangye
 * fixed a typo
 *
 * Revision 1.54  2010/11/17 14:35:04  lmericle
 * removed setupTip param from several functions; replaced setInputFieldValue with Def.setFieldVal after timing tests showed was surprisingly faster
 *
 * Revision 1.53  2010/10/29 15:11:23  lmericle
 * added optional param setupTip to loadData, setFieldValue, setInputfieldValue
 *
 * Revision 1.52  2010/10/22 21:30:44  wangye
 * first checkin of the modified panel edit page adding 'browse panels' and 'search panel/test' options; removed the double click function on group headers; restore the in_hdr buttons positions
 *
 * Revision 1.51  2010/10/07 17:37:53  mujusu
 * hideTipMessage not needed
 *
 * Revision 1.50  2010/08/31 19:30:58  wangye
 * fixed a bug that panel header has input field
 *
 * Revision 1.49  2010/08/30 21:02:32  wangye
 * added handling of test_data_type for flowsheet
 *
 * Revision 1.48  2010/05/27 15:17:59  wangye
 * make test panel's row work with isHiddenOrDisabled function by adding style.display='none' when it needs to be hidden
 *
 * Revision 1.47  2010/05/25 15:57:06  wangye
 * moved the 'more' button in test panel to table header
 *
 * Revision 1.46  2010/05/21 14:00:59  mujusu
 * rtemoved toggleTooltip
 *
 * Revision 1.45  2010/04/26 19:07:52  wangye
 * hide the 'more' button in test panel when there's no optional tests
 *
 * Revision 1.44  2010/03/05 14:35:05  lmericle
 * added code to load lists for combo fields
 *
 * Revision 1.43  2010/02/04 22:25:01  plynch
 * Changes to load the form from the DataModel data when possible.
 *
 * Revision 1.42  2009/12/22 22:22:43  plynch
 * Changed splitFullFieldID so that its return value is cached, updated
 * the code to be aware of that, and moved the function into idCache.js.
 *
 * Revision 1.41  2009/09/24 17:56:33  mujusu
 * header elements in span
 *
 * Revision 1.40  2009/09/10 20:15:36  wangye
 * removed ajax calls for ranges when page is loaded
 *
 * Revision 1.39  2009/07/24 21:51:12  wangye
 * bug fixes for the newly add date field on each test
 *
 * Revision 1.38  2009/04/22 23:18:46  wangye
 * changes on test panel units and range
 *
 * Revision 1.37  2009/04/15 16:33:56  wangye
 * bug fixes on panel save code and datastore of panel tree
 *
 * Revision 1.36  2009/04/03 17:58:00  wangye
 * updated test panels for required field, units and answer_list
 *
 * Revision 1.35  2009/03/30 21:07:39  plynch
 * Changes to disable saved rows (part of controlled edit table changes.)
 *
 * Revision 1.34  2009/03/18 19:42:36  wangye
 * set unit field if there's one in the list
 *
 * Revision 1.33  2009/03/16 23:00:31  plynch
 * Gave the fields table stuff a namespace.
 *
 * Revision 1.32  2009/02/27 23:01:33  smuju
 * method to show data. faster than tootletooltip
 *
 * Revision 1.31  2009/02/26 20:51:47  wangye
 * rewrote test panel load, hide and display codes to improve js performance
 *
 * Revision 1.30  2009/02/25 21:43:51  plynch
 * Don't know.
 *
 * Revision 1.29  2009/02/25 00:10:37  wangye
 * added answer list for test panels
 *
 * Revision 1.28  2009/02/19 23:54:43  wangye
 * updates for test panel features
 *
 * Revision 1.27  2009/02/18 22:42:17  lmericle
 * testing comments
 *
 * Revision 1.26  2009/02/18 17:48:33  lmericle
 * added loading parameter to addTableLine call
 *
 * Revision 1.25  2009/02/12 23:33:55  lmericle
 * changes to speed up adding table lines for data loading.  not done yet
 *
 * Revision 1.24  2009/02/10 16:52:54  plynch
 * A fix for bullet list static_text fields (e.g. the rules page).
 *
 * Revision 1.23  2009/02/03 22:15:03  plynch
 * Changes related to fixing HTML encoding in error messages and static_text.
 *
 * Revision 1.22  2009/01/30 22:30:36  wangye
 * bug fixes for new test panels
 *
 * Revision 1.21  2009/01/30 16:20:46  wangye
 * replaced regexp with string comparision
 *
 * Revision 1.20  2009/01/29 22:40:56  wangye
 * test panel style changes
 *
 * Revision 1.19  2009/01/28 23:39:44  wangye
 * redesign of the test panels
 *
 * Revision 1.18  2009/01/14 00:16:08  plynch
 * Revised to support the setting of prefetched autocompleter lists.
 *
 * Revision 1.17  2008/10/24 21:34:31  wangye
 * bug fixes for IE7 and performance tune-up
 *
 * Revision 1.16  2008/10/23 18:21:06  smuju
 * toggle tooltip when setting value. in lieu of javasript onchange
 *
 * Revision 1.15  2008/10/16 20:41:33  lmericle
 * changed if/else clause related to adding lines to increase efficiency
 *
 * Revision 1.14  2008/09/25 21:22:12  lmericle
 * dataLoader - removed checkbox log output; no longer needed.  rules - removed set_fb_fields log output; no longer needed
 *
 * Revision 1.13  2008/09/18 21:18:12  lmericle
 * modified check_box loading; removed [CHECKED] flag
 *
 * Revision 1.12  2008/09/10 14:13:41  lmericle
 * fixes for checkboxes
 *
 * Revision 1.11  2008/08/06 23:42:06  plynch
 * A fix for tables with max_responses=1
 *
 * Revision 1.10  2008/07/24 21:51:19  yango
 * add datahash to the signup page to store user's input
 *
 * Revision 1.9  2008/07/07 18:45:41  wangye
 * add a new line in a table when load data only if the table allows multiple rows
 *
 * Revision 1.8  2008/05/01 14:49:52  lmericle
 * updates to set up nav keys and run rules once after all data loaded
 *
 * Revision 1.7  2008/04/03 16:45:17  plynch
 * Changes to get the save code working for the edit general rule page.
 *
 * Revision 1.6  2008/03/06 22:51:33  plynch
 * Initial changes for adding rule forms.
 *
 * Revision 1.5  2008/02/28 21:40:18  lmericle
 * change to write data to <DIV> as well as input field
 *
 * Revision 1.4  2008/02/12 22:06:57  lmericle
 * changed console statements to def.logger calls; splitAutoComp updates to TablePrefetch class
 *
 * Revision 1.3  2008/02/08 22:26:27  lmericle
 * changes for column display of strength and form data
 *
 * Revision 1.2  2008/01/15 20:54:16  lmericle
 * changes for data loading
 *
 * Revision 1.1  2008/01/09 23:14:58  lmericle
 * added
 *
 * 
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 */

Def.DataLoader = {};  // Namespace for the data loader code
 
/**
 *  Loads the data in the dataHash structure to the form
 * @param dataHash the hash table containing the data to be loaded
 * @param suffix the current field name suffix in use
 */
Def.DataLoader.loadData = function(dataHash, suffix) {

  // run through each name/value pair in the current
  // hash object.  If the value is NOT an array, load
  // it to the field named by the key (fdName). 

  var first_in_level = true ;
  var inputSuffix = suffix;  // suffix changes below
  for (var fdName in dataHash) {

    var hVal = dataHash[fdName];
    if (hVal != null) {
      var fdId = this.func_make_form_field_id(fdName, inputSuffix);
      var fmFld = $(fdId); 
      if (!fmFld) {
        // It turns out that the only case in which this is valid to occur
        // is when the value is a sub-hash, i.e., the fmFld is
        // field group.  In those cases (for some reason)
        // the field ID gets an extra _0.  So, we can slightly shorten
        // the processing time by making an assumption here.  If we can't
        // find the _0 field either, then we'll report an error.
        fmFld = $(fdId + '_0');
        if (!this.fieldMissing(fmFld, fdId)) {
          // Append a _ the suffix prior to processing the group data.
          if (first_in_level) {
            if (suffix == null)
              suffix = '_' ;
            else
              suffix += '_' ;
            first_in_level = false; 
          }
          
          // If the value is an array, this is a horizontal field group;
          // otherwise it is a hash and is for a vertical field group.
          if (hVal instanceof Array)
            this.processHorizontalGroup(fdName, hVal, fmFld, suffix);
          else
            this.loadData(hVal, suffix + '1'); // vertical group.
        }
      }
      else if (typeof hVal != 'object') {
        // hVal should be a string, or maybe a number (?).
        this.setFieldValue(fmFld, hVal);
       
        // add special handling for test panels
        // try to speed up by avoiding unnecessary regular expression comparison
        // performance gain not tested or confirmed yet
        if (fdName.substr(0,2) == 'tp') {
          this.setTestPanelStyle(fdName,fmFld,inputSuffix,hVal);  
        } // end of special handling for test panels
      } // end if the value is not an object (array or another hash)

      // check to see if this is a combo field that needs to be built (and
      // do so if it is).
      else if (hVal[0] == 'cmb_spec') {
        if (Def.Navigation.setFocusedFieldWrapper_ == null) {
          Def.Navigation.initWrappers() ;
        }
        fmFld.comboField.onDataReqComplete(hVal[2]) ;
        this.setFieldValue(fmFld, hVal[1]) ;
      }
      else {
        // The object should be an array.  Decide what to do with it.
        if (hVal.length > 1 && typeof hVal[1] != 'string') {
          // This is an array of data for a prefetched autocompleter field.

          var fieldVal = hVal[0];
          var listItems = hVal[1];
          var listCodes = hVal[2];
          Def.setFieldVal(fmFld, fieldVal, false) ;
          // add special handling for test panels
          // try to speed up by avoiding unnecessary regular expression comparison
          // performance gain not tested or confirmed yet
          if (fdName.substr(0,2) == 'tp') {
            this.setTestPanelStyle(fdName,fmFld,inputSuffix,fieldVal);
          }
          fmFld.autocomp.setList(listItems, listCodes);
        }
        else {
          // The last valid case is that this is an array of data for a
          // bulleted list.  We could check fmFld.hasClassName('bullet_list'),
          // but that might slow things down.  (For now, I'm not checking,
          // until we see a need for it.)

          // Make a bulleted, multi-column, static HTML list for this field.
          // The maximum row character length should be an attribute of the
          // field.
          var maxRowCharsStr = fmFld.readAttribute('maxRowChars');
          if (!maxRowCharsStr)
            var maxRowChars = 100; // a default
          else
            maxRowChars = parseInt(maxRowCharsStr);
          
          var htmlForList = this.makeBulletList(hVal, maxRowChars);
          fmFld.innerHTML = htmlForList;
        } // end else if the value is a bullet list
        //*/
      } // end else the value is an array
    } // end if the value is not null
  } // end do for each field name in the hash   

} // end loadData

// Additional DataLoader functions
Object.extend(Def.DataLoader, {
  /**
   *  Cache a reference to function toggleTipMessages for efficiency.
   */
  // func_toggleTipMessages: toggleTipMessages,
  /**
   *  Cache a reference to function make_form_field_id for efficiency.
   */
  func_make_form_field_id: make_form_field_id,
  /**
   *  Cache a reference to function htmlEncode for efficiency.
   */
  func_htmlEncode: htmlEncode,
  
  /**
   *  Cache a reference to function limitedHtmlEncode for efficiency.
   */
  func_partialHtmlEncode: Def.partialHtmlEncode.bind(Def),
  

  /**
   *  Reports an error if the given field object is null.
   * @param fmFld the DOM field object
   * @param fdId the field ID
   * @return true if the field is not null
   */
  fieldMissing: function(fmFld, fdId) {
    if (!fmFld) {
      Def.Logger.logMessage(['data loading error 1, ',
                             'could not find form field ', fdId]) ;
      // I'm not really sure we want to set the status here-- we should
      // probably show a popup, but we can sort that out later.  (This is
      // the code that was here.)
      window.status = "data loading error, could not find form field " +
                        fdId ;
      return true;
    }
    else {
      return false;
    }
  },
  
  
  /**
   *  Change group header text value to test panel name and set style class
   *  for test items
   * @param fdName the field's target_field
   * @param fmFld the DOM field object
   * @param inputSuffix the suffix of the DOM field object
   * @param hVal the value of the field
   */
  setTestPanelStyle: function(fdName, fmFld, inputSuffix, hVal) {
    // 'tp_invisible_field_panel_name'
    // rewrite it to avoid the regular expression
    //    var matched = fdName.match(/^tp([0-9]*)_invisible_field_panel_name$/);
    //    if (matched) {
    //      var p_sn = matched[1];
    var index = fdName.indexOf('_');
    var p_sn = fdName.substr(2,index-2);
    var str_field = fdName.substr(index);
    if (str_field == '_invisible_field_panel_name' ) {
      // 'tp_loinc_panel_temp'
      var test_panel_grp_id = this.func_make_form_field_id(
            'tp' + p_sn +'_loinc_panel_temp', inputSuffix + '_0');
      var p_ele = $(test_panel_grp_id).parentNode.parentNode.parentNode;
      var s_eles = p_ele.getElementsBySelector('#' + test_panel_grp_id);
      var h_ele = s_eles[0].down('span');
      h_ele.innerHTML = hVal;
    }
    // set class based on display_level value
    // 'tp_test_disp_level'
    // rewrite it to avoid the regular expression
    //    if (fdName.match(/^tp[0-9]*_test_disp_level$/)) {
    else if (str_field == '_test_disp_level' ) {
      var t_ele = $(fmFld.parentNode.parentNode);
      var display_class = '';
      var level = parseInt(hVal);
      switch (level) {
        case 1:
          display_class = 'panel_l1';
          break;
        case 2:
          display_class = 'panel_l2';
          break;
        case 3:
          display_class = 'panel_l3';
          break;
        case 4:
          display_class = 'panel_l4';
          break;
        case 5:
          display_class = 'panel_l5';
          break;
        default:
          display_class = 'panel_l1';
      }
      t_ele.addClassName(display_class);
    }
    // set class based on required_in_panel value
    else if (str_field == '_test_required_in_panel') {
      $(fmFld).addClassName('required_in_panel');
      var elemRow = $(fmFld.parentNode.parentNode);
      if ( hVal == true) {
        elemRow.addClassName('test_required');
      }
      else {
        elemRow.addClassName('test_optional');
        // setting style.display='none' is required for the
        // isHiddenOrDisabled function to work
        if (!elemRow.hasClassName('containsRecovered')) {
          elemRow.style.display='none';
        }
        /* make the more button visiable when there are optional tests */
        /* in style.css this div, with class of .panel_buttons is set to */
        /* display:none initially */
        var button_id =  this.func_make_form_field_id(
            'tp' + p_sn +'_button_row',inputSuffix);
        button_id = button_id.gsub(/_[0-9]+$/,'_0');
        var opt_button = $(button_id);        
        if (opt_button) {
          opt_button.style.display ='block';
        }
      }
    }
    // set class based on is_panel_hdr value
    // 'tp_test_is_panel_hdr'
    // rewrite it to avoid the regular expression
    //    if (fdName.match(/^tp[0-9]*_test_is_panel_hdr$/) && hVal == true) {
    else if (str_field == '_test_is_panel_hdr' && hVal == true) {
      var eleRow = $(fmFld.parentNode.parentNode);
      eleRow.addClassName('panel_header');
      // hide the cells in the panel header row
      // except the loinc name field
      // use visibility='hidden', instead of display='none'
      // reset the attribute on TD, not Input fields, because navigation
      // functions upInTable and downInTable only check TD's visibility using
      // function isHiddenOrDisable()
      var eleTDs = eleRow.getElementsBySelector('td');
      var ele_len = eleTDs.length;
      for(var i=0; i< ele_len; i++) {
        var eleInput = $(eleTDs[i]).getElementsBySelector('input[type=text],textarea')[0];
        if (eleInput != null && !eleInput.id.match(/_test_name_/)) {
          //eleInput.addClassName('hidden_field');
          eleTDs[i].style.visibility = 'hidden';
        }
      }
    }
    // hide units and range if data_type is 'CWE' or 'CNE'
    // do not disable them. now there's a rule that will enable/disable all the
    // field depending on whether the when done field has value or not.
    else if (str_field == '_test_data_type' && (hVal == 'CWE' || hVal == 'CNE')) {
      var ids = Def.IDCache.splitFullFieldID(fmFld.id);
      var eleUnit = $(ids[0] + 'tp' + p_sn + '_test_unit' + ids[2]);
      //eleUnit.disabled = true;
      eleUnit.style.display = 'none';
      eleUnit.removeClassName('inlineedit');
      var eleRange = $(ids[0] + 'tp' + p_sn + '_test_range' + ids[2]);
      // no range fields on flowsheet page
      if (eleRange) {
        //eleRange.disabled = true;
        eleRange.style.display = 'none';
        eleRange.removeClassName('inlineedit');
      }
    }
  }, // end setTestPanelStyle
  

  /**
   *  Assigns a value to a field.
   * @param fmFld the DOM field object whose value is to be set.
   * @param fieldVal the field value
   */
  setFieldValue: function(fmFld, fieldVal) {
    if (fmFld != null) {
      if (fmFld.type == 'checkbox') {
        var cbVal = fmFld.readAttribute('value') ;
        if (cbVal != null && cbVal == fieldVal) {
          fmFld.setAttribute('checked',true) ;
        }
        else {
          fmFld.setAttribute('checked',false) ;
        }  
        // Do NOT write a value to the field.  Checkbox "values" are
        // the values to be returned when the user either checks or 
        // doesn't check the box.  Because of the way the input 
        // field is specified, if you write a value to the field,
        // it usually ends up overwriting the "yes" value with the
        // "no" value.  Don't do that.
      }
      else {
        Def.setFieldVal(fmFld, fieldVal, false) ;
      } // end if it is/isn't a div or a checkbox to be checked         
    } // end if we found the field

    else {
      if (window.addEventListener)
        Def.Logger.logMessage(['data loading error 2, ',
                               'could not find form field ', fdId]) ;
      else if (window.attachEvent)
        window.status = "data loading error, could not find form field " +
                        fdId ;
    }
  },
  

 /**
   *  Processes the data for a horizontal field group.
   * @param hVal the sub-data hash for the group of fields
   * @param group_hdr the field group header field
   * @param suffix the part of the field ID suffix currently known
   */
  processHorizontalGroup: function(fdName, hVal, group_hdr, suffix) { 
    var table = group_hdr.down('table');

    // The max_responses from the group header is a string that needs
    // to be converted to an integer.  Default is 0 if it's not there.
    var maxResponses = 0 ;
    if (group_hdr.readAttribute) {
      // If this is a test panel, call a separate function to determine
      // the max responses value for the panel.
      // try to speed up by avoiding unnecessary regular expression comparison
      // performance gain not tested or confirmed yet
      if (fdName.substr(0,2) == 'tp') {
        maxResponses =Def.DataModel.setTestPanelMaxResponses(fdName, group_hdr,
                                                     maxResponses, hVal.length);
      } 
      else {
        maxResponses = parseInt(group_hdr.readAttribute('max_responses'));
        if (isNaN(maxResponses))
          maxResponses = 0 ;
      }    
    }

    // Get the number of existing rows in the table
    var numExistingRows = parseInt(table.readAttribute('nextid')) - 1;
    var numRows = hVal.length;
    var numToAdd = numRows - numExistingRows ;
    var addBlankRow =
      maxResponses == 0 || (numToAdd + numExistingRows) < maxResponses
    if (addBlankRow)
       numToAdd += 1 ;
    else // maxResponses != 0 && numToAdd + numExistingRows >= maxResponses
      numToAdd = maxResponses - numExistingRows ;
    if (group_hdr.ce_table !== undefined) {
      group_hdr.ce_table.createReadOnlyRows(table, numRows);
      if (addBlankRow)
        Def.FieldsTable.addTableLine(table, null, 1, true);
    }
    else
      Def.FieldsTable.addTableLine(table, null, numToAdd, true) ;
    for (var i = 0; i < numRows && ((maxResponses == 0) ||
                                    (i < maxResponses)); ++i) {
      // need to check the number of existing rows : numExistingRows
      // only insert a new row when numRows > numExistingRows
      //  not to assume there's always one empty row only.
      //if (i != 0) {
      //if (i >= numExistingRows) {
      //  addTableLine(table, null, true);
      //}
      var indexedSuffix = suffix+(i+1);
      this.loadData(hVal[i], indexedSuffix);
    } // end do for each element in the array

    // See if we should add one more line
    //if (maxResponses == 0 || numRows < maxResponses)
    //  addTableLine(table, null, true);
  }, // end processHorizontalGroup

            
  /**
   *  Returns the HTML for a multi-column bulleted list.
   * @param listItems a list of strings that comprise the list
   * @param the maximum number of characters in a row.  Set this to zero
   *  if you only want one column.
   */
  makeBulletList: function(listItems, maxRowChars) {
    var listMatrix = this.getBulletListMatrix(listItems, maxRowChars);
    var numCols = listMatrix.size();
    var output = ''
    for (var col=0; col<numCols; ++col) {      
      output += '<div class="bullet_list_column"><ul>'
      var column = listMatrix[col];
      var numRows = column.size();
      for (var row=0; row<numRows; ++row) {
        output += '<li>'+column[row]+'</li>'
      }
      output += '</ul></div>'
    }
    return output;
  },
  
  
  /**
   *  Divides up a list of items into columns, according to a specified
   *  maximum character width for a row.
   * @param listItems a list of strings that comprise the list
   * @param the maximum number of characters in a row.  Set this to zero
   *  if you only want one column.
   * @return an array of arrays.  The first index is for the columns, and the
   *  second is row the rows (the opposite of the usual order).
   */
  getBulletListMatrix: function(listItems, maxRowChars) {
    var totalLength = 0
    var numItems = listItems.size();
    var itemLengths = new Array(numItems);
    for (var i=0; i<numItems; ++i) {
      itemLengths[i] = listItems[i].length;
      totalLength += itemLengths[i];
    }
    var numCols;
    if (numItems == 0)
      numCols = 0
    else {
      var avgLength = totalLength/numItems;
      numCols = Math.ceil(maxRowChars/avgLength);
    }
    
    // Find the actual maximum row length using num_cols rows and see if it is
    // too long.  If it is too long, decrease num_cols and try again.
    var maxRowLength = maxRowChars + 1;
    numCols += 1;
    while (numCols > 1 && maxRowLength > maxRowChars) {
      numCols -= 1
      maxRowLength = 0
      var numRows = Math.ceil(numItems/numCols);
      // Now we might need to adjust the number of columns.  For example,
      // if you have 10 items and try 9 columns, you need two rows, but
      // since we are filling column by column, if you have two rows, you
      // only need 5 columns.
      numCols = Math.ceil(numItems/numRows);

      for (var row=0; row<numRows; ++row) {
        var rowSize=0;
        for (var col=0; col<numCols; ++col) {
          var cellIndex=row + col*numRows;
          if (cellIndex < numItems)
            rowSize += itemLengths[cellIndex];
        }
        if (rowSize > maxRowLength)
          maxRowLength = rowSize;        
      }
    }
    
    // If numCols exceeds the number of items, shorten it to match.
    if (numCols > numItems)
      numCols = numItems;
    
    // At this point, numCols should be the number of columns we want,
    // and we can output the matrix.
    var output = new Array(numCols);
    for (i=0; i<numCols; ++i)
      output[i] = [];
    numRows = Math.ceil(numItems/numCols);
    for (i=0; i<numItems; ++i)
      output[Math.floor(i/numRows)].push(listItems[i]);
    return output;
  }
     
});

