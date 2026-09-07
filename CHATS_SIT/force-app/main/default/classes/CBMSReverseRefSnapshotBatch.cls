Global class CBMSReverseRefSnapshotBatch implements Database.Batchable<sObject>, Database.Stateful{
    /*************************************************************
Class Name      - CBMSReverseRefSnapshotBatch
Test Class      - 
Description     - Batch to capture initial snapshot for CBMS reverse Referral Mapping
Author          - Shashank Singla
Requiremnt      - CCCAP-10162
**************************************************************/
    global static List<Exception_Log__c> errors = new List<Exception_Log__c>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryStr ='SELECT ID,name,Case_Reverse_Refer_Track__c,CHATS_Reverse_Refer_Mode__c ';
        queryStr+= ',(Select id,CDE_STATUS_CASE__c,CDE_MODE_CASE__c from T_SBSD_CASE10__r where DTE_END_EFFV__c>=Today OR DTE_END_EFFV__c = null Order by DTE_BEGIN_EFFV__c,createddate Desc NULLS FIRST Limit 1) ';
        queryStr+= ',(select id,Auth_Reverse_Refer_Track__c,DTE_END_EFFV_AUTH__C from T_AUTH__r where DTE_END_EFFV_AUTH__C>TODAY or DTE_END_EFFV_AUTH__C=null) ';
        queryStr+= ',(select id from T_COPAY_DELINQC__r where DTE_RESOLN_DELINQC__c=null and AMT_DELINQC_COPAY_ENRLMT__c!=null) ';
        queryStr+= ' from T_SBSD_Case__c where Program_Type__c != NULL';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_SBSD_CASE__c> scope) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<T_SBSD_Case__c> otherCases = new List<T_SBSD_Case__c>();
            List<T_Auth__c> authsToUpdate = new List<T_Auth__c>();
            List<T_COPAY_DELINQC__c> parentFeeDToUpdate = new List<T_COPAY_DELINQC__c>();
            for(T_SBSD_Case__c cs: scope){
                if(cs.T_SBSD_CASE10__r!=null && !cs.T_SBSD_CASE10__r.isEmpty() &&
                   (cs.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c == 'OPN' || cs.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c == 'PEN' )){
                       String reverseReferTrack = cs.CHATS_Reverse_Refer_Mode__c ?? '' ;
                       if(cs.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c == 'PEN'){
                           reverseReferTrack += reverseReferTrack.contains('Pending Case')? '':(reverseReferTrack ==''? 'Pending Case':';Pending Case');
                               }
                       // find Auth to Update
                       for(T_Auth__c auth: cs.T_AUTH__r){
                           auth.Auth_Reverse_Refer_Track__c = true;
                           authsToUpdate.add(auth);
                           reverseReferTrack += reverseReferTrack.contains('Auth Creation')? '':(reverseReferTrack ==''? 'Auth Creation':';Auth Creation');
                               }
                       // find parent Fee D to Update
                       for(T_COPAY_DELINQC__c pfd : cs.T_COPAY_DELINQC__r){
                           pfd.Parent_fee_Reverse_Refer_Track__c = true;
                           parentFeeDToUpdate.add(pfd);
                           reverseReferTrack += reverseReferTrack.contains('Parent Fee Delinquency Creation')? '':(reverseReferTrack == '' ?'Parent Fee Delinquency Creation': ';Parent Fee Delinquency Creation');
                               }
                       if(reverseReferTrack!=''){
                           cs.Case_Reverse_Refer_Track__c = true;
                           cs.CHATS_Reverse_Refer_Mode__c = reverseReferTrack;
                           otherCases.add(cs); 
                       }
                   }
            }
            toggleTriggerCustomSettings(false);
            system.debug('***authsToUpdate****  '+authsToUpdate);
            update authsToUpdate;
            system.debug('***parentFeeDToUpdate***  '+parentFeeDToUpdate);
            update parentFeeDToUpdate;
            system.debug('***otherCases***  '+otherCases);
            update otherCases;
            toggleTriggerCustomSettings(true);
            
        } catch(Exception e) {
            Database.rollback(sp);            
            system.debug('****Exception Occured***  '+e.getMessage());
            errors.add(new Exception_Log__c(Class__c = 'CBMSReverseRefSnapshotBatch', Method__c = 'finish', Exception_Message__c = 'CBMS Reverse Referral Update: '+e.getMessage(), Exception_Type__c = 'Error'));
            
        }
    }
    global void finish(Database.BatchableContext bc) {
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'CBMSReverseRefSnapshotBatch'});
        }
    }
    private static void toggleTriggerCustomSettings(boolean isActive){
        List<Triggers_On_Off_Settings__c> triggercustomToUpdate = new List<Triggers_On_Off_Settings__c>();
        Triggers_On_Off_Settings__c triggerOnOffAuthRecord = Triggers_On_Off_Settings__c.getInstance('AuthorizationTrigger') ?? new Triggers_On_Off_Settings__c(name='AuthorizationTrigger');
        triggerOnOffAuthRecord.Active__c= isActive;
        triggercustomToUpdate.add(triggerOnOffAuthRecord);
        Triggers_On_Off_Settings__c triggerOnOffPFDRecord = Triggers_On_Off_Settings__c.getInstance('ParentFeeDelinquencyTrigger') ?? new Triggers_On_Off_Settings__c(name='ParentFeeDelinquencyTrigger');
        triggerOnOffPFDRecord.Active__c= isActive;
        triggercustomToUpdate.add(triggerOnOffPFDRecord);
        Triggers_On_Off_Settings__c triggerOnOffCaseRecord = Triggers_On_Off_Settings__c.getInstance('CaseTrigger') ?? new Triggers_On_Off_Settings__c(name='CaseTrigger');
        triggerOnOffCaseRecord.Active__c= isActive;
        triggercustomToUpdate.add(triggerOnOffCaseRecord);
        update triggercustomToUpdate;
    }
}