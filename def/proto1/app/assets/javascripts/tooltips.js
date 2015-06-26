//OFT1.1
///////////////////////////////////////
//
//  Onfocus tooltips by Brothercake
//  http://www.brothercake.com/
//
///////////////////////////////////////

//global object and initial properties
var tip = {
	'tooltip' : null,
	'parent' : null,
	'timer' : null
	};

var map = new Object();


//initialisation function
tip.init = function()
{
   // initialize and position tooltips 
   // toggleTipMessages(document) ;
}
//  No - we're now doing this from the setUp
//setup initialisation function
// Using prototype method to register/unregister any events to ensure cross 
// browser compatibility
// Event.observe(window, 'load', tip.init);
//find object position
tip.getRealPosition = function(ele, dir)
{
	tip.pos = (dir=='x') ? ele.offsetLeft : ele.offsetTop;
	tip.tmp = ele.offsetParent;
	while(tip.tmp != null)
	{
		tip.pos += (dir=='x') ? tip.tmp.offsetLeft : tip.tmp.offsetTop;
		tip.tmp = tip.tmp.offsetParent;
	}
	return tip.pos;
}

//delay timer
tip.focusTimer = function(e)
{ 
     if ((e.target != undefined && e.target_value != undefined && e.target.value.length > 0)
        || (e.value != undefined && e.value != undefined && e.value.length > 0))
     {
       Event.stopObserving(tip.tags[i],'blur',tip.focusTimer,'false') ;
       Event.stopObserving(tip.tags[i],'focus',tip.blurTip,'false') ;
       return ;
     }
	//second loop	
	if(tip.timer != null)
	{
		//clear timer
		clearInterval(tip.timer);
		tip.timer = null;
	
		//pass object to create tooltip
		tip.focusTip(e);
	}
	//first loop
	else
	{
		//get focussed object to pass back through timer
		tip.tmp = (e) ? e.target : event.srcElement;
                // temporary fix to hide the list when focus on this field
                // Should ideally work in only those cases where we have
                // hifeTheList defined on onfocus. Which for now is true for all date
                // fields. Try to add original onFocus added while atatching this 
                // function
		//set interval
		tip.timer = setInterval('tip.focusTimer(tip.tmp)',tip_delay);
	}
}

//create tooltip
tip.focusTip = function(obj)
{

	//remove any existing tooltip
	tip.blurTip();

	//if tooltip is null
	if(tip.tooltip == null)
	{
		//get window dimensions
		if(typeof window.innerWidth!="undefined")
		{
			tip.window = {
				x : window.innerWidth,
				y : window.innerHeight
				};
		}
		else if(typeof document.documentElement.offsetWidth!="undefined")
		{
			tip.window = {
				x : document.documentElement.offsetWidth,
				y : document.documentElement.offsetHeight
				};
		}
		else 
		{
			tip.window = {
				x : document.body.offsetWidth,
				y : document.body.offsetHeight
				};
		}

		//create toolTip, detecting support for namespaced element creation, in case we're in the XML DOM
		tip.tooltip = (typeof document.createElementNS != 'undefined') ? document.createElementNS('http://www.w3.org/1999/xhtml', 'div') : document.createElement('div');

		//add classname
		tip.tooltip.setAttribute('class','');
		tip.tooltip.className = 'tooltip';

		//get focussed object co-ordinates
		if(tip.parent == null)
		{
			tip.parent = {
				x : tip.getRealPosition(obj,'x') - 3,
				y : tip.getRealPosition(obj,'y') + 2
				};
		}

		// offset tooltip from object
		tip.parent.y += obj.offsetHeight;

		//apply tooltip position
		tip.tooltip.style.left = tip.parent.x + 'px';
		tip.tooltip.style.top = tip.parent.y + 'px';
                 
                // aa
                tip.tooltip.appendChild(document.createTextNode(obj.title));

		//add to document
		document.getElementsByTagName('body')[0].appendChild(tip.tooltip);

		//restrict width
		if(tip.tooltip.offsetWidth > 300)
		{
			tip.tooltip.style.width = '300px';
		}

		//get tooltip tip.extent
		tip.extent = {
				x : tip.tooltip.offsetWidth,
				y : tip.tooltip.offsetHeight
				};

		//if tooltip exceeds window width
		if((tip.parent.x + tip.extent.x) >= tip.window.x)
		{
			//shift tooltip left
			tip.parent.x -= tip.extent.x;
			tip.tooltip.style.left = tip.parent.x + 'px';
		}

// remove after testing in IE
		//get scroll height
//		if(typeof window.pageYOffset!="undefined")
//		{
//			tip.scroll = window.pageYOffset;
//		}
//		else if(typeof document.documentElement.scrollTop!="undefined")
//		{
// 	                tip.scroll = document.documentElement.scrollTop;
//		}
//		else 
//		{
//			tip.scroll = document.body.scrollTop;
//		}
                // Since we use dojoSplit, the default scroll does not get correct position.
                // The inner scroll bar is not counted. We need a DOM compliant browser
                // and this code works there
    tip.scroll =  document.getElementById('vFormArea').scrollTop;

		//if tooltip exceeds window height
		if((tip.parent.y + tip.extent.y) >= (tip.window.y + tip.scroll))
		{
			//shift tooltip up
			tip.parent.y -= (tip.extent.y + obj.offsetHeight  +4 );
			tip.tooltip.style.top = tip.parent.y + 'px';
		}
                    
                       // position the tooltip correctly
			// tip.parent.y -= tip.scroll - 10;
			tip.parent.y -= tip.scroll ;
			tip.tooltip.style.top = tip.parent.y + 'px';

		 	tip.parent.x += 27 ;
			tip.tooltip.style.left = tip.parent.x + 'px';

	}
}

//remove tooltip
tip.blurTip = function()
{
	//if tooltip exists
	if(tip.tooltip != null)
	{
		//remove and nullify tooltip
		document.getElementsByTagName('body')[0].removeChild(tip.tooltip);
		tip.tooltip = null;
		tip.parent = null;
	}
	
	//cancel timer
	clearInterval(tip.timer);
	tip.timer = null;
}


/** 
 * Display the tooltip in a box 
 * @param targ target tipMessage node which needs to be positioned and displayed.
 *             or hidden depending on current.
 */ 
tip.displayTipInTextbox= function(targ) {
    

      // defeat Safari bug
	  if (targ.nodeType == 3)	targ = targ.parentNode;

      //add the newly created element and it's content into the DOM
      //#formContent has to be "position: relative;"
      //so that the newly added textarea stays put over the text input field 
      //while form is being scrolled up or down.
      //Since newDiv will probably be positioned twice, make it invisiable first to
      //get rid of the "Jump" visual effect.
      // targ.style.visibility = "visible";
  
      //get source element's position
      var srcPos = tip.findRelativePosToPrevSibling(targ);
  
      //reposition it, 10px is the border width of #formContent, see below.
      //var bdrTop = parseInt(LargeEditBox.getStyle($("formContent"),'borderTopWidth'));
      //var bdrLeft = parseInt(LargeEditBox.getStyle($("formContent"),'borderLeftWidth'));

      targ.style.left = srcPos[0] + "px";
      targ.style.top = srcPos[1] + "px";
  
      //There's a bug in firefox. 
      //On PHR form, the form banner includes a image which is loaded through css
      //file. The real offset position of left and top of the newDiv are 10px 
      //shorter than where it is supposed to be. The 10px appears to be the left 
      //and top border width of #formContent.
      //The fix is to compare the the real postion of the newDiv after it is 
      //inserted into DOM and the supposed position. And add the difference if any.
      var realPos = tip.findRelativePos(targ);
      if (srcPos[0] - realPos[0] != 0) {
        targ.style.left =  srcPos[0] + (srcPos[0] - realPos[0]) + "px";
      }
      if (srcPos[1] - realPos[1] != 0) {
        targ.style.top = srcPos[1] + (srcPos[1] - realPos[1]) + "px";
      }

      targ.style.zIndex = "1"
      targ.previousSibling.style.zIndex = "2";
      // Toggles the visibility of tooltip/text field based on whether there is a value.
      if (targ.previousSibling.value == ''){
          targ.previousSibling.style.opacity = "0.0"
          targ.style.opacity = "1.0"
          targ.style.zIndex = "1.0"
          
          if (targ.previousSibling.height != null) {
             targ.style.height = targ.previousSibling.height+ "px" ;
          }
          else if( targ.previousSibling.style.height != '')
          {
              targ.style.height =  targ.previousSibling.style.height ;
          }
          else if( targ.previousSibling.clientHeight != '')
          {
              targ.style.height =  targ.previousSibling.clientHeight + "px" ;
          }

          if (targ.previousSibling.width != null) {
              targ.style.width = targ.previousSibling.width+ "px" ;
          }
          else if(  targ.previousSibling.style.width != '' )
          {
              targ.style.width = targ.previousSibling.style.width  ;
          }
          else if(  targ.previousSibling.clientWidth != '' )
          { 
              targ.style.width = targ.previousSibling.clientWidth+ "px"  ;
          }
      }
      else {
          targ.previousSibling.style.opacity = "1.0"
          targ.style.opacity = "0.0"
          targ.style.zIndex = "-1"
      }

        targ.style.visibility = "visible";
   }   
   
//find an element's position relative to an ancestor/parent 
// node and previous sibling.
//left-top point, margin/border/padding included. 
tip.findRelativePosToPrevSibling = function(obj) {
 var curleft = curtop = 0;
  if(obj.previousSibling && obj.parentNode)
  {
     objPar = obj.parentNode ;
     objSib = obj.previousSibling ;
     var parPos = tip.findPosition(objPar) ;
     var sibSrcPos = tip.findPosition(objSib) ;
     curleft = sibSrcPos[0] -  parPos[0] ;
     curtop = sibSrcPos[1] -  parPos[1];
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

//find an element's position relative to an ancestor/parent
//left-top point, margin/border/padding included. 
tip.findRelativePos = function(obj) {
 var curleft = curtop = 0;
  if(obj && obj.parentNode)
  {
     objPar = obj.parentNode ;
     var parPos = tip.findPosition(objPar) ;
     var objSrcPos = tip.findPosition(obj) ;
     curleft = objSrcPos[0] -  parPos[0] ;
     curtop = objSrcPos[1] -  parPos[1];
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

tip.findPosition = function(obj) {
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


 /** 
  * This method accepts a given form element (or id string from which
  * it obtains the element) and finds the children of that element that
  * have a tooltip message.  It calls displayTipInTextbox for each child
  * element found with a tooltip.
  *
  * @param tag form element, or id of a form element, that should be 
  *            searched for child elements with tip messages 
 function toggleTipMessages(tag)  {

   return true;

    if (tag.nodeType == 9){
       tip.tipTags = $$('[class="tipMessage"]') ;
    }
    else {
   Def.Logger.logMessage(['in toggleTipMessages, tag id = ', $(tag).id]);
      //if (!Object.isElement(tag))
      // extend it anyway. --IE debugging
      tag = $(tag) ;
      tip.tipTags = tag.select('.tipMessage');
    }

    if (tip.tipTags)
    {
      tip.tipTagsLen = tip.tipTags.length;
      for (var i=0, il = tip.tipTagsLen; i < il ; i++) {
        theField = tip.tipTags[i].previousSibling ;
        if (theField.value == ''){
            theField.tipValue = theField.nextSibling.textContent ;
	          theField.value	= theField.tipValue;
	         	theField.style.color	= "gray";
            theField.setAttribute("noValue", true);
        }
        else {
           theField.setAttribute("noValue", false);
           theField.style.color	= "";
        }
    }
  }
} // end toggleTipMessages
*/

