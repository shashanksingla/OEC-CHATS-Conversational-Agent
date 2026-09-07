@isTest 
public class SchedulableAuthBatchApxTest {
    static testmethod void  testschedule(){
        Test.StartTest();
        SchedulableAuthBatchApx sh1 = new SchedulableAuthBatchApx();     
        String sch = '0  00 1 3 * ?';
        String jobId = system.schedule('Test', sch, sh1);
        //String jobId = System.schedule('ScheduleApexClassTest',CRON_EXP,new SCHEDULEDCLASSTOTEST());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression,'Scheduled time should match');
        System.assertEquals(0, ct.TimesTriggered,'No. of times triggered should be zero');
        Test.stopTest();
        
    }
}