public with sharing class CHATS_ProviderClaimRequestHandler {
    public static CHATS_claimResponseWrapper resp {get;set;}
    public static Map<String, Object> RequestMap{get;set;}
    private static Map<String,Object> methodInfo = new Map<String,Object>();
    private static List<Exception_Log__c> xLogs = new List<Exception_Log__c>();
    
    public static CHATS_claimResponseWrapper handleSaveOperation(String Body){
        resp = new CHATS_claimResponseWrapper();
        resp.status='success';
        RequestMap =   (Map<String, Object>) JSON.deserializeUntyped(Body);
        if(RequestMap.get('operation') == 'UpsertClaim'){
            saveClaimData();
        }else{
            resp.status = 'error';
            resp.message = 'Operation not defined';
        }
        return resp;
    }    
    private static void saveClaimData(){
        System.savePoint databaseSavepoint = Database.setSavepoint();
        Map<String,Id> T235OwnerQueues = new Map<String,Id>();
        List<Task> t235ToInsert = new List<Task>();
        methodInfo.put('Class__c','CHATS_ProviderClaimRequestHandler');
        methodInfo.put('Method__c','saveClaimData');
        try{
            List<Messaging.SingleEmailMessage> taskEmaillist = new List<Messaging.SingleEmailMessage>(); // Final Emails to be sent
            Map<String, Set<String>> queueMemberMap = new Map<String, Set<String>>();
            Set<String> totalUserIdList = new Set<String>();
            Map<String, User> userEmailMap = new Map<String, User>();
            List<Sobject> claimDetailsToUpsert = new list<Sobject>();
            List<Sobject> claimDayDetailsToUpsert = new list<Sobject>();
            List<Sobject> claimFilesToUpsert = new list<Sobject>();
            Map<String,object> claimMap = (Map<String,object>) RequestMap.get('claim');
            Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email);

            for(Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE '%_235_Task']){
                T235OwnerQueues.put(g.DeveloperName, g.Id);
            }
            // Fetching all members of all Tax Intercept queues
            for(GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName LIKE '%_235_Task' ORDER BY Group.DeveloperName]){
                if(queueMemberMap.containsKey(gm.GroupId)){
                    Set<String> memberList = queueMemberMap.get(gm.GroupId);
                    if(!memberList.contains(gm.UserOrGroupId)){
                        memberList.add(gm.UserOrGroupId);
                        totalUserIdList.add(gm.UserOrGroupId);
                    }
                    queueMemberMap.put(gm.GroupId, memberList);
                } else {
                    Set<String> memberList = new Set<String>{gm.UserOrGroupId};
                        totalUserIdList.add(gm.UserOrGroupId);
                    queueMemberMap.put(gm.GroupId, memberList);
                }
            }
            // Fetching emails of all Tax Intercept queue members
            for(User u : [SELECT Id, Email, Name FROM User WHERE Id IN: totalUserIdList]){
                userEmailMap.put(u.Id, u);
            }
            for(string key : claimMap.keyset()){
                if(key.containsIgnoreCase('__r')){
                    claimMap.remove(key);
                }
            }
            claimMap.remove('CreatedDate');
            Sobject claimRecord = (Sobject)JSON.deserialize(JSON.serialize(claimMap),Sobject.class); //claimWrap.claim;
            claimRecord.Id = null;
            claimRecord.put('Denied_Claim_Queue__c', [select id from Provider_Manual_Claim__c where IDN_EXTNL__c =:(Id)claimRecord.get('Denied_Claim_Queue__c') LIMIT 1]?.Id);
            claimRecord.put('CHATS_Provider__c',[select id from T_CHATS_PROVR_STATUS__c where External_ID__c =: (string)claimRecord.get('Provider_Id__c') LIMIT 1]?.Id);
            // #####  DML  Inserting Claim #####
            GenericDMLHandler.insertRecords(new List<Sobject>{claimRecord}, methodInfo);
            
            
            List<claimDetailWrapper> claimDWrap = (List<claimDetailWrapper>) JSON.deserialize(JSON.serialize(RequestMap.get('claimDetails')),List<claimDetailWrapper>.class); //claimWrap.claim;
            if(claimDWrap!=null && !claimDWrap.isEmpty()){
                for (claimDetailWrapper wrap :claimDWrap) {
                    Claim_Detail__c claimDetailRecord = (Claim_Detail__c)wrap.claimDetail;
                    claimDetailRecord.id = null;
                    claimDetailRecord.Provider_Manual_Claim__c = claimRecord.Id;
                    claimDetailsToUpsert.add(claimDetailRecord);
                }
                // #####  DML Inserting Claim Details #####
                GenericDMLHandler.insertRecords(claimDetailsToUpsert, methodInfo);
                
                for (claimDetailWrapper wrap : claimDWrap) {
                    if(wrap.claimDayDetails!=null && !wrap.claimDayDetails.isEmpty()){
                        for (Sobject dayDetail : wrap.claimDayDetails) {
                            dayDetail.Id=null;
                            dayDetail.put('Claim_Detail__c', wrap.claimDetail.Id);
                            dayDetail.put('Provider_Manual_Claim__c', claimRecord.Id);
                            claimDayDetailsToUpsert.add(dayDetail);
                        }
                    }
                }
                // #####  DML Inserting Claim Day Details #####
                GenericDMLHandler.insertRecords(claimDayDetailsToUpsert, methodInfo);
            }
            List<Sobject> claimFiles = (List<Sobject>)JSON.deserialize(JSON.serialize(RequestMap.get('claimFiles')),List<Sobject>.class); //claimWrap.claim;
            if(claimFiles!=null && !claimFiles.isEmpty()){
                for (Sobject claimFile :claimFiles) {
                    claimFile.id = null;
                    claimFile.put('Provider_Manual_Claim__c',claimRecord.Id);
                    claimFilesToUpsert.add(claimFile);
                }
                // #####  DML Inserting Claim Files #####
                GenericDMLHandler.insertRecords(claimFilesToUpsert, methodInfo); 
            }
            String claimCounty = (String)claimRecord.get('County__c');
            if(claimCounty!=null && T235OwnerQueues.containsKey(claimCounty.replace(' ', '_') + '_T235_Task')){
                Task t = new Task();
                t.Subject = Label.Task_T235_Subject;
                String Recordlink = URL.getOrgDomainUrl().toExternalForm()+'/'+claimRecord.get('CHATS_Provider__c');
                t.Description = (Label.Task_T235_Description).replace('{!providerId}', Recordlink).replace('{!CountyName}',(String)claimRecord.get('County__c'));
                t.ActivityDate = System.today().addDays(14);
                t.WhatId = claimRecord.Id;
                t.OwnerId = T235OwnerQueues.get(claimCounty.replace(' ', '_') + '_T235_Task'); // owner pending from business
                
                EmailTemplate emailTemplate = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Task_Assignment_Custom_Template' LIMIT 1];
                // Preparing Email data
                if(queueMemberMap.containskey(t.OwnerId)){
                    for(String queueMember : queueMemberMap.get(t.OwnerId)){
                        User u = userEmailMap.get(queueMember);
                        String htmlMailBody = emailTemplate.HtmlValue;
                        htmlMailBody = htmlMailBody.replace('{!recipientName}', u.Name);
                        htmlMailBody = htmlMailBody.replace('{!taskSubject}', Label.Task_T235_Subject);
                        htmlMailBody = htmlMailBody.replace('{!objectName}', 'Provider Manual Claim');
                        htmlMailBody = htmlMailBody.replace('{!recordName}', (String)claimRecord.get('Name'));
                        htmlMailBody = htmlMailBody.replace('{!taskDueDate}', t.ActivityDate.month() + '/' + t.ActivityDate.day() + '/' + t.ActivityDate.year());
                        htmlMailBody = htmlMailBody.replace('{!taskPriority}', 'Normal');
                        htmlMailBody = htmlMailBody.replace('{!taskDescription}', t.Description);
                        htmlMailBody = htmlMailBody.replace('{!recordURL}', URL.getOrgDomainUrl().toExternalForm() + '/' + t.whatId);
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new List<String>{u.Email});
                        mail.setSubject(Label.Task_T235_Subject);
                        mail.setHtmlBody(htmlMailBody);
                        if(owEmailAddressId != null){
                            mail.setOrgWideEmailAddressId(owEmailAddressId);
                        }
                        taskEmaillist.add(mail);
                    } 
                }
                // #####  DML for final Tasks and sending Emails #####
                GenericDMLHandler.insertRecords(new list<Sobject>{t}, methodInfo);
                if(!test.isrunningTest())
                    Messaging.sendEmail(taskEmaillist);
            }
        }
        catch(exception ex){
            xlogs.add(ExceptionLoggingServices.captureExceptionLogInstance(ex,methodInfo));
        }
        if(xlogs!=null && !xlogs.isEmpty()){
            Database.rollback(databaseSavepoint);
            resp.status = 'error';
            resp.message = (String)xlogs[0].Exception_Message__c;
            Insert xlogs;
        }
    }
    public class claimDetailWrapper {
        Sobject claimDetail;
        list<Sobject> claimDayDetails;

    }
}