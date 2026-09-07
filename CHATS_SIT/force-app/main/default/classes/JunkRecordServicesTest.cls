@isTest
public class JunkRecordServicesTest {
    
    public static testMethod void testJunkRecordDeletionBatch(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        JunkRecordServices.insertJunkRecords(new List<SObject>{countyRec});
        Test.startTest();
        Database.executeBatch(new JunkRecordDeletionBatch());
        Test.stopTest();
        System.assert([SELECT Id FROM Junk_Record__c limit 100].isEmpty(),'Query should return zero rows as they all deleted');
        System.assert([SELECT Id FROM T_COUNTY__c limit 100].isEmpty(),'Query should return county records');
    }
    
    public static testMethod void testInsertJunkRecordsById(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        JunkRecordServices.insertJunkRecords(new List<Id>{countyRec.Id});
        Test.startTest();
        JunkRecordServices.deleteJunkRecordsByRecordIds(new List<Id>{countyRec.Id},false);
        Test.stopTest();
        System.assert([SELECT Id FROM Junk_Record__c limit 100].isEmpty(),'Query should return zero rows as they all deleted');
        System.assert(![SELECT Id FROM T_COUNTY__c limit 100].isEmpty(),'Query should return county records');
    }

    public static testMethod void testInsertJunkRecords(){
    	
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true,countyRec.Id ) ;
        T_SBSD_INDIV__c individualRec = TestClassUtility.createIndividual(true, system.today().addYears(-20), 'firstname', '1', 'lastname', '123', 'CC');
        T_CHATS_PROVR_STATUS__c providerRec = TestClassUtility.createProvider(true, 'Level 1');
        T_AUTH__c authRec = TestClassUtility.createAuthorization(true, system.today().addYears(2), system.today(), countyRec.Id, providerRec.Id);
        T_SBSD_CASE_STATUS_MODE__c caseStatusModeRec = TestClassUtility.createCaseStatusMode(true, caseRec.Id);
        T_SBSD_CASE_INDIV__c caseIndividualRec = TestClassUtility.createCaseIndividual(true, caseRec.Id, individualRec.Id, true);
        JunkRecordServices.insertJunkRecords(new List<SObject>{countyRec,caseRec,individualRec,providerRec,authRec});
        Test.startTest();
        JunkRecordServices.deleteJunkRecordsByRecords(new List<SObject>{countyRec},false);
        JunkRecordServices.deleteJunkRecordsByRecords(new List<SObject>{caseRec,individualRec,providerRec,authRec},true);
        Test.stopTest();
        System.assert([SELECT Id FROM Junk_Record__c limit 100].isEmpty(),'Query should return zero rows as they all deleted');
        System.assert(![SELECT Id FROM T_COUNTY__c limit 100].isEmpty(),'Query should return county records');
        
    }
    
    public static testMethod void testJunkRecordDeletionBatchSchedulable(){
        Test.startTest();
        JunkRecordDeletionBatchSchedulable schObj =  new JunkRecordDeletionBatchSchedulable();
        String sch = '0 0 23 * * ?';
        
        
        String jobId =system.schedule('Test Junk Deletion Batch Check', sch, schObj); 
      // Get the information from the CronTrigger API object 
         CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
       // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression); 
      // Verify the job has not run 
      System.assertEquals(0, ct.TimesTriggered,'Cron trigger should return zero jobs'); 
        
        Test.stopTest();
    }
    public static testMethod void testDeleteJunkChildRecord(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_PROVR_FISCAL_AGREMENT__c provrFA = TestClassUtility.createFiscaAgreement(false, 'name', system.today(), countyRec.Id) ;
        provrFA.ID_SERVICE__c = TestClassUtility.createProvider(true, 'Level 1').Id;
        insert provrFA;
        T_FISCAL_SCH__c rateSchRec = TestClassUtility.createRateSchedule(true, system.today(), system.today().addYears(1),provrFA.Id , '1;13;');
        Test.startTest();
        JunkRecordServices.deleteJunkChildRecord(new List<T_PROVR_FISCAL_AGREMENT__c>{provrFA}, 'T_FISCAL_SCH__c', 'IDN_AGRMT_FISCAL__c'); 
        System.assert([SELECT Id FROM T_FISCAL_SCH__c].isEmpty(),'Query should not return schedule records');
        Test.stopTest();
    }
    
    public static testMethod void testJunkRecordDeletionBatchEmail(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        JunkRecordServices.insertJunkRecords(new List<SObject>{countyRec,countyRec});
        Delete countyRec;
        Test.startTest();
        Database.executeBatch(new JunkRecordDeletionBatch());
        Test.stopTest();
        System.assert([SELECT Id FROM Junk_Record__c].isEmpty(),'Query should return zero rows as they all deleted');
       
    }  
}