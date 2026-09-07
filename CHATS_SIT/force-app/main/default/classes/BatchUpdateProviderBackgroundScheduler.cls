/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/08/2023                                                          
*  @description    Schedulable for Provider Background Check Update Batch.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 02/08/2023                                                             
*  * Author: Raina Yeole                                                     
*  * Description: Initial version 
*********************************************************************************************/

global without sharing class BatchUpdateProviderBackgroundScheduler implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new BatchUpdateProviderBackground(), 200);
    }
}