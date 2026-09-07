@isTest
public class applicationPrcsSearchTriggerTest {
    static testmethod void testApplicationPrcsSearchTrigger(){
    	test.startTest();
        T_APPLN_PRCS_SEARCH__c applnPrcsSearchRec = new T_APPLN_PRCS_SEARCH__c(IDN_SEARCH_PRCS_APPLN__c = 12345);
        insert applnPrcsSearchRec;
        system.assertEquals(1,[select Id from T_APPLN_PRCS_SEARCH__c limit 10].size(),'Query should return Application Process Search record');
        test.stopTest();
    }
}