/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class adjustmentTriggerTest {
    
    public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyObj;
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        
        Test.startTest();
        T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, providerObj.Id);
        T_ADJMT__c admntAfterInsert = [select Id,IDN_EXTNL__c from T_ADJMT__c where Id=:adjObj.Id];
        Test.stopTest();
        System.assert(admntAfterInsert.IDN_EXTNL__c!=null && admntAfterInsert.IDN_EXTNL__c == adjObj.Id, 'Salesforce ID is not successfully stamped to external ID');
    }
    
    @isTest
    static void testTriggerCorspdCR206() {
        T_COUNTY__c countyObj = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyObj;
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        
        Id inProcessRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('In Process').getRecordTypeId();
        Id finalizedRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        Id newRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        
        T_ADJMT__c adjObj1 = new T_ADJMT__c(CDE_COUNTY__c = countyObj.Id, IDN_CASE__c = caseObj.Id, CDE_STATUS_ADJMT__c = '1', RecordTypeId = inProcessRecordTypeId);
        T_ADJMT__c adjObj2 = new T_ADJMT__c(CDE_COUNTY__c = countyObj.Id, IDN_PROVR__c = providerObj.Id, CDE_STATUS_ADJMT__c = '1', RecordTypeId = inProcessRecordTypeId);
        T_ADJMT__c adjObj3 = new T_ADJMT__c(CDE_COUNTY__c = countyObj.Id, IDN_PROVR__c = providerObj.Id, CDE_STATUS_ADJMT__c = '1', RecordTypeId = newRecordTypeId);
        insert new list<T_ADJMT__c>{adjObj1,adjObj2,adjObj3};
        
        T_ADJMT_ADDR__c adjAdd1 = new T_ADJMT_ADDR__c(IDN_ADJMT__c = adjObj1.Id);
        Insert adjAdd1;
        
        adjObj1.CDE_TYPE_ADJMT__c = '2';
        adjObj1.CDE_STATUS_ADJMT__c = '2';
        adjObj1.RecordTypeId = finalizedRecordTypeId;
        adjObj1.DTE_DISCV_ADJMT_ORIG__c = System.today();
        
        adjObj2.CDE_TYPE_ADJMT__c = '2';
        adjObj2.CDE_STATUS_ADJMT__c = '3';
        adjObj2.RecordTypeId = finalizedRecordTypeId;
        adjObj2.DTE_DISCV_ADJMT_ORIG__c = System.today();
        update New List<T_ADJMT__c>{adjObj1,adjObj2};
        
        adjObj1.CDE_STATUS_ADJMT__c = '3';
        
        adjObj2.CDE_TYPE_ADJMT__c = '1';
        adjObj2.CDE_STATUS_ADJMT__c = '2';
        adjObj2.RecordTypeId = finalizedRecordTypeId;
        
        update New List<T_ADJMT__c>{adjObj1,adjObj2};
        
        List<T_ADJMT_DETAIL__c> adjustDetailList = new List<T_ADJMT_DETAIL__c>();
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=100,IDN_ADJMT__c=adjObj3.Id));
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=200,IDN_ADJMT__c=adjObj3.Id));
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=300,IDN_ADJMT__c=adjObj3.Id));
        insert adjustDetailList;
        
        List<T_ADJMT_DETAIL__c> adjtDetList = [Select Id from T_ADJMT_DETAIL__c where IDN_ADJMT__c=:adjObj3.Id];
        system.assertEquals(3,adjtDetList.size(),'Query Should return Adjustment Detail records');
        T_ADJMT__c adjmtDelete = [select Id, CDE_STATUS_ADJMT__c, CDE_TYPE_ADJMT__c FROM T_ADJMT__c WHERE Id =:adjObj3.Id];
        delete adjmtDelete;
        
        List<T_ADJMT_DETAIL__c> adjtDetList2 = [Select Id from T_ADJMT_DETAIL__c where IDN_ADJMT__c=:adjObj3.Id];
        system.assertEquals(0,adjtDetList2.size(),'Query should return zero Adjustment Detail records');
    }
    
    @isTest
    static void testForceCorspdCR206_CR209_TaxIntercept() {
        Test.startTest();
        T_COUNTY__c countyObj = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyObj;
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        
        Id inProcessRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('In Process').getRecordTypeId();
        Id finalizedRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        Id newRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        
        List<T_ADJMT__c> adjToInsert = new List<T_ADJMT__c>();
        T_ADJMT__c adjObj1 = new T_ADJMT__c(CDE_COUNTY__c = countyObj.Id, IDN_CASE__c = caseObj.Id, CDE_STATUS_ADJMT__c = '1', RecordTypeId = inProcessRecordTypeId);
        adjToInsert.add(adjObj1);
        T_ADJMT__c adjObj2 = new T_ADJMT__c(CDE_COUNTY__c = countyObj.Id, IDN_PROVR__c = providerObj.Id, CDE_STATUS_ADJMT__c = '1', RecordTypeId = inProcessRecordTypeId);
        adjToInsert.add(adjObj2);
        insert adjToInsert;
        
        List<T_ADJMT_ADDR__c> adjAddToInsert = new List<T_ADJMT_ADDR__c>();
        T_ADJMT_ADDR__c adjAdd1 = new T_ADJMT_ADDR__c(IDN_ADJMT__c = adjObj1.Id);
        adjAddToInsert.add(adjAdd1);
        T_ADJMT_ADDR__c adjAdd2 = new T_ADJMT_ADDR__c(IDN_ADJMT__c = adjObj2.Id);
        adjAddToInsert.add(adjAdd2);
        T_ADJMT_ADDR__c adjAdd3 = new T_ADJMT_ADDR__c(IDN_ADJMT__c = adjObj1.Id);
        adjAddToInsert.add(adjAdd3);
        Insert adjAddToInsert;
        
        Tax_Intercept__c ti = new Tax_Intercept__c(Adjustment__c = adjObj1.Id);
        Insert ti;
        
        List<T_ADJMT__c> adjToUpdate1 = new List<T_ADJMT__c>();
        adjObj1.CDE_TYPE_ADJMT__c = '2';
        adjObj1.CDE_STATUS_ADJMT__c = '2';
        adjObj1.RecordTypeId = finalizedRecordTypeId;
        adjObj1.DTE_DISCV_ADJMT_ORIG__c = System.today();
        adjToUpdate1.add(adjObj1);
        adjObj2.CDE_TYPE_ADJMT__c = '2';
        adjObj2.CDE_STATUS_ADJMT__c = '2';
        adjObj2.RecordTypeId = finalizedRecordTypeId;
        adjObj2.DTE_DISCV_ADJMT_ORIG__c = System.today();
        adjToUpdate1.add(adjObj2);
        Update adjToUpdate1;
        
        List<T_ADJMT__c> adjToUpdate2 = new List<T_ADJMT__c>();
        adjObj1.CHK_CR206ForceTrigger__c = true;
        adjToUpdate2.add(adjObj1);
        adjObj2.CHK_CR206ForceTrigger__c = true;
        adjToUpdate2.add(adjObj2);
        Update adjToUpdate2;
        
        T_ADJMT_CANCEL__c adjCancel = new T_ADJMT_CANCEL__c();
        adjCancel.CDE_STATUS__c = '3';
        adjCancel.CDE_RSN_CANCELLATION__c = '1';
        adjCancel.IDN_ADJMT__c = adjObj1.Id;
        Insert adjCancel;
        
        T_ADJMT__c adjObj3 = [SELECT Id, CDE_STATUS_ADJMT__c, DTE_CANCEL_ADJMT__c FROM T_ADJMT__c WHERE Id = :adjObj1.Id];
        adjObj3.CDE_STATUS_ADJMT__c = '6';
        adjObj3.DTE_CANCEL_ADJMT__c = System.today().addDays(-1);
        Update adjObj3;
        Test.stopTest();
    }
    
    static testMethod void providerStatusCheckTest() {
        String newRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        T_COUNTY__c countyObj = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyObj;
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(false, 'Test');
        providerObj.CDE_STATUS_PROVR__c = 'Open';
        Insert providerObj;
        T_CHATS_PROVR_STATUS__history provHistory1 = new T_CHATS_PROVR_STATUS__history(ParentId = providerObj.Id, Field = 'CDE_STATUS_PROVR__c');
        insert provHistory1;
        T_CHATS_PROVR_STATUS__history provHistory2 = new T_CHATS_PROVR_STATUS__history(ParentId = providerObj.Id, Field = 'CDE_STATUS_PROVR__c');
        insert provHistory2;
        
        T_ADJMT__c adj1 = new T_ADJMT__c(IDN_PROVR__c = providerObj.Id, CDE_COUNTY__c = countyObj.Id, 
                                         CDE_STATUS_ADJMT__c = '1', CDE_TYPE_ADJMT__c = '1', RecordTypeId = newRecordTypeId,
                                         DTE_START_ADJMT__c = System.today(), DTE_END_ADJMT__c = System.today());
        insert adj1;
    }
    
    static testMethod void providerStatusCheckTest2() {
        String newRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        T_COUNTY__c countyObj = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyObj;
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(false, 'Test');
        providerObj.CDE_STATUS_PROVR__c = 'Open';
        Insert providerObj;
        T_CHATS_PROVR_STATUS__history provHistory1 = new T_CHATS_PROVR_STATUS__history(ParentId = providerObj.Id, Field = 'CDE_STATUS_PROVR__c');
        Insert provHistory1;
        T_CHATS_PROVR_STATUS__history provHistory2 = new T_CHATS_PROVR_STATUS__history(ParentId = providerObj.Id, Field = 'CDE_STATUS_PROVR__c');
        Insert provHistory2;
        
        T_ADJMT__c adj1 = new T_ADJMT__c(IDN_PROVR__c = providerObj.Id, CDE_COUNTY__c = countyObj.Id, 
                                         CDE_STATUS_ADJMT__c = '1', CDE_TYPE_ADJMT__c = '1', RecordTypeId = newRecordTypeId,
                                         DTE_START_ADJMT__c = System.today(), DTE_END_ADJMT__c = System.today());
        Insert adj1;
    }
    
    public static testMethod void exceptionTestMethod(){
        Profile userProfile=[Select id from Profile where Name ='Read Only User'];
        User user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        String newRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        T_COUNTY__c countyObj = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyObj;
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(false, 'Test');
        providerObj.CDE_STATUS_PROVR__c = 'Open';
        Insert providerObj;
        
        T_ADJMT__c adj1 = new T_ADJMT__c(IDN_PROVR__c = providerObj.Id, CDE_COUNTY__c = countyObj.Id, 
                                         CDE_STATUS_ADJMT__c = '1', CDE_AGNST_ADJMT__c = '2', RecordTypeId = newRecordTypeId,
                                         DTE_START_ADJMT__c = System.today(), DTE_END_ADJMT__c = System.today());
        List<T_ADJMT__c> adjList = new List<T_ADJMT__c>();
        adjList.add(adj1);
        Insert adjList;
        T_ADJMT_CMT__c adjComment = new T_ADJMT_CMT__c(IDN_ADJMT__c = adj1.Id);
        Insert adjComment;
        
        System.runAs(user){
            try {
                adjustmentServices.deleteAllChildAdjustmentRecords(adjList);
            } catch (Exception e) {
                return;
            }
        }
    }
    
}