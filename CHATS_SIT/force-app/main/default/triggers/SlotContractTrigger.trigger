trigger SlotContractTrigger on T_SLOT_CONTRACT__c (after insert, after update, before delete) {
    
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('SlotContractTrigger')) {
        return; //rest of the lines will not be executed
    }
    
    if(Trigger.isAfter){
        SlotContractUtility.insertATSRecord(Trigger.new);
    }
    if(Trigger.isBefore){
        SlotContractUtility.updateAuthSlotBegin(Trigger.old);
        if(Trigger.isDelete){
            SlotContractUtility.checkIfDeleteAllowed(Trigger.old);
        }
    }
}