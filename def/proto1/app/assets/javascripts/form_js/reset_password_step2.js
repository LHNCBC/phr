/**
 * reset_password_step2.js -> javascript class that contains functions
 *      specific to the reset_password_step2 form. Members of this class
 *      should be specific to the reset_password_step2 form.
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Bascially,
 * you can use the code as long as you give NLM credit.
 *
 *  $Log: reset_password_step2.js,v $
 *  Revision 1.2  2010/12/17 17:42:49  mujusu
 *  peccling correction etc
 *
 *  Revision 1.1  2010/11/10 18:31:23  mujusu
 *  radio button selection javascrtiot. Hides/shows sections
 *
 */
Def.ResetSecurity = {
  /*
   * when user selects one option from toggle button
   */
  onRadio: function(ele) {
    if (ele != null && ele.value == 'questions') {
      online = $('fe_select_on_grp_1_0');
      online.style.display = 'block';
    } 
    else {
      online = $('fe_select_on_grp_1_0');
      online.style.display = 'none';
    }
  },

  onLoadRadio: function() {
    $('fe_select_on_grp_1_0').style.display = 'none';
     reset = $('fe_email_option_radio_1R_1_1') ;
     reset.checked="yes" ;
  }
}  // end Def.ResetSecurity

Event.observe(window,'load',Def.ResetSecurity.onLoadRadio) ;