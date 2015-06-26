/**
 *  A class for displaying a printable view of PHR form.
 */
Def.PrintableView = Class.create();
Object.extend(Def.PrintableView.prototype, {
  /**
   *  The constructor.  (See Prototype's Class.create method.)
   */
  initialize: function() {
  },

  /**
   * open a printable view page for the entire form
   * @param event the event that triggered this action
   */
  openPrintableView: function(event) {
    // See http://www.alistapart.com/articles/printtopreview/
    var linkTags = document.getElementsByTagName("link");
    var button = event.target;
    if (button.inPrintableView == true) {
      for (var i=0, max=linkTags.length; i<max; ++i) {
        var tag = linkTags[i];
        if (tag.disabled == true)
          tag.disabled = false;
        else if (tag.wasPrint == true)
          tag.setAttribute('media', 'print');
      }
      button.inPrintableView = false;
    }
    else {
      button.inPrintableView = true;
      for (i=0, max=linkTags.length; i<max; ++i) {
        tag = linkTags[i];
        var media = tag.getAttribute('media');
        if (media == 'screen') {
          tag.disabled = true;
        }
        else if (media == 'print') {
          tag.wasPrint = true;
         tag.setAttribute('media', 'all');
        }
      }
    }
  }

});