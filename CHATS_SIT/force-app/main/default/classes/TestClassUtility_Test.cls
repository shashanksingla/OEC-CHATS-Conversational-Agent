/*************************************************************
Class Name	    - TestClassUtility_Test
Covering Class	- TestClassUtility
Author          - Rishav Maji
**************************************************************/
@isTest
public class TestClassUtility_Test {
    
    @testSetup
    public static void doSetup(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_CHATS_PROVR_STATUS__c prov = TestClassUtility.createProvider(true, 'Level 2');
        T_SBSD_INDIV__c indiv = TestClassUtility.createIndividual(true, System.today().addYears(-35), 'firstname', '1', 'lastname', '999999', 'CC');
        T_ADJMT__c caseAdj = TestClassUtility.createAdjustment(false, countyRec.Id, caseRec.Id, null);
        caseAdj.CDE_TYPE_ADJMT__c = '2';
        caseAdj.DTE_DISCV_ADJMT_ORIG__c = System.today();
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(CDE_COUNTY__c = '2');
        GenericDMLHandler.insertRecords(new List<Sobject>{appCase, caseAdj}, null);
    }
    
    public static testMethod void testAllMethods_part1(){
        Test.startTest();
        T_COUNTY__c c = TestClassUtility.createCounty('test', 'test', 2, true);
        T_CHATS_PROVR_STATUS__c prov = TestClassUtility.createProvider(true, 'Level 1');
        String idProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u = TestClassUtility.createUser(idProfile, 'Test', 'Test', 'test@invalid.com', 'test@invalid.com.'+string.valueof(math.random()*3), 'ttes');
        Insert u;
        T_AUTH__c auth = TestClassUtility.createAuthorization(true, System.today().addDays(30), System.today(), c.Id, prov.Id);
        T_SBSD_CASE__c cs = TestClassUtility.createCase(true, c.Id);
        T_SBSD_INDIV__c indiv = TestClassUtility.createIndividual(true, System.today().addYears(-30), 'firstname', '1', 'lastname', '123456', 'CC');
        T_APPEAL__c app = TestClassUtility.createAppeal(true, cs.Id, c.Id, prov.Id);
        T_INDIV_DISQLN__c indivDisq = TestClassUtility.createIndivDisqln(true, app.Id);
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, cs.Id, indiv.Id, true);
        T_PROVR_FISCAL_AGREMENT__c pfa = TestClassUtility.createFiscaAgreement(true, 'Test', System.today(), c.Id);
        T_COPAY_DELINQC__c del = TestClassUtility.createparentFeelDelinq(true, cs.Id, indiv.Id, 1);
        T_PMT_PLAN__c pmtPlan = TestClassUtility.createPaymentPlan(true, prov.Id, 10, 10, 5);
        T_PRIM_ACTV__c pAct = TestClassUtility.createPrimaryActivity(true, cs.Id, indiv.Id, System.today(), System.today().addDays(1), 'EMP');
        T_PRIM_ACTV_CNTR__c pActCNTR = TestClassUtility.createPrimaryActivityCNTR(true, indiv.Id, pAct.Id, 1);
        T_FISCAL_SCH__c faSch = TestClassUtility.createRateSchedule(true, System.today(), System.today().addDays(1), pfa.Id, '1');
        batchsit_t_eligty_run__x elig = TestClassUtility.createEligibilityRunRecord(true, cs.Id);
        T_ADJMT__c adj = TestClassUtility.createAdjustment(false, c.Id, cs.Id, prov.Id);
        Task tsk = TestClassUtility.createTask(true, 'subject', 'description', 'Not Started', cs.Id, u.Id);
        Test.stopTest();
        System.assertEquals(2, c.CDE_COUNTY__c);
        System.assertEquals('Level 1', prov.TXT_CHATS_RATING__c);
        System.assertEquals('Test', u.LastName);
        System.assertEquals(c.Id, auth.CDE_COUNTY__c);
        System.assertEquals('N', cs.IND_ASSIST_PROVR__c);
        System.assertEquals('NA', indiv.IND_CDE_TYPE_VERIF_DOB__c);
        System.assertEquals(cs.Id, app.IDN_CASE__c);
        System.assertEquals('Y', indivDisq.CDE_TYPE_ASSIGN__c);
        System.assertEquals(true, caseIndiv.IND_CRTKR__c);
        System.assertEquals(System.today(), pfa.DTE_RCV_AGRMT_FISCAL__c);
        System.assertEquals(cs.Id, del.IDN_CASE__c);
        System.assertEquals(10, pmtPlan.AMT_PLAN_PMT__c);
        System.assertEquals('EMP', pAct.CDE_TYPE_ACTV__c);
        System.assertEquals(1, pActCNTR.CNT_WEEKS__c);
        System.assertEquals(pfa.Id, faSch.IDN_AGRMT_FISCAL__c);
        System.assertEquals(1234, elig.idn_run_eligty__c);
        System.assertEquals('1', adj.CDE_STATUS_ADJMT__c);
        System.assertEquals('subject', tsk.Subject);
    }
    public static testMethod void testAllMethod_part3(){
        Test.startTest();
        T_COUNTY_PLAN__c cp = TestClassUtility.createCountyPlan('PEN', true);
        T_COUNTY_RATE__c crp = TestClassUtility.createCountyRatePlan('PEN', true);
        T_COUNTY_RATE_AMT__c cra = TestClassUtility.createCountyRateAmount(crp.Id, true);
        String idProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        String idRole = [SELECT Id FROM UserRole WHERE Name = 'Template Administrator' LIMIT 1].Id;
        User u2 = TestClassUtility.createUserWithRole(idProfile, 'Test', 'Test', 'test@invalid.com', 'test@invalid.com.'+string.valueof(math.random()*3), 'test', idRole);
        T_SBSD_INDIV__c childIndiv = TestClassUtility.createIndividual(true, System.today().addYears(-10), 'firstName', '1', 'lastName', '01234567', 'CC');
        T_INDIV_DSBLTY__c indivDsbl = TestClassUtility.createIndivDisability(true, childIndiv.Id);
        T_CHILD_SUP__c chSup = TestClassUtility.createChildSupport(true, childIndiv.Id);
        T_PROVR_PREF__c pp = TestClassUtility.createCorrespondanceAndLanguagePref(false, 'Test', 'en');
        T_APPLN_CASE__c appCase = [SELECT Id FROM T_APPLN_CASE__c WHERE CDE_COUNTY__c = '2' LIMIT 1];
        T_APPLN_INDIV__c appIndiv = TestClassUtility.createApplicationIndividual(true, System.today().addYears(-35), 'firstname', '1', 'lastname', '123456', appCase.Id);
        TestClassUtility.createServicePeriod(true, System.today(), System.today().addDays(1), System.today(), System.today());
        T_FISCAL_RAT_FEES__c rat = TestClassUtility.createRATFees(true);
        Test.stopTest();
        System.assertEquals('123456', appIndiv.NBR_SSN__c);
        System.assertEquals('Test', u2.LastName);
        System.assertEquals(false, pp.IND_ACTIVE__c);
        System.assertEquals('2', cra.CDE_UNIT__c);
        System.assertEquals('1', cp.CDE_COUNTY_PLAN_TEMPLT__c);
        System.assertEquals('PEN', crp.CDE_STATUS__c);
        System.assertEquals('Y', indivDsbl.IND_CC_GIVE_ABLE__c);
        System.assertEquals('N', chSup.IND_COOP_PARENT__c);
    }
    public static testMethod void testAllMethods_part2(){
        Test.startTest();
        T_ADJMT__c adj = [SELECT Id FROM T_ADJMT__c WHERE CDE_COUNTY__r.CDE_COUNTY__c = 1 LIMIT 1];
        T_SBSD_CASE__c cs = [SELECT Id FROM T_SBSD_CASE__c WHERE CDE_COUNTY__r.CDE_COUNTY__c = 1 LIMIT 1];
        T_CHATS_PROVR_STATUS__c prov = [SELECT Id FROM T_CHATS_PROVR_STATUS__c WHERE TXT_CHATS_RATING__c = 'Level 2' LIMIT 1];
        T_SBSD_INDIV__c indiv = [SELECT Id FROM T_SBSD_INDIV__c WHERE NBR_SSN__c = '999999' LIMIT 1];
        T_SBSD_CASE_STATUS_MODE__c caseMode = TestClassUtility.createCaseStatusMode(true, cs.Id);
        T_ADJMT_ADDR__c adjAdd = TestClassUtility.createAdjustmentAddress(true, adj.Id);
        T_ADJMT_DETAIL__c adjDet = TestClassUtility.createAdjustmentDetail(true, adj.Id);
        T_ADJMT_CMT__c adjNote = TestClassUtility.createAdjustmentNote(true, adj.Id);
        T_ADJMT_PMT__c adjPmt = TestClassUtility.createAdjustmentPayment(false, cs.Id, null);
        T_ADJMT_PMT_DETAIL__c adjPmtDet = TestClassUtility.createAdjustmentPaymentDetail(true, adjDet.Id, adj.Id, null);
        T_ADJMT_RESPBL_PARTY__c adjRsp = TestClassUtility.createAdjustmentRespPart(true, cs.Id, prov.Id, indiv.Id, adj.Id);
        T_SBSD_CASE_WTLST__c wtlst = TestClassUtility.createCaseWaitlist(true, cs.Id, System.today(), System.today().addDays(1), 'REM');
        Reverse_Referral_Interface_Report__c revRef = TestClassUtility.createReverseRef(true,cs.Id,cs.Id,Date.today(),'323232');
        Test.stopTest();
        
        System.assertEquals('INT', caseMode.CDE_MODE_CASE__c);
        System.assertEquals(adj.Id, adjAdd.IDN_ADJMT__c);
        System.assertEquals(adj.Id, adjDet.IDN_ADJMT__c);
        System.assertEquals(adj.Id, adjNote.IDN_ADJMT__c);
        System.assertEquals('1', adjPmt.CDE_TYPE_PMT_ADJMT__c);
        System.assertEquals(adj.Id, adjPmtDet.IDN_ADJMT__c);
        System.assertEquals(adj.Id, adjRsp.IDN_ADJMT__c);
        System.assertEquals('REM', wtlst.CDE_STATUS_WTLST__c);
    }
}