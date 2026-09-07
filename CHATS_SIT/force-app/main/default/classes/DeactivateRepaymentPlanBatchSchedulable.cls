global without sharing class DeactivateRepaymentPlanBatchSchedulable implements schedulable{
	global void execute(SchedulableContext sc){
        database.executebatch(new DeactivateRepaymentPlanBatch(), 200);
    }
}