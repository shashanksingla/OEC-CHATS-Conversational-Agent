/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Job Search Trigger   
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger jobSearchTrigger on T_JOB_SEARCH__c (after insert,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('jobSearchTrigger')) {
        return; //rest of the lines will not be executed
    }

if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_JOB_SEARCH__c where Id=:trigger.newMap.keySet()],true);
        }
        
        //CHATS-5148 Defect Fix to update Eligiblity Date Changed on Case
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.pluckIds(
                 trigger.new, 'IDN_CLIENT__c'));
    }
}