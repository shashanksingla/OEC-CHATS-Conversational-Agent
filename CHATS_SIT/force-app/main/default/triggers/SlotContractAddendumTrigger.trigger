trigger SlotContractAddendumTrigger on T_SLOT_CONTRACT_ADDENDUM__c (before delete) {
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            SlotContractAddendumServices.beforeDeleteCheckAddendumStatus(Trigger.old);
        }
    }
}