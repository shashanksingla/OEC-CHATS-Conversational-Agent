/*************************************************************
Class Name      - T233_TaskCreationBatch  
Test Class      - T233_TaskCreationBatch_Test
Description     - Task to remind user to perform Case Review when RE106 is generated 
Author          - Shashank Singla
Requirement     - Project 425, JIRA CCCAP-11862
**************************************************************/
global class T233_TaskCreationBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public List<Exception_Log__c> errors = new List<Exception_Log__c>();
    public Set<Integer> countySet = new Set<Integer>();
    
    global void execute(SchedulableContext ctx) {
        database.executebatch(new T233_TaskCreationBatch(), 200);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryStr ='SELECT Id, Subject, Status, County__c FROM Task WHERE Subject = \'T230 – RE106 is Available for Review\' AND ActivityDate = THIS_MONTH';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<Task> scope) {
        try {
            for(Task t : scope){
                if(t.Status != 'Completed' && t.Status != 'Deferred' && t.Status != 'Cancelled'){
                    countySet.add(Integer.valueOf(t.County__c));
                }
            }
        } catch(Exception e) {
            errors.add(new Exception_Log__c(Class__c = 'T233_TaskCreationBatch', Method__c = 'execute', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'));
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        List<Task> taskToInsert = new List<Task>();
        List<Messaging.SingleEmailMessage> taskEmaillist = new List<Messaging.SingleEmailMessage>();
        Map<String, String> reviewQueueMap = new Map<String, String>();
        Map<Integer, String> countyCodeNameMap = new Map<Integer, String>();
        Map<String, Set<String>> queueMemberMap = new Map<String, Set<String>>();
        Map<String, User> userMap = new Map<String, User>();
        Set<String> queueMemberIdSet = new Set<String>();
        try {
            if(!countySet.isEmpty()){
                EmailTemplate emailTemplate = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Task_Assignment_Custom_Template_NoHyperlink' LIMIT 1];
                Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email);
                for(GroupMember gm : [SELECT UserOrGroupId, GroupId, Group.DeveloperName FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName LIKE '%Lead_Workers_Supervisors' ORDER BY Group.DeveloperName]){
                    reviewQueueMap.put(gm.Group.DeveloperName, gm.GroupId);
                    queueMemberIdSet.add(gm.UserOrGroupId);
                    if(queueMemberMap.containsKey(gm.GroupId)){
                        Set<String> memberList = queueMemberMap.get(gm.GroupId);
                        if(!memberList.contains(gm.UserOrGroupId)){
                            memberList.add(gm.UserOrGroupId);
                        }
                        queueMemberMap.put(gm.GroupId, memberList);
                    } else {
                        Set<String> memberList = new Set<String>{gm.UserOrGroupId};
                        queueMemberMap.put(gm.GroupId, memberList);
                    }
                }
                for(User u : [SELECT Id, Email, Name FROM User WHERE Id IN: queueMemberIdSet]){
                    userMap.put(u.Id, u);
                }
                Schema.DescribeFieldResult countyField = User.Owner_County__c.getDescribe();
                List<Schema.PicklistEntry> countyPicklistValues = countyField.getPicklistValues();
                for(Schema.PicklistEntry pe : countyPicklistValues){
                    countyCodeNameMap.put(Integer.valueOf(pe.getValue()), pe.getLabel());
                }
                for(Integer county : countySet){
                    String queueId = reviewQueueMap.get((countyCodeNameMap.get(county).replace(' ', '_')) + '_Lead_Workers_Supervisors');
                    if(String.isBlank(queueId))
                        continue;
                    Task t = new Task();
                    t.Subject = Label.Task_T233_Subject;
                    t.Description = Label.Task_T233_Description;
                    t.ActivityDate = Date.newInstance(System.today().year(), System.today().month(), 20);
                    t.OwnerId = queueId;
                    t.County__c = String.valueOf(county);
                    taskToInsert.add(t);
                    for(String queueMemberId : queueMemberMap.get(queueId)){
                        User u = userMap.get(queueMemberId);
                        String htmlMailBody = emailTemplate.HtmlValue;
                        htmlMailBody = htmlMailBody.replace('{!recipientName}', u.Name);
                        htmlMailBody = htmlMailBody.replace('{!taskSubject}', Label.Task_T233_Subject);
                        htmlMailBody = htmlMailBody.replace('{!taskDueDate}', System.today().month() + '/20/' + System.today().year());
                        htmlMailBody = htmlMailBody.replace('{!taskPriority}', 'Normal');
                        htmlMailBody = htmlMailBody.replace('{!taskDescription}', Label.Task_T233_Description);
                        htmlMailBody = htmlMailBody.replace('{!customText}', '');
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new List<String>{u.Email});
                        mail.setSubject(Label.Task_T233_Subject);
                        mail.setHtmlBody(htmlMailBody);
                        if(owEmailAddressId != null){
                            mail.setOrgWideEmailAddressId(owEmailAddressId);
                        }
                        taskEmaillist.add(mail);
                    }
                }
                if(!taskToInsert.isEmpty()){
                    Database.insert(taskToInsert, false);
                    Messaging.sendEmail(taskEmaillist);
                }
            }
        } catch(Exception e) {
            errors.add(new Exception_Log__c(Class__c = 'T233_TaskCreationBatch', Method__c = 'finish', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'));
        }
        if(!errors.isEmpty()){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'T233_TaskCreationBatch'});
        }
    }
}