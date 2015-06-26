Def.DateUtils = {
  /**
   *  This function returns number of milliseconds since epoch given
   *   a input date in one of the accepted date formats. Accepted
   *   formats are determined by parseDate
   *  @param val input string in a format accepted by parseString
   *  @param epochtime point. 0 is begining, 1 is middle, 2(or anything else) is
   *   end of the timeperiod. Default it to select middle of the timeSpan.
   *  @return  date in milliseconds since epoch in the local time zone.
   **/
  getEpochTime: function(val,et_point) {

    if(et_point == null || et_point === "") {
        et_point = 1 // Make default as median. -Ajay 05/30/2013
    }
    var d = null ;
    if (d = Date.parseDayString(val)){
      /*
      return (et_point != null && et_point === 2) ?
        d.getEndDate('D').getTime() -1 : d.getTime() ;
      */
      // Fixed the midday logic. -Ajay
      return (et_point != null && et_point === 1) ?
        d.getMedianDate('D').getTime()  : (et_point == null || et_point == 0) ?
        d.getTime() : d.getEndDate('D').getTime()-1;
    }
    else if (d = Date.parseMonthString(val)){
      return (et_point != null && et_point === 1) ?
        d.getMedianDate('M').getTime()  : (et_point == null || et_point == 0) ?
        d.getMonthDayOneDate().getTime() : d.getEndDate('M').getTime()-1;
    }
    else if (d = Date.parseYearString(val)){
      return (et_point != null && et_point === 1) ?
         d.getMedianDate('Y').getTime() : (et_point == null || et_point == 0) ?
         d.getYearJanOneDate().getTime() : d.getEndDate('Y').getTime()-1;
    } else{
      return 0;
    }

  }
}


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