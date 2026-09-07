public without sharing class ChildCareLastUpdatedServices {
    public static void updateRefInfo(List<T_APPLN_CHILD_CARE__c> childCareNewList, Map<Id, T_APPLN_CHILD_CARE__c> childCareNewMap,List<T_APPLN_CHILD_CARE__c> childCareList) {
        Map<String,List<T_APPLN_CHILD_CARE__c>> childCareMap = new Map<String,List<T_APPLN_CHILD_CARE__c>>();
        if(childCareList == null && childCareNewMap !=null && childCareNewMap.size()>0){
             childCareList = [SELECT id,CHILD_NAME__c,IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.CDE_CBMS_REF_TYP__c,CNT_HOUR_ON_FRI__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_APPLN__c,
                                                     CNT_HOUR_ON_MON__c,CNT_HOUR_ON_SAT__c,CNT_HOUR_ON_SUN__c,CNT_HOUR_ON_THU__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_CBMS_REF__c,
                                                     CNT_HOUR_ON_TUE__c,CNT_HOUR_ON_WED__c,IDN_CBMS_PROVR__c,IDN_INDIVIDUAL__c,NAM_FACILITY__c from T_APPLN_CHILD_CARE__c where id IN:childCareNewMap.keySet() WITH SECURITY_ENFORCED];
        }
       
        for(T_APPLN_CHILD_CARE__c care:childCareList){
            String key= String.valueOf(care.IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_APPLN__c)+'_'+String.valueOf(care.IDN_INDIVIDUAL__r.IDN_CLIENT__c);
            if(childCareMap.containsKey(key)){
                List<T_APPLN_CHILD_CARE__c> childCareTemp = childCareMap.get(key);
                childCareTemp.add(care);
                childCareMap.put(key,childCareTemp);
            }else{
                List<T_APPLN_CHILD_CARE__c> childCareTemp = new List<T_APPLN_CHILD_CARE__c>();
                childCareTemp.add(care);
                childCareMap.put(key,childCareTemp);
            }
        }
        for(String care:childCareMap.keySet()){
            List<T_APPLN_CHILD_CARE__c>childCareListFinal = childCareMap.get(care);
            APXPolicyRecordsServices.createRefData(childCareListFinal[0].IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_CBMS_REF__c ,childCareListFinal[0].IDN_INDIVIDUAL__r.IDN_APPLN__r.CDE_CBMS_REF_TYP__c,childCareListFinal);
            
        }
    }
}