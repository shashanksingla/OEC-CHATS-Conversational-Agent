/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/20/2017                                                          
*  @description    Case Address Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 20-Nov-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version                                                 
*  *CHAT-1158: Adr City is required for AdrType is "Mailing" and is not Homeless
*  *           Adr City is required for AdrType is "HOME" - Validation Rule implemented
*  *CHAT-1170: If IND_IS_HOMELESS = YES from T_SBSD_CASE_HOMELESS, then default to "Declared Homeless"
*  *CHAT-1159: Adr Line 1 is required for AdrType is "Mailing" and is not Homeless
*  *           Adr Line 1 is required for AdrType is "HOME" - Validation Rule implemented
*  *CHAT-1171: A case can only have one related Residential Address record (CDE_TYPE_ADR = 'HOM') and 
*  *           one related Mailing Address record (CDE_TYPE_ADR = 'MAL')
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger caseAddressTrigger on T_SBSD_CASE_ADR__c (before insert, before Update, after insert, after update, after delete) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('caseAddressTrigger')) {
        return; //rest of the lines will not be executed
    }
    // added for CCCAP-14909
    if(caseAddressServices.disableTrigger){
        return;
    }
    if(Trigger.isBefore){
        if((Trigger.isInsert)|| (Trigger.isUpdate)){
            //CHAT-1158,1159,1170,1171
            caseAddressServices.caseAddressValidations(Trigger.new);
            caseAddressServices.avoidDuplicateCaseAddresses(Trigger.new);
        }
        /*if(Trigger.isInsert){
            caseAddressServices.updateCaseAddressEndDate(Trigger.new);
        }*/
        
    }
    
    If(Trigger.isAfter){
        //updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c after case address is updated
        if(Trigger.isInsert || Trigger.isUpdate) {
        CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(
            CaseLastUpdatedServices.pluckIds(trigger.new, 'IDN_CASE__c')
        );
         caseAddressServices.caseAddressesChangeTaskTrigger(Trigger.new,Trigger.oldMap);
        }
        if(Trigger.isInsert) {
            caseAddressServices.disableTrigger = true; // added for CCCAP-14909
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_CASE_ADR__c where Id=:trigger.newMap.keySet()],true);
            caseAddressServices.disableTrigger = false; // added for CCCAP-14909
        }
        if(Trigger.isDelete){
             caseAddressServices.deleteCaseAddressEndDate(Trigger.old);
        }
    }
}