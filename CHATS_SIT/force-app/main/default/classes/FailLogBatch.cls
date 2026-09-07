global with sharing class FailLogBatch implements Database.Batchable<sObject> {
    global List<SObject> start(Database.BatchableContext bc) {
        //List<Batch_Log__c> salesforceBatchLogList = new List<Batch_Log__c>();
        List<SObject> herokuLogList = new List<SObject>();
        DateTime utTime = System.now();
        TimeZone tz = UserInfo.getTimeZone();
        DateTime currTime = utTime.addSeconds((tz.getOffset(utTime)/1000));
        DateTime last24Hrs = currTime.addHours(-12);
        String tableName = Label.herokuBatchLogTableName; 
        //String externalObjectName = Label.
        try{

            
            String failedBatchLogQuery = 'SELECT Id, idn_batch_log__c, createdDate__c, Batch_Name__c, Records_Processed__c , Records_Failed__c,Status__c, Error_Message__c, batch_run_date__c, start_time__c, end_time__c ';
            failedBatchLogQuery += 'FROM ' + tableName;
            failedBatchLogQuery += ' WHERE createdDate__c >= :last24Hrs AND Status__c = \'FAILED\' Order by createdDate__c DESC';

            herokuLogList = Database.query(failedBatchLogQuery);
            // for(sObject extObj : herokuLogList){
            //     Batch_Log__c singleObj = new Batch_Log__c();
            //     singleObj.IDN_EXTNL__c = (String)extObj.get('idn_extnl__c');
            //     singleObj.Batch_Name__c = (String)extObj.get('batch_name__c');
            //     singleObj.Status__c = (String)extObj.get('status__c');
            //     singleObj.Records_Processed__c = (Decimal)extObj.get('records_processed__c');
            //     singleObj.Error_Message__c = (String)extObj.get('error_message__c');
            //     Datetime batchRunDatetime = (Datetime)extObj.get('batch_run_date__c');
            //     singleObj.Date__c = Date.newinstance(batchRunDatetime.year(), batchRunDatetime.month(), batchRunDatetime.day());
            //     singleObj.start_time__c = (DateTime)extObj.get('start_time__c');
            //     singleObj.end_time__c = (DateTime)extObj.get('end_time__c');
            //     salesforceBatchLogList.add(singleObj);
                
            // }
        }catch(Exception e){
            Exception_Log__c errorLog = new Exception_Log__c();
            errorLog.Exception_Message__c = 'ERROR IN FailLogBatch:' + e.getMessage();
            List<Exception_Log__c> errorList = new List<Exception_Log__c>();
            errorList.add(errorLog);
            GenericDMLHandler.insertRecords(errorList, null);
        }
        return herokuLogList;
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        Map<String, List<SObject>> failedBatchLogMapByName = new Map<String, List<SObject>>();
        for(SObject blObj : scope){
            if(failedBatchLogMapByName.get((String)blObj.get('batch_name__c')) == null ){
                List<SObject> logList = new List<SObject>();
                logList.add(blObj);
                failedBatchLogMapByName.put((String)blObj.get('batch_name__c'), logList);
            }
            else{
                List<SObject> existingLogList = failedBatchLogMapByName.get((String)blObj.get('batch_name__c'));
                existingLogList.add(blObj);
                failedBatchLogMapByName.put((String)blObj.get('batch_name__c'), existingLogList);
            }
        }

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(String keyString : failedBatchLogMapByName.keyset()){
            List<SObject> logsByName = failedBatchLogMapByName.get(keyString);

            FailLogEmailHelper helperObject = new FailLogEmailHelper(logsByName,keyString);
            emailList.add(helperObject.createEmails(Label.chats24hrSupportEmail));
        }
        Messaging.sendEmail(emailList);

    }

    global void finish(Database.BatchableContext BC){
    }

}