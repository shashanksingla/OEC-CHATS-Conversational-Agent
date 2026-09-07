@isTest
public class BatchInsertCR202Corspd_Test {

    public static testMethod void testCR202CorspdInsert(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_ADJMT__c caseAdj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, null);
        caseAdj.Outstanding_Recovery_Balance__c = 100;
        update caseAdj;
        T_ADJMT__c provAdj = new T_ADJMT__c(
            CDE_COUNTY__c = countyObj.Id, IDN_PROVR__c = providerObj.Id,
            CDE_AGNST_ADJMT__c = '2', CDE_STATUS_ADJMT__c = '1', 
            DTE_END_ADJMT__c = Date.valueOf(Date.newInstance(2018, 01, 15)),
            DTE_START_ADJMT__c = Date.valueOf(Date.newInstance(2018, 01, 01)),
            Outstanding_Recovery_Balance__c = 100
        );
        GenericDMLHandler.insertRecords(new List<Sobject>{provAdj}, null);
        Tax_Intercept__c taxRec1 = new Tax_Intercept__c(
            County__c = countyObj.Id, Name__c = 'firstName lastName', Recovery_Reason__c = '1', SSN__c = '1234567',
            Type__c = 'Case', Case__c = caseObj.Id, Adjustment__c = caseAdj.Id, Classification__c = '1'
        );
        Tax_Intercept__c taxRec2 = new Tax_Intercept__c(
            County__c = countyObj.Id, Name__c = 'test provider name', Recovery_Reason__c = '7',
            Type__c = 'Provider', Provider__c = providerObj.Id, Adjustment__c = provAdj.Id, Classification__c = '2'
        );
        GenericDMLHandler.insertRecords(new List<Sobject>{taxRec1,taxRec2}, null);
        
        Test.startTest();
		String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(uuId, 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            BatchInsertCR202Corspd batch = new BatchInsertCR202Corspd();
            database.executebatch(batch);
        }
        Test.stopTest();

    }
}