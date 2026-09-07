/**/
public with sharing class CaseLastUpdatedTestFactory {
    public static Map<String, SObject> createCaseData(){
        Map<String, SObject> caseData = new Map<String, SObject>();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(true, caseRec.Id);
        caseData.put('countyRec',countyRec);
        caseData.put('individual',individual);
        caseData.put('caseRec',caseRec);
        caseData.put('caseIndiv',caseIndiv);
        caseData.put('caseStaMod',caseStaMod);
        return caseData;
    }
    
    public static void testCaseDataUpdate(){
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c Limit 1];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        System.assertEquals(true, caseRecords.get(0).IND_CHGD_DATA_ELIGTY__c, 'IND_CHGD_DATA_ELIGTY__c should be true');
    }
    
    public static void testCaseStatusModeCreate(){
        List<T_SBSD_CASE__c> caseRecords = [SELECT DTE_SENT_PACKET_REDET__c, DTE_RCVD_PACKET_REDET__c FROM T_SBSD_CASE__c Limit 1];
        List<T_SBSD_CASE_STATUS_MODE__c> caseStatusMode = [Select CDE_MODE_CASE__c,CDE_STATUS_CASE__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,Id,IDN_CASE__c from T_SBSD_CASE_STATUS_MODE__c where IDN_CASE__c=:caseRecords.get(0).Id];
        System.assertEquals(1,caseStatusMode.size(),'New Case Status Mode record need to be created');
        System.assertEquals(date.today()+5, caseRecords.get(0).DTE_RCVD_PACKET_REDET__c, 'DTE_RCVD_PACKET_REDET__c Needs to be updated with NEw value');
        
    }
    
}