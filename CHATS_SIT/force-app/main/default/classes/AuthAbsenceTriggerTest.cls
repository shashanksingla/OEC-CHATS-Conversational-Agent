@isTest
public class AuthAbsenceTriggerTest {
    
    public static testMethod void testAuthAbsenceTrigger() {
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj =TestClassUtility.createCase(true,countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_AUTH__c authObj = TestClassUtility.createAuthorization(true,System.today() + 9, System.today(), countyObj.Id, providerObj.Id); 
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstNameA','1','lastNameA','123','CC');
        test.startTest();
        T_AUTH_ABSENCE__c authAbsenceObj = new T_AUTH_ABSENCE__c ( IDN_AUTH__c = authObj.Id, IDN_CASE__c = caseObj.Id, IDN_CLIENT__c = individual.Id, IDN_EXTNL__c = NULL);
        insert authAbsenceObj;
        test.stopTest();
        T_AUTH_ABSENCE__c fetchAuthAbsenceRecord = [select Id, IDN_EXTNL__c From T_AUTH_ABSENCE__C where Id =: authAbsenceObj.Id]; 
        System.assert(fetchAuthAbsenceRecord.IDN_EXTNL__c!=null && fetchAuthAbsenceRecord.IDN_EXTNL__c == authAbsenceObj.Id,'Salesforce ID was successfully stamped to external ID');
        
    }
}