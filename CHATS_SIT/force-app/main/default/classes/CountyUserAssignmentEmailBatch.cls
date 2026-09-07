/*************************************************************
Class Name      - CountyUserAssignmentEmailBatch
Test Class      - CountyUserAssignmentEmailBatch_Test
Description     - When a county does not have a profile users assigned, send email to the CCCAP State team
Author          - Rishav Maji
Requiremnt      - CCCAP-5489
**************************************************************/
global class CountyUserAssignmentEmailBatch implements Database.Batchable<sObject>, Schedulable {
    
    public List<Exception_Log__c> errors = new List<Exception_Log__c>();
    
    global void execute(SchedulableContext ctx) {
        database.executebatch(new CountyUserAssignmentEmailBatch(), 1); // BATCH SIZE SHOULD ALWAYS BE 1
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryStr ='SELECT Id, Name, CDE_COUNTY__c FROM T_COUNTY__c WHERE CDE_COUNTY__c != 66 ORDER BY CDE_COUNTY__c';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_COUNTY__c> scope) {
        try {
            T_COUNTY__c county = scope.isEmpty() ? null : scope[0];
            String countyCode = String.valueOf(Integer.valueOf(county.CDE_COUNTY__c));
            if(!String.isBlank(countyCode)){
                // Changed to Permission Set names CCCAP-14993
                String BOW 	= 'Business_Office_Worker_PS';
                String BOS 	= 'Business_Office_Supervisor_PS';
                String EW 	= 'Eligibility_Worker_PS';
                String EWS 	= 'Eligibility_Worker_Supervisor_PS';
                String FW 	= 'Fiscal_Worker_PS';
                String FWS 	= 'Fiscal_Worker_Supervisor_PS';
                String PW 	= 'Provider_Worker_PS';
                String PWS 	= 'Provider_Worker_Supervisor_PS';
                String UU 	= 'Universal_User_PS';
                String IPVU	= 'IPV Update';
                String IPVS	= 'IPV Supervisor';
                Boolean profileRuleViolation = false;
                Boolean roleRuleViolation = false;
                EmailTemplate emailTemplate = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'County_User_Assignment_Template' WITH SECURITY_ENFORCED LIMIT 1];
                Set<String> permSetNames = new Set<String>();//CCCAP-14993
                Set<String> roleSet = new Set<String>();
                Set<Id> userIds = new Set<Id>();
                String ruleDescription;
                
                List<String> permissionSetNames = new List<String>{BOW, BOS, EW, EWS, FW, FWS, PW, PWS, UU};
                String psaQuery = 'SELECT AssigneeId, PermissionSet.Name, Assignee.UserRole.Name ' +
                                  'FROM PermissionSetAssignment ' +
                                  'WHERE Assignee.IsActive = true ' +
                                  'AND (Assignee.Owner_County__c = :countyCode OR Assignee.Common_County__c INCLUDES (:countyCode)) ' +
                                  'AND PermissionSet.Name IN :permissionSetNames';
                if(Test.isRunningTest()){
                    psaQuery += ' AND Assignee.CreatedById = \'' + UserInfo.getUserId() + '\'';
                }
                // Query permission set assignments for these users CCCAP-14993
                for(PermissionSetAssignment psa : Database.query(psaQuery)) {
                    userIds.add(psa.AssigneeId);
                    permSetNames.add(psa.PermissionSet.Name);
                    roleSet.add(psa.Assignee.UserRole.Name);
                }
                
                if(!userIds.isEmpty()){
                    //Using Permission set CCCAP-14993
                    // Profile Rule (#2, #3, #4, #5) validation
                    if(!profileRuleViolation && !permSetNames.contains(UU) && !permSetNames.contains(FW) && !permSetNames.contains(FWS) && !permSetNames.contains(BOW) && !permSetNames.contains(BOS)){
                        profileRuleViolation = true; // Rule #2 Violation
                        ruleDescription = 'There is no Universal User and no Fiscal Worker, Fiscal Supervisor, Business Office Worker or Business Office Supervisor.';
                    }
                    if(!profileRuleViolation && !permSetNames.contains(UU) && !permSetNames.contains(PW) && !permSetNames.contains(PWS) && !permSetNames.contains(BOW) && !permSetNames.contains(BOS)){
                        profileRuleViolation = true; // Rule #3 Violation
                        ruleDescription = 'There is no Universal User and no Provider Worker,  Provider Worker Supervisor, Business Office Worker or Business Office Supervisor.';
                    }
                    if(!profileRuleViolation && !permSetNames.contains(UU) && !permSetNames.contains(EW) && !permSetNames.contains(EWS)){
                        profileRuleViolation = true; // Rule #4 Violation
                        ruleDescription = 'There is no Universal User and no Eligibility Worker or Eligibility Supervisor.';
                    }
                    if(!profileRuleViolation && !permSetNames.contains(UU) && !permSetNames.contains(BOS) && !permSetNames.contains(EWS) && !permSetNames.contains(FWS) && !permSetNames.contains(PWS)){
                        profileRuleViolation = true; // Rule #5 Violation
                        ruleDescription = 'There is no Universal User and no Supervisor profile user (any supervisor).';
                    }
                    if(profileRuleViolation){
                        List<OrgWideEmailAddress> owa = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'CHATS Support Team (Do Not Reply)' WITH SECURITY_ENFORCED];
                        String htmlMailBody = emailTemplate.HtmlValue;
                        htmlMailBody = htmlMailBody.replace('{!countyName}', county.Name);
                        htmlMailBody = htmlMailBody.replace('{!ruleDescription}', ruleDescription);
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        if(!owa.isEmpty()){
                            mail.setOrgWideEmailAddressId(owa[0].Id);
                        }
                        mail.setToAddresses(new List<String>{User_and_Email_Settings__c.getInstance('Support Helpdesk Email').Value__c});
                        mail.setSubject(county.Name + ' County profile set user assignment needs attention');
                        mail.setHtmlBody(htmlMailBody);
                        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                    }
                    
                    // Role Rule (#7, #8, #9) validation, Rule #6 no longer needed
                    if(!roleRuleViolation && !roleSet.contains(IPVU) && !roleSet.contains(IPVS)){
                        roleRuleViolation = true; // Rule #7 Violation
                        ruleDescription = 'There are no IPV Update and no IPV Supervisor role users.';
                    }
                    if(!roleRuleViolation && !roleSet.contains(IPVU) && roleSet.contains(IPVS)){
                        roleRuleViolation = true; // Rule #8 Violation
                        ruleDescription = 'There is a user with IPV Supervisor role but no user with IPV Update role.';
                    }
                    if(!roleRuleViolation && roleSet.contains(IPVU) && !roleSet.contains(IPVS)){
                        roleRuleViolation = true; // Rule #9 Violation
                        ruleDescription = 'There is a user with IPV Update role but no user with IPV Supervisor role.';
                    }
                    if(roleRuleViolation){
                        List<OrgWideEmailAddress> owa = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'CHATS Support Team (Do Not Reply)' WITH SECURITY_ENFORCED];
                        String htmlMailBody = emailTemplate.HtmlValue;
                        htmlMailBody = htmlMailBody.replace('{!countyName}', county.Name);
                        htmlMailBody = htmlMailBody.replace('{!ruleDescription}', ruleDescription);
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        if(!owa.isEmpty()){
                            mail.setOrgWideEmailAddressId(owa[0].Id);
                        }
                        mail.setToAddresses(new List<String>{User_and_Email_Settings__c.getInstance('CCCAP Monitoring Team Email').Value__c});
                        mail.setSubject(county.Name + ' County profile set user assignment needs attention');
                        mail.setHtmlBody(htmlMailBody);
                        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                    }
                } else {
                    // Rule #1 Violation
                    List<OrgWideEmailAddress> owa = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'CHATS Support Team (Do Not Reply)' WITH SECURITY_ENFORCED];
                    ruleDescription = 'County does not have an active user assigned.';
                    String htmlMailBody = emailTemplate.HtmlValue;
                    htmlMailBody = htmlMailBody.replace('{!countyName}', county.Name);
                    htmlMailBody = htmlMailBody.replace('{!ruleDescription}', ruleDescription);
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    if(!owa.isEmpty()){
                        mail.setOrgWideEmailAddressId(owa[0].Id);
                    }
                    mail.setToAddresses(new List<String>{User_and_Email_Settings__c.getInstance('Support Helpdesk Email').Value__c});
                    mail.setSubject(county.Name + ' County profile set user assignment needs attention');
                    mail.setHtmlBody(htmlMailBody);
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                }
            }
        } catch(Exception e) {
            errors.add(new Exception_Log__c(Class__c = 'CountyUserAssignmentEmailBatch', Method__c = 'execute', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'));
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'CountyUserAssignmentEmailBatch'});
        }
    }

}