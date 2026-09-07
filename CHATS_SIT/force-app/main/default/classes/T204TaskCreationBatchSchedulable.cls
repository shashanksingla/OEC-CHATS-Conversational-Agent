/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/27/2022                                                          
*  @description    Schedulable for T204 Task Creation Batch.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 27-Nov-2022                                                             
*  * Author: Azharuddin Mohammad                                                     
*  * Description: Initial version 
*********************************************************************************************/

global without sharing class T204TaskCreationBatchSchedulable implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new T204TaskCreationBatch(), 200);
    }
}