public with sharing class AssessParentFeeController {
    @auraEnabled
    public Static List<ParentFeeAssessmentWrapper> getAuthCopayRecords(String caseId) {
        List<ParentFeeAssessmentWrapper> wrapList = new List<ParentFeeAssessmentWrapper>();
        Id caseSFid;
        Set<String> authId = new Set<String>();
        Map<String,Object> methodInfo = new Map<String,Object>();
        methodInfo.put('Class__c','AssessParentFeeController');    
        methodInfo.put('Method__c','getAuthCopayRecords'); 
        //caseId = 'a2T0t000000OMxaEAG';
        if(caseId!= null) {
            //caseId = 'a2T0t000000OMxaEAG';
            Set<String> caseAuthorizations = new Set<String>();
            Map<String,T_Auth__c> authorizationMap = new Map<String,T_Auth__c>();
            List<T_SBSD_CASE__c> caseList = [select id,(SELECT IDN_EXTNL__c,IDN_PROVR__c,IDN_PROVR__r.Name FROM T_AUTH__r WHERE DTE_BEGIN_EFFV_AUTH__c<=TODAY AND (DTE_END_EFFV_AUTH__c=null OR DTE_END_EFFV_AUTH__c>TODAY)) from T_SBSD_CASE__c WHERE IDN_EXTNL__c = :caseId LIMIT 1];
            Set<String> authIdsHavingAuthCopay = new Set<String>();
            if(caseList.size()>0){
                caseSFid = caseList[0].id;
                system.debug('@@@@@@caseSFid: '+caseSFid);
                for(T_Auth__c auth:caseList[0].T_AUTH__r){
                    caseAuthorizations.add(auth.IDN_EXTNL__c);                    
                }
            }
            for(T_Auth__c auth :[SELECT Name,IDN_EXTNL__c,IDN_PROVR__c,IDN_PROVR__r.Name FROM T_AUTH__c where IDN_CASE__r.IDN_EXTNL__c =:caseId]){
                authorizationMap.put(auth.IDN_EXTNL__c,auth);
            }
            System.debug('Authorizations for this case:'+caseAuthorizations);
            //caseSFid = 'a2T0t000000OMxaEAG'; //sit
            //caseSFid = 'a1Qg0000006gKaCEAU'; //dev
            try{
            Httprequest httpRequest = new Httprequest();
            Http http = new Http();
            httpRequest.setHeader('Content-Type', 'application/json;charset=UTF-8');
            httpRequest.setEndpoint(Label.AuthCopayFetch);
            httpRequest.setMethod('POST');
            String jsonStr = '{"sfid":"'+caseSFid +'"}';
            system.debug('jsonStr----'+jsonStr);
            httpRequest.setBody(jsonStr);
            
            Httpresponse httpResponse = http.send(httpRequest);
            system.debug('httpResponse----'+httpResponse);
            if(httpResponse != null && (httpResponse.getStatusCode() == 202 || httpResponse.getStatusCode() == 200)) {
                String responseBody = httpResponse.getBody();
                List<Object> responseList = (List<Object>)JSON.deserializeUntyped(responseBody);
                system.debug('responseList '+responseBody+'responseList size '+responseList.size());
                if(!responseList.isEmpty()) {
                    for (integer i=0;responseList.size()>i;i++) {
                    	Boolean isAuthInSF = false;
                        Map<String, Object> responseMap = (Map<String, Object>)responseList[i];
                        system.debug('responseMap '+responseMap);
                        ParentFeeAssessmentWrapper wrap = new ParentFeeAssessmentWrapper();
                        
                        wrap.childName = (String)responseMap.get('indivNamLast')+', '+(String)responseMap.get('indivNamFirst');
                        wrap.IDN_AUTH =  (String)responseMap.get('authCopayAuthId');
                        if(String.isNotEmpty(wrap.IDN_AUTH)){
                            caseAuthorizations.remove(wrap.IDN_AUTH);                        
                        }
                        T_Auth__c authObj = authorizationMap.get((String)responseMap.get('authCopayAuthId')); 
                        if(authObj != null){
                        	isAuthInSF = true;
                            wrap.IDN_PROVR =authObj.IDN_PROVR__r.Name;
                            wrap.authName =authObj.Name;
                        }
                        system.debug('eff date: '+responseMap.get('authCopayDteBeginEffectv'));
                        system.debug('responseMap.get--'+responseMap.get('authCopayId'));
                        wrap.authCopayId = (String)responseMap.get('authCopayId');
                        //String todate = '12/27/2013';
                        //Date dt = Date.parse(todate);
                        /*if(responseMap.get('authCopayDteBeginEffectv')!= null) {
wrap.AUTH_Effective_BGN_Date =Date.parse((String)responseMap.get('authCopayDteBeginEffectv'));
system.debug('eff date 1: '+responseMap.get('authCopayDteBeginEffectv'));
} */
                        if(responseMap.get('authCopayDteBeginEffectv')!= null && responseMap.get('authCopayDteBeginEffectv')!= 'null') {
                            Date beginDate1;
                            String beginDate =(String)responseMap.get('authCopayDteBeginEffectv');
                            List<String> dateParts = new List<String>();
                            dateParts= beginDate.split('-');
                            beginDate1 = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                            wrap.AUTH_Effective_BGN_Date =beginDate1;
                        }
                        //wrap.AUTH_Effective_BGN_Date = dt;
                        wrap.CDE_STATUS_AUTH = (String)responseMap.get('cdeAuthStatus');
                        
                        system.debug('wrap.IDN_PROVR---'+wrap.IDN_PROVR);
                        system.debug('IDN_PROVR---'+(String)responseMap.get('authProvrId'));
                        if((String)responseMap.get('namFacility')!= null){
                            wrap.ProviderName = (String)responseMap.get('namFacility');
                        }
                        else{
                            if((String)responseMap.get('provrNamFirst')!= null){
                            	wrap.ProviderName = (String)responseMap.get('provrNamFirst');
                            }
                                
                            if((String)responseMap.get('provrNamFirst')!= null){
                            	wrap.ProviderName+=' '+(String)responseMap.get('provrNamLast');
                            }
                                
                        }
                        wrap.DTE_DOB = (String)responseMap.get('indivDOB');
                        //Double decimalVal = Double.valueOf(responseMap.get('amtCopayAuth'));
                        //system.debug('Number: '+responseMap.get('amtCopayAuth')+' Decimal length: '+(String.valueOf(responseMap.get('amtCopayAuth'))).IsNumeric());
                        try{
                            Integer.valueOf(responseMap.get('amtCopayAuth'));
                            system.debug('Valid num');
                            wrap.AMT_COPAY_AUTH = Integer.valueOf(responseMap.get('amtCopayAuth'));
                        } catch (Exception e) {
                            wrap.AMT_COPAY_AUTH = Integer.valueOf( Decimal.valueOf(String.valueOf(responseMap.get('amtCopayAuth')).replaceAll(',','')).round(System.RoundingMode.DOWN));
                           system.debug('--amount--'+Integer.valueOf( Decimal.valueOf(String.valueOf(responseMap.get('amtCopayAuth')).replaceAll(',','')).round(System.RoundingMode.DOWN)));
                            system.debug('Not a valid num');//wrap.errMsg = 'Invalid existing amount '+String.valueOf(responseMap.get('amtCopayAuth'));
                        }
                        
                        system.debug('Response wrap--->' + wrap);  
                        if(!authId.contains(wrap.IDN_AUTH)){
                            authId.add(wrap.IDN_AUTH);
                            if(wrap.CDE_STATUS_AUTH != '4'){
                                if(isAuthInSF){
                                    wrapList.add(wrap);
                                }
                            }
                        }
                        
                    }
                }
            }
           else {
                            
                 //ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, methodInfo);
            }
            System.debug('Authorizations excluding coming from webservice:'+caseAuthorizations);
            for(batchsit_t_auth_status__x authStatus:[SELECT idn_auth__c FROM batchsit_t_auth_status__x WHERE idn_auth__c IN: caseAuthorizations AND dte_begin_effv__c<=TODAY AND cde_status_auth__c='4']){
                System.debug('authStatus:'+authStatus);
                caseAuthorizations.remove(authStatus.idn_auth__c);
            }
            System.debug('Authorizations after checking their authorization status(Shell Auth):'+caseAuthorizations);
            for(T_AUTH__c auth:[SELECT Name, IDN_EXTNL__c, IDN_CLIENT__c,IDN_CLIENT__r.NAM_LAST__c,
                                IDN_CLIENT__r.NAM_FIRST__c,IDN_PROVR__r.Name, IDN_PROVR__r.NAM_FACILITY__c,
                                IDN_CLIENT__r.DTE_DOB__c,
                                (SELECT cde_status_auth__c FROM batchsit_t_auth_status__r WHERE dte_begin_effv__c<=TODAY ORDER BY dte_begin_effv__c DESC LIMIT 1000)
                                FROM T_AUTH__c WHERE IDN_EXTNL__c IN:caseAuthorizations]){
                                    ParentFeeAssessmentWrapper wrap = new ParentFeeAssessmentWrapper();
                                    if(String.isNotEmpty(auth.IDN_CLIENT__c)){
                                        wrap.childName = auth.IDN_CLIENT__r.NAM_LAST__c+', '+auth.IDN_CLIENT__r.NAM_FIRST__c;
                                        wrap.DTE_DOB = String.valueOf(auth.IDN_CLIENT__r.DTE_DOB__c);
                                    }                
                                    wrap.IDN_AUTH =  auth.IDN_EXTNL__c;
                                    wrap.authName =  auth.Name;
                                    wrap.AUTH_Effective_BGN_Date =System.today();
                                    if(!auth.batchsit_t_auth_status__r.isEmpty()){
                                        System.debug('Checking Auth Status for Shell:'+auth.batchsit_t_auth_status__r);
                                        wrap.CDE_STATUS_AUTH = auth.batchsit_t_auth_status__r.get(0).cde_status_auth__c;
                                    }                                    
                                    wrap.IDN_PROVR = auth.IDN_PROVR__r.Name;
                                    if(String.isNotEmpty(auth.IDN_PROVR__c) && String.isNotEmpty(auth.IDN_PROVR__r.NAM_FACILITY__c)){
                                        wrap.ProviderName = auth.IDN_PROVR__r.NAM_FACILITY__c;
                                    }
                                    /*else{
                                    if((String)responseMap.get('provrNamFirst')!= null)
                                    wrap.ProviderName = (String)responseMap.get('provrNamFirst');
                                    if((String)responseMap.get('provrNamFirst')!= null)
                                    wrap.ProviderName+=' '+(String)responseMap.get('provrNamLast');
                                    }*/
                                    wrap.AMT_COPAY_AUTH = 0;
                                    system.debug('Response wrap--->' + wrap);    
                                    wrapList.add(wrap);
                                }
          } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'AssessParentFeeController','Method__c'=>'AssessParentFeeController'});             
        }                          
        }
        system.debug('@@@@@@@@wrapList: '+wrapList);
        return wrapList;
    }
}