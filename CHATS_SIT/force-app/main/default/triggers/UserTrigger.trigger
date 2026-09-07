trigger UserTrigger on User (before update, before insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('UserTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isBefore){
        UserUpdateService.validateCounty(Trigger.new, Trigger.oldMap);//CCCAP-14971
        if(Trigger.isUpdate){
            UserUpdateService.validateUserBeforeUpdate(Trigger.new);
        }
    }
    //CCCAP-15161
    if(Trigger.isAfter && Trigger.isUpdate){
        UserUpdateService.handleReportDashboardUnsubscribe(Trigger.new, Trigger.oldMap);
}
}