/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Child Support Enforcement Trigger   
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger childSupportTrigger on T_CHILD_SUP__c (after insert,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('childSupportTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_CHILD_SUP__c where Id=:trigger.newMap.keySet()],true);
        }
        
         //CHATS-5148 Defect Fix to update Eligiblity Date Changed on Case
         CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.pluckIds(
                 trigger.new, 'IDN_CLIENT__c')
        );
    }
}