trigger CountyRateTrigger on T_COUNTY_RATE_AMT__c (after update, after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CountyRateTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            CountyRateServices.updateCountyRateAmountsOnFTAmtUpdate(CountyRateServices.filterFTRatesWhereAmtIdUpdated(Trigger.new, Trigger.oldMap,true),true);
        }
        if(Trigger.isInsert){
        CountyRateServices.updateCountyRateAmountsOnFTAmtUpdate(CountyRateServices.filterFTRatesWhereAmtIdUpdated(Trigger.new,null,false),false);
        }
    }
}