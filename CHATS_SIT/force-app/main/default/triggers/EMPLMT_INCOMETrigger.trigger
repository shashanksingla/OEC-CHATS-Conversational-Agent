/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Employment Income Trigger   
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/

trigger EMPLMT_INCOMETrigger on T_EMPLMT_INCOME__c (after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('EMPLMT_INCOMETrigger')) {
        return; //rest of the lines will not be executed
    }
	if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_EMPLMT_INCOME__c where Id=:trigger.newMap.keySet()],true);
        }
    
    }
}