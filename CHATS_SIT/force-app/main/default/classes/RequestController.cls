/**
* @verison 1.0
* 
* Initial pipeline to process / delegate request
* 
*/
public with sharing class RequestController {
    /**
* Used to delegate request by creating an instance of the class which implements IRequest
* 
* @param className - Name of the Apex class which implements IRequest
* @param methodName - Name of the method to be invoked internally with in the Apex class
* @param jsonParam - Request params in String format
* 
* @return string - JSON response
*/
    @auraEnabled
    public static string delegateRequest(String className, String methodName, String jsonParam){
        Object response;
        try{
            Type classType = Type.forName(className);
            IRequest req = (IRequest)classType.newInstance();
            response = req.processRequest(methodName,jsonParam);            
        }
        catch(Exception ex){
            LightningServerResponse rsp = new LightningServerResponse(false,ex.getMessage(),null);
            rsp.status = RequestStatus.UNKNOWN_ERROR;
            response = rsp;
        }
        return JSON.serialize(response);
    }
    @auraEnabled(continuation=true)
    public static Object delegateConRequest(String className, String methodName, String jsonParam){
        
        Type classType = Type.forName(className);
        IConRequest req = (IConRequest)classType.newInstance();
        Continuation con = new Continuation(120);
        Object response = req.processRequest(methodName,jsonParam,con);
        return response;        
    }
    // Callback method
    @auraEnabled
    public static String getResponse(Object state) {
        String respString;
        try{
            Map<String, Object> objectData = new Map<String, Object>();
            HttpResponse res = Continuation.getResponse((String)state);
            objectData.put('message','Continuation request Completed');
            LightningServerResponse response = new LightningServerResponse(true,'',objectData);
            response.status = RequestStatus.OK;
            respString = JSON.serialize(response);
        }
        catch(Exception ex){
            LightningServerResponse response = new LightningServerResponse(false,ex.getMessage(),null);
            response.status = RequestStatus.UNKNOWN_ERROR;
            respString = JSON.serialize(response);
        }
        return respString;
    } 
}