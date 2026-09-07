public with sharing class NewRelationshipController {
    @AuraEnabled
    public static LightningServerResponse getDoInit(String recordId){
        
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        String sObjectName;
        if(String.isNotBlank(recordId)){
            sObjectName = CHATSAuraUtility.getSobjectName(recordId);
        }
        
        if(sObjectName =='T_INDIV_REL__c'){
            List<T_INDIV_REL__c> inidvRelLst = [Select id, Name,CDE_SOURCE_VRFYD_REL__c,CDE_TYPE_REL_INDIV__c, CDE_TYPE_VERIF__c,IDN_CLIENT__c,IDN_CLIENT_RELTD__c,
                                                DTE_BEGIN_EFFV__c, DTE_END_EFFV__c from T_INDIV_REL__c where id=:recordId];
            if(inidvRelLst != null && inidvRelLst.size()>0){
                objectData.put('relRec',inidvRelLst[0]);
            }
        }

        objectData.put('getSobjectName',sObjectName);
        return new LightningServerResponse(true,message,objectData);
    }
}