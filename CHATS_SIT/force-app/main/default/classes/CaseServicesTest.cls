/*
*/
@isTest
public class CaseServicesTest {
    
    public static testMethod void testDeleteChildRecords(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        caseRec.Is_Peak_Data__c = true;
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(true, caseRec.Id);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(NAM_FACILITY__c = 'Provider Test', TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        insert new List<SObject>{new T_APPLN_PRCS_QUEUE__c(IDN_CASE__c = caseRec.id),
            new T_APPEAL__c(IDN_CASE__c = caseRec.id),
            new T_AUTH__c(IDN_CASE__c = caseRec.id, IDN_PROVR__c = provider.Id),
            new T_COPAY_DELINQC__c(IDN_CASE__c = caseRec.id, AMT_DELINQC_COPAY_ENRLMT__c=1)
            };
        insert new List<SObject>{
            new T_SBSD_CASE_ADR__c(IDN_CASE__c = caseRec.id),
                new T_SBSD_CASE_ASSET__c(IDN_CASE__c = caseRec.id),
                new T_SBSD_CASE_HOMELESS__c(IDN_CASE__c = caseRec.id,DTE_BEGIN_EFFV__c=date.Today())
                };
        Test.startTest();
        delete caseRec;
        System.assert([SELECT Id FROM T_APPLN_PRCS_QUEUE__c]!=null);
        System.assert([SELECT Id FROM T_ADJMT__c]!=null);
        System.assert([SELECT Id FROM T_ADJMT_RESPBL_PARTY__c]!=null);
        System.assert([SELECT Id FROM T_CBMS_ADDNL_INFO__c]!=null);
        System.assert([SELECT Id FROM T_DOC_RQ__c]!=null);
        System.assert([SELECT Id FROM T_CW_ADDNL_INFO__c]!=null);
        System.assert([SELECT Id FROM T_APPEAL__c]!=null);
        System.assert([SELECT Id FROM T_AUTH__c]!=null);
        System.assert([SELECT Id FROM T_COPAY_DELINQC__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_WTLST__c]!=null);
        System.assert([SELECT Id FROM T_PRIM_ACTV__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_INFO__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_PHONE__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_ADR__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_ASSET__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_HOMELESS__c]!=null);
        Test.stopTest();
    }
    
    public static testMethod void testDeleteChildRecords1(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        caseRec.Is_Peak_Data__c = true;
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(true, caseRec.Id);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(NAM_FACILITY__c = 'Provider Test', TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        insert new List<SObject>{new T_APPLN_PRCS_QUEUE__c(IDN_CASE__c = caseRec.id),
            new T_ADJMT__c(IDN_CASE__c = caseRec.id),
            new T_ADJMT_RESPBL_PARTY__c(IDN_CASE__c = caseRec.id),
            new T_CBMS_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseRec.id, DTE_BEGIN_EFFEV__c = system.today())
            };
        insert new List<SObject>{
            new T_SBSD_CASE_WTLST__c(IDN_CASE__c = caseRec.id),
                new T_PRIM_ACTV__c(IDN_CASE__c = caseRec.id, CDE_TYPE_ACTV__c = 'DSB'),
                new T_SBSD_CASE_INFO__c(IDN_CASE__c = caseRec.id)
                };
        Test.startTest();
        delete caseRec;
        System.assert([SELECT Id FROM T_APPLN_PRCS_QUEUE__c]!=null);
        System.assert([SELECT Id FROM T_ADJMT__c]!=null);
        System.assert([SELECT Id FROM T_ADJMT_RESPBL_PARTY__c]!=null);
        System.assert([SELECT Id FROM T_CBMS_ADDNL_INFO__c]!=null);
        System.assert([SELECT Id FROM T_DOC_RQ__c]!=null);
        System.assert([SELECT Id FROM T_CW_ADDNL_INFO__c]!=null);
        System.assert([SELECT Id FROM T_APPEAL__c]!=null);
        System.assert([SELECT Id FROM T_AUTH__c]!=null);
        System.assert([SELECT Id FROM T_COPAY_DELINQC__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_WTLST__c]!=null);
        System.assert([SELECT Id FROM T_PRIM_ACTV__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_INFO__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_PHONE__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_ADR__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_ASSET__c]!=null);
        System.assert([SELECT Id FROM T_SBSD_CASE_HOMELESS__c]!=null);
        Test.stopTest();
    }
}