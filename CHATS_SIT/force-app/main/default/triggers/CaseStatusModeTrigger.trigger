/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Case Status Mode Trigger   
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger CaseStatusModeTrigger on T_SBSD_CASE_STATUS_MODE__c (after insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CaseStatusModeTrigger')) {
        return; //rest of the lines will not be executed
    }
    // added for CCCAP-14909
    if(CaseStatusModeService.disableTrigger){
        return;
    }
    if(trigger.isAfter) {
        if(trigger.isInsert){
            CaseStatusModeService.updateTaskStatus(trigger.new);
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_CASE_STATUS_MODE__c where Id=:trigger.newMap.keySet()],true);
            CaseStatusModeService.insertATSRecord(trigger.new);
            CaseStatusModeService.createTaskT112(trigger.new, null);
            CaseStatusModeService.updateCase(trigger.new);
            CaseStatusModeService.markReverseReferTrack(Trigger.new,null);
            CaseStatusModeService.captureUpdate_UFE(Trigger.new,trigger.oldMap); // added for UFE by Shashank 08/13/24
        }
        else if(trigger.isUpdate){
            List<T_SBSD_CASE_STATUS_MODE__c> caseStatusModeToCreateATS = new List<T_SBSD_CASE_STATUS_MODE__c>();
            for(T_SBSD_CASE_STATUS_MODE__c newCaseStatusMode:trigger.new){
                if(newCaseStatusMode.IDN_EXTNL__c==trigger.oldMap.get(newCaseStatusMode.Id).IDN_EXTNL__c){
                    caseStatusModeToCreateATS.add(newCaseStatusMode);
                }
            }
            if(!caseStatusModeToCreateATS.IsEmpty()){
                CaseStatusModeService.insertATSRecord(caseStatusModeToCreateATS);
            }
            CaseStatusModeService.createTaskT112(trigger.new, trigger.oldMap);
            CaseStatusModeService.markReverseReferTrack(Trigger.new,trigger.oldMap);
            CaseStatusModeService.captureUpdate_UFE(Trigger.new,trigger.oldMap); // added for UFE by Shashank 08/13/24
        }
    }
}