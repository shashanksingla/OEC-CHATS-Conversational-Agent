public class sidmodIntegrationWebservices {
    public static String errorMessage;
    public static String errorCode;
    
    // getMatchedSIDMODIndividuals - getClientClearance Integration	
    public static list<object> GetClientClearance(String fName, String lName, String MI, String dob, String ssn, String gndr){	
        system.debug('get Client clearance reached');
        List<sidmodResponseWrapper> respSidmodlst = new List<sidmodResponseWrapper>();
        List<Object> responseList = new List<object>();	
        try{	
            Httprequest httpRequest = new Httprequest();	
            Http http = new Http();	
            httpRequest.setHeader('Content-type', 'application/x-www-form-urlencoded');	
            String sUrl = Label.sidmodGetClientClearance;	
            String body = '';
            system.debug('fName--'+fName);
            system.debug('lName--'+lName);
            system.debug('MI--'+MI);
            system.debug('dob--'+dob);
            system.debug('ssn--'+ssn);
            system.debug('gndr--'+gndr);
            
            if(String.isNotBlank(fName)){
                body += 'firstName='+ EncodingUtil.urlEncode(fName,'UTF-8');	
            }
            if(String.isNotBlank(lName)){
                body += '&lastName='+ EncodingUtil.urlEncode(lName,'UTF-8');	
            }
            if(String.isNotBlank(MI)) {
                body += '&middleName='+ EncodingUtil.urlEncode(MI,'UTF-8');
            } else {
                body += '&middleName=';
            }
            if(String.isNotBlank(gndr)){
                String gender = '';
                if(gndr == '1'){
                    gender = 'M';
                } else if (gndr == '2'){
                      gender = 'F';
                } else if(gndr == '3'){
                      gender = 'U';
                } else if (gndr == '4') {
                    gender = 'X';
                } else {
                    gender = '';
                }
                  
                system.debug('gender--'+gender);
                body += '&gender='+ EncodingUtil.urlEncode(gender,'UTF-8');	
            }
            if(String.isNotBlank(dob)){
                string dateOfBirth = dob.substring(5,7)+ '/' + dob.substring(8,10) + '/' + dob.substring(0, 4);
                system.debug('dateOfBirth--'+dateOfBirth);    
                body += '&dateOfBirth='+ dateOfBirth;}	//04-05-1967 mm-dd-yyyy
            if(String.isNotBlank(ssn)) {
                body += '&SSN='+ EncodingUtil.urlEncode(ssn,'UTF-8');	
            } else {
                body += '&SSN=';
            }
            
            httpRequest.setMethod('POST');	
            httpRequest.setCompressed(true);	
            httpRequest.setEndpoint(sUrl + '?' + body); 	
            httpRequest.setTimeout(30000);	
            system.debug(sUrl + '?' + body);
            Httpresponse httpResponse = http.send(httpRequest);	
            system.debug('response-->'+httpResponse.getStatusCode());
            
            if(httpresponse !=NULL && httpResponse.getStatusCode() == 200){	
                system.debug('c' + httpResponse);	
                system.debug('Return status code -->' + httpResponse.getStatusCode());	
                system.debug('httpResponse.getBody--'+ httpResponse.getBody());	
                String responseJSON = httpResponse.getBody();//.get('responseObjectList') ;
                system.debug('The response JSOn string-->'+responseJSON);
                                
                Map<String, object> responseJSONMap = (Map<String, object>) JSON.deserializeUntyped(responseJSON);//, Map<String, string>.class);
              	system.debug('Response map 1--> '+responseJSONMap);
                List<Map<String, Object>> resObjList = new List<Map<String, Object>>();
                List<Object> objList = (List<Object>) responseJSONMap.get('responseObjectList');
                if(objList != null){
                	for (Object obj : objList) {
                    	resObjList.add((Map<String, Object>)obj);
                	}    
                }
                system.debug('Response map 2--> '+resObjList);
                if(!resObjList.isEmpty()){
                    for (integer i=0;resObjList.size()>i;i++ ) {
                        Map<String, Object> responseMap = (Map<String, Object>)resObjList[i];
                        system.debug('response list Map '+responseMap);
                                                
                        sidmodResponseWrapper responseFromSidmod = new sidmodResponseWrapper();
                        responseFromSidmod.firstName = (String)responseMap.get('firstName');
                        responseFromSidmod.middleName = (String)responseMap.get('middleName');
                        responseFromSidmod.lastName = (String)responseMap.get('lastName');
                        responseFromSidmod.gender = (String)responseMap.get('gender');
                        responseFromSidmod.dateOfBirth = (String)responseMap.get('dateOfBirth'); 
                        responseFromSidmod.ssn = (String)responseMap.get('ssn');
                        responseFromSidmod.stateId = (String)responseMap.get('stateId');
                        responseFromSidmod.alienRegNumber = (String)responseMap.get('alienRegNumber');
                        responseFromSidmod.title = (String)responseMap.get('title');
                        responseFromSidmod.score = (String)responseMap.get('score');
                        system.debug('Response from Sidmod--->' + responseFromSidmod);    
                        respSidmodlst.add(responseFromSidmod);
                        system.debug('Response List from Sidmod--->' + respSidmodlst);
                    }
                }
            } else{	
                system.debug('URL :' + sUrl);	
                system.debug('c :' + httpResponse);	
                system.debug('Return status code -->' + httpResponse.getStatusCode());	
            }	
        }catch(Exception e){	
           ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'sidmodIntegrationWebservices','Method__c'=>'GetClientClearance'});
        }	
        return respSidmodlst;	
    }
    
public static list<object> assignStateId(String fName, String lName, String MI, String dob, String ssn, String gndr){    
    List<sidmodResponseWrapper> respSidmodlst = new List<sidmodResponseWrapper>();
    List<Object> responseList = new List<object>(); 
    Map<String, Object> objectData = new map<String, Object>();
    Boolean isSuccessful;
    String message;
    Map<String,Object> methodReqInfo = new Map<String,Object>();
    methodReqInfo.put('Class__c','APXPeakApplicationToCaseController');    
    methodReqInfo.put('Method__c','assignStateId');   
    try{    
        Httprequest httpRequest = new Httprequest();    
        Http http = new Http(); 
        httpRequest.setHeader('Content-type', 'application/json'); 
        String sUrl = Label.sidmodAssignStateId;
        httpRequest.setMethod('POST');
        httpRequest.setEndpoint(sUrl);
        httpRequest.setTimeout(30000);
        String gender = '';
        if(gndr == '1'){
            gender = 'M';
        } else if (gndr == '2'){
            gender = 'F';
        } else if (gndr == '3'){
            gender = 'U';
        } else if (gndr == '4'){
            gender = 'X';
        }
        //start - SIDMOD MODERNization Changes
        SIDMODRequestWrapper bodySidmod = new SIDMODRequestWrapper();
        SIDMODRequestWrapper.cls_person person = new SIDMODRequestWrapper.cls_person();
        person.firstName = 	fName!=null ? fName : null;
        person.middleName = MI!=null ? MI : null;
        person.lastName = 	lName!=null ? lName : null;
        person.dateOfBirth = dob;
        person.sex = gender!=null ? gender : null;
        person.ssn = ssn!=null ? ssn : null;
        bodySidmod.person = person;
        String requestBody =  JSON.serialize(bodySidmod,true);
        system.debug('requestBody'+requestBody);
        httpRequest.setBody(requestBody);
        //end - SIDMOD MODERNization Changes
        Httpresponse httpResponse = http.send(httpRequest); 
        if(httpresponse !=NULL && httpResponse.getStatusCode() == 200){ 
            String responseJSON = httpResponse.getBody();//.get('responseObjectList') ;
            system.debug('The response JSOn string-->'+responseJSON);
            Map<String, object> responseJSONMap = (Map<String, object>) JSON.deserializeUntyped(responseJSON);//, Map<String, string>.class);
            if(responseJSONMap.get('persons') != NULL){
                List<Map<String, Object>> resObjList = new List<Map<String, Object>>();
                List<Object> objList = (List<Object>) responseJSONMap.get('persons'); //responseObjectList
                for (Object obj : objList) {
                    resObjList.add((Map<String, Object>)obj);
                }
                //start - SIDMOD MODERNization Changes
                if(!resObjList.isEmpty()){
                    for(integer i=0;resObjList.size()>i;i++){
                        Map<String, Object> responseMap = (Map<String, Object>)resObjList[i];
                        sidmodResponseWrapper responseFromSidmod = new sidmodResponseWrapper();
                        responseFromSidmod.stateId = (String)responseMap.get('stateId');
                        if(!responseMap.containsKey('matchRate')){
                            responseFromSidmod.score = '100';
                        } else {
                            responseFromSidmod.score = (String)responseMap.get('matchRate');
                        }
                        Map<String,Object> demographicInfo = (Map<String,Object>)responseMap.get('demographics');
                        if(demographicInfo != null){
                            responseFromSidmod.firstName = (String)demographicInfo.get('firstName');
                            responseFromSidmod.middleName = (String)demographicInfo.get('middleName');
                            responseFromSidmod.lastName = (String)demographicInfo.get('lastName');
                            responseFromSidmod.gender = (String)demographicInfo.get('sex');
                            responseFromSidmod.dateOfBirth = (String)demographicInfo.get('dateOfBirth');
                            responseFromSidmod.ssn = (String)demographicInfo.get('ssn');
                            responseFromSidmod.alienRegNumber = (String)demographicInfo.get('alienNumber');
                            responseFromSidmod.title = (String)demographicInfo.get('title');
                            responseFromSidmod.dateOfDeath = (String)demographicInfo.get('dateOfDeath');
                        }
                        respSidmodlst.add(responseFromSidmod);
                    }
                }
                //end - SIDMOD MODERNization Changes
            }else if(responseJSONMap.containskey('errorMessage')){
                message =  (String)responseJSONMap.get('errorMessage');
                errorCode =  (String)responseJSONMap.get('statusCode');
                errorMessage= message;
            }
        } else{ 
            ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, methodReqInfo);
        }   
    }catch(Exception e){    
        system.debug('the client exception-->'+e.getMessage());  
        ExceptionLoggingServices.captureExceptionLog(e, methodReqInfo);
    }
    
    if(respSidmodlst.isEmpty()){
        message = 'No State Id assigned';
    }else{
        message = 'New State Id assigned';
    }
    isSuccessful = true;
    system.debug('The respSidmodlst returned -->'+respSidmodlst);
    return respSidmodlst;
}   
    // added for CCCAP-10315 for SIDMOD Notify Feature
    public static LightningServerResponse notifySIDMOD(String stateId,Id indivId,Boolean isAppIndividual){
        List<Sobject> individualsToBeUpdated = new List<Sobject>();
        Boolean isSuccessful = true;
        String message='';
        Map<String, Object> objectData = new map<String, Object>();
        try{
            Boolean notifyBool;
            if(isAppIndividual){
                notifyBool = [select id,IND_NOTIF_SIDMOD__c from T_APPLN_INDIV__c where id =:indivId]?.IND_NOTIF_SIDMOD__c;
            }else{
                notifyBool = [select id,IND_NOTIF_SIDMOD__c from T_SBSD_INDIV__c where id =:indivId]?.IND_NOTIF_SIDMOD__c;
            } 
            if(notifyBool == false){
                SIDMODRequestWrapper bodySidmod = new SIDMODRequestWrapper();
                bodySidmod.stateId = stateId;
                Httprequest httpRequest = new Httprequest();    
                Http http = new Http(); 
                httpRequest.setHeader('Content-type', 'application/json'); 
                String sUrl = Label.sidmodNotify;
                httpRequest.setMethod('POST');
                httpRequest.setEndpoint(sUrl);
                httpRequest.setTimeout(30000);
                string reqBody = JSON.serialize(bodySidmod,true);
                system.debug('reqBody'+reqBody);
                httpRequest.setBody(reqBody);
                Httpresponse httpResponse = http.send(httpRequest); 
                String responseJSON = httpResponse.getBody();
                system.debug('responseJSON'+responseJSON);
                if(httpresponse !=NULL && httpResponse.getStatusCode() == 200){
                    Map<String, object> responseJSONMap = (Map<String, object>) JSON.deserializeUntyped(responseJSON);//, Map<String, string>.class);
                    system.debug('The response JSOn string-->'+responseJSON);
                    string statusCode =(String)responseJSONMap.get('statusCode'); 
                    if(statusCode == '200' || statusCode == '201'){
                        if(isAppIndividual){
                            individualsToBeUpdated.add(new T_APPLN_INDIV__c(Id=indivId,IND_NOTIF_SIDMOD__c=true)); 
                            GenericDMLHandler.updateRecords(individualsToBeUpdated, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_INDIV__c'},'Method__c'=>'updateRecords','Class__c'=>'APXPeakApplicationToCaseController'});                                           
                            List<T_SBSD_INDIV__c> relatedIndivs = [SELECT Id, IND_NOTIF_SIDMOD__c from T_SBSD_INDIV__c where IDN_STATE__c = :stateId LIMIT 1];
                            if(relatedIndivs.size() > 0){
                                relatedIndivs[0].IND_NOTIF_SIDMOD__c = true;
                                GenericDMLHandler.updateRecords(relatedIndivs, new Map<String,Object>{'Method__c'=>'updateRecords','Class__c'=>'APXPeakApplicationToCaseController'});                                           
                            }                                           
                        }else{
                            individualsToBeUpdated.add(new T_SBSD_INDIV__c(Id=indivId,IND_NOTIF_SIDMOD__c=true)); 
                            GenericDMLHandler.updateRecords(individualsToBeUpdated, new Map<String,Object>{'Method__c'=>'updateRecords','Class__c'=>'APXPeakApplicationToCaseController'});                   
                        }
                        message = 'notified';
                    }else{
                        isSuccessful = false; 
                        message = (String)responseJSONMap.get('errorMessage');  
                    }                    
                }                
            }            
        }catch(DMLException ex){
            message = ex.getDMLMessage(0);
            isSuccessful = false;
        }catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful,message,objectData); 
    }
}