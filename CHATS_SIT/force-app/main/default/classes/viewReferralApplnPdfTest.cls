@isTest
private class viewReferralApplnPdfTest {
    
    static testmethod void testGetPdf() {
        T_APPLN_CASE__c applnCase = new T_APPLN_CASE__c(IDN_APPLN__c=123456543, NBR_APPLN_SEC__c='ApplnNumber', IDN_CBMS_REF__c='12345');
        insert applnCase;
        T_APPLN_PRCS_QUEUE__c applnPrcsQueue = new T_APPLN_PRCS_QUEUE__c(IDN_APPLN__c = applnCase.Id);
        insert applnPrcsQueue;
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new viewPeakApplnPdfMockTest());
        LightningServerResponse rtrn = viewReferralApplnPdfController.getReferralPdf(applnPrcsQueue.Id);
        system.assertEquals(true,rtrn.isSuccessful,'isSuccessful is set to true');
        
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        LightningServerResponse rtrn1 = viewReferralApplnPdfController.getReferralPdf(applnPrcsQueue.Id);
        string applnId = viewReferralApplnPdfController.fetchPdfFileFromS3(applnPrcsQueue.Id);
        viewReferralApplnPdfController constructorTest = new viewReferralApplnPdfController() ;
		test.stopTest();
    }
}