/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           
*  @description    Case Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 
*  * Author: Gaurav Dharra 
*  * Description: Initial version                                                 
*  * Update DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c after case is updated
*********************************************************************************************/
trigger CaseTrigger on T_SBSD_CASE__c (after insert, after update, before update, before delete) {
    
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CaseTrigger')) {
        return; //rest of the lines will not be executed
    }
    // added for CCCAP-14909
    if(CaseLastUpdatedServices.disableTrigger){
        return;
    }
    
    If(Trigger.isAfter){       
        if(Trigger.isInsert){
            CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(trigger.newMap.keySet()); // modified for CCCAP-14909
            CaseLastUpdatedServices.disableTrigger = true; // added for CCCAP-14909
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_CASE__c where Id=:trigger.newMap.keySet()],true);
            CaseLastUpdatedServices.disableTrigger = false; // added for CCCAP-14909
            CaseLastUpdatedServices.updateCaseNameField(trigger.newMap.keySet()); // CHATS-3939 and CHATS-3937
            //CaseLastUpdatedServices.insertATSRecord(trigger.new);
            CaseLastUpdatedServices.resetBypassValidationFlag(trigger.newMap.keySet()); // Added by Rishav for CCCAP-2720
        }
        
        if(Trigger.isUpdate){
            if(checkRecursive.runOnce()) {
                CaseLastUpdatedServices.checkIfTriggerExecuted = false;
                CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(CaseLastUpdatedServices.filterCaseIds(trigger.new, trigger.oldMap));
               // CaseLastUpdatedServices.updateRefInfo(trigger.newMap);   
            }
            
        }       
    } else {
        if(Trigger.isUpdate){
            CaseLastUpdatedServices.updateLastRedeterminationDate(trigger.new, trigger.oldMap);
        }
        if(Trigger.isDelete){
        	CaseServices.deleteChildRecords(trigger.old);
        }
    }
}