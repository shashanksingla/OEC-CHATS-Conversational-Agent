@isTest
public class IPVDisQualifycationApxTrigger_Test {
    static testMethod void triggerCR110Scenario() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        IPV_Information__c ipvRecord = new IPV_Information__c();
        ipvRecord.Individual_ID__c=sbsdIndiv.id;
        ipvRecord.Number_of_occurrences__c='1';
        ipvRecord.Disqualification_Begin_Date__c = system.today().addDays(-15);
        ipvRecord.Disqualification_End_Date__c = system.today();
        ipvRecord.Disqualification_determination_Date__c = system.today().addDays(-1);
        ipvRecord.County__c = county.id;
        ipvRecord.disqualification_created__c = true;
        
        
        Test.startTest();
        insert ipvRecord;
        ipvRecord.Number_of_occurrences__c ='2';
        update ipvRecord;
        Test.stopTest();
    }
    static testMethod void triggerCR110Scenario2() {
        
        
        
        Test.startTest();
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, county.Id);
        T_SBSD_CASE__c caseRec2 = TestClassUtility.createCase(true, county.Id);
        caseRec.Is_Peak_Data__c = true;
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        T_SBSD_CASE_INDIV__c caseIndiv2 = new T_SBSD_CASE_INDIV__c();
        caseIndiv2.IDN_CASE__c = caseRec2.Id;
        caseIndiv2.IDN_CLIENT__c = individual.Id;
        caseIndiv2.IND_CRTKR__c = true;
        caseIndiv2.DTE_BEGIN_EFFV__c = system.today().addDays(-1);
        insert caseIndiv2;
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(true, caseRec.Id);
        T_SBSD_CASE_STATUS_MODE__c caseStaMod2 = TestClassUtility.createCaseStatusMode(true, caseRec2.Id);
        IPV_Information__c ipvRecord = new IPV_Information__c();
        ipvRecord.Individual_ID__c=individual.id;
        ipvRecord.Number_of_occurrences__c='1';
        ipvRecord.Disqualification_Begin_Date__c = system.today().addDays(-15);
        ipvRecord.Disqualification_End_Date__c = system.today();
        ipvRecord.Disqualification_determination_Date__c = system.today().addDays(-1);
        ipvRecord.County__c = county.id;
        ipvRecord.disqualification_created__c = true;
        insert ipvRecord;
        T_DOC_RQ__c req = new T_DOC_RQ__c();
        req.IPV_Information__c =ipvRecord.id;
        req.CDE_COUNTY__c=county.id;
        req.IDN_CLIENT__c=individual.id;
        req.DTE_REQ__c = system.today();
        req.CDE_CORSPD_STATUS__c = 'Requested';
        req.NME_CORSPD__c='CR110';
        req.CDE_TYPE_RCPT__c ='P';        
        insert req;
        ipvRecord.Number_of_occurrences__c ='2';
        ipvRecord.Disqualification_Begin_Date__c = system.today().addDays(-14);
        ipvRecord.Disqualification_determination_Date__c = system.today().addDays(-2);
        ipvRecord.Disqualification_End_Date__c = system.today().addDays(1);
        update ipvRecord;
        Test.stopTest();
    }
}