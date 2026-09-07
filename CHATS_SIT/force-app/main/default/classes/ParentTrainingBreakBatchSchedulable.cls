global class  ParentTrainingBreakBatchSchedulable implements schedulable{
 global void execute(SchedulableContext sc)
    {
    ParentTrainingBreakBatch b = new ParentTrainingBreakBatch(); 
    database.executebatch(b,100);
    }
}