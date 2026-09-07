public with sharing class RATFeesServices {
    public static final String CR707RsnCode = 'CR0016';
    public static void triggerCorspdCR707(List<T_FISCAL_RAT_FEES__c> newRATFeesList){
        set<Id> rateSchedules = new set<Id>();
        Map<string,string> keyParams = new Map<string, string>();
        integer countyCode;
        
        for(T_FISCAL_RAT_FEES__c eachRATFees: newRATFeesList){
            if(eachRATFees.IDN_FISCAL_SCH__c != NULL){
               rateSchedules.add(eachRATFees.IDN_FISCAL_SCH__c );
            }
        }
        
        map<Id, T_FISCAL_SCH__c> ratFeesFiscalAgrmntMap = new map<Id, T_FISCAL_SCH__c>([select Id, IDN_AGRMT_FISCAL__c, IDN_AGRMT_FISCAL__r.Name, IDN_AGRMT_FISCAL__r.CDE_COUNTY__r.CDE_COUNTY__c, IDN_AGRMT_FISCAL__r.ID_SERVICE__r.Name FROM T_FISCAL_SCH__c WHERE Id IN:rateSchedules]);
        
        for(Id eachRateSchedule: ratFeesFiscalAgrmntMap.keySet()){
            if(ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__r.CDE_COUNTY__c != NULL){
                decimal cntyCode = ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__r.CDE_COUNTY__r.CDE_COUNTY__c;
                countyCode = integer.valueOf(cntyCode);
            }
            if(ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__c != NULL){
                keyParams.put('faId', ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__c);
            }
            if(ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__r.ID_SERVICE__c != NULL){
                keyParams.put('providerId', ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__r.ID_SERVICE__r.Name);
            }            
            CorspdTrigger.createCorspdRequest(CR707RsnCode,NULL,NULL,countyCode,keyParams);
        }
    }

}