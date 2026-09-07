global class  TeenEduBreakBatchSchedulable implements schedulable{
 global void execute(SchedulableContext sc)
    {
    TeenEduBreakBatch b = new TeenEduBreakBatch(); 
    database.executebatch(b,100);
    }
}