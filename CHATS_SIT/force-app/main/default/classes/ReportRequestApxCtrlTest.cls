/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           05/09/2019                                                         
*  @description    Request Report Class Test  
*  * Version: 1.0                                                                             
*  * Date:  05/09/2019                                                           
*  * Author: Diya Chaudhary                                               
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class ReportRequestApxCtrlTest {
    static testMethod void getInitReportRequestDataScenario() {
        Test.startTest();
        ReportRequestApxCtrl.getInitReportRequestData('RE213');
        ReportRequestApxCtrl.submitReportReq('12-12-2019', '12-12-2019', '', '','',1,'',2,'','');
        Test.stopTest();
    }
    
}