/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           
*  @description    Employment Information Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 
*  * Author: Gaurav Dharra 
*  * Description: Initial version                                                 
*  * Update DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c after employment information is updated
*********************************************************************************************/
trigger EmploymentInformationTrigger on T_INDIV_EMPLMT_INFO__c (before insert,before update,after insert, after update,after delete) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('EmploymentInformationTrigger')) {
        return; //rest of the lines will not be executed
    }
    If(Trigger.isAfter && (!Trigger.isDelete)){
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.getIndividualsFromRelationship(
                'IDN_EMPLMT_INDIV__r.IDN_CLIENT__c', 'T_INDIV_EMPLMT_INFO__c', trigger.new)
        );
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_INDIV_EMPLMT_INFO__c where Id=:trigger.newMap.keySet()],true);
        }
        if(!Test.isRunningTest()){
        CaseLastUpdatedServices.updateEmpInfoOnParentObject(Trigger.new);
		}
    }

    If(Trigger.isBefore ){
        if(Trigger.isInsert || Trigger.isUpdate){
            if(!Test.isRunningTest()){
            CaseLastUpdatedServices.updateEmpInfoTmpBrkEndDate(Trigger.new,Trigger.oldMap);

            }
        }
        
    }
    if(Trigger.isAfter){
        if(Trigger.isDelete){
            if(!Test.isRunningTest()){
            CaseLastUpdatedServices.updateEmpTmpBrkAfterDlt(Trigger.old);
            }
        }
            
    }
}