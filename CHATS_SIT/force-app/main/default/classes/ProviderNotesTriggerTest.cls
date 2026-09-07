@isTest(seeAllData=false)
public class ProviderNotesTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        insert new T_PROVR_NOTES__c(ID_SERVICE__c=TestClassUtility.createProvider(true,'Test').Id,TXT_DESC_NOTES__c='line1',
                                    TXT_SUBJECT__c='MAL',
                                    CDE_TYPE_NOTES__c='1'
                                   );
        
        Test.startTest();
        T_PROVR_NOTES__c pNotes =[Select Id, IDN_EXTNL__c  from T_PROVR_NOTES__c Limit 1];
        system.assertEquals(pNotes.Id,pNotes.IDN_EXTNL__c,'External Id is not matching with record Id');
        Test.stopTest();
    }
}