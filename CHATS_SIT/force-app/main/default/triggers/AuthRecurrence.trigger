trigger AuthRecurrence on Auth_Schedule_Recurrence__c (before update) {
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
             AuthorizationServices.duplicateRecurrenceCheck(Trigger.new,Trigger.oldMap);
             AuthorizationServices.updateRecurrence(Trigger.new,Trigger.oldMap);
        }
        
    }
}