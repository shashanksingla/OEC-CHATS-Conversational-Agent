/*
	Title: Roadmap PDF Controller Test Class 
	Description: Test Class
	Author: Balamurugan Chinnaiah
	Comments: CCCAP-3117 09/10/2021
*/

@isTest
public class viewRoadmapPdfTest {
    static testmethod void testGetRoadmapPdfFromCbms() {
		T_COUNTY__c county = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c cases = TestClassUtility.createCase(true, county.Id);
        T_SBSD_INDIV__c ind = TestClassUtility.createIndividual(true, System.today().addYears(-18), 'firstName','1', 'lastName','989898989','CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, cases.Id, ind.Id,true);
        T_SBSD_ROADMAP_CORR_ID__c road = new T_SBSD_ROADMAP_CORR_ID__c();
        road.CASE_ID__c = cases.id;
        road.CBMS_CASE_NUM__c = 'ABC123';
        road.INDIVIDUAL__c = ind.id;
        road.ROADMAP_CORR_ID__c = '1234';
        insert road;
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new viewRoadmapPdfMockTest());
        LightningServerResponse rtrn = viewRoadmapPdfController.getRoadmapPdfFromCbms(road.id);
        
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        LightningServerResponse rtrn1 = viewRoadmapPdfController.getRoadmapPdfFromCbms(road.id);
        string applnId = viewRoadmapPdfController.fetchRoadmapFileName(road.id);
        viewRoadmapPdfController constructorTest = new viewRoadmapPdfController();
		test.stopTest();
    }
}