@IsTest(SeeAllData=false)
public class CannedReportHomepageControllerTest {
    
    static testMethod void testGetAvailableReportsOnHomepage(){
        CannedReportHomepageController.getAvailableReportsOnHomepage();
    }

    static testMethod void testgetAllReportName(){
        CannedReportHomepageController.getAllReportName();
    }
    
    static testMethod void testgetReportName(){
        CannedReportHomepageController.getReportName('Case');
    }
    
    static testMethod void testprocessViewResults(){
        CannedReportHomepageController.processViewResults('test','test1');
    }
  
}