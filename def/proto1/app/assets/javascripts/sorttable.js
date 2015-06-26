/**
 * sorttable.js -> javascript functions for Sortable Tables
 *
 * $Id: sorttable.js,v 1.28 2011/08/02 19:07:56 taof Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/sorttable.js,v $
 * $Author: taof $
 *
 * This set of javascript functions and the related stylesheet
 * /styles/sorttable.css were downloaded from
 * http://www.kryogenix.org/code/browser/sorttable/ 
 * - which lists these files as freely available.
 * 
 * To make a table sortable, include this set of javascript functions
 * and the stylesheet, assign a unique id to each table, and set the 
 * class of the table (or one of the classes of the table) to "sortable". 
 *
 * Note - sorting will not work properly if you have cells in the table
 *        that span multiple columns.
 *
 * $Log: sorttable.js,v $
 * Revision 1.28  2011/08/02 19:07:56  taof
 * changes of code review #357
 *
 * Revision 1.27  2011/06/29 13:50:54  taof
 * bugfix: event.fireEvent() not working with IE9
 *
 * Revision 1.26  2010/06/21 15:24:11  wangye
 * make the sortabletable to support checkbox
 *
 * Revision 1.25  2010/05/12 13:35:43  lmericle
 * fixed isBlankonlyTip in sorttable & removed automatic assumption of model row in a table; added code in displayRuleVals of rules.js to sort list before it's displayed
 *
 * Revision 1.24  2010/05/10 16:41:52  lmericle
 * fixed isBlankonlyTip; removed automatic assumption of model row in the table, so that sort does not omit first line if there is no model row.
 *
 * Revision 1.23  2010/05/04 16:05:31  lmericle
 * optimized a loop
 *
 * Revision 1.22  2009/12/22 22:22:43  plynch
 * Changed splitFullFieldID so that its return value is cached, updated
 * the code to be aware of that, and moved the function into idCache.js.
 *
 * Revision 1.21  2009/05/18 16:33:35  mujusu
 * now tooltip is essentially a value but should bve treated as blank. Changes for
 * new tooltip implementation
 *
 * Revision 1.20  2009/05/12 16:12:01  lmericle
 * fixed acquisition of cell header object
 *
 * Revision 1.19  2009/03/30 20:35:19  lmericle
 * added id to sort header spans
 *
 * Revision 1.18  2009/03/20 13:38:20  lmericle
 * changes related to conversion of navigation.js functions to Def.Navigation class object
 *
 * Revision 1.17  2009/03/19 18:15:57  lmericle
 * changes to redo navSeqsHash for fields that have been resorted
 *
 * Revision 1.16  2008/11/18 17:59:59  lmericle
 * modified calls to update navigation when table sorted to use new navigation scheme
 *
 * Revision 1.15  2008/11/13 21:31:27  lmericle
 * modifications to make work, including with date fields, to replace up/down arrows with wedge/inverted wedge icon, and only on column currently sorte, and did some cleanup.
 *
 * Revision 1.14  2008/10/24 21:34:32  wangye
 * bug fixes for IE7 and performance tune-up
 *
 * Revision 1.13  2008/02/28 14:57:30  lmericle
 * changes to move from first field of last blank line in a horizontal table to next accessible field outside the table
 *
 * Revision 1.12  2008/02/12 22:06:57  lmericle
 * changed console statements to def.logger calls; splitAutoComp updates to TablePrefetch class
 *
 * Revision 1.11  2007/11/16 18:57:33  lmericle
 * modified arrow keys to work with ctrl instead of shift; set sorted table headers to noNav
 *
 * Revision 1.10  2007/10/26 22:29:15  lmericle
 * changes for embedded tables
 *
 * Revision 1.9  2007/09/10 18:33:06  smuju
 * added resetofNav keys after sorting for proper sorting order
 *
 * Revision 1.8  2007/08/30 22:12:54  smuju
 * Made the ICD9 specific code for putting blank lines/columns at the bottom of sort available to all
 *
 * Revision 1.7  2007/08/15 21:04:46  fun
 * ts_makeSortable not use ts_getInnerText for title
 *
 * Revision 1.6  2007/08/15 18:22:12  fun
 * change ts_getInnerText for sub-table in cell
 *
 * Revision 1.5  2007/07/31 20:50:29  smuju
 * ICD9 code specific changes. pul blanks at the end etc.
 *
 * Revision 1.4  2007/07/31 01:02:50  plynch
 * Changed it so it assumes the first column is initially sorted alphabetically.
 *
 * Revision 1.3  2007/07/30 20:18:48  smuju
 * check for ICD9 Code. Sort it as a String rather than NUmber
 *
 * Revision 1.2  2007/06/14 00:00:47  plynch
 * Changes to implement a table for search results.
 *
 * Revision 1.1  2007/06/11 22:28:12  lmericle
 * added
 *
 * Revision 1.4  2006/08/29 15:39:35  lmericle
 * updates
 *
 * Revision 1.3  2006/03/28 15:56:17  lmericle
 * added/updated documentation
 *
 * Revision 1.2  2006/03/20 16:58:53  lmericle
 * documented
 *
 */

/**
 * Use Event.observe function from prototype.js to add sortables_init to 
 * the "onLoad" event list without destroying whatever else is there. This 
 * function is compatible with major browsers including IE9, FF5 etc.
 */
Event.observe(window, "load", sortables_init);

/** index of the column on which the table is currently sorted
 */
var SORT_COLUMN_INDEX;

/** images used to indicate sort direction
 */
var ASCENDING_IMAGE = '<img class="ascend_arrow" src="'+Def.blankImage_+'" alt="\u2228">' ;
var DESCENDING_IMAGE = '<img class="descend_arrow" src="'+Def.blankImage_+'" alt="\u2227">' ;

/** This function controls the initialization tasks, which find
 *  tables of the 'sortable' class and make adjustments to the
 *  header cells that implement sorting.
 *
 * @param ev the event that called this.  Should be "load".
 * @param sort_col optional number of the column on which we're sorting
 *        (starting with 0 for the leftmost column).  Default of -1
 *        is used if the parameter is not specified.  -1 indicates that
 *        the table starts out unsorted.
 */
function sortables_init(ev, sort_col) {

  // If the current browser doesn't support the getElementsByTagName
  // function, don't bother - this stuff just won't work
  if (document.getElementsByTagName) {
    
    // Set the initial sort column index
    if (typeof sort_col == 'undefined') 
      SORT_COLUMN_INDEX = -1 ;
    else
      SORT_COLUMN_INDEX = sort_col ;

	  // Get all tables and pass off each one that is 'sortable' AND
    // has an id assigned to it to the ts_makeSortable function.  
//    var tbls = document.getElementsByTagName("table");
//    for (var ti = 0, til = tbls.length; ti < til; ti++) {
//      var thisTbl = tbls[ti];
//      if (((' '+thisTbl.className+' ').indexOf("sortable") != -1) &&
//		  		(thisTbl.id)) {
//        ts_makeSortable(thisTbl);
//      }
//    }
    var tbls = document.getElementsByClassName("sortable") ;
    for (var ti = 0, til = tbls.length; ti < til; ti++) {
      if (tbls[ti].id)
        ts_makeSortable(tbls[ti]) ;
    }

  }
} // sortables_init



/** This function modifies the innerHTML of each cell in the first row
 *  of the table to make it sortable.  Specifically, it<ul>
 *  <li>assigns the 'sortheader' class to the cell</li>
 *  <li>adds an onclick event action to call ts_resortTable</li>
 *  <li>adds the arrow, using the sortarrow class to the cell
 *      following the cell text</li></ul>
 *
 * @param table the table object to be modified
 * @param callingObj optional parameter that can be used to specify a
 *  function to be called after the table is resorted.  The callingObject
 *  is passed to the afterFunc function by ts_resortTable after the table
 *  sort completes (if specified).
 * @param afterFunc see the callingObj description
 */
function ts_makeSortable(table, callingObj, afterFunc) {

  table.caller = callingObj ;
  table.afterSortFunction = afterFunc ;
    
  // only do this if we can get the first (header) row of the table
  if (table.rows && table.rows.length > 0) {
    var firstRow = table.rows[0];
  }
  if (firstRow) {
    
    // Assume the first row is the header and update the innerHTML
    for (var i = 0, il = firstRow.cells.length; i < il; i++) {
      var cell = firstRow.cells[i];
        
      // if this header is in the "nosort" class, don't make
      // this particular column sortable.
      if ((' '+cell.className+' ').indexOf("nosort") == -1) {
        var cellID = cell.id ;
        var txt = cell.innerHTML;
        
        // If this is the sort column, add the ascending indicator
        if (i == SORT_COLUMN_INDEX) {
          cell.innerHTML = '<a href="#" class="sortheader noNav" ' +
          'id="' + cellID + '_sorter" ' +
          'title="Click to sort by this column." ' +
          'onclick="ts_resortTable(this);return false;">' + txt +
          '<span sortdir="ascending" class="sortarrow noNav">' +
          ASCENDING_IMAGE + '</span></a>' ;
          //first_sort_field = false ;
        }
        else {
          cell.innerHTML = '<a href="#" class="sortheader noNav" ' +
          'id="' + cellID + '_sorter" ' +
          'title="Click to sort by this column." ' +
          'onclick="ts_resortTable(this);return false;">' + txt + 
          '<span class="sortarrow noNav"></span></a>';
        }
      }
    }
  }
} // ts_makeSortable


/** This function returns the text from the element passed to it.
 *  The way the text is obtained depends on the type of element
 *  passed, and this handles the various types.
 *
 * @param el the element whose text we want
 * @returns the inner text of the element
 */
function ts_getInnerText(el) {

  var ret = null ;
  
  // return the element passed in if it's a string, undefined,
  // or is, in fact, the text of the element (innerText)
  if (typeof el == "string" || typeof el == "undefined") 
    ret = el ;
  
  // If the element is a cell in a table row (which is what
  // we're expecting, get the input field within the field and
  // return its value (if any)
  else if (el.tagName.toLowerCase() == 'td') {
    var ifields = el.select('input') ;
    if (ifields.length > 0)
      ret = ifields[0].value ;
  }
  
  // If we don't have a return value, go searching at lower levels
  if (ret == null) {
    
    // if the element has no child nodes, return either its innerHTML
    // or, if it doesn't have that, it's value or, if it has neither of
    // those, a blank
    if (el.childNodes.length < 1 ) {
      if (el.innerHTML) 
        ret = el.innerHTML ; 
       else if (el.value) 
         ret = el.value ;
       else 
         ret = "" ;
    }	
    // Otherwise, get the child nodes of the element and either
    // get the nodeValue for text nodes or call this recursively
    // for other node types.
    else {
      ret = "";
      var cs = el.childNodes;
      var l = cs.length;

      for (var i = 0; i < l; i++) {
        switch (cs[i].nodeType) {
        case 1: //ELEMENT_NODE, skip images
				  if (cs[i].tagName.toLowerCase()!='img') 
            ret += ts_getInnerText(cs[i]);
          break;
        case 3:	//TEXT_NODE
				  ret += cs[i].nodeValue;
          break;
        }
      }
    } // end if the element does not/does have children
  } // end if we didn't get the value directly from el
	return ret;

} // ts_getInnerText



/** This function sorts the table based on the contents of the cells
 *  in the column of the header cell passed in (the cell the user
 *  clicked on).
 *
 * @param lnk the link in the header cell that the user clicked on
 */
function ts_resortTable(lnk) {

  // Get the sortarrow span which was assigned to the cell text 
  // in the ts_makeSortable function.  This contains the sort 
  // direction indicator
  var span;
  for (var ci = 0, cil = lnk.childNodes.length; ci < cil; ci++) {
	  if (lnk.childNodes[ci].tagName && 
		  	lnk.childNodes[ci].tagName.toLowerCase() == 'span') 
			span = lnk.childNodes[ci];
  }

  // Get the parentNode of the header, which will be the cell, 
	// then get its index so we'll know which column we're sorting
	// on, and the table, so we'll know which table we're sorting
  var td = getParent(lnk, 'TH');
  if (td.cellIndex)
    SORT_COLUMN_INDEX = td.cellIndex;
  else
    SORT_COLUMN_INDEX = getCellIndex(td) ;
  
  var table = getParent(td,'TABLE');

  // Set the minimum number of rows needed in the table to make sorting
  // useful.  If there is a model row in the table, we need 4 - the header
  // row, the model row, and 2 data rows.  Otherwise we just need 3.
  if (table.rows[1].getAttribute != undefined &&
      table.rows[1].getAttribute('rowID') == 0)
    var minRows = 4 ;
  else
    minRows = 3 ;
  var startingRow = minRows - 2 ;

  if (table.rows.length >= minRows) {
    
    // Get the first and last inputs currently on the table, before
    // we start rearranging things.  We'll need these for resorting
    // later.
    var inputs = table.select('input') ;
    var startingInputs = [];
    // 'hidden' or 'noNav' input fields have no navagations
    for (var s = 1, len = inputs.length;
        $(inputs[s]) && !isHiddenOrDisabled(inputs[s]) && s < len; s++)
      startingInputs.push(inputs[s]);
    var startInpLen = startingInputs.length ;
    if (startInpLen > 0) {
      var firstInput = startingInputs[0] ;
      var lastInput = startingInputs[startInpLen - 1] ;
    } // end if we have input fields to start with
    
    // Set the default sort function to case insensitive, for
    // character string values.  Then get the column value in the
    // first visible row and test to see if it's a calendar field, a date,
    // a $$ value, or a numeric value.
    // Reset the sort function as appropriate if it's one of those.
    var sortfn = ts_sort_caseinsensitive;
    // it's an input field in a normal calendar field
    var dtTable = 
      table.rows[startingRow].cells[SORT_COLUMN_INDEX].select('table.dateField');
    // or it's a static text field, such as the ones on the due date reminder
    var dtField =
      table.rows[startingRow].cells[SORT_COLUMN_INDEX].select('div.dateField');
    if (dtTable.length > 0 || dtField.length > 0 )
      sortfn = ts_sort_HL7_date ;
    else {
      var itm = ts_getInnerText(table.rows[startingRow].cells[SORT_COLUMN_INDEX]);

      if (itm.match(/^\d\d[\/-]\d\d[\/-]\d\d\d\d$/)) sortfn = ts_sort_date;
      if (itm.match(/^\d\d[\/-]\d\d[\/-]\d\d$/)) sortfn = ts_sort_date;
      if (itm.match(/^[??$]/)) sortfn = ts_sort_currency;
      if (itm.match(/^[\d\.]+$/)) sortfn = ts_sort_numeric;
    }

    // Create an array to hold the content rows of the table (excluding the
    // header and model rows).  Use a separate array to hold a totally blank
    // row. Then use the javascript sort function to sort content rows 
    // using the sort function as determined above.
    var newRows = new Array();
    var newRowsBlankCol = new Array()

    var k = 0 ;
    l = 0 ;
    var cl = table.rows[0].cells.length ;
    for (var j=startingRow, jl = table.rows.length; j < jl; j++) {
      var cellText = ts_getInnerText(table.rows[j].cells[SORT_COLUMN_INDEX]) ;
     
      if ((cellText.length > 0)  && cellText.substr(0,10) != '//<![CDATA' &&
          !isBlankonlyTip(table.rows[j].cells[SORT_COLUMN_INDEX])) {
         newRows[k++] = table.rows[j] ;
      }
      else {
        // check the other cells in the row
        var blank = true ;
        for (var r = 0; blank && r < cl; ++r) {
          //tipval = "" ;
          if (r != SORT_COLUMN_INDEX) {
            cellText = ts_getInnerText(table.rows[j].cells[r]);
           
            if (cellText.length > 0 && 
                (!isBlankonlyTip(table.rows[j].cells[r])) &&
                cellText.substr(0,10) != '//<![CDATA' ) {
               blank = false ;
            }
          }
        }
        if (blank)
          newRowsBlankCol[l++] = table.rows[j] ;
        else
          newRows[k++] = table.rows[j] ;
      }
    }
    // Now sort
    newRows.sort(sortfn);
    
    // Make sure there are no arrows on any columns
    // (Note that the span elements are not necessarily returned
    // in the order they show in the table, so using the 
    // SORT_COLUMN_INDEX to determine which one is the current
    // sort column won't work here.  So just clear 'em all.)
    var allspans = table.getElementsByTagName("span");
    for (ci = 0, cil = allspans.length; ci < cil; ci++) {
      if (allspans[ci].className.indexOf('sortarrow') != -1)
        allspans[ci].innerHTML = '';
    }    

    // If the rows were previously sorted in the ascending direction,
    // reverse the sort - because we're now sorting in the 
    // descending direction.
    // Set the header to include the sort indicator arrow, making
    // sure we're pointing in the correct direction - which would be
    // the opposite direction from the previous setting of the
    // "sortdir" attribute if there was one, or ascending if this is
    // the first time the column's been sorted, and so it doesn't
    // have a "sortdir" attribute yet.  Also set the sort direction
    // attribute.
    if (span.getAttribute("sortdir") == 'ascending') {
      newRows.reverse();
      //var rem_arrow = ASCENDING_IMAGE ;
      span.innerHTML = DESCENDING_IMAGE ;
      span.setAttribute('sortdir','descending');
    } else {
      //var rem_arrow = DESCENDING_IMAGE ;
      span.innerHTML = ASCENDING_IMAGE;
      span.setAttribute('sortdir','ascending');
    }
    
    // We append the sorted rows to the tbody so it moves them rather than 
    // creating new ones.  I don't know why appending them doesn't just
    // add them to what's already there, but this works.
    // After we put the sorted rows on, put the blank row(s) on.
    var tmpBody = table.tBodies[0];
    for (var i = 0, il = newRows.length; i < il; i++) { 
		  tmpBody.appendChild(newRows[i]);
    }
    for (i = 0, il = newRowsBlankCol.length; i < il ; i++) { 
      tmpBody.appendChild(newRowsBlankCol[i]);
	  }
    
    // Reset navigation since we have resorted - IFF we have
    // inputs.  If we're sorting a list table - prefetched list
    // or search results list - those nodes don't participate
    // in any navigation scheme, and so don't need to be adjusted.
    if (startInpLen > 0) {         
      Def.Navigation.resortNavKeys(firstInput, lastInput) ;
    }
    // if an "after" function was specified, call it now
    if (table.caller != null)
      table.afterSortFunction.call(table.caller) ;
  }
} // ts_resortTable


/**
 * For a given element recursively goes through all the children
 * to find any with tooltip. If finds an element with tooltip and
 * no actual value, returns true. If there is a value, return false
 * @param ele the element whose tooltip/text we want
 * @returns true if no field with value or only tooltip
 *          false  if field with tooltip has a actual value (not tooltip)
 **/
function isBlankonlyTip(ele){

  var blank = true ;

  // If we can use the getAttribute method on the element and if it
  // has a "novalue" attribute, check that and set blank to its value.
  if (ele.getAttribute != undefined &&
      (ele.getAttribute("novalue") != null)) {
    if (ele.getAttribute("novalue") == "false" ){
      blank = false ;
    }
    else {
      blank = true ;
    }
  }

  // Else we can't use a "novalue" attribute
  else {
    var numChild = ele.childNodes.length ;

    // If this element has no children, set blank bacsed on whether or
    // not it has a value that is not null.
    if (numChild == 0) {
      if (ele.value != undefined) {
        blank = ele.value.length <= 0 ;
      }
      else {
        if (ele.nodeValue != undefined) {
          blank = ele.nodeValue.length <= 0 ;
        }
      } // end if we can use value or need to use nodeValue
    }
    // Else this element has children.  Check them until we find a non-blank
    // or run out of children
    else {
      for (var i = 0, il = numChild; i < il && blank == true; i++) {
	      //blank = !isBlankonlyTip(ele.childNodes[i]) ;
	      blank = isBlankonlyTip(ele.childNodes[i]) ;
      }
    }
  } // end if we can/can't use a "novalue" attribute

  return blank ;
} // end isBlankonlyTip

/** This function looks at the node passed in and gets the parent
 *  node that has the tag name specified.
 *
 * @param el child node
 * @param pTagName tag name of the parent to be returned
 */
function getParent(el, pTagName) {
  
  var ret = null ;
  
  // Don't bother if the node passed in is null OR if its
  // tag name matches the tag name passed in
  if (el != null) {
    if (el.nodeType == 1 && 
		    el.tagName.toLowerCase() == pTagName.toLowerCase())
		  // Gecko bug, supposed to be uppercase
		  ret = el;
    else
		  ret = getParent(el.parentNode, pTagName);
  }
  return ret ;
  
} // getParent


function getCellIndex(el) {
  
  var ret = -1 ;
  var row = getParent(el, 'TR') ;
  if (row) {
    var rowCells = row.cells.length ;
    for (var r = 0; r < rowCells; ++r) {
      if (el.id == row.cells[r].id) {
        ret = r ;
        r = rowCells;
      }
    } 
  }
  return ret ;
  
} // getCellIndex


/** This function sorts two table rows based on the contents
 *  of the cell in the column indicated by the SORT_COLUMN_INDEX,
 *  where the contents have been determined to be dates.  
 *
 *  Note - two digit years less than 50 are treated as 20xx,
 *         greater than 50 are treated as 19xx.
 *
 *  Also note - this assumes dates in dd/mm/yy or dd/mm/yyyy format
 *
 * @param a the first row
 * @param b the second row
 * @returns <ul>
 *  <li> 0 if the values in the two rows are the same</li>
 *  <li>-1 if the value in row a is less than the value in row b</li>
 *  <li> 1 if the value in row a is greater than the value in row b</li>
 * </ul>
 */
function ts_sort_date(a,b) {

    aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]);
    bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]);
    if (aa.length == 10) {
        dt1 = aa.substr(6,4)+aa.substr(3,2)+aa.substr(0,2);
    } else {
        yr = aa.substr(6,2);
        if (parseInt(yr) < 50) { yr = '20'+yr; } else { yr = '19'+yr; }
        dt1 = yr+aa.substr(3,2)+aa.substr(0,2);
    }
    if (bb.length == 10) {
        dt2 = bb.substr(6,4)+bb.substr(3,2)+bb.substr(0,2);
    } else {
        yr = bb.substr(6,2);
        if (parseInt(yr) < 50) { yr = '20'+yr; } else { yr = '19'+yr; }
        dt2 = yr+bb.substr(3,2)+bb.substr(0,2);
    }
    if (dt1==dt2) return 0;
    if (dt1<dt2) return -1;
    return 1;

} // ts_sort_date


/** This function sorts two table rows based on the contents of 
 *  of the cell in the column indicated by the SORT_COLUMN_INDEX,
 *  where the contents have been determined to be a date field.
 *
 *  Specifically, the value on which to sort is obtained from the
 *  HL7 date field that corresponds to the input field found in the
 *  the cell noted above.
 *
 *  THIS ASSUMES that there is a corresponding HL7 date field.  If
 *  there is not, no sorting will be performed.
 *
 * @param a the first row
 * @param b the second row
 * @returns <ul>
 *  <li> 0 if the values in the two rows are the same</li>
 *  <li> negative number if the row a's value is less than row b's</li>
 *  <li> positive number if the row a's value is greater than row b's</li>
 * </ul>
 */
function ts_sort_HL7_date(a,b) { 

  aa = getHL7Value(a.cells[SORT_COLUMN_INDEX]) ;
  bb = getHL7Value(b.cells[SORT_COLUMN_INDEX]) ;
  if (aa==bb) return 0;        
  if (aa<bb) return -1;
  return 1;
}


/** This function obtains the current value from the HL7 form field 
 *  that corresponds to the input date field found in the cell passed
 *  in.
 *
 * @param dateCell cell containing the input date field
 * @returns the value of the corresponding HL7 date field, or null
 *  if it is not found.
 */
function getHL7Value(dateCell) {
  ret = null ;
  // it's an input field in a normal calendar field
  inp = dateCell.select('input') ;
  // or it's a static text field, such as the ones on the due date reminder
  if (inp.length == 0 ) {
    inp = dateCell.select('div.dateField');
  }
  if (inp.length > 0) {
    var inpParts = Def.IDCache.splitFullFieldID(inp[0].id) ;
    HL7Fld = $(inpParts[0] + inpParts[1] + '_HL7' + inpParts[2]) ;
    if (HL7Fld)
      ret = HL7Fld.tagName == 'INPUT' ? HL7Fld.value : HL7Fld.textContent;
  }
  return ret ;
    
} // get_HL7_value


/** This function sorts two table rows based on the contents of 
 *  of the cell in the column indicated by the SORT_COLUMN_INDEX,
 *  where the contents have been determined to be currency
 *
 * @param a the first row
 * @param b the second row
 * @returns <ul>
 *  <li> 0 if the values in the two rows are the same</li>
 *  <li> negative number if the row a's value is less than row b's</li>
 *  <li> positive number if the row a's value is greater than row b's</li>
 * </ul>
 */
function ts_sort_currency(a,b) { 
  aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]).replace(/[^0-9.]/g,'');
  bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]).replace(/[^0-9.]/g,'');
  return parseFloat(aa) - parseFloat(bb);
}


/** This function sorts two table rows based on the contents of 
 *  of the cell in the column indicated by the SORT_COLUMN_INDEX,
 *  where the contents have been determined to be numeric (and not
 *  dates and not currency)
 *
 * @param a the first row
 * @param b the second row
 * @returns <ul>
 *  <li> 0 if the values in the two rows are the same</li>
 *  <li> negative number if the row a's value is less than row b's</li>
 *  <li> positive number if the row a's value is greater than row b's</li>
 * </ul>
 */
function ts_sort_numeric(a,b) { 
  aa = parseFloat(ts_getInnerText(a.cells[SORT_COLUMN_INDEX]));
  if (isNaN(aa)) aa = 0;
  bb = parseFloat(ts_getInnerText(b.cells[SORT_COLUMN_INDEX])); 
  if (isNaN(bb)) bb = 0;
  return aa-bb;
}


/** This function sorts two table rows based on the contents of 
 *  of the cell in the column indicated by the SORT_COLUMN_INDEX,
 *  where the contents have been determined to be not numeric, not
 *  dates and not currency.  The assumption is, of course, text.
 *
 * @param a the first row
 * @param b the second row
 * @returns <ul>
 *  <li> 0 if the values in the two rows are the same</li>
 *  <li> negative number if the row a's value is less than row b's</li>
 *  <li> positive number if the row a's value is greater than row b's</li>
 * </ul>
 */
function ts_sort_caseinsensitive(a,b) {

  aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]).toLowerCase();
  bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]).toLowerCase();

  if (aa==bb) return 0;        
  if (aa<bb) return -1;
  return 1;
}


/** This function sorts two table rows based on the contents of 
 *  of the cell in the column indicated by the SORT_COLUMN_INDEX,
 *  where the content type has not been determined.  
 *
 *  Note - this function doesn't actually seem to be USED anywhere.
 *         At least, it's not invoked by anything.
 *
 * @param a the first row
 * @param b the second row
 * @returns <ul>
 *  <li> 0 if the values in the two rows are the same</li>
 *  <li> negative number if the row a's value is less than row b's</li>
 *  <li> positive number if the row a's value is greater than row b's</li>
 * </ul>
 */
function ts_sort_default(a,b) {
  aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]);
  bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]);
  if (aa==bb) return 0;
  if (aa<bb) return -1;
  return 1;
}

// The following method was replaced by Event.observe() to ensure cross browser
// compatibility - Frank 
///** This adds an event to the event queue specified.  In this case
// *  it's used (by the addEvent call at the beginning of this file)
// *  to add the sortables_init function to the onLoad queue.  Using
// *  the onLoad function replaces anything in the queue, where this
// *  non-destructively adds to the queue.
// *
// *  addEvent and removeEvent cross-browser event handling for IE5+,
// *  NS6 and Mozilla.  By Scott Andrew
// *
// * @param elm the element with the target queue
// * @param evType the event type
// * @param fn the function to be added
// * @param useCapture when to fire off the event
// *  <ul><li>true = use capturing mode, which means that the event
// *          occurs after any events also fired off for the element's
// *          parent</li>
// *      <li>false = use bubbling mode, which means that the event
// *          occurs before any events also fired off for the element's
// *          parent</li>
// */
//function addEvent(elm, evType, fn, useCapture) {
//
//  var ret = true ;
//  if (elm.addEventListener) {
//    elm.addEventListener(evType, fn, useCapture);
//  }
//  else if (elm.attachEvent) {
//    ret = elm.attachEvent("on" + evType, fn);
//  } 
//  else {
//    alert("Handler could not be added");
//    ret = false ;
//  }
//  return ret ;
//} // addEvent 
