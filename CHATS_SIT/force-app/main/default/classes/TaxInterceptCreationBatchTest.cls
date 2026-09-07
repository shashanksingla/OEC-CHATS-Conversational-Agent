@isTest
private class TaxInterceptCreationBatchTest {
    @isTest
    static void TaxInterceptCreationTest(){
        T_COUNTY__c countyRec = new T_COUNTY__c(CNTY_DEPT_NAME__c = 'Arapahoe County', CDE_COUNTY__c = 3);
        insert countyRec;
        T_CHATS_PROVR_STATUS__c prov = TestClassUtility.createProvider(false, 'Level 1');
        prov.NBR_SSN__c = '12345678';
        insert prov;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_CASE_STATUS_MODE__c csStatusMode = new T_SBSD_CASE_STATUS_MODE__c(IDN_CASE__c = caseRec.Id, CDE_STATUS_CASE__c='OPN', DTE_BEGIN_EFFV__c = Date.valueOf(Date.newInstance(2017, 10, 07)));
        insert csStatusMode;

        List<T_ADJMT__c> adjToBeInserted = new List<T_ADJMT__c>();
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        T_ADJMT__c provAdj = TestClassUtility.createAdjustment(false, countyRec.Id, caseRec.Id, null);
        provAdj.IDN_PROVR__c = prov.Id;
        provAdj.CDE_TYPE_ADJMT__c = '2';
        provAdj.CDE_STATUS_ADJMT__c = '2';
        provAdj.RecordtypeId=recordTypeId;
        provAdj.DTE_DISCV_ADJMT_ORIG__c = Date.valueOf(Date.newInstance(2018, 01, 07));
        adjToBeInserted.add(provAdj);
        T_ADJMT__c caseAdj = TestClassUtility.createAdjustment(false, countyRec.Id, caseRec.Id, null);
        caseAdj.IDN_PROVR__c = prov.Id;
        caseAdj.CDE_TYPE_ADJMT__c = '2';
        caseAdj.CDE_STATUS_ADJMT__c = '2';
        caseAdj.RecordtypeId=recordTypeId;
        caseAdj.DTE_DISCV_ADJMT_ORIG__c = Date.valueOf(Date.newInstance(2018, 01, 07));
        adjToBeInserted.add(caseAdj);
        insert adjToBeInserted;
        Test.setCreatedDate(caseAdj.Id, Date.valueOf(Date.newInstance(2018, 02, 01)));
        Test.setCreatedDate(provAdj.Id, Date.valueOf(Date.newInstance(2018, 02, 01)));

        List<T_NON_ADJMT_DETAIL__c> nonAdjDetList = new List<T_NON_ADJMT_DETAIL__c>();
        T_NON_ADJMT_DETAIL__c nonAdjDtl = new T_NON_ADJMT_DETAIL__c(IDN_ADJMT__c = caseAdj.Id, AMT_DETAIL_ADJMT__c = 50);
        nonAdjDetList.add(nonAdjDtl);
        T_NON_ADJMT_DETAIL__c nonAdjDtl2 = new T_NON_ADJMT_DETAIL__c(IDN_ADJMT__c = provAdj.Id, AMT_DETAIL_ADJMT__c = 30);
        nonAdjDetList.add(nonAdjDtl2);
        insert nonAdjDetList;

        T_ADJMT_DETAIL__c adjDtl = TestClassUtility.createAdjustmentDetail(true, caseAdj.Id);        
        T_ADJMT_PMT__c adjPmt = TestClassUtility.createAdjustmentPayment(true, caseRec.Id, null);
        T_ADJMT_DETAIL__c adjDtl2 = TestClassUtility.createAdjustmentDetail(true, provAdj.Id);        
        T_ADJMT_PMT__c adjPmt2 = TestClassUtility.createAdjustmentPayment(true, null, prov.Id);

        List<T_ADJMT_PMT_DETAIL__c> adjPmtDtlList = new List<T_ADJMT_PMT_DETAIL__c>();
        T_ADJMT_PMT_DETAIL__c adjPmtDtl = TestClassUtility.createAdjustmentPaymentDetail(false, adjDtl.Id, caseAdj.Id, adjPmt.Id);
        adjPmtDtl.CDE_STATUS_DETAIL_PMT_ADJMT__c = '4';
        adjPmtDtl.AMT_PMT_DETAIL_ADJMT__c = 20;
        adjPmtDtlList.add(adjPmtDtl);    
        T_ADJMT_PMT_DETAIL__c adjPmtDtl2 = TestClassUtility.createAdjustmentPaymentDetail(false, adjDtl2.Id, provAdj.Id, adjPmt2.Id);
        adjPmtDtl2.CDE_STATUS_DETAIL_PMT_ADJMT__c = '3';
        adjPmtDtl2.AMT_PMT_DETAIL_ADJMT__c = 20;
        adjPmtDtlList.add(adjPmtDtl2);
        insert adjPmtDtlList;
        Test.setCreatedDate(adjPmtDtl2.Id, Date.valueOf(Date.newInstance(2018, 01, 01)));
		Test.startTest();
        T_SBSD_INDIV__c indiv = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC');
        T_ADJMT_RESPBL_PARTY__c adjRespParty = TestClassUtility.createAdjustmentRespPart(false, caseRec.Id, prov.id, indiv.Id, caseAdj.Id);
        T_ADJMT_RESPBL_PARTY__c adjRespParty2 = TestClassUtility.createAdjustmentRespPart(false, caseRec.Id, prov.id, indiv.Id, provAdj.Id);
        Insert New List<T_ADJMT_RESPBL_PARTY__c>{adjRespParty,adjRespParty2};
        
        TaxInterceptCreationBatch batch = new TaxInterceptCreationBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        List<Tax_Intercept__c> taxinterceptList = [SELECT Id FROM Tax_Intercept__c WHERE Adjustment__c=:provAdj.Id LIMIT 1];
        System.assertEquals(1, taxinterceptList.size(), 'Size should be 1');
    }
}