// JavaScript for logging.  Right now, we can only log if Firebug is enabled.

if (typeof Def == 'undefined') {
  Def = {};
}
  
Def.Logger = {}; // A namespace for logging methods

Object.extend(Def.Logger, {
  /**
   *  Logs an exception.
   */
  logException: function(e) {
    if (typeof console != 'undefined' && console.log !== undefined) {
      if (typeof Def.Rules != 'undefined' &&
          e instanceof Def.Rules.Exceptions.NoVal) {
        console.log(e.message);
      }
      else
        console.log(e);
    }
    // else do nothing; there is no way to report the exception without
    // rethrowing it, and only the caller knows whether that is appropriate.
  },
  
  /**
   *  Logs a message consisting of the given array of strings, which will
   *  be joined together.
   *
   *  @param msgParts - an array consists of all parts of log message
   *  @param needLog - decide whether we need to log the message
   *  @param logNow - log the time spending from the input start point to now
   */
   logMessage: function(msgParts, needLog, logNow) {
     if(logNow == undefined){
       logNow = false;
     }
     if(logNow == true){
       msgParts[1] = new Date().getTime()- msgParts[1];
       var lastMsg = msgParts.last()+ " ";
       if(lastMsg.indexOf("ms") == -1){
         msgParts.push(" ms");
       }
     }
     if(needLog == undefined){
       needLog = true;
     }
     if(typeof console != 'undefined' && console.log !== undefined && needLog) {
       console.log(msgParts.join(''));
      }
   }, // logMessage


   /**
    *  Logs a stack trace.
    */
   trace: function() {
     if (typeof console !== 'undefined' && console.trace !== undefined)
       console.trace();
   }

});
