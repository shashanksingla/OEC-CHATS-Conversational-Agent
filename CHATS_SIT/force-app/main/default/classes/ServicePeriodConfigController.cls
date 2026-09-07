public with sharing class ServicePeriodConfigController implements IRequest {
    
    public String jsonParam;
    private static Map<String, Object> requestObj;
    
    /**
* @description Main entry point for processing requests
* @param methodName The method to execute
* @param jsonParam JSON string containing parameters
* @return LightningServerResponse with result
*/
    public Object processRequest(String methodName, String jsonParam) {
        Object response = new LightningServerResponse(true, '', new Map<String, Object>());
        this.jsonParam = jsonParam;
        
        if (jsonParam != null) {
            requestObj = (Map<String, Object>) JSON.deserializeUntyped(jsonParam);
        }
        if (methodName == 'getExistingServicePeriodConfig') {
            response = getExistingServicePeriodConfig();
        }else if (methodName == 'upsertServicePeriodConfig') {
            response = upsertServicePeriodConfig(getMapValue('configData'));
        }
        return response;
    }
    
    /**
* @description Retrieves the most recent Service Period Config record
* @return LightningServerResponse containing the existing config data
*/
    @AuraEnabled
    public static LightningServerResponse getExistingServicePeriodConfig() {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        
        try {
            if(Schema.sObjectType.Service_Period_Config__c.isCreateable() && Schema.sObjectType.Service_Period_Config__c.isUpdateable()){
                // Query for the most recent Service Period Config record
                List<Service_Period_Config__c> configRecords = [
                    SELECT Id,Name,Future_Payment__c, Payment_Release_Day__c, Service_Period_Frequency__c,Payment_Calculation_Day__c,
                    CreatedDate
                    FROM Service_Period_Config__c 
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
                
                List<T_SERV_PERIOD__c> servicePeriods = new List<T_SERV_PERIOD__c>([select DTE_END_EFFV__c 
                                                                                    from T_SERV_PERIOD__c order by DTE_END_EFFV__c desc limit 1]);
                Date periodStartDate = servicePeriods[0]?.DTE_END_EFFV__c.addDays(1);
                objectData.put('periodStartDate',periodStartDate);
                if (!configRecords.isEmpty()) {
                    Service_Period_Config__c existingConfig = configRecords[0];
                    objectData.put('existingConfig', existingConfig);
                } 
            }else{
                isSuccessful = false;
                message = 'The access to manage the Service Period Config is restricted, please contact the System Administrator! ';
            }
            
        } catch (Exception ex) {
            System.debug('Exception occurred while retrieving config: ' + ex.getMessage());
            isSuccessful = false;
            message = 'An error occurred while retrieving existing configuration: ' + ex.getMessage();
        }
        
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    /**
* @description Upserts Service Period Config record (updates last record or creates new)
* @param configData JSON string containing the field values for the record
* @return LightningServerResponse containing success status and any error messages
*/
    @AuraEnabled
    public static LightningServerResponse upsertServicePeriodConfig(String configData) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        
        try {
            Service_Period_Config__c configRecord = (Service_Period_Config__c)JSON.deserialize(configData,Service_Period_Config__c.class);
            List<Service_Period_Config__c>configRecords = new List<Service_Period_Config__c>{configRecord};
                if(!configRecords.isEmpty()){
                    if(configRecord.id!=null){
                        GenericDmlHandler.updateRecords(configRecords, new Map<String,Object>{'Method__c'=>'upsertServicePeriodConfig','Class__c'=>'ServicePeriodConfigController'}, new List<String>{'Payment_Calculation_Day__c','Service_Period_Frequency__c','Payment_Release_Day__c'});
                    }else{
                        GenericDmlHandler.insertRecords(configRecords, new Map<String,Object>{'Method__c'=>'upsertServicePeriodConfig','Class__c'=>'ServicePeriodConfigController'}, new List<String>{'Payment_Calculation_Day__c','Service_Period_Frequency__c','Payment_Release_Day__c'});
                    }
                    // Set success response
                    objectData.put('servicePeriodConfigObj', configRecord);
                }else{
                    isSuccessful = false;
                    message = 'The access to manage the Service Period Config is restricted, please contact the System Administrator!';
                }
        } catch (Exception ex) {
            System.debug('Exception occurred: ' + ex.getMessage());
            isSuccessful = false;
            message = 'An unexpected error occurred: ' + ex.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    private static String getMapValue(String fieldName) {
        return (String) requestObj.get(fieldName);
    }
}