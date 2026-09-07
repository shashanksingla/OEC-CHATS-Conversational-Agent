global class CountyDropInDayBatchSchedulable implements schedulable{
 global void execute(SchedulableContext sc)
    {
    CountyDropInDaysBatchApxCtrl b = new CountyDropInDaysBatchApxCtrl(); 
    database.executebatch(b,100);
    }
}