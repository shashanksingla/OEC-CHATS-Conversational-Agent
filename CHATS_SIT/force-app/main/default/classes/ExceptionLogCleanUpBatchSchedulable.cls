/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           07/10/2018                                                          
*  @description    Schedulable class for Scheduling cleaning up of Exception Log Object.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 10-Jul-2018                                                             
*  * Author: Vineet Srivastava                                                     
*  * Description: Initial version 
*********************************************************************************************/
global without sharing class ExceptionLogCleanUpBatchSchedulable implements schedulable{
global void execute(SchedulableContext sc){
        database.executebatch(new ExceptionLogCleanUpBatch(), 200);
    }
}