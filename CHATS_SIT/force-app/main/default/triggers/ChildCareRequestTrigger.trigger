/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/20/2017                                                          
*  @description    Child Care Request Trigger                             
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
trigger ChildCareRequestTrigger on T_INDIV_CAT_RQ__c  (after insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('ChildCareRequestTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        //updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c
        CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(
         CaseLastUpdatedServices.getCaseIds(CaseLastUpdatedServices.getIndividualsFromRelationship('IDN_CASE_INDIV__r.IDN_CASE__c','T_INDIV_CAT_RQ__c',trigger.new)));
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_INDIV_CAT_RQ__c where Id=:trigger.newMap.keySet()],true);
        }
    
    }
}