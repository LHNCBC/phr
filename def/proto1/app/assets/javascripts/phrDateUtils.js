/*
 *Parsing formats for partial dates.
 */
Date.parseYearFormats = new Array('yyyy','yy');
Date.parseMonthFormats = new Array('yyyy/M','M/yyyy','MMMM/yyyy', 'yyyy/MMMM','MMMM/yy',
        'yy/MMMM','yyyy/MMM','MM/yyyy','MMM/yyyy','MMM/yy','M/yy','yy/MMM');
Date.parseDayFormats = new Array('yyyy/MM/d','yyyy/M/d','yyyy/MM/dd','yyyy/M/dd',
               'MMM/d/yyyy','MMM/d/yy','MMMM/d/yyyy','MMMM/d/yy','MM/d/yyyy',
               'MM/d/yy','M/d/yyyy','M/d/yy','d/M/yyyy','d/M/yy','d/MM/yy',
               'd/MM/yyyy','d/MMM/yyyy','d/MMM/yy','yyyy/MMM/dd','yyyy/MMM/d');

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
  return Date.parseExact(val,Date.parseYearFormats);
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
  return Date.parseExact(newstr,Date.parseDayFormats);

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
  return Date.parseExact(newstr,Date.parseMonthFormats);
} ;


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

  var d = val;
  if(d == null) {
    return null;
  }
  else if(typeof d.getMonth === 'function') {
    return d.toString('yyyyMMdd');
  }
  else if (d = Date.parseDayString(val)){
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

/**
 * In case of a non specific date, calculate a median date of
 * the possible date range. e.g. April 2008 => 15 April 2008.
 * Its here since it is intended to be used on server side too where other JS
 * files (dateTimeCalcs.js) may not necessarily be avaialable.
 * @params prec M or Y for date precision when created
 * @returns returns Epoch time for the approximated median date
 **/
Date.prototype.getMedianDate = function(prec) {

  if (prec == 'D'){
    this.setHours(12);
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
    //this.setDate(15) ;
  }
  return this;
};

/**
 * In case of a non specific date, calculate first date out of range.
 *  e.g. April 2008 => 1 may 2008 00:00:00. Then we remove 1 millisecond later
 *  to get the last moment of the given date.
 * Its here since it is intended to be used on server side too where other JS
 * files (dateTimeCalcs.js) may not necessarily be available.
 * @params prec M or Y for date precision when created
 * @returns returns last possible date in the range.
 **/
Date.prototype.getEndDate = function(prec) {

  if (prec == 'M'){
    this.setMonth(this.getMonth()+1) ;
  }
  else if (prec == 'Y'){
    this.setMonth(11, 32);
  }
  else if (prec == 'D'){
    this.setDate(this.getDate()+1) ;
  }
  return this;
};

DateUtils = {
/**
   *  This function returns number of milliseconds since epoch given
   *   a input date in one of the accepted date formats. Accepted
   *   formats are determined by parseDate
   *  @param val input string|object
   *    string: In a format accepted by parseString
   *    object: Date object which return exact epoch time
   *  @param et_point point. 0 is begining, 1 is middle, 2 is
   *   end of the timeperiod. If invalid or not supplied it defaults to select
   *   middle of the timeSpan.
   *  @return  date in milliseconds since epoch in the local time zone.
   **/
  getEpochTime: function(val, et_point) {

    if(et_point == null || et_point === "" || et_point > 2) {
        et_point = 1 // For backward compatibility default to median
    }
    var d = val;
    if(d == null) {
      return 0;
    }
    else if(typeof d.getMonth === 'function') {
      return d.getTime(); // This is a date object asking for exact time
    }
    else if (d = Date.parseDayString(val)){
      return (et_point === 1) ?
        d.getMedianDate('D').getTime()  : (et_point == 0) ?
        d.getTime() : d.getEndDate('D').getTime()-1;
    }
    else if (d = Date.parseMonthString(val)){
      return (et_point === 1) ?
        d.getMedianDate('M').getTime()  : (et_point == 0) ?
        d.getMonthDayOneDate().getTime() : d.getEndDate('M').getTime()-1;
    }
    else if (d = Date.parseYearString(val)){
      return (et_point === 1) ?
         d.getMedianDate('Y').getTime() : (et_point == 0) ?
         d.getYearJanOneDate().getTime() : d.getEndDate('Y').getTime()-1;
    } else{
      return 0;
    }

  },

  isPartialDate: function(val) {
    return (Date.parseYearString(val) || Date.parseMonthString(val));
  }
}