/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           05/11/2023                                                         
*  @description    Schedulable class for CaseMissingInfoTrackingBatch batch class.

*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 11-May-2023                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Initial version 
*********************************************************************************************/
global without sharing class CaseMissingInfoTrackingBatchSchedulable implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new CaseMissingInfoTrackingBatch(), 1);
    }

}