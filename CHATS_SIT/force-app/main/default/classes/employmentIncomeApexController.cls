/*************************************************************
Class Name	    - employmentIncomeApexController
Test Class	    - employmentIncomeApexController_Test
Description     - Common controller class for all Employment Income components
Author          - Rishav Maji
JIRA Id			- CCCAP-3041
**************************************************************/
public without sharing class employmentIncomeApexController {
    
    @AuraEnabled
    public static LightningServerResponse getInitData(String recordId){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        String employmentType;
        try {
            Id myRecordId = Id.valueOf(recordId);
            String sObjName = myRecordId.getSObjectType().getDescribe().getName();
            objectData.put('sObjName', sObjName);
            if(sObjName == 'T_EMPLMT_INCOME__c'){
                T_EMPLMT_INCOME__c emp = [SELECT Id, IDN_EMPLMT_INDIV__c, IDN_EMPLMT_INDIV__r.RecordType.DeveloperName FROM T_EMPLMT_INCOME__c WHERE Id =: recordId WITH SECURITY_ENFORCED Limit 1];
                objectData.put('employmentType', emp.IDN_EMPLMT_INDIV__r.RecordType.DeveloperName);
                objectData.put('parentObjId', emp.IDN_EMPLMT_INDIV__c);
                objectData.put('howVerifiedOptions', getHowVerifiedOptions(emp.IDN_EMPLMT_INDIV__r.RecordType.DeveloperName));
            } else {
                T_SBSD_INDIV_EMPLMT__c emp = [SELECT Id, RecordType.DeveloperName FROM T_SBSD_INDIV_EMPLMT__c WHERE Id =: recordId WITH SECURITY_ENFORCED Limit 1];
                objectData.put('employmentType', emp.RecordType.DeveloperName);
                objectData.put('parentObjId', emp.Id);
                objectData.put('howVerifiedOptions', getHowVerifiedOptions(emp.RecordType.DeveloperName));
            }
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse saveEmploymentIncome(T_EMPLMT_INCOME__c empIncomeObj){
        List<SObject> lstSObject = new List<SObject>();
        lstSObject.add(empIncomeObj);
        return GenericDataSaverApxCtrl.upsertRecordsFinal(lstSObject, true);
    }
    
    public static List<Map<String, String>> getHowVerifiedOptions(String employmentType){
        String allowedOptionsLabel = employmentType == 'Self_Employment' ? System.Label.SelfEmploymentIncome_HowVerified_Options : System.Label.EmploymentIncome_HowVerified_Options;
        List<String> allowedOptions = allowedOptionsLabel.deleteWhitespace().split(',');
        List<Map<String, String>> howVerifiedOptions = new List<Map<String, String>>();
        howVerifiedOptions.add(new Map<String, String> {'value'=>'', 'label'=>'--None--'});
        Schema.DescribeFieldResult fieldResult = T_EMPLMT_INCOME__c.CDE_SOURCE_VRFYD_PAY__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pv : picklistValues){
            if(allowedOptions.contains(pv.getValue()))
                howVerifiedOptions.add(new Map<String, String> {'value'=>pv.getValue(), 'label'=>pv.getLabel()});
        }
        return howVerifiedOptions;
    }
}