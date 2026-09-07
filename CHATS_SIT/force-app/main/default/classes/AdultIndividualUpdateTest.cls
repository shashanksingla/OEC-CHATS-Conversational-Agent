//Commenting out as the batch is no longer in use
//@isTest
public class AdultIndividualUpdateTest {
    /*@TestSetup
    static void setup() {
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c testCase = TestClassUtility.createCase(true, countyObj.Id);
        T_SBSD_INDIV__c adultIndiv = TestClassUtility.createIndividual(true, Date.today().addYears(-30), 'AdultFirst', '1', 'AdultLast', '123456789', 'CC');
        T_SBSD_INDIV__c indiv2 = new T_SBSD_INDIV__c( NAM_FIRST__c = 'John', NAM_LAST__c = 'Smith', DTE_DOB__c = date.today().addYears(-25),
                                                       IND_CDE_TYPE_VERIF_DOB__c = 'V', NBR_SSN__c = '123456789', CDE_GENDER__c = '1',
                                                       CDE_ETNCTY__c = 'N', CDE_SOURCE_VRFYD_DOB__c = 'TF', CDE_SOURCE_VRFYD_IDNTY__c = 'CC',
                                                       IND_CHILD_IDEA__c = 'N', IND_CHILD_SCREEN__c = 'N', IND_NOTIFY_SIDMOD__c = 'Y', CDE_ATTENDING_SCHOOL1__c = 'N');
        insert indiv2;
        T_SBSD_CASE_INDIV__c caseIndivPC = TestClassUtility.createCaseIndividual(true, testCase.Id, adultIndiv.Id, true);
        T_SBSD_CASE_INDIV__c caseIndivPC2 = TestClassUtility.createCaseIndividual(true, testCase.Id, indiv2.Id, true);
        T_SBSD_INDIV_INFO__c indivInfo = new T_SBSD_INDIV_INFO__c(IDN_CLIENT__c = adultIndiv.Id, CDE_TYPE_INFO_INDIV__c = 'CS', CDE_VALUE_INFO_INDIV__c = 'CZN', IDN_CASE__c=testCase.Id);
        insert indivInfo;
        T_INDIV_VERIF__c indivVerif = new T_INDIV_VERIF__c(IDN_CLIENT__c = indivInfo.Id, CDE_TYPE_INFO_INDIV__c = 'CS');
        insert indivVerif;
        T_SBSD_INDIV__c childIndiv = TestClassUtility.createIndividual(true, Date.today().addYears(-5), 'ChildFirst', '1', 'ChildLast', '987654321', 'CC');
        T_SBSD_CASE_INDIV__c caseIndivChild = new T_SBSD_CASE_INDIV__c(IDN_CASE__c = testCase.Id, IDN_CLIENT__c = childIndiv.Id, IND_CRTKR__c = false, Individual_Status__c = 'Child', DTE_BEGIN_EFFV__c = System.today());
        insert caseIndivChild;
    }
    @isTest
    static void testBatchExecution() {
        T_SBSD_INDIV__c adultIndiv = [SELECT Id, CDE_GENDER__c, CDE_ATTENDING_SCHOOL1__c, IND_CHILD_IDEA__c, IND_CHILD_SCREEN__c, CDE_RACE__c, CDE_ETNCTY__c, IND_CDE_TYPE_VERIF_DOB__c FROM T_SBSD_INDIV__c WHERE NAM_FIRST__c = 'AdultFirst' LIMIT 1];
        Test.startTest();
        AdultIndividualUpdate batchJob = new AdultIndividualUpdate();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();
        T_SBSD_INDIV__c updatedIndiv = [SELECT Id, CDE_GENDER__c, CDE_ATTENDING_SCHOOL1__c, IND_CHILD_IDEA__c, IND_CHILD_SCREEN__c, CDE_RACE__c, CDE_ETNCTY__c, IND_CDE_TYPE_VERIF_DOB__c, Bypass_On__c FROM T_SBSD_INDIV__c WHERE Id = :adultIndiv.Id];
        System.assertEquals('3', updatedIndiv.CDE_GENDER__c, 'Gender should be updated to 3');
        System.assertEquals('Unknown', updatedIndiv.CDE_ATTENDING_SCHOOL1__c, 'Attending school should be Unknown');
        System.assertEquals('N', updatedIndiv.IND_CHILD_IDEA__c, 'Child IDEA should be N');
        System.assertEquals('N', updatedIndiv.IND_CHILD_SCREEN__c, 'Child Screen should be N');
        System.assertEquals('6', updatedIndiv.CDE_RACE__c, 'Race should be 6');
        System.assertEquals('U', updatedIndiv.CDE_ETNCTY__c, 'Ethnicity should be U');
        System.assertEquals('N/A-adult caretaker', updatedIndiv.IND_CDE_TYPE_VERIF_DOB__c, 'DOB verification type should be N/A-adult caretaker');
        System.assertNotEquals(null, updatedIndiv.Bypass_On__c, 'Bypass_On__c should be set');
        T_SBSD_INDIV_INFO__c updatedInfo = [SELECT Id, CDE_VALUE_INFO_INDIV__c FROM T_SBSD_INDIV_INFO__c WHERE IDN_CLIENT__c = :adultIndiv.Id AND CDE_TYPE_INFO_INDIV__c = 'CS' LIMIT 1];
        System.assertEquals('N/A-adult caretaker', updatedInfo.CDE_VALUE_INFO_INDIV__c, 'Individual info value should be updated to N/A-adult caretaker');
        List<T_INDIV_VERIF__c> remainingVerif = [SELECT Id FROM T_INDIV_VERIF__c WHERE IDN_CLIENT__c = :updatedInfo.Id];
        System.assertEquals(0, remainingVerif.size(), 'Verification records should be deleted');
    }*/
}