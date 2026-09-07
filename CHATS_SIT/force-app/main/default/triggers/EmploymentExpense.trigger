/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           
*  @description    Employment Expense Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 
*  * Author: Gaurav Dharra 
*  * Description: Initial version                                                 
*  * Update DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c after employment expense is updated
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger EmploymentExpense on T_SBSD_EMPLMT_EXP__c (after insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('EmploymentExpense')) {
        return; //rest of the lines will not be executed
    }
    If(Trigger.isAfter){
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.getIndividualsFromRelationship(
                'IDN_EMPLMT_INDIV__r.IDN_CLIENT__c', 'T_SBSD_EMPLMT_EXP__c', trigger.new)
        );
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_EMPLMT_EXP__c where Id=:trigger.newMap.keySet()],true);
        }
    }
}