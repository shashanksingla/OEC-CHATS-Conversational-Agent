@isTest
public class caseIndividualServicesTest {
    
    public static testmethod void testDoUpdateRecentChildCareRequest(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_SBSD_CASE_INDIV__c caseIndiv = (T_SBSD_CASE_INDIV__c)caseData.get('caseIndiv');
        insert new T_INDIV_CAT_RQ__c(CDE_CAT_PROG__c = 'CC', DTE_BEGIN_EFFV__c = System.today()-14, IDN_CASE_INDIV__c = caseIndiv.Id);
        caseIndiv.DTE_END_EFFV__c = System.today();
        update caseIndiv;
        system.assertEquals(system.today(),[Select DTE_END_EFFV__c from T_SBSD_CASE_INDIV__c where Id=:caseIndiv.Id].DTE_END_EFFV__c ,'Effective End Date should be today');
    }
    
    public static testmethod void testUpdateEndDateOnCaseIndivRole(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_SBSD_CASE_STATUS_MODE__c caseStatusMode = (T_SBSD_CASE_STATUS_MODE__c)caseData.get('caseStaMod');
        T_SBSD_CASE_INDIV__c caseIndiv = (T_SBSD_CASE_INDIV__c)caseData.get('caseIndiv');
        caseIndiv.IND_CRTKR__c = true;
        update caseIndiv;
        T_SBSD_CASE_INDIV_ROLE__c newCaseIndivRoleRecord = new T_SBSD_CASE_INDIV_ROLE__c();                
        newCaseIndivRoleRecord.DTE_BEGIN_EFFV__c = date.today();
        newCaseIndivRoleRecord.IDN_CASE_INDIV__c = caseIndiv.Id;
        insert newCaseIndivRoleRecord;
        caseStatusMode.CDE_MODE_CASE__c = 'INT';
        update caseStatusMode;
        System.assertEquals(1, [SELECT Count() FROM T_SBSD_CASE_INDIV_ROLE__c WHERE DTE_END_EFFV__c=null], 'There should be one effective Case Individual Role record');
        caseIndiv.IND_CRTKR__c = false;
        Test.startTest();
        update caseIndiv;
        System.assertEquals(0, [SELECT Count() FROM T_SBSD_CASE_INDIV_ROLE__c WHERE DTE_END_EFFV__c=null], 'There should be no effective Case Individual Role record');        
        Test.stopTest();
    }    
    
    public static testmethod void testUpdateChildCareRequests(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_SBSD_CASE_INDIV__c caseIndiv = (T_SBSD_CASE_INDIV__c)caseData.get('caseIndiv');
        T_INDIV_CAT_RQ__c childCareRequest = new T_INDIV_CAT_RQ__c(CDE_CAT_PROG__c = 'CC', DTE_BEGIN_EFFV__c = System.today()-14, IDN_CASE_INDIV__c = caseIndiv.Id);
        insert childCareRequest;
        childCareRequest.CDE_CHANGE_RQ_CAT__c = 'MH';
        caseIndividualServices.updateChildCareRequests(new List<T_INDIV_CAT_RQ__c>{childCareRequest}, new Map<Id,T_SBSD_CASE_INDIV__c>{childCareRequest.Id=>caseIndiv});
        system.assert([select CDE_CAT_PROG__c from T_INDIV_CAT_RQ__c].size()>0,'Query should return childCareRequest records');
    }
    
    static testmethod void caseIndividualTest(){
        
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new T_SBSD_CASE_INDIV__c(    IDN_CLIENT__c = caseData.get('individual').Id,
                                        IDN_CASE__c = caseData.get('caseRec').Id,
                                        DTE_BEGIN_EFFV__c = date.today() );
        
        test.startTest();
        
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
        
        T_COUNTY__c countyObj =  new T_COUNTY__c (  CNTY_DEPT_NAME__c = 'Arapahoe County',
                                                  CDE_COUNTY__c = 3 );
        insert countyObj;
        
        T_SBSD_CASE__c caseObj = new T_SBSD_CASE__c (   CDE_COUNTY__c = countyObj.Id,
                                                     IND_ASSIST_PROVR__c = 'N',
                                                     CDE_ASST_HSNG__c = 'N');
        insert caseObj;
        
        T_SBSD_INDIV__c indivObj = new T_SBSD_INDIV__c( NAM_FIRST__c = 'John', NAM_LAST__c = 'Smith', DTE_DOB__c = date.today(),
                                                       IND_CDE_TYPE_VERIF_DOB__c = 'V', NBR_SSN__c = '123456789', CDE_GENDER__c = '1',
                                                       CDE_ETNCTY__c = 'N', CDE_SOURCE_VRFYD_DOB__c = 'BC', CDE_SOURCE_VRFYD_IDNTY__c = 'CC',
                                                       IND_CHILD_IDEA__c = 'N', IND_CHILD_SCREEN__c = 'N', IND_NOTIFY_SIDMOD__c = 'Y', CDE_ATTENDING_SCHOOL1__c = 'N');
        insert indivObj;
        
        T_APPLN_CASE__c applicationCase = new T_APPLN_CASE__c(IDN_APPLN__c = 123);
        
        insert applicationCase;
        /*T_APPLN_PRCS_QUEUE__c applnPrcsQueueObj = new T_APPLN_PRCS_QUEUE__c (IDN_CASE__c = caseObj.Id, 
DTE_RCVD_APPLN__c = date.today()-1,
IDN_APPLN__c =applicationCase.Id,
CDE_SOURCE__c='PK' , 
CDE_STATUS_APPLN__c ='NEW');
insert applnPrcsQueueObj;*/
        
        
        T_CHATS_PROVR_STATUS__c provr= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provr;
        
        T_AUTH__c authObj = new T_AUTH__c ( CDE_COUNTY__c = countyObj.Id, IDN_CASE__c = caseObj.Id,
                                           IDN_CLIENT__c = indivObj.Id, DTE_BEGIN_EFFV_AUTH__c = date.today(),
                                           IDN_PROVR__c = provr.Id, CDE_TYPE_VERIF__c = 'V', CDE_SOURCE_VRFYD_IMMU__c = 'PRO');
        insert authObj;
        
        /* T_SBSD_CASE_STATUS_MODE__c caseStatModeObj = new T_SBSD_CASE_STATUS_MODE__c(    DTE_BEGIN_EFFV__c = date.today(),
IDN_CASE__c = caseObj.Id,
CDE_MODE_CASE__c = 'INT'
);
insert caseStatModeObj;*/
        
        //Removed unused variable on 5/14/2018 BG  
        T_SBSD_CASE_INDIV__c caseIndivObj = new T_SBSD_CASE_INDIV__c(   IDN_CASE__c = caseObj.Id,
                                                                     IDN_CLIENT__c = indivObj.Id,
                                                                     DTE_BEGIN_EFFV__c = date.today());
        
        //caseIndivLst.add(caseIndivObj);
        //insert caseIndivLst;
        try{
            insert caseIndivObj;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Effective Begin Date Cannot be before-Latest Appl Receive Date in Application Process Queue') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        
        //this is to update earlier Primary caretaker to false
        T_SBSD_CASE_INDIV__c caseIndivObj1 = new T_SBSD_CASE_INDIV__c(  IDN_CASE__c = caseObj.Id,
                                                                      IDN_CLIENT__c = indivObj.Id,
                                                                      DTE_BEGIN_EFFV__c = date.today(),
                                                                      IND_CRTKR__c = true);
        
        try{
            insert caseIndivObj1;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Effective Begin Date Cannot be before-Latest Appl Receive Date in Application Process Queue') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        
        //Case Indiv Role update the end date
        T_SBSD_CASE_INDIV_ROLE__c caseIndivRoleObj = new T_SBSD_CASE_INDIV_ROLE__c( CDE_ROLE_CASE__c = 'HOH',
                                                                                   IDN_CASE_INDIV__c = caseIndivObj1.Id,
                                                                                   DTE_BEGIN_EFFV__c = date.today() - 1 );
        
        insert caseIndivRoleObj;
        
        /*        
caseIndivObjUpd.Id = caseIndivObj.Id;
caseIndivObjUpd.IDN_CASE__c = caseObj.Id;
caseIndivObjUpd.IDN_CLIENT__c = indivObj.Id;
caseIndivObjUpd.DTE_BEGIN_EFFV__c = date.today();
caseIndivObjUpd.IND_CRTKR__c = true;
update caseIndivObjUpd;
*/      
        
        system.assertEquals('HOH',caseIndivRoleObj.CDE_ROLE_CASE__c,'Head of Household');
        
        test.stopTest();
    }
    static testmethod void testInsertATSRecord(){
        List<T_SBSD_CASE_INDIV__c> lstCaseIndiv = new List<T_SBSD_CASE_INDIV__c>();
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_SBSD_CASE_INDIV__c caseIndiv= new T_SBSD_CASE_INDIV__c(    IDN_CLIENT__c = caseData.get('individual').Id,
                                                                 IDN_CASE__c = caseData.get('caseRec').Id,
                                                                 DTE_BEGIN_EFFV__c = date.today() );
        lstCaseIndiv.add(caseIndiv);
        test.startTest();
        CaseIndividualServices.insertATSRecord(lstCaseIndiv);
        test.stopTest();        
    }
    
    static testmethod void testUpdatePrimarcaretakeronIndividual(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_SBSD_CASE_INDIV__c caseIndiv= new T_SBSD_CASE_INDIV__c();
        caseIndiv=(T_SBSD_CASE_INDIV__c)caseData.get('caseIndiv');
        caseIndiv.IND_CRTKR__c = true;
        update caseIndiv;
        
        system.assertEquals(true,[select Is_Primary_Parent_Caretaker__c from T_SBSD_INDIV__c where Id=:caseData.get('individual').Id].Is_Primary_Parent_Caretaker__c, 'Is Primary Parent CareTaker is false');
        
        delete caseIndiv;
        
        system.assertEquals(false,[select Is_Primary_Parent_Caretaker__c from T_SBSD_INDIV__c where Id=:caseData.get('individual').Id].Is_Primary_Parent_Caretaker__c, 'Is Primary Parent CareTaker is true');
        

    }   
    
    @isTest
    static void testUpdateIndivDetailsForAdults() {
        T_COUNTY__c county = TestClassUtility.createCounty('Test County', 'Test County Dept', 1, true);
        T_SBSD_CASE__c testCase = TestClassUtility.createCase(true, county.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, Date.today().addYears(-25), 'John', '1', 'Doe', '123456789', 'CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(true, Date.today().addYears(-5), 'Jane', '2', 'Smith', '987654321', 'CC');
        T_SBSD_INDIV_INFO__c indivInfo = new T_SBSD_INDIV_INFO__c(
            IDN_CLIENT__c = individual.Id,
            CDE_TYPE_INFO_INDIV__c = 'CS',
            CDE_VALUE_INFO_INDIV__c = 'CZN',
            IDN_CASE__c = testCase.Id
        );
        insert indivInfo;        
        T_INDIV_VERIF__c indivVerif = new T_INDIV_VERIF__c(
            IDN_CLIENT__c = indivInfo.Id,
            CDE_TYPE_INFO_INDIV__c = 'CS'
        );
        insert indivVerif;        
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, testCase.Id, individual.Id, false);
 		T_SBSD_CASE_INDIV__c caseIndiv2 = TestClassUtility.createCaseIndividual(true, testCase.Id, individual2.Id, false);
             
        Test.startTest();
        
        caseIndiv.Individual_Status__c = 'PC';
        update caseIndiv;
        T_SBSD_INDIV__c updatedIndiv = [SELECT Id, CDE_GENDER__c, CDE_ATTENDING_SCHOOL1__c, IND_CHILD_IDEA__c, 
                                        IND_CHILD_SCREEN__c, CDE_RACE__c, CDE_ETNCTY__c, IND_CDE_TYPE_VERIF_DOB__c,
                                        CDE_SOURCE_VRFYD_DOB__c, CDE_SOURCE_VRFYD_CITIZEN__c 
                                        FROM T_SBSD_INDIV__c WHERE Id = :individual.Id];
        System.assertEquals('3', updatedIndiv.CDE_GENDER__c, 'Gender should be updated to 3');
        System.assertEquals('Unknown', updatedIndiv.CDE_ATTENDING_SCHOOL1__c, 'Attending school should be Unknown');
        System.assertEquals('N', updatedIndiv.IND_CHILD_IDEA__c, 'Child IDEA should be N');
        System.assertEquals('N', updatedIndiv.IND_CHILD_SCREEN__c, 'Child screen should be N');
        System.assertEquals('6', updatedIndiv.CDE_RACE__c, 'Race should be 6');
        System.assertEquals('U', updatedIndiv.CDE_ETNCTY__c, 'Ethnicity should be U');
        System.assertEquals('N/A-adult caretaker', updatedIndiv.IND_CDE_TYPE_VERIF_DOB__c, 'DOB verification should be N/A-adult caretaker');
        
        T_SBSD_INDIV_INFO__c updatedIndivInfo = [SELECT Id, CDE_VALUE_INFO_INDIV__c FROM T_SBSD_INDIV_INFO__c WHERE Id = :indivInfo.Id];
        System.assertEquals('N/A-adult caretaker', updatedIndivInfo.CDE_VALUE_INFO_INDIV__c, 'Individual info should be updated to N/A-adult caretaker');
        List<T_INDIV_VERIF__c> deletedVerifs = [SELECT Id FROM T_INDIV_VERIF__c WHERE IDN_CLIENT__c = :indivInfo.Id];
        System.assertEquals(0, deletedVerifs.size(), 'Individual verification records should be deleted');
        
        caseIndiv2.Individual_Status__c = 'Child';
        update caseIndiv2;   
        T_SBSD_INDIV__c updatedIndiv2 = [SELECT Id, CDE_GENDER__c, CDE_ATTENDING_SCHOOL1__c, IND_CHILD_IDEA__c, 
                                        IND_CHILD_SCREEN__c, CDE_RACE__c, CDE_ETNCTY__c, IND_CDE_TYPE_VERIF_DOB__c
                                        FROM T_SBSD_INDIV__c WHERE Id = :individual2.Id];
        System.assertEquals('2', updatedIndiv2.CDE_GENDER__c, 'Gender should not be updated for Child');
        Test.stopTest();
    }
    
    @isTest
    static void testUpdatePrimCrtkrOnIndivStatusUpdate() {
        T_COUNTY__c county = TestClassUtility.createCounty('Test County 2', 'Test County Dept', 1, true);
        T_SBSD_CASE__c testCase = TestClassUtility.createCase(true, county.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, Date.today().addYears(-25), 'John', '1', 'Doe', '123456789', 'CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, testCase.Id, individual.Id, false);
        
        Test.startTest();
        caseIndiv.Individual_Status__c = 'PC';
        update caseIndiv;
        T_SBSD_CASE_INDIV__c updatedCaseIndiv = [SELECT Id, IND_CRTKR__c, Individual_Status__c FROM T_SBSD_CASE_INDIV__c WHERE Id = :caseIndiv.Id];
        System.assertEquals(true, updatedCaseIndiv.IND_CRTKR__c, 'Primary caretaker flag should be true when Individual_Status__c is PC');
        caseIndiv.Individual_Status__c = 'AC';
        update caseIndiv;
        updatedCaseIndiv = [SELECT Id, IND_CRTKR__c, Individual_Status__c FROM T_SBSD_CASE_INDIV__c WHERE Id = :caseIndiv.Id];
        System.assertEquals(false, updatedCaseIndiv.IND_CRTKR__c, 'Primary caretaker flag should be false when Individual_Status__c is not PC');
        Test.stopTest();
    }
    
}