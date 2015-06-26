/** 
 * usageStatsTest.js -> Test code used in acceptance testing of the
 *                      Usage stats stuff.
 *
 *  This contains code for processing performed by the acceptance testing,
 *  where the processing is too long to include in a single javascript
 *  statement.
 *
 *  License:  This file should be considered to be under the terms of some
 *  "non-viral" open source license, which we will specify soon.  Basically,
 *  you can use the code as long as you give NLM credit.
 *  
 **/

Def.UsageStatsTest = {
  
  /**
   * This function runs through the current events stored in the Def.UsageMonitor
   * occurrenceData_ array and writes the event type and event data to the test
   * storage that can then be examined by test statements.
   *
   * @param occData the current usage monitor occurrence data
   * @param storedData the ATR.testData_
   * @param keepFocus an optional flag indicating whether or not to keep any
   *  focus events processed.  Default is true.  Pass false when the event types
   *  being checked don't include focus events.
   */
  getEvents: function(occData, storedData, keepFocus) {

    if (keepFocus === undefined)
      keepFocus = true ;

    while (occData.length > 0) {
      var numEvents = occData.length;
      for (var i=numEvents - 1; i >= 0; i--) {
        var evName = occData[i][0];
        if (keepFocus == true || evName.indexOf('focus') < 0) {
          if (evName == 'list_value') {
            if (occData[i][2]['duplicate_warning'] != null)
              evName = 'dup_warning' ;
            else if (occData[i][2]['suggestion_list'] != null)
              evName = 'suggestions' ;
          }
          var datHash = occData[i][2];   
          if (occData[i][0] == 'list_value') {
            storedData['events'][evName] = {} ;
            for (var key in datHash) {
              storedData['events'][evName][key] = datHash[key];
            }
          } // end if this is a list_value event
          else {
            if (storedData['events'][evName] == null) {
              storedData['events'][evName] = {};
            }
            var evData = storedData['events'][evName] ;
            for (var key in datHash) {
              var value = datHash[key] ;
              if (evData[key] == null) {
                evData[key] = {};
              }
              if (evData[key][value] == null) {
                evData[key][value] = 1;
              }
              else {
                evData[key][value] += 1;
              }
            } // end for each key in the data hash
          } // end if this is not a list_value event
        } // end if this is not a focus event to be discarded
        occData.splice(i,1);
      } // end for the current number of events
    } // end while there are more events to process
    return true ;
  } , // end getEvents
  

  /**
   * This function validates a date/time stamp.  It validates the format,
   * which is expected to include fractional seconds, and it validates the value,
   * which should be less than the current time, but by no more than 2 minutes.
   *
   *
   * @param dateTime the value to be validated
   */
  validateDateTime: function(dateTime) {

    // Check the format first
    var dateParts = dateTime.split('T') ;
    var datePatt = /^(19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$/;
    var ret = datePatt.test(dateParts[0]) ;
    if (ret) {
      var timePatt = /^(0[0-9]|1[0-9]|2[0-3])(:([0-5][0-9])){2}.[0-9]{3}Z$/;
      ret = timePatt.test(dateParts[1]) ;
    }

    // If the pattern's OK compare it to the current time.  It should be
    // less than the current time but greater than 2 minutes ago.
    if (ret) {     
      var cur = new Date();
      var prev = new Date() ;
      var min = cur.getMinutes() ;
      if (min > 1) {
        prev.setMinutes(min - 2) ;
      }
      else {
        prev.setHours(prev.getHours() - 1);
        prev.setMinutes(58 + min) ;
      }
      cur = cur.toISOString();
      prev = prev.toISOString();

      ret = (dateTime < cur && dateTime > prev);
    }
    return ret ;
  } // end validateDateTime
}; // end Def.usageStatsTest
