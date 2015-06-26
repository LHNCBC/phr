/* This file contains application-specific code, i.e. code that is not
 * part of the FFAR framework but part of an application using the framework.
 */

/**
 *  The SET_VAL_DELIM string escaped for inclusion in a regular expression.
 */
Def.ESCAPED_SET_VAL_DELIM = null;


/**
 *  Initializes application-specific variables used by code in app_specific.
 */
Def.appSpecificInit = function() {
  Def.ESCAPED_SET_VAL_DELIM = Def.SET_VAL_DELIM.replace(/\|/, '\\|');
};
