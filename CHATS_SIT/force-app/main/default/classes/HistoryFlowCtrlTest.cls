@isTest
global class HistoryFlowCtrlTest {
    
    public static testMethod void testGetInitDataError(){
        LightningServerResponse lsr = HistoryFlowCtrl.getInitData(null);
    }
    
    public static testMethod void testGetInitData(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '1';
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstNameA','1','lastNameA','123','CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(false,system.today().addYears(-25),'firstNameB','1','lastNameB','123','CC');
        insert new List<SObject>{caseRec,individual, individual2};
            List<T_SBSD_CASE__c> cases = [SELECT IDN_EXTNL__c FROM T_SBSD_CASE__c];
        System.assertEquals(false, cases.isempty(), 'cases should not be empty');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual.Id,false);
        T_SBSD_CASE_INDIV__c caseIndiv2 = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual2.Id,true);
        caseIndiv.IDN_EXTNL__c='1';
        caseIndiv2.IDN_EXTNL__c='2';
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=individual.Id,
                                                                        ADR_CITY__c = 'Denver',
                                                                        IND_STUBS_PAY_RCVS__c = 'Y',
                                                                        DTE_BEGIN_EFFV__c = date.today(),
                                                                        NAM_BUSNS__c = 'DellCorp',
                                                                        IDN_EXTNL__c='1',
                                                                        Ignore__c=true);
        insert new List<SObject>{caseIndiv, caseIndiv2, employment};
            LightningServerResponse lsr = HistoryFlowCtrl.getInitData(null);
    }
    
    
    public static testMethod void testgetIneligibleReason(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '1';
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstNameA','1','lastNameA','123','CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(false,system.today().addYears(-25),'firstNameB','1','lastNameB','123','CC');
        insert new List<SObject>{caseRec,individual, individual2};
            List<T_SBSD_CASE__c> cases = [SELECT IDN_EXTNL__c FROM T_SBSD_CASE__c];
        System.assertEquals(false, cases.isempty(), 'cases should not be empty');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual.Id,false);
        T_SBSD_CASE_INDIV__c caseIndiv2 = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual2.Id,true);
        caseIndiv.IDN_EXTNL__c='1';
        caseIndiv2.IDN_EXTNL__c='2';
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=individual.Id,
                                                                        ADR_CITY__c = 'Denver',
                                                                        IND_STUBS_PAY_RCVS__c = 'Y',
                                                                        DTE_BEGIN_EFFV__c = date.today(),
                                                                        NAM_BUSNS__c = 'DellCorp',
                                                                        IDN_EXTNL__c='1',
                                                                        Ignore__c=true);
        insert new List<SObject>{caseIndiv, caseIndiv2, employment};
            LightningServerResponse lsr = HistoryFlowCtrl.getIneligibleReason(null);
    }
    
    
    public static testMethod void testincomeSummaryfetch(){

        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '1';
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstNameA','1','lastNameA','123','CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(false,system.today().addYears(-25),'firstNameB','1','lastNameB','123','CC');
        insert new List<SObject>{caseRec,individual, individual2};
        List<T_SBSD_CASE__c> cases = [SELECT IDN_EXTNL__c FROM T_SBSD_CASE__c];
        System.assertEquals(false, cases.isempty(), 'cases should not be empty');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual.Id,false);
        T_SBSD_CASE_INDIV__c caseIndiv2 = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual2.Id,true);
        caseIndiv.IDN_EXTNL__c='1';
        caseIndiv2.IDN_EXTNL__c='2';
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=individual.Id,
                                                                        ADR_CITY__c = 'Denver',
                                                                        IND_STUBS_PAY_RCVS__c = 'Y',
                                                                        DTE_BEGIN_EFFV__c = date.today(),
                                                                        NAM_BUSNS__c = 'DellCorp',
                                                                        IDN_EXTNL__c='1',
                                                                        Ignore__c=true);
        insert new List<SObject>{caseIndiv, caseIndiv2, employment};
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        //Removed unused variable on 5/13/2018 BG         
        Test.startTest();
        HistoryFlowCtrl.incomeSummaryfetch(null);
        Test.stopTest();  
    }
    
    global class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) { 
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            //res.setBody('{"example":"test"}');
            //res.setBody('[{"authCopayId":"1891","authCopayDteBeginEffectv":"null","indivNamFirst":"Ganesh","indivNamLast":"Hegde","authCopayAuthId":"123","cdeAuthStatus":"2","authProvrId":"a1jg00000028GDgAAM","namFacility":"Govinda Trust and company","provrNamLast":null,"provrNamFirst":null,"indivDOB":"2001-12-19","amtCopayAuth":"40.0","errorMsg":null},{"authCopayId":"1891","authCopayDteBeginEffectv":"9-9-1999","indivNamFirst":"Ganesh","indivNamLast":"Hegde","authCopayAuthId":"4444","cdeAuthStatus":"2","authProvrId":"a1jg00000028GDgAAM","namFacility":null,"provrNamLast":"Some","provrNamFirst":"Name","indivDOB":"2001-12-19","amtCopayAuth":"40.0","errorMsg":null},{"authCopayId":"40","authCopayDteBeginEffectv":"null","indivNamFirst":"Sachin","indivNamLast":"Tendukar","authCopayAuthId":"8888","cdeAuthStatus":"4","authProvrId":"a1jg00000028GjrAAE","namFacility":"Being Human Trust","provrNamLast":null,"provrNamFirst":null,"indivDOB":"2001-12-19","amtCopayAuth":"122.89","errorMsg":null}]');
            res.setStatusCode(200);
            return res;
        }
    }
    
}