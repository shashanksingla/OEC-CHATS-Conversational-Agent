/*****************************************************************************************
Class Name      - ClientComplaintTriggerHandler
Trigger         - ClientComplaintTrigger
Test Class      - ClientComplaintTriggerHandler_Test
Description     - Handler class for Client_Complaint__c trigger. 
*****************************************************************************************/
public with sharing class ClientComplaintTriggerHandler {

    public static Boolean skipT236ForCountyTransfer = false;

    private static final String T236_SUBJECT      = System.Label.Task_T236_Subject;
    private static final String TASK_STATUS       = 'Not Started';
    private static final String T236_COMMENT      = System.Label.Task_T236_Description;
    private static final Integer BUSINESS_DAYS_DUE = 3;
    private static final String STATUS_NEW         = 'New';
    private static final String STATUS_IN_PROGRESS = 'In progress';

    public static void handleAfterInsert(List<Client_Complaint__c> newList) {
        if (skipT236ForCountyTransfer) {
            return;
        }
        List<Client_Complaint__c> eligible = new List<Client_Complaint__c>();
        for (Client_Complaint__c cc : newList) {
            if (cc.Assignee__c != null && cc.Complaint_Status__c == STATUS_NEW) {
                eligible.add(cc);
            }
        }
        if (!eligible.isEmpty()) {
            createT236Tasks(eligible);
        }
    }

    private static void createT236Tasks(List<Client_Complaint__c> complaints) {
        Date dueDate = addBusinessDays(Date.today(), BUSINESS_DAYS_DUE);

        List<Task> tasksToInsert = new List<Task>();
        for (Client_Complaint__c cc : complaints) {
            Task t         = new Task();
            t.Subject      = T236_SUBJECT;
            t.Status       = TASK_STATUS;
            t.Description  = T236_COMMENT;
            t.ActivityDate = dueDate;
            t.OwnerId      = cc.Assignee__c;
            t.WhatId       = cc.Id;
            t.Priority     = 'Normal';
            tasksToInsert.add(t);
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    // Marks all open tasks on a complaint as Completed.
    public static void completeOpenTasks(Id complaintId) {
        if (complaintId == null) return;

        List<Task> openTasks = [SELECT Id FROM Task WHERE WhatId = :complaintId AND Status != 'Completed'];
        if (!openTasks.isEmpty()) {
            for (Task t : openTasks) {
                t.Status = 'Completed';
            }
            new TaskElevatedOps().updateTasks(openTasks);
        }
    }

    // Reassigns all open tasks on a complaint to new assignee
    public static void reassignOpenTasks(Id complaintId, Id newOwnerId) {
        if (complaintId == null || newOwnerId == null) return;

        Database.update(new Client_Complaint__c(Id = complaintId, byPassValidation__c = true), false);

        try {
            List<Task> openTasks = [SELECT Id FROM Task WHERE WhatId = :complaintId AND Status != 'Completed'];
            if (!openTasks.isEmpty()) {
                for (Task t : openTasks) {
                    t.OwnerId = newOwnerId;
                }
                new TaskElevatedOps().updateTasks(openTasks);
            }
        } finally {
            // Always reset the bypass flag
            Database.update(new Client_Complaint__c(Id = complaintId, byPassValidation__c = false), false);
        }
    }

    // runs without sharing to bypass Task OWD access restrictions.
    private without sharing class TaskElevatedOps {
        void updateTasks(List<Task> tasks) {
            if (tasks != null && !tasks.isEmpty()) {
                Database.update(tasks, false);
            }
        }
    }

    public static void createT237Task(Client_Complaint__c newComplaint, Id assigneeId, Id taskOwnerId) {
        String taskSubject  = System.Label.Task_T237_Subject;
        String taskComment  = System.Label.Task_T237_Description;
        Date   dueDate      = addBusinessDays(Date.today(), BUSINESS_DAYS_DUE);

        Task t         = new Task();
        t.Subject      = taskSubject;
        t.Status       = TASK_STATUS;
        t.Description  = taskComment;
        t.ActivityDate = dueDate;
        t.OwnerId      = taskOwnerId;
        t.WhatId       = newComplaint.Id;
        t.Priority     = 'Normal';
        insert t;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Business-day calculator
    // Day 1 starts the business day AFTER the submission date (today = Day 0).
    // Monday–Friday are business days; Saturday and Sunday are skipped.
    // ─────────────────────────────────────────────────────────────────────────

    @TestVisible
    private static Date addBusinessDays(Date startDate, Integer businessDaysToAdd) {
        Date result       = startDate;
        Integer daysAdded = 0;
        while (daysAdded < businessDaysToAdd) {
            result = result.addDays(1);
            Integer dayOfWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(result), 7);
            // 0 = Sunday, 6 = Saturday  (anchor: 1900-01-07 was a Sunday)
            if (dayOfWeek != 0 && dayOfWeek != 6) {
                daysAdded++;
            }
        }
        return result;
    }
}