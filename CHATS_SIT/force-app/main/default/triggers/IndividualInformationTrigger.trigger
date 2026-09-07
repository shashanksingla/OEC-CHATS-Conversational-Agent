/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/20/2017                                                          
*  @description    Individual Information Trigger                           
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
trigger IndividualInformationTrigger on T_SBSD_INDIV_INFO__c (after insert, after update, before insert, before update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('IndividualInformationTrigger')) {
        return; //rest of the lines will not be executed
    }
     if(Trigger.isAfter) {
        //updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            IndividualInformationServices.getIndividualsInformationBasedonType(trigger.new));
         if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_INDIV_INFO__c where Id=:trigger.newMap.keySet()],true);
        }
    }
    if(Trigger.isBefore) {
        if(Trigger.isInsert || Trigger.isUpdate) {
            IndividualInformationServices.checkDuplicateCitizenshipRecords(trigger.new);
        }
    }

}