/**
 * forgot_id_step2.js -> javascript class that contains functions
 *      specific to the reset_password_step2 form. Members of this class
 *      should be specific to the reset_password_step2 form.
 *
 * License:  This file should be considered to be under the terms of some
 * "non-viral" open source license, which we will specify soon.  Bascially,
 * you can use the code as long as you give NLM credit.
 *
 *  $Log: forgot_id_step2.js,v $
 *  Revision 1.1  2010/11/10 18:25:17  mujusu
 *  radio button hide/show function
 *
 */
Def.VerifySecurity = {
  /*
   * when user selected one option from toggle button
   */
  onRadio: function(ele) {
    if (ele != null && ele.value == 'password') {
      var online = $('fe_passwd_ans_lbl_1_1').parentNode ;
      online.style.display = 'block';

      online = $('fe_chall_quest_lbl_1_1').parentNode ;
      online.style.display = 'none';
      online2 = $('fe_chall_answ_1_1').parentNode ;
      online2.style.display = 'none';
    } 
    else {
      online = $('fe_passwd_ans_lbl_1_1').parentNode ;
      online.style.display = 'none';

      online = $('fe_chall_quest_lbl_1_1').parentNode ;
      online.style.display = 'block';
      online2 = $('fe_chall_answ_1_1').parentNode ;
      online2.style.display = 'block';
    }
  },

  onLoadRadio: function() {
      var reset = $('fe_reset_option_radio_1R_1')
      reset.checked="yes"
      var online = $('fe_passwd_ans_lbl_1_1').parentNode ;
      online.style.display = 'block';

      online = $('fe_chall_quest_lbl_1_1').parentNode ;
      online.style.display = 'none';
      online2 = $('fe_chall_answ_1_1').parentNode ;
      online2.style.display = 'none';
  }
}  // end Def.ResetSecurity

Event.observe(window,'load',Def.VerifySecurity.onLoadRadio)