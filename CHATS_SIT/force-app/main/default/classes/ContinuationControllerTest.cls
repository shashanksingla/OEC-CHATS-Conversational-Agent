@isTest
public class ContinuationControllerTest {

    @testSetup
    public static void doSetupData(){
        CaseLastUpdatedTestFactory.createCaseData();
    }
    
    public static testMethod void testGetVFBaseURL(){
        PageReference pageRef = Page.ContinuationProxy;
        System.assertEquals(true, ContinuationController.getVFBaseURL()!=null, 'getVFBaseURL() should return a value');
    }

    public static testMethod void testController(){
        ContinuationController conti = new ContinuationController();
        system.assertEquals(true,string.valueof(conti).contains('ContinuationController'),'Should return ContinuationController');
    }
    
    public static testMethod void testInvokeWithNull(){
        Continuation conti = (Continuation)ContinuationController.invoke(null, null);
        system.assertEquals(null,conti ,'Should return null');
    }
    
   /* public static testMethod void testDoCallBackAssessEligibilityContinuation(){
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        //AssessEligibilityFlowApxCtrl.doCallBackAssessEligibilityContinuation('Continuation-1');
    }    
    */
    public static testMethod void testCallbackForBRECreate200(){
        //Removed unused variable on 5/13/2018 BG         
        List<T_SBSD_CASE__c> cases = [SELECT Id FROM T_SBSD_CASE__c limit 202];
        System.assertEquals(false,cases.isEmpty(),'cases should not empty');
        List<String> params = new List<String>{cases.get(0).Id,'TF'};
        Continuation conti = (Continuation)ContinuationController.invoke('BRECreate', params);
        System.debug('conti:'+conti);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBREResponse200());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBRECreate('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }

    public static testMethod void testCallbackForBRECreate200WithError(){
        
        List<T_SBSD_CASE__c> cases = [SELECT Id FROM T_SBSD_CASE__c limit 202];
        System.assertEquals(false,cases.isEmpty(),'cases should not empty');
        List<String> params = new List<String>{cases.get(0).Id,'TF'};
            Continuation conti = (Continuation)ContinuationController.invoke('BRECreate', params);
        System.debug('conti:'+conti);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBREResponse200withError());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBRECreate('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }

    
    public static testMethod void testCallbackForBRECreateGreaterThan2000(){
        //Removed unused variable on 5/13/2018 BG         
        List<T_SBSD_CASE__c> cases = [SELECT Id FROM T_SBSD_CASE__c limit 202];
        System.assertEquals(false,cases.isEmpty(),'cases should not empty');
        List<String> params = new List<String>{cases.get(0).Id,'TF'};
        Continuation conti = (Continuation)ContinuationController.invoke('BRECreate', params);
        System.debug('conti:'+conti);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBREResponseGreaterThan2000());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBRECreate('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }

    public static testMethod void testCallbackForBRECreateNot200(){
        //Removed unused variable on 5/13/2018 BG         
        List<T_SBSD_CASE__c> cases = [SELECT Id FROM T_SBSD_CASE__c limit 202];
        System.assertEquals(false,cases.isEmpty(),'cases should not empty');
        List<String> params = new List<String>{cases.get(0).Id,'TF'};
        Continuation conti = (Continuation)ContinuationController.invoke('BRECreate', params);
        System.debug('conti:'+conti);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBREResponseNot200());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBRECreate('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }
    
    public static testMethod void testCallbackForBREConfirmEligibility200(){
        List<String> params = new List<String>{'71112636','10109087'};
        Continuation conti = (Continuation)ContinuationController.invoke('BREConfirmEligibility', params);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBREConfirmEligibilityResponse200());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBREConfirmEligibility('Continuation-1');
        system.assertEquals( true,lsr.isSuccessful,'isSuccessful should return true');
    }

    public static testMethod void testCallbackForBREConfirmEligibilityGreaterThan2000(){
        List<String> params = new List<String>{'71112636','10109087'};
        Continuation conti = (Continuation)ContinuationController.invoke('BREConfirmEligibility', params);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBREConfirmEligibilityResponseGreaterThan200());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBREConfirmEligibility('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }
    
    public static testMethod void testCallbackForBREConfirmEligibility200WithError(){
        List<String> params = new List<String>{'71112636','10109087'};
        Continuation conti = (Continuation)ContinuationController.invoke('BREConfirmEligibility', params);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBREConfirmEligibilityResponse200WithError());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBREConfirmEligibility('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }

    
    public static testMethod void testCallbackForBREConfirmEligibilityNot200(){
        List<String> params = new List<String>{'71112636','10109087'};
        Continuation conti = (Continuation)ContinuationController.invoke('BREConfirmEligibility', params);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBREConfirmEligibilityResponseNot200());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBREConfirmEligibility('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }
    
     public static testMethod void testInvoke(){
        try{
        ContinuationController.invoke('BRESaveIneligibilityReasons', new string[] {'0','1','2'});
        } catch(Exception ex) {  
            System.debug('The following exception has occurred from Method testInvoke Line 94 in Apex class EligibilityFlowCmpApxCtrlTest: ' + ex.getMessage()); // IronDome Report fix.
        }
         try{
         LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBRESaveIneligibilityReasons('Continuation-1');
         system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
         } catch(Exception ex) {
             System.debug('The following exception has occurred from Method testInvoke Line 99 in Apex class EligibilityFlowCmpApxCtrlTest: ' + ex.getMessage()); // IronDome Report fix.
         }
          try{
        ContinuationController.callbackForBREConfirmEligibility('Continuation-1');
          } catch(Exception ex) {
              System.debug('The following exception has occurred from Method testInvoke Line 104 in Apex class EligibilityFlowCmpApxCtrlTest: ' + ex.getMessage()); // IronDome Report fix.
          }
    }
    
    public static testMethod void testCallbackForBRESaveIneligibilityReasons200(){
        //Removed unused variable on 5/14/2018 BG  
        List<String> params = new List<String>{'123456','123456','CR115','054,076,075'};
        Continuation conti = (Continuation)ContinuationController.invoke('BRESaveIneligibilityReasons', params);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBRESaveIneligibilityReasonse200());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBRESaveIneligibilityReasons('Continuation-1');
        system.assertEquals( true,lsr.isSuccessful,'isSuccessful shouls return true');
    }

    public static testMethod void testCallbackForBRESaveIneligibilityReasons200WithError(){
        //Removed unused variable on 5/14/2018 BG  
        List<String> params = new List<String>{'123456','123456','CR115','054,076,075'};
        Continuation conti = (Continuation)ContinuationController.invoke('BRESaveIneligibilityReasons', params);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getBRESaveIneligibilityReasonse200WithError());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBRESaveIneligibilityReasons('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }

    public static testMethod void testCallbackForBRESaveIneligibilityReasonsGreaterThan200(){
        //Removed unused variable on 5/14/2018 BG  
        List<String> params = new List<String>{'123456','123456','CR115','054,076,075'};
        Continuation conti = (Continuation)ContinuationController.invoke('BRESaveIneligibilityReasons', params);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getResponseGreaterThan2400());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBRESaveIneligibilityReasons('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }
    
    public static testMethod void testCallbackForBRESaveIneligibilityReasonsNot200(){
        //Removed unused variable on 5/14/2018 BG  
        List<String> params = new List<String>{'123456','123456','CR115','054,076,075'};
        Continuation conti = (Continuation)ContinuationController.invoke('BRESaveIneligibilityReasons', params);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, HttpRequest> requests = conti.getRequests();
        System.debug(requests);
        // Set the fake response for the continuation     
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator();
        Test.setContinuationResponse('Continuation-1', mock.getResponseNot200());
        LightningServerResponse lsr=(LightningServerResponse)ContinuationController.callbackForBRESaveIneligibilityReasons('Continuation-1');
        system.assertEquals( false,lsr.isSuccessful,'isSuccessful will return false');
    }
    
    
}