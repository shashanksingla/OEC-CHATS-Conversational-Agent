@isTest
public class CBMSInboxScreenCtrlTest {

    public static testMethod void testgetInitCBMSRequestData(){
        LightningServerResponse lsr = CBMSInboxScreenCtrl.getInitCBMSRequestData(); 
    }
    
    public static testMethod void testSearchIndividualsForSimpleSearchIndividual(){
        List<T_APPLN_CASE__c> cases = [SELECT Id, IDN_APPLN__c FROM T_APPLN_CASE__c];
        System.assertEquals(false, cases.isEmpty(),'cases should not be empty');
        List<T_APPLN_INDIV__c> appIndiv = [SELECT Id, IDN_APPLN__c, NBR_SSN__c, NAM_FIRST__c, NAM_LAST__c FROM T_APPLN_INDIV__c Where IDN_APPLN__c=:cases.get(0).Id];
        System.assertEquals(false, appIndiv.isEmpty(),'appIndiv should not be empty');
        List<T_APPLN_PRCS_QUEUE__c> appQueues = [SELECT Id, Name, IDN_CASE__r.Name,DTE_RCVD_REF__c, IDN_APPLN__r.CBMS_REF_REASON__c,IDN_APPLN__r.CDE_CBMS_REF_TYP__c,CDE_SOURCE__c,IDN_APPLN__c, CDE_REJECT_APPLN__c,CDE_STATUS_APPLN__c,CDE_COUNTY__c,DTE_RCVD_APPLN__c, County_Name__r.Name  FROM T_APPLN_PRCS_QUEUE__c Where IDN_APPLN__c=:cases.get(0).Id];
        System.assertEquals(false, appQueues.isEmpty(),'appQueues should not be empty');
        Date fromDate = system.today() -1;
        Date toDate = system.today() +10;
        String applId = appQueues.get(0).Id;
        CBMSInboxWrapper cbmsInboxWrapper = new CBMSInboxWrapper(appQueues.get(0).CDE_COUNTY__c, appQueues.get(0).CDE_STATUS_APPLN__c,string.valueOf(appQueues.get(0).IDN_APPLN__r.CBMS_REF_REASON__c),appQueues.get(0).IDN_APPLN__r.CDE_CBMS_REF_TYP__c,  appIndiv.get(0).NAM_FIRST__c,appIndiv.get(0).NAM_LAST__c,fromDate,toDate);
        cbmsInboxWrapper.searchType ='StringSearch';
        List<CBMSResultWrapper> appCasesLst = (List<CBMSResultWrapper>)CBMSInboxScreenCtrl.processViewResults(JSON.serialize(cbmsInboxWrapper)).objectData.get('test');
        
        CBMSInboxWrapper cbmsInboxWrapper1 = new CBMSInboxWrapper(appQueues.get(0).CDE_COUNTY__c, appQueues.get(0).CDE_STATUS_APPLN__c,string.valueOf(appQueues.get(0).IDN_APPLN__r.CBMS_REF_REASON__c),appQueues.get(0).IDN_APPLN__r.CDE_CBMS_REF_TYP__c,  appIndiv.get(0).NAM_FIRST__c,appIndiv.get(0).NAM_LAST__c,fromDate,toDate);
        cbmsInboxWrapper1.searchType ='SoundexSearch';
        List<CBMSResultWrapper> appCasesLst1 = (List<CBMSResultWrapper>)CBMSInboxScreenCtrl.processViewResults(JSON.serialize(cbmsInboxWrapper1)).objectData.get('test');
    }
    
    @testSetup
    public static void doSetUp(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Adams','Adams',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        Date appDate = system.today();
        
        T_APPLN_CASE__c appCaseRec1 = new T_APPLN_CASE__c();
        appCaseRec1.IDN_APPLN__c = 55;
        appCaseRec1.DTE_RCVD_APPLN__c = appDate;
        appCaseRec1.CBMS_REF_REASON__c = 'New';
        appCaseRec1.CDE_CBMS_REF_TYP__c = 'New';
        insert appCaseRec1;
        
        T_APPLN_PRCS_QUEUE__c appQueueRec1 = new T_APPLN_PRCS_QUEUE__c();
        appQueueRec1.CDE_STATUS_APPLN__c = 'PRC';
        appQueueRec1.CDE_COUNTY__c = '1';
        appQueueRec1.CDE_SOURCE__c = 'CB';
        appQueueRec1.IDN_APPLN__c = appCaseRec1.Id;
        appQueueRec1.IDN_CASE__c = caseRec.Id;
        appQueueRec1.CDE_REJECT_APPLN__c = '';
        appQueueRec1.DTE_RCVD_REF__c=appDate;
        insert appQueueRec1;
        
        T_APPLN_INDIV__c appIndivRec1 = new T_APPLN_INDIV__c();
        appIndivRec1.IDN_APPLN__c = appCaseRec1.Id;
        appIndivRec1.NBR_SSN__c = '12345';
        appIndivRec1.NAM_FIRST__c = 'Test1';
        appIndivRec1.NAM_LAST__c = 'Name1';
        appIndivRec1.IND_CRTKR_PRIM__c = 'Y';
        insert appIndivRec1;
        
    }
}