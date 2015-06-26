/**
 * ct_search.js -> javascript class that contains functions specific to the
 *                 ct_search form
 *
 * Members of this class should be specific to the ct_search form.
 *
 * $Id: ct_search.js,v 1.2 2010/09/14 23:37:41 taof Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/form/ct_search.js,v $
 * $Author: taof $
 *
 * $Log: ct_search.js,v $
 * Revision 1.2  2010/09/14 23:37:41  taof
 * change field name from age to age_group
 *
 * Revision 1.1  2009/06/02 15:26:26  lmericle
 * added ct_search.js; modified phr.js in way ct_search window brought up and parameters passed
 *
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Bascially,
 * you can use the code as long as you give NLM credit.
 */

/**
 * Set up an event observer to run loadChoices when the form is loaded
 */
Def.CtSearch = {

  /**
   *  Opens a window used to get parameters for a search of the clinical
   *  trials database.  Assumes this is invoked by an onclick of the
   *  Research Studies button (or a button).
   * 
   * @return false (return for button)
   */
  loadChoices: function() {

    // Get the parameters from the url
    var url = location.href.split("?") ;
    if (url.length > 1) {
      var params = decodeURIComponent(url[1]).split("&") ;
      var ageCode = params[0].split("=")[1] ;
      var listItems = params[1].split("=")[1].split("+") ;
      var listCodes = params[2].split("=")[1].split(",") ;
    }
    else {
      params = listItems = listCodes = [] ;
      ageCode = null ;
    }
    // Check to see if we have values from a previous search
    var prevProblem = Def.getFieldVal(opener.$('fe_ctsearch_problem')) ;
    var prevState = Def.getFieldVal(opener.$('fe_ctsearch_state')) ;
    var prevAgeCode = Def.getFieldVal(opener.$('fe_ctsearch_age_code')) ;
 
    // Now set the field values
    if (listItems.length > 0) {
      fe_problem_autoComp.setListAndField(listItems, listCodes) ;
    }
    if (prevProblem != 'undefined')
      Def.setFieldVal($('fe_problem'), prevProblem) ;
    else if (listItems.length > 0)
      Def.setFieldVal($('fe_problem'), listItems[0]) ;
    if (prevState != 'undefined')
      Def.setFieldVal($('fe_state'), prevState) ;
    if (prevAgeCode != 'undefined')
      fe_age_group_autoComp.selectByCode(prevAgeCode) ;
    else if (ageCode)
      fe_age_group_autoComp.selectByCode(ageCode) ;
 
  } ,// end loadChoices


  /**
   *  Responds to the search button on the parameters window.  Saves the
   *  user's current choices in the main PHR form ('opener') hidden fields
   *  used to retain this info.  The choices are retained so that if the
   *  user returns to the parameters window from the clinical trials 
   *  results page (via the back button), the choices will still be 
   *  available and can be redisplayed.
   * 
   * @return false (return for button)
   */
  invokeSearch: function() {

    var the_prob = Def.getFieldVal($('fe_problem')) ;
    Def.setFieldVal(opener.$('fe_ctsearch_problem'), the_prob) ;

    var the_state = Def.getFieldVal($('fe_state')) ;
    var the_state_code = Def.getFieldVal($('fe_state_abbreviation')) ;
    Def.setFieldVal(opener.$('fe_ctsearch_state'), the_state) ;

    var the_age = Def.getFieldVal($('fe_age_group_C')) ;
    Def.setFieldVal(opener.$('fe_ctsearch_age_code'), the_age) ;

    Def.clinTrialsSearch(the_prob, the_state_code, the_age) ;
  } // end invokeSearch

} // end Def.CtSearch

Event.observe(window, 'load', Def.CtSearch.loadChoices);

