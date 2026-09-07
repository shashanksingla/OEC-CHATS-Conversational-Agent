global without sharing class JunkRecordDeletionBatchSchedulable implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new JunkRecordDeletionBatch(), 10);
    }
}