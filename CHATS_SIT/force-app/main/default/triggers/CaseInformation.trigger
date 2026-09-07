/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           
*  @description    Case Information Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 
*  * Author: Gaurav Dharra 
*  * Description: Initial version                                                 
*  * Update DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c after case information is updated
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*  * Version: 3.0                                                                             
*  * Date: 05/28/2018                                                             
*  * Author: Bharadwaj Gaddam                                                   
*  * Description: Restricting user from creating not more than one Email Type

*********************************************************************************************/
trigger CaseInformation on T_SBSD_CASE_INFO__c (after insert, after update, before insert, before update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CaseInformation')) {
        return; //rest of the lines will not be executed
    }
    If(Trigger.isAfter){
        CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(
            CaseLastUpdatedServices.pluckIds(trigger.new, 'IDN_CASE__c')
        );
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_CASE_INFO__c where Id=:trigger.newMap.keySet()],true);
        }
        if(Trigger.isInsert || Trigger.isUpdate) {
            CaseInformationServices.insertCaseIndivToATSOnEmailUpdate(trigger.new, trigger.oldMap);
        }
    }
    
    if(Trigger.isBefore) {
        //CHATS-5014 Restricting user from creating not more than one Email Type
        CaseInformationServices.allowOnlyOneEmailType(trigger.new);
    }
}