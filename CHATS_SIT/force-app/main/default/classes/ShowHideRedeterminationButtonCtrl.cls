public With Sharing class ShowHideRedeterminationButtonCtrl {
    @AuraEnabled
    public static LightningServerResponse getInitData(String caseId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        
        List<T_SBSD_CASE__c> caseRecord = new List<T_SBSD_CASE__c>
            (
                [SELECT Id,Name,CDE_COUNTY__R.NAME,OWNER.NAME, Program_Type__c
                 FROM T_SBSD_CASE__c WHERE Id =:caseId]
            );
        if(String.isNotBlank(caseId)){
            String pgmType = caseRecord[0].Program_Type__c != null ? caseRecord[0].Program_Type__c : CaseHeaderApxCtrl.getChildCareProgram(caseId);
            objectData.put('childCareProgram', pgmType); 
        }
        if(!caseRecord.isEmpty()){
            objectData.put('caseRecord',caseRecord);
            isSuccessful=true;
        }
        else{
            isSuccessful=false;
            message = Label.caseRecord_Not_Found;
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
}