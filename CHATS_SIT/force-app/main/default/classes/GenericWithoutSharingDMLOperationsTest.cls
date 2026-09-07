/*
*/
@isTest
public class GenericWithoutSharingDMLOperationsTest {
    public static testMethod void testInsertRecords(){
        T_SBSD_CASE__c caseRecord = new T_SBSD_CASE__c();
        List<SObject> lstObjects = new List<SObject>();
        lstObjects.add(caseRecord);
        GenericWithoutSharingDMLOperations.insertRecords(lstObjects,null);
        List<T_SBSD_CASE__c> listOfCases = [SELECT id FROM T_SBSD_CASE__c];
        System.assertEquals(false, listOfCases.isEmpty(), 'List of cases should not be empty');
    }
    public static testMethod void testDeleteRecords(){
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(new List<Id>{individual.id});
        GenericWithoutSharingDMLOperations.deleteRecords(null);
        List<T_SBSD_CASE__c> listOfCases = [SELECT id FROM T_SBSD_CASE__c];
        System.assertEquals(true, listOfCases.isEmpty(), 'List of cases should be empty');
    }
    
    
}