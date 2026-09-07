@isTest
public class applicationCaseTriggerTest {
    static testmethod void testApplicationCaseTrigger(){
    	test.startTest();
        T_APPLN_CASE__c applnCaseRec = new T_APPLN_CASE__c(IDN_APPLN__c = 12345);
        insert applnCaseRec;
        system.assertEquals(1,[select Id from T_APPLN_CASE__c limit 10].size(),'Query should return Application Case record');
        test.stopTest();
    }
}