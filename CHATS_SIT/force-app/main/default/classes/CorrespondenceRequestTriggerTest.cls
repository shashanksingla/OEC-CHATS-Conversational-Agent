@isTest
public class CorrespondenceRequestTriggerTest {
    static testmethod void testCorrespondenceRequestTrigger(){
        test.startTest();
        T_COUNTY__c countyObj = new T_COUNTY__c(CNTY_DEPT_NAME__c = 'Arapahoe County', CDE_COUNTY__c = 3);
        insert countyObj;
        T_SBSD_CASE__c caseObject = new T_SBSD_CASE__c (	CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N', CDE_ASST_HSNG__c = 'N', Name = '123', CDE_LANG_CORR__c = 'SPN');
        insert caseObject;
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'Provider Test');
        insert providerObj;
        T_CHATS_PROVR_STATUS__c providerObj1 = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'Provider Test1');
        insert providerObj1;
        
        T_PROVR_PREF__c provrPref = new T_PROVR_PREF__c (IDN_PROVR__c = providerObj.Id, CDE_PREF_LANG_PROVR__c = 'SPN', CDE_PREF_CORR_PROVR__c = '1', IND_ACTIVE__c = true);
        insert provrPref;
        
        T_DOC_RQ__C corrReq_case = new T_DOC_RQ__C( 	NME_CORSPD__c = 'CR213',
                                             			CDE_CORSPD_STATUS__c='Requested',
                                                   		IDN_CASE__c = caseObject.Id,
                                                   		CDE_TYPE_RCPT__c='C');
        insert corrReq_case;
        
        T_DOC_RQ__C corrReq_provr = new T_DOC_RQ__C( 	NME_CORSPD__c = 'CR213',
                                             			CDE_CORSPD_STATUS__c='Requested',
                                                   		IDN_PROVR__c = providerObj.Id,
                                             			CDE_TYPE_RCPT__c='P');
        insert corrReq_provr;
        
        T_DOC_RQ__C corrReq_provr1 = new T_DOC_RQ__C( 	NME_CORSPD__c = 'CR213',
                                             			CDE_CORSPD_STATUS__c='Requested',
                                                   		IDN_PROVR__c = providerObj1.Id,
                                             			CDE_TYPE_RCPT__c='P');
        insert corrReq_provr1;
        
        
        
        test.stopTest();
    }
}