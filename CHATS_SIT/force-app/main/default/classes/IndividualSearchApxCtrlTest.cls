/*************************************************************
Class Name	    - IndividualSearchApxCtrlTest
Covering Class	- IndividualSearchApxCtrl
**************************************************************/
@isTest
public class IndividualSearchApxCtrlTest {
    
    @testSetup
    public static void doSetUp(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        insert new T_SBSD_CASE_ADR__c(IDN_CASE__c = caseRec.Id,
                                      ADR_CITY__c = 'test',
                                      ADR_STATE__c = 'CO',
                                      ADR_ZIP_MAIN__c = '12345',
                                      ADR_LINE_1__c = 'test Line',
                                      ADR_LINE_2__c = 'test Line2',
                                      ADR_ZIP_EXTN__c = '1234',
                                      CDE_TYPE_ADR__c = 'HOM'
                                     );
        insert new T_SBSD_CASE_PHONE__c(IDN_CASE__c = caseRec.Id,NBR_PHONE__c = '9998887776', CDE_TYPE_PHONE__c='HOM');
        Insert new Individual_E_mail__c(Individual__c = individual.Id, Email_Information__c = 'test@test.com', Effective_Begin_Date__c = System.today(),  Effective_End_Date__c = System.today()+1);
        TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        TestClassUtility.createCaseStatusMode(true,caseRec.Id );
    }
    
    public static testMethod void testSearchIndividualsForSimpleSearchIndividual(){
        List<T_SBSD_CASE__c> cases = [SELECT Id, Name, CDE_COUNTY__c FROM T_SBSD_CASE__c];
        System.assertEquals(false, cases.isEmpty(),'cases should not be empty');
        IndividualSearchWrapper indivSearchWrapper = new IndividualSearchWrapper(new T_SBSD_INDIV__c(NAM_FIRST__c = 'test first', NAM_LAST__c='test last', DTE_DOB__c=system.today().addYears(-15),NBR_SSN__c='1234',IDN_STATE__c='98765'), cases.get(0).Name, 'CO', 'test', cases.get(0).CDE_COUNTY__c, '12345', null,'StringSearch', null);
        List<T_SBSD_INDIV__c> individuals = (List<T_SBSD_INDIV__c>)IndividualSearchApxCtrl.searchIndividuals(JSON.serialize(indivSearchWrapper)).objectData.get('listIndiv');
        // System.assertEquals(true, individuals.isEmpty(), 'individuals should not be empty');
        IndividualSearchWrapper indivSearchWrapper2 = new IndividualSearchWrapper(new T_SBSD_INDIV__c(NAM_FIRST__c = '', NAM_LAST__c='', DTE_DOB__c=null,NBR_SSN__c='',IDN_STATE__c=''), cases.get(0).Id, 'CO', 'test', cases.get(0).CDE_COUNTY__c, '12345', null,'StringSearch', null);
        List<T_SBSD_INDIV__c> individuals2 = (List<T_SBSD_INDIV__c>)IndividualSearchApxCtrl.searchIndividuals(JSON.serialize(indivSearchWrapper2)).objectData.get('listIndiv');
    }
    
    public static testMethod void testSearchIndividualsForSimpleSearchAddress(){
        List<T_SBSD_CASE__c> cases = [SELECT Id,CDE_COUNTY__c FROM T_SBSD_CASE__c];
        System.assertEquals(false, cases.isEmpty(),'cases should not be empty');
        IndividualSearchWrapper indivSearchWrapper = new IndividualSearchWrapper(null , null, 'CO', 'test', cases.get(0).CDE_COUNTY__c, '12345', null,'StringSearch', null);
        List<T_SBSD_INDIV__c> individuals = (List<T_SBSD_INDIV__c>)IndividualSearchApxCtrl.searchIndividuals(JSON.serialize(indivSearchWrapper)).objectData.get('listIndiv');
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
    }
    
    public static testMethod void testSearchIndividualsForSimpleSearchPhone(){
        List<T_SBSD_CASE__c> cases = [SELECT Id,CDE_COUNTY__c, Name FROM T_SBSD_CASE__c];
        System.assertEquals(false, cases.isEmpty(),'cases should not be empty');
        IndividualSearchWrapper indivSearchWrapper = new IndividualSearchWrapper(null , null, null, null , cases.get(0).CDE_COUNTY__c, null, '9998887776','StringSearch',null);
        List<T_SBSD_INDIV__c> individuals = (List<T_SBSD_INDIV__c>)IndividualSearchApxCtrl.searchIndividuals(JSON.serialize(indivSearchWrapper)).objectData.get('listIndiv');
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
        IndividualSearchWrapper indivSearchWrapper2 = new IndividualSearchWrapper(null , cases.get(0).Name, 'CO', 'test' , cases.get(0).CDE_COUNTY__c, '12345', '9998887776','StringSearch',null);
        List<T_SBSD_INDIV__c> individuals2 = (List<T_SBSD_INDIV__c>)IndividualSearchApxCtrl.searchIndividuals(JSON.serialize(indivSearchWrapper2)).objectData.get('listIndiv');
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
    }
    
    public static testMethod void testSearchIndividualsForSoundexSearch(){
        List<T_SBSD_CASE__c> cases = [SELECT Id,CDE_COUNTY__c FROM T_SBSD_CASE__c];
        IndividualSearchWrapper indivSearchWrapper = new IndividualSearchWrapper(new T_SBSD_INDIV__c(NAM_FIRST__c = 'firstName', NAM_LAST__c='lastName'), cases.get(0).Id, null, null, null, null, null,'SoundexSearch',null);
        List<T_SBSD_INDIV__c> individuals = (List<T_SBSD_INDIV__c>)IndividualSearchApxCtrl.searchIndividuals(JSON.serialize(indivSearchWrapper)).objectData.get('listIndiv');
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
        IndividualSearchWrapper indivSearchWrapper2 = new IndividualSearchWrapper(new T_SBSD_INDIV__c(NAM_FIRST__c = '', NAM_LAST__c='lastName'), cases.get(0).Id, null, null, null, null, null,'SoundexSearch',null);
        List<T_SBSD_INDIV__c> individuals2 = (List<T_SBSD_INDIV__c>)IndividualSearchApxCtrl.searchIndividuals(JSON.serialize(indivSearchWrapper2)).objectData.get('listIndiv');
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
        IndividualSearchWrapper indivSearchWrapper3 = new IndividualSearchWrapper(new T_SBSD_INDIV__c(NAM_FIRST__c = 'firstName', NAM_LAST__c='', DTE_DOB__c=system.today().addYears(-15),NBR_SSN__c='1234',IDN_STATE__c='98765'), cases.get(0).Id, 'CO', 'test', null, '12345', '8123445000','SoundexSearch',null);
        List<T_SBSD_INDIV__c> individuals3 = (List<T_SBSD_INDIV__c>)IndividualSearchApxCtrl.searchIndividuals(JSON.serialize(indivSearchWrapper3)).objectData.get('listIndiv');
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
    }
    
    public static testMethod void testGetCaseRelatedToIndividual(){
        List<T_SBSD_INDIV__c> individuals = [SELECT Id FROM T_SBSD_INDIV__c];
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
        LightningServerResponse lsr = IndividualSearchApxCtrl.getCaseRelatedToIndividual(individuals.get(0).Id);  
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
    }
    
    public static testMethod void testSearchIndividualsWithEmail(){
        List<T_SBSD_CASE__c> cases = [SELECT Id, CDE_COUNTY__c, Name FROM T_SBSD_CASE__c];
        System.assertEquals(false, cases.isEmpty(),'cases should not be empty');
        IndividualSearchWrapper indivSearchWrapper = new IndividualSearchWrapper(null , null, null, null, cases.get(0).CDE_COUNTY__c, null, null,'StringSearch', 'test@test.com');
        List<T_SBSD_INDIV__c> individuals = (List<T_SBSD_INDIV__c>)IndividualSearchApxCtrl.searchIndividuals(JSON.serialize(indivSearchWrapper)).objectData.get('listIndiv');
        System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
    }
    
    public static testMethod void testGetCaseButtonVisibility(){
        Boolean result = IndividualSearchApxCtrl.getCaseButtonVisibility();
        System.assertEquals(true, result);
    }
}