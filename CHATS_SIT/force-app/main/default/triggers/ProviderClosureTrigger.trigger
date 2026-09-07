trigger ProviderClosureTrigger on T_PROVR_CLOSURE__c (before delete) {
	//Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('ProviderClosureTrigger')) {
        return; //rest of the lines will not be executed
    }
    
    if(Trigger.isBefore){        
        if(Trigger.isDelete){
            ProviderClosureUtility.checkIfDeleteAllowed(Trigger.old);
        }
    }
}