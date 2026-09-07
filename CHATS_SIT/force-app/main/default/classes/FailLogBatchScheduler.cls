global without sharing class FailLogBatchScheduler implements schedulable{
    global void execute(SchedulableContext sc){
        FailLogBatch batchprocess = new FailLogBatch();
        Database.executeBatch(batchprocess); 
    }

}