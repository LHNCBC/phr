// License:  This file should be considered to be under the terms of some
// "non-viral" open source license, which we will specify soon.  Bascially,
// you can use the code as long as you give NLM credit.

// This file contains event handlers needed for allowing a click on a text
// field to select the text in the field.  Normally, even if you select the
// text on focus events, a click event will deselect it and set the insertion
// point.  So, we define here click event handler that reselects the text.
// There are a couple of tricky parts.  First, on the second click
// in the text field, we do not want select the text, so that the user can
// insert new text at the point they clicked.  Second, if the user has
// tabbed into the field (in which case we select the text) we want a subsequent
// click event to deselect the text and set the insertion point.

// A field that uses this should have all of the event handlers here
// registered for the corresponding events, e.g. "onclick" for a click
// event, etc.

// Some field controls (e.g. the MultiFieldBox have cases where the
// text should not be selected or it causes problems.  In such cases,
// the code for those controls can see the flag "doNotSelect" to true
// (on the text element).

Def.ClickedTextSelector = {
  /**
   *  An event handler to be used for click events.  It assumes "this"
   *  points to the field getting the event.
   */
  onclick: function(event) {
    if (this.clickShouldSelect && !this.doNotSelect) {
      this.select();
      this.clickShouldSelect = false;
    }
  },


  /**
   *  An event handler to be used for focus events.  It assumes "this"
   *  points to the field getting the event.
   */
  onfocus: function(event) {
    if (!this.doNotSelect)
      this.select();
    this.focused = true;
  },


  /**
   *  An event handler to be used for focus events.  It assumes "this"
   *  points to the field getting the event.
   */
  onmousedown: function(event) {
    if (!this.focused)
      this.clickShouldSelect = true;
  },


  /**
   *  An event handler to be used for blur events on the field.  It assumes
   *  "this" points to the field getting the event.
   */
  onblur: function(event) {
    this.focused = false;
    this.clickShouldSelect = false;
  },


  /**
   *  Sets up the needed observers for the given element.
   * @param elem the element for which it is desired to have the text selected
   *  when clicked.
   */
  setUpObservers: function(elem) {
    Event.observe(elem, 'click', this.onclick);
    Event.observe(elem, 'focus', this.onfocus);
    Event.observe(elem, 'mousedown', this.onmousedown);
    Event.observe(elem, 'blur', this.onblur);
  },


  /**
   *  Removes the text-selecting observers set up by setUpObservers from
   *  the given element.
   */
  removeObservers: function(elem) {
    Event.stopObserving(elem, 'click', this.onclick);
    Event.stopObserving(elem, 'focus', this.onfocus);
    Event.stopObserving(elem, 'mousedown', this.onmousedown);
    Event.stopObserving(elem, 'blur', this.onblur);
  }
};
