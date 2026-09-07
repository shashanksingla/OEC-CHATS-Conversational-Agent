@isTest
public class DeleteOldRevInterfaceReportsBatch_Test {
    public static testMethod void DeleteRevInterfaceReports_Test(){
        Reverse_Referral_Interface_Report__c revRef = TestClassUtility.createReverseRef(true,null,null,Date.today()-30,'323232');
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(5);
        String cronStr = '0 ' +  dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month()+ ' ? ' + dt.year();
        String batchName = 'DeleteOldReverseInterfaceReportsBatch_test';
        system.schedule(batchName, cronStr, new DeleteOldReverseInterfaceReportsBatch());
        Test.stopTest();
    }
    @istest()
    public static void testMethod2(){
        Test.startTest();
        try{
            integer k = 1/0;
        }catch(exception e){
            DeleteOldReverseInterfaceReportsBatch.setException(e.getMessage());
        }
        Test.stopTest();
    }
}