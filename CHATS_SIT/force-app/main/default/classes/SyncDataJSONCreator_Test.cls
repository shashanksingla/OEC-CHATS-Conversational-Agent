@isTest
public class SyncDataJSONCreator_Test {
    public static testMethod void testSyncDataJSONForm(){
        //Removed unused variable on 5/13/2018 BG     
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, true);   
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, aCounty.Id);
        TestClassUtility.createCaseStatusMode(true,caseRec.Id);
        List<T_SBSD_INDIV__c> individualList = new List<T_SBSD_INDIV__c>();
        individualList.add((T_SBSD_INDIV__c)TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC'));
        individualList.add((T_SBSD_INDIV__c)TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC'));
        insert individualList;
        List<T_SBSD_CASE_INDIV__c> caseIndivList= new  List<T_SBSD_CASE_INDIV__c>();
        caseIndivList.add((T_SBSD_CASE_INDIV__c)TestClassUtility.createCaseIndividual(false, caseRec.Id, individualList[0].Id,true)); 
        caseIndivList.add((T_SBSD_CASE_INDIV__c)TestClassUtility.createCaseIndividual(false, caseRec.Id, individualList[1].Id,false)); 
        insert caseIndivList;
       
        /*List<T_INDIV_REL__c> relList = new List<T_INDIV_REL__c>();
        relList.add(new T_INDIV_REL__c(IDN_CLIENT_RELTD__c=individualList[1].Id,IDN_CLIENT__c=individualList[0].Id));
        insert relList;*/
        TestClassUtility.createIndivDisability(true,individualList[1].Id);
        insert new T_INDIV_CAT_RQ__c(   IDN_CASE_INDIV__c = caseIndivList[0].Id,
                                     CDE_CAT_PROG__c = 'CC',
                                     DTE_BEGIN_EFFV__c = system.today() );
        string returnvalue=SyncDataJSONCreator.SyncDataJSONForm(caseRec.Id);
        //system.assert(returnvalue.contains(relList[0].Id)) ;
    }
    public static testMethod void testSyncDataJSONForm1(){
        //Removed unused variable on 5/13/2018 BG     
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, true);   
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, aCounty.Id);
        TestClassUtility.createCaseStatusMode(true,caseRec.Id);
        T_SBSD_CASE_ADR__c adr = new T_SBSD_CASE_ADR__c(IDN_CASE__c=caseRec.Id,CDE_TYPE_ADR__c ='HOM');
        insert adr;
        T_SBSD_CASE_ASSET__c asset= new T_SBSD_CASE_ASSET__c(IDN_CASE__c=caseRec.Id);
        insert asset;
        List<T_SBSD_INDIV__c> individualList = new List<T_SBSD_INDIV__c>();
        individualList.add((T_SBSD_INDIV__c)TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC'));
        insert individualList;
        List<T_SBSD_CASE_INDIV__c> caseIndivList= new  List<T_SBSD_CASE_INDIV__c>();
        caseIndivList.add((T_SBSD_CASE_INDIV__c)TestClassUtility.createCaseIndividual(false, caseRec.Id, individualList[0].Id,true)); 
        insert caseIndivList;
        
        T_PRIM_ACTV__c prmryActvtyObj = new T_PRIM_ACTV__c( IDN_CASE__c = caseRec.Id, DTE_BEGIN_ACTV_PRIM__c = system.today(),
                                                           DTE_END_ACTV_PRIM__c = system.today() + 1, Ignore__c = true,
                                                           CDE_TYPE_ACTV__c = 'GED',IDN_CLIENT__c=individualList[0].Id
                                                          );
        insert prmryActvtyObj;
        
        T_PRIM_ACTV_CNTR__c prmryActvtyCntr = new T_PRIM_ACTV_CNTR__c(  IDN_PRIM_ACTV__c = prmryActvtyObj.Id, CNT_WEEKS__c = 13);
        insert prmryActvtyCntr;
       
        insert new T_INDIV_CAT_RQ__c(   IDN_CASE_INDIV__c = caseIndivList[0].Id,
                                     CDE_CAT_PROG__c = 'CC',
                                     DTE_BEGIN_EFFV__c = system.today() );
        string returnvalue=SyncDataJSONCreator.SyncDataJSONForm(caseRec.Id);
    }
    public static testMethod void testSyncDataJSONForm2(){
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, true);   
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, aCounty.Id);
        List<T_SBSD_INDIV__c> individualList = new List<T_SBSD_INDIV__c>();
        individualList.add((T_SBSD_INDIV__c)TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC'));
        individualList.add((T_SBSD_INDIV__c)TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC'));
        insert individualList;
        List<T_SBSD_CASE_INDIV__c> caseIndivList= new  List<T_SBSD_CASE_INDIV__c>();
        caseIndivList.add((T_SBSD_CASE_INDIV__c)TestClassUtility.createCaseIndividual(false, caseRec.Id, individualList[0].Id,true)); 
        caseIndivList.add((T_SBSD_CASE_INDIV__c)TestClassUtility.createCaseIndividual(false, caseRec.Id, individualList[1].Id,false)); 
        insert caseIndivList;
        T_INDIV_EDUC__c educ= new T_INDIV_EDUC__c(IDN_CLIENT__c=individualList[1].Id,Ignore__c=true);
        insert educ;
        T_INDIV_DDTN__c indivDeduction = new T_INDIV_DDTN__c(IDN_CLIENT__c=individualList[0].Id,Ignore__c=true);
        insert indivDeduction;
        T_INDIV_OTHER_INCOME__c income= new T_INDIV_OTHER_INCOME__c(IDN_CLIENT__c=individualList[0].Id);
        insert income;
        T_INDIV_TRAIN__c train= new T_INDIV_TRAIN__c(IDN_CLIENT__c=individualList[0].Id,DTE_BEGIN_EFFV__c=system.today(),Ignore__c=true);
        insert train;
        TestClassUtility.createChildSupport(true,individualList[1].Id);
        T_JOB_SEARCH__c Jobsearch= new T_JOB_SEARCH__c(IDN_CLIENT__c=individualList[0].Id,Ignore__c=true);
        insert Jobsearch; 
        T_SBSD_INDIV_INFO__c indivInfoRec =  new T_SBSD_INDIV_INFO__c(  IDN_CLIENT__c =individualList[0].Id,
                                                                      CDE_TYPE_INFO_INDIV__c = 'HDS',
                                                                      DTE_BEGIN_EFFV__c = date.today() );
        insert indivInfoRec;
        insert new T_INDIV_VERIF__c (   IDN_CLIENT__c = indivInfoRec.Id,
                                     CDE_TYPE_VERIF__c = 'NA' ,CDE_TYPE_INFO_INDIV__c='CS');
        string returnvalue=SyncDataJSONCreator.SyncDataJSONForm(caseRec.Id);
        system.assert(returnvalue.contains(Jobsearch.Id)) ;
    }
    
    public static testMethod void testSyncDataJSONForm3(){
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, true);   
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, aCounty.Id);
        List<T_SBSD_INDIV__c> individualList = new List<T_SBSD_INDIV__c>();
        individualList.add((T_SBSD_INDIV__c)TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC'));
        individualList.add((T_SBSD_INDIV__c)TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC'));
        insert individualList;
        List<T_SBSD_CASE_INDIV__c> caseIndivList= new  List<T_SBSD_CASE_INDIV__c>();
        caseIndivList.add((T_SBSD_CASE_INDIV__c)TestClassUtility.createCaseIndividual(false, caseRec.Id, individualList[0].Id,true)); 
        caseIndivList.add((T_SBSD_CASE_INDIV__c)TestClassUtility.createCaseIndividual(false, caseRec.Id, individualList[1].Id,false)); 
        insert caseIndivList;
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c; 
        Map<String,Schema.RecordTypeInfo> employmentRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
        
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(    IDN_CLIENT__c=individualList[0].Id,
                                                                        ADR_CITY__c = 'Denver',
                                                                        IND_STUBS_PAY_RCVS__c = 'Y',
                                                                        DTE_BEGIN_EFFV__c = date.today(),
                                                                        NAM_BUSNS__c = 'DellCorp',
                                                                        RecordTypeId = employmentRecordTypeInfo .get('Self-Employment').getRecordTypeId());
        insert employment;
        T_SBSD_INDIV_EMPLMT__c employment2 =  new T_SBSD_INDIV_EMPLMT__c(    IDN_CLIENT__c=individualList[0].Id,
                                                                        ADR_CITY__c = 'Denver',
                                                                        IND_STUBS_PAY_RCVS__c = 'Y',
                                                                        DTE_BEGIN_EFFV__c = date.today(),
                                                                        NAM_BUSNS__c = 'DellCorp',
                                                                        RecordTypeId = employmentRecordTypeInfo .get('Employment').getRecordTypeId());
        insert employment2 ;
        T_EMPLMT_INCOME__c empIncome = new T_EMPLMT_INCOME__c ( IDN_EMPLMT_INDIV__c = employment.Id,
                                                               DTE_BEGIN_EFFV__c = date.today(),
                                                               CNT_WEEK_PER_HOURS_ESTMD__c = 20.00,
                                                               AMT_INCOME_ANNUAL_ESTMD__c = 10000.00,
                                                               CDE_FREQ_PAY_ESTMD__c = 'MON',
                                                               CDE_TYPE_VERIF__c = 'NA'
                                                              );
        insert empIncome;
        insert new T_SBSD_EMPLMT_EXP__c (   IDN_EMPLMT_INDIV__c = employment.Id
                                        );
        insert new T_INDIV_EMPLMT_VERIF__c(IDN_EMPLMT_INDIV__c=employment2.Id);
        insert new T_INDIV_EMPLMT_INFO__c ( IDN_EMPLMT_INDIV__c = employment.Id,
                                           CDE_TYPE_INFO_EMPLMT__c = 'EIW');
        insert new T_EMPLMT_PAY_STUB__c(IDN_EMPLMT_INCOME__c=empIncome.Id, CDE_TYPE_VERIF__c ='NA');
        string returnvalue=SyncDataJSONCreator.SyncDataJSONForm(caseRec.Id);
        system.assert(returnvalue.contains(empIncome.Id)) ;
    }
}