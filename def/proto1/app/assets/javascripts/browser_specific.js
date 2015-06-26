// JavaScript needed for particular browsers.

if (BrowserDetect.IE) {
  // Look for all textarea tags with a maxlength setting, and add a listener
  // to enforce that.  (IE does not yet support the html5 textarea attribute
  // maxlength.)
  $J.getScript('/assets/maxlength.js', function() {
    setformfieldsize($J('textarea[maxlength]'));
  });
}
