trigger applicationPrcsQueueTrigger on T_APPLN_PRCS_QUEUE__c (after insert, before insert, before update, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('applicationPrcsQueueTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c, County_Name__c, CDE_COUNTY__c from T_APPLN_PRCS_QUEUE__c where Id=:trigger.newMap.keySet()],true);
            ApplicationProcessQueueService.setApplicationRecievedDate(trigger.new);
        }
        if(Trigger.isupdate) {
            ApplicationProcessQueueService.UpdApplnRcvdDateAndCreateTask115(trigger.new, trigger.oldMap);
            ApplicationProcessQueueService.captureAppUpdates_UFE(trigger.new, trigger.oldMap); // added for UFE by Shashank 08/13/24
        }
        ApplicationProcessQueueService.validateCountyWithUserCounties(trigger.newMap, trigger.oldMap);//CCCAP-14530
    }else{
        ApplicationProcessQueueService.populateCountyNameBasedOnCounty(trigger.new, trigger.oldMap);
        if(Trigger.isInsert){
            ApplicationProcessQueueService.populateApplicationProcessedDate(trigger.new);
        }
        if(trigger.isUpdate){
            ApplicationProcessQueueService.populateApplicationProcessedDateOnSearch(trigger.new, trigger.oldMap);
        }
    }
}