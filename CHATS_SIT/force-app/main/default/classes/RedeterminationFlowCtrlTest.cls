@isTest
public class RedeterminationFlowCtrlTest {
    public static testMethod void testUpdateCase(){
        test.startTest();
        T_SBSD_CASE__c caseRecord = new T_SBSD_CASE__c();
        insert caseRecord;
        T_SBSD_CASE_STATUS_MODE__c caseStatusModeChild = new T_SBSD_CASE_STATUS_MODE__c();
        caseStatusModeChild.IDN_CASE__c = caseRecord.Id; 
        caseStatusModeChild.DTE_BEGIN_EFFV__c = date.today()-2;
        insert caseStatusModeChild;
        LightningServerResponse lsr=RedeterminationFlowCtrl.updateCase(new List<SObject>{caseRecord});
        system.assertEquals(true,lsr.isSuccessful,'isSuccessful should be true');
        test.stopTest();
    }
    
    public static testMethod void testUpdateCaseError(){
        test.startTest();
        T_SBSD_CASE__c caseRecord = new T_SBSD_CASE__c();
        insert caseRecord;
        T_SBSD_CASE_STATUS_MODE__c caseStatusModeChild = new T_SBSD_CASE_STATUS_MODE__c();
        caseStatusModeChild.IDN_CASE__c = caseRecord.Id; 
        caseStatusModeChild.DTE_BEGIN_EFFV__c = date.today()-2;
        insert caseStatusModeChild;
        caseRecord.CNT_SIZE_FAMILY__c = 12345678;
        LightningServerResponse lsr=RedeterminationFlowCtrl.updateCase(new List<SObject>{caseRecord});
        system.assertEquals(false,lsr.isSuccessful,'isSuccessful should be false');
        test.stopTest();
    }
    
    public static testMethod void testCaseServices(){
        Test.startTest();
        Map<String, SObject> data= CaseLastUpdatedTestFactory.createCaseData();
        T_SBSD_CASE__c caseRec= (T_SBSD_CASE__c)data.get('caseRec');
        T_SBSD_INDIV__c indiv= (T_SBSD_INDIV__c)data.get('individual');
        T_SBSD_INDIV_EMPLMT__c  emp= new T_SBSD_INDIV_EMPLMT__c(idn_client__c=indiv.Id, ADR_CITY__c = 'test', DTE_BEGIN_EFFV__c = System.today().addDays(-5));
        insert emp;
        T_EMPLMT_INCOME__c empInc= new T_EMPLMT_INCOME__c(idn_emplmt_indiv__c= emp.Id, CDE_STATUS__c='ACT' , 
                                                          DTE_BEGIN_EFFV__c=System.today(), 
                                                          CNT_WEEK_PER_HOURS_ESTMD__c = 20.00, 
                                                          AMT_INCOME_ANNUAL_ESTMD__c = 10000.00, 
                                                          CDE_FREQ_PAY_ESTMD__c = 'MON',
                                                          CDE_TYPE_VERIF__c = 'SD');
        insert empInc;
        T_EMPLMT_PAY_STUB__c empPayStub= new T_EMPLMT_PAY_STUB__c(idn_emplmt_income__c=empInc.Id, CDE_STATUS__c='ACT');
        insert empPayStub;
        caseRec.DTE_RCVD_PACKET_REDET__c = System.today().addDays(-1);
        LightningServerResponse lsr=RedeterminationFlowCtrl.updateCase(new List<SObject>{caseRec});
        system.assertEquals(System.today().addDays(-1),[Select DTE_RCVD_PACKET_REDET__c from T_SBSD_CASE__c where Id=:caseRec.Id].DTE_RCVD_PACKET_REDET__c,'Packet recieved date should be yesterday');
        Test.stopTest();
    }
    
    public static testMethod void testRedeterminationFlowAgain(){
        test.startTest();
        T_SBSD_CASE__c caseRecord = new T_SBSD_CASE__c();
        insert caseRecord;
        T_SBSD_CASE_STATUS_MODE__c caseStatusModeChild = new T_SBSD_CASE_STATUS_MODE__c();
        caseStatusModeChild.IDN_CASE__c = caseRecord.Id; 
        caseStatusModeChild.DTE_BEGIN_EFFV__c = date.today()-2;
        insert caseStatusModeChild;
        LightningServerResponse lsr=RedeterminationFlowCtrl.updateCase(new List<SObject>{caseRecord});
        system.assertEquals(true,lsr.isSuccessful,'isSuccessful should be true');
        LightningServerResponse lsr2=RedeterminationFlowCtrl.updateCase(new List<SObject>{caseRecord});
        system.assertEquals(false,lsr2.isSuccessful,'isSuccessful should be false');
        test.stopTest();
    }
    
}