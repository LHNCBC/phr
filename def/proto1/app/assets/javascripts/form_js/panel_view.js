// Set the window name here from the argument (window name) passed in
// from the showModalDialog call.  Do check to make sure we have the
// argument.  We won't if the current browser doesn't support the call.
if (window.dialogArguments) {
  window.name = window.dialogArguments[0] ;
}

// Set up a context menu after the page is loaded
Event.observe(window,"dom:loaded",function() {
  if (Def.formEditability_ !== Def.FORM_READ_ONLY_EDITABILITY)
    TestPanel.addContextMenuHTML();
});

// Update the due date reminder count when this window is closed.
Event.observe(window, 'beforeunload', function (e) {
  var windowOpener = Def.getWindowOpener(this);
  if (windowOpener && windowOpener.location.href.indexOf('edit') > -1)
    windowOpener.Def.PHR.setDueDateReminderCount();
});

jQuery.connect(Def.DataModel, 'setup', TestPanel,'updatePanelViewButtons');
jQuery.connect(Def.DataModel, 'setup', TestPanel,'updatePanelList');
