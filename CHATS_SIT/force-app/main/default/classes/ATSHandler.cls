public class ATSHandler {
    
    public static Boolean isType2Inserted = false;
    public static Boolean isType3Inserted = false;
    
    public static void insertATSRecord(Boolean doDML, batchsit_t_pos_trans_queue_ats__x atsRecord){
        try {
            if(atsRecord!=null){
                atsRecord.createdbyid__c =  UserInfo.getUserId();
                atsRecord.lastmodifiedbyid__c =  UserInfo.getUserId();
                atsRecord.createddate__c =  System.now();
                atsRecord.lastmodifieddate__c = System.now();
                atsRecord.dte_change_last__c = System.today();
                if(doDML){
                    Database.insertAsync(atsRecord,new ATSAsyncCallbackHandler()); 
                }
            } 
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'ATSHandler','Method__c'=>'insertATSRecord','Record_ID__c'=>atsRecord?.IDN_AUTH__c});
            system.Debug(ex.getMessage());
        }  
    }
    
    public static void insertATSRecord(Boolean doDML, List<batchsit_t_pos_trans_queue_ats__x> atsRecordList){
        try {
            if(!Test.isRunningTest() && atsRecordList!=null){
                for(batchsit_t_pos_trans_queue_ats__x atsRecord:atsRecordList){
                    atsRecord.createdbyid__c =  UserInfo.getUserId();
                    atsRecord.lastmodifiedbyid__c =  UserInfo.getUserId();
                    atsRecord.createddate__c =  System.now();
                    atsRecord.lastmodifieddate__c = System.now();
                    atsRecord.dte_change_last__c = System.today();
                }
                if(doDML){
                    Database.insertAsync(atsRecordList,new ATSAsyncCallbackHandler());
                }
            } 
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'ATSHandler','Method__c'=>'insertATSRecord','Record_ID__c'=>atsRecordList[0]?.IDN_AUTH__c});
            system.Debug(ex.getMessage());
        } 
    }
    
    public static void insertATSRecordForCaseIndividualAndIndividual(Boolean doDML, List<batchsit_t_pos_trans_queue_ats__x> atsRecordList){
        try {
            if(atsRecordList!=null){
                for(batchsit_t_pos_trans_queue_ats__x atsRecord:atsRecordList){
                    atsRecord.createdbyid__c =  UserInfo.getUserId();
                    atsRecord.lastmodifiedbyid__c =  UserInfo.getUserId();
                    atsRecord.createddate__c =  System.now();
                    atsRecord.lastmodifieddate__c = System.now();
                    atsRecord.dte_change_last__c = System.today();
                }
                if(doDML){
                    String asyncOnOffService = System.Label.Async_On_Off_Service;
                    if(Boolean.valueOf(asyncOnOffService)) {
                        Database.insertAsync(atsRecordList,new ATSAsyncCallbackHandlerIndividual());  
                    } else {
                        Database.insertAsync(atsRecordList,new ATSAsyncCallbackHandler()); 
                    }
                }
            } 
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'ATSHandler','Method__c'=>'insertATSRecord'});
            system.Debug(ex.getMessage());
        } 
    } 
}