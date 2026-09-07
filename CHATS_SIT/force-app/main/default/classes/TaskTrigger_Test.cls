/*************************************************************
Class Name	    - TaskTrigger_Test
Covering Class	- TaskTrigger, TaskServicesAPXCtrl
Author          - Rishav Maji
**************************************************************/
@isTest
public class TaskTrigger_Test {

    @testSetup
    public static void doSetup(){
        Date datetoday = System.Today();
        Date firstDayOfNextMonth = date.newInstance(datetoday.year(), datetoday.month() + 1, 1);
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(true, 'Level 1');
        T_COUNTY_PLAN__c CPRec = TestClassUtility.createCountyPlan('PEN', false);
        CPRec.CDE_COUNTY__c = countyRec.Id;
        Insert CPRec;
        T_PROVR_FISCAL_AGREMENT__c FARec = TestClassUtility.createFiscaAgreement(false, 'FA1', firstDayOfNextMonth, countyRec.Id);
        FARec.ID_SERVICE__c = provRec.Id;
        FARec.CDE_COUNTY__c = countyRec.Id;
        Insert FARec;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.CDE_COUNTY__c = countyRec.Id;
        Insert caseRec;
        T_AUTH__c authRec = TestClassUtility.createAuthorization(false, null, System.today().addDays(-8), countyRec.Id, provRec.Id);
        authRec.IDN_CASE__c = caseRec.Id;
        authRec.CDE_COUNTY__c = countyRec.Id;
        Insert authRec;
        T_ADJMT__c adjRec = TestClassUtility.createAdjustment(false, countyRec.Id, caseRec.Id, provRec.Id);
        adjRec.CDE_COUNTY__c = countyRec.Id;
        Insert adjRec;
        T_COUNTY_RATE__c CRPRec = TestClassUtility.createCountyRatePlan('PEN', false);
        CRPRec.IDN_COUNTY__c = countyRec.Id;
        Insert CRPRec;
    }
    
    // Bulk insertion as End User with County mismatch
    public static testMethod void TaskTrigger_Test1(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'Universal User' LIMIT 1].Id;
        User u = TestClassUtility.createUserWithPS(uuId,'Universal_User_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u){
            Test.startTest();
            T_COUNTY__c countyRec = [SELECT Id FROM T_COUNTY__c WHERE CDE_COUNTY__c = 1 LIMIT 1];
            
            List<Task> tasksToInsert = new List<Task>();
            
            Task t1 = new Task();
            t1.Subject = 'Test FA';
            t1.OwnerId = u.id;
            t1.Status = 'Completed';
            t1.WhatId = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t1);
            
            Task t2 = new Task();
            t2.Subject = 'Test Case';
            t2.OwnerId = u.id;
            t2.Status = 'Completed';
            t2.WhatId = [SELECT Id FROM T_SBSD_CASE__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t2);
            
            Task t3 = new Task();
            t3.Subject = 'Test CP';
            t3.OwnerId = u.id;
            t3.Status = 'Completed';
            t3.WhatId = [SELECT Id FROM T_COUNTY_PLAN__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t3);
            
            Task t4 = new Task();
            t4.Subject = 'Test Auth';
            t4.OwnerId = u.id;
            t4.Status = 'Completed';
            t4.WhatId = [SELECT Id FROM T_AUTH__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t4);
            
            Task t5 = new Task();
            t5.Subject = 'Test Adj';
            t5.OwnerId = u.id;
            t5.Status = 'Completed';
            t5.WhatId = [SELECT Id FROM T_ADJMT__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t5);
            
            Task t6 = new Task();
            t6.Subject = 'Test CRP';
            t6.OwnerId = u.id;
            t6.Status = 'Completed';
            t6.WhatId = [SELECT Id FROM T_COUNTY_RATE__c WHERE IDN_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t6);
            
            Task t7 = new Task();
            t7.Subject = 'Test County';
            t7.OwnerId = u.id;
            t7.Status = 'Completed';
            t7.WhatId = countyRec.Id;
            tasksToInsert.add(t7);
            
            Task t8 = new Task();
            t8.Subject = 'Test Provider';
            t8.OwnerId = u.id;
            t8.Status = 'Completed';
            t8.WhatId = [SELECT Id FROM T_CHATS_PROVR_STATUS__c WHERE TXT_CHATS_RATING__c = 'Level 1'].Id;
            tasksToInsert.add(t8);
            
            Try {
                Insert tasksToInsert;
            } Catch(Exception e) {
                System.assertEquals('System.DmlException', e.getTypeName());
            }
            Test.stopTest();
        }
    }
    
    // Bulk & Single insertion as System Admin
    public static testMethod void TaskTrigger_Test2(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u = TestClassUtility.createUserwithPS(uuId,'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u){
            Test.startTest();
            T_COUNTY__c countyRec = [SELECT Id FROM T_COUNTY__c WHERE CDE_COUNTY__c = 1 LIMIT 1];
            Task t1 = new Task();
            t1.Subject = 'Test FA';
            t1.OwnerId = u.id;
            t1.Status = 'Completed';
            t1.WhatId = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            INSERT t1;
            
            List<Task> tasksToInsert = new List<Task>();
            
            Task t2 = new Task();
            t2.Subject = 'Test Case';
            t2.OwnerId = u.id;
            t2.Status = 'Completed';
            t2.WhatId = [SELECT Id FROM T_SBSD_CASE__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t2);
            
            Task t3 = new Task();
            t3.Subject = 'Test CP';
            t3.OwnerId = u.id;
            t3.Status = 'Completed';
            t3.WhatId = [SELECT Id FROM T_COUNTY_PLAN__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t3);
            
            INSERT tasksToInsert;
            
            Task tsk1 = [SELECT Id, OwnerId FROM Task WHERE Subject = 'Test FA' LIMIT 1];
            System.assertEquals(u.id, tsk1.OwnerId);
            Task tsk2 = [SELECT Id, OwnerId FROM Task WHERE Subject = 'Test Case' LIMIT 1];
            System.assertEquals(u.id, tsk2.OwnerId);
            Test.stopTest();
        }
    }
    
    // Bulk & Single insertion as End User without County Error
    public static testMethod void TaskTrigger_Test3(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'Universal User' LIMIT 1].Id;
        User u = TestClassUtility.createUser(uuId, 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        u.Owner_County__c = '1';
        System.runAs(u){
            Test.startTest();
            T_COUNTY__c countyRec = [SELECT Id FROM T_COUNTY__c WHERE CDE_COUNTY__c = 1 LIMIT 1];
            Task t1 = new Task();
            t1.Subject = 'Test FA';
            t1.OwnerId = u.id;
            t1.Status = 'Completed';
            t1.WhatId = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            INSERT t1;
            
            List<Task> tasksToInsert = new List<Task>();
            
            Task t2 = new Task();
            t2.Subject = 'Test Case';
            t2.OwnerId = u.id;
            t2.Status = 'Completed';
            t2.WhatId = [SELECT Id FROM T_SBSD_CASE__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t2);
            
            Task t3 = new Task();
            t3.Subject = 'Test CP';
            t3.OwnerId = u.id;
            t3.Status = 'Completed';
            t3.WhatId = [SELECT Id FROM T_COUNTY_PLAN__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            tasksToInsert.add(t3);
            
            INSERT tasksToInsert;
            
            Task tsk1 = [SELECT Id, OwnerId FROM Task WHERE Subject = 'Test FA' LIMIT 1];
            System.assertEquals(u.id, tsk1.OwnerId);
            Task tsk2 = [SELECT Id, OwnerId FROM Task WHERE Subject = 'Test Case' LIMIT 1];
            System.assertEquals(u.id, tsk2.OwnerId);
            Test.stopTest();
        }
    }
    
    // Single insertions as End User with County mismatch
    public static testMethod void TaskTrigger_Test4(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'Universal User' LIMIT 1].Id;
        User u = TestClassUtility.createUserWithPS(uuId,'Universal_User_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u){
            Test.startTest();
            T_COUNTY__c countyRec = [SELECT Id FROM T_COUNTY__c WHERE CDE_COUNTY__c = 1 LIMIT 1];
            
            Task t1 = new Task();
            t1.Subject = 'Test FA';
            t1.OwnerId = u.id;
            t1.Status = 'Completed';
            t1.WhatId = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_COUNTY__c = :countyRec.Id].Id;
            Try {
                INSERT t1;
            } Catch(Exception e) {
                System.assertEquals('System.DmlException', e.getTypeName());
            }
            
            Task t2 = new Task();
            t2.Subject = 'Test CRP';
            t2.OwnerId = u.id;
            t2.Status = 'Completed';
            t2.WhatId = [SELECT Id FROM T_COUNTY_RATE__c WHERE IDN_COUNTY__c = :countyRec.Id].Id;
            Try {
                INSERT t2;
            } Catch(Exception e) {
                System.assertEquals('System.DmlException', e.getTypeName());
            }
            
            Task t3 = new Task();
            t3.Subject = 'Test County';
            t3.OwnerId = u.id;
            t3.Status = 'Completed';
            t3.WhatId = countyRec.Id;
            Try {
                INSERT t3;
            } Catch(Exception e) {
                System.assertEquals('System.DmlException', e.getTypeName());
            }
            
            Task t4 = new Task();
            t4.Subject = 'Test Provider';
            t4.OwnerId = u.id;
            t4.Status = 'Completed';
            t4.WhatId = [SELECT Id FROM T_CHATS_PROVR_STATUS__c WHERE TXT_CHATS_RATING__c = 'Level 1'].Id;
            Try {
                INSERT t4;
            } Catch(Exception e) {
                System.assertEquals('System.DmlException', e.getTypeName());
            }
            Test.stopTest();
        }
    }
    
    // Covering 'transferItem' method
    public static testMethod void TaskTrigger_Test5(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u = TestClassUtility.createUserWithPS(uuId,'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        User u2 = TestClassUtility.createUserWithPS(uuId,'System_Administrator_PS', 'test2', 'test2', 'test2@example.com.invalid', 'test2@example.com.'+string.valueof(math.random()*3), 'ttes2');
        User u3 = TestClassUtility.createUserWithPS(uuId,'System_Administrator_PS', 'test3', 'test3', 'test3@example.com.invalid', 'test3@example.com.'+string.valueof(math.random()*3), 'ttes3');
        System.runAs(u){
            Test.startTest();
            T_COUNTY__c countyRec = [SELECT Id FROM T_COUNTY__c WHERE CDE_COUNTY__c = 1 LIMIT 1];
            T_PROVR_FISCAL_AGREMENT__c FARec = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_COUNTY__c = :countyRec.Id];
            Task tsk = TestClassUtility.createTask(true, 'Test Existing Task', 'Test Existing Task', 'New', FARec.Id, u.Id);
            
            LightningServerResponse resp1 = TaskServicesAPXCtrl.transferItem(tsk.Id, u2.Id);
            System.assertEquals('Assignee updated', resp1.successMessage);
            
            try {
                LightningServerResponse resp2 = TaskServicesAPXCtrl.transferItem(tsk.Id, u3.Id);
            } Catch(Exception e) {
                System.assertEquals('System.DmlException', e.getTypeName());
            }
            
            LightningServerResponse resp3 = TaskServicesAPXCtrl.transferItem('000000000000000000', u3.Id);
            System.assert(!resp3.isSuccessful);
            Test.stopTest();
        }
    }
    
    // Covering 'markTaskAsCompleted' and 'reOpenMarkCompletedTask' methods
    public static testMethod void TaskTrigger_Test6(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u = TestClassUtility.createUserWithPs(uuId,'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u){
            Test.startTest();
            T_COUNTY__c countyRec = [SELECT Id FROM T_COUNTY__c WHERE CDE_COUNTY__c = 1 LIMIT 1];
            T_PROVR_FISCAL_AGREMENT__c FARec = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_COUNTY__c = :countyRec.Id];
            Task tsk = TestClassUtility.createTask(true, 'Test Existing Task', 'Test Existing Task', 'New', FARec.Id, u.Id);
            LightningServerResponse resp1 = TaskServicesAPXCtrl.markTaskAsCompleted(tsk.Id);
            System.assertEquals('Task Mark Complete', resp1.successMessage);
            
            LightningServerResponse resp2 = TaskServicesAPXCtrl.reOpenMarkCompletedTask(tsk.Id, 'In Progress');
            System.assertEquals('Task Status Updated', resp2.successMessage);
            Test.stopTest();
        }
    }

    //Covering 'checkT227ForEmailNotification' method
    @isTest
    public static void TaskTrigger_Test7(){
        T_COUNTY__c countyRec = [SELECT Id FROM T_COUNTY__c WHERE CDE_COUNTY__c = 1 LIMIT 1];
        T_ADJMT__c adjRec = [SELECT Id FROM T_ADJMT__c WHERE CDE_COUNTY__c = :countyRec.Id LIMIT 1];
        Task tsk = TestClassUtility.createTask(false, 'T227 – Recovery Overpayment requires refund', 'Test T227 Task', 'New', adjRec.Id, UserInfo.getUserId());
        tsk.ActivityDate = Date.newInstance(2024, 02, 01);
        Test.startTest();
        insert tsk;
        Test.stopTest();
        System.assertEquals('T227 – Recovery Overpayment requires refund',tsk.subject);
    }
}