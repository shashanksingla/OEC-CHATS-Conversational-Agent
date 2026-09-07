trigger primaryActivityCounterTrigger on T_PRIM_ACTV_CNTR__c (after insert, after Update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('primaryActivityCounterTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        if((Trigger.isInsert) || (Trigger.isUpdate)) {
            primaryActivityCounterServices.createT105task(trigger.new); 
        }
        
        //CHATS-5148 Defect Fix to update Eligiblity Date Changed on Case
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.pluckIds(
                 trigger.new, 'IDN_CLIENT__c'));
        
    }
}