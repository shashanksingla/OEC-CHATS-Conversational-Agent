public class HealthCheckController {
    
    @AuraEnabled
    public static Map<String,Map<String,String>> getWebserviceStatus(){
        
        Map<String,Map<String,String>> healthReportResponse = new Map<String,Map<String,String>>();
        
        Integer devstatus = HealthCheckController.fetchCounty(HealthCheckConstants.COUNTY_ID_DEV,HealthCheckConstants.FETCH_COUNTY_DEV_URL,'POST');
        Integer cistatus = HealthCheckController.fetchCounty(HealthCheckConstants.COUNTY_ID_CI,HealthCheckConstants.FETCH_COUNTY_CI_URL,'POST');
        Integer sitstatus = HealthCheckController.fetchCounty(HealthCheckConstants.COUNTY_ID_SIT,HealthCheckConstants.FETCH_COUNTY_SIT_URL,'POST');
        Integer pltstatus = HealthCheckController.fetchCounty(HealthCheckConstants.COUNTY_ID_PLT,HealthCheckConstants.FETCH_COUNTY_PLT_URL,'POST');
        
        Map<String,String> countyFetchMap = new Map<String,String>();
        countyFetchMap.put('SIT',  String.valueOf(sitstatus));
        countyFetchMap.put('CI',  String.valueOf(cistatus));
        countyFetchMap.put('DEV',  String.valueOf(devstatus));
        countyFetchMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Fetch_County_Records',countyFetchMap);
        
        //fetch Auth copay
        
        devstatus = HealthCheckController.fetchAuthCopay(HealthCheckConstants.CASE_ID_DEV,HealthCheckConstants.FETCH_AUTHCOPAY_DEV_URL,'POST');
        cistatus = HealthCheckController.fetchAuthCopay(HealthCheckConstants.CASE_ID_CI,HealthCheckConstants.FETCH_AUTHCOPAY_CI_URL,'POST');
        sitstatus = HealthCheckController.fetchAuthCopay(HealthCheckConstants.CASE_ID_SIT,HealthCheckConstants.FETCH_AUTHCOPAY_SIT_URL,'POST');
        pltstatus = HealthCheckController.fetchAuthCopay(HealthCheckConstants.CASE_ID_PLT,HealthCheckConstants.FETCH_AUTHCOPAY_PLT_URL,'POST');
        
        
        Map<String,String> authCopayFetchMap = new Map<String,String>();
        authCopayFetchMap.put('SIT',  String.valueOf(sitstatus));
        authCopayFetchMap.put('CI',  String.valueOf(cistatus));
        authCopayFetchMap.put('DEV',  String.valueOf(devstatus));
        authCopayFetchMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Fetch_Auth_Copay_Records',authCopayFetchMap);
        
        
        // Fetch Auth Encmbr
        
        devstatus = HealthCheckController.fetchAuthEncmbr(HealthCheckConstants.AUTH_ID_DEV,HealthCheckConstants.FETCH_FETCH_ENCMBR_DEV_URL,'POST');
        cistatus = HealthCheckController.fetchAuthEncmbr(HealthCheckConstants.AUTH_ID_CI,HealthCheckConstants.FETCH_FETCH_ENCMBR_CI_URL,'POST');
        sitstatus = HealthCheckController.fetchAuthEncmbr(HealthCheckConstants.AUTH_ID_SIT,HealthCheckConstants.FETCH_FETCH_ENCMBR_SIT_URL,'POST');
        pltstatus = HealthCheckController.fetchAuthEncmbr(HealthCheckConstants.AUTH_ID_PLT,HealthCheckConstants.FETCH_FETCH_ENCMBR_PLT_URL,'POST');
        
        Map<String,String> authEncmbrFetchMap = new Map<String,String>();
        authEncmbrFetchMap.put('SIT',  String.valueOf(sitstatus));
        authEncmbrFetchMap.put('CI',  String.valueOf(cistatus));
        authEncmbrFetchMap.put('DEV',  String.valueOf(devstatus));
        authEncmbrFetchMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Fetch_Auth_Encmbr_Records',authEncmbrFetchMap);
        
        
        // Fetch correspondance 
        
        Map<String,String> searchCorrMap = new Map<String,String>();
        searchCorrMap.put('SIT',  HealthCheckController.searchCorr(HealthCheckConstants.COUNTY_NAME,HealthCheckConstants.FETCH_CORR_SIT_URL,'POST'));
        searchCorrMap.put('CI',  HealthCheckController.searchCorr(HealthCheckConstants.COUNTY_NAME,HealthCheckConstants.FETCH_CORR_CI_URL,'POST'));
        searchCorrMap.put('DEV',  HealthCheckController.searchCorr(HealthCheckConstants.COUNTY_NAME,HealthCheckConstants.FETCH_CORR_DEV_URL,'POST'));
        searchCorrMap.put('PLT',  HealthCheckController.searchCorr(HealthCheckConstants.COUNTY_NAME,HealthCheckConstants.FETCH_CORR_PLT_URL,'POST'));
        
        healthReportResponse.put('Corr_Search',searchCorrMap);
        
        
        //update auth status
        
        devstatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_STATUS_UPDATE_JSON,HealthCheckConstants.AUTH_STATUS_UPDATE_DEV_URL,'POST');
        cistatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_STATUS_UPDATE_JSON,HealthCheckConstants.AUTH_STATUS_UPDATE_CI_URL,'POST');
        sitstatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_STATUS_UPDATE_JSON,HealthCheckConstants.AUTH_STATUS_UPDATE_SIT_URL,'POST');
        pltstatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_STATUS_UPDATE_JSON,HealthCheckConstants.AUTH_STATUS_UPDATE_PLT_URL,'POST');
        
        Map<String,String> updateAuthStatusMap = new Map<String,String>();
        updateAuthStatusMap.put('SIT',  String.valueOf(sitstatus));
        updateAuthStatusMap.put('CI',  String.valueOf(cistatus));
        updateAuthStatusMap.put('DEV',  String.valueOf(devstatus));
        updateAuthStatusMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Update_Auth_Status',updateAuthStatusMap);
        
        // update auth copay record 
        
        devstatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_COPAY_UPDATE_JSON,HealthCheckConstants.AUTH_COPAY_UPDATE_DEV_URL,'POST');
        cistatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_COPAY_UPDATE_JSON,HealthCheckConstants.AUTH_COPAY_UPDATE_CI_URL,'POST');
        sitstatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_COPAY_UPDATE_JSON,HealthCheckConstants.AUTH_COPAY_UPDATE_SIT_URL,'POST');
        pltstatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_COPAY_UPDATE_JSON,HealthCheckConstants.AUTH_COPAY_UPDATE_PLT_URL,'POST');
        
        Map<String,String> updateAuthCopayMap = new Map<String,String>();
        updateAuthCopayMap.put('SIT',  String.valueOf(sitstatus));
        updateAuthCopayMap.put('CI',  String.valueOf(cistatus));
        updateAuthCopayMap.put('DEV',  String.valueOf(devstatus));
        updateAuthCopayMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Update_Auth_Copay',updateAuthCopayMap);
        
        
        // update auth encmbr record 
        
        devstatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_ENCMBR_UPDATE_JSON,HealthCheckConstants.AUTH_ENCMB_UPDATE_DEV_URL,'POST');
        cistatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_ENCMBR_UPDATE_JSON,HealthCheckConstants.AUTH_ENCMB_UPDATE_CI_URL,'POST');
        sitstatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_ENCMBR_UPDATE_JSON,HealthCheckConstants.AUTH_ENCMB_UPDATE_SIT_URL,'POST');
        pltstatus = HealthCheckController.checkService(HealthCheckConstants.AUTH_ENCMBR_UPDATE_JSON,HealthCheckConstants.AUTH_ENCMB_UPDATE_PLT_URL,'POST');
        
        Map<String,String> updateEncmbrMap = new Map<String,String>();
        updateEncmbrMap.put('SIT',  String.valueOf(sitstatus));
        updateEncmbrMap.put('CI',  String.valueOf(cistatus));
        updateEncmbrMap.put('DEV',  String.valueOf(devstatus));
        updateEncmbrMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Update_Encmbr_Copay',updateEncmbrMap);
        
        
        // update case copay record 
        
        devstatus = HealthCheckController.checkService(HealthCheckConstants.CASE_COPAY_UPDATE_JSON,HealthCheckConstants.CASE_COPAY_UPDATE_DEV_URL,'POST');
        cistatus = HealthCheckController.checkService(HealthCheckConstants.CASE_COPAY_UPDATE_JSON,HealthCheckConstants.CASE_COPAY_UPDATE_CI_URL,'POST');
        sitstatus = HealthCheckController.checkService(HealthCheckConstants.CASE_COPAY_UPDATE_JSON,HealthCheckConstants.CASE_COPAY_UPDATE_SIT_URL,'POST');
        pltstatus = HealthCheckController.checkService(HealthCheckConstants.CASE_COPAY_UPDATE_JSON,HealthCheckConstants.CASE_COPAY_UPDATE_PLT_URL,'POST');
        
        Map<String,String> caseCopayMap = new Map<String,String>();
        caseCopayMap.put('SIT',  String.valueOf(sitstatus));
        caseCopayMap.put('CI',  String.valueOf(cistatus));
        caseCopayMap.put('DEV',  String.valueOf(devstatus));
        caseCopayMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Update_Case_Copay',caseCopayMap);
        
        // update sub payment detail record
        
        devstatus = HealthCheckController.checkService(HealthCheckConstants.SUB_PYMT_DTL_UPDATE_JSON,HealthCheckConstants.SUB_PYMT_DTL_UPDATE_DEV_URL,'POST');
        cistatus = HealthCheckController.checkService(HealthCheckConstants.SUB_PYMT_DTL_UPDATE_JSON,HealthCheckConstants.SUB_PYMT_DTL_UPDATE_CI_URL,'POST');
        sitstatus = HealthCheckController.checkService(HealthCheckConstants.SUB_PYMT_DTL_UPDATE_JSON,HealthCheckConstants.SUB_PYMT_DTL_UPDATE_SIT_URL,'POST');
        pltstatus = HealthCheckController.checkService(HealthCheckConstants.SUB_PYMT_DTL_UPDATE_JSON,HealthCheckConstants.SUB_PYMT_DTL_UPDATE_PLT_URL,'POST');
        
        Map<String,String> pymtDtlMap = new Map<String,String>();
        pymtDtlMap.put('SIT',  String.valueOf(sitstatus));
        pymtDtlMap.put('CI',  String.valueOf(cistatus));
        pymtDtlMap.put('DEV',  String.valueOf(devstatus));
        pymtDtlMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('UPDATE_PYMT_DTL',pymtDtlMap);
        
        
        
        // Create Auth Encmbr
        
        devstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_AUTH_ENCMBR_JSON,HealthCheckConstants.CREATE_AUTH_ENCMBR_DEV_URL,'POST');
        cistatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_AUTH_ENCMBR_JSON,HealthCheckConstants.CREATE_AUTH_ENCMBR_CI_URL,'POST');
        sitstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_AUTH_ENCMBR_JSON,HealthCheckConstants.CREATE_AUTH_ENCMBR_SIT_URL,'POST');
        pltstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_AUTH_ENCMBR_JSON,HealthCheckConstants.CREATE_AUTH_ENCMBR_PLT_URL,'POST');
        
        Map<String,String> createAuthEncmbrMap = new Map<String,String>();
        createAuthEncmbrMap.put('SIT',  String.valueOf(sitstatus));
        createAuthEncmbrMap.put('CI',  String.valueOf(cistatus));
        createAuthEncmbrMap.put('DEV',  String.valueOf(devstatus));
        createAuthEncmbrMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Create_Auth_Encmbr',createAuthEncmbrMap);
        
        
        
        // Create Auth status
        
        devstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_AUTH_STATUS_JSON,HealthCheckConstants.CREATE_AUTH_STATUS_DEV_URL,'POST');
        cistatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_AUTH_STATUS_JSON,HealthCheckConstants.CREATE_AUTH_STATUS_CI_URL,'POST');
        sitstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_AUTH_STATUS_JSON,HealthCheckConstants.CREATE_AUTH_STATUS_SIT_URL,'POST');
        pltstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_AUTH_STATUS_JSON,HealthCheckConstants.CREATE_AUTH_STATUS_PLT_URL,'POST');
        
        Map<String,String> createAuthStatusMap = new Map<String,String>();
        createAuthStatusMap.put('SIT',  String.valueOf(sitstatus));
        createAuthStatusMap.put('CI',  String.valueOf(cistatus));
        createAuthStatusMap.put('DEV',  String.valueOf(devstatus));
        createAuthStatusMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Create_Auth_Status',createAuthStatusMap);
        
        
        // Create Auth status
        
        devstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_CASE_COPAY_JSON,HealthCheckConstants.CREATE_CASE_COPAY_DEV_URL,'POST');
        cistatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_CASE_COPAY_JSON,HealthCheckConstants.CREATE_CASE_COPAY_CI_URL,'POST');
        sitstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_CASE_COPAY_JSON,HealthCheckConstants.CREATE_CASE_COPAY_SIT_URL,'POST');
        pltstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_CASE_COPAY_JSON,HealthCheckConstants.CREATE_CASE_COPAY_PLT_URL,'POST');
        
        Map<String,String> createCaseCopayMap = new Map<String,String>();
        createCaseCopayMap.put('SIT',  String.valueOf(sitstatus));
        createCaseCopayMap.put('CI',  String.valueOf(cistatus));
        createCaseCopayMap.put('DEV',  String.valueOf(devstatus));
        createCaseCopayMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Create_Case_Copay',createCaseCopayMap);
        
        
        
        // Update Care Level
        
        devstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_CASE_COPAY_JSON,HealthCheckConstants.Update_Care_Lvl_DEV_URL,'POST');
        cistatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_CASE_COPAY_JSON,HealthCheckConstants.Update_Care_Lvl_DEV_URL,'POST');
        sitstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_CASE_COPAY_JSON,HealthCheckConstants.Update_Care_Lvl_DEV_URL,'POST');
        pltstatus = HealthCheckController.checkService(HealthCheckConstants.CREATE_CASE_COPAY_JSON,HealthCheckConstants.Update_Care_Lvl_PLT_URL,'POST');
        
        Map<String,String> updateCareLvlMap = new Map<String,String>();
        updateCareLvlMap.put('SIT',  String.valueOf(sitstatus));
        updateCareLvlMap.put('CI',  String.valueOf(cistatus));
        updateCareLvlMap.put('DEV',  String.valueOf(devstatus));
        updateCareLvlMap.put('PLT',  String.valueOf(pltstatus));
        
        healthReportResponse.put('Update_Care_Lvl',updateCareLvlMap);
        
        
        // Generate Correspondence
          
        Map<String,String> genCorrMap = new Map<String,String>();
        genCorrMap.put('SIT',  HealthCheckController.checkGetService(HealthCheckConstants.GENERATE_CORR_SIT_URL));
        genCorrMap.put('CI',  HealthCheckController.checkGetService(HealthCheckConstants.GENERATE_CORR_CI_URL));
        genCorrMap.put('DEV',  HealthCheckController.checkGetService(HealthCheckConstants.GENERATE_CORR_DEV_URL));
        genCorrMap.put('PLT',  HealthCheckController.checkGetService(HealthCheckConstants.GENERATE_CORR_PLT_URL));
        
        healthReportResponse.put('GenerateCorr',genCorrMap);
        
        system.debug('----main chart----'+healthReportResponse);
        
        Map<String,Map<String,String>> healthResponse = new Map<String,Map<String,String>>(healthReportResponse);
        healthResponse.put('dev_status',getChartData('DEV',healthReportResponse));
        healthResponse.put('ci_status',getChartData('CI',healthReportResponse));
        healthResponse.put('sit_status',getChartData('SIT',healthReportResponse)); 
        healthResponse.put('plt_status',getChartData('PLT',healthReportResponse));  

        return healthResponse;

        
    }
    
    public static Map<String,String> getChartData(String Env ,Map<String,Map<String,String>> heathReportMap){
        
        Map<String,String> statusMap = new Map<String,String>();
        Integer success = 0;
        Integer failure = 0;
        
        for(Map<String,String> inpMap : heathReportMap.values()){
            
            if(inpMap.get(Env)!='200'){
                failure=failure+1;
            }else{
                success=success+1;
            }
          }
        
        statusMap.put('success',String.valueOf(success));
        statusMap.put('failure',String.valueOf(failure));
        
         system.debug('----status  chart----'+statusMap);
        
        return statusMap;
    }
    
    
    public  static Integer fetchCounty(String countyId , String URL, String MethodType){
        Integer responsecode;
        try{
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL);
        request.setMethod(MethodType);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String requestBody = '{"countyId":"'+countyId+'"}';
        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        responsecode=response.getStatusCode();
        if(response !=NULL && response.getStatusCode() != 200){  
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'fetchCounty'});
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'fetchCounty'});             
        } 
        return responsecode;
        
    }
    
    public static Integer fetchAuthCopay(String caseId , String URL, String MethodType){
        Integer responsecode;
        try{
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL);
        request.setMethod(MethodType);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String requestBody = '{"sfid":"'+caseId+'"}';
        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        responsecode=response.getStatusCode();
        if(response !=NULL && response.getStatusCode() != 200){  
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'fetchAuthCopay'});
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'fetchAuthCopay'});             
        } 
        return responsecode;
    }
    
    
    public static Integer fetchAuthEncmbr(String authId , String URL, String MethodType){
        Integer responsecode;
        try{
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL);
        request.setMethod(MethodType);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String requestBody = '{"authId":"'+authId+'"}';
        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        responsecode=response.getStatusCode();
        if(response !=NULL && response.getStatusCode() != 200){  
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'fetchAuthEncmbr'});
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'fetchAuthEncmbr'});             
        } 
        return responsecode;
    }
    
    
    public static String searchCorr(String countyName , String URL, String MethodType){
        
        String responseStatus;
        Httprequest httpRequest = new Httprequest();
        Http http = new Http();
        HttpRequest.setHeader('Content-type', 'application/json');
        HttpRequest.setHeader('Accept', 'application/json');
        httpRequest.setEndpoint(URL); 
        httpRequest.setMethod(MethodType);
        httpRequest.setBody('{"countyName" : "'+countyName+'"}');
        httpRequest.setTimeout(120000);
        try{
            Httpresponse httpResponse = http.send(httpRequest);
            responseStatus = String.valueOf(httpResponse.getStatusCode());
            if(httpresponse !=NULL && httpResponse.getStatusCode() != 200){  
                ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'searchCorr'});
            }
        }catch(System.CalloutException e){
            responseStatus='408';
        }
        
        return responseStatus;
        
    }
    
    public static Integer checkService(String requestJSON , String URL, String MethodType){
        Integer responsecode;
        try{
        Httprequest httpRequest = new Httprequest();
        Http http = new Http();
        HttpRequest.setHeader('Content-type', 'application/json');
        HttpRequest.setHeader('Accept', 'application/json');
        httpRequest.setEndpoint(URL); 
        httpRequest.setMethod(MethodType);
        httpRequest.setBody(requestJSON);
        Httpresponse httpResponse = http.send(httpRequest);
        responsecode=httpResponse.getStatusCode();
        if(httpresponse !=NULL && httpResponse.getStatusCode() != 200){ 
                ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'checkService'});
            }
        }catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'checkService'});             
        }  
        return responsecode;
    }
    
    public static String checkGetService(String URL){
        
        String responseStatus;
        Httprequest httpRequest = new Httprequest();
        Http http = new Http();
        HttpRequest.setHeader('Content-type', 'application/json');
        httpRequest.setEndpoint(URL); 
        httpRequest.setTimeout(120000);
        httpRequest.setMethod('GET');
        try{
            Httpresponse httpResponse = http.send(httpRequest);
            responseStatus = String.valueOf(httpResponse.getStatusCode());
            if(httpresponse !=NULL && httpResponse.getStatusCode() != 200){ 
                ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, new Map<String,Object>{'Class__c'=>'HealthCheckController','Method__c'=>'checkGetService'});
            }
        }
        catch(System.CalloutException e){
            responseStatus = '408';
            
        }
        return responseStatus;
    }
    
    
    
    
}