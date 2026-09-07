trigger applicationPrcsSearchTrigger on T_APPLN_PRCS_SEARCH__c (after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('applicationPrcsSearchTrigger')) {
        return; //rest of the lines will not be executed
    }

	    If(Trigger.isAfter){
        	if(Trigger.isInsert) {
            	//copying salesforce Id to External Id
            	CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_APPLN_PRCS_SEARCH__c where Id=:trigger.newMap.keySet()],true);
        	}
    	}
}