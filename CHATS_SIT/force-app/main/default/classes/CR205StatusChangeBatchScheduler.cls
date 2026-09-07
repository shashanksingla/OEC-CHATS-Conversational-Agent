global class CR205StatusChangeBatchScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      Database.executeBatch(new ChangeCR205StatusToRequestedBatch(), 200);
   }
}