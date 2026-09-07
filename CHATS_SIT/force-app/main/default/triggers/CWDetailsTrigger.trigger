/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    CW Additional Information Trigger   
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger CWDetailsTrigger on T_CW_ADDNL_INFO__c (before insert,before update,after insert,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CWDetailsTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_CW_ADDNL_INFO__c where Id=:trigger.newMap.keySet()],true);
        }
        
        //CHATS-5148 Defect Fix to update Eligiblity Date Changed on Case
        CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(
            CaseLastUpdatedServices.pluckIds(trigger.new, 'IDN_CASE_CHATS__c')
        );
        
    }
    
    if(Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate){
            CaseLastUpdatedServices.updateCWDetailEndDate(Trigger.new, Trigger.isInsert ? true:false);
        }
        
    }
}