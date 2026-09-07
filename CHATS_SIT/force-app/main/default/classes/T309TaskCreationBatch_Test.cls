@isTest
public class T309TaskCreationBatch_Test {
    @testSetup static void setup(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 16, true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.DTE_RCVD_PACKET_REDET__c =Date.today()-13;
        caseRec.DTE_SENT_PACKET_REDET__c = Date.today()-15;
        insert caseRec;
        
    }
    @isTest
    public static void testMethod1(){
        T_SBSD_CASE__c csRec = [select id from T_SBSD_CASE__c limit 1];
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(false, csRec.Id);
        caseStaMod.DTE_BEGIN_EFFV__c = Date.today()-15;
        caseStaMod.CDE_MODE_CASE__c = 'RED';
        Test.startTest();
        Insert caseStaMod;
        T309TaskCreationBatch sh1 = new T309TaskCreationBatch();     
        String sch = '0  00 1 3 * ?';
        String jobId = system.schedule('Test', sch, sh1);
        Test.stopTest();
    }
    @istest()
    public static void testMethod2(){
        Test.startTest();
        try{
            integer k = 1/0;
        }catch(exception e){
            T309TaskCreationBatch.setException(e);
        }
        
        Test.stopTest();
    }
}