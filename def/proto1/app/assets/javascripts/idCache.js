// $Log: idCache.js,v $
// Revision 1.22  2010/12/21 16:31:19  wangye
// added sparkline on test panel flowsheet using a jquery sparkline plugin
//
// Revision 1.21  2010/06/29 19:43:38  lmericle
// made partialSuffix parameter for findByIDStart method optional
//
// Revision 1.20  2010/04/01 13:05:27  lmericle
// syntax fix
//
// Revision 1.19  2010/03/12 17:17:12  lmericle
// added missing documentation for splitFullFieldID
//
// Revision 1.18  2010/01/21 22:45:53  plynch
// added comment
//
// Revision 1.17  2009/12/22 22:22:43  plynch
// Changed splitFullFieldID so that its return value is cached, updated
// the code to be aware of that, and moved the function into idCache.js.
//
// Revision 1.16  2009/03/06 21:08:10  lmericle
// added checkClassName
//
// Revision 1.15  2009/03/03 15:39:23  lmericle
// added checkClassName
//
// Revision 1.14  2009/01/26 22:00:00  plynch
// Comments.
//
// Revision 1.13  2009/01/21 20:32:21  taof
// bugfix: newDollar(null) should return null
//
// Revision 1.12  2009/01/13 19:14:18  lmericle
// added code at beginning of newDollar to immediately return an element parameter that's already an Element object
//
// Revision 1.11  2008/11/18 18:00:58  lmericle
// conditioned findByID return on element existence in cache
//
// Revision 1.10  2008/10/24 21:34:31  wangye
// bug fixes for IE7 and performance tune-up
//
// Revision 1.9  2008/10/23 18:21:33  lmericle
// documentation fixes
//
// Revision 1.8  2008/10/22 15:42:53  lmericle
// modified to include model row elements in fullIDcache_ but not in cache_
//
// Revision 1.7  2008/10/20 23:31:36  plynch
// Removed the old addToCache statement that I accidentally left in in the
// previous version.  We don't need to do that on the load event, since we
// now do it immediately when idCache.js is read.
//
// Revision 1.6  2008/10/20 23:07:50  plynch
// An improvement in effienciency for rules.js' findFields.
// Also, idCache now initializes its cache when it is processed.
//
// Revision 1.5  2008/10/09 19:55:14  lmericle
// created fullIDcache_, implemented newDollar and getID functions
//
// Revision 1.4  2008/04/28 18:03:50  plynch
// Added some statements to track how long various parts of the JavaScript
// initialization are taking.
//
// Revision 1.3  2008/04/24 22:19:00  plynch
// Some more performance enhancements and some cleanup.
//
// Revision 1.2  2008/04/24 20:43:07  plynch
// Got rid of the call to "up" in addToCache to speed things up.
//
// Revision 1.1  2008/04/24 19:45:23  plynch
// Added a cache of base ID strings to actual field IDs, to speed up
// the run time of the rules.
//

/**
 *  A class that speeds up finding elements whose ID attributes start with
 *  a given base ID and suffix.  In our system, IDs looks like "fe_myField_1_2".
 *  In that example, "fe_myField" is the base ID, and "_1_2" is the suffix.
 *  Elements are added to the cache with "addToCache" (which
 *  will also add elements contained within the given element) and can be
 *  retrieved with "findByIDStart".  The findByIDStart method can take
 *  partial suffixes, e.g. "_1_", and will return elements whose IDs' suffixes
 *  start with that suffix.
 *  In the future we might want to add a delete method as well, but we don't
 *  seem to need that yet.
 */
Def.IDCache = {  // This is really more of a namespace than a class
  /**
   *  A Map from base ID strings to hashmaps where the keys are IDs that share
   *  that base ID and the values are the elements for those IDs.
   */
  cache_: null,
  
  /**
   *  A map from the full ID of an element to the element.
   */
  fullIDcache_: null,

  /**
   *  A map from the full ID of an element to the ID parts returned by
   *  splitFullFieldID.  (This hash is maintained by splitFullFieldID)
   */
  idPartsCache_: {},
  

  /**
   *  Adds the given element and any contained elements to the cache (for the
   *  elements that have IDs).  Note that this means you don't have to add each
   *  element individually-- the top element is enough.
   *  
   *  Note that if any of the elements to be added already exist in the cache,
   *  they will be overwritten.  Paul says that this is necessary so that when
   *  static rows in controlled edit tables are replaced with input fields, 
   *  the static elements in the cache are replaced with input fields.  
   *  lm, 3/2012
   *
   *  Fields that are in "model rows" (rowid=0) of our fields tables are not
   *  included in the cache.  (The user never sees those-- they are just used
   *  for creating new rows.)
   * @param topElem the top-level element of a chunk of HTML whose ID-containing
   *  elements should be cached for future lookup.
   */
  addToCache: function(topElem) {
    if (this.cache_ == null) {
      this.cache_ = {};
      this.fullIDcache_ = {};
    }
    // Get all elements in topElem that have an ID.
    var nonModElems = [];
    var modElems = [] ;
    this.getIDElements(topElem, nonModElems, modElems);
    var topId = this.getID(topElem);    
    if (topId) {
      var isModelRow = this.checkModelRow(topElem) ;
      if (!isModelRow)
        nonModElems.push(topElem);
      else
        modElems.push(topElem);
    }
    for (var i=0, max=nonModElems.length; i<max; ++i) {
      var e = nonModElems[i];
      var id = e.id;
      var id_parts = this.splitFullFieldID(id);
      var id_base = id_parts[0] + id_parts[1];
      var baseHash = this.cache_[id_base];
      if (!baseHash) {
        baseHash = {};
        this.cache_[id_base] = baseHash;
      }
      e = Element.extend(e) ;
      baseHash[id] = e;
      this.fullIDcache_[id] = e;
    }
    for (i=0, max=modElems.length; i<max; ++i) {
      e = Element.extend(modElems[i]) ;
      this.fullIDcache_[modElems[i].id] = e;
    }
  }, // end addToCache


 /**
   *  Finds the elements (added with addToCache) whose IDs start with
   *  the given base ID plus the given suffix (which may be a partial suffix).
   *  For example, if the base ID is "fe_myField" and the partial suffix
   *  is "_1_", then the returned list of fields could include fields whose
   *  IDs are "fe_myField_1_1", "fe_myField_1_2", and "fe_myField_1_2_1".
   *
   *  NOTE:  If this is called without first adding anything to the cache,
   *  the whole document will be added before attempting to search for the
   *  matching elements.
   * @param baseID the base part of the id, e.g. fe_myField
   * @param partialSuffix the beginning part of a suffix, e.g. "_1_2"
   * @return an array of matching elements (or the empty array if there are
   *  none.)
   */
  findByIDStart: function(baseID, partialSuffix) {
    if (this.cache_ == null) {      
      var start = new Date().getTime();
      this.addToCache($$('body')[0]);      
      var finish = new Date().getTime();
      Def.Logger.logMessage(['Initialized IDCache in ', (finish-start), 'ms',
                             'from findByIDStart']);
    }
    if (partialSuffix == undefined)
      partialSuffix = '' ;

    var rtn = [];
    var baseHash = this.cache_[baseID];
    var idStartRE = new RegExp('^'+baseID+partialSuffix);
    for (var id in baseHash) {
      if (idStartRE.exec(id))
        rtn.push(baseHash[id]);
    }
    return rtn;
  }, // end findByIDStart


  /**
   *  Finds the element (added with addToCache) wwith the specified
   *  ID.  
   *
   *  NOTE:  If this is called without first adding anything to the cache,
   *  the whole document will be added before attempting to search for the
   *  matching elements.
   * @param id the id of the element to find
   * @return the element - or null if it was not found
   */
  findByID: function(id) {
    if (Def.IDCache.fullIDcache_ == null) {      
      var start = new Date().getTime();      
      this.addToCache($$('body')[0]);      
      var finish = new Date().getTime();
      Def.Logger.logMessage(['Initialized IDCache in ', (finish-start), 'ms',
                             'from findByID']);
    }
    var ret = null ;
    if (id)
      ret = this.fullIDcache_[id] ;
    return ret ;
  }, // end findByID


  /**
   *  Parses a full field ID (fe_first_name_1_2_3) into prefix, field name,
   *  and suffix.  The return value is cached, so the caller must take care
   *  not to modify the returned array.
   *
   *  @param fieldID the full form field ID
   *  @return a 3-element array containing the prefix, field name and suffix
   */
  splitFullFieldID: function(fieldID) {
    var rtn = this.idPartsCache_[fieldID];
    if (!rtn) {
      var match = /(_\d+)+$/.exec(fieldID);
      var suffix = match==null ? '' : match[0];
      match = /^[^_]+_/.exec(fieldID);
      var prefix = match==null ? '' : match[0];
      var fieldName =
        fieldID.substring(prefix.length, fieldID.length-suffix.length);
      rtn = [prefix, fieldName, suffix];
      this.idPartsCache_[fieldID] = rtn;
    }
    return rtn;
  },


  /**
   *  Returns a list of elements contained by the given element (which is
   *  not checked) that have an ID attribute.  Model row elements are skipped.
   * @param topElem the element within which to find elements with IDs.
   * @return the return array (passed in for efficiency).
   */
  getIDElements: function(topElem, nonModElems, modElems, isModelRow) {
    // Note: PL Made three attempts at making this faster, including rewriting
    // this as a non-recursive function.  This (original) implementation was the
    // fastest on Firefox when running with Firebug off, in terms of overall
    // page lode time for a large PHR record.
    if (isModelRow == undefined)
      isModelRow = false ;
    // Assuming if the parent row is a model row, then all sub rows are model 
    // rows too
    if (topElem.tagName == 'TR' && !isModelRow )
      isModelRow = this.checkModelRow(topElem) ;
    
    var child = topElem.firstChild;
    while (child) {
      if (child.nodeType == 1) {
        var isModelRowChild = (child.tagName == 'TR' && !isModelRow) ?
           this.checkModelRow(child) : isModelRow ;
        var id = this.getID(child);          
        if (id) {
          if (isModelRowChild)
            modElems.push(child);
          else
            nonModElems.push(child) ;
        }
        if (child.firstChild)
          this.getIDElements(child, nonModElems, modElems, isModelRowChild);
      }
      child = child.nextSibling;
    } // end do while there are children of the topElem
  }, // end getIDElements 


  /**
   *  Checks to see if an element is the start of a model row.
   *  ASSUMES that the element passed in is a table row element
   *  (tagName == 'TR').  I didn't put that within this method, because
   *  the check needs to be made in the calling code.
   *
   *  It's not a lot of code, but it provides a standard definition of
   *  how to recognize a model row.
   *
   * @param element the element to chekc
   * @return boolean indicating whether or not it's the start of a model row
   */  
  checkModelRow: function(element) {
    var rowid = element.getAttribute('rowid');
    return (rowid && rowid == '0') ;
  } , // end checkModelRow
  
  
  /* This function attempts to use the quickest method to 
   * get an ID for a form value.
   * 
   * If we can simply access the id directly (element.id), we
   * do so.  Otherwise we use getAttribute to get it.
   *
   * We don't use prototype's readAttribute method here, because
   * for an id value it defaults to getAttribute.  Might as well
   * use it directly.
   *
   * @params element - the element whose id we want
   * @returns the id (or null if we couldn't acquire it).
   */
  getID: function(element) {  
    var ret = null ;
    if (element.id)
      ret = element.id ;
    else
      ret = element.getAttribute('id') ;
    return ret ; 
  } // end getID
  
}; // end Def.IDCache

/* This function is substituted for the prototype $ method to
 * force acquisition of form elements from the fullIDcache_ instead
 * of via the $ method, which searches the form.
 *
 * If passed a string, we assume the string represents the id of
 * the element, and search the fullIDcache_ for it.  If found in
 * the fullIDcache_ we return it - as an Element, which is how it's
 * stored in the cache.  If we don't find it in fullIDcache-, we
 * call the $ function in prototype to find the element in the form
 * and, if it's found, then add it to the cache(s) as an Element object.
 *
 * If passed a single object (that's not a string), we try to get
 * its id and use that to find it in the fullIDcache_.  Again, if
 * we find it, we return it.  Otherwise we add the object passed
 * in to the cache(s).
 *
 * If we're passed an array of values/objects, or if we cannot
 * find the element, we call the $ function in prototype.
 *
 * @param element - the element to be found.  
 * @returns the element, if found.
 */ 
function newDollar(element) {
  
  var ret = null ;
  if (element == null || typeof element == "Element") {
    ret = element ;
  }
  else if (Object.isString(element)) {  
    if (Def.IDCache.fullIDcache_ != null) 
      ret = Def.IDCache.findByID(element);
    if (ret == null) {
      ret = document.getElementById(element) ;
      if (ret) {
        ret = Element.extend(ret) ;
        Def.IDCache.addToCache(ret) ;
      }
    }
  }
  // else assume this is an object
  else if (arguments.length == 1) {
    if (element.getAttribute) {
      var elemID = Def.IDCache.getID(element) ;
      if (elemID) { 
        ret = Def.IDCache.findByID(elemID) ;    
        if (ret == null) {
          Def.IDCache.addToCache(element) ;
          ret = Def.IDCache.findByID(elemID) ;
        }
      }
      else {
        ret = Element.extend(element) ;
      }
    }
    else
      ret = Element.extend(element) ;
  }
  else {  // multiple arguments
    for (var i = 0, elements = [], il=arguments.length; i < il; ++i)
      elements.push(newDollar(arguments[i])) ;
    ret = elements ;
  }
  return ret ;
} // end newDollar


/* This function should be used instead of prototype's
 * hasClassName function whenever multiple class names are being
 * checked.
 *
 * @param element the element to be checked for a class name
 *  that matches one passed in
 * @param className a string or an array of class names to be
 *  checked to see if the element passed in has one of them.
 *  Multiple class name specifications MUST be specified in an
 *  array.
 *
 * @returns true if the specified className or one of the 
 *  specified classNames are applied to the element passed in.
 */
function checkClassName(element, className) {

  var ret = false ;
  var eleClass = element.className ;
  if (eleClass.length > 0) {
    eleClass = ' ' + eleClass + ' ' ;
    if (Object.isString(className)) {
      ret = eleClass.indexOf(' ' + className + ' ') >= 0 ;
    }
    else {
      for (var c = 0, cl = className.length; !ret && c < cl; c++) 
        ret = eleClass.indexOf(' ' + className[c] + ' ') >= 0 ;
    }
  }
  return ret ;
  
} // end checkClassName

// redefine jQuery's $ function to $J
if (typeof jQuery !='undefined' && jQuery !=null ) {
  if (Def.Logger)
    Def.Logger.logMessage(['Redefine $ in jQuery to $J']);
  var $J = jQuery.noConflict();
}

// redefine prototype's $ function
this.oldDollar = this.$ ;
this.$ = this.newDollar ;

// Set up the ID cache.  This is okay to do as long as this file gets
// loaded in the bottom part of the page (after the page is defined),
// as it now does.  We want it loaded right away, before other JavaScript
// needs the cache (possibly before the pages gets the load event).
var start = new Date().getTime(); 
Def.IDCache.addToCache($$('body')[0]);
if (Def.Logger) {
Def.Logger.logMessage(['Cached ID elements in ',
             (new Date().getTime()-start)/1000, 's']);
}
