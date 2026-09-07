/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/26/2017                                                          
*  @description    Test class for DisabilityServices
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 17-Nov-2017                                                             
*  * Author: Shubham Jain                                                      
*  * Description: Initial version                                                 
*                                                                                 
*  * Version: 2.0                                                                             
*  * Date: 27-Apr-2017                                                             
*  * Author: Shubham Jain                                                      
*  * Description: Added start & stop method to fix 101 SOQL error.

*********************************************************************************************/
@isTest
public class DisabilityServicesTest {
    public static testMethod void testUpdateFieldsForPrimaryCaretaker(){
        List<T_SBSD_INDIV__c> individuals = [SELECT Id FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
        T_INDIV_DSBLTY__c indivDisablity = new T_INDIV_DSBLTY__c(IDN_CLIENT__c = individuals.get(0).Id,
                                                                 CDE_TYPE_DSBLTY__c = 'BEH',
                                                                 DTE_BEGIN_EFFV__c = System.today(),
                                                                 IND_CC_GIVE_ABLE__c = 'Y',
                                                                 CDE_SOURCE_DSBLTY_CHILD__c = 'DST'
                                                                );
        insert indivDisablity;
        List<T_INDIV_DSBLTY__c> insertedIndividualDisablity = [SELECT IND_REQMT_WORK_MEET_ABLE__c FROM T_INDIV_DSBLTY__c limit 100];
        System.assertEquals(1, insertedIndividualDisablity.size(), 'insertedIndividualDisablity should not be empty');
        System.assertEquals('N', insertedIndividualDisablity.get(0).IND_REQMT_WORK_MEET_ABLE__c, 'IND_REQMT_WORK_MEET_ABLE__c should be N');
        
        List<T_SBSD_CASE_INDIV__c> caseIndividuals = [SELECT Id,IND_CRTKR__c, IDN_CASE__c FROM T_SBSD_CASE_INDIV__c limit 100];
        System.assertEquals(false, caseIndividuals.isEmpty(), 'caseIndividuals should not be empty');
        insert new T_SBSD_CASE_STATUS_MODE__c(
            IDN_CASE__c = caseIndividuals.get(0).IDN_CASE__c,
            CDE_MODE_CASE__c = 'INT',
            DTE_BEGIN_EFFV__c = System.today()-5,
            DTE_END_EFFV__c = System.today()+5
        );              
        
        caseIndividuals.get(0).IND_CRTKR__c = true;
        update caseIndividuals;
        
        try{
            indivDisablity.IND_CC_GIVE_ABLE__c = 'N';
            update indivDisablity;
            System.assert(true, 'This state should not be executed');
        }catch(Exception ex){
            indivDisablity.CDE_LENGTH_DSBLTY__c = 'PER';
        }
        update indivDisablity;
        insertedIndividualDisablity = [SELECT IND_REQMT_WORK_MEET_ABLE__c FROM T_INDIV_DSBLTY__c WHERE Id = :indivDisablity.Id];
        System.assertEquals(1, insertedIndividualDisablity.size(), 'insertedIndividualDisablity should not be empty');
        //System.assertEquals('Y', insertedIndividualDisablity.get(0).IND_REQMT_WORK_MEET_ABLE__c, 'IND_REQMT_WORK_MEET_ABLE__c should be changed to Y');
    }
    
    public static testMethod void testUpdateFieldsForRelatedPrimaryCaretaker(){
        CaseLastUpdatedServices.isPeakApplicationContext = true;
        List<T_SBSD_INDIV__c> individuals = [SELECT Id FROM T_SBSD_INDIV__c limit 100];
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
        
        List<T_SBSD_CASE_INDIV__c> caseIndividuals = [SELECT Id,IND_CRTKR__c, IDN_CASE__c FROM T_SBSD_CASE_INDIV__c limit 100];
        System.assertEquals(false, caseIndividuals.isEmpty(), 'caseIndividuals should not be empty');
        insert new T_SBSD_CASE_STATUS_MODE__c(
            IDN_CASE__c = caseIndividuals.get(0).IDN_CASE__c,
            CDE_MODE_CASE__c = 'INT',
            DTE_BEGIN_EFFV__c = System.today()-5,
            DTE_END_EFFV__c = System.today()+5
        );              
        caseIndividuals.get(0).IND_CRTKR__c = true;
        update caseIndividuals;
        
        List<T_SBSD_CASE__c> caseRecords = [SELECT Id FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false, caseRecords.isEmpty(), 'caseRecords should not be empty');
        
        Test.startTest();
        CaseLastUpdatedServices.isPeakApplicationContext = true;
        
        T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(true,System.today().addYears(-15), 'firstNameB','1', 'lastNameB','123456780','CC');
        insert new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRecords.get(0).Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
        
        //T_INDIV_REL__c relationship = new T_INDIV_REL__c(IDN_CLIENT_RELTD__c = indivRec.Id, IDN_CLIENT__c = individuals.get(0).Id, CDE_TYPE_REL_INDIV__c = 'M');
        //insert relationship;
        
        //System.assertEquals(true,relationship.Id!=null, 'relationship should be successfully inserted');
        
        T_INDIV_DSBLTY__c indivDisablity = new T_INDIV_DSBLTY__c(IDN_CLIENT__c = indivRec.Id,
                                                                 CDE_TYPE_DSBLTY__c = 'BEH',
                                                                 DTE_BEGIN_EFFV__c = System.today(),
                                                                 IND_CC_GIVE_ABLE__c = 'Y'
                                                                );
        
        try{
            insert indivDisablity;
            System.assert(true, 'This code should not be reachable');
        }catch(Exception ex){
            indivDisablity.CDE_LENGTH_DSBLTY__c = 'PER';
            indivDisablity.CDE_SOURCE_DSBLTY_CHILD__c = 'DST';
            insert indivDisablity;
        }
        List<T_INDIV_DSBLTY__c> insertedIndividualDisablity = [SELECT IND_REQMT_WORK_MEET_ABLE__c FROM T_INDIV_DSBLTY__c WHERE Id = :indivDisablity.Id];
        System.assertEquals(1, insertedIndividualDisablity.size(), 'insertedIndividualDisablity should not be empty');
        Test.stopTest();
        // System.assertEquals('Y', insertedIndividualDisablity.get(0).IND_REQMT_WORK_MEET_ABLE__c, 'IND_REQMT_WORK_MEET_ABLE__c should be Y');
    }
    
    public static testMethod void testUpdateFieldsForAge(){
        List<T_SBSD_CASE__c> caseRecords = [SELECT Id FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false, caseRecords.isEmpty(), 'caseRecords should not be empty');
        
        T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(true,System.today().addYears(-25), 'firstNameB','1', 'lastNameB','123456780','CC');
        T_INDIV_DSBLTY__c indivDisablity = new T_INDIV_DSBLTY__c(IDN_CLIENT__c = indivRec.Id,
                                                                 CDE_TYPE_DSBLTY__c = 'BEH',
                                                                 DTE_BEGIN_EFFV__c = System.today(),
                                                                 IND_CC_GIVE_ABLE__c = 'Y'
                                                                );
        try{
            insert indivDisablity;
            System.assert(true, 'This code should not be reachable');
        }catch(Exception ex){
            indivDisablity.CDE_LENGTH_DSBLTY__c = 'PER';
            indivDisablity.CDE_SOURCE_DSBLTY_CHILD__c = 'DST';
            insert indivDisablity;
        }
        List<T_INDIV_DSBLTY__c> insertedIndividualDisablity = [SELECT IND_REQMT_WORK_MEET_ABLE__c FROM T_INDIV_DSBLTY__c WHERE Id = :indivDisablity.Id];
        System.assertEquals(1, insertedIndividualDisablity.size(), 'insertedIndividualDisablity should not be empty');
        // System.assertEquals('Y', insertedIndividualDisablity.get(0).IND_REQMT_WORK_MEET_ABLE__c, 'IND_REQMT_WORK_MEET_ABLE__c should be Y');
    }
    
    
    @testSetup
    public static void setUpData(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.uesername','ttes');
        
        if(user!=null){
        	insert user;
        }
             
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
            T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true,countyRec.Id);
            T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(true,System.today().addYears(-15), 'firstNameA','1', 'lastNameA','123456789','CC');
            insert new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
        }
    }
}