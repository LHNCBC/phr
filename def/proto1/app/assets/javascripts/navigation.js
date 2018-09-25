/**
 * navigation.js -> javascript class that contains functions to control
 *                  keyboard navigation within an html form
 *
 * Form elements that participate in the keyboard navigation are all
 * input elements of type "text", "button", or "select".  The DOM
 * document.forms[f].elements array is used as the source of navigable
 * elements.
 *
 * Keys used for navigation are: the <TAB> and <RETURN> keys, which move
 * forward from field to field unless the <SHIFT> key is held down while
 * pressing them, in which case the direction is reversed; and the four
 * arrow keys IF the <CTRL> key is held down while pressing them.
 *
 * The UP arrow key's behavior outside of a table is the same as the LEFT
 * arrow key.  Inside a table the UP arrow key moves up a row in the table.
 * The DOWN arrow key's behavior is analogous - mirroring the RIGHT key
 * outside of a table and moving down a row within a table.
 *
 * Navigation keys move in and out of tables as appropriate to the requested
 * movement, without any special key sequence.  Likewise, when the end of the
 * form is reached (or the beginning if moving backwards), movement continues
 * at the beginning (or end) of the form.
 *
 * The <RETURN> key includes special handling, in that if it is depressed
 * while on a button, and the <SHIFT> key is NOT simultaneously depressed,
 * it is interpreted as a request to perform the action offered by the
 * button rather than as a navigation request.
 *
 * $Id: navigation.js,v 1.68 2011/06/02 17:02:19 plynch Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/navigation.js,v $
 * $Author: plynch $
 *
 * $Log: navigation.js,v $
 * Revision 1.68  2011/06/02 17:02:19  plynch
 * Fixes for problems that occurred with navigation after a row was deleted
 * from a controlled edit table.
 *
 * Revision 1.67  2011/04/20 16:37:57  plynch
 * Changed focuesedField_ to be null when not set, for easier checking
 *
 * Revision 1.66  2010/09/23 18:18:25  mujusu
 * typo fixes
 *
 * Revision 1.65  2010/09/23 15:28:32  mujusu
 * fixes javascript error when navigating back to first element
 *
 * Revision 1.64  2010/09/13 21:46:12  plynch
 * Changes to prevent the page from shrinking after it grows longer to
 * accomodate a list at the bottom of the page.
 *
 * Revision 1.63  2010/08/27 22:14:16  plynch
 * Made more fields wrapping fields, changed the alignment of the wrapping fields in the row, and fixed a bug in navigation.js.
 *
 * Revision 1.62  2010/07/30 15:44:37  plynch
 * Some related to the selection of text in fields that should have been
 * checked in before.
 *
 * Revision 1.61  2010/07/22 22:47:44  plynch
 * Changes for making non-large edit fields select the text on receiving focus.
 *
 * Revision 1.60  2010/05/07 13:42:06  lmericle
 * removed some commented out code - long obsolete
 *
 * Revision 1.59  2010/03/05 14:35:54  lmericle
 * moved initialization of general handler wrappers to separate function for instances where they need to be referenced before the navigation is set up (combo fields)
 *
 * Revision 1.58  2010/01/29 16:45:00  lmericle
 * added optional theObservers parameter to setUpFieldListeners
 *
 * Revision 1.57  2009/12/22 22:22:43  plynch
 * Changed splitFullFieldID so that its return value is cached, updated
 * the code to be aware of that, and moved the function into idCache.js.
 *
 * Revision 1.56  2009/11/18 20:41:03  plynch
 * A fix to get the class and ingredient check to fire correctly in the drug
 * table when the status is changed, plus changes to way change events are run.
 *
 * Revision 1.55  2009/06/30 17:57:45  lmericle
 * moved document key event handler to Def.Navigation.handleDocumentKeyEvent (from setUpDocumentKeyEventListener)
 *
 * Revision 1.54  2009/06/16 15:27:52  lmericle
 * fixed hidden_field class qualifier for buttons to get moveIfHidden event handler
 *
 * Revision 1.53  2009/06/15 19:51:18  lmericle
 * restricted application of moveIfHidden event handler so that, for button elements, it's only applied if the button has in the hidden_class
 *
 * Revision 1.52  2009/06/11 15:25:13  lmericle
 * moved large edit box handlers out of setUpFieldListeners and into form_helper.rb
 *
 * Revision 1.51  2009/05/29 17:27:13  lmericle
 * finished switch from field initializers to field observers
 *
 * Revision 1.50  2009/05/27 12:58:15  lmericle
 * modified structure of fieldInitializers, changes to accommodate
 *
 * Revision 1.49  2009/05/15 23:24:52  lmericle
 * moved creation of moveIfHidden click event handler to be executed after all others
 *
 * Revision 1.48  2009/05/13 20:51:14  lmericle
 * removed some console output no longer needed
 *
 * Revision 1.47  2009/05/12 16:12:26  lmericle
 * removed log message in setUpFieldListeners
 *
 * Revision 1.46  2009/04/28 21:16:07  lmericle
 * removed log comment
 *
 * Revision 1.45  2009/04/22 22:34:21  plynch
 * Fixes for the controlled edit table to initialize listeners on fields for
 * rows that are made editable.
 *
 * Revision 1.44  2009/04/21 14:45:54  lmericle
 * fixed bug in setUpFieldListeners where I was referencing element.type instead of element.tagName
 *
 * Revision 1.43  2009/04/16 20:45:43  lmericle
 * modified setUpFieldListeners to accomodate parameters in fieldInitializers_
 *
 * Revision 1.42  2009/04/14 18:12:00  mujusu
 * locate element only once and reuse
 *
 * Revision 1.41  2009/04/03 17:46:27  lmericle
 * changed doNavKeys to call setUpFieldListeners for all fields; modified setUpFieldListeners to condition more specifically.  (Fixed checkbox rules).
 *
 * Revision 1.40  2009/04/03 15:30:27  lmericle
 * added fieldInitializers_ and initialerFunctions_ in application_phr.js and used them in navigation setUpFieldListeners to set up event observers
 *
 * Revision 1.39  2009/03/26 14:59:57  lmericle
 * added focusedField_ to navigation.js and code to set it
 *
 * Revision 1.38  2009/03/20 22:10:59  wangye
 * js performance improvement
 *
 * Revision 1.37  2009/03/20 13:38:20  lmericle
 * changes related to conversion of navigation.js functions to Def.Navigation class object
 *
 * Revision 1.36  2009/03/19 18:15:57  lmericle
 * changes to redo navSeqsHash for fields that have been resorted
 *
 * Revision 1.35  2009/03/16 23:00:32  plynch
 * Gave the fields table stuff a namespace.
 *
 * Revision 1.34  2009/03/06 21:15:49  lmericle
 * implemented navSeqsHash to speed up navigation loading; changes related to that
 *
 * Revision 1.33  2009/03/03 15:32:03  lmericle
 * removed some redundant calls to isHiddenOrDisabled
 *
 * Revision 1.32  2009/02/03 19:47:29  lmericle
 * removed timeout we tried in moveToNextFormElem - didn't work.
 *
 * Revision 1.31  2009/01/28 23:18:54  smuju
 * Fixed navigation bug.  submit buttons will now submit form.
 *
 * Revision 1.30  2009/01/14 22:03:32  taof
 * after click submit button, user should be able to dynamically update error msgs
 *
 * Revision 1.29  2008/12/29 15:06:01  lmericle
 * corrected comment typo
 *
 * Revision 1.28  2008/12/18 18:28:30  lmericle
 * added timeout for navigation from autocompleter field with recDataRequester
 *
 * Revision 1.27  2008/12/15 20:40:48  plynch
 * Changes to add codes to AJAX lists;
 * changes to autocompleters to make them behave more alike
 * changes to test code.
 *
 * Revision 1.26  2008/11/20 13:44:47  lmericle
 * fixed bug in upInTable
 *
 * Revision 1.25  2008/11/19 21:01:57  lmericle
 * Modified navigation to handle embedded rows correctly
 *
 * Revision 1.24  2008/11/18 18:05:51  lmericle
 * modified navigation scheme to use prev/next pointers instead of sequence numbers
 *
 * Revision 1.23  2008/11/05 19:42:08  smuju
 * ifixed table navigation for date fields
 *
 * Revision 1.22  2008/10/24 21:34:31  wangye
 * bug fixes for IE7 and performance tune-up
 *
 * Revision 1.21  2008/10/23 15:17:23  wangye
 * bug fix for IE7
 *
 * Revision 1.20  2008/10/22 18:14:22  smuju
 * *** empty log message ***
 *
 * Revision 1.19  2008/10/22 15:43:16  lmericle
 * change to reduce unnecessary calls to $
 *
 * Revision 1.18  2008/10/20 17:42:25  smuju
 * commented out toggletooltip in setupnavkeys as it is being done outside + plus causes performance issues
 *
 * Revision 1.17  2008/10/16 20:43:04  lmericle
 * added tasks, such as large edit box initial tasks, to setUpNavKeysForField to consolidate runs through all document elements
 *
 * Revision 1.16  2008/10/09 22:07:37  lmericle
 * moved code to set large edit box event observers on text input fields from separate onload event started in lgEditBox.js to setUpNavKeys in navigation.js - so that they're set at the same time we work through the form elements for other things.
 *
 * Revision 1.15  2008/10/09 19:54:29  lmericle
 * conditioned doNavKeys on existing elements
 *
 * Revision 1.14  2008/08/19 19:45:26  smuju
 * added functionality to select text on first click and allow edit subsequently on next click
 *
 * Revision 1.13  2008/08/04 23:49:46  plynch
 * fields_table.js - corrected some bugs in skipBlankLine
 * navigation.js - fixed a bug in moveToNextFormElem
 * (related to task 707)
 *
 * Revision 1.12  2008/07/22 18:17:04  lmericle
 * oops - removed console.log debugging line
 *
 * Revision 1.11  2008/07/22 17:21:40  lmericle
 * modified form field moves to take into account permission problems
 *
 * Revision 1.10  2008/03/27 17:30:56  lmericle
 * updates to accomodate change in controls.js, where the onKeyPress event handler is now called for keydown events instead of keypress events.
 *
 * Revision 1.9  2008/02/28 14:57:30  lmericle
 * changes to move from first field of last blank line in a horizontal table to next accessible field outside the table
 *
 * Revision 1.8  2008/02/08 22:26:27  lmericle
 * changes for column display of strength and form data
 *
 * Revision 1.7  2008/01/23 19:27:42  plynch
 * initial changes to add "rules".
 *
 * Revision 1.6  2008/01/23 14:25:42  lmericle
 * updated incomplete documentation for the selectText function
 *
 * Revision 1.5  2007/12/10 16:32:08  wangye
 * Make a field's content automatically selected when it gets focus through key navigation
 *
 * Revision 1.4  2007/11/29 14:26:02  lmericle
 * navigation updates
 *
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Basically,
 * you can use the code as long as you give NLM credit.
 */

Def.Navigation = {

 /**
  * Hash used to determine order in page for each element, using
  * a field's ID as the key
  */
  navSeqsHash_: {} ,

 /**
  * ID of the field that currently has focus
  */
  focusedField_: null,

 /**
  * Wrapper used to assign the setFocusedField function to a focus
  * event for each field where appropriate.  see SetUpFieldListeners.
  * Initialized (once) in setUpNavKeys.  (Can't initialize it until
  * this class is finished defining itself).
  */
  setFocusedFieldWrapper_: null ,

 /**
  * Wrapper used to assign the handleNavKey function to a keydown
  * event for each field where appropriate.  see SetUpFieldListeners.
  * Initialized (once) in setUpNavKeys.  (Can't initialize it until
  * this class is finished defining itself).
  */
  handleNavKeyWrapper_: null ,

 /**
  * Wrapper used to assign the moveIfHidden function to a click
  * event for each field where appropriate.  see SetUpFieldListeners.
  * Initialized (once) in setUpNavKeys.  (Can't initialize it until
  * this class is finished defining itself).
  */
  moveIfHiddenWrapper_: null ,

 /**
  *  True if doNavKeys has run for the whole form.
  */
 formNavInitialized_: false,


 /**
  *  Returns the character code associated with the given key event.
  * @param e the key event whose code is requested
  * @return the code for the key event passed in
  */
  getKeyCode: function(e) {
    // Copied from http://www.quirksmode.org/js/events_properties.html#key
    var code;
    if (!e) e = window.event;
    if (e.keyCode) code = e.keyCode;
    else if (e.which) code = e.which;
    return code;
  } , // getKeyCode


 /**
  *  This function initalizes the event function wrappers if they are null.
  */
  initWrappers: function() {
    Def.Logger.logMessage(['called initWrappers']);
    this.setFocusedFieldWrapper_ = this.setFocusedField.bind(this) ;
    this.handleNavKeyWrapper_ = this.handleNavKey.bind(this) ;
    this.moveIfHiddenWrapper_ = this.moveIfHidden.bind(this) ;

  } , // initWrappers


 /**
  *  This function controls the processing of the elements for
  *  each form on the page.  This should be called on page load.
  */
  setUpNavKeys: function() {
    for (var f=0, fl = document.forms.length; f < fl; ++f) {
      this.doNavKeys(f) ;
    }
  } , // setUpNavKeys


 /**
  *  This function processes each element for the form indicated
  *  by the index passed in.  Two values for each element are written
  *  to the navSeqsHash_:
  *   1) the index to the form on which it appears; and
  *   2) the index to its position the elements array for the form.
  *  It is then passed to the setUpListenersField function if
  *  appropriate.
  *
  *  This method is called on page load.  It is also called to
  *  update the navSeqsHash_ elements when lines are added to or
  *  removed the form - which automatically shifts the element
  *  indexes in the document's form.elements array.
  *
  * @param f the index in the document.forms array for the
  *          form whose elements are to be processed.
  * @param e the number of the element at which to start the
  *          renumbering process.  Use this when possible to
  *          cut down on the number of elements being renumbered,
  *          i.e., when you're adding elements to the page.
  *          optional, default is 0.
  * @param initNewOnly if this is true, a check will be made to see
  *  whether fields have been processed before, and if so, the set up
  *  of field listeners will be skipped.  The default is false.  However,
  *  except for the time when the form is first loaded, this should be set
  *  to true.
  * @param adding optional boolean that indicates whether or
  *          not you're adding elements to the page.  Default is false.
  * @param checkAllElements optional boolean that indicates whether or
  *          not all elements after 'e' are checked to set up event listeners.
  *          Default is false.
  */
  doNavKeys: function(f, e, initNewOnly, adding, checkAllElements) {
    // The following check used to be in setUpNavKeys, and had to be moved
    // here because during autosave recovery this gets called before
    // setUpNavKeys
    if (this.setFocusedFieldWrapper_ == null) {
      this.initWrappers() ;
    }

    // set defaults
    if (typeof adding == "undefined") {
      adding = false;
      if (typeof initNewOnly == "undefined") {
        initNewOnly = false;
        if (typeof e == "undefined")
          e = 0 ;
      }
    }
    if (typeof checkAllElements == "undefined") {
      checkAllElements = false;
    }

    var wholeForm = e==0 && !initNewOnly;

    var curForm = document.forms[f];
    var elemArray = curForm.elements;
    var el = elemArray.length ;
    var doFieldSetup = !initNewOnly || adding;

    for (; e < el; ++e) {

      var nextElem = elemArray[e];
      if (nextElem && nextElem.id && nextElem.id != '' &&
        !["EMBED","OBJECT"].include(nextElem.nodeName)) {
        // check for the end of a new set of elements added
        // to a page - if we're adding here.
        if (initNewOnly && (doFieldSetup || checkAllElements))
          doFieldSetup = this.navSeqsHash_[nextElem.id] == null ;

        // Update the navSeqsHash_ for the next element, whether
        // or not it's a new one.  Since we've inserted elements,
        // all the ones after the new ones have number element indices.
        this.navSeqsHash_[nextElem.id] = [f,e] ;

        // If we're not at an element flagged 'noNav', and the
        // element has an id  - and we're not at the end of
        // the new elements, where applicable - call
        // setUpFieldListeners to set up all event listeners
        // needed for the field.
        if (doFieldSetup) {
            //&& !checkClassName(nextElem, ['noNav','hidden_field'])) {
            //!nextElem.hasClassName('noNav')) {
          this.setUpFieldListeners($(nextElem));
        }
      }
    }

    if (wholeForm)
      this.formNavInitialized_ = true;

  }, // doNavKeys


 /**
  *  This function updates element numbers in the navSeqsHash_ for
  *  a group of fields, presumably fields in a table that has
  *  been resorted.
  *
  *  The fields must all be existing fields that already have
  *  values in the navSeqsHash_.
  *
  * @param first the field that was first in the group BEFORE it
  *  was resorted.
  * @param last the field that was last in the group BEFORE it
  *  was resorted.
  */
  resortNavKeys: function(first, last) {

    var formNum = this.navSeqsHash_[first.id][0] ;
    var startNum = this.navSeqsHash_[first.id][1] ;
    var endNum = this.navSeqsHash_[last.id][1] ;
    var curForm = document.forms[formNum];

    for (var e = startNum; e <= endNum; ++e) {
      var nextElem = $(curForm.elements[e]);
      if (nextElem) {
        this.navSeqsHash_[nextElem.id][1] = e ;
      }
      else
        Def.Logger.logMessage(['resortNavKeys did not find nextElem']);
    }
  }, // resortNavKeys


 /**
  *  Sets up the observers need for field elements on a page, based
  *  on various criteria.
  *
  * @param theField the input element to (possibly) receive the event observers
  * @param theObservers hash containing the observers to be processed.  This
  *  will usually be null, causing the observer to be drawn from the
  *  Def.fieldObservers_ hash.  But in some cases (e.g. combo fields) a
  *  separate hash will be supplied, which should be used in place of the
  *  Def.fieldObservers_ hash.
  */
  setUpFieldListeners: function(theField, theObservers) {

    if (theObservers === undefined) {
      theObservers = Def.fieldObservers_ ;
    }
    // All fields get the onfocus listener that calls setFocusedField.
    Event.observe(theField, 'focus', this.setFocusedFieldWrapper_) ;

    // Only set up the handleNavKey handler for forms that use the
    // PHR-specific navigation code. - NO - this didn't work.
    // Fields with an "eventsHandled" class get separate handlers
    // that are set up within the autocomplete code.
    // Fields with a "noNav" class are excluded from keyboard navigation.
    //if (Def.use_navigation_ && <-- No - this didn't work.
    if (!checkClassName(theField, ['eventsHandled', 'noNav'])) {
      Event.observe(theField, 'keydown', this.handleNavKeyWrapper_);
    }

    // Process any functions indicated for the field in the fieldObservers_
    // hash
    var fieldParts = Def.IDCache.splitFullFieldID(theField.id) ;
    var changeEventsHandled = theField.hasClassName('eventsHandled');
    if (theObservers[fieldParts[1]] != null) {
      var eventToObservers = theObservers[fieldParts[1]] ;
      for (var theEvent in eventToObservers) {
        var observers = eventToObservers[theEvent];
        var iLen = observers.length ;
        for (var i = 0; i < iLen; i++) {
          var theFunction = observers[i];
          if (theEvent == 'load')
            theFunction(theField) ;
          else {
            if (theEvent != 'change' || !changeEventsHandled)
              Event.observe(theField, theEvent, theFunction);
          }
        }
      }
    } // end if the field has observers

    // THIS IS HERE BECAUSE LEE WANTS TO GO FISHING.  DON'T TOUCH IT.
    // Also, it needs to be after the other initializers.
    // because otherwise they don't work right. also some functions
    // change the status of a field from hidden to not.
    // Input fields and buttons get checked to see if they are hidden
    // when they get moved into.  This can happen when they get hidden
    // by another field as they are being moved into.
    //if (theField.tagName == 'INPUT' || theField.tagName == 'BUTTON') {
    if (theField.tagName == 'INPUT' ||
        (theField.tagName == 'BUTTON' &&
         theField.hasClassName('hidden_field'))) {
      Event.observe(theField, 'click', this.moveIfHiddenWrapper_) ;
    }
  } , // end setUpFieldListeners


  /**
   *  Clears cached navigation data about the given fields, which the caller
   *  should remove from the DOM.
   * @param fields the fields whose navigation information should be cleared.
   */
  clearNavData: function(fields) {
    for (var i=0, max=fields.length; i<max; ++i)
      delete this.navSeqsHash_[fields[i].id];
  },


 /**
  * Handles key events on the document - e.g., key events when the user
  * is not in a field.  If no field yet has focus, this allows
  * a TAB or RETURN to move the user to the first input field on the form
  * that is visible, editable and is not a button or an image.  If none are
  * found a visible button gets the focus.  If no button is available, an
  * input-capable image is tried.  If none of those are found, this gives
  * up.
  *
  * This also prevents backspace keys from making the browser go to the
  * previous page.
  *
  * This was initially based on code from
  * http://mspeight.blogspot.com/2007/05/how-to-disable-backspace-in-ie-and.html
  *
  * @param ev the key event.  Not used for IE.  Used for other browsers.
  */
  handleDocumentKeyEvent: function(ev) {

    // if we're using IE, get the event directly.
    if (typeof window.event != 'undefined') {
      ev = event ;
      var targetType = ev.srcElement.type ;
    }
    else {
      targetType = ev.target.type ;
    }
    var keyCode = ev.keyCode ;

    if ((keyCode == 9 || keyCode == 13) &&
      !Def.Navigation.focusedField_) {
      var firstField = Def.Navigation.findFirstField() ;
      if (firstField != null) {
        firstField.focus() ;
        var stopKey = true ;
      }
    }
    else {
      // Stop a backspace character from returning to the previous page
      stopKey = (!((keyCode != 8) || (targetType == 'text') ||
                 (targetType == 'textarea') || (targetType == 'password')));
          }
    if (stopKey == true) {
      Event.stop(ev) ;
    }
  } , //end handleDocumentKeyEventListener


  /**
   * This looks for the first editable/input capable field on a form.  It is
   * used to position the form's focus at that first field when the form is
   * displayed
   *
  * @param includeButtons boolean to indicate whether or not buttons should
  *  be considered in the search.  Default is false.  If no other field is
  *  found on the form, this function is rerun with this parameter set to true.
  *
  * @return - the first editable/input capable form element
   */
  findFirstField: function(includeButtons) {
    if (includeButtons == 'undefined')
      includeButtons = false ;
    var theFirst = null ;
    for (var f = 0, fl = document.forms.length;
         f < fl && theFirst == null; ++f) {
      for (var e = 0, el = document.forms[f].length;
           e < el && theFirst == null; ++e) {
        theFirst = document.forms[f].elements[e] ;
        if (isHiddenOrDisabled(theFirst) ||
            ((theFirst.type != 'text' && theFirst.type != 'password' &&
              theFirst.type != 'textarea' && theFirst.type != 'checkbox') &&
              (!includeButtons ||
               (includeButtons && theFirst.type != 'button' &&
                theFirst.type != 'commit'))))
           theFirst = null ;
      } // end do for each element until we find the field
    } // end do for each form until we find the field
    if (theFirst == null)
      theFirst = Def.Navigation.findFirstField(true) ;
    return theFirst ;
  } ,


  /**
  *  This function sets the value of focusedField_ to the id
  *  of the field that called it, which presumably will be the
  *  field that just received focus.  If this is called by an
  *  object that has no id, focusedField_ will not be changed.
  *
  *  This is set up as an event observer for all fields that
  *  participate in the navigation processing.  See
  *  setUpFieldListeners.
  *
  * @param event the focus event, which will have a reference to the
  *  field on which the event occurred.
  */
  setFocusedField: function(event) {
    var eventElement = Event.element(event);
    if (eventElement.id) {
      this.focusedField_ = eventElement.id ;
    }
  } , // setFocusedField


 /**
  *  This handles the actual movement of focus in relation to a navigation
  *  key event.  It is called by handleNavKey after certain validations
  *  are performed (valid event, determining whether or not a pause is
  *  needed).  It may be called after a timeout has finished.
  *
  *  "Movement" means the movement of keyboard focus from one form
  *  input element to another.  Key events are handled as follows:
  *
  *  <TAB>
  *   without <SHIFT> - move to the next available input field
  *   with <SHIFT> - move to the previous available input field
  *
  *  <RETURN>
  *   without <SHIFT>
  *     if pressed when focus is on a button, NOT processed as a
  *     navigation request (assume user wants to invoke button's
  *     function).
  *
  *     if pressed when focus is NOT on a button, move to the
  *     next available input field
  *
  *   with <SHIFT> - move to the previous available input field
  *
  *  <LEFT arrow> WITH <CTRL> key - move to the previous available
  *                                 input field
  *
  *  <RIGHT arrow> WITH <CTRL> key - move to the next available
  *                                  input field
  *
  *  <UP arrow> WITH <CTRL> key
  *     if pressed from within a table - move to the corresponding
  *     field in the previous row - or to the first available input
  *     field preceding the table if no available rows above the
  *     one in which the keypress originated
  *
  *     if not pressed within a table - move to the previous
  *     available input field
  *
  *  <DOWN arrow> WITH <CTRL> key
  *     if pressed from within a table - move to the corresponding
  *     field in the next row - or to the first available input
  *     field following the table if no available rows below the
  *     one in which the keypress originated
  *
  *     if not pressed within a table - move to the next available
  *     input field
  *
  *  See the isHiddenOrDisabled function for a definition of
  *  "available input field".
  *
  * @param event the key event that caused this to be invoked.
  */
  handleNavKey: function(event) {
    // See if the event is stopped (e.g. by the autocompleter) before proceeding.
    // Handle both prototypejs and jQuery events in case we switch to jQuery
    // events.
    if (!event.stopped && (!event.isImmediatePropagationStopped ||
        !event.isImmediatePropagationStopped())) {
      var eventElement = Event.element(event);
      if (this.isNavKey(event, eventElement)) {
        // Process a request to move to the next element in the form
        if (event.keyCode == Event.KEY_RIGHT ||
            (!event.shiftKey &&
             (event.keyCode == Event.KEY_RETURN ||
              event.keyCode == Event.KEY_TAB))) {
          if (!Def.FieldsTable.skipBlankLine(eventElement))
            this.moveToNextFormElem(eventElement) ;
        }
        // Process a request to move to the previous element in the form
        else if (event.keyCode == Event.KEY_LEFT ||
                 (event.shiftKey &&
                  (event.keyCode == Event.KEY_RETURN ||
                   event.keyCode == Event.KEY_TAB))) {
          this.moveToPrevFormElem(eventElement) ;
        }
        // Handle the up and down arrows
        else if (event.keyCode == Event.KEY_DOWN) {
          if (this.inTable(eventElement)) {
            this.downInTable(eventElement) ;
          }
          else {
            this.moveToNextFormElem(eventElement) ;
          }
        }
        else { // KEY_UP
          if (this.inTable(eventElement)) {
            this.upInTable(eventElement) ;
          }
          else {
            this.moveToPrevFormElem(eventElement) ;
          }
        }
        // Stop the event -- we've handled it here.
        Event.stop(event);

      } // end if this is a navigation key
    }
  } , // handleNavKey


 /**
  *  Determines whether or not the given key event was instigated from
  *  a navigation key.  Note that the shift key is required for arrows,
  *  to avoid clashes with list controls.
  *
  * @param event the key event that caused this to be invoked
  * @param eventElement the element from which the key was pressed
  * @return true if the key is a valid navigation key
  *         false if the key is not a valid navigation key
  */
  isNavKey: function(event, eventElement) {

    // Valid navigation keys are the arrows - if used with the control key,
    // the tab key, and the return key - WITH conditions.  If the user has
    // pressed RETURN for a submit button, or other type of button, don't
    // process this as a navigation request.  The user is requesting the
    // action associated with the button, not to move focus.
    return (event.keyCode == Event.KEY_TAB || event.ctrlKey &&
            (event.keyCode == Event.KEY_LEFT ||
             event.keyCode == Event.KEY_UP ||
             event.keyCode == Event.KEY_RIGHT ||
             event.keyCode == Event.KEY_DOWN) ||
             (event.shiftKey && event.keyCode == Event.KEY_RETURN) ||
              (event.keyCode == Event.KEY_RETURN &&
               (((eventElement.nodeName == 'INPUT') ||
               (eventElement.type != 'submit' &&
                eventElement.type != 'button'&&
                !(eventElement.type == 'textarea' &&
                  eventElement.hasClassName('allow_newline')))))));
  } , // isNavKey


 /**
  * Check if the containing row (tr) is a new row at the end of the table,
  * which is under the control of the controlled edit table code
  * Note: Lee might have a better idea to make this part of the
  * isHiddenOrDisabled function.
  *
  * @param cellElement the element to be checked
  * @return true if the element's content element is not editable
  *         false if the element's content element is not editable
  */

 inNewRow: function(cellElement) {
   var ret = false;
   if (cellElement && cellElement.hasClassName('rowEditText')) {
     var rowElement = cellElement.parentNode;
     var inputElement = cellElement.firstElementChild;
     if (rowElement.nodeName == 'TR' &&
         rowElement.hasClassName('repeatingLine') &&
         (inputElement.nodeName == 'INPUT' ||
         inputElement.nodeName == 'TEXTAREA' ||
         (inputElement.nodeName == 'TABLE' &&
         inputElement.hasClassName('dateField'))) &&
         inputElement.style.visibility != 'hidden') {
       ret = true;
     }
   }
   return ret;
 },


 /**
  *  Determines whether or not the given element is contained within
  *  an HTML table.
  *
  * @param element the element to be checked
  * @return true if the element is within an HTML table
  *         false if the element is not within an HTML table
  */
 // performance is not good.
 // for a input field with a date field, X1000
 // 332ms while the intable_old only needs 5ms
 // for a regular input field , X1000
 // 189ms while the intable_old only needs 44ms
 // *** rewrite it in the intable_old style
  inTable: function(element) {
    var ret = false;

    var tableElement = $(element).up('table');

    // search again if it is a date field
    if (tableElement && tableElement.hasClassName('dateField')) {
      tableElement = tableElement.up('table');
    }

    if (tableElement) {
      ret = true;
    }
    return ret;

  } , // inTable
//  inTable_old: function(element) {
//    var tmpField = element ;
//    var tmpTagName = tmpField.tagName;
//
//
//    while (tmpTagName == 'INPUT' ||
//           (tmpTagName != 'TD' &&
//            !(tmpTagName == 'DIV' &&
//              $(tmpField).hasClassName('field')) &&
//            tmpTagName != 'TR' &&
//            tmpTagName != 'TBODY' &&
//            tmpTagName != 'TABLE' &&
//            !$(tmpField).hasClassName('fieldGroup') &&
//            tmpTagName != 'HTML')) {
//      tmpField = tmpField.parentNode;
//      tmpTagName = tmpField.tagName;
//    }
//    return (tmpTagName == 'TD' ||
//            tmpTagName == 'TR' ||
//            tmpTagName == 'TABLE') ;
//
//  } , // inTable


/**
  * Determine whether or not the given element is contained whtin an HTML table
  * of a calendar field
  *
  * @param element the element to be checked
  * @return true if the element is within an HTML table of a calendar field
  *         false if the element is not within an HTML table of a calendar field
  */
  inDateTable: function(element) {
    var ret = false;
    var tableElement = $(element).up('table');

    if (tableElement && tableElement.hasClassName('dateField')) {
      ret = true;
    }
    return ret;
  } , // inDateTable


 /**
  *  This function causes focus to move to the previous available input
  *  element.  If no previous input element is available, focus is not
  *  moved.
  *
  * @param elem the element from which to move
  */
  moveToPrevFormElem: function(elem) {

    // First remove focus from the current element.  This forces the
    // running of any rules which might affect which element is "previous".
    elem.blur();

    var prev = this.getPrevFormElem(elem);
    if (prev != null) {
      prev.focus();
    }
  } , // moveToPrevFormElem


 /**
  *  Returns the previous available form input element.  If we are at
  *  the first available input element on the current form, the "previous"
  *  element returned is either:
  *  1) the last available input element of the form that precedes the
  *     current form; or, if no form precedes the current one,
  *  2) the last available input element of the last form of the document,
  *     which may or may not be the current form.
  *
  * @param elem the element from which to start the search for
  *             the "previous available" element.
  * @return the closest "previous" element that is available for input
  *         or null if we don't find one.
  */
  getPrevFormElem: function(elem) {

    var seqInfo = this.navSeqsHash_[elem.id] ;
    var prevElem = null ;
    if (seqInfo) { // might be undefined if the element was removed
      var f = seqInfo[0] ;
      var prevSeq = seqInfo[1] - 1;
      var thisPrev = null ;

      // Get the previous element on the form - if there is one
      if (prevSeq >= 0)
        thisPrev = $(document.forms[f].elements[prevSeq]) ;
      if (thisPrev != null)
        prevElem = thisPrev ;

      // If we got an element, make sure it's not hidden or disabled.
      // If it is, keep moving back until we find one that's not - or
      // hit the beginning of the form.
      while ((thisPrev) && ((isHiddenOrDisabled(thisPrev)) ||
        Def.Navigation.navSeqsHash_[prevElem.id] == undefined)) {
        prevSeq-- ;
        if (prevSeq >= 0) {
          thisPrev = $(document.forms[f].elements[prevSeq]);
          prevElem = thisPrev ;
        }
        else
          thisPrev = null ;
      }
      // If we've run out of elements on this form, we need to go to the last
      // accessible element on the previous form - if there is a previous
      // form.  Otherwise we need to go to the last element on this form.
      if (thisPrev == null) {
        if (f == 0) {
          var totForms = document.forms.length ;
          if (totForms > 1)
            f = totForms - 1 ;
        }
        else {
          f-- ;
        }
        // Start with the last element on whatever form formNum points to.
        // If it's hidden or disabled, call this function on that element
        // do work backwards on the form.
        var last = document.forms[f].elements.length - 1;
        thisPrev = document.forms[f].elements[last] ;
        for (var p = last - 1; thisPrev.hasClassName('noNav'); p--)
          thisPrev = document.forms[f].elements[p] ;
        // NEED CODE TO HANDLE FORM WITH NO NAVIGABLE ELEMENTS
        if (isHiddenOrDisabled(thisPrev))
          prevElem = this.getPrevFormElem(thisPrev) ;
        else
          prevElem = thisPrev ;
      } // end if we didn't find a previous element on the original form
    } // end if we have navigation information for the current element
    // Return whatever we found.
    return prevElem;

  } , // end getPrevFormElem


 /**
  *  This function causes focus to move to the next available input
  *  element.  If no next input element is available, focus is not
  *  moved.
  *
  * @param elem the element from which to move
  */
  moveToNextFormElem: function(elem) {
    // Call "blur" first, and set a timeout to do the focus, so that
    // rules can run in between (in case those hide or show fields).
    // Set the timeout now, before calling blur, so that it will run
    // before any other timeouts set by event listeners.  The autocompleter,
    // for instance,  will set a timeout to refocus the field if there is a
    // problem with the user's input.
    setTimeout(function () {
      var nextElem = Def.Navigation.getNextFormElem(elem) ;
      if (nextElem != null) {
        nextElem.focus();
      }
    }, 1);

    // First remove focus from the current element.  This forces the
    // running of any rules which might affect which element is "next".
    elem.blur();
 }, // moveToNextFormElem


 /**
  *  Returns the next available form input element.  If we are at the
  *  last available input element on the current form, the "next" element
  *  returned is either:
  *  1) the first available input element of the form that follows the
  *     current form; or, if no form follows the current one,
  *  2) the first available input element of the first form of the
  *     document, which may or may not be the current form.
  *
  * @param elem the element from which to start the search for the
  *             "next available" element.
  * @return the closest "next" element that is available for input
  *         or null if we don't find one.
  */
  getNextFormElem: function(elem) {
    var seqInfo = this.navSeqsHash_[elem.id] ;
    var nextElem = null ;
    if (seqInfo) { // might be undefined if the element was removed
      var f = seqInfo[0] ;
      var nextSeq = seqInfo[1] + 1;
      var thisNext = null ;

      // Get the next element on the form - if there is one
      if (nextSeq < document.forms[f].elements.length)
        thisNext = $(document.forms[f].elements[nextSeq]) ;
      if (thisNext != null)
        nextElem = thisNext ;

      // If we got an element, make sure it's not hidden or disabled.
      // If it is, keep moving forward until we find one that's not -
      // or hit the end of the form.
      while ((thisNext) && ((isHiddenOrDisabled(thisNext)) ||
        Def.Navigation.navSeqsHash_[nextElem.id] == undefined)) {
        nextSeq++ ;
        if (nextSeq < document.forms[f].elements.length) {
          thisNext = $(document.forms[f].elements[nextSeq]) ;
          nextElem = thisNext ;
        }
        else
          thisNext = null ;
      }
      // if we've run out of elements on this form, we need to go to the
      // first accessible element on the next form - if there is a next
      // form.  Otherwise we need to go to the first element on this form.
      if (thisNext == null) {
        f++ ;
        if (f == document.forms.length) {
          f = 0 ;
        }
        // Start with the first element on whatever form formNum points to.
        // If it's hidden or disabled, call this function on that element
        // do work forwards on the form. Make sure element has id, else skip
        // to next element. ID is required for element to be in sequence Hash
        thisNext = document.forms[f].elements[0] ;

        for (var n = 1; thisNext.hasClassName('noNav') || thisNext.id == "" ; n++)
          thisNext = document.forms[f].elements[n] ;
        // NEED CODE TO HANDLE CASE OF FORM WITH NO NAVIGABLE OBJECTS ON IT
        if (isHiddenOrDisabled(thisNext))
          nextElem = this.getNextFormElem(thisNext) ;
        else
          nextElem = thisNext ;
      } // end if we didn't find a next element on the original form
    } // end if we have navigation information for the current element
    return nextElem ;

  } , // getNextFormElem


 /**
  *  This function causes focus to move "up" in a horizontal table
  *  of input elements.  Usually this moves to the input element in
  *  the table cell immediately above the current cell.  If that is
  *  not possible, this moves up the rows in the table, in the same
  *  column, until it finds an available input element - or runs out
  *  of rows in the table.  In that case it moves to the first available
  *  input cell that precedes the table.
  *
  * @param element the element from which to start the movement
  */
  upInTable: function(element) {

    var eCell = element.parentNode ;
    while (eCell.tagName != 'TD') {
      eCell = eCell.parentNode ;
    }
    var eRow = eCell.parentNode ;
    while (eRow.tagName != 'TR') {
      eRow = eRow.parentNode ;
    }
    var eTable = eRow.parentNode ;
    while (eTable.tagName != 'TABLE') {
      eTable = eTable.parentNode ;
    }
    // Date fields have input elements inside a table. So, skip the first
    // cell/row/table which is for calendar field and go up to the next
    // containing cell/row to find the repeating Line
    while (eTable.hasClassName('dateField')) {
      eCell = eTable.parentNode ;
      while (eCell.tagName != 'TD') {
        eCell = eCell.parentNode ;
      }
      eRow = eCell.parentNode ;
      while (eRow.tagName != 'TR') {
        eRow = eRow.parentNode ;
      }
      eTable = eRow.parentNode ;
      while (eTable.tagName != 'TABLE') {
        eTable = eTable.parentNode ;
      }
    }
    // Set the index to the previous row.  Then, if it's hidden
    // or disabled (including model rows, which are always hidden)
    // or the corresponding cell in the row is hidden or disabled,
    // move back until we find an accessible row & cell - or hit the
    // beginning of the table
    var ri = eRow.rowIndex - 1 ;
    var ci = eCell.cellIndex ;
    var upEle = null ;
    // avoid checking the header and model rows (0 & 1)
    if (ri >= 1) {
      while ((upEle == null) && (ri > 1)) {
        if (eTable.rows[ri].hasClassName('repeatingLine')) {
          if (!isHiddenOrDisabled(eTable.rows[ri].cells[ci]) ||
              this.inNewRow(eTable.rows[ri].cells[ci]))
            upEle = eTable.rows[ri].cells[ci] ;
        }
        else if (eTable.rows[ri].hasClassName('embeddedRow')) {
          var embInputs = eTable.rows[ri].select('input', 'textarea', 'a') ;
          for (var e = embInputs.length - 1; upEle == null && e > 0; e--) {
            if (!isHiddenOrDisabled(embInputs[e]) ||
                this.inNewRow(embInputs[e]) ) {
              upEle = embInputs[e] ;
            }
          }
        }
        if (upEle == null)
          ri = ri - 1 ;
      } // end looking for the row
    }
    // if we've hit the top of the table and haven't found an
    // accessible "up" cell, move to the previous element on the
    // form before the table that contains the one that started all
    // this.
    if (upEle == null) {
      var tabInps = eTable.select('input', 'textarea', 'button') ;
      upEle = this.getPrevFormElem(tabInps[0]) ;
    }
    // If we got a cell from a repeating line, get its input element
    if (upEle.tagName.toLowerCase() == 'td')
      upEle = Def.FieldsTable.inputElement(upEle) ;

    if (upEle != null) {
      upEle.focus() ;
    }
  } , // upInTable


 /**
  *  This function causes focus to move "down" in a horizontal table
  *  of input elements.  Usually this moves to the input element in
  *  the table cell immediately below the current cell.  If that is
  *  not possible, this moves down the rows in the table, in the same
  *  column, until it finds an available input element - or runs out
  *  of rows in the table.  In that case it moves to the first available
  *  input cell that follows the table.
  *
  * @param element the element from which to start the movement
  */
  downInTable: function(element) {

    var eCell = element.parentNode ;
    while (eCell.tagName != 'TD') {
      eCell = eCell.parentNode ;
    }
    var eRow = eCell.parentNode ;
    while (eRow.tagName != 'TR') {
      eRow = eRow.parentNode ;
    }
    var eTable = eRow.parentNode ;
    while (eTable.tagName != 'TABLE') {
      eTable = eTable.parentNode ;
    }
    // Date fields have input elements inside a table. So, skip the first
    // cell/row/table which is for calendar field and go down to the next
    // containing cell/row to fing the repeating line
    while (eTable.hasClassName('dateField')) {
      eCell = eTable.parentNode ;
      while (eCell.tagName != 'TD') {
        eCell = eCell.parentNode ;
      }
      eRow = eCell.parentNode ;
      while (eRow.tagName != 'TR') {
        eRow = eRow.parentNode ;
      }
      eTable = eRow.parentNode ;
      while (eTable.tagName != 'TABLE') {
        eTable = eTable.parentNode ;
      }
    }
    // Set the index to the next row.  Then, if it's hidden or
    // disabled,or the corresponding cell in the row is hidden or
    // disabled, move down until we find an accessible row & cell
    // - or hit the end of the table
    var ri = eRow.rowIndex + 1 ;
    var ci = eCell.cellIndex ;
    var totRows = eTable.rows.length ;
    var downEle = null ;

    if (ri < totRows) {
      while ((downEle == null) && (ri < totRows)) {
        if (eTable.rows[ri].hasClassName('repeatingLine')) {
          if (!isHiddenOrDisabled(eTable.rows[ri].cells[ci]) ||
              this.inNewRow(eTable.rows[ri].cells[ci]))
            downEle = eTable.rows[ri].cells[ci] ;
        }
        else if (eTable.rows[ri].hasClassName('embeddedRow')) {
          var embInputs = eTable.rows[ri].select('input', 'textarea', 'a') ;
          var embInLen = embInputs.length ;
          for (var e = 0; downEle == null && e < embInLen; e++) {
            if (!isHiddenOrDisabled(embInputs[e]) ||
                this.inNewRow(embInputs[e])) {
              downEle = embInputs[e] ;
            }
          }
        }
        if (downEle == null)
          ri = ri + 1 ;
      } // end looking for the row
    } // end if we're not at the last row

    // If we haven't found an accessible "down" cell move to the
    // next element on the form after the one that started all this.
    // That should be the next element after the table.  (down and out!)
    if (downEle == null) {
      var tabInps = eTable.select('input', 'textarea', 'button') ;
      downEle = this.getNextFormElem(tabInps[tabInps.length - 1]) ;
    }

    // If we got a cell from a repeating line, get its input element
    if (downEle.tagName.toLowerCase() == 'td')
      downEle = Def.FieldsTable.inputElement(downEle) ;

    if (downEle != null) {
      downEle.focus() ;
    }
  } , // downInTable


 /**
  * This function makes the text selected is cleared if the element
  * passed in is a text input element.  This only works
  * for input text elements
  *
  * Removed !isHiddenOrDisabled qualifier 3/19/09.  Why do we care?
  *
  * @param elem the element to be cleared
  */
  clearText: function(elem) {

    if (elem.tagName == 'INPUT' && elem.type == 'text')
      elem.clear();

  } , // clearText


 /**
  *  On a click event, checks to see if the element is hidden
  *  when it gets the focus (as it might be if a rule on the last
  *  field caused it to be hidden).  If so, the focus is shifted
  *  to the next element.
  *
  * @param elem the element to which the handler is added
  */
  moveIfHidden: function(event) {
    if (isHiddenOrDisabled(Event.element(event)))
      this.moveToNextFormElem(Event.element(event));
  } , // moveIfHidden



  /**
  *  This function will move the focus to the first accessible element
  *  beyond the current table.  If there are no more accessible elements
  *  on the form, this will move to the next form OR back to the beginning
  *  of the page.
  *
  * @param row a row in the table to move beyond
  */
  moveBeyondTable: function(row) {

    // Get the table that contains the row
    while (row.parentNode != null && row.parentNode.tagName != 'TABLE')
      row = row.parentNode ;

    // Get all the input elements in the table and get the last navigable
    // one (whether or not it's currently accessible).
    var inputs = row.select('input', 'textarea') ;
    var i = inputs.length - 1 ;
    for (; i > -1 && this.navSeqsHash_[inputs[i].id] == null; --i) ;

    // Move to the next element in the form after the current table
    // elements.
    if (i > -1)
      this.moveToNextFormElem(inputs[i]) ;

    // Log an error if we didn't find one.  Something's not right.
    else
      Def.Logger.logMessage(["Tried to move beyond table contents, " +
                             "couldn't find.  Issued from moveBeyondTable " +
                             "function in navigation.js"]) ;
  } // end moveBeyondTable



}; // Def.Navigation

