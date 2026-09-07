trigger CannedReportRequestTrigger on Canned_Report_Request__c (after insert) {
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from Canned_Report_Request__c where Id=:trigger.newMap.keySet()],true);
        }
    }
}