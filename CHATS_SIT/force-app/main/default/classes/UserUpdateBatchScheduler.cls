/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           10/31/2019                                                          
*  @description    Schedulable class for UserUpdateBatch batch class.

*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 31-Oct-2019                                                             
*  * Author: ANUJ WALI                                                     
*  * Description: Initial version 
*********************************************************************************************/
global without sharing class UserUpdateBatchScheduler implements schedulable{
    global void execute(SchedulableContext sc){
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
    }

}