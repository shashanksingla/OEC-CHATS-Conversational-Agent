@isTest
public class PeakInboxScreenCtrlTest {
    
    public static testMethod void testgetInitPeakRequestData(){
        LightningServerResponse lsr = PeakInboxScreenCtrl.getInitPeakRequestData(); 
    }
    
    public static testMethod void testSearchIndividualsForSimpleSearchIndividual(){
        List<T_APPLN_CASE__c> cases = [SELECT Id, IDN_APPLN__c FROM T_APPLN_CASE__c];
        System.assertEquals(false, cases.isEmpty(),'cases should not be empty');
        List<T_APPLN_INDIV__c> appIndiv = [SELECT Id, IDN_APPLN__c, NBR_SSN__c, NAM_FIRST__c, NAM_LAST__c FROM T_APPLN_INDIV__c Where IDN_APPLN__c=:cases.get(0).Id];
        System.assertEquals(false, appIndiv.isEmpty(),'appIndiv should not be empty');
        List<T_APPLN_PRCS_QUEUE__c> appQueues = [SELECT Id, Name, IDN_CASE__r.Name, CDE_SOURCE__c,IDN_APPLN__c, CDE_REJECT_APPLN__c,CDE_STATUS_APPLN__c,CDE_COUNTY__c,DTE_RCVD_APPLN__c, County_Name__r.Name  FROM T_APPLN_PRCS_QUEUE__c Where IDN_APPLN__c=:cases.get(0).Id];
        System.assertEquals(false, appQueues.isEmpty(),'appQueues should not be empty');
        Date fromDate = system.today() -1;
        Date toDate = system.today() +10;
        String applId = appQueues.get(0).Id;
        PeakInboxWrapper peakInboxWrapper = new PeakInboxWrapper(appQueues.get(0).CDE_COUNTY__c, appQueues.get(0).CDE_STATUS_APPLN__c,appIndiv.get(0).NBR_SSN__c, string.valueOf(cases.get(0).IDN_APPLN__c), 'StringSearch',appIndiv.get(0).NAM_FIRST__c,appIndiv.get(0).NAM_LAST__c,fromDate,toDate);
        PeakInboxWrapper peakInboxWrapper1 = new PeakInboxWrapper(appQueues.get(0).CDE_COUNTY__c, appQueues.get(0).CDE_STATUS_APPLN__c,appIndiv.get(0).NBR_SSN__c, string.valueOf(cases.get(0).IDN_APPLN__c), 'SoundexSearch',appIndiv.get(0).NAM_FIRST__c,appIndiv.get(0).NAM_LAST__c,fromDate,toDate);
        PeakInboxWrapper peakInboxWrapperLstNameNull = new PeakInboxWrapper(appQueues.get(0).CDE_COUNTY__c, appQueues.get(0).CDE_STATUS_APPLN__c,appIndiv.get(0).NBR_SSN__c, string.valueOf(cases.get(0).IDN_APPLN__c), 'SoundexSearch',appIndiv.get(0).NAM_FIRST__c,null,fromDate,toDate);
        PeakInboxWrapper peakInboxWrapper1FstnameNull = new PeakInboxWrapper(appQueues.get(0).CDE_COUNTY__c, appQueues.get(0).CDE_STATUS_APPLN__c,appIndiv.get(0).NBR_SSN__c, string.valueOf(cases.get(0).IDN_APPLN__c), 'SoundexSearch',null,appIndiv.get(0).NAM_LAST__c,fromDate,toDate);
        List<PeakResultWrapper> appCasesLst = (List<PeakResultWrapper>)PeakInboxScreenCtrl.processViewResults(JSON.serialize(peakInboxWrapper)).objectData.get('test');
        List<PeakResultWrapper> appCasesLst1 = (List<PeakResultWrapper>)PeakInboxScreenCtrl.processViewResults(JSON.serialize(peakInboxWrapper1)).objectData.get('test');
        List<PeakResultWrapper> appCasesLst2 = (List<PeakResultWrapper>)PeakInboxScreenCtrl.processViewResults(JSON.serialize(peakInboxWrapperLstNameNull)).objectData.get('test');
        List<PeakResultWrapper> appCasesLst3 = (List<PeakResultWrapper>)PeakInboxScreenCtrl.processViewResults(JSON.serialize(peakInboxWrapper1FstnameNull)).objectData.get('test');
    }
    
    @testSetup
    public static void doSetUp(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Adams','Adams',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        Date appDate = system.today();
        
        T_APPLN_CASE__c appCaseRec1 = new T_APPLN_CASE__c();
        appCaseRec1.IDN_APPLN__c = 55;
        appCaseRec1.DTE_RCVD_APPLN__c = appDate;
        insert appCaseRec1;
        
        T_APPLN_PRCS_QUEUE__c appQueueRec1 = new T_APPLN_PRCS_QUEUE__c();
        appQueueRec1.CDE_STATUS_APPLN__c = 'PRC';
        appQueueRec1.CDE_COUNTY__c = '1';
        appQueueRec1.CDE_SOURCE__c = 'PK';
        appQueueRec1.IDN_APPLN__c = appCaseRec1.Id;
        appQueueRec1.IDN_CASE__c = caseRec.Id;
        appQueueRec1.CDE_REJECT_APPLN__c = '';
        insert appQueueRec1;
        LightningServerResponse lsr = PeakInboxScreenCtrl.validateCounty(appQueueRec1.Id);
        T_APPLN_INDIV__c appIndivRec1 = new T_APPLN_INDIV__c();
        appIndivRec1.IDN_APPLN__c = appCaseRec1.Id;
        appIndivRec1.NBR_SSN__c = '12345';
        appIndivRec1.NAM_FIRST__c = 'Test1';
        appIndivRec1.NAM_LAST__c = 'Name1';
        appIndivRec1.IND_CRTKR_PRIM__c = 'Y';
        insert appIndivRec1;
        
    }
}