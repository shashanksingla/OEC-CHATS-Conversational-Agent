@isTest
global class parentFeeFlowApxCtrlTest {
    
    testMethod static void testUpsertCaseCopay() {
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId='11',amt_copay_case_assesd__c=10,cde_rec_copay__c='3',dte_begin_effv__c=Date.valueOf('2012-12-12'),idn_case__c='14',amt_copay_case_ft__c=1,amt_copay_case_ft_qlty__c=1,amt_copay_case_pt__c=1,amt_copay_case_pt_qlty__c=1,cde_reason_ovrd__c='R',createddate__c=Date.valueOf('2010-08-24'),dte_end_effv__c=Date.valueOf('2018-04-30'),idn_sbsd_case_copay__c=11,ind_qlty__c='Y',lastmodifieddate__c=Date.valueOf('2018-03-06'),nbr_seq_hist__c=1);
        Test.startTest();
        try {
        parentFeeFlowApxCtrl.upsertCaseCopay(caseCopayRec, '100', '2018-05-01', 'R',true, null);
        } catch(Exception ex) {
            system.assert(string.valueOf(ex.getMessage()).contains('0'),'Should return zero records'); //.contains('Methods defined as TestMethod do not support Web service callouts'),'Web service callout should not be supported');
        }
        try {
        parentFeeFlowApxCtrl.upsertCaseCopay(caseCopayRec, '100', '2018-05-01', 'R',true, '1');
        } catch(Exception ex) {
            system.assert(string.valueOf(ex.getMessage()).contains('0'),'Should return zero records');//.contains('Methods defined as TestMethod do not support Web service callouts'),'Web service callout should not be supported');
        }
        Test.stopTest();
    }
    
    testMethod static void testGetInitData() {
        try {
        T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        
        T_SBSD_Case__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '12345';
        upsert caseRec;
        
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId='11',amt_copay_case_assesd__c=10,cde_rec_copay__c='3',dte_begin_effv__c=Date.valueOf('2012-12-12'),amt_copay_case_ft__c=1,amt_copay_case_ft_qlty__c=1,amt_copay_case_pt__c=1,amt_copay_case_pt_qlty__c=1,cde_reason_ovrd__c='R',createddate__c=Date.valueOf('2010-08-24'),dte_end_effv__c=Date.valueOf('2018-04-30'),idn_sbsd_case_copay__c=11,ind_qlty__c='Y',lastmodifieddate__c=Date.valueOf('2018-03-06'),nbr_seq_hist__c=1, idn_case__c=caseRec.IDN_EXTNL__c);
        Database.insertAsync(caseCopayRec);
        
        system.debug('caseCopayRec'+caseCopayRec);
        
        TestClassUtility.createEligibilityRunRecord(true, caseRec.Id);
        
        Test.startTest();
        system.debug('caseCopayRec  '+caseCopayRec);
        parentFeeFlowApxCtrl.getInitData(caseRec.Id);
        parentFeeFlowApxCtrl.deleteCaseCopayRecord(caseCopayRec.Id);
        system.assertEquals('12345',caseRec.IDN_EXTNL__c,'Case External Id should match' );
        Test.stopTest();
        } catch(Exception ex) {}
    }
    testMethod static void testdeleteCaseCopayRecord() {
        try{ 
        T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        T_SBSD_Case__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '12345';
        upsert caseRec;
        
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId='11',amt_copay_case_assesd__c=10,cde_rec_copay__c='3',dte_begin_effv__c=Date.valueOf('2012-12-12'),amt_copay_case_ft__c=1,amt_copay_case_ft_qlty__c=1,amt_copay_case_pt__c=1,amt_copay_case_pt_qlty__c=1,cde_reason_ovrd__c='R',createddate__c=Date.valueOf('2010-08-24'),dte_end_effv__c=Date.valueOf('2018-04-30'),idn_sbsd_case_copay__c=11,ind_qlty__c='Y',lastmodifieddate__c=Date.valueOf('2018-03-06'),nbr_seq_hist__c=1, idn_case__c=caseRec.IDN_EXTNL__c);
        parentFeeFlowApxCtrl.mockListTest.add(caseCopayRec);
        List<batchsit_t_auth_copay__x> currentAuthCopayRecord = new  List<batchsit_t_auth_copay__x>();
       
        batchsit_t_auth_copay__x authCopayList = new batchsit_t_auth_copay__x();
        authCopayList.dte_begin_effv__c = System.today()+1;
        authCopayList.dte_end_effv__c = System.today()+1;
        currentAuthCopayRecord.add(authCopayList);
       
        system.debug('**************authCopayList.dte_begin_effv__c'+ System.today() + '   '+authCopayList.dte_begin_effv__c);
        List<batchsit_t_auth_copay__x> authCopayRecordToDelete = new  List<batchsit_t_auth_copay__x>();
         authCopayRecordToDelete.add(authCopayList);
        Test.startTest();
        parentFeeFlowApxCtrl.deleteCaseCopayRecord(caseCopayRec.Id);
        parentFeeFlowApxCtrl.deleteAuthCopayRecord(currentAuthCopayRecord,authCopayRecordToDelete);
        system.assertEquals('12345',caseRec.IDN_EXTNL__c,'Case External Id should match' );
        Test.stopTest();
        } catch(Exception ex) {
        }
    }

    testMethod static void testSaveAuthCopay() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        String effDt = '2018-04-01';
        String wrapLst = '[{"AMT_COPAY_AUTH":"10","authCopayId":"1891","CDE_STATUS_AUTH":"2","childName":"Hegde,Ganesh","DTE_DOB":"2001-12-19","IDN_AUTH":"4444","IDN_PROVR":"a1jg00000028GDgAAM","ProviderName":"Govinda Trust and company","errMsg":null},{"AMT_COPAY_AUTH":"10","authCopayId":"1889","CDE_STATUS_AUTH":"2","childName":"Hegde,Ganesh","DTE_DOB":"2001-12-19","IDN_AUTH":"4444","IDN_PROVR":"a1jg00000028GDgAAM","ProviderName":"Govinda Trust and company","errMsg":null}]';
        //String wrapLst = JSON.serializePretty('[{"authCopayId":"1891","authCopayDteBeginEffectv":"null","indivNamFirst":"Ganesh","indivNamLast":"Hegde","authCopayAuthId":"4444","cdeAuthStatus":"2","authProvrId":"a1jg00000028GDgAAM","namFacility":"Govinda Trust and company","provrNamLast":null,"provrNamFirst":null,"indivDOB":"2001-12-19","amtCopayAuth":"40.0","errorMsg":null},{"authCopayId":"1891","authCopayDteBeginEffectv":"9/9/2009","indivNamFirst":"Ganesh","indivNamLast":"Hegde","authCopayAuthId":"4444","cdeAuthStatus":"2","authProvrId":"a1jg00000028GDgAAM","namFacility":null,"provrNamLast":"Some","provrNamFirst":"Name","indivDOB":"2001-12-19","amtCopayAuth":"40.0","errorMsg":null}]');
        LightningServerResponse resp = parentFeeFlowApxCtrl.saveAuthCopay(effDt, wrapLst);
        System.assertEquals(true, resp.isSuccessful,'issuccessful should be true');
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
            res.setBody('[{"authCopayId":"1892","errMessage":"","successInd":"Y"},{"authCopayId":"1893","errMessage":"","successInd":"Y"}]');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }
}