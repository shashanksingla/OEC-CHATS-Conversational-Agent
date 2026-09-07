/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/11/2017                                                          
*  @description    Disability Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 17-Nov-2017                                                             
*  * Author: Shubham Jain                                                      
*  * Description: Initial version; 
*  * JIRA Ticket: CHAT-379
*  * 1. Populate T_INDIV_DSBLTY.IND_REQMT_WORK_MEET_ABLE with 'N' if Client is not the primary caretaker AND is younger than 19 and does not have a relationship of mother, father, spouse, common law husband, common law wife, husband, wife, live-in companion else 'Y'.
*  * 2. Enforce required validation for T_INDIV_DSBLTY.CDE_LENGTH_DSBLTY if individual is 19 or older AND/OR is the primary caretaker OR is younger than 19 and has a relationship of mother, father, spouse, common law husband, common law wife, husband, wife, live-in companion.
*  * Version: 2.0                                                                             
*  * Date: 01-Dec-2017                                                             
*  * Author: Azharuddin Mohammad
*  * JIRA Ticket: CHAT-1197, CHAT-1198
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger DisabilityTrigger on T_INDIV_DSBLTY__c (before insert,before Update, after insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('DisabilityTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isBefore){
        DisabilityServices.updateFields(trigger.new);
    }
    
    If(Trigger.isAfter){
        //updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.pluckIds(
                trigger.new, 'IDN_CLIENT__c')
        );
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_INDIV_DSBLTY__c where Id=:trigger.newMap.keySet()],true);
        }
    }
}