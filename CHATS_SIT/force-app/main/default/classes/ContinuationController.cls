global with sharing class ContinuationController {
    
    public ContinuationController() {
        String hostname = URL.getOrgDomainUrl().getHost();
        String lcBaseURL;    
        if(Test.isRunningTest()){
            hostname = 'https://cccap--chats--c.cs20.visual.force.com/apex/ContinuationProxy';
        }
        String mydomain = hostname.substring(0, hostname.indexOf('.'));
        if(mydomain.lastIndexOf('--c')!=-1){
            mydomain = mydomain.substring(0, mydomain.lastIndexOf('--c'));
        }
        if(hostname.contains('sandbox')){
            lcBaseURL = 'https://' + mydomain + '.sandbox.lightning.force.com';
        } else {
            lcBaseURL = 'https://' + mydomain + '.lightning.force.com';
        }
        Map<String, String> headers = Apexpages.currentPage().getHeaders();	
        headers.put('X-Frame-Options', 'ALLOW-FROM ' + lcBaseURL);
        headers.put('Content-Security-Policy', 'frame-ancestors ' + lcBaseURL);
        
    }
    
    @AuraEnabled
    public static String getVFBaseURL() {
        User user = [SELECT fullPhotoUrl FROM User WHERE userType = 'Standard' LIMIT 1]; 
        // The above query returns a URL like https://my-domain-dev-ed--c.na50.content.force.com/profilephoto/001/A
        // Let's use the two first fragments of that URL to create the VF base URL 
        List<String> fragments = user.fullPhotoUrl.split('\\.');
        if(user.FullPhotoUrl.contains('sandbox')){
            return fragments[0].toLowerCase() + '--c.' + fragments[1].toLowerCase() + '.vf.force.com';    
        } else {
            return fragments[0].toLowerCase() + '--c.vf.force.com';
        }
    }
    
    // Called via JavaScript Remoting
    @RemoteAction
    global static Object invoke(String methodName, String[] params) {
        String method = '';
        String param0 ='';
        String param1 ='';
        String param2 ='';
        String param3 ='';
        if(methodName!= null){
            method = String.escapeSingleQuotes(methodName);
        }
        if(params!= null && params.size()> 0){
            param0 = String.escapeSingleQuotes(params[0]);
        }
        if(params!= null && params.size()> 1){
            param1 = String.escapeSingleQuotes(params[1]);
        }
        if(params!= null && params.size()> 2){
            param2 = String.escapeSingleQuotes(params[2]);
        }
        if(params!= null && params.size()> 3){
            param3 = String.escapeSingleQuotes(params[3]);
        }
        if(method == 'BRECreate'){
            // Create a Continuation for the HTTPRequest        
            Continuation con = new Continuation(120);
            return AssessEligibilityFlowApxCtrl.doCallAssessEligibilityContinuation(con, param0 ,param1);
        }else if(method == 'BRESaveIneligibilityReasons'){
            // Create a Continuation for the HTTPRequest        
            Continuation con = new Continuation(120);
            return IndividualFlowCtrl.doCallBRESaveIneligibilityReasonsContinuation(con, param0,param1,param2,param3);
        }else if(method == 'BREConfirmEligibility'){
            // Create a Continuation for the HTTPRequest        
            Continuation con = new Continuation(120);
            return EligibilityFlowCmpApxCtrl.doCallBREConfirmEligibilityContinuation(con, param0, param1);
        }else{
            return null;
        }
    }
    
    global static Object callbackForBRECreate(Object state) {
        return AssessEligibilityFlowApxCtrl.doCallBackAssessEligibilityContinuation(state);
    }
    
    global static Object callbackForBRESaveIneligibilityReasons(Object state) {
        return IndividualFlowCtrl.doCallBackBRESaveIneligibilityReasonsContinuation(state);
    }
    
    global static Object callbackForBREConfirmEligibility(Object state) {
        return EligibilityFlowCmpApxCtrl.doCallBackBREConfirmEligibilityContinuation(state);
    }
}