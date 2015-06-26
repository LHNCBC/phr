/**
 * multiFieldBox.js --> A class to a mutil-field edit box for a field.
 * *
 * $Log: multiFieldBox.js,v $
 * Revision 1.7  2011/08/03 18:01:13  plynch
 * Changes to remove dojo from all but the panel_view and panel_edit pages.
 *
 * Revision 1.6  2010/08/26 22:21:59  wangye
 * removed an repeating line of code
 *
 * Revision 1.5  2010/07/22 22:47:44  plynch
 * Changes for making non-large edit fields select the text on receiving focus.
 *
 * Revision 1.4  2009/12/22 22:22:43  plynch
 * Changed splitFullFieldID so that its return value is cached, updated
 * the code to be aware of that, and moved the function into idCache.js.
 *
 * Revision 1.3  2009/09/25 21:27:09  wangye
 * removed log info
 *
 * Revision 1.2  2009/09/11 15:48:34  wangye
 * fixed a bug on multi-field edit box that when jumping between 2 boxes the 1st one does not disappear
 *
 * Revision 1.1  2009/07/31 22:03:54  wangye
 * added a multi-field editor for test panels
 *
 */

//global object and initial properties
var MultiFieldBox = {
	'srcEle' : null,
  'newEle' : null,
  'inputFields': null,
  'referenceField': null,
  'valueField':null,
  'leaving':null,
  'seperator': ' - '
}

MultiFieldBox.reset = function() {
  MultiFieldBox.srcEle = null;
  MultiFieldBox.newEle = null;
  MultiFieldBox.inputFields = null;
  MultiFieldBox.referenceField = null;
  MultiFieldBox.valueField = null;
  MultiFieldBox.leaving = null;

}
//find an element's screen position
//left-top point, margin/border/padding included. 
MultiFieldBox.findPos = function(obj) {
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
MultiFieldBox.findRelativePos = function(obj, ancID) {
  var curleft = curtop = 0;
  while (obj != null && obj.id != ancID ) {
    curleft += parseInt(obj.offsetLeft);
    curtop += parseInt(obj.offsetTop);
    obj = obj.offsetParent;
	}
	return [curleft,curtop];
  
}


//simulate keypress event to fire an autocompleter event
//not working: the keypress event listener on on srcEle not fired
//not used.
MultiFieldBox.simulateKeyPress = function() {
//  var evt = document.createEvent("UIEvents");
//  evt.initUIEvent("keypress", true, true, window, 1);
//  MultiFieldBox.srcEle.dispatchEvent(evt);
  
  var evt = document.createEvent("KeyboardEvent");
  if(evt.initKeyEvent && MultiFieldBox.srcEle.dispatchEvent) {
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

    MultiFieldBox.srcEle.dispatchEvent(evt);
   }

}

MultiFieldBox.simulateChange = function() {
  
  if (document.createEventObject){
        // dispatch for IE
        var evt = document.createEventObject();
        MultiFieldBox.srcEle.fireEvent('onchange',evt)
    }
    else{
        // dispatch for firefox + others
        var evt = document.createEvent("HTMLEvents");
        evt.initEvent("change", true, false ); 
        MultiFieldBox.srcEle.dispatchEvent(evt);
    }    
}

MultiFieldBox.simulateBlur = function() {

  if (document.createEventObject){
        // dispatch for IE
        var evt = document.createEventObject();
        MultiFieldBox.srcEle.fireEvent('onblur',evt)
    }
    else{
        // dispatch for firefox + others
        var evt = document.createEvent("HTMLEvents");
        evt.initEvent("blur", true, false );
        MultiFieldBox.srcEle.dispatchEvent(evt);
    }
}

//display a large edit box
MultiFieldBox.showMultiFieldBox = function(e) {

  //get source element
 	var targ;
	if (!e) e = window.event;
	if (e.target) targ = e.target;
	else if (e.srcElement) targ = e.srcElement;
  // defeat Safari bug
	if (targ.nodeType == 3)	targ = targ.parentNode;

  // if a box already exists on another field, get rid of that box first
  if ( MultiFieldBox.srcEle != null && 
       MultiFieldBox.srcEle != undefined &&
       MultiFieldBox.srcEle != targ) {
    MultiFieldBox.saveText();
    MultiFieldBox.simulateChange();
    MultiFieldBox.simulateBlur();
    MultiFieldBox.reset();
  }


  // for some reason, if the onFocus event is triggered twice
  if (targ == MultiFieldBox.srcEle) {
    MultiFieldBox.inputFields[0].focus();
    return;
  }
  
  var ele_id = targ.id;
  var id_parts = Def.IDCache.splitFullFieldID(ele_id);
  var ref_ele = $(id_parts[0] + targ.getAttribute('ref_fd') + id_parts[2])
  var val_ele = $(id_parts[0] + targ.getAttribute('val_fd') + id_parts[2])
  
  var units = ref_ele.value.split('-');

  if (units.length <=1) {
    return;
  }
  //create a large edit box
  var newDiv = document.createElement("div");
  Element.addClassName(newDiv, "mFieldBoxWrapper")

  var strInputField = "<td><input type='text' class='mFieldBox' ></input></td>";
  var strSeperator = "<td><label>" + MultiFieldBox.seperator + "</label></td>";
  var strTable = "<table><tbody><tr>" + strInputField + strSeperator +
                  strInputField + "</tr></tbody></table>"
  newDiv.innerHTML = strTable
  //add the newly created element and it's content into the DOM
  //#formContent has to be "position: relative;"
  //so that the newly added textarea stays put over the text input field 
  //while form is being scrolled up or down.
  //Since newDiv will probably be positioned twice, make it invisiable first to
  //get rid of the "Jump" visual effect.
  newDiv.style.visibility = "hidden";
  $("formContent").appendChild(newDiv);
  
  //get source element's position
  var srcPos = MultiFieldBox.findRelativePos(targ, "formContent");
  
  newDiv.style.left = srcPos[0] + "px";
  newDiv.style.top = srcPos[1] + "px";

  var srcWidth = targ.getWidth();
  var srcHeight = targ.getHeight();
  newDiv.style.width = srcWidth +'px';
  newDiv.style.height = srcHeight +'px';
  
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
  var realPos = MultiFieldBox.findRelativePos(newDiv, "formContent");
  
  // srcPos and realPos are same in FF3 if lgEditBoxWrapper is set as 
  // position:relative
  // They are always different in FF2, and in FF3 if lgEditBoxWrapper is NOT 
  // set as position:relative. 
  // srcPos = realPos + [border width of $('formContent')]   
  if (srcPos[0] - realPos[0] != 0) {
    newDiv.style.left = srcPos[0] + (srcPos[0] - realPos[0]) + "px";
  }
  if (srcPos[1] - realPos[1] != 0) {
    newDiv.style.top = srcPos[1] + (srcPos[1] - realPos[1]) + "px";
  }

  newDiv.style.visibility = "visible";
  var newEditBox = newDiv.getElementsBySelector("input[type=text]");
  //add event listener on the new large edit box
  for(var i=0; i< 2; i++) {
    Event.observe(newEditBox[i], 'keydown', MultiFieldBox.processKey);
    Event.observe(newEditBox[i], 'blur', MultiFieldBox.processBlur);
    Event.observe(newEditBox[i], 'focus', MultiFieldBox.processFocus);
    Def.ClickedTextSelector.setUpObservers(newEditBox[i]);
  }

  newEditBox[0].style.width = (srcWidth-4-6)/2  + 'px';
  newEditBox[1].style.width = (srcWidth-4-6)/2  + 'px';
  newEditBox[0].style.height = srcHeight  + 'px';
  newEditBox[1].style.height = srcHeight  + 'px';
  var seperator = newDiv.getElementsBySelector("label");
  seperator[0].style['height'] = srcHeight + 'px';
  seperator[0].style['width'] = 6 + 'px';
//  var val_parts = val_ele.value.split('|');
  var val_parts = targ.value.split(MultiFieldBox.seperator);
  if (val_parts) {
    if (val_parts.length ==2) {
      newEditBox[0].value = val_parts[0];
      newEditBox[1].value = val_parts[1];
    }
    else if (val_parts.length ==1) {
      newEditBox[0].value = val_parts[0];
    }
  }
  MultiFieldBox.srcEle = targ;
  MultiFieldBox.newEle = newDiv;
  MultiFieldBox.inputFields = newEditBox;
  MultiFieldBox.referenceField = ref_ele;
  MultiFieldBox.valueField = val_ele;
  targ.doNotSelect = true;
  newEditBox[0].focus();
  
}



MultiFieldBox.processKey = function(e) {
  Def.Navigation.firstKey_ =false
  //get source element
 	var targ;
  if (!e) e = window.event;
	if (e.target) targ = e.target;
	if (targ.nodeType == 3) // defeat Safari bug
		targ = targ.parentNode;
  //MultiFieldBox.getKeyCode(e);
  var keycode = e.keyCode;
  switch (keycode) {
  case Event.KEY_ESC: //ESC
  //ECS: exit editing without save the content      
    MultiFieldBox.cancelText(e);
    //MultiFieldBox.srcEle.focus();
    Def.Navigation.moveToPrevFormElem(MultiFieldBox.srcEle) ;
    MultiFieldBox.reset();
    Event.stop(e);
    break;
  case Event.KEY_RETURN:
  case Event.KEY_TAB:
    // shift key is pressed too
    if (e.shiftKey) {
      // on the 2nd input field, move focus to the 1st field. not to save
      if (targ == MultiFieldBox.inputFields[1]) {
        MultiFieldBox.inputFields[0].focus();
        Event.stop(e);
      }
      // on the 1st field, save
      else {
        Def.Navigation.moveToPrevFormElem(MultiFieldBox.srcEle) ;
        // canel the event, not to submit the form
        Event.stop(e);
      }

    }
    else {
      // on the 1st input field, move focus to the 2nd field. not to save
      if (targ == MultiFieldBox.inputFields[0]) {
        MultiFieldBox.inputFields[1].focus();
        Event.stop(e);
      }
      // on the 2nd field, save
      else {
        if (!Def.FieldsTable.skipBlankLine(MultiFieldBox.srcEle)) {
          Def.Navigation.moveToNextFormElem(MultiFieldBox.srcEle) ;
        }
        // canel the event, not to submit the form
        Event.stop(e);
      }
    }
    break;
  default:
  }
  
}

MultiFieldBox.cancelText = function(e) {

  if (!MultiFieldBox.newEle) return;
  
  //remove this element
  Def.ClickedTextSelector.removeObservers(MultiFieldBox.inputFields[0]);
  Def.ClickedTextSelector.removeObservers(MultiFieldBox.inputFields[1]);
  $("formContent").removeChild(MultiFieldBox.newEle);

}

MultiFieldBox.saveText = function() {
  
  if (!MultiFieldBox.newEle) return;
  //get the value from the textarea element
  var value_1 = MultiFieldBox.inputFields[0].value;
  var value_2 = MultiFieldBox.inputFields[1].value;
  if (value_1.match(/^\s*$/) && value_2.match(/^\s*$/)) {
    Def.setFieldVal(MultiFieldBox.srcEle, '');
    Def.setFieldVal(MultiFieldBox.valueField, '');
  }
  else {
    var textValue= MultiFieldBox.inputFields[0].value + MultiFieldBox.seperator +
                   MultiFieldBox.inputFields[1].value;
    var realValue = MultiFieldBox.inputFields[0].value + "|" +
                    MultiFieldBox.inputFields[1].value;
    //save the value to the original text input element
    if (MultiFieldBox.srcEle) {
      Def.setFieldVal(MultiFieldBox.srcEle, textValue);
    }
    if (MultiFieldBox.valueField) {
      Def.setFieldVal(MultiFieldBox.valueField, realValue);
    }
  }
  //remove this element
  MultiFieldBox.srcEle.doNotSelect = false;
  Def.ClickedTextSelector.removeObservers(MultiFieldBox.inputFields[0]);
  Def.ClickedTextSelector.removeObservers(MultiFieldBox.inputFields[1]);
  $("formContent").removeChild(MultiFieldBox.newEle);
}

MultiFieldBox.processBlur = function(e) {
  //exit editing and save the content
  MultiFieldBox.leaving = true;
  setTimeout(function() {
    if (MultiFieldBox.leaving) {
      MultiFieldBox.saveText();
      MultiFieldBox.simulateChange();
      MultiFieldBox.simulateBlur();
      MultiFieldBox.reset();
    }
  }, 3);

}

MultiFieldBox.processFocus = function(e) {
  MultiFieldBox.leaving = false;
}

MultiFieldBox.srcKeyEventHandler = function(e) {
  
  //get source element
 	var targ;
  if (!e) e = window.event;

	if (e.target) targ = e.target;
	else if (e.srcElement) targ = e.srcElement;
	if (targ.nodeType == 3) // defeat Safari bug
		targ = targ.parentNode;
  
  var keycode = e.keyCode;
  
  switch (keycode) {
  case 115: //F4 keycode=115
    MultiFieldBox.showMultiFieldBox(e)
    break;
  //charactors
  default:
  }
}

MultiFieldBox.srcOnFocusHandler = function(e) {
  MultiFieldBox.showMultiFieldBox(e)
  Event.stop(e);
}

