/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           08 Sept 2020                                                          
*  @description    Test Class for testing AuthAbsenceHoursFromATS Class.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 08-Sept-2020                                                             
*  * Author: Azharuddin Mohammad                                                     
*  * Description: Initial version 
*********************************************************************************************/
@isTest
public class AuthAbsenceHoursFromATSTest {

    public static testMethod void testAuthAbsenceHoursFromATS(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_AUTH__c authObj = TestClassUtility.createAuthorization(true,System.today() + 9, System.today(), countyObj.Id, providerObj.Id); 
        Test.startTest();
        Database.executeBatch(new AuthAbsenceHoursFromATS(),200);
        Test.stopTest();
        //System.assert([SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c where DTE_END_AGRMT__c < TODAY and CDE_TYPE_STATUS__c!='CLS'].isEmpty(),'Query should return zero rows as all closed');
    }
    
    public static testMethod void testAuthAbsenceHoursFromATSBatchSchedulable(){
        Test.startTest();
        AuthAbsenceHoursFromATSBatchSchedulable schObj =  new AuthAbsenceHoursFromATSBatchSchedulable();
        String sch = '0 0 6 1/1 * ? *';
        String jobId =system.schedule('Test Exception Log Clean Up Batch Check', sch, schObj); 
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered,'Cron trigger should return zero jobs'); 
        Test.stopTest();
    }
}