trigger IDXRStagingTrigger on T_IDXR_STG_DELETE__c (after insert) {
    if(TriggersOnOffServices.triggerStatus('IDXRStagingTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_IDXR_STG_DELETE__c where Id=:trigger.newMap.keySet()], true);
        }
    }
}