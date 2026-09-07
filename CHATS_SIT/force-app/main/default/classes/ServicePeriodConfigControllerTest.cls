@isTest
private class ServicePeriodConfigControllerTest {
    
    @TestSetup
    static void setup() {
        Service_Period_Config__c config = new Service_Period_Config__c(
            Service_Period_Frequency__c = '2',
            Payment_Release_Day__c = '1',
            Payment_Calculation_Day__c = '2'
        );
        insert config;
        
        T_SERV_PERIOD__c servicePeriod = new T_SERV_PERIOD__c(
            Name = '795',
            DTE_BEGIN_EFFV__c = Date.today().addDays(-7),
            DTE_END_EFFV__c = Date.today().addDays(-1)
        );
        insert servicePeriod;
    }
    
    @isTest
    static void testProcessRequestAllMethods() {
        ServicePeriodConfigController controller = new ServicePeriodConfigController();
        
        // Test getExistingServicePeriodConfig method
        Test.startTest();
        Object getResponse = controller.processRequest('getExistingServicePeriodConfig', null);
        
        LightningServerResponse getServerResponse = (LightningServerResponse) getResponse;
        // Test upsertServicePeriodConfig method
        Service_Period_Config__c newConfig = new Service_Period_Config__c(
            Service_Period_Frequency__c = '2',
            Payment_Release_Day__c = '3',
            Payment_Calculation_Day__c = '1'
        );
        String configData = JSON.serialize(newConfig);
        Map<String, Object> requestData = new Map<String, Object>{
            'configData' => configData
                };
                    String jsonParam = JSON.serialize(requestData);
        
        
        Object upsertResponse = controller.processRequest('upsertServicePeriodConfig', jsonParam);
        
        LightningServerResponse upsertServerResponse = (LightningServerResponse) upsertResponse;
        
        Object invalidResponse = controller.processRequest('invalidMethod', null);
        Test.stopTest();
        System.assertNotEquals(null, invalidResponse, 'Invalid response should not be null');
        LightningServerResponse invalidServerResponse = (LightningServerResponse) invalidResponse;
        System.assertEquals(true, invalidServerResponse.isSuccessful, 'Default response should be successful');
    }
}