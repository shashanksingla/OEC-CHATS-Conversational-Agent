/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           07/29/2020                                                          
*  @description    Test class for T210 Task Creation Batch.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 29-Jul-2020                                                             
*  * Author: Sahil Garg                                                     
*  * Description: Initial version 
*********************************************************************************************/
@isTest
public class T210TaskCreationBatchTest {

    public static testMethod void testT210TaskCreationBatch(){
        Test.startTest();
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_COUNTY__c countyObj2 = TestClassUtility.createCounty('countyName2', 'countyDepartmentName2',12,true);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(false, 'Test');
        providerObj.CDE_STATUS_PROVR__c='Open';
        providerObj.cde_type_provr__c='EFACH';
        insert providerObj;
        
        T_CHATS_PROVR_STATUS__c providerObj2 = TestClassUtility.createProvider(false, 'Test2');
        providerObj2.CDE_STATUS_PROVR__c='Open';
        providerObj2.cde_type_provr__c='EFACH';
        insert providerObj2;
        
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c providerFA1 =  TestClassUtility.createFiscaAgreement(false,'test',System.today(),countyObj.Id);
        providerFA1.ID_SERVICE__c=providerObj.Id;
        providerFA1.RecordtypeId=openRecordTypeId;
        providerFA1.CDE_TYPE_STATUS__c='OPN';
        
        
        insert providerFA1;
        
        T_PROVR_FISCAL_AGREMENT__c providerFA2 =  TestClassUtility.createFiscaAgreement(false,'test',System.today(),countyObj2.Id);
        providerFA2.ID_SERVICE__c=providerObj2.Id;
        providerFA2.RecordtypeId=openRecordTypeId;
        providerFA2.CDE_TYPE_STATUS__c='OPN';
        
        
        insert providerFA2;
        
        T_AUTH__c authObj = TestClassUtility.createAuthorization(true, System.today(), System.today() - 9, countyObj.Id, providerObj.Id);
        T_AUTH__c authObj2 = TestClassUtility.createAuthorization(true, System.today()+10, System.today() + 1, countyObj.Id, providerObj.Id);
         
        Database.executeBatch(new T210TaskCreationBatch());
        Test.stopTest();
        System.assertEquals(1, [Select Subject from Task ].size());
    }
    public static testMethod void testT210TaskCreationBatchSchedulable(){
        Test.startTest();
        T210TaskCreationBatchSchedulable schObj =  new T210TaskCreationBatchSchedulable();
        String sch = '0 0 6 1/1 * ? *';
        String jobId =system.schedule('Test 210 task creation Batch Check', sch, schObj); 
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered,'Cron trigger should return zero jobs'); 
        Test.stopTest();
    }
}