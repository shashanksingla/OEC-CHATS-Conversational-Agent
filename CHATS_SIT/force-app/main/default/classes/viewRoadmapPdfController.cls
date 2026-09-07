/*
	Title: Roadmap PDF Controller 
	Description: Get Roadmap PDF from S3 if available else call Mulesoft
	Author: Balamurugan Chinnaiah
	Comments: CCCAP-3117 09/10/2021
*/

public with sharing class viewRoadmapPdfController {
    public static String viewRoadmapPdf = 'viewRoadmapPdf';
    public static String viewReferralAEMCred = 'viewReferralAEMCred';
    public static String strConvertedBlob {get; set;}
    public Blob blobResponse {get; set;}
    
    public viewRoadmapPdfController(){
        viewRoadmapPdfController.getFileString();
    }
    
    public static string getFileString(){
        Blob blobResponse;
        string responseString;
        try{
            String fileName = System.currentPageReference().getParameters().get('fileName');
            String recordId = System.currentPageReference().getParameters().get('recordId');
            System.debug('fileName:'+fileName);
            System.debug('recordId:'+recordId);
            HttpResponse response = roadmapCallout(fileName);
            if (response <> null && response.getStatusCode() == 200) {
                blobResponse = response.getBodyAsBlob();
                system.debug('The Blob: '+blobResponse);
                if(null!=blobResponse)
                    strConvertedBlob = EncodingUtil.base64Encode(blobResponse);
                else{
                	system.debug('No Roadmap in S3. Call Mulesoft Webservice.');
                   	LightningServerResponse serverResponse = getRoadmapPdfFromCbms(recordId);
                    if(null!=serverResponse && serverResponse.isSuccessful){
                        String responseJSON=(String)serverResponse.objectData.get('responseJSON');
                        HttpResponse response2ndCallout = roadmapCallout(fileName);
                        if (response2ndCallout <> null && response2ndCallout.getStatusCode() == 200) {
                            blobResponse = response2ndCallout.getBodyAsBlob();
                            system.debug('The Blob: '+blobResponse);
                            if(null!=blobResponse)
                                strConvertedBlob = EncodingUtil.base64Encode(blobResponse);}
                    }
                }
                system.debug('The stringResponse from File'+strConvertedBlob);
            } else {
                system.debug('Res Code ' + response.getStatusCode() +', The string response--'+response.getBody());
            }
        } catch (exception e){
            system.debug('Exception occured in returning Roadmap PDF Blob - ' + e.getmessage());
        }
        return strConvertedBlob;
    }
    
    @auraEnabled
    public static LightningServerResponse getRoadmapPdfFromCbms(string recordId){
        List<WebServiceConfiguration__mdt> serviceMetaData = new List<WebServiceConfiguration__mdt>();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        
        String responseJSON;
        
        List<T_SBSD_ROADMAP_CORR_ID__c> roadmaps = [select id, CBMS_CASE_NUM__c, ROADMAP_CORR_ID__c From T_SBSD_ROADMAP_CORR_ID__c where id =: recordId];
        
        system.debug('The list of roadmaps--'+roadmaps);
        serviceMetaData = [SELECT id, AuthId__c, AuthToken__c, EndPoint__c, isActive__c, ServiceType__c, MasterLabel, DeveloperName FROM WebServiceConfiguration__mdt WHERE isActive__c = true AND DeveloperName = :viewRoadmapPdf LIMIT 1];
        
        system.debug('The list of serviceMetaData--'+serviceMetaData);
        
        try{
            if (!serviceMetaData.isEmpty() && serviceMetaData[0].AuthId__c <> null && serviceMetaData[0].AuthToken__c <> null && serviceMetaData[0].EndPoint__c <> null) {
                Httprequest request = new Httprequest();
                Http http = new Http();
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Accept', '*/*');
                request.setHeader('client_id', CryptoClass.decrypt(serviceMetaData[0].AuthId__c));
                request.setHeader('client_secret', CryptoClass.decrypt(serviceMetaData[0].AuthToken__c));
                request.setTimeout(120000);
                request.setEndpoint((serviceMetaData[0].EndPoint__c));
                
                JSONGenerator generator = JSON.createGenerator(true);
                if(roadmaps.size() > 0 ) {
                    for(integer i = 0; i < roadmaps.size(); i++) {
                    	DateTime myDateTime = DateTime.now();
						//String timeStamp = myDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
						String timeStamp = myDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss','America/Denver');
                        generator.writeStartObject();
                        generator.writeObjectField('cbmsCaseID',roadmaps[i].CBMS_CASE_NUM__c);
                        generator.writeObjectField('correspondenceType','F');
                        generator.writeObjectField('correspondenceId',roadmaps[i].ROADMAP_CORR_ID__c);
                        generator.writeObjectField('requestedUserId',UserInfo.getUserId().substring(0,14));
                        generator.writeObjectField('requestedTimestamp',timeStamp);
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
                    xLog.Class__c = 'viewRoadmapPdfController';
                    xLog.Method__c = 'getRoadmapPdfFromCbms';
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
                }
            }
        } catch(Exception ex){
            isSuccessful = false;
            message = 'Webservice Exception : '+ ex.getMessage(); 
            //ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'viewRoadmapPdfController','Method__c'=>'getPdfFromPeak'});
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled
    public static string fetchRoadmapFileName(string recordId){
        List<T_SBSD_ROADMAP_CORR_ID__c> roadmaps = new List<T_SBSD_ROADMAP_CORR_ID__c>();
        string roadmapCorrespondenceId;
        roadmaps = [select id, ROADMAP_CORR_ID__c From T_SBSD_ROADMAP_CORR_ID__c where id =: recordId];
        if(roadmaps != null){
            roadmapCorrespondenceId = string.valueOf(roadmaps[0].ROADMAP_CORR_ID__c);
        }
        return roadmapCorrespondenceId;
    }
    
    public static HttpResponse roadmapCallout(String fileName){
	List<WebServiceConfiguration__mdt> serviceMetaData = new List<WebServiceConfiguration__mdt>();
        serviceMetaData = [SELECT id, AuthId__c, AuthToken__c, EndPoint__c,UserName__c,Password__c, isActive__c, ServiceType__c, MasterLabel, DeveloperName FROM WebServiceConfiguration__mdt WHERE isActive__c = true AND DeveloperName = :viewReferralAEMCred LIMIT 1];
        String username;
        String password;
        Httprequest request = new Httprequest();
        Http http = new Http();
        request.setMethod('POST');
	if(!serviceMetaData.isEmpty() && serviceMetaData[0].Password__c != null && serviceMetaData[0].UserName__c != null){
                username  = serviceMetaData[0].UserName__c;
                password= serviceMetaData[0].Password__c;
            }            
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader);
        String url = Label.correspondenceTargetPdfServlet + 'pathInAws=correspondence/cbmsRoadmap'+'&fileName=' + fileName+'.pdf';
        system.debug('The url for servlet server--'+url);
        request.setEndpoint(url);
        HttpResponse response = http.send(request);
        return response;
    }
}