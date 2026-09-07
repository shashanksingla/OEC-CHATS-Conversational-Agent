@isTest
public class CompareCP_CRP_lwcTest {
    @testSetup
    static void setupTestData() {
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Test County', 'Test Department Name',1, true);
        T_COUNTY_PLAN__c cpRec = TestClassUtility.createCountyPlan('APV', false);
        cpRec.CDE_COUNTY__c = countyRec.Id;
        T_COUNTY_PLAN__c cpRecSub = TestClassUtility.createCountyPlan('PEN', false);
        cpRecSub.CDE_COUNTY__c = countyRec.Id;
        insert new List<T_COUNTY_PLAN__c>{cpRec,cpRecSub};
        T_COUNTY_RATE__c crpRec = TestClassUtility.createCountyRatePlan('APV', false); 
		crpRec.IDN_COUNTY__c = countyRec.Id;
        T_COUNTY_RATE__c crpRecSub = TestClassUtility.createCountyRatePlan('PEN', false); 
		crpRecSub.IDN_COUNTY__c = countyRec.Id;
        insert new List<T_COUNTY_RATE__c>{crpRec,crpRecSub};
        // Create test data for CP_CRP_Feedback__c
        CP_CRP_Feedback__c feedback = new CP_CRP_Feedback__c(
            Feedback__c = 'Test Feedback',
            Identifier__c = 'TestIdentifier',
            County__c = countyRec.Id,
            Section__c = 'TestSection',
            feedback_type__c = 'CP'
        );
        insert feedback;
    }

    @isTest
    static void testProcessRequest_getAllData() {
        T_COUNTY_PLAN__c cpRec = [SELECT Id FROM T_COUNTY_PLAN__c LIMIT 1];
        Test.startTest();
        CompareCP_CRP_lwc controller = new CompareCP_CRP_lwc();
        String jsonParam = '{"recordId":"' +cpRec.Id+ '","isCPFlow":true}';
        Object response = controller.processRequest('getAllData', jsonParam);
        Test.stopTest();

        System.assert(response != null, 'Response should not be null');
        System.assert(response instanceof LightningServerResponse, 'Response should be of type LightningServerResponse');
    }

    @isTest
    static void testProcessRequest_saveFeedbacks() {
        Test.startTest();
        CompareCP_CRP_lwc controller = new CompareCP_CRP_lwc();
        //String jsonParam = '{"recordId":"TestRecordId","feedbacks":"[{\"Feedback__c\":\"Test Feedback\",\"Identifier__c\":\"TestIdentifier\"}]"}';
        List<Map<String, String>> feedbacks = new List<Map<String, String>>();
        Map<String, String> feedback = new Map<String, String>{
        'Feedback__c' => 'Test Feedback',
        'Identifier__c' => 'TestIdentifier'
            };
        feedbacks.add(feedback);
        String feedbacksString = JSON.serialize(feedbacks);
        String jsonParam = '{"recordId":"TestRecordId","feedbacks":' + JSON.serialize(feedbacksString) + '}';

        Object response = controller.processRequest('saveFeedbacks', jsonParam);
        Test.stopTest();

        System.assert(response != null, 'Response should not be null');
        System.assert(response instanceof LightningServerResponse, 'Response should be of type LightningServerResponse');
    }

    @isTest
    static void testProcessRequest_getFeedbacks() {
        Test.startTest();
        CompareCP_CRP_lwc controller = new CompareCP_CRP_lwc();
        String jsonParam = '{"recordId":"TestRecordId","isCPFlow":true}';
        Object response = controller.processRequest('getFeedbacks', jsonParam);
        Test.stopTest();

        System.assert(response != null, 'Response should not be null');
        System.assert(response instanceof LightningServerResponse, 'Response should be of type LightningServerResponse');
    }

    @isTest
    static void testProcessRequest_initLoad() {
        Test.startTest();
        CompareCP_CRP_lwc controller = new CompareCP_CRP_lwc();
        String jsonParam = '{"recordId":"TestRecordId","isCPFlow":true}';
        Object response = controller.processRequest('initLoad', jsonParam);
        Test.stopTest();

        System.assert(response != null, 'Response should not be null');
        System.assert(response instanceof LightningServerResponse, 'Response should be of type LightningServerResponse');
    }

    @isTest
    static void testGetAllData() {
        Test.startTest();
        LightningServerResponse response = CompareCP_CRP_lwc.getAllData('TestRecordId', true);
        Test.stopTest();

        System.assert(response != null, 'Response should not be null');
        System.assert(response.isSuccessful, 'Response should be successful');
    }

    @isTest
    static void testGetFeedbacks() {
        Test.startTest();
        LightningServerResponse response = CompareCP_CRP_lwc.getFeedbacks('TestRecordId', true);
        Test.stopTest();

        System.assert(response != null, 'Response should not be null');
        System.assert(response.isSuccessful, 'Response should be successful');
    }

    @isTest
    static void testInitLoad() {
        Test.startTest();
        LightningServerResponse response = CompareCP_CRP_lwc.initLoad('TestRecordId', true);
        Test.stopTest();

        System.assert(response != null, 'Response should not be null');
        System.assert(response.isSuccessful, 'Response should be successful');
    }

    @isTest
    static void testSaveFeedbacks() {
        T_COUNTY_PLAN__c cpRec = [SELECT Id FROM T_COUNTY_PLAN__c LIMIT 1];
        Test.startTest();
        String feedbacksJson = '[{"Feedback__c":"Test Feedback","Identifier__c":"TestIdentifier","County__c":"Denver","feedback_type__c":"CP","Section__c":"TestSection"}]';
        LightningServerResponse response = CompareCP_CRP_lwc.saveFeedbacks('TestRecordId', feedbacksJson);
        Test.stopTest();
        System.assert(response != null, 'Response should not be null');
    }

    @isTest
    static void testIsDateAfter_15June2025() {
        Date testDate = Date.newInstance(2025, 6, 16);
        Boolean result = CompareCP_CRP_lwc.IsDateAfter_15June2025(testDate);

        System.assert(result, 'Date should be after 15 June 2025');
    }
}