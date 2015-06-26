/*
 * admin_index.js -> javascript functions to support the Admin Management form.
 *
 *$Log: admin_index.js,v $
 *Revision 1.3  2010/09/23 19:11:40  mujusu
 *fixed comment
 *
 *Revision 1.2  2010/09/23 15:28:41  mujusu
 *fixed comments
 *
 *Revision 1.1  2010/03/24 18:50:01  mujusu
 *for admin page tasks
 *
 */

Def.PHRAdminManagement = { 
  /**
   *  Invokes an action specified on the phr admin form
   * @param formNameFld the field containing the id of the phr form
   * on which to  take the action
   * @param event the submit event to be stopped if the action is handled
   *  in a different way (i.e., not through submitting the form)
   */
  doAdminAction: function(formNameFld,event) {
    var form = $(formNameFld).value;
    if (form){
      Def.setDocumentLocation("/forms/" + form + "/rules") ;
      Event.stop(event) ;
      return true ;
    }
    else{
      Event.stop(event) ;
      return false;
    }
  }
}  //End of Def.PHRAdminManagement
