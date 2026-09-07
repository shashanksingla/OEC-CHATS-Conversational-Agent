/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/29/2022                                                          
*  @description    Schedulable for CR202 Correspondence Creation Batch.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 29-Nov-2022                                                             
*  * Author: Raina Yeole                                                     
*  * Description: Initial version 
*********************************************************************************************/

global without sharing class BatchInsertCR202CorspdScheduler implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new BatchInsertCR202Corspd(), 200);
    }
}