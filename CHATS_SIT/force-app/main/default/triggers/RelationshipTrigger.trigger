/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/20/2017                                                          
*  @description    Relationship Trigger                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 20-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                     
*  * Description: Initial version                                                 
*  * updates DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c

*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger RelationshipTrigger on T_INDIV_REL__c (before insert, after insert, after update, after delete) {
    Boolean doNotRunTrigger = TriggersOnOffServices.triggerStatus('caseIndividualTrigger');
    
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            RelationshipServices.relationshipValidation(trigger.new);
            RelationshipServices.beginDatePopulation(trigger.new);
        }
    }
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert || Trigger.isUpdate) {
            if(!doNotRunTrigger) {
                CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
                    CaseLastUpdatedServices.pluckIds(trigger.new,'IDN_CLIENT__c'));
            }
            RelationshipServices.updateIndividualWithHasAllowedRelationship(trigger.new);
        }
        if(Trigger.isInsert) {
            if(!doNotRunTrigger) {
                //copying salesforce Id to External Id
                CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_INDIV_REL__c where Id=:trigger.newMap.keySet()],true);
            }
        }
        
        if(Trigger.isDelete) {
            RelationshipServices.updateIndividualWithHasAllowedRelationship(trigger.old);
        }

        if(Trigger.isUpdate){
            //CCCAP-972
            RelationshipServices.relationshipDateOverlapping(Trigger.new);
         }
    } 
    
}