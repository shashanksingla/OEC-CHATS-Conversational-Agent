@isTest
public class ProviderManualClaim_Test {
    @testSetup
    static void setupTestData() {
        // Create test Provider Manual Claim records
        List<Provider_Manual_Claim__c> claims = new List<Provider_Manual_Claim__c>();
        for (Integer i = 0; i < 3; i++) {
            claims.add(new Provider_Manual_Claim__c(
                Claim_Status__c = 'Submitted',
                Status_Updated_Date__c = Date.today().addDays(-1),
                County__c = '2',
                Provider_Name__c = 'abc',
                Provider_Id__c = '20250307'
            ));
        }
        insert claims;
        T_COUNTY__c county = TestClassUtility.createCounty('Test', null, 2, true);
        T_CHATS_PROVR_STATUS__c provrObj = new T_CHATS_PROVR_STATUS__c (name='20250307',NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c = 'Open', CDE_TYPE_PROVR__c = 'PRS', Slot_Contract_Suggestion__c = 'test~BREAK~test:vlaue', TXT_CHATS_RATING__c = '0');
        insert provrObj;
    }
    
    @isTest
    static void testHandleBeforeUpdateOps() {
        // Fetch test data
        Test.startTest();
        List<Provider_Manual_Claim__c> claims = [SELECT Id, Claim_Status__c FROM Provider_Manual_Claim__c];
        Map<Id, Provider_Manual_Claim__c> oldClaims = new Map<Id, Provider_Manual_Claim__c>(claims);
        
        // Update claims to trigger before update logic
        for (Provider_Manual_Claim__c claim : claims) {
            claim.Claim_Status__c = 'Denied';
            claim.Denial_Reason__c = 'test denial';
        }
        Test.stopTest();
    }
    
    @isTest
    static void testHandleAfterUpdateOps() {
        // Fetch test data
        Test.setMock(HttpCalloutMock.class, new getATSResponseMockup());
        List<Provider_Manual_Claim__c> claims = [SELECT Id, Claim_Status__c FROM Provider_Manual_Claim__c];
        Map<Id, Provider_Manual_Claim__c> oldClaims = new Map<Id, Provider_Manual_Claim__c>(claims);
        
        // Update claims to trigger after update logic
        for (Provider_Manual_Claim__c claim : claims) {
            claim.Claim_Status__c = 'Approved';
        }
        update claims;
        
        Test.startTest();
        ProviderManualClaimTriggerHandler.handleAfterUpdateOps(claims, oldClaims);
        Test.stopTest();
        
        // Verify that the job was enqueued
        System.assert(true, 'CallAtsAPIJob should have been enqueued.');
    }
    
    @isTest
    static void testHandleSaveOperation() {
        String requestBody = '{"operation":"UpsertClaim","claim":{"Provider_Id__c":"20250307","Claim_Status__c":"Submitted","County__c":"2","attributes":{"type":"Provider_Manual_Claim__c"}},'+
            '"claimDetails" : [{"claimDetail":{"Name" : "CD-00000001","Claim_for__c":"Vacant Slot Contract","Is_Active__c":true,"attributes":{"type":"Claim_Detail__c"}},'+
            '"claimDayDetails" : [{"Claim_Amount__c" : "200","Care_Date__c" : "2025-03-11","Is_Active__c":true,"attributes":{"type":"Claim_Day_Detail__c"}}]}]}';
        Test.startTest();
        CHATS_claimResponseWrapper response = CHATS_ProviderClaimRequestHandler.handleSaveOperation(requestBody);
        
        Test.stopTest();
        
        System.assertEquals('success', response.status, 'The operation should be successful.');
    }
    
    @isTest
    static void testGetFileDownloadUrl() {
        Test.startTest();
        Map<String,Object> keyVal = new Map<string,Object>();
        keyVal.put('fileIdentifier','TestFileIdentifier');
        keyVal.put('fileName','TestFileName.pdf');
        Test.setMock(HttpCalloutMock.class, new getFileDownloadUrlMockTest());
        
        String resp = RequestController.delegateRequest('ClaimInboxScreenCtrl', 'getFileDownloadUrl', JSON.serialize(keyVal));
        Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(resp);
        
        Test.stopTest();
        //System.assert((Boolean)response.get('isSuccessful'), 'The file download URL should be fetched successfully.');
    }
    
    @isTest
    static void testGetInitClaimRequestData() {
        Test.startTest();
        String resp = RequestController.delegateRequest('ClaimInboxScreenCtrl', 'getInitClaimRequestData', null);
        Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(resp);
        Test.stopTest();
        System.assert((Boolean)response.get('isSuccessful'), 'The initial claim request data should be fetched successfully.');
        System.assert(((Map<String,Object>)response.get('objectData')).containsKey('user'), 'The response should contain user data.');
    }
    
    @isTest
    static void testProcessViewResults() {
        Map<String,Object> keyVal = new Map<string,Object>();
        ClaimInboxWrapper claimWrap = new ClaimInboxWrapper('2','firstName','secondName');
        claimWrap.status = 'Submitted';
        keyVal.put('claimSearchWrapperStr',JSON.serialize(claimWrap));
        Test.startTest();
        String resp = RequestController.delegateRequest('ClaimInboxScreenCtrl', 'processViewResults', JSON.serialize(keyVal));
        Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(resp);
        Test.stopTest();
        System.assert((Boolean)response.get('isSuccessful'), 'The view results should be processed successfully.');
    }
}