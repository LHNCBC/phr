/*
 * How to initialize the mobile table?
 *
 * 1) load the raw table with 100 columns (50ms max)
 * 2) convert big cells if any (150ms max)
 *  - find the max # of characters allowed for data cells by row(100ms max)
 *    + Inputs:
 *    + predefined # of characters allowed in both the label and data columns
 *    + json hash (with cell string and indentation)
 *    + Algorithem:
 *    + determined by the number of rows allowed (i.e. min 3) for each row based on label column content and indentation
 *  - convert any cell which has oversized content (50ms) (can be done on table or json hash object) (50ms max?)
 * 2) convert it into mobile table (50ms max)
 *
 *
 * Steps to do lazy loading after the mobile table was initialized (150ms max?):
 *
 * 1) make sure the content is limited to the allowed size (100ms max)
 *  a) get the data in hash format from server (50ms max)
 *  b) convert big cells (50 ms max?)
 * 2) load to the page (50ms)
 *   - add new columns to mobile table using the json hash ( 50ms average)
 *
 * */
Def.dataCellLineChars = 11; // matches to the div.date css 62px while 8 chars matches to 45px
Def.labelCellLineChars = 35;
Def.dataCellMax = [];
Def.oriPanelData = [];
// starting with the second page
Def.maxPage = false;
Def.ajaxRunning = false;
Def.hash_info = null;
Def.columnsPerPage=100;


function  mobilizeTable() {
  console.log("## in mobilizeTable");
  var table = $("table");
  // data cell max rows allowed
  Def.dataCellMax = getDataCellMaxFromTable(table);
  // replace oversized data table cells
  replaceOversizedTextInTable(table, Def.dataCellMax);
  formatMobileTable(table);
  //e.preventDefault();
}
//$.connect(this, "replaceOversizedTextInTable", this, "formatMobileTable");


function getDataCellMaxFromTable(table) {
  var a = "getDataCellMaxFromTable";
  console.time(a);
  var dataCellMax = [null];// the header data cell should be omitted as it's data content will always be the same
  if (table == undefined) table = $("table");
  var rs = table[0].rows;
  // the header row data cell will always have the same amount of characters, it could be skipped here
  for (var i = 1; i < rs.length; i++) {
    var row = rs[i];
    var labelCell = row.cells[0]; // labelCell
    // Try to find the number of rows needed for the label cell
    lineChar = Def.labelCellLineChars;
    padding_left = labelCell.style.paddingLeft.replace("em", "");
    if (padding_left > 0) {
      padding_left = Math.round(padding_left / 0.5); // number of blank characters used for indentation
      lineChar -= padding_left;
    }
    rows = labelCell.textContent.length / lineChar;
    rows = Math.round(rows + 0.5);

    // calculate the maximum size of data cell and store them in an array
    dataCellMax.push(rows * Def.dataCellLineChars);
  }
  console.timeEnd(a);
  //console.log(Def.dataCellMax);

  return dataCellMax;
}


/* go through all the table cells and replace them if the cell has big text content in it
 */
function replaceOversizedTextInTable(table, cellMaxByRow) {
  var a = "replaceOversizedTextInTable";
  console.time(a);
  console.log("## in replaceOversizedTextInTable");
  if(cellMaxByRow==undefined) cellMaxByRow = Def.dataCellMax;
  if(table==undefined) table = $("table");
  var rows = table[0].rows;
  // the first header row's data cell should always has the same length of content, thus don't need to be filtered
  for (var ri = 1; ri < rows.length; ri++) {
    var row= rows[ri];
    var cells = row.cells;
    for (var ci = 1; ci < cells.length; ci++) {
      var cell = cells[ci];
      if (cell.textContent.length > cellMaxByRow[ri])
        cell.innerHTML = truncateCellContent(cell.textContent, cellMaxByRow[ri]);
    }
  }
  console.timeEnd(a);
}


function truncateCellContent(name, cellMax){
  //if (id === undefined) id = "id_"+ (new Date()).valueOf();
  //$("<div id='"+id+"' data-role='popup' >"+name+"</div>").appendTo($("#flowsheet"));
  //return  "<a href='#"+id+"' data-rel='popup' title='"+name+"'>" + name.substring(0, cellMax-3 ) + "...</a>";
  return  "<a title='"+name+"'>" + name.substring(0, cellMax-3 ) + "...</a>";
}


function formatMobileTable(table){
  var a = "formatMobileTable";
  console.time(a);
  if (table == undefined) table = $("table");
  console.log("## in formatMobileTable");
  // adding sticky header not working in portrait mode of iphone 5
  // make sure the layout is landscape
  var rtn = null;
  if (screen.width > screen.height) {
    var b="fixedHeaderTable";
    console.time(b);
    rtn = table.fixedHeaderTable({
      //height: '350',//'200' make it bigger for demo purpose
      height: '200',
      width: '560',
      altClass: 'odd',
      fixedColumn: true,
      themeClass: 'fancyDarkTable' });
    console.timeEnd(b);
  }

  // trigger reloading upon scrolling
  $(".fht-tbody").scroll(function () {
    console.log("scroll event detected");
    if(!Def.ajaxRunning && !Def.maxPage)
      switchHashInfoAjax(table);
  })
  console.timeEnd(a);
  $("div#flowsheet").removeClass("hidden");
  return rtn;
}


function switchHashInfoAjax(table){
  console.log("Trying to load more columns...");
  if(!Def.maxPage && !Def.ajaxRunning){
    console.log("Fetching more records using Ajax call ...");
    Def.ajaxRunning = true;
    var existCols = table[0].rows[0].cells.length - 1;
    //Def.nextPage +=1;


    // find the ajax data parameter Def.ajaxReqParams
    var newUrlPart = "get_paginated_flowsheet_data_hash?exist_cols="+existCols+
                                                      "&columns_per_page="+Def.columnsPerPage;
    var initFlowsheetUrl = $("form")[0].action;
    var url = initFlowsheetUrl.replace("flowsheet", newUrlPart);
    $.ajax({
      url: url,
      data: Def.ajaxReqParams,
      method: "get",
      success: function(response){
        // update the hash_info variable
        Def.hash_info = JSON.parse(response);
        // if no panel data info returned, update Def.maxPage
        var columnsLoaded = Def.hash_info.panel_date ? Def.hash_info.panel_date.length : 0;
        console.log("Number of columns loaded: " + columnsLoaded);
        if (columnsLoaded > 0) appendColumns();
        if (columnsLoaded < Def.columnsPerPage) {
          Def.maxPage = true;
        }
        Def.ajaxRunning = false;
      }
    })
  }
}


/*
 * show flowsheet in the landscape mode only!
 *
 */
function showFlowsheet() {
  if (screen.width > screen.height) {
    $("div#flowsheet").removeClass("portrait");
    $("div#orientation_hints").removeClass("portrait");

    $("div#flowsheet").addClass("landscape");
    $("div#orientation_hints").addClass("landscape");
    //window.setTimeout(function(){abc();}, 300);
  }
  else {
    $("div#flowsheet").removeClass("landscape");
    $("div#orientation_hints").removeClass("landscape");

    $("div#flowsheet").addClass("portrait");
    $("div#orientation_hints").addClass("portrait");
  }
}
showFlowsheet();


$(window).bind("orientationchange",function(evt){
  //alert(evt.orientation);
  if($("div#flowsheet")){}
    showFlowsheet();
});


/**
 * Add new columns into the mobile flowsheet table
 **/
function appendColumns(){
  // convert oversized cells
  replaceOversizedTextInHash(Def.hash_info, Def.dataCellMax);

  // add new columns into the mobile table, add missing column headers
  var s = new Date();
  var table = $("table.fht-table-init");

  var cstr = "buildNewCellsByRows";
  console.time(cstr);
  buildNewCells(table[0].rows, Def.hash_info);
  console.timeEnd(cstr);

  cstr = "refreshFixedHeader";
  console.time(cstr);
  table.fixedHeaderTable("refreshFixedHeader");
  console.timeEnd(cstr);

  var dt = (new Date()) - s;
  var rows = table[0].rows;
  showLoadMoreStatus(dt, rows.length, rows[0].cells.length );
}


function replaceOversizedTextInHash(hash, cellMaxByRow){
  if(hash==undefined) hash = Def.hash_info;
  if(cellMaxByRow==undefined) cellMaxByRow = Def.dataCellMax;
  //edit in place of hash_info
  pd = hash.panel_data;
  Def.oriPanelData = $.extend([], pd);

  for(i=0;i< pd.length; i++){
    data_line = pd[i];
    for(k in data_line){
      name = data_line[k][0];
      cellMax =  cellMaxByRow[i+1]; // first row of cellMaxByRow (i.e. the header row) is null
      if (name.length >cellMax){
        aaa = truncateCellContent(name,cellMax);
        data_line[k][0] = aaa;
      }
    }
  }
}


function buildNewCells(rows, hash_info){
  for(var i=0;i<rows.length; i++) {
    var row = rows[i];
    var newCellsHTML = buildNewCellsByRow(i, hash_info);
    $(newCellsHTML).appendTo($(row));
  }
}


function buildNewCellsByRow(index,hash_info) {
  // when index is 0, do the headers th
  // then index is not 0, do the normal table cells td
  var rtn = "";
  if (index == 0) {
    var tag = "th";
    // this is the table head
    hash_info.panel_date.forEach(function (e) {
      for (key in e) {
        var vs = e[key];
        //var vs = e.values;
        rtn += "<" + tag + ">";
        rtn += "<div class='date'>" + vs[0] + "</div>";
        rtn += "<div class='date'>" + vs[1] + "</div>";
        rtn += "<div class='date'>" + vs[2] + "</div>";
        rtn += "</" + tag + ">";
      }
    });
  } else {
    var tag = "td";
    // this is the tbody
    var row_hash = hash_info.panel_data[index];
    hash_info.panel_date.forEach(function (e) {
      for (cid in e) {
        var cell_value = row_hash[cid];
        rtn += "<" + tag + ">";
        rtn += cell_value ? cell_value[0] : " ";
        rtn += "</" + tag + ">";
      }
    });
  }
  return rtn;
}


function showLoadMoreStatus(r, rows, cells) {
  // build the alert span if not exist
  if($("#alert").length == 0){
    var statusSpan = $("<span style='color: yellow' id='alert'></span>");
    var groupTitle = $("div.ui-content h2");
    statusSpan.appendTo(groupTitle);
  }
  // update content of the alert span
  //var statusHtml = "<b>Time: " + r + "ms; </b>";
  var statusHtml = "Row/Columns/<b>Cells</b>:" + rows + " / " + cells + " / <b>" + (rows * cells) + "</b>";
  $("#alert")[0].innerHTML = statusHtml;
}