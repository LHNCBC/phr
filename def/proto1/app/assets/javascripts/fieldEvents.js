// License:  This file should be considered to be under the terms of some
// "non-viral" open source license, which we will specify soon.  Bascially,
// you can use the code as long as you give NLM credit.
//
// $Log: fieldEvents.js,v $
// Revision 1.7  2011/06/29 13:50:54  taof
// bugfix: event.fireEvent() not working with IE9
//
// Revision 1.6  2011/05/13 19:28:13  taof
// required field validation not working in controlled edit table
//
// Revision 1.5  2009/12/22 22:22:43  plynch
// Changed splitFullFieldID so that its return value is cached, updated
// the code to be aware of that, and moved the function into idCache.js.
//
// Revision 1.4  2009/11/18 20:46:30  plynch
// initial
//

/**
 *  The FieldEvents namespace contains code for managing field events and
 *  field event handlers.
 */
Def.FieldEvents = {};

Object.extend(Def.FieldEvents, {

  /**
   *  Runs the change event observers for the given field(s).
   * @param fields the DOM field that has changed, or an array of such fields.
   */
  runChangeEventObservers: function(fields) {
    this.runEventObservers(fields, "change");
  },

  runEventObservers: function(fields, eventName) {
    if (!(fields instanceof Array))
      fields = [fields];
    var idCache = Def.IDCache;
    for (var j=0, max=fields.length; j<max; ++j) {
      var field = fields[j];
      var observers =
        Def.fieldObservers_[idCache.splitFullFieldID(field.id)[1]];
      if (observers) {
        observers = observers[eventName];
        if (observers) {
          for (var i=0, maxI=observers.length; i<maxI; ++i) {
            var observer = observers[i];
            // Bind the "this" to the element, and call the event handling 
            // function with a fake event object.
            observer.bind(field)({target: field});
          }
        }
      }
    }
  }

});
