/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/16/2017                                                          
*  @description    Waitlist Trigger                            
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 25-Nov-2017                                                              
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version  
*  * CHAT-1157 :Whenever a T_SBSD_CASE_WTLST record is created or updated (related to the case), 
*  *           populate waitlist Status field in T_SBSD_CASE__c with value of T_SBSD_CASE_WTLST.CDE_STATUS_WTLST 
*  *           where today is on or between T_SBSD_CASE_WTLST.DTE_BEGIN_EFFV_WTLST and 
*  *           T_SBSD_CASE_WTLST.DTE_END_EFFV_WTLST
*  *
*  * Version: 2.0                                                                             
*  * Date: 05-Dec-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * CHAT-676 : Event Based Trigger 
*  * Version: 3.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger waitlistTrigger on T_SBSD_CASE_WTLST__c (before update,after insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('waitlistTrigger')) {
        return; //rest of the lines will not be executed
    }
    // Version-1 : CHAT-1157
    if(Trigger.isAfter){
        // added isUpdate for CCCAP-12874
        if(Trigger.isInsert || Trigger.isUpdate){
            waitlistServices.caseWaitlistStatusUpdate(Trigger.new);
        }
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_CASE_WTLST__c where Id=:trigger.newMap.keySet()],true);
        }
        
        //CHATS-5148 Defect Fix to update Eligiblity Date Changed on Case
        CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(
            CaseLastUpdatedServices.pluckIds(trigger.new, 'IDN_CASE__c')
        );
        
    }
    //start of version-2 : CHAT-676
    list<T_SBSD_CASE_WTLST__c> listWaitList = new list<T_SBSD_CASE_WTLST__c>();
    set<Id> waitlistCaseIds = new set<Id>();
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            waitlistServices.validateCounty(Trigger.New, Trigger.oldMap);
            
            for(T_SBSD_CASE_WTLST__c wtlst : Trigger.New){
                if((wtlst.CDE_REASON_REMOVAL__c == 'ATP') && (wtlst.CDE_STATUS_WTLST__c == 'REM') && (wtlst.DTE_BEGIN_EFFV_WTLST__c == date.today())){
            		waitlistCaseIds.add(wtlst.IDN_CASE__c);
                }
            }
            waitlistServices.triggerCorspdCR101(waitlistCaseIds);        
        }
    }
    //End of version-2
}