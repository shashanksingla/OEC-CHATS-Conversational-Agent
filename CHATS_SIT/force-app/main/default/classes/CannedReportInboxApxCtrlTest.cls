@IsTest(SeeAllData=false)
public class CannedReportInboxApxCtrlTest {
    
    static testMethod void testfetchUser(){
        CannedReportInboxApxCtrl.fetchUser();
    }
    
    static testMethod void testgetInitReportRequestData(){
        LightningServerResponse lsr = CannedReportInboxApxCtrl.getInitReportRequestData('');
    }
    
    static testMethod void testprocessViewResults(){
        CannedReportInboxApxCtrl.processViewResults('test','test1','test2','test3','test4',null,null);
        CannedReportInboxApxCtrl.processViewResults('test00','test11','test22','test33','test44',date.newInstance(2022,01,17),date.newInstance(2022,02,17));
    }
    
    static testMethod void testgetReportName(){
        CannedReportInboxApxCtrl.getReportName('Case');
        CannedReportInboxApxCtrl.getReportName('');
    }
    
    static testMethod void testgetAllReportName(){
        CannedReportInboxApxCtrl.getAllReportName();
    }
    
    static testMethod void testgetReportType(){
        CannedReportInboxApxCtrl.getReportType();
    }
    
    @isTest
    static void testviewCannedReportApxCtrl() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockTest());
        CannedReportInboxApxCtrl.geReportFromAWS('RE213_000001.xslx');
        CannedReportInboxApxCtrl report = new CannedReportInboxApxCtrl();
        test.stopTest();
    }
    
    @isTest
    static void testviewCannedReportApxCtrlError() {
        test.startTest();
        CannedReportInboxApxCtrl.geReportFromAWS('RE213_000001.xslx');
        test.stopTest();
    }
    
    @isTest
    static void testgetReportResponse() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockTest());
        CannedReportInboxApxCtrl.getReportResponse('RE213_000001.xslx');
        CannedReportInboxApxCtrl report = new CannedReportInboxApxCtrl();
        test.stopTest();
    }
    
    @isTest
    static void testgetReportResponseError() {
        test.startTest();
        CannedReportInboxApxCtrl.getReportResponse('RE213_000001.xslx');
        test.stopTest();
    }
}