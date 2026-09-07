public without sharing class ATSAsyncCallbackHandlerIndividual extends DataSource.AsyncSaveCallback{
    public override void processSave(Database.SaveResult saveResult){
        Exception_Log__c xLog = new Exception_Log__c();
        if(!saveResult.isSuccess()){
            String error='';
            for(integer i=0;i<saveResult.getErrors().size();i++){
                error += 'Message: '+saveResult.getErrors().get(i).getMessage()+' StatusCode: '+saveResult.getErrors().get(i).getStatusCode();
                if(saveResult.getErrors().get(i).getFields()!=null && saveResult.getErrors().get(i).getFields().size()>0){
                    error+='.Field:';
                    for(String fieldName:saveResult.getErrors().get(i).getFields()){
                        error+=fieldName;
                    }
                }
            }
            xLog.Class__c = 'AsyncSaveCallback';
            xLog.Method__c = 'processSave';
            xLog.Exception_Type__c = 'ATS Error';
            xLog.Stack_Trace__c = error;
            xLog.Record_ID__c = saveResult.getId();
            //insert xLog;
			ExceptionLoggingServices.captureExceptionLog(xLog); 
        }else{
            xLog.Class__c = 'AsyncSaveCallback';
            xLog.Method__c = 'processSave';
            xLog.Exception_Type__c = 'ATS Success';
            xLog.Stack_Trace__c = 'Records are successfully inserted.';
            xLog.Record_ID__c = saveResult.getId();
            //insert xLog;
			ExceptionLoggingServices.captureExceptionLog(xLog); 
        }
    }
}