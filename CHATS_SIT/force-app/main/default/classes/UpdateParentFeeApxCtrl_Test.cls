@isTest
global class UpdateParentFeeApxCtrl_Test {
    public static final String OPEN = 'OPN';
    public static final String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
    testMethod static void testSaveAuthCopay() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();   
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x();
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        T_SBSD_Case__c caseRec = new T_SBSD_Case__c(CDE_COUNTY__c=countyRec.Id);  
        insert caseRec;
        Date effective = System.today();
        String wrapLst = '[{"AMT_COPAY_AUTH":"10","authCopayId":"1891","CDE_STATUS_AUTH":"2","childName":"Hegde,Ganesh","DTE_DOB":"2001-12-19","IDN_AUTH":"4444","IDN_PROVR":"a1jg00000028GDgAAM","ProviderName":"Govinda Trust and company","errMsg":null},{"AMT_COPAY_AUTH":"10","authCopayId":"1889","CDE_STATUS_AUTH":"2","childName":"Hegde,Ganesh","DTE_DOB":"2001-12-19","IDN_AUTH":"4444","IDN_PROVR":"a1jg00000028GDgAAM","ProviderName":"Govinda Trust and company","errMsg":null}]';
        ParentFeeAllocationWrapper wrapper = new ParentFeeAllocationWrapper('Hegde,Ganesh','4444',effective, '123', 'Govinda Trust and company', effective,effective,  10,  'authExternalId', effective, '12345',false,effective,10,'','' ); 
        List<ParentFeeAllocationWrapper> listWrapper = new List<ParentFeeAllocationWrapper>();
        listWrapper.add(wrapper);
        String authCopayWrap = JSON.serialize(listWrapper);
        
        String wrapLst2 = '[{"AMT_COPAY_AUTH":"10","authCopayId":"1891","CDE_STATUS_AUTH":"2","childName":"Hegde,Ganesh","DTE_DOB":"2001-12-19","IDN_AUTH":"4444","IDN_PROVR":"a1jg00000028GDgAAM","ProviderName":"Govinda Trust and company","errMsg":null},{"AMT_COPAY_AUTH":"10","authCopayId":"1889","CDE_STATUS_AUTH":"2","childName":"Hegde,Ganesh","DTE_DOB":"2001-12-19","IDN_AUTH":"4444","IDN_PROVR":"a1jg00000028GDgAAM","ProviderName":"Govinda Trust and company","errMsg":null}]';
        ParentFeeAllocationWrapper wrapper2 = new ParentFeeAllocationWrapper('Hegde,Ganesh','4444',effective, '123', 'Govinda Trust and company', effective,effective,  10,  'authExternalId', effective, '',false,effective ,10,'','');
        List<ParentFeeAllocationWrapper> listWrapper2 = new List<ParentFeeAllocationWrapper>();
        listWrapper2.add(wrapper2);
        String authCopayWrap2 = JSON.serialize(listWrapper2);

        String uniqueUserName = 'testuser' + DateTime.now().getTime() + '@test.com';
        Profile pro = [SELECT Id FROM Profile WHERE Name='Read Only User'];
        User testUser = TestClassUtility.createUser(pro.Id, 'lastNameT', 'firstNameT', 'testUser@test.com', 'testing_testuser@test.com', 'testT');
        System.runAs(testUser) {
            UpdateParentFeeApxCtrl.getInitData(caseRec.Id);
        }
        UpdateParentFeeApxCtrl.getActiveAuthorizationForCase(caseRec.Id,effDt);
        UpdateParentFeeApxCtrl.getActiveAuthorizationForCase(caseRec.Id,'2018-01');
        UpdateParentFeeApxCtrl.deleteParentFeeData('12345');
        UpdateParentFeeApxCtrl.saveAuthCopay(effDt,authCopayWrap);
        UpdateParentFeeApxCtrl.saveAuthCopay('2018-01',authCopayWrap);
        UpdateParentFeeApxCtrl.updateAuthCopay(effDt,authCopayWrap,false);
        UpdateParentFeeApxCtrl.updateAuthCopay('2018-01',authCopayWrap2,false);
        Test.stopTest();
    }
    testMethod static void testgetActiveAuthorizationForCase() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        
        Date datetoday=System.Today();
        //Date begindate = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        //Date enddate = begindate.addDays(20);
        
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        sbsdcase.IDN_EXTNL__c='12345';
        upsert sbsdcase;
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        String parentFeeDate =String.valueOf(begindate);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.CDE_TYPE_VERIF__c = 'NA';
        authorization.CDE_SOURCE_VRFYD_IMMU__c ='PRO';
        authorization.CDE_IMM__c ='NRL';
        insert authorization;
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement.RecordtypeId=openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c=begindateOpn;
        insert fiscalAgreement;
        T_FISCAL_SCH__c fiscalRateSch1 = new T_FISCAL_SCH__c(IDN_AGRMT_FISCAL__c = fiscalAgreement.Id, CDE_RATE_TYPE__c = '1', TXT_CHATS_RATING__c='Level 3', DTE_BEGIN_EFFV__c= (Date.today()).addDays(-7));
        insert fiscalRateSch1;
        Test.startTest();
        UpdateParentFeeApxCtrl.getActiveAuthorizationForCase(sbsdcase.Id,parentFeeDate);
        Test.stopTest();
    } 
    
    global class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            //System.assertEquals(Label.AuthCopayFetch, req.getEndpoint());
            //System.assertEquals('POST', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            //res.setBody('{"example":"test"}');
            res.setBody('[{"authCopayId":"1892","errMessage":"Test","successInd":"N"},{"authCopayId":"1893","errMessage":"Test","successInd":"Y"}]');
            res.setStatusCode(300);
            res.setStatus('OK');
            return res;
        }
    }
     global class MockHttpResponseGenerator1 implements HttpCalloutMock {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            //System.assertEquals(Label.AuthCopayFetch, req.getEndpoint());
            //System.assertEquals('POST', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            //res.setBody('{"example":"test"}');
            res.setBody('{"caseCopayid":"860985","successInd":"Y","errMessage":""}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }
    global class MockHttpResponseGenerator2 implements HttpCalloutMock {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            //System.assertEquals(Label.AuthCopayFetch, req.getEndpoint());
            //System.assertEquals('POST', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            //res.setBody('{"example":"test"}');
            res.setBody('{"caseCopayid":"860985","successInd":"N","errMessage":"tEST"}');
            res.setStatusCode(300);
            res.setStatus('OK');
            return res;
        }
    }
    @isTest static void testPostCallout() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= System.today(),cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
       // HerokuService.caseCopyCreate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','',true);
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',false,newCaseCopayRec);
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',TRUE,newCaseCopayRec);
        Test.stopTest();
        
    }
    @isTest static void testPostCallout_Scneraio3() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= System.today(),cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        HerokuService.caseCopyUpdate('12','123','effDt', '12','Y','2018-12-12','','1233','111','11','12','12','12345');
        HerokuService.caseCopyCreate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','',true);
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',false,newCaseCopayRec);
        Test.stopTest();
        
    }
    @isTest static void testPostCallout_Scneraio6() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= System.today(),cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        HerokuService.caseCopyCreate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','',true);
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',TRUE,newCaseCopayRec);
        Test.stopTest();
        
    }
     @isTest static void testPostCallout_Scneraio10() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= System.today(),cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        HerokuService.caseCopyCreate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','',true);
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',TRUE,newCaseCopayRec);
        Test.stopTest();
        
    }
    @isTest static void testPostCallout_Scneraio11() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= System.today(),cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        HerokuService.caseCopyCreate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','',true);
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',FALSE,newCaseCopayRec);
        Test.stopTest();
        
    }
    @isTest static void testPostCallout_Scneraio12() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= System.today(),cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        HerokuService.caseCopyUpdate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','','12345');
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',FALSE,newCaseCopayRec);
        Test.stopTest();
        
    }
    @isTest static void testPostCallout_Scneraio13() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
        Date effectiveDate = Date.newInstance(2018, 04, 01); 
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= effectiveDate,cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        HerokuService.caseCopyUpdate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','','12345');
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',FALSE,newCaseCopayRec);
        Test.stopTest();
        
    }
    @isTest static void testPostUpdateCallout() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
       batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= System.today(),cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x(); Test.startTest();
        HerokuService.caseCopyUpdate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','','12345');
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',false,newCaseCopayRec);
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',TRUE,newCaseCopayRec);
        Test.stopTest();
        
    }
    @isTest static void testPostUpdateCallout_Scneraio4() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
       batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= System.today(),cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        HerokuService.caseCopyUpdate('12','123','effDt', '12','Y','2018-12-12','','1233','111','11','12','12','12345');
        HerokuService.caseCopyCreate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','',true);
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',false,newCaseCopayRec);
        Test.stopTest();
        
    }
     @isTest static void testPostUpdateCallout_Scneraio5() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseCaseCopayGenerator()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
       batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_ft__c=123,amt_copay_case_assesd__c=10,dte_begin_effv__c= System.today(),cde_rec_copay__c ='TES',cde_reason_ovrd__c='Test',idn_case__c='12345',nbr_seq_hist__c=1234,amt_copay_case_ft_qlty__c=123,amt_copay_case_pt_qlty__c=123,ind_qlty__c='Y',idn_sbsd_case_copay__c=123456);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        HerokuService.caseCopyUpdate('12','123','effDt', '12','Y','2018-12-12','','1233','111','11','12','12','12345');
        HerokuService.caseCopyCreate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','',true);
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',false,newCaseCopayRec);
         UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',true,newCaseCopayRec);
        Test.stopTest();
        
    }
    global class MockHttpResponseCaseCopayGenerator implements HttpCalloutMock {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"caseCopayid":"860983","successInd":"N","errMessage":"Custom"}');
            response.setStatusCode(200);
            return response; 
        }
    }

    @isTest static void testPostUpdateCallout_Scneraio1() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_assesd__c=10);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        HerokuService.caseCopyUpdate('12','1234','effDt', 'wrapLst','false','newCaseCopayRec','123','123','111','11','','','12345');
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',false,newCaseCopayRec);
        
        Test.stopTest();
        
    }
    @isTest static void testPostUpdateCallout_Scneraio2() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId ='12345',amt_copay_case_pt__c =10,amt_copay_case_assesd__c=10);
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        Test.startTest();
        UpdateParentFeeApxCtrl.saveCaseCopayRecord(caseCopayRec,'1234',effDt, 'wrapLst',false,newCaseCopayRec);
        Test.stopTest();
        
    }
    testMethod static void testAuthWeight() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x();
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        T_SBSD_Case__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        T_SBSD_Case__c caseR= new T_SBSD_Case__c(CDE_COUNTY__c=countyRec.Id);  
        insert caseR;
        system.debug('caseR---'+caseR.id);
        UpdateParentFeeApxCtrl.getInitData(caseR.Id);
        UpdateParentFeeApxCtrl.getAuthWeight(caseR.Id,'2022-11-01');
        Test.stopTest();
    }
     testMethod static void testgetAuthCopayRecords() {
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        Test.startTest();
         Date effective = System.today();
         ParentFeeAllocationWrapper wrapper2 = new ParentFeeAllocationWrapper('Hegde,Ganesh','4444',effective, '123', 'Govinda Trust and company', effective,effective,  10,  'authExternalId', effective, '',false,effective,10,'','' );
        List<ParentFeeAllocationWrapper> listWrapper2 = new List<ParentFeeAllocationWrapper>();
        listWrapper2.add(wrapper2);
        String authCopayWrap2 = JSON.serialize(listWrapper2);
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x();
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        T_SBSD_Case__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        T_SBSD_Case__c caseR= new T_SBSD_Case__c(CDE_COUNTY__c=countyRec.Id);  
        insert caseR;
        system.debug('caseR---'+caseR.id);
         ParentFeeFlowWSCaller.callSearchParentFeeWS(caseR.IDN_EXTNL__c,'10',2019,effDt,null);
         //UpdateParentFeeApxCtrl.getAuthCopayRecords(caseRec.Id,effDt);
         UpdateParentFeeApxCtrl.upsertParentFeeData(authCopayWrap2,system.today(),true,true);
         UpdateParentFeeApxCtrl.getCaseParentFeeRecord(caseR.IDN_EXTNL__c,effDt,null);
         UpdateParentFeeApxCtrl.getCaseParentFeeRecord(caseR.IDN_EXTNL__c,'2018-01',null);
        Test.stopTest();
    }
     testMethod static void testgetAuthCopayRecords_Scneraio1() {
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        
         Date effective = System.today();
         ParentFeeAllocationWrapper wrapper2 = new ParentFeeAllocationWrapper('Hegde,Ganesh','4444',effective, '123', 'Govinda Trust and company', effective,effective,  10,  'authExternalId', effective, '',false,effective ,10,'','');
        List<ParentFeeAllocationWrapper> listWrapper2 = new List<ParentFeeAllocationWrapper>();
        listWrapper2.add(wrapper2);
        String authCopayWrap2 = JSON.serialize(listWrapper2);
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x();
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        T_SBSD_Case__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        T_SBSD_Case__c caseR= new T_SBSD_Case__c(CDE_COUNTY__c=countyRec.Id);  
        insert caseR;
        system.debug('caseR---'+caseR.id);
        Test.startTest();
        UpdateParentFeeApxCtrl.getAuthCopayRecords(caseRec.Id,effDt,null,'');
        UpdateParentFeeApxCtrl.getAuthCopayRecords(caseRec.Id,'2018-01',null,'');
        Test.stopTest();
    }
     testMethod static void testgetAuthCopayRecords_Scneraio2() {
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        
         Date effective = System.today();
         ParentFeeAllocationWrapper wrapper2 = new ParentFeeAllocationWrapper('Hegde,Ganesh','4444',effective, '123', 'Govinda Trust and company', effective,effective,  10,  'authExternalId', effective, '',false,effective ,10,'','');
        List<ParentFeeAllocationWrapper> listWrapper2 = new List<ParentFeeAllocationWrapper>();
        listWrapper2.add(wrapper2);
        String authCopayWrap2 = JSON.serialize(listWrapper2);
        String effDt = '2018-04-01';
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x();
        batchsit_t_sbsd_case_copay__x newCaseCopayRec = new batchsit_t_sbsd_case_copay__x();
        T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        T_SBSD_Case__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        T_SBSD_Case__c caseR= new T_SBSD_Case__c(CDE_COUNTY__c=countyRec.Id);  
        insert caseR;
         Test.startTest();
         ParentFeeFlowWSCaller.callSearchParentFeeWS(caseR.IDN_EXTNL__c,'10',2019,effDt,null);
         UpdateParentFeeApxCtrl.upsertParentFeeData(authCopayWrap2,system.today(),true,true);
         UpdateParentFeeApxCtrl.getPrivateRates(listWrapper2, system.today(), 'PT', caseR.IDN_EXTNL__c, null);
        Test.stopTest();
    }    
}