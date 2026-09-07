@isTest
public class ProviderHeaderForExternalTest {

    static testmethod void testProvrHdr() {
        T_CHATS_PROVR_CNT_INFO_c__x provrContact = new T_CHATS_PROVR_CNT_INFO_c__x();
        T_CHATS_PROVR_COND_c__x provrCond = new T_CHATS_PROVR_COND_c__x();
        T_CHATS_PROVR_CAPACITY_c__x provrCpcty = new T_CHATS_PROVR_CAPACITY_c__x();
        //Removed unused variable on 5/14/2018 BG  
        
        test.startTest();
        String strProvrCntc, strProvrCond, strProvrCpcty;
        strProvrCntc = 'Provider Contact';
        strProvrCond = 'Provider Condition';
        strProvrCpcty = 'Provider Capacity';
        
        //provrContact = [select Id, ExternalId FROM T_CHATS_PROVR_CNT_INFO_c__x ];
        //provrCond = [select Id FROM T_CHATS_PROVR_COND_c__x ];
        //provrCpcty = [select Id FROM T_CHATS_PROVR_CAPACITY_c__x ];
        
        system.assert(string.valueOf(providerHdrForExtnlobjects.providerHeaderId (provrContact.Id, strProvrCntc)).contains('T_CHATS_PROVR_STATUS__c'),'Should return Provider record');
        system.assert(string.valueOf(providerHdrForExtnlobjects.providerHeaderId (provrCond.Id, strProvrCond)).contains('T_CHATS_PROVR_STATUS__c'),'Should return Provider record');
        system.assert(string.valueOf(providerHdrForExtnlobjects.providerHeaderId (provrCpcty.Id, strProvrCpcty)).contains('T_CHATS_PROVR_STATUS__c'),'Should return Provider record');
        test.stopTest();
        
    }
}