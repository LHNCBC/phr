/**
 *  formBuilder.js -> A class for javascript functions specific to the form
 *                    builder.
 * $Id: formBuilder.js,v 1.4 2009/02/12 23:34:23 lmericle Exp $
 * $Source: /proj/cvs/def/proto1/public/javascripts/formBuilder.js,v $
 * $Author: lmericle $
 *
 * $Log: formBuilder.js,v $
 * Revision 1.4  2009/02/12 23:34:23  lmericle
 * added skeleton for checking circularHeadingHierarchy
 *
 * Revision 1.3  2009/02/09 22:09:55  lmericle
 * changes in progress
 *
 * Revision 1.2  2008/10/24 21:34:31  wangye
 * bug fixes for IE7 and performance tune-up
 *
 * Revision 1.1  2008/07/22 17:26:16  lmericle
 * added
 *
 */
 
MAX_LENGTH = 14  // Maximum length for a target_field
 
Def.FormBuilder = {}

// Extend Def.FormBuilder, not Def.FormBuilder.prototype, because we are 
// using Def.FormBuilder more as a namespace than a class.
Object.extend(Def.FormBuilder, { 
  
  /**
   *  This function creates a target_field value for a field definition
   *  based on a display_name value or other specified string.  The 
   *  target_field value created conforms to the following rules:
   *
   *  must be lowercase;
   *  must not be longer than MAX_LENGTH;
   *  must not match any other target_field value on the current form;
   *  must be as humanly readable as possible;
   *  must not be terminated with '_' or '_[:digit]+';
   *  must not be terminated with '_id'; and
   *  must not contain any whitespace.
   *
   *  Note:  we were going to check to make sure it was not terminated
   *         with one of the special suffixes we use for programmatically
   *         created fields - such as _ET, _HL7 and _C.  But since we're
   *         forcing target_field values here to be all lowercase, we're
   *         safe from that.
   *
   *  Parameters:
   *  * strLabel - the string that is to be used to create the target_field
   *               value.  We assume this is the display_name entered by
   *               the form designer, and so it may have spaces and be
   *               longer than the maximum length we're imposing on
   *               target_field values.
   *
   *  Returns: the target_field string
   */
  uniqueTargetField: function(strLabel) {
     
    // Create a base string from the label passed in

    var baseStr = null;
    var arrLabels = strLabel.strip().split(/\s+/);

    switch(arrLabels.length) {
       
    case 1:  // only one word, take it
      baseStr = arrLabels[0].substr(0, MAX_LENGTH);
      break;
  
    case 2:  // two words, concatenate them    
      // total length of the 2 sub fields < MAX_LENGTH
      if ((arrLabels[0].length + arrLabels[1].length) <= (MAX_LENGTH -1)) {
        baseStr = arrLabels[0] + '_' + arrLabels[1];
      }
      // take first (MAX_LENGTH/2 -1) characters of each sub label
      else {
        var intLength = Math.floor(MAX_LENGTH/2 -1);
        baseStr = arrLabels[0].substr(0, intLength) + '_' +
                  arrLabels[1].substr(0, intLength);
      }
      break;
  
    case 3:  // three words, concatenate them
      // total length of the 3 sub fields < MAX_LENGTH
      if ((arrLabels[0].length + arrLabels[1].length + 
           arrLabels[2].length) <= (MAX_LENGTH -2)) {
        baseStr = arrLabels[0] + '_' + arrLabels[1] + '_' + arrLabels[2];
      }
      // take first (MAX_LENGTH/3 -1) characters of each sub label
      else {
        var intLength = Math.floor(MAX_LENGTH/3 -1);
        baseStr = arrLabels[0].substr(0, intLength) + '_' +
                  arrLabels[1].substr(0, intLength) + '_' +
                  arrLabels[2].substr(0, intLength);
      }
      break;
  
    case 4:  // four or more words, concatenate the (first) four 
    default:
      //total length of the 4 sub fields < maxLength
      if ((arrLabels[0].length + arrLabels[1].length + 
           arrLabels[2].length + arrLabels[3].length) <= (MAX_LENGTH -3)) {
        baseStr = arrLabels[0] + '_' + arrLabels[1] + '_' + 
                  arrLabels[2] + '_' + arrLabels[3];
      }
      // take first (MAX_LENGTH/4 -1) characters of each sub label
      else {
        var intLength = Math.floor(MAX_LENGTH/4 -1);
        baseStr = arrLabels[0].substr(0, intLength) + '_' +
                  arrLabels[1].substr(0, intLength) + '_' +
                  arrLabels[2].substr(0, intLength) + '_' +
                  arrLabels[3].substr(0, intLength);
      }
      break;
    } // end switch based on word count
    
    // Set the base string to lowercase and check to make sure that no
    // illegal termination strings are present.  Replace any found with '_x'.
    baseStr = baseStr.toLowerCase();    

    // Check for a terminator of '_' or '_[:digit]+'
    if (baseStr.match(/_\d*$/)) {
      baseStr = baseStr.replace(/_\d*$/, 'x');
    }
    // Check for a terminator of '_id'
    else if (baseStr.match(/_id$/i)) {
      baseStr = baseStr.replace(/_id$/i, '_x');
    }

    // Now get a list of target_field values currently defined on the
    // form and use it to determine whether or not this one is unique.
    // If it's not, append a numerical suffix to force uniqueness.
    // (keep trying until we find one that makes it unique).

    var iSuffix = 0;
    var targetFields = $$('input[id^="fe_target_field"]');
    var targStr = baseStr ;
    
    while (!Def.FormBuilder.isUnique(targStr, targetFields)) {
      
      iSuffix++ ;
      var strSuffix = iSuffix.toString();
      
      // Simply add the suffix if the total length is within limit
      if ((baseStr.length + strSuffix.length) <= MAX_LENGTH) {
        targStr = baseStr + strSuffix;
      }
      // Otherwise reduce the string size, then add the suffix
      else {
        targStr = baseStr.substr(0, baseStr.length - strSuffix.length) + 
                  strSuffix ;
      }  
      // If this has caused the string to end in the invalid digit terminator
      // - '_[:digit]+',  Replace it with _x.
      if (targStr.match(/_\d*$/)) {
        targStr.replace(/_\d*$/,'x');
      }
    } // end do while we don't have a unique value
  
    return targStr;
  }, // end uniqueTargetField
  
  
  /**
   *  This function checks a string against the values of an array of 
   *  input fields.  If a match is not found, the check string is considered
   *  unique. 
   *
   *  Parameters:
   *  * checkStr - the string to be checked.
   *  * inpFlds  - an array of input fields whose values are to be
   *                checked against the string.
   *
   *  Returns: boolean indicating whether or not the string matched 
   *           a value found for one of the input fields
   */
  isUnique: function(checkStr, inpFlds) { 

    for (var i=0, unique = true, il=inpFlds.length; i < il  && unique; ++i)
      unique = checkStr != $F(inpFlds[i]) ;      
    return unique;
  }, 
 
  
  /**
   *  This function checks to make sure a target_field value conforms
   *  to the following rules:
   *
   *    must be lowercase;
   *    must not be longer than MAX_LENGTH;
   *    must not match any other target_field value on the current form;
   *    must not be terminated with '_' or '_[:digit]+';
   *    must not be terminated with '_id', '_ET', '_HL7' or '_C'; and
   *    must not contain any whitespace.
   *
   *  If an array of strings is passed in, it also checks the value
   *  to make sure it doesn't match any of the strings (is unique).
   *
   *  Parameters:
   *  * strTarget - the target_field value to be validated
   *  * compStrs  - an array of strings to compare this to
   *                - if passed in, will check for uniqueness
   *
   *  Returns: a string that is either empty or contains a short
   *           description of the problem(s) found that makes the
   *           target_field value invalid.  
   *
   *  Note:  if you want a valid string created, use the uniqueTargetField
   *         function
   */
  validateTargetField: function(strTarget, compStrs) {

    var problem = '' ;
    
    if (strTarget.length > MAX_LENGTH) 
      problem += 'Greater than ' + MAX_LENGTH + ' characters; ' ;
  
    if (strTarget.match(/_\d*$/)) 
      problem += 'Ends with "_" or "_[:digit]"; ' ; 
    
    else if (strTarget.match(/_id$/i)) 
      problem += 'Ends with "_id"; ' ;
    
    else if (strTarget.match(/_ET$/i)) 
      problem += 'Ends with "_ET"; ' ;
    
    else if (strTarget.match(/_HL7$/i))
      problem += 'Ends with "_HL7"; ' ; 
    
    else if (strTarget.match(/_C$/i))
      problem += 'Ends with "_C"; ' ;
    
    if (strTarget.match(/\s+/)) 
      problem += 'Includes whitespace; ' ;
   
    if (strTarget.match(/[A-Z]+/))
      problem += 'Is not all lowercase; ' ;
  
    if (compStrs) {
      var comps = compStrs.join(' ') ;
      if ((strTarget + ' ').match(comps))
        problem += 'Is not unique; ' ;
    }
    if (problem.length > 0)
      problem = problem.substr(0, problem.length - 2) ;
    
    return problem ;
  }, // end validateTargetField
  
  
  /**
   *  This function checks a group header assignment to make sure
   *  that a circular hierarchy is not being created.
   * 
   *  A circular hierarchy can exist in nested group headers,
   *  where a group header is assigned to a group that is actually
   *  a subgroup of itself.  For example:
   *    group header 1 is group header
   *    group header 2 is assigned as a subgroup of group header 1
   *    group header 3 is assigned as a subgroup of group header 2
   *    group header 1 is assigned as a subgroup of group header 3
   *    - oops!
   *
   * create rule action validateField and pass as parameter
   * this function name.  assume affected field is one to be
   * checked by passing to named function.  see rulecall, whatever,
   * in rules for how to invoke.
   *
   *  Parameters:
   *  * ckField - the field to be checked.
   *
   *  Returns: boolean indicating whether or not the a 
   *  circular hierarchy was found
   */
  circularHeaderHierarchy: function(ckField) { 

    //tbd   
    return false;
  } // circularHeaderHierarchy
  
});
