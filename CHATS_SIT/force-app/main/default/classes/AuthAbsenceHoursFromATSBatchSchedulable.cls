/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           08/13/2019                                                          
*  @description    Schedulable class for AuthAbsenceHoursFromATS batch class.

*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 02-Sept-2020                                                             
*  * Author: Azharuddin Mohammad                                                     
*  * Description: Initial version 
*********************************************************************************************/
global without sharing class AuthAbsenceHoursFromATSBatchSchedulable implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new AuthAbsenceHoursFromATS(), 200);
    }

}