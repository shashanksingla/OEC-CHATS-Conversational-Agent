@isTest
public class tempBatchCBMSDatafixTest {
    
    
    public static testMethod void testCheckIfAppHasPrimaryCaretaker(){ 
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true); 
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(NBR_PHONE_CELL__c='9999999999', NBR_PHONE_HOME__c = '9999999999', NBR_PHONE_MSG_EXTN__c = '9876', NBR_PHONE_MSG__c = '9999999999', CDE_INFO_PMC__c = 'WOR',CDE_INFO_EM__c='test@test.com', IND_IS_HOMELESS__c='Y',WORK_SPECIALIST__c='Conversion user' );
        insert appCase;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, county.Id); 
        
        
        T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
            IDN_APPLN__c = appCase.Id,
            CDE_SOURCE__c = 'PK',
            DTE_RCVD_APPLN__c = System.today().addDays(-15),
            CDE_COUNTY__c = '1',
            IDN_CASE__c = caseRec.Id
        );
        insert appProcessQueue; 
        
        Test.startTest();
        tempBatchCBMSDatafix obj = new tempBatchCBMSDatafix();
        DataBase.executeBatch(obj); 
        //system.assertEquals(10,[select Id from T_AUTH__c limit 100].size(),'Query should return 10 Auth records');      
        Test.stopTest(); 
        
    }
    
}