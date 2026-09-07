/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/16/2017                                                          
*  @description    Parent Fee Delinquency Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 16-Nov-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version                                                 
*  *CHAT-1044: Can only be Month of Reported Delinquency Date, month before, or 2 months before
*  *CHAT-1048: Can only be Year of DTE_RPTD_DELINQC, year of month before, or year of 2 months before
*
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger ParentFeeDelinquencyTrigger on T_COPAY_DELINQC__c (before insert, before update, after insert,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('ParentFeeDelinquencyTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isBefore){
        if((Trigger.isInsert)|| (Trigger.isUpdate)){
            parentFeeDelinquencyServices.delinqcMonthYear(Trigger.new);
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_COPAY_DELINQC__c where Id=:trigger.newMap.keySet()],true);
        }
        if(Trigger.isInsert || Trigger.isUpdate){
            parentFeeDelinquencyServices.markReverseRefOnCase(Trigger.newMap,Trigger.oldMap); // for CCCAP-10162 by Shashank
        }
    }
}