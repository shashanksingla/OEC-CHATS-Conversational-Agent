@isTest
public class caseCWandTANFDetailTest {
    
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
                                                                   DTE_BEGIN_EFFEV__c = system.today());
            //DTE_END_EFFEV__c = system.today() - 1
            
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
    
}