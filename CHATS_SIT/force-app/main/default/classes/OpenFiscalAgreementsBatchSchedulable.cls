/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           08/26/2020                                                          
*  @description    Schedulable class for OpenFiscalAgreementsBatch batch class.

*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 08/26/2020
*  * Author: Balamurugan Chinnaiah
*  * Description: Initial version 
*********************************************************************************************/
global without sharing class OpenFiscalAgreementsBatchSchedulable implements schedulable{
    global void execute(SchedulableContext sc){
        database.executebatch(new OpenFiscalAgreementsBatch(), 200);
    }

}