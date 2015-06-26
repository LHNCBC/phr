// Set up a call to hideTheLastRowAndHiddenRows after the data has been loaded.
jQuery.connect(Def.DataModel, 'setup', Def.DateReminders,
    'customizeReminderTable');

// Update the due date reminder count when this window is closed.
Event.observe(window, 'beforeunload', function (e) {
  var windowOpener = Def.getWindowOpener(this);
  if (windowOpener.location.href.indexOf('edit') > -1)
    windowOpener.Def.PHR.setDueDateReminderCount();
});
