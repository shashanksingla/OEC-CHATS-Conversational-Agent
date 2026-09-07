/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           06/25/2018                                                          
*  @description    Utility class to log all the exceptions.
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 25-Jun-2018                                                            
*  * Author: Shubham Jain                                                      
*  * Description: Initial version                                                 
*  * JIRA Ticket: 
*  * 
*********************************************************************************************/
public with sharing class ExceptionLoggingServices {

    static Boolean logException = Exception_Logging_Framework_Settings__c.getInstance().Enable_Exception_Log__c;
    static List<PII_Exception__mdt> lstPIIExceptionData = [SELECT Class_Name__c, Method_Name__c,PII_in_Exception_Message__c,Success_Log_Required__c, PII_in_Stack_Trace__c, PII_in_Request__c ,PII_in_Response__c FROM PII_Exception__mdt];
    public static Boolean pIIData= false;
    public static Boolean pIIDataInStackTrace= false;
    public static Boolean pIIDataInExceptionMsg= false;
    public static Boolean pIIDataInRequest= false;
    public static Boolean pIIDataInResponse= false;
     public static Boolean isSuccessLog= false;
    private static Boolean insertLog = true;
    
    public static Exception_Log__c captureExceptionLogInstance(Exception ex, Map<String, Object> methodInfo){
        insertLog = false;
        return captureExceptionLog(ex,methodInfo);
    }
    public static List<Exception_Log__c> captureExceptionLogInstance(List<Database.SaveResult> lstSaveResults, List<SObject> lstSObject, Map<String, Object> methodInfo){
        insertLog = false;
        return captureExceptionLog(lstSaveResults,lstSObject,methodInfo);
    }
    
    public static List<Exception_Log__c> captureExceptionLog(List<Database.SaveResult> lstSaveResults, List<SObject> lstSObject, Map<String, Object> methodInfo){
        setPIIParameters(methodInfo);
        List<Exception_Log__c> xLogs = new List<Exception_Log__c>();
        if(logException){
            try{
                Exception_Log__c xLog;
                for(Integer i=0;i<lstSObject.size();i++){
                    if(lstSaveResults.size()>i && !lstSaveResults[i].isSuccess()){
                        String errorMessage = '';
                        for(Database.Error error:lstSaveResults[i].getErrors()){
                            errorMessage+=error.getMessage();
                        }
                        xLog = new Exception_Log__c();                
                        if(methodInfo!=null){
                            if(methodInfo.containsKey('Class__c')){
                                xLog.Class__c = String.valueOf(methodInfo.get('Class__c'));
                            }
                            if(methodInfo.containsKey('Method__c')){
                                xLog.Method__c = String.valueOf(methodInfo.get('Method__c'));
                            }
                        }
                        xLog.Record_ID__c = lstSObject[i].Id;
                        if(!pIIDataInExceptionMsg){
                            xLog.Exception_Message__c = errorMessage;
                        }
                        else{
                            xLog.Exception_Message__c = Label.PII_Information;
                            xLog.PII_Information__c += 'Exception Msg: '+errorMessage;
                        }
                        xLog.Exception_Type__c = 'DML Error';
                        if(errorMessage.containsIgnoreCase('exception') || errorMessage.length() > 0 ){
                            xLogs.add(trimXLogData(xLog));
                        }
                    }
                }
                if(methodInfo==null){
                    methodInfo = new Map<String, Object>();
                }
                methodInfo.put('byPassExceptionLogging',true);
                if(insertLog){
	                GenericDMLHandler.insertRecords(xLogs, methodInfo);                    
                }
            }catch(Exception ex){
                captureExceptionLog(ex,methodInfo);
            }
        }
        return xLogs;
    }
    
    public static Exception_Log__c captureExceptionLog(Exception ex, Map<String, Object> methodInfo){
        setPIIParameters(methodInfo);
        Exception_Log__c xLog = new Exception_Log__c();
        if(logException){
            try{
                if(methodInfo!=null){
                    if(methodInfo.containsKey('Class__c')){
                        xLog.Class__c = String.valueOf(methodInfo.get('Class__c'));
                    }
                    if(methodInfo.containsKey('Method__c')){
                        xLog.Method__c = String.valueOf(methodInfo.get('Method__c'));
                    }
                    if(methodInfo.containsKey('Record_ID__c')){
                        xLog.Record_ID__c = String.valueOf(methodInfo.get('Record_ID__c'));
                    }
                }
                if(ex!=null){
                    xLog.Exception_Type__c = ex.getTypeName();
                    if(!pIIDataInExceptionMsg){
                        xLog.Exception_Message__c = ex.getMessage();
                    }else{
                        xLog.Exception_Message__c = Label.PII_Information;
                        xLog.PII_Information__c += 'Exception Msg: '+ ex.getMessage();
                    }
                    if(!pIIDataInStackTrace){
                    xLog.Stack_Trace__c = ex.getStackTraceString();
                    } else{
                        xLog.Stack_Trace__c = Label.PII_Information ; 
                        xLog.PII_Information__c += 'Stack Trace: '+ ex.getStackTraceString();
                    }
                }
                if(xLog.getSObjectType().getDescribe().isCreateable() && insertLog){
                    insert trimXLogData(xLog);
                }
            }catch(Exception exc){
                captureExceptionLog(exc, methodInfo);
            }
        }
        return xLog;
    }
    
    public static void captureExceptionLog(Exception_Log__c xLog){
        setSuccessLogParam(xLog);
        if(logException){
            try{
                if(String.isNotEmpty(xLog.Log_Type__c) && xLog.Log_Type__c == 'Success'){
                    if(isSuccessLog){
                        if(xLog.getSObjectType().getDescribe().isCreateable()){
                            insert trimXLogData(xLog);
                        }   
                    }
                }else{
                    if(xLog.getSObjectType().getDescribe().isCreateable()){
                        insert trimXLogData(xLog);
                    } 
                }
            }catch(Exception exc){
                Map<String, Object> methodInfo = new Map<String, Object>();
                methodInfo.put('Class__c', xLog.Class__c);
                methodInfo.put('Method__c', xLog.Method__c);
                captureExceptionLog(exc, methodInfo);
            }
        }
    }
    
    public static void captureExceptionLog(HttpResponse res, HttpRequest req,Map<String, Object> methodInfo){
        setPIIParameters(methodInfo);
        if(logException){
            
            Exception_Log__c xLog = new Exception_Log__c();
            try{
                if(methodInfo!=null){
                    if(methodInfo.containsKey('Class__c')){
                        xLog.Class__c = String.valueOf(methodInfo.get('Class__c'));
                    }
                    if(methodInfo.containsKey('Method__c')){
                        xLog.Method__c = String.valueOf(methodInfo.get('Method__c'));
                    }
                    if(methodInfo.containsKey('Record_ID__c')){
                        xLog.Record_ID__c = String.valueOf(methodInfo.get('Record_ID__c'));
                    }
                }
                if(res!=null){
                    if(!pIIDataInExceptionMsg){
                    	xLog.Exception_Message__c = 'Status is :'+res.getStatus()+',Status Code is :'+String.valueOf(res.getStatusCode());
                    }else{
                        xLog.Exception_Message__c = Label.PII_Information;
                        xLog.PII_Information__c += 'Exception Msg: '+ 'Status is :'+res.getStatus()+',Status Code is :'+String.valueOf(res.getStatusCode());
                    }
                    if(res.getStatusCode()!=null){
                        xLog.Exception_Type__c = 'Web Service';
                    }
                    if(!pIIDataInResponse){
                    xLog.Response__c = res.getBody();
                    }
                    else{
                        xLog.Response__c = Label.PII_Information;
                        xLog.PII_Information__c += ' Response :'+res.getBody();
                    }
                }
                if(req!=null){
                    if(!pIIDataInRequest){
                    xLog.Request__c = 'End point:'+req.getEndpoint()+':'+req.getBody();
                    }
                    else{
                        xLog.Request__c =Label.PII_Information;
                        xLog.PII_Information__c += ' Request: '+ 'End point:'+req.getEndpoint()+':'+req.getBody();
                    }
                }
                if(xLog.getSObjectType().getDescribe().isCreateable()){
                    insert trimXLogData(xLog);
                }
            }catch(Exception ex){
                captureExceptionLog(ex,methodInfo);
            }
        }
    }   
    public static Exception_Log__c trimXLogData(Exception_Log__c xLog){
        if(String.isNotEmpty(xLog.Exception_Message__c) && xLog.Exception_Message__c.length()>255){
            xLog.Exception_Message__c = xLog.Exception_Message__c.subString(0,254);
        }        
        if(String.isNotEmpty(xLog.Exception_Type__c) && xLog.Exception_Type__c.length()>50){
            xLog.Exception_Type__c = xLog.Exception_Type__c.subString(0,49);
        } 
        if(String.isNotEmpty(xLog.Method__c) && xLog.Method__c.length()>50){
            xLog.Method__c = xLog.Method__c.subString(0,49);
        } 
        if(String.isNotEmpty(xLog.Request__c) && xLog.Request__c.length()>131072){
            xLog.Request__c = String.escapeSingleQuotes(xLog.Request__c).subString(0,131071);
        } 
        if(String.isNotEmpty(xLog.Response__c) && xLog.Response__c.length()>131072){
            xLog.Response__c = String.escapeSingleQuotes(xLog.Response__c).subString(0,131071);
        } 
        if(String.isNotEmpty(xLog.Stack_Trace__c) && xLog.Stack_Trace__c.length()>131072){
            xLog.Stack_Trace__c	= String.escapeSingleQuotes(xLog.Stack_Trace__c).subString(0,131071);
        }
        if(String.isNotEmpty(xLog.PII_Information__c) && xLog.PII_Information__c.length()>4){
            if(xLog.PII_Information__c.substring(0,4)=='null'){
                xLog.PII_Information__c = xLog.PII_Information__c.subString(4,xLog.PII_Information__c.length()-1);
            } 
        }
        if(String.isNotEmpty(xLog.PII_Information__c) && xLog.PII_Information__c.length()>131072){
            xLog.PII_Information__c	= String.escapeSingleQuotes(xLog.PII_Information__c).subString(0,131071);
        } 
        // Added by Diya for Success callout logging
        if(String.isNotEmpty(xLog.Log_Type__c)){
            xLog.Log_Type__c	= String.escapeSingleQuotes(xLog.Log_Type__c);
        }
        // end
        return xLog;
    }
    public static void setPIIParameters (Map<String, Object> methodInfo) {
        for (PII_Exception__mdt pIIDataRec : lstPIIExceptionData){
            if(methodInfo!=null && methodInfo.containsKey('Class__c') && pIIDataRec.Class_Name__c.trim() == String.valueOf(methodInfo.get('Class__c')).trim() &&
               methodInfo.containsKey('Method__c') && pIIDataRec.Method_Name__c.trim() == String.valueOf(methodInfo.get('Method__c')).trim() ){
                  pIIData = true;
                   if(pIIDataRec.PII_in_Request__c == true){
                       pIIDataInRequest = true;
                   }
                   if(pIIDataRec.PII_in_Response__c == true){
                       pIIDataInResponse = true;
                   }
                   if(pIIDataRec.PII_in_Stack_Trace__c == true){
                       pIIDataInStackTrace = true;
                   }
                   if(pIIDataRec.PII_in_Exception_Message__c == true){
                       pIIDataInExceptionMsg = true;
                   }
                   break;
               }
        }
    }
    public static void setSuccessLogParam (Exception_Log__c xLog) {
        for (PII_Exception__mdt pIIDataRec : lstPIIExceptionData){
            if(xLog!=null && String.isNotEmpty(xLog.Class__c) && pIIDataRec.Class_Name__c.trim() == xLog.Class__c.trim() &&
               String.isNotEmpty(xLog.Method__c) && pIIDataRec.Method_Name__c.trim() == xLog.Method__c ){
                   if(pIIDataRec.Success_Log_Required__c == true){
                       isSuccessLog = true;
                   }
                   break;
               }	
        }
    }
}