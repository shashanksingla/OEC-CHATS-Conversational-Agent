public with sharing class updateSupportTicketController {
    @auraEnabled
    public static void onCloseButtonClick(string recordId){
        System.debug('The Record Id -->'+recordId);
        List<CHATS_Support__c> clsRecordList = new List<CHATS_Support__c>();
        CHATS_Support__c updCloseRecord = new CHATS_Support__c( id = recordId,
                                                               Status__c = 'Fixed/Completed',
                                                               Root_Cause__c= 'Clarification',
                                                               Ticket_Closure_Date__c= system.now());
        clsRecordList.add(updCloseRecord);
        //update updCloseRecord;
        if(!clsRecordList.isEmpty()){
            GenericDMLHandler.updateRecords(clsRecordList,null);
        }
        
    }

    @auraEnabled
    public static Boolean canAccessReopenButtonComponent(){
        //List<Profile> profile = [SELECT Id FROM Profile WHERE Name='Read Only User' LIMIT 1]; Moving to custom permission CCCAP-14993
        // CCCAP-14993 Using custom permission
        if(FeatureManagement.checkPermission('Read_Only_User')){
            if([select Count() from PermissionSetAssignment where Assignee.Id = :UserInfo.getUserId() AND PermissionSet.Name = 'County_Security_Administrator']==0){
            	return false;    
            }            
        }
        return true;
    }
    
    @auraEnabled
    public static void onReopenButtonClick(string recordId, string reOpenReason){
        System.debug('The Record Id -->'+recordId);
        datetime emptyDate = null;
        List<CHATS_Support__c> reopenRecordList = new List<CHATS_Support__c>();
        CHATS_Support__c updReopenRecord = new CHATS_Support__c( id = recordId,
                                                               	Status__c = 'Reopened',
                                                               	Root_Cause__c= 'Pending Triage',
                                                               	Ticket_Closure_Date__c= emptyDate,
                                                              	Date_Elevated__c = emptyDate,
                                                                Reopened_By_User__c= true,
                                                                Reopen_Reason__c= reOpenReason,
                                                               	Elevated_to__c = null);
        
       	reopenRecordList.add(updReopenRecord);
        if(!reopenRecordList.isEmpty()){
            GenericDMLHandler.updateRecords(reopenRecordList,null);
        }
        
    }
    
}