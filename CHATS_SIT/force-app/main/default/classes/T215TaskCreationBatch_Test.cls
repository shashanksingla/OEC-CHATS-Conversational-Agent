/*************************************************************
Class Name	    - T215TaskCreationBatch_Test
Covering Class	- T215TaskCreationBatch
Author          - Rishav Maji
**************************************************************/
@isTest
public class T215TaskCreationBatch_Test {
    
    @testSetup
    public static void doSetup(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(true, 'Level 1');
        T_ADJMT__c caseAdj = TestClassUtility.createAdjustment(true, countyRec.Id, caseRec.Id, null);
        T_ADJMT__c provAdj = new T_ADJMT__c(
            CDE_COUNTY__c = countyRec.Id, IDN_PROVR__c = provRec.Id,
            CDE_AGNST_ADJMT__c = '2', CDE_STATUS_ADJMT__c = '1', 
            DTE_END_ADJMT__c = Date.valueOf(Date.newInstance(2018, 01, 15)),
            DTE_START_ADJMT__c = Date.valueOf(Date.newInstance(2018, 01, 01))
        );
        GenericDMLHandler.insertRecords(new List<Sobject>{provAdj}, null);
        Tax_Intercept__c taxRec1 = new Tax_Intercept__c(
            County__c = countyRec.Id, Name__c = 'firstName lastName', Recovery_Reason__c = '1', SSN__c = '1234567',
            Type__c = 'Case', Case__c = caseRec.Id, Adjustment__c = caseAdj.Id, Classification__c = '1'
        );
        Tax_Intercept__c taxRec2 = new Tax_Intercept__c(
            County__c = countyRec.Id, Name__c = 'test provider name', Recovery_Reason__c = '7',
            Type__c = 'Provider', Provider__c = provRec.Id, Adjustment__c = provAdj.Id, Classification__c = '2'
        );
        GenericDMLHandler.insertRecords(new List<Sobject>{taxRec1, taxRec2}, null);
    }
    
    public static testMethod void T215TaskCreationBatch_Test1(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            Test.startTest();
            T215TaskCreationBatch t215b = new T215TaskCreationBatch();
            database.executebatch(t215b);
            Test.stopTest();
        }
    }
    
    public static testMethod void T215TaskCreationBatch_Test2(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            Test.startTest();
            T215TaskCreationBatch t215b = new T215TaskCreationBatch();
            database.executebatch(t215b);
            Test.stopTest();
            Exception_Log__c xLog = [SELECT Id, Exception_Message__c FROM Exception_Log__c WHERE Class__c = 'T215TaskCreationBatch' LIMIT 1];
            System.assertEquals('Attempt to de-reference a null object', xLog.Exception_Message__c);
        }
    }

}