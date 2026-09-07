@isTest
public class CaseLastUpdatedServices_Test {
	public static testMethod void testUpdateParentTrainignBreak(){
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC');
        T_INDIV_TRAIN__c indivTraining = new T_INDIV_TRAIN__c (IDN_CLIENT__c = indivObj.Id,
                                                              	Ignore__c = true,
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN__c indivTraining2 = new T_INDIV_TRAIN__c (IDN_CLIENT__c = indivObj.Id,
                                                              	Ignore__c = true,
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = null);
        Test.startTest();
        insert indivTraining;
        insert indivTraining2;
      //  T_INDIV_TRAIN__c IndivTrain =[Select Id, IDN_EXTNL__c from T_INDIV_TRAIN__c where Id=:indivTraining.Id];
        T_INDIV_TRAIN_INFO__c indivTrainingInfo1 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+1,
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN_INFO__c indivTrainingInfo2 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+2,
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN_INFO__c indivTrainingInfo3 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining2.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+4,
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN_INFO__c indivTrainingInfo4 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining2.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+4,
                                                              	DTE_END_EFFV__c = null);
        insert indivTrainingInfo1;
        insert indivTrainingInfo2;
        insert indivTrainingInfo3;
     //   insert indivTrainingInfo4;
        List<T_INDIV_TRAIN_INFO__c> lstIndvTrain = new List<T_INDIV_TRAIN_INFO__c>();
        lstIndvTrain.add(indivTrainingInfo1);
        lstIndvTrain.add(indivTrainingInfo4);
        CaseLastUpdatedServices.updateParentTrainignBreak(lstIndvTrain);
        CaseLastUpdatedServices.updateParentTrainingTmpBrkAfterDlt(lstIndvTrain);
        Test.stopTest();
    }
    
    public static testMethod void testUpdateParentTrainignBreak2(){
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC');
        T_INDIV_TRAIN__c indivTraining = new T_INDIV_TRAIN__c (IDN_CLIENT__c = indivObj.Id,
                                                              	Ignore__c = true,
                                                             //  	DTE_BEGIN_EFFV_INFO__c = System.today(),
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN__c indivTraining2 = new T_INDIV_TRAIN__c (IDN_CLIENT__c = indivObj.Id,
                                                              	Ignore__c = true,
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = null);
        Test.startTest();
        insert indivTraining;
        insert indivTraining2;
      
        T_INDIV_TRAIN_INFO__c indivTrainingInfo1 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = System.today());
        T_INDIV_TRAIN_INFO__c indivTrainingInfo2 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = System.today());
        T_INDIV_TRAIN_INFO__c indivTrainingInfo3 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+4,
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN_INFO__c indivTrainingInfo4 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining2.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+4,
                                                              	DTE_END_EFFV__c = null); 
        insert indivTrainingInfo1;
        insert indivTrainingInfo2;
        insert indivTrainingInfo3;
        insert indivTrainingInfo4;
        List<T_INDIV_TRAIN_INFO__c> lstIndvTrain = new List<T_INDIV_TRAIN_INFO__c>();
        lstIndvTrain.add(indivTrainingInfo1);
        lstIndvTrain.add(indivTrainingInfo3);
        CaseLastUpdatedServices.updateParentTrainingTmpBrkAfterDlt(lstIndvTrain);
        Test.stopTest();
    }
    
    public static testMethod void testUpdateEmpInfoOnParentObject(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c; 
		Map<String,Schema.RecordTypeInfo> employmentRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
		
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today(),
                                         									NAM_BUSNS__c = 'DellCorp' );
        T_SBSD_INDIV_EMPLMT__c employment2 =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today()+1,
                                         									NAM_BUSNS__c = 'DellCorp' );
        insert employment;
        insert employment2;
        T_INDIV_EMPLMT_INFO__c empInfo = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+2,
                                                                    DTE_END_EFFV__c =null);   
        T_INDIV_EMPLMT_INFO__c empInfo2 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+1,
                                                                    DTE_END_EFFV__c =null);
        T_INDIV_EMPLMT_INFO__c empInfo3 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment2.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+4,
                                                                    DTE_END_EFFV__c =null);
        T_INDIV_EMPLMT_INFO__c empInfo4 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment2.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+4,
                                                                    DTE_END_EFFV__c =null);
        
        Test.startTest();
        insert empInfo;
        insert empInfo2;
        insert empInfo3;
        insert empInfo4;
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
        List<T_INDIV_EMPLMT_INFO__c> lstIndvEmpInfo = new List<T_INDIV_EMPLMT_INFO__c>();
        lstIndvEmpInfo.add(empInfo);
        lstIndvEmpInfo.add(empInfo4);
        CaseLastUpdatedServices.updateEmpInfoOnParentObject(lstIndvEmpInfo);
        CaseLastUpdatedServices.updateEmpTmpBrkAfterDlt(lstIndvEmpInfo);
        Test.stopTest();
    }
    
    public static testMethod void testUpdateEmpInfoOnParentObject2(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c; 
		Map<String,Schema.RecordTypeInfo> employmentRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
		
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today()-3,
                                         									NAM_BUSNS__c = 'DellCorp' );
        T_SBSD_INDIV_EMPLMT__c employment2 =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today()-3,
                                         									NAM_BUSNS__c = 'DellCorp' );
        insert employment;
        insert employment2;
        T_INDIV_EMPLMT_INFO__c empInfo = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+2,
                                                                    DTE_END_EFFV__c =null);   
        
        T_INDIV_EMPLMT_INFO__c empInfo2 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()-1,
                                                                    DTE_END_EFFV__c =null); 
        T_INDIV_EMPLMT_INFO__c empInfo3 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment2.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+4,
                                                                    DTE_END_EFFV__c =null); 
        Test.startTest();
        insert empInfo;
        insert empInfo2;
        insert empInfo3;
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
        List<T_INDIV_EMPLMT_INFO__c> lstIndvEmpInfo = new List<T_INDIV_EMPLMT_INFO__c>();
        lstIndvEmpInfo.add(empInfo);
        lstIndvEmpInfo.add(empInfo3);
        CaseLastUpdatedServices.updateEmpInfoOnParentObject(lstIndvEmpInfo);
        CaseLastUpdatedServices.updateEmpTmpBrkAfterDlt(lstIndvEmpInfo);
        Test.stopTest();
    }
    
    public static testMethod void testupdateEmpTmpBrkAfterDlt(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c; 
		Map<String,Schema.RecordTypeInfo> employmentRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
		
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today()-3,
                                         									NAM_BUSNS__c = 'DellCorp' );
        T_SBSD_INDIV_EMPLMT__c employment2 =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today()-3,
                                         									NAM_BUSNS__c = 'DellCorp' );
        insert employment;
        insert employment2;
        T_INDIV_EMPLMT_INFO__c empInfo = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+2,
                                                                    DTE_END_EFFV__c =null);   
        
        T_INDIV_EMPLMT_INFO__c empInfo2 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()-2,
                                                                    DTE_END_EFFV__c =system.today()-1); 
        T_INDIV_EMPLMT_INFO__c empInfo3 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment2.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()-2,
                                                                    DTE_END_EFFV__c =system.today()-1); 
        Test.startTest();
        insert empInfo;
        insert empInfo2;
        insert empInfo3;
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
        List<T_INDIV_EMPLMT_INFO__c> lstIndvEmpInfo = new List<T_INDIV_EMPLMT_INFO__c>();
        lstIndvEmpInfo.add(empInfo);
        lstIndvEmpInfo.add(empInfo3);
        CaseLastUpdatedServices.updateEmpTmpBrkAfterDlt(lstIndvEmpInfo);
        Test.stopTest();
    }
    
    public static testMethod void testUpdateTeenEduInfoOnParentObject(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_INDIV_EDUC__c indivEduc = new T_INDIV_EDUC__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                   	CDE_TYPE_VERIF__c = 'NA',
                                   	DTE_BEGIN_EFFV__c = date.today() );
        T_INDIV_EDUC__c indivEduc2 = new T_INDIV_EDUC__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                   	CDE_TYPE_VERIF__c = 'NA',
                                   	DTE_BEGIN_EFFV__c = date.today()+1 );
        insert indivEduc;
        insert indivEduc2;
        Test.startTest();
        T_INDIV_EDUC_INFO__c indivEducInfo1 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today() );
        T_INDIV_EDUC_INFO__c indivEducInfo2 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc2.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+1 );
        T_INDIV_EDUC_INFO__c indivEducInfo3 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+4 );
         T_INDIV_EDUC_INFO__c indivEducInfo4 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc2.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+4 );
        
        insert indivEducInfo1;
        insert indivEducInfo2;
        insert indivEducInfo3;
        insert indivEducInfo4;
        List<T_INDIV_EDUC_INFO__c> newEmpInfoList = new List<T_INDIV_EDUC_INFO__c>();
        newEmpInfoList.add(indivEducInfo1);
        newEmpInfoList.add(indivEducInfo2);
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
        CaseLastUpdatedServices.updateTeenEduInfoOnParentObject(newEmpInfoList);
        CaseLastUpdatedServices.updateTeenEduBrkAfterDlt(newEmpInfoList);
      //  CaseLastUpdatedServices.updateTeenParentTmpBrkEndDate(newEmpInfoList);
        Test.stopTest();
    }
    
    public static testMethod void testUpdateTeenEduInfoOnParentObject2(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_INDIV_EDUC__c indivEduc = new T_INDIV_EDUC__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                   	CDE_TYPE_VERIF__c = 'NA',
                                   	DTE_BEGIN_EFFV__c = date.today()-3 );
        T_INDIV_EDUC__c indivEduc2 = new T_INDIV_EDUC__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                   	CDE_TYPE_VERIF__c = 'NA',
                                   	DTE_BEGIN_EFFV__c = date.today()-3 );
        insert indivEduc;
        insert indivEduc2;
        Test.startTest();
        T_INDIV_EDUC_INFO__c indivEducInfo1 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+2 );
        T_INDIV_EDUC_INFO__c indivEducInfo2 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc2.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+1 );
        T_INDIV_EDUC_INFO__c indivEducInfo3 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+4 );
       
        insert indivEducInfo1;
        insert indivEducInfo2;
        insert indivEducInfo3;
        List<T_INDIV_EDUC_INFO__c> newEmpInfoList = new List<T_INDIV_EDUC_INFO__c>();
        newEmpInfoList.add(indivEducInfo1);
        newEmpInfoList.add(indivEducInfo2);
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
        CaseLastUpdatedServices.updateTeenEduInfoOnParentObject(newEmpInfoList);
        CaseLastUpdatedServices.updateTeenEduBrkAfterDlt(newEmpInfoList);
        Test.stopTest();
    }
    
       
    public static testMethod void updateCWDetailEndDateOverlappingCaseCon1Test(){
        try{
            T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
            T_SBSD_CASE__c caseObj = TestClassUtility.createCase(false, countyObj.Id);
            caseObj.Is_Peak_Data__c = false;
            insert caseObj;
            TestClassUtility.createProvider(true, 'Test');
            T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
            
            List<T_CW_ADDNL_INFO__c> cwDataList = new List<T_CW_ADDNL_INFO__c>();
            T_CW_ADDNL_INFO__c cwdetails1 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                   IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today(),
                                                                   DTE_END_EFFEV__c = system.today() + 10);
            cwDataList.add(cwdetails1);
            
            T_CW_ADDNL_INFO__c cwdetails2 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                   IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today() +2,
                                                                   DTE_END_EFFEV__c = system.today() + 4);
            cwDataList.add(cwdetails2);
            
            T_CW_ADDNL_INFO__c cwdetails3 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                   IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today() +1,
                                                                   DTE_END_EFFEV__c = system.today() + 6);
            cwDataList.add(cwdetails3);
            T_CW_ADDNL_INFO__c cwdetails4 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                   IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today(),
                                                                   DTE_END_EFFEV__c = system.today() + 4);
            cwDataList.add(cwdetails4);
            
            T_CW_ADDNL_INFO__c cwdetails6 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                   IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today() + 1,
                                                                   DTE_END_EFFEV__c = system.today() + 2);
            cwDataList.add(cwdetails6);         
            
            
            insert cwDataList;
            Test.startTest();
            T_CW_ADDNL_INFO__c cwdetails5 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                   IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today() +6,
                                                                   DTE_END_EFFEV__c = system.today() +7);
            insert cwdetails5;
            
            List<T_CW_ADDNL_INFO__c> cwList = new List<T_CW_ADDNL_INFO__c>();
            cwList = [SELECT id,IDN_CASE_CHATS__c,IDN_CLIENT__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CW_ADDNL_INFO__c Where IDN_CASE_CHATS__c = :caseObj.Id];
            
            CaseLastUpdatedServices.updateCWDetailEndDate(cwList, false);
            Test.stopTest(); 
        }catch(exception ex){
            system.debug('Error');
        }  
        
    }
    
    public static testMethod void updateCWDetailEndDateOverlappingClientCon1Test(){
        
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(false, countyObj.Id);
        caseObj.Is_Peak_Data__c = false;
        insert caseObj;
        TestClassUtility.createProvider(true, 'Test');
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
        
        List<T_CW_ADDNL_INFO__c> cwDataList = new List<T_CW_ADDNL_INFO__c>();
        T_CW_ADDNL_INFO__c cwdetails1 = new T_CW_ADDNL_INFO__c(IDN_CASE_REFERAL__c = 124,
                                                               IDN_CLIENT__c = indivObj.Id,
                                                               TANF_RCVNG__c = 'Y',
                                                               CDE_PROG_AREA__c = 'OTH',
                                                               DTE_BEGIN_EFFEV__c = system.today(),
                                                               DTE_END_EFFEV__c = system.today() + 2);
        cwDataList.add(cwdetails1);
        
        T_CW_ADDNL_INFO__c cwdetails2 = new T_CW_ADDNL_INFO__c(IDN_CASE_REFERAL__c = 124,
                                                               IDN_CLIENT__c = indivObj.Id,
                                                               TANF_RCVNG__c = 'Y',
                                                               CDE_PROG_AREA__c = 'OTH',
                                                               DTE_BEGIN_EFFEV__c = system.today() +4,
                                                               DTE_END_EFFEV__c = system.today() + 5);
        cwDataList.add(cwdetails2);
        
        
        insert cwDataList;
        Test.startTest();
        T_CW_ADDNL_INFO__c cwdetails3 = new T_CW_ADDNL_INFO__c(IDN_CASE_REFERAL__c = 124,
                                                               IDN_CLIENT__c = indivObj.Id,
                                                               TANF_RCVNG__c = 'Y',
                                                               CDE_PROG_AREA__c = 'OTH',
                                                               DTE_BEGIN_EFFEV__c = system.today() +6,
                                                               DTE_END_EFFEV__c = system.today() +7);
        insert cwdetails3;
        List<T_CW_ADDNL_INFO__c> cwList = new List<T_CW_ADDNL_INFO__c>();
        cwList = [SELECT id,IDN_CASE_CHATS__c,IDN_CLIENT__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CW_ADDNL_INFO__c Where IDN_CLIENT__c = :indivObj.Id];
        
        CaseLastUpdatedServices.updateCWDetailEndDate(cwList, false);
        Test.stopTest();
    }
    
    public static testMethod void updateCWDetailEndDateCheckForCaseAndClientTest(){
        try{
            T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
            T_SBSD_CASE__c caseObj = TestClassUtility.createCase(false, countyObj.Id);
            caseObj.Is_Peak_Data__c = false;
            insert caseObj;
            TestClassUtility.createProvider(true, 'Test');
            T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
            
            List<T_CW_ADDNL_INFO__c> cwDataList = new List<T_CW_ADDNL_INFO__c>();
            T_CW_ADDNL_INFO__c cwdetails1 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                   IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today(),
                                                                   DTE_END_EFFEV__c = system.today() - 1);
            Test.startTest();  
            insert cwdetails1;
            List<T_CW_ADDNL_INFO__c> cwList = new List<T_CW_ADDNL_INFO__c>();
            cwList = [SELECT id,IDN_CASE_CHATS__c,IDN_CLIENT__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CW_ADDNL_INFO__c Where IDN_CASE_CHATS__c = :caseObj.Id];
            
            CaseLastUpdatedServices.updateCWDetailEndDate(cwList, false);
            Test.stopTest();  
        }catch(exception ex){
            system.debug('Error');
        }   
    }
    
    public static testMethod void updateCWDetailEndDateNullCheckForCaseAndClientTest(){
        try{
            T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
            T_SBSD_CASE__c caseObj = TestClassUtility.createCase(false, countyObj.Id);
            caseObj.Is_Peak_Data__c = false;
            insert caseObj;
            TestClassUtility.createProvider(true, 'Test');
            T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
            
            List<T_CW_ADDNL_INFO__c> cwDataList = new List<T_CW_ADDNL_INFO__c>();
            T_CW_ADDNL_INFO__c cwdetails1 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                   IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today(),
            													   DTE_END_EFFEV__c = null);
            
            insert  cwdetails1;  
            T_CW_ADDNL_INFO__c cwdetails2 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                   IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today(),
                                                                   DTE_END_EFFEV__c = system.today() + 1);
            
            Test.startTest();  
            insert cwdetails2;
            List<T_CW_ADDNL_INFO__c> cwList = new List<T_CW_ADDNL_INFO__c>();
            cwList = [SELECT id,IDN_CASE_CHATS__c,IDN_CLIENT__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CW_ADDNL_INFO__c Where IDN_CASE_CHATS__c = :caseObj.Id and IDN_CLIENT__c = :indivObj.Id];
            
            CaseLastUpdatedServices.updateCWDetailEndDate(cwList, false);
            Test.stopTest();  
        }catch(exception ex){
            system.debug('Error');
        }   
    }
    
    public static testMethod void updateCWDetailEndDateNullCheckForCaseAndClientTest2(){
        try{
            T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
            T_SBSD_CASE__c caseObj = TestClassUtility.createCase(false, countyObj.Id);
            caseObj.Is_Peak_Data__c = false;
            insert caseObj;
            TestClassUtility.createProvider(true, 'Test');
            T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
            
            List<T_CW_ADDNL_INFO__c> cwDataList = new List<T_CW_ADDNL_INFO__c>();
            T_CW_ADDNL_INFO__c cwdetails1 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                  // IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today(),
            													   DTE_END_EFFEV__c = null);
            
            insert  cwdetails1;  
            T_CW_ADDNL_INFO__c cwdetails2 = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                                   IDN_CASE_REFERAL__c = 124,
                                                                  // IDN_CLIENT__c = indivObj.Id,
                                                                   TANF_RCVNG__c = 'Y',
                                                                   CDE_PROG_AREA__c = 'OTH',
                                                                   DTE_BEGIN_EFFEV__c = system.today(),
                                                                   DTE_END_EFFEV__c = system.today() + 1);
            
            Test.startTest();  
            insert cwdetails2;
            List<T_CW_ADDNL_INFO__c> cwList = new List<T_CW_ADDNL_INFO__c>();
            cwList = [SELECT id,IDN_CASE_CHATS__c,IDN_CLIENT__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CW_ADDNL_INFO__c Where IDN_CASE_CHATS__c = :caseObj.Id and IDN_CLIENT__c = :indivObj.Id];
            
            CaseLastUpdatedServices.updateCWDetailEndDate(cwList, false);
            Test.stopTest();  
        }catch(exception ex){
            system.debug('Error');
        }   
    }
    
    public static testMethod void updateTANFDetailEndDateOverlappingCon1Test(){
        try{
            T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
            T_SBSD_CASE__c caseObj = TestClassUtility.createCase(false, countyObj.Id);
            caseObj.Is_Peak_Data__c = false;
            insert caseObj;
            TestClassUtility.createProvider(true, 'Test');
            T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
            
            List<T_CBMS_ADDNL_INFO__c> tanfDataList = new List<T_CBMS_ADDNL_INFO__c>();
            T_CBMS_ADDNL_INFO__c cs1 = new T_CBMS_ADDNL_INFO__c();
            cs1.IDN_CASE_INTFC__c = 'test1';
            cs1.CDE_CAT_ACTIV__c = 'CMA';
            cs1.IDN_CASE_CHATS__c = caseObj.Id;
            cs1.DTE_BEGIN_EFFEV__c = system.today();
            cs1.DTE_END_EFFEV__c = system.today() +10;
            tanfDataList.add(cs1);
            
            T_CBMS_ADDNL_INFO__c cs4 = new T_CBMS_ADDNL_INFO__c();
            cs4.IDN_CASE_INTFC__c = 'test2';
            cs4.CDE_CAT_ACTIV__c = 'CMA';
            cs4.IDN_CASE_CHATS__c = caseObj.Id;
            cs4.DTE_BEGIN_EFFEV__c = system.today() +2;
            cs4.DTE_END_EFFEV__c = system.today() +4;
            tanfDataList.add(cs4);
            
            T_CBMS_ADDNL_INFO__c cs5 = new T_CBMS_ADDNL_INFO__c();
            cs5.IDN_CASE_INTFC__c = 'test2';
            cs5.CDE_CAT_ACTIV__c = 'CMA';
            cs5.IDN_CASE_CHATS__c = caseObj.Id;
            cs5.DTE_BEGIN_EFFEV__c = system.today() +1;
            cs5.DTE_END_EFFEV__c = system.today() +6;
            tanfDataList.add(cs5);
            
            T_CBMS_ADDNL_INFO__c cs6 = new T_CBMS_ADDNL_INFO__c();
            cs6.IDN_CASE_INTFC__c = 'test2';
            cs6.CDE_CAT_ACTIV__c = 'CMA';
            cs6.IDN_CASE_CHATS__c = caseObj.Id;
            cs6.DTE_BEGIN_EFFEV__c = system.today();
            cs6.DTE_END_EFFEV__c = system.today() +4;
            tanfDataList.add(cs6);
            
            T_CBMS_ADDNL_INFO__c cs2 = new T_CBMS_ADDNL_INFO__c();
            cs2.IDN_CASE_INTFC__c = 'test2';
            cs2.CDE_CAT_ACTIV__c = 'CMA';
            cs2.IDN_CASE_CHATS__c = caseObj.Id;
            cs2.DTE_BEGIN_EFFEV__c = system.today() +1;
            cs2.DTE_END_EFFEV__c = system.today() +2;
            tanfDataList.add(cs2);
            
            insert tanfDataList;
            Test.startTest();
            T_CBMS_ADDNL_INFO__c cs3 = new T_CBMS_ADDNL_INFO__c();
            cs3.IDN_CASE_INTFC__c = 'test3';
            cs3.CDE_CAT_ACTIV__c = 'CMA';
            cs3.IDN_CASE_CHATS__c = caseObj.Id;
            cs3.DTE_BEGIN_EFFEV__c = system.today() +7;
            cs3.DTE_END_EFFEV__c = system.today() +10;
            insert cs3;
            
            List<T_CBMS_ADDNL_INFO__c> tanfList = new List<T_CBMS_ADDNL_INFO__c>();
            tanfList = [SELECT id,IDN_CASE_CHATS__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CBMS_ADDNL_INFO__c Where IDN_CASE_CHATS__c = :caseObj.Id];
            
            CaseLastUpdatedServices.updateTANFDetailEndDate(tanfList, false);
            Test.stopTest();
        }catch(exception ex){
            system.debug('Error');
        } 
        
    }
    
    public static testMethod void updateTANFDetailEndDateCheckTest(){
        try{
            T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
            T_SBSD_CASE__c caseObj = TestClassUtility.createCase(false, countyObj.Id);
            caseObj.Is_Peak_Data__c = false;
            insert caseObj;
            TestClassUtility.createProvider(true, 'Test');
            T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
            
            T_CBMS_ADDNL_INFO__c cs3 = new T_CBMS_ADDNL_INFO__c();
            cs3.IDN_CASE_INTFC__c = 'test3';
            cs3.CDE_CAT_ACTIV__c = 'CMA';
            cs3.IDN_CASE_CHATS__c = caseObj.Id;
            cs3.DTE_BEGIN_EFFEV__c = system.today();
            cs3.DTE_END_EFFEV__c = system.today() -1 ;
            
            
            Test.startTest();  
            insert cs3;
            List<T_CBMS_ADDNL_INFO__c> tanfList = new List<T_CBMS_ADDNL_INFO__c>();
            tanfList = [SELECT id,IDN_CASE_CHATS__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CBMS_ADDNL_INFO__c Where IDN_CASE_CHATS__c = :caseObj.Id];
            
            CaseLastUpdatedServices.updateTANFDetailEndDate(tanfList, false);
            Test.stopTest();  
        }catch(exception ex){
            system.debug('Error');
        }   
    }
    
    public static testMethod void updateTANFDetailEndDateNullCheckTest(){
        try{
            T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
            T_SBSD_CASE__c caseObj = TestClassUtility.createCase(false, countyObj.Id);
            caseObj.Is_Peak_Data__c = false;
            insert caseObj;
            TestClassUtility.createProvider(true, 'Test');
            T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
            
            T_CBMS_ADDNL_INFO__c cs3 = new T_CBMS_ADDNL_INFO__c();
            cs3.IDN_CASE_INTFC__c = 'test3';
            cs3.CDE_CAT_ACTIV__c = 'CMA';
            cs3.IDN_CASE_CHATS__c = caseObj.Id;
            cs3.DTE_BEGIN_EFFEV__c = system.today();
            
            insert  cs3;  
            T_CBMS_ADDNL_INFO__c cs4 = new T_CBMS_ADDNL_INFO__c();
            cs4.IDN_CASE_INTFC__c = 'test3';
            cs4.CDE_CAT_ACTIV__c = 'CMA';
            cs4.IDN_CASE_CHATS__c = caseObj.Id;
            cs4.DTE_BEGIN_EFFEV__c = system.today();
            cs4.DTE_END_EFFEV__c = system.today() + 1 ;
            
            Test.startTest();  
            insert cs4;
            List<T_CBMS_ADDNL_INFO__c> tanfList = new List<T_CBMS_ADDNL_INFO__c>();
            tanfList = [SELECT id,IDN_CASE_CHATS__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CBMS_ADDNL_INFO__c Where IDN_CASE_CHATS__c = :caseObj.Id];
            
            CaseLastUpdatedServices.updateTANFDetailEndDate(tanfList, false);
            Test.stopTest();  
        }catch(exception ex){
            system.debug('Error');
        }   
    }
    
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
		
		T_SBSD_INDIV_EMPLMT__c employment = new T_SBSD_INDIV_EMPLMT__c(ADR_CITY__c='NY',IDN_CLIENT__c=caseData.get('individual').Id,
																		NAM_BUSNS__c='test',
																		DTE_BEGIN_EFFV__c=system.today(),
																		Ignore__c=true);
								
		
		insert employment;
		
		insert new T_INDIV_EMPLMT_VERIF__c(IDN_EMPLMT_INDIV__c=employment.Id);
    //    insert new T_INDIV_EMPLMT_VERIF__c(IDN_EMPLMT_INDIV__c=employment.Id);
		
        Test.startTest();
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
        
        //05.16.2018- Assert added for code review changes : Shubham K
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        Test.stopTest();
    }
    
    public static testMethod void testupdateEmpInfoTmpBrkEndDate(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c; 
		Map<String,Schema.RecordTypeInfo> employmentRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
		
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today(),
                                         									NAM_BUSNS__c = 'DellCorp' );
        T_SBSD_INDIV_EMPLMT__c employment2 =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today()+1,
                                         									NAM_BUSNS__c = 'DellCorp' );
        insert employment;
        insert employment2;
        T_INDIV_EMPLMT_INFO__c empInfo = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+2,
                                                                    DTE_END_EFFV__c =null);   
        T_INDIV_EMPLMT_INFO__c empInfo2 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+1,
                                                                    DTE_END_EFFV__c =system.today()+3);
        T_INDIV_EMPLMT_INFO__c empInfo3 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment2.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+4,
                                                                    DTE_END_EFFV__c =null);
        T_INDIV_EMPLMT_INFO__c empInfo4 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment2.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+4,
                                                                    DTE_END_EFFV__c =null);
        T_INDIV_EMPLMT_INFO__c empInfo5 = new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment2.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today()+4,
                                                                    DTE_END_EFFV__c =null);
        
        Test.startTest();
        insert empInfo;
        insert empInfo2;
        insert empInfo3;
        insert empInfo4;
        insert empInfo5;
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
        List<T_INDIV_EMPLMT_INFO__c> lstIndvEmpInfo = new List<T_INDIV_EMPLMT_INFO__c>();
        lstIndvEmpInfo.add(empInfo);
        lstIndvEmpInfo.add(empInfo4);
        Map<Id, T_INDIV_EMPLMT_INFO__c> oldMapTempBrk = new Map<Id,T_INDIV_EMPLMT_INFO__c>();
        CaseLastUpdatedServices.updateEmpInfoTmpBrkEndDate(lstIndvEmpInfo,null);
        oldMapTempBrk.put(empInfo.Id, empInfo);
        oldMapTempBrk.put(empInfo2.Id, empInfo2);
        oldMapTempBrk.put(empInfo3.Id, empInfo3);
        CaseLastUpdatedServices.updateEmpInfoTmpBrkEndDate(lstIndvEmpInfo,oldMapTempBrk);
        Test.stopTest();
    }
    
    
    public static testMethod void testupdateTeenParentTmpBrkEndDate(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_INDIV_EDUC__c indivEduc = new T_INDIV_EDUC__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                   	CDE_TYPE_VERIF__c = 'NA',
                                   	DTE_BEGIN_EFFV__c = date.today() );
        T_INDIV_EDUC__c indivEduc2 = new T_INDIV_EDUC__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                   	CDE_TYPE_VERIF__c = 'NA',
                                   	DTE_BEGIN_EFFV__c = date.today()+1 );
        insert indivEduc;
        insert indivEduc2;
        Test.startTest();
        T_INDIV_EDUC_INFO__c indivEducInfo1 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today(),
                                                                    DTE_END_EFFV__c = null);
        T_INDIV_EDUC_INFO__c indivEducInfo2 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc2.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+1,
                                                                    DTE_END_EFFV__c = date.today()+3);
        T_INDIV_EDUC_INFO__c indivEducInfo3 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+4,
                                                                    DTE_END_EFFV__c = null);
        T_INDIV_EDUC_INFO__c indivEducInfo4 = new T_INDIV_EDUC_INFO__c( IDN_EDUC_INDIV__c=indivEduc2.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+4,
                                                                    DTE_END_EFFV__c = null);
        T_INDIV_EDUC_INFO__c indivEducInfo5 = new T_INDIV_EDUC_INFO__c( IDN_EDUC_INDIV__c=indivEduc2.Id,
                                   									CDE_TYPE_INFO_EDUC__c = 'MPL',
                                                                   	CDE_TYPE_VERIF__c = 'NA',
                                   									DTE_BEGIN_EFFV__c = date.today()+5,
                                                                    DTE_END_EFFV__c = date.today()+6);
        
        insert indivEducInfo1;
        insert indivEducInfo2;
        insert indivEducInfo3;
        insert indivEducInfo4;
        insert indivEducInfo5;
        List<T_INDIV_EDUC_INFO__c> newEmpInfoList = new List<T_INDIV_EDUC_INFO__c>();
        newEmpInfoList.add(indivEducInfo1);
        newEmpInfoList.add(indivEducInfo2);
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
		Map<Id, T_INDIV_EDUC_INFO__c> oldMapTempBrk = new Map<Id,T_INDIV_EDUC_INFO__c>();
        oldMapTempBrk.put(indivEducInfo1.Id, indivEducInfo1);
        oldMapTempBrk.put(indivEducInfo3.Id, indivEducInfo3);
        oldMapTempBrk.put(indivEducInfo4.Id, indivEducInfo4);
        CaseLastUpdatedServices.updateTeenParentTmpBrkEndDate(newEmpInfoList,oldMapTempBrk);
        Test.stopTest();
    }
    
    public static testMethod void testupdateParentTrainingTmpBrkEndDate(){
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC');
        T_INDIV_TRAIN__c indivTraining = new T_INDIV_TRAIN__c (IDN_CLIENT__c = indivObj.Id,
                                                              	Ignore__c = true,
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN__c indivTraining2 = new T_INDIV_TRAIN__c (IDN_CLIENT__c = indivObj.Id,
                                                              	Ignore__c = true,
                                                              	DTE_BEGIN_EFFV__c = System.today()+1,
                                                              	DTE_END_EFFV__c = null);
        Test.startTest();
        insert indivTraining;
        insert indivTraining2;
        T_INDIV_TRAIN_INFO__c indivTrainingInfo1 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+1,
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN_INFO__c indivTrainingInfo2 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+2,
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN_INFO__c indivTrainingInfo3 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining2.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+4,
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN_INFO__c indivTrainingInfo4 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining2.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+4,
                                                              	DTE_END_EFFV__c = null);
        T_INDIV_TRAIN_INFO__c indivTrainingInfo5 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = indivTraining2.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today()+5,
                                                              	DTE_END_EFFV__c = System.today()+6);
        insert indivTrainingInfo1;
        insert indivTrainingInfo2;
        insert indivTrainingInfo3;
     //   insert indivTrainingInfo4;
       // insert indivTrainingInfo5;
        List<T_INDIV_TRAIN_INFO__c> lstIndvTrain = new List<T_INDIV_TRAIN_INFO__c>();
        lstIndvTrain.add(indivTrainingInfo1);
        lstIndvTrain.add(indivTrainingInfo4);
        Map<Id, T_INDIV_TRAIN_INFO__c> oldMapTempBrk = new Map<Id, T_INDIV_TRAIN_INFO__c>();
        oldMapTempBrk.put(indivTrainingInfo2.Id, indivTrainingInfo2);
        oldMapTempBrk.put(indivTrainingInfo3.Id, indivTrainingInfo3);
        CaseLastUpdatedServices.updateParentTrainingTmpBrkEndDate(lstIndvTrain,oldMapTempBrk);
        Test.stopTest();
    }
}