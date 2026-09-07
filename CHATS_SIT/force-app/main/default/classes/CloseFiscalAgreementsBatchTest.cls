/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           07/10/2018                                                          
*  @description    Test Class for Testing closing Fiscal Agreements.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 10-Jul-2018                                                             
*  * Author: Vineet Srivastava                                                     
*  * Description: Initial version 
*********************************************************************************************/
@isTest
public class CloseFiscalAgreementsBatchTest {

    public static testMethod void testCloseFABatch(){
        T_COUNTY__c countyRecord = TestClassUtility.createCounty('countyName', 'CD', 99, true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        T_PROVR_FISCAL_AGREMENT__c faRecord = TestClassUtility.createFiscaAgreement(false, 'FA-00001', System.today().addDays(-15), countyRecord.Id);
        faRecord.ID_SERVICE__c = provider.Id;
        insert faRecord;
        faRecord.DTE_END_AGRMT__c = system.today().addDays(-1);
        update faRecord;
        Test.startTest();
        Database.executeBatch(new CloseFiscalAgreementsBatch(),200);
        Test.stopTest();
        System.assert([SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c where DTE_END_AGRMT__c < TODAY and CDE_TYPE_STATUS__c!='CLS'].isEmpty(),'Query should return zero rows as all closed');
    }
    
    public static testMethod void testCloseFABatchSchedulable(){
        Test.startTest();
        CLoseFiscalAgreementsBatchSchedulable schObj =  new CLoseFiscalAgreementsBatchSchedulable();
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