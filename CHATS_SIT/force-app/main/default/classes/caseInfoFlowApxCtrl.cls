public with sharing class caseInfoFlowApxCtrl {
    @AuraEnabled
    public static LightningServerResponse getDoInit(String recordId){
        Map<String, Object> objectData = new map<String, Object>();
        //List<PicklistOption> CaseInfoTypeOptions = new List<PicklistOption>();
        
        Boolean isSuccessful = true;
        String message='';
        String sObjectName;
        /*CaseInfoTypeOptions.add(new PicklistOption(
            '--None--', ''                 
        ));
        
        CaseInfoTypeOptions.add(new PicklistOption(
            'Primary Method Of Contact', 'PMC'                 
        ));*/
        if(String.isNotBlank(recordId)){
            sObjectName = CHATSAuraUtility.getSobjectName(recordId);
            
        }
       
        if(sObjectName =='T_SBSD_CASE_INFO__c'){
            List<T_SBSD_CASE_INFO__c> CseinfotypLst = [Select id, Name,CDE_TYPE_INFO_CASE__c,TXT_VALUE_INFO_CASE__c,IDN_CASE__c from T_SBSD_CASE_INFO__c where id=:recordId];
            if(CseinfotypLst != null && CseinfotypLst.size()>0){
                objectData.put('sbsdcaseinfoRec',CseinfotypLst[0]);
                
            }
        }
        /*system.debug('CaseInfoTypeOptions---'+CaseInfoTypeOptions);
        objectData.put('CaseInfoTypeOptions',CaseInfoTypeOptions);*/
        objectData.put('getSobjectName',sObjectName);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
  
    

}