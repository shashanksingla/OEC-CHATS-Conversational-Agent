global without sharing class DeletedRecordArchivalBatchSchedulable implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new DeletedRecordArchivalBatch(), 1);
    }

}