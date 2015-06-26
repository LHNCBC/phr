// License:  This file should be considered to be under the terms of some
// "non-viral" open source license, which we will specify soon.  Basically,
// you can use the code as long as you give NLM credit.

// This file contains auto-completer code for the Data Entry Framework project.
// These autocompleters are for the split style of display, where the
// auto-completion list appears in a separate area on the right or below.

// These autocompleters are based on the Autocompleter.Base class defined
// in the Script.aculo.us controls.js file.

/**
 *  The autocompleter for the fill-in-the-blanks tool.
 */
Def.Autocompleter.FillInBlanks = Class.create();
Object.extend(Def.Autocompleter.FillInBlanks.prototype,
  Def.Autocompleter.Prefetch.prototype);
Def.Autocompleter.FillInBlanks.prototype.className = 'Def.Autocompleter.FillInBlanks' ;  
Object.extend(Def.Autocompleter.FillInBlanks.prototype, {
  /**
   *  The constructor.  (See Prototype's Class.create method.)
   * @param id the ID of the field
   * @param matchListValue whether the field should validate its value
   *  against the list.
   * @param add_seqnum whether sequence numbers should be added to the items 
   *  in the prefetched answer list.
   * @param added indicates if the item in array already has number added if 
   *  add_seqnum is true.
   * @param template the string containing the templates for this list
   * @param rightAuto is a flag which indicates if this is the right sided
   *  autocomplater or not
   */
  initialize: function (id, matchListValue, add_seqnum, added, templateStr, 
      rightAuto) {
    this.templateStr = templateStr;
    this.listItems = new Array(); //associative array where listItems[{dose} {route} {freq}] = {dose||25mg, 50mg, 75mg|||y}{freq||BID, ...
    this.rAuto = rightAuto; //flag that indicates if this is the rightsided autocompleter
    var sigRegExp;  //some regualr expression that gets used once
    var numSigs; //number of sigs i.e. list items in autoco,pleter
    var sigChoices; //an array that holds holds the actual unformatted elements i.e. {dose||50mg, 25mg, |....
    var arr= new Array(); //holds the displayed elements
    var divUpdate; 
    
    //separate string into list items for autocompleter
    if (this.rAuto) { //if its the autocompleter on the right
      sigRegExp = /(![^!;]+;)*([^!;]+)/g; //this probably is not quite right (ctd)
      //, looks for zero or more headers ! followed by ; any other text that is not a header
      //somehow text before the first { doesn't work though
      
      sigChoices = templateStr.match(sigRegExp);
      divUpdate =null; //will get set to 'completionOptions' in Prefetch initialize
    } else { //not right auto, so this is a list of 25mg, 50mg, 75mg etc.
      sigChoices = templateStr.split("\,");
      divUpdate =  document.createElement("DIV"); //create div that will drop down and contain input boxes
      divUpdate.writeAttribute({"class": "auto_complete"});
      divUpdate.style.display="none";
      $(id).insert({"after": divUpdate}); //append to doc (MISSION CRITICAL)
    }

    numSigs = sigChoices.size();
  
    //get rid of the headers FOR NOW
    for (var h=0; h< numSigs; h++){
      sigChoices[h] = sigChoices[h].replace(/![^!;]+;/g, "");
    }
    
    //format list items to be displayed, populate listItems
    for (var i = 0; i< numSigs; i++){
      if (sigChoices[i][0] == "{"){ //if it has {dose||25mg, 50mg, ...
        arr[i] = sigChoices[i].replace(/([\|]+)[^}]*/g, ""); 
        //make it look nice by getting rid of 25mg, etc -> {dose}
        arr[i][0] +="}";
      }
      else {
        //nothing in {} here, but user should still be able to choose i.e. 975mg PO q6h
        arr[i] = sigChoices[i];
      }
      
      //see comment for listArr at top
      this.listItems[arr[i]] = sigChoices[i];
    }

    //call prefetch autocompleter initialize method 
    Def.Autocompleter.Prefetch.prototype.initialize.apply(this, 
      [id, false, add_seqnum, arr, null, null, divUpdate]);

    //for some reason you have to set update (in base class auto init AND listContainer
    //only if it is not the right auto
    if (!this.rAuto) {
      //llistarr (id is divarr) x holds the list for inarr x
      this.listContainer = $(divUpdate);
      this.update.style.display="none";
    }
  },

  
  /**
   *  A copy constructor, for a new field (e.g. another field in a new row
    *  of a table).
    * @param fieldID the ID of the field being assigned to the new autocompleter
    *  this method creates.
    * @return a new autocompleter for field field ID
    */
  dupForField: function(fieldID) {
    // TBD - This section has not been tested, because we are not yet
    // actually using FillInBlanks autocompleters, let alone putting
    // them into tables.  PL 2008/4/23
    return new Def.Autocompleter.FillInBlanks(fieldID,
      this.matchListValue_, this.add_seqnum, false, this.templateStr, null,
      null, this.rAuto);
  },


  /** updateElement. remove the sequence # from the selected item in the list
   *  
   */
  updateElement: function(selectedElement) {
    if (this.options.updateElement) {
      this.options.updateElement(selectedElement);
      return;
    }

    var value = '';
    var tempValue;
    if (this.options.select) {
      var nodes = document.getElementsByClassName(this.options.select, selectedElement) || [];
      if(nodes.length>0) value = Element.collectTextNodes(nodes[0], this.options.select);
    } else
      value = Element.collectTextNodesIgnoreClass(selectedElement, 'informal');
    
    // remove serail number
    if (this.add_seqnum == true) {
      var index = value.indexOf(' - ');
      value = value.substring(index + 3);
      //console.log(value);
    }
    
    tempValue = value;
    
    //if its is free text with no input boxes, listArr['975 mg PO qdaily'] == '975mg PO qdaily'
    //another layer in this becomes lsitArr['35mg'] == '35mg'
    //this will put the focus back in the same filed if it is plain text
    //this works
    if(!(tempValue == this.listItems[value])) {
      value = this.listItems[value];
      this.firstDivField = this.showDiv(value);
    } else { //no need to run show div, just plain text here
      //this.element.value = value;
      Def.setFieldVal(this.element, value);
      //Def.Logger.logMessage([this.element.id, " 1 setFieldVal in autoCompFillingBlank.updateElement"]);
    }

    if (this.options.afterUpdateElement)
      this.options.afterUpdateElement(this.element, selectedElement); 
  },
  
 /* showList: function() {
    this.listContainer.style.visibility = 'visible';
    if (!this.rAuto) {
      this.listContainer.style.display = 'inline';
    }
  },*/
  
  
  /**
   *  USED TO Position the answer list and scrolls the selected item (if any)
   *  into view.  Now does nothing...maybe this should only run if it is the right sided auto
   */
  positionAnsList: function() {
    var doNothing;
  },
    
  /**
   *  Puts the focus into the field.
   *  fisrtDivField is the first input box
   *  if it is null then it is just free text, (right?)
   *
   */
  focusField: function() {
    if (this.firstDivField) {
      this.firstDivField.focus();
    } else {
      this.element.focus();
    }
  },
  
  
  //called in afterUpdateElement
  //created the inputboxes and the div for the template
  showDiv: function(sigStrSelect){
    if (!sigStrSelect)
       return;
    // adapted from this: http://codingforums.com/archive/index.php?t-27510.html
    var sigs = this.parseQuestion(sigStrSelect);
    var hiddendiv; 
    var para;
    var arr = new Array(); //temporary container elements in {} 
    var inputarr = new Array(); //array of input boxes
    var listarr = new Array(); //array of divs that hold the drop down lists for autocompleter
    var textarr = new Array();
    var len=sigs.size(); //number of {} or fixed txt (ie PO, with meals, etc), also equals length of sigs array
    var autocomparr = new Array();
    var lastinput = -1;  //index of last inputarr elt (last input box)
    var sigChoices = new Array();
    var sigRegExp, numSigs;
    var childArray = new Array(); //so you can walk through them all at the end and append to hiddendiv



    //make input boxes
    for (var i = 0; i< len; i++){
      if (sigs[i][0] == "{"){
        //its in {}, need to parse it and make an input box 
        arr[i] = sigs[i].split("\|");
      
        //make a text box
        inputarr[i]=$(document.createElement("input"));

        inputarr[i].id=this.element.id + "_" + i.toString();
        inputarr[i].autocomplete="off";
        inputarr[i].value=arr[i][0] + "}";
        inputarr[i].addClassName('eventsHandled');
        lastinput = i;

        //assign the size of text box
        if (arr[i][1] > 0) {
          inputarr[i].size=arr[i][1]; 
        } 
        else {
          inputarr[i].size=12;
        }

        childArray.push(inputarr[i]);
      }
      else  {
        //its just free text 
        textarr[i] = document.createTextNode(sigs[i]);
        childArray.push(textarr[i]);
      }
    }
    
    //document.body.appendChild(this.hiddendiv);
    //if there are some input boxes that need to be filled out
    if (lastinput >= 0) {
        //make this div
      this.hiddendiv = $(document.createElement("DIV"));
      this.hiddendiv.writeAttribute({"class": "fillInBlanks"});
      
      for (var r = 0, max = childArray.length; r < max; r++){
        this.hiddendiv.appendChild(childArray[r]);
        childArray[r] = null;
      }
      
      // stuff starts appearing on page NOW
      this.element.insert({"after": this.hiddendiv});
      //setUpNavKeys();
      //loop to make the autocompleters
      for (var j=0; j< len; j++){
        if(inputarr[j]) {
          autocomparr[j] = new Def.Autocompleter.FillInBlanks(inputarr[j].id, true, true, false,arr[j][2], null, null, false);          
          autocomparr[j].id = "auto" + j.toString();
        }
      }
      
      //first input box should have focus and the text should be selected
      inputarr[0].focus();
      Def.Navigation.selectText(inputarr[0]);
      
      //if the user chooses something changes their mind 
      Event.observe(this.element, 'focus', 
        this.makeStr.bindAsEventListener(autocomparr[lastinput], len, inputarr, sigs, this));
      
      //return the completed string to the field, sort of works
     Event.observe(inputarr[lastinput], 'blur', 
        this.makeStr.bindAsEventListener(autocomparr[lastinput], len, inputarr, sigs, this));
      
      Def.Navigation.setUpNavKeys();
    }
    else { //the sig was just plain text i.e. 975mg PO q6h, no need to call makeStr
      //this.cleanUp(len-1, this);
      //this.element.value = sigStrSelect;
      Def.setFieldVal(this.element, sigStrSelect);
      //Def.Logger.logMessage([this.element.id, " 2 setFieldVal in autoCompFillingBlank.showDiv"]);
    }
    //return true if there are input boxes, false if no
    return (inputarr.length ? inputarr[0] : null);
  },

  //makes the string out of the fixed text and value of input boxes
  //walks through the input boxes and the sigs (if no input box exists) and makes the return string
  //called by event handlers in showDiv()
  makeStr: function (lastauto, len, inputarr, sigs, auto) {
    returnstr = "";
    //console.log("makestr");
    //if the autocompleter is not done yet MISSION CRITICAL
    if (lastauto.active) { 
    
      //wait for afterUpdateElement to run before coputing this string to be returned
      lastauto.options.afterUpdateElement = function() {
          this.makeStr(lastauto, len, inputarr, sigs);
      };
    }
    else {
      for (var l=0, returnstr = ""; l < len; l++){
        if (inputarr[l]) { //if there is an input box
          returnstr += inputarr[l].value;
        }
        else { //if there isnt an input box it is just text
          returnstr += sigs[l];
        }
      }
      //set the main input box at top to string you just made
      auto.element.value = returnstr;
      this.cleanUp(len-1, auto);
    }
  },

  //for parsing
  parseQuestion: function(parseThis){
    //(look for "}txt{" ) OR (look for "{text}" ), don't stop at first hit
    var curlyBrackets=/([^{}]+)|(\{[^}]*)/g;
    return parseThis.match(curlyBrackets);
  },

  //all this does is remove hidden div, it needs to do a lot more...
  cleanUp: function(lastinp, auto) {
    var n, tempinput, templist, tempauto;
    /*
    //get rid of inputarray
    for (n=0; n <= lastinp; n++) {
      tempinput = document.getElementById("inarr" + n.toString());
      //sometimes temp elt is null because there was fixed text in sigs
      if (tempinput) {
        
        //get rid of inputarr[n]
        p.removeChild(tempinput);
        
        //get rid of listarr[n]
        p.removeChild(document.getElementById("divlist" + n.toString()));
        
        //get rid autocomp[n]
        tempauto = document.getElementById("auto" + n.toString());
        if (tempauto) {
          tempauto = null;
        }
      }
      else { 
        //remove the textarr[i] -- for some reason 
        if (p && p.firstChild)  {//not sure why this would ever be null but it happend once
          p.removeChild(p.firstChild);
        }
      }
    }*/
    if(auto.hiddendiv && auto.hiddendiv.parentNode) {
      auto.hiddendiv.remove(); 
    }
    
  }
});



