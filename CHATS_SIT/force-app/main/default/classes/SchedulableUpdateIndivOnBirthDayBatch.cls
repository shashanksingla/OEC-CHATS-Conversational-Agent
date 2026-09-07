global without sharing class SchedulableUpdateIndivOnBirthDayBatch implements schedulable {
global void execute(SchedulableContext sc)
    {
    UpdateIndivOnBirthDayBatchApxCtrl b = new UpdateIndivOnBirthDayBatchApxCtrl(); 
      database.executebatch(b,10);
    }
}