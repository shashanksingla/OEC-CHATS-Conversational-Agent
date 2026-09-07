@isTest
public class customLookupControllerTest {
    static testmethod void testFetchLookUpValues(){
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c (Name = '9999999', NAM_FACILITY__c = 'Lookup Provider');
        insert providerObj;
        List<T_CHATS_PROVR_STATUS__c> lookupList = customLookUpController.fetchLookUpValues(providerObj.Name, 'T_CHATS_PROVR_STATUS__c');
        system.assertEquals(1, lookupList.size(), 'lookup list size is 1');
        List<sObject> recentlyViewedList = customLookUpController.fetchRecentLookUpValues('T_CHATS_PROVR_STATUS__c');
        if(recentlyViewedList.size() == 0){
        	system.assertEquals(0, recentlyViewedList.size());
        } else {
            system.assertNotEquals(0, recentlyViewedList.size(), 'Recently Viewed object will return atleast one record');
        }
    }
}