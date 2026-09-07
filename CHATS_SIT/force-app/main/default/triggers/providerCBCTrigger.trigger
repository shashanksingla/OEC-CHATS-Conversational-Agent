trigger providerCBCTrigger on T_PROVR_CBC__c (after insert, after Update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('providerCBCTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        if((Trigger.isInsert) || (Trigger.isUpdate)) {
            providerCBCServices.provrCBCResults(Trigger.New);
            providerCBCServices.updateProviderFields(Trigger.New); // Added by Rishav for CCCAP-4768
            providerCBCServices.generateT218Task(Trigger.New, Trigger.oldMap); // Added by Rishav for CCCAP-4768
        }
    }
}