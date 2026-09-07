@isTest
public class ApplicationIndividualServicesTest {
    public static testMethod void testDoFillSoundexValue(){
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c();
        insert appCase;
        String appCaseId = appCase.Id;
        
        T_APPLN_INDIV__c individual = TestClassUtility.createApplicationIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123',appCaseId);
        List<T_APPLN_INDIV__c> testIndividuals = [SELECT TXT_SNDX__c FROM T_APPLN_INDIV__c limit 100];
        System.assertEquals(false, testIndividuals.isEmpty(), 'testIndividuals should not be empty');
        System.assertEquals(true, String.isNotEmpty(testIndividuals.get(0).TXT_SNDX__c), 'Soundex text should not be empty');
        individual.NAM_FIRST__c = 'Somerandomstring'; 
        update individual;
        List<T_APPLN_INDIV__c> testIndividualsAfterUpdate = [SELECT TXT_SNDX__c FROM T_APPLN_INDIV__c limit 100];
        System.assertEquals(false, testIndividualsAfterUpdate.isEmpty(), 'testIndividualsAfterUpdate should not be empty');
        System.assertEquals(true, String.isNotEmpty(testIndividualsAfterUpdate.get(0).TXT_SNDX__c), 'Soundex text should not be empty');

        individual.NAM_LAST__c = 'SomerandomstringB';
        update individual;
        List<T_APPLN_INDIV__c> testIndividualsAfterAnotherUpdate = [SELECT TXT_SNDX__c FROM T_APPLN_INDIV__c limit 100];
        System.assertEquals(false, testIndividualsAfterAnotherUpdate.isEmpty(), 'testIndividualsAfterAnotherUpdate should not be empty');
        System.assertEquals(true, String.isNotEmpty(testIndividualsAfterAnotherUpdate.get(0).TXT_SNDX__c), 'Soundex text should not be empty');
    }
}