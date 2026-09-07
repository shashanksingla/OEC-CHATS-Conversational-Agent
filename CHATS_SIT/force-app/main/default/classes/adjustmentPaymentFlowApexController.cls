/*************************************************************
Class Name      - adjustmentPaymentFlowApexController
Test Class      - adjustmentPaymentFlowApexController_Test
Description     - Common controller class for all Adjustment Payment components
Author          - Rishav Maji
JIRA Id         - CCCAP-6608
**************************************************************/
public class adjustmentPaymentFlowApexController implements Irequest {

    public String jsonParam;
    private static Map<String, Object > requestObj;

    public Object processRequest(String methodName, String jsonParam) {
        Object response = new LightningServerResponse(true,'',new Map<String,Object>());
        this.jsonParam = jsonParam;

        if(jsonParam!=null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);
        }
        if (methodName == 'getInitData') {
            response = getInitData(getMapValue('parentObjectId'),getMapValue('parentObjectAPI'));
        }else if(methodName == 'saveAdjustmentPayment'){
            Map<String, Object> adjPaymentMap = (Map<String, Object>)requestObj.get('adjPaymentObj');
            T_ADJMT_PMT__c adjPaymentObj = (T_ADJMT_PMT__c)JSON.deserialize(JSON.serialize(adjPaymentMap), T_ADJMT_PMT__c.class);
            response = saveAdjustmentPayment(adjPaymentObj);
}       
        return response;
    }
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }
    
    @AuraEnabled
    public static LightningServerResponse getInitData(String parentObjectId, String parentObjectAPI){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            if(!String.isBlank(parentObjectId)){
                String queryString = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(parentObjectAPI) + ' WHERE Id = \'' + String.escapeSingleQuotes(parentObjectId) + '\' LIMIT 1';
                sObject parentObject = Database.query(queryString);
                objectData.put('parentObjectName', parentObject.get('Name'));
            } else {
                objectData.put('parentObjectName', 'T_ADJMT_PMT__c');
            }
            //CCCAP-14993
            User u = [SELECT Id, Owner_County__c, Common_County__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            List<Map<String, String>> assignedCounties = new List<Map<String, String>>();
            Set<String> countyCodeSet = new Set<String>();
            assignedCounties.add(new Map<String, String> {'value'=>'', 'label'=>'--None--'});
            if(!String.isBlank(u.Owner_County__c)){
                countyCodeSet.add(u.Owner_County__c);
            }
            if (!String.isBlank(u.Common_County__c)) {
                countyCodeSet.addAll(u.Common_County__c.split(';'));
            }
            Map<String, String> pickListValuesMap = new Map<String, String>();
            Schema.DescribeFieldResult fieldResult = T_ADJMT_PMT__c.CDE_COUNTY__c.getDescribe();
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
            objectData.put('assignedCounties', assignedCounties);
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse saveAdjustmentPayment(T_ADJMT_PMT__c adjPaymentObj){
        List<SObject> lstSObject = new List<SObject>();
        lstSObject.add(adjPaymentObj);
        return GenericDataSaverApxCtrl.upsertRecordsFinal(lstSObject, true);
    }
}