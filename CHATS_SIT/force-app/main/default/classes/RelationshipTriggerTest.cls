@isTest(SeeAllData=true)
public class RelationshipTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        
        T_INDIV_REL__c updIndivRelrcrd = new T_INDIV_REL__c();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true,countyRec.Id);
        T_SBSD_INDIV__c indivRec3 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameC','1', 'LastNameC','3327124','CC');
        T_SBSD_INDIV__c indivRec5 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameE','1', 'LastNameE','3327128','CC');
        
        insert new List<SObject>{indivRec3, indivRec5};
            
            T_SBSD_CASE_INDIV__c caseIndiv3 =  new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=true, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec3.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
        T_SBSD_CASE_INDIV__c caseIndiv5 =  new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec5.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
        insert new List<SObject>{ caseIndiv3, caseIndiv5};
            
            T_INDIV_REL__c indivRel = new T_INDIV_REL__c(IDN_CLIENT_RELTD__c = indivRec5.Id, IDN_CLIENT__c = indivRec3.Id, CDE_TYPE_REL_INDIV__c = 'M');
        try{
            insert indivRel; 
            Test.startTest();
            updIndivRelrcrd.Id = indivRel.Id;
            updIndivRelrcrd.CDE_TYPE_REL_INDIV__c = 'A';
            update updIndivRelrcrd;
            system.assertEquals('A', updIndivRelRcrd.CDE_TYPE_REL_INDIV__c,'Relationship should be Aunt' );
            Test.stopTest();
        }catch(exception ex){    
            system.assertNotEquals(ex, null);      
        }
        
    }
    
    private static testmethod void testUpdateIndividualWithHasAllowedRelationship() {
        
        T_INDIV_REL__c updIndivRelrcrd = new T_INDIV_REL__c();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true,countyRec.Id);
        T_SBSD_INDIV__c indivRec3 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameC','1', 'LastNameC','3327124','CC');
        T_SBSD_INDIV__c indivRec5 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameE','1', 'LastNameE','3327128','CC');
        
        insert new List<SObject>{indivRec3, indivRec5};
            
            T_SBSD_CASE_INDIV__c caseIndiv3 =  new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=true, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec3.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
        T_SBSD_CASE_INDIV__c caseIndiv5 =  new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec5.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
        insert new List<SObject>{ caseIndiv3, caseIndiv5};
            
            T_INDIV_REL__c indivRel = new T_INDIV_REL__c(IDN_CLIENT_RELTD__c = indivRec5.Id, IDN_CLIENT__c = indivRec3.Id, CDE_TYPE_REL_INDIV__c = 'M');
        try{
            insert indivRel;
            
            List<T_SBSD_INDIV__c> newLst = [select Has_Allowed_Relationship__c from T_SBSD_INDIV__c where Id=:indivRec5.Id];
            
            system.assertEquals(true,newLst[0].Has_Allowed_Relationship__c , 'Has allowed relationship is false'); 
        }catch(exception ex){    
            system.assertNotEquals(ex, null);     
        } 
        
    } 
}