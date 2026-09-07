/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           05/16/2019                                                         
*  @description    View Canned report as Excel Class Test  
*  * Version: 1.0                                                                             
*  * Date:  05/16/2019                                                           
*  * Author: Diya Chaudhary                                               
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class ViewCannedReportApxCtrlTest {
@isTest
    static void testviewCannedReportApxCtrl() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockTest());
        ViewCannedReportApxCtrl.geReportFromAWS();
        ViewCannedReportApxCtrl report = new ViewCannedReportApxCtrl();
        test.stopTest();
    }
    
	@isTest
    static void testviewCannedReportApxCtrlError() {
        test.startTest();
        ViewCannedReportApxCtrl.geReportFromAWS();
        test.stopTest();
    }
}