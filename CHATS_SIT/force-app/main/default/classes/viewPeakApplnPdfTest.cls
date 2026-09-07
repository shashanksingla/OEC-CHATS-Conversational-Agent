@isTest
public class viewPeakApplnPdfTest {
    static testmethod void testGetPdfFromPeak() {
        T_APPLN_CASE__c applnCase = new T_APPLN_CASE__c (   IDN_APPLN__c = 123456543, NBR_APPLN_SEC__c = 'ApplnNumber');
        insert applnCase;
        T_APPLN_PRCS_QUEUE__c applnPrcsQueue = new T_APPLN_PRCS_QUEUE__c( IDN_APPLN__c = applnCase.Id);
        insert applnPrcsQueue;
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new viewPeakApplnPdfMockTest());
        LightningServerResponse rtrn = viewPeakApplnPdfController.getPdfFromPeak(applnPrcsQueue.Id);
        //system.assertEquals(true,rtrn.isSuccessful,'isSuccessful is set to true');
        
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        LightningServerResponse rtrn1 = viewPeakApplnPdfController.getPdfFromPeak(applnPrcsQueue.Id);
        string applnId = viewPeakApplnPdfController.fetchPdfFileFromS3(applnPrcsQueue.Id);
        system.assertEquals(123456543,integer.valueOf(applnId),'isSuccessful is set to false');
        viewPeakApplnPdfController constructorTest = new viewPeakApplnPdfController() ;
		test.stopTest();
    }
}