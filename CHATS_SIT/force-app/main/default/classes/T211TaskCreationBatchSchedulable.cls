/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           07/29/2020                                                          
*  @description    Schedulable for T211 Task Creation Batch.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 29-Jul-2020                                                             
*  * Author: Sahil Garg                                                     
*  * Description: Initial version 
*********************************************************************************************/
global without sharing class T211TaskCreationBatchSchedulable implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new T211TaskCreationBatch(), 200);
    }
}