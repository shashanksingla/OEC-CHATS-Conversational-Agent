public with sharing class CallAtsAPIJob implements Queueable,Database.AllowsCallouts{
    private Set<Id> claimRecordIds;
    Public static List<API_logger__c> apiLogsToInsert{get;set;}
    public static Map<String,Object> methodInfo{get;set;}
    public CallAtsAPIJob(String recordIds){
        this.claimRecordIds =(Set<Id>)JSON.deserialize(recordIds,Set<Id>.class);
    }
    public void execute(QueueableContext context){
        methodInfo = new Map<String,Object>();
        sobjectWrap sWrap = new sobjectWrap();        
        methodInfo.put('Class__c','CallAtsAPIJob');
        methodInfo.put('Method__c','invokeAtsAPI');
        sWrap.records = new List<Map<String,Object>>();
        try{
            for(Provider_Manual_Claim__c claimsToSync : [select id,IDN_EXTNL__c,Claim_Status__c,Denial_Reason__c,
                                                         Status_Updated_Date__c,Adjustment__r.Name
                                                         from Provider_Manual_Claim__c where id IN:claimRecordIds])
            {
                Map<String,Object> sob = new Map<String,object>();
                sob.put('id',claimsToSync.IDN_EXTNL__c);
                sob.put('attributes',new Map<String,String>{'type'=>'Provider_Manual_Claim__c'});
                sob.put('Denial_Reason__c',claimsToSync.Denial_Reason__c);
                sob.put('Claim_Status__c',claimsToSync.Claim_Status__c);
                sob.put('Status_Updated_Date__c',claimsToSync.Status_Updated_Date__c);
                sob.put('AdjustmentId__c',claimsToSync.Adjustment__r.Name);
                sWrap.records.add(sob);
            }
            string atsBody=JSON.serialize(sWrap);
            string atsUrl = 'callout:DECL_Credential/services/data/v62.0/composite/sobjects';
            invokeAtsAPI(atsBody,atsUrl);
        }catch (System.CalloutException e) {
            ExceptionLoggingServices.captureExceptionLog(e, methodInfo);
        }
        catch(exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
            
        }
    }
    private static void invokeAtsAPI(String ATSBody,String atsUrl){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(atsUrl);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        system.debug('ATSBody'+ATSBody);
        req.setBody(ATSBody);
        req.setMethod('PATCH'); 
        Http h = new Http();
        HttpResponse response = h.send(req);
        System.debug('response code: ' + response.getStatusCode());
        System.debug('response body: ' + response.getBody());
        apiLogsToInsert = new List<API_Logger__c>();
        
        if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
            List<responseWrap> responses= (List<responseWrap>)JSON.deserialize(response.getBody(),List<responseWrap>.class);
            for(responseWrap wrap : responses){
                if(wrap.success == false){
                    apiLogsToInsert.add(new API_Logger__c(record_Id__c=wrap.id,
                                                          API_Flow__c='ATS Manual Claim',
                                                          Failure_Reason__c=wrap.errors[0].statusCode,
                                                          Message__c=wrap.errors[0].message));
                }
            }
            system.debug('responseMap'+responses);
        }else{
            ExceptionLoggingServices.captureExceptionLog(response,req,methodInfo);
        }
        if(!apiLogsToInsert.isEmpty()){
            Database.insert(apiLogsToInsert);
        }
    }
    public class sobjectWrap{
        public Boolean allOrNone=false;
        List<Map<String,Object>> records{get;set;}
    }
    public class responseWrap{
        public string id{get;set;}
        public Boolean success{get;set;}
        public List<errorWrap> errors{get;set;}
    }
    public class errorWrap{
        public string message{get;set;}
        public string statusCode{get;set;}
    }
    
}