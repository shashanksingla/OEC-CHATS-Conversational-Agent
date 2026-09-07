@isTest
public class ConvertCBMSDataToCHATS_TEST 
{
    @isTest static void converChangeReftData_TEST() 
	{
		//Map<String, SObject> caseRecIs = CaseLastUpdatedTestFactory.createCaseData();
        //T_SBSD_CASE__c caseX = new T_SBSD_CASE__c(CDE_CBMS_REF_TYP__c = 'Change', DTE_APPLN__c = System.today());
		//insert x;
		T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
		T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false, System.today().addYears(-18), 'firstName','1', 'lastName','989898989','CC');
        individual.IDN_STATE__c = '';
        insert individual;
        caseRec.CDE_CBMS_REF_TYP__c = 'Change';
        caseRec.DTE_APPLN__c = System.today();
        insert caseRec;
		T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        //
		T_APPLN_CASE__c applnCase = new T_APPLN_CASE__c (   IDN_APPLN__c = 123456543, NBR_APPLN_SEC__c = 'ApplnNumber');
        insert applnCase;
        T_APPLN_PRCS_QUEUE__c applnPrcsQueue = new T_APPLN_PRCS_QUEUE__c( IDN_APPLN__c = applnCase.Id);
        insert applnPrcsQueue;
		T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(NBR_PHONE_CELL__c='9999999999', NBR_PHONE_HOME__c = '9999999999', NBR_PHONE_MSG_EXTN__c = '9876', NBR_PHONE_MSG__c = '9999999999', CDE_INFO_PMC__c = 'WOR');
        insert appCase;
		T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
            IDN_APPLN__c = appCase.Id,
            CDE_SOURCE__c = 'PK',
            DTE_RCVD_APPLN__c = System.today().addDays(-15),
            CDE_COUNTY__c = '1'
        );
        insert appProcessQueue;
        
        T_APPLN_DSBLTY__c appDisablilty = new T_APPLN_DSBLTY__c(IND_CC_GIVE_ABLE__c = 'Y', IND_YR_DSBL__c  = 'Y');
        T_APPLN_DSBLTY__c appDisablilty2 = new T_APPLN_DSBLTY__c(IND_CC_GIVE_ABLE__c = 'Y', IND_YR_DSBL__c  = 'N');
        
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test','1', 'Individual', '12345678',appProcessQueue.IDN_APPLN__c);
		appIndivRec.IDN_STATE__c = '11223344';
        appIndivRec.CDE_STATUS_MIL__c = 'NO';
        appIndivRec.IND_CRTKR_PRIM__c = 'Y';
        appIndivRec.IDN_SEQ_INDIV__c = 1;
        appIndivRec.NAM_MI__c = 'TEST';	
		appIndivRec.ROADMAP_CORR_ID__c = '1234';
		insert appIndivRec;
        T_APPLN_INDIV__c appIndivRec1 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test','1', 'Individual', '12345678',appProcessQueue.IDN_APPLN__c);
		appIndivRec1.IDN_STATE__c = '11223344';
        appIndivRec1.CDE_STATUS_MIL__c = 'NO';
        //appIndivRec.IND_CRTKR_PRIM__c = 'Y';
        appIndivRec1.IDN_SEQ_INDIV__c = 1;
        appIndivRec1.NAM_MI__c = 'TEST';	
		appIndivRec1.ROADMAP_CORR_ID__c = '1234';
		insert appIndivRec1;
        List<String> appIndivRecList = new List<String>();
		appIndivRecList.add(appIndivRec.Id);
		//
		T_SBSD_CASE__c cases = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c ind = TestClassUtility.createIndividual(true, System.today().addYears(-18), 'firstName','1', 'lastName','989898989','CC');
		T_SBSD_ROADMAP_CORR_ID__c road = new T_SBSD_ROADMAP_CORR_ID__c();
        road.CASE_ID__c = cases.id;
        road.CBMS_CASE_NUM__c = 'ABC123';
        road.INDIVIDUAL__c = ind.id;
        road.ROADMAP_CORR_ID__c = '1234';
        insert road;
		//
		T_APPLN_CHILD_CARE__c appChildCareRec = new T_APPLN_CHILD_CARE__c(IDN_INDIVIDUAL__c = appIndivRec.Id, IND_NEED_CHILD_CARE__c = 'Y');
        T_APPLN_CHILD_SUP__c appChildSupEnforce = new T_APPLN_CHILD_SUP__c(IDN_APPLN_INDIV__c = appIndivRec.Id);
		insert appChildCareRec;
		insert appChildSupEnforce;
		//
		insert new List<SObject>{
                new T_APPLN_ADR__c(
                    ADR_CITY__c = 'test',
                    ADR_LINE_1__c = 'test line 1',
                    ADR_LINE_2__c = 'test line 2',
                    ADR_STATE__c = 'AK',
                    ADR_ZIP_EXTN__c = '1345',
                    ADR_ZIP_MAIN__c = '12345',
                    CDE_TYPE_ADR__c = 'ML',
                    IDN_APPLN_INDIV__c = appIndivRec.Id
                ),
		new T_APPLN_INDIV_RACE__c(IDN_APPLN_INDIV__c = appIndivRec.Id, IDN_APPLN_INDIV_RACE__c = 3, CDE_RACE__c = 'AA', CDE_ETNCTY__c = '12'),    
            //new T_APPLN_PRCS_ADDNL_INFO__c(IND_TANF_RCVNG__c = 'Y', IDN_APPLN__c = appProcessQueues.get(0).IDN_APPLN__c),
            //new T_APPLN_JOB_SEARCH__c(IDN_APPLN_INDIV__c = appIndivRec.Id, DTE_BEGIN_EFFV__c = System.today()),
            new T_APPLN_CHILD_SUP__c(DTE_BIRTH_CUST_NON__c = System.today(),
                                     IDN_STATE_CUST_NON__c = '12',
                                     IND_CASE_OPEN__c = 'Y',
                                     IND_COOP_PARENT__c = 'Y',
                                     NAM_FIRST_CUST_NON__c = 'test',
                                     NAM_LAST_CUST_NON__c = 'test',
                                     IDN_APPLN_INDIV__c = appIndivRec.Id,
                                     NBR_SSN_CUST_NON__c = '12'
                                    ),
			new T_APPLN_CUST__c(
                        IDN_APPLN_INDIV__c = appIndivRec.Id,
                        IDN_APPLN_CUST__c = 12,
                        DTE_BEGIN_HEAD_START__c = System.today(),
                        IND_CC_REQ__c = 'Y',
                        IND_HEAD_START__c = 'N',
                        IND_FOSTER__c = 'Y',
                        IND_JOINT_CUST__c = 'Y',
                        DTE_JOINT_CUST__c = System.today(),
                        DTE_FOSTER__c = System.today()),
            new T_APPLN_DSBLTY__c(IND_CC_GIVE_ABLE__c = 'Y',IDN_APPLN_INDIV__c = appIndivRec.Id),
            new T_APPLN_DDTN__c(AMT_DDTN_TOTAL__c = 1,
                                CDE_FREQ_PAID__c = '2PY',
                                NAM_PAYEE__c = 'Test',
                                NBR_DOCKET__c = '1',
                                IDN_APPLN_INDIV__c = appIndivRec.Id
                               ),
            new T_APPLN_OTHER_INCOME__c( 
                IDN_APPLN_INDIV__c = appIndivRec.Id,
                IDN_APPLN_OTHER_INCOME__c = 12,
                CDE_SOURCE_INCOME__c = '1',
                IDN_COURT__c = '12',
                CDE_FREQ_INCOME__c = '09',
                AMT_INCOME_OTHER_GROSS__c = 23
            ),
            new T_APPLN_EDUC__c(IDN_APPLN_INDIV__c = appIndivRec.Id, NAM_SCHOOL__c = 'testSchool', CDE_TYPE_SCHOOL__c = '02')
            };
		//
		LightningServerResponse lsr = ConvertCBMSDataToCHATS.convertData(null, null);
		//
		Test.startTest();
		ConvertCBMSDataToCHATS.converChangeReftData(caseRec, appProcessQueue, appIndivRecList, individual.Id);
        Test.stoptest();
		/* XD */
		/* :D */
		
		
        
    }
    
    @isTest static void convertData_TEST() 
	{
       T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(NBR_PHONE_CELL__c='9999999999', NBR_PHONE_HOME__c = '9999999999', NBR_PHONE_MSG_EXTN__c = '9876', NBR_PHONE_MSG__c = '9999999999', CDE_INFO_PMC__c = 'WOR');
        insert appCase;
		T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
            IDN_APPLN__c = appCase.Id,
            CDE_SOURCE__c = 'PK',
            DTE_RCVD_APPLN__c = System.today().addDays(-15),
            CDE_COUNTY__c = '1'
        );
        insert appProcessQueue;
        
        T_APPLN_INDIV__c appIndivRec1 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test','1', 'Individual', '12345678',appProcessQueue.IDN_APPLN__c);
		appIndivRec1.IDN_STATE__c = '11223344';
        appIndivRec1.CDE_STATUS_MIL__c = 'NO';
        //appIndivRec.IND_CRTKR_PRIM__c = 'Y';
        appIndivRec1.IDN_SEQ_INDIV__c = 1;
        appIndivRec1.NAM_MI__c = 'TEST';	
		appIndivRec1.ROADMAP_CORR_ID__c = '1234';
		insert appIndivRec1;
        List<String> appIndivRecList = new List<String>();
		appIndivRecList.add(appIndivRec1.Id);
		// Date
		T_YEAR_HOL__c holidayRec = new T_YEAR_HOL__c();
        holidayRec.DTE_HOL__c= System.today();
        holidayRec.CDE_YEAR__c=System.today().year();
        insert holidayRec;
        //Test.setCreatedDate(appProcessQueue.Id, System.today());
       
        Test.startTest();
        ConvertCBMSDataToCHATS.convertData(appProcessQueue, appIndivRecList);
        Test.stopTest();
    }
    
    @isTest static void convertRefDataForTransition_TEST() 
    {
		T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false, System.today().addYears(-18), 'firstName','1', 'lastName','989898989','CC');
        individual.IDN_STATE__c = '112233';
        insert individual;
        T_SBSD_INDIV__c individual1 = TestClassUtility.createIndividual(false, System.today().addYears(-18), 'firstName','1', 'lastName','989898989','CC');
        individual1.IDN_STATE__c = '1122';
        insert individual1;
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c cases = TestClassUtility.createCase(true, countyRec.Id);
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(NBR_PHONE_CELL__c='9999999999', NBR_PHONE_HOME__c = '9999999999', NBR_PHONE_MSG_EXTN__c = '9876', NBR_PHONE_MSG__c = '9999999999', CDE_INFO_PMC__c = 'WOR');
        appCase.CBMS_CASE_NUM__c = '1234';
        insert appCase;
		T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
            IDN_APPLN__c = appCase.Id,
            CDE_SOURCE__c = 'PK',
            DTE_RCVD_APPLN__c = System.today().addDays(-15),
            CDE_COUNTY__c = '1',
            IDN_CASE__c = cases.Id
        );
        insert appProcessQueue;
        
        T_APPLN_INDIV__c appIndivRec2 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test','1', 'Individual', '12345678',appProcessQueue.IDN_APPLN__c);
		appIndivRec2.IDN_STATE__c = '112233';
        appIndivRec2.CDE_STATUS_MIL__c = 'NO';
        //appIndivRec.IND_CRTKR_PRIM__c = 'Y';
        appIndivRec2.IDN_SEQ_INDIV__c = 1;
        appIndivRec2.NAM_MI__c = 'TEST';	
		appIndivRec2.ROADMAP_CORR_ID__c = '14';
		insert appIndivRec2;
        T_APPLN_INDIV__c appIndivRec1 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test','1', 'Individual', '12345678',appProcessQueue.IDN_APPLN__c);
		appIndivRec1.IDN_STATE__c = '112233';
        appIndivRec1.CDE_STATUS_MIL__c = 'NO';
        //appIndivRec.IND_CRTKR_PRIM__c = 'Y';
        appIndivRec1.IDN_SEQ_INDIV__c = 1;
        appIndivRec1.NAM_MI__c = 'TEST';	
		appIndivRec1.ROADMAP_CORR_ID__c = '1234';
		insert appIndivRec1;
        List<String> appIndivRecList = new List<String>();
		appIndivRecList.add(appIndivRec1.Id);
		appIndivRecList.add(appIndivRec2.Id);        
		//
		List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, County_Name__c, IDN_CASE__c, CDE_COUNTY__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
		T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test','M', 'Individual', '12345678',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec.IDN_STATE__c = '112233';
        appIndivRec.CDE_STATUS_MIL__c = 'NO';
        appIndivRec.IND_CRTKR_PRIM__c = 'Y';
        appIndivRec.IDN_SEQ_INDIV__c = 1;
        appIndivRec.NAM_MI__c = 'TEST';
		insert new List<SObject>{appIndivRec};

          insert new T_APPLN_REL__c(IDN_APPLN_INDIV__c=appIndivRec1.id,IDN_SEQ_INDIV_RELTD__c=2, CDE_TYPE_REL_INDIV__c='FA');
		insert new List<SObject>{
                new T_APPLN_ADR__c(
                    ADR_CITY__c = 'test',
                    ADR_LINE_1__c = 'test line 1',
                    ADR_LINE_2__c = 'test line 2',
                    ADR_STATE__c = 'AK',
                    ADR_ZIP_EXTN__c = '1345',
                    ADR_ZIP_MAIN__c = '12345',
                    CDE_TYPE_ADR__c = 'ML',
                    IDN_APPLN_INDIV__c = appIndivRec1.Id
                ),
                    new T_APPLN_INDIV_RACE__c(IDN_APPLN_INDIV__c = appIndivRec1.Id, IDN_APPLN_INDIV_RACE__c = 3, CDE_RACE__c = 'AA'),    
                    //new T_APPLN_PRCS_ADDNL_INFO__c(IND_TANF_RCVNG__c = 'Y', IDN_APPLN__c = appProcessQueues.get(0).IDN_APPLN__c),
                    //new T_APPLN_JOB_SEARCH__c(IDN_APPLN_INDIV__c = appIndivRec.Id, DTE_BEGIN_EFFV__c = System.today()),
                    new T_APPLN_CHILD_SUP__c(DTE_BIRTH_CUST_NON__c = System.today(),
                                             IDN_STATE_CUST_NON__c = '12',
                                             IND_CASE_OPEN__c = 'Y',
                                             IND_COOP_PARENT__c = 'Y',
                                             NAM_FIRST_CUST_NON__c = 'test',
                                             NAM_LAST_CUST_NON__c = 'test',
                                             IDN_APPLN_INDIV__c = appIndivRec.Id,
                                             NBR_SSN_CUST_NON__c = '12'
                                            ),
                    new T_APPLN_DSBLTY__c(IND_CC_GIVE_ABLE__c = 'Y',IDN_APPLN_INDIV__c = appIndivRec.Id),
                    new T_APPLN_DDTN__c(AMT_DDTN_TOTAL__c = 1,
                                        CDE_FREQ_PAID__c = '2PY',
                                        NAM_PAYEE__c = 'Test',
                                        NBR_DOCKET__c = '1',
                                        IDN_APPLN_INDIV__c = appIndivRec.Id
                                       ),
                    new T_APPLN_OTHER_INCOME__c( 
                        IDN_APPLN_INDIV__c = appIndivRec1.Id,
                        IDN_APPLN_OTHER_INCOME__c = 12,
                        CDE_SOURCE_INCOME__c = '1',
                        IDN_COURT__c = '12',
                        CDE_FREQ_INCOME__c = '09',
                        AMT_INCOME_OTHER_GROSS__c = 23
                    ),
                    new T_APPLN_EDUC__c(IDN_APPLN_INDIV__c = appIndivRec.Id, NAM_SCHOOL__c = 'testSchool', CDE_TYPE_SCHOOL__c = '02'),
                    new T_APPLN_CUST__c(
                        IDN_APPLN_INDIV__c = appIndivRec1.Id,
                        IDN_APPLN_CUST__c = 12,
                        DTE_BEGIN_HEAD_START__c = System.today(),
                        IND_CC_REQ__c = 'Y',
                        IND_HEAD_START__c = 'N',
                        IND_FOSTER__c = 'Y',
                        IND_JOINT_CUST__c = 'Y',
                        DTE_JOINT_CUST__c = System.today(),
                        DTE_FOSTER__c = System.today()),
                    new T_APPLN_EMPLMT__c(
                        IDN_APPLN_INDIV__c = appIndivRec1.Id,
                        ADR_CITY__c = 'test', ADR_SUFX__c = 'test', ADR_NAM__c = 'test',
                        ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'tewzt', ADR_STATE__c = 'AK',
                        CDE_UNIT__c = '1', NAM_BUSNS__c = '12', NBR_PHONE__c = '12387632',
                        ADR_ZIP_EXTN__c = '2625', NBR_PHONE_EXTN__c = '2222', ADR_POST__c = '26',
                        AMT_INCOME_MONTH_ESTMD__c = 12.00, ADR_ZIP_MAIN__c = '12235',
                        CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, ADR_PO_BOX__c = '1', ADR_PRE__c = '1',
                        DTE_BEGIN_INCOME__c = System.Date.newInstance(2017, 12, 01),
                        DTE_BEGIN_STRIKE__c = System.Date.newInstance(2017, 11, 07),
                        DTE_BEGIN_EMP__c = System.Date.newInstance(2017, 11, 07), CDE_FREQ_EXP__c = '02'),
                    
                    new T_APPLN_SELF_EMPLMT__c(
                        IDN_APPLN_INDIV__c = appIndivRec1.Id, ADR_CITY__c = 'test', IDN_APPLN_SELF_EMPLMT__c = 1212,
                        CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, AMT_INCOME_MONTH_ESTMD__c = 12.00, IND_LLC_SCORP__c = '1',
                        ADR_ZIP_EXTN__c = '1234', NBR_PHONE_EXTN__c = '1234', NBR_PHONE__c = '4564362', ADR_ZIP_MAIN__c = '12445',
                        NAM_BUSNS__c = '12', AMT_EXP_MONTH__c = 12.00, ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'test', ADR_STATE__c = 'AK',
                        DTE_BEGIN_EFFV__c = System.Date.newInstance(2017, 11, 11))
                    
                    };
		T_APPLN_ACTIVITY__c appActivityRec = new T_APPLN_ACTIVITY__c();
         appActivityRec.IDN_INDIVIDUAL__c = appIndivRec1.Id;
         appActivityRec.CDE_TYPE_ACTV__c = '13';
        insert appActivityRec;
        T_APPLN_ACTIVITY__c appActivityRec2 = new T_APPLN_ACTIVITY__c();
         appActivityRec2.IDN_INDIVIDUAL__c = appIndivRec1.Id;
         appActivityRec2.CDE_TYPE_ACTV__c = '15';
        insert appActivityRec2;
        T_APPLN_ACTIVITY__c appActivityRec3 = new T_APPLN_ACTIVITY__c();
         appActivityRec3.IDN_INDIVIDUAL__c = appIndivRec1.Id;
         appActivityRec3.CDE_TYPE_ACTV__c = '16';
        insert appActivityRec3;
        
       
		T_SBSD_ROADMAP_CORR_ID__c road = new T_SBSD_ROADMAP_CORR_ID__c();
        road.CASE_ID__c = cases.id;
        road.CBMS_CASE_NUM__c = 'ABC123';
        road.INDIVIDUAL__c = individual.id;
        road.ROADMAP_CORR_ID__c = '1234';
        insert road;
        T_SBSD_ROADMAP_CORR_ID__c road1 = new T_SBSD_ROADMAP_CORR_ID__c();
        road1.CASE_ID__c = cases.id;
        road1.CBMS_CASE_NUM__c = 'ABC123';
        road1.INDIVIDUAL__c = individual1.id;
        road1.ROADMAP_CORR_ID__c = '';
        insert road1;
        
        Test.startTest();
        ConvertCBMSDataToCHATS.convertRefDataForTransition(appProcessQueue.Id, appIndivRecList);
        Test.stopTest();
    }
    
    @isTest static void createIndividualChildRecords_TEST() 
    {
		T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
		T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
		T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false, System.today().addYears(-18), 'firstName','1', 'lastName','989898989','CC');
        individual.IDN_STATE__c = '';
        insert individual;
		//
        caseRec.CDE_CBMS_REF_TYP__c = 'Change';
        caseRec.DTE_APPLN__c = System.today();
        insert caseRec;
		//
		Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_INDIV_EDUC__c indivEduc = new T_INDIV_EDUC__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                   	CDE_TYPE_VERIF__c = 'NA',
                                   	DTE_BEGIN_EFFV__c = date.today()-3 );
		insert indivEduc;
		//
		T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC');
        T_INDIV_TRAIN__c indivTraining = new T_INDIV_TRAIN__c (IDN_CLIENT__c = indivObj.Id,
                                                              	Ignore__c = true,
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = null);
		insert indivTraining;
		//
		List<SObject> lstChildRecords = new List<SObject>();
		lstChildRecords.add(indivEduc);
		lstChildRecords.add(indivTraining);
        //lstChildRecords.add(caseRec);
		//
        Test.startTest();
        ConvertCBMSDataToCHATS.createIndividualChildRecords(individual, caseRec, lstChildRecords, null);
        Test.stopTest();
    }
}