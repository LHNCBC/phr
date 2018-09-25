/* Depends on popups.js
 *
 * Opens a popup window to display related MedlinePlus pages.
 */

/* ***************************** 
 * Global Variables used to specify popup window size, options, and
 * to track window status for using a single popup window for all links.
 */

/*
 * Size and options, for initial popup.  We let the general popups code
 * position the box relative to the field that called it.
 */
var MPlusWindowOpts_  = 'width=1000,height=680,resizable=yes,scrollbars=yes,' +
                        'status=yes';
/*
 * Pointer to window
 */
var MPlusWindowObjectReference_ = null;

/*
 * Target name for MedlinePlus window
 */
var MPlusWindowTarget_ = "mplusWindow";

/*
 * Url currently in the popup window.  (Not really used in the code, but useful
 * for testing.)
 */
var MPlusPreviousUrl_;


/*
 * A dialog window showing multiple clickable medlineplus links 
 */
var MplusDialog_ = null;


/**
 * This is intended to be the onclick action for an element that
 * open links to MedlinePlus Health Topic page in a new window
 *
 * @param clickedImg the element that was clicked
 * @param nameTarget farget_field value for the text field that holds
 *  the health problem value.
 *
 */
  function raiseMplusHealthTopicLink(clickedImg, nameTarget) {

    // Get the problem name from the problem field.
    var idParts = Def.IDCache.splitFullFieldID(clickedImg.id) ;
    var problemField = $(idParts[0] + nameTarget + idParts[2]);
    var problemName = Def.getFieldVal(problemField);

    if (problemName==null || problemName.length==0 ) {
      // if no problem name, pop-up help message
      alert("Please enter the name of a Medical Problem in this row.");
    }
    else {
      // Try to get the code for the value if the field has an autocompleter.
      var fieldAutocomp = problemField.autocomp;
      var code = null;
      codeField = Def.getFieldsCodeField(problemField);

      if (codeField)
        code = Def.getFieldVal(codeField);

      // Construct the AJAX URL
      var theAjaxUrl ;
      if (code && code != '') {
        theAjaxUrl = '/form/mplus_health_topic_links?problem_code=' +
                     code.escapeHTML();
      }
      else {
        // Use the problem name instead.
        theAjaxUrl = '/form/mplus_health_topic_links?problem_name=' +
                     problemName.escapeHTML();
      }
      openMplusLinksAsPopUp(theAjaxUrl, problemName, problemField);
    }
  } // end raiseMplusHealthTopicLink


/**
 * This is intended to be the onclick action for an element that
 * open links to MedlinePlus drug page in new window.
 * This method assumes the element is part of a 2-stage drug auto-repeater
 * in a repeating line.
 * MODIFIED Jan 2008 - no longer assumes a 2-stage autocompleter
 *                     field.
 * @param clickedImg the element that was clicked
 * @param target the target_field value for the field containing the drug name
 */
  function raiseMplusDrugLink(clickedImg, target) {

    var idParts = Def.IDCache.splitFullFieldID(clickedImg.id) ;
    var formFld = $(idParts[0] + target + idParts[2]);
    var theDrug = Def.getFieldVal(formFld);

    // Pop up the appropriate page based on the number of links
    if (theDrug==null || theDrug.trim().length==0) {
      alert("Please select a drug in this row.");
    }
    else {
       var theAjaxUrl = '/form/mplus_drug_links_for?drugName=' +
                       theDrug.escapeHTML();
       openMplusLinksAsPopUp(theAjaxUrl, theDrug, formFld);
    }
  } // end raiseMplusDrugLink
  
  
  /* Open a pop up with related MedlinePlus information using the links or
   * query provided as arguments.
   *
   * @param mplusLinkArray an array of 2-dimensional arrays.  Each 2-dimensional
   *  array is an URL and title for a MedlinePlus page.
   * @param theQuery a query string in case the first argument is empty.
   * @param theField the form field to be used to position the window
   */  
  function openMplusLinksAsPopUp(theAjaxUrl, theQuery, theField){
    // Open a popup, then update it's url based on the response from ajax. 
    // Warning:  Don't open popup inside ajax call as the popup could be 
    // blocked by the special browser setting. - Frank
    openMplusPopUp("about:blank", theField);
    // Use the Prototype javascript Ajax.Request to make a request and handle
    // the response.
    // When the Ajax request succeeds, execute onSuccess.
    // When the Ajax request fails, execute onFailure.
    new Ajax.Request(theAjaxUrl,
    {
      method:'get',
      onSuccess: function(transport){
        // Create a javascript Array object from the response text 
        var responses = JSON.parse(transport.responseText);

        // Update the pop-up window using the received url(s) and title(s)
        updateMplusLinksInPopUp(responses, theQuery);
      },
      onFailure: function(){
        // Update a MedlinePlus search result page for the problem name
        updateMplusSearchLinkDoc(theQuery);
      }
    });
  } // end of openMplusLinksAsPopUp
  

  /* Update the pop up with related MedlinePlus information using the links or
   * query provided as arguments.
   *
   * @param mplusLinkArray an array of 2-dimensional arrays.  Each 2-dimensional
   *  array is an URL and title for a MedlinePlus page.
   * @param theQuery a query string in case the first argument is empty.
   */
  function updateMplusLinksInPopUp(mplusLinkArray, theQuery) {

    if (mplusLinkArray==null || mplusLinkArray.length==0) {
      //remove the route part if no links
      theQuery=theQuery.replace(/\s*\(.*\)\s*$/, '');
      // update url of the pop up search results when there are no links
      updateMplusSearchLinkDoc(theQuery)
    } 
    else if (mplusLinkArray.length==1) {
      // update url of the pop up when exactly one link is received
      var docLocation = mplusLinkArray[0][0];
      updateMplusPopUpUrl(docLocation);
    } 
    else {
      // update the list of links of the pop up when more than one link is received
      updateMultiMplusLinkDocs(mplusLinkArray, theQuery, 0);
    }
  } // end updateMplusLinksInPopUp


  /* Create a search-based URL for medlinePlus given a query and replace the url
   * of the Mplus pop up window.
   *
   * @param theQuery the query to be executed
   */
  function updateMplusSearchLinkDoc(theQuery) {
    var docLocation = 'http://search.nlm.nih.gov/medlineplus/query?' +
                  'MAX=500&SERVER1=server1&SERVER2=server2&' +
                  'DISAMBIGUATION=true&FUNCTION=search&PARAMETER=' +
                  encodeURIComponent(theQuery);
    updateMplusPopUpUrl(docLocation);
  } // end updateMplusSearchLinkDoc


  /* Update url of the Mplus pop up window
   *
   * @param docLocation the new url for the pop up window
   */
  function updateMplusPopUpUrl(docLocation){
    MPlusPreviousUrl_ = docLocation;
    
    // Add the event to the usage reporting data - unless this is the call
    // from openMultiMplusLinkDocs that opens a blank page and then writes
    // to it.  We don't need to track that.  We'll get what the user clicks
    // on from the list of links.
    if (docLocation != 'about:blank')
      Def.UsageMonitor.add('info_button_opened',
                           {"info_url":docLocation});
    
    MPlusWindowObjectReference_.location.href = docLocation;        
  } // end updateMplusPopUpUrl


  /**
   * Create a jQuery dialog with related medlineplus links based on the query 
   *  
   * @param mplusLinkArray an array of link information, where each element
   *  is itself a two-element array containing a URL and a title.
   * @param theQuery a subject about which the links are being offered
   * @param retryCount the number of attempts that have been made to show
   *  the links.  For a while, if an exception is thrown, this method will
   *  set a timeout to call itself a little later when the link window is
   *  ready.  Pass in zero, except within this method itself.
   */  
  function updateMultiMplusLinkDocs(mplusLinkArray, theQuery,retryCount) {
    // close the empty pop up window prepared for single medlineplus links
    if(MPlusWindowObjectReference_ !=null)
      MPlusWindowObjectReference_.close();

    MplusDialog_ = MplusDialog_ || new Def.NoticeDialog({
      width: 700
    });
    
    // get mulitple medlineplus links
    var msgs = [];
    var title = 'MedlinePlus Pages Related to: '+ theQuery;
    //rtn.push('<h1 id=\'title\'>' + title +'</h1>');
    msgs.push('<ul>');
    var itemNum = 1 ;
    mplusLinkArray.each( function(item) {
      var linkString = '<li><a id=\"item' + itemNum.toString() + '\" ' +
        'href=\"javascript:void(0);\" alt=\"'+item[0]+'\" ' +
        'onClick=\'openMplusPopUp(this.getAttribute(\"alt\"), null); '+
        'MplusDialog_.hide();\' >' + item[1] + '</a></li>';
      msgs.push(linkString) ;
      itemNum++ ;
    });
    msgs.push('</ul>') ;
    msgs = msgs.join('');
    MplusDialog_.setTitle(title);
    MplusDialog_.setContent(msgs);
    MplusDialog_.show();
    return MplusDialog_;
  }


  /**
   *  Pop up a window displaying the url or text given as an argument.  Tracks
   *  the window to allow reuse of the existing window.
   *  
   * @param docLocation the URL to be used for the popup window, or the text
   *  to be written to it
   * @param anchorFld the form field to use as an anchor for the window, so that
   *  it ends up somewhere close to the field where it was requested.
   */
  function openMplusPopUp(docLocation, anchorFld) {
    MPlusPreviousUrl_ = docLocation;
    
    // If the window has already been put up once, close it.  For some
    // reason that I was unable to figure out, the focus() method does
    // not bring the medlinePlus window back to the front if it's currently
    // open.  It does for other windows, such as the help window.  Just not
    // these.
    if (MPlusWindowObjectReference_ != null)
      MPlusWindowObjectReference_.close() ;
    
    // Add the event to the usage reporting data - unless this is the call
    // from openMultiMplusLinkDocs that opens a blank page and then writes
    // to it.  We don't need to track that.  We'll get what the user clicks
    // on from the list of links.
    if (docLocation != 'about:blank')
      Def.UsageMonitor.add('info_button_opened',
                           {"info_url":docLocation});
    // Open it up!
    MPlusWindowObjectReference_ = openPopup(anchorFld,
                                            docLocation,
                                            null,
                                            MPlusWindowOpts_,
                                            MPlusWindowTarget_);
 
  } // end openMplusPopUp
