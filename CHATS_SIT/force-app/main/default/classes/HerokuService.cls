/*
 * 	HerokuService.caseCopyCreate();
	HerokuService.authEncumbranceCreate();
	HerokuService.authEncumbrancefetch();
	HerokuService.authEncumbranceUpdate();
	HerokuService.caseCopyUpdate();

	**Auth Copay**
	HerokuService.authCopayCreate();
	HerokuService.authCopayFetch();
	HerokuService.authCopayFetch(); 
 *
 */
 // Changes
 // 11/03/2020		Balamurugan Chinnaiah	CCCAP-2340: 6MB Heap Size Exceeds
 public class HerokuService {
    public static Set<Date> careDateList{get;set;}
    public static Map<String,Boolean> globalAttended = new Map<String,Boolean>();
     public static boolean isApiSuccess = false;
     public static List<batchsit_t_auth_encmbr__x> authEncumbrancefetchArchived(String authId,String monthStr,string yearStr){
        List<batchsit_t_auth_encmbr__x> lstEncumbranceRecords = new List<batchsit_t_auth_encmbr__x>();
        String method = 'POST';
        try{
            if(monthStr != null ){
                monthStr = string.valueOf((Integer.valueOf(monthStr)+1));
                if(monthStr.length()==1){
                    monthStr = '0'+monthStr;
                }
            }
            String startDateCare =yearStr+'-'+monthStr+'-'+'01';
            Date dateField = Date.newInstance(Integer.valueOf(yearStr), Integer.valueOf(monthStr), 01);
            Integer numberOfDays = Date.daysInMonth(dateField.year(), dateField.month());
            Date lastDayOfMonth = Date.newInstance(dateField.year(), dateField.month(), numberOfDays);
            String endDateCare =lastDayOfMonth.year()+'-'+monthStr+'-'+lastDayOfMonth.day();
            Http http = new Http();
            HttpRequest request = new HttpRequest();
        request.setEndpoint(System.Label.ArchivedAuthEncumbranceFetch);
        //request.setEndpoint('https://chatstranswssitapp.herokuapp.com/ArchivedAuthEncumbrance/FetchRecords');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String jsonStr = '{"authId":"'+authId +'","startDateCare":"'+startDateCare+'","endDateCare":"'+endDateCare+'"}';
        request.setBody(jsonStr);
        Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
        request.setTimeout(timeOutVal);
        //request.setBody('{"authId":"a1fg0000001me0JAAQ"}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbrancefetch'});             
                            
        } else {
                    Map<String,Object>  lst_JsonParse = (Map<String,Object> ) JSON.deserializeUntyped(response.getBody());
            List<Object> enucmbList = (List<Object>)lst_JsonParse.get('archivedAuthEncumbrDetails');
                for(Object obj :enucmbList)
                {
                    Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                    batchsit_t_auth_encmbr__x encumbranceRec = new batchsit_t_auth_encmbr__x();
                    Boolean attended = false;
                    if((String)mp_StrObj.get('errorMessage') == null){     
                        encumbranceRec.cde_Level_Care__c = (String)mp_StrObj.get('careLevel');
                        encumbranceRec.cde_Status_Encmbr__c = (String)mp_StrObj.get('encmbrStatus');
                        encumbranceRec.cde_Type_Unit_Care__c = (String)mp_StrObj.get('careUnitType');
                        encumbranceRec.cnt_Hour_Attnd_Actual__c = Integer.valueOf(mp_StrObj.get('actualAttndHour')) ;
                        encumbranceRec.cnt_Hour_Care__c =Integer.valueOf(mp_StrObj.get('careHour'));
                        encumbranceRec.ind_0_36_months__c = (String)mp_StrObj.get('ind_0_36_months'); //added for CCCAP-14174
                        if(mp_StrObj.get('attendedFlag') != null){
                            String attendedFlg = (String)mp_StrObj.get('attendedFlag');
                            if(attendedFlg.toLowerCase()=='true'){
                                attended = true; 
                            }
                        }
                        
                        encumbranceRec.idn_Auth__c = (String)mp_StrObj.get('authId');
                        encumbranceRec.createdbyid__c = (String)mp_StrObj.get('createdById');
                        // encumbranceRec.createddate__c = (Date)mp_StrObj.get('createddate');
                        // encumbranceRec.createddate__c = DateTime.parse('2018-03-07T23:50:31.000+0000');
                        encumbranceRec.nbr_Seq_Hist__c = Integer.valueOf(mp_StrObj.get('nbrSeqHist'));
                        //  encumbranceRec.lastmodifieddate__c =Date.valueOf(mp_StrObj.get('lastmodifieddate'));
                        encumbranceRec.lastmodifiedbyid__c = (String)mp_StrObj.get(' lastModifiedById');
                        encumbranceRec.ExternalId = (String)mp_StrObj.get('authEncmbrId');
                        globalAttended.put(encumbranceRec.ExternalId,attended); 
                        
                        List<String> dateParts = String.valueOf(mp_StrObj.get('careDate')).split('-');
                        Date dateWithTime = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                        
                        encumbranceRec.dte_care__c = dateWithTime ;
                        lstEncumbranceRecords.add(encumbranceRec);
                    }
                    
                }
            }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbrancefetch'});             
        }
        return lstEncumbranceRecords;
    }
    public static HttpResponse createCareLevelRecords(String body){
         try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(Label.Care_Level_Create_WS);
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            req.setBody(body);
            HttpResponse response = http.send(req);
            return response;
        } catch(Exception ex) {
            System.debug('ex:'+ex);
            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setBody(ex.getMessage());
            return response;
        }
        
    }
    public static void authEncubUpdateCareLevel(){
        try {
        String method = 'POST';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(System.Label.SubpaymentWebService);
        request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthEncumbr/UpdateRecordsForCareLevel');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody('{"idn_Client":"a1Vg0000002khcMEAQ","start_Date_36M":"2012-12-12","start_Date_SA":"2018-01-01"}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncubUpdateCareLevel'});             
        } else {
            //System.debug(response.getBody()); 
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncubUpdateCareLevel'});             
        }
    }
    
    public static void authStatusCreate(){
        try{
        String method = 'POST';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(System.Label.SubpaymentWebService);
        request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthStatus/CreateRecord');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody('{"cde_Reason_Change_Auth":"T","cde_Status_Auth":"T","dte_Begin_Effv":"2019-12-12","dte_End_Effv":"2012-12-12","idn_Auth":"T","nbr_seq_hist": "2","createdbyid": "T","createddate": "2012-12-12 12:12:12","lastmodifieddate":"2012-12-12 12:12:12","lastmodifiedbyid":"salesforce"}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
             ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authStatusCreate'});             

        } else {
            //System.debug(response.getBody());
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authStatusCreate'});             
        }
    }
    
    public static void authCopayCreate(){
        try{
        String method = 'POST';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(System.Label.SubpaymentWebService);
        request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthCopay/CreateRecords');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody('{"amt_copay_auth":"4" , "dte_begin_effv":"2010-12-01", "dte_end_effv":"2010-12-01", "idn_auth":"a1fg0000001mzPX", "createdbyid":"visverma", "createddate":"2018-28-08 09:03:24",  "nbr_seq_hist":"2",  "lastmodifiedbyid":"Salesforce",  "lastmodifieddate":"2018-28-02 09:03:24"}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authCopayCreate'});             

        } else {
            //System.debug(response.getBody());
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authCopayCreate'});             
        }
    }
    
    public static void authCopayFetch(){
        try{
        String method = 'POST';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(System.Label.SubpaymentWebService);
        request.setEndpoint('http://chatstranswssitapp.herokuapp.com/AuthCopay/FetchRecords');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody('{"sfid" :"a2T0t000000OMxaEAG"}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authCopayFetch'});             
             
        } else {
            //System.debug('response-->'+response.getBody());
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authCopayFetch'});             
        }
    }
    
     public static void authCopayUpdate(){
        try{
        String method = 'POST';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(System.Label.SubpaymentWebService);
        request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthCopay/UpdateRecords');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody('[{"idn_copay_auth" : "2","dte_begin_effv":"2010-12-01","amt_copay_auth":"44","lastmodifiedbyid": "vishu" ,"lastmodifieddate" :"2018-28-08 09:03:24"},{"idn_copay_auth" : "7","dte_begin_effv":"2010-12-01","amt_copay_auth":"10","lastmodifiedbyid": "vishu" ,"lastmodifieddate" :"2018-28-08 09:03:24"}]'); 
         HttpResponse response = http.send(request);        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
           ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authCopayUpdate'});             
                         
        } else {
            //System.debug('response-->'+response.getBody());
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authCopayUpdate'});             
        }
    }
    
    public static void authCopayDelete(String authExtId, Date endDate, String lastModifiedById){
        String method = 'POST';
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.AuthCopayDelete);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            String jsonStr = '{"idn_auth":"'+authExtId +'","dte":"'+endDate +'","lastModifiedById":"'+lastModifiedById+'"}';
            request.setBody(jsonStr);
            Integer timeOutVal = Integer.valueOf(System.Label.WebServiceTimeOut);
            request.setTimeout(timeOutVal);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authCopayDelete'});             
                
            } else {
               
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbrancefetch'});             
        }
    }
    
    public static WebserviceResponse authEncumbranceCreate(List<EncumberenceWrapper> lstEncumberenceRecords){        
        WebserviceResponse webServiceWrap = new WebserviceResponse();
        Map<String,Object> methodInfo = new Map<String,Object>();
        String authId;
        methodInfo.put('Class__c','HerokuService');    
        methodInfo.put('Method__c','authEncumbranceCreate'); 
        List<String> lstInsertedExtIds = new List<String>();
        map<Date, String> mapCareDateToExtId = new map<Date, String>();
        String method = 'POST';
        HttpRequest request;
        HttpResponse response;
        try{
            Http http = new Http();
            request = new HttpRequest();
            request.setEndpoint(System.Label.EncumbranceCreate);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            String requestBodyStr ='';
            List<EncumberenceWrapper> lstEncumberenceRecordsTemp = new List<EncumberenceWrapper>();
            if(lstEncumberenceRecords != null){
                for(Integer i=0;i<lstEncumberenceRecords.size();i++){
                    lstEncumberenceRecordsTemp.add(lstEncumberenceRecords[i]);
                    authId = lstEncumberenceRecords[i].idn_Auth;
                    if(String.isBlank(requestBodyStr)){
                        requestBodyStr = requestBodyStr +'['+ JSON.serialize(lstEncumberenceRecords[i]).replaceAll('__c','');
                    }else{
                        requestBodyStr = requestBodyStr +','+ JSON.serialize(lstEncumberenceRecords[i]).replaceAll('__c','');
                    }
                }
            }
            requestBodyStr = requestBodyStr +']';
            if(!String.isBlank(requestBodyStr)){
                request.setBody(requestBodyStr);
            }
            Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
            request.setTimeout(timeOutVal);
            response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                JSONParser parser = JSON.createParser(response.getBody());
                while (parser.nextToken() != null) {
                    if(parser.getText() == 'errorMessage'){
                        parser.nextToken();
                        webServiceWrap.message =parser.getText();
                        webServiceWrap.statusCode =response.getStatusCode();
                        webServiceWrap.isSuccess = false;
                        webServiceWrap.req = request;
                        webServiceWrap.resp = response;
                    }
                }
                if(String.isNotBlank(authId)){
                    methodInfo.put('Record_ID__c',authId); 
                }
                ExceptionLoggingServices.captureExceptionLog(response, request, methodInfo);
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            } else {
                //  ExceptionLoggingServices.captureExceptionLog(response, request, methodInfo);        
                List<Object> lst_JsonParse = (List<Object>) JSON.deserializeUntyped(response.getBody());
                for(Object obj : lst_JsonParse){
                    Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                    String authEncumbIdExt = String.valueOf(mp_StrObj.get('authEncmbrId'));
                    lstInsertedExtIds.add(authEncumbIdExt);

                    List<String> dateParts = String.valueOf(mp_StrObj.get('careDate')).split('-');
                    Date careDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                    mapCareDateToExtId.put(careDate, authEncumbIdExt);
                }
                webServiceWrap.statusCode =response.getStatusCode();
                webServiceWrap.isSuccess = true;
                webServiceWrap.req = request;
                webServiceWrap.resp = response;
                webServiceWrap.lstInsertedExtIds =lstInsertedExtIds;
                webServiceWrap.mapCareDateToExtId = mapCareDateToExtId; 
            }
        } catch(Exception ex) {
            webServiceWrap.isSuccess = FALSE;
            webServiceWrap.message =ex.getMessage();
            webServiceWrap.statusCode = null;
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceCreate'}); 
            //ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceCreate'});           
        }
        return webServiceWrap;
    }
    
    public static void authEncumbranceDelete(String authExtId, Date endDate){        
        String method = 'POST';
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.EncumbranceDelete);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            String jsonStr = '{"authId":"'+authExtId +'","endDate":"'+endDate +'"}';
            request.setBody(jsonStr);
            Integer timeOutVal = Integer.valueOf(System.Label.WebServiceTimeOut);
            request.setTimeout(timeOutVal);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceDelete'});             
                
            } else {
                
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbrancefetch'});             
        }
    }
    
    public static List<batchsit_t_auth_encmbr__x> authEncumbrancefetch(String authId){
        List<batchsit_t_auth_encmbr__x> lstEncumbranceRecords = new List<batchsit_t_auth_encmbr__x>();
        String method = 'POST';
        try{
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(System.Label.EncumbFetch);
        //request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthEncumbr/FetchRecords');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String jsonStr = '{"authId":"'+authId +'"}';
      //  request.setBody('{"authId":'+authId+'}');
        request.setBody(jsonStr);
        Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
        request.setTimeout(timeOutVal);
        //request.setBody('{"authId":"a1fg0000001me0JAAQ"}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbrancefetch'});             
                            
        } else {
                List<Object> lst_JsonParse = (List<Object>) JSON.deserializeUntyped(response.getBody());
                for(Object obj : lst_JsonParse)
                {
                    Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                    batchsit_t_auth_encmbr__x encumbranceRec = new batchsit_t_auth_encmbr__x();
                    Boolean attended = false;
                    if((String)mp_StrObj.get('errorMessage') == null){                       
                        encumbranceRec.cde_Level_Care__c = (String)mp_StrObj.get('cde_Level_Care');
                        encumbranceRec.cde_Status_Encmbr__c = (String)mp_StrObj.get('cde_Status_Encmbr');
                        encumbranceRec.cde_Type_Unit_Care__c = (String)mp_StrObj.get('cde_Type_Unit_Care');
                        encumbranceRec.cnt_Hour_Attnd_Actual__c = Integer.valueOf(mp_StrObj.get('cnt_Hour_Attnd_Actual')) ;
                        encumbranceRec.cnt_Hour_Care__c =Integer.valueOf(mp_StrObj.get('cnt_Hour_Care'));
                        encumbranceRec.ind_0_36_months__c = (String)mp_StrObj.get('ind_0_36_months'); //added for CCCAP-14174
                        if(mp_StrObj.get('attendedFlag') != null){
                            String attendedFlg = (String)mp_StrObj.get('attendedFlag');
                            if(attendedFlg.toLowerCase()=='true'){
                                attended = true; 
                            }
                        }
                        
                        encumbranceRec.idn_Auth__c = (String)mp_StrObj.get('idn_Auth');
                        encumbranceRec.createdbyid__c = (String)mp_StrObj.get('createdbyid');
                        // encumbranceRec.createddate__c = (Date)mp_StrObj.get('createddate');
                        // encumbranceRec.createddate__c = DateTime.parse('2018-03-07T23:50:31.000+0000');
                        encumbranceRec.nbr_Seq_Hist__c = Integer.valueOf(mp_StrObj.get('nbr_Seq_Hist'));
                        //  encumbranceRec.lastmodifieddate__c =Date.valueOf(mp_StrObj.get('lastmodifieddate'));
                        //made below changes for CCCAP-9353 by SS
                        String lastmodifiedby = (String)mp_StrObj.get('lastmodifiedbyid');
                        if(lastmodifiedby!=null && (lastmodifiedby.length() == 15 || lastmodifiedby.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', lastmodifiedby)){
                        	encumbranceRec.lastmodifiedbyid__c = (String)mp_StrObj.get('lastmodifiedbyid');    
                        }
                        encumbranceRec.ExternalId = (String)mp_StrObj.get('idn_Encmbr_Auth');
                        globalAttended.put(encumbranceRec.ExternalId,attended); 
                        
                        List<String> dateParts = String.valueOf(mp_StrObj.get('dte_Care')).split('-');
                        Date dateWithTime = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                        
                        encumbranceRec.dte_care__c = dateWithTime ;
                        lstEncumbranceRecords.add(encumbranceRec);
                    }
                    
                }
            }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbrancefetch'});             
        }
        return lstEncumbranceRecords;
    }

    //removed as part of CCCAP-14174
    /*public static WebserviceResponse authEncumbranceEnrollCreate(List<EncumbranceEnrollWrapper> lstEncumberenceRecords){        
        WebserviceResponse webServiceWrap = new WebserviceResponse();
        Map<String,Object> methodInfo = new Map<String,Object>();
        String authId;
        methodInfo.put('Class__c','HerokuService');    
        methodInfo.put('Method__c','authEncumbranceEnrollCreate'); 
        List<String> lstInsertedExtIds = new List<String>();
        String method = 'POST';
        HttpRequest request;
        HttpResponse response;
        try{
            Http http = new Http();
            request = new HttpRequest();
            request.setEndpoint(System.Label.EncumbranceEnrollCreate);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            String requestBodyStr = '';
            List<EncumbranceEnrollWrapper> lstEncumberenceRecordsTemp = new List<EncumbranceEnrollWrapper>();
            system.debug('lstEncumberenceRecords--'+lstEncumberenceRecords.size());
            if(lstEncumberenceRecords != null){
                for(Integer i=0;i<lstEncumberenceRecords.size();i++){
                    lstEncumberenceRecordsTemp.add(lstEncumberenceRecords[i]);
                    authId = lstEncumberenceRecords[i].authId;
                    if(String.isBlank(requestBodyStr)){
                        requestBodyStr = requestBodyStr +'['+ JSON.serialize(lstEncumberenceRecords[i]).replaceAll('__c','');
                    }else{
                        requestBodyStr = requestBodyStr +','+ JSON.serialize(lstEncumberenceRecords[i]).replaceAll('__c','');
                    }
                }
            }
            requestBodyStr = requestBodyStr +']';
            if(!String.isBlank(requestBodyStr)){
                request.setBody(requestBodyStr);
            }
            system.debug('JSONGenerated--->'+requestBodyStr);
            system.debug('request------>'+request);
            Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
            request.setTimeout(timeOutVal);
            response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                JSONParser parser = JSON.createParser(response.getBody());
                while (parser.nextToken() != null) {
                    system.debug('parser.nextToken()--'+parser.getText());
                    if(parser.getText() == 'errorMessage'){
                        parser.nextToken();
                        webServiceWrap.message = parser.getText();
                        webServiceWrap.statusCode = response.getStatusCode();
                        webServiceWrap.isSuccess = false;
                        webServiceWrap.req = request;
                        webServiceWrap.resp = response;
                        system.debug('message1 authEncumbranceEnrollCreate---'+parser.getText());
                    }
                }
                if(String.isNotBlank(authId)){
                    methodInfo.put('Record_ID__c', authId); 
                }
                ExceptionLoggingServices.captureExceptionLog(response, request, methodInfo);
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            } else {
                System.debug(response.getBody());
                List<Object> lst_JsonParse = (List<Object>) JSON.deserializeUntyped(response.getBody());
                for(Object obj : lst_JsonParse){
                    Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                    system.debug('mp_StrObj--'+mp_StrObj);
                    String authEncumbEnrollIdExt = String.valueOf(mp_StrObj.get('authEncmbrEnrollId'));
                    system.debug('authEncumbEnrollIdExt---'+authEncumbEnrollIdExt);
                    lstInsertedExtIds.add(authEncumbEnrollIdExt);
                }
                webServiceWrap.statusCode = response.getStatusCode();
                webServiceWrap.isSuccess = true;
                webServiceWrap.req = request;
                webServiceWrap.resp = response;
                webServiceWrap.lstInsertedExtIds = lstInsertedExtIds;
                
            }
            system.debug('lstInsertedExtIds---'+lstInsertedExtIds);
        } catch(Exception ex) {
            webServiceWrap.isSuccess = FALSE;
            webServiceWrap.message = ex.getMessage();
            webServiceWrap.statusCode = null;
            system.debug('Exception occured--'+webServiceWrap);
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceEnrollCreate'}); 
        }
        return webServiceWrap;
    }*/
    
    //removed as part of CCCAP-14174
    /*public static List<batchsit_t_auth_encmbr_enroll__x> authEncumbranceEnrollfetch(String authId){
        List<batchsit_t_auth_encmbr_enroll__x> lstEncumbranceEnrollRecords = new List<batchsit_t_auth_encmbr_enroll__x>();
        String method = 'GET';
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.EncumbEnrollFetch+'/'+authId);
            //request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/authencumbrenroll/fetch/{authId}');
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            //String jsonStr = '{"authId":"'+authId +'"}';
            //system.debug('jsonStr----'+jsonStr);
            //request.setBody('{"authId":'+authId+'}');
            //request.setBody(jsonStr);
            Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
            request.setTimeout(timeOutVal);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceEnrollfetch'});                                         
            } else {
                List<Object> lst_JsonParse = (List<Object>) JSON.deserializeUntyped(response.getBody());
                for(Object obj : lst_JsonParse){
                    Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                    batchsit_t_auth_encmbr_enroll__x encumbranceEnrollRec = new batchsit_t_auth_encmbr_enroll__x();
                    if((String)mp_StrObj.get('errorMessage') == null){
                        system.debug('Inside If');
                        encumbranceEnrollRec.idn_encmbr_auth__c = (String)mp_StrObj.get('authEncmbrId');
                        encumbranceEnrollRec.ind_0_36_months__c = (String)mp_StrObj.get('ind_0_36_months');
                        lstEncumbranceEnrollRecords.add(encumbranceEnrollRec);
                    }
                    
                }
            }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceEnrollfetch'});             
        }
        return lstEncumbranceEnrollRecords;
    }*/
    
    //removed as part of CCCAP-14174
    /*public static void authEncumbranceEnrollDelete(String authExtId, Date endDate){        
        String method = 'DELETE';
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            String authEndDate = String.valueOf(endDate);
            request.setEndpoint(System.Label.EncumbranceEnrollDelete+'/'+authExtId+'?careEndDate='+authEndDate);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            //String jsonStr = '{"authId":"'+authExtId +'","endDate":"'+endDate +'"}';
            //request.setBody(jsonStr);
            Integer timeOutVal = Integer.valueOf(System.Label.WebServiceTimeOut);
            request.setTimeout(timeOutVal);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceEnrollDelete'});                             
            } else {                
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceEnrollDelete'});             
        }
    }*/
    
    public  static Map<String, String> authEncumbranceUpdate(String jSONEncumbRec){
        Map<String, String> mapJsonParse= new Map<String, String>();
        String method = 'POST';
        try{
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(System.Label.IndividualCareLevelUpdate);
        //request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthEncumbr/UpdateRecord');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(jSONEncumbRec);  
        Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
        request.setTimeout(timeOutVal);
        //request.setBody('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');  
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            //System.debug('The status code returned was not expected: ' +
                         //response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            mapJsonParse.put('success', 'false');
            mapJsonParse.put('message', response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceUpdate'});             
            isApiSuccess = false;
            return mapJsonParse;
            
        } else {
            //System.debug(response.getBody());
            List<Object> lst_JsonParse = (List<Object>) JSON.deserializeUntyped(response.getBody());
            for(Object obj : lst_JsonParse)
            {
                Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                String authEncumbIdExt = String.valueOf(mp_StrObj.get('authEncmbrId'));
                mapJsonParse.put('authEncmbrId',(String)mp_StrObj.get('authEncmbrId'));
                mapJsonParse.put('errorMessage', String.valueOf(mp_StrObj.get('errorMessage')));
                mapJsonParse.put('successInd', String.valueOf(mp_StrObj.get('successInd')));
                
            }
            isApiSuccess = true;
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbranceUpdate'});             
        	isApiSuccess =false;
        }
        return mapJsonParse;
    }
    
    @future(callout=true)
    Public static void subPaymentService(Set<String> subPaymentDetailIdList, String adjstmentType){
        //Removed unused variable on 5/13/2018 BG  
        String method = 'POST';
        try{
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(System.Label.SubpaymentWebService);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        
        //Removed unused variable on 5/13/2018 BG  
        map<string, object> mapToSerialize;
        string jsonstring=null;
        for(String subPaymentDetailId : subPaymentDetailIdList){
            mapToSerialize = new map<string, object>();
            mapToSerialize.put('recId', subPaymentDetailId);
            mapToSerialize.put('lastModifiedById', Userinfo.getUserId());
            mapToSerialize.put('lastModifiedDate', system.now().format('yyyy-MM-dd HH:mm:ss'));
            if(jsonstring==null){
                jsonstring = JSON.serialize(mapToSerialize);
            }else {
                jsonstring += ','+JSON.serialize(mapToSerialize);
            }
        }
        
        String dataBody = '{"subPaymtDtlId":['+jsonstring+'],"adjType":"'+adjstmentType+'"}';
        
        // Set the body as a JSON object
        request.setBody(dataBody);
        HttpResponse response = http.send(request);
        // Parse the JSON response
         if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'subPaymentService'});             
                         
        } else {
            //System.debug('Working:'+response.getBody());
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'subPaymentService'});             
        }
    }
    public static HttpResponse caseCopyCreate(String amt_Copay_Case_Assesd, String amt_Copay_Case_Ft, String amt_Copay_Case_Pt,
                                     String cde_Reason_Ovrd, String cde_Rec_Copay,
                                     String dte_Begin_Effv, String dte_End_Effv,
                                     String idn_Case, String nbr_Seq_Hist,
                                     String amt_Copay_Case_Ft_Qlty,  String amt_Copay_Case_Pt_Qlty, String ind_Qlty,Boolean isDeleteAuthCopay){
        String method = 'POST';
        HttpResponse response;
        try{
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(System.Label.SubpaymentWebService);
        request.setEndpoint(System.Label.Case_Copay_Web_Service_Create);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        //request.setBody('{"amt_Copay_Case_Assesd":"1", "amt_Copay_Case_Ft":"1","amt_Copay_Case_Pt":"1", "cde_Reason_Ovrd":"R","cde_Rec_Copay":"R",  "dte_Begin_Effv":"2012-12-12",  "dte_End_Effv":"2012-12-12",  "idn_Case":"621003857" ,  "nbr_Seq_Hist":"1",  "lastmodifiedbyid":"sahil"  ,  "lastmodifieddate":"2012-12-12 12:12:12"  ,  "createdbyid":"sahil"  ,  "createddate":"2012-12-12 12:12:12"  ,  "amt_Copay_Case_Ft_Qlty":"1" ,  "amt_Copay_Case_Pt_Qlty":"4" , "ind_Qlty":"Y"}');

		String bodyStr = '{';                                         
        if(amt_Copay_Case_Assesd!=null){
			bodyStr+= '"amt_Copay_Case_Assesd":"'+String.valueOf(amt_Copay_Case_Assesd)+'",';                                                    
        }                                         
        if(amt_Copay_Case_Ft!=null){
			bodyStr+= '"amt_Copay_Case_Ft":"'+String.valueOf(amt_Copay_Case_Ft)+'",';                                                    
        }                                         
        if(amt_Copay_Case_Pt!=null){
			bodyStr+= '"amt_Copay_Case_Pt":"'+String.valueOf(amt_Copay_Case_Pt)+'",';                                                    
        }              
        if(String.isNotEmpty(cde_reason_ovrd)){
			bodyStr+= '"cde_Reason_Ovrd":"'+cde_reason_ovrd+'",';                                                    
        }                                         
        if(String.isNotEmpty(cde_Rec_Copay)){
			bodyStr+= '"cde_Rec_Copay":"'+cde_Rec_Copay+'",';                                                    
        }                                         
        if(String.isNotEmpty(dte_Begin_Effv)){
			bodyStr+= '"dte_Begin_Effv":"'+dte_Begin_Effv+'",';                                                    
        }                                         
        if(String.isNotEmpty(idn_Case)){
			bodyStr+= '"idn_Case":"'+idn_Case+'",';                                                    
        }                                         
        if(String.isNotEmpty(nbr_Seq_Hist)){
			bodyStr+= '"nbr_Seq_Hist":"'+nbr_Seq_Hist+'",';                                                    
        }    
        if(isDeleteAuthCopay){
                bodyStr+='"isDeleteAuthCopay":"'+isDeleteAuthCopay+'",';
            }                                     
	
        bodyStr+= '"lastmodifiedbyid":"'+UserInfo.getUserId()+'",';                                                    
        
        bodyStr+= '"lastmodifieddate":"'+System.now()+'",';                                                    

  		bodyStr+= '"createdbyid":"'+UserInfo.getUserId()+'",';                                                    
                                         
  		bodyStr+= '"createddate":"'+System.now()+'",';                                                    

        if(String.isNotEmpty(amt_Copay_Case_Ft_Qlty)){
			bodyStr+= '"amt_Copay_Case_Ft_Qlty":"'+amt_Copay_Case_Ft_Qlty+'",';                                                    
        }                                         

        if(String.isNotEmpty(amt_Copay_Case_Ft_Qlty)){
			bodyStr+= '"amt_Copay_Case_Pt_Qlty":"'+amt_Copay_Case_Pt_Qlty+'",';                                                    
        }                                         

        if(String.isNotEmpty(ind_Qlty)){
			bodyStr+= '"ind_Qlty":"'+ind_Qlty+'",';                                                    
        }          
        bodyStr = bodyStr.removeEnd(',');
		bodyStr+='}';                                         
                                         
		request.setBody(bodyStr);                                         
       /* request.setBody('{"amt_Copay_Case_Assesd":"'+String.valueOf(amt_Copay_Case_Assesd)+'", "amt_Copay_Case_Ft":"'+String.valueOf(amt_Copay_Case_Ft)+
                        '","amt_Copay_Case_Pt":"'+amt_Copay_Case_Pt+'", "cde_Reason_Ovrd":"'+cde_Reason_Ovrd+
                        '","cde_Rec_Copay":"'+cde_Rec_Copay+'",  "dte_Begin_Effv":"'+dte_Begin_Effv+
                        '",  "idn_Case":"'+idn_Case+
                        '",  "nbr_Seq_Hist":"'+nbr_Seq_Hist+'",  "lastmodifiedbyid":"'+ UserInfo.getUserId() +'", "lastmodifieddate":"'+Date.today()  +
                        '",  "createdbyid":"'+ UserInfo.getUserId() +'",  "createddate":"'+Date.today()  +'",  "amt_Copay_Case_Ft_Qlty":"'+amt_Copay_Case_Ft_Qlty+
                        '",  "amt_Copay_Case_Pt_Qlty":"'+amt_Copay_Case_Pt_Qlty +'", "ind_Qlty":"'+ind_Qlty+'"}');
		*/
		response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
               ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'caseCopyCreate'});            
        } else {
            //System.debug(response.getBody());
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'caseCopyCreate'});             
        }
        return response;
    }
    public static HttpResponse caseCopyUpdate(String amt_Copay_Case_Assesd, String amt_Copay_Case_Ft, String amt_Copay_Case_Pt,
                                     String cde_Reason_Ovrd, String cde_Rec_Copay,
                                     String dte_Begin_Effv, String dte_End_Effv,
                                     String idn_Case, String nbr_Seq_Hist,
                                     String amt_Copay_Case_Ft_Qlty,  String amt_Copay_Case_Pt_Qlty, String ind_Qlty, String externalId){
        
        String method = 'POST';
        HttpResponse response;
        try{
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(System.Label.SubpaymentWebService);
        request.setEndpoint(System.Label.Case_Copay_Web_Service_Update);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
		//String endDate = String.isNotEmpty(dte_End_Effv)?'",  "dte_End_Effv":"'+dte_End_Effv:'';
		String bodyStr = '{';                                         
        if(String.isNotEmpty(amt_Copay_Case_Assesd)){
			bodyStr+= '"amt_Copay_Case_Assesd":"'+String.valueOf(amt_Copay_Case_Assesd)+'",';                                                    
        }                                         
        if(amt_Copay_Case_Ft!=null){
			bodyStr+= '"amt_Copay_Case_Ft":"'+String.valueOf(amt_Copay_Case_Ft)+'",';                                                    
        }                                         
        if(amt_Copay_Case_Pt!=null){
			bodyStr+= '"amt_Copay_Case_Pt":"'+String.valueOf(amt_Copay_Case_Pt)+'",';                                                    
        }                     
        if(String.isNotEmpty(cde_reason_ovrd)){
			bodyStr+= '"cde_Reason_Ovrd":"'+cde_reason_ovrd+'",';                                                    
        }                                         
        if(String.isNotEmpty(cde_Rec_Copay)){
			bodyStr+= '"cde_Rec_Copay":"'+cde_Rec_Copay+'",';                                                    
        }                                         
        if(String.isNotEmpty(dte_Begin_Effv)){
			bodyStr+= '"dte_Begin_Effv":"'+dte_Begin_Effv+'",';                                                    
        } 
        if(String.isNotEmpty(dte_End_Effv)){
			bodyStr+= '"dte_End_Effv":"'+dte_End_Effv+'",';                                                    
        }                                         
        if(String.isNotEmpty(idn_Case)){
			bodyStr+= '"idn_Case":"'+idn_Case+'",';                                                    
        }                                         
        if(String.isNotEmpty(nbr_Seq_Hist)){
			bodyStr+= '"nbr_Seq_Hist":"'+nbr_Seq_Hist+'",';                                                    
        }                                         
	
        bodyStr+= '"lastmodifiedbyid":"'+UserInfo.getUserId()+'",';                                                    
        
        bodyStr+= '"lastmodifieddate":"'+System.now()+'",';                                                    

  		bodyStr+= '"createdbyid":"'+UserInfo.getUserId()+'",';                                                    
                                         
  		bodyStr+= '"createddate":"'+System.now()+'",';                                                    

        if(String.isNotEmpty(amt_Copay_Case_Ft_Qlty)){
			bodyStr+= '"amt_Copay_Case_Ft_Qlty":"'+amt_Copay_Case_Ft_Qlty+'",';                                                    
        }                                         

        if(String.isNotEmpty(amt_Copay_Case_Ft_Qlty)){
			bodyStr+= '"amt_Copay_Case_Pt_Qlty":"'+amt_Copay_Case_Pt_Qlty+'",';                                                    
        }                                         

        if(String.isNotEmpty(ind_Qlty)){
			bodyStr+= '"ind_Qlty":"'+ind_Qlty+'",';                                                    
        }          
		
		bodyStr+= '"idn_Sbsd_Case_Copay":"'+externalId+'"';                                         
                                         
        bodyStr = bodyStr.removeEnd(',');
		bodyStr+='}';                                         
                                         
		request.setBody(bodyStr);                                         
                                         
        //request.setBody('{ "amt_Copay_Case_Assesd":"10" ,"amt_Copay_Case_Ft":"1","amt_Copay_Case_Pt":"1","cde_Reason_Ovrd":"R","cde_Rec_Copay":"R","dte_Begin_Effv":"2012-12-12","dte_End_Effv":"2012-12-12","idn_Case":"14" ,"nbr_Seq_Hist":"1","lastmodifiedbyid":"sahilnew","lastmodifieddate":"2012-12-12 12:12:12","amt_Copay_Case_Ft_Qlty":"1" ,"amt_Copay_Case_Pt_Qlty":"1" ,"ind_Qlty":"Y","idn_Sbsd_Case_Copay":"11"}');  
        /*request.setBody('{"amt_Copay_Case_Assesd":"'+String.valueOf(amt_Copay_Case_Assesd)+'", "amt_Copay_Case_Ft":"'+String.valueOf(amt_Copay_Case_Ft)+
                        '","amt_Copay_Case_Pt":"'+String.valueOf(amt_Copay_Case_Pt)+'", "cde_Reason_Ovrd":"'+cde_Reason_Ovrd+
                        '","cde_Rec_Copay":"'+cde_Rec_Copay+'",  "dte_Begin_Effv":"'+dte_Begin_Effv+
                        '",  "idn_Case":"'+idn_Case+ endDate+
                        '",  "nbr_Seq_Hist":"'+nbr_Seq_Hist+'",  "lastmodifiedbyid":"'+ UserInfo.getUserId() +'", "lastmodifieddate":"'+Date.today()  +
                        '",  "createdbyid":"'+ UserInfo.getUserId() +'",  "createddate":"'+Date.today()  +'",  "amt_Copay_Case_Ft_Qlty":"'+amt_Copay_Case_Ft_Qlty+
                        '",  "amt_Copay_Case_Pt_Qlty":"'+amt_Copay_Case_Pt_Qlty +'", "ind_Qlty":"'+ind_Qlty+'", "idn_Sbsd_Case_Copay":"'+externalId+'"}');
		*/
		 response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
      // ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'caseCopyUpdate'});            
  
        } else {
            //System.debug(response.getBody());
        }
        } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'caseCopyUpdate'});             
        }
        return response;
    }
    public static WebserviceResponse updateCaseParentFee(String providerId){
        // Parse the JSON response
        WebserviceResponse wsr = new WebserviceResponse();
        try{
        String method = 'POST';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(System.Label.parentFeeUpdateURL);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
		String bodyStr = '{ "providerId":"'+providerId+'" }';                                         
        request.setBody(bodyStr);
        HttpResponse response;
        if(!test.isRunningTest()){
            response = http.send(request);
        }else{
            HttpMockCallOutUpdateParentFee mock = new HttpMockCallOutUpdateParentFee();
            response =mock.respond(request) ;
        }
        
        
        wsr.statusCode = response.getStatusCode();
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            wsr.isSuccess= false;
            wsr.message= response.getStatus()+' '+response.getBody();
            ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'updateCaseParentFee'});            
        } else {
            //System.debug(response.getBody());
            wsr.isSuccess= true;
            wsr.message='Success!';
        }
        } catch(Exception ex) {ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'updateCaseParentFee'});             
        }
        return wsr;
    }
    
    public class FiscalRateResponse {
        public string name;
	    public string cde_Age_Group;
	    public string cde_Care_Unit;
	    public string amt_Cty;
	    public string amt_Fa;
	    public string amt_Provr;
	    public string cde_Rate_Type;
	    public string idn_Fiscal_Sch;
	    public string idn_Fiscal_Rate;
	    public string lastmodifiedbyid;
	    public string lastmodifieddate;
	    public string createdbyid;
	    public string createddate;
	    public string errorMessage;
	    public string dte_Begin_Effv;
	    public string dte_End_Effv;
	    public string dte_End_Agrmt;
	    public string dte_Begin_Agrmt;
    }
    
    public static List<FiscalRateWrapper> fiscalRatefetch(List<String> fiscalScheduleIdLst){
        List<FiscalRateWrapper> fiscalRateWrapList = new List<FiscalRateWrapper>();
        String method = 'POST';
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.FiscalRateFetch);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            List<String> lstFiscalScheduleExtId = new List<String>();
            for(T_FISCAL_SCH__c rateSchedule : [Select IDN_EXTNL__c from T_FISCAL_SCH__c where id in:fiscalScheduleIdLst ]){
                lstFiscalScheduleExtId.add(rateSchedule.IDN_EXTNL__c);
            }
            String jsonStr = fiscalSchJsonString(lstFiscalScheduleExtId);
            lstFiscalScheduleExtId.clear();		// CCCAP-2340: Free Memory
            request.setBody(jsonStr);
            jsonStr = null;		// CCCAP-2340: Free Memory					
            Integer timeOutVal = Integer.valueOf(System.Label.WebServiceTimeOut);
            request.setTimeout(timeOutVal);
            timeOutVal = null;		// CCCAP-2340: Free Memory
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'fiscalRatefetch'});             
                
            } else {
            	request = null; 	// CCCAP-2340: Free Memory
                System.debug('The status code returned was expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                List<FiscalRateResponse> FiscalRateResponses = (List<FiscalRateResponse>) JSON.deserialize(response.getBody(), List<FiscalRateResponse>.class);
                response = null;	// CCCAP-2340: Free Memory
                
                for(FiscalRateResponse obj : FiscalRateResponses)
                {
                    FiscalRateWrapper fiscalRateWrap = new FiscalRateWrapper();
                    
		            if(obj.errorMessage == null) {
		                if(obj.name != null) { 
		                    fiscalRateWrap.name = obj.name; 
		                }
		                if(obj.cde_Age_Group != null) {
		                	fiscalRateWrap.ageGroup = obj.cde_Age_Group; 
		                }
		                if(obj.cde_Care_Unit != null) { 
		                    fiscalRateWrap.careUnit = obj.cde_Care_Unit; 
						}
		                if(obj.amt_Cty != null) { 
		                    fiscalRateWrap.countyCeilingAmount = Decimal.valueOf(obj.amt_Cty.replaceAll(',','')).setScale(2); 
		                }
		                if(obj.amt_Fa != null) { 
		                    fiscalRateWrap.fiscalRateAmount = Decimal.valueOf(obj.amt_Fa.replaceAll(',','')).setScale(2); 
		                }
		                if(obj.amt_Provr != null) { 
		                    fiscalRateWrap.providerRateAmount = Decimal.valueOf(obj.amt_Provr.replaceAll(',','')).setScale(2);
						}
		                if(obj.cde_Rate_Type != null) { 
		                    fiscalRateWrap.rateType = obj.cde_Rate_Type; 
		                }
		                if(obj.idn_Fiscal_Sch != null) { 
		                    fiscalRateWrap.idnFiscalSchedule = obj.idn_Fiscal_Sch; 
		                }
		                if(obj.idn_Fiscal_Rate != null) { 
		                    fiscalRateWrap.idnFiscalRate = Integer.valueOf(obj.idn_Fiscal_Rate);
		                }
		                if(obj.lastmodifiedbyid != null) { 
		                    fiscalRateWrap.lastModifiedByUserId = obj.lastmodifiedbyid; 
		                }
		                if(obj.lastmodifieddate != null) { 
		                    fiscalRateWrap.lastModifiedDate = convertDateTimeStrJSONToDateTime(obj.lastmodifieddate); 
		                }
		                if(obj.createdbyid != null) { 
		                    fiscalRateWrap.createdByUserId = obj.createdbyid; 
		                }
		                if(obj.createddate != null) { 
		                    fiscalRateWrap.createdDate = convertDateTimeStrJSONToDateTime(obj.createddate); 
		                }
		                if(obj.dte_Begin_Agrmt != null) { 
		                    fiscalRateWrap.fiscalAgreeBeginDate = convertDateJSONToDate(obj.dte_Begin_Agrmt); 
		                }
		                if(obj.dte_End_Agrmt != null) { 
		                    fiscalRateWrap.fiscalAgreeEndDate = convertDateJSONToDate(obj.dte_End_Agrmt); 
		                }
		                if(obj.dte_Begin_Effv != null) { 
		                    fiscalRateWrap.rateSchBeginDate = convertDateJSONToDate(obj.dte_Begin_Effv); 
		                }
		                if(obj.dte_End_Effv != null) { 
		                    fiscalRateWrap.rateSchEndDate = convertDateJSONToDate(obj.dte_End_Effv); 
		                }
		                fiscalRateWrapList.add(fiscalRateWrap);
		            }
		            obj = null;
		            fiscalRateWrap= null;
                }
                FiscalRateResponses.clear();
            }
        } catch(Exception ex) {ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'fiscalRatefetch'});             
        }
        return fiscalRateWrapList;
    }
    public static String fiscalSchJsonString(List<String> fiscalScheduleIdLst){
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for(String sc :fiscalScheduleIdLst){
            gen.writeStartObject();
            gen.writeStringField('idn_fiscal_Sch',sc);
            gen.writeEndObject();
        }
        gen.writeEndArray();
        String fiscalSchString = gen.getAsString();
        return fiscalSchString;
    }
     public static Date convertDateJSONToDate(String dateJSON){
        Date convertedDate;
        try{
            if(String.isNotEmpty(dateJSON)){
                String[] dateComponents = dateJSON.split('-');
                convertedDate = Date.newInstance(Integer.valueOf(dateComponents[0]), Integer.valueOf(dateComponents[1]), Integer.valueOf(dateComponents[2]));
            }
        }catch(Exception ex){System.debug(ex.getLineNumber()+':'+ex.getMessage());
        }
        return convertedDate;
    }
    public static DateTime convertDateJSONToDateTime(String dateJSON){
        DateTime convertedDateTime;
        try{
            if(String.isNotEmpty(dateJSON)){
                String[] dateComponents = dateJSON.split('-');
                convertedDateTime = DateTime.newInstance(Integer.valueOf(dateComponents[0]), Integer.valueOf(dateComponents[1]), Integer.valueOf(dateComponents[2]));
            }
        }catch(Exception ex){System.debug(ex.getLineNumber()+':'+ex.getMessage());
        }
        return convertedDateTime;
    }
    public static DateTime convertDateTimeStrJSONToDateTime(String dateJSON){
    	// 2019-06-28 19:49:33.0
        DateTime convertedDateTime;
        try{
            if(String.isNotEmpty(dateJSON)){
                String[] dateComponents = dateJSON.split('-');
                Integer year = Integer.valueOf(dateComponents[0]);
                Integer month = Integer.valueOf(dateComponents[1]); 
                String[] timeComponent = dateComponents[2].split(' ');
                Integer datte = Integer.valueOf(timeComponent[0]);
                String[] secminComponent = timeComponent[1].split(':');
                Integer hours = Integer.valueOf(secminComponent[0]);
                Integer mins = Integer.valueOf(secminComponent[1]);
                Integer secs = Integer.valueOf(secminComponent[2]);
                convertedDateTime = DateTime.newInstanceGMT(year, month, datte, hours, mins, secs);
            }
        }catch(Exception ex){System.debug(ex.getLineNumber()+':'+ex.getMessage());
        }
        return convertedDateTime;
    }
    public static WebserviceResponse createFiscalRateRecords(List<batchsit_t_fiscal_rate__x>lstFiscalRates){
        String method = 'POST';
        List<batchsit_t_fiscal_rate__x> lstFiscalRatesCreated = new List<batchsit_t_fiscal_rate__x>();
        WebserviceResponse wsr = new WebserviceResponse(); 
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.fiscalRateCreate);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            String jsonStr = generateFiscalRateJSON(lstFiscalRates);
            request.setBody(jsonStr);
            request.setTimeout(Integer.valueOf(System.Label.FiscalWebServiceTimeOut));
            HttpResponse response = http.send(request);
            // Parsing the JSON response
            if(response !=NULL && response.getStatusCode() == 200){
                wsr.isSuccess = true;
                List<Object> lst_JsonParse = (List<Object>) JSON.deserializeUntyped(response.getBody());
                for(Object obj : lst_JsonParse)
                {
                    Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                    batchsit_t_fiscal_rate__x fiscalRate = new batchsit_t_fiscal_rate__x();
                    if((String)mp_StrObj.get('errorMessage') == null){
                        if(mp_StrObj.get('name') != null){
                            fiscalRate.Id = (String)mp_StrObj.get('Id');
                        }
                        lstFiscalRatesCreated.add(fiscalRate);
                    }
                    wsr.lstSObject = lstFiscalRatesCreated;
                }  
            }else if(response !=NULL && (response.getStatusCode() == 503 || response.getStatusCode() == 500)){
                wsr.isSuccess= false;
                wsr.message = 'Retry';
            }else{
                wsr.isSuccess= false;
                wsr.statusCode = response.getStatusCode();
                wsr.message = 'The process of creating Rate Schedule is taking more time, please wait and click Complete.';
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'createFiscalRateRecords'});
            }
        }catch(Exception ex) {
            wsr.isSuccess= false;
            if(ex.getMessage()=='Read timed out'){
                wsr.message = 'Retry';
            }else{
                wsr.message = 'The process of creating Rate Schedule is taking more time, please wait and click Complete.';
            }
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'createFiscalRateRecords'});                          
        }
        return wsr;
    }
    public static String generateFiscalRateJSON(List<batchsit_t_fiscal_rate__x>lstFiscalRates){
      String jSONString ='';
      List<FiscalRateCreateWrapper> lstFiscalRateWrap  = new List<FiscalRateCreateWrapper>();
        for(batchsit_t_fiscal_rate__x fiscalRate : lstFiscalRates){
           FiscalRateCreateWrapper wrap = new FiscalRateCreateWrapper(fiscalRate.cde_age_group__c, fiscalRate.cde_care_unit__c, fiscalRate.cde_rate_type__c,fiscalRate.idn_fiscal_sch__c,fiscalRate.amt_fa__c,fiscalRate.amt_provr__c);
           lstFiscalRateWrap.add(wrap); 
        }
        jSONString = JSON.serialize(lstFiscalRateWrap);
        return jSONString;
    }
    public static WebserviceResponse deleteFiscalRateRecords(List<Id>lstRateScheduleIds){
        String method = 'POST';
        WebserviceResponse wsr = new WebserviceResponse(); 
            try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.fiscalRateDelete);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            String jsonStr = '[';
                for(Id id :lstRateScheduleIds){
                jsonStr += '{"idn_fiscal_Sch":"'+id+'"}';
                }
                jsonStr += ']';
            request.setBody(jsonStr);
            request.setTimeout(Integer.valueOf(System.Label.WebServiceTimeOut));
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                wsr.isSuccess= false;
                wsr.statusCode = response.getStatusCode();
                wsr.message = response.getStatus()+' '+response.getBody();
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'deleteFiscalRateRecords'});
            } else {
                wsr.isSuccess = true;
            }
        }catch(Exception ex) {wsr.isSuccess= false;wsr.message = ex.getMessage();ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'deleteFiscalRateRecords'});             
        }
        return wsr;
    }


    // Added by Diya for CCCAP-4771
    // Call get subsidy amount service
    public static HttpResponse getAmountPaidService(String caseExternalId, String month, String year) {
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(Label.CaseReviewSubsidyAmtService);
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            if(month.length() == 1){
                month = '0' + month;
            }
            String body;
            if(String.isNotBlank(caseExternalId)){
                body = '{"caseid":"' + caseExternalId + '","month":"' + month + '","year":"' + year + '"}';
            }
            req.setBody(body);
            HttpResponse response = http.send(req);
            return response;
        } catch(Exception ex) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setBody(ex.getMessage());
            return response;
        }
    }
    public static LightningServerResponse doCallBREConfirmEligibility(String CaseID, String RunID){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message='';
        try{
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('PUT');
            req.setTimeout(120000);
            req.setEndpoint(System.Label.BRE_ConfirmEligibility);
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            String body = '{"CaseID":"'+CaseID+'","RunID":"'+RunID+'","UserLastUpdated":"'+UserInfo.getUserId()+'"}';
            req.setBody(body);
            HttpResponse response = http.send(req);
            Integer statusCode = response.getStatusCode();
            if (statusCode >= 2000) {
                isSuccessful = false;
                message = Label.CONTINUATION_ERROR + statusCode;
                ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinsition'});
            }else if (response.getStatusCode() != 200) {
                ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinsition'});
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                isSuccessful = false;
                String error = Label.An_error_occurred_while_calling_BRE;
                error+=response.getStatus()!=null?String.valueOf(response.getStatus())+',':'';
                String errorBody = response.getBody();
                String actualError = errorBody.substringBetween('The exception message is', 'See server logs for more details');
                if(String.isNotEmpty(actualError)){
                    error += actualError;
                    error = error.replaceAll('\'', '');
                }else{
                    error+= errorBody;
                }
                message = error;
                ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinsition'});
            } else {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if(data.get('ErrorValue')!=null){
                    List<Object> errorValues = (List<Object>)data.get('ErrorValue');
                    if(!errorValues.isEmpty()){
                        for(Object ob:errorValues){
                            message+=String.valueOf(ob);
                        }
                        isSuccessful = false;
                        ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinsition'});
                    }
                }else{
                    isSuccessful = true;
                    //objectData.put('data',String.valueOf(data)); 
                }
            }
        } catch(Exception ex) {
            isSuccessful = false;
            message=ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinsition'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }   
    public static LightningServerResponse doCallAssessEligibility(String caseId, String programName) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message='';
        String CONFIRMED = Label.CFM;
        String caseMode, caseStatus;
        List<T_SBSD_CASE__c> cases = [SELECT Name,IDN_EXTNL__c, (SELECT Id, CDE_MODE_CASE__c, CDE_STATUS_CASE__c FROM T_SBSD_CASE10__r WHERE DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c=null OR DTE_END_EFFV__c>TODAY)) FROM T_SBSD_CASE__c WHERE Id = :caseId];
        if(!cases.get(0).T_SBSD_CASE10__r.isEmpty()) {
            caseMode = cases.get(0).T_SBSD_CASE10__r.get(0).CDE_MODE_CASE__c;
            caseStatus = cases.get(0).T_SBSD_CASE10__r.get(0).CDE_STATUS_CASE__c;
        }
        String oldProgram=null;
        List<batchsit_t_eligty_run__x> eligRuns = [SELECT idn_run_eligty__c FROM batchsit_t_eligty_run__x WHERE idn_case__c = :cases.get(0).IDN_EXTNL__c AND cde_eligty_cfmd__c = :CONFIRMED ORDER BY idn_run_eligty__c DESC];
        if(!eligRuns.isEmpty()) {
            String idn_run_eligty = String.valueOf(eligRuns.get(0).idn_run_eligty__c);
            List<batchsit_t_fcompsn_eligty__x> caseEligibility = [SELECT idn_eligty_fcompsn__c, cde_prog__c FROM batchsit_t_fcompsn_eligty__x WHERE idn_run_eligty__c =: idn_run_eligty AND idn_eligty_fcompsn__c!=null];
            Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
            for(batchsit_t_fcompsn_eligty__x fcompsnEligty:caseEligibility) {
                fcompsnEligtyIdToRecord.put(String.valueOf(fcompsnEligty.idn_eligty_fcompsn__c),fcompsnEligty);
            }
            List<batchsit_t_fcompsn_eligty_detail__x> caseEligibilityDetails = [SELECT idn_eligty_fcompsn__c FROM batchsit_t_fcompsn_eligty_detail__x
                                                                                WHERE idn_eligty_fcompsn__c IN: fcompsnEligtyIdToRecord.keySet() 
                                                                                ORDER BY idn_eligty_fcompsn__c  DESC, dte_begin_effv__c DESC LIMIT 1000];
            if(!caseEligibilityDetails.isEmpty()) {
                String idnEligtyFcompsnLatest = caseEligibilityDetails.get(0).idn_eligty_fcompsn__c;
                if(fcompsnEligtyIdToRecord.containsKey(idnEligtyFcompsnLatest)) {
                    oldProgram = fcompsnEligtyIdToRecord.get(idnEligtyFcompsnLatest).cde_prog__c;
                }
            } else {
                oldProgram = caseEligibility.get(0).cde_prog__c;
            }            
        }
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setTimeout(120000);
        req.setEndpoint(System.Label.BRECreate);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        List<T_SBSD_CASE_STATUS_MODE__c> caseStatusMode = [Select Id
                                                           From T_SBSD_CASE_STATUS_MODE__c
                                                           Where IDN_CASE__c =: caseId AND CDE_ELIGTY_CONTNUS__c = 'N' AND CDE_STATUS_CASE__c = 'PEN' AND CDE_MODE_CASE__c = 'INT' AND DTE_BEGIN_EFFV__c <= TODAY AND (DTE_END_EFFV__c > TODAY OR DTE_END_EFFV__c = null )];
        Boolean programChange;
        if(caseStatusMode.size()>0) {
            programChange = false;  
        } else {
            programChange = oldProgram==null || programName==oldProgram?false:true;
        }
        //Boolean programChange = oldProgram==null || programName==oldProgram?false:true;
        String syncDataJSON;
        try {
            DateTime startTime = System.now();
            syncDataJSON = SyncDataJSONCreator.SyncDataJSONForm(caseId);
            DateTime endTime = System.now();
            Long timeTaken = endTime.getTime() - startTime.getTime(); 
        } catch(Exception ex) {
            Map<String,Object> methodInfo = new Map<String,Object>();
            methodInfo.put('Class__c','AssessEligibilityFlowApxCtrl');            
            methodInfo.put('Method__c','doCallBackAssessEligibilityContinsition');            
            ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
        }
        String body = '{"CaseID":'+cases.get(0).Name+//Name of the case(Int-32): CHATS-3525
            ',"CaseMode":"'+caseMode+//from latest case status mode record: CHATS-3525
            '","CaseStatus":"'+caseStatus+//from latest case status mode record: CHATS-3525
            '","ConfirmEligibilityCode":"INP",'+//It should always be INP: CHATS-3525
            '"ProgramChange":"'+programChange+'",'+//It is stored in cde_prog__c of batchsit1$t_fcompsn_eligty, so need to do a query on the last confirmed elig run record.: CHATS-3525
            '"ProgramName":"'+programName+'",'+//whatever user selected on the screen
            '"UserLastUpdated":"'+UserInfo.getUserId();//Salesforce Id of current user
        if(String.isNotEmpty(syncDataJSON)) {
            body = body +'","SyncData":'+syncDataJSON;//SyncData required for Assessing Eligibility
        }
        body = body + '}';
        req.setBody(body);
        HttpResponse response = http.send(req);
        if (response.getStatusCode() != 200) {
            isSuccessful = false;
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, req, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbrancefetch'});             
            
        } else {
            
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> errorValues = (List<Object>)data.get('ErrorValue');
            if(errorValues!=null && !errorValues.isEmpty()){
                for(Object ob:errorValues) {
                    message+=String.valueOf(ob);
                }
                isSuccessful = false;
                Map<String,Object> methodInfo = new Map<String,Object>();
                methodInfo.put('Class__c','AssessEligibilityFlowApxCtrl');            
                methodInfo.put('Method__c','doCallBackAssessEligibilityContinsition');            
                ExceptionLoggingServices.captureExceptionLog(response, null, methodInfo);
            } else {
                String ruId = String.valueOf(data.get('RunID'));
                if(String.isNotEmpty(ruId)){
                        List<batchsit_t_eligty_run__x> eligRunRecords = [SELECT Id, idn_case__c, idn_run_eligty__c, idn_case__r.Id, idn_case__r.IND_CHGD_DATA_ELIGTY__c
                                                                          FROM batchsit_t_eligty_run__x WHERE idn_run_eligty__c = :integer.valueof(ruId)];
                        if(!eligRunRecords.isEmpty()) {
                            objectData.put('eligRunSFID',eligRunRecords.get(0).Id);
                        } else {
                            isSuccessful = false;
                            message = 'There exists no record in DB corresponding to external id:'+ruId;
                        }                    
                    }
                objectData.put('RunID',ruId);
                isSuccessful= true;
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }  

     public static LightningServerResponse doCallBRESaveIneligibilityReasons(String FCEligibilityID, String FCIndividualID, String DocumentId, String FailureCodes){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message='';
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setTimeout(120000);
        req.setEndpoint(System.Label.BRE_SaveIneligibilityReasons);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String body = '{"FCEligibilityID":'+FCEligibilityID+',';
        if(String.isNotEmpty(FCIndividualID)){
            body+='"FCIndividualID":'+FCIndividualID+',';
        }
        body+='"DocumentId":"'+DocumentId+'",';
        body+='"FailureCodes":[';
        if(String.isNotEmpty(FailureCodes)){
            FailureCodes = FailureCodes.removeEnd(',');
            for(String FailureCode:FailureCodes.split(',')){
                body+='"'+FailureCode+'",';
            }
            body = body.removeEnd(',');
        }
        body += '],';
        body += '"UserLastUpdated":"'+UserInfo.getUserId()+'"}';
        req.setBody(body);
        HttpResponse response = http.send(req);
        Integer statusCode = response.getStatusCode();
        try{
        if (statusCode >= 2000) {
            isSuccessful = false;
            message = Label.CONTINUATION_ERROR + statusCode;
            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'IndividualFlowApxCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});
        }else if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'IndividualFlowApxCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});

            isSuccessful = false;
            String error = Label.An_error_occurred_while_calling_BRE;
            error+=response.getStatus()!=null?String.valueOf(response.getStatus())+Label.SEPARATOR_COMMA:'';
            String errorBody = response.getBody();
            String actualError = errorBody.substringBetween('The exception message is', 'See server logs for more details');
            if(String.isNotEmpty(actualError)){
                error += actualError;
                error = error.replaceAll('\'', '');
            }else{
                error+= errorBody;
            }
            message = error;
            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'IndividualFlowApxCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});
        } else {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if(data.get('ErrorValue')!=null){
                List<Object> errorValues = (List<Object>)data.get('ErrorValue');
                if(!errorValues.isEmpty()){
                    for(Object ob:errorValues){
                        message+=String.valueOf(ob);
                    }
                    isSuccessful = false;
		            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'IndividualFlowCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});
                }
            }else{
                objectData.put('failureCodes',data.get('FailureCodes'));
            }
        }
        }catch(Exception ex) {
        	isSuccessful = false;
            message=ex.getMessage();
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'IndividualFlowCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});             
        }
        // Adding req for continuation callBacks.
        // Return it to the system for processing
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    //CCCAP-12574
    
    public static Map<String, List<batchsit_t_auth_encmbr__x>> authEncumbrancefetchMult(List<String> authIds){
        Map<String,List<batchsit_t_auth_encmbr__x>> lstEncumbranceRecords = new Map<String,List<batchsit_t_auth_encmbr__x>>();
        String method = 'POST';
        FetchBulkAuthEncmbrModel reqWrap = new FetchBulkAuthEncmbrModel();
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.EncumbFetchBulk);
            //request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthEncumbr/BulkTransfer');
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            reqWrap.authIds = authIds;
            Set<string> dates = new Set<String>();
            if(careDateList!=null){
                for(Date d : careDateList){
                    dates.add(String.valueOf(d).removeEnd(' 00:00:00'));
                }
            }
            reqWrap.careDateList = dates;
            String jsonArrStr= JSON.serialize(reqWrap);
            request.setBody(jsonArrStr);
            Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
            request.setTimeout(timeOutVal);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbrancefetchMult'});             
                isApiSuccess =false;
            }else {
                Map<String, Object> lst_JsonParse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                for(String key : lst_JsonParse.keyset()){
                    list<object> rec = (list<object>) lst_JsonParse.get(key);
                    for (Object value : rec) {
                        Map<String, Object> mp_StrObj = (Map<String, Object>) value;
                        batchsit_t_auth_encmbr__x encumbranceRec = new batchsit_t_auth_encmbr__x();
                        Boolean attended = false;
                        if((String)mp_StrObj.get('errorMessage') == null){                       
                            encumbranceRec.cde_Level_Care__c = (String)mp_StrObj.get('cde_Level_Care');
                            encumbranceRec.cde_Status_Encmbr__c = (String)mp_StrObj.get('cde_Status_Encmbr');
                            encumbranceRec.cde_Type_Unit_Care__c = (String)mp_StrObj.get('cde_Type_Unit_Care');
                            encumbranceRec.cnt_Hour_Attnd_Actual__c = Integer.valueOf(mp_StrObj.get('cnt_Hour_Attnd_Actual')) ;
                            encumbranceRec.cnt_Hour_Care__c =Integer.valueOf(mp_StrObj.get('cnt_Hour_Care'));
                            encumbranceRec.ind_0_36_months__c = (String)mp_StrObj.get('ind_0_36_months'); //added for CCCAP-14174
                            if(mp_StrObj.get('attendedFlag') != null){
                                String attendedFlg = (String)mp_StrObj.get('attendedFlag');
                                if(attendedFlg.toLowerCase()=='true'){
                                    attended = true; 
                                }
                            }
                            
                            encumbranceRec.idn_Auth__c = (String)mp_StrObj.get('idn_Auth');
                            encumbranceRec.createdbyid__c = (String)mp_StrObj.get('createdbyid');
                            encumbranceRec.nbr_Seq_Hist__c = Integer.valueOf(mp_StrObj.get('nbr_Seq_Hist'));
                            //made below changes for CCCAP-9353 by SS
                            String lastmodifiedby = (String)mp_StrObj.get('lastmodifiedbyid');
                            if(lastmodifiedby!=null && (lastmodifiedby.length() == 15 || lastmodifiedby.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', lastmodifiedby)){
                                encumbranceRec.lastmodifiedbyid__c = (String)mp_StrObj.get('lastmodifiedbyid');    
                            }
                            encumbranceRec.ExternalId = (String)mp_StrObj.get('idn_Encmbr_Auth');
                            globalAttended.put(encumbranceRec.ExternalId,attended); 
                            
                            List<String> dateParts = String.valueOf(mp_StrObj.get('dte_Care')).split('-');
                            Date dateWithTime = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                            encumbranceRec.dte_care__c = dateWithTime ;
                            if (!lstEncumbranceRecords.containsKey(key)) {
                                lstEncumbranceRecords.put(key, new List<batchsit_t_auth_encmbr__x>());
                            }
                            
                            lstEncumbranceRecords.get(key).add(encumbranceRec);
                        }
                    } 
                }
                isApiSuccess = true;
            }
        } catch(Exception ex) {
            isApiSuccess = false;
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'authEncumbrancefetchMult'});             
        }
        return lstEncumbranceRecords;
    }  
    public class FetchBulkAuthEncmbrModel{
        public List<String> authIds{get;set;}
        public Set<String> careDateList{get;set;}
        public FetchBulkAuthEncmbrModel(){
            authIds = new List<String>();
            careDateList = new Set<String>();
        }
    }  
}