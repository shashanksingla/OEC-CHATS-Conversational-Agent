trigger adjustmentAddressTrigger on T_ADJMT_ADDR__c (after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('adjustmentAddressTrigger')) {
        return; //rest of the lines will not be executed
    }
	if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_ADJMT_ADDR__c where Id=:trigger.newMap.keySet()],true);
        }
    
    }
}