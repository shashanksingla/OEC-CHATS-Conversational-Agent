@isTest
public class viewCorrespondencePdfControllerTest {
	@isTest
    static void testViewCorrespondencePdfController() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockTest());
        viewCorrespondencePdfController.getFileString();
        system.assertNotEquals('File does not exist.',viewCorrespondencePdfController.strConvertedBlob,'Return status should be null as there is no file name passed');
        test.stopTest();
    }
    
	@isTest
    static void testViewCorrespondencePdfControllerError() {
        test.startTest();
        viewCorrespondencePdfController.getFileString();
        test.stopTest();
    }
    
}