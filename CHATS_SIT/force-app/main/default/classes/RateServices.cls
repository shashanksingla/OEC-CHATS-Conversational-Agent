public class RateServices {

    public static void checkRateTypeAndPopulateSchedule(List<T_FISCAL_RATE__c> newRateList){
        List<Id> lstRateScheduleIds = new List<Id>();
        for(T_FISCAL_RATE__c newRate :newRateList ){
            newRate.Rate_Schedule__c = newRate.IDN_FISCAL_SCH__c;
            lstRateScheduleIds.add(newRate.Rate_Schedule__c);
        }
        Map<Id,List<String>> rateScheduleToRateTypeMap = new Map<Id, List<String>>();
        for(T_FISCAL_SCH__c rateSchedule: [Select id, CDE_RATE_TYPE__c from T_FISCAL_SCH__c where id in :lstRateScheduleIds ]){
            if(rateSchedule.CDE_RATE_TYPE__c !=null){
               rateScheduleToRateTypeMap.put(rateSchedule.Id, rateSchedule.CDE_RATE_TYPE__c.split(';'));
            }
        }
        for(T_FISCAL_RATE__c newRate :newRateList ){
            if( rateScheduleToRateTypeMap.containsKey(newRate.IDN_FISCAL_SCH__c) && !rateScheduleToRateTypeMap.get(newRate.IDN_FISCAL_SCH__c).contains(newRate.CDE_RATE_TYPE__c)){
                newRate.addError('The Rate Type does not belong to the Schedule');
            }
        }
    }
}