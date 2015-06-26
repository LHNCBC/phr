// $Log: messageManager.js,v $
// Revision 1.4  2010/11/03 22:56:00  taof
// add show more or less feature to reminder messages
//
// Revision 1.3  2009/05/27 14:38:41  taof
// create flu shot rule and modified loinc related latest rules
//
// Revision 1.2  2008/10/24 21:34:31  wangye
// bug fixes for IE7 and performance tune-up
//
// Revision 1.1  2007/11/28 03:28:13  plynch
// Changes for the reminder messages.
//

/**
 *  A class for managing a collection of messages to be shown to the user
 *  (probably all at once).  This relies on popups.js for showing the messages.
 */
Def.MessageManager = Class.create();
Object.extend(Def.MessageManager.prototype, {

  /**
   * Form name to be used for this popup.  Substitution for the form_name
   * that is available for forms defined in the forms table.
   */
  POPUP_FORM_NAME_ : "messages",

  /**
   *  The constructor.  (See Prototype's Class.create method.)
   * @param control (Optional.)  This can be an HTML control associated with the
   *  manager.  If provided, the HTML control will be disabled when there are
   *  no messages.
   */
  initialize: function(control) {
    this.control_ = control;
    if (this.control_) 
      this.control_.disabled = true; // start out with no messages
    
    // Instance variables get defined here.  (If you define them on the
    // prototype, they are class variables shared between instances.)
    
    // A hash of message keys to messages.
    this.messageMap_ = {};
  
    // A list of message keys, in the order in which they were given to the
    // message manager.
    this.messageKeys_ = [];
    
    // The keys of reviewed messages
    this.reviewedMessageKeys_ = [];
  
    // The messages that have been formatted in HTML for display
    this.formattedMessages_ = null;
    
    // The attribute name for the key of a message found in formattedMessages_ 
    // variable
    this.keyAttribute_ = "messageKey";
    
    // Link to the function for refreshing the display of unreviewed message 
    // number on the count button. The function should be defined in the form 
    // specific JavaScript file in order to make sure the customized function 
    // works on the specified form only. The parameter of the linked function is
    // the message manager JavaScript object
    this.REFRESH_COUNT_BUTTON = Def.refreshCountButton;
    
    // The id_shown of a user profile. It is used as profile identifier when
    // updating keys of reviewed messages on the server side
    this.idShown_ = null;

    // The date reminders being generated
    this.createdOn_ = null;
  },
  

  /**
   * Get the number of existing messages
   */
  getMessageCount: function() {
    return this.messageKeys_.length;
  },


  /**
   *  Adds a message under the given message key.  If a message with the same
   *  key was already in the manager, the previous message will be replaced,
   *  but its order in the message list will be retained for the new message.
   */
  addMessage: function(key, message) {
    if (this.control_ && this.messageKeys_.length == 0) {
      // Re-enable the control
      this.control_.disabled = false;
    }
    if (this.messageMap_[key]==null)
      this.messageKeys_.push(key);
    this.messageMap_[key]=message;
    if(this.formattedMessages_)
        this.formattedMessages_ = null;
  },
  
    
  /**
   *  Deletes the message with the given key from the manager.
   */
  removeMessage: function(key) {
    // Remove the key from the key list.
    var found = false;
    for (var i=0, len=this.messageKeys_.length; i<len && !found; ++i) {
      if (this.messageKeys_[i] == key) {
        found = true;
        this.messageKeys_.splice(i, 1);
      }
    }
    if (this.control_ && this.messageKeys_.length == 0) {
      // Disable the control
      this.control_.disabled = true;
    }    
    delete this.messageMap_[key];
    
    // Run the message onRemove handler
    this.messageOnRemove(key);

    if(this.formattedMessages_)
      this.formattedMessages_ = null;
  },
  
  
  /**
   *  Returns the message with the given key, or null if no such message
   *  exists.
   */
  getMessage: function(key) {
    return this.messageMap_[key];
  },
  
  
  /**
   *  Returns a list of all messages added to the manager, in the order in
   *  which the keys were added.
   */
  getAllMessages: function() {
    var rtn = [];
    for (var i=0, len=this.messageKeys_.length; i<len; ++i) {
      rtn.push(this.messageMap_[this.messageKeys_[i]]);
    }
    return rtn;
  },
  
 
  /**
   *  Displays all the messages in a popup window
   *      
   *  @param title the title of the message window.
   */  
  showAllMessages: function(title) {

  // Add a form opened usage event, and then go ahead and send it (and
  // any others that haven't been sent) to the server.  If we just add it,
  // then it will get sent at some point in the future by the PHR Home
  // page, and will not have a profile id on it (because the PHR Home page
  // has multiple profiles on it.
   
    Def.UsageMonitor.add('form_opened', {"form_name":title,
                                         "form_title":title}) ;
    Def.UsageMonitor.sendReport(this.idShown_);

    
    var popupContentHash = {};
    popupContentHash["text"] = this.formatMessages();
    popupContentHash["script"] = "<script> Def.DataModel.id_shown_ = \""+ this.idShown_ +"\"; </script>";
    var popupContent = Object.toJSON(popupContentHash);

    var popup = openPopup(window, popupContent, title, "height=700,width=550",
                          "message_manager");
    if(popup) {
      // Popup window should know the reminder message on the main window
      popup.reminderManager_ = this;
      Def.lastPopupWindow_ = popup;
    }
  },
  
  
  /**
   * Returns all messages in an HTML page with the class names listed as follows:
   *      div.group_title
   *      div.truncatable div.odd/even
   *        div.r_title
   *        div.r_text
   *      ...
   */
  formatMessages: function(){
    if(this.formattedMessages_ == null){
      var truncatableClass = typeof(HtmlTruncator)=='undefined' ? null : 
        HtmlTruncator.TRUNCATABLE_CLASS;

      // Sort message keys by their values
      var mm = $H(this.messageMap_).toArray();
      var mm = mm.sort(function(){return arguments[0][1]> arguments[1][1]});
      var sortedMsgKeys = $A(mm).map(function(e){return e[0]});
      
      var messages={"unread":[], "read":[]}
      for(var i=0,max=sortedMsgKeys.length;i<max;i++){
        var key = sortedMsgKeys[i];
        var msg = this.messageMap_[key];
        // Remove <br> between title and message text
        msg = msg.gsub("<br>","");
        // Add style via class names 
        if(msg.indexOf("</b>") > 0){
          msg = msg.gsub("<b>","<div class='r_title'>");
          msg = msg.gsub("</b>","</div><div class='r_text'>");
          msg +="</div>";
        }
        var msgStatus = this.isReviewedMessage(key) ? "read" : "unread";
        var classes = [];
        classes.push(truncatableClass ? truncatableClass : "");
        classes.push(msgStatus);
        msg = '<div '+ this.keyAttribute_+'="' + key + '"' + 
        ' class="'+ classes.join(" ")+'"'+ 
        '>' + msg + '</div>';
        messages[msgStatus].push([msg,key]);
      }
      for (var msgStatus in messages) {
        if (messages[msgStatus].length > 0) {
          if (this.formattedMessages_ == null)
            this.formattedMessages_ = "";
          this.formattedMessages_ += this.populateMessagesToTableRows(msgStatus, messages[msgStatus]) 
        }
      }
      var dateCreated = this.createdOn_ || (new Date()).toString();
      this.formattedMessages_ = "* Created on " + dateCreated + this.formattedMessages_
    } 
    return this.formattedMessages_;
  },
  
  
  /**
   * Returns a table with rows of reminders with a checkbox attached in HTML
   *
   * @param msgStatus the read/unread status of a reminder message
   * @param list the list of reminders of the same status (i.e. either 'read' or 'unread')
   */
  populateMessagesToTableRows: function(msgStatus, list){
    if (list.length > 0) {
      switch(msgStatus) {
        case "read":
          var title =  "Read";
          var helper_text = "Check to mark as unread";
          break;
        case "unread":
          var title = "Unread";
          var helper_text = "Check to mark as read";
          break;
      }

      var rtn = [];
      rtn.push("<table class='"+msgStatus+"_table' cellpadding='0.01'><body>");
      rtn.push("<tr><td colspan='2'>"+'<div class="group_title">'+title+'</div>');
      rtn.push('<div class="helper_text">'+helper_text+'</div>');
      rtn.push("</td></tr>");
      for(var i=0, max=list.length; i<max; i++) {
        rtn.push("<tr>");
        rtn.push("<td class='r_checkbox'><input type='checkbox' messageKey='"+list[i][1]+"' onclick='Def.checkboxClick(this)' title='"+helper_text+"'></td>");
        rtn.push("<td>"+list[i][0]+"</td>");
        rtn.push("</tr>");
      }
      rtn.push("</body></table>");
      return rtn.join("");
    }
    else{
      return '';
    }
  },
  
  
  /**
   * For an unread message, when the checkbox is unchecked, the message click 
   * event handler will do the following things:
   * 1) Update reviewed status variable on the client side
   * 2) Update the number of the un-reviewed messages showing on the PHR form
   * 3) Save the information of which messages have been reviewed to the database 
   * 4) mark the checkbox as checked 
   *  
   * @param clickedTruncatedNode the clicked truncated node
   */
  messageOnClick: function(clickedTruncatedNode){
    if (clickedTruncatedNode.hasClassName("unread")) {
     var reviewedMsgKey = this.getMessageKey(clickedTruncatedNode);
      var win = Def.getWindow(clickedTruncatedNode);
      var checkbox = win.$$("[type=checkbox][messageKey="+reviewedMsgKey+"]")[0];
      if (checkbox.checked != 1) {
        // Update message status
        this.markReviewedMessage(reviewedMsgKey);
        // Update the number of un-read reminder messages
        this.refreshNumberOfUnreviewedMessages();      
        // Update the status of clicked health reminders on the server
        this.updateReviewedStatusOnServer();
        // Mark the checkbox as checked
        checkbox.checked= 1
      }
    }
    return false;
  },
  
  
  /**
   * Updates the un-reviewed message count
   * 
   * @param countButton the button which shows the unreviewed message count
   */
  refreshNumberOfUnreviewedMessages: function(){
    // defined on form specific JavaScript file. The function can be used for
    // customizing the behavior of this function on different forms
    if (typeof this.REFRESH_COUNT_BUTTON === "function") {
      this.REFRESH_COUNT_BUTTON(this); 
    }
    else {
      // Default way of updating the display of unreviewed message counts
      var countButton = this.control_;
      if (countButton) {
        var count = this.getUnreviewedMessageCount();
        Def.updateMessageCount(countButton, count);
      }
      else {
        throw("The anchor for displaying the number of unreviewed messages"+
              " is missing.");
      }
    }
  },  
  
  
  /** 
   * Updates the status of reviewed health reminders on the server
   */
  updateReviewedStatusOnServer: function(){
    var url = "/form/update_reviewed_reminders";
    new Ajax.Request(url, {
      method: 'post',
      parameters: {
        authenticity_token: window._token,
        profile_id: this.idShown_,
        reviewed_reminders: Object.toJSON(this.reviewedMessageKeys_)
      },
      asynchronous: false
    });
  },
  
  
  /**
   * Check to see if this.messageMap_ and this.reviewedMessageKeys_ are matched. 
   * If not, updates both the reviewedMessageKeys_ property and the related data 
   * stored on server side.
   */
  updateReviewedMessageInfo: function() {
    var currentKeys = this.reviewedMessageKeys_.clone();
    this.reviewedMessageKeys_=[];

    for(var i=0, max=currentKeys.length;i<max;i++){
      var key = currentKeys[i];
      if (this.messageMap_[key])
        this.markReviewedMessage(key);
    }
    if(Object.toJSON(this.reviewedMessageKeys_) != 
       Object.toJSON(currentKeys))
      this.updateReviewedStatusOnServer();
  },
  

  /**
   * Return true if the input key is associated with a reviewed message and 
   * vice versa
   * 
   *  @params key the key generated from a message 
   */
  isReviewedMessage: function(key) {
    return this.reviewedMessageKeys_.indexOf(key) != -1;
  },
  
  
  /**
   * Mark the message as a reviewed message when it is associated with the 
   * input key 
   * 
   * @params key the key generated from a message
   */
  markReviewedMessage: function(key) {
    var index = this.reviewedMessageKeys_.indexOf(key);
    if (index == -1) {
      this.reviewedMessageKeys_.push(key);
      if(this.formattedMessages_) 
        this.formattedMessages_ = null;
    }
  },
  
  
  /**
   * Unmark the message as a reviewed message when it is associated with the 
   * input key 
   * 
   * @params key the key generated from a message
   */
  unMarkReviewedMessage: function(key) {
    var index = this.reviewedMessageKeys_.indexOf(key);
    if (index != -1) {
      this.reviewedMessageKeys_.splice(index, 1);
      if(this.formattedMessages_) 
        this.formattedMessages_ = null;  
    }
  },
  
  
  /**
   * Returns the number of un-reviewed reminders
   **/
  getUnreviewedMessageCount: function() {
    return this.getMessageCount() - this.reviewedMessageKeys_.length;
  },

  
  /**
   * Function needs to be run after the input message was removed
   * 
   * @param msgRemoved the key of the reminder message being removed
   */
  messageOnRemove:function(msgRemovedKey){
    if (this.reviewedMessageKeys_.length > 0 ) {
      // Remove the message from the reviewed_reminders table if exists
      if (this.isReviewedMessage(msgRemovedKey)){
        // Update the message review status on client side
        this.unMarkReviewedMessage(msgRemovedKey);
        // Update the reviewed_reminders table on server
        this.updateReviewedStatusOnServer();
      }
      else { 
        // Update the display of un-reviewed reminders on client
        this.refreshNumberOfUnreviewedMessages();
      }
    }
  },
  
    
  /**
   * Return the key of the original reminder message defined in our reminder 
   * rule system
   * 
   * @param node a DOM node containing either complete reminder message or 
   * truncated reminder message
   */
  getMessageKey:function(node){
    return $(node).getAttribute(this.keyAttribute_);
  }
  
    
});


/**
 * Attaches message manager as defined in anchorMap using Ajax
 * 
 * @param anchorMap a hash from id_shown of a profile to an array which has 
 * anchorID, count button ID and message title. The keys of this hash are 
 * limited to the id_shown values of profiles of the current user. 
 */
Def.attachMessageManagers = function(anchorMap) {
  var pids = Object.keys(anchorMap);
  var url = "/phr_records/message_managers";
  var stime = (new Date().getTime());
  Def.Logger.logMessage(["Start Ajax request ",url,"..."]);
  new Ajax.Request(url,
  {
    method: 'get',
    onSuccess: function(response){
      Def.Logger.logMessage(["Ajax request was successfuly completed in ", 
        (new Date().getTime() - stime)," ms "]);
      
      var msgs = eval('(' + response.responseText + ')')[0]; 
      stime = new Date().getTime();
      Def.completeMessageManager(msgs, anchorMap);
      Def.Logger.logMessage(["Attaching message managers was done in: ",
        (new Date().getTime() - stime)," ms"]);
    }, 
    onFailure: function(t){
      try {
        throw ('Error ' + t.status + ' -- ' + t.statusText) ;
      } 
      catch (e) {
        Def.reportError(e);
        Def.showError(
          "We're sorry, but we were unable to retrieve reminder messages "+
          "for your profiles. Everything else should work fine."+
          " We are aware of the problem and are working to fix it.") ;
      }
    }
  });
}



/**
 * Generate message manager object and attach it to the anchor. Also update the 
 * count button
 * 
 * @param allMsgs a hash from id_shown to the list containing the following two 
 * message manager properties: messageMap_ and reviewedMessageKeys_. The format 
 * should look like:
 *   { id_shown: [ messageMap_, reviewedMessageKeys_], ...}
 * @param anchorMap a hash from id_shown to the list containing anchor ID and 
 * count button ID. The format should look like:
 *   { id_shown: [ anchor_id, count_button_id], ... }
 */ 
Def.completeMessageManager = function(allMsgs, anchorMap){
  var idShownWoAnchors = [];
  for(var id_shown in allMsgs){
    var mapAndKeys = allMsgs[id_shown]; 
    var mMap  = mapAndKeys[0] || {};
    var mDate = mapAndKeys[1] || null;
    var mKeys = mapAndKeys[2] || [];

    // find the anchor based on id_shown and anchorMap
    var anchorInfo = anchorMap[id_shown];
    var anchor = null ;
    if (anchorInfo){
      var anchorId = anchorInfo[0];
      var countId = anchorInfo[1] || anchorId;
      var title = anchorInfo[2];
      anchor = $(anchorId);
    }
    
    if (anchor) {
      // Create new message manager
      var mm = new Def.MessageManager(anchor);
      // The date reminders being generated
      mm.createdOn_ = mDate;
      // Needed for updating the reviewed message status on server side
      mm.idShown_ = id_shown;
      // Needed for generating the messages and show them in a popup window
      mm.messageMap_ = mMap; 
      mm.messageKeys_ = Object.keys(mMap);
      mm.reviewedMessageKeys_ = mKeys;  
      // When there is no message, the clickable anchor should be disabled
      mm.control_.disabled = (mm.messageKeys_.length == 0);
      // The unreviewed message list from server side maybe out of sync with
      // client this.messageMap_, this function is to make sure they are in sync
      // It includes code for refreshing server side unreviewed message status.
      mm.updateReviewedMessageInfo();
      // Attach the message manager to the anchor
      anchor.messageManager_ = mm;
      anchor.observe('click', function(event) {
        this.messageManager_.showAllMessages( title || "Messages");
        return false;
      });
      // Update the display of unreviewd message count.
      mm.refreshNumberOfUnreviewedMessages();
    }
    else {
      idShownWoAnchors.push(id_shown);
    }// end of if(anchor)
  } // iterates through each profile
  if (idShownWoAnchors.length > 0)
    throw("Cannot find anchors for id_shown values: " + idShownWoAnchors.join("/"));
}


/**
 * Toggle the read/unread status of the attached reminder when
 * the checkbox was clicked
 *
 * @param ele the checkbox being clicked
 */
Def.checkboxClick= function(ele){
  var win= Def.getWindow(ele);
  var reminderMgr = win.reminderManager_;
  if(reminderMgr){
    var reviewedMsgKey = ele.getAttribute('messageKey');
    // Update message status
    if(!reminderMgr.isReviewedMessage(reviewedMsgKey)) {
      reminderMgr.markReviewedMessage(reviewedMsgKey);
    }else{
      reminderMgr.unMarkReviewedMessage(reviewedMsgKey);
    }
    // Run event handlers 
    // 1) Update the number of un-read reminder messages
    reminderMgr.refreshNumberOfUnreviewedMessages();      
    // 2) Update the status of clicked health reminders on the server
    reminderMgr.updateReviewedStatusOnServer();    
  }else{
    alert('messsage manager object not found');
  }
}

/**
 * Returns the window which has the input DOM element
 *
 * @param ele a DOM element inside a window 
 */
Def.getWindow = function(ele){
  var doc= ele.ownerDocument;
  return 'defaultView' in doc? doc.defaultView : doc.parentWindow;
}

