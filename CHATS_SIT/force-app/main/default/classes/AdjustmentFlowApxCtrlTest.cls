/*
*Change Log :
* Updating field name nonAdjustmentDetail to nonAdjmtDtl
* Updating field name selectedSubPayment to selSubPmt
* Updating field name subPaymentDetailObj to subPmtDtlObj
*
*/

@isTest
public class AdjustmentFlowApxCtrlTest {
    public static final String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
    public static testMethod void testDoGetInitDataWithCase(){
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        insert countyRec;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_CASE_ADR__c caseAddr = new T_SBSD_CASE_ADR__c();
        caseAddr.ADR_CITY__c = 'Denver';
        caseAddr.ADR_LINE_1__c = '102 street- test';
        caseAddr.ADR_STATE__c = 'CO';
        caseAddr.ADR_ZIP_MAIN__c = '80111';
        caseAddr.CDE_TYPE_ADR__c = 'MAL';
        caseAddr.IDN_CASE__c = caseRec.Id;
        caseAddr.DTE_BEGIN_EFFV__c = Date.today()-1;
        insert caseAddr;
        
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-20),'firstName','1','lastName','123','CC');
        insert individual;
        TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        //TestClassUtility.createCaseIndividual(true, TestClassUtility.createCase(true, countyRec.Id).Id, individual.Id,true);
        T_ADJMT__c theAdjustment = new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='3',CDE_AGNST_ADJMT__c='1',IDN_CASE__c=caseRec.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8));
        insert theAdjustment;
        Test.startTest();
        LightningServerResponse lsr=AdjustmentFlowApxCtrl.doGetInitData(theAdjustment.Id);
        system.assertEquals(true,lsr.isSuccessful,'isSuccessful should be true');
        Test.stopTest();
    }
    
    static testMethod void isAuthValidTest() {
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        String begDate = String.valueOf(begindate);
        Date enddate = begindate.addDays(20);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        T_AUTH__c authorization=TestClassUtility.createAuthorization(true,enddate,begindate,county.Id,provider.Id);
        Test.startTest();
        LightningServerResponse lsr=AdjustmentFlowApxCtrl.getAuthObj(authorization.Id);
        system.assertEquals(true,lsr.isSuccessful,'isSuccessful should be true');
        Test.stopTest();
    }
    
    public static testMethod void testDoGetInitData(){
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        insert countyRec;
        T_SBSD_CASE__c caseRec =TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        insert individual;
        TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        T_ADJMT__c theAdjustment = new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='3',CDE_AGNST_ADJMT__c='1',IDN_PROVR__c=provider.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8));
        theAdjustment.CDE_COUNTY__c = countyRec.Id;
        insert theAdjustment;
        T_ADJMT_ADDR__c adjusAddress = new T_ADJMT_ADDR__c(ADR_LINE_1__c='XXX',ADR_LINE_2__c='YYY',ADR_CITY__c='Test city',ADR_STATE__c='CO',ADR_ZIP_MAIN__c='12345',ADR_ZIP_EXTN__c='3852',IDN_ADJMT__c=theAdjustment.Id);    
        insert adjusAddress;
        T_ADJMT_RESPBL_PARTY__c adjusRespblParty = new T_ADJMT_RESPBL_PARTY__c(IDN_CLIENT__c=individual.Id);
        insert adjusRespblParty;
        T_AUTH__c authorization= new T_AUTH__c(DTE_END_EFFV_AUTH__c=System.Today()+2,DTE_BEGIN_EFFV_AUTH__c=System.Today(),CDE_COUNTY__c=countyRec.Id,IDN_PROVR__c=provider.Id);
        insert authorization;
        T_NON_ADJMT_DETAIL__c nonAdjmtDtl = new T_NON_ADJMT_DETAIL__c(IDN_AUTH__c=authorization.Id,AMT_DETAIL_ADJMT__c=100,IDN_PROG_FNDG__c='1',IDN_ADJMT__c=theAdjustment.Id);
        insert nonAdjmtDtl;
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgrmt = new T_PROVR_FISCAL_AGREMENT__c(ID_SERVICE__c=provider.Id,CDE_COUNTY__C=countyRec.id,RecordTypeId=openRecordTypeId,CDE_TYPE_STATUS__c='OPN',DTE_RCV_AGRMT_FISCAL__c = system.today());
        insert fiscalAgrmt;
        T_FISCAL_SCH__c fiscalSch= new T_FISCAL_SCH__c(IDN_AGRMT_FISCAL__c=fiscalAgrmt.Id,CDE_RATE_TYPE__c='1;31');
        insert fiscalSch;
       /* List<T_FISCAL_RATE__c> listFiscalRate= new List<T_FISCAL_RATE__c>();
        T_FISCAL_RATE__c fiscalrate = new T_FISCAL_RATE__c(IDN_FISCAL_SCH__c=fiscalSch.Id,CDE_RATE_TYPE__C='1',CDE_AGE_GROUP__c='1');
        T_FISCAL_RATE__c fiscalrate1 = new T_FISCAL_RATE__c(IDN_FISCAL_SCH__c=fiscalSch.Id,CDE_RATE_TYPE__C='1',CDE_AGE_GROUP__c='2');
        listFiscalRate.add(fiscalrate);
        listFiscalRate.add(fiscalrate1);
        insert listFiscalRate; */
        SubPaymentSearchApxCtrl.subpaymentWrapper subPay = new SubPaymentSearchApxCtrl.subpaymentWrapper();
        subPay.authid = authorization.Id;
        Decimal subPaymentId =12341;
        String subPaymentIds ='12341';
        String PaymentId ='12341';
        
        String datetoday=string.valueOf(System.Today());//format('yyyy-MM-dd HH:mm:ss');
        List<String> dateParts = datetoday.split('-');
        Date beginDate1 = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
        String datetoday1=string.valueOf(beginDate1);
        datetoday1 = datetoday1.replace('-','.');
        //Date myDate = Date.newInstance(1960, 2, 17);
        // Date begindate = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        // Date enddate = begindate.addDays(20);
        SubPaymentSearchApxCtrl.subpaymentWrapper selSubPmt = new SubPaymentSearchApxCtrl.subpaymentWrapper();
        List<batchsit_t_sub_pmt_detail__x> subPaymentDetails = new List<batchsit_t_sub_pmt_detail__x>() ;
        List<T_ADJMT_DETAIL__c> adjustmentDetail = new List<T_ADJMT_DETAIL__c>();
        
        String adjustmentWrap ;
        batchsit_t_sub_pmt_detail__x subPmtDtlObj = new batchsit_t_sub_pmt_detail__x(idn_pmt_sub__c = '10101');
        T_ADJMT_DETAIL__c adjustmentDetailObj = new T_ADJMT_DETAIL__c(IDN_ADJMT__C=theAdjustment.Id,IDN_DETAIL_PMT_SUB__c='1',NBR_HOURS_ATTND_ADJD__c=3,CDE_TYPE_RATE_ADJD__c='1');
        T_ADJMT_DETAIL__c adjustmentDetailObj1 = new T_ADJMT_DETAIL__c(IDN_ADJMT__C=theAdjustment.Id,IDN_DETAIL_PMT_SUB__c='1',NBR_HOURS_ATTND_ADJD__c=2,CDE_TYPE_RATE_ADJD__c='31');        
        
        adjustmentDetail.add(adjustmentDetailObj);
        adjustmentDetail.add(adjustmentDetailObj1);
        insert adjustmentDetail;
        adjustmentWrapper wrapper = new adjustmentWrapper(subPmtDtlObj,adjustmentDetailObj,'Test');
        List<adjustmentWrapper> listWrapper = new List<adjustmentWrapper>();
        listWrapper.add(wrapper);
        adjustmentWrap = JSON.serialize(listWrapper);
        Test.startTest();
        
        LightningServerResponse lsr = AdjustmentFlowApxCtrl.doGetInitData(theAdjustment.Id);
        AdjustmentFlowApxCtrl.adjustmentDetails(theAdjustment.Id);
        AdjustmentFlowApxCtrl.getAdjustmentDetails(theAdjustment.Id);
        AdjustmentFlowApxCtrl.getCurrentUtilizationRecord(theAdjustment.Id);
        AdjustmentFlowApxCtrl.doDeleteRecords(theAdjustment.Id,true);
        AdjustmentFlowApxCtrl.doDeleteRecords(theAdjustment.Id,false);
        AdjustmentFlowApxCtrl.doDeleteAdjustRecords(theAdjustment.Id);
        AdjustmentFlowApxCtrl.doSearchSubPaymentDetails(subPaymentId,JSON.serialize(subPay),theAdjustment);
        AdjustmentFlowApxCtrl.searchRelatedAuthRecord('Test1','Test',theAdjustment,caseRec.Id);
        AdjustmentFlowApxCtrl.doSearchSubPayment(PaymentId,subPaymentIds,'Test1','','Test','',theAdjustment,'','','',false);
        AdjustmentFlowApxCtrl.calculateAdjustDetail(JSON.serialize(selSubPmt),theAdjustment,subPaymentDetails,adjustmentDetail,adjustmentWrap);
        AdjustmentFlowApxCtrl.getRateTypeMap(subPmtDtlObj,adjustmentDetailObj);
        AdjustmentFlowApxCtrl.subPaymentCallOut(adjustmentDetail);
        AdjustmentFlowApxCtrl.querySubpaymentDetail('123',theAdjustment);
        AdjustmentFlowApxCtrl.doVerifyAdjustmentNote(theAdjustment.Id);
        system.assertEquals(true, lsr.isSuccessful,'isSuccessful should be true');
        system.assert(lsr.objectData.containsKey('adjustment'),'Adjustment object should be returned');
        Test.stopTest();
    }
    
   /* public static testMethod void testupsertResponsibleParties(){
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        insert countyRec;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id); 
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstNameA','1','lastNameA','123','CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstNameB','1','lastNameB','123','CC');
        List<T_SBSD_INDIV__c> indivList = new List<T_SBSD_INDIV__c>();
        indivList.add(individual);
        indivList.add(individual2);
        insert indivList;
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        T_ADJMT__c theAdjustment = new T_ADJMT__c(RecordTypeId=recordTypeId, CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='3',CDE_AGNST_ADJMT__c='1',IDN_PROVR__c=provider.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8));
        insert theAdjustment;
        
        Test.startTest(); 
       // LightningServerResponse lsr = AdjustmentFlowApxCtrl.upsertResponsibleParties(new List<id>{individual.id,individual2.id}, theAdjustment.Id);
        //test
       // LightningServerResponse lsr2 = AdjustmentFlowApxCtrl.upsertResponsibleParties(new List<id>{individual.id}, theAdjustment.Id);
       // system.assertEquals(true, lsr.isSuccessful,'isSuccessful should be true');
       // system.assertEquals(true, lsr2.isSuccessful,'isSuccessful should be true');
        Test.stopTest();
    }*/
    
    public static testMethod void testGetIndivInfoFromAuth(){
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        provider.CDE_TYPE_PROVR__c = 'FCCH';
        insert provider;
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        insert countyRec;
        T_AUTH__c authorization= new T_AUTH__c(DTE_END_EFFV_AUTH__c=System.Today()+2,DTE_BEGIN_EFFV_AUTH__c=System.Today(),CDE_COUNTY__c=countyRec.Id,IDN_PROVR__c=provider.Id);
        insert authorization;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
		T_ADJMT__c adjRec = new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='3',CDE_AGNST_ADJMT__c='1',IDN_CASE__c=caseRec.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8));
        insert adjRec;
        Test.startTest();
        LightningServerResponse lsr = AdjustmentFlowApxCtrl.getIndivInfoFromAuth(authorization.Id, adjRec.DTE_START_ADJMT__c, adjRec.DTE_END_ADJMT__c);
        system.assertEquals(true, lsr.isSuccessful);
        system.assert(lsr.objectData.containsKey('authorization'));
        Test.stopTest();
    }
    
    public static testMethod void testgetRecordTypeId(){
        Test.startTest();
        LightningServerResponse lsr = AdjustmentFlowApxCtrl.getRecordTypeId('In Process','T_ADJMT__c', null, 0);
        system.assertEquals(true, lsr.isSuccessful,'isSuccessful should be true');
        system.assertEquals(true,lsr.objectData.containsKey('recordtypeId'));
        Test.stopTest();
    }
    
    public static testMethod void testGetIndividualFromId(){
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        batchsit_t_sub_pmt_detail__x subPaymentDetails;
        T_ADJMT_DETAIL__c ajustmentDetails;
        String childName ;
        Test.startTest();
        List<T_SBSD_INDIV__c> individuals = AdjustmentFlowApxCtrl.getIndividualFromId(individual.Id);
        //Removed unused variable on 5/13/2018 BG         
        system.assertEquals(false,individuals.isEmpty(),'individuals should not be empty');
        Test.stopTest();
    }
    
    public static testMethod void testgetFundingProgram(){
        Test.startTest();
        Map<String, String> fundingProgram;
         fundingProgram=AdjustmentFlowApxCtrl.getFundingProgram('Test','LI');
        system.assertEquals(2, fundingProgram.size());
           fundingProgram=AdjustmentFlowApxCtrl.getFundingProgram('Test','TF');
        system.assertEquals(2, fundingProgram.size());
           fundingProgram=AdjustmentFlowApxCtrl.getFundingProgram('Test','FT');
        system.assertEquals(2, fundingProgram.size());
           fundingProgram=AdjustmentFlowApxCtrl.getFundingProgram('Test','CW');
        system.assertEquals(2, fundingProgram.size());
           fundingProgram=AdjustmentFlowApxCtrl.getFundingProgram('Y','CW');
        system.assertEquals(2, fundingProgram.size());
        Test.stopTest();
    }
     public static testMethod void testgetSelectedIPVRecord(){
         IPV_Information__c newIpv=new IPV_Information__c(Number_of_occurrences__c ='2');
         insert newIpv;
        LightningServerResponse response;
        
        Test.startTest();     
     
            response = AdjustmentFlowApxCtrl.getSelectedIPVRecord(newIpv.id);
            System.assertEquals(response.isSuccessful,true);
       
        Test.stopTest();
    }
    public static testMethod void testupsertResponsiblePartiesAddress(){
        T_COUNTY__c county=TestClassUtility.createCounty('Denver', 'test', 1, true);
        T_CHATS_PROVR_STATUS__c prvder=TestClassUtility.createProvider(true, 'Level 2');
        T_SBSD_CASE__c crCase=TestClassUtility.createCase(true,county.id);
        T_ADJMT__c crAd=TestClassUtility.createAdjustment(true,county.id,crCase.id,prvder.id);
        List<T_ADJMT_ADDR__c> adL=new List<T_ADJMT_ADDR__c>();
        T_ADJMT_ADDR__c crAdrs1=TestClassUtility.createAdjustmentAddress(true, crAd.id);
        T_ADJMT_ADDR__c crAdrs2=TestClassUtility.createAdjustmentAddress(true, crAd.id);
        T_ADJMT_ADDR__c crAdrs3=TestClassUtility.createAdjustmentAddress(true, crAd.id);
        adL.add(crAdrs1);
        adL.add(crAdrs2);
        adL.add(crAdrs3);
        LightningServerResponse response;
        
        Test.startTest();     
     
            response = AdjustmentFlowApxCtrl.upsertResponsiblePartiesAddress(crAd.id,adL);
            System.assertEquals(response.isSuccessful,true);
       
        Test.stopTest();
    }
    public static testMethod void testupsertResponsibleParties(){
        T_COUNTY__c county=TestClassUtility.createCounty('Denver', 'test', 1, true);
        T_CHATS_PROVR_STATUS__c prvder=TestClassUtility.createProvider(true, 'Level 2');
        T_SBSD_CASE__c crCase=TestClassUtility.createCase(true,county.id);
        T_ADJMT__c crAd=TestClassUtility.createAdjustment(true,county.id,crCase.id,prvder.id);
        T_SBSD_INDIV__c crInd=TestClassUtility.createIndividual(true,system.today().addYears(-20),'firstname','1', 'lastname','636005466','CC');
        List<T_ADJMT_RESPBL_PARTY__c> adL=new List<T_ADJMT_RESPBL_PARTY__c>();
        T_ADJMT_RESPBL_PARTY__c crAdrs1=TestClassUtility.createAdjustmentRespPart(true,crCase.id,prvder.id,crInd.id, crAd.id);
        T_ADJMT_RESPBL_PARTY__c crAdrs2=TestClassUtility.createAdjustmentRespPart(true,crCase.id,prvder.id,crInd.id, crAd.id);
        T_ADJMT_RESPBL_PARTY__c crAdrs3=TestClassUtility.createAdjustmentRespPart(true,crCase.id,prvder.id,crInd.id, crAd.id);
        adL.add(crAdrs1);
        adL.add(crAdrs2);
        adL.add(crAdrs3);
        LightningServerResponse response;
        
        Test.startTest();     
     
            response = AdjustmentFlowApxCtrl.upsertResponsibleParties(crAd.id,adL);
            System.assertEquals(response.isSuccessful,true);
       
        Test.stopTest();
    }
	public static testMethod void testgetPicklistOptions()
    {
        LightningServerResponse response;
        
        Test.startTest();     
     
            response = AdjustmentFlowApxCtrl.getPicklistOptions();
            System.assertEquals(response.isSuccessful,true);
       
        Test.stopTest();
    }
}