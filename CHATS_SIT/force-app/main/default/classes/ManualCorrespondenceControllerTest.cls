@isTest
public class ManualCorrespondenceControllerTest {

    public static testmethod void testProcessManualCorspd(){
        
        T_COUNTY__c countyObj=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c caseObj = new T_SBSD_CASE__c(CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N', CDE_ASST_HSNG__c = 'N', Name = '123543', IND_ELG_PRE_PROVR__c  = false);//TestClassUtility.createCase(true, countyObj.Id);
        insert caseObj;
        T_DOC_RSN__c ob1 = new T_DOC_RSN__c();
        ob1.Name ='CR0004';
        ob1.CND_TRIGR__c ='Manual';
        ob1.Is_Manual__c =true;
        ob1.CDE_TYPE_RCPT__c ='C';
        ob1.NME_CORSPD__c ='CR107';
        INSERT ob1;
        
        T_DOC_RSN__c ob2 = new T_DOC_RSN__c();
        ob2.Name ='CR0013';
        ob2.CND_TRIGR__c ='Manual';
        ob2.Is_Manual__c =true;
        ob2.CDE_TYPE_RCPT__c ='P';
        ob2.NME_CORSPD__c ='CR702';
        INSERT ob2;
        
        T_DOC_RSN__c ob3 = new T_DOC_RSN__c();
        ob3.Name ='CR0010';
        ob3.CND_TRIGR__c ='Manual';
        ob3.Is_Manual__c =true;
        ob3.CDE_TYPE_RCPT__c ='P;C';
        ob3.NME_CORSPD__c ='CR213';
        INSERT ob3;
        T_DOC_RSN__c corspdRsnClient = new T_DOC_RSN__c(NME_CORSPD__c = 'CR107', CDE_TYPE_RCPT__c = 'C', Is_Manual__c = true);
        insert corspdRsnClient;
        T_DOC_RSN__c corspdRsnPrv = new T_DOC_RSN__c(NME_CORSPD__c = 'CR702', CDE_TYPE_RCPT__c = 'P', Is_Manual__c = true);
        insert corspdRsnPrv;
        T_DOC_RSN__c corspdRsnBoth = new T_DOC_RSN__c(NME_CORSPD__c = 'CR213', CDE_TYPE_RCPT__c = 'P;C', Is_Manual__c = true);
        insert corspdRsnBoth;
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c (Name = '12345', NAM_FACILITY__c = 'Provider Test');
        insert providerObj;
        T_PROVR_FISCAL_AGREMENT__c fiscAgreement = new T_PROVR_FISCAL_AGREMENT__c ( DTE_BEGIN_AGRMT__c=date.today(), CDE_TYPE_STATUS__c = 'DFT', ID_SERVICE__c = providerObj.Id, CDE_COUNTY__c = countyObj.Id );
        insert fiscAgreement;
		
        LightningServerResponse processManualCorspd_rslt1 = ManualCorrespondenceController.processManualCorspd(corspdRsnClient.NME_CORSPD__c ,caseObj.Name, null, countyObj.Id, null, 'cr107Other', null, null, string.valueOf(system.today()),NULL,NULL,NULL,string.valueOf(system.today()),string.valueOf(system.today()),string.valueOf(system.today()),'99','1234567890'); 
        System.assertEquals(true,processManualCorspd_rslt1.isSuccessful,'processManualCorspd_rslt1.isSuccessful should be true');
        LightningServerResponse processManualCorspd_rslt2 = ManualCorrespondenceController.processManualCorspd(corspdRsnPrv.NME_CORSPD__c ,null, integer.valueOf(providerObj.Name), countyObj.Id, null, null, null, 'cr702Other', string.valueOf(system.today()),NULL,NULL,NULL,string.valueOf(system.today()),string.valueOf(system.today()),string.valueOf(system.today()),'99','1234567890'); 
        System.assertEquals(true,processManualCorspd_rslt2.isSuccessful,'processManualCorspd_rslt2.isSuccessful should be true');
        LightningServerResponse processManualCorspd_rslt3 = ManualCorrespondenceController.processManualCorspd(corspdRsnBoth.NME_CORSPD__c ,null, integer.valueOf(providerObj.Name), countyObj.Id, null, null, null, 'cr213Other', string.valueOf(system.today()),NULL,NULL,NULL,string.valueOf(system.today()),string.valueOf(system.today()),string.valueOf(system.today()),'99','1234567890'); 
        System.assertEquals(true,processManualCorspd_rslt3.isSuccessful,'processManualCorspd_rslt3.isSuccessful should be true');
        string perfromdisable_rslt = ManualCorrespondenceController.performdisable(corspdRsnClient.NME_CORSPD__c);
        system.assertEquals('C', perfromdisable_rslt);
        string validateInput_rslt = ManualCorrespondenceController.validateInput(corspdRsnClient.NME_CORSPD__c, null, null);
        system.assertEquals('C', validateInput_rslt);
        string validateCase_rslt = ManualCorrespondenceController.validateCase(caseObj.Name);
        string validateProvider_rslt = ManualCorrespondenceController.validateProvider(integer.valueOf(providerObj.Name));
        string validateProvider_rslt_invalid = ManualCorrespondenceController.validateProvider(99887);
        system.assertEquals('ValidProvider', validateProvider_rslt);
        string validateAdjustment_rslt_invalid = ManualCorrespondenceController.validateAdjustment(99887);
        system.assertEquals('InvalidAdjustment', validateAdjustment_rslt_invalid);
        string validateAdjtmtCaseProv_rslt_invalid = ManualCorrespondenceController.validateAdjtmtCaseProv(99887,null,integer.valueOf(providerObj.Name));
        system.assertEquals('InvalidvalidProvAndCase', validateAdjtmtCaseProv_rslt_invalid);
        string validateAdjtmtCaseProv_rslt_invalid1 = ManualCorrespondenceController.validateAdjtmtCaseProv(99887,99887,null);
        system.assertEquals('InvalidvalidProvAndCase', validateAdjtmtCaseProv_rslt_invalid1);
        string validateAdjtmtCaseProv_rslt_invalid2 = ManualCorrespondenceController.validateAdjtmtCaseProv(99887,null,null);
        system.assertEquals('InvalidvalidProvAndCase', validateAdjtmtCaseProv_rslt_invalid2);
        string validateChild_rslt_invalid = ManualCorrespondenceController.validateChild('99887');
        system.assertEquals('InvalidChild', validateChild_rslt_invalid);
        Boolean caseClientAssociationInvalid = ManualCorrespondenceController.validateCaseClientAssociation(caseObj.Name, '99887');
        System.assertEquals(true, caseClientAssociationInvalid);
    }
    
    @isTest
    static void testGetManualCorspdDetails() {
        T_COUNTY__c countyObj=TestClassUtility.createCounty('County2','Dept2',10,true);
        T_SBSD_CASE__c caseObj = new T_SBSD_CASE__c(CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N', CDE_ASST_HSNG__c = 'N', Name = '123543', IND_ELG_PRE_PROVR__c  = false);//TestClassUtility.createCase(true, countyObj.Id);
        insert caseObj;
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c (Name = '1234567', NAM_FACILITY__c = 'Provider Name');
        insert providerObj;
        
        T_DOC_RQ__C corspdReqClient107 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107', IDN_CASE__c = caseObj.Id, RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', cde_lang_doc__c = 'SPN', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqClient107;
        T_DOC_RQ__C corspdReqProvr702 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR702', IDN_PROVR__c = providerObj.Id, RSN_CODE__c = 'CR0013', CDE_TYPE_RCPT__c = 'P', cde_lang_doc__c = 'ENG', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqProvr702;
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ManualCorrespondenceMockTest());
        object getManualCorspdDetails_rslt = ManualCOrrespondenceController.getManualCorspdDetails(corspdReqClient107.Id,null,caseObj.Id);
        object getManualCorspdDetails_rslt1 = ManualCOrrespondenceController.getManualCorspdDetails(corspdReqProvr702.Id,providerObj.Id,null);
        test.stopTest();
    }

    @isTest
    static void testProcessCorspdQueueToView() {
        T_DOC_RQ__c corspdReq = new T_DOC_RQ__c (   CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107', RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C');
        T_DOC_RQ__c corspdReq_generated = new T_DOC_RQ__c (   CDE_CORSPD_STATUS__c = 'Generated', NME_CORSPD__c = 'CR107', DTE_REQ__c = system.today(), cde_lang_doc__c = 'ENG', RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C');
        //insert corspdReq;
        insert corspdReq_generated;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new CorspdPrintQueueMockSuccessTest());
        //corspdReturnPacket rtrn = corspdPrintQueue.processCorspdQueueToView(corspdReq.Name);
        corspdReturnPacket rtrn_gen = ManualCOrrespondenceController.processManualCorspdPrint(corspdReq_generated.Id);
        system.assertEquals('Success',rtrn_gen.returnStatus,'Return status should be Success');
        
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        corspdReturnPacket rtrn1 = corspdPrintQueue.processCorspdQueueToView(NULL);
        system.assertEquals('Failure',rtrn1.returnStatus,'Return status should be failure');
        test.stopTest();
    }

    @isTest
    static void testGetManualCorspdDetails1() {
        T_COUNTY__c countyObj=TestClassUtility.createCounty('County2','Dept2',10,true);
        T_SBSD_CASE__c caseObj = new T_SBSD_CASE__c(CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N', CDE_ASST_HSNG__c = 'N', Name = '123543', IND_ELG_PRE_PROVR__c  = false);//TestClassUtility.createCase(true, countyObj.Id);
        insert caseObj;
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c (Name = '1234567', NAM_FACILITY__c = 'Provider Name');
        insert providerObj;
        
        T_DOC_RQ__C corspdReqClient108 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR108', IDN_CASE__c = caseObj.Id, RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', cde_lang_doc__c = 'SPN', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqClient108;
        
        T_DOC_RQ__C corspdReqClient212 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR212', IDN_CASE__c = caseObj.Id, RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', cde_lang_doc__c = 'SPN', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqClient212;
        
        T_DOC_RQ__C corspdReqClient207 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR207', IDN_CASE__c = caseObj.Id, RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', cde_lang_doc__c = 'SPN', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqClient207;
        
        T_DOC_RQ__C corspdReqClient114 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR114', IDN_CASE__c = caseObj.Id, RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', cde_lang_doc__c = 'SPN', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqClient114;
        
        /*
        T_DOC_RQ__C corspdReqClient110 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR110', IDN_CASE__c = caseObj.Id, RSN_CODE__c = 'CR0022', CDE_TYPE_RCPT__c = 'C', cde_lang_doc__c = 'ENG', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqClient110;
		*/
        
        T_DOC_RQ__C corspdReqProvr702 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR702', IDN_PROVR__c = providerObj.Id, RSN_CODE__c = 'CR0013', CDE_TYPE_RCPT__c = 'P', cde_lang_doc__c = 'ENG', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqProvr702;
        
        T_DOC_RQ__C corspdReqClient109 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR109', IDN_CASE__c = caseObj.Id, RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', cde_lang_doc__c = 'SPN', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqClient109;
        
        T_DOC_RQ__C corspdReqProvr212 = new T_DOC_RQ__c(CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR212', IDN_PROVR__c = providerObj.Id, RSN_CODE__c = 'CR0013', CDE_TYPE_RCPT__c = 'P', cde_lang_doc__c = 'ENG', CDE_COUNTY__c = countyObj.Id);        
        insert corspdReqProvr212;
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ManualCorrespondenceMockTest());
        object getManualCorspdDetails_rslt = ManualCOrrespondenceController.getManualCorspdDetails(corspdReqClient108.Id,null,caseObj.Id);
        object getManualCorspdDetails_rslt1 = ManualCOrrespondenceController.getManualCorspdDetails(corspdReqClient114.Id,providerObj.Id,null);
        object getManualCorspdDetails_rslt2 = ManualCOrrespondenceController.getManualCorspdDetails(corspdReqClient207.Id,null,caseObj.Id);
        object getManualCorspdDetails_rslt3 = ManualCOrrespondenceController.getManualCorspdDetails(corspdReqClient212.Id,null,caseObj.Id);
        object getManualCorspdDetails_rslt4 = ManualCOrrespondenceController.getManualCorspdDetails(corspdReqProvr702.Id,providerObj.Id,null);
        object getManualCorspdDetails_rslt5 = ManualCOrrespondenceController.getManualCorspdDetails(corspdReqClient109.Id,null,caseObj.Id);
        //object getManualCorspdDetails_rslt6 = ManualCOrrespondenceController.getManualCorspdDetails(corspdReqClient110.Id,null,caseObj.Id);
        test.stopTest();
    }

}