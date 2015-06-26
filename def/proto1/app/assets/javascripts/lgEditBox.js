/**
 * lgEditBox.js --> A class to display a large edit box for text input field.
 *
 * $Id: lgEditBox.js,v 1.22 2011/08/03 18:01:13 plynch Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/lgEditBox.js,v $
 * $Author: plynch $
 *
 * $Log: lgEditBox.js,v $
 * Revision 1.22  2011/08/03 18:01:13  plynch
 * Changes to remove dojo from all but the panel_view and panel_edit pages.
 *
 * Revision 1.21  2010/07/22 22:47:44  plynch
 * Changes for making non-large edit fields select the text on receiving focus.
 *
 * Revision 1.20  2010/01/29 16:44:35  lmericle
 * commented out setUpListener so cannot be used.
 *
 * Revision 1.19  2009/07/31 22:00:42  wangye
 * added a multi-field editor for test panels
 *
 * Revision 1.18  2009/06/08 16:43:56  wangye
 * removed unused functions
 *
 * Revision 1.17  2009/04/30 21:16:42  wangye
 * changes for test panels units and range
 *
 * Revision 1.16  2009/04/17 21:50:25  wangye
 * fixed bugs on return and tab key behavior of lgeditbox
 *
 * Revision 1.15  2009/03/20 22:10:59  wangye
 * js performance improvement
 *
 * Revision 1.14  2009/03/20 13:49:38  lmericle
 * removed redundant getKeyCode function
 *
 * Revision 1.13  2009/03/20 13:38:20  lmericle
 * changes related to conversion of navigation.js functions to Def.Navigation class object
 *
 * Revision 1.12  2008/10/23 15:10:03  wangye
 * bug fix for IE7 and Firefox3
 *
 * Revision 1.11  2008/10/09 22:07:37  lmericle
 * moved code to set large edit box event observers on text input fields from separate onload event started in lgEditBox.js to setUpNavKeys in navigation.js - so that they're set at the same time we work through the form elements for other things.
 *
 * Revision 1.10  2008/08/20 18:02:31  smuju
 * fixed bug with text selection when clicking
 *
 * Revision 1.9  2008/08/19 19:45:26  smuju
 * added functionality to select text on first click and allow edit subsequently on next click
 *
 * Revision 1.8  2008/07/15 15:42:44  wangye
 * removed possible duplicated listener on tables
 *
 * Revision 1.7  2008/06/17 21:47:02  wangye
 * added F2 to make edit box disappear and save the text
 *
 * Revision 1.6  2008/05/27 20:36:20  wangye
 * updated text width calculation
 *
 * Revision 1.5  2008/05/21 21:34:00  wangye
 * use key F2 to open editbox and many bug fixes
 *
 * Revision 1.4  2008/05/06 21:37:56  wangye
 * added functions to auto-increase height
 *
 * Revision 1.3  2008/05/02 22:14:33  wangye
 * to igore readonly_field
 *
 * Revision 1.2  2008/03/13 16:24:50  wangye
 * bug fix
 *
 * Revision 1.1  2008/03/10 18:23:25  wangye
 * large edit box for text input field
 *
 * Revision 1.1  2008/03/10 14:10:30  wangye
 * initial version 
 */

//global object and initial properties
var LargeEditBox = {
  'editing' : false,
	'srcEle' : null,
  'newEle' : null,
  'initWidth' : null
}

//find an element's screen position
//left-top point, margin/border/padding included. 
LargeEditBox.findPos = function(obj) {
  var curleft = curtop = 0;
  while (obj != null ) {
    curleft += parseInt(obj.offsetLeft);
    curtop += parseInt(obj.offsetTop);
    obj = obj.offsetParent;
	}
	return [curleft,curtop];
}

//find an element's position relative to an ancestor
//left-top point, margin/border/padding included. 
LargeEditBox.findRelativePos = function(obj, ancID) {
  var curleft = curtop = 0;
  while (obj != null && obj.id != ancID ) {
    curleft += parseInt(obj.offsetLeft);
    curtop += parseInt(obj.offsetTop);
    obj = obj.offsetParent;
	}
	return [curleft,curtop];
  
}

LargeEditBox.findPosition = function(obj) {
  var curleft = curtop = 0;
  if(obj.offsetParent)
      while(1) 
      {
        curleft += obj.offsetLeft;
        curtop += obj.offsetTop;
        if(!obj.offsetParent)
          break;
        obj = obj.offsetParent;
      }
   else {
     if(obj.x) {
       curleft += obj.x;
     }
     if(obj.y) {
       curtop += obj.y;
     }
   }        
	return [curleft,curtop];
}

//insert at cursor position in a textarea
//Not used
LargeEditBox.insertAtCursor = function(txtArea, insText) {
  //IE support
  if (document.selection) {
    txtArea.focus();
    var sel = document.selection.createRange();
    sel.moveStart('character',0);
    sel.select();
    sel.moveEnd('character',1);
    sel.text = '';
    sel.select();
    sel.text = insText;
    //where is the cursor position?? not tested on IE yet.
  }
  //MOZILLA/NETSCAPE support
  else if (txtArea.selectionStart || txtArea.selectionStart == '0') {
    var startPos = txtArea.selectionStart;
    var endPos = txtArea.selectionEnd;
    txtArea.value = txtArea.value.substring(0, startPos)
    + insText
    + txtArea.value.substring(endPos, txtArea.value.length);
    //reset cursor position
    txtArea.selectionStart = startPos+1;
    txtArea.selectionEnd = startPos+1;
    
  } else {
    txtArea.value += insText;
  }
}
//get mouse position
LargeEditBox.getMousePos = function(e) {
  
  //posx and posy contain the mouse position relative to the document
  var posx = 0;
	var posy = 0;
  if (!e) e = window.event;
	if (e.pageX || e.pageY) 	{
		posx = e.pageX;
		posy = e.pageY;
	}
	else if (e.clientX || e.clientY) 	{
		posx = e.clientX + document.body.scrollLeft
			+ document.documentElement.scrollLeft;
		posy = e.clientY + document.body.scrollTop
			+ document.documentElement.scrollTop;
	}

  //or ?? 
  //  posx = e.screenX-e.clientX;
  //  posy = e.screenY-e.clientY;

  return [posx, posy];
}


//get a style property of an element
LargeEditBox.getStyle = function(ele, prop) {
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
}

//get the actual height
//border(and margin/padding)'s height not included
//ele.offsetHeight includes border and padding's height, but not margin's
LargeEditBox.getHeight = function(ele) {
  return parseInt( LargeEditBox.getStyle( ele, 'height'));
}
//get the actual width
//border(and margin/padding)'s width not included
//ele.offsetWidth includes border and padding's width, but not margin's
LargeEditBox.getWidth = function(ele) {
  return parseInt( LargeEditBox.getStyle( ele, 'width'));
}

LargeEditBox.getComputedWidth = function(ele) {
  var comWidth = document.defaultView.getComputedStyle(ele, "").getPropertyValue("width");
  //comWidth has unit 'px'
  return width = parseFloat(comWidth);
  
}
//simulate keypress event to fire an autocompleter event
//not working: the keypress event listener on on srcEle not fired
//not used.
LargeEditBox.simulateKeyPress = function() {
//  var evt = document.createEvent("UIEvents");
//  evt.initUIEvent("keypress", true, true, window, 1);
//  LargeEditBox.srcEle.dispatchEvent(evt);
  
  var evt = document.createEvent("KeyboardEvent");
  if(evt.initKeyEvent && LargeEditBox.srcEle.dispatchEvent) {
    evt.initKeyEvent(
        "keyup", // in DOMString typeArg,
        false,                 // in boolean canBubbleArg,
        true,                  // in boolean cancelableArg,
        null,                  // in nsIDOMAbstractView viewArg,
        false,                 // in boolean ctrlKeyArg,
        false,                 // in boolean altKeyArg,
        false,                 // in boolean shiftKeyArg,
        false,                 // in boolean metaKeyArg,
        0,                  // key code;
        49);    // char code.

    LargeEditBox.srcEle.dispatchEvent(evt);
   }

}

LargeEditBox.simulateChange = function() {
  
  if (document.createEventObject){
        // dispatch for IE
        var evt = document.createEventObject();
        LargeEditBox.srcEle.fireEvent('onchange',evt)
    }
    else{
        // dispatch for firefox + others
        var evt = document.createEvent("HTMLEvents");
        evt.initEvent("change", true, false ); 
        LargeEditBox.srcEle.dispatchEvent(evt);
    }    
}

//display a large edit box
LargeEditBox.showLargeEditBox = function(e) {

  //get source element
 	var targ;
	if (!e) e = window.event;
	if (e.target) targ = e.target;
	else if (e.srcElement) targ = e.srcElement;
  // defeat Safari bug
	if (targ.nodeType == 3)	targ = targ.parentNode;

  //create a large edit box
  var newDiv = document.createElement("div");
  Element.addClassName(newDiv, "lgEditBoxWrapper")
  newDiv.innerHTML = "<textarea class='lgEditBox' rows=3 cols=30>" + targ.value + "</textarea>";

  //add the newly created element and it's content into the DOM
  //#formContent has to be "position: relative;"
  //so that the newly added textarea stays put over the text input field 
  //while form is being scrolled up or down.
  //Since newDiv will probably be positioned twice, make it invisiable first to
  //get rid of the "Jump" visual effect.
  newDiv.style.visibility = "hidden";
  $("formContent").appendChild(newDiv);
  
  //get source element's position
  var srcPos = LargeEditBox.findRelativePos(targ, "formContent");
  
  //reposition it, 10px is the border width of #formContent, see below.
  //var bdrTop = parseInt(LargeEditBox.getStyle($("formContent"),'borderTopWidth'));
  //var bdrLeft = parseInt(LargeEditBox.getStyle($("formContent"),'borderLeftWidth'));

  newDiv.style.left = srcPos[0] + "px";
  newDiv.style.top = srcPos[1] + "px";
  
  LargeEditBox.initWidth = LargeEditBox.resetWidth(targ, newDiv);
  
  // http://www.alanamos.de/articles/firefox_2+3_offset_attributes.html
  // When FireFox 3 calculates offsetLeft & offsetTop for an element using 
  // JavaScript, it takes account of the border-width of the element's 
  // offsetParent object. This is not the case with Firefox 2, which ignores 
  // this attribute for this type of offsetParent.
  
  //There's a bug in firefox 2. 
  //On PHR form, the form banner includes a image which is loaded through css
  //file. The real offset position of left and top of the newDiv are 10px 
  //shorter than where it is supposed to be. The 10px appears to be the left 
  //and top border width of #formContent.
  //The fix is to compare the the real postion of the newDiv after it is 
  //inserted into DOM and the supposed position. And add the difference if any.
  
  // The above fix not working on firefox 3, unless lgEditBoxWrapper is set as
  // position:relative; --Ye, 10/2/2008
  var realPos = LargeEditBox.findRelativePos(newDiv, "formContent");
  
  // srcPos and realPos are same in FF3 if lgEditBoxWrapper is set as 
  // position:relative
  // They are always different in FF2, and in FF3 if lgEditBoxWrapper is NOT 
  // set as position:relative. 
  // srcPos = realPos + [border width of $('formContent')] 
  
  //console.log("srcPos:" + srcPos[0]);
  //console.log("realPos:" + realPos[0]);
  
  if (srcPos[0] - realPos[0] != 0) {
    newDiv.style.left = srcPos[0] + (srcPos[0] - realPos[0]) + "px";
  }
  if (srcPos[1] - realPos[1] != 0) {
    newDiv.style.top = srcPos[1] + (srcPos[1] - realPos[1]) + "px";
  }

  newDiv.style.visibility = "visible";
  
  var newEditBox = newDiv.getElementsBySelector("textarea");
  
  //add event listener on the new large edit box
  Event.observe(newEditBox[0], 'keydown', LargeEditBox.processKey);
  Event.observe(newEditBox[0], 'blur', LargeEditBox.processBlur);

  LargeEditBox.srcEle = targ;
  LargeEditBox.newEle = newDiv;
  newEditBox[0].focus();
  
}

//get the number of cols and rows of a multiline text block
LargeEditBox.parseText = function(strText) {
  var intCols = 0;
  var arrLines = strText.split('\n');
  var intRows = arrLines.length;
  for (var i=0, il=arrLines.length; i<il; i++) {
    if (intCols < arrLines[i].length) {
      intCols = arrLines[i].length;
    }
  }
  return [intCols, intRows]
  
}

LargeEditBox.resetWidth = function(srcEle, divEle) {
  var fontWidth = 9;
  var formWidth = LargeEditBox.getWidth($('formContent'));    
  var eleLeft = parseInt(LargeEditBox.getStyle(divEle,'left'));
  var eleWidth= parseInt(srcEle.offsetWidth);
  //In keyPress event, srcEle is a TextArea
  //srcEle.value.lenth is the value before the keyPress event
  var textWidth = srcEle.value.length * fontWidth;
  var minWidth;
  //to resize large edit box, in keypress event
  if (LargeEditBox.initWidth) {
    minWidth = LargeEditBox.initWidth > 200 ? LargeEditBox.initWidth : 200;
  }
  //in creating a new large edit box
  else {
    minWidth = eleWidth > 200 ? eleWidth : 200;
  }
  
  var allowedWidth = formWidth - eleLeft;
  //Add some empty space
  textWidth += 2 * fontWidth; 
//  console.log("init: eleWidth:" + eleWidth);
//  console.log("init: formWidth:" + formWidth);
//  console.log("init: eleLeft:" + eleLeft);
//  console.log("init: textWidth:" + textWidth);
//  console.log("init: allowedWidth:" + allowedWidth);
//  console.log("init: minWidth:" + minWidth);

  var retWidth;
  if (textWidth > allowedWidth) {
    retWidth = allowedWidth;
  }
  else {
    if (textWidth > minWidth) {
      retWidth = textWidth;
    }
    else {
      if (minWidth > allowedWidth ) {
        retWidth = allowedWidth;
      }
      else {
        retWidth = minWidth;
      }
    }
  }
  divEle.style.width = retWidth + 'px';

  return retWidth;
  
}

LargeEditBox.processKey = function(e) {
  //get source element
 	var targ;
  if (!e) e = window.event;
	if (e.target) targ = e.target;
	if (targ.nodeType == 3) // defeat Safari bug
		targ = targ.parentNode;
  
  //LargeEditBox.getKeyCode(e);
  
  var keycode = e.keyCode;
  switch (keycode) {
  case Event.KEY_ESC: //ESC
  //ECS: exit editing without save the content      
    LargeEditBox.cancelText(e);
    LargeEditBox.srcEle.focus();
    LargeEditBox.srcEle = null;
    LargeEditBox.newEle = null;
    LargeEditBox.initWidth = null;
    break;
  case 113:    // F2, same as Return
  case Event.KEY_RETURN: //Return
  //Return: save
  //Ctrl-Return: (new line) in textarea,  
    if (e.ctrlKey) {
      //add a new row
      LargeEditBox.insertAtCursor(targ, '\n');
      targ.rows = targ.rows +1;    
    }
    else {
      LargeEditBox.saveText(e);
      LargeEditBox.srcEle.focus();
      LargeEditBox.simulateChange();
      //move to next element
      if (!e.shiftKey)  {
        if (!Def.FieldsTable.skipBlankLine(LargeEditBox.srcEle)) {
          Def.Navigation.moveToNextFormElem(LargeEditBox.srcEle) ;
        }
      //move to previous element
      } else {
        Def.Navigation.moveToPrevFormElem(LargeEditBox.srcEle) ;
      }
      LargeEditBox.srcEle = null;
      LargeEditBox.newEle = null;
      LargeEditBox.initWidth = null;
      // canel the event, not to submit the form
      Event.stop(e);
    }
    break;
  case Event.KEY_TAB: //Tab
  //default behavior is to lose focus and go to next element on page
  //on firefox, ctrl-tab goes to next tab.
  //so no special handling needed. which also means "tab" is not able to be
  //inserted in textarea. but the content will be save when tab is hit because
  //of losing focus.
  
    //enforce save and focus. otherwise can not control which element get focus
    LargeEditBox.saveText(e);
    LargeEditBox.srcEle.focus();
    LargeEditBox.simulateChange();
    //move to next element
    if (!e.shiftKey)  {
      if (!Def.FieldsTable.skipBlankLine(LargeEditBox.srcEle)) {
        Def.Navigation.moveToNextFormElem(LargeEditBox.srcEle) ;
      }
    //move to previous element
    } else {
      Def.Navigation.moveToPrevFormElem(LargeEditBox.srcEle) ;
    }
    //LargeEditBox.srcEle.blur();
    LargeEditBox.srcEle = null;
    LargeEditBox.newEle = null;
    LargeEditBox.initWidth = null;
    // canel the event, not to move the focus by the standard TAB behavior
    Event.stop(e);  
    break;
  default:
  //others: recalculate EditBox's width and height
    if (LargeEditBox.newEle) {
      var xy =LargeEditBox.parseText(targ.value);
//      console.log(targ.value);
//      console.log(xy);
//      var fontWidth = 8;
//      console.log("box width: " + LargeEditBox.newEle.style.width);
//      console.log("text width: " + xy[0] * fontWidth);
      LargeEditBox.resetWidth(targ, LargeEditBox.newEle);
      
    }
  }
  
}

LargeEditBox.cancelText = function(e) {

  if (!LargeEditBox.newEle) return;
  
  //remove this element
  $("formContent").removeChild(LargeEditBox.newEle);

}

LargeEditBox.saveText = function(e) {
  
  if (!LargeEditBox.newEle) return;
  
 	var targ;
	if (!e) e = window.event;
	if (e.target) targ = e.target;
	else if (e.srcElement) targ = e.srcElement;
	if (targ.nodeType == 3) // defeat Safari bug
		targ = targ.parentNode;
  //get the value from the textarea element
  var textValue= targ.value;
  
  //save the value to the original text input element
  if (LargeEditBox.srcEle) {
   Def.setFieldVal(LargeEditBox.srcEle, textValue);
  }
  //remove this element
  $("formContent").removeChild(LargeEditBox.newEle);

}

LargeEditBox.processBlur = function(e) {
  //exit editing and save the content
  LargeEditBox.saveText(e);
  LargeEditBox.simulateChange();
  LargeEditBox.srcEle.blur();

  LargeEditBox.srcEle = null;
  LargeEditBox.newEle = null;
  LargeEditBox.initWidth = null;

}

LargeEditBox.srcKeyEventHandler = function(e) {
  
  //get source element
 	var targ;
  if (!e) e = window.event;

	if (e.target) targ = e.target;
	else if (e.srcElement) targ = e.srcElement;
	if (targ.nodeType == 3) // defeat Safari bug
		targ = targ.parentNode;
  
  var fontWidth = 9;

  //get computed width (prototype)
  var fieldWidth = targ.getWidth();
  var textWidth = targ.value.length * fontWidth;
  
  //LargeEditBox.getKeyCode(e);
  
  var keycode = e.keyCode;
  
  switch (keycode) {
  case 113: //F2 keycode=113
    LargeEditBox.showLargeEditBox(e)
    break;
  //charactors
  default:
// automatically open the edit box
//    console.log("Box width  : " + fieldWidth);
//    console.log("Text length: " + targ.value.length);
//    console.log("Text widht : " + textWidth);
//
//    if (textWidth >= (fieldWidth - 3 * fontWidth)) {
//      LargeEditBox.showLargeEditBox(e);
//    }
  }
}
