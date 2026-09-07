@isTest(seeAllData=false)
public class ServicePeriodTrigger_Test {
    static testmethod  void testfetchLoggedInUserId(){
        Date beginEffectiveDate =  System.today();
        Date endEffectiveDate =  System.today() +1;
        Date paymentBatchFileDate =System.today();
        Date paymentBatchProcessedDate =  System.today() +1;
        Test.startTest();
        TestClassUtility.createServicePeriod(true,beginEffectiveDate,endEffectiveDate,paymentBatchFileDate,paymentBatchProcessedDate);
        T_SERV_PERIOD__c  servicePeriod =[Select Id, IDN_EXTNL__c  from T_SERV_PERIOD__c  Limit 1];
        system.assertEquals(servicePeriod.Id,servicePeriod.IDN_EXTNL__c,'External Id is not matching with record Id');
        Test.stopTest();
    }
}