//  // Set the window name here from the argument (window name) passed in
//  // from the showModalDialog call.  Do check to make sure we have the
//  // argument.  We won't if the current browser doesn't support the call.
if (window.dialogArguments) {
  window.name = window.dialogArguments[0] ;
}

// Set up a call to updatePanelTemplate after the data has been loaded.
jQuery.connect(Def.DataModel, 'setup', TestPanel,'updatePanelTemplate');
// Add a left-click helper on the panel container element
jQuery.connect(Def.DataModel, 'setup', TestPanel,'addLeftClickHelper');

// Update the due date reminder count when this window is closed.
Event.observe(window, 'beforeunload', function (e) {
  var windowOpener = Def.getWindowOpener(this);
  if (windowOpener.location.href.indexOf('edit') > -1)
    windowOpener.Def.PHR.setDueDateReminderCount();
});
