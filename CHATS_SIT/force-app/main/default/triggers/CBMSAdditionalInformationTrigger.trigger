trigger CBMSAdditionalInformationTrigger on T_CBMS_ADDNL_INFO__c (before insert,before update, after insert,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CBMSAdditionalInformationTrigger')) {
        return; //rest of the lines will not be executed
    }
    If(Trigger.isAfter){
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_CBMS_ADDNL_INFO__c where Id=:trigger.newMap.keySet()],true);
        }
        
        //CHATS-5148 Defect Fix to update Eligiblity Date Changed on Case
        CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(
            CaseLastUpdatedServices.pluckIds(trigger.new, 'IDN_CASE_CHATS__c')
        );
        if(Trigger.isUpdate) {
            CaseLastUpdatedServices.updateRefInfo(trigger.newMap);
        }
    }
     if(Trigger.isBefore){
         if(Trigger.isInsert || Trigger.isUpdate){
            CaseLastUpdatedServices.updateTANFDetailEndDate(Trigger.new, Trigger.isInsert ? true:false);
        }
        // CCCAP-4430 CHANGES
        if(Trigger.isUpdate){
             CaseLastUpdatedServices.updateTANFDetailFrequency(Trigger.new);
         }
         // CCCAP-4430 CHANGES ENDS
        
    }
}