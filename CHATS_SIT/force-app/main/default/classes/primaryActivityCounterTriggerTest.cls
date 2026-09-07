@isTest
public class primaryActivityCounterTriggerTest {
    static testmethod void testPrimaryActivityCounterTrigger() {
        //County object
        test.startTest();
        T_COUNTY__c countyObj = new T_COUNTY__c (  CDE_COUNTY__c = 3 );
        insert countyObj;
        T_COUNTY_PLAN__c countyPlanObj = new T_COUNTY_PLAN__c(	CDE_COUNTY__c = countyObj.Id, CDE_STATUS__c = 'APV', 
                                                              	ELIGIBILITY_Q2_1__c = 105, ELIGIBILITY_Q3_1__c = 50, ELIGIBILITY_Q4__c = 15);
        insert countyPlanObj;
        
        T_SBSD_CASE__c caseObj = new T_SBSD_CASE__c (   CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N', CDE_ASST_HSNG__c = 'N');
        T_SBSD_CASE__c caseObj2 = new T_SBSD_CASE__c (CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N', CDE_ASST_HSNG__c = 'N');
        insert new List<T_SBSD_CASE__c>{caseObj, caseObj2};
            
       T_SBSD_INDIV__c adultIndiv = TestClassUtility.createIndividual(true, Date.today().addYears(-30), 'AdultFirst', '1', 'AdultLast', '123456789', 'CC');
       T_SBSD_CASE_INDIV__c caseIndivPC = TestClassUtility.createCaseIndividual(true,caseObj2.Id, adultIndiv.Id, true);

        
        T_SBSD_CASE_STATUS_MODE__c caseStatModeObj = new T_SBSD_CASE_STATUS_MODE__c(    DTE_BEGIN_EFFV__c = date.today(), IDN_CASE__c = caseObj.Id,
                                                                                        CDE_MODE_CASE__c = 'ONG', CDE_STATUS_CASE__c = 'OPN'
                                                                                   );
        T_SBSD_CASE_STATUS_MODE__c caseStatModeObj2 = new T_SBSD_CASE_STATUS_MODE__c(DTE_BEGIN_EFFV__c = date.today(), IDN_CASE__c = caseObj2.Id,
                                                                                        CDE_MODE_CASE__c = 'ONG', CDE_STATUS_CASE__c = 'OPN'
                                                                                   );
        insert new List<T_SBSD_CASE_STATUS_MODE__c>{caseStatModeObj, caseStatModeObj2};
        
        T_PRIM_ACTV__c prmryActvtyObj = new T_PRIM_ACTV__c(	IDN_CASE__c = caseObj.Id, DTE_BEGIN_ACTV_PRIM__c = system.today(),
                                                          	DTE_END_ACTV_PRIM__c = system.today() + 1, Ignore__c = true,
                                                          	CDE_TYPE_ACTV__c = 'JS'
                                                          );
        T_PRIM_ACTV__c prmryActvtyObj2 = new T_PRIM_ACTV__c(IDN_CASE__c = caseObj2.Id, DTE_BEGIN_ACTV_PRIM__c = system.today(),
                                                          	DTE_END_ACTV_PRIM__c = system.today() + 1, Ignore__c = true,
                                                          	CDE_TYPE_ACTV__c = 'SUD'
                                                          );
        insert new List<T_PRIM_ACTV__c>{prmryActvtyObj, prmryActvtyObj2};
        
        T_PRIM_ACTV_CNTR__c prmryActvtyCntr = new T_PRIM_ACTV_CNTR__c(	IDN_PRIM_ACTV__c = prmryActvtyObj.Id, CNT_WEEKS__c = 13);
        T_PRIM_ACTV_CNTR__c prmryActvtyCntr2 = new T_PRIM_ACTV_CNTR__c(	IDN_PRIM_ACTV__c = prmryActvtyObj2.Id, CNT_WEEKS__c = 50, IDN_CLIENT__c=adultIndiv.Id);
        insert new List<T_PRIM_ACTV_CNTR__c>{prmryActvtyCntr, prmryActvtyCntr2};
        
        system.assertEquals(prmryActvtyObj.Id,[select IDN_EXTNL__c from T_PRIM_ACTV__c where Id=:prmryActvtyObj.Id].IDN_EXTNL__c,'Primary actvity External id should be matching with Record Id');
    	test.stopTest();
    }
}