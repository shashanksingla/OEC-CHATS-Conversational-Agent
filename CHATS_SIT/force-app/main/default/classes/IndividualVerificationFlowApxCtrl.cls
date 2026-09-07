public with sharing class IndividualVerificationFlowApxCtrl {
    
    @AuraEnabled
    public static LightningServerResponse getInitData(String indivId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<T_SBSD_INDIV__c> individual = [SELECT NAM_FIRST__c, NAM_LAST__c,DTE_DOB__c, 
                                      IND_CDE_TYPE_VERIF_DOB__c, CDE_SOURCE_VRFYD_DOB__c, 
                                      CDE_SOURCE_VRFYD_CITIZEN__c, CDE_VRFYD_IDNTY__c, 
                                      CDE_SOURCE_VRFYD_IDNTY__c,
                                      (SELECT Id,Individual_Status__c,IDN_CLIENT__c, DTE_END_EFFV__c from Case_Individual__r where IDN_CLIENT__c=:indivId),     
                                      (SELECT Id FROM Individual_Information__r WHERE CDE_TYPE_INFO_INDIV__c = 'CS')
                                      FROM T_SBSD_INDIV__c WHERE Id = :indivId LIMIT 1]; //Added case individual for CCCAP-13633
        List<T_INDIV_VERIF__c> indVerif = [SELECT CDE_TYPE_VERIF__c, CDE_TYPE_INFO_INDIV__c FROM T_INDIV_VERIF__c WHERE IDN_CLIENT__r.IDN_CLIENT__c = :indivId AND CDE_TYPE_INFO_INDIV__c = 'CS' LIMIT 1];
        objectData.put('individual',individual.get(0));
        objectData.put('indVerif',indVerif.isEmpty()?new T_INDIV_VERIF__c(CDE_TYPE_INFO_INDIV__c='CS'):indVerif.get(0));
        isSuccessful = true;
        return new LightningServerResponse(isSuccessful,message,objectData);        
    }
    
    @AuraEnabled
    public static LightningServerResponse isReadOnlyProfile(){
        String message;
        Map<String, Object> objectData = new Map<String, Object>();
        //String loggedInUserProfile = [Select Id,Name from Profile where Id=:userinfo.getProfileId() limit 1].Name; Commenting as using custom permission CCCAP-14993
        //Using Custom permission CCCAP-14993
        if(FeatureManagement.checkPermission('Fiscal_Worker') || FeatureManagement.checkPermission('Fiscal_Worker_Supervisor') || FeatureManagement.checkPermission('Read_Only_User')){
            objectData = new map<String, Object>{'isReadOnly' => true};
        }
        return new LightningServerResponse(true,message,objectData);
    }
}