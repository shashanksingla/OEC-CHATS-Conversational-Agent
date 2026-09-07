/*************************************************************
Class Name	    - T555TaskCreationBatchSchedulable
Test Class	    - T555TaskCreationBatch_Test
Description     - Schedular class to execute 'T555' task creation batch
Author          - Diya Chaudhary
Requiremnt		- Project 418 : CCCAP-6984
**************************************************************/
global class AuthTaskBasedOnEnrollBatchSchedulable implements Schedulable {
    global void execute(SchedulableContext ctx) {
        database.executebatch(new AuthTaskBasedOnEnrollBatchApxCtrl());
    }
}