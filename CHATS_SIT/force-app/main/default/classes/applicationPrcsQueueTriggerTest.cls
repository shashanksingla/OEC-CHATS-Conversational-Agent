@isTest
public class applicationPrcsQueueTriggerTest {
    static testmethod void testApplicationPrcsQueueTrigger(){
    	test.startTest();
        T_APPLN_PRCS_QUEUE__c applnPrcsQueueRec = new T_APPLN_PRCS_QUEUE__c(IDN_APPLN_COMPASS__c = 12345, DTE_RCVD_APPLN__c = system.today());
        insert applnPrcsQueueRec;
        system.assertEquals(1,[select Id from T_APPLN_PRCS_QUEUE__c limit 10].size(),'Query should return Application Process queue record');
        test.stopTest();
    }
}