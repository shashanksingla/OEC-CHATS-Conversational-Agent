/*
*/
@isTest
public class CaseReOpenApxCtrlTest {
    public static testMethod void testGetInitData(){
        LightningServerResponse lsr = CaseReOpenApxCtrl.getInitData(null);
        System.assertEquals(false, lsr.isSuccessful, 'should be false');
        List<T_SBSD_CASE__c> caseList = [SELECT Id FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false, caseList.isEmpty(), 'caseList should not be empty');
        lsr = CaseReOpenApxCtrl.getInitData(caseList.get(0).Id);
        System.assertEquals(true, lsr.isSuccessful, 'should be true');
    }

    public static testMethod void testOnCaseReopenFlowCompletionBIE(){
        List<T_SBSD_CASE__c> caseList = [SELECT Id FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false, caseList.isEmpty(), 'caseList should not be empty');
        LightningServerResponse lsr = CaseReOpenApxCtrl.getInitData(caseList.get(0).Id);
        if(lsr.isSuccessful){
            T_SBSD_CASE__c caseRec = (T_SBSD_CASE__c)lsr.objectData.get('data');
            caseRec.DTE_APPLN__c = System.today().addDays(-1);
            T_SBSD_CASE_STATUS_MODE__c newCaseStatus = (T_SBSD_CASE_STATUS_MODE__c)lsr.objectData.get('newCaseStatus');
            newCaseStatus.CDE_ELIGTY_CONTNUS__c = 'N';
            Test.Starttest();
            T_SBSD_CASE_STATUS_MODE__c currentCaseStatusMode = (T_SBSD_CASE_STATUS_MODE__c)lsr.objectData.get('currentCaseStatusMode');            
            lsr = CaseReOpenApxCtrl.onCaseReopenFlowCompletion(caseRec,newCaseStatus, currentCaseStatusMode,new T_SBSD_CASE__c(DTE_APPLN__c = null),new T_CASE_APPLN_DTE__c(DTE_APPLN_OLD__c = System.today().addDays(-1),DTE_APPLN_NEW__c=system.today(),Reopened_or_Elig__c='Case Reopen'));// New parameter as part of CCCAP-13251
            Test.StopTest();
        }
    }

    public static testMethod void testOnCaseReopenFlowCompletionCE(){
        List<T_SBSD_CASE__c> caseList = [SELECT Id FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false, caseList.isEmpty(), 'caseList should not be empty');
        LightningServerResponse lsr = CaseReOpenApxCtrl.getInitData(caseList.get(0).Id);
        if(lsr.isSuccessful){
            T_SBSD_CASE__c caseRec = (T_SBSD_CASE__c)lsr.objectData.get('data');
            caseRec.DTE_APPLN__c = System.today().addDays(-1);
			T_SBSD_CASE_STATUS_MODE__c newCaseStatus = (T_SBSD_CASE_STATUS_MODE__c)lsr.objectData.get('newCaseStatus');
            newCaseStatus.CDE_ELIGTY_CONTNUS__c = 'Y';
            newCaseStatus.DTE_BEGIN_EFFV__c = System.today();
            T_SBSD_CASE_STATUS_MODE__c currentCaseStatusMode = (T_SBSD_CASE_STATUS_MODE__c)lsr.objectData.get('currentCaseStatusMode'); 
	        lsr = CaseReOpenApxCtrl.onCaseReopenFlowCompletion(caseRec,newCaseStatus, currentCaseStatusMode,new T_SBSD_CASE__c(DTE_APPLN__c = null),new T_CASE_APPLN_DTE__c(DTE_APPLN_OLD__c = null));// New parameter as part of CCCAP-13251
            lsr = CaseReOpenApxCtrl.onCaseReopenFlowCompletion(caseRec,newCaseStatus, currentCaseStatusMode,new T_SBSD_CASE__c(DTE_APPLN__c = null),new T_CASE_APPLN_DTE__c(DTE_APPLN_OLD__c = System.today().addDays(-1),DTE_APPLN_NEW__c=system.today(),Reopened_or_Elig__c='Case Reopen'));// New parameter as part of CCCAP-13251

        }
    }

    public static testMethod void testOnCaseReopenFlowCompletionError(){
        List<T_SBSD_CASE__c> caseList = [SELECT Id FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false, caseList.isEmpty(), 'caseList should not be empty');
        LightningServerResponse lsr = CaseReOpenApxCtrl.getInitData(caseList.get(0).Id);
        if(lsr.isSuccessful){
            T_SBSD_CASE__c caseRec = (T_SBSD_CASE__c)lsr.objectData.get('data');
            caseRec.DTE_RCVD_PACKET_REDET__c = System.today().addDays(-1);
			T_SBSD_CASE_STATUS_MODE__c newCaseStatus = (T_SBSD_CASE_STATUS_MODE__c)lsr.objectData.get('newCaseStatus');
            newCaseStatus.CDE_ELIGTY_CONTNUS__c = 'Y';
            newCaseStatus.DTE_BEGIN_EFFV__c = System.today();
            T_SBSD_CASE_STATUS_MODE__c currentCaseStatusMode = (T_SBSD_CASE_STATUS_MODE__c)lsr.objectData.get('currentCaseStatusMode'); 
            caseRec.IND_ASSIST_PROVR__c = 'Y';
            lsr = CaseReOpenApxCtrl.onCaseReopenFlowCompletion(caseRec,newCaseStatus, currentCaseStatusMode,caseRec,new T_CASE_APPLN_DTE__c(DTE_APPLN_OLD__c = System.today().addDays(-1),DTE_APPLN_NEW__c=system.today(),Reopened_or_Elig__c='Case Reopen'));// New parameter as part of CCCAP-13251
            lsr = CaseReOpenApxCtrl.onCaseReopenFlowCompletion(null,null, null,null,null);// New parameter as part of CCCAP-13251
        }
    }
    
    @testSetup
    public static void doSetUpData(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.DTE_APPLN__c = System.today().addDays(-10);
        insert caseRec;
	    T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
	    T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        insert new List<SObject>{new T_SBSD_CASE_STATUS_MODE__c(CDE_STATUS_CASE__c = 'CLS', CDE_MODE_CASE__c = 'INT', IDN_CASE__c = caseRec.Id, DTE_BEGIN_EFFV__c = System.today().addMonths(-2)),
            new T_SBSD_CASE_STATUS_MODE__c(CDE_STATUS_CASE__c = 'CLS', CDE_MODE_CASE__c = 'INT', IDN_CASE__c = caseRec.Id, DTE_BEGIN_EFFV__c = System.today().addMonths(-3), DTE_END_EFFV__c = System.today().addMonths(-2)),
            individual, individual2
            };
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual.Id,true);
        caseIndiv.DTE_BEGIN_EFFV__c =  System.today().addMonths(-3);
        T_SBSD_CASE_INDIV__c caseIndiv2 = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual2.Id,false);
        caseIndiv2.DTE_END_EFFV__c = System.today().addDays(10);
        insert new List<SObject>{caseIndiv,caseIndiv2}; 
                insert new List<SObject>{new T_SBSD_CASE_INDIV_ROLE__c( DTE_BEGIN_EFFV__c=System.today().addMonths(-50),IDN_CASE_INDIV__c= caseIndiv.id),
                    new T_INDIV_CAT_RQ__c(IDN_CASE_INDIV__c = caseIndiv.Id, CDE_CAT_PROG__c = 'CC', DTE_BEGIN_EFFV__c = System.today().addMonths(-4)),
						new T_INDIV_CAT_RQ__c(IDN_CASE_INDIV__c = caseIndiv2.Id, CDE_CAT_PROG__c = 'CC', DTE_BEGIN_EFFV__c = System.today().addMonths(-4))                    
                    }; 
    }

}