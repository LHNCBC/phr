if (typeof Def === 'undefined')
  Def = {};

/* 
 *  This is a class for managing "combo fields"-- fields that can be one of
 *  a number of different control types, e.g. searchable lists, prefetch lists,
 *  plain text fields, and perhaps one day others.
 */
Def.ComboField = Class.create({
  /**
   *  A reference to the DOM field object.
   */
  field_: null,

  /**
   *  The split version of the field id
   */
  split_field_id_: null ,

  /**
   *  The current type of the field.
   */
  currentFieldType_: null,

  /**
   *  The last originating field for the last list mimicked
   */
  lastOriginatingFieldID_: null,

  /**
   *  The last dbFieldDescID for the last list mimicked
   */
  lastDbFieldDescID_: null ,

  /**
   *  Flag indicating whether or not this combo field is in a horizontal table.
   */
  inTable_: false ,

  /**
   *  For a combo field that is in a horizontal table, this is the DOM node
   *  (the td node) that contains the field node and its associated tooltip
   *  node as well as any other enclosing nodes.  Specifically, date fields
   *  need to be in a table within this td node, so when we switch from text
   *  or list fields to date fields (and back), we need to work from this
   *  parent node
   */
  master_parent_node_: null ,

  /**
   *  For a combo field that is in a horizontal table, this contains the DOM
   *  node ancestors for the field node and its associated tooltip node when
   *  it is to be a text or list field.  This is used to switch back and
   *  forth between date fields and text/list fields.
   */
  text_field_ancestors_: null ,

  /**
   *  For a combo field that is in a horizontal table, this contains the DOM
   *  node ancestors for the field node and its associated tooltip node when
   *  it is to be a date field.  This is used to switch back and forth between
   *  date fields and text/list fields.
   */
  date_field_ancestors_: null ,

  /**
   *  This is the DOM node for the tip field
   */
  tip_field_node_: null ,

  /**
   *  For a combo field that is in a horizontal table, this is the node in
   *  the date field hierarchy to which this field's node and tip_field_node_
   *  should be attached (as children).
   */
  date_field_parent_node_: null ,

  /**
   *  For a combo field that is in a horizontal table, this is the node in
   *  the text field hierarchy to which this field's node and tip_field_node_
   *  should be attached (as children).
   */
  text_field_parent_node_: null ,


  /**
   *  The constructor.
   *
   *  This assumes that the field type defaults to plain text.  If that
   *  assumption changes, assumptions made by the positionDOMElements and
   *  insert functions will need to be modified accordingly.
   *
   * @param ff_id the id of the form field this instance will manage.
   */
  initialize: function(ff_id) {
    this.currentFieldType_ = Def.ComboField.PLAIN_TEXT;
    this.field_ = $(ff_id);
    this.field_.comboField = this;
    this.inTable_ = Def.Navigation.inTable(this.field_) ;
    this.split_field_id_ = Def.IDCache.splitFullFieldID(ff_id) ;
  },


  /**
   *  Changes the combo field so that it mimics the field with the given
   *  field description id.
   * @param dbFieldDescID the ID of the db field description this combo
   *  field should use as the basis of this combo field OR a negative
   *  number used to indicate the field type to be created.
   * @param originatingFieldID the name (ID without prefix or suffix) of the
   *  field that originated the request to set the combo field.
   */
  mimicField: function(dbFieldDescID, originatingFieldID) {
    if (dbFieldDescID >= 0) {
      this.lastOriginatingFieldID_ = originatingFieldID ;
      this.lastDbFieldDescID_ = dbFieldDescID ;
      var newType = 0 ;
    }
    else {
      newType = dbFieldDescID * -1 ;
      if (newType != Def.ComboField.PLAIN_TEXT && this.currentFieldType_) {
        dbFieldDescID = this.lastDbFieldDescID_ ;
        originatingFieldID = this.lastOriginatingFieldID_ ;
      }
    }
    var dataRequestOptions = {};
    dataRequestOptions.onComplete = this.onDataReqComplete.bind(this);
    dataRequestOptions.parameters = {'db_id': dbFieldDescID,
                                     'ff_id': this.field_.id,
                                     'form_name': Def.data_['form_name'] ,
                                     'orig_ff_id': originatingFieldID ,
                                     'in_table' : this.inTable_ ,
                                     'authenticity_token': window._token};
    new Ajax.Request('/form/handle_combo_field_change', dataRequestOptions);
  } , // end mimicField


  /**
   *  This gets called when the AJAX request issued by mimicField comes back.
   */
  onDataReqComplete: function(response) {
    try {
      // The response text should be a JSON object for a data hash map.
      var fieldData = JSON.parse(response.responseText);
      this.removeOldFieldControls();
      this.assignNewFieldControls(fieldData);
    }
    catch (e) {
      Def.reportError(e);
      throw e;
    }
  }, 


  /**
   *  Remove the old field controls (e.g. autocompleters) and clears the field.
   */
  removeOldFieldControls: function() {
    Def.setFieldVal(this.field_, '');
    
    if (this.currentFieldType_ == Def.ComboField.PREFETCHED_LIST ||
        this.currentFieldType_ == Def.ComboField.SEARCH_FIELD) {
      this.field_.autocomp.destroy();
    }
  },


  /**
   * @param fieldData the (evaluated) data returned by the form controller's
   *  handle_combo_field_change method.
   */
  assignNewFieldControls: function(fieldData) {

    // Get the parameters that are passed for all types (if there's anything
    // to pass).
    var newFieldType = fieldData[0];
    var tooltip = fieldData[1] ;
    if (tooltip == null)
      tooltip = "" ;
    var observers = fieldData[2] ;
    var jvscript = fieldData[3] ;

/*  hold on this stuff for now
    // If the field type has changed, see about repositioning/replacing
    // the DOM elements that enclose the field.
    if (this.currentFieldType_ != newFieldType && this.inTable_) {
      if (newFieldType == Def.ComboField.DATE_FIELD)
        this.positionDOMElements(fieldData[4]) ;
      else
        this.positionDOMElements() ;
    }
*/
    // Remove the current field observers.  We're going to reset them based
    // on what the field needs, and we don't want the new ones to bump into
    // the old ones.
    this.field_.stopObserving() ;

    if (newFieldType == Def.ComboField.PREFETCHED_LIST ||
      newFieldType == Def.ComboField.SEARCH_FIELD ) {

      // Create the recordDataRequester if the field is supposed to have one.
      var rdrParams = fieldData[4];
      var rdr = null;
      if (rdrParams) {
        rdr = new Def.RecordDataRequester(this.field_,
                                          rdrParams['dataUrl'],
                                          rdrParams['dataReqInput'],
                                          rdrParams['dataReqOutput'],
                                          rdrParams['outputToSameGroup']);

        if (rdr.outputFieldsHash_ == null)
          rdr.constructOutputFieldsHash();
      }

      // Now create the autocompleter for the field.  Note that we need to
      // pass the add_seqnum parameter as a boolean rather than a string
      // value.  On prefetch autocompleters that are created
      // on page creation, the parameters are sent to a view that does the
      // translation.  Since they're not going through a view here, we need
      // to do the translation.  (that was a fun bug!)
      var autocompParams = fieldData[5];
      if (newFieldType == Def.ComboField.PREFETCHED_LIST) {
        var ac = new Def.Autocompleter.Prefetch(this.field_.id,
          autocompParams['optList'], {
            'matchListValue': autocompParams['matchListValue'],
            'addSeqNum': autocompParams['add_seqnum']=='true',
            'dataRequester': rdr,
            'codes': autocompParams['code_vals'],
            'autoFill': autocompParams['auto_fill']});
        // If no selection list was specified for the autocompleter and if
        // we have a update list parameter in the field data, this list gets
        // its data from another autocompleter's RecordDataRequester.  Call
        // loadList to find and load the data.
        if ((autocompParams['optList'] == null ||
             autocompParams['optList'].length == 0) &&
            fieldData[6] != null) {
          ac.loadList(Def.FIELD_ID_PREFIX+fieldData[6][0], fieldData[6][1]);
        }
      }
      else { // Def.ComboField.SEARCH_FIELD
        // Create the search autocompleter, but turn off the use of the
        // results cache, which is not safe for a combo field since it is based
        // on the field's target field name.
        new Def.Autocompleter.Search(this.field_.id,
                     autocompParams['resultsUrl'],
                     {matchListValue: autocompParams['matchListValue'],
                      autocomp: autocompParams['autocomp'],
                      dataRequester: rdr,
                      useResultCache: false});
      }

    } // end other object setups for list fields

    // Reset the observers
    this.resetObservers(observers, newFieldType) ;

    // Set - or reset - the tipValue attribute on the field to the tooltip
    // value - or blank if there isn't one.
    if (tooltip != "") {
      Def.resetTip(this.field_, tooltip) ;
    }

    // Evaluate any javascript that was returned and reset current field type
    eval(jvscript) ;
    this.currentFieldType_ = newFieldType;

  } , // end assignNewFieldControls
  
  
  /**
   *  This checks to see if the DOM elements for the field need to be
   *  switched around.  This is necessary when we go from a text/list field
   *  to a date field and vice versa.  At the moment this is only for 
   *  fields in a horizontal table.  If/when we run across combo fields not
   *  in a horizontal table we'll need to look at what's necessary there.  
   *  Might be nothing.
   *  
   *  The switches ASSUME that a combo field is created with a default type
   *  of plain text - no list, no dates.  This is when it's initially set
   *  up.  If that changes, the assumptions made by this and the insert
   *  functions will need to be modified.
   *  
   *  @param dateFieldData the date field elements passed back from the
   *   server, when we're moving to a date field.  If we're not moving
   *   to a date field this parameter will be null.
   */
  positionDOMElements: function(dateFieldData) {

    // If we're moving to a date field the dateFieldData parameter will
    // not be null.
    if (dateFieldData) {
      if (this.master_parent_node_ == null) {
        this.setInstanceDOMElements(dateFieldData.trim()) ;
      }
      this.switchToDateFieldAncestors() ;
    }
    // Otherwise if we're moving FROM a date field, no elements need to
    // be passed on, as they've already been stored when we changed to
    // a date field.
    else if (this.currentFieldType_ == Def.ComboField.DATE_FIELD)
      this.switchToTextFieldAncestors() ;
    
    // Note that if we're moving from a plain text to a list field, or
    // vice versa, we don't need to do any positioning.
  } , // end positionDOMElements


  /**
   *  This sets up the DOM ancestor element structures used when we
   *  switch back and forth between date and non-date fields in a table.
   *
   *  This should be called only once, when we first switch from a text or
   *  list field to a date field.   This will locate and store the ancestor
   *  elements for text and list fields in the text_field_parent and _ancestor
   *  holders, and detach them from the master_parent_node (which it also
   *  locates and stores).
   *
   *  The date field html passed in is then converted to DOM nodes, and the
   *  parent and ancestor nodes for dates are stored in the appropriate holders.
   *
   *  This only needs to be called once because the nodes store here are
   *  reused for subsequent field type switches.  So it assumes that the
   *  master_parent_node, and the holders for the other nodes, are null when
   *  this is called.
   *
   *  This also assumes that the combo field is created as a plain text field
   *  with whatever ancestor node(s) it needs as for a plain text input field.
   *
   *  @param date_html the date field html returned from the server
  */
  setInstanceDOMElements: function(date_html) {

    // Get the immediate parent for the text field hierarchy - that is,
    // the node that is at bottom/end of the nodes specific to text field.
    // We'll need that to reattach the text field nodes if we switch back
    // to a text or list field.
    this.text_field_parent_node_ = this.field_.parentNode ;

    // Now get the top text field specific nodes.  We'll need that to
    // replace the date-specific nodes if we switch back to a text field.
    var the_ancestors = this.field_.ancestors() ;
    for (var a = 0, aLen = the_ancestors.length;
                    a < aLen && the_ancestors[a].nodeName != 'TD'; ++a) ;
    this.text_field_ancestors_ = the_ancestors[a - 1] ;

    // Then set the master_parent_node, which is where we attach
    // the date or text field nodes.
    this.master_parent_node_ = the_ancestors[a] ;

    // Now extract the html that describes the date field specific nodes
    // that go between the master parent node and the input and tip field
    // nodes (which stay the same).  Convert the html to dome nodes and
    // store the beginning node as the date field parent node.
    var start_frag = date_html.substring(0, date_html.indexOf('INPUTFIELD')) ;
    this.date_field_ancestors_ = HTMLtoDOM(start_frag,
                                           document.createElement("div")) ;

    // Now find the node in the date field specific nodes to which we
    // need to attach the input and tip field nodes.
    this.date_field_parent_node_ = this.date_field_ancestors_ ;
    while (this.date_field_parent_node_.immediateDescendants().length > 0) {
      var children = this.date_field_parent_node_.immediateDescendants() ;
      var child_count = children.length ;
      this.date_field_parent_node_ = children[child_count - 1];
    }
    // And set the tip field node pointer while we're at it.
    this.tip_field_node_ = this.field_.next() ;

  } , // end setInstanceDOMElements


  /**
   *  This switches the DOM elements enclosing the combo field from those
   *  used for a text field to those used for a date field.
   */
  switchToDateFieldAncestors: function() {

    // Remove the text field specific nodes from the master parent's children
    this.master_parent_node_.removeChild(this.text_field_ancestors_) ;

    // Add the input and tip fields to the date field parent node's
    // children and then add the date field nodes to the master parent
    // node's children.
    this.date_field_parent_node_.appendChild(this.field_) ;
    this.date_field_parent_node_.appendChild(this.tip_field_node_) ;
    this.master_parent_node_.appendChild(this.date_field_ancestors_) ;

  } , // end switchToDateFieldAncestors


  /**
   *  This switches the DOM elements enclosing the combo field from those
   *  used for a text field to those used for a date field.
   */
  switchToTextFieldAncestors: function() {

    // Remove the date field specific nodes from the master parent's children
    this.master_parent_node_.removeChild(this.date_field_ancestors_) ;

    // Add the input and tip fields to the text field parent node's
    // children and then add the text field nodes to the master parent
    // node's children.
    this.text_field_parent_node_.appendChild(this.field_) ;
    this.text_field_parent_node_.appendChild(this.tip_field_node_) ;
    this.master_parent_node_.appendChild(this.text_field_ancestors_) ;
    
  } , // end switchToTextFieldAncestors

  /**
   *  This resets the field observers to the ones specified for this field
   *  type.  This assumes that the observers that were on the field have
   *  already been stopped.  This calls the setUpFieldListeners function in
   *  the navigation code to set up what came back from the server.  Any other
   *  observers will be out of luck, except the ones the autocompleters set up.
   */
  resetObservers:  function(observers, newFieldType) {

    // Execute the javascript passed back for the observers.  This will
    // create the fldObservers object, which contains the observers
    // for the field.
    eval(observers) ;

    // Pass the new field observers to setUpFieldListeners to use those
    // for the field now.
    Def.Navigation.setUpFieldListeners(this.field_, fldObservers) ;

    if (newFieldType == Def.ComboField.DATE_FIELD) {
      var calendar_field = $(this.split_field_id_[0] +
                             this.split_field_id_[1] + '_calendar' +
                             this.split_field_id_[2])
      Def.Navigation.setUpFieldListeners(calendar_field, fldObservers) ;
    }
  } // end resetObservers
}); 


Object.extend(Def.ComboField, {
  // Field type constants - need to match constants in combo_fields_helper.rb
  // AND comparison_operator.rb
  /**
   *  The field type constant for a plain text field.
   */
  PLAIN_TEXT: 1,

  /**
   *  The field type constant for a prefetched list field.
   */
  PREFETCHED_LIST: 2,

  /**
   *  The field type constant for a search field.
   */
  SEARCH_FIELD: 3,

  /**
  *   The field type constant for a date field.
  */
  DATE_FIELD: 4
});


