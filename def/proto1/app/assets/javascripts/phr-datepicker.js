/* 
 * Cutom date picker for PHR widget library.
 * Use a set of defaults intended for PHR and related projects.
 * Notably uses date parsing rules as supporetd by date.js and
 * moves button image inside the input box.
 *
 * Author: Ajay Kanduru Dt. 11/25/2013.
 */

(function ( $ ) {
  $.fn.phrDatepicker = function( options ) {
    var date_changed = false;
    var originalDateFormat = options.dateFormat || 'yy M d';
    options.placeholder       = options.placeholder || 'YYYY/[MM/[DD]]';
    options.title             = options.title || 'YYYY/[MM/[DD]]';
    options.altFormat         = originalDateFormat; // Use originalDateFormat
    options.buttonImageInside = options.buttonImageInside || true;
    options.changeMonth       = options.changeMonth || true;
    options.changeYear        = options.changeYear || true;
    options.constrainInput    = options.constrainInput || false;
    options.showOn            = options.showOn || 'button';
    options.showOtherMonths   = options.showOtherMonths || true;
    options.selectOtherMonths = options.selectOtherMonths || true;
    options.showMonthAfterYear = options.showMonthAfterYear || true;
    options.buttonImageOnly   = options.buttonImageOnly || true;
    options.buttonText        = options.buttonText || '';
    options.onChangeMonthYear = options.onChangeMonthYear || function(year, month) {
      if(date_changed) {
        return;
      }
      date_changed = true;
      var d = $(this).datepicker("getDate");
      if(d != null) {
        d.setFullYear(year);
        d.setMonth(month - 1);
        $(this).datepicker("setDate", d);
      }
      date_changed = false;
    };
   
    // Initialize the object
    this.each(function() {
      $(this).addClass('phr-datepicker-wrapper');
      var dpEl = $('<input class="dp_field"/>');
      var altEl = options.altField;
      if(!altEl) {
        altEl = $('<input class="dp_altField"/>');
      }
      options.altField = altEl;
      $(this).append([dpEl, altEl]);
      $(altEl).addClass('phr-datepicker-input');
      $(altEl).prop('placeholder', options.placeholder);
      $(altEl).prop('title', options.title);
      //Initialize datepicker
      dpEl.datepicker(options);
      dpEl.hide();
      // Move button image to inside of input box.
      if(options.buttonImageInside &&
         options.buttonImageOnly) {
        var imgEl = dpEl.next('img');
        if(imgEl) {
          imgEl.addClass('phr-datepicker-inside-icon');
        }
      }
      // Handle date parsing
      altEl.on("change", function(e) {
        if(date_changed) {
          return;
        }
        date_changed = true;
        //var valid_date = Date.parse(e.target.value);
        var val = e.target.value;
        var valid_date = DateUtils.getEpochTime(val, 1);
        if(!valid_date) {
          valid_date = Date.parse(val);
        }
        if(valid_date) {
          dpEl.datepicker("setDate", new Date(valid_date));
          if(DateUtils.isPartialDate(val)) {
            //dpEl.datepicker('option', 'altFormat', val);
            altEl.prop('value', val);
          }
          else {
            //dpEl.datepicker('option', 'altFormat', originalDateFormat);
            //altEl.prop('value', val);
          }

          //imgEl.addClass('phr-datepicker-inside-icon');
        }
        date_changed = false;
      });
    });
    // Return datepicker object for user handling.
    return $(this).find('input');
  }
}(jQuery));