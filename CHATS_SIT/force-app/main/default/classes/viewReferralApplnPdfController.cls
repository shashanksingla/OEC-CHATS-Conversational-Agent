public with sharing class viewReferralApplnPdfController {
    public static String viewReferralPdf = 'viewReferralPdf';
    public static String viewReferralAEMCred = 'viewReferralAEMCred';
    public static String strConvertedBlob {get; set;}
    public Blob blobResponse {get; set;}
    
    public viewReferralApplnPdfController(){
        viewReferralApplnPdfController.getFileString();
    }
    
    public static string getFileString(){
        Blob blobResponse;
        string responseString;
        try{
            String fileName = System.currentPageReference().getParameters().get('fileName');
            String recordId = System.currentPageReference().getParameters().get('recordId');
            System.debug('fileName:'+fileName);
            System.debug('recordId:'+recordId);
            HttpResponse response = cbmsCallout(fileName);
            if (response <> null && response.getStatusCode() == 200) {
                blobResponse = response.getBodyAsBlob();
                system.debug('The Blob: '+blobResponse);
                if(null!=blobResponse)
                    strConvertedBlob = EncodingUtil.base64Encode(blobResponse);
                else{
                   LightningServerResponse serverResponse = getReferralPdf(recordId);
                    if(null!=serverResponse && serverResponse.isSuccessful){
                        String responseJSON=(String)serverResponse.objectData.get('responseJSON');
                        HttpResponse response2ndCallout = cbmsCallout(fileName);
                        if (response2ndCallout <> null && response2ndCallout.getStatusCode() == 200) {
                            blobResponse = response2ndCallout.getBodyAsBlob();
                            system.debug('The Blob: '+blobResponse);
                            if(null!=blobResponse)
                                strConvertedBlob = EncodingUtil.base64Encode(blobResponse);}
                    }
                }
                system.debug('The stringResponse from File'+strConvertedBlob);
                //responseString = EncodingUtil.base64Encode(responseString);
            } else {
                system.debug('Res Code ' + response.getStatusCode() +', The string response--'+response.getBody());
            }
        } catch (exception e){
            system.debug('Exception occured in returning Peak PDF Blob - ' + e.getmessage());
            //ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'viewPeakApplnPdfController','Method__c'=>'getFileBlob'});
            //throw new CorspdException('Exception occured in returning Peak PDF Blob - ' + e.getmessage(),e);
        }
        return strConvertedBlob;
    }
    
    @auraEnabled
    public static LightningServerResponse getReferralPdf(string recordId){
        List<WebServiceConfiguration__mdt> serviceMetaData = new List<WebServiceConfiguration__mdt>();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;        
        String responseJSON;
        
        List<T_APPLN_PRCS_QUEUE__c> lstofApplnPrcsQueues = [select id, IDN_APPLN__r.Name, IDN_APPLN__r.CBMS_CASE_NUM__c, IDN_APPLN__r.IDN_CBMS_REF__c, IDN_APPLN__r.CreatedDate from T_APPLN_PRCS_QUEUE__c where id =:recordId];
        system.debug('The list application process queue--'+lstofApplnPrcsQueues);
        
        try{
            Httprequest request = new Httprequest();
            Http http = new Http();
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            String sUrl = Label.CBMSReferralPDFGenerateUrl;
            request.setTimeout(120000);
            request.setEndpoint(sUrl);
            
            JSONGenerator generator = JSON.createGenerator(true);
            if(lstofApplnPrcsQueues.size() > 0 ) {
                for(integer i = 0; i < lstofApplnPrcsQueues.size(); i++) {
                    generator.writeStartObject();
                    generator.writeObjectField('applicationId',lstofApplnPrcsQueues[i].IDN_APPLN__r.Name);
                    generator.writeObjectField('referralId',lstofApplnPrcsQueues[i].IDN_APPLN__r.IDN_CBMS_REF__c);
                    Datetime referralDate = lstofApplnPrcsQueues[i].IDN_APPLN__r.CreatedDate;
                    String formattedDate = referralDate.yearGmt()+'-'+referralDate.monthGmt()+'-'+referralDate.dayGmt();
                    generator.writeObjectField('referralCreationDate',formattedDate);
                    generator.writeEndObject();
                }
            }
            String JSONString = generator.getAsString();
            system.debug('The JSON Input--'+JSONString);
            request.setBody(JSONString);
            HttpResponse response = http.send(request);
            if (response <> null && response.getStatusCode() == 200) {
                responseJSON = response.getBody();
                system.debug('The string response--'+responseJSON);
                objectData.put('responseJSON', responseJSON);
                isSuccessful = true;
            }  else {
                isSuccessful = false;
                message = 'Webservice Status returned is : '+ response.getStatusCode() + ' ; ' + response.getStatus();
                Exception_Log__c xLog = new Exception_Log__c();
                xLog.Class__c = 'viewReferralApplnPdfController';
                xLog.Method__c = 'getReferralPdf';
                if (response != null) {
                    xLog.Exception_Message__c = 'Status is :' + response.getStatus() + ',Status Code is :' + String.valueOf(response.getStatusCode());
                    if (response.getStatusCode() != null) {
                        xLog.Exception_Type__c = 'Web Service';
                    }
                    xLog.Response__c = response.getBody();
                }
                if (response != null) {
                    xLog.Request__c = 'End point:' + request.getEndpoint() + ':' + response.getBody();
                }
                //ExceptionLoggingServices.captureExceptionLog(xLog); 
                system.debug(xLog.Exception_Message__c);
                system.debug(xLog.Request__c);
            }
        } catch(Exception ex){
            isSuccessful = false;
            message = 'Webservice Exception : '+ ex.getMessage(); 
            system.debug(message);
            //ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'viewReferralApplnPdfController','Method__c'=>'getReferralPdf'});
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled
    public static string fetchPdfFileFromS3(string recordId){
        List<T_APPLN_PRCS_QUEUE__c> applnPrcsQueueList = new List<T_APPLN_PRCS_QUEUE__c>();
        string applnId;
        applnPrcsQueueList = [select id, IDN_APPLN__r.CBMS_CASE_NUM__c, IDN_APPLN__r.Name From T_APPLN_PRCS_QUEUE__c where id =: recordId];
        if(applnPrcsQueueList != null){
            applnId = string.valueOf(applnPrcsQueueList[0].IDN_APPLN__r.Name);
        }
        return applnId;
    }
    
    public static HttpResponse cbmsCallout(String fileName){
        List<WebServiceConfiguration__mdt> serviceMetaData = new List<WebServiceConfiguration__mdt>();
        serviceMetaData = [SELECT id, AuthId__c, AuthToken__c, EndPoint__c,UserName__c,Password__c, isActive__c, ServiceType__c, MasterLabel, DeveloperName FROM WebServiceConfiguration__mdt WHERE isActive__c = true AND DeveloperName = :viewReferralAEMCred LIMIT 1];
        String username;
        String password;
        Httprequest request = new Httprequest();
        Http http = new Http();
        request.setMethod('POST');
        String url = Label.correspondenceTargetPdfServlet + 'pathInAws=correspondence/cbmsreferrals'+'&fileName=' + fileName+'.pdf';
        if(!serviceMetaData.isEmpty() && serviceMetaData[0].Password__c != null && serviceMetaData[0].UserName__c != null){
                username  = serviceMetaData[0].UserName__c;
                password= serviceMetaData[0].Password__c;
            }            
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader);
        request.setEndpoint(url);
        HttpResponse response = http.send(request);
        return response;
    }
}