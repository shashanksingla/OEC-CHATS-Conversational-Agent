global with sharing  class CountyDropInDaysBatchApxCtrl implements 
Database.Batchable<sObject>, Database.Stateful {
    
    public List<T_AUTH__c> authNameList = new List<T_AUTH__c>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate =  System.today();
        String status = 'APV';
        Boolean isTemplate = false;
        String queryStr = 'SELECT Id, CFS_Q1__c, CDE_STATUS__c, PAYMENT_Q14__c, PAYMENT_Q14_1__c, IDN_COUNTY__c, PAYMENT_Q11_3__c FROM T_COUNTY_RATE__c WHERE DTE_BEGIN_EFFV_RATE__c =: todayDate AND (DTE_END_EFFV_RATE__c >=: todayDate OR DTE_END_EFFV_RATE__c = null) AND CDE_STATUS__c=: status AND IND_RATE_PLAN_TEMPLT__c =:isTemplate and County_Rate_Plan__c=NULL';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_COUNTY_RATE__c> countyRateList) {
        Map<Id, List<T_COUNTY_RATE__c>> countyMap = new Map<Id, List<T_COUNTY_RATE__c>>();
        List<T_AUTH__c> authList = new List<T_AUTH__c>();
        List<Id> countyLst2 = new List<Id>(); // Added by Rishav for CCCAP-2929
        Date todayDate = System.today();
        for(T_COUNTY_RATE__c countyRate : countyRateList){
            if(!countyMap.containsKey(countyRate.IDN_COUNTY__c)){
                countyMap.put(countyRate.IDN_COUNTY__c, new List<T_COUNTY_RATE__c>{countyRate});
            } else {
                List<T_COUNTY_RATE__c> countyLst = (countyMap.get(countyRate.IDN_COUNTY__c));
                countyLst.add(countyRate);
                countyMap.put(countyRate.IDN_COUNTY__c,countyLst);
            }
            // Added below 'if' by Rishav for CCCAP-2929
            if(countyRate.PAYMENT_Q11_3__c == 'N')
                countyLst2.add(countyRate.IDN_COUNTY__c); // Counties where Child Transportation fee will be cleared at Auth level
        }
        for(T_AUTH__c authRec :[SELECT Id, Name, Number_of_Drop_in_Days__c, CDE_COUNTY__c, CDE_TRANS_FEE__c FROM T_AUTH__c WHERE CDE_COUNTY__c IN:countyMap.keySet() AND DTE_END_EFFV_AUTH__c  >=:todayDate]){
            // Added below 'if' by Rishav for CCCAP-2929
            if(countyLst2.contains(authRec.CDE_COUNTY__c))
                authRec.CDE_TRANS_FEE__c = null;
            authRec.Number_of_Drop_in_Days__c = 0;
            authList.add(authRec);
            authNameList.add(authRec);
        }
        if(authList!= null && authList.size() > 0){
            GenericDMLHandler.updateRecords(authList,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'CountyDropInDaysBatchApxCtrl'});
        } 
    }
    
    global void finish(Database.BatchableContext bc) {
        if(!authNameList.isEmpty() && authNameList.size() > 0){
            AuthorizationStatusController.insertATSRecords(authNameList);
        }
    }
}