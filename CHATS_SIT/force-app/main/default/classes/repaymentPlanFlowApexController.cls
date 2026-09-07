/*************************************************************
Class Name      - repaymentPlanFlowApexController
Test Class      - repaymentPlanFlowApexController_Test
Description     - Common controller class for all Repayment Plan components
Author          - Rishav Maji
JIRA Id         - CCCAP-5785
**************************************************************/
public class repaymentPlanFlowApexController {
    
    @AuraEnabled
    public static LightningServerResponse getInitData(String recordId){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Id myRecordId = Id.valueOf(recordId);
            User u = [SELECT Id, Owner_County__c, Common_County__c, Profile.Name FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            String sObjName = myRecordId.getSObjectType().getDescribe().getName();
            objectData.put('sObjName', sObjName);
            if(sObjName == 'T_CHATS_PROVR_STATUS__c'){ // New Record Flow
                T_CHATS_PROVR_STATUS__c provr = [SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c WHERE Id =: recordId Limit 1];
                objectData.put('parentObjId', provr.Id);
                objectData.put('parentObjName', provr.Name);
                objectData.put('assignedCounties', getAssignedCounties('', sObjName, u));
                objectData.put('allowedCounties', getUserCounties(u));
                //CCCAP-14993
                objectData.put('isAdmin', (FeatureManagement.checkPermission('System_Administrator') || FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')) ? true : false);
            } else { // Edit Record Flow
                T_PMT_PLAN__c payPlan = [SELECT Id, IDN_PROVR__c, IDN_PROVR__r.Name, CDE_COUNTY__c FROM T_PMT_PLAN__c WHERE Id =: recordId Limit 1];
                objectData.put('parentObjId', payPlan.IDN_PROVR__c);
                objectData.put('parentObjName', payPlan.IDN_PROVR__r.Name);
                objectData.put('assignedCounties', getAssignedCounties(payPlan.CDE_COUNTY__c, sObjName, u));
                objectData.put('allowedCounties', getUserCounties(u));
                //CCCAP-14993
                objectData.put('isAdmin', (FeatureManagement.checkPermission('System_Administrator') || FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')) ? true : false);
            }
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse saveRepaymentPlan(T_PMT_PLAN__c repaymentPlanObj){
        List<SObject> lstSObject = new List<SObject>();
        lstSObject.add(repaymentPlanObj);
        return GenericDataSaverApxCtrl.upsertRecordsFinal(lstSObject, true);
    }
    
    public static List<String> getUserCounties(User u){
        List<String> countyList = new List<String>();
        Set<String> countyCodeSet = new Set<String>();
        if(!String.isBlank(u.Owner_County__c)){
            countyCodeSet.add(u.Owner_County__c);
        }
        if (!String.isBlank(u.Common_County__c)) {
            countyCodeSet.addAll(u.Common_County__c.split(';'));
        }
        countyList.addAll(countyCodeSet);
        return countyList;
    }
    
    public static List<Map<String, String>> getAssignedCounties(String currentCountyCode, String sObjName, User u){
        List<Map<String, String>> assignedCounties = new List<Map<String, String>>();
        Set<String> countyCodeSet = new Set<String>();
        assignedCounties.add(new Map<String, String> {'value'=>'', 'label'=>'--None--'});
        if(!String.isBlank(u.Owner_County__c)){
            countyCodeSet.add(u.Owner_County__c);
        }
        if (!String.isBlank(u.Common_County__c)) {
            countyCodeSet.addAll(u.Common_County__c.split(';'));
  }
        if(sObjName == 'T_PMT_PLAN__c' && !String.isBlank(currentCountyCode)){ // Edit Flow
            countyCodeSet.add(currentCountyCode);
        }
        System.debug('countyCodeSet-->'+countyCodeSet);
        Map<String, String> pickListValuesMap = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = T_PMT_PLAN__c.CDE_COUNTY__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        //CCCAP-14993
        if(FeatureManagement.checkPermission('System_Administrator') || FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')) {
            for(Schema.PicklistEntry pickListVal : ple){
                if(pickListVal.getValue() != '66'){ // Excluding 'All County (State)' option
                    assignedCounties.add(new Map<String, String> {'value'=>pickListVal.getValue(), 'label'=>pickListVal.getLabel()});
                }
            }
        } else {
            for(Schema.PicklistEntry pickListVal : ple){
                if(pickListVal.getValue() != '66' && countyCodeSet.contains(pickListVal.getValue())){ // Excluding 'All County (State)' option
                    assignedCounties.add(new Map<String, String> {'value'=>pickListVal.getValue(), 'label'=>pickListVal.getLabel()});
                }
            }
        }
        System.debug('assignedCounties-->'+assignedCounties);
        return assignedCounties;
    }
}