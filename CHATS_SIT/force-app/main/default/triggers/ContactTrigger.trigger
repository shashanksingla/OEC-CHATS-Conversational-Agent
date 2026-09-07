trigger ContactTrigger on Contact (after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('ContactTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter){
        ContactServices.upsertIndividualPIN(Trigger.New);
    }
}