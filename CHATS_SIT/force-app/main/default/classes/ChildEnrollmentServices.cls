/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           10/25/2022                                                          
*  @description    ChildEnrollmentServices for T556 and T557 generation                          
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 25-Oct-2022                                                             
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
public class ChildEnrollmentServices {
   public static void createT556Tasks(List<T_CHATS_CHILD_ENROLLMENT__c> newChilEnrollmentsList,Map<id,T_CHATS_CHILD_ENROLLMENT__c> oldMap){
        Set<Id> clientIDSet = new Set<Id>();
        Set<Id> providerIDSet = new Set<Id>();
        Set<String> providerChildIDSet = new Set<String>();
        List<Task> taskstoBeCreated = new List<Task>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ChildEnrollmentServices','Method__c'=>'createT556Tasks'};
            
            Map<String,string> providerChildIdMap = new Map<String,string>();
        for(T_CHATS_CHILD_ENROLLMENT__c enroll :newChilEnrollmentsList){
            system.debug('enroll--'+enroll);
            if(enroll.Enrollment_Reason__c == 'Child never attended' && enroll.Enrollment_Reason__c !=oldMap.get(enroll.Id).Enrollment_Reason__c){
                clientIDSet.add(enroll.IDN_CLIENT__c);
                providerIDSet.add(enroll.IDN_PROVR__c);
                providerChildIDSet.add(enroll.IDN_PROVR__c+'_'+enroll.IDN_CLIENT__c);
                providerChildIdMap.put(enroll.IDN_PROVR__c, enroll.IDN_CLIENT__c);
            }
        }
        Map<String,Task> taskMap = new  Map<String,Task>();
        for(Task tsk :[select id,WhatId,Subject,Status,ActivityDate  from Task  where Subject=:System.Label.Task_T556_Subject  ]){
            taskMap.put(tsk.WhatId, tsk);
        }
        for(T_AUTH__c authorization:[Select id,Name,IDN_CASE__c,IDN_CASE__r.Name,IDN_CASE__r.OwnerId,IDN_CLIENT__c,IDN_CLIENT__r.Name,IDN_PROVR__c,IDN_PROVR__r.Name from T_AUTH__c where IDN_CLIENT__c in:clientIDSet and 
                                     IDN_PROVR__c in:providerIDSet and Authorization_Status__c !='4']){ // Need to add date check to filter down auth records
                                         if(providerChildIDSet.contains(authorization.IDN_PROVR__c+'_'+authorization.IDN_CLIENT__c)){
                                            if(!taskMap.containsKey(authorization.Id)){
                                             Task tsk = new Task();
                                             tsk.Subject = System.Label.Task_T556_Subject;
                                             tsk.WhatId = authorization.Id;
                                             tsk.OwnerId = authorization.IDN_CASE__r.OwnerId;
                                             tsk.Status = 'New';
                                             tsk.Priority = 'Normal';
                                             tsk.ActivityDate = system.today().addDays(10);
                                             tsk.Description = 'The provider '+authorization.IDN_PROVR__r.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_CHATS_PROVR_STATUS__c/'+authorization.IDN_PROVR__c
                                                 +'/view ) ' +' has rejected/unenrolled authorization '+ authorization.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_AUTH__c/'+authorization.id
                                                 +'/view ) '+' for individual '+authorization.IDN_CLIENT__r.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_INDIV__c/'+authorization.IDN_CLIENT__c
                                                 +'/view ) '+' on case '+ authorization.IDN_CASE__r.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_CASE__c/'+authorization.IDN_CASE__c
                                                 +'/view ) '+'. Please contact the caretaker to verify the need for an authorization and take action on the authorization as necessary';
                                             
                                             //tsk.Description = CHATSUtility.mergeText(authorization, System.Label.Task_T556_Description);
                                             taskstoBeCreated.add(tsk);
                                            }
                                         }
                                     }
        if(taskstoBeCreated.size()>0){
            //Database.DMLOptions dm = new Database.DMLOptions();
            //dm.EmailHeader.triggerUserEmail=true;
            //dm.optAllOrNone = false;
            GenericDMLHandler.insertRecords(taskstoBeCreated,false,methodInfo);
        }
    }
    public static void createT557Tasks(List<T_CHATS_CHILD_ENROLLMENT__c> newChilEnrollmentsList,Map<id,T_CHATS_CHILD_ENROLLMENT__c> oldMap){
        Set<Id> clientIDSet = new Set<Id>();
        Set<Id> providerIDSet = new Set<Id>();
        Set<String> providerChildIDSet = new Set<String>();
        List<Task> taskstoBeCreated = new List<Task>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ChildEnrollmentServices','Method__c'=>'createT557Tasks'};
            
            Map<String,T_CHATS_CHILD_ENROLLMENT__c> providerChildIdMap = new Map<String,T_CHATS_CHILD_ENROLLMENT__c>();
        for(T_CHATS_CHILD_ENROLLMENT__c enroll :newChilEnrollmentsList){
            system.debug('enroll--'+enroll);
            if(//enroll.Enrollment_Reason__c !=oldMap.get(enroll.Id).Enrollment_Reason__c &&  
                enroll.Enrollment_Reason__c == 'Child was disenrolled as of this date and will no longer be receiving care with this child care provider'){
                    clientIDSet.add(enroll.IDN_CLIENT__c);
                    providerIDSet.add(enroll.IDN_PROVR__c);
                    providerChildIDSet.add(enroll.IDN_PROVR__c+'_'+enroll.IDN_CLIENT__c);
                    providerChildIdMap.put(enroll.IDN_PROVR__c+'_'+enroll.IDN_CLIENT__c, enroll);
                }
        }
        Map<String,Task> taskMap = new  Map<String,Task>();
        for(Task tsk :[select id,WhatId,Subject,Status,ActivityDate  from Task  where Subject=:System.Label.Task_T557_Subject  ]){
            taskMap.put(tsk.WhatId, tsk);
        }
        for(T_AUTH__c authorization:[Select id,Name,IDN_CASE__c,IDN_CASE__r.Name,IDN_CASE__r.OwnerId,IDN_CLIENT__c,IDN_CLIENT__r.Name,IDN_PROVR__c,IDN_PROVR__r.Name from T_AUTH__c where IDN_CLIENT__c in:clientIDSet and 
                                     IDN_PROVR__c in:providerIDSet and Authorization_Status__c !='4']){ // Need to add date check to filter down auth records
                                         if(providerChildIDSet.contains(authorization.IDN_PROVR__c+'_'+authorization.IDN_CLIENT__c)){
                                           if(!taskMap.containsKey(authorization.Id)){
                                            Date unEnrolledDatetime;
                                               T_CHATS_CHILD_ENROLLMENT__c currentEnroll = providerChildIdMap.get(authorization.IDN_PROVR__c+'_'+authorization.IDN_CLIENT__c);
                                               if(currentEnroll != null){
                                                   if(currentEnroll.Enroll_Flag__c =='Declined'){
                                                       unEnrolledDatetime = (providerChildIdMap.get(authorization.IDN_PROVR__c+'_'+authorization.IDN_CLIENT__c).DTE_BEGIN_EFFV__c);
                                                   }else if(currentEnroll.Enroll_Flag__c =='Enrolled' && currentEnroll.DTE_END_EFFV__c != null){
                                                       unEnrolledDatetime = (providerChildIdMap.get(authorization.IDN_PROVR__c+'_'+authorization.IDN_CLIENT__c).DTE_END_EFFV__c).addDays(1);
                                                   }
                                               }
                                             String unEnrolledDate;
                                             if(unEnrolledDatetime != null){
                                                 unEnrolledDate = Date.newInstance(unEnrolledDatetime.year(), unEnrolledDatetime.month(), unEnrolledDatetime.day()).format();
                                                 
                                             }                                             Task tsk = new Task();
                                             tsk.Subject = System.Label.Task_T557_Subject;
                                             tsk.WhatId = authorization.Id;
                                             tsk.OwnerId = authorization.IDN_CASE__r.OwnerId;
                                             tsk.Status = 'New';
                                             tsk.Priority = 'Normal';
                                             tsk.ActivityDate = system.today().addDays(10);
                                             tsk.Description = 'The provider ID '+authorization.IDN_PROVR__r.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_CHATS_PROVR_STATUS__c/'+authorization.IDN_PROVR__c
                                                 +'/view ) ' +' has reported that a child has been disenrolled with authorization ID '+ authorization.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_AUTH__c/'+authorization.id
                                                 +'/view ) '+' for individual ID '+authorization.IDN_CLIENT__r.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_INDIV__c/'+authorization.IDN_CLIENT__c
                                                 +'/view ) '+' on case number '+ authorization.IDN_CASE__r.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_CASE__c/'+authorization.IDN_CASE__c +'/view ) ';
                                             if(unEnrolledDate != null){
                                                 tsk.Description +=' as of '+unEnrolledDate +' date';
                                             }
                                                 tsk.Description += '.  Please contact the CCCAP parent/caretaker to verify the date the child was disenrolled and take action on the authorization as necessary. No payment will be released as of the day the child was disenrolled (no longer enrolled with the provider).';
                                             //tsk.Description = CHATSUtility.mergeText(authorization, System.Label.Task_T556_Description);
                                              taskstoBeCreated.add(tsk);
                                           }
                                         }
                                     }
        if(taskstoBeCreated.size()>0){
            //Database.DMLOptions dm = new Database.DMLOptions();
            //dm.EmailHeader.triggerUserEmail=true;
            //dm.optAllOrNone = false;
            GenericDMLHandler.insertRecords(taskstoBeCreated,false,methodInfo);
        }
    }
     public static void insertATSRecords(List<T_CHATS_CHILD_ENROLLMENT__c> childEnrollmentList){
        List <batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List <batchsit_t_pos_trans_queue_ats__x>();
        for(T_CHATS_CHILD_ENROLLMENT__c enrollObj : childEnrollmentList){
            batchsit_t_pos_trans_queue_ats__x atsRecord = new batchsit_t_pos_trans_queue_ats__x();
            atsRecord.CDE_STATUS_TRANS__c = '1';
            atsRecord.CDE_TYPE_TRANS__c = '10';
            if(enrollObj != null){
                atsRecord.IDN_CHILD_ENROLL__c = enrollObj.Name ;
            }
            atsRecord.DTE_CHANGE_LAST__c = system.today();
            lstATSRecords.add(atsRecord);
        }
        if(!Test.isRunningTest()){
            ATSHandler.insertATSRecord(true, lstATSRecords);
        }
        
    }
    /* Commented out for CCCAP-15890 by Shashank on 08/18/26
    public static void upsertEnrollRecord(List<T_CHATS_CHILD_ENROLLMENT__c> childEnrollmentList){
        Set<Id> childEnrollmentToBeDeleted = new Set<Id>();
        Set<String> externlIdsToBeUpdated = new Set<String>();
        Map<string,T_CHATS_CHILD_ENROLLMENT__c> newEnrollToExitingMap = new Map<string,T_CHATS_CHILD_ENROLLMENT__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ChildEnrollmentServices','Method__c'=>'upsertEnrollRecord'};
            List<T_CHATS_CHILD_ENROLLMENT__c> enrollToBeUpdated = new List<T_CHATS_CHILD_ENROLLMENT__c>();
        for(T_CHATS_CHILD_ENROLLMENT__c enroll :childEnrollmentList){
            if(enroll.ConnectionReceivedId != null ){
                externlIdsToBeUpdated.add(enroll.IDN_EXTNL__c);
                childEnrollmentToBeDeleted.add(enroll.Id);
                newEnrollToExitingMap.put(enroll.IDN_EXTNL__c, enroll);
            }
        }
        for(T_CHATS_CHILD_ENROLLMENT__c en :[select id,IDN_EXTNL__c,Previous_Enroll_End_Date__c,Enroll_Flag__c,Enrollment_Reason__c,DTE_END_EFFV__c,DTE_BEGIN_EFFV__c from T_CHATS_CHILD_ENROLLMENT__c where IDN_EXTNL__c in:externlIdsToBeUpdated ]){
            if(newEnrollToExitingMap.containsKey(en.IDN_EXTNL__c)){
                T_CHATS_CHILD_ENROLLMENT__c enroll = newEnrollToExitingMap.get(en.IDN_EXTNL__c);
                en.Enroll_Flag__c=enroll.Enroll_Flag__c;
                en.Enrollment_Reason__c =enroll.Enrollment_Reason__c;
                en.DTE_END_EFFV__c =enroll.DTE_END_EFFV__c;
                en.DTE_BEGIN_EFFV__c=enroll.DTE_BEGIN_EFFV__c;
                en.Previous_Flag__c = enroll.Previous_Flag__c;
                en.Previous_Enroll_End_Date__c = enroll.Previous_Enroll_End_Date__c;
                enrollToBeUpdated.add(en);
            }
        }
        Exception_Log__c xLog2 = new Exception_Log__c();
                            xLog2.Class__c = 'ChildENrollServiceCheckingIds';
                            xLog2.Method__c = 'upsertEnrollRecord'+childEnrollmentToBeDeleted;
                            xLog2.Exception_Message__c = JSON.serialize(childEnrollmentToBeDeleted);
                            xLog2.Exception_Type__c = 'Success';
                            GenericDMLHandler.insertRecords(new List<SObject>{xLog2},false,new Map<String,Object>{'Method__c'=>'upsertEnrollRecord','Class__c'=>'ChildENrollServiceCheckingIds'});
        if(enrollToBeUpdated != null && enrollToBeUpdated.size()>0){
            
            GenericDMLHandler.updateRecords(enrollToBeUpdated, methodInfo);
            Exception_Log__c xLog = new Exception_Log__c();
                            xLog.Class__c = 'ChiildEnrollment';
                            xLog.Method__c = 'upsertenroll';
                            xLog.Exception_Message__c = JSON.serialize(enrollToBeUpdated);
                            xLog.Exception_Type__c = 'Success';
                            GenericDMLHandler.insertRecords(new List<SObject>{xLog},false,new Map<String,Object>{'Method__c'=>'setAuthorizationFlag','Class__c'=>'AuthorizationFlowApxCtrl'});
            deleteChilEnrollRecords(childEnrollmentToBeDeleted);
        }
        
    }
    @future
    public static void deleteChilEnrollRecords(Set<Id> childEnrollmentToBeDeleted){
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ChildEnrollmentServices','Method__c'=>'deleteChilEnrollRecords'};
            List<T_CHATS_CHILD_ENROLLMENT__c> enrollmentDeleteList = [SELECT Id from T_CHATS_CHILD_ENROLLMENT__c WHERE Id IN :childEnrollmentToBeDeleted];
        List<PartnerNetworkRecordConnection> partNetRecConnList = [SELECT Id, LocalRecordId FROM PartnerNetworkRecordConnection WHERE 
                                                                   LocalRecordId IN :childEnrollmentToBeDeleted];
        Exception_Log__c xLog1 = new Exception_Log__c();
                            xLog1.Class__c = 'ChiildEnrollment';
                            xLog1.Method__c = 'deleteChilEnrollRecords';
                            xLog1.Exception_Message__c = JSON.serialize(enrollmentDeleteList);
                            xLog1.Exception_Type__c = 'Success';
                            GenericDMLHandler.insertRecords(new List<SObject>{xLog1},false,new Map<String,Object>{'Method__c'=>'deleteChilEnrollRecords','Class__c'=>'ChilEnrollmentService'});
        
        if(enrollmentDeleteList.size()>0){
            try{
                 Exception_Log__c xLog = new Exception_Log__c();
                            xLog.Class__c = 'ChiildEnrollment';
                            xLog.Method__c = 'deleteChilEnrollRecords';
                            xLog.Exception_Message__c = JSON.serialize(partNetRecConnList);
                            xLog.Exception_Type__c = 'Success';
                            GenericDMLHandler.insertRecords(new List<SObject>{xLog},false,new Map<String,Object>{'Method__c'=>'setAuthorizationFlag','Class__c'=>'deleteChilEnrollRecords'});
                if (PartnerNetworkRecordConnection.sObjectType.getDescribe().isDeletable()){
                    delete partNetRecConnList;
                }
                else{
                   
                    System.debug('Insufficient delete access:partNetRecConnList');
                }
                GenericDMLHandler.deleteRecords(enrollmentDeleteList, methodInfo);
            }
            catch(Exception e){
                 Exception_Log__c xLog = new Exception_Log__c();
                            xLog.Class__c = 'ChiildEnrollment';
                            xLog.Method__c = 'deleteChilEnrollRecords';
                            xLog.Exception_Message__c = e.getMessage();
                            xLog.Exception_Type__c = 'Exception';
                            GenericDMLHandler.insertRecords(new List<SObject>{xLog},false,new Map<String,Object>{'Method__c'=>'setAuthorizationFlag','Class__c'=>'deleteChilEnrollRecords'});
            }
        }
    }*/
}