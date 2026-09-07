trigger AccountTrigger on Account (after insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('AccountTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter){
        AccountServices.chatProvrUpd(Trigger.New);
    } 
}