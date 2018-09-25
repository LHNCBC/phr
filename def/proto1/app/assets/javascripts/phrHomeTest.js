/** 
 * phrHomeTest.js -> Test code used in acceptance testing of the
 *                   PHR Home page.
 *
 *  This contains code for processing performed by the acceptance testing,
 *  where the processing is too long to include in a single javascript
 *  statement or I just couldn't figure out how to do it.
 *
 *  License:  This file should be considered to be under the terms of some
 *  "non-viral" open source license, which we will specify soon.  Basically,
 *  you can use the code as long as you give NLM credit.
 *  
 **/

Def.PhrHomeTest = {

  /**
   * This Provides a date string for a date that is a specified number of years,
   * months, and or days ago.  This was written to use when testing the specification
   * of a birth date for a new or updated phr, and then checking to see if the age
   * string displayed for that phr is correct.
   *
   * @param years_ago how many years ago the returned date should be, or 0 for 
   *  the current year
   * @param months_ago how many months ago the date should be or 0 for the current 
   *  year
   * @param days_ago how many days ago the date should be or 0 for the current day
   * @returns the computed date string in a slash-delimited format that is acceptable
   *  to our date fields
   */
  getPrevDate: function(years_ago, months_ago, days_ago) {

    var prevDate = new Date();
    if (years_ago > 0)
      prevDate.setFullYear(prevDate.getFullYear() - years_ago);
    if (months_ago > 0)
      prevDate.setMonth(prevDate.getMonth() - months_ago);
    if (years_ago > 0)
      prevDate.setDate(prevDate.getDate() - days_ago);
    return prevDate.toLocaleDateString() ;
  } , // end getPrevDate


  /**
   * This function extracts a total reminders count from a reminders string
   * displayed for a phr on the PHR Home page.  This can be the health
   * reminders or the date reminders.  It just needs to be formatted so that
   * the count comes first followed by a space and then the type of reminder -
   * "health" or "date" - or whatever word follows the count.
   *
   * @param the reminders string
   * @param the type of reminder
   * @returns the count as an integer
   */
  totalRemCount: function(remindersString, remType) {

    var textStart = remindersString.indexOf(remType) ;
    return parseInt(remindersString.substring(0, textStart).trim()) ;
  } , // end totalRemindersCount


 /**
   * This function extracts a new reminders count from a reminders string
   * displayed for a phr on the PHR Home page.  Currently this is just used
   * for health reminders.  The reminders string is assumed to have text
   * that precedes the count, and the count in the format (x new) where x
   * is the count, and it and the word "new" are enclosed in parentheses.
   *
   * @param the reminders string
   * @returns the count as an integer
   */
  newRemCount: function(remindersString) {

    var startParen = remindersString.indexOf("(") ;
    var endSpace = remindersString.indexOf(" ", startParen) ;
    return parseInt(remindersString.substring(startParen + 1, endSpace).trim()) ;
  } , // end totalRemindersCount


 /**
   * This function will go through an array of unread reminders and click on each one
   * so that all the reminders in the array are flagged as read. 
   */
  reviewHealthReminders: function() {
    for (var i = 0; i < testWindow_.document.getElementsByClassName('unread truncated_node').length; i++) {
      ATR.clickCmd(['javascript{testWindow_.document.getElementsByClassName("unread truncated_node")[' + i + ']}']);
    }
    return true ;
  } ,

  verifyDialogBoxTitle: function(box, title) {
    //var box = testWindow_.$('Def.PHRHome.' + box_name) ;
    //var title = $('testWindow_.Def.PHRHome.' + title_name).innerHTML ;
    return (box.dialog_.siblings()[0].firstChild.innerHTML == title);
  } 
}; // end Def.PhrHomeTest
