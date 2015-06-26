// Code that should run after all the other JS files have been loaded.

// Put the split containers into the right place.
Def.formArea_ = $('vFormArea'); // initial value
/*Event.observe(window, 'load',
  function() {
    Def.formArea_ = $('vFormArea'); // initial value
    if (Def.formVSplit_) {
      $('vListArea').appendChild($('listAreaContent'));
      Def.formArea_.appendChild($('formContent'));

    }
    else {
      changeSplitDirection($('splitButtonControl'));
    }
    $('splitButton').style.visibility = 'visible';
  });*/  // We might not need this anymore

Event.observe(window, 'load', setUpReqInfoNotice) ;
(function() {
  var the_tables = document.getElementsByTagName('TABLE') ;
  for (t = 0; t < the_tables.length; ++t) {
    var rows_ct = the_tables[t].rows.length ;
    if (rows_ct > 0) {
      var high_id = the_tables[t].rows[rows_ct - 1].getAttribute('rowid') ;
      var next_id = parseInt(high_id) + 1;
      the_tables[t].setAttribute('nextid', next_id.toString()) ;
    }
  }
}());

// Start a timeout to periodically check for urgent system notices.
Def.Updater = {
  // The frequency of the updates
  UPDATE_CHECK_TIME: 10*60*1000, // 10*60*1000 = 10 minutes in ms

  // The base URL for the updates
  URL_BASE: '/form/get_session_updates?since=',
  
  // The epoch time of the last update, or (initially) the page load time.
  lastCheckTime_: new Date().getTime(),

  // Does one update,
  doUpdate: function() {
    new Ajax.Request(this.URL_BASE+this.lastCheckTime_, {
      method: 'get',
      onSuccess: function(transport) {
        var update = transport.responseText.evalJSON(true);
        var urgentNotice = update['urgent_notice'];
        if (urgentNotice) {
          window.alert(urgentNotice);
        }
      }
    });
    this.lastCheckTime_ = new Date().getTime();
  },

  // Does a periodic update
  doPeriodicUpdate: function() {
    this.doUpdate();
    setTimeout(this.doPeriodicUpdate.bind(this), this.UPDATE_CHECK_TIME);
  }
}
setTimeout(Def.Updater.doPeriodicUpdate.bind(Def.Updater),
           Def.Updater.UPDATE_CHECK_TIME);