/** 
 * usageMonitor.js -> The UsageMonitor object and methods
 *
 *  This stores information about the user's session and actions the user has
 *  taken so that we can analyze usage patterns (in a de-identified manner).
 *  There is only one of these, so it is not defined as a class.
 *
 *  License:  This file should be considered to be under the terms of some
 *  "non-viral" open source license, which we will specify soon.  Basically,
 *  you can use the code as long as you give NLM credit.
 *  
 * $Id:  $
 * $Source:  $
 * $Author:  $
 *
 * $Log:  $
 *
 **/

Def.UsageMonitor = {
  
  /**
   *  The interval at which to save any discreet event occurrences that have 
   *  not been saved.
   */
  CHECK_STATS_TIME : 60 * 1000 , // 60 seconds in milliseconds
  
  /**
   * The timeout object used to trigger the (next) check
   */
  checkTime_ : '' ,

  /**
   * The current "last active" time.  This is reset every time occurrence
   * data is sent to the server.  We may get multiple occurrences of the
   * last_active event, so between sends to the server, we just retain one
   * time.
   */
  lastActive_ : null ,
  
  /**
   *  Contains data for the events for which we store data for each occurrence
   *  of the event i.e. not counts of things).  Each element stores one event 
   *  in an array containing the event name, the event time, and the event data.
   *  The event data is a hash that contains various key/value pairs, depending
   *  on the event type.  For example, a logout event could have the following
   *  data hash:
   *    {"type":"user_requested"}
   */
  occurrenceData_: [],

  /**
   * A hash used to hold event parameters that are acquired before the event
   * is written to the occurrenceData_ array.  This is used for autocompleter
   * list events at the moment, but could be used by other event types as
   * needed.  The key for this hash is a field id, which identifies the
   * field for which event parameters are being recorded.   The value in
   * this hash is another hash, that contains the various key/value pairs
   * appropriate to the list scenario being recorded.
   */
  holdParams_ : {},

  /**
   * An array of the event names for the list events that pass data to
   * the usage monitor.
   */
  LIST_EVENTS : {'listSelection':  1,
                 'fieldFocus':  1,
                 'listExpansion': 1,
                 'escapeKey': 1,
                 'suggestionListShown': 1,
                 'suggestionListUsed': 1,
                 'duplicateWarning': 1} ,

  /**
   * An array of the event names for those list events that are considered
   * 'terminating', i.e., those that should intiate the process of saving
   * the list parameters we've been accumulating.
   */
  TERMINATING_EVENTS : {'listSelection': 1,
                        'escapeKey': 1,
                        'suggestionListUsed': 1,
                        'duplicateWarning': 1} ,


  /**
   * Contains the base ID of the fields for which autocompleter list usage
   * observers have been set.  Avoids setting them for each instance of
   * the field, since that is not necessary.
   */
  observersSet_ : [] ,

  /**
   * A string indicating that a suggestionListShown event has been received
   * but a suggestionListUsed event has not yet been received.  Currently we
   * only receive a suggestionListUsed event, which is a terminating event,
   * if the user actually selects a suggestion from the list.  If they do
   * not, we don't get anything.  I don't want to make the list shown event
   * a terminating one, because if we then get a list used event, we've
   * already processed the shown event.  So I'm hoping I can talk Paul into
   * providing a suggestionListUsed event - with a false flag - when the
   * suggestion list box is brought down - whether by the user selecting a
   * suggestion or by the user just getting rid of the box.
   *
   * In the interim this string is set to the field ID when we get the list
   * shown event.  If the next event received is not a list used event, we go
   * ahead and write out what we've got.  :(
   *
   * The string is reset to empty if a list used event is received or a pending
   * event is processed.
   *
   * NOTE - if the user just closes the suggestion list box and doesn't go to
   * any other field that we're tracking list events for, the data will be lost 
   * - because we won't get another list event.
   */
  suggestionShownPending_ : "" ,

  /**
   * This function sets observers for all form fields that use observers for
   * usage stats - currentlythe autocompleter list usage observers.  The
   * observers are set for all form fields with the base ID (field ID excluding
   * the prefix and suffix).   As noted above, for the observersSet_, this is
   * done once for each base ID, not for each instance of the field.
   */
  setObservers: function(fieldObj) {
    var baseID = Def.IDCache.splitFullFieldID(fieldObj.id)[1] ;
    if (this.observersSet_.indexOf(baseID) < 0) {

      Def.Autocompleter.Event.observeFocusEvents(baseID,
            function(data){Def.UsageMonitor.storeListEventParams('fieldFocus', data);});

      Def.Autocompleter.Event.observeListExpansions(baseID,
      function(data){Def.UsageMonitor.storeListEventParams('listExpansion', data);});

      Def.Autocompleter.Event.observeCancelList(baseID,
            function(data){data['escape_key'] = true;
                           data['used_list'] = false ;
                           Def.UsageMonitor.storeListEventParams('escapeKey', data);});

      Def.Autocompleter.Event.observeListSelections(baseID,
      function(data){Def.UsageMonitor.storeListEventParams('listSelection', data);});

      Def.Autocompleter.Event.observeSuggestionsShown(baseID,
            function(data){Def.UsageMonitor.storeListEventParams('suggestionListShown', data);});

      Def.Autocompleter.Event.observeSuggestionUsed(baseID,
            function(data){data['used_suggestion'] = true;
                           Def.UsageMonitor.storeListEventParams('suggestionListUsed', data);});

      Def.FieldsTable.ControlledEditTable.observeDuplicateWarnings(baseID,
            function(data){data['duplicate_warning'] = data['data'] ;
                           delete data.data;
             Def.UsageMonitor.storeListEventParams('duplicateWarning', data);});

      this.observersSet_.push(baseID) ;
    }
  } , // end setObservers


  /**
   *  Adds a new piece of data for an event where we save each occurrence.
   * @param eventName the name of the event that happened (a key for the data)
   * @param eventData (optional) hash of data associated with the event
   */
  add: function(eventName, eventData) {
    if (eventData === undefined)
      eventData = null;
    if (eventName === 'last_active') {
      this.lastActive_ = eventData ;
    }
    else {
      this.occurrenceData_.push([eventName, new Date().toISOString(), eventData]) ;
    }
    if (eventName === 'form_closed' && this.suggestionShownPending_ != "")
      this.processAbandonedSuggestions();
  },
  
  
  /**
   *  Sends a report for the collected data and resets the collected data
   *  storage buffers (so that each subsequent call will only send new data).
   * @param idShown id shown for the profile for which this is being sent.
   *  Default is the Def.DataModel.id_shown_.  This is used primarily by
   *  certain popups when they are closed, to make sure that the usage
   *  stats gathered on the popup (e.g., the reminders window) get sent.
   */
  sendReport: function(idShown) {
    
    idShown = idShown === undefined ?
                          Def.DataModel && Def.DataModel.id_shown_ : idShown ;
    if (this.lastActive_) {
      this.occurrenceData_.push(['last_active', new Date().toISOString(),
                                              {'date_time':this.lastActive_}]) ;
      this.lastActive_ = null ;
    }
    if (this.occurrenceData_.size() > 0) {
      new Ajax.Request('/usage_stats', {
        method: 'post',
        parameters: {
          id_shown: idShown ,
          report: Object.toJSON(this.occurrenceData_),
          authenticity_token: window._token
        },
        // onSuccess: do nothing
        onFailure: function(response) {
          // use the Def.onFailedSave function to take care of the problem.
          Def.onFailedSave(response, true) ;
        },
        asynchronous: true
      });
      
      // Reset the collected data.  Don't wait until the request returns, 
      // because new data might arrive in the meantime.  If the request doesn't 
      // make it, then we will just lose some data.  (I'm not sure why it 
      // wouldn't make it. - because life is cruel.)
      this.occurrenceData_ = [];
    } // end if there's anything to send
  } , // end sendReport


  /**
   * This function accepts list event parameters from autocompleter list
   * callbacks.  It merges them into the holdParams_ hash for the specific
   * field on which the events are being recorded, which may or
   * may not already have some parameters that we're holding for the current
   * autocompleter field.   If the event that initiates this is a "terminating"
   * event, i.e., an event that causes the user to leave the field, the
   * createListEventReport method is then called to evaulate the parameters
   * we have, set the scenario value, and add a row to the occurrenceData_.
   *
   * This function checks to make sure that, if we already have some parameters
   * on hold, the parameters being passed now are for the same field_id.  It
   * also verifies that the event_type is one defined by the LIST_EVENTS hash.
   *
   * @param event_type the name of the event that called this function; must
   *  be one of the expected types, as defined by the LIST_EVENTS hash.
   * @param params a hash of the values being passed by the calling event;
   *  varies by event type.
   */
  storeListEventParams: function(event_type, params) {

    // First check to see if we have a valid event type
    if (this.LIST_EVENTS[event_type] === null) {
      // we have a problem
    }
    else {
      var fieldID = params['field_id'] ;

      // Before we process the current event data, check for suggestion events.
      // 
      // If this is a suggestionListShown event, place the fieldID in the
      // suggestionShownPending_ variable so we'll know we're waiting to see
      // if the user used a suggestion.  But do this ONLY if there were any
      // suggestions to display.
      // 
      // If this is a suggestionListUsed event, it's telling us what suggestion
      // the user selected.  Clear the pending variable and move on with
      // processing.
      // 
      // If there is a suggestion list event left over that hasn't been closed
      // out, call processAbandonedSuggestions to process the leftover event.
      // On return we'll process the current event.

      if (event_type === 'suggestionListShown') {
        var noSuggestions = params['suggestion_list'].length == 0 ;
        if (noSuggestions == false)
          this.suggestionShownPending_ = fieldID ;
      }
      else if (event_type === 'suggestionListUsed')
        this.suggestionShownPending_ = "" ;
      else if (this.suggestionShownPending_ != "") {
        this.processAbandonedSuggestions() ;
      }
      // Now process the current event.
      if (this.holdParams_[fieldID] == null)
        this.holdParams_[fieldID] = {'field_id':fieldID} ;
      var fieldParams = this.holdParams_[fieldID] ;
      if (fieldParams['start_time'] == null)
        fieldParams['start_time'] = new Date().toISOString() ;
      if (event_type === 'fieldFocus' && fieldParams['final_val'])
         fieldParams['final_val'] = null ;
      fieldParams = ($H(params).merge(fieldParams)).toObject() ;
      if (event_type === 'escapeKey') {
        fieldParams['val_typed_in'] = fieldParams['restored_value'] ;
        delete fieldParams['restored_value'] ;
      }
      this.holdParams_[fieldID] = fieldParams ;
      if (this.TERMINATING_EVENTS[event_type] || noSuggestions)
        this.createListEventReport(fieldID) ;
    } // end if we're on the right field
  } , // end storeListEventParams


  /**
   *  This function processes a pending suggestions event when the
   *  user does not use the list and does not return to the field for
   *  which the list was generated.
   *
   *  It is called in two cases:
   *  1) if the user closes the suggestion list box and clicks in a
   *     field other than the one the suggestions were for; and
   *  2) if the user closes the suggestion list and closes the current
   *     form.
   */
  processAbandonedSuggestions: function() {
     this.holdParams_[this.suggestionShownPending_]['used_suggestion'] = false ;
     this.createListEventReport(this.suggestionShownPending_) ;
     this.suggestionShownPending_ = "" ;
  } , // end processAbandonedSuggestions
  

  /**
   *  This function determines what scenario is to be assigned to the
   *  list event usage data stored for the current autocompleter field, 
   *  based on what parameters are specified, and call the add function
   *  to add a usage data record for the field.  If a scenario can't be
   *  determined, an error is thrown but processing is allowed to continue.
   *
   *  Scenarios are as follows:
   *  A - User selects or enters a value from a non-expanded list
   *  B - User selects a value from an expanded list
   *  C - User uses the escape key to restore a typed-in value
   *  D - User selects a value from a suggestion list
   *  E - User does not select a value from a suggestion list
   *  F - User enters a value not found on any lists, nothing to suggest
   *  G - User enters a duplicate value 
   *
   * @param fieldID the form field ID for the input field
   */
  createListEventReport: function(fieldID) {

    var fieldParams = this.holdParams_[fieldID] ;

    // check to make sure the minimum values are in the holding hash
    // hm - not sure yet what this should be.
    if (fieldParams['field_id'] === null) {
      ; // we have a problem.  Not enough data here
    }
    else {
      // process a duplicate warning
      if (fieldParams['duplicate_warning']) {
        fieldParams['scenario'] = 'G' ;
      }
      else {
        // process suggestion list variations when no suggestion used
        if (fieldParams['suggestion_list']) {
          if (fieldParams['suggestion_list'].length == 0) {
            fieldParams['scenario'] = 'F' ;
            fieldParams['used_suggestion'] = false ;
          }
          else
            fieldParams['scenario'] = 'E' ;
        }
        else {
          // process a suggestion list used event
          if (fieldParams['used_suggestion'] === true) {
            fieldParams['final_val'] = fieldParams['suggestion_used'] ;
            delete fieldParams['suggestion_used'] ;
            fieldParams['scenario'] = 'D' ;
          }
          else {
            // process the other types
            if (fieldParams['escape_key'] === true)
              fieldParams['scenario'] = 'C' ;
            else {
              if (fieldParams['list_expansion_method'])
                fieldParams['scenario'] = 'B';
              else {
                if (fieldParams['input_method'])
                  fieldParams['scenario'] = 'A' ;
                else
                  ;// we have a problem
              } // end if list expanded
            } // end if escape key event
          } // end if suggestion used
        } // end if not an unused suggestion
      } // end if not a duplicate warning
      this.add('list_value', this.holdParams_[fieldID]) ;
      if (fieldParams['scenario'] in {A:1, B:1})
        var hold_final = fieldParams['final_val'] ;
      this.holdParams_[fieldID] = {'field_id':fieldID} ;
      if (fieldParams['scenario'] in {A:1, B:1})
        this.holdParams_[fieldID]['final_val'] = hold_final ;
    } // end if we are/aren't missing some data
  } , // createListEventReport


  /**
   *  Checks to see if there are pending reports and, if there are, sends
   *  them to the server.
   */
  checkForReports: function() {
    
    // Call sendReport and reset the timer.
    Def.UsageMonitor.sendReport() ;
    Def.UsageMonitor.setTimer() ;
    
  },  // end checkForReports

      
  /**
   * Sets the timer to invoke the checkForReports function at the
   * CHECK_STATS_TIME interval.  Clears the timeout first if it's
   * not already cleared.  This is initiated in the show.rhtml.erb
   * file IF we're not in test mode.  If we are, we want the usage
   * data to be available on the client side for checking while the
   * test is running.
   */
  setTimer: function() {
    if (Def.UsageMonitor.checkTime_ != '')
      window.clearTimeout(Def.UsageMonitor.checkTime_) ;
    Def.UsageMonitor.checkTime_ = 
                         window.setTimeout("Def.UsageMonitor.checkForReports()",
                                           this.CHECK_STATS_TIME) ;
  } , // end setTimer


  /**
   * Clears the timer if it's not already cleared
   */
  stopTimer: function() {
    if (Def.UsageMonitor.checkTime_ != '')
      window.clearTimeout(Def.UsageMonitor.checkTime_) ;
  }  // end stopTimer
     
};
