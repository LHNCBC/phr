// Set up a call to hideTheLastRow after the data has been loaded.
jQuery.connect(Def.DataModel, 'setup', Def.DateReminders, 'hideTheLastRow');

// Refresh the due date reminder when this window is closed.
Event.observe(window, 'beforeunload', function (e) {
  var windowOpener = Def.getWindowOpener(this);
  if (windowOpener.location.href.indexOf('reminders') > -1)
    windowOpener.location.reload();
});
