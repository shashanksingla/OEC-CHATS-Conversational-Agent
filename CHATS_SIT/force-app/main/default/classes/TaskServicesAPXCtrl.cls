/*****************************************************************************************
Class Name       - TaskServicesAPXCtrl 
Test Class       - TaskTrigger_Test
Parent Component - TaskTrigger(Trigger), taskChangeOwner(Aura), taskReopen(Aura), Mark Complete (button in Task)
Description      - Main trigger handler and utility class for Task object and related Aura

*  Modification Log:
*
*  * CCCAP-8475: Added 'validateCountyBulk' method.
*****************************************************************************************/
public with sharing class TaskServicesAPXCtrl {
    
    Public Static Boolean isSuccessful = true;
    Public Static String message = '';

    private static final String SUBJECT_T236 = System.Label.Task_T236_Subject;
    private static final String SUBJECT_T237 = System.Label.Task_T237_Subject;
    private static final String OWNER_UPDATE_ERROR = 'Please update the assignee from client complaint record and close your task.';

    //CCCAP-15359
    public static void validateOwnerUpdateRestriction(List<Task> newTasks, Map<Id, Task> oldMap) {
        if (FeatureManagement.checkPermission('System_Administrator')) {
            return;
        }

        Set<Id> complaintIds = new Set<Id>();
        for (Task t : newTasks) {
            Task oldTask = oldMap.get(t.Id);
            if ((t.Subject == SUBJECT_T236 || t.Subject == SUBJECT_T237) && t.OwnerId != oldTask.OwnerId && t.WhatId != null) {
                complaintIds.add(t.WhatId);
            }
        }

        if (complaintIds.isEmpty()) {
            return;
        }

        Map<Id, Client_Complaint__c> complaintMap = new Map<Id, Client_Complaint__c>(
            [SELECT Id, byPassValidation__c FROM Client_Complaint__c WHERE Id IN :complaintIds]
        );

        for (Task t : newTasks) {
            Task oldTask = oldMap.get(t.Id);
            if ((t.Subject == SUBJECT_T236 || t.Subject == SUBJECT_T237) && t.OwnerId != oldTask.OwnerId && t.WhatId != null) {
                Client_Complaint__c complaint = complaintMap.get(t.WhatId);
                if (complaint != null && complaint.byPassValidation__c != true) {
                    t.OwnerId.addError(OWNER_UPDATE_ERROR);
                }
            }
        }
    }

    @AuraEnabled
    public Static LightningServerResponse transferItem(String taskId, String ownerId){
        Map<String, Object> objectData = new map<String, Object>();
        List<Task> lstRecords = new List<Task>();
        for(Task task : [Select WhoId, ownerId from Task where Id = :taskId]) {
            task.ownerId = ownerId;
            lstRecords.add(task);
        }
        if(lstRecords.size() > 0){
            try {
                GenericWithoutSharingDMLOperations.updateRecords(lstRecords, new Map<String,Object>{'Method__c'=>'updateRecords','Class__c'=>'TaskServicesAPX'});
                message = 'Assignee updated';
            } catch(Exception ex) {
                isSuccessful = false;
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String, Object>{'Method__c'=>'updateRecords','Class__c'=>'TaskServicesAPX'});
                throw ex;
            }
        } else {
            isSuccessful = false;
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    public static string validateCounty(String taskId){
        Set<String> sObjectTypes = new Set<String>{'T_PROVR_FISCAL_AGREMENT__c', 'T_SBSD_CASE__c', 'T_COUNTY_PLAN__c', 'T_AUTH__c', 'T_ADJMT__c'};      
        String errorMessage = '';
        Task t = [SELECT WhatId, OwnerId, Subject FROM Task Where Id = :taskId limit 1];
        Boolean countyMatched = true;
        if(t.WhatId != null){
            Id relatedId = t.WhatId;
            String sobjectType = relatedId.getSObjectType().getDescribe().getName();
            String fieldName = '';
            if(sObjectTypes.contains(sobjectType)) {
                fieldName = 'CDE_COUNTY__c';
            } else if(sobjectType == 'T_COUNTY_RATE__c') {
                fieldName = 'IDN_COUNTY__c';
            } else if(sobjectType == 'T_County__c') {
                fieldName = 'Id';
            }
            if(sobjectType == 'T_CHATS_PROVR_STATUS__c') {
                if(t.Subject == Label.Task_T215_Subject || t.Subject == Label.Task_T216_Subject){
                    List<string> memberIds = new List<String>();
                	for(GroupMember gm: [SELECT Id, GroupId, UserOrGroupId, SystemModstamp FROM GroupMember where GroupId =: t.OwnerId]){
                    	memberIds.add(gm.UserOrGroupId);
                	}
                    
                	if(!memberIds.isEmpty() && !memberIds.contains(UserInfo.getUserId())){
                        countyMatched = CHATSUtility.checkCountyforProvider(relatedId);
                		if(!countyMatched){
                    		isSuccessful = false;
                    		errorMessage = 'The task does not belong to your assigned county(ies).';
                		}
                    }
                } else{
                    countyMatched = CHATSUtility.checkCountyforProvider(relatedId);
                	if(!countyMatched){
                    	isSuccessful = false;
                    	errorMessage = 'The task does not belong to your assigned county(ies).';
                	}
                }
            } else if(string.isNotBlank(fieldName)) {
                String query = 'SELECT '+fieldName+' FROM '+sobjectType+' Where Id =:relatedId';
                List<sObject> objList = Database.query(query);
                if(!objList.isEmpty()){
                    Id countyId = (Id)objList[0].get(fieldName);
                    if(countyId != null){
                        String countyName = [SELECT Name FROM T_County__c Where Id =:countyId][0].Name;
                        countyMatched = CHATSUtility.checkCountyWithUserCounty(countyId); 
                        if(!countyMatched){
                            isSuccessful = false;
                            errorMessage = 'The task belongs to '+countyName+' county. This does not match your assigned county(ies).';
                        }
                    }
                }
            }
        }
        return errorMessage;
    }
    
    // Added by Rishav for CCCAP-8475
    public static void validateCountyBulk(List<Task> newTaskList, Map<Id, Task> oldTaskMap) {
        Integer applicableTaskNumber = 0;
        Map<Id, String> errorRecordCountyMap = new Map<Id, String>();
        Set<Id> FAIdSet 	= new Set<Id>();
        Set<Id> CaseIdSet 	= new Set<Id>();
        Set<Id> CPIdSet 	= new Set<Id>();
        Set<Id> AuthIdSet 	= new Set<Id>();
        Set<Id> AdjmtIdSet 	= new Set<Id>();
        Set<Id> CRPIdSet 	= new Set<Id>();
        Set<Id> CountyIdSet = new Set<Id>();
        Set<Id> ProvrIdSet 	= new Set<Id>();
        
        //Removing Profile.name since moved to custom permission CCCAP-14993
        List<User> users = new list<User>([SELECT Owner_County__c, Common_County__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1]);
        //Using custom permission CCCAP-14993
        if(users.size()>0 && (FeatureManagement.checkPermission('System_Administrator') || FeatureManagement.checkPermission('CCCAP_Program_Internal_Team'))){
            return;
        }
        
        Map<Id, T_COUNTY__c> countyMap = new Map<Id, T_COUNTY__c>([SELECT Id, Name, CDE_COUNTY__c FROM T_COUNTY__c]);
        for(Task t : newTaskList){
            if(t.WhatId != null && t.Status == 'Completed' && (oldTaskMap == null || t.Status != oldTaskMap.get(t.Id)?.Status)){
                Id relatedId = t.WhatId;
                String sobjectType = relatedId.getSObjectType().getDescribe().getName();
                System.debug('taskId-->'+t.Id+' sobjectType-->'+sobjectType+' relatedId-->'+relatedId);
                if(sobjectType == 'T_PROVR_FISCAL_AGREMENT__c') {
                    FAIdSet.add(relatedId);
                    applicableTaskNumber++;
                } else if(sobjectType == 'T_SBSD_CASE__c') {
                    CaseIdSet.add(relatedId);
                    applicableTaskNumber++;
                } else if(sobjectType == 'T_COUNTY_PLAN__c') {
                    CPIdSet.add(relatedId);
                    applicableTaskNumber++;
                } else if(sobjectType == 'T_AUTH__c') {
                    AuthIdSet.add(relatedId);
                    applicableTaskNumber++;
                } else if(sobjectType == 'T_ADJMT__c') {
                    AdjmtIdSet.add(relatedId);
                    applicableTaskNumber++;
                } else if(sobjectType == 'T_COUNTY_RATE__c') {
                    CRPIdSet.add(relatedId);
                    applicableTaskNumber++;
                } else if(sobjectType == 'T_County__c') {
                    CountyIdSet.add(relatedId);
                    applicableTaskNumber++;
                } else if(sobjectType == 'T_CHATS_PROVR_STATUS__c') {
                    ProvrIdSet.add(relatedId);
                    applicableTaskNumber++;
                }
            }
        }
        
        System.debug('applicableTaskNumber-->'+applicableTaskNumber);
        if(applicableTaskNumber > 0){
            User currentUser = users.size()>0 ?users[0] : new user();
            System.debug('T_PROVR_FISCAL_AGREMENT__c-->'+FAIdSet);
            for(T_PROVR_FISCAL_AGREMENT__c record : [SELECT Id, CDE_COUNTY__c FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id IN :FAIdSet AND CDE_COUNTY__c != null]){
                T_COUNTY__c county = countyMap.get(record.CDE_COUNTY__c);
                if(!isUserCountyMatch(currentUser, county)){
                    errorRecordCountyMap.put(record.Id, county.Name);
                }
            }
            System.debug('T_SBSD_CASE__c-->'+CPIdSet);
            for(T_SBSD_CASE__c record : [SELECT Id, CDE_COUNTY__c FROM T_SBSD_CASE__c WHERE Id IN :CaseIdSet AND CDE_COUNTY__c != null]){
                T_COUNTY__c county = countyMap.get(record.CDE_COUNTY__c);
                if(!isUserCountyMatch(currentUser, county)){
                    errorRecordCountyMap.put(record.Id, county.Name);
                }
            }
            System.debug('T_COUNTY_PLAN__c-->'+CPIdSet);
            for(T_COUNTY_PLAN__c record : [SELECT Id, CDE_COUNTY__c FROM T_COUNTY_PLAN__c WHERE Id IN :CPIdSet AND CDE_COUNTY__c != null]){
                T_COUNTY__c county = countyMap.get(record.CDE_COUNTY__c);
                if(!isUserCountyMatch(currentUser, county)){
                    errorRecordCountyMap.put(record.Id, county.Name);
                }
            }
            System.debug('T_AUTH__c-->'+AuthIdSet);
            for(T_AUTH__c record : [SELECT Id, CDE_COUNTY__c FROM T_AUTH__c WHERE Id IN :AuthIdSet AND CDE_COUNTY__c != null]){
                T_COUNTY__c county = countyMap.get(record.CDE_COUNTY__c);
                if(!isUserCountyMatch(currentUser, county)){
                    errorRecordCountyMap.put(record.Id, county.Name);
                }
            }
            System.debug('T_ADJMT__c-->'+AdjmtIdSet);
            for(T_ADJMT__c record : [SELECT Id, CDE_COUNTY__c FROM T_ADJMT__c WHERE Id IN :AdjmtIdSet AND CDE_COUNTY__c != null]){
                T_COUNTY__c county = countyMap.get(record.CDE_COUNTY__c);
                if(!isUserCountyMatch(currentUser, county)){
                    errorRecordCountyMap.put(record.Id, county.Name);
                }
            }
            System.debug('T_COUNTY_RATE__c-->'+CRPIdSet);
            for(T_COUNTY_RATE__c record : [SELECT Id, IDN_COUNTY__c FROM T_COUNTY_RATE__c WHERE Id IN :CRPIdSet AND IDN_COUNTY__c != null]){
                T_COUNTY__c county = countyMap.get(record.IDN_COUNTY__c);
                if(!isUserCountyMatch(currentUser, county)){
                    errorRecordCountyMap.put(record.Id, county.Name);
                }
            }
            
            System.debug('T_County__c-->'+CountyIdSet);
            for(Id recordId : CountyIdSet){
                T_COUNTY__c county = countyMap.get(recordId);
                if(!isUserCountyMatch(currentUser, county)){
                    errorRecordCountyMap.put(recordId, county.Name);
                }
            }
            System.debug('T_CHATS_PROVR_STATUS__c-->'+ProvrIdSet);
            for(T_PROVR_FISCAL_AGREMENT__c record : [SELECT Id, ID_SERVICE__c, CDE_COUNTY__c FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c IN :ProvrIdSet AND CDE_COUNTY__c != null]){
                T_COUNTY__c county = countyMap.get(record.CDE_COUNTY__c);
                if(!isUserCountyMatch(currentUser, county)){
                    errorRecordCountyMap.put(record.ID_SERVICE__c, county.Name);
                }
            }
            
            System.debug('errorRecordCountyMap-->'+errorRecordCountyMap);
            for(Task t : newTaskList){
                if(errorRecordCountyMap.containsKey(t.WhatId)){
                    t.addError('The task belongs to ' + errorRecordCountyMap.get(t.WhatId) + ' county. This does not match your assigned county(ies).');
                }
            }
        }
    }
    
    // Added by Rishav for CCCAP-8475
    private Static Boolean isUserCountyMatch(User user, T_COUNTY__c countyObj){
        Boolean countyMatched = false;
        if(user != null && countyObj != null){
            String county = String.valueOf(countyObj.CDE_COUNTY__c);
            if(user.Owner_County__c == county || (String.isNotBlank(user.Common_County__c) && new Set<String>(user.Common_County__c.split(';')).contains(county))) {
                countyMatched = true;
            }
        }
        return countyMatched;
    }
    
    @AuraEnabled
    public Static LightningServerResponse markTaskAsCompleted(String taskId){
        List<Task> lstRecords = new List<Task>();
        Task task = new Task();
        task.id = taskId;
        task.Status = 'Completed';
        lstRecords.add(task);
        String errorMessage = validateCounty(taskId);
        Boolean countyMatched = true;
        if(string.isNotBlank(errorMessage)){
            countyMatched = false;
            isSuccessful = false;
            message = errorMessage;
        }
        if(lstRecords.size() > 0 && countyMatched){
            try {
                GenericWithoutSharingDMLOperations.updateRecords(lstRecords, new Map<String,Object>{'Method__c'=>'updateRecords','Class__c'=>'TaskServicesAPX'});
                message = 'Task Mark Complete';
            } catch(Exception ex) {
                isSuccessful = false;
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Method__c'=>'updateRecords','Class__c'=>'TaskServicesAPX'});
                throw ex;
            }            
        } else {
            isSuccessful = false;
        }
        return new LightningServerResponse(isSuccessful, message, null);
    }
    
    @AuraEnabled
    public Static LightningServerResponse reOpenMarkCompletedTask(String taskId, String status){   
        List<Task> lstRecords = new List<Task>();
        Task task = new Task();
        task.id = taskId;
        task.Status = status;
        lstRecords.add(task);
        if(lstRecords.size() > 0){
            try {
                GenericWithoutSharingDMLOperations.updateRecords(lstRecords, new Map<String, Object>{'Method__c'=>'updateRecords','Class__c'=>'TaskServicesAPX'});
                message = 'Task Status Updated';
            } catch(Exception ex) {
                isSuccessful = false;
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String, Object>{'Method__c'=>'updateRecords','Class__c'=>'TaskServicesAPX'});
                throw ex;
            }
        } else {
            isSuccessful = false;
        }
        return new LightningServerResponse(isSuccessful, message, null);
    }

    //added for CCCAP-11593
    public static void checkT227ForEmailNotification(List<Task> taskList){
        List<Task> tasksToBeNotified = new List<Task>();
        for(Task tsk: taskList){
            if(tsk.Subject == System.Label.Task_T227_Subject){
                tasksToBeNotified.add(tsk);
            }
        }
        if(!tasksToBeNotified.isEmpty()){
            List<Messaging.SingleEmailMessage> finalEmailList = new List<Messaging.SingleEmailMessage>(); 
            EmailTemplate emailTemplate = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Task_Assignment_Custom_Template' LIMIT 1];
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            Set<Id> userIds = new Set<Id>();
            for(GroupMember gm: [SELECT UserOrGroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName LIKE '%T227%']){
                userIds.add(gm.UserOrGroupId);
            }
            List<User> userList = [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];            
            Set<Id> adjIds = new Set<Id>();
            for(Task t: tasksToBeNotified){
                if(t.WhatId != null){
                    adjIds.add(t.WhatId);
                }
            }
            List<T_ADJMT__c> adjList = new List<T_ADJMT__c>();
            if(!adjIds.isEmpty()){
                adjList = [SELECT Id, Name from T_ADJMT__c WHERE Id IN :adjIds];
            }            
            Map<Id, T_ADJMT__c> adjMap = new Map<Id,T_ADJMT__c>(adjList);
            Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email);   
            for(Task t: tasksToBeNotified){
                for(User u: userList){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    String htmlMailBody = emailTemplate.HtmlValue;
                    htmlMailBody = htmlMailBody.replace('{!recipientName}', u.Name);
                    htmlMailBody = htmlMailBody.replace('{!taskSubject}', Label.Task_T227_Subject);
                    htmlMailBody = htmlMailBody.replace('{!objectName}', 'Adjustment');
                    htmlMailBody = htmlMailBody.replace('{!recordName}', adjMap.get(t.WhatId).Name);
                    htmlMailBody = htmlMailBody.replace('{!taskDueDate}', t.ActivityDate.month() + '/' + t.ActivityDate.day() + '/' + t.ActivityDate.year());
                    htmlMailBody = htmlMailBody.replace('{!taskPriority}', 'Normal');
                    htmlMailBody = htmlMailBody.replace('{!taskDescription}', t.Description);
                    htmlMailBody = htmlMailBody.replace('{!recordURL}', baseUrl + '/' + t.WhatId);
                    mail.setToAddresses(new List<String>{u.Email});
                    mail.setSubject(Label.Task_T227_Subject);
                    mail.setHtmlBody(htmlMailBody);
                    if(owEmailAddressId != null){
                        mail.setOrgWideEmailAddressId(owEmailAddressId);
                    }
                    finalEmailList.add(mail);                   
                }
            }
            if(!finalEmailList.isEmpty()){
                Messaging.sendEmail(finalEmailList);
            }
        }
    }
}