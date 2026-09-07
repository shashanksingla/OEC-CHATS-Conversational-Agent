@isTest
private class ProviderReviewApexControllerTest 
{
    @testSetup
    static void setupTestData() 
    { 
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = TestClassUtility.createUserWithPS(profile.Id, 'System_Administrator_PS', 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');

        System.runAs(testUser) {
            T_CHATS_PROVR_STATUS__c provrObj = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c = 'Open', CDE_TYPE_PROVR__c = 'PRS', Slot_Contract_Suggestion__c = 'test~BREAK~test:vlaue', TXT_CHATS_RATING__c = '0');
            insert provrObj;
            
            // Create a County
            T_COUNTY__c county = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
            
            Review_Question__c rq = new Review_Question__c();
            rq.Active__c = true; rq.LicenseType__c = 'Licensed'; rq.Element__c = 'test'; rq.NA_Reason_Options__c = '1;2';
            rq.Order__c = 1; rq.Question__c = 'test'; rq.Review_Requirement__c = 'test'; rq.Review_Type__c = 'Provider';
            Insert rq;
            /*
            User_and_Email_Settings__c ues1 = new User_and_Email_Settings__c();
            ues1.Name = 'T119 Assignee';
            ues1.Value__c = (String)testUser.Id;
            Insert ues1;*/
            // Create a Provider Fiscal Agreement
            T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, 'Test FA 1', Date.today()-60, county.Id);
            fiscalAgreement.ID_SERVICE__c = provrObj.Id;
            fiscalAgreement.DTE_END_AGRMT__c = Date.today();
            insert fiscalAgreement;
            // Create a Provider Review
            Provider_Review__c providerReview = new Provider_Review__c(
                Provider_Fiscal_Agreement__c = fiscalAgreement.Id,
                Review_Status__c = '1',
                Reviewee__c = testUser.Id
            );
            insert providerReview;
            Provider_Review_Response__c prr = new Provider_Review_Response__c();
            prr.Provider_Review__c = providerReview.Id;
            Insert prr;
        }
    }
    
    @isTest
    static void testCheckEligibility_PositiveScenario() 
    {
        // Test the positive scenario for checkEligibility method
        User testUser = [SELECT Id FROM User WHERE Email = 'test1@example.com' LIMIT 1];
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        requestObj obj = new requestObj();
        obj.keyVal.put('recordId',fiscalAgreement.Id);
        obj.keyVal.put('screenMode','NEW');
        obj.keyVal.put('isDelete',false);
        obj.keyVal.put('fetchAllData',true);
        System.runAs(testUser) 
        {
            Test.startTest();
            RequestController.delegateRequest('providerReviewApexController', 'checkEligibility', JSON.serialize(obj.keyVal));
            Test.stopTest();    
        }
    }
    
    @isTest
    static void testCheckEligibility_NegativeScenario() 
    {
        // Test the negative scenario for checkEligibility method
        User testUser = [SELECT Id FROM User WHERE Email = 'test1@example.com' LIMIT 1];
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        requestObj obj = new requestObj();
        obj.keyVal.put('recordId',fiscalAgreement.Id);
        obj.keyVal.put('screenMode','NEW');
        obj.keyVal.put('isDelete',false);
        obj.keyVal.put('fetchAllData',false);
        System.runAs(testUser) 
        {
            Test.startTest();
            RequestController.delegateRequest('providerReviewApexController', 'checkEligibility', JSON.serialize(obj.keyVal));
            Test.stopTest();
        }
    }
    
    @isTest
    static void testHandleSample_MY_Update() 
    {
        // Test the handleSample_MY_Update method
        User testUser = [SELECT Id FROM User WHERE Email = 'test1@example.com' LIMIT 1];
        Date todayD = date.today();
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = [SELECT Id,CDE_County__c,ID_Service__c FROM T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        requestObj obj = new requestObj();
        obj.keyVal.put('recordId',fiscalAgreement.Id);
        obj.keyVal.put('providerId',fiscalAgreement.ID_Service__c);
        obj.keyVal.put('objectName','T_PROVR_FISCAL_AGREMENT__c');
        obj.keyVal.put('sampleMonth',''+todayD.Month());
        obj.keyVal.put('sampleYear',''+todayD.Year());
        obj.keyVal.put('countyId',fiscalAgreement.CDE_COUNTY__c);
        obj.keyVal.put('FA_Id',fiscalAgreement.Id);
        System.runAs(testUser) 
        {
            Test.startTest();
            RequestController.delegateRequest('providerReviewApexController', 'handleSample_MY_Update', JSON.serialize(obj.keyVal));
            Test.stopTest();
        }
    }
    
    @isTest
    static void testDeleteProviderReview() 
    {
        // Test the deleteProviderReview method
        Provider_Review__c providerReview = [SELECT Id FROM Provider_Review__c LIMIT 1];
        requestObj obj = new requestObj();
        obj.keyVal.put('recordId',providerReview.Id);
        Test.startTest();
        RequestController.delegateRequest('providerReviewApexController', 'deleteProviderReview', JSON.serialize(obj.keyVal));
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteProviderReviewButton() 
    {
        // Test the deleteProviderReviewButton method
        Provider_Review__c providerReview = [SELECT Id FROM Provider_Review__c LIMIT 1];
        requestObj obj = new requestObj();
        obj.keyVal.put('recordId',providerReview.Id);
        
        Test.startTest();
        RequestController.delegateRequest('providerReviewApexController', 'deleteProviderReviewButton', JSON.serialize(obj.keyVal));
        Test.stopTest();
    }
    
    @isTest
    static void testSaveProviderReview() 
    {
        // Test the saveProviderReview method
        Provider_Review__c providerReview = [SELECT Id FROM Provider_Review__c LIMIT 1];
        String providerReviewObj = JSON.serialize(providerReview);
        String responsesRecords = JSON.serialize(new List<Provider_Review_Response__c>());
        requestObj obj = new requestObj();
        obj.keyVal.put('providerReviewObj',providerReviewObj);
        obj.keyVal.put('responsesRecords',responsesRecords);
        obj.keyVal.put('screenMode','NEW');
        obj.keyVal.put('methodName','doSubmit');
        
        Test.startTest();
        RequestController.delegateRequest('providerReviewApexController', 'saveProviderReview', JSON.serialize(obj.keyVal));
        Test.stopTest();
    }
    
    @isTest
    static void testCheckRecordAccess() 
    {
        // Test the checkRecordAccess method
        Provider_Review__c providerReview = [SELECT Id FROM Provider_Review__c LIMIT 1];
        requestObj obj = new requestObj();
        obj.keyVal.put('recordId',providerReview.Id);
        Test.startTest();
        RequestController.delegateRequest('providerReviewApexController', 'checkRecordAccess', JSON.serialize(obj.keyVal));
        //LightningServerResponse response = providerReviewApexController.checkRecordAccess(providerReview.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetVFBaseURL() 
    {
        // Test the getVFBaseURL method
        Test.startTest();
        RequestController.delegateRequest('providerReviewApexController', 'getVFBaseURL', null);
        Test.stopTest();
    }
    
    @isTest
    static void testSumbitForStateReversal() 
    {
        // Test the sumbitForStateReversal method
        Provider_Review__c providerReview = [SELECT Id FROM Provider_Review__c LIMIT 1];
        requestObj obj = new requestObj();
        obj.keyVal.put('recordId',providerReview.Id);
        obj.keyVal.put('taskComment','Test Comment');
        Test.startTest();
        RequestController.delegateRequest('providerReviewApexController','sumbitForStateReversal',JSON.serialize(obj.keyVal));        
        Test.stopTest();
    }
    
    @isTest
    static void testSubmitToReviewee() 
    {
        // Test the submitToReviewee method
        Provider_Review__c providerReview = [SELECT Id FROM Provider_Review__c LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'test1@example.com' LIMIT 1];
        requestObj obj = new requestObj();
        obj.keyVal.put('revieweeId',testUser.Id);
        obj.keyVal.put('recordId',providerReview.Id);
        Test.startTest();
        RequestController.delegateRequest('providerReviewApexController','submitToReviewee',JSON.serialize(obj.keyVal));
        Test.stopTest();
    }
    
    // New test method added for getLicenseDetailsBySampleMonthYear()
    @isTest
    static void testGetLicenseDetailsBySampleMonthYear() 
    {
        // Test the getLicenseDetailsBySampleMonthYear method
        requestObj obj = new requestObj();
        obj.keyVal.put('providerId',(String)[select id from T_CHATS_PROVR_STATUS__c limit 1]?.Id); // Replace with actual provider ID
        obj.keyVal.put('sampleMonth', '1');
        obj.keyVal.put('sampleYear','2023');
        
        Test.startTest();
        RequestController.delegateRequest('providerReviewApexController','getLicenseDetailsBySampleMonthYear',JSON.serialize(obj.keyVal));
        Test.stopTest();
    }
    public class requestObj{
        Map<String,Object> keyVal = new Map<string,Object>();
    }
}