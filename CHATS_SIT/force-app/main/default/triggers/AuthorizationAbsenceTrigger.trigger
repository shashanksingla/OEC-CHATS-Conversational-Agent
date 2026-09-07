trigger AuthorizationAbsenceTrigger on T_AUTH_ABSENCE__c (after insert) {
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_AUTH_ABSENCE__c where Id=:trigger.newMap.keySet()],true);
        }
    }
}