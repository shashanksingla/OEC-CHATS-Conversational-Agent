/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/30/2017                                                          
*  @description    Custody Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 30-Nov-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version                                                 
*  *CHAT-1175: When Save is clicked, show a warning message (""This record may not be appropriate for this individual
*  *		   based on their age and/or relationship to the primary caretaker of this case"") 
*  *		   on the screen only for individuals who:
*  *           -are 19 and older (Validation Rule )
*  *           -are younger than 19 but have a relationship of mother, father, spouse, common law husband, 
*  *            common law wife, husband, wife, live-in companion
*  *		   -are the primary caretaker
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger custodyTrigger on T_INDIV_CUST__c (before insert,before update,after insert,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('custodyTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isBefore){
        if((Trigger.isInsert) || (Trigger.isUpdate)){
            //custodyServices.primaryCareTaker(trigger.new);
        }
    }
    
    if(Trigger.isAfter) {
        //updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.pluckIds(trigger.new,'IDN_CLIENT__c'));
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_INDIV_CUST__c where Id=:trigger.newMap.keySet()],true);
        }
    }

}