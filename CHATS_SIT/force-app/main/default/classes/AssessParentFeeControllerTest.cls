@isTest
global class AssessParentFeeControllerTest {
    
    testMethod static void testGetAuthCopayRecords() {
        
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        batchsit_t_auth_status__x authStatus ;
        //Removed unused variable on 5/13/2018 BG         
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyObj.Id);
        caseRec.DTE_APPLN__c = System.today().addDays(-10);
        caseRec.IDN_EXTNL__c = '4444';
        insert caseRec;
        T_AUTH__c authObj = TestClassUtility.createAuthorization(false, null, System.today().addDays(-8), countyObj.Id, providerObj.Id);
        authObj.IDN_CASE__c = caseRec.Id;
        authObj.IDN_EXTNL__c='123';
        insert authObj;
        T_AUTH__c authObj2 = TestClassUtility.createAuthorization(false, null, System.today().addDays(-8), countyObj.Id, providerObj.Id);
        authObj2.IDN_CASE__c = caseRec.Id;
        authObj.IDN_EXTNL__c='456';
        insert authObj2;
        
        //Removed unused variable on 5/13/2018 BG  
        AuthorizationStatusController.upsertAuthStatus(authStatus,true,false,authObj.Id,true);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        //Removed unused variable on 5/13/2018 BG         
        Test.startTest();
        List<ParentFeeAssessmentWrapper> wrapList = AssessParentFeeController.getAuthCopayRecords('4444');
        System.assertEquals(wrapList[0].IDN_AUTH, '123');
        Test.stopTest();
    }
    
    global class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            System.assertEquals(Label.AuthCopayFetch, req.getEndpoint());
            System.assertEquals('POST', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            //res.setBody('{"example":"test"}');
            res.setBody('[{"authCopayId":"1891","authCopayDteBeginEffectv":"null","indivNamFirst":"Ganesh","indivNamLast":"Hegde","authCopayAuthId":"123","cdeAuthStatus":"2","authProvrId":"a1jg00000028GDgAAM","namFacility":"Govinda Trust and company","provrNamLast":null,"provrNamFirst":null,"indivDOB":"2001-12-19","amtCopayAuth":"40.0","errorMsg":null},{"authCopayId":"1891","authCopayDteBeginEffectv":"9-9-1999","indivNamFirst":"Ganesh","indivNamLast":"Hegde","authCopayAuthId":"4444","cdeAuthStatus":"2","authProvrId":"a1jg00000028GDgAAM","namFacility":null,"provrNamLast":"Some","provrNamFirst":"Name","indivDOB":"2001-12-19","amtCopayAuth":"40.0","errorMsg":null},{"authCopayId":"40","authCopayDteBeginEffectv":"null","indivNamFirst":"Sachin","indivNamLast":"Tendukar","authCopayAuthId":"8888","cdeAuthStatus":"4","authProvrId":"a1jg00000028GjrAAE","namFacility":"Being Human Trust","provrNamLast":null,"provrNamFirst":null,"indivDOB":"2001-12-19","amtCopayAuth":"122.89","errorMsg":null}]');
            res.setStatusCode(202);
            res.setStatus('Accepted');
            return res;
        }
    }
}