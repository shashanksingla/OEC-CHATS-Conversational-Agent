/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Case HomeLess Trigger   
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field

@version 2.0 Added logic to end date the homeless record when a new record is added. //CCCAP-12639
*********************************************************************************************/
trigger CaseHomeLessTrigger on T_SBSD_CASE_HOMELESS__c  (before insert, before update, after insert, after update) {    
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CaseHomeLessTrigger')) {
        return; //rest of the lines will not be executed
    }
    
    if(Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate){
            CaseHomelessServices.validateHomeless(Trigger.new,Trigger.oldMap);
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_CASE_HOMELESS__c where Id=:trigger.newMap.keySet()],true);
            
            //Update previous record end dates when new homeless record is inserted
            CaseHomelessServices.updatePreviousRecordEndDates(Trigger.new,Trigger.oldMap);
        }
        
        if(Trigger.isUpdate) {
            //Update previous record end dates when homeless record is updated with begin date
            CaseHomelessServices.updatePreviousRecordEndDates(Trigger.new,Trigger.oldMap);
        }
    }
}