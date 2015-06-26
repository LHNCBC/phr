var prototype = require('prototype') // modified prototype without DOM
, http = require('http')
, qs = require('querystring')
, fs = require('fs')
, path = require('path')
, url = require('url');
Object.extend(global, prototype);

// Name of the configuration file of the JavaScript Server
var configFile = "./config.json";
var configs = require(configFile);  

/**
* Lower the privilleges of node process to webserv for security concern 
*/
var process_group = configs.gid;
var process_user = configs.uid;
if (process_group) {
  process.setgid(process_group);
  console.log("New gid: " + process.getgid());
}
if (process_user) {
  process.setuid(process_user);
  console.log("New uid: " + process.getuid());
}

/**
 * List of variables needed for this JavaScript server:
 * 
 * 1) allowedHost: the host of any acceptable requests
 */
var allowedHost = "localhost"; 

/**
 * Variables retrieved from the JavaScript server configuration file (see the
 * variable configFile)
 * 
 * 1) hostname: host name of the JavaScript server
 * 2) port: port number of the JavaScript server
 * 3) urlPath: path of the uri for retrieving reminders from the JavaScript server
 */
var urlParts = url.parse(configs.uri);   
var hostname = urlParts.hostname
   ,port = urlParts.port
   ,urlPath = urlParts.path;
   

/**
 * Creates a JavaScript server
 */
http.createServer( function(req, res){
  try{
    // Only accept requests from specified host
    var reqHost = req.headers.host.split(":")[0];
    if ( !reqHost || reqHost != allowedHost)
      throw "This request:[" + req.headers.host + req.url + "] is not allowed";
    var startTotal = new Date().getTime();
    // Only accept POST request
    if (req.method == 'POST') {
      console.log("[200] " + req.method + " to " + req.url);
      var body = "";    
      req.on('data', function(chunk) {
        body += chunk;
      });
    
      req.on('end', function() {
        var startParse = new Date().getTime();
        var data = qs.parse(body);
        var js_files = data.js_files;
        var profiles = data.profiles;
        // eval() won't work when the returned object is a Hash. But it works
        // okay with an Array 
        profiles = eval(profiles)[0]; 
        var pageView = data.page_view;
        var debug = data.debug;
        var durationParse = (new Date().getTime() - startParse);
        
        /////////////////////////////////////////////////////
        // Loads Javascript files including the generated one
        var startLib = new Date().getTime();
        // The following two lines are used to replace the original application.js 
        // file as it contains too much un-related codes and dependents on 
        // soundmanager2.js, and effects.js files
        Def = {};
        console.log("The page view is: " + pageView);
        Def.page_view = pageView;
        Def.deepClone = function(obj){
          return Object.toJSON(obj);
        };
        Def.IDCache = {};
        Def.IDCache.splitFullFieldID = function(id){
          return [];
        };
        console.log("Loading external JS libraries ...");
        console.log("js files are: " + js_files);
        var jsSources = js_files.split(",");
        for (i=0,max=jsSources.length; i<max; i++) {
          var strJs= jsSources[i];
          try {
            eval(fs.readFileSync(strJs, 'utf8'));
            var status = "FileLoaded";
          }
          catch(e){
            var status = "FileNotAvailable";
          }
          console.log( status + ": " + strJs );
        }
        var durationLib = (new Date().getTime()) - startLib;
        console.log("Loading external lib took " + durationLib  + " ms");
        // End of loading external js libs
        /////////////////////////////////////////////////////
      
        // Generates reminders  
        var rtn = '';
        if (profiles) {
          var rs = {};
          for (var profile_key in profiles) {
            var dataTable = profiles[profile_key];
            //if (dataTable) {
            // Loads Def.DataModel.taffy_db_ so that it can be used by the method
            // Def.DataModel.searchRecord used for running fetch rules
            var startT = new Date().getTime();
            Def.DataModel.setupTaffyDb(dataTable); 
            Def.DataModel.initialized_ = true;
            var durationTaffy = (new Date().getTime() - startT);

            var startR = new Date().getTime();
            // Specifies non DOM environment so that we can get the reminders from 
            // Def.Rules.messageManager
            Def.Rules.nonDOM_ = true;
            Def.Rules.runDataRules();
            // Collects reminders
            Def.Rules.processMessageQueue();
            var mm = Def.Rules.messageManager;
            rtn = mm.messageMap_;
            var durationR = (new Date().getTime() - startR);
            var durationTotal = (new Date().getTime() - startTotal);

            if (debug){
              var debugStr = [
              "************************************************************",
              "Reminders Information generated at " + (new Date().toString())
              , "Getting parameters took " + durationParse + " ms"
              , "Running rules took " + durationR + " ms"
              , "Loading taffydb took " + durationTaffy + " ms"
              , "Total js server request time " + durationTotal + " ms"];
              // js server logging
              console.log(debugStr.join("\n"));
              // attach the debug message to the top of the returned web page
              debugStr = debugStr.join("<br/>");
              debugStr = [ "<div>", debugStr, "</div><br/>"].join("");
            }
            var creationDate = (new Date()).toString();
            rs[profile_key] = [rtn, creationDate, debugStr];
          }
          // Directly convert a stringified json hash back to object using
          // JSON.parse not working, but it works okay with any stringified 
          // array 
          rtn = JSON.stringify([rs]);
        }
        else {
          rtn = "User data is missing."
        }
        // Sends back the response to browser
        res.end(rtn);    
      });
    } else {
      console.log("[405] " + req.method + " to " + req.url);
      res.writeHead(405, "Method not supported", {
        'Content-Type': 'text/html'
      });
      res.end('<html><head><title>405 - Method not supported</title></head>'+
        '<body><h1>Method not supported.</h1></body></html>');
    }
  } catch (e) { 
    console.log(e);
    res.end(e);
  } 
}).listen(port, hostname, urlPath);
console.log('Server running at http://'+ hostname +':' + port +  urlPath);
// end of creating a JavaScript server
  
