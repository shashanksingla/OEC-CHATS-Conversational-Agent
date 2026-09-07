/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/11/2017                                                          
*  @description    Handler class for Fiscal Agreement Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 9-Nov-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: CHAT-905 : updates CDE_TYPE_FACILITY__c on Fiscal Agreements                                            
*  *
*  * Version: 2.0                                                                             
*  * Date: 7-Dec-2017                                                             
*  * Author: Azharuddin Mohammad
*  * Description: Chat-683 - Event Based correspondence trigger -CR704,CR706
*  *
*  * Version: 3.0                                                                             
*  * Date: 11-Dec-2017                                                             
*  * Author: Azharuddin Mohammad
*  * Description: Chat-488 - Fiscal Agrmnt Begin Date should be greater than the end date(max) of 
*  *                         previous Fiscal Agreements
*  * Version: 4.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger FiscalAgreementTrigger on T_PROVR_FISCAL_AGREMENT__c (before insert, before update, after update,after insert,before delete) {
    
    // Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('FiscalAgreementTrigger')) {
        return; // Rest of the lines will not be executed
    }
    
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            FiscalAgreementServices.closeExistingFA(Trigger.new, Trigger.oldMap); // CHAT-906
            FiscalAgreementServices.endRateSchedule(Trigger.new, Trigger.oldMap); // CHAT-906
            FiscalAgreementServices.updateTaskStatus(Trigger.new, Trigger.oldMap); // CHAT-1134
            FiscalAgreementServices.insertATSRecord(Trigger.new); // CHATS-3824
            FiscalAgreementServices.updateProviderFields(Trigger.newMap); // Added by Rishav for CCCAP-7432
            if(!Test.isRunningTest()){
                FiscalAgreementServices.triggerCorspdCR708(Trigger.new, Trigger.old);
            }
        }
        if(Trigger.isInsert) {
            // Copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_PROVR_FISCAL_AGREMENT__c where Id=:trigger.newMap.keySet()],true);
            FiscalAgreementServices.insertATSRecord(Trigger.new); // CHATS-3824
            FiscalAgreementServices.triggerCorspdCR704orCR706(Trigger.new); // CHAT-683 on 05/24/2018
        }
    }
    
    if(Trigger.isBefore) {
        if(Trigger.isInsert){
            FiscalAgreementServices.updateFacilityTypeonFiscalAgrmntonBeforeInsert(Trigger.new); // CHAT-905 (updates CDE_TYPE_FACILITY__c on Fiscal Agreements)
            FiscalAgreementServices.updateEndateonInsert(Trigger.new); // CHAT-907
            FiscalAgreementServices.validateExistingFiscalAgreement(Trigger.new, null); // CHAT-2236
            FiscalAgreementServices.agrmntBeginDate(Trigger.new,null);
        }
        if(Trigger.isUpdate){
       //     FiscalAgreementServices.updateEndateonUpdate(Trigger.new,Trigger.oldMap); // CHAT-907 
            FiscalAgreementServices.validateExistingFiscalAgreement(Trigger.new, Trigger.oldMap); // CHAT-2236
            FiscalAgreementServices.agrmntBeginDate(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isDelete){
            //check the type before deleting FA
            FiscalAgreementServices.beforeDeleteCheckFiscalAgreementType(Trigger.old);
            //delete child Rate Schedule records
            FiscalAgreementServices.deleteFiscalAgreeChildRecords(Trigger.old); 
        }
    }
}