@isTest 
public class AuthorizationBatchApxCtrl_Test 
{
    static testMethod void testMethod1() 
    {
        List<T_AUTH__c> lstAuth= new List<T_AUTH__c>();
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(NAM_FACILITY__c = 'Provider Test', TXT_CHATS_RATING__c ='Level 1');
        insert provider; 
        for(Integer i=0 ;i <10;i++)
        {
            T_AUTH__c acc = new T_AUTH__c();
            acc.DTE_END_EFFV_AUTH__c = system.today();
            acc.DTE_BEGIN_EFFV_AUTH__c = System.today();
            acc.IDN_PROVR__c = provider.Id;
            lstAuth.add(acc);
        }
        insert lstAuth;
        batchsit_t_auth_status__x stat = new batchsit_t_auth_status__x(idn_auth__c =lstAuth[0].Id);
        Test.startTest();
            AuthorizationBatchApxCtrl obj = new AuthorizationBatchApxCtrl();
            DataBase.executeBatch(obj); 
       system.assertEquals(10,[select Id from T_AUTH__c limit 100].size(),'Query should return 10 Auth records');      
        Test.stopTest();
    }
}