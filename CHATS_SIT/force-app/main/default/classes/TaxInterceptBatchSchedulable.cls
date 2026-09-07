/*************************************************************
Class Name	    - TaxInterceptBatchSchedulable
Test Class	    - TaxInterceptCreationBatch_Test
Description     - Schedular class to execute Tax Intercept batch
Author          - Rishav Maji
Requiremnt		- Project 282 : CCCAP-4414
**************************************************************/
global class TaxInterceptBatchSchedulable implements Schedulable {
    global void execute(SchedulableContext ctx) {
        TaxInterceptCreationBatch ticb = new TaxInterceptCreationBatch();
        database.executebatch(ticb, 1);
    }
}