@isTest
public class DeletedRecordArchivalBatch_Test {
    public static testMethod void testArchiveDeletedRecords(){
        Record_Archival_Setup__c setup = new Record_Archival_Setup__c(Archival_Object__c='T_COUNTY__c', Is_Active__c=true);
        insert setup;
        T_COUNTY__c county = TestClassUtility.createCounty('countyName', 'countyDepartmentName', 01, true);
        delete county;
        Test.startTest();
        DeletedRecordArchivalBatch batch = new DeletedRecordArchivalBatch();
        database.executeBatch(batch,1);
        Test.stopTest();
        System.assert(![SELECT Id FROM Archived_Record__c].isEmpty(),'Query should not return zero rows as they all deleted');
        System.assert([SELECT Id FROM T_COUNTY__c].isEmpty(),'Query should not return county records');
    }
    public static testMethod void testDeleteArchiveRecords(){
        Archived_Record__c record = new Archived_Record__c();
        insert record;
        Test.startTest();
        DeleteArchivedRecordsBatch batch = new DeleteArchivedRecordsBatch();
        database.executeBatch(batch,200);
        Test.stopTest();
        System.assert([SELECT Id FROM Archived_Record__c].isEmpty(),'Query should return zero rows as they all deleted');
        
    }
    public static testMethod void testDeletedRecordArchivalBatchSchedulable(){
        Test.startTest();
        DeletedRecordArchivalBatchSchedulable schObj =  new DeletedRecordArchivalBatchSchedulable();
        String sch = '0 0 23 * * ?';
        String jobId =system.schedule('Test Deleted Record Archive Batch Check', sch, schObj); 
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered,'Cron trigger should return zero jobs'); 
        
        Test.stopTest();
    }
    public static testMethod void testDeleteArchivedRecordBatchSchedulable(){
        Test.startTest();
        DeleteArchivedRecordsBatchSchedulable schObj =  new DeleteArchivedRecordsBatchSchedulable();
        String sch = '0 0 22 * * ?';
        String jobId =system.schedule('Test Delete Archived Record Batch Check', sch, schObj); 
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered,'Cron trigger should return zero jobs'); 
        
        Test.stopTest();
    }
    
}