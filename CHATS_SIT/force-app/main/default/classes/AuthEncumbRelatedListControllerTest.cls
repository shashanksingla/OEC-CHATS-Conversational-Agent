@isTest
public class AuthEncumbRelatedListControllerTest {

    static testMethod void getAuthEncumbRecordIdTest(){
        Test.startTest();
       	String recordId = AuthEncumbRelatedListController.getAuthEncumbRecordId('Test123');
       	System.assertEquals(null, recordId);
        Test.stopTest();
    }
    
    static testMethod void fetchRelatedObjectdataTest(){
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstNameA','1','lastNameA','1','CC');
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(false,'123');
        provider.CDE_TYPE_PROVR__c = 'FCCH';
        insert provider;
        T_AUTH__c authorization = new T_AUTH__c(DTE_BEGIN_EFFV_AUTH__c=system.today(),IDN_CLIENT__c=sbsdIndiv.id,IDN_EXTNL__c='Test123',IDN_PROVR__c=provider.Id);        
        insert authorization;
        
        Test.startTest();
        LightningServerResponse response=AuthEncumbRelatedListController.fetchRelatedObjectdata(authorization.id);
        System.assertEquals(true, response.isSuccessful);
        
        authEncumbranceRelatedListWrap wrap = new authEncumbranceRelatedListWrap('123', '123', '2', '1', Date.today(), 0, false,0);
        Test.stopTest();
    }

    testMethod static void fetchRelatedArchivedObjectdataTest(){
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true, date.newInstance(1983, 7, 15),'firstNameA','1','lastNameA','1','CC');
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(false,'123');
        provider.CDE_TYPE_PROVR__c = 'FCCH';
        insert provider;
        T_AUTH__c authorization = new T_AUTH__c(DTE_BEGIN_EFFV_AUTH__c = System.today(), IDN_CLIENT__c=sbsdIndiv.id, IDN_EXTNL__c='Test123', IDN_PROVR__c=provider.Id);        
        insert authorization;

        Test.startTest();
        LightningServerResponse response=AuthEncumbRelatedListController.fetchRelatedArchivedObjectdata(authorization.id, 'March', '2022');
        System.assertEquals(true, response.isSuccessful, 'Should be successful');
        Test.stopTest();
    }
}