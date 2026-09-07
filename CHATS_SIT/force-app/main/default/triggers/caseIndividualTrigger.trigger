/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/11/2017                                                          
*  @description    Case Individual Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 9-Nov-2017                                                             
*  * Author: Azharuddin Mohammad                                                     
*  * Description: Initial version
*  * CHAT-1204 : T_SBSD_CASE_INDIV-DTE_BEGIN_EFFV cannot be before DTE_BEGIN_EFFV of any T_AUTH records with a status of Authorized
*  * CHAT-1200 : If the child is not in Joint custody (T_INDIV_CUST) and they are already on another case, do not allow them to be added to a second case
*  * CHAT-1203 : creating SBSD_INIDV_ROLE record when Primary indicator is set to true
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger caseIndividualTrigger on T_SBSD_CASE_INDIV__c (before insert, before update, after update,after insert,before delete,after delete) {
    if(caseIndividualServices.disableTrigger){
        return;
    }
    Boolean doNotRunTrigger = TriggersOnOffServices.triggerStatus('caseIndividualTrigger');
    if(!doNotRunTrigger){
        if(Trigger.isUpdate){
            boolean isFieldUpdated = isAnyFieldUpdated();
            if(!isFieldUpdated)  
                return;
        }
        if(Trigger.isBefore){
            if((Trigger.isInsert) || (Trigger.isUpdate)){
                //CHAT-1204
                caseIndividualServices.effvBeginDate(trigger.new, trigger.oldMap);
                //Chat-1200
                caseIndividualServices.indivCaseAlreadyAssigned(trigger.new);
            }
            
            //CHAT-1203
            if((Trigger.isUpdate)|| (Trigger.isInsert)){
                caseIndividualServices.prmryCareTakerCannotUpdtd(trigger.new, trigger.oldMap);
            }
            if(Trigger.isDelete){
                caseIndividualServices.handleCaseIndivUpdatesforUFE(trigger.new,Trigger.oldMap);
            }
        }
        if(Trigger.isAfter) {
            
            if(Trigger.isInsert || Trigger.isUpdate) {
                Boolean isATSRerun;
                List<T_SBSD_CASE_INDIV__c> caseIndivToCreateRole = new List<T_SBSD_CASE_INDIV__c>();
                for(T_SBSD_CASE_INDIV__c eachCaseindiv : trigger.new){
            if(eachCaseIndiv.IND_CRTKR__c && !(Trigger.isUpdate && eachCaseindiv.DTE_END_EFFV__c != null && trigger.oldMap.get(eachCaseindiv.Id).DTE_END_EFFV__c == null)) { // New role record need not be created if we are just end dating PC CCCAP-15656
                caseIndivToCreateRole.add(eachCaseindiv);
              } 
                    if(Trigger.isUpdate){
                        caseIndividualServices.updateIndividualEmailInCaseInfo(Trigger.newMap,trigger.oldMap); //Added for Hotfix CCCAP-3305
                        if(caseIndividualServices.caseIndivRecordMap != null){
                            if(!caseIndividualServices.caseIndivRecordMap.containsKey(eachCaseindiv.id)){
                                caseIndividualServices.caseIndivRecordMap.put(eachCaseindiv.id,false);
                            }
                        }else{
                            caseIndividualServices.caseIndivRecordMap.put(eachCaseindiv.id,false);
                        }
                        
                    }
                }
                if(Trigger.isUpdate){
                    for(T_SBSD_CASE_INDIV__c eachCaseindiv : trigger.new){
                        if(Trigger.isUpdate){
                            if(caseIndividualServices.caseIndivRecordMap.get(eachCaseindiv.id)){
                                isATSRerun= false;
                            }else{
                                isATSRerun = true;
                                break;
                            }
                        }
                    }
                }
                caseIndividualServices.createCaseIndivRoleRecord(caseIndivToCreateRole); // CHAT-1203
                
                CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(
                    CaseLastUpdatedServices.pluckIds(trigger.new,'IDN_CASE__c'));
                if((!CaseIndividualServices.atsRecordsCreated) && (Trigger.isInsert)){
                    CaseIndividualServices.insertATSRecord(trigger.new);
                    CaseIndividualServices.atsRecordsCreated = true;
                    
                }
                if(Trigger.isUpdate){
                    if(isATSRerun){
                        CaseIndividualServices.insertATSRecord(trigger.new);
                        // CaseIndividualServices.atsRecordsCreated = true;
                        for(T_SBSD_CASE_INDIV__c caseIndivRec:trigger.new) {
                            caseIndividualServices.caseIndivRecordMap.put(caseIndivRec.id,true);
                            
                        }
                    }
                }
                /*else{
                    Exception_Log__c ExceptionLog = new Exception_Log__c();
                    ExceptionLog.Class__c = 'caseIndividualTrigger';
                    ExceptionLog.Method__c = 'CaseIndividualServices.insertATSRecord';
                    //ExceptionLog.Log_Type__c = 'Info';
                    // ExceptionLog.CreatedById = UserInfo.getUserId();
                    //ExceptionLog.CreatedDate = system.today();
                    String serializeList = JSON.serialize(trigger.new);
                    serializeList = serializeList.length() > 131071 ? serializeList.substring(0,131071) : serializeList;
                    ExceptionLog.Stack_Trace__c = serializeList;
                    insert ExceptionLog;
                }*/
                
                //CCCAP-341
                caseIndividualServices.updateEndDateForRelationships(trigger.new);
                
                //CHATS-5262
                caseIndividualServices.upadatePrimaryCareTakeronCase(trigger.new);              
                caseIndividualServices.updatePrimarcaretakeronIndividual(trigger.new);
                //added for UFE-RAPID by Shashank
                caseIndividualServices.handleCaseIndivUpdatesforUFE(trigger.new,Trigger.oldMap);
                //added for CCCAP-13633
                caseIndividualServices.updatePrimCrtkrOnIndivStatusUpdate(trigger.new, trigger.oldMap);
                caseIndividualServices.updateIndivDetailsForAdults(trigger.new, trigger.oldMap); 
            }
            if(Trigger.isInsert) {
                //copying salesforce Id to External Id
                CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_CASE_INDIV__c where Id=:trigger.newMap.keySet()],true);
            }
            if(Trigger.isUpdate){
                
                caseIndividualServices.doUpdateRecentChildCareRequest(trigger.new, trigger.oldMap);
                //[11/14/18: CHATS-6771]
                caseIndividualServices.updateEndDateOnCaseIndivRole(trigger.new, trigger.oldMap);
            }
            if(Trigger.isDelete) {
                caseIndividualServices.updatePrimarcaretakeronIndividual(trigger.old);
            }
        }
    }
    private Boolean isAnyFieldUpdated()
    {
        Boolean returnFlag = false;
        if(Trigger.isUpdate)
        {
            Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.T_SBSD_CASE_INDIV__C.fields.getMap(); 
            for(T_SBSD_CASE_INDIV__C newRecrd : trigger.new)
            {
                T_SBSD_CASE_INDIV__C oldRecrd = trigger.oldMap.get(newRecrd.Id);
                for (String str : mapFields.keyset()){ 
                    try { 
                        if(newRecrd.get(str) != oldRecrd.get(str) && (str != 'lastmodifieddate' && str != 'lastmodifiedbyid'  && str != 'systemmodstamp' && str != 'IDN_EXTNL__c' )){ 
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
}