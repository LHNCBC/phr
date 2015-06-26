// Converted and modified from jQuery's truncator.js
HtmlTruncator = {

  /**
   * Default options for implementing show more or less feature
   */
  DEFAULT_OPTS:  {
    max_length: 90,
    more: '(more)',
    less: '(less)',
    lessDelimit: ' ',
    moreDelimit: " ... "
    
  },

  /**
   * Class name associated with webpage text which needs to be collapsible and
   * expandable
   */
  TRUNCATABLE_CLASS: 'truncatable',
  
  /**
   * Class name associated with the toggle link for expending or collapsing
   * webpage text
   */
  LINK_CLASS: "html_truncator_link", // see assets/stylesheets/help.css.erb

  /**
   * Returns true when there is a mark for truncating full version of the text
   * into a short one
   */
  foundMarker: false,

  /**
   * The mark for truncating the full version of the text into a short one
   */
  MARKER: "(more)",

  /**
   * Indicating whether there is a truncating mark in the ext
   */
  hasMarker: false,

  /**
   * A text node for cloning new text nodes located at the end of the shortened
   * text
   */
  textNode: null,


  /**
   * A link node for cloning new link nodes which can toggle full or shortened
   * text
   */
  linkNode: null,
  
  
  /**
   * Class name associated with a non-truncated reminder message (i.e. a full 
   * node)
   */
  FULL_NODE: 'full_node',


  /**
   * Class name associated with a truncated reminder message (i.e. a truncated 
   * node)
   */
  TRUNCATED_NODE: 'truncated_node',
  
  
  /**
   * A hash containing all the handlers for the onclick event of a truncated 
   * node  
   * /
  truncatedNodeOnclickHandlers : {},


  /**
   * Implements show more or less feature for specified webpage text
   * @param options customizable options for implementing show more or less feature
   */
  truncate: function(options){
    //alert("change 1b");
    //var s = new Date().getTime();

    // when inserting new node before an element of parts of the same classname,
    // the new node will appear in the parts. therefore convert parts into array
    var parts = $A(document.getElementsByClassName(this.TRUNCATABLE_CLASS));
    
    for(var i=0, max = parts.length; i<max; i++){
      var opts = Object.extend({}, this.DEFAULT_OPTS, options);
      var content_length = this.squeeze(parts[i].textContent).trim().length;
      
      if (content_length > opts.max_length){
        this.hasMarker = parts[i].textContent.indexOf(this.MARKER) > -1;
        this.foundMarker = false; 
        // if there is a mark, then search all the text until find the (more)
        // otherwise, tries to truncate around the specified length
        var actual_max_length = this.hasMarker ? parts[i].textContent.length :
        (opts.max_length - opts.more.length);

        var truncatedNode = this.recursivelyTruncate(parts[i], actual_max_length);
        truncatedNode.addClassName(this.TRUNCATED_NODE);
        var full_node = $(parts[i]).hide();
        full_node.addClassName(this.FULL_NODE);
        // if there is a mark in the text indicating the end of a short version
        // of this text, then remove this mark before displaying full version
        // of this text
        if(this.hasMarker){
          full_node.innerHTML = full_node.innerHTML.gsub(this.MARKER, "");
        }

        this.appendNode(full_node, truncatedNode);

        // appends "... (more)" at the end of the text
        this.appendTruncatedLine(truncatedNode, opts.moreDelimit, opts.more)
        // appends " (less)" at the end of the text
        this.appendTruncatedLine(full_node, opts.lessDelimit, opts.less)

        // setup onclick event listener for truncated node
        truncatedNode.onclick = function() {
          // Update clicked status 
//          if(!this.hasClassName('clicked')){
//            this.addClassName("clicked");
//            this.previous().addClassName("clicked");
//          }
          
          var handlers = HtmlTruncator.truncatedNodeOnclickHandlers;
          for(var h in handlers){
            handlers[h](this);
          }
          
          this.toggle();
          this.previous().toggle();
          return false;
        };
        
        // setup onclick event listener for full node
        full_node.onclick = function() { 
          this.next().toggle();
          this.toggle();
          return false;
        };
      }
    }

  /*
    Def.Logger.logMessage(
    [parts.length +" reminder messages have been truncated in ",
    (new Date().getTime())-s, " ms"]);
    */
  },

  getTitle: function(moreNode) {
    Def.Logger.logMessage(['getTitle called!']) ;
    var trunkie = null ;
    while (trunkie == null || !trunkie.hasClassName('truncatable'))
      trunkie = getAncestor(moreNode, 'DIV') ;
     
    var title = trunkie.getElementsByClassName('r_title')[0] ;
    return title.innerHTML ;
 
  } ,
  
  /**
   * Returns a node with its text content being truncated to specified length
   * and keep all other parts of the node intact
   * @param node original node for truncating
   * @param max_length the length of text allowed in the returning node
   */
  recursivelyTruncate: function(node, max_length) {
    return  (node.nodeType == 3) ? this.truncateText(node, max_length) :
    this.truncateNode(node, max_length);
  },

  /**
   * Returns a cloned non text node with its text being truncated to a
   * specified length
   *
   * @param node input non text node need to be truncated
   * @param max_length the length of text allowed of the returning node
   */
  truncateNode: function(node, max_length) {
    var node = $(node);
    var new_node = node.clone();
    var truncatedChild;
    var childNodes = node.childNodes;
    for(var i=0,max= childNodes.length;i<max;i++){
      if(this.hasMarker){
        if(this.foundMarker) break;
      }
      else{
        var remaining_length = max_length - new_node.textContent.length;
        if(remaining_length <= 0) break; // breaks the loop
      }
      truncatedChild = this.recursivelyTruncate(childNodes[i], remaining_length);
      if (truncatedChild) new_node.appendChild(truncatedChild);
    }
    return new_node;
  },


  /**
   * Returns a cloned text node with its text being truncated to a
   * specified length
   *
   * @param node input text node need to be truncated
   * @param max_length the length of text allowed of the returning node
   */
  truncateText: function(node, max_length) {
    var nodeText = node.data;
    // The text node which needs to be truncated for it is longer than max_length
    if(this.hasMarker){
      var markIndex = nodeText.indexOf(this.MARKER);
      this.foundMarker = markIndex > -1;
      var truncatedText = this.foundMarker ? nodeText.slice(0, markIndex) : nodeText;
    }
    else if(nodeText.length <= max_length){
      // The text node which does not need to be truncated since it isn't longer
      // than the max_length
      truncatedText = nodeText;
    }
    else{
      if(nodeText.charAt(max_length-1) == " " ||
        nodeText.charAt(max_length) == " "){
        truncatedText = nodeText.slice(0, max_length);
      }
      else{
        var spaceIndex = nodeText.slice(max_length).indexOf(" ");
        if(spaceIndex > -1){
          truncatedText = nodeText.slice(0, max_length + spaceIndex);
        }
        else{
          truncatedText = nodeText;
        }
      }
    }
    return document.createTextNode(truncatedText);
  },


  /**
   * Appends necessary text and links to the targetNode. For example, appends 
   * "... (more)" to the end of a truncated webpage paragraph where "(more)" is 
   * link for showing the full paragraph.
   * @param targetNode the node to be appended
   * @param prefixText the text needs to be appended in front of a link
   * @param linkText the text of a link which is used to togger show more or less
   */
  appendTruncatedLine: function(targetNode, prefixText, linkText){
    targetNode = targetNode.getElementsByClassName('r_text')[0];
    if(this.textNode != null){
      appendingTxtNode = this.textNode.cloneNode(true);
      appendingTxtNode.data = prefixText;
    }
    else{
      var appendingTxtNode = document.createTextNode(prefixText);
      this.textNode = $(appendingTxtNode).cloneNode(true);
    }
    targetNode.appendChild(appendingTxtNode);
    
    if(this.linkNode!=null){
      var appendingNode = this.linkNode.cloneNode(true);
      appendingNode.innerHTML = linkText;
    }
    else{
      var appendingNode = document.createElement('a');
      appendingNode.innerHTML = linkText;
      appendingNode.href = "javascript:void(0)";
      appendingNode.addClassName(this.LINK_CLASS);
      this.linkNode = $(appendingNode).cloneNode(true);
    }
    targetNode.appendChild(appendingNode)
  },


  /**
   * Appends targetNode to the sourceNode
   * @param sourceNode the node to be appended
   * @param targetNode the appending node
   */
  appendNode: function(sourceNode, targetNode){
    var nextNode = sourceNode.next();
    var parentNode = sourceNode.parentNode;
    nextNode ?
    parentNode.insertBefore(targetNode, nextNode) :
    parentNode.appendChild(targetNode);
  },


  /**
   * Collapses a sequence of whitespace in a string into a single space
   * @param string an input string
   */
  squeeze: function(string){
    return string.replace(/\s+/g, ' ');
  } 

}


HtmlTruncator.truncatedNodeOnclickHandlers ={
  /**
   * Monitors the usage when the truncated node was clicked
   * @params el is a truncated node
   */
  monitorUsage: function(el){          
    var childNode = el.childNodes[0];
    Def.UsageMonitor.add('reminders_more',
                        {"topic":HtmlTruncator.getTitle(childNode)}) ;
  },


  /**
   * Runs the reminder onclick handler when the truncated node was clicked
   * @params el is a truncated node
   */
  reminderOnclick: function(el){
    var doc= el.ownerDocument;
    var win= 'defaultView' in doc? doc.defaultView : doc.parentWindow;
    var reminderMgr = win.reminderManager_;
    if(reminderMgr)
      reminderMgr.messageOnClick(el);
  }
}