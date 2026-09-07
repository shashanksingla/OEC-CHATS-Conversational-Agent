/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           08/26/2020                                                          
*  @description    Test Class for Testing Opening Fiscal Agreements.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 08/26/2020                                                          
*  * Author: Balamurugan Chinnaiah
*  * Description: Initial version 
*********************************************************************************************/
@isTest
public class OpenFiscalAgreementsBatchTest {

    public static testMethod void testOpenFABatch(){
        T_COUNTY__c countyRecord = TestClassUtility.createCounty('countyName', 'CD', 99, true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        Date dt = System.today();
		Id FINALIZED_RECORD_TYPE_ID = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c faRecord = TestClassUtility.createFiscaAgreement(false, 'FA-00001', dt, countyRecord.Id);
        faRecord.CDE_TYPE_STATUS__c = 'FIN';
        faRecord.ID_SERVICE__c = provider.Id;
        faRecord.RecordTypeId = FINALIZED_RECORD_TYPE_ID;
        insert faRecord;
        System.debug('FARecord:'+faRecord);
        Test.startTest();
        Database.executeBatch(new OpenFiscalAgreementsBatch(),200);
        Test.stopTest();
        System.debug('FARecord:'+faRecord);
        System.assert([SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c where DTE_BEGIN_AGRMT__c = TODAY and CDE_TYPE_STATUS__c!='OPN'].isEmpty(),'Query should return zero rows as all opened');
    }
    
    public static testMethod void testOpenFABatchSchedulable(){
        Test.startTest();
        OpenFiscalAgreementsBatchSchedulable schObj =  new OpenFiscalAgreementsBatchSchedulable();
        String sch = '0 0 6 1/1 * ? *';
        String jobId =system.schedule('Test Open Fiscal Agreement Batch Schedule', sch, schObj);
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered,'Cron trigger should return zero jobs'); 
        Test.stopTest();
    }
}