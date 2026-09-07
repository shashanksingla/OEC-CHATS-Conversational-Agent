/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           
*  @description    Case Phone Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 
*  * Author: Gaurav Dharra 
*  * Description: Initial version                                                 
*  * Update DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c after case phone is updated
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger CasePhone on T_SBSD_CASE_PHONE__c (before insert,after insert, after update,after delete) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CasePhone')) {
        return; //rest of the lines will not be executed
    }
	If(Trigger.isAfter){
		if(Trigger.isInsert || Trigger.isUpdate) {
        CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(
            CaseLastUpdatedServices.pluckIds(trigger.new, 'IDN_CASE__c')
        );
		}
         if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_CASE_PHONE__c where Id=:trigger.newMap.keySet()],true);
        }
        if(Trigger.isDelete){
             caseAddressServices.deleteCasePhoneEndDate(Trigger.old);
        }
    }
    if(Trigger.isBefore){
        
        if(Trigger.isInsert){
            caseAddressServices.updateCasePhoneEndDate(Trigger.new);
        }
        
    }
}