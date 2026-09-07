/*************************************************************
Class Name      - TaxInterceptApexController
Test Class      - TaxInterceptApexController_Test
Description     - Common apex for all Tax Intercept components
Author          - Rishav Maji
Requiremnt      - Project 282 : CCCAP-4372

**************************************************************/
public with sharing class TaxInterceptApexController implements IRequest {
    private static Map<String, Object > requestObj;
    public Object processRequest(String methodName, String jsonParam) {
        Object response = new LightningServerResponse(true, '', new Map<String, Object>());
        requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);
        if (methodName == 'searchTaxIntercepts') {
           response = searchTaxIntercepts(JSON.serialize(requestObj.get('searchWrapperString')));
        } else if (methodName == 'saveRecord') {
            
            String recordId = getMapValue('recordId');
            String removeReasonOld = getMapValue('removeReasonOld');
            String removeReasonNew = getMapValue('removeReasonNew');
            response = saveRecord(recordId, removeReasonOld, removeReasonNew);
        }
        return response;
    }
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }
    
    // Updated to support both direct Aura calls and RequestController calls
    @AuraEnabled
    public static LightningServerResponse searchTaxIntercepts(String searchWrapperString) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Boolean hasRemoveAccess = false;
            User u = [SELECT Id, Profile.Name, Owner_County__c, Common_County__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1]; // 'WITH SECURITY_ENFORCED' will not work on 'Profile' obj
            //CCCAP-14993 using custom permission
            //String allowedProfiles = System.label.taxIntercept_removeFieldAccess;
            if(FeatureManagement.checkPermission('Business_Office_Worker') || FeatureManagement.checkPermission('CCCAP_Program_Internal_Team') || FeatureManagement.checkPermission('Business_Office_Supervisor') ||
            FeatureManagement.checkPermission('Fiscal_Worker_Supervisor') ||FeatureManagement.checkPermission('Fiscal_Worker') ||FeatureManagement.checkPermission('Universal_User') ||FeatureManagement.checkPermission('System_Administrator')) {    
                hasRemoveAccess = true;
            }
            Set<String> userCounty = new Set<String>();
            userCounty.add(u.Owner_County__c);
            if (String.isNotBlank(u.Common_County__c)) {
                userCounty.addAll(u.Common_County__c.split(';'));
            }
            TaxInterceptSearchWrapper searchWrapper = (TaxInterceptSearchWrapper)JSON.deserialize(searchWrapperString, TaxInterceptSearchWrapper.class);
            
            String query;
            query = 'SELECT';
            query += ' County__r.Name, County__r.CDE_COUNTY__c, Provider__r.Name, Case__r.Name, Adjustment__r.Name, toLabel(recovery_reason__c), toLabel(classification__c),';
            query += ' toLabel(type__c), toLabel(sent_to_cdor__c), toLabel(reinstate__c), toLabel(case_status__c),';
            if(!hasRemoveAccess){
                query += ' toLabel(remove_reason__c),';
            }
            Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('Tax_Intercept__c').getDescribe().fields.getMap();
            for(String s : objectFields.keySet()){
                if(!query.contains(s)){
                    query += ' ' + s + ',';
                }
            }
            query = query.removeEnd(',');
            query += ' FROM Tax_Intercept__c WHERE ';
            if(searchWrapper.selectedCounty != null && !searchWrapper.selectedCounty.isEmpty() && !searchWrapper.selectedCounty.contains('66')){
                query += 'County__r.CDE_COUNTY__c IN (' + String.escapeSingleQuotes(String.join(searchWrapper.selectedCounty, ',')) + ') AND ';
            }
            if(!String.isBlank(searchWrapper.taxRecord.Tax_Year__c)){
                query += 'Tax_Year__c = \'' + String.escapeSingleQuotes(searchWrapper.taxRecord.Tax_Year__c) + '\' AND ';
            }
            if(!String.isBlank(searchWrapper.taxRecord.Name__c)){
                query += 'Name__c LIKE \'%' + String.escapeSingleQuotes(searchWrapper.taxRecord.Name__c) + '%\' AND ';
            }
            if(!String.isBlank(searchWrapper.taxRecord.Type__c)){
                query += 'Type__c = \'' + String.escapeSingleQuotes(searchWrapper.taxRecord.Type__c) + '\' AND ';
            }
            if(!String.isBlank(searchWrapper.taxRecord.Case__c)){
                query += 'Case__c = \'' + String.escapeSingleQuotes(searchWrapper.taxRecord.Case__c) + '\' AND ';
            }
            if(!String.isBlank(searchWrapper.taxRecord.SSN__c)){
                query += 'SSN__c = \'' + String.escapeSingleQuotes(searchWrapper.taxRecord.SSN__c) + '\' AND ';
            }
            if(!String.isBlank(searchWrapper.taxRecord.Adjustment__c)){
                query += 'Adjustment__c = \'' + String.escapeSingleQuotes(searchWrapper.taxRecord.Adjustment__c) + '\' AND ';
            }
            if(!String.isBlank(searchWrapper.taxRecord.Provider__c)){
                query += 'Provider__c = \'' + String.escapeSingleQuotes(searchWrapper.taxRecord.Provider__c) + '\' AND ';
            }
            if(searchWrapper.recoveryReason != null && !searchWrapper.recoveryReason.isEmpty()){
                String recoveryReasonString = String.escapeSingleQuotes(String.join(searchWrapper.recoveryReason, ',')).replace(',', '\',\'');
                query += 'Recovery_Reason__c INCLUDES (\'' + recoveryReasonString + '\') AND ';
            }
            if(!String.isBlank(searchWrapper.taxRecord.Classification__c)){
                query += 'Classification__c = \'' + String.escapeSingleQuotes(searchWrapper.taxRecord.Classification__c) + '\' AND ';
            }
            query = query.removeEnd('AND ');
            query += 'ORDER BY Name ASC LIMIT 10000';
            System.debug('[TaxInterceptApexController.searchTaxIntercepts]--query conditions-->'+query.substringAfter('FROM'));
            List<Tax_Intercept__c> taxInterceptList = new List<Tax_Intercept__c>();
            taxInterceptList = Database.query(query);
            objectData.put('taxInterceptList', taxInterceptList);
            objectData.put('recordCount', taxInterceptList.Size());
            objectData.put('hasRemoveAccess', hasRemoveAccess);
            objectData.put('userCounty', userCounty);
            //CCCAP-14993 replacing with custom permission
            objectData.put('isAdmin', FeatureManagement.checkPermission('System_Administrator') ? true : false);
            System.debug('[TaxInterceptApexController.searchTaxIntercepts]--taxInterceptList.Size()-->'+taxInterceptList.Size());
        } catch(Exception e) {
            isSuccessful = false;
            message = e.getMessage();
            throw e;
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
   @AuraEnabled
    public static LightningServerResponse saveRecord(String recordId, String removeReasonOld, String removeReasonNew) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Tax_Intercept__c taxRecordToUpdate = new Tax_Intercept__c(Id = recordId);
            if(!String.isBlank(recordId)){
                if(Schema.sObjectType.Tax_Intercept__c.fields.Intercept_Status__c.isAccessible()){
                    Tax_Intercept__c taxToUpd = [SELECT Id, Intercept_Status__c FROM Tax_Intercept__c WHERE Id =: recordId LIMIT 1];
                    if(taxToUpd.Intercept_Status__c != 'Expired'){
                        if(Schema.sObjectType.Tax_Intercept__c.fields.Remove_Reason__c.isUpdateable()){
                            taxRecordToUpdate.Remove_Reason__c = removeReasonNew;
                        }
                        if(!String.isBlank(removeReasonNew) && Schema.sObjectType.Tax_Intercept__c.fields.Remove_Date__c.isUpdateable()){
                            taxRecordToUpdate.Remove_Date__c = System.today();
                        }
                        if(!String.isBlank(removeReasonOld) && String.isBlank(removeReasonNew)
                           && Schema.sObjectType.Tax_Intercept__c.fields.Reinstate__c.isUpdateable() 
                           && Schema.sObjectType.Tax_Intercept__c.fields.Reinstate_Date__c.isUpdateable()){
                               taxRecordToUpdate.Reinstate__c = 'Y';
                               taxRecordToUpdate.Reinstate_Date__c = System.today();
                        }
                        if(Schema.sObjectType.Tax_Intercept__c.isUpdateable()){
                            UPDATE taxRecordToUpdate;
                        }
                    } else {
                         isSuccessful = false;
                         message = System.label.taxIntercept_expiredError;
                    }
                }
                
                Tax_Intercept__c taxRecordUpdated = [SELECT Id, toLabel(Reinstate__c), Remove_Reason__c, Remove_Date__c, Reinstate_Date__c, Remove_Reason_Text__c FROM Tax_Intercept__c WHERE Id =: recordId LIMIT 1];
                objectData.put('taxRecord', taxRecordUpdated);
                System.debug('[TaxInterceptApexController.saveRecord]--taxRecordUpdated-->'+taxRecordUpdated);
            }
        } catch(Exception e) {
            isSuccessful = false;
            message = e.getMessage();
            throw e;
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
}