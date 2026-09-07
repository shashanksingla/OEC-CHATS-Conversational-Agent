/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           08/13/2019                                                          
*  @description    Schedulable class for CloseFiscalAgreementsBatch batch class.

*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 13-Aug-2019                                                             
*  * Author: Vineet Srivastava                                                     
*  * Description: Initial version 
*********************************************************************************************/
global without sharing class CLoseFiscalAgreementsBatchSchedulable implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new CloseFiscalAgreementsBatch(), 200);
    }

}