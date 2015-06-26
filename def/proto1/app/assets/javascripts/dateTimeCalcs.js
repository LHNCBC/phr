/**
 * dateTimeCalcs.js -> javascript functions to handle date and time
 *                     calculations
 *
 * $Id: dateTimeCalcs.js,v 1.45 2011/06/29 13:50:54 taof Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/dateTimeCalcs.js,v $
 * $Author: taof $
 *
 * $Log: dateTimeCalcs.js,v $
 * Revision 1.45  2011/06/29 13:50:54  taof
 * bugfix: event.fireEvent() not working with IE9
 *
 * Revision 1.44  2011/06/16 14:47:29  taof
 * IE9 bugfix: when_started field initial value should be a date rather than 't'
 *
 * Revision 1.43  2011/04/15 14:35:39  mujusu
 * bug fixes
 *
 * Revision 1.42  2011/04/05 17:39:16  mujusu
 * fixed bug
 *
 * Revision 1.41  2010/08/10 19:26:08  mujusu
 * fix validatiopn tooltip clearing bug
 *
 * Revision 1.40  2010/05/21 14:00:59  mujusu
 * rtemoved toggleTooltip
 *
 * Revision 1.39  2010/05/12 21:36:22  plynch
 * Fixed a problem with the makeDateFormat function being called when a
 * controlled edit table row is reverted back to its saved state.
 *
 * Revision 1.38  2010/05/03 20:16:46  mujusu
 * added new function to calc epochtime in beginning instead of median fora year ./ year month
 *
 * Revision 1.37  2010/04/21 16:04:10  mujusu
 * bug fix
 *
 * Revision 1.36  2010/04/20 16:09:12  mujusu
 * taffydb updated now
 *
 * Revision 1.35  2010/04/16 21:12:22  mujusu
 * bug fix for invalid date condition
 *
 * Revision 1.34  2010/04/16 18:37:54  mujusu
 * redid for a strange compression error essentially same as 1.33 with a extra ;
 *
 * Revision 1.33  2010/04/15 23:14:15  mujusu
 * epoch time related fixes
 *
 * Revision 1.32  2010/03/15 17:53:20  mujusu
 * fixed bug with year/month only
 *
 * Revision 1.31  2010/02/02 19:22:46  mujusu
 * time functions
 *
 * Revision 1.30  2010/01/29 16:43:35  lmericle
 * code formatting fix
 *
 * Revision 1.29  2009/12/22 22:22:43  plynch
 * Changed splitFullFieldID so that its return value is cached, updated
 * the code to be aware of that, and moved the function into idCache.js.
 *
 * Revision 1.28  2009/07/08 17:33:51  wangye
 * fire on change event on _RT and _HL7 fields when their values changes
 *
 * Revision 1.27  2009/06/29 23:43:20  plynch
 * Fixes for the compression script
 *
 * Revision 1.26  2009/06/29 23:30:36  plynch
 * Changes for field defaults; removed jscalendar_date_format.js, which did
 * not appear to be used.
 *
 * Revision 1.25  2009/05/18 16:43:24  mujusu
 * changes for updated tooltip
 *
 * Revision 1.24  2009/05/12 16:13:06  lmericle
 * made updates to makeDateFormat to reflect changes to date event handling
 *
 * Revision 1.23  2009/04/22 17:07:19  taof
 * Using tooltip instead of popup window to show invalid field error messages
 *
 * Revision 1.22  2008/11/04 19:17:51  smuju
 * fixed bugs in case the date entered is not valid
 *
 * Revision 1.21  2008/09/04 18:32:59  smuju
 * changes based on code review
 *
 * Revision 1.20  2008/08/13 17:02:00  smuju
 * fixed bug 803. check if error present before rmoving the error div/Button
 *
 * Revision 1.19  2008/07/16 17:16:26  smuju
 * Comments + changes to make error button work correctly in year of birth
 *
 * Revision 1.18  2008/07/11 17:11:24  smuju
 * updated to populate HL7 fields
 *
 * Revision 1.17  2008/07/11 15:20:59  smuju
 * created makeFormatJS. Moved from ruby to js
 *
 * Revision 1.16  2008/07/09 20:22:39  smuju
 * added newer format
 *
 * Revision 1.15  2008/07/02 14:35:28  smuju
 * added more date formats
 *
 * Revision 1.14  2008/05/20 18:03:35  smuju
 * added - to regex
 *
 * Revision 1.13  2008/05/20 17:46:45  smuju
 * " replaced by '
 *
 * Revision 1.12  2008/05/20 17:41:05  smuju
 * modified regex for date/day parsing
 *
 * Revision 1.11  2008/05/20 14:14:06  smuju
 * added quotes on regex pattern
 *
 * Revision 1.10  2008/05/19 23:34:02  smuju
 * added semi colon
 *
 * Revision 1.9  2008/05/19 23:28:07  smuju
 * updated to work with multi types of seperators plus more patterns
 *
 * Revision 1.8  2008/05/05 20:26:47  smuju
 * added more formats
 *
 * Revision 1.7  2008/05/05 12:13:38  smuju
 * made changes to work with new date.js library
 *
 * Revision 1.6  2008/02/08 20:23:17  smuju
 * aqdded format2
 *
 * Revision 1.5  2008/01/23 16:32:13  smuju
 * added coomments
 *
 * Revision 1.4  2008/01/17 23:21:52  smuju
 * added functions to extend the date class
 *
 * Revision 1.3  2007/08/27 14:14:06  lmericle
 * documentation, updates
 *
 * Revision 1.2  2007/08/23 14:34:32  lmericle
 * changes for dependencies
 *
 * Revision 1.1  2007/08/22 22:29:34  lmericle
 * updated dependencies for multiple conditions; added dateTimeCalcs.js
 */

/**
 * Javascript functions to perform date and time calculations (differences,
 * etc) are contained in this file.
 *
 * Prerequisites:  none
 */

 // used in dependencies.js to show available methods for date/Time based
 // calculations/operators - I don't think they're used anymore.  Let's see
 // if something blows up.
//var dateCalcFunctions = new Array() ;
//dateCalcFunctions.push("elapsedYrs") ;
 
/**
 *  This function calculates the number of years from a specified year to
 *  this year.  No provisions are made for month and day in this function.
 *
 * @param fromYear  year from which we should calculate the number of
 *                  years that have elapsed.  If null or an empty string,
 *                  is set to this year, causing a return of 0
 * returns the number of years from the fromYear to this year.  If the
 *         fromYear is in the future, the value returned is negative
 */
function elapsedYrs(fromYear) {

  var d = new Date() ;
  var thisYear = d.getFullYear() ;
  if ((fromYear == "") || (fromYear == null)) {
    fromYear = thisYear
  }
  return (thisYear - fromYear) ;
} ;
 
/**
 * Check if the input text has a possible date by interpreting the text.
 * @param val date string with year only
 * @return date if valid. null if invalid. 
 **/
Date.interpretDate = function(val) {
  // look for common strings n, otherwise throw error/return null
  var search = 
    val.search(/t|yesterday|week|month|year|sun|mon|tue|wed|thu|fri|sat|add|subtract|past|future|st|nd|rd|th/i) ;
  var d = null ;
  if (search!=-1) { 
    d=Date.parse(val);
  }
  return d;
} ;

/**
 * parse and interpret time as a HHMM string.
 * @param val date string with year only
 * @return date if valid. null if invalid.
 **/
Date.parseTimeString = function(val) {
 // var formats=new Array('HH:mm','hh:mm');
  return Date.parse(val);
} ;

/**
 * parse and interpret date as a year string.
 * @param val date string with year only
 * @return date if valid. null if invalid. 
 **/
Date.parseYearString = function(val) {
  var formats=new Array('yyyy','yy');
  return Date.parseExact(val,formats);
} ;

/**
 * parse and interpret date as a full day string ( ie with year, month, day).
 * @param val date string with year/month/day only
 * @return date if valid. null if invalid. 
 **/
Date.parseDayString = function(val) {
  // This regular expression matches specific parts of the date string
  // The individual parts ( day, month. year) are then reassembled into a 
  // standard format seperated by / to be further matched to paterns and 
  // interpreted
  var re =  new RegExp('([0-9a-zA-Z]*)[ \\-_.,/]*([0-9a-zA-Z]*)'+
             '[ .\\_,/-]*([0-9a-zA-Z]*)')
  var newstr = val.replace(re, '$1/$2/$3');
  var formats=new Array('yyyy/MM/d','yyyy/M/d','yyyy/MM/dd','yyyy/M/dd',
               'MMM/d/yyyy','MMM/d/yy','MMMM/d/yyyy','MMMM/d/yy','MM/d/yyyy',
               'MM/d/yy','M/d/yyyy','M/d/yy','d/M/yyyy','d/M/yy','d/MM/yy',
               'd/MM/yyyy','d/MMM/yyyy','d/MMM/yy','yyyy/MMM/dd','yyyy/MMM/d');
  return Date.parseExact(newstr,formats);

} ;

/**
 * parse and interpret date as a month string ( ie with year, month).
 * @param val date string with year/month only
 * @return date if valid. null if invalid. 
 **/
Date.parseMonthString = function(val) {
  // This regular expression matches specific parts of the date string
  // The individual parts ( day, month. year) are then reassembled into a 
  // standard format seperated by / to be further matched to paterns and 
  // interpreted
  var re = new RegExp('([0-9a-zA-Z]*)[ \\-_.,/]*([0-9a-zA-Z]*)' +
     '[ .\\_,/-]*$')    ;
  var newstr = val.replace(re, '$1/$2');
  var formats=new Array('yyyy/M','M/yyyy','MMMM/yyyy', 'yyyy/MMMM','MMMM/yy',
        'yy/MMMM','yyyy/MMM','MM/yyyy','MMM/yyyy','MMM/yy','M/yy','yy/MMM');
  return Date.parseExact(newstr,formats);
} ;


/**
 * Parse and interpret the date based on the a special sets of date formats
 * @param val date string of special format
 **/
Date.parseSpecialString = function(val) {
  var lcVal = val.toLowerCase();
  // Acceptable condition 1: Allows special characters being passed through
  var acceptable_inputs = ["t", "today", "tomorrow", "yesterday", "d", "w", "m", "y", "mon", "tue", "wed", "thur", "fri"];
  var isWord = acceptable_inputs.indexOf(lcVal) > -1;
  // Acceptable condition 2: Allows calculating the date based on today's date
  var reg = new RegExp(/^\s*((t)?\s*[+-]|next\s|last\s)/);
  var isExp = reg.test(lcVal);
  return ( isWord || isExp ) ? Date.parse(val) : null;
}


/** 
 * In case of a non specific date, calculate a median date of
 * the possible date range. e.g. April 2008 => 15 April 2008
 * @params prec M or Y for date precision when created
 * @returns returns Epoch time for the approximated median date
 **/
Date.prototype.getMedianDate = function(prec) {

  if (prec == 'D'){
    this.setHours(12); // Pick mid day.
  }
  else if (prec == 'M'){
    if (this.getMonth() ==1){
      this.setDate(14) ;
    }
    else {
      this.setDate(15) ;
    }
  }
  else if (prec == 'Y'){
    this.setMonth(6) ;
    //this.setDate(15) ; // Start of the July is middle of year. -Ajay
  }
  return this;
};

/**
 * In case of a non specific date, with just year, return date
 * with jan 01 instead of default.
 * @params prec M or Y for date precision when created
 * @returns returns Epoch time for the approximated median date
 **/
Date.prototype.getYearJanOneDate = function() {
    this.setMonth(0) ;
    this.setDate(1) ;
    return this;
};

/**
 * In case of a non specific date, with just year and month, return
 * date with day 01 instead of default.
 * @params prec M or Y for date precision when created
 * @returns returns Epoch time for the approximated median date
 **/
Date.prototype.getMonthDayOneDate = function() {
    this.setDate(1) ;
    return this;
};


/**
 *  This function interprets date whether full day, month or just year.
 *  Returns appropriate date object.
 *  @param val input string in a format accepted by parseString
 *  @return  date in HL7 format
 **/
Date.getHl7Date = function(val) {
  var d = null ;
  if (d = Date.parseDayString(val)){
    return d.toString('yyyyMMdd') ;
  }
  else if (d = Date.parseMonthString(val)){
    return  d.toString('yyyyMMdd') ;
  }
  else if (d = Date.parseYearString(val)){
    return d.toString('yyyyMMdd') ;
  } else{
    return "" ;
  }
};

/** This function returns number of milliseconds since epoch
 *   given a input date in one of the accepted date formats as well as time.
 *   Accepted formats are determined by parseDate. Right now only complete date.
 *  @param dateVal the epoch value of the date in the string format
 *  @param timeVal input time object (optional)
 *  @return  date in milliseconds since epoch
 **/
Date.getTimeEpochTime = function(dateVal,timeObj) {
  var ret = '';
  if (dateVal){
    if (timeObj) {
      var dateObj = new Date(parseInt(dateVal));
      var newDateObj = new Date(dateObj.getFullYear(),
          dateObj.getMonth(),dateObj.getDate(),
          timeObj.getHours(),timeObj.getMinutes(), 0);
      ret = newDateObj.getTime();      
    }
  }
  return ret;
};

/*
 * Pads a 0 in front if single digit. Formats hours/mins ets. toString()
 * @param s time number
 * @return time number with podding if <10
 **/
Date.pad = function(s){
  return(s.toString().length==1)?"0"+s:s;
};

/**
 * Below is a new namespace for functions specific to our date field (i.e. not
 * general date/time calculations.  If this grows, it should be moved into its
 * own file.
 **/
Def.DateField = {
  
 /** 
  * This function checks, validates and displays the date in appropriate echoback
  * format. This also populates the epoch time as well as hl7 date fields with
  * equivalent date values.
  *  @param dateField date Field where the value is entered and the output is set
  *  NO - removed param hiddenField Field with EpochTime value
  *  NO - removed param hiddenHL7Field field with HL7 date value
  *  @param dateFormat date format with optional field in []. ex. YYYY/[MM]/[DD]
  *  @param dateEchoFmtD echoback format for full DATE EG. MMM dd, YYYY
  *  @param dateEchoFmtM echoback format for Month/Year EG. MMM YYYY
  *  @param dateEchoFmtY echoback format for year. eq. YYYY
  *  @param displayName field name to be displayed in error message
  *  @param errorMessage  error message to post when there is error in validating
  *  @param et_point epoch time calculation point.
  *  field.
  **/  
  makeDateFormat: function(dateField,
                           dateFormat,
                           dateEchoFmtD,
                           dateEchoFmtM,
                           dateEchoFmtY,
                           displayName,
                           errorMessage,
                           et_point) {

    var format = ''  ; // format in case the date is interpreted from string.
    var formatYA = '' ;
    var formatMA = '' ;
    var formatDA = '' ;
    var formatDB = dateEchoFmtD ; // echo back format with day
    var formatMB = dateEchoFmtM ; // echo back format with month
    //      if (dateFormat == null){dateFormat = "" ; }
    var dateFormatNoBracs = dateFormat.replace(/[\[\]]/g,'') ;
    // determine the echoback format based on passed dateFormat.
    // square brackets signify optional elements.
    //  in case we have YYYY[[MM]DD] or YYYY[MM[DD]] formats
    if (dateFormat.match(/\[\[(MM|DD)/)  ||
      dateFormat.match(/(MM|DD)\]\]/) )  {
      formatYA = dateEchoFmtY ;
      // remove DD as MM cannot be optional. If it is then use [MM] [DD]
      formatMA = dateFormatNoBracs;
      formatMA = formatMA.replace('DD','') ;
      formatMA = formatMA.replace('YYYY','y') ;
      formatDA = dateFormatNoBracs;
      formatDA = formatDA.replace('DD','dd') ;
      formatDA = formatDA.replace('YYYY','y') ;
      format = formatDB ;
    }
    // for case such as YYYY[MMDD] or YYYY[DDMM]
    else if (dateFormat.match(/\[(MM|DD)(?!\])/)) {
      formatYA = dateEchoFmtY ;
      formatDA = dateFormatNoBracs;
      formatDA = formatDA.replace('DD','dd') ;
      formatDA = formatDA.replace('YYYY','y') ;
      format = formatDB ;
    }
    // for case such as YYYYMM[DD]
    else if (dateFormat.match(/\[DD\]/))  {
      formatMA = dateFormatNoBracs ;
      formatMA = formatMA.replace('DD','') ;
      formatMA = formatMA.replace('YYYY','y') ;
      formatDA = dateFormatNoBracs ;
      formatDA = formatDA.replace(/DD/,'dd') ;
      formatDA = formatDA.replace('YYYY','y') ;
      format = formatDB ;
    }
    // for case YYYY[MM]
    else if (dateFormat.match(/\[MM\]/)) {
      formatMA = dateFormatNoBracs;
      formatMA = formatMA.replace('YYYY','y') ;
      formatYA = dateEchoFmtY ;
      format = formatMB ;
    }
    else  {
      // for case YYYYMMDD
      if (dateFormat.match("DD")) {
        formatDA = dateFormatNoBracs ;
        formatDA = formatDA.replace('DD','dd') ;
        formatDA = formatDA.replace('YYYY','y') ;
        formatMA = dateFormatNoBracs;
        formatMA = formatMA.replace('DD','') ;
        formatMA = formatMA.replace('YYYY','y') ;
        formatMB=formatDB ; // fix so that partial date witout day still works good.
        format = formatDB ;
      }
      // for case YYYYMM
      else if (dateFormat.match("MM")) {
        formatMA = dateFormatNoBracs ;
        formatMA = formatMA.replace('YYYY','y') ;
        format = formatMB ;
      }
      // for case YYYY
      else {
        formatYA = dateEchoFmtY ;
        format = formatYA ;
      }
    }

    // Now parse the input value and populate the field based on formats
    // selected above. Also populate HL7 as well as EpochTime fields
    var val = '' ;
    if (Def.getFieldVal(dateField))
      val = Def.getFieldVal(dateField).replace(/^\s+|\s+$/g,'')   
    var len = val.length ;
    var re = new RegExp('([0-9a-zA-Z]*)[ \\-_.,/]*([0-9a-zA-Z]*)'+
             '[ .\\_,/-]*([0-9a-zA-Z]*)')
    var regexLen = re.exec(val).clean("").length  ;

    var date = null ;
    var idParts = Def.IDCache.splitFullFieldID(dateField.id) ;
    var epochFld = $(idParts[0] + idParts[1] + '_ET' + idParts[2]);
    var hl7Fld = $(idParts[0] + idParts[1] + '_HL7' + idParts[2]) ;
    var valid = true;
    if (len > 0) {
      if (regexLen == 4 && formatDA != '' && (date = Date.parseDayString(val))){
        Def.setFieldVal(dateField,date.toString(formatDB)) ;
        Def.setFieldVal(epochFld, Def.DateUtils.getEpochTime(val),false) ;
        Def.setFieldVal(hl7Fld,date.toString('yyyyMMdd'),false) ;
      }
      else if (regexLen == 3 && formatMA != '' 
          && (date = Date.parseMonthString(val))) {
        Def.setFieldVal(dateField, date.toString(formatMB)) ;
        Def.setFieldVal(epochFld,Def.DateUtils.getEpochTime(val,et_point),false);
        Def.setFieldVal(hl7Fld,date.toString('yyyyMM'),false) ;
      }
      else if (regexLen == 2 && formatYA != '' 
          && (date = Date.parseYearString(val)))   {
        Def.setFieldVal(dateField,date.toString(formatYA)) ;
        Def.setFieldVal(epochFld,Def.DateUtils.getEpochTime(val,et_point),false) ;
        Def.setFieldVal(hl7Fld,date.toString('yyyy'),false) ;
      }
      else if (regexLen < 4 && (date = Date.parseSpecialString(val))) {
        Def.setFieldVal(dateField,date.toString(format)) ;
        Def.setFieldVal(epochFld,date.getTime(),false) ;
        Def.setFieldVal(hl7Fld,date.toString('yyyyMMdd'),false) ;
      }
      else if (val == dateField.tipValue ||
               val == '') {
        Def.setFieldVal(epochFld,'',false) ;
        Def.setFieldVal(hl7Fld,'',false) ;
      }
      else{
        valid = false;
        Def.setFieldVal(epochFld,'',false) ;
        Def.setFieldVal(hl7Fld,'',false) ;
      }
       
      if (Def.getFieldVal(epochFld) != '') {
        var timeField = $(idParts[0] + idParts[1] + '_time' + idParts[2]);
        if (timeField != undefined && Def.getFieldVal(timeField) != '') {
          // added "2010/01/01" to make sure the time string "str" won't be 
          // mistakenly treated as a date string, e.g. Date.parse('12')
          var time = Date.parse('2010/01/01 '+Def.getFieldVal(timeField)) ;
          var timePart = Date.pad(time.getHours()).toString()+
                Date.pad(time.getMinutes()).toString() ;
          Def.setFieldVal(epochFld,Date.getTimeEpochTime(Def.getFieldVal(epochFld),
            time),false) ;
          Def.setFieldVal(hl7Fld,date.toString('yyyyMMdd')+timePart,false) ;
        }
      }
    }
    // Else if cleared of any value/ reset clear any error buttons etc.
    else {
      var errBtn = getElementsByClass('errorButton',dateField.parentNode,'*');
      if (errBtn[0] != null)
        errBtn[0].parentNode.removeChild(errBtn[0]) ;
      Def.setFieldVal(epochFld, '',false) ;
      Def.setFieldVal(hl7Fld,'',false) ;
    }
    Def.refreshErrorDisplay(dateField, [valid, errorMessage]);
    
    // handler at onChange event updates TaffyDB
    appFireEvent(epochFld, 'change');
    appFireEvent(hl7Fld, 'change');
    return ;
  }, // end makeDateFormat
  
  
  /**
   *  Checks to see if there is a default value for the field, and inserts
   *  it if the field is empty.
   * @param field the date field to be filled in with the default
   */
  insertDefaultVal: function(field) {
    if (Def.getFieldVal(field) == '') {
      var targetFieldName = Def.IDCache.splitFullFieldID(field.id)[1];
      var defaultVal = Def.FieldDefaults[targetFieldName]
      if (defaultVal) {
        Def.setFieldVal(field, defaultVal);
        //field.value = defaultVal; // might be 'today'
        //appFireEvent(field, 'change');
      }
    }
  }
}; // Def.DateField
