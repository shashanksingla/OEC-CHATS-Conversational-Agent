/*************************************************************
Class Name	    - TaxInterceptApexController_Test
Covering Class	- TaxInterceptApexController, TaxInterceptSearchWrapper
Author          - Rishav Maji
**************************************************************/
@isTest
public class TaxInterceptApexController_Test {
    
    @testSetup
    public static void doSetup(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_COUNTY__c allCountyRec = TestClassUtility.createCounty('All County(State)', 'All County(State)', 66, true);
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
    
    public static testMethod void searchTaxIntercepts_Test1(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'Universal User' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(uuId, 'test', 'test', 'test@example.com', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        String searchWrapperString = '{"recoveryReason":["1"],"selectedCounty":["1"],"taxRecord":{"sobjectType":"Tax_Intercept__c","Type__c":"Case","Classification__c":"1","Name__c":"firstName","SSN__c":"1234567",';
        searchWrapperString = searchWrapperString + '"Case__c":"' + [SELECT Id FROM T_SBSD_CASE__c LIMIT 1].Id;
        searchWrapperString = searchWrapperString + '","Tax_Year__c":"' + System.Today().year();
        searchWrapperString = searchWrapperString + '","Adjustment__c":"' + [SELECT Id FROM T_ADJMT__c WHERE CDE_STATUS_ADJMT__c = '1' LIMIT 1].Id;
        searchWrapperString = searchWrapperString + '"}}';
        System.runAs(u1){
            Test.startTest();
            LightningServerResponse res = TaxInterceptApexController.searchTaxIntercepts(searchWrapperString);
            Test.stopTest();
            System.assertEquals(true, res.isSuccessful);
        }
    }
    
    public static testMethod void searchTaxIntercepts_Test2(){
        String rou = [SELECT Id, Name FROM Profile WHERE Name = 'Read Only User' LIMIT 1].Id;
        User u2 = TestClassUtility.createUser(rou, 'test2', 'test2', 'test2@example.com', 'test2@example.com.'+string.valueof(math.random()*3), 'ttes2');
        String searchWrapperString = '{"selectedCounty":["1"],"taxRecord":{"sobjectType":"Tax_Intercept__c","Type__c":"Provider","Classification__c":"2","Name__c":"test provider name",';
        searchWrapperString = searchWrapperString + '"Provider__c":"' + [SELECT Id FROM T_CHATS_PROVR_STATUS__c LIMIT 1].Id;
        searchWrapperString = searchWrapperString + '","Tax_Year__c":"' + System.Today().year();
        searchWrapperString = searchWrapperString + '","Adjustment__c":"' + [SELECT Id FROM T_ADJMT__c WHERE CDE_STATUS_ADJMT__c = '1' LIMIT 1].Id;
        searchWrapperString = searchWrapperString + '"}}';
        System.runAs(u2){
            Test.startTest();
            LightningServerResponse res = TaxInterceptApexController.searchTaxIntercepts(searchWrapperString);
            Test.stopTest();
            System.assertEquals(true, res.isSuccessful);
        }
    }
    
    public static testMethod void searchTaxIntercepts_TestEx(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'Universal User' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(uuId, 'test', 'test', 'test@example.com', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        String searchWrapperString = null;
        System.runAs(u1){
            Test.startTest();
            try {
                LightningServerResponse res = TaxInterceptApexController.searchTaxIntercepts(searchWrapperString);
            } catch (NullPointerException ex) {
                System.assertEquals('null input to JSON parser', ex.getMessage());
            }
            Test.stopTest();
        }
    }
    
    public static testMethod void saveRecord_Test(){
        Tax_Intercept__c taxRecord = [SELECT Id FROM Tax_Intercept__c WHERE Name__c = 'firstName lastName' LIMIT 1];
        Test.startTest();
        LightningServerResponse res1 = TaxInterceptApexController.saveRecord(taxRecord.Id, null, '1');
        LightningServerResponse res2 = TaxInterceptApexController.saveRecord(taxRecord.Id, '1', null);
        Test.stopTest();
        System.assertEquals(true, res1.isSuccessful);
        System.assertEquals(true, res2.isSuccessful);
    }
    
    public static testMethod void saveRecord_TestEx(){
        Test.startTest();
        try {
            LightningServerResponse res = TaxInterceptApexController.saveRecord(null, null, '1');
        } catch (DmlException ex) {
            System.assertEquals('Update failed. First exception on row 0; first error: MISSING_ARGUMENT, Id not specified in an update call: []', ex.getMessage());
        }
        Test.stopTest();
    }
    
    public static testMethod void TaxInterceptSearchWrapper_Test(){
        Tax_Intercept__c taxRecord = [SELECT Id, Name__c, SSN__c FROM Tax_Intercept__c WHERE Name__c = 'firstName lastName' LIMIT 1];
        List<String> selectedCounty = new List<String>{'1','66'};
        List<String> recoveryReason = new List<String>{'1'};
        Test.startTest();
        TaxInterceptSearchWrapper searchWrapper = new TaxInterceptSearchWrapper(taxRecord, selectedCounty, recoveryReason);
        Test.stopTest();
        System.assertEquals('1234567', searchWrapper.taxRecord.SSN__c);
    }
    
}