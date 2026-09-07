global without sharing class DeleteArchivedRecordsBatchSchedulable implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new DeletedRecordArchivalBatch(), 200);
    }

}