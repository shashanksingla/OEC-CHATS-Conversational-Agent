/*********************************************************************************************
* @author         Deloitte Consulting LLP.                                           
* @date           06/25/2018                                                         
* @description    Utility class to be used to deal with database operations
* Modification Log:                                                                             
* * * Version: 1.0                                                                              
* * Date: 25-Jun-2018                                                             
* * Author: Shubham Jain                                                      
* * Description: Initial version                                                 
* * JIRA Ticket: 
* * *********************************************************************************************/
public with sharing class GenericDMLHandler {
    public Map<String, Schema.SObjectType> globalDescribe {get;set;}
    public GenericDMLHandler() {
        this.globalDescribe = Schema.getGlobalDescribe();
    }
    public static void insertRecords(List<SObject> lstSObjects, Map<String,Object> methodInfo){
        List<CRUDPermissionException> lstCRUDPermissionException = new List<CRUDPermissionException>();        
        for(Integer i=0;i<lstSObjects.size();i++){
            if(!lstSObjects.get(i).getSObjectType().getDescribe().isCreateable()){
                if(methodInfo==null){
                    lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create'));
                }else{
                    if(!methodInfo.containsKey('byPassObjects')){
                        lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create'));
                    }else{
                        Set<String> byPassObjects = (Set<String>)methodInfo.get('byPassObjects');
                        if(!byPassObjects.contains(lstSObjects.get(i).getSObjectType()+'')){
                            lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create'));
                        }
                    }
                }
            }
        }
        if(!lstCRUDPermissionException.isEmpty()){
            throw CRUDPermissionException.getCRUDPermissionException(lstCRUDPermissionException);
        }else{
            try{
                insert lstSObjects;
            }catch(Exception ex){
                if(methodInfo==null || !methodInfo.containskey('byPassExceptionLogging') || methodInfo.get('byPassExceptionLogging')==true){
                    ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                }
                throw ex;
            }
        }
    }
    //SS:  Added new method with additional paramter of fieldNames for Checkmarx CCCAP-8861
    public static void insertRecords(List<SObject> lstSObjects, Map<String,Object> methodInfo, List<String> fieldNames){
        List<CRUDPermissionException> lstCRUDPermissionException = new List<CRUDPermissionException>();        
        for(Integer i=0;i<lstSObjects.size();i++){
            schema.DescribeSObjectResult sobj = lstSObjects.get(i).getSObjectType().getDescribe();
            Boolean isAllowed= sobj.isCreateable();
            Map<String, SObjectField> fieldMap = sobj.fields.getMap();
            for(string fName : fieldNames){
                if(fieldMap.containsKey(fName) && !fieldMap.get(fName).getDescribe().isCreateable()){
                    isAllowed = false;
                }
            }
            if(!isAllowed){
                if(methodInfo==null){
                    lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create'));
                }else{
                    if(!methodInfo.containsKey('byPassObjects')){
                        lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create'));
                    }else{
                        Set<String> byPassObjects = (Set<String>)methodInfo.get('byPassObjects');
                        if(!byPassObjects.contains(lstSObjects.get(i).getSObjectType()+'')){
                            lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create'));
                        }
                    }
                }
            }
        }
        if(!lstCRUDPermissionException.isEmpty()){
            throw CRUDPermissionException.getCRUDPermissionException(lstCRUDPermissionException);
        }else{
            try{
                insert lstSObjects;
            }catch(Exception ex){
                if(methodInfo==null || !methodInfo.containskey('byPassExceptionLogging') || methodInfo.get('byPassExceptionLogging')==true){
                    ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                }
                throw ex;
            }
        }
    }
    //SS: Added new method with additional paramter of fieldNames for Checkmarx CCCAP-8861
    public static List<DMLResult> insertRecords(List<SObject> lstSObjects,Boolean allOrNothing, Map<String,Object> methodInfo,List<String> fieldNames){
        List<DMLResult> lstDMLResult = new List<DMLResult>();        
        List<SObject> lstSObjectToBeInserted = new List<SObject>();
        for(Integer i=0;i<lstSObjects.size();i++){
            schema.DescribeSObjectResult sobj = lstSObjects.get(i).getSObjectType().getDescribe();
            Boolean isAllowed= sobj.isCreateable();
            Map<String, SObjectField> fieldMap = sobj.fields.getMap();
            for(string fName : fieldNames){
                if(fieldMap.containsKey(fName) && !fieldMap.get(fName).getDescribe().isCreateable()){
                    isAllowed = false;
                }
            }
            if(!isAllowed){
                if(methodInfo==null){
                    lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create')));
                }else{
                    if(!methodInfo.containsKey('byPassObjects')){
                        lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create')));
                    }else{
                        Set<String> byPassObjects = (Set<String>)methodInfo.get('byPassObjects');
                        if(!byPassObjects.contains(lstSObjects.get(i).getSObjectType()+'')){
                            lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create')));
                        }else{
                            lstDMLResult.add(new DMLResult(null,null));
                            lstSObjectToBeInserted.add(lstSObjects.get(i));
                        }
                    }
                }
            }else{
                lstDMLResult.add(new DMLResult(null,null));
                lstSObjectToBeInserted.add(lstSObjects.get(i));
            }
        }
        List<Database.SaveResult> lstSaveResults = Database.insert(lstSObjectToBeInserted, allOrNothing);
        Integer saveResultIndex=0;
        for(Integer i=0;i<lstDMLResult.size();i++){
            if(lstDMLResult.get(i).crudPermissionException==null){
                lstDMLResult.get(i).saveResult = lstSaveResults.get(saveResultIndex);
                saveResultIndex++;
            }
        }
        ExceptionLoggingServices.captureExceptionLog(lstSaveResults, lstSObjectToBeInserted, methodInfo);
        return lstDMLResult;
    }
    
    public static List<DMLResult> insertRecords(List<SObject> lstSObjects,Boolean allOrNothing, Map<String,Object> methodInfo){
        List<DMLResult> lstDMLResult = new List<DMLResult>();        
        List<SObject> lstSObjectToBeInserted = new List<SObject>();
        for(Integer i=0;i<lstSObjects.size();i++){
            if(!lstSObjects.get(i).getSObjectType().getDescribe().isCreateable()){
                if(methodInfo==null){
                    lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create')));
                }else{
                    if(!methodInfo.containsKey('byPassObjects')){
                        lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create')));
                    }else{
                        Set<String> byPassObjects = (Set<String>)methodInfo.get('byPassObjects');
                        if(!byPassObjects.contains(lstSObjects.get(i).getSObjectType()+'')){
                            lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Create')));
                        }else{
                            lstDMLResult.add(new DMLResult(null,null));
                            lstSObjectToBeInserted.add(lstSObjects.get(i));
                        }
                    }
                }
            }else{
                lstDMLResult.add(new DMLResult(null,null));
                lstSObjectToBeInserted.add(lstSObjects.get(i));
            }
        }
        List<Database.SaveResult> lstSaveResults = Database.insert(lstSObjectToBeInserted, allOrNothing);
        Integer saveResultIndex=0;
        for(Integer i=0;i<lstDMLResult.size();i++){
            if(lstDMLResult.get(i).crudPermissionException==null){
                lstDMLResult.get(i).saveResult = lstSaveResults.get(saveResultIndex);
                saveResultIndex++;
            }
        }
        ExceptionLoggingServices.captureExceptionLog(lstSaveResults, lstSObjectToBeInserted, methodInfo);
        return lstDMLResult;
    }
    
    public static List<DMLResult> updateRecords(List<SObject> lstSObjects,Boolean allOrNothing, Map<String,Object> methodInfo){
        List<DMLResult> lstDMLResult = new List<DMLResult>();        
        List<SObject> lstSObjectToBeUpdated = new List<SObject>();
        for(Integer i=0;i<lstSObjects.size();i++){
            if(!lstSObjects.get(i).getSObjectType().getDescribe().isUpdateable()){
                if(methodInfo==null){
                    lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Update')));
                }else{
                    if(!methodInfo.containsKey('byPassObjects')){
                        lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Update')));
                    }else{
                        Set<String> byPassObjects = (Set<String>)methodInfo.get('byPassObjects');
                        if(!byPassObjects.contains(lstSObjects.get(i).getSObjectType()+'')){
                            lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Update')));
                        }else{
                            lstDMLResult.add(new DMLResult(null,null));
                            lstSObjectToBeUpdated.add(lstSObjects.get(i));
                        }
                    }
                }
            }else{
                lstDMLResult.add(new DMLResult(null,null));
                lstSObjectToBeUpdated.add(lstSObjects.get(i));
            }
        }
        List<Database.SaveResult> lstSaveResults = Database.update(lstSObjectToBeUpdated, allOrNothing);
        Integer saveResultIndex=0;
        for(Integer i=0;i<lstDMLResult.size();i++){
            if(lstDMLResult.get(i).crudPermissionException==null){
                lstDMLResult.get(i).saveResult = lstSaveResults.get(saveResultIndex);
                saveResultIndex++;
            }
        }
        ExceptionLoggingServices.captureExceptionLog(lstSaveResults, lstSObjectToBeUpdated, methodInfo);
        return lstDMLResult;
    }
    
    public static void updateRecords(List<SObject> lstSObjects, Map<String,Object> methodInfo){
        List<CRUDPermissionException> lstCRUDPermissionException = new List<CRUDPermissionException>();        
        for(Integer i=0;i<lstSObjects.size();i++){
            if(!lstSObjects.get(i).getSObjectType().getDescribe().isUpdateable()){
                if(methodInfo==null){
                    lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Update'));
                }else{
                    if(!methodInfo.containsKey('byPassObjects')){
                        lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Update'));
                    }else{
                        Set<String> byPassObjects = (Set<String>)methodInfo.get('byPassObjects');
                        if(!byPassObjects.contains(lstSObjects.get(i).getSObjectType()+'')){
                            lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Update'));
                        }
                    }
                }
            }
        }
        if(!lstCRUDPermissionException.isEmpty()){
            throw CRUDPermissionException.getCRUDPermissionException(lstCRUDPermissionException);
        }else{
            try{
                update lstSObjects;
            }catch(Exception ex){
                if(lstSObjects!=null && lstSObjects.size()>0 && lstSObjects.get(0).Id!=null){
                    methodInfo.put('Record_Id__c',lstSObjects.get(0).Id);
                }
                ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                throw ex;
            }
        }
    }
    // SS: Added new method with additional paramter of fieldNames for Checkmarx CCCAP-8861
    public static void updateRecords(List<SObject> lstSObjects, Map<String,Object> methodInfo,list<String> fieldNames){
        List<CRUDPermissionException> lstCRUDPermissionException = new List<CRUDPermissionException>();        
        
        for(Integer i=0;i<lstSObjects.size();i++){
            schema.DescribeSObjectResult sobj = lstSObjects.get(i).getSObjectType().getDescribe();
            Boolean isAllowed= sobj.isUpdateable();
            Map<String, SObjectField> fieldMap = sobj.fields.getMap();
            for(string fName : fieldNames){
                if(fieldMap.containsKey(fName) && !fieldMap.get(fName).getDescribe().isUpdateable()){
                    isAllowed = false;
                }
            }
            if(!isAllowed){
                if(methodInfo==null){
                    lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Update'));
                }else{
                    if(!methodInfo.containsKey('byPassObjects')){
                        lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Update'));
                    }else{
                        Set<String> byPassObjects = (Set<String>)methodInfo.get('byPassObjects');
                        if(!byPassObjects.contains(lstSObjects.get(i).getSObjectType()+'')){
                            lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Update'));
                        }
                    }
                }
            }
        }
        if(!lstCRUDPermissionException.isEmpty()){
            throw CRUDPermissionException.getCRUDPermissionException(lstCRUDPermissionException);
        }else{
            try{
                update lstSObjects;
            }catch(Exception ex){
                if(lstSObjects!=null && lstSObjects.size()>0 && lstSObjects.get(0).Id!=null){
                    methodInfo.put('Record_Id__c',lstSObjects.get(0).Id);
                }
                ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                throw ex;
            }
        }
    }
    public static void deleteRecords(List<SObject> lstSObjects, Map<String,Object> methodInfo){
        List<CRUDPermissionException> lstCRUDPermissionException = new List<CRUDPermissionException>();        
        for(Integer i=0;i<lstSObjects.size();i++){
            if(!lstSObjects.get(i).getSObjectType().getDescribe().isDeletable()){
                if(methodInfo==null){
                    lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Delete'));
                }else{
                    if(!methodInfo.containsKey('byPassObjects')){
                        lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Delete'));
                    }else{
                        Set<String> byPassObjects = (Set<String>)methodInfo.get('byPassObjects');
                        if(!byPassObjects.contains(lstSObjects.get(i).getSObjectType()+'')){
                            lstCRUDPermissionException.add(new CRUDPermissionException(lstSObjects.get(i).getSObjectType()+'', 'Delete'));
                        }
                    }
                }
            }
        }
        if(!lstCRUDPermissionException.isEmpty()){
            throw CRUDPermissionException.getCRUDPermissionException(lstCRUDPermissionException);
        }else{
            try{
                delete lstSObjects;
            }catch(Exception ex){
                if(lstSObjects!=null && lstSObjects.size()>0){
                    methodInfo.put('Record_Id__c',lstSObjects.get(0).Id);
                }
                ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                throw ex;
            }
        }
    }
    
    public static List<Database.SaveResult> getSaveResultsFromDMLResults(List<DMLResult> lstDMLResult){
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        for(DMLResult dmlRes:lstDMLResult){
            lstSaveResult.add(dmlRes.saveResult);
        }
        return lstSaveResult;
    }
    
    public static List<CRUDPermissionException> getCRUDPermissionExceptionsFromDMLResults(List<DMLResult> lstDMLResult){
        List<CRUDPermissionException> lstCrudPermissionException = new List<CRUDPermissionException>();
        for(DMLResult dmlRes:lstDMLResult){
            if(dmlRes.crudPermissionException!=null){
                lstCrudPermissionException.add(dmlRes.crudPermissionException);
            }
        }
        return lstCrudPermissionException;
    }
    public static List<DMLResult> insertRecordsWithEmailTrigger(List<SObject> lstSObjects, Database.DMLOptions dm, Map<String,Object> methodInfo){
        List<DMLResult> lstDMLResult = new List<DMLResult>();        
        List<SObject> lstSObjectToBeInserted = new List<SObject>();
        Map<SObjectType, Boolean> sObjectTypeCreateableMap = new Map<SObjectType, Boolean>();

        for(Integer i=0;i<lstSObjects.size();i++){
            SObjectType sobjType = lstSObjects.get(i).getSObjectType();
            if(!sObjectTypeCreateableMap.containsKey(sobjType)){
                sObjectTypeCreateableMap.put(sobjType, sobjType.getDescribe().isCreateable());
            }

            if(!sObjectTypeCreateableMap.get(sobjType)){
                String objName = String.valueOf(sobjType);
                if(methodInfo==null){
                    lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(objName, 'Create')));
                }else{
                    if(!methodInfo.containsKey('byPassObjects')){
                        lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(objName, 'Create')));
                    }else{
                        Set<String> byPassObjects = (Set<String>)methodInfo.get('byPassObjects');
                        if(!byPassObjects.contains(objName)){
                            lstDMLResult.add(new DMLResult(null,new CRUDPermissionException(objName, 'Create')));
                        }else{
                            lstDMLResult.add(new DMLResult(null,null));
                            lstSObjectToBeInserted.add(lstSObjects.get(i));
                        }
                    }
                }
            }else{
                lstDMLResult.add(new DMLResult(null,null));
                lstSObjectToBeInserted.add(lstSObjects.get(i));
            }
        }

        //SAS: DKIM requirement interception
        Boolean sendCustomEmails = false; 
        if(dm != null && dm.EmailHeader != null && dm.EmailHeader.triggerUserEmail == true){
            dm.EmailHeader.triggerUserEmail = false;
            sendCustomEmails = true; 
        }

        List<Database.SaveResult> lstSaveResults = Database.insert(lstSObjectToBeInserted, dm);

        //SAS: DKIM Compliant Email Transaction
        if(sendCustomEmails){
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email);
            Set<Id> userIds = new Set<Id>();
            List<Task> successfulTasks = new List<Task>();
            
            for(Integer i=0; i<lstSObjectToBeInserted.size(); i++) {
                if(lstSObjectToBeInserted[i] instanceof Task && lstSaveResults[i].isSuccess()) {
                    Task t = (Task)lstSObjectToBeInserted[i];
                    successfulTasks.add(t);
                    
                    if(t.OwnerId != null && String.valueOf(t.OwnerId).startsWith('005')) {
                        userIds.add(t.OwnerId);
                    }
                }
            }
            
            if(!successfulTasks.isEmpty()){
                Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Email FROM User WHERE Id IN :userIds]);
                Map<Id, Task> taskDetailsMap = new Map<Id, Task>([
                    SELECT Id, What.Name, What.Type FROM Task WHERE Id IN :successfulTasks
                ]);
                
                String runningUserName = UserInfo.getName();
                EmailTemplate emailTemplate;
                
                List<EmailTemplate> templates = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Custom_Task_Assignment_Template' LIMIT 1];
                if(!templates.isEmpty()) {
                    emailTemplate = templates[0];
                }                

                Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
                Map<String, String> objectLabelCache = new Map<String, String>();

                for(Task t : successfulTasks) {
                    if(t.OwnerId != null && userMap.containsKey(t.OwnerId)) {
                        User u = userMap.get(t.OwnerId);                        
                        Task queriedTask = taskDetailsMap.get(t.Id);
                        String recordName = (queriedTask != null && queriedTask.What != null) ? queriedTask.What.Name : '';
                        String objectApiName = (queriedTask != null && queriedTask.What != null) ? queriedTask.What.Type : '';
                        String objectLabel = 'Record'; 
                        
                        if (String.isNotBlank(objectApiName)) {
                            if(objectLabelCache.containsKey(objectApiName)){
                                objectLabel = objectLabelCache.get(objectApiName);
                            } else {
                                Schema.SObjectType sObjType = globalDescribeMap.get(objectApiName);                           
                                if (sObjType != null) {
                                    objectLabel = sObjType.getDescribe().getLabel();
                                    objectLabelCache.put(objectApiName, objectLabel);
                                }
                            }
                        }

                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new List<String>{u.Email});
                        mail.setSubject(t.Subject);
                        mail.setSaveAsActivity(false);
                        if(owEmailAddressId != null) {
                            mail.setOrgWideEmailAddressId(owEmailAddressId);
                        }
                        
                        if(emailTemplate != null && String.isNotBlank(emailTemplate.HtmlValue)) {
                            String htmlMailBody = emailTemplate.HtmlValue;
                            htmlMailBody = htmlMailBody.replace('{!recipientName}', u.Name);
                            htmlMailBody = htmlMailBody.replace('{!assignerName}', runningUserName);
                            htmlMailBody = htmlMailBody.replace('{!taskSubject}', t.Subject);
                            htmlMailBody = htmlMailBody.replace('{!objectName}', objectLabel);
                            htmlMailBody = htmlMailBody.replace('{!taskPriority}', t.Priority != null ? t.Priority : 'Normal');
                            htmlMailBody = htmlMailBody.replace('{!taskDueDate}', t.ActivityDate != null ? t.ActivityDate.month() + '/' + t.ActivityDate.day() + '/' + t.ActivityDate.year() : 'None');
                            htmlMailBody = htmlMailBody.replace('{!taskDescription}', t.Description != null ? t.Description : '');
                            htmlMailBody = htmlMailBody.replace('{!recordName}', recordName);
                            htmlMailBody = htmlMailBody.replace('{!recordURL}', t.WhatId != null ? URL.getOrgDomainUrl().toExternalForm() + '/' + t.WhatId : '');
                            mail.setHtmlBody(htmlMailBody);
                        }                        
                        emailsToSend.add(mail);
                    }
                }
                
                if(!emailsToSend.isEmpty()) {
                    List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailsToSend, false);
                    for (Messaging.SendEmailResult res : results){
                        if (!res.isSuccess()){
                            for (Messaging.SendEmailError err : res.getErrors()) {                                     
                                Exception ex = new NullPointerException();
                                ex.setMessage('Custom tsk email dispatch failed. Message: ' + err.getMessage() + ' (Status: ' + err.getStatusCode() + ')');
                                
                                if(lstSObjectToBeInserted != null && lstSObjectToBeInserted.size() > 0){
                                    methodInfo.put('Record_Id__c', lstSObjectToBeInserted.get(0).Id);
                                }
                                ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                            }
                        }
                    }
                }
            }
        }
        Integer saveResultIndex=0;
        for(Integer i=0;i<lstDMLResult.size();i++){
            if(lstDMLResult.get(i).crudPermissionException==null){
                lstDMLResult.get(i).saveResult = lstSaveResults.get(saveResultIndex);
                saveResultIndex++;
            }
        }
        ExceptionLoggingServices.captureExceptionLog(lstSaveResults, lstSObjectToBeInserted, methodInfo);
        return lstDMLResult;
    }
}