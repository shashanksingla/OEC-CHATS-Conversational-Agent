/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           1/19/2018                                                          
*  @description    Service Period Trigger                           
*  Modification Log:                                                                             
*                                                                                                                              
*  * Version: 1.0                                                                             
*  * Date: 19-Jan-2018                                                           
*  * Author: Bharadwaj Gaddam                                                 
*  * Description: copying salesforce Id to External Id                                                  

*********************************************************************************************/
trigger ServicePeriodTrigger on T_SERV_PERIOD__c  (after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('ServicePeriodTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SERV_PERIOD__c  where Id=:trigger.newMap.keySet()],true);
        }
    
    }

}