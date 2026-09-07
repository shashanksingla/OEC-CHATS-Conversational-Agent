/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           07/29/2020                                                          
*  @description    Test Class for T211 Task Creation Batch.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 29-Jul-2020                                                             
*  * Author: Sahil Garg                                                     
*  * Description: Initial version 
*********************************************************************************************/
@isTest
public class T211TaskCreationBatchTest {
    
    public static testMethod void testT211TaskCreationBatch(){
        
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_COUNTY__c countyObj2 = TestClassUtility.createCounty('countyName2', 'countyDepartmentName2',12,true);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(false, 'Test');
        providerObj.CDE_STATUS_PROVR__c='Open';
        providerObj.cde_type_provr__c='EFACH';
        insert providerObj;
        
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c providerFA1 =  TestClassUtility.createFiscaAgreement(false,'test',System.today(),countyObj.Id);
        providerFA1.ID_SERVICE__c=providerObj.Id;
        providerFA1.RecordtypeId=openRecordTypeId;
        providerFA1.CDE_TYPE_STATUS__c='OPN';
        
        
        insert providerFA1;
        providerFA1=[select Id,Name,OwnerId from T_PROVR_FISCAL_AGREMENT__c where id=:providerFA1.Id];
        
        T_PROVR_FISCAL_AGREMENT__c providerFA2 =  TestClassUtility.createFiscaAgreement(false,'test',System.today(),countyObj2.Id);
        providerFA2.ID_SERVICE__c=providerObj.Id;
        providerFA2.RecordtypeId=openRecordTypeId;
        providerFA2.CDE_TYPE_STATUS__c='OPN';
        
        
        insert providerFA2;
        
        
        Task tsk= new Task();
        tsk.Subject = 'T210 - Fiscal Agreement without an open authorization for more than 90 days';
        tsk.WhatId = providerFA1.Id;
        tsk.OwnerId = providerFA1.OwnerId;
        tsk.Status = 'New';
        tsk.Priority = 'Normal';
        tsk.ActivityDate= System.today().addDays(10);
        insert tsk;
        
        Test.startTest();
        Database.executeBatch(new T211TaskCreationBatch());
        Test.stopTest();
        System.assertEquals(1, [Select Subject from Task where Subject='T211 - Fiscal Agreement without an open authorization for more than 90 days'].size());
        
    }
     public static testMethod void testT211TaskCreationBatchSchedulable(){
        Test.startTest();
        T211TaskCreationBatchSchedulable schObj =  new T211TaskCreationBatchSchedulable();
        String sch = '0 0 6 1/1 * ? *';
        String jobId =system.schedule('Test 211 task creation Batch Check', sch, schObj); 
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered,'Cron trigger should return zero jobs'); 
        Test.stopTest();
    }
}