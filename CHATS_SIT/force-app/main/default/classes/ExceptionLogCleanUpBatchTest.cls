/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           07/10/2018                                                          
*  @description    Test Class for Testing cleaning up Exception Log Object.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 10-Jul-2018                                                             
*  * Author: Vineet Srivastava                                                     
*  * Description: Initial version 
*********************************************************************************************/
@isTest
public class ExceptionLogCleanUpBatchTest {
    public static testMethod void testJunkRecordDeletionBatch(){
        Exception_Log__c exceptionLog = new Exception_Log__c();
        exceptionLog.Class__c = 'ExceptionLogCleanUpBatchTest';
        exceptionLog.Method__c='testJunkRecordDeletionBatch';
        insert exceptionLog;
        Test.startTest();
        Database.executeBatch(new ExceptionLogCleanUpBatch(),200);
        Test.stopTest();
        System.assert([SELECT Id FROM Exception_Log__c where CreatedDate < LAST_N_DAYS : 89].isEmpty(),'Query should return zero rows as they all deleted');
    }
    public static testMethod void testExceptionLogCleanUpBatchSchedulable(){
        Test.startTest();
        ExceptionLogCleanUpBatchSchedulable schObj =  new ExceptionLogCleanUpBatchSchedulable();
        String sch = '0 0 23 * * ?';
        String jobId =system.schedule('Test Exception Log Clean Up Batch Check', sch, schObj); 
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered,'Cron trigger should return zero jobs'); 
        Test.stopTest();
    }
}