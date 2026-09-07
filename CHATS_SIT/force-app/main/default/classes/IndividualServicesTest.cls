/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           1/8/2018                                                          
*  @description    Test class for IndividualServices
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 8-JAN-2018                                                             
*  * Author: Nikunj Doshi                                                   
*  * Description: testDoFillSoundexValue: testing the functionality of doFillSoundexValue
*  *              testToSoundex: testing the functionality of toSoundex 

*  * Version: 2.0                                                                             
*  * Date: 2-Feb-2018                                                           
*  * Author: Shubham Jain
*  * Description: testCreateTaskT101: testing the functionality of createTaskT101

*  * Version: 3.0                                                                             
*  * Date: 6-Mar-2018                                                           
*  * Author: Shubham Jain
*  * Description: testFillIND_NOTIFY_SIDMOD: testing the functionality of fillIND_NOTIFY_SIDMOD

*********************************************************************************************/
@isTest
public class IndividualServicesTest {
    public static testMethod void testDoFillSoundexValue(){
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        List<T_SBSD_INDIV__c> testIndividuals = [SELECT TXT_SNDX__c FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals(false, testIndividuals.isEmpty(), 'testIndividuals should not be empty');
        System.assertEquals(true, String.isNotEmpty(testIndividuals.get(0).TXT_SNDX__c), 'Soundex text should not be empty');
        individual.NAM_FIRST__c = 'Somerandomstring'; 
        update individual;
        List<T_SBSD_INDIV__c> testIndividualsAfterUpdate = [SELECT TXT_SNDX__c FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals(false, testIndividualsAfterUpdate.isEmpty(), 'testIndividualsAfterUpdate should not be empty');
        System.assertEquals(true, String.isNotEmpty(testIndividualsAfterUpdate.get(0).TXT_SNDX__c), 'Soundex text should not be empty');
        System.assertNotEquals(testIndividuals.get(0).TXT_SNDX__c, testIndividualsAfterUpdate.get(0).TXT_SNDX__c, 'Soundex text should be changed');

        individual.NAM_LAST__c = 'SomerandomstringB';
        update individual;
        List<T_SBSD_INDIV__c> testIndividualsAfterAnotherUpdate = [SELECT TXT_SNDX__c FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals(false, testIndividualsAfterAnotherUpdate.isEmpty(), 'testIndividualsAfterAnotherUpdate should not be empty');
        System.assertEquals(true, String.isNotEmpty(testIndividualsAfterAnotherUpdate.get(0).TXT_SNDX__c), 'Soundex text should not be empty');
        System.assertNotEquals(testIndividuals.get(0).TXT_SNDX__c, testIndividualsAfterAnotherUpdate.get(0).TXT_SNDX__c, 'Soundex text should be changed');

    }

    public static testMethod void testFillIND_NOTIFY_SIDMOD(){
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        List<T_SBSD_INDIV__c> testIndividuals = [SELECT IND_NOTIFY_SIDMOD__c FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals(false, testIndividuals.isEmpty(), 'testIndividuals should not be empty');
        System.assertEquals('N', testIndividuals.get(0).IND_NOTIFY_SIDMOD__c, 'IND_NOTIFY_SIDMOD__c should be N');
        individual.IDN_STATE__c = 'TEST1234';
        update individual;
        List<T_SBSD_INDIV__c> testIndividualsAfterUpdate = [SELECT IND_NOTIFY_SIDMOD__c FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals('Y', testIndividualsAfterUpdate.get(0).IND_NOTIFY_SIDMOD__c, 'IND_NOTIFY_SIDMOD__c should be Y');
        individual.IDN_STATE__c = 'SID Req';
        update individual;
        List<T_SBSD_INDIV__c> testIndividualsAfterAnotherUpdate = [SELECT IND_NOTIFY_SIDMOD__c FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals('N', testIndividualsAfterAnotherUpdate.get(0).IND_NOTIFY_SIDMOD__c, 'IND_NOTIFY_SIDMOD__c should be N');
    }
	
    public static testMethod void testCreateTaskT101(){
        Test.StartTest();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :caseRec.Id];
        System.assertEquals(true, tasks.isEmpty(), 'tasks should be empty');
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(false, caseRec.Id);
        caseStaMod.CDE_MODE_CASE__c = 'ONG';
        caseStaMod.CDE_STATUS_CASE__c = 'OPN';        
        insert caseStaMod;
        TestClassUtility.createCaseWaitlist(true,caseRec.Id, System.today()-10,null, 'RFS');
        individual.DTE_DOB__c = individual.DTE_DOB__c.addDays(1);
        individual.DTE_Death__c = Date.Today(); // added for T501 for SIDMOD , CCCAP-7695
        update individual;
        tasks = [SELECT Id FROM Task WHERE WhatId = :caseRec.Id];
        System.assertEquals(false, tasks.isEmpty(), 'tasks should not be empty');
        Test.StopTest();
    }
    public static testMethod void testCreateTaskT502(){
        Test.StartTest();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :caseRec.Id];
        System.assertEquals(true, tasks.isEmpty(), 'tasks should be empty');
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(false, caseRec.Id);
        caseStaMod.CDE_MODE_CASE__c = 'ONG';
        caseStaMod.CDE_STATUS_CASE__c = 'CLS';        
        insert caseStaMod;
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_ADJMT__c adj = TestClassUtility.createAdjustment(false,countyRec.Id, caseRec.Id,providerObj.Id);
        adj.CDE_TYPE_ADJMT__c = '2';
        adj.DTE_DISCV_ADJMT_ORIG__c =Date.today()-1;
        insert adj;
        individual.DTE_DOB__c = individual.DTE_DOB__c.addDays(1);
        individual.DTE_Death__c = Date.Today();
        update individual;
        tasks = [SELECT Id FROM Task WHERE WhatId = :caseRec.Id];
        System.assertEquals(false, tasks.isEmpty(), 'tasks should not be empty');
        Test.StopTest();
    }
    
    public static testMethod void testToSoundex(){
        System.assertEquals(true, SoundexUtil.toSoundex(null)==null, 'It should be null');
        String soundexText = SoundexUtil.toSoundex('USYH');
        System.assertEquals(true, soundexText.right(1)=='0', 'soundexText should end with 0.');
    }
    
    public static testMethod void testDeleteChildRecords(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        individual.IDN_STATE__c = 'Test123';
        insert individual;
        TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        insert new T_INDIV_TRAIN__c(DTE_BEGIN_EFFV__c = System.today().addDays(-2), Ignore__c = true, IDN_CLIENT__c = individual.Id); 
        delete individual;
        List<T_SBSD_INDIV__c> testIndividuals = [SELECT Id FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals(true, testIndividuals.isEmpty(), 'testIndividuals should be empty');
        List<T_SBSD_CASE_INDIV__c> testCaseIndividuals = [SELECT Id FROM T_SBSD_CASE_INDIV__c limit 100];
        System.assertEquals(true, testCaseIndividuals.isEmpty(), 'testCaseIndividuals should be empty');
        List<T_INDIV_TRAIN__c> testParentTrainings = [SELECT Id FROM T_INDIV_TRAIN__c limit 100];
        System.assertEquals(true, testParentTrainings.isEmpty(), 'testParentTrainings should be empty');
        List<T_IDXR_STG_DELETE__c> idxrstgRecs = [SELECT Id FROM T_IDXR_STG_DELETE__c limit 100];
        System.assertEquals(1, idxrstgRecs.size(), 'IDXR staging record should be created for deleted individual');
    } 
    
    
    
    public static testMethod void updatePrimCaretakerOnCaseTest() {
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        T_SBSD_CASE_INDIV__c caseIndiv=(T_SBSD_CASE_INDIV__c)TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        
        T_SBSD_CASE__c queryCaseRec=[select Id, NAM_PRIMARY_CARETAKER__c from T_SBSD_CASE__c where Id=:caseRec.Id];
        T_SBSD_CASE_INDIV__c queryCaseIndiv=[select Id, NAM_INDIV__c from T_SBSD_CASE_INDIV__c where Id=:caseIndiv.Id];
        
        system.assertEquals(queryCaseIndiv.NAM_INDIV__c ,queryCaseRec.NAM_PRIMARY_CARETAKER__c, 'Primary Caretaker name mismach');
        
        Test.StartTest();
        individual.NAM_LAST__c ='John';
        individual.NAM_FIRST__c ='Smith';
        individual.NAM_MI__c ='G';
        update individual;
        
        T_SBSD_CASE__c queryCaseRec2=[select Id, NAM_PRIMARY_CARETAKER__c from T_SBSD_CASE__c where Id=:caseRec.Id];
        T_SBSD_CASE_INDIV__c queryCaseIndiv2=[select Id, NAM_INDIV__c from T_SBSD_CASE_INDIV__c where Id=:caseIndiv.Id];
        
        system.assertEquals(queryCaseIndiv2.NAM_INDIV__c ,queryCaseRec2.NAM_PRIMARY_CARETAKER__c, 'Primary Caretaker name mismach');
        Test.StopTest();
    
    }
    
    public static testMethod void updateDOBChangeIndicatorTest(){
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        List<T_SBSD_INDIV__c> testIndividuals = [SELECT Id, DTE_DOB__c, DOB_Change_Indicator__c FROM T_SBSD_INDIV__c WHERE id=:individual.id limit 100];
        System.assertEquals(false, testIndividuals.isEmpty(), 'testIndividuals should not be empty');
        System.assertEquals(false, testIndividuals.get(0).DOB_Change_Indicator__c, 'DOB_Change_Indicator__c should be False');
        Test.StartTest();
        testIndividuals[0].IND_NOTIFY_SIDMOD__c = 'N';
        testIndividuals[0].DTE_DOB__c = system.today().addYears(-14);
        update testIndividuals;
        List<T_SBSD_INDIV__c> testIndividualsAfterUpdate = [SELECT Id, DTE_DOB__c, DOB_Change_Indicator__c FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals(true, testIndividualsAfterUpdate.get(0).DOB_Change_Indicator__c, 'DOB_Change_Indicator__c should be True');
        Test.StopTest();
    }
    
    public static testMethod void testValidateReadOnlyFieldsForClearedIndividuals(){
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false, system.today().addYears(-15), 'John', '1', 'Doe', '123456789', 'CC');
        individual.IDN_STATE__c = '123';
        individual.IND_NOTIFY_SIDMOD__c = 'Y'; 
        individual.NAM_MI__c = 'A';
        individual.DTE_Death__c = null;
        insert individual;
        
        Test.startTest();
        
        T_SBSD_INDIV__c nonClearedIndividual = TestClassUtility.createIndividual(false, system.today().addYears(-10), 'Jane', '2', 'Smith', '987654321', 'CC');
        nonClearedIndividual.IND_NOTIFY_SIDMOD__c = 'N';
        insert nonClearedIndividual;
        
        nonClearedIndividual.NAM_FIRST__c = 'Janet';
        nonClearedIndividual.NAM_LAST__c = 'Johnson';
        try {
            update nonClearedIndividual;
            System.assert(true, 'Non-cleared individual should allow field updates');
        } catch (Exception e) {
            System.assert(false, 'Non-cleared individual should allow field updates but got error: ' + e.getMessage());
        }
        
        individual.NAM_FIRST__c = 'Johnny';
        Boolean errorOccurred = false;
        try {
            update individual;
        } catch (DmlException e) {
            errorOccurred = true;
            System.assert(e.getMessage().contains('Fields: First Name, Middle Initial, Last Name, Gender, SSN, DOB, Date of Death cannot be edited for the cleared individual'), 
                         'Should get validation error for cleared individual field update');
        }
        System.assert(errorOccurred, 'Validation error should occur when updating cleared individual fields');
    }
}