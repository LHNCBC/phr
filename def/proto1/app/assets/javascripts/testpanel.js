/**
 * testpanel.js --> A class to dynamically add/remove test panels.
 *
 * $Id: testpanel.js,v 1.127 2011/08/22 21:22:45 lmericle Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/testpanel.js,v $
 * $Author: lmericle $
 *
 * Revision 1.1  2008/04/07 14:10:30  wangye
 * initial version
 */
//global object and initial properties
var TestPanel = {
  // if empty rows in data sheet are shown
  emptyRowsShown:true,

  // if panel info rows in data sheet are shown
  panelDataShown:true,

  // the popup menu on data sheet
  contextMenu_: null,

  // current seleted panel record's obr_order_id
  selectedObrId: null,
  // current seleted panel record's panel loinc_num
  selectedObrPanelLoincNum: null,
  // the panel definition's loinc_num that current seleted panel record is
  // contained in the the flow sheet table
  selectedPanelLoincNum: null,

  // the sequene number used for creating element id when a panel record is
  // opened for edit
  // it is 1 when there's a hidden panel group included, otherwise it is 0
  panelEditBoxSN: 1,

  // search condition cached for data sheet refresh
  searchConditions: {
    groupByCode: null,
    dataRangeCode : null,
    dateStart: null,
    dateEnd: null,
    dateEndStr: null,
    loincNums: [],
    combined: null,
    includeAll: null
  },

  // test's common units and no_data information for each panel
  // {p_loinc_num: [{obr_id:{loincNum:
  //                         testName:
  //                         commomUnits:
  //                         numOfRecords:
  //                         chartData: {normal_range: {max:, min:},
  //                                     orders: [obrId, ...],
  //                                     type:,
  //                                     values: [x:y, ...]
  //                                    }
  //                        },
  //                 ...
  //               ]
  //  ...
  //  }
  panelInfo: {},

  // if any column is in edit mode
  inEditMode: false,

  // if any data is displayed on the flowsheet
  dataLoaded: null,

  // if the ajax call has returned (when editing)
  ajaxDone: true,


  // a cloned copy of taffydb data of panels opened for edit or deleted in place
  // {obrId: {obr_db: hash of the obr_data_table record,
  //           obx_db: array of the obx_data_table records}
  // }
  originalPanelDbRecords: {},

  // current status of columns that are deleted or in editing
  // {obrId => array of the status of ('deleted' | 'in_edit' | 'unchanged')}
  // the status and its available menu items
  // ['unchnaged'] or NULL  ===> new|edit|edit in place| delete
  // ['deleted']            ===> new|undo delete
  // ['in_edit']            ===> new|delete|undo edit
  //
  columnDataStatus: {},

  // sequence numbers used in the field ids of the editable column
  // numbers are kept even if the 'edit' is cancelled, so that when the panel
  // record is in 'edit' mode again there's no need to recreate the edit box
  columnEditBoxSN: {},

  /**
   *  A dialog for a warning message.
   */
  fsWarningDialog_: null,

  fsConfirmingDialog_: null,

  /**
   *  A dialog for the charts.
   */
  chartDialog_: null,

  // columns status constants
  COLUMN_STATUS_INEDIT    : 'in_edit',
  COLUMN_STATUS_DELETED   : 'deleted',
  COLUMN_STATUS_UNCHANGED : 'unchanged',

  // panel info field names
  PANEL_INFO_FIELD_NAMES: {
    test_date: 'When Done',
    test_date_time: 'When Done Time',
    test_place: 'Where Done',
    summary: 'Comment',
    due_date: 'Due Date'
  },

  // number of rows in data sheet for panel info
  // panel name, comment, where done and due date
  PANEL_INFO_ROW_NUM: 4,

  // has panel list
  hasPanelList: null,

  // has any panel selected in the panel list
  hasPanelSelected: null,

  // options set for the add tests and measures popup window
  popupOption: {},

  // options for updating the panel list on the flow sheet page.
  // initial values are set by the code in _panel_static_table.rhtml when
  // the page is loaded.
  panelListOption: {
    fdID: null,
    colNum:null,
    btnID: 'fe_show_record_too_1',
    listID: null,
    dataURL: null
  },

  // Plot data
  Flot : {
    // options for all displayed test panels records

    // data for sparkling/plot of all records
    // updated when records are deleted or revised
    // example:
    // { obr_loinc_num1 : { 'orders' : [ obr_id1, obr_id2, ,,,]
    //                      'values' : [ [ test_loinc_num,
    //                                    [value1:time1, value2:time2, ...]
    //                                   ]
    //                                   //other tests
    //                                   ....
    //                                 ]
    //                    },
    //   //other panels
    //   obr_loinc_num2 : ...
    // }
    //
    chartData: {},

    // options for creating one plot
    // plot data
    plotData: [],
    plotOption: {},
    plotOptions: [],

    yaxisOptions: [],

    // overview data
    overviewData: [],
    overviewOption: {},

    // div elements that contain the chart
    chartEles: [],
    // the flot objects
    flots: [],
    numOfPlots: null,
    // the overview flot object
    overviewFlot: null,

    // Colors used by series in the plot chart
    lineColors: ['#024769','#AFD775','#2C5700','#DE9D7F', '#EFD279','#95CBE9'],
    //lineColors: ['#663300','#996633','#CC6600','#CC9966','#FF9933','#FF9900'],
    //lineColors: ['#2B3E42', '#747E80','#D5E1DD', '#F7F3E8', '#F2583E', '#77BED2'],
    // extra data associated with the data point, for a plot chart with multiple
    // data series
    // x.to_s + y => [units, min, max]
    chartDataExtra: {},

    previousPoint: null

  }
};


/**
 * reset variables
 * called data sheet is refreshed
 */
TestPanel.resetVariables = function() {

  TestPanel.emptyRowsShown = true;
  TestPanel.panelDataShown = true;

  TestPanel.selectedObrId = null;
  TestPanel.selectedPanelLoincNum = null;
  TestPanel.selectedObrPanelLoincNum = null;
  TestPanel.selectedObrPName = null;

  TestPanel.panelEditBoxSN = 1; // when there's a hidden panel group included
                                // otherwise it is 0

  TestPanel.searchConditions = {
    groupByCode: null,
    dataRangeCode : null,
    dateStart: null,
    dateEnd: null,
    dateEndStr: null,
    loincNums: [],
    combined: null,
    includeAll: null
  };
  TestPanel.inEditMode = false;
  TestPanel.ajaxDone = true;
  TestPanel.dataLoaded = null;
  TestPanel.columnEditBoxSN = {};
  TestPanel.originalPanelDbRecords = {};
  TestPanel.columnDataStatus = {};
  TestPanel.panelInfo ={};
};


/**
 * add a test panel template on the panel_edit form
 * @param ele the 'Add' button
 */
TestPanel.addPanel = function(ele) {

  // in the search group
  if (ele.id == 'fe_add_panel_1') {
    var textEle = $('fe_new_panel_list_1');
    var codeEle = $('fe_new_panel_list_C_1');
  }
  // in the browse group
  else {
    textEle = $('fe_panel_in_class_1');
    codeEle = $('fe_panel_in_class_C_1');
  }
  // get the loinc number of the selected panel
  var pLoincNum = codeEle.value.strip();

  if (pLoincNum == "") {
    TestPanel.showWarning (
      'Panel/Test field is empty. Please pick a panel or test first.',
      'Warning');
  }
  else {
    TestPanel.attachAPanel(pLoincNum, textEle, codeEle);
  }

};


/** Attach a panel template at the bottom of the panel_edit form
 * @param pLoincNum the panel's loinc_num
 * @param textEle optional, the panel field when the function call is originated
 *        from the 'add' button
 * @param codeEle optional, the hidden loinc number field when the function call
 *        is originated from the 'add' button
 */
TestPanel.attachAPanel = function(pLoincNum, textEle, codeEle) {
    var panelGrpContainer = $('fe_tp1_loinc_panel_temp_grp_0');
    var idParts = Def.IDCache.splitFullFieldID(panelGrpContainer.id);
    var fdSuffix = idParts[2];
    // remove the last '_0' part if there's one, see Def.DataLoader.loadData
    fdSuffix = fdSuffix.replace(/_0$/, '');
    var matched = idParts[1].match(/^tp([0-9]*)_loinc_panel_temp_grp$/);
    if (matched) {
      var panelSeqNo = matched[1];
    }

    var maxResponses = parseInt(panelGrpContainer.readAttribute('max_responses'));
    // fetch the panel template and insert it into the form
    TestPanel.getSelectedPanel(pLoincNum, maxResponses, fdSuffix,
      panelSeqNo, panelGrpContainer, null, null, textEle, codeEle);
};

/**
 * preview a panel's structure or a test's detail
 * @param ele the 'Details' button
 */
TestPanel.previewPanel = function(ele) {

  // in the search group
  if (ele.id == 'fe_preview_panel_1') {
    var codeEle = $('fe_new_panel_list_C_1');
  }
  // in the browse group
  else {
    codeEle = $('fe_panel_in_class_C_1');
  }

  var loincNum = codeEle.value.strip();
  if (loincNum == "") {
    TestPanel.showWarning(
      'Panel/Test field is empty. Please pick a panel or test first.',
      'Warning');
  }
  else {
    TestPanel.popupDetailPage(loincNum);
  }
};


/**
 * display a details page for a test from the loinc.org
 * @param loincNum  the test's loinc_num
 */
TestPanel.popupDetailPage = function(loincNum) {

  var title = "Panel/Test Details";
  // show a local msg for the local defined loinc_num
  if (loincNum.match(/^X/)) {
    var strText = "Locally defined LOINC item. Details will be added soon.";
    // only specify the window options that differ from the defaults
    var winProp = "menubar=no,width=400,height=200";
  }
  else {
    strText = "http://s.details.loinc.org/LOINC/" + loincNum + ".html";
    // only specify the window options that differ from the defaults
    winProp = "menubar=no,width=640,height=480";
  }
  // this popup should not be modal.
  openPopup(null, strText, title, winProp, 'panelDetails',
            true, false);
}

/**
 * remove a test panel template
 * @param ele the 'remove' button
 */
TestPanel.removePanel = function(ele) {

  // to be finished

  // check if data has been saved

  // check if data has been entered

  // if data saved, not changed afterward
  //    ask 'data has been saved, do you also want to delete saved data?' yes/no/cancel
  // if data saved, and changed afterword
  //    ask 'new chagnes have not been saved, do you want to delete previous saved data?' yes/no/cancel
  //    if no is seleted
  //      ask 'new changes has not been saved, do you want to save the changes?' yes/no/cancel
  // if data not saved, but entered
  //    ask 'data has not been saved, do you want to save it?' yes/no/cancel
  // if data not saved, or entered
  //    no question asked

  // clean up data in the template using setFieldVal, which also cleans up data in taffydb

  // hide the panel template
  var eleTD = ele.up().up().up().up();
  eleTD.style.display='none';

// for now, do not touch data, just hide the panel

};

/**
 * get a selected panel structure, with or without data, from server
 * @param loincNum an optional loinc_num of the selected panel. if provided,
 *        panel's loinc number will not come from a form field
 * @param maxResponses numbers of existing panels already displayed in the
 *        container group
 * @param suffixPrefix a string in the suffix before the panel stucture suffix
 *        pattern
 * @param panelSeqNo optional, a sequence number for panel container groups,
 *        default is 1, meaning there's only one container on the form
 * @param panelGrpContainer the div element of the panel container where the
 *        panel structure is added in
 * @param profileIdShown optional, a profile's id shown on client side
 * @param obrId optional, an obr_orders record's id
 * @param textEle optional, the panel field when the function call is originated
 *        from the 'add' button
 * @param codeEle optional, the hidden loinc number field when the function call
 *        is originated from the 'add' button
 */
TestPanel.getSelectedPanel = function(loincNum, maxResponses,suffixPrefix,
  panelSeqNo, panelGrpContainer, profileIdShown, obrId, textEle, codeEle) {

  Def.showLoadingMsg();

  new Ajax.Request('/form/get_loinc_panel_data', {
    method: 'post',
    parameters: {
      authenticity_token: window._token,
      p_num: loincNum ,
      p_seqno: panelSeqNo || '1' ,
      p_skip: maxResponses ,
      p_form_rec_id: profileIdShown || Def.DataModel.id_shown_ ,
      obr_index: Def.DataModel.getRecCount(Def.DataModel.OBR_TABLE) ,
      obx_index: Def.DataModel.getRecCount(Def.DataModel.OBX_TABLE) ,
      suffix_prefix: suffixPrefix ,
      obr_id: obrId || '',
      form_name: Def.DataModel.form_name_
    } ,
    onSuccess: showResponse,
    on404: function(t) {
      Def.hideLoadingMsg();
      alert("The data you were looking for doesn't exist.");
    },
    on500: function(t) {
      Def.hideLoadingMsg();
      if (t == 'do_logout') {
        window.location = Def.LOGOUT_URL ;
      }
      else {
        alert("We're sorry, but something went wrong. " +
            "We've been notified about this issue and we'll take a look at it shortly. ");
      }
    },
    onFailure: function(t) {
      Def.hideLoadingMsg();
        alert("We're sorry, but something went wrong. " +
            "We've been notified about this issue and we'll take a look at it shortly. ");
    }

  }) ;

  // a call back function
  function showResponse(response) {
    try {
      var taffyDbData = JSON.parse(response.responseText);

      // load data into taffy db and form
      var dataModel = Def.DataModel;
      if (dataModel.initialized_) {
        dataModel.append(taffyDbData);
      }
      else {
        dataModel.setup(taffyDbData);
      }
      Def.AutoSave.resetData(null, true, false) ;
      dataModel.setAutosave(true) ;

      // remove the border line in the container's table
      var table = panelGrpContainer.down('table');
      table.setAttribute('border', '0');

      // add required field validation listeners
      var tmp = $A(panelGrpContainer.getElementsByTagName("tr")).last();
      tmp = getAncestor(tmp, "TR");
      var reqFlds = tmp.getElementsBySelector(
        'input[required]:not(.hidden_field)');
      var validReqFld = null;
      for (var i=0, max = reqFlds.length; i< max && !validReqFld; i++){
        if (!isHiddenOrDisabled(reqFlds[i], true)){
          validReqFld = reqFlds[i];
        }
      }
      if (validReqFld) {
        var validation = Def.Validation.RequiredField.Functions;
        var newLineFields = validation.findLineFields(validReqFld)[2];
        validation.enableValidationOnNewLine(newLineFields);
      }

      // Empty the input box of new panel
      if (textEle && codeEle) {
        Def.setFieldVal(textEle, "");
        Def.setFieldVal(codeEle, "")
      }

      // Show tooltips again
      setTipFields();

      // set classes for stripes on tests
      TestPanel.setStripeCssClass();

      var panels = panelGrpContainer.getElementsBySelector("div.panelGroup.fieldGroup");
      var panel_pos = Def.findScreenPosition(panels[panels.length -1]);
      // show the panel in the view in case it's hidden
      window.scroll(0, panel_pos[1]-35);
      // show the test panel group
      panelGrpContainer.style.display = "block";

      Def.hideLoadingMsg();

    }
    catch (e) {
      Def.Logger.logException(e);
    }
  }
}; // end getSelectedPanel


/**
 * create an 'editable' format for a selected panel record
 * @param profileIdShown user's profile id_shown
 * @param pLoincNum LOINC num of the selected panel
 * @param obrId id of the selected panel's record
 * @param editInPlace a flag indicates whether it is 'edit in place' or
 *        'delete in place
 */
TestPanel.getPanel4Edit = function(profileIdShown, pLoincNum, obrId,
  editInPlace) {

  Def.showLoadingMsg();

  var pSN = TestPanel.panelEditBoxSN++;
  var startLoad_ = new Date().getTime();
  var suffixPrefix = '';

  // set the flag to avoid possible changes in the SelectedObrId and etc
  // if user clicks other columns before the ajax returns.
  TestPanel.ajaxDone = false;
  new Ajax.Request('/form/get_loinc_panel_data', {
    method: 'post',
    parameters: {
      authenticity_token: window._token ,
      p_num: pLoincNum,
      p_seqno: '1' ,
      p_skip: pSN ,
      p_form_rec_id: profileIdShown || Def.DataModel.id_shown_ ,
      obr_index: Def.DataModel.getRecCount(Def.DataModel.OBR_TABLE) ,
      obx_index: Def.DataModel.getRecCount(Def.DataModel.OBX_TABLE) ,
      suffix_prefix: suffixPrefix ,
      obr_id: obrId ,
      form_name: Def.DataModel.form_name_
    } ,
    onSuccess: showResponse4Edit,
    on404: function(t) {
      Def.hideLoadingMsg();
      alert('Error:   Panel ' + panelName + ' was not found!');
      TestPanel.ajaxDone = true;
    },
    on500: function(t) {
      Def.hideLoadingMsg();
      if (t == 'do_logout') {
        window.location = Def.LOGOUT_URL ;
      }
      else {
        alert('Error ' + t.status + ' -- ' + t.statusText) ;
      }
      TestPanel.ajaxDone = true;
    },
    onFailure: function(t) {
      Def.hideLoadingMsg();
      alert('Error ' + t.status + ' -- ' + t.statusText);
      TestPanel.ajaxDone = true;
    }
  }) ;

  // a call back function
  function showResponse4Edit(response) {
    try {
      var taffyDbData = JSON.parse(response.responseText);

      var obrRecord = taffyDbData[0][Def.DataModel.OBR_TABLE][0];
      var obxRecords = taffyDbData[0][Def.DataModel.OBX_TABLE];

      // keep the original records before data is loaded on form when the
      // answer lists are removed
      TestPanel.keepOriginalRecords(obrId, taffyDbData);

      // if edit, create the input boxes first so that data will be loaded into
      // the input field when dataModel is set up
      if (editInPlace) {
        // create fields in the selected column before loading the data
        TestPanel.createTestEditBox(obrRecord, obxRecords, pSN);
      }
      // load data into taffy db and form
      var dataModel = Def.DataModel;
      if (dataModel.initialized_) {
        dataModel.append(taffyDbData, false);
      }
      else {
        dataModel.setup(taffyDbData,false);
      }
      Def.AutoSave.resetData(null, true, false)
      dataModel.setAutosave(true) ;

      // edit
      if (editInPlace) {
        // update column status
        TestPanel.columnDataStatus[obrId] = TestPanel.COLUMN_STATUS_INEDIT;
      }
      // delete
      else {
        // answer lists are removed in the copying over data from the
        // original records to the live records
        TestPanel.restoreFromOriginalRecords(obrId, true);
        // update record_id
        TestPanel.updateObrObxRecordId(obrId, true);
        // add line-through
        TestPanel.addLineThrough(obrId);
        // update column status
        TestPanel.columnDataStatus[obrId] = TestPanel.COLUMN_STATUS_DELETED;
      }

      // record the panel sn
      TestPanel.columnEditBoxSN[obrId] = pSN;

      // show the save/cancel buttons
      TestPanel.showHideSaveButtons();
      // set the flag
      TestPanel.inEditMode = true;
      // rerun form rules
      Def.Rules.runFormRules();

      Def.hideLoadingMsg();

      // display loading time
      var msgDiv = $('fe_load_time_td');
      // no toolbar in popup mode
      if (msgDiv) {
      var time = 'Panel data loaded in ' +
        (new Date().getTime() - startLoad_)/1000 + ' seconds';

        msgDiv.innerHTML = time;
        setTimeout("$('fe_load_time_td').innerHTML=''", 15000);
      }
      TestPanel.ajaxDone = true;
    }
    catch (e) {
      Def.Logger.logException(e);
      TestPanel.ajaxDone = true;
    }
  }
}; // end getPanel4Edit

/**
 * hide or show optional tests
 * @param el the action button
 */
TestPanel.toggleOptTests = function(el) {

  //the tbody element above the button
  var tbody = el.parentNode.parentNode.parentNode.parentNode.parentNode;
  //tbody = el.parentNode.parentNode.parentNode.parentNode.parentNode;
  //find all the 'required_in_panel' input element within the table
  var requiredTests = tbody.select('input.required_in_panel');
  var l = requiredTests.length;
  var imageSrc =el.src;
  for (var i=0; i<l; i++) {
    var requiredValue = requiredTests[i].value;
    var trEle = requiredTests[i].parentNode.parentNode;
    var hasRequiredClass = trEle.hasClassName('test_required');
    var hasOptionalClass = trEle.hasClassName('test_optional');
    if (requiredValue == 'false') {
      if (hasRequiredClass) {
        trEle.removeClassName('test_required');
        trEle.addClassName('test_optional');
        // setting style.display='none' is required for the
        // isHiddenOrDisabled function to work
        trEle.style.display='none';
        el.firstChild.innerHTML = 'Show More';
        el.addClassName('show_more') ;
        el.removeClassName('show_less') ;
      }
      else if (hasOptionalClass) {
        trEle.removeClassName('test_optional');
        trEle.addClassName('test_required');
        trEle.style.display='table-row';
        el.firstChild.innerHTML = 'Show Less';
        el.addClassName('show_less') ;
        el.removeClassName('show_more') ;
      }
    }
  }
  // do not use $(el), el is an image without id
  el.src = imageSrc;

  // set classes for stripes on tests
  TestPanel.setStripeCssClass();

}; // end toggleOptTests


/**
 * Set a class for CSS settings of stripes on the tests
 */
TestPanel.setStripeCssClass = function() {
  var containerGroup= $$('div.panelGroupContainer.fieldGroup');
  if (containerGroup.size() > 0) {
    var panelGroups = containerGroup[0].select('div.panelGroup.fieldGroup');
    for (var j=0, jlen=panelGroups.length; j<jlen; j++ ) {
      var visibleTestRows= panelGroups[j].select('tr.repeatingLine.test_required');
      for (var i=0, ilen=visibleTestRows.length; i<ilen; i++) {
        if (i % 2 == 0) {
          visibleTestRows[i].removeClassName('odd_row');
          visibleTestRows[i].addClassName('even_row');
        }
        else {
          visibleTestRows[i].removeClassName('even_row');
          visibleTestRows[i].addClassName('odd_row');
        }
      }
    }
  }
};


/**
 * replace the element with the html text in the all panel list div
 * @param newHtmlText the new html content
 */
TestPanel.replacePanelList = function(newHtmlText) {
  var ele = $(TestPanel.panelListOption.listID);

  var parentEle = ele.parentNode;
  var newDiv = document.createElement("div");
  newDiv.innerHTML = newHtmlText;
  newDiv.setAttribute("id",TestPanel.panelListOption.listID);
  parentEle.replaceChild(newDiv, ele);
  Def.IDCache.addToCache(parentEle);
  // reset navigation sequence, not event listeners
  Def.Navigation.doNavKeys(0,0,true,true,true);

  // check if there are any panels listed
  var noPanel = newDiv.select("div.no-panel");
  if (noPanel.length > 0 ) {
    // no panel, hide options, buttons and instructions
    $('check_all_div').style.display = 'none';
    $('fe_panel_list_grp_ins_0').style.display = 'none';
    //    $('fe_option_grp_1_0').style.display = 'none';
    //    $('fe_show_record_too_1').style.display = 'none';
    //    $('in_one_grid_1_div').style.display = 'none';
    //    $('include_all_1_div').style.display = 'none';
    TestPanel.hasPanelList = false;
  }
  else {
    // has panels, show options, buttons and instructions
    $('check_all_div').style.display = 'inline';
    $('fe_panel_list_grp_ins_0').style.display = 'block';
    //    $('fe_option_grp_1_0').style.display = 'block';
    //    $('fe_show_record_too_1').style.display = 'inline';
    //    $('in_one_grid_1_div').style.display = 'inline';
    //    $('include_all_1_div').style.display = 'inline';
    TestPanel.hasPanelList = true;
    // set a correct checkbox status
    TestPanel.checkCheckAll();
  }
}; // end replacePanelList


/**
 * validate when done value to be not empty
 *
 */
TestPanel.validateWhenDoneValue = function() {

  var valid = true;
  var invalidFieldIdx = [];
  var obrRecords = Def.DataModel.data_table_['obr_orders'];
  for(var i=0, len = obrRecords.length; i<len; i++) {
    if (obrRecords[i]['test_date'] == null ||
        obrRecords[i]['test_date'] == '') {
      invalidFieldIdx.push(i);
    }
  }
  var length = invalidFieldIdx.length;
  if (length > 0) {
    valid = false;
    for(var j=0; j<length; j++) {
      var dbKey = 'obr_orders' + Def.DataModel.KEY_DELIMITER +
          'test_date' + Def.DataModel.KEY_DELIMITER + (invalidFieldIdx[j]+1);
      var fieldId = Def.DataModel.mapping_table_db_[dbKey];
      //alert( fieldId + " can not be empty");
      Def.Validation.RequiredField.ErrDisplay.outlineErrField($(fieldId));
    }
  }
  return valid;
}

/**
 * Get the value of the text node
 * @param el an html elemt
 */
TestPanel.getInnerText = function(el) {
  // get the nodeValue for text nodes or call this recursively
  // for other node types.
  var str = "";
  var cs = el.childNodes;
  var l = cs.length;

  for (var i = 0; i < l; i++) {
    switch (cs[i].nodeType) {
      case 1: //ELEMENT_NODE, skip images, javascript, class=sortarrow
        var eleDisplay = cs[i].style.display;
        var eleClass =cs[i].className;
        if (cs[i].tagName.toLowerCase()!='img' &&
          cs[i].tagName.toLowerCase()!='script' &&
          !eleClass.match(/sortarrow/) &&
          !eleClass.match(/inline_fields/) &&
          eleDisplay != "none" )
          str += this.getInnerText(cs[i]);
        break;
      case 3:	//TEXT_NODE
        var txtValue = cs[i].nodeValue;
        txtValue = txtValue.replace(/^[\s|\n]*/,"");
        txtValue = txtValue.replace(/[\s|\n]*$/,"");

        str += txtValue;
        break;
    }
  }
  return str;
}; // getInnerText


/**
 * Add a click event listener on the div.panelGroupContainer elementto catch
 * all the left-click events from the input fields (except the 'when done'
 * fields). When there's no value in the 'When done' field, all these
 * input fields are still hidden and the cells are not opened for editing yet.
 * If a user clicks on any of the unopened cells, a message will be shown once
 * per page loading in a popup window to ask the user to type a value
 * in the 'when done' field before starting to entering values
 *
 * Note: These inputs fields are hidden (visibility:hidden) when there's
 * no value in the 'When done' field, so the left-click events are actually
 * from the containing TD elements
 *
 */
TestPanel.addLeftClickHelper = function() {
  // find all div.panelGroupContainer elements
  $J('div.panelGroupContainer').click(function(e) {
      var srcEle = e.target || e.srcElement;
      if (!TestPanel.onLeftClickHelpShown_ &&
          srcEle.tagName == 'TD' && srcEle.hasClassName('rowEditText') &&
          srcEle.firstChild && srcEle.firstChild.style.visibility == 'hidden') {
        TestPanel.onLeftClickHelpShown_ = true;
        var dialog = new Def.NoticeDialog({'title': 'Edit Help'});
            dialog.setContent('Please enter a date in the "Date done" field ' +
              'before entering any other test information.');
        dialog.show();
      }
  });
}


/**
 * refresh show sheet with the previous search conditions
 * not used.
 */
TestPanel.refreshRecord = function() {

  if (TestPanel.searchConditions.loincNums.length > 0) {
    TestPanel.getRecords(TestPanel.searchConditions,
        TestPanel.updateTimelineView, true);
  }
  else {
    // hide the hide/show panel info button
    $('fe_show_hide_panel_info').style.display = 'none';
    // hide the hide/show button
    $('fe_show_hide_empty').style.display = 'none';
    // empty grid
    var panelViewDiv = $('fe_panel_view');
    if (panelViewDiv.firstChild) {
      panelViewDiv.removeChild(panelViewDiv.firstChild);
    }
    // clean up search conditions
    TestPanel.resetVariables();
  }
}; // end refreshRecord


/**
 * get the selected test panel records for timeline view
 * @param ele the action button
 */
TestPanel.showRecord = function(ele) {

  var refresh = true;
  if (!TestPanel.hasPanelList) {
    // show a warning message
    TestPanel.showWarning("Please click on the Add Trackers & Test Results button " +
        "and enter some data for the flowsheet.", "Warning");
    refresh = false;
  }
  else if (!TestPanel.hasPanelSelected) {
    // show a warning message
    TestPanel.showWarning("Please select one or more panels from the list.",
        "Warning");
    refresh = false;
  }
  else if (TestPanel.inEditMode) {
    refresh = TestPanel.cancelChanges();
  }
  if (refresh) {
    // clean up cached data
    TestPanel.resetVariables();
    Def.DataModel.cleanUpData();

    // get the list of loinc_nums of selected panels
    var loincNums = [];

    var grpDiv =$(TestPanel.panelListOption.listID);
    var checkBoxes = grpDiv.select("input.selected_panel");
    // pick the loinc_nums on the 1st column, then 2nd, and so on, to keep
    // the list order of the panels in the flowsheet same as the list order
    // of these panels in the list section.
    var i = 0, length = checkBoxes.length, j = 0, columns = 3;
    while(i < length) {
      if(checkBoxes[i].checked == true) {
        // find the loinc_num
        var loincNum = checkBoxes[i].up().up().next().innerHTML;
        if (loincNum != null) {
          loincNums.push(loincNum);
        }
      }
      i += columns;
      // go through next column
      if (i >= length && j < columns) {
        i = j;
        j++;
      }
    }

    if (loincNums.length > 0) {
      // display record in one grid?
      var inOneGrid = $('fe_in_one_grid_1_1').checked;
      // include data from other panels?
      var includeAll = $('fe_include_all_1_1').checked;

      // get date range code
      var dateRangeCode = $('fe_date_range_C_1_1').value;
      // get start/ed date (epoch time)
      var dateStart = $('fe_start_date_ET_1_1_1').value;
      var dateEnd = $('fe_end_date_ET_1_1_1').value;
      var dateEndStr = $('fe_end_date_1_1_1').value;
      // get group by code
      var groupByCode = $('fe_group_by_C_1_1').value;

      // cache the search condition for data sheet refresh
      var searchConditions = {
        groupByCode: groupByCode,
        dataRangeCode : dateRangeCode,
        dateStart: dateStart,
        dateEnd: dateEnd,
        dateEndStr: dateEndStr,
        loincNums: loincNums,
        combined: inOneGrid,
        includeAll: includeAll
      };
      TestPanel.searchConditions = searchConditions;

      TestPanel.getRecords(searchConditions, TestPanel.updateTimelineView, true);

      TestPanel.dataLoaded = true;
    }
    else {
      // hide the hide/show panel info button
      $('fe_show_hide_panel_info').style.display = 'none';
      // hide the hide/show button
      $('fe_show_hide_empty').style.display = 'none';
      // empty grid
      var panelViewDiv = $('fe_panel_view');
      if (panelViewDiv.firstChild) {
        panelViewDiv.removeChild(panelViewDiv.firstChild);
      }
    }
  }
}; // end showRecord


/**
 * check if all panels are selected
 * @param ele the action button
 */
TestPanel.checkCheckAll = function(ele) {
  var allChecked = true;
  var oneChecked = false;
  var grpDiv = $(TestPanel.panelListOption.listID);
  var checkBoxes = grpDiv.select("input.selected_panel");
  for(var i=0, len=checkBoxes.length; i<len; i++) {
    if (!checkBoxes[i].checked) {
      allChecked = false;
    }
    else {
      oneChecked = true;
    }
    if (!allChecked && oneChecked) {
      break;
    }
  }
  // check the checkbox
  $('fe_check_all').checked = allChecked;
  // set the flag
  TestPanel.hasPanelSelected = oneChecked;
};


/**
 * select/deselect all the panels in the list
 * @param ele the check box
 */
TestPanel.checkAllPanel = function(ele) {

  var grpDiv = $(TestPanel.panelListOption.listID);
  var value = ele.checked;
  var checkBoxes = grpDiv.select("input.selected_panel");
  for(var i=0, len=checkBoxes.length; i<len; i++) {
    checkBoxes[i].checked = value;
  }
  // set the flag
  TestPanel.hasPanelSelected = value;
};


/**
 * Add menu html
 */
TestPanel.addContextMenuHTML = function() {
  TestPanel.menuId_ = 'tp_flowsheet_menu';
  TestPanel.menuItems_ = ['tp_menu_undo', 'tp_menu_revise', 'tp_menu_delete'];
  TestPanel.contextMenu_ = $J('<ul id="'+ TestPanel.menuId_ +
    '" class="jeegoocontext cm_default" style="display: none">' +
    '<li id="' + TestPanel.menuItems_[0] + '">Undo</li>' +
    '<li class="separator"></li>' +
    '<li id="' + TestPanel.menuItems_[1] + '">Revise</li>' +
    '<li id="' + TestPanel.menuItems_[2] + '">Delete</li></ul>'
    );
  $J('body').append(TestPanel.contextMenu_[0]);
}


/**
 * Set up a context menu on each data table on the flow sheet page
 */
TestPanel.setupContextMenu = function(eleId) {

  // todo: remove all previus context menus ?

  // set up context menu listener
  if ((TestPanel.searchConditions.groupByCode == null ||
       TestPanel.searchConditions.groupByCode == '' ||
       TestPanel.searchConditions.groupByCode == '1') &&
       !TestPanel.searchConditions.combined &&
       !TestPanel.searchConditions.includeAll) {

    var divDataTables = $('fe_panel_view').select("div.test_data_table");
    for(var i=0, len=divDataTables.length; i<len; i++) {
      var table = divDataTables[i].down(0);
      TestPanel.attachContextMenu(table);
    } // end of tables loop
  } // end if the search conditions are correct
} // end of TestPanel.setupContextMenu


/**
 * Attach a context menu to an element
 * @param ele the element to which the context menu is attach
 * @param opt the jeegoo menu option, for exampel {event: 'click'} for
 *        listening on left-click event
 */
TestPanel.attachContextMenu = function(ele, opt) {
  var options = {
    delay: 0,
    fadeIn: 0,
    onShow: function(e, context) {

      if (TestPanel.selectedPanelLoincNum ==
          TestPanel.selectedObrPanelLoincNum) {
          TestPanel.customizeContextMenu();
        var showMenu = true ;
      }
      // show a warning msg
      else {
        showMenu = false;
        var message = 'This value belongs to the "' +
                      TestPanel.selectedObrPName +
                      '". It cannot be edited from this panel.';
        var title = "Info";
        TestPanel.showWarning(message, title);
      }
      return showMenu;
    }, // end of onShow
    onSelect: function(e, context){
      var showMenu = !Def.DataModel.subFormUnsavedChanges_ ;
      if (showMenu == false) {
        var message = 'You have unsaved changes from your <b>Add Trackers ' +
                  '& Test Results</b> request.\nThose must be resolved ' +
                  'before making any changes on this form.'
        var title = "Info";
        var warningBox = TestPanel.showWarning(message, title) ;
        TestPanel.openNewPanelEditor() ;
        warningBox.hide() ;
      }
      else {
        showMenu = true ;
        switch($J(this).attr('id')) {
          case TestPanel.menuItems_[0]: //'tp_menu_undo':
            TestPanel.undoEditOrDelete();
            break;
          case TestPanel.menuItems_[1]: //'tp_menu_revise':
            TestPanel.editPanelInPlace();
            break;
          case TestPanel.menuItems_[2]: //'tp_menu_delete':
            TestPanel.deletePanelInPlace();
            break;
        }
      }
      return showMenu ;
    } // end of onSelect
  }

  if (opt) $J.extend(options,opt);

  $J(ele).jeegoocontext(TestPanel.menuId_, options)
}


TestPanel.forceAddTestsCompletion = function () {
  // put up warning
  // show add tests and measures
 TestPanel.openNewPanelEditor() ;
}

/**
 * customize the context menu
 */
TestPanel.customizeContextMenu = function() {

  var obrId = TestPanel.selectedObrId;
  var curStatus = TestPanel.columnDataStatus[obrId];

  // hide unneeded menu items based on the column status
  // not in edit or deleted mode
  if (curStatus == null || curStatus == undefined ||
    curStatus ==TestPanel.COLUMN_STATUS_UNCHANGED) {
    // undo
    $(TestPanel.menuItems_[0]).addClassName('disabled');
    $(TestPanel.menuItems_[0]).innerHTML = 'Undo';
    // edit in place
    $(TestPanel.menuItems_[1]).removeClassName('disabled');
    // delete
    $(TestPanel.menuItems_[2]).removeClassName('disabled');
  }
  // deleted
  else if (curStatus ==TestPanel.COLUMN_STATUS_DELETED) {
    // undo
    $(TestPanel.menuItems_[0]).removeClassName('disabled');
    $(TestPanel.menuItems_[0]).innerHTML = 'Undo Delete';
    // edit in place
    $(TestPanel.menuItems_[1]).addClassName('disabled');
    // delete
    $(TestPanel.menuItems_[2]).addClassName('disabled');
  }
  // in edit
  else if (curStatus ==TestPanel.COLUMN_STATUS_INEDIT) {
    // undo
    $(TestPanel.menuItems_[0]).removeClassName('disabled');
    $(TestPanel.menuItems_[0]).innerHTML = 'Undo Revise';
    // edit in place
    $(TestPanel.menuItems_[1]).addClassName('disabled');
    // delete
    $(TestPanel.menuItems_[2]).addClassName('disabled');
  }
};


/**
 * Get the panel data for all selected panels and insert the data (html content)
 * into the page
 * @param searchConditions the search conditions
 * @param callBackFunc the call back function on a successful ajax return
 * @param savePref a flag to determine if the list of panels selected should
 *    be saved. When it's called on the flowsheet page, it is true. It is
 *    false when it's called on the PHR form.
 *
 */
TestPanel.getRecords = function(searchConditions, callBackFunc, savePref) {

  if (!savePref) {
    savePref = false;
  }

  TestPanel.startLoad_ = new Date().getTime();

  Def.showLoadingMsg();

  // make an ajax call
  var opt = {
    method: 'post',
    onSuccess: callBackFunc,
    on404: function(t) {
      Def.hideLoadingMsg();
      alert('Error:   Panel records not found!');
    },
    onFailure: function(t) {
      Def.hideLoadingMsg();
      alert('Error ' + t.status + ' -- ' + t.statusText);
    }
  };

  // get the profile id
  var profileIdShown = Def.DataModel.id_shown_;

  // token for CSRF protection
  var tkn = '&authenticity_token='+ encodeURIComponent(window._token) || '' ;
  var ajaxurl = '/form/get_loinc_panel_timeline_view?id=' +
  profileIdShown + tkn +
  '&l_nums=' + searchConditions.loincNums +
  '&in_one=' + searchConditions.combined +
  '&all=' + searchConditions.includeAll +
  '&sd=' + searchConditions.dateStart +
  '&ed=' + searchConditions.dateEnd +
  '&eds=' + searchConditions.dateEndStr +
  '&gbc=' + searchConditions.groupByCode +
  '&drc=' + searchConditions.dataRangeCode +
  '&sf=' + savePref;

  var ajax = new Ajax.Request(ajaxurl, opt);

}; // end of TestPanel.getRecords


/**
 * Update the timeline view with returning content from the ajax call
 * @param response the ajax call returning object
 */
TestPanel.updateTimelineView = function(response) {
  try {
    var retData = response.responseText.split('<@SP@>');
    TestPanel.panelInfo = JSON.parse(retData[1]);
    //create a new div
    var newDiv = document.createElement("div");
    newDiv.innerHTML = retData[0];

    // get the panel view div
    var panelViewDiv = $('fe_panel_view');

    if (panelViewDiv.firstChild !=null) {
      panelViewDiv.replaceChild(newDiv,panelViewDiv.firstChild);
    }
    else {
      panelViewDiv.appendChild(newDiv);
    }

    // show the hide/show empty rows button
    $('fe_show_hide_empty').firstChild.innerHTML = "Show Empty Rows";
    $('fe_show_hide_empty').style.display = 'inline';
    TestPanel.emptyRowsShown = true;

    // hide empty rows
    TestPanel.showHideEmptyRows(true);

    // show the hide/show panel_info button
    $('fe_show_hide_panel_info').firstChild.innerHTML = "Show Panel Info";
    $('fe_show_hide_panel_info').style.display = 'inline';
    TestPanel.panelDataShown = true;

    // hide panel info
    TestPanel.showHidePanelInfo(true);

    var btnExp = $('fe_expand_columns');
    var btnGrp = $('fe_group_columns');
    if (TestPanel.searchConditions.groupByCode != null &&
        TestPanel.searchConditions.groupByCode != '' &&
        TestPanel.searchConditions.groupByCode != '1') {

      btnExp.style.display = 'inline';
      btnGrp.style.display = 'inline';
    }
    else {
      btnExp.style.display = 'none';
      btnGrp.style.display = 'none';
    }

    // set up context menu
    if (Def.formEditability_ !== Def.FORM_READ_ONLY_EDITABILITY)
      TestPanel.setupContextMenu();

    // highlight the column on mouse over
    TestPanel.columnHighlight();

    // show sparkline charts
    TestPanel.Flot.createSparkLines();

    // show additional instructions if it's 'grouped' or 'combined'
    if (TestPanel.searchConditions.groupByCode != null &&
        TestPanel.searchConditions.groupByCode != '' &&
        TestPanel.searchConditions.groupByCode != '1' ||
        TestPanel.searchConditions.combined ||
        TestPanel.searchConditions.includeAll) {
      var fd = $('fe_instruction');
      fd.innerHTML = "When 'Group Data Columns', 'Combine records in" +
        " one timeline table' and/or 'Include test data from other panels'" +
        " is selected, the flow sheet content is not editable.";
      fd.removeClassName('hidden_field');
      fd.addClassName('guidance');
      fd.parentNode.removeClassName('hidden_field');
    }
    else {
      $('fe_instruction').parentNode.addClassName('hidden_field');
    }

    Def.hideLoadingMsg();
    // reset navigation sequence, not event listeners
    Def.Navigation.doNavKeys(0,0,true,true,true);

    // display loading time
    var msgDiv = $('fe_load_time_td');
    // no toolbar in popup mode
    if (msgDiv) {
      var time = 'Panel data loaded in ' +
        (new Date().getTime() - TestPanel.startLoad_)/1000 + ' seconds';

      msgDiv.innerHTML = time;
      setTimeout("$('fe_load_time_td').innerHTML=''", 15000);
    }
  }
  catch (e) {
    Def.Logger.logException(e);
    Def.reportError(e);
  }
}; // end of showTimelineView


/**
 * Keep the orinigal obr/obx records of the selected column when entering the
 * 'edit in place' or 'delete' mode
 * @param obrId the record_id of the obr record
 * @param taffyDbData the taffy db data for the seletect panel record
 */
TestPanel.keepOriginalRecords = function(obrId, taffyDbData) {
  var originalRecord = TestPanel.originalPanelDbRecords[obrId];
  if(originalRecord == null || originalRecord == undefined) {
    TestPanel.originalPanelDbRecords[obrId] = Def.deepClone(taffyDbData[0]);
  }
};


/**
 * create cell content from taffy db records
 * @param obrRecord a obr_orders record, for now it is not used except to get
 *        the record_id, since the obr data never chagne
 * @param obxRecords an array of obx_observartion records
 */
TestPanel.createColumnTextFromDbRecords = function(obrRecord, obxRecords) {
  var divPanelView = $('fe_panel_view');

  var obrId = obrRecord['record_id'];
  var loincNum = obrRecord['loinc_num'];
  var panelInfo = TestPanel.panelInfo[loincNum];

  // for OBR record
  // for headers, data won't change. remove css class
  var thInCol = divPanelView.select('th.' + obrId);
  var dateET = new Date(parseInt(obrRecord['test_date_ET']));
  if (thInCol) {
    // year
    thInCol[0].removeClassName('deleted');
    thInCol[0].removeClassName('in_edit');
    thInCol[0].innerHTML = dateET.getFullYear();
    // day-month
    thInCol[1].removeClassName('deleted');
    thInCol[1].removeClassName('in_edit');
    thInCol[1].innerHTML = dateET.getDate() + " " + dateET.toString("MMM");

    var htmlValue = '';
    // time
    thInCol[2].removeClassName('deleted');
    thInCol[2].removeClassName('in_edit');
    if (obrRecord['test_date_time'] == null || obrRecord['test_date_time'] == '')
      htmlValue = '&nbsp;';
    else
      htmlValue = obrRecord['test_date_time'];
    thInCol[2].innerHTML = htmlValue;
  }

  // for data cells
  // the first 4 cells are panel info
  var tdInCol = divPanelView.select('td.' + obrId);
  if (tdInCol) {
    // panel header
    tdInCol[0].removeClassName('deleted');
    tdInCol[0].removeClassName('in_edit');
    // comment
    tdInCol[1].removeClassName('deleted');
    tdInCol[1].removeClassName('in_edit');
    if (obrRecord['summary'] == null || obrRecord['summary'] == '')
      htmlValue = '&nbsp;';
    else
      htmlValue = obrRecord['summary'];
    tdInCol[1].innerHTML = htmlValue;
    // where one
    tdInCol[2].removeClassName('deleted');
    tdInCol[2].removeClassName('in_edit');
    var testPlace = obrRecord['test_place'];
    if (testPlace != null && testPlace != undefined && typeof testPlace == 'object') {
        testPlace = testPlace[0];
    }
    if (testPlace == null || testPlace == '')
      testPlace = '&nbsp;';
    tdInCol[2].innerHTML = testPlace;
    // due date
    tdInCol[3].removeClassName('deleted');
    tdInCol[3].removeClassName('in_edit');
    if (obrRecord['due_date'] == null || obrRecord['due_date'] == '')
      htmlValue = '&nbsp;';
    else
      htmlValue = obrRecord['due_date'];
    tdInCol[3].innerHTML = htmlValue;

    // for each OBX record
    for (i=0, len=obxRecords.length; i<len; i++) {
      var abnormal_flag = null;
      var value = obxRecords[i]['obx5_value'];
      // if it is not a string, it must be an array
      if (value != null && value != undefined && typeof value == 'object') {
        value = value[0];
      }

      var fValue = parseFloat(value);
      // calculate abnormal flag only if this is a numeric type
      if (!isNaN(fValue) && value == fValue + '') {
        var high = obxRecords[i]['test_normal_high'];
        var fHigh = parseFloat(high);
        var low = obxRecords[i]['test_normal_low'];
        var fLow = parseFloat(low);
        if (!isNaN(fHigh) && fValue > fHigh) {
          abnormal_flag ='*H';
        }
        else if (!isNaN(fLow) && fValue < fLow) {
          abnormal_flag ='*L';
        }
      }

      // check units
      var units = obxRecords[i]['obx6_1_unit'];
      // if it is not a string, it must be an array
      if (units != null && units != undefined && typeof units == 'object') {
        units = units[0];
      }
      var diffUnits = false;
      if (panelInfo[i]['commUnits'] != null && units != null &&
        panelInfo[i]['commUnits'] != units) {
        diffUnits = true;
      }

      // create static content
      if (value == null || value.length ==0) {
        var cellValue = '-';
        if (diffUnits) {
          cellValue = cellValue + ' ' + units;
        }
        tdInCol[i+TestPanel.PANEL_INFO_ROW_NUM].addClassName('no_data');
      }
      // normal test
      else {
        if (diffUnits) {
          value = value + ' ' + units;
        }
        if (abnormal_flag != null) {
          cellValue = value + '<input class="readonly_field flag" ' +
              'readonly="readonly" value=' + abnormal_flag + '></input>';
        }
        else {
          cellValue = value + '<input class="readonly_field flag" ' +
              'readonly="readonly" > </input>';
        }
      }

      tdInCol[i+TestPanel.PANEL_INFO_ROW_NUM].innerHTML = cellValue;
      tdInCol[i+TestPanel.PANEL_INFO_ROW_NUM].removeClassName('in_edit');
      tdInCol[i+TestPanel.PANEL_INFO_ROW_NUM].removeClassName('deleted');
    } // end of each OBX record
  }

};


/**
 * Recreate the cell content from the the orinigal obr/obx
 * records of the selected column. and replace the live data in taffy db with
 * the original data.
 * @param obrId the record_id of the obr record
 * @param updateLive whether to update live obr/obx records
 */
TestPanel.restoreFromOriginalRecords = function(obrId, updateLive) {

  if (updateLive == null || updateLive == undefined) {
    updateLive = true;
  }

  var originalRecords = TestPanel.originalPanelDbRecords[obrId];
  if(originalRecords != null && originalRecords != undefined) {
    var obrRecord = Def.deepClone(originalRecords[Def.DataModel.OBR_TABLE][0]);
    var obxRecords = Def.deepClone(originalRecords[Def.DataModel.OBX_TABLE]);

    // recreate column content
    TestPanel.createColumnTextFromDbRecords(obrRecord, obxRecords);

    // update live data store
    if(updateLive) {
      // remove the lists in the value of
      for(var obr_key in obrRecord) {
        // if value is an array
        var value = obrRecord[obr_key];
        if (value != null && value !=undefined  && typeof value == 'object' &&
          value.length >0) {
          obrRecord[obr_key] = value[0];
        }
      }
      for(var i=0, len=obxRecords.length; i<len; i++) {
        for(var obxKey in obxRecords[i]) {
          value = obxRecords[i][obxKey];
          if (value != null && value !=undefined  && typeof value == 'object' &&
            value.length >0) {
            obxRecords[i][obxKey] = value[0];
          }
        }
      }
      // get the taffydbs
      var obrTaffy = Def.DataModel.taffy_db_[Def.DataModel.OBR_TABLE];
      var obxTaffy = Def.DataModel.taffy_db_[Def.DataModel.OBX_TABLE];

      // find the obr index
      var obrIdVal = obrId;
      if(TestPanel.columnDataStatus[obrId]==TestPanel.COLUMN_STATUS_DELETED){
        obrIdVal = 'delete ' + obrId;
      }
      var obrPositions = obrTaffy.find({
        record_id:obrIdVal
      });
      // replace obr record
      Def.DataModel.data_table_[Def.DataModel.OBR_TABLE][obrPositions[0]] =
      obrRecord;

      // find the obx index
      var obxPositions = obxTaffy.find({
        _p_id_:obrRecord['_id_']
        });
      // replace obx records
      for(i=0, len = obxPositions.length; i<len; i++) {
        Def.DataModel.data_table_[Def.DataModel.OBX_TABLE][obxPositions[i]] =
        obxRecords[i];
      }
    }
    // update status
    TestPanel.columnDataStatus[obrId]=TestPanel.COLUMN_STATUS_UNCHANGED;
  }
};


/**
 * Recreate the cell content from the the updated obr/obx
 * records of the selected column
 * @param obrId the record_id of the obr record
 * @param updateOriginalRecords a optional flag that determines if the orginal
 *    db records need to be updated too (when it is still available).
 *    default value is false
 */
TestPanel.restoreAfterSave = function(obrId, updateOriginalRecords) {

  if (updateOriginalRecords == null || updateOriginalRecords == undefined ||
      updateOriginalRecords != true) {
    updateOriginalRecords = false;
  }

  // find the data record in taffy db
  var obrRecords = Def.DataModel.searchRecord(Def.DataModel.OBR_TABLE,
    [{
      conditions:{
        record_id:obrId
      }
    }]);
  var obxRecords = Def.DataModel.searchRecord(Def.DataModel.OBX_TABLE,
    [{
      conditions:{
        _p_id_:obrRecords[0]['_id_']
        }
      }]);

  if(obrRecords != null && obrRecords != undefined) {
    var obrRecord = obrRecords[0];
    // recreate column content
    TestPanel.createColumnTextFromDbRecords(obrRecord, obxRecords);

    if (updateOriginalRecords) {
      //update the original data with the live data while keeping the answer lists
      // obr_orders
      var origObrRecord =
      TestPanel.originalPanelDbRecords[obrId][Def.DataModel.OBR_TABLE][0];
      for(var obrKey in origObrRecord) {
        var value = origObrRecord[obrKey];
        // if the value is an array
        if (value != null && value !=undefined  && typeof value == 'object' &&
          value.length >0) {
          var listItems = value[1];
          var listCodes = value[2];
          var opts = value[3];
          var liveValue = obrRecord[obrKey];
          if (opts) {
            origObrRecord[obrKey] = [liveValue, listItems, listCodes, opts];
          }
          else {
            origObrRecord[obrKey] = [liveValue, listItems, listCodes];
          }
        }
        // normal value
        else {
          origObrRecord[obrKey] = obrRecord[obrKey];
        }
      } // end of loop of obr record columns

      // obx_observations
      var origObxRecords =
      TestPanel.originalPanelDbRecords[obrId][Def.DataModel.OBX_TABLE];
      for(var i=0, len=origObxRecords.length; i<len; i++) {
        for(var obxKey in origObxRecords[i]) {
          value = origObxRecords[i][obxKey];
          // if the value is an array
          if (value != null && value !=undefined  && typeof value == 'object' &&
            value.length >0) {
            listItems = value[1];
            listCodes = value[2];
            opts = value[3];
            liveValue = obxRecords[i][obxKey];
            if (opts) {
              origObxRecords[i][obxKey] = [liveValue, listItems, listCodes, opts];
            }
            else {
              origObxRecords[i][obxKey] = [liveValue, listItems, listCodes];
            }
          }
          // normal value
          else {
            origObxRecords[i][obxKey] = obxRecords[i][obxKey];
          }
        } // end of loop of obx record columns
      } // end of loop of origObxRecords
    } // end of updateOriginalRecords
  }
  // update column status
  TestPanel.columnDataStatus[obrId] = TestPanel.COLUMN_STATUS_UNCHANGED;

};


/**
 * Cancels all unsaved editing on the flowsheet, restores the initial values
 * of the fields, and invokes a rollback of the autosave data.  Does not
 * close the window.
 */
TestPanel.cancelChanges = function() {

  // Use the Def.confirmCancel method to make sure that all the autosave
  // data gets handled correctly and to keep all cancel confirmations in
  // one place.  This will also take care of rolling back the autosaved
  // data.

  var answer = Def.confirmCancel('return', false) ;

  if (answer) {
    for(var obrId in TestPanel.columnDataStatus) {
      if (TestPanel.columnDataStatus[obrId] != TestPanel.COLUMN_STATUS_UNCHANGED) {
        TestPanel.restoreFromOriginalRecords(obrId);
        TestPanel.cleanNavData(obrId);
      }
    }
    // reset navigation sequence, not event listeners
    Def.Navigation.doNavKeys(0,0,true,true,true);

    // hide the save/cancel buttons
    TestPanel.showHideSaveButtons();

    // reset the flag
    TestPanel.inEditMode = false;
  }
  return answer;

}; // end cancelChanges


/**
 * Update flow sheet status, plot data and gui after a successful save
 *
 */
TestPanel.afterSaveCleanup = function() {
  for(var obrId in TestPanel.columnDataStatus) {
    TestPanel.cleanNavData(obrId);
    // if it's deleted
    if(TestPanel.columnDataStatus[obrId]==TestPanel.COLUMN_STATUS_DELETED) {

      // update plot data first, which relies on data_table_
      TestPanel.Flot.updateSparklineData(obrId, true);

//      // remove the deleted data from data model
//      // obr record
//      var obrTaffy = Def.DataModel.taffy_db_[Def.DataModel.OBR_TABLE];
//      var obrIndex = obrTaffy.find({
//          record_id:'delete '+obrId
//          });
//      var obrRec = obrTaffy.get(obrIndex);
//      if (obrIndex.length >0) {
//        // remove the obr record and related mapping records
//        var obrRemovedRecords = [[Def.DataModel.OBR_TABLE, obrIndex[0]+1, obrId]];
//        Def.DataModel.removeRecordsAndUpdateMappings(obrRemovedRecords);
//
//        // obx records
//        var obxTaffy = Def.DataModel.taffy_db_[Def.DataModel.OBX_TABLE];
//        var obxIndex = obxTaffy.find({
//            _p_id_:obrRec[0]['_id_']
//            });
//        var obxRemovedRecords = [];
//        // make the index in reverse order
//        obxIndex.sort(function(x,y) {return y-x;});
//        for (var i=0, ilen = obxIndex.length; i<ilen; i++) {
//          obxRemovedRecords.push([Def.DataModel.OBX_TABLE, obxIndex[i]+1, null]);
//        }
//        Def.DataModel.removeRecordsAndUpdateMappings(obxRemovedRecords);
//      }


      // remove the deleted column from the table
      TestPanel.removeAColumn(obrId);
    }
    // if it's revised
    else if(TestPanel.columnDataStatus[obrId]==TestPanel.COLUMN_STATUS_INEDIT) {
     // remove the edit boxes and update the original records
      TestPanel.restoreAfterSave(obrId);
      //update plot data
      TestPanel.Flot.updateSparklineData(obrId, false);
    }
  }

  // reset Def.DataModel
  // It is not as good as the original design, which updates the cached data.
  // But a deleted record causes too much cached data useless, and it's now
  // difficult to maintain.
  Def.DataModel.cleanUpData();
  Def.AutoSave.resetData(Def.DataModel.data_table_, false) ;

  // reset the cached data and data related to the inplace editing
  TestPanel.panelEditBoxSN = 1; // when there's a hidden panel group included
                                // otherwise it is 0
  TestPanel.columnEditBoxSN = {};
  TestPanel.originalPanelDbRecords = {};
  TestPanel.columnDataStatus = {};

  // reset navigation sequence, not event listeners
  Def.Navigation.doNavKeys(0,0,true,true,true);

  // hide the save/cancel buttons
  TestPanel.showHideSaveButtons();

  // reset the flag
  TestPanel.inEditMode = false;

  // update sparklines
  TestPanel.Flot.createSparkLines();
};


/**
 * Update plot data in TestPanel.panelInfo
 * @param obrId obr_id of the updated/deleted record
 * @param remove remove the deleted data, optional. default is false
 */
TestPanel.Flot.updateSparklineData = function(obrId, remove) {

  if (remove == null || remove == undefined) {
    remove = false;
  }

  if (remove) {
    var searchKey = 'delete ' + obrId;
  }
  else {
    searchKey = obrId;
  }

  // find the data record in taffy db
  var obrRecords = Def.DataModel.searchRecord(Def.DataModel.OBR_TABLE,
    [{
      conditions:{
        record_id:searchKey
      }
    }]);
  var obxRecords = Def.DataModel.searchRecord(Def.DataModel.OBX_TABLE,
    [{
      conditions:{
        _p_id_:obrRecords[0]['_id_']
        }
      }]);

  // if obr and obx records are found
  if(obrRecords != null && obrRecords != undefined) {
    // get the current data in Def.DataModel.data_table_
    var p_loinc_num = obrRecords[0]['loinc_num'];
    // for each obx record
    for(var i=0, len=obxRecords.length; i<len; i++) {
      var t_loinc_num = obxRecords[i]['loinc_num'];

      // if panelinfo is available and loinc numbers valid
      if (p_loinc_num && t_loinc_num && TestPanel.panelInfo) {

        var testData = TestPanel.panelInfo[p_loinc_num];
        // if there's data for each test
        if (testData) {
          // for each test's data
          for(var j=0, jlen=testData.length; j<jlen; j++) {
            // if there's chart data for this test
            if (testData[j] && testData[j]['chartData'] &&
                testData[j]['loincNum'] &&
                testData[j]['loincNum'] == t_loinc_num) {

              var chartData = testData[j]['chartData'];
              // if it has data for chart
              if (chartData['values'] && chartData['orders']) {
                var index = chartData['orders'].indexOf(obrId +'');
                // if this record has valid data in the value array
                if (index >=0) {
                  // if the records were deleted
                  if (remove) {
                    // not necessary to actually delete the value in the array
                    // just set it to null
                    chartData['values'][index] =  null;
                  }
                  // if it is an update
                  else
                  {
                    var x = obrRecords[0]['test_date_ET'];
                    var y = obxRecords[i]['obx5_value'] ;
                    // value shoud not be null or empty
                    if (y && y != '') {
                      y = parseFloat(y) + '';
                      chartData['values'][index] =  x + ":" + y;
                    }
                    // otherwise set it as null
                    else {
                      chartData['values'][index] =  null;
                    }
                  } // delete or update
                } // if this record has valid data in the value array
              } // if it has data for chart
            } // if there's chart data for this test
          } // for each test's data
        } // if there's data for each test
      } // if panelinfo is available
    } // for each obx record
  } // if obr and obx records are found
};


/**
 * update flowsheet with new data when all the changes are saved
 * @param button the save button
 */
TestPanel.saveChanges = function(button) {

  // save the data
  Def.doSave(button, true, null, function(){TestPanel.afterSaveCleanup();});

};


/**
 * create or update sparklines based on the updated data in TestPanel.panelInfo
 */
TestPanel.Flot.createSparkLines = function() {
  var options = {type: 'line',
        barColor: 'green',
        width:'60px',
        fillColor: false,
        lineColor: 'blue',
        normalRangeColor: '	#FFF380', //#54C571', // sea green 3.
        // see http://www.computerhope.com/htmcolor.htm
        enableTagOptions: true,
        disableTooltips: true // the values of 'TS' type are epoch time, a long integer, which are almost useless to
                              // display over the data point. Here we just disable tooltups for all kinds of data types.
      }

  var panelDefDivs = $J('div.panel_def');
  for(var i=0, ilen =panelDefDivs.length; i<ilen; i++) {
    var p_loinc_num = panelDefDivs[i].getAttribute('p_no');
    var sparklineDivs = panelDefDivs[i].select('td.sparkline_chart');
    for(var j=0, jlen =sparklineDivs.length; j<jlen; j++) {
      var t_loinc_num = sparklineDivs[j].getAttribute('l_no');
      var redrawSparkline = false;
      if (t_loinc_num) {
        var chartData = TestPanel.Flot.getSparklineData(p_loinc_num, t_loinc_num);
        if (chartData && chartData['values'] && chartData['values'].length > 1) {
          options['normalRangeMax'] = chartData['normal_range']['max'];
          options['normalRangeMin'] = chartData['normal_range']['min'];
          // sparkline needs a visible block to draw on
          var sparkline = sparklineDivs[j].down(1);
          if (sparkline) sparkline.style.display = 'block';

          $J(sparklineDivs[j].down('.sparkline')).sparkline(chartData['values'], options);
          redrawSparkline = true;
        }
      }

      // hide the checkbox and sparkline
      if (!redrawSparkline) {
        var checkbox = sparklineDivs[j].down(0);
        if (checkbox) checkbox.style.display = 'none';
        sparkline = sparklineDivs[j].down(1);
        if (sparkline) sparkline.style.display = 'none';
      }
    }
  }
}

/**
 * get the data for sparkline for one test in one test panel record
 * @param p_loinc_num the loinc number of the panel
 * @param t_loinc_num the loinc number of the test
 * @return a hash map that contains the sparkline data and options
 */
TestPanel.Flot.getSparklineData = function(p_loinc_num, t_loinc_num) {
  var retVal = null;
  if (p_loinc_num && t_loinc_num && TestPanel.panelInfo) {
    var testData = TestPanel.panelInfo[p_loinc_num];
    if (testData) {
      for(var i=0, ilen=testData.length; i<ilen; i++) {
        if (testData[i] && testData[i]['chartData'] &&
            testData[i]['loincNum'] &&
            testData[i]['loincNum'] == t_loinc_num) {
          var dataArray = [];
          var chartData = testData[i]['chartData']['values'];
          if (chartData) {
            for (var j=0, jlen=chartData.length; j<jlen; j++) {
              if (chartData[j] != null) {
                dataArray.push(chartData[j]);
              }
            }
            retVal = {'values': dataArray,
                'normal_range': testData[i]['chartData']['normal_range']};
          }
          break;
        }
      }
    }
  }
  return retVal;
}
/**
 * create editable fields for 'edit in place' of a panel on flowsheet
 * @param obrRecord a obr_orders record, for now it is not used except to get
 *        the record_id, since the obr data never chagne
 * @param obxRecords an array of obx_observartion records
 * @param pSN number of exsitng 'editable' panel on the flowsheet
 */
TestPanel.createTestEditBox = function(obrRecord, obxRecords, pSN) {

  // find the all the tds to be replaced with fields
  var panelViewDiv = $('fe_panel_view');

  // the 3 date and time fields in the header
  var selectedTHs = panelViewDiv.select('th.' +
    TestPanel.selectedObrId);

  var selectedTDs = panelViewDiv.select('td.' +
    TestPanel.selectedObrId);
  var loincNum = obrRecord['loinc_num'];
  var panelInfo = TestPanel.panelInfo[loincNum];

  // default event listeners
  var defaultObservers = {
    'focus': [Def.ClickedTextSelector.onfocus],
    'change': [function(event){
      Def.DataModel.formFieldUpdateHandler(event);
    }],
    'mousedown': [Def.ClickedTextSelector.onmousedown],
    'blur': [Def.ClickedTextSelector.onblur],
    'click': [Def.ClickedTextSelector.onclick]
  };
  // event observers on the test value fields
  var testValueObservers = Def.deepClone(defaultObservers);
  testValueObservers['change'] = testValueObservers['change'].concat(
      function(event){Def.Rules.runRules(this);});
  testValueObservers['click'] = testValueObservers['click'].concat(
      MultiFieldBox.srcOnFocusHandler);

  // event observers on the test date time field
  var timeObservers = Def.deepClone(defaultObservers);
  timeObservers['change'] = [function(event){Def.runValidations(this);},
      function(event){Def.DataModel.formFieldUpdateHandler(event);},
      function(event){Def.Rules.runRules(this);}];
  timeObservers['blur'] = [function(event){Def.onBlurAfterValidation(this);}, Def.ClickedTextSelector.onblur];

// event observers on the test date field
  var testDateObservers = Def.deepClone(defaultObservers);
  testDateObservers['focus'] =
      [function(event){Def.DateField.insertDefaultVal(this);},
       function(event){Def.onFocusTip(this);},
       Def.ClickedTextSelector.onfocus];
  testDateObservers['change'] =
      [function(event){Def.DataModel.formFieldUpdateHandler(event);}, function(event){Def.Rules.runRules(this);}];
  testDateObservers['load'] = [function(theField){Def.onTipSetup(theField);}];
  testDateObservers['blur'] = [function(event){Def.onBlurTip(this);}, Def.ClickedTextSelector.onblur];

// event observers on the due date field
  var dueDateObservers = Def.deepClone(defaultObservers);
  dueDateObservers['focus'] =
      [function(event){Def.DateField.insertDefaultVal(this);},
       function(event){Def.onFocusTip(this);},
       Def.ClickedTextSelector.onfocus];
  dueDateObservers['change'] =
      [function(event){Def.DataModel.formFieldUpdateHandler(event);}, function(event){Def.Rules.runRules(this);}];
  dueDateObservers['load'] = [function(theField){Def.onTipSetup(theField);}];
  dueDateObservers['blur'] = [function(event){Def.onBlurTip(this);}, Def.ClickedTextSelector.onblur];

  // check units first
  var hasDiffUnits = false;
  var diffUnits = [];
  for(var i=0, len=obxRecords.length; i<len; i++) {
    var units = obxRecords[i]['obx6_1_unit'];
    // if it is not a string, it must be an array
    if (units != null && units != undefined && typeof units == 'object') {
      units = units[0];
    }
    var diff = false;
    // check units
    if (panelInfo[i]['commUnits'] != null && units != null &&
      panelInfo[i]['commUnits'] != units) {
      diff = true;
      hasDiffUnits = true;
    }
    diffUnits.push([diff,units]);
  }

  var infoValueClass = 'test_value_edit';
  // keep the same width if there's no different unit
  if (hasDiffUnits) {
    infoValueClass = 'test_value_edit without_units';
  }
  var inputStyle = '';
  var calFieldStyle = '';

  // create input fields for the obr record
  var obrSuffix = "_" + (pSN+1) + "_1";
  // hide the first cell (the year field)
  var th = selectedTHs[0];
  th.innerHTML = '&nbsp;';
  // when done (in the day-month field)
  th = selectedTHs[1];

  th.innerHTML = "<div title='Date done' class='date_container hasToolTip'>" +
            "<input type='text' class='"+ infoValueClass +
            " required' " + calFieldStyle +" id='fe_tp1_panel_testdate" +
            obrSuffix +"' autocomplete='off' title='YYYY/[MM/[DD]]'></div>" +
            "<input type='text' id='fe_tp1_panel_testdate_ET" + obrSuffix +
            "' class='hidden_field' autocomplete='off'>" +
            "<input type='text' id='fe_tp1_panel_testdate_HL7" + obrSuffix +
            "' class='hidden_field' autocomplete='off'>";


  th.addClassName('in_edit');
  TestPanel.addEventListener('tp1_panel_testdate', testDateObservers);
  // when done time
  th = selectedTHs[2];
  th.innerHTML = "<input title='Time done' type='text' class='time "+
    infoValueClass + "' " +  inputStyle +" id='fe_tp1_panel_testdate_time" +
    obrSuffix + "' autocomplete='off' placeholder='Time done'>";
  th.addClassName('in_edit');
  TestPanel.addEventListener('tp1_panel_testdate_time', timeObservers);
  // comment
  var td= selectedTDs[1];
  td.innerHTML = "<input type='text' class='"+ infoValueClass + "' " +
      inputStyle +" id='fe_tp1_panel_summary" + obrSuffix +
      "' autocomplete='off'>";
  td.addClassName('in_edit');
  // where done
  td= selectedTDs[2];
  td.innerHTML = "<input type='text' class='"+ infoValueClass + "' " +
    inputStyle +" id='fe_tp1_panel_testplace" + obrSuffix +
    "' class='ansList right-icon-widget eventsHandled' autocomplete='off'>";
  td.addClassName('in_edit');

  // due date
  td= selectedTDs[3];

  td.innerHTML = "<div class='date_container hasToolTip'><input type='text' class='"+
    infoValueClass + "' " + calFieldStyle +" id='fe_tp1_panel_duedate" +
    obrSuffix +"' autocomplete='off' ></div>" +
        "<input type='text' id='fe_tp1_panel_duedate_ET" + obrSuffix +
        "' class='hidden_field' autocomplete='off'>" +
        "<input type='text' id='fe_tp1_panel_duedate_HL7" + obrSuffix +
        "' class='hidden_field' autocomplete='off'>";

  td.addClassName('in_edit');
  TestPanel.addEventListener('tp1_panel_duedate', dueDateObservers);

  var date_changed = false;
  var date_picker_opts = {
    //firstDay: 1,
    //minDate: '#{min_date}',
    //maxDate: '#{max_date}',
    changeMonth: true,
    changeYear: true,
    constrainInput: false,
    dateFormat: "yy M dd",
    showOn: "button",
    showOtherMonths: true,
    showMonthAfterYear: true,
    selectOtherMonths: true,
    buttonImage: Def.blankImage_,
    buttonImageOnly: true,
    buttonText: "",
    onChangeMonthYear: function(year, month) {
      if(date_changed) {
        return;
      }
      date_changed = true;
      var d = $J(this).datepicker("getDate");
      if(d !== null) {
        d.setFullYear(year);
        d.setMonth(month - 1);
        //this.setValue(d.toLocaleFormat("%Y/%m/%d"));
        $J(this).datepicker("setDate", d);
Def.Logger.logMessage(['This log statement here to make acceptance tests (usage_stats:866) pass!']);
        appFireEvent(this, "change");
      }
      date_changed = false;
    },
    onSelect: function() {
      appFireEvent(this, "change");
      $J(this).datepicker("hide");
    },
    onClose: function() {
      Def.Navigation.moveToNextFormElem(this);
    }
};

  $J('#fe_tp1_panel_testdate'+obrSuffix).datepicker(date_picker_opts);
  $J('#fe_tp1_panel_testdate'+obrSuffix)[0].next().addClassName('sprite_icons-calendar');

  $J('#fe_tp1_panel_duedate'+obrSuffix).datepicker(date_picker_opts);
  $J('#fe_tp1_panel_duedate'+obrSuffix)[0].next().addClassName('sprite_icons-calendar');

  // other obr fields with event listeners
  var obrTargetFields =
    ['tp1_panel_testdate_ET', 'tp1_panel_testdate_HL7',
    'tp1_panel_summary', 'tp1_panel_testplace',
    'tp1_panel_duedate_ET','tp1_panel_duedate_HL7'];
  //add event listeners
  for(i=0, len=obrTargetFields.length; i< len; i++) {
    TestPanel.addEventListener(obrTargetFields[i], defaultObservers);
  }

  // create input fields for the obx records
  var targetFields = ['tp1_test_value','tp1_test_value_C', 'tp1_test_unit',
      'tp1_test_unit_C', 'tp1_test_value_real', 'tp1_test_data_type',
      'tp1_test_data_type', 'tp1_test_date', 'tp1_test_date_ET',
      'tp1_test_date_HL7', 'tp1_test_date_time', 'tp1_test_loinc_num'];
  for(i=0, len=obxRecords.length; i<len; i++) {
    // the first 4 tds are panel info, which are not editable
    // replaced static text with input fields
    td= selectedTDs[i+TestPanel.PANEL_INFO_ROW_NUM];
    var suffix = "_" + (pSN+1) + "_1_" + (i+1);

    // calculate the class
    var valueClass = 'test_value_edit';
    var unitsClass = 'hidden_field test_unit_edit readonly_field';
    // add classes based on whether a different unit occurs
    if (hasDiffUnits) {
      // the test has a different units than the common units
      if(diffUnits[i][0]) {
        unitsClass = 'test_unit_edit readonly_field';
      }
      // this test has no different units (normal field)
      else {
        valueClass = 'test_value_edit without_units';
      }
    }

    // if this is not a sub panel header
    var isPanelHeader = obxRecords[i]['is_panel_hdr'];
    if(isPanelHeader == null || isPanelHeader != true) {
      // create the html content
      var strHTML = '';
      for(var n=0, nlen=targetFields.length; n<nlen; n++) {
        var fieldId = 'fe_' + targetFields[n] + suffix;
        Def.fieldObservers_[targetFields[n]] = {};
        switch (targetFields[n]) {
        case 'tp1_test_value':
          strHTML += "<input class='" + valueClass +"' id=" + fieldId +
              " ref_fd='tp1_test_unit' val_fd='tp1_test_value_real' " +
              inputStyle + "></input>";
          // add event listener
          TestPanel.addEventListener(targetFields[n], testValueObservers);
          break;
        case 'tp1_test_unit':
          strHTML += "<input class='" + unitsClass +"' disabled='true' id=" +
              fieldId + "></input>";
          // add event listener
          TestPanel.addEventListener(targetFields[n], defaultObservers);
          break;
        default:
          strHTML += "<input class='hidden_field' id=" + fieldId + "></input>";
          TestPanel.addEventListener(targetFields[n], defaultObservers);
          break;
        }
      }
      td.innerHTML = strHTML;
      td.addClassName('in_edit');
    } // end of not sub panel header
  } // end of obx records

  // Adds field validation rules for test edit box
  var r_testdate = Def.fieldValidations_.tp1_panel_testdate ;
  var r_duedate = Def.fieldValidations_.tp1_panel_duedate ;
  // change required field validation type from normalline into common
  if (r_testdate.last().join("|") === "required|normalLine") {
    r_testdate[r_testdate.length - 1][1] = "common";
  }
  if (r_duedate.last().join("|") === "required|normalLine") {
    r_duedate[r_duedate.length - 1][1] = "common";
  }
  // Because the function TestPanel.addEventListener overwrites the existing
  // change/blur event listeners with non field validation observers, we need
  // manully add the validation listeners into Def.fieldObservers_
  Def.loadFieldValidations({
    "tp1_panel_testdate": r_testdate,
    "tp1_panel_duedate": r_duedate
  });

  // add to id cache
  Def.IDCache.addToCache(panelViewDiv);

  // reset the navigation
  var firstElePos = Def.Navigation.navSeqsHash_['fe_include_all_1_1'];
  Def.Navigation.doNavKeys(firstElePos[0], firstElePos[1]+1,true,true,true);
  // add required field validation
  Def.Validation.RequiredField.Functions.loadValidator();

  // set focus on the first test value field
  var FieldId = 'fe_tp1_test_value'+ "_" + (pSN+1) + "_1_1" ;
  if ($(FieldId)) {
    $(FieldId).focus();
  }
}; // end of TestPanel.createTestEditBox


/**
 * clean up navigation data for selected panel records in edit mode
 * when the data are either saved or undone
 * @param obrId the record_id of the obr record
 */
TestPanel.cleanNavData = function(obrId) {

  // obr_orders
  var table = 'obr_orders';
  var obrTaffyDb = Def.DataModel.taffy_db_[table];
  var obrPosition = obrTaffyDb.find({record_id:obrId});

  var obrModelRecord = Def.DataModel.model_table_[table];
  for (var col in obrModelRecord) {
    var dbKey = table + Def.DataModel.KEY_DELIMITER +
        col + Def.DataModel.KEY_DELIMITER + (obrPosition[0]+1);
    var fieldId = Def.DataModel.mapping_table_db_[dbKey];
    delete Def.Navigation.navSeqsHash_[fieldId];
  }
  // obx_observations
  table = 'obx_observations';
  var obxTaffyDb = Def.DataModel.taffy_db_[table];
  var obxPositions = obxTaffyDb.find({_p_id_:obrPosition[0]});

  var obxModelRecord = Def.DataModel.model_table_[table];
  for (col in obxModelRecord) {
    for(var i=0, len=obxPositions.length; i< len; i++) {
      dbKey = table + Def.DataModel.KEY_DELIMITER +
          col + Def.DataModel.KEY_DELIMITER + (obxPositions[i]+1);
      fieldId = Def.DataModel.mapping_table_db_[dbKey];
      delete Def.Navigation.navSeqsHash_[fieldId];
    }
  }
}


/**
 * Add default event listeners
 */
TestPanel.addEventListener = function(targetField, observers) {
  var events = ['blur', 'click', 'focus', 'change', 'mousedown', 'delete',
    'undelete'];
  for(var i=0, len=events.length; i<len; i++) {
    if (observers[events[i]]) {
      if (!Def.fieldObservers_[targetField]) {
        Def.fieldObservers_[targetField] = {};
      }
      Def.fieldObservers_[targetField][events[i]] = observers[events[i]];
    }
  }
}


/**
 * expand all grouped columns
 */
TestPanel.expandAllColumns = function() {
  TestPanel.expColAllColumns(false);
};


/**
 * re-group all columns
 */
TestPanel.groupAllColumns = function() {
  TestPanel.expColAllColumns(true);
};


/**
 * expand or collapse all the grouped columns in the data table
 * @param collapse to collapse to expand
 */
TestPanel.expColAllColumns = function(collapse) {

  var panelViewDiv = $('fe_panel_view');
  var expImages = panelViewDiv.getElementsBySelector('img.exp_column');
  for(var i=0, len = expImages.length; i < len; i++) {
    var expImg = expImages[i];
    TestPanel.expColColumn(expImg, collapse);
  }
};


/**
 * hide or show the save and cancel buttons
 */
TestPanel.showHideSaveButtons = function() {

  var hide = true;
  // check columnDataStatus to determine whether to show or hide the save
  // and cancel buttons
  for(var obrId in TestPanel.columnDataStatus) {
    if( TestPanel.columnDataStatus[obrId] != 'unchanged') {
      hide = false;
      break;
    }
  }
  // get the buttons
  var btnSave = $('fe_save');
  var btnCancel = $('fe_cancel');
  var btnClose = $('fe_return_button');
  var btnAdd = $('fe_add_new_test');
  if(hide) {
    btnSave.style.display ='none';
    btnCancel.style.display = 'none';
    // show close button
    btnClose.style.display = 'inline';
    // show add tests and measures
    btnAdd.style.display = 'inline';
  }
  else {
    btnSave.style.display = 'inline';
    btnCancel.style.display = 'inline';
    // hide close button
    btnClose.style.display = 'none';
    // hide add tests and measures
    btnAdd.style.display = 'none';
  }
};


/**
 * hide or show empty records in test panel data table
 * @param hide to hide or show
 * @panel includePanelInfoRows a flag to determine if to hide or show empty
 *        panel info rows (comments, where done, due date)
 */
TestPanel.showHideEmptyRows = function(hide, includePanelInfoRows) {
  if (hide == null || hide == undefined) {
    hide = TestPanel.emptyRowsShown ? true : false;
  }

  if (includePanelInfoRows == null || includePanelInfoRows == undefined) {
    includePanelInfoRows = false;
  }

  var panelViewDiv = $('fe_panel_view');
  var panelTimelineDivs = panelViewDiv.getElementsBySelector('div.panel_timeline');
  for(var i=0, len = panelTimelineDivs.length; i < len; i++) {
    var timeline_div = panelTimelineDivs[i];
    // get panel def rows
    var panelDefDiv = timeline_div.getElementsBySelector('div.panel_def')[0];
    //var panelDefTRs = panelDefDiv.getElementsBySelector('tr');
    var panelDefTRs = panelDefDiv.down().down().childElements();
    // get panel data rows
    var dataDiv = timeline_div.getElementsBySelector('div.test_data_table')[0];
    var dataTRs = dataDiv.down('table').rows;

    for (var j=0, length=panelDefTRs.length; j<length; j++) {
      var row = panelDefTRs[j];
      // hide/show empty panel info rows too
      if (includePanelInfoRows) {
        if (checkClassName(row,'no_data')) {
          if (hide) {
            row.style.display = 'none';
            dataTRs[j].style.display = 'none';
          }
          else {
            row.style.display = 'table-row';
            dataTRs[j].style.display = 'table-row';
          }
        }
      }
      // hide/show tests rows only
      else {
        if (checkClassName(row,'no_data') && !(checkClassName(row,'panel_info'))) {
          if (hide) {
            row.style.display = 'none';
            dataTRs[j].style.display = 'none';
          }
          else {
            row.style.display = 'table-row';
            dataTRs[j].style.display = 'table-row';
          }
        }
      }
    }
  }
  var rowBtnEle = $('fe_show_hide_empty');
  if (hide) {
    TestPanel.emptyRowsShown = false;
    // this function is now also called on the PHR form, where there's no such
    // 'hide/show empty rows' button
    if (rowBtnEle) {
      rowBtnEle.firstChild.innerHTML = "Show Empty Rows";
    }
  }
  else {
    TestPanel.emptyRowsShown = true;
    // this function is now also called on the PHR form, where there's no such
    // 'hide/show empty rows' button
    if (rowBtnEle) {
      rowBtnEle.firstChild.innerHTML = "Hide Empty Rows";
    }
  }

};


/**
 * hide or show 3 rows of the panel information
 * (comment, where done and due date)
 * @param hide to hide or show
 */
TestPanel.showHidePanelInfo = function(hide) {
  if (hide == null || hide == undefined) {
    hide = TestPanel.panelDataShown ? true : false;
  }

  var panelViewDiv = $('fe_panel_view');
  var panelTimelineDivs = panelViewDiv.getElementsBySelector('div.panel_timeline');
  for(var i=0, len = panelTimelineDivs.length; i < len; i++) {
    var timeline_div = panelTimelineDivs[i];
    // get panel def rows
    var panelDefDiv = timeline_div.getElementsBySelector('div.panel_def')[0];
    // var panelDefTRs = panelDefDiv.getElementsBySelector('tr');
    var panelDefTRs = panelDefDiv.down().down().childElements();

    // get panel data rows
    var dataDiv = timeline_div.getElementsBySelector('div.test_data_table')[0];

    var dataTRs = dataDiv.down('table').rows;

    for (var j=0, length=panelDefTRs.length; j<length; j++) {
      var row = panelDefTRs[j];
      if (checkClassName(row,'panel_info')) {
        if (hide) {
          row.style.display = 'none';
          dataTRs[j].style.display = 'none';
        }
        else {
          row.style.display = 'table-row';
          dataTRs[j].style.display = 'table-row';
        }
      }
    }
  }
  var rowBtnEle = $('fe_show_hide_panel_info');
  if (hide) {
    TestPanel.panelDataShown = false;
    rowBtnEle.firstChild.innerHTML = "Show Panel Info";
  }
  else {
    TestPanel.panelDataShown = true;
    rowBtnEle.firstChild.innerHTML = "Hide Panel Info";
  }

};


/**
 * The Click event handler on the sparkline chart
 * @param e the sparkline div element
 */
TestPanel.Flot.sparklineClickHandler = function(e) {
  if (e.className == 'sparkline') {
    // make the flowsheet stay put when the popup window is closed
    e.setAttribute('tabindex', 100);
    e.focus();
    var tbody = e.up(2);
    var divPanelDef = tbody.up(1);
    var p_loinc_num = divPanelDef.getAttribute('p_no');
    var panelName = 'Plot Chart';
    if ($('fe_in_one_grid_1_1').checked != true ) {
      panelName = panelName + " - " +
      tbody.down('tr.panel_header.panel_l1').down(0).innerHTML;
    }

    var chartDataArray = [];
    // clean up the data cache
    TestPanel.Flot.chartDataExtra = [];

    var selectedTests = tbody.select('input.forplot');
    for (var i=0,len=selectedTests.length; i<len; i++) {
      if (selectedTests[i].checked == true) {
        var t_loinc_num = selectedTests[i].up(0).getAttribute('l_no');
        var chartData = TestPanel.Flot.getPlotData(p_loinc_num,t_loinc_num);
        if (chartData != null) {
          chartDataArray.push(chartData);
        }
      }
    }
    if (chartDataArray.length > 0) {
      TestPanel.Flot.showPlotChart(chartDataArray, panelName, true, true, 'tp_chart_dialog');
    }
    // use the current one if none of the tests is selected
    else {
      t_loinc_num = e.up(0).getAttribute('l_no');
      chartData = TestPanel.Flot.getPlotData(p_loinc_num,t_loinc_num);
      TestPanel.Flot.showPlotChart([chartData], panelName, true, true, 'tp_chart_dialog');
    }
  }
}


TestPanel.Flot.sparklineClickHandler_Old = function(e) {
  if (e.className == 'sparkline') {
    // make the flowsheet stay put when the popup window is closed
    e.setAttribute('tabindex', 100);
    e.focus();
    var tr = e.up(1);
    var tbody = tr.up(0);
    var panelName = 'Plot Chart';
    if ($('fe_in_one_grid_1_1').checked != true ) {
      panelName = panelName + " - " +
      tbody.down('tr.panel_header.panel_l1').down(0).innerHTML;
    }

    var chartDataArray = [];
    // clean up the data cache
    TestPanel.Flot.chartDataExtra = [];

    var selectedTests = tbody.select('input.forplot');
    for (var i=0,len=selectedTests.length; i<len; i++) {
      if (selectedTests[i].checked == true) {
        var sparklineDiv = selectedTests[i].next();
        var chartData = TestPanel.Flot.getPlotDataFromDiv(sparklineDiv);
        if (chartData != null) {
          chartDataArray.push(chartData);
        }
      }
    }
    if (chartDataArray.length > 0) {
      TestPanel.Flot.showPlotChart(chartDataArray, panelName, true, true, 'tp_chart_dialog');
    }
    // use the current one if none of the tests is selected
    else {
      chartData = TestPanel.Flot.getPlotDataFromDiv(e);
      TestPanel.Flot.showPlotChart([chartData], panelName, true, true, 'tp_chart_dialog');
    }

  }

}


/**
 * get the plot data from the the sparkline div
 *@param sparklineDiv the div that contains the plot data
 *
 *Return chartData
 */
TestPanel.Flot.getPlotDataFromDiv_NotUsed = function(sparklineDiv) {

  var chartData = null;

  if (sparklineDiv != null && sparklineDiv != undefined) {
    var tr = sparklineDiv.up(1);
    var testName = tr.down(0).innerHTML;
    var units = sparklineDiv.getAttribute('units');
    var strDataTime = sparklineDiv.getAttribute('values');
    var dataType = sparklineDiv.getAttribute('type');

    var strDataTimeArray = strDataTime.split(',');
    var dataArray = [];

    for (var i = 0, len = strDataTimeArray.length; i < len; i++) {
      var timeData = strDataTimeArray[i].split(":");
      dataArray.push([parseFloat(timeData[0]), parseFloat(timeData[1])]);
    }

    // normal range
    var normMax = parseFloat(sparklineDiv.getAttribute('sparknormalrangemax'));
    var normMin = parseFloat(sparklineDiv.getAttribute('sparknormalrangemin'));
    normMax = isNaN(normMax) ? null : normMax
    normMin = isNaN(normMin) ? null : normMin

    chartData = {
      'name': testName,
      'data': dataArray,
      'norm_max': normMax,
      'norm_min': normMin,
      'units': units,
      'type': dataType
    };
  }
  return chartData;
}


/**
 * get the data for sparkline for one test in one test panel record
 * @param p_loinc_num the loinc number of the panel
 * @param t_loinc_num the loinc number of the test
 * @return a hash map that contains the plot data and options
 */
TestPanel.Flot.getPlotData = function(p_loinc_num, t_loinc_num) {

  var retVal = null;
  if (p_loinc_num && t_loinc_num && TestPanel.panelInfo) {
    var testData = TestPanel.panelInfo[p_loinc_num];
    if (testData) {
      for(var i=0, ilen=testData.length; i<ilen; i++) {
        if (testData[i] && testData[i]['chartData'] &&
            testData[i]['loincNum'] &&
            testData[i]['loincNum'] == t_loinc_num) {
          var dataArray = [];
          var chartData = testData[i]['chartData']
          for (var j=0, jlen=chartData['values'].length; j<jlen; j++) {
            if (chartData['values'][j] != null) {
              var timeData = chartData['values'][j].split(":");
              dataArray.push([parseFloat(timeData[0]), parseFloat(timeData[1])]);
            }
          }

          retVal = {
            'name': testData[i]['testName'],
            'data': dataArray,
            'norm_max': chartData['normal_range']['max'],
            'norm_min': chartData['normal_range']['min'],
            'units': testData[i]['commUnits'],
            'type': chartData['type']
          };
          break;
        }
      }
    }
  }
  return retVal;


  var chartData = null;

  if (sparklineDiv != null && sparklineDiv != undefined) {
    var tr = sparklineDiv.up(1);
    var testName = tr.down(0).innerHTML;
    var units = sparklineDiv.getAttribute('units');
    var strDataTime = sparklineDiv.getAttribute('values');
    var dataType = sparklineDiv.getAttribute('type');

    var strDataTimeArray = strDataTime.split(',');
    var dataArray = [];

    for (var i = 0, len = strDataTimeArray.length; i < len; i++) {
      var timeData = strDataTimeArray[i].split(":");
      dataArray.push([parseFloat(timeData[0]), parseFloat(timeData[1])]);
    }

    // normal range
    var normMax = parseFloat(sparklineDiv.getAttribute('sparknormalrangemax'));
    var normMin = parseFloat(sparklineDiv.getAttribute('sparknormalrangemin'));
    normMax = isNaN(normMax) ? null : normMax
    normMin = isNaN(normMin) ? null : normMin

    chartData = {
      'name': testName,
      'data': dataArray,
      'norm_max': normMax,
      'norm_min': normMin,
      'units': units,
      'type': dataType
    };
  }
  return chartData;
}


/** open a popup message when a record is not editable
 * @param text the text of the message
 * @param title the title for the window
 */
TestPanel.showWarning = function(text, title) {
  // Get or construct the warning dialog
  var warningDialog = this.fsWarningDialog_;
  if (!warningDialog) {
    warningDialog = this.fsWarningDialog_ = new Def.NoticeDialog({
      width: 320,
      height: 240,
      position: 'center'
    });
  }
  warningDialog.setContent(text)
  warningDialog.setTitle(title);
  warningDialog.show();
  return warningDialog ;
}


/** open a modal popup message with two buttons (Ok and Cancel)
 * -- not used now
 * @param text the text of the message
 * @param title the title for the window
 * @param funcOk the function to run when the 'Ok' button is clicked
 */
TestPanel.showConfirmation = function(text, title, funcOk) {
  var confirmingDialog = this.fsConfirmingDialog_;
  if (!confirmingDialog) {
    confirmingDialog = this.fsConfirmingDialog_ = new Def.ModalPopupDialog({
      width: 320,
      height: 240,
      position: 'center',
      buttons: {
        OK: function() {
          // undo changes
          funcOk();
          $J(this).dialog("close");
        },
        Cancel: function() {
          $J(this).dialog("close");
        }
      }
    });

    confirmingDialog.setContent(
      '<div id="fsConfirmingMessage" style="margin-bottom: 1em"></div>');
  }
  $('fsConfirmingMessage').innerHTML = text;
  confirmingDialog.setTitle(title);
  confirmingDialog.show();
  return confirmingDialog ;

}


/** Get all previous values of a selected panel
 * @param ele the 'All Previous values' button
 */
TestPanel.getPrevData = function(ele) {
  // get the loinc_num
  var idParts = Def.IDCache.splitFullFieldID(ele.id);
  var loincEleId = idParts[0] + 'tp1_invisible_field_panel_loinc_num' +
      idParts[2];
  var pLoincNum = $(loincEleId).value;
  TestPanel.getPrevDataForLoinc(pLoincNum);
}


/**
 *  Shows the previous values for a particular loinc number.
 */
TestPanel.getPrevDataForLoinc = function(loincNum) {
  // search conditions
  var searchConditions = {
    groupByCode: '',
    dataRangeCode : '',
    dateStart: '',
    dateEnd: '',
    dateEndStr: '',
    loincNums: [loincNum],
    combined: false,
    includeAll: false
  };

  TestPanel.getRecords(searchConditions, TestPanel.showPrevData, false);
}


/** Show all previous data in an jQuery popup (dialog)
 * @param response the ajax call returning object
 */
TestPanel.showPrevData = function(response) {

  try {
    var retData = response.responseText.split('<@SP@>');
    TestPanel.panelInfo = JSON.parse(retData[1]);
    //create a new div if it does not exist
    var divDialog = $('fe_panel_view');
    if (!divDialog) {
      divDialog = document.createElement("div");
    }
    var guidance = "<div class='guidance'> To edit values or see other data, " +
      "click on 'View & Edit Results Timeline' on the main window.</div>";
    var flowsheet = "<div id='fe_panel_view' class='panel_timeline_grp'><div>" +
          retData[0] + "</div></div>";
    divDialog.innerHTML = guidance + flowsheet;

    // jQuery dialog option
    var option = {title: 'All Previous Values',
                   width: 700,
                   height: 'auto',
                   closeOnEscape: true
//                   buttons: [{ text: 'Close',
//                               click: function() { $J(this).dialog('close'); }
//                             }]
                 }
    // show the dialog
    var dialog = $J(divDialog).dialog(option);

    // hide empty rows
    TestPanel.showHideEmptyRows(true, true);

    // hide the sparkline chart column
    $J('.sparkline_chart').hide();
    // resize the panel_def part
    $J('td.fixed_col').width(300); // it's 400px in the css file

    Def.hideLoadingMsg();

    // display loading time
    var msgDiv = $('fe_load_time_td');
    // no toolbar in popup mode
    if (msgDiv) {
      var time = 'Panel data loaded in ' +
        (new Date().getTime() - TestPanel.startLoad_)/1000 + ' seconds';

      msgDiv.innerHTML = time;
      setTimeout("$('fe_load_time_td').innerHTML=''", 15000);
    }

    // set fucous on the dialog (the close button actually) so that
    // the 'escape' key could work to close the dialog
    dialog[0].up().down('.ui-dialog-titlebar-close').focus();
  }
  catch (e) {
    Def.Logger.logException(e);
    Def.reportError(e);
  }

}


// NOT USED. Chart with mutilple y axes, has potential bugs
//
// /**
//   * Opens a pop-up for showing a chart for a selected test
//   * @param chartDataArray an array of hashmaps that contains all the data
//   *        required for displaying a chart for a seleted test
//   * @param panelName the selected panel name
//   * @param showNormRange a flag that indicates if the markings for normal
//   *        range is shown
//   */
//TestPanel.showSinglePlotChart = function(chartDataArray, panelName, showNormRange) {
//  if (chartDataArray != null && chartDataArray != undefined) {
//    // Get or construct the warning dialog
//    var chartDialog = dijit.byId('tp_chart_dialog');
//    if (!chartDialog) {
//      chartDialog = new Def.NoticeDialog({
//        id: 'tp_chart_dialog'
//      });
//      $('content_for_tp_chart_dialog').innerHTML =
//      '<div id="tp_chart_ph"></div>' +
//      '<div id="tp_legend_ph"></div>' +
//      '<table id="tp_overview_table">' +
//      '<tr><td><div id="tp_overview_ph"></div></td>' +
//      '<td>Chart Type:<input type="radio" value="line" id="tp_chart_line"' +
//      ' class="radio_button" name="tp_chart_type" checked="true">Line' +
//      ' <input type="radio" value="bar" id="tp_chart_bar"' +
//      ' class="radio_button" name="tp_chart_type" >Bar</td>' +
//      '<td><button class="rounded" id="tp_reset"><span>Reset</span></button>' +
//      '</td></tr></table>'
//    }
//    // set popup title
//    chartDialog.set('title', panelName);
//    // show the dialog first
//    // flot works on visible elements
//    chartDialog.show();
//
//    var chart = $J("#tp_chart_ph");
//    var legend = $J("#tp_legend_ph");
//    var overview = $J("#tp_overview_ph");
//    var reset = $J("#tp_reset");
//
//    TestPanel.Flot.plotData = [];
//    TestPanel.Flot.overviewData = [];
//    TestPanel.Flot.yaxisOptions = [];
//    TestPanel.Flot.plotOption = {};
//    TestPanel.Flot.overviewOption = {};
//    var markings = [];
//
//    // process each data series
//    for (var i=0, len=chartDataArray.length; i<len; i++) {
//      chartData = chartDataArray[i];
//      TestPanel.Flot.plotData.push(
//          { data: chartData['data'],
//            label: chartData['name'],
//            lines: {lineWidth:2},
//            points: {radius:2},
//            bars: {barWidth:1},
//            shadowSize:1,
//            color: TestPanel.Flot.lineColors[i % 5], //#73A0C8',
//            hoverable:true,
//            yaxis: i+1
//          });
//      // if one data series and to show normal range
//      // get the marking data for normal range
//      if (len == 1 && showNormRange!=null && showNormRange!= undefined) {
//        if (chartData['norm_max'] != null || chartData['norm_min'] != null ) {
//        // has norm_min only
//        if (chartData['norm_max'] == null) {
//          markings =  [
//              //{ color: '#54C571', yaxis: { from: normMin, to: normMax } }
//              { color: '#FFF380', yaxis: {from: chartData['norm_min']} }];
//          var rangeLabel = "Normal Range (from " + chartData['norm_min'] + ")";
//        }
//        // has norm_max only
//        else if (chartData['norm_min'] == null) {
//          markings = [ { color: '#FFF380', yaxis: {to: chartData['norm_max']}}];
//          rangeLabel = "Normal Range (to " + chartData['norm_max'] + ")";
//        }
//        // has both
//        else {
//          markings = [ { color: '#FFF380', yaxis: {from: chartData['norm_min'],
//              to: chartData['norm_max']}}];
//          rangeLabel = "Normal Range (from " + chartData['norm_min'] + " to "+
//              chartData['norm_max'] + ")";
//        }
//        // add a series for dispaying a legeng of normal_range only
//        TestPanel.Flot.plotData.push(
//            { data: chartData['data'],
//              label: rangeLabel,
//              lines: {show:false},
//              points: {show:false},
//              bars: {show:false},
//              color: '#FFF380',
//              hoverable:false
//            });
//        }
//      }
//
//      // put y axis on the left side or the right side
//      var position = 'left';
//      if (i % 2 == 1) { position = 'right'; }
//
//      // y axis option for time data
//      if (chartData['type'] == 'TS') {
//        TestPanel.Flot.yaxisOptions.push(
//            { tickColor: TestPanel.Flot.lineColors[i % 6],
//              color: TestPanel.Flot.lineColors[i % 6],
//              position: position,
//              mode: "time", timeformat: "%H:%M %p"
//            });
//      }
//      else {
//        TestPanel.Flot.yaxisOptions.push(
//            { tickColor: TestPanel.Flot.lineColors[i % 6],
//              color: TestPanel.Flot.lineColors[i % 6],
//              position: position
//            });
//      }
//
//      //over view plot
//      TestPanel.Flot.overviewData.push(
//          { data: chartData['data'],
//            label: chartData['name'],
//            lines: {lineWidth:1},
//            bars:{barWidth:1},
//            shadowSize:0,
//            color: TestPanel.Flot.lineColors[i % 6] //#73A0C8',
//          });
//    }
//
//    // plot option
//    TestPanel.Flot.plotOption = {
//        grid: { hoverable: true, markings: markings, autoHighlight:true},
//        xaxes: [{ mode: "time", timeformat: "%b %d %y"}],
//        yaxes: TestPanel.Flot.yaxisOptions,
//        legend: { container: legend, noColumns: 3},
//        selection: { mode: "x" },
//        lines: {show:true},
//        points: {show:true},
//        bars: {show:false}
//
//    };
//
//    // create the plot
//    var plot = $J.plot(chart, TestPanel.Flot.plotData,
//        TestPanel.Flot.plotOption);
//
//    // overview option
//    TestPanel.Flot.overviewOption = {
//        grid: { hoverable: false, autoHighlight: false},
//        xaxis: { ticks: [], mode: "time"},
//        yaxis: { ticks: [], autoscaleMargin: 0.1 },
//        legend: { show: false},
//        selection: { mode: "x" , color: "#F75D59"}, //"#e8cfac"
//        lines: {show:true},
//        points: {show:false},
//        bars: {show:false}
//    };
//    // create the overview
//    var overviewChart = $J.plot(overview, TestPanel.Flot.overviewData,
//        TestPanel.Flot.overviewOption);
//
//    // handle the plothover event on the plot
//    chart.bind("plothover", TestPanel.Flot.plotHoverHandler);
//
//    // now connect the plot and the overview
//    chart.bind("plotselected", function (event, ranges) {
//      // get the chart type
//      var newPlotOption = {};
//      var chart = $J("#tp_chart_ph");
//      // lines
//      if ($('tp_chart_line').checked) {
//        $J.extend(true, newPlotOption, TestPanel.Flot.plotOption, {
//            lines: {show:true}, points: {show:true}, bars:{show:false} });
//      }
//      // bars
//      else {
//        $J.extend(true, newPlotOption, TestPanel.Flot.plotOption, {
//            lines: {show:false}, points: {show:false}, bars: {show:true} });
//      }
//      // do the zooming
//      plot = $J.plot(chart, TestPanel.Flot.plotData,
//          $J.extend(true, {}, newPlotOption, {
//          xaxis: { min: ranges.xaxis.from, max: ranges.xaxis.to }
//          }));
//
//      // don't fire event on the overview to prevent eternal loop
//      overviewChart.setSelection(ranges, true);
//    });
//
//    overview.bind("plotselected", function (event, ranges) {
//        plot.setSelection(ranges);
//    });
//
//    // add the reset function
//    reset.bind('click', TestPanel.Flot.plotResetHandler);
//
//    $J("#tp_chart_dialog").bind('')
//  }
//}


/**
   * Opens a pop-up for showing a chart for a selected test
   * @param chartDataArray an array of hashmaps that contains all the data
   *        required for displaying a chart for a seleted test
   * @param panelName the selected panel name
   * @param showNormRange a flag that indicates if the markings for normal
   *        range is shown
   * @param in_a_dialog to show the chart in a dialog or in a page
   * @param container_id the id of the element that contains the chart
   */
TestPanel.Flot.showPlotChart = function(chartDataArray, panelName,
    showNormRange, in_a_dialog, container_id) {

  if (in_a_dialog == null || in_a_dialog == undefined) {
    in_a_dialog = false;
  }
  if (chartDataArray != null && chartDataArray != undefined ) {
    if (in_a_dialog) {
      var chartDialog = this.chartDialog_;
      if (!chartDialog) {
        chartDialog = this.chartDialog_ = new Def.NoticeDialog({
          width: 850
        });
        chartDialog.setContent(
          '<div id="tp_chart_wrap">' +
          '<div id="tp_chart_div"></div></div>' +
          '<table id="tp_overview_table">' +
          '<tr><td><div id="tp_overview_ph"></div></td>' +
          '<td>Chart Type:<input type="radio" value="line" id="tp_chart_line"' +
          ' class="radio_button" name="tp_chart_type" checked="true">Line' +
          ' <input type="radio" value="bar" id="tp_chart_bar"' +
          ' class="radio_button" name="tp_chart_type" >Bar</td>' +
          '<td><button class="rounded" id="tp_reset"><span>Reset</span></button>' +
          '</td></tr></table>')
      }
      // set popup title
      chartDialog.setTitle(panelName);
      // show the dialog first
      // flot works on visible elements
      chartDialog.show();
      // set default selection to 'line'
      $('tp_chart_line').checked = true;
    }
    // in a normal page
    else {
      $(container_id).innerHTML =
      '<div id="tp_chart_wrap">' +
    '<div id="tp_chart_div"></div></div>' +
    '<table id="tp_overview_table">' +
    '<tr><td><div id="tp_overview_ph"></div></td>' +
    '<td>Chart Type:<input type="radio" value="line" id="tp_chart_line"' +
    ' class="radio_button" name="tp_chart_type" checked="true">Line' +
    ' <input type="radio" value="bar" id="tp_chart_bar"' +
    ' class="radio_button" name="tp_chart_type" >Bar</td>' +
    '<td><button class="rounded" id="tp_reset"><span>Reset</span></button>' +
    '</td></tr></table>'
    }


    var chartDiv = $J("#tp_chart_div");
    // clean up existing tp_chart and tp_legend divs
    chartDiv.empty();
    // reset variables
    TestPanel.Flot.plotData = [];
    TestPanel.Flot.overviewData = [];
    TestPanel.Flot.yaxisOptions = [];
    TestPanel.Flot.plotOptions = [];
    TestPanel.Flot.overviewOption = {};
    TestPanel.Flot.chartEles = [];
    TestPanel.Flot.flots = []; // the flot object array
    TestPanel.Flot.overviewFlot = null;
    TestPanel.Flot.numOfPlots = chartDataArray.length;
    TestPanel.Flot.chartDataExtra = [];

    // get the min and max values of the x values (time stamps)
    var dataArray = chartDataArray[0]['data'];
    var min =   dataArray[0][0];
    var max = dataArray[dataArray.length-1][0];
    for (var i=1; i < TestPanel.Flot.numOfPlots; i++) {
      dataArray = chartDataArray[i]['data'];
      if (min > dataArray[0][0]) {
        min = dataArray[0][0];
      }
      if (max < dataArray[dataArray.length-1][0]) {
        max = dataArray[dataArray.length-1][0]
      }
    }

    // process each data series
    for (i=0; i < TestPanel.Flot.numOfPlots; i++) {
      var chartData = chartDataArray[i];
      // cache the data for display in the hangover event
      TestPanel.Flot.chartDataExtra.push(
      {
        units: chartData['units'],
        type: chartData['type'],
        norm_min: chartData['norm_min'],
        norm_max: chartData['norm_max']
      });

      var markings = [];
      var chartDataSeries = [
      {
        data: chartData['data'],
        label: chartData['name'],
        lines: {lineWidth:2},
        points: {radius:2},
        //barWidth is in the units of the x axis
        // here x axis is a time series the unit is miliseconds.
        // a day = 24 * 60 * 60 * 1000
        // we use half a day as the unit for y axis
        bars: {barWidth:43200000},
        shadowSize:1,
        color: TestPanel.Flot.lineColors[i % 5], //#73A0C8',
        hoverable:true //,
      //yaxis: i+1
      }];
      // if to show normal range
      // get the marking data for normal range
      if ( showNormRange!=null && showNormRange!= undefined) {
        if (chartData['norm_max'] != null || chartData['norm_min'] != null ) {
          // has norm_min only
          if (chartData['norm_max'] == null) {
            markings =  [
            //{ color: '#54C571', yaxis: { from: normMin, to: normMax } }
            {
              color: '#FFF380',
              yaxis: {from: chartData['norm_min']}
            }];
          var rangeLabel = "Normal Range (from " + chartData['norm_min'] + ")";
          }
          // has norm_max only
          else if (chartData['norm_min'] == null) {
            markings = [{
              color: '#FFF380',
              yaxis: {to: chartData['norm_max']}
            }];
            rangeLabel = "Normal Range (to " + chartData['norm_max'] + ")";
          }
          // has both
          else {
            markings = [ {
              color: '#FFF380',
              yaxis: {from: chartData['norm_min'], to: chartData['norm_max']}
            }];
            rangeLabel = "Normal Range (from " + chartData['norm_min'] + " to "+
                chartData['norm_max'] + ")";
          }
          // add a series for dispaying a legend of normal_range only
          chartDataSeries.push(
          {
            data: chartData['data'],
            label: rangeLabel,
            lines: {show:false},
            points: {show:false},
            bars: {show:false},
            color: '#FFF380',
            hoverable:false
          });
        }
      }
      TestPanel.Flot.plotData.push(chartDataSeries);

      // put y axis on the left side or the right side
      var position = 'left';
      var yaxisOption = {};
      // store the y axis option for time data
      if (chartData['type'] == 'TS') {
        yaxisOption =
        {
          tickColor: TestPanel.Flot.lineColors[i % 6],
          color: TestPanel.Flot.lineColors[i % 6],
          position: position,
          mode: "time",
          timeformat: "%H:%M %p",
          labelWidth: 40 // pixels

        };
      }
      else {
        yaxisOption =
        {
          tickColor: TestPanel.Flot.lineColors[i % 6],
          color: TestPanel.Flot.lineColors[i % 6],
          position: position,
          labelWidth: 40 // pixels
        };
      }
      TestPanel.Flot.yaxisOptions.push(yaxisOption);

      //store the overview plot data,
      //(normal range data is not in the overview chart)
      TestPanel.Flot.overviewData.push(
      {
        data: chartData['data'],
        label: chartData['name'],
        lines: {lineWidth:1},
        bars:{barWidth:1},
        shadowSize:0,
        color: TestPanel.Flot.lineColors[i % 6] //#73A0C8',
      });

      // chart and legend div element
      var eles = TestPanel.Flot.createChartElements(i);
      TestPanel.Flot.chartEles.push(eles[0]);

      // store the each plot's option
      TestPanel.Flot.plotOptions.push(
      {
        grid: {hoverable: true, markings: markings, autoHighlight:true},
        xaxis: {mode: "time", timeformat: "%b %d %y", min: min, max: max},
        yaxis: yaxisOption,
        legend: {container: eles[1], noColumns: 3},
        selection: {mode: "x"},
        lines: {show:true},
        points: {show:true},
        bars: {show:false}
      });
    }

    // store the overview option
    TestPanel.Flot.overviewOption = {
      grid: {hoverable: false, autoHighlight: false},
      xaxis: {ticks: [], mode: "time", min: min, max: max},
      yaxis: {ticks: [], autoscaleMargin: 0.1},
      legend: {show: false},
      selection: {mode: "x" , color: "#F75D59"}, //"#e8cfac"
      lines: {show:true},
      points: {show:false},
      bars: {show:false}
    };

    // create the overview plot chart
    var overview = $J("#tp_overview_ph");
    var overviewPlot = $J.plot(overview, TestPanel.Flot.overviewData,
      TestPanel.Flot.overviewOption);

    // set up the overview plot selection event listener
    overview.bind("plotselected", function (event, ranges) {
      // only need to trigger event on one chart, other charts are updated in
      // in the chart's event handler
      TestPanel.Flot.flots[0].setSelection(ranges);
    });
    // store the overview plot object
    TestPanel.Flot.overviewFlot = overviewPlot;

    // make the chart bigger if there's only one chart
    if (TestPanel.Flot.numOfPlots == 1) {
      $J('div.tp_chart').height('350');
    }

    // process each plot chart and its event listener
    for (i=0; i < TestPanel.Flot.numOfPlots; i++) {
      var chart = $J(TestPanel.Flot.chartEles[i]);
      // create the plot
      var plot = $J.plot(chart, TestPanel.Flot.plotData[i],
        TestPanel.Flot.plotOptions[i]);
      // store each plot object
      TestPanel.Flot.flots.push(plot);

      // handle the plothover event on the plot
      chart.bind("plothover", TestPanel.Flot.plotHoverHandler);

      // now connect the plot and the overview
      chart.bind("plotselected", TestPanel.Flot.plotSelectedHandler);
    }

    // add the reset function
    $J("#tp_reset").bind('click', TestPanel.Flot.plotResetHandler);

    if (in_a_dialog) $J("#"+container_id).bind('');
  }
}


/**
 * Create a chart div that will contains a plot chart
 * @param sn the sequence number of the plot chart
 */
TestPanel.Flot.createChartElements = function(sn) {
  var chartDiv = $J("#tp_chart_div");

  var newChart = document.createElement("div");
  //newChart.setAttribute("id","tp_chart_ph");
  newChart.setAttribute("class","tp_chart");
  newChart.setAttribute("sn",sn);
  chartDiv.append(newChart);
  var newLegend = document.createElement("div");
  //newLegend.setAttribute("id","tp_legend_ph");
  newLegend.setAttribute("class","tp_legend");
  chartDiv.append(newLegend);

  return [newChart, newLegend]
}



/**
 * format hours and minutes by adding the heading of 0 if it is
 * a single digit value.
 * @param s a string of the hours or minutes
 */
TestPanel.formatTime = function (s) {
  return (s.toString().length ==1 ) ? "0"+s : s;
};


/**
 * plot selection event handler
 * @param event the click event on the reset button
 * @param ranges the selected data ranges
 */
TestPanel.Flot.plotSelectedHandler = function(event, ranges) {
  var sn = event.target.getAttribute('sn');
  sn = parseInt(sn);

  TestPanel.Flot.flots = [];
  // process each plot chart option
  for (var i=0; i < TestPanel.Flot.numOfPlots; i++) {
    var chart = $J(TestPanel.Flot.chartEles[i]);
    var newPlotOption = {};
    // lines
    if ($('tp_chart_line').checked) {
      $J.extend(true, newPlotOption, TestPanel.Flot.plotOptions[i], {
        lines: {show:true},
        points: {show:true},
        bars:{show:false}
      });
    }
    // bars
    else {
      $J.extend(true, newPlotOption, TestPanel.Flot.plotOptions[i], {
        lines: {show:false},
        points: {show:false},
        bars: {show:true}
      });
    }
    // do the zooming on each plot
    var plot = $J.plot(chart, TestPanel.Flot.plotData[i],
      $J.extend(true, {}, newPlotOption,
          {xaxis: {min: ranges.xaxis.from, max: ranges.xaxis.to}
      }));
    TestPanel.Flot.flots.push(plot);
  }

  // set range on the overview chart
  // don't fire event on the overview to prevent eternal loop
  TestPanel.Flot.overviewFlot.setSelection(ranges, true);
}


/**
 * plot reset button click event handler
 * @param event the click event on the reset button
 */
TestPanel.Flot.plotResetHandler = function (event) {

  TestPanel.Flot.flots = [];
  // process each plot chart option
  for (var i=0; i < TestPanel.Flot.numOfPlots; i++) {
    var chart = $J(TestPanel.Flot.chartEles[i]);
    var newPlotOption = {};
    // lines
    if ($('tp_chart_line').checked) {
      $J.extend(true, newPlotOption, TestPanel.Flot.plotOptions[i], {
        lines: {show:true},
        points: {show:true},
        bars:{show:false}
      });
    }
    // bars
    else {
      $J.extend(true, newPlotOption, TestPanel.Flot.plotOptions[i], {
        lines: {show:false},
        points: {show:false},
        bars: {show:true}
      });
    }
    // create the plot
    var plot = $J.plot(chart, TestPanel.Flot.plotData[i],
      newPlotOption);
    TestPanel.Flot.flots.push(plot);
  }

  // get the chart type
  var newOverviewOption = {};
  // lines
  if ($('tp_chart_line').checked) {
    $J.extend(true, newOverviewOption, TestPanel.Flot.overviewOption, {
      lines: {show:true},
      points: {show:false},
      bars:{show:false}
    });
  }
  // bars
  else {
    $J.extend(true, newOverviewOption, TestPanel.Flot.overviewOption, {
      lines: {show:false},
      points: {show:false},
      bars:{show:true}
    });
  }
  // redraw the overview
  $J.plot($J("#tp_overview_ph"), TestPanel.Flot.overviewData,
    newOverviewOption);
  // remove the tooltip, just in case
  $J("#chart_tooltip").remove();
  TestPanel.Flot.previousPoint = null
};


/**
 * the plothover envent handler
 * @param event the 'plothover' event
 * @param pos the position of the mouse
 * @param item the data point item at the poistion
 *
 */
TestPanel.Flot.plotHoverHandler = function (event, pos, item) {
  if (item) {
    var sn = event.target.getAttribute('sn');
    sn = parseInt(sn);

    if (TestPanel.Flot.previousPoint == null ||
      TestPanel.Flot.previousPoint[0] != item.datapoint[0] ||
      TestPanel.Flot.previousPoint[1] != item.datapoint[1]) {

      TestPanel.Flot.previousPoint = item.datapoint;

      $J("#chart_tooltip").remove();
      // values at the data point
      var x = item.datapoint[0],
      y = item.datapoint[1];
      var testDate = new Date(x);
      var strDate = testDate.toString("MMM dd yyyy");
      var strTime = TestPanel.formatTime(testDate.getHours()) + ':' +
      TestPanel.formatTime(testDate.getMinutes()) + ':' +
      TestPanel.formatTime(testDate.getSeconds());
      if (TestPanel.Flot.chartDataExtra[sn]['type'] == 'TS') {
        var time = new Date(y);

        var content = TestPanel.formatTime(time.getUTCHours()) + ':' +
        TestPanel.formatTime(time.getUTCMinutes()) + " on " + strDate;
      }
      else {
        if (TestPanel.Flot.chartDataExtra[sn]['units']) {
          content = y + " " + TestPanel.Flot.chartDataExtra[sn]['units'] +
              " at " +strTime + " on " + strDate;
        }
        else {
          content = y + " at " +strTime + " on " + strDate;
        }
      }
      //      // normal range
      //      var normMin = TestPanel.Flot.chartDataExtra[dataKey]['norm_min'];
      //      var normMax = TestPanel.Flot.chartDataExtra[dataKey]['norm_max'];
      //      if (normMax != null || normMin != null ) {
      //        // has norm_min only
      //        if (normMax == null) {
      //          var rangeLabel = "Normal Range (from " + normMin+ ")";
      //        }
      //        // has norm_max only
      //        else if (normMin == null) {
      //          rangeLabel = "Normal Range (to " + normMax + ")";
      //        }
      //        // has both
      //        else {
      //          rangeLabel = "Normal Range (from " + normMin + " to "+
      //              normMax + ")";
      //        }
      //        content += "<br>" + rangeLabel;
      //      }

      // add tooltip
      $J('<div id="chart_tooltip">' + content + '</div>').css( {
        position: 'absolute',
        display: 'none',
        top: item.pageY + 5,
        left: item.pageX + 5,
        border: '1px solid #fdd',
        padding: '2px',
        'background-color': '#fee',
        opacity: 0.80,
        'z-index': 10000
      }).appendTo("body").fadeIn(200);
    }
  }
  else {
    $J("#chart_tooltip").remove();
    TestPanel.Flot.previousPoint = null;
  }
};


/**
 * expand or collapse one grouped column in the test panel data table
 * @param button the expand img button
 * @param collapse to collapse or expand
 */
TestPanel.expColColumn = function(button, collapse) {
  // no collapse provided when called by the img button onclick listener
  if (collapse == null || collapse == undefined) {
    collapse = TestPanel.grouped_col_expanded ? true : false;
  }

  // get the common class name
  var parentTH = button.parentNode;
  var classes = parentTH.getAttribute('class').split(' ');
  var commonClass = '';
  for(var i=0; i< 2; i++ ) {
    if ( classes[i] != 'sum') {
      commonClass = classes[i];
      break;
    }
  }

  // find the parent node: div.test_data_table
  var panelDataDiv = parentTH.parentNode.parentNode.parentNode.parentNode;
  // find all the elements in the current column and hide them
  var elesInCol = panelDataDiv.getElementsBySelector('.sum.'+commonClass);
  for(var i=0, len = elesInCol.length; i < len; i++) {
    var eleInCol = elesInCol[i];
    // get style.display value
    if (eleInCol.nodeName != 'COL') {
      if (collapse) {
        var displayValue='table-cell';
      }
      else {
        displayValue='none';
      }
      eleInCol.style.display=displayValue;
    }
  }

  // find all the elements in the related data columns and show them
  var dataElesInCol = panelDataDiv.getElementsBySelector('.rec.'+commonClass);
  for(i=0, len = dataElesInCol.length; i < len; i++) {
    var ele = dataElesInCol[i];
    // get style.display value
    if (ele.nodeName != 'COL') {
      if (collapse) {
        displayValue='none';
      }
      else {
        displayValue='table-cell';
      }
      ele.style.display=displayValue;
    }
  }
};


///**
// * set the height of each row in test data table to be same as the height of
// * corresponding row in the test panel definition tabl
// * not used
// */
//TestPanel.resetDataTableRowHeight = function () {
//  var panelViewDiv = $('fe_panel_view');
//  var panelTimelineDivs = panelViewDiv.select('div.panel_timeline');
//  for(var i=0, len = panelTimelineDivs.length; i < len; i++) {
//    var timeline_div = panelTimelineDivs[i];
//    // get panel def rows
//    var panelDefDiv = timeline_div.down('div.panel_def', 0);
//    var panelDefTRs = panelDefDiv.select('tr');
//    // get panel data rows
//    var dataDiv = timeline_div.down('div.test_data_table', 0);
//    var dataTRs = dataDiv.select('tr');
//    var trHeights = [];
//    for (var j=0, length=panelDefTRs.length; j<length; j++) {
//      var rowHeight = panelDefTRs[j].getHeight() + "px";
//      trHeights.push(rowHeight);
//    }
//    for ( j=0, length=panelDefTRs.length; j<length; j++) {
//      rowHeight = trHeights[j];
//      dataTRs[j].style.height = rowHeight;
//    }
//  }
//};


/**
 * Opens a flowsheet modal popup window from the PHR main form.
 */
TestPanel.openTimelineView = function() {
  var strURL = "/profiles/" + Def.DataModel.id_shown_ + "/panels";
  var popup = openPopup(null, strURL, 'View & Edit Results Timeline', null,
                        'panel_view', true, true);
}; // end openTimelineView


/**
 * Opens a modal panel_edit popup window from the either the flowsheet page
 * OR from the main PHR page.
 */
TestPanel.openNewPanelEditor = function() {
  var option = {
    action: 'new',
    profileIdShown: Def.DataModel.id_shown_
  };
  var strURL = "/profiles/" + option.profileIdShown + "/panel_edit";
  TestPanel.popupOption['panel_add'] = option;
  var popup = openPopup(null, strURL, 'Add Trackers & Test Results', null,
                        'panel_edit', true, true);
};


/**
 * Unload listener for popup window which is used for either editing or creating
 * tests. In dev and prod modes, it should be a modal popup. In test mode, we
 * need to use the non-modal version to continue our testing inside the popup.
 * @param isModal a flag indicating whether the popup is a modal or not
 * @param popup the popup window
 */
TestPanel.testEditingPopupUnloadListener = function(isModal, popup) {
  if (isModal){
    TestPanel.refreshWindowBasedOnTestDataChanges(window);
  }
  else{
    Event.observe(popup, "unload", function(){
      TestPanel.refreshWindowBasedOnTestDataChanges(this);
    }.bind(Def.getWindowOpener(popup)));
  }
}


/**
 * Update exisiting panel list
 */

TestPanel.updatePanelList = function() {
  Def.showLoadingMsg();
  var btnShow = $(TestPanel.panelListOption.btnID);
  if (btnShow) {
    btnShow.style.display='none';
  }
  new Ajax.Request(TestPanel.panelListOption.dataURL,
      {method: 'GET',
        parameters: {
          fd_id: TestPanel.panelListOption.fdID,
          col_num: TestPanel.panelListOption.colNum,
          id_shown: Def.DataModel.id_shown_
        },
        onSuccess: function(transport) {
          var staticTable = transport.responseText ;
          TestPanel.replacePanelList(staticTable);
          if (btnShow) {
            btnShow.style.display='inline';
          }
          Def.hideLoadingMsg();
        },
        onFailure: function(transport) {
          Def.hideLoadingMsg();
        }
      });
}


/**
 * Updates the window with its embedded data based on the test data changes
 * @param win the openning window which will become outdated due to the test
 *        data changes. There are two such windows: PHR window and flowsheet
 *        window.
 */
TestPanel.refreshWindowBasedOnTestDataChanges = function(win){
  var phrPatt = /^\/profiles\/[0-9a-z]+;edit$/;
  var flowsheetPatt = /^\/profiles\/[0-9a-z]+\/panels(\?|$)/;
  var pathname = win.location.pathname;
  var openerName = phrPatt.test(pathname) ? "phr" :
   (flowsheetPatt.test(pathname) ? "flowsheet" : null)
  switch(openerName){
    // PHR form
    case "phr":
      win.Def.Rules.updateRuleSystemOnObxDataChanges(win.Def.DataModel.id_shown_);
      break;
    // Flowsheet form
    case "flowsheet":
      win.TestPanel.updatePanelList();
      // Per Ye, refreshing of flowsheet could be very slow if the profile has
      // many tests. Will let user do the updating by clicking the "show flowsheet"
      // button
      //if (TestPanel.dataLoaded){
      //  var showRecordButton = $("fe_show_record_too_1");
      //  TestPanel.showRecord(showRecordButton);
      //}
      break;
    default:// do nothing
  }
}


/**
 * close the flowsheet or add tests & measures page and, if this was a page
 * instead of a popup, return to:
 *  the phr home page if this is the flowsheet; or
 *  the flowsheet if this is the add tests & measures page.
 * (The add tests & measures page usually shows up as a popup, unless it's
 *  being displayed with unsaved changes when the user requests the flowsheet).
 *
 *  NOTE: The close button flowsheet has no need to process the autosave stuffs
 *  because the page is readonly when the close button is shown. It uses the
 *  TestPanel.closeForm() directly.
 *
 * @param showSaveMsg optional parameter indicating whether or not the
 *  Saving message should be displayed while this runs.  Default is true
 * @param save_button also optional but should be the save (not save & close)
 *  button used to invoke the close IF a save button was used
 **/
TestPanel.closeOrReturn = function(showSaveMsg, save_button) {

  if (showSaveMsg == undefined)
    showSaveMsg = true ;
  if (save_button == undefined)
    save_button = null ;

  // Check to make sure there's no unsaved data
  Def.AutoSave.checkForUpdates() ;

  // reset the autosave stuff

  Def.setWaitState(showSaveMsg, save_button) ;

  new Ajax.Request('/form/reset_autosave_base', {
    method: 'post',
    parameters: {
      authenticity_token: window._token,
      profile_id: Def.DataModel.id_shown_,
      form_name: Def.DataModel.form_name_,
      data_tbl: Object.toJSON(Def.DataModel.data_table_),
      do_close: true
    },
    onSuccess: onSuccessfulClose,
    onFailure: onFailedClose,
    asynchronous: false
  });

  function onSuccessfulClose(response) {
    //Def.endWaitState();
    TestPanel.closeForm() ;
  } // end onSuccessfulClose

  function onFailedClose(response) {
    //Def.endWaitState();
    var evaled_resp = JSON.parse(response.responseText) ;
    if (evaled_resp == 'do_logout') {
      window.location = Def.LOGOUT_URL ;
    }
    else {
      var msg = 'There were problems closing the window:<br> ' + evaled_resp
      Def.showError(msg,true);
      TestPanel.closeForm() ;
    }
  } // end onFailedClose

}; // end closeOrReturn


/**
 * Close the current form/popup and return to whatever called this
 */
TestPanel.closeForm = function() {

  // If is a case where a request for the flowsheet was diverted to the
  // Add Tests & Measures form, to resolve unsaved changes, the user is
  // now closing the Add Tests & Measures form.  Give them the flowsheet
  // they originally asked for, by replacing the contents of the current
  // page or popup with the flowsheet.

  if (divertedToPanelEdit) {
    Def.setDocumentLocation("/profiles/" + Def.DataModel.id_shown_ + "/panels")
  }

  // Otherwise this was either a popup, so we close it, or a full page,
  // in which case we go back to the PHR Home page (which is the only
  // place that provides the flowsheet as a full page instead of a popup).
  else if (Def.getWindowOpener()) {
    closeWindow() ;
  }
  else {
    Def.setDocumentLocation("/phr_home")
  }
} ;


/**
 *update initial status of buttons on the flow sheet page
 */
TestPanel.updatePanelViewButtons = function() {
  if (TestPanel.dataLoaded != true) {
    $('fe_show_hide_panel_info').style.display = 'none';
    $('fe_show_hide_empty').style.display = 'none';
    $('fe_expand_columns').style.display = 'none';
    $('fe_group_columns').style.display = 'none';
    $('fe_save').style.display = 'none';
    $('fe_cancel').style.display = 'none';
  }
};


/**
 * update the panel templated on the panel_edit form based on the option values
 */
TestPanel.updatePanelTemplate = function() {

  var windowOpener = Def.getWindowOpener();
  if (windowOpener)
    var option = windowOpener.TestPanel.popupOption[window.name];
  else
    option = null ;

  var panelGrpContainer = $('fe_tp1_loinc_panel_temp_grp_0');
  var maxResponses = 0;
  var suffixPrefix = '';
  var panelSeqNo = 1;

  if(option) {
    panelGrpContainer.style.display = 'block';
    switch(option.action) {
      case 'edit':
        TestPanel.getSelectedPanel(option.loincNum, maxResponses,suffixPrefix,
          panelSeqNo, panelGrpContainer, option.profileIdShown, option.obrId);

        // hide the search boxes
        var generator = $('fe_panel_generator_0');
        generator.style.display = 'none';
        var generator2 = $('fe_panel_browser_0');
        generator2.style.display = 'none';
        var searchOption = $('fe_option_grp_0');
        searchOption.style.display = 'none';

        var testTable = $('fe_tp1_loinc_panel_temp_test_1_1_0_tbl');
        var columns = testTable.select('col');
        // hide the 'previous' value
        // note: neither 'display:none' or 'visibility:hidden' works correctly
        // which hides the 4th visible col in the table!
        columns[4].style.width ='0px';
        // when the content type became static text (from input), and the width is
        // resized to 0, the heights of the divs in these cells become bigger than
        // the normal row height, which causes the entire row's height increase
        // a lot. So have to change the div's height to 0px too
        var rows= testTable.select('tr');
        for(var i=0, rlen=rows.length; i<rlen; i++) {
          if (rows[i]) {
            var cols = rows[i].select('td');
            if (cols.length > 0 && cols[4]) {
              var divs = cols[4].select('div');
              if (divs.length > 0) {
                divs[0].style.height = '0px';
              }
            }
            var headers = rows[i].select('th');
            if (headers[4]) {
              headers[4].innerHTML = '';
            }
          }
        }
        break;
      // this is when a pre-loaded panel is shown on the form, and the search
      // section is hidden.
      case 'add':
        // if there's no autosaved data, preload the selected panel,
        // otherwise the selected panel should already be included in the
        // recovered autosaved data, no need to load it again.
        if (!Def.DataModel.recovered_fields_) {
          TestPanel.getSelectedPanel(option.loincNum, maxResponses,suffixPrefix,
            panelSeqNo, panelGrpContainer, option.profileIdShown, null);
        }
        // hide the search boxes
        generator = $('fe_panel_generator_0');
        generator.style.display = 'none';
        generator2 = $('fe_panel_browser_0');
        generator2.style.display = 'none';
        searchOption = $('fe_option_grp_0');
        searchOption.style.display = 'none';
        break;
      // this is where an empty 'add tests & measures' window is created
      // from the phr page or the flowsheet page
      // it also handles the restoration of the autosaved test panel data
      case 'new':
        // not displayed if no recovered autosaved data
        if (Def.DataModel.data_table_['obr_orders'] != null &&
          Def.DataModel.data_table_['obr_orders'].length > 0)
          panelGrpContainer.style.display = 'block' ;
        else
          panelGrpContainer.style.display = 'none';
        // show classes/panels browser
        generator = $('fe_panel_generator_0');
        generator.style.display = 'none';
        generator2 = $('fe_panel_browser_0');
        generator2.style.display = 'block';
        searchOption = $('fe_option_grp_0');
        searchOption.style.display = 'block';
        var panelBrowser = $('fe_search_option_1R_1');
        panelBrowser.checked = true;
        break;
    }
  }
  else {
    // initially not displayed
    if (Def.DataModel.data_table_['obr_orders'] != null &&
      Def.DataModel.data_table_['obr_orders'].length > 0)
      panelGrpContainer.style.display = 'block' ;
    else
      panelGrpContainer.style.display = 'none';
    // show classes/panels browser
    generator = $('fe_panel_generator_0');
    generator.style.display = 'none';
    generator2 = $('fe_panel_browser_0');
    generator2.style.display = 'block';
    searchOption = $('fe_search_option_1');
    searchOption.style.display = 'block';
    panelBrowser = $('fe_search_option_1R_1');
    panelBrowser.checked = true;
  }
};


/*
 * stwich between panel browser and panel search
 * @param ele the radio button
 */
TestPanel.updateSearchOption = function(ele) {
  if (ele.value == 'browse') {
    var generator = $('fe_panel_generator_0');
    generator.style.display = 'none';
    var generator2 = $('fe_panel_browser_0');
    generator2.style.display = 'block';
  }
  else if (ele.value == 'search') {
    generator = $('fe_panel_generator_0');
    generator.style.display = 'block';
    generator2 = $('fe_panel_browser_0');
    generator2.style.display = 'none';
  }
};


/**
 * Add more of the same kind of panel as the panel on which the button is
 * located on the phr form.
 * It opens the 'panel_edit' popup with the selected panel info preloaded and
 * the search section of the 'panel_edit' form is hidden.
 * On the 'panel_edit' form, it add the selected panel at the bottom of the
 * panel seection, just like the panel is added through the search section.
 *
 * @param ele the 'add more' button
 */
TestPanel.addMorePanel = function(ele) {
  // find the panel's loinc_num
  var idParts = Def.IDCache.splitFullFieldID(ele.id);
  var loincEleId = idParts[0] + 'tp1_invisible_field_panel_loinc_num' +
      idParts[2];
  var pLoincNum = $(loincEleId).value;
  // if it's the 'phr' form, open a popup window
  if (Def.DataModel.form_name_ == 'phr') {
    TestPanel.openPanelEditor(pLoincNum);
  }
  // if it's the 'panel_edit' form, add the panel at the bottom
  else if (Def.DataModel.form_name_ == 'panel_edit') {
    TestPanel.attachAPanel(pLoincNum);
  }
};


/**
 *  Opens a modal popup window with preloaded panel definition for
 *  entering new data.
 *
 *  @param pLoincNum the panel's loinc_num
 */
TestPanel.openPanelEditor = function(pLoincNum) {

  var option = {
    action: 'add',
    loincNum: pLoincNum,
    obrId:  null,
    profileIdShown: Def.DataModel.id_shown_
  };

  // maybe one request is enough to get all data back
  // var strURL = "/profiles/" + option.profileIdShown + "/panel_edit?p_num=" +
  //    option.loincNum + '&obr_id=' + option.obrId;

  var strURL = "/profiles/" + option.profileIdShown + "/panel_edit";

  // make a unique window name to ensure a new window is opened every time
  var windowName = 'panel_new_' + new Date().getTime();
  TestPanel.popupOption[windowName] = option;
  openPopup(null, strURL, 'Add Trackers & Test Results', null, windowName,
            true, true);

};


///**
// *  Opens a modal popup window to edit an existing panel record
// */
//TestPanel.editPanel = function() {
//  var option = {
//    action: 'edit',
//    loincNum: TestPanel.selectedPanelLoincNum,
//    obrId:  TestPanel.selectedObrId,
//    profileIdShown: Def.DataModel.id_shown_
//  };
//
//  // maybe one request is enough to get all data back
//  // var strURL = "/profiles/" + option.profileIdShown + "/panel_edit?p_num=" +
//  //     option.loincNum + '&obr_id=' + option.obrId;
//
//  var strURL = "/profiles/" + option.profileIdShown + "/panel_edit";
//  // only specify the window options that differ from the defaults
//  var winProp = "width=800,height=600";
//
//  // make a unique window name to ensure a new window is opened every time
//  var windowName = 'panel_edit_' + new Date().getTime();
//  TestPanel.popupOption[windowName] = option;
//  openPopup(null, strURL, null, winProp, windowName,
//            true, true);
//
//};


/**
 * menu function for 'edit in place'
 */
TestPanel.editPanelInPlace = function() {

  var obrId = TestPanel.selectedObrId;
  var currentStatus = TestPanel.columnDataStatus[obrId];

  // if the taffydb data has not been retrieved, do an ajax call to get the data
  if(currentStatus == null || currentStatus == undefined) {
    TestPanel.getPanel4Edit(Def.DataModel.id_shown_,
      TestPanel.selectedPanelLoincNum, TestPanel.selectedObrId, true);
  }
  // otherwise reuse the existing taffy data
  else {
    // get the obr/obx records
    var obrRecord = Def.DataModel.searchRecord(Def.DataModel.OBR_TABLE,
      [{
        conditions:{
          record_id:obrId
        }
      }])[0];
    var obxRecords = Def.DataModel.searchRecord(Def.DataModel.OBX_TABLE,
      [{
        conditions:{
          _p_id_:obrRecord['_id_']
          }
        }]);

    var obrTaffy = Def.DataModel.taffy_db_[Def.DataModel.OBR_TABLE];
    var obxTaffy = Def.DataModel.taffy_db_[Def.DataModel.OBX_TABLE];

    // previous used sn for edit box
    var panelSN = TestPanel.columnEditBoxSN[obrId];
    if (panelSN == null || panelSN == undefined) {
      panelSN = TestPanel.panelEditBoxSN++;
    }
    // create input fields in the selected column
    TestPanel.createTestEditBox(obrRecord,obxRecords,panelSN);

    // the answer list is lost in the live records
    // add them back from original records before reload form data
    // obr_orders
    var origObrRecord =
    TestPanel.originalPanelDbRecords[obrId][Def.DataModel.OBR_TABLE][0];
    for(var obrKey in origObrRecord) {
      var recordWithList = {};
      var value = origObrRecord[obrKey];
      // if the value is an array
      if (value != null && value !=undefined  && typeof value == 'object' &&
        value.length >=1) {
        var listItems = value[1];
        var listCodes = value[2];
        var opts = value[3];
        var liveValue = obrRecord[obrKey];
        if (opts) {
          recordWithList[obrKey] = [liveValue, listItems, listCodes, opts];
        }
        else {
          recordWithList[obrKey] = [liveValue, listItems, listCodes];
        }

        // get the postion
        var obrPositions = obrTaffy.find(
          {
            record_id:origObrRecord['record_id']
          });
        // update live records with new value.
        // no autosave is needed for this update
        Def.DataModel.doAutosave_ = false;
        Def.DataModel.updateOneRecord(Def.DataModel.OBR_TABLE,
          obrPositions[0]+1, recordWithList,false);
        Def.DataModel.doAutosave_ = true;
      }
    }


    // obx_observations
    var origObxRecords =
    TestPanel.originalPanelDbRecords[obrId][Def.DataModel.OBX_TABLE];
    for(var i=0, len=origObxRecords.length; i<len; i++) {
      for(var obxKey in origObxRecords[i]) {
        recordWithList = {};
        value = origObxRecords[i][obxKey];
        // if the value is an array
        if (value != null && value !=undefined  && typeof value == 'object' &&
          value.length >=1) {
          listItems = value[1];
          listCodes = value[2];
          opts = value[3];
          liveValue = obxRecords[i][obxKey];
          if (opts) {
            recordWithList[obxKey] = [liveValue, listItems, listCodes, opts];
          }
          else {
            recordWithList[obxKey] = [liveValue, listItems, listCodes];
          }

          // get the postion
          var obxPositions = obxTaffy.find(
          {
            record_id:origObxRecords[i]['record_id'],
            _p_id_:obrRecord['_id_']
            });
          // update live records with new value
          // no autosave is needed for this update
          Def.DataModel.doAutosave_ = false;
          Def.DataModel.updateOneRecord(Def.DataModel.OBX_TABLE,
            obxPositions[0]+1, recordWithList,false);
          Def.DataModel.doAutosave_ = true;
        }
      }
    }

    // load data into the edit boxes,
    // which sets up the autocomplter, and removes the lists in the data tables
    Def.DataModel.refreshFormData();
    // update column status
    TestPanel.columnDataStatus[obrId] = TestPanel.COLUMN_STATUS_INEDIT;
    // show the save/cancel buttons
    TestPanel.showHideSaveButtons();
    // set the flag
    TestPanel.inEditMode = true;

    // rerun form rules
    Def.Rules.runFormRules();
  }
};


/**
 * menu function for 'delete'
 */
TestPanel.deletePanelInPlace = function() {

  var obrId = TestPanel.selectedObrId;
  var currentStatus = TestPanel.columnDataStatus[obrId];

  // if the taffydb data has not been retrieved, do an ajax call to get the data
  if(currentStatus == null || currentStatus == undefined) {
    TestPanel.getPanel4Edit(Def.DataModel.id_shown_,
      TestPanel.selectedPanelLoincNum, TestPanel.selectedObrId, false);
  }
  // otherwise resuse the existing taffy data
  else {
    // if it is already in edit mode, recreate static cell content
    if(TestPanel.columnDataStatus[obrId] == TestPanel.COLUMN_STATUS_INEDIT) {
      // create static cell content from original data
      TestPanel.restoreFromOriginalRecords(obrId, false);
    }
    // update record_id
    TestPanel.updateObrObxRecordId(obrId, true);
    // add line-through
    TestPanel.addLineThrough(obrId);
    // update column status
    TestPanel.columnDataStatus[obrId] = TestPanel.COLUMN_STATUS_DELETED;
    // show the save/cancel buttons
    TestPanel.showHideSaveButtons();
    // set the flag
    TestPanel.inEditMode = true;
  }
};



/**
 * menu function for 'undo'
 */
TestPanel.undoEditOrDelete = function() {
  var obrId = TestPanel.selectedObrId;

  // if this column has been in edit mode
  if(TestPanel.columnDataStatus[obrId] == TestPanel.COLUMN_STATUS_INEDIT) {
    TestPanel.undoEditPanelInPlace(obrId);
  }
  // if this column has been deleted
  else if(TestPanel.columnDataStatus[obrId] == TestPanel.COLUMN_STATUS_DELETED){
    TestPanel.undoDeletePanelInPlace(obrId);
  }

  TestPanel.cleanNavData(obrId);
  // reset navigation sequence, not event listeners
  Def.Navigation.doNavKeys(0,0,true,true,true);


};


/**
 * undo edit
 * @param obrId the record_id of the obr record
 */
TestPanel.undoEditPanelInPlace = function(obrId) {
  // undo edit
  TestPanel.restoreFromOriginalRecords(obrId, true);
  // show the save/cancel buttons
  TestPanel.showHideSaveButtons();
  // reset the flag
  TestPanel.inEditMode = false;
};


/**
 * undo delete
 * @param obrId the record_id of the obr record
 */
TestPanel.undoDeletePanelInPlace = function(obrId) {
  // update record_id
  TestPanel.updateObrObxRecordId(obrId, false);
  // remove line-through
  TestPanel.removeLineThrough(obrId);
  // update column status
  TestPanel.columnDataStatus[obrId] = TestPanel.COLUMN_STATUS_UNCHANGED;
  // show the save/cancel buttons
  TestPanel.showHideSaveButtons();
  // reset the flag
  TestPanel.inEditMode = false;

};


/**
 *remove a selected column from table
 *@param obrId the record_id of the obr record
 */
TestPanel.removeAColumn = function(obrId) {
  var divPanelView = $('fe_panel_view');
  // find the tds
  var tdInCol = divPanelView.select('td.' + obrId + ',th.' + obrId);
  for (var j=0, len=tdInCol.length; j<len; j++) {
    tdInCol[j].remove();
  }
};


/**
 * add line-though for one seleclt column
 * @param obrId the record_id of the obr record
 */
TestPanel.addLineThrough = function(obrId) {
  // add line-through on each cell
  var divPanelView = $('fe_panel_view');
  // find the tds
  var tdInCol = divPanelView.select('td.' + obrId + ',th.' + obrId);
  for (var j=0, len=tdInCol.length; j<len; j++) {
    tdInCol[j].addClassName('deleted');
  }
};


/**
 * Remove line-though for one seleclt column
 * @param obrId the record_id of the obr record
 */
TestPanel.removeLineThrough = function(obrId) {
  // remove line-through from cell content
  var divPanelView = $('fe_panel_view');
  // find the tds
  var tdInCol = divPanelView.select('td.' + obrId + ',th.' + obrId);
  for (var j=0, len=tdInCol.length; j<len; j++) {
    tdInCol[j].removeClassName('deleted');
  }
};


/**
 * update record_id on obr and obx tables
 * @param obrId the record_id of the obr record
 * @param toDelete mark the record to delete or not
 */
TestPanel.updateObrObxRecordId = function(obrId, toDelete) {

  // to delete
  if(toDelete) {
    var obrIdSearchVal = obrId;
  }
  // to undelete
  else {
    obrIdSearchVal = 'delete ' + obrId;
  }
  // get the obr/obx records
  var obrRecords = Def.DataModel.searchRecord(Def.DataModel.OBR_TABLE,
    [{
      conditions:{
        record_id:obrIdSearchVal
      }
    }]);

  var obxRecords = Def.DataModel.searchRecord(Def.DataModel.OBX_TABLE,
    [{
      conditions:{
        _p_id_:obrRecords[0]['_id_']
        }
      }]);

  // get the taffydbs
  var obrTaffy = Def.DataModel.taffy_db_[Def.DataModel.OBR_TABLE];
  var obxTaffy = Def.DataModel.taffy_db_[Def.DataModel.OBX_TABLE];
  var obrPositions = obrTaffy.find({
    record_id:obrIdSearchVal
  });

  // to delete records
  // update record_ids to 'delete n' in obr_orders and obx_observations tables
  if (toDelete) {
    // obr_orders
    Def.DataModel.updateOneRecord(Def.DataModel.OBR_TABLE, obrPositions[0]+1,
    {
      record_id: 'delete '+ obrId
      }, false);
    // for each OBX record, update record_id
    for (var i=0, len=obxRecords.length; i<len; i++) {
      var obxPositions = obxTaffy.find({
        record_id:obxRecords[i]['record_id'],
        _p_id_:obrRecords[0]['_id_']
        });
      // mark it to be deleted only if it's an existing record
      if (obxRecords[i]['record_id'] != null &&
          obxRecords[i]['record_id'] != "" ) {
        Def.DataModel.updateOneRecord(Def.DataModel.OBX_TABLE,
            obxPositions[0]+1,
            {record_id: 'delete '+ obxRecords[i]['record_id']},
            false);
      }
    }
  }
  // to undelete, remove the 'delete ' from 'delete n' in record_id
  else {
    // obr_orders
    Def.DataModel.updateOneRecord(Def.DataModel.OBR_TABLE, obrPositions[0]+1,
    {
      record_id: obrId
    }, false);
    // for each OBX record, update record_id
    for (var j=0, len2=obxRecords.length; j<len2; j++) {
      obxPositions = obxTaffy.find({
        record_id:obxRecords[j]['record_id'],
        _p_id_:obrRecords[0]['_id_']
        });
      // mark it to be undeleted only if it's an existing record
      if (obxRecords[j]['record_id'] != null &&
          obxRecords[j]['record_id'] != "" ) {
        Def.DataModel.updateOneRecord(Def.DataModel.OBX_TABLE,
            obxPositions[0]+1,
            {record_id: obxRecords[j]['record_id'].slice(7)},
            false);
      }
    }
  }
};


/**
 * adding new event listener for the mouse down once
 * panel data is loaded on to the page
 *
 */
TestPanel.columnHighlight = function() {
    var editable = false;
    // set up context menu listener
    if ((TestPanel.searchConditions.groupByCode == null ||
        TestPanel.searchConditions.groupByCode == '' ||
        TestPanel.searchConditions.groupByCode == '1') &&
        !TestPanel.searchConditions.combined &&
        !TestPanel.searchConditions.includeAll &&
         Def.formEditability_ !== Def.FORM_READ_ONLY_EDITABILITY) {
      editable = true;
    }
    // add column highlights on mouseover
    $J("div.test_data_table > table").delegate('td,th','mouseenter mouseleave mousedown', function(e) {
      // if the previous ajax call is done
      if (TestPanel.ajaxDone) {
        var dataTable = $J(this).parents("div.test_data_table > table");

        if (e.type == 'mouseenter') {
          // ignore the td, th in the date field
          if ( $J(this).parents("table.dateField").length==0 ) {
            var top = dataTable.offset().top;
            //var left = $J(this).offset().left;
            dataTable.find("col").eq($J(this).index()).addClass("hover");
            if (editable) {
              // show an edit icon on top of the column
              var eleTH = dataTable.find("tr").first().find("th").
                 eq($J(this).index()).append("<img id='doc_edit_icon' src='"+
                 Def.blankImage_+"' style='top:" + (top -15) + "px;'>");
              // attach the contect menu to the image
              var img = eleTH.find("img");
              TestPanel.attachContextMenu(img, {event: 'click'});
            }
          }
        }
        // remove column highlights on mouseleave
        else if( e.type == 'mouseleave') {
          // ignore the td, th in the date field
          if ( $J(this).parents("table.dateField").length==0 ) {
            dataTable.find("col").eq($J(this).index()).removeClass("hover");
            if (editable) {
              dataTable.find("tr").first().find("th").eq($J(this).index()).find("img").remove();
            }
          }
        }
        // on click/mousedown
        else if (e.type == 'mousedown') {
          // ignore the td, th in the date field
          if ( $J(this).parents("table.dateField").length==0 ) {
            var selectedCol = dataTable.find("col").eq($J(this).index());

            // column highlighting not needed for now, 3/13/2013
            //$J("col.selected_col").removeClass("selected_col");
            //selectedCol.addClass("selected_col");

            // get the obrId of the column
            TestPanel.selectedObrId = selectedCol.attr('obr_id');
            // get the panel loinc num
            TestPanel.selectedPanelLoincNum = dataTable.attr('p_no');
            // get the panel loinc num of the current seleted obr record
            TestPanel.selectedObrPanelLoincNum = selectedCol.attr('p_ln');
            TestPanel.selectedObrPName = selectedCol.attr('p_name');
          }
        }
      } // ajaxDone
    });


};


/**
   * Syncronize the test date fields of non-empty observations inside a panel
   * when the panel's test date field (AKA when done field) changed or a new
   * test is added. When an existing test value is cleared, also clear its
   * test date fields (including ET and HL7 fields).
   *
   * @param new_record new value for the test date field of a panel
   * @param taffy_obj the taffy object corresponding to panel test date field
   **/
TestPanel.sync_observation_date = function(new_record, taffy_obj){
  var tableName = taffy_obj.table_name_;
  var debug_msgs = [];
  var show_debug_msg = true;

  // When panel's test_date field changed, test_date fields of the non-empty
  // tests in the same panel should be updated.
  // Same applies to test_date_ET and test_date_HL7 fields
  if (tableName == "obr_orders" && (
    new_record['test_date'] != undefined ||
    new_record['test_date_time'] != undefined ||
    new_record['test_date_ET'] != undefined ||
    new_record['test_date_HL7'] != undefined)){
    // go through all the included tests and
    // update test_date field if it was changed and test_value field is not blank
    var taffy_obx = Def.DataModel.taffy_db_['obx_observations'];
    var positions = taffy_obx.find({
      '_p_id_': taffy_obj.update_position_ -1
      });
    if (!Def.DataModel.in_updating_)
      Def.DataModel.in_updating_ = true;
    for (var i=0,max=positions.length; i<max; i++){
      taffy_position = positions[i];
      var obx_rec = taffy_obx.get(taffy_position)[0];
      if (obx_rec['obx5_value'] != null && !obx_rec['obx5_value'].blank()){
        for (var column in new_record){
          if (obx_rec[column] != new_record[column]){
            var field =
              Def.DataModel.getFormField("obx_observations", column, taffy_position + 1);
            if (field){
              Def.setFieldVal(field, new_record[column]);
              debug_msgs.push([
                "<<<<<< WhenDone Onchange to: " + new_record['test_date'],
                "obx taffy position:" + taffy_position,
                "test value:"+ obx_rec['obx5_value'],
                column + " has new value:"+ new_record[column]].join(" | "))
            }
          }
        }
      }
    }
    if (Def.DataModel.in_updating_)
      Def.DataModel.in_updating_ = false;
  }

  // When a test changed its value, its test_date fields (including ET and HL7)
  // should be sync-ed with the corresponding ones on the panel
  var update = false;
  var update_attributes = null;
  if (tableName == "obx_observations" && (new_record['obx5_value'] != undefined)){
    var taffy_position = taffy_obj.update_position_ -1 ;
    var obx_rec = taffy_obj.get(taffy_position)[0];
    var obr_rec = Def.DataModel.taffy_db_['obr_orders'].get(obx_rec['_p_id_'])[0];

    // do the checking only the obx5_value is string
    // Note: there's case on flowsheet, when a column is 'revised', 'unrevised'
    // and then 'revised' again. The obx5_value will be updated first with an
    // answer list (to be an array) if there's one, which will trigger
    // the functon here.
    if (typeof(new_record['obx5_value']) == 'string' ) {
      if (new_record['obx5_value'].blank()) {
        if (!obx_rec['test_date'].blank()){
          update = true;
          update_attributes = {
            'test_date_ET':"",
            'test_date_HL7':"",
            'test_date':"",
            'test_date_time':""
          };
        }
      }
      else {
        if (obx_rec['test_date'] != obr_rec['test_date']) {
          update = true;
          update_attributes = {
            'test_date_ET':obr_rec["test_date_ET"],
            'test_date_HL7':obr_rec["test_date_HL7"],
            'test_date':obr_rec["test_date"],
            'test_date_time':obr_rec["test_date_time"]
          };
        }
      }
    }
    if (update){
      if (!Def.DataModel.in_updating_)
        Def.DataModel.in_updating_ = true;
      // updating form fields which update their taffyDb fields
      for (var column in update_attributes){
        var field =
          Def.DataModel.getFormField("obx_observations", column, taffy_position+1);
        if (field){
          Def.setFieldVal(field, update_attributes[column]);
          debug_msgs.push(["<<<<<< test_value Onchange to: " + new_record['obx5_value'],
                "obx taffy position:" + taffy_position,
                column + " has new value:"+ update_attributes[column]].join(" | "))
        }
      }
      if (Def.DataModel.in_updating_)
        Def.DataModel.in_updating_ = false;
    }
  }
  if(show_debug_msg && debug_msgs.length > 0)
    Def.Logger.logMessage([debug_msgs.join("\n")]);
};


/**
 * TestPanel Prefix
 **/
TestPanel.PREFIX = 'tp';

/**
 * Target field name for loinc number
 **/
TestPanel.LOINC_NUM_COL_NAME = "test_loinc_num";

/**
 * Used for building a rule trigger with target_field and loinc number. The
 * trigger is used in a hash from triggers to rules
 */
TestPanel.FIELD_LOINC_NUM_DELIMITER = ":";

Object.extend(TestPanel, {
  /**
  * Returns value of a loinc field based on it's target field, panelField and
  * loincNum
  *
  *  @param panelField - an loinc panel field
  *  @param loincNum - an loinc number
  *  @param valueField - target field name of an loinc field
  **/
  getFieldValue: function(panelField, loincNum, valueField){
    // find the field matching to a loinc number by a testDate
    var LoincNumFld = this.getSubFieldFromPanelField(panelField,
      (this.PREFIX + "_" + this.LOINC_NUM_COL_NAME), loincNum);
    var rtn = null;
    if(LoincNumFld)
      rtn = this.getLoincSiblingValue(LoincNumFld, valueField);
    return rtn;
  },


  /**
   * Returns the stripped value of a sibling field in an loinc table row
   *
   * @param sourceField - a source field
   * @param siblingField - a sibling field of the source field
   **/
  getLoincSiblingValue: function(sourceField, siblingField){
    // find the loinc number from the trigger field
    var rtn= null;
    var sib = this.getLoincSibling(sourceField, siblingField);
    if(sib && sib.value != "undefined") rtn = sib.value && sib.value.strip();
    return rtn;
  },


  /**
   * Returns the sibling field of a source field
   *
   * @param sourceField - a source field, it can be either an array of id parts
   * or an DOM element
   * @param siblingField - a sibling field of the source field
   **/
  getLoincSibling: function(sourceField, siblingField){
    // find the loinc number from the trigger field
    if(sourceField instanceof Array){
      var id_parts = sourceField.concat();
    }
    else{
      var id_parts = Def.IDCache.splitFullFieldID(sourceField.id).clone();
    }

    if(siblingField.indexOf(this.PREFIX) ==0)
      siblingField = this.getBaseTargetName(siblingField);

    id_parts[1] = [id_parts[1].split("_")[0], siblingField].join("_");
    return $(id_parts.join(""));
  },


  /**
 * Returns the loinc number of the row of the sourceField
 * @param sourceField - a loinc field
 **/
  getLoincValue: function(sourceField){
    var id_parts = Def.IDCache.splitFullFieldID(sourceField.id).clone();
    id_parts[1] = [id_parts[1].split("_")[0], this.LOINC_NUM_COL_NAME].join("_");
    var lf =  $(id_parts.join(""));
    return lf && lf.value ;
  },

  /**
   *Returns an loinc number and target field in an Array
   *
   *@param tpField - a string consists of target field and loinc number for a
   *loinc field, e.g. "tp_test_value:84820-2"
   **/
  getLoincNumAndTargetField: function(tpField){
    var re = /(tp_(.*?)):([\d-]+)/;
    var m = re.exec(tpField);
    return m ? [m[3], m[1]] : null;
  },


  /**
   * Returns list of loinc number fields under the test date field
   *
   * @param panelField - a loinc panel field
   * @param columnField - target field of a column in loinc panel
   * @param cellValue - value of an field in loinc panel
   **/
  getSubFieldFromPanelField: function(panelField, columnField, cellValue){
    var id_parts = Def.IDCache.splitFullFieldID(panelField.id).clone();
    var valueBaseName= this.getBaseTargetName(columnField);
    id_parts[1] = [id_parts[1].split("_")[0], valueBaseName].join("_");

    var found = false;
    var i = 1;
    var curFld= $([id_parts.join(""), "_", i].join(""));
    while(!found && curFld){
      if(curFld.value == cellValue){
        found = true;
      }
      if(!found)
        curFld= $([id_parts.join(""), "_", ++i].join(""));
    }
    return curFld;
  },


  /**
   * Returns a list of loinc numbers in a test panel
   * @param idPartsInput - ID parts of a panel field
   **/
  getLoincNumbersByPanel: function(idPartsInput){
    var id_parts = idPartsInput.clone();
    id_parts[1] = [id_parts[1].split("_")[0],this.LOINC_NUM_COL_NAME].join("_");
    var list  = [];
    var i = 1;
    var curFld= $([id_parts.join(""), "_", i].join(""));
    while(curFld){
      list.push(curFld.value);
      curFld= $([id_parts.join(""), "_", ++i].join(""));
    }
    return list;
  },

  /**
   * Returns true if this field is an test panel field
   *
   * @param targetField - target field or target field name
   **/
  inTestPanel: function(targetField){
    // target_field is an Element
    if(typeof targetField == "object"){
      var reg = new RegExp("^"+ Def.FIELD_ID_PREFIX + TestPanel.PREFIX + "\\d*_");
      return targetField.id.match(reg) ? true : false;
    }
    // target_field is a String
    return (targetField.substr(0,2) == this.PREFIX);
  },


  /**
   * Returns all the rules associated with the testPanelField using its
   * target_field and loinc number
   *
   * @param testPanelField a trigger field in test panel
   **/
  findLoincRules: function(testPanelField){
    var targetField = Def.IDCache.splitFullFieldID(testPanelField.id)[1];
    targetField = this.getRealTargetName(targetField);
    var loincNumber = this.getLoincNum(testPanelField);
    var triggerName =
    [targetField, loincNumber].join(this.FIELD_LOINC_NUM_DELIMITER);

    return Def.Rules.loincFieldRules_[triggerName] || [];
  },


  /**
   * Returns loinc numbers associated with the input test panel field.
   * 1) when it is a panel field, returns all the loinc numbers of tests inside
   * the panel
   * 2) when it is a single test, returns the loinc number in an single element
   * array
   *
   * @param testPanelField a field in test panel
   */
  getLoincNums: function(testPanelField){
    var triggerIdParts = Def.IDCache.splitFullFieldID(testPanelField.id);
    var rtn = (triggerIdParts[1].indexOf("panel") > -1) ?
    this.getLoincNumbersByPanel(triggerIdParts) :
    this.getLoincSiblingValue(triggerIdParts, this.LOINC_NUM_COL_NAME);
    return (rtn instanceof Array) ? rtn : (rtn ? [rtn] : []);
  },

  /**
   * Returns the loinc number associated with the testPanelField using TaffyDB
   *
   * @param testPanelField a field inside test panel
   */
  getLoincNum: function(testPanelField){
    rtn = null;
    var searchInfo = Def.DataModel.mapping_table_id_[testPanelField.id];
    if(searchInfo){ // searchInfo will be null if the testPanleField is hidden
      var table = searchInfo[0];
      var rowNum = searchInfo[2] - 1;
      var rec = Def.DataModel.data_table_[table][rowNum];
      var rtn = rec && rec['loinc_num'];
    }
    return rtn;
  },


  /**
   * Returns target field name without test panel prefix
   *
   * @param IdPartOne - the second string from a fully splitted ID
   * (e.g. "tp1_test_value") or a target field(e.g. "tp_test_value")
   **/
  getBaseTargetName:function(IdPartOne){
    var rtn = null;
    var tpPrefixReg = new RegExp("^" +this.PREFIX +"(\\d*)?_(.*)");
    var match = tpPrefixReg.exec(IdPartOne);
    if(match){
      rtn= match[2];
    }
    return rtn;
  },


  /**
   * Returns a target field whose test panel prefix is this.PREFIX
   *
   * @param IdPartOne - the second string from a fully splitted ID
   * (e.g. "tp1_test_value") or a target field(e.g. "tp_test_value")
   *
   */
  getRealTargetName: function(IdPartOne){
    return this.PREFIX + "_" + this.getBaseTargetName(IdPartOne);
  },

  /**
   * Returns the label name for any loinc field in test panel
   *
   * @param field - the field for getting the label name
   **/
  getLabelName: function(field){

    var labelName = '';
    var dm = Def.DataModel;
    var dbLocation = dm.getModelLocation(field.id);
    if (dbLocation[0]==dm.OBR_TABLE) {
      labelName = TestPanel.PANEL_INFO_FIELD_NAMES[dbLocation[1]];
      if (labelName == null || labelName == '') {
        labelName =
          dm.getModelFieldValue(dbLocation[0],dbLocation[1], dbLocation[2]);
      }
    }
    else if (dbLocation[0]==dm.OBX_TABLE) {
      labelName =
        dm.getModelFieldValue(dbLocation[0],'obx3_2_obs_ident', dbLocation[2]);
    }

    return this.getPanelHeaderName(field) + " / " + labelName;

  },

  /**
   * Returns the panel header name of an input field
   * @param field - an input field inside a test panel
   **/
  getPanelHeaderName: function(field){

    var labelName = '';
    var dm = Def.DataModel;
    var dbLocation = dm.getModelLocation(field.id);
    if (dbLocation[0]==dm.OBR_TABLE) {
      labelName =
        dm.getModelFieldValue(dbLocation[0],'panel_name', dbLocation[2]);
    }
    else if (dbLocation[0]==dm.OBX_TABLE) {
      var obrPosition =
        dm.getModelFieldValue(dbLocation[0],'_p_id_', dbLocation[2]) + 1;
      labelName = dm.getModelFieldValue(dm.OBR_TABLE,'panel_name',obrPosition);
    }
    return labelName;
  }

});


/**
 * Rule related Functions using DataModel
 * **/
Object.extend(TestPanel, {

  /**
   * A hash containing all useless fields in a sub-panel row stored as keys
   */
  uselessSubpanelRowFields: {
    "test_value": 1,
    "test_lastvalue_date":1,
    "test_unit":1,
    "test_range":1
  },

  /**
   * Returns true if it is a header field of some tests inside a panel and vice
   * versa
   * @param field the input field to be checked to see if it is a header field
   * or not
   */
  inSubpanelHeaderRow: function(field){
    var rtn = false;
    if(this.inTestPanel(field)){
      if (Def.DataModel.initialized_ ) {
        var taffy_location = Def.DataModel.mapping_table_id_[field.id];
        // not all fields in the same column are included in the mapping_table
        if(taffy_location){
          var taffy = Def.DataModel.taffy_db_[taffy_location[0]];
          var record = taffy.get(taffy_location[2]-1)[0];
          rtn = record["is_panel_hdr"];
        }
      }
    }
    return rtn;
  }
});


/**
 * Rule related Functions for finding latest loinc value
 * **/
Object.extend(TestPanel, {
  /**
   * Return the latest value and the latest date in an Array for a loinc number
   *
   * @param loincNum - a loinc number
   * @param opts - a hash map for parameters including the target field for loinc
   * number fields, target fields for last value and date and target fields for
   * individual loinc number's value and date
   **/
  findLatest: function(loincNum, opts){
    var loincNumFlds, currPair, latestPair;
    if(!opts){
      opts = {
        targetField: null,
        lastValueDate:null,
        currentValueDate: null
      };
    }

    loincNumFlds = this.getLoincNumFields(loincNum, opts.targetField);
    latestPair = this.getLastValueDatePair(loincNumFlds[0], opts.lastValueDate);

    for(var i=0, max = loincNumFlds.length; i< max; i++){
      currPair = this.getCurrentValueDatePair(loincNumFlds[i], opts.currentValueDate);
      latestPair = this.getLatestValueDatePair(currPair, latestPair);
    }
    return latestPair;
  },

  /**
   * Returns a list of fields matches to the inputting loincNum
   *
   * @param loincNum - a loinc number
   * @param targetField - the target field for a column of loinc number fields
   **/
  getLoincNumFields: function(loincNum, targetField){
    var rtn = [], loincNumFlds;
    if(!targetField) targetField = "tp_test_loinc_num";

    loincNumFlds = findFields(Def.FIELD_ID_PREFIX, targetField, "");
    for(var i=0, max=loincNumFlds.length; i< max; i++){
      //  if(loincNumFlds[i].value == loincNum && !isHiddenOrDisabled(loincNumFlds[i])){
      if(loincNumFlds[i].value == loincNum ){
        rtn.push(loincNumFlds[i]);
      }
    }
    return rtn;
  },

  /**
   * Returns last value and last date in an Array
   *
   * @param loincFld - a loinc field
   * @param opts - a hash map for target fields of last value and last date
   **/
  getLastValueDatePair: function(loincFld, opts){
    if(!opts){
      opts={
        value: "tp_test_last_value",
        date: "tp_test_lastdate_ET"
      };
    }
    var lastVal = this.getLoincSiblingValue(loincFld, opts.value);
    var lastDate = this.getLoincSiblingValue(loincFld, opts.date);
    return [lastVal, lastDate];
  },

  /**
   * Returns current value and current date in an Array
   *
   * @param loincFld - a loinc field
   * @param opts - a hash map for target fields of the loinc field's value and
   * date
   **/
  getCurrentValueDatePair: function(loincFld, opts){
    if(!opts){
      opts={
        value: "tp_test_value",
        date: "tp_panel_testdate"
      };
    }
    var currVal = this.getLoincSiblingValue(loincFld, opts.value);
    var currDate = this.getPanelFieldValue(loincFld, opts.date);
    var currDate = Def.DateUtils.getEpochTime(currDate);
    return [currVal, currDate];
  },

  /**
   * Returns latest value and latest date in an array by comparing the existing
   * and the new value/date Arrays
   *
   * @param current - new value and new date in an Array
   * @param latest - latest value and latest date in an Array
   **/
  getLatestValueDatePair: function(current, latest){
    if(current[1] && current[0] && current[0].strip().length > 0 ){
      if( latest[1] && latest[0] && latest[0].strip().length > 0
        && current[1] <= latest[1]){
        return latest;
      }
      return current;
    }
    return latest;
  },

  /**
   * Returns value of the loinc panel field
   *
   * @param sourceField - a loinc field
   * @param panelFieldName - a target field in a loinc panel
   **/
  getPanelFieldValue: function(sourceField, panelFieldName){
    var idParts = Def.IDCache.splitFullFieldID(sourceField.id).clone();
    // remove the last digit
    var sourceId = idParts[2];
    sourceId = sourceId.split("_");
    sourceId.pop();
    sourceId = sourceId.join("_");

    idParts[1] = [idParts[1].split("_")[0], this.getBaseTargetName(panelFieldName)].join("_");
    idParts[2] = sourceId;
    return $(idParts.join("")).value;
  }

});
