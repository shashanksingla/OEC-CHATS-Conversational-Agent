/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/20/2017                                                          
*  @description    Employment Verification Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 20-DEC-2017                                                             
*  * Author: Bharadwaj Gaddam                                                     
*  * Description: Initial version                                                 
*  * updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger EmploymentVerificationTrigger on T_INDIV_EMPLMT_VERIF__c (after insert, after update,before insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('EmploymentVerificationTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        //updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.getIndividualsFromRelationship(
                'IDN_EMPLMT_INDIV__r.IDN_CLIENT__c', 'T_INDIV_EMPLMT_VERIF__c', trigger.new)
        );
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_INDIV_EMPLMT_VERIF__c where Id=:trigger.newMap.keySet()],true);
        }
    }
    
    //CHATS-6468 Prod Fix to avoid duplicate Employment Verification records
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            CaseLastUpdatedServices.duplicateEmploymentVerificationCheck(trigger.new);
        }
    
    }
    
}