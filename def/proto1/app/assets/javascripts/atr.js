/* JavaScript for that Acceptance Test Runner */

/**
 *  Adds a function to the String class for trimming white space.  This
 *  was copied from:  http://www.codingforums.com/showthread.php?p=178098
 */
String.prototype.trim=function(){
  return this.replace(/^\s*|\s*$/g,'');
}

/* Namespace for the Acceptance Test Runner */
ATR = {

  /** The default delay between test commands, in milliseconds. */
  COMMAND_DELAY: 50,

  /** The time to wait between retries. */
  RETRY_DELAY: 300,


  /* Manages a queue of functions to run. */
  FunctionQueue: {
    /**
     *  An array that holds the functions.  Each element should be an array
     *  consisting of a function and a time delay to wait before running the
     *  function.
     */
    functions_: [],

    /**
     *  True if the queue manager is running.
     */
    running_: false,

    /**
     *  An ID that gets incremented each time the queue starts running.
     *  This way, prior runs which start a new run can know that a new
     *  run has started and can stop themselves.
     */
    runID_: 1,

    /**
     *  Adds a function to the queue, and starts the queue running if it is
     *  not already.
     * @param call the function to run
     * @param waitTime the time to wait before running the function.
     */
    add: function(call, waitTime) {
      this.functions_.push([call, waitTime]);
      this.start(); // if it isn't already running
    },


    /**
     *  Prepends a function to the queue, so that the function will be the
     *  next one to run.
     */
    prepend: function(call, waitTime) {
      this.functions_.unshift([call, waitTime]);
    },


    /**
     *  Runs the next function (if there is one) by seting a timeout for it.
     * @param waitTime the amount of time in milliseconds to wait before running
     *  the function.  If not specified, ATR.COMMAND_DELAY will be used.
     */
    next: function(waitTime) {
      if (waitTime === undefined)
        waitTime = ATR.COMMAND_DELAY;
      var runID = this.runID_; // capture the current value
      setTimeout(function() {
        if (this.running_ && runID == this.runID_) {
          var nextData = this.functions_.shift();
          if (!nextData)
            this.running_ = false;
          else {
            var nextCall = nextData[0];
            var waitTime = nextData[1];
            // The queue might have been stopped and restarted while this
            // was sleeping, or from the prior function.  Do not continue
            // if that is the case; we don't want two threads of timeouts
            // going through the queue.
            try {
              this.currentFunction_ = nextCall;
              nextCall();
            }
            catch(e) {
              this.stop();
              console.exception(e);
            }
            // The run ID might have changed via nextCall, above (which
            // might have started the next test).
            if (this.running_ && runID == this.runID_) {
              this.next(waitTime); // Set a timeout for the next one
            }
          }
        }
      }.bind(this), waitTime);
    },


    /**
     *  Starts the queue running if it isn't already.
     */
    start: function() {
      if (!this.running_) {
        this.running_ = true;
        ++this.runID_;
        this.next();
      }
    },


    /**
     *  Stops the queue.  If a timeout has been set, it will still fire.
     */
    stop: function() {
      this.running_ = false;
    },


    /**
     *  Pushes the currently executing (or most recent) function back onto the
     *  stack.
     * @param delay the time to wait before executing.
     */
    replayCurrent: function(delay) {
      this.prepend(this.currentFunction_, delay);
    },


    /**
     *  Stops the queue and empties it.
     */
    reset: function() {
      this.stop();
      this.functions_.length = 0; // empty the array.  For discussion see
      // http://stackoverflow.com/questions/1232040/how-to-empty-an-array-in-javascript
    }

  },


  /**
   *  True if the browser allows script-generated keypress events to
   *  generate the default action (i.e. to put the character in the field.)
   *  Currently we are only running this on Firefo 3.6 and 4; we can
   *  expand the test later.
   */
  keypressFillsField_:
    navigator.userAgent.indexOf('Firefox/3.6') != -1,

  /**
   *  The file name of the file containing the current test script.
   */
  currentTestFile_: null,

  /**
   *  A hash of the data variables stored by the current test script.
   */
  testData_: {},

  /**
   *  Whether the last key event issued was canceled.
   */
  keyEventCanceled_: false,

  /**
   *  The time at which a currently executing waitFor call
   *  was begun, or null if no such call is currently running.
   */
  waitForStartTime_: null,

  /**
   *  The current timeout setting (in ms) for the waitFor commands.
   */
  timeout_: 30000,

  /**
   *  The current state of the control key (down or up)
   */
  controlKeyIsDown_: false,

  /**
   *  The current state of the shift key (down or up)
   */
  shiftKeyIsDown_: false,

  /**
   *  The time at which selectByConentCmd started if that command is
   *  running; otherwise null.
   */
  inSelectByContentCmd_: null,

  /**
   *  A set of the supported test commands, implemented as a hash map.
   *  When a new test command is added, it needs to be added to this
   *  map.
   */
  validCommands_: {
    click:  true,
    clickDate:  true,
    controlKeyDown: true,
    controlKeyUp: true,
    mouseUp: true,
    mouseDown: true,
    fireEvent: true,
    goBack: true,
    keyDown: true,
    keyPress: true,
    keyUp: true,
    open:  true,
    pause: true,
    selectByContent: true,
    selectByIndex: true,
    setTimeout: true,
    shiftKeyDown: true,
    shiftKeyUp: true,
    storeElementHeight: true,
    storeElementPositionTop: true,
    storeExpression: true ,
    type:  true,
    typeKeys: true,
    typeText: true,
    verifyButtonEnabled: true,
    verifyEditable: true,
    verifyElementHeight: true,
    verifyElementPositionTop: true,
    verifyElementPresent: true,
    verifyExpression: true,
    verifyFieldHasList: true,
    verifyTextPresent: true,
    verifyValue: true,
    verifyValueInFieldList: true,
    verifyValuesMatch: true,
    verifyVisible: true
  },


  /**
   *  Sets the "testWindowLoaded_" flag to true to indicate that the
   *  test window has loaded its content.  (This is used for the open
   *  command.)
   */
  setWindowLoaded: function() {
    this.testWindowLoaded_ = true;
  },


  /**
   *  Handles a click on the Run All button.
   */
  handleRunAll: function() {
    this.curTestSuiteIndex_ = 0;
    this.resetTestState();
    this.runAll();
  },


  /**
   *  Handles a click on the Run From Next button.
   */
  handleRunFromNext: function() {
    this.startNextTest();
  },


  /**
   *  Handles a click on one of the test buttons.
   * @param testFile - the file name containing the script for this button's
   *  test.
   */
  handleTestButton: function(testFile) {
    // Stop any running tests
    // Clear the state of the test and run it.
    this.resetTestState();
    this.runningAll_ = false;
    this.curTestSuiteIndex_ = this.testSuiteFiles_.indexOf(testFile);
    if (this.currentTestFile_!=testFile) {
      // Just show the test commands.  The user might be clicking to see the
      // results of the last run.
      this.currentTestFile_ = testFile;
      this.showTestSection(testFile);
    }
    else {
      this.runTest(testFile);
    }
  },


  /**
   *  Resets the test state information (except for the index of the
   *  current test suite, and the flag about whether we are running all
   *  the tests.)
   */
  resetTestState: function() {
    this.curTestCommandIndex_ = 0;
    this.openStartTime_ = null;
    this.waitForStartTime_ = null;
    this.handlingPauseCmd_ = false;
    this.testData_ = {};
    this.failCount_ = 0;
    ATR.FunctionQueue.reset();
    // Set the window in which the page being tested is displayed.  This probably
    // should be ATR.testWindow_, but we have tests referencing "testWindow_".
    if (testWindow_ && testWindow_ != window.frames['testWin'])
      testWindow_.close();
    testWindow_ = window.frames['testWin'];
    $('testWinFrame').style.display = 'block'; // starts out hidden
  },


  /**
   *  Returns the button element that runs the test with the given
   *  test file name.
   * @param testfile the file name for the test
   */
  getTestButton: function(testfile) {
    return $(testfile+'_button');
  },


  /**
   *  Reports the results of the test back to the acceptance controller.
   */
  reportResults: function() {
    // Construct the URL
    var url = document.location.href
    var questionMark = url.indexOf('?');
    if (questionMark >= 0)
      url = url.substr(0, questionMark); // remove the parameters
    url += '/../report_results?';
    for (var i=0, max=this.testSuiteFiles_.length; i<max; ++i) {
      var testfile = this.testSuiteFiles_[i];
      var testButton = this.getTestButton(testfile);
      var result = testButton.className == 'button_success' ? 'PASS' :
        'FAIL';
      if (i != 0)
        url += '&';
      url += testfile + '=' + result;
    }

    // Make the AJAX call.
    new Ajax.Request(url);
  },


  /**
   *  Run all of the tests from the current test index.
   */
  runAll: function() {
    this.runningAll_ = true;
    this.runTest(this.testSuiteFiles_[this.curTestSuiteIndex_]);
  },


  /**
   *  Starts the next test running, after stopping the current one (if any).
   */
  startNextTest: function() {
    if (this.curTestSuiteIndex_ === undefined)
      this.curTestSuiteIndex_ = 0;
    else
      ++this.curTestSuiteIndex_;
    this.resetTestState();
    this.runAll();
  },


  /**
   *  Run the given test.
   * @param testFile the name of the test file.  This should be a key
   *  for the testCommands_ hashmap.
   */
  runTest: function(testFile) {
    this.currentTestFile_ = testFile;
    var testButton = this.getTestButton(testFile);
    var commands = this.testCommands_[testFile];
    if (this.curTestCommandIndex_ == 0) {
      testButton.className = 'button_in_progress';
      this.resetTestSection(testFile);
      this.showTestSection(testFile);
    }
    var cmdRows = $(testFile + '_section').select('tr');
    this.currentTestCommandRows_ = cmdRows;

    // Trim any trailing comment "commands" so that the last command
    // can tell it is the last one.
    for (var i=commands.length-1; i>=0 && commands[i] == null; --i)
      commands.pop();

    if (commands.length == 0) // no commands in test!
      this.endOfTest();
    else {
      for (var max=commands.length; this.curTestCommandIndex_<max;
        ++this.curTestCommandIndex_) {

        var cmdArray = commands[this.curTestCommandIndex_];
        // Comment rows are represented by a null entry.
        if (cmdArray == null) continue;
        var cmd = cmdArray[0];
        var args = cmdArray.slice(1);

        // The function we run for the command is the cmd string plus
        // 'Cmd', except when cmd starts with "verifyNot", "assert",
        // or "assertNot", which we handle by calling the corresponding
        // verify command.  We set some flags here that indicate the
        // type of command.  We also compute the name of the command
        // that handles the command (if different).
        var verifyNot = false;
        var assertNot = false;
        var assert = false;
        var waitFor = false;
        var waitForNot = false;
        var cmdHandledBy = null;
        if (cmd.indexOf('verifyNot') == 0) {
          verifyNot = true;
          cmdHandledBy = 'verify'+cmd.substr(9);
        }
        else if (cmd.indexOf('assertNot') == 0) {
          assertNot = true;
          cmdHandledBy = 'verify'+cmd.substr(9);
        }
        else if (cmd.indexOf('assert') == 0) {
          assert = true;
          cmdHandledBy = 'verify'+cmd.substr(6);
        }
        else if (cmd.indexOf('waitForNot') == 0) {
          waitForNot = true;
          cmdHandledBy = 'verify'+cmd.substr(10);
        }
        else if (cmd.indexOf('waitFor') == 0) {
          waitFor = true;
          cmdHandledBy = 'verify'+cmd.substr(7);
        }
        else
          cmdHandledBy = cmd;

        var validCommand = this.validCommands_[cmdHandledBy];
        if (validCommand) {
          var cmdCall = this[cmdHandledBy+'Cmd'].bind(this);

          var flipRtn = waitForNot || verifyNot || assertNot;
          var cmdFunc = (function(cmdCall, args, flipRtn) {
            return function() {
              var rtn = cmdCall.call(this, args);
              return flipRtn ? !rtn : rtn;
            }
          })(cmdCall, args, flipRtn);

          if (waitFor || waitForNot) {
            this.queueRetryCmd(cmdFunc, this.curTestCommandIndex_, false);
          }
          else {
            if (assert || assertNot) {
              this.queueTestCmd(cmdFunc, this.curTestCommandIndex_, false);
            }
            else {
              this.queueTestCmd(cmdFunc, this.curTestCommandIndex_, true);
            }
          }
        }
        else
          throw "Invalid command: "+cmd;
      } // each test command
    }
  },


  /**
   *  Adds a test command to the queue.
   * @param testCall the function call for the test command.
   * @param testIndex the command index for the test, so we know which one
   *  gets its status updated after the test.
   * @param continueOnFail whether the tests should keep running if testCall
   *  does not pass.
   * @param delay the amount of time to wait before running the command
   *  after the previous one finishes.  This is optional, in which case
   *  COMMAND_DELAY is used as default.
   */
  queueTestCmd: function(testCall, testIndex, continueOnFail, delay) {
    // Re-use queueRetryCmd, but set the time limit to zero so there
    // is just one attempt.
    this.queueRetryCmd(testCall, testIndex, continueOnFail, 0, delay);
  },


  /**
   *  Prepends a test command to the queue, to be run next.
   * @param testCmdFn the function call for the test command.
   * @param testCmdIndex the command index for the test, so we know which one
   *  gets its status updated after the test.
   * @param continueOnFail whether the tests should keep running if testCall
   *  does not pass.
   * @param delay the amount of time to wait before running the command
   *  after the previous one finishes.  This is optional, in which case
   *  COMMAND_DELAY is used as default.
   */
  prependTestCmd: function(testCmdFn, testCmdIndex, continueOnFail, delay) {
    // Re-use queueRetryCmd, but set the time limit to zero so there
    // is just one attempt.
    this.queueRetryCmd(testCmdFn, testCmdIndex, continueOnFail, 0, delay, true);
  },


  /**
   *  Queues a function call that will continue to be attempted within
   *  the given timeLimit.
   * @param testCmdFn the function call for the test command.
   * @param testCmdIndex the command index for the test, so we know which one
   *  gets its status updated after the test.
   * @param continueOnFail whether the tests should keep running if testCall
   *  does not pass.
   * @param timeLimit the amount of time during which the command will be retried
   * @param delay the amount of time to wait before running the command
   *  after the previous one finishes.  This is optional, in which case
   *  COMMAND_DELAY is used as default.
   * @param prepend (optional) true if the new comand should be put at the start
   *  of the queue (i.e. run next).  The default is false.
   */
  queueRetryCmd: function(testCmdFn, testCmdIndex, continueOnFail, timeLimit, delay, prepend) {
    if (timeLimit === undefined)
      timeLimit = ATR.timeout_;
    if (delay===undefined)
      delay = this.COMMAND_DELAY;
    var startTime = 0;
    var runAndUpdateStatus = function() {
      this.curTestCommandIndex_ = testCmdIndex;
      if (startTime === 0) {
        // first attempt
        startTime = new Date().getTime();
        console.log('ATR:  test file: ' + this.currentTestFile_);
        console.log('ATR:  command index: ' + testCmdIndex);
        console.log('ATR: ' + this.currentTestCommandRows_[testCmdIndex].innerHTML);
        this.currentTestCommandRows_[testCmdIndex].className =
          'cmd_in_progress';
      }
      try {
        var rtn = testCmdFn();
      }
      catch(e) {
        console.log('ATR: Caught exception in queueRetryCommand');
        console.exception(e);
        rtn = false;
      }
      if (rtn !== null) { // rtn === null means do not update the status
        if (rtn) {
          var retry = false;
          // Update status to success
          this.currentTestCommandRows_[testCmdIndex].className =
            'cmd_success';
          // Scroll the test section to the currently completed element.
          this.getTestSection(this.currentTestFile_).scrollTop =
            this.currentTestCommandRows_[this.curTestCommandIndex_].offsetTop;
        }
        else {
          if (new Date().getTime() - startTime < timeLimit) {
            // Try again
            retry = true;
            ATR.FunctionQueue.prepend(runAndUpdateStatus, ATR.RETRY_DELAY);
          }
          else {
            // Update status to failed
            this.currentTestCommandRows_[testCmdIndex].className =
              'cmd_failure';
            ++this.failCount_;
          }
        }

        // If we are at the end of the test, set the test status and start
        // the next test if we are in the runningAll_ state.
        if (!retry &&
          (testCmdIndex==this.testCommands_[this.currentTestFile_].length-1 ||
            (this.failCount_ && !continueOnFail))) {
          this.endOfTest();
        }
      }
    }.bind(this);

    if (!prepend)
      ATR.FunctionQueue.add(runAndUpdateStatus, delay);
    else
      ATR.FunctionQueue.prepend(runAndUpdateStatus, delay);
  },



  /**
   *  Handles stuff that needs to be done at the end of a test.  Updates
   *  the button status color, and starts the next test or reports results
   *  as appropriate.
   */
  endOfTest: function() {
    // We might have stopped due to an error.  Stop the queue from running.
    ATR.FunctionQueue.reset();

    // Set the button status
    var testButton = this.getTestButton(this.currentTestFile_);
    if (this.failCount_==0)
      testButton.className = 'button_success';
    else
      testButton.className = 'button_failure';
    if (this.runningAll_) {  // then try to move to the next test
      var numTestSuites = this.testSuiteFiles_.length
      if (this.curTestSuiteIndex_ < numTestSuites - 1) {
        this.startNextTest();
      }
      else if (this.autoRun_) {
        // Report the results, since we have finished all of the tests
        reportResults();
      }
    }
  },


  /**
   *  Prepends a function call that will continue to be attempted within
   *  the given timeLimit.
   */
  prependRetryCmd: function(testCmdFn, testCmdIndex, continueOnFail, timeLimit, delay) {
    this.queueRetryCmd(testCmdFn, testCmdIndex, continueOnFail, timeLimit, delay, true);
  },


  /**
   *  Resets the status color of the test commands for the given test.
   * @param testFile the file name for the test
   */
  resetTestSection: function(testFile) {
    var rows = this.getTestSection(testFile).select('tr');
    for (var i=0, max=rows.length; i<max; ++i) {
      if (rows[i].className != 'comment')
        rows[i].className = '';
    }
  },


  /**
   *  Shows the list of commands for the given test, and hides the others.
   * @param testFile the file name for the test whose section should be
   *  shown.
   */
  showTestSection: function(testFile) {
    for (var otherTestFile in this.testCommands_) {
      if (otherTestFile != testFile) {
        this.getTestSection(otherTestFile).style.display = 'none';
      }
    }
    this.getTestSection(testFile).style.display = 'block';
  },


  /**
   *  Returns the element containing the HTML for the test script
   *  for the given test.
   * @param testFile the file name for the test
   */
  getTestSection: function(testFile) {
    return $(testFile+'_section');
  },


  /**
   *  Resumes the tests from the point at which they were last paused.
   */
  resumeTests: function() {
    if (this.runningAll_)
      this.runAll();
    else
      this.runTest(this.currentTestFile_);
  },


  /**
   *  Interprets a Selenium "locator" for an element, and returns the
   *  the element.  A locator can be an element's ID, or it can be
   *  a DOM expression starting with "dom=document.", or it can be a
   *  CSS expression starting with "css=", or it can be a special
   *  JavaScript expression to be used by evaluatedJS function, or it
   *  can be a dom object
   * @param locator the locator for the element.
   */
  interpretLocator: function(locator) {
    var rtn = null;
    if (typeof locator === 'string') {
      if (locator.length > 3 && locator.substr(0,3) == 'id=') {
        rtn = testWindow_.document.getElementById(locator.substr(3));
      }
      else if (locator.length > 4 && locator.substr(0,4) == 'dom=')
        rtn = eval('testWindow_.' + locator.substr(4));
      else if (locator.length > 4 && locator.substr(0,4) == 'css=') {
        var matches = testWindow_.$$(locator.substr(4));
        if (matches && matches.length == 1)
          rtn = matches[0];
      }
      else if (locator.length > 10 && locator.substr(0,10) == 'javascript')
        rtn = this.evaluateJS(locator);
      else { // Assume an ID
        rtn = testWindow_.document.getElementById(locator);
      }
    }
    else if (typeof locator === 'object') {
      if (testWindow_.oldDollar !== undefined)
        rtn = testWindow_.oldDollar(locator);
      else if (testWindow_.$ !== undefined)
        rtn = testWindow_.$(locator);
    }
    return rtn;
  },


  /**
   *  Evalates a value which might be a JavaScript expression.  If it
   *  detects the 'javascript{' wrapper, it calls evaluateJS; otherwise
   *  it just returns the value passed in.
   * @param val the value to be evaluated.
   */
  evaluateValue: function(val) {
    var rtn;
    if (val.indexOf('javascript{') == 0)
      rtn = this.evaluateJS(val);
    else
      rtn = val;
    return rtn;
  },


  /**
   *  Evaluates a JavaScript expression and returns its value.
   *  This assumes that the expression is prefixed with "javascript{"
   *  and suffixed with "}".
   * @param jsExp the expression to be evaluated.  It should start with
   *  "javascript{" and end with "}".    The expression
   *  may contain references to stored values using the syntax
   *  storedVars['someVariableName'].
   */
  evaluateJS: function(jsExp) {
    var js = jsExp.substring(11, jsExp.length-1);
    // Replace references to "storedVars" with testData_.
    js = js.replace(/storedVars/g, 'ATR.testData_');
    return eval(js);
  },


  /**
   *  Checks that a value matches a Selenium pattern.
   * @param val The value to check.  This should be a string.
   * @param pattern a Selenium "pattern".  Although this
   *  does not seem to be documented, it appears that a "pattern"
   *  can also be a JavaScript expression (at least sometimes).
   * @return true if val matches the pattern
   */
  patternMatch: function(val, pattern) {
    var pass = false;

    // Patterns can be one of three types.  See:
    // http://release.openqa.org/selenium-core/0.8.0/reference.html
    // The default is "glob".

    // Also, though not documented (at all?) patterns can apparently
    // have ${ var } strings in them which get replaced with a previously
    // stored value of variable "var".
    var varPattern = new RegExp('\\${([^}]+)}', 'g')
    pattern = pattern.replace(varPattern, function(str, p1) {
      return this.testData_[p1];
    });

    // Also not documented is that it can be a JavaScript expression
    // instead of a pattern.

    if (pattern.indexOf('regexp:') == 0) {
      // A regular expression
      pattern = pattern.slice(7); // remove 'regexp:'
      pass = new RegExp(pattern).test(val);
    }
    else if (pattern.indexOf('exact:') == 0) {
      pattern = pattern.slice(6); // remove 'exact:'
      pass = pattern == val;
    }
    else if (pattern.indexOf('javascript{') == 0) {
      // A JavaScript pattern
      pass = this.evaluateJS(pattern) == val;
    }
    else {
      // Assume glob.
      if (pattern.indexOf('glob:') == 0) {
        pattern = pattern.slice(5); // remove 'glob:'
      }
      // For a glob, we just have ? and *, but they are used like
      // on the command line.  To turn this into a regular expression,
      // we need to insert '.' in front of the pattern.
      // The Selenium documentation doesn't specify whether one of
      // these can be escaped, so for now I'm assuming they can't be.
      pattern = pattern.replace(/(\?|\*)/g, '.$1')
      // Also escape parentheses
      pattern = pattern.replace(/(\(|\))/g, '\\$1')
      // Require a match against the full string
      pattern = '^' + pattern + '$'
      pass = new RegExp(pattern).test(val);
    }

    if (!pass) {
      console.log('ATR:  value "'+val+'" failed to match pattern "'+pattern+'"');
    }
    return pass;
  },


  /**
   *  Interprets a Selenium "keySequence", and returns the character
   *  (ASCII) code.
   * @param keySeq A string containing a Selenium "keySequence", i.e.,
   *  either a single character or the decimal character code preceeded
   *  by a \ (e.g. \119 = w).
   * @return the integer character code, or null if the key sequence
   *  cannot be interpreted
   */
  interpretKeySequence: function(keySeq) {
    var rtn = null;
    if (keySeq.length == 1)
      rtn = keySeq.charCodeAt(0);
    else if (keySeq.charAt(0) == '\\') {
      rtn = parseInt(keySeq.substr(1));
    }
    return rtn;
  },


  /**
   *  Returns the IE key code for a given character.  In the case of
   *  numbers, this assumes the number pad was not used.
   * @param charCode the character code of a character (the unicode value).
   */
  ieKeyCode: function(charCode) {
    // See http://unixpapa.com/js/key.html
    var rtn = null;
    if (charCode >= 65 && charCode <= 90) // upper case letters
      rtn = charCode;
    else if (charCode >= 97 && charCode <= 122) // lower case letters
      rtn = charCode - 97 + 65;  // use upper case ASCII value
    else if (charCode >= 48 && charCode <= 57) // numbers
      rtn = charCode;
    else {
      switch (charCode) {
        case 33:  // !
        case 35:  // #
        case 36:  // $
        case 37:  // %
          rtn = charCode - 33 + 49; // ASCII for the corresponding numbers
          break;
        case 64:  // @
          rtn = 50; // ASCII for 2
          break;
        case 94:  // ^
          rtn = 6 + 48;  // ASCII for 6
          break;
        case 38:  // &
          rtn = 7 + 48;
          break;
        case 40:  // (
        case 41:  // )
          rtn = charCode - 40 + 9 + 48; // ASCII for 9 and 10
          break;
        case 58:  // :
        case 59:  // ;
          rtn = 186;
          break;
        case 43:  // +
        case 61:  // =
          rtn = 187;
          break;
        case 44:  // ,
        case 60:  // <
          rtn = 188;
          break;
        case 45:  // -
        case 95:  // _
          rtn = 189;
          break;
        case 46:  // .
        case 62:  // >
          rtn = 190;
          break;
        case 47:  // /
        case 63:  // ?
          rtn = 191;
          break;
        case 96:  // `
        case 126: // ~
          rtn = 192;
          break;
        case 91:  // [
        case 123: // {
          rtn = 219;
          break;
        case 92:  // \
        case 124: // |
          rtn = 220;
          break;
        case 93:  // ]
        case 125: // }
          rtn = 221;
          break;
        case 39:  // '
        case 34:  // "
          rtn = 222;
          break;
        default:
          rtn = charCode;
          break;
      }
    }
    return rtn;
  },


  /**
   *  Returns the Mozilla key code for a given character.  In the case of
   *  numbers, this assumes the number pad was not used.
   * @param charCode the character code of a character (the unicode value).
   */
  mozillaKeyCode: function(charCode) {
    // See http://unixpapa.com/js/key.html
    var rtn = null;
    if (charCode >= 65 && charCode <= 90) // upper case letters
      rtn = charCode;
    else if (charCode >= 97 && charCode <= 122) // lower case letters
      if (charCode == 113 && this.controlKeyIsDown_) { // F2
        rtn = charCode ;
      }
      else {
        rtn = charCode - 97 + 65;  // use upper case ASCII value
      }
    else if (charCode >= 48 && charCode <= 57) // numbers
      rtn = charCode;
    else {
      switch (charCode) {
        case 33:  // !
        case 35:  // #
        case 36:  // $
          rtn = charCode - 33 + 49; // ASCII for the corresponding numbers
          break;
        case 37: // % with shift key, else left arrow
          if (this.shiftKeyIsDown_)
            rtn = charCode - 33 + 49 ;
          else
            rtn = charCode ;
          break ;
        case 64:  // @
          rtn = 50; // ASCII for 2
          break;
        case 94:  // ^
          rtn = 6 + 48;  // ASCII for 6
          break;
        case 38:  // & with shift key, else up arrow
          if (this.shiftKeyIsDown_)
            rtn = 7 + 48;
          else
            rtn = charCode ;
          break;
        case 40:  // ( with shift key, else down arrow
          if (this.shiftKeyIsDown_)
            rtn = charCode - 40 + 9 + 48
          else
            rtn = charCode
          break;
        case 41:  // )
          rtn = charCode - 40 + 9 + 48; // ASCII for 9 and 10
          break;
        case 58:  // :
        case 59:  // ;
          rtn = 59;
          break;
        case 43:  // +
        case 61:  // =
          rtn = 61;
          break;
        case 44:  // ,
        case 60:  // <
          rtn = 188;
          break;
        case 45:  // -
        case 95:  // _
          rtn = 109;  // yes, 109, per Jan Wolter
          break;
        case 46:  // .
        case 62:  // >
          rtn = 190;
          break;
        case 47:  // /
        case 63:  // ?
          rtn = 191;
          break;
        case 96:  // `
        case 126: // ~
          rtn = 192;
          break;
        case 91:  // [
        case 123: // {
          rtn = 219;
          break;
        case 92:  // \
        case 124: // |
          rtn = 220;
          break;
        case 93:  // ]
        case 125: // }
          rtn = 221;
          break;
        case 39:  // ' with shift key, else right arrow
          if (this.shiftKeyIsDown_)
            rtn = 222 ;
          else
            rtn = charCode ;
          break ;
        case 34:  // "
          rtn = 222;
          break;
        default:
          rtn = charCode;
          break;
      }
    }
    return rtn;
  },


  /**
   * Determines if an element is visible, by checking computed style, not static
   * styles, which might be misleading if it's changed in CSS files
   *
   * @param elem the element to be tested for visibility
   * @return true if the element is hidden (display:none or visibility:hidden in
   *         computed style).
   *         false if the element is visible
   */
  isElementVisible: function(elem) {

    if (elem == testWindow_.document) return true;
    if (!elem) return false;
    if (!elem.parentNode) return false;

    if (elem.style && (elem.style.display == 'none' ||
                       elem.style.visibility == 'hidden') ||
                       elem.style.visibility == 'collapse') {
      return false;
    }
    //Try the computed style in a standard way
    else if (testWindow_.getComputedStyle) {
      var style = testWindow_.getComputedStyle(elem, "");
      if (style.display == 'none') return false;
      if (style.visibility == 'hidden' ||
          style.visibility == 'collapse') return false;
    }
    //Or get the computed style using IE's silly proprietary way
    else {
      var style = elem.currentStyle;
      if (style) {
        if (style['display'] == 'none') return false;
        if (style['visibility'] == 'hidden' ||
            style['visibility'] == 'collapse') return false;
      }
    }
    return this.isElementVisible(elem.parentNode);
  },


  /**
   *  Fires a key event.
   * @param args An array of two elements, the first of which should be
   *  a Selenium element "locator" (e.g. the ID of the element), and the
   *  second of which should be a Selenium keySequence (either a
   *  character or a \ followed by the decimal unicode number) to be typed.
   * @param eventName The name of the key event.  This should be either
   *  keypress, keydown, or keyup.
   * @return true if no problem was found with the arguments and the event
   *  was dispatched.
   */
  fireKeyEvent: function(args, eventName) {
    var pass = false;
    if (args.length == 2) {
      var elem = this.interpretLocator(args[0]);
      var evt = null;
      if (elem) {
        var charCode = this.interpretKeySequence(args[1]);
        this.keyEventCanceled_ = false;
        if (elem.fireEvent) {
          // IE
          evt = elem.createEventObject();
          if (eventName == 'keypress')
            evt.keyCode = charCode;
          else
            evt.keyCode = ieKeyCode(charCode);
          evt.ctrlKey = this.controlKeyIsDown_ ;
          evt.shiftKey = this.shiftKeyIsDown_ ;
          elem.fireEvent(eventName, evt);
        }
        else {
          // Assume Firefox
          evt = document.createEvent("KeyboardEvent");
          var keyCode;
          if (eventName == 'keypress')
            keyCode = 0;
          else { // keyup or keydown
            keyCode = this.mozillaKeyCode(charCode);
            charCode = 0;
          }

          // See http://developer.mozilla.org/en/docs/DOM:event.initKeyEvent
          // The following call was based on the example there.
          evt.initKeyEvent(
            eventName,         //  in DOMString typeArg,
            true,              //  in boolean canBubbleArg,
            true,              //  in boolean cancelableArg,
            null,              //  in nsIDOMAbstractView viewArg,
            this.controlKeyIsDown_, //  in boolean ctrlKeyArg,
            false,             //  in boolean altKeyArg,
            this.shiftKeyIsDown_,   //  in boolean shiftKeyArg,
            false,             //  in boolean metaKeyArg,
            keyCode,           //  in unsigned long keyCodeArg,
            charCode);         //  in unsigned long charCodeArg);
          var canceled = !elem.dispatchEvent(evt);
        }
        if (evt && evt.stopped)
          this.keyEventCanceled_ = true;
        pass = true;
      }
    }
    return pass;
  },


  //  Supported test commmands are below this comment.

  /**
   *  Changes the document location of the test window to point
   *  to a new URL. The URL could be a js expression.
   * @param args The arguments given to the command in the test script
   * @return true if the command executed successfully or if the
   *  function returns after scheduling a timeout.
   */
  openCmd: function(args) {
    var pass = false;
    if (args.length > 0) {
      if (!this.openStartTime_) {
        this.openStartTime_ = new Date().getTime();
        this.testWindowLoaded_ = false;
        var url = args[0];
        if (url.indexOf('javascript{')==0) {
          url = this.evaluateJS(url);
        }
        testWindow_.location = url;
      }

      // Wait for the window to load.  When we created the window,
      // we set up an onload function that sets testWindow_.loaded to
      // true.
      // Time out after some number of seconds
      // changed max time to see if fixes intermittent failures
      // in running tests
      if (new Date().getTime() - this.openStartTime_ < this.timeout_) {
        if (!this.testWindowLoaded_) {
          ATR.FunctionQueue.replayCurrent(ATR.RETRY_DELAY);
          pass = null;
        }
        else {
          pass = true;
          this.openStartTime_ = null;  // reset for the next open command
        }
      }
      else {
        this.openStartTime_ = null;  // reset for the next open command
      }
    }
    return pass;
  },


  /**
   *  Handles a pause command (as a part of a test script).
   *  Pauses execution of the tests for the given interval.
   * @param args The arguments given to the command in the test script.
   *  This should contain the time in milleseconds for the length of the
   *  pause in the run of the test commands.
   * @return true if the command executed successfully or if the
   *  function returns after scheduling a timeout.
   */
  pauseCmd: function(args) {
    var rtn = false;
    if (this.handlingPauseCmd_) {
      this.handlingPauseCmd_ = false;
      rtn = true;
    }
    else {
      this.handlingPauseCmd_ = true;
      var pauseTime = parseInt(args[0]);
      ATR.FunctionQueue.replayCurrent(pauseTime);
      rtn = null;
    }

    return rtn;
  },


  /**
   *  Clicks on the given element ID.
   * @param args The arguments given to the command in the test script.
   *  This should contain the ID of the element to which a click event
   *  should be sent.
   * @return true if the command executed successfully.
   */
  clickCmd: function(args) {

    // For some reason the click does not send a focus event, so we do that
    // here.
    var pass = this.fireEventCmd([args[0], 'focus']);
    if (pass && args.length > 0) {
      var elem = this.interpretLocator(args[0]);
      if (elem) {
        if (elem.fireEvent) {
          // IE
          elem.fireEvent('onclick')
        }
        else {
          // MouseDown and MouseUp event handlers are needed in order to
          // handle onmouseup event for BODY element
          var evt = testWindow_.document.createEvent("MouseEvents");
          evt.initMouseEvent('mousedown', true, true, testWindow_,
            0, 0, 0, 0, 0, false, false, false, false, 0, null);
          elem.dispatchEvent(evt);

          evt = testWindow_.document.createEvent("MouseEvents");
          evt.initMouseEvent('mouseup', true, true, testWindow_,
            0, 0, 0, 0, 0, false, false, false, false, 0, null);
          elem.dispatchEvent(evt);

          // Based on the example at:
          // http://developer.mozilla.org/en/docs/DOM:dispatchEvent_example
          evt = testWindow_.document.createEvent("MouseEvents");
          evt.initMouseEvent('click', true, true, testWindow_,
            0, 0, 0, 0, 0, false, false, false, false, 0, null);
          elem.dispatchEvent(evt);
        }
        pass = true; // it would nice to check the status, but not sure how
      }
    }
    return pass;
  },


  /**
   *  MouseDown on the given element ID.
   * @param args The arguments given to the command in the test script.
   *  This should contain the DOM/ID of the element to which a click event
   *  should be sent.
   * @return true if the command executed successfully.
   */
  mouseDownCmd: function(args) {
    var pass = false;
    if (args.length > 0) {
      var elem = this.interpretLocator(args[0]);
      if (elem) {
        if (elem.fireEvent) {
          // IE
          elem.fireEvent('onmousedown')
          pass = true; // it would nice to check the status, but not sure how
        }
        else
        {
          var evt = testWindow_.document.createEvent("MouseEvents");
          evt.initMouseEvent('mousedown', true, true, window,0, 0, 0,0,
            0,false, false, false, false, 0, null);
          elem.dispatchEvent(evt);
          pass = true; // it would nice to check the status, but not sure how
        }
      }
    }
    return pass ;
  },


  /**
   *  MouseUp on the given element ID.
   * @param args The arguments given to the command in the test script.
   *  This should contain the DOM/ID of the element to which a click event
   *  should be sent.
   * @return true if the command executed successfully.
   */
  mouseUpCmd: function(args) {
    var pass = false;
    if (args.length > 0) {
      var elem = this.interpretLocator(args[0]);
      if (elem) {
        if (elem.fireEvent) {
          // IE
          elem.fireEvent('onmouseup')
          pass = true; // it would nice to check the status, but not sure how
        }
        else
        {
          var evt = testWindow_.document.createEvent("MouseEvents");
          evt.initMouseEvent('mouseup', true, true, window,0, 0, 0,0,
            0,false, false, false, false, 0, null);
          elem.dispatchEvent(evt);
          pass = true; // it would nice to check the status, but not sure how
        }
      }
    }
    return pass ;
  },


  /**
   *  Sets the value of an input field.  This DOES NOT send key events.
   *  (Use typeKeys for that.)
   * @param  args The arguments given to the command in the test script.
   *  There should be one or two-- the ID of the field whose value is being
   *  set, and the new value.  If the new value is missing, the assigned
   *  value is the empty string.  The value may be a JavaScript expression
   *  enclosed in 'javascript{' and '}'.
   */
  typeCmd: function(args) {
    var pass = false;
    if (args.length > 0) {
      var elem = this.interpretLocator(args[0]);
      if (elem)
        elem.value = args.length > 1 ? this.evaluateValue(args[1]) : '';
      pass = true;
    }
    return pass;
  },


  /**
   *  Sets the value of an input field and sends the key events for the
   *  last character.  This is equivalent to using "type" with the
   *  value minus the last character, followed by "typeKeys" with the value
   *  of the last character.
   */
  typeTextCmd: function(args) {
    var pass = false;
    // Check for a blank, as we do with the typeCmd.  This is for those
    // of us who do not have enough memory space to remember to use
    // different text input commands - who need a one size fits all.  :)
    var fullVal = args.length > 1 ? this.evaluateValue(args[1]) : '';
    if (!fullVal || fullVal.length == 0)
      pass = this.typeCmd([args[0], fullVal])
    else {
      var fullValLen = fullVal.length;
      var typeVal = fullVal.slice(0, fullValLen-1);
      pass = this.typeCmd([args[0], typeVal]);
      if (pass) {
        var typeKeysVal = fullVal.slice(fullValLen-1, fullValLen)
        pass = this.typeKeysCmd([args[0], typeKeysVal]);
      }
    }
    return pass;
  },


  /**
   *  Emulates a keydown event.
   * @param args The arguments given to the command in the test script.
   *  There should be two-- the ID of the element to receive the keydown,
   *  set, and a string containing a Selenium "keySequence" (either a
   *  character or a \ followed by the decimal unicode number) to be typed.
   */
  keyDownCmd: function(args) {
    return this.fireKeyEvent(args, 'keydown');
  },


  /**
   *  Emulates a keyup event.
   * @param args The arguments given to the command in the test script.
   *  There should be two-- the ID of the element to receive the keydown,
   *  set, and a string containing a Selenium "keySequence" (either a
   *  character or a \ followed by the decimal unicode number) to be typed.
   */
  keyUpCmd: function(args) {
    return this.fireKeyEvent(args, 'keyup');
  },


  /**
   *  Emulates a keypress event.
   * @param args The arguments given to the command in the test script.
   *  There should be two-- the ID of the element to receive the keydown,
   *  set, and a string containing a Selenium "keySequence" (either a
   *  character or a \ followed by the decimal unicode number) to be typed.
   */
  keyPressCmd: function(args) {
    var elem = this.interpretLocator(args[0]);
    var elemVal = elem.value;
    var rtn = this.fireKeyEvent(args, 'keypress');

    // Work around a change/bug in Firefox 4, in which the events do
    // not result in the actual input field being updated.  This workaround
    // does produce correct behavior if the there is selected text
    // in the field (which should get erased by a keypress).  At the moment
    // it does not seem worth the effort to handle that.  See:
    // http://stackoverflow.com/questions/275761/how-to-get-selected-text-from-textbox-control-with-javascript
    // for a starting point if we need it.
    if (!this.keypressFillsField_ && args[1].charAt(0) != '\\')
      elem.value = elemVal + args[1];
    return rtn
  },


  /**
   *  Types keys at the specified element.  The sends keydown, keyup,
   *  and keypress events for each character in the specified string.
   * @param  args The arguments given to the command in the test script.
   *  There should be two-- the ID of the element to receive the keystrokes,
   *  set, and the string to be typed.  The value to be typed can be
   *  specified as a JavaScript expression wrapped in 'javascript{' and
   *  '}'.
   */
  typeKeysCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      var elemLocator = args[0];
      var str = this.evaluateValue(args[1]);
      pass = true;
      var callsToQueue = [];
      for (var i=0, max=str.length; i<max && pass; ++i) {
        // If the character is \ followed by some numbers, treat
        // that as a key sequence that should be passed together to
        // the key event methods.
        var keyArgs;
        var ch = str.charAt(i);
        var maxIndex = max - 1;
        if (i<maxIndex && ch == '\\') {
          ch = str.charAt(i+1);
          var j=i+1;
          for (; j<max && ch >= '0' && ch <= '9'; ++j) {
            if (j+1<maxIndex)
              ch = str.charAt(j+1);
          }
          keyArgs = [elemLocator, str.substring(i, j)];
          i = j - 1; // skip over the key sequence
        }
        else
          keyArgs = [elemLocator, str.substr(i, 1)];

        // Run the events.  For some reason, the key down and key press events
        // need to run together.  Without that, it seems that the keydown
        // listener does not get the updated value of the field (which happens
        // in keypress).  I would have expected that the key down listeners
        // would always fully run before the keypress fired, so I'm not sure
        // why this is.
        callsToQueue.push((function(keyArgs) {
          return function() {
            return this.keyDownCmd(keyArgs) && this.keyPressCmd(keyArgs)
          };
        })(keyArgs).bind(this));
        callsToQueue.push((function(keyArgs) {
          return function() {return this.keyUpCmd(keyArgs)};
        })(keyArgs).bind(this));
      }

      // Now prepend the queued tests in reverse order
      for (i=callsToQueue.length-1; i>=0; --i) {
        this.prependTestCmd(callsToQueue[i], this.curTestCommandIndex_,
          false);
      }
    }
    return null;
  },


  /**
   *  Causes an element to receive the given typeof event.  Supported
   *  events are:
   *  <ul>
   *    <li>blur</li>
   *    <li>focus</li>
   *  </ul>
   *  (But the current implementation might work for other events too.)
   *  For click events, use the 'click' command.
   * @param args  The arguments given to the command in the test script.
   *  There should be two-- the ID of the element receiving the event,
   *  and the event name.
   */
  fireEventCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      var elem = this.interpretLocator(args[0]);
      if (elem) {
        // Note:  Calling blur()/focus() on the elements does not work if
        // the window does not have the focus-- the fields don't receive
        // the events.  (At least not on Firefox 2.)
        // However, if we don't call them, but
        // just use fireEvent, etc. as below, the CSS :focus rules don't get
        // processed (at least not in Firefox 2).

        // Allow multiple events to be listed separated by commas (so we can fire
        // change and blur events without a delay between them).
        var eventNames = args[1].split(/,/);
        for (var i=0, num=eventNames.length; i<num; ++i) {
          var eventName = eventNames[i];
          // As of Firefox 17.0.3esr, calling blur() for blur events below
          // also causes the blur event listeners to be notified, so
          // for blur events we are no longer firing the event
          // ourselves.
          if (eventName != 'blur') {
            if (elem.fireEvent) {
              // IE
              var evt = elem.createEventObject();
              elem.fireEvent(eventName, evt);
            }
            else {
              // Assume Firefox
              // See http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-eventgroupings-htmlevents
              var evt = document.createEvent("HTMLEvents");
              evt.initEvent(eventName, true, true);
              var canceled = !elem.dispatchEvent(evt);
            }
          }
          // We're adding a call to focus() and blur() because in one of our
          // tests, the event fired above is received by our event handlers
          // but does not actually focus the field (though it normally does).
          if (eventName == 'focus')
            elem.focus() ;
          else if (eventName == 'blur') {
            elem.blur();
          }
          pass = true;
        }
      }
    }
    return pass;
  },


  /**
   *  Verifies that an element's value matches the given pattern.
   * @param  args The arguments given to the command in the test script.
   *  There should be two-- the ID of the field whose value is being
   *  checked, and the regular expression to match against.  If the second
   *  argument is not present, the element's value is checked against
   *  the empty string.
   */
  verifyValueCmd: function(args) {
    var pass = false;
    if (args.length >= 1) {
      var elem = this.interpretLocator(args[0]);
      if (elem) {

        if (elem.type === 'button')
          var elemValue = elem.textContent;
        else {
          if (Def && Def.getFieldVal)
            elemValue = Def.getFieldVal(elem).trim();
          else
            elemValue = elem.value.trim();
        }
        if (args.length > 1) {
          if (args[1].indexOf('javascript{')==0)
            pass = this.patternMatch(elemValue, this.evaluateJS(args[1]));
          else
            pass = this.patternMatch(elemValue, args[1]);
        }
        else
          pass = elemValue == '';
      }
      if (!pass) {
        var expectedVal = args.length>1 ? args[1] : '';
        Def.Logger.logMessage(["ATR:  Expected value '", expectedVal,
          "' but was '", elemValue,"'"]);
      }
    }
    return pass;
  },


  /**
   *  Verifies that an element exists on the page.
   * @param args The arguments given to the command in the test script.
   *  There should be one-- the ID of the element whose presence is
   *  being verified.
   */
  verifyElementPresentCmd: function(args) {
    var pass = false;
    if (args.length == 1) {
      pass = this.interpretLocator(args[0]) != null;
    }
    return pass;
  },


  /**
   *  Verifies that a given string appearas somewhere on the page.
   *  In order to pass, the string must appear between HTML tags
   *  (i.e. not inside them) and be outside of script tags.
   * @param args The arguments given to the command in the test script.
   *  There should be one-- the string whose presence is
   *  being verified.
   */
  verifyTextPresentCmd: function(args) {
    var pass = false;
    if (args.length == 1) {
      // Note:  If we want to skip tags, we cannot use body.innerHTML
      // for two reasons:
      // 1) On Firefox, things like &lt; that appear in tag attributes
      //    appear decoded in the innerHTML value.  This makes it impossible
      //    to remove tags.
      // 2) According to:
      //    http://developer.mozilla.org/en/docs/DOM:element.innerHTML
      //    the Firefox browser will not update innerHTML in response
      //    to values entered in fields.
      // However, we can skip tags by walking the DOM tree and checking
      // each text node.  We also need to check the values of the fields.

      var nodeTest = function(node) {
        var foundVal = false;
        if (node.nodeType == Node.ELEMENT_NODE) {
          if ((node.nodeName == 'INPUT' && node.type == "text")
            || node.nodeName == 'TEXTAREA') {
            foundVal = node.value.indexOf(args[0]) >= 0
          }
        }
        else if (node.nodeType == Node.TEXT_NODE) {
          foundVal = node.nodeValue.indexOf(args[0]) >= 0;
        }
        return foundVal;
      };

      var nodeSearch = function(node, nodeTest) {
        var foundVal = nodeTest(node);
        if (!foundVal) {
          if (node.nodeType == Node.ELEMENT_NODE) {
            // Iterate over the children
            var childNodes = node.childNodes;
            for (var i=0, max=childNodes.length; i<max && !foundVal;
                 ++i) {
              foundVal = nodeSearch(childNodes.item(i), nodeTest);
            }
          }
        }
        return foundVal;
      };

      pass = nodeSearch(testWindow_.document.body, nodeTest);
    }
    return pass;
  },


  /**
   *  Stores the height (offsetHeight) of an element.
   * @param args The arguments given to the command in the test script.
   *  There should be two-- a Selenium locator (e.g. an ID) for an element,
   *  and a variable name into which the height should be stored.
   */
  storeElementHeightCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      var elem = this.interpretLocator(args[0]);
      if (elem) {
        this.testData_[args[1]] = elem.offsetHeight;
        pass = true;
      }
    }
    return pass;
  },



  /**
   *  Stores an element's top cordinate relative to the top of the frame.
   * @param args The arguments given to the command in the test script.
   *  There should be two-- a Selenium locator (e.g. an ID) for an element,
   *  and a variable name into which the position should be stored.
   */
  storeElementPositionTopCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      var elem = this.interpretLocator(args[0]);
      if (elem) {
        this.testData_[args[1]] = this.getAbsY(elem);
        pass = true;
      }
    }
    return pass;
  },


  /**
   *  Verifies that an element is editable.  An element is not editable if
   *  it is not disabled.
   *
   * @param args The arguments given to the command in the test script.
   *  There should be one-- a Selenium locator (e.g. an ID) for the element
   *  whose visility is being verified.
   */
  verifyEditableCmd: function(args) {
    var pass = false;
    if (args.length == 1) {
      var elem = this.interpretLocator(args[0]) ;
      if (elem) {
        pass = elem.disabled == false ;
      }
    }
    return pass;
  },


  /**
   *  Verifies that the element has a height (offsetHeight) matching the
   *  given pattern.
   * @param args The arguments given to the command in the test script.
   *  There should be two-- a Selenium locator (e.g. an ID) for an element,
   *  and a Selenium pattern that the value of the height (as a string)
   *  should match.
   */
  verifyElementHeightCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      var elem = this.interpretLocator(args[0]);
      if (elem) {
        var elemHeight = elem.offsetHeight + ''; // convert to string
        var pattern = args[1];
        pass = this.patternMatch(elemHeight, pattern);
      }
    }
    return pass;
  },


  /**
   *  Verifies the value of a JavaScript expression.  The expression
   *  may contain references to stored values using the syntax
   *  storedVars['someVariableName'].
   * @param args The arguments given to the command in the test script.
   *  There should be two-- a Javascript expression with the prefix
   *  "javascript:{" and the suffix "}", and a Selenium pattern to compare
   *  with the output of the expression.
   */
  verifyExpressionCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      var js = args[0];
      if (js.indexOf('javascript{')==0) {
        var pattern = args[1];
        pass = this.patternMatch(this.evaluateJS(js), pattern);
      }
    }
    return pass;
  },


  /**
   * Stores the value of a Javascript expression with the prefix
   * "javascript{" and the suffix "}" in the testData hash.  The
   * value can be retrieved by using storedVars['keyname'] within
   * a javascript expression, e.g. javascript{storedVars['keyname']}
   */
  storeExpressionCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      var js = args[0];
      if (js.indexOf('javascript{')==0) {
        this.testData_[args[1]] = this.evaluateJS(js);
        pass = true;
      }
    }
    return pass;
  },

  /**
   *  Verifies that the top of an element is at a given position (relative
   *  to the top of the frame).
   * @param args The arguments given to the command in the test script.
   *  There should be two-- a Selenium locator (e.g. an ID) for an element,
   *  and a Selenium "pattern" that the top position value should match.
   */
  verifyElementPositionTopCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      var elem = this.interpretLocator(args[0]);
      if (elem) {
        var topPos = getAbsY(elem);
        var pattern = args[1];
        pass = this.patternMatch(topPos, pattern);
      }
    }
    return pass;
  },


  /**
   *  Verifies that an element is visible.  An element is not visible if
   *  either it or an ancestor node has visibility set to hidden or display
   *  set to none.
   * @param args The arguments given to the command in the test script.
   *  There should be one-- a Selenium locator (e.g. an ID) for the element
   *  whose visibility is being verified.
   */
  verifyVisibleCmd: function(args) {
    var pass = false;
    if (args.length == 1) {
      var elem = this.interpretLocator(args[0]);
      var visible = this.isElementVisible(elem);
      pass = visible == true;
    }
    return pass;
  },


 /**
   *  Verifies that a button element is enabled. An element is not visible if
   *  either it or an ancestor node has visibility set to hidden or display
   *  set to none.
   * @param args The arguments given to the command in the test script.
   *  There should be one-- a Selenium locator (e.g. an ID) for the button
   *  whose state is being verified.
   */
  verifyButtonEnabledCmd: function(args) {
    var pass = false;
    if (args.length == 1) {
      var elem = this.interpretLocator(args[0]);
      pass = elem.disabled == false ;
    }
    return pass;
  },


  /**
   *  Verifies that the contents of two elements on the page match.
   * @param args The arguments given to the command in the test script.
   *  There should be two Selenium locators (e.g. an ID) for the two
   *  elements whose values are being compared.
   *           */
  verifyValuesMatchCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      var elem1 = this.interpretLocator(args[0]);
      var elem2 = this.interpretLocator(args[1]);
      pass = elem1.value == elem2.value ;
    }
    return pass;
  },


  /**
   *  Sets the time limit used by the waitFor commands.
   * @param args The arguments given to the command in the test script.
   *  There should be one-- the new time limit.
   */
  setTimeoutCmd: function(args) {
    var pass = false;
    if (args.length == 1) {
      this.timeout_ = parseInt(args[0]);
      pass = true;
    }
    return pass;
  },


  /**
   *  Sets the state of the control key to "down" (active)
   */
  controlKeyDownCmd: function() {
    this.controlKeyIsDown_ = true ;
    return true;
  },

  /**
   *  Sets the state of the control key to "up" (not active)
   */
  controlKeyUpCmd: function() {
    this.controlKeyIsDown_ = false ;
    return true;
  },

  /**
   *  Sets the state of the shift key to "down" (active)
   */
  shiftKeyDownCmd: function() {
    this.shiftKeyIsDown_ = true ;
    return true;
  },

  /**
   *  Sets the state of the shift key to "up" (not active)
   */
  shiftKeyUpCmd: function() {
    this.shiftKeyIsDown_ = false ;
    return true;
  },

  /**
   * Clicks the browser's back button
   **/
  goBackCmd: function(){
    var pass = false ;
    testWindow_.history.back();
    pass = true;
    return pass;
  },


  /* Non-Selenium Commands Go Below This Comment */

  /**
   *  Selects an item from a list field.  This hides the complexity
   *  of having to wait for the right things to happen, which requires
   *  knowledge of our autocompletion code.  After this is run, if the
   *  list selection is succesful, no field will have focus.
   * @param args The arguments given to the command in the test script.
   *  There should be two-- a field ID (for the list field) and an index
   *  of the item in the list that is to be sected.
   */
  selectByIndexCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      try {
        var listIndex = parseInt(args[1]);
        var field = testWindow_.document.getElementById(args[0]);
        if (!field)
          Def.Logger.logMessage(['selectByIndex:  Element ',args[0],
            ' was not found']);
        else {
          var auto = field.autocomp;
          if (!auto) {
            Def.Logger.logMessage(['selectByIndex:  Element ', args[0],
              ' did not have an autocompleter']);
          }
          else {
            // The "seeMoreItemsClicked_" applies to prefetched lists,
            // and will prevent the list from being truncated.
            auto.seeMoreItemsClicked_ = true;
            this.fireEventCmd([args[0], 'focus']);
            auto.activate();
            auto.index = listIndex;
            auto.selectEntry();
            // Fire a change event on the field to let everything know
            // the field has changed.
            this.fireEventCmd([args[0], 'change']);
            this.fireEventCmd([args[0], 'blur']);
            pass = true;
          }
        }
      }
      catch (e) {
        Def.Logger.logException('selectByIndex failed:  ' +e);
      }
    }
    return pass;
  },


  /**
   *  Selects an item from a list field.  This hides the complexity
   *  of having to wait for the right things to happen, which requires
   *  knowledge of our autocompletion code.  After this is run, if the
   *  list selection is succesful, no field will have focus.
   * @param args The arguments given to the command in the test script.
   *  There should be two-- a Selenium locator (e.g. an ID) for the list
   *  field and the content to type typed into the field.  There should be
   *  enough content to reduce the list to one item, or at least to bring
   *  the desired item to the top of the list.
   */
  selectByContentCmd: function(args) {
    var pass = false;
    if (args.length == 2) {
      try {
        var field = this.interpretLocator(args[0]);
        var optionsULTag = testWindow_.document.getElementById('completionOptions').down();
        var autocomp = field.autocomp;
        if (!this.inSelectByContentCmd_) {
          this.selectByContentEnteredContent_ = false;
          this.inSelectByContentCmd_ = new Date().getTime();
          Element.simulate(field, 'focus');
          field.focus();
        }

        if (!this.selectByContentEnteredContent_) {
          // Type into the field to get the new list
          var itemContent = args[1];
          if (itemContent.indexOf('javascript{')===0) {
            itemContent = this.evaluateJS(itemContent);
          }
          // Store itemContent in a global variable in case the field
          // value goes away when the list is populated.
          this.selectByContentFieldValue_ = itemContent;
          var lastCharIndex = itemContent.length-1;
          var allButLastChar = itemContent.substr(0, lastCharIndex);
          this.typeCmd([field, allButLastChar]);
          // Now use typeKeys to queue key events. typeKeysCmd will add
          // events to the front of the queue, after which we want to run
          // this command again (after the events have happened).  So,
          // we prepend this one first, and then call typeKeysCmd.
          ATR.FunctionQueue.replayCurrent(50); // let the events happen,
          this.typeKeysCmd([field, itemContent.substr(lastCharIndex, 1)]);
          this.selectByContentEnteredContent_ = true;
          pass = null;
        }
        else {
          // Wait for the list to have an item that exactly matches the
          // entry, or for the list to have a length of one.
          if (new Date().getTime() - this.inSelectByContentCmd_ < this.timeout_) {
            if (optionsULTag===null) {
              ATR.FunctionQueue.replayCurrent(20);
              pass = null;
            }
            else {
              var foundMatch = false;
              var elemVal =
                this.selectByContentFieldValue_.trim().toLowerCase();
              if (field.value.trim()==='') {
                field.value = elemVal; // restore the value lost by the assignment of the field's list
              }
              if (autocomp.entryCount == 1) {
                foundMatch = true;
                autocomp.index = 0;
              }
              else {
                for (var i=0; i<autocomp.entryCount && !foundMatch; ++i) {
                  var liTag = autocomp.getEntry(i);
                  if (!liTag) {
                    // The list changed
                    ATR.FunctionQueue.replayCurrent(20);
                    pass = null;
                    break;
                  }
                  else {
                    var itemVal = autocomp.listItemValue(liTag).toLowerCase();
                    if (elemVal==itemVal) {
                      foundMatch = true;
                      autocomp.index = i;
                    }
                  }
                }
              }
              if (foundMatch) {
                // Tab to the next field to trigger change and blur events,
                this.typeKeysCmd([field, '\\9']);

                // FYI: Instead of the above typeKeysCmd, we used to do the
                // following, but then sometimes it seemed the following steps
                // blurred the field without firing event listeners (some of the
                // time).
                //Element.simulate(field, 'change');
                //Element.simulate(field, 'blur');
                //field.blur();

                this.inSelectByContentCmd_ = null;
                pass = true;
              }
              else {
                ATR.FunctionQueue.replayCurrent(20);
                pass = null;
              }
            }
          }
          else
            this.inSelectByContentCmd_ = null;
        }
      }
      catch (e) {
        Def.Logger.logMessage(['selectByContent failed']);
        Def.Logger.logException(e);
        this.inSelectByContentCmd_ = null;
      }
    }
    return pass;
  },


  /**
   *  Verifies that a field has an autocompleter with a list
   *  that has at least 1 item.  This should work for either prefetched
   *  or search lists.  (This is more useful as waitForFieldHasList.)
   * @param args The arguments given to the command in the test script.
   *  There should be one-- a Selenium locator (e.g. an ID) for the list
   *  field.
   */
  verifyFieldHasListCmd: function(args) {
    var pass = false;
    try {
      if (args.length == 1) {
        var elem = this.interpretLocator(args[0]);
        if (elem && elem.autocomp && elem.autocomp.rawList_ &&
            elem.autocomp.rawList_.length > 0) {
          pass = true;
        }
      }
    }
    catch (e) {
      Def.Logger.logException('verifyFieldHasList failed:  ' +e);
    }
    return pass;
  },


  /**
   *  Verifies that a field has an autocompleter and its list contains
   *  a specified value.  This works only for prefetched lists.
   *  (This is more useful as waitForValueInFieldList.)
   * @param args The arguments given to the command in the test script.
   *  There should be two -- a Selenium locator (e.g. an ID) for the list
   *  field and the value to find in the list.
   */
  verifyValueInFieldListCmd: function(args) {
    var pass = false;
    try {
      if (args.length == 2) {
        var elem = this.interpretLocator(args[0]);
        var value = args[1];
        if (value.indexOf('javascript{')==0)
          value = this.evaluateJS(value);
        if (elem) {
          if (elem.autocomp && elem.autocomp.rawList_ &&
              elem.autocomp.rawList_.length > 0) {
            pass = elem.autocomp.rawList_.indexOf(value) > -1 ;
          }
        }
      }
    }
    catch (e) {
      Def.Logger.logException('verifyValueInFieldList failed:  ' + e);
    }
    return pass;
  }
};

// Draw the stop button
var ctx = $('stop').getContext("2d");
ctx.fillStyle="#990000";
ctx.beginPath();
ctx.arc(13,13,13,0,2*Math.PI);
ctx.fill();
Event.observe($('stop'), 'click',  ATR.FunctionQueue.stop.bind(ATR.FunctionQueue));
