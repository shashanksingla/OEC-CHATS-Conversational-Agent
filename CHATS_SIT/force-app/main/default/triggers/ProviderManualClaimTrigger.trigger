trigger ProviderManualClaimTrigger on Provider_Manual_Claim__c (before update,after update) {
    if(trigger.isUpdate){
        if(Trigger.isBefore){                
            ProviderManualClaimTriggerHandler.handleBeforeUpdateOps(Trigger.New,Trigger.oldMap);
        }else{
            ProviderManualClaimTriggerHandler.handleAfterUpdateOps(Trigger.New,Trigger.oldMap);
        }
    }
}