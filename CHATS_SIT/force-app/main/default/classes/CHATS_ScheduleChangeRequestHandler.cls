/****
* Objective: CHATS-side handler for the CCCAP Schedule Change Request intake.
*            Parses the inbound payload, looks up the CCCAP Authorization by
*            its Name (the inbound "CCCAP_Authorization" field carries the
*            Authorization Name), creates a Task owned by the related IDN Case
*            owner, and returns { status, message, taskId }.
* */
global with sharing class CHATS_ScheduleChangeRequestHandler {
    global class ApiResponseWrapper {
        @AuraEnabled global String status{get;set;}
        @AuraEnabled global String message{get;set;}
        @AuraEnabled global String taskId{get;set;}
    }
    public static ApiResponseWrapper handleCreate(String body) {
        ApiResponseWrapper resp = new ApiResponseWrapper();
        resp.status = 'success';
        List<Messaging.SingleEmailMessage> taskEmaillist = new List<Messaging.SingleEmailMessage>(); // Final Emails to be sent
        String authName = null;
        try {
            if (String.isBlank(body)) {
                return errorResp(resp, 'Request body is empty or invalid', null, null);
            }
            // Parse payload (tolerate either bare payload or { "scheduleChangeRequest": {...} })
            Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(body);
            if (raw.containsKey('scheduleChangeRequest') && raw.get('scheduleChangeRequest') instanceof Map<String, Object>) {
                raw = (Map<String, Object>) raw.get('scheduleChangeRequest');
            }
            authName        = sanitize((String) raw.get('CCCAP_Authorization'), 80);
            String comment  = sanitize((String) raw.get('Requested_Schedule_Change'), 32000);
            String stackRsp = sanitize((String) raw.get('Stack_CCCAP_UPK_Response'), 50);    
            if (String.isBlank(authName)) {
                return errorResp(resp, 'CCCAP_Authorization is required', null, null);
            }
            List<T_AUTH__C> authRecord = [SELECT Name,IDN_Case__c, IDN_Case__r.OwnerId,IDN_Case__r.Owner.Email,IDN_Case__r.Owner.Name
                                          FROM T_AUTH__C
                                          WHERE Name = :authName
                                          LIMIT 1
                                         ];
            String stackText = String.isBlank(stackRsp) ? 'No response' : stackRsp;
            String description =
                'ATS parent submitted CCCAP care schedule change request for ' + authName
                + ', ATS Parent Comment: ' + (comment == null ? '' : comment.unescapeHtml4())
                + ', parent response to \u201CWould you like to stack child CCCAP/UPK schedule?\u201D was '
                + stackText + '.';
            Task t = new Task(
                Subject      = 'T124 – ATS CCCAP Authorization Change Request',
                Description  = description,
                Status       = 'Not Started',
                ActivityDate = Date.today()+10,
                OwnerId      = authRecord[0].IDN_Case__r.OwnerId,
                WhatId       = authRecord[0].Id
            );
            
            if(authRecord[0].IDN_Case__r.Owner.Email!=null && authRecord[0].IDN_Case__r.Owner.Email!=''){
                EmailTemplate emailTemplate = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Task_Assignment_Custom_Template' LIMIT 1];
                Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email);

                String htmlMailBody = emailTemplate.HtmlValue;
                htmlMailBody = htmlMailBody.replace('{!recipientName}', authRecord[0].IDN_Case__r.Owner.Name);
                htmlMailBody = htmlMailBody.replace('{!taskSubject}', t.Subject);
                htmlMailBody = htmlMailBody.replace('{!objectName}', 'Authorization');
                htmlMailBody = htmlMailBody.replace('{!recordName}', authRecord[0].Name);
                htmlMailBody = htmlMailBody.replace('{!taskDueDate}', t.ActivityDate.month() + '/' + t.ActivityDate.day() + '/' + t.ActivityDate.year());
                htmlMailBody = htmlMailBody.replace('{!taskPriority}', 'Normal');
                htmlMailBody = htmlMailBody.replace('{!taskDescription}', t.Description);
                htmlMailBody = htmlMailBody.replace('{!recordURL}', Label.CDHS_LMS_Link);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{authRecord[0].IDN_Case__r.Owner.Email});
                mail.setSubject(t.Subject);
                mail.setHtmlBody(htmlMailBody);
                If(owEmailAddressId != null){
                    mail.setOrgWideEmailAddressId(owEmailAddressId);
                }
                taskEmaillist.add(mail);
            }
            
            
            Database.SaveResult sr = Database.insert(t, false);
            // #####  DML for final Tasks and sending Emails #####           
            if (!sr.isSuccess()) {
                List<String> msgs = new List<String>();
                for (Database.Error e : sr.getErrors()) {
                    msgs.add(e.getStatusCode() + ': ' + e.getMessage());
                }
                return errorResp(resp, 'Failed to create Task: ' + String.join(msgs, ' | '), authName, null);
            }
            if(!test.isrunningTest())
                Messaging.sendEmail(taskEmaillist);
            resp.message = 'Task created for CCCAP Authorization ' + authName;
            return resp;   
        } catch (Exception ex) {
            return errorResp(resp, ex.getMessage(), authName, ex.getStackTraceString());
        }
    }
    // Trim, cap length, strip control chars, and HTML-escape an inbound API string.
    // Returns null when the input is null/blank after trimming.
    @TestVisible
    private static String sanitize(String value, Integer maxLength) {
        if (value == null) {
            return null;
        }
        String cleaned = value.trim();
        if (String.isBlank(cleaned)) {
            return null;
        }
        // Strip ASCII control chars (keep tab, LF, CR)
        cleaned = cleaned.replaceAll('[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]', '');
        if (maxLength != null && maxLength > 0 && cleaned.length() > maxLength) {
            cleaned = cleaned.substring(0, maxLength);
        }
        // Defense-in-depth against HTML/script injection in downstream renderings
        return cleaned.escapeHtml4();
    }
    // Logs the failure to Exception_Log__c and stamps the response as an error
    private static ApiResponseWrapper errorResp(ApiResponseWrapper resp, String message, String recordId, String stack) {
        resp.status  = 'error';
        resp.message = message;
        Database.insert(new Exception_Log__c(
            Exception_Message__c = message,
            Record_ID__c         = recordId,
            Exception_Type__c    = 'Web Service',
            Method__c            = 'handleCreate',
            Class__c             = 'CHATS_ScheduleChangeRequestHandler',
            Stack_Trace__c       = stack
        ), false);
        return resp;
    }
}