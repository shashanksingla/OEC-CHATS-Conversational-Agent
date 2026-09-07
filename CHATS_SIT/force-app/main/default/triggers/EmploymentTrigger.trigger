/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           
*  @description    Employment Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 
*  * Author: Gaurav Dharra 
*  * Description: Initial version                                                 
*  * Update DTE_CHGD_LAST_DATA_ELIGTY__c, IND_CHGD_DATA_ELIGTY__c fields on T_SBSD_CASE__c after employment is updated
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger EmploymentTrigger on T_SBSD_INDIV_EMPLMT__c (before insert, before update, after insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('EmploymentTrigger')) {
        return; //rest of the lines will not be executed
    }
    
    if(Trigger.isUpdate){
        boolean isFieldUpdated = isAnyFieldUpdated();
        if(!isFieldUpdated)  
            return;
    }
    
    private Boolean isAnyFieldUpdated(){
        Boolean returnFlag = false;
        if(Trigger.isUpdate){
            Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.T_SBSD_CASE_INDIV__C.fields.getMap(); 
            for(T_SBSD_INDIV_EMPLMT__c newRecrd : trigger.new){
                T_SBSD_INDIV_EMPLMT__c oldRecrd = trigger.oldMap.get(newRecrd.Id);
                for (String str : mapFields.keyset()){ 
                    try { 
                        if(newRecrd.get(str) != oldRecrd.get(str) && (str != 'lastmodifieddate' && str != 'lastmodifiedbyid'  && str != 'systemmodstamp' && str != 'CDE_WAGE_MIN__c' )){ 
                            returnFlag = true;
                            System.Debug('IGORU Field changed: ' + str + '. The value has changed from: ' + oldRecrd.get(str) + ' to: ' + newRecrd.get(str)); 
                        } 
                    } 
                    catch (Exception e) { 
                        System.Debug('Error: ' + e); 
                    } 
                }
            }
        }
        system.debug('IGORU check :::' + returnFlag);
        return returnFlag;
    }
    
    if(Trigger.isBefore){
        EmploymentServices.validateEmploymentCounty(Trigger.new, Trigger.oldMap);
    }
    
    if(Trigger.isAfter){
        CaseLastUpdatedServices.updateCaseLastChangeFromIndividualIds(
            CaseLastUpdatedServices.pluckIds(
                trigger.new, 'IDN_CLIENT__c')
        );
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_INDIV_EMPLMT__c where Id=:trigger.newMap.keySet()],true);
        }
    }
    
}