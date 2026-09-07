@isTest
public class customLookupController_LwcTest {    
    @testSetup
    static void setupTestData() {
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c (Name = '9999999', NAM_FACILITY__c = 'Lookup Provider');
        insert providerObj;
    }
    
    @isTest
    static void testFetchLookUpValues() {
        Test.startTest();
        T_CHATS_PROVR_STATUS__c providerObj = [SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c LIMIT 1];        
        String jsonParam = '{"searchKeyWord": "' +providerObj.Name + '","ObjectName":"T_CHATS_PROVR_STATUS__c","searchField":"Name"}';
        customLookupController_Lwc controller = new customLookupController_Lwc();
        LightningServerResponse response = (LightningServerResponse)controller.processRequest('fetchLookUpValues', jsonParam);        
        System.assertEquals(RequestStatus.OK, response.status, 'Response status should be OK');
        System.assertEquals(1, ((List<sObject>)response.objectData.get('records')).size(), 'Expected 1 record');        
        Test.stopTest();
    }
    
    @isTest
    static void testFetchRecentLookUpValues() {
        Test.startTest();        
        String jsonParam = '{"ObjectName":"T_CHATS_PROVR_STATUS__c"}';
        customLookupController_Lwc controller = new customLookupController_Lwc();
        LightningServerResponse response = (LightningServerResponse)controller.processRequest('fetchRecentLookUpValues', jsonParam);
        System.assertEquals(RequestStatus.OK, response.status, 'Response status should be OK');        
        Test.stopTest();
    }
    
    @isTest
    static void testFetchRecordFromParentRecordId() {
        Test.startTest();
        T_CHATS_PROVR_STATUS__c providerObj = [SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c LIMIT 1];        
        String jsonParam = '{"parentRecordId":"' + providerObj.Id + '","ObjectName":"T_CHATS_PROVR_STATUS__c"}';
        customLookupController_Lwc controller = new customLookupController_Lwc();
        LightningServerResponse response = (LightningServerResponse)controller.processRequest('fetchRecordFromParentRecordId', jsonParam);        
        System.assertEquals(RequestStatus.OK, response.status, 'Response status should be OK');
        System.assertEquals(providerObj.Id, ((sObject)response.objectData.get('record')).Id, 'Expected record ID to match');        
        Test.stopTest();
    }
}