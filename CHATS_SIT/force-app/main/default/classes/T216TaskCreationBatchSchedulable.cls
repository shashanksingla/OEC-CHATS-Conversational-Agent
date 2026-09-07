/*************************************************************
Class Name	    - T216TaskCreationBatchSchedulable
Test Class	    - T216TaskCreationBatch_Test
Description     - Schedular class to execute 'T216' task creation batch
Author          - Rishav Maji
Requiremnt		- Project 282 : CCCAP-4373
**************************************************************/
global class T216TaskCreationBatchSchedulable implements Schedulable {
    global void execute(SchedulableContext ctx) {
        database.executebatch(new T216TaskCreationBatch());
    }
}