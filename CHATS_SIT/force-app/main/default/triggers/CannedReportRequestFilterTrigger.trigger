trigger CannedReportRequestFilterTrigger on Canned_Report_Request_Filter__c (after insert) {
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from Canned_Report_Request_Filter__c where Id=:trigger.newMap.keySet()],true);
        }
    }
}