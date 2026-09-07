@isTest
public class subPaymentSearchTest {
    
    public static testMethod void doSearchSubPaymentTest(){
        // Initialize with mock data in case there are no data available. Based on Deloitte3.
        String paymentId = '5413';
        String providerId = '';
        String caseId = '';
        String countyId = '';
        String servicePeriodId;
        String stateId = 'G651582';
        String childFirstName = 'John';
        String childLastName = 'Doe';
        
        List<batchsit_t_sub_pmt__x> mockSubPaymentList = [select idn_pmt__c, idn_pmt__r.IDN_PROVR__c, idn_auth__r.IDN_CASE__c, 
                                                           idn_pmt__r.CDE_COUNTY__c, idn_period_serv__c, 
                                                           idn_auth__r.IDN_CLIENT__r.IDN_STATE__c, idn_auth__r.IDN_CLIENT__r.NAM_FIRST__c, 
                                                           idn_auth__r.IDN_CLIENT__r.NAM_LAST__c 
                                                           from batchsit_t_sub_pmt__x 
                                                           where idn_pmt__c != null AND 
                                                           idn_period_serv__c != null AND 
                                                           idn_auth__c != null
                                                           LIMIT 1];
        if(mockSubPaymentList.size() > 0){
            paymentId = mockSubPaymentList.get(0).idn_pmt__c;
            providerId = mockSubPaymentList.get(0).idn_pmt__r.IDN_PROVR__c;
            caseId = mockSubPaymentList.get(0).idn_auth__r.IDN_CASE__c;
            countyId = mockSubPaymentList.get(0).idn_pmt__r.CDE_COUNTY__c;
            servicePeriodId = mockSubPaymentList.get(0).idn_period_serv__c;
            stateId = mockSubPaymentList.get(0).idn_auth__r.IDN_CLIENT__r.IDN_STATE__c;
            childFirstName = mockSubPaymentList.get(0).idn_auth__r.IDN_CLIENT__r.NAM_FIRST__c;
            childLastName = mockSubPaymentList.get(0).idn_auth__r.IDN_CLIENT__r.NAM_LAST__c;
        }
        
        Test.startTest();
        LightningServerResponse lsr = subPaymentSearch.doSearchSubPayment(paymentId, providerId, caseId, countyId, servicePeriodId, 
                                                                          stateId, childFirstName, childLastName);
        system.assertEquals(null, lsr.objectData.get('SubpaymentSearchResults'));
        system.assertEquals(true, lsr.isSuccessful);
        Test.stopTest();
    }
    
    public static testMethod void subPaymentPicklistMapTest(){
        String recordId = '';
        List<batchsit_t_sub_pmt__x> subPaymentList = [select Id from batchsit_t_sub_pmt__x LIMIT 1];
        if(subPaymentList.size() >0){
            recordId = subPaymentList.get(0).Id;
        }
        
        Test.startTest();
        LightningServerResponse lsr = subPaymentSearch.subPaymentPicklistMap(recordId);
        system.assertNotEquals(null, lsr.objectData.get('subPaymentInfo'));
        system.assertEquals(true, lsr.isSuccessful);
        Test.stopTest();
    }
    
    public static testMethod void subPaymentDetailPicklistMapTest(){
        String recordId = '';
        List<batchsit_t_sub_pmt_detail__x> subPaymentDetailList = [select Id from batchsit_t_sub_pmt_detail__x LIMIT 1];
        if(subPaymentDetailList.size() >0){
            recordId = subPaymentDetailList.get(0).Id;
        }
        
        Test.startTest();
        LightningServerResponse lsr = subPaymentSearch.subPaymentDetailsPicklistMap(recordId);
        system.assertNotEquals(null, lsr.objectData.get('subPaymentDetailInfo'));
        system.assertEquals(true, lsr.isSuccessful);
        Test.stopTest();
    }
    
    public static testMethod void SubpaymentMockDatatest(){
        String paymentId = '5413';
        String providerId = '';
        String caseId = '';
        String countyId = '';
        String servicePeriodId = '63';
        String stateId = 'G651582';
        String childFirstName = 'John';
        String childLastName = 'Doe';
        
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(CDE_STATUS_PROVR__c = 'Open');
        insert provider;
        
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();    
        
        T_COUNTY__c county = TestClassUtility.createCounty('TestCounty', 'Test1', 12, true);
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        
        T_PROVR_FISCAL_AGREMENT__c providerFA1 =  TestClassUtility.createFiscaAgreement(false, 'test', System.today(), county.Id);
        providerFA1.ID_SERVICE__c = provider.Id;
        providerFA1.RecordtypeId = openRecordTypeId;
        providerFA1.CDE_TYPE_STATUS__c = 'OPN';
        insert providerFA1;
        
        T_PAYMT__c payId = new T_PAYMT__c(IDN_PROVR__c = provider.Id, CDE_COUNTY__c = county.Id, CDE_METHOD_PMT__c = 'EBT', AMT_PMT__c = 22);
        insert payId;
        
        T_SERV_PERIOD__c servicePeriod = new T_SERV_PERIOD__c(DTE_BEGIN_EFFV__c = system.today(), DTE_END_EFFV__c = system.today(), DTE_BATCH_FILE_PMT__c = system.today(), DTE_BATCH_PRCS_PMT__c = system.today());
        insert servicePeriod;
        
        Test.startTest();
        LightningServerResponse lsr = subPaymentSearch.doSearchSubPayment([select Name from T_PAYMT__c limit 1].Name, 
                                                                          [select Name, Id from T_CHATS_PROVR_STATUS__c limit 1].Id, 
                                                                          [select Name, Id from T_SBSD_CASE__c limit 1].Id, 
                                                                          [select Name, Id from T_COUNTY__c limit 1].Id, 
                                                                          [select Name, Id from T_SERV_PERIOD__c limit 1].Id, 
                                                                          stateId, childFirstName, childLastName);
        system.assertEquals(null, lsr.objectData.get('SubpaymentSearchResults'));
        system.assertEquals(true, lsr.isSuccessful);
        Test.stopTest();
    }
    
    public static testMethod void doSearchSubPaymentForAdjustmentEntryTest(){
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c = 'Level 1');
        insert provider;
        
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, false);
        insert countyRec;
        
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false, system.today().addYears(-15), 'firstName', '1', 'lastName', '123', 'CC');
        insert individual;
        
        TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id, true);
        T_ADJMT__c theAdjustment = new T_ADJMT__c(RecordtypeId = recordTypeId, CDE_STATUS_ADJMT__c = '2', CDE_TYPE_ADJMT__c = '2', CDE_TYPE_CLSFN__c = '3', CDE_AGNST_ADJMT__c = '1', IDN_PROVR__c = provider.Id, DTE_END_ADJMT__c = null, DTE_START_ADJMT__c = system.today(), DTE_DISCV_ADJMT_ORIG__c = System.today());
        insert theAdjustment;
        
        TestClassUtility.createServicePeriod(true, system.today(), system.today()+5, system.today(), system.today());
        
        Test.startTest();
        LightningServerResponse lsr = SubPaymentSearchApxCtrl.doSearchSubPaymentForAdjustmentEntry(null, null, 'first', string.valueof(system.today()), 'last', string.valueof(system.today()+5), theAdjustment, '', '', null, false);
        system.assertEquals(true, lsr.isSuccessful, 'isSuccessful should be true');
        LightningServerResponse lsr2 = SubPaymentSearchApxCtrl.doSearchSubPaymentForAdjustmentEntry(null, null, 'first', null, 'last', string.valueof(system.today()+5), theAdjustment, '', '', null, false);
        try {
            LightningServerResponse lsr3 = SubPaymentSearchApxCtrl.doSearchSubPaymentForAdjustmentEntry(null, null, null, string.valueof(system.today()), null, null, null, '', '', null, false);
        } catch(Exception ex) {}
        List<String> listStr = SubPaymentSearchApxCtrl.getSubPmtOrPrvdrExtIdsBasedOnAuth(null, caseRec.Id, null, null, null, null, null, false, '');
        SubPaymentSearchApxCtrl.querySubPaymentRecords(new List<string>{'1'}, '1', null, false);
        SubPaymentSearchApxCtrl.querySubPaymentRecords(new List<string>{'1'}, '1', 'test', true);
        SubPaymentSearchApxCtrl.querySubPaymentRecords(new List<string>{'1'}, '1', null, true);
        SubPaymentSearchApxCtrl.querySubPaymentRecords(new List<string>{'1'}, 'test', true);
        SubPaymentSearchApxCtrl.querySubPaymentRecords(new List<string>{'1'}, null, true);
        SubPaymentSearchApxCtrl.querySubPaymentRecords(new List<string>{'1'}, 'test', false);
        Test.stopTest();
    }
    public static testMethod void wrapperTest(){
        Test.startTest();
        SubPaymentSearchApxCtrl.requestParams req = new SubPaymentSearchApxCtrl.requestParams();
        req.isSearchByVacantSlotContractId = '';
        req.adjCountySFID ='';
        req.vacantSlotId = '';
        req.subPymtId = '';
        req.subPymtIds = new List<string>();
        SubPaymentSearchApxCtrl.subpaymentWrapper wrapper = new SubPaymentSearchApxCtrl.subpaymentWrapper();
        Test.stopTest();
    }
}