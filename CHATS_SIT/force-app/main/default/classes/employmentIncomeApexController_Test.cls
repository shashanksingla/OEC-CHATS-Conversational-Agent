/*************************************************************
Class Name	    - employmentIncomeApexController_Test
Covering Class	- employmentIncomeApexController
Author          - Rishav Maji
**************************************************************/
@isTest
public with sharing class employmentIncomeApexController_Test {
    
    public static testMethod void testMethod1(){
        T_COUNTY__c county = TestClassUtility.createCounty('countyName', 'countyDepartmentName', 01, true);
        T_SBSD_CASE__c caserec = TestClassUtility.createCase(true,county.Id);
        T_SBSD_INDIV__c indivrec = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        TestClassUtility.createCaseIndividual(true, caserec.Id, indivrec.Id, true);
        RecordType recType = [SELECT Id from RecordType where DeveloperName = 'Self_Employment' AND SobjectType = 'T_SBSD_INDIV_EMPLMT__c' LIMIT 1];
        T_SBSD_INDIV_EMPLMT__c emprec = new T_SBSD_INDIV_EMPLMT__c();
        emprec.ADR_CITY__c='Puri';
        emprec.DTE_BEGIN_EFFV__c=date.newInstance(1983, 7, 15);
        emprec.IDN_CLIENT__c=indivrec.Id;
        emprec.IDN_CASE__c=caserec.Id;
        emprec.NAM_BUSNS__c='Testing';
        emprec.IND_STUBS_PAY_RCVS__c='Y';
        emprec.RecordTypeId = recType.Id;
        Insert emprec;
        T_EMPLMT_INCOME__c inc = new T_EMPLMT_INCOME__c();
        inc.IDN_EMPLMT_INDIV__c = emprec.Id;
        inc.AMT_INCOME_ANNUAL_ESTMD__c = 1000;
        inc.CDE_STATUS__c = 'ACT';
        inc.CDE_FREQ_PAY_ESTMD__c = '1PY';
        inc.DTE_BEGIN_EFFV__c = Date.today();
        inc.CNT_WEEK_PER_HOURS_ESTMD__c = 40;
        inc.CDE_TYPE_VERIF__c = 'V';
        inc.CDE_SOURCE_VRFYD_PAY__c = 'OTH';
        Insert inc;
        Test.startTest();
        LightningServerResponse initData1 = employmentIncomeApexController.getInitData(inc.Id);
        LightningServerResponse initData2 = employmentIncomeApexController.getInitData(emprec.Id);
        inc.AMT_INCOME_ANNUAL_ESTMD__c = 2000;
        inc.CNT_WEEK_PER_HOURS_ESTMD__c = 45;
        LightningServerResponse saveResult = employmentIncomeApexController.saveEmploymentIncome(inc);
        Test.stopTest();
        System.assertEquals(true, initData1.isSuccessful);
        System.assertEquals(true, initData2.isSuccessful);
        System.assertEquals(true, saveResult.isSuccessful);
    }
    
    public static testMethod void exceptionTestMethod1(){
        Test.startTest();
        LightningServerResponse initData1 = employmentIncomeApexController.getInitData('ABC');
        Test.stopTest();
    }
}