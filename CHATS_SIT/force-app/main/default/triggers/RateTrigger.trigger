trigger RateTrigger on T_FISCAL_RATE__c (before insert, before update) {
    
    /*if(Trigger.isBefore){
        if(Trigger.isInsert||Trigger.isUpdate){
           RateServices.checkRateTypeAndPopulateSchedule(Trigger.new);
        }
    }*/

}