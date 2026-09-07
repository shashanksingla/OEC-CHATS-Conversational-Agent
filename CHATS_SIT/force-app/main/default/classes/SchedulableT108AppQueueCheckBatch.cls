/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/02/2019                                                          
*  @description    Schedulable class for T108_AppQueueCheckBatch batch class.
*********************************************************************************************/
global without sharing class SchedulableT108AppQueueCheckBatch implements schedulable{
    global void execute(SchedulableContext sc)
    {
        T108_AppQueueCheckBatch batchprocess = new T108_AppQueueCheckBatch(); 
        database.executebatch(batchprocess);
    }
}