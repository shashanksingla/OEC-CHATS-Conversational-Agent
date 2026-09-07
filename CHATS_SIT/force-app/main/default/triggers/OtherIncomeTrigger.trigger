/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/20/2017                                                          
*  @description    Other Income Trigger                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 20-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                     
*  * Description: Initial version                                                 
*  * updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c

*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger OtherIncomeTrigger on T_INDIV_OTHER_INCOME__c (after insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('OtherIncomeTrigger')) {
        return; //rest of the lines will not be executed
    }
     if(Trigger.isAfter) {
        //updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.pluckIds(trigger.new,'IDN_CLIENT__c'));
         if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_INDIV_OTHER_INCOME__c where Id=:trigger.newMap.keySet()],true);
        }
    }

}