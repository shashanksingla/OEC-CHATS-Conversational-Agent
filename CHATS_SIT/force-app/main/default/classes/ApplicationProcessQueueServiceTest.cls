@isTest
public class ApplicationProcessQueueServiceTest {    
    public final static String EMPTY_LOOKUP = null;
    public static testMethod void testPopulateCountyNameBasedOnCountyCodeValid(){
        Test.startTest();
        T_COUNTY__c county = [SELECT Id from T_COUNTY__c WHERE CDE_COUNTY__c=1 LIMIT 1];
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(NBR_PHONE_CELL__c='9999999999', NBR_PHONE_HOME__c = '9999999999', NBR_PHONE_MSG_EXTN__c = '9876', NBR_PHONE_MSG__c = '9999999999', CDE_INFO_PMC__c = 'WOR');
            insert appCase;
            T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
                IDN_APPLN__c = appCase.Id,
                CDE_SOURCE__c = 'PK',
                DTE_RCVD_APPLN__c = System.today().addDays(-15),
                County_Name__c = county.Id
            );
            insert appProcessQueue;
        system.assertEquals(1,[select Id from T_APPLN_PRCS_QUEUE__c LIMIT 10].size(),'Query should return Application Process Queue record');
        Test.stopTest();
    }
    
    public static testMethod void testPopulateCountyNameBasedOnCountyCodeNotValid(){
        T_COUNTY__c county = [SELECT Id from T_COUNTY__c WHERE CDE_COUNTY__c=2 LIMIT 1];
        Test.startTest();
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(NBR_PHONE_CELL__c='9999999999', NBR_PHONE_HOME__c = '9999999999', NBR_PHONE_MSG_EXTN__c = '9876', NBR_PHONE_MSG__c = '9999999999', CDE_INFO_PMC__c = 'WOR');
        insert appCase;
        T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
            IDN_APPLN__c = appCase.Id,
            CDE_SOURCE__c = 'PK',
            DTE_RCVD_APPLN__c = System.today().addDays(-15),
            County_Name__c = county.Id
        );
        insert appProcessQueue;
        system.assertEquals(1,[select Id from T_APPLN_PRCS_QUEUE__c LIMIT 10].size(),'Query should return Application Process Queue record');
        Test.stopTest();
    }
    
    public static testMethod void testPopulateCountyNameBasedOnCountyException(){
        Test.startTest();
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(NBR_PHONE_CELL__c='9999999999', NBR_PHONE_HOME__c = '9999999999', NBR_PHONE_MSG_EXTN__c = '9876', NBR_PHONE_MSG__c = '9999999999', CDE_INFO_PMC__c = 'WOR');
        insert appCase;
        T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
            IDN_APPLN__c = appCase.Id,
            CDE_SOURCE__c = 'PK',
            DTE_RCVD_APPLN__c = System.today().addDays(-15),
            CDE_COUNTY__c = 'AB'
        );
        try{
            insert appProcessQueue;
            System.assert(true, 'This line should not execute');
        }catch(Exception ex){
            T_COUNTY__c cnty = [SELECT Id from T_COUNTY__c WHERE CDE_COUNTY__c=1 LIMIT 1];
            T_APPLN_PRCS_QUEUE__c appProcessQueue2 = new T_APPLN_PRCS_QUEUE__c(
                IDN_APPLN__c = appCase.Id,
                CDE_SOURCE__c = 'PK',
                DTE_RCVD_APPLN__c = System.today().addDays(-15),
                County_Name__c = cnty.Id
            );
            insert appProcessQueue2;
            appProcessQueue2.CDE_COUNTY__c = EMPTY_LOOKUP;
            update appProcessQueue2;
            system.assertEquals(1,[select Id from T_APPLN_PRCS_QUEUE__c LIMIT 10].size(),'Query should return Application Process Queue record');
            T_COUNTY__c county=TestClassUtility.createCounty('Denver', 'Test Dept', 16, true);
            appProcessQueue2.County_Name__c = county.Id;
            appProcessQueue2.County_Transfer_Notes__c = 'updating County';
            update appProcessQueue2;
            appProcessQueue2.County_Name__c = EMPTY_LOOKUP;
            appProcessQueue2.County_Transfer_Notes__c = 'updating County Again';
            update appProcessQueue2;
            T_APPLN_PRCS_SEARCH__c appProcessSearch = new T_APPLN_PRCS_SEARCH__c(IDN_APPLN__c = appCase.Id);
            insert appProcessSearch;
            appProcessQueue2.CDE_STATUS_APPLN__c = 'PRC';
            update appProcessQueue2;
        }
        Test.stopTest();
    }
    
    @testSetup
    public static void setUpData(){
        TestClassUtility.createCounty('Denver','Denver',1,true);
        TestClassUtility.createCounty('Weld','Weld',2,true);
    }
    
}